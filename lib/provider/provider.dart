import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'dart:developer';

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
        isWalletCreated = true; // 👈 wallet exists
      } else {
        log("🆕 No existing wallet found.");
      }
    } catch (e) {
      isWalletCreated = false; // 👈 new user
      log("❌ Init error: $e");
    }
  }

  Future<void> createIdentity() async {
    mnemonic = bip39.generateMnemonic();
    await _deriveKeys(mnemonic!);
    await _storage.write(key: 'mnemonic', value: mnemonic);
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
