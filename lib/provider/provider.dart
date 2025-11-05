import 'dart:typed_data' show Uint8List;

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'dart:developer';
import 'dart:typed_data';
import 'package:bs58/bs58.dart' as bs58;

class IdentityModel extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  Web3Client? _client;
  String? mnemonic;
  String? privateKey;
  String? publicAddress;
  String? did;
  EtherAmount? balance;
  bool isWalletCreated = false; // 👈 track if wallet exists

  Future<void> init() async {
    try {
      // ✅ Load RPC from .env
      final walletCreated = await _storage.read(key: 'wallet_created');
      isWalletCreated = walletCreated == 'true';

      final rpcUrl =
          dotenv.env['RPC_URL'] ?? 'https://rpc-amoy.polygon.technology';
      log("🌐 Using RPC: $rpcUrl");

      // ✅ Connect Web3 client
      _client = Web3Client(rpcUrl, Client());

      // ✅ Check if wallet already exists
      mnemonic = await _storage.read(key: 'mnemonic');
      if (mnemonic != null && mnemonic!.isNotEmpty) {
        log("🔑 Existing wallet found, deriving keys...");
        await _deriveKeys(mnemonic!);
        await fetchBalance();
        isWalletCreated = true;
        notifyListeners(); // 👈 wallet exists
      } else {
        isWalletCreated = false;
        log("🆕 No existing wallet found.");
      }
    } catch (e) {
      // 👈 new user
      log("❌ Init error: $e");
    }
  }

  // simple Base58 encode (Bitcoin alphabet)
  String _base58Encode(Uint8List input) {
    const String alphabet =
        '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    BigInt intData = BigInt.zero;
    for (final byte in input) {
      intData = (intData << 8) | BigInt.from(byte);
    }

    if (intData == BigInt.zero) {
      // handle all-zero input
      return alphabet[0] * input.length;
    }

    String result = '';
    while (intData > BigInt.zero) {
      final divRem = intData.remainder(BigInt.from(58));
      result = alphabet[divRem.toInt()] + result;
      intData = intData ~/ BigInt.from(58);
    }

    // preserve leading zeros
    for (final byte in input) {
      if (byte == 0) {
        result = alphabet[0] + result;
      } else {
        break;
      }
    }
    return result;
  }

  Future<void> createIdentity() async {
    mnemonic = bip39.generateMnemonic();
    await _deriveKeys(mnemonic!);
    await _storage.write(key: 'mnemonic', value: mnemonic);
    await _storage.write(key: 'wallet_created', value: 'true');
    await _storage.write(key: 'public_address', value: publicAddress);
    isWalletCreated = true;
    await _storage.write(key: 'wallet_created', value: 'true');
    notifyListeners();
  }

  Future<void> _deriveKeys(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath("m/44'/60'/0'/0/0");

    privateKey = hex.encode(child.privateKey!);
    final credentials = EthPrivateKey.fromHex(privateKey!);
    publicAddress = credentials.address.hex;
    did = 'did:ethr:$publicAddress';
    // derive did:key (multicodec prefix 0xE7 for secp256k1-pub)
    final Uint8List pub = child.publicKey; // compressed pubkey (33 bytes)
    final Uint8List prefixed = Uint8List(1 + pub.length)
      ..[0] = 0xE7
      ..setRange(1, 1 + pub.length, pub);
    final String b58 = _base58Encode(prefixed);
    did = 'did:key:z$b58';
  }

  // Future<bool> hasExistingWallet() async {
  //   String? address = await _storage.read(key: 'address');
  //   if (address != null && address.isNotEmpty) {
  //     publicAddress = address;
  //     mnemonic = await _storage.read(key: 'mnemonic');
  //     await fetchBalance();
  //     notifyListeners();
  //     return true;
  //   }
  //   return false;
  // }

  Future<void> logout() async {
    await _storage.deleteAll();
    isWalletCreated = false;
    mnemonic = null;
    publicAddress = null;
    balance = null;
    notifyListeners();
  }

  Future<void> fetchBalance() async {
    if (publicAddress == null) return;
    final address = EthereumAddress.fromHex(publicAddress!);
    balance = await _client?.getBalance(address);
    notifyListeners();
  }
}
