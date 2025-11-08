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
// import 'package:bs58/bs58.dart' as bs58;

class IdentityModel extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  Web3Client? _client;
  String? mnemonic;
  String? privateKey;
  String? publicAddress;
  String? did;
  EtherAmount? balance;
  bool isWalletCreated = false;
  EthPrivateKey? credentials; // 👈 track if wallet exists

  bool isDark = false;

  ThemeMode get themeMode => isDark ? ThemeMode.dark : ThemeMode.light;
  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
  }

  Future<void> init() async {
    try {
      // ✅ Load RPC from .env
      final walletCreated = await _storage.read(key: 'wallet_created');
      isWalletCreated = walletCreated == 'true';

      final rpcUrl =
          dotenv.env['RPC_URL'] ??
          'https://eth-mainnet.g.alchemy.com/v2/8UlYC2t1GfmS8_omQdLrp';
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

    // ✅ Assign to class-level variable
    credentials = EthPrivateKey.fromHex(privateKey!);

    publicAddress = credentials!.address.hex;
    did = 'did:ethr:$publicAddress';

    // Optional DID:key format (Base58)
    final Uint8List pub = child.publicKey; // compressed pubkey
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

  Future<String?> sendTransaction({
    required String toAddress,
    required double amount,
  }) async {
    if (credentials == null || _client == null) {
      throw Exception("Wallet not initialized");
    }

    try {
      final sender = credentials!.address;
      final to = EthereumAddress.fromHex(toAddress);

      // Convert amount to Wei (use BigInt to avoid precision issues)
      final BigInt amountWei = BigInt.from(amount * 1e18);
      final value = EtherAmount.fromBigInt(EtherUnit.wei, amountWei);

      // Get current gas price
      final gasPrice = await _client!.getGasPrice();

      // Estimate gas with proper parameters
      final estimatedGas = await _client!.estimateGas(
        sender: sender,
        to: to,
        value: value,
        data: Uint8List(0), // empty data for simple transfer
      );

      // Add 20% buffer to estimated gas
      final gasLimit = (estimatedGas * BigInt.from(120)) ~/ BigInt.from(100);

      // Calculate total cost: (gasPrice * gasLimit) + value
      final gasCost = gasPrice.getInWei * gasLimit;
      final totalCost = gasCost + value.getInWei;

      // Check balance
      final balance = await _client!.getBalance(sender);
      if (balance.getInWei < totalCost) {
        final ethNeeded = EtherAmount.fromBigInt(
          EtherUnit.wei,
          totalCost,
        ).getValueInUnit(EtherUnit.ether);
        throw Exception(
          'Insufficient balance. Need $ethNeeded ETH (including gas)',
        );
      }

      // Send with calculated values
      final txHash = await _client!.sendTransaction(
        credentials!,
        Transaction(
          to: to,
          value: value,
          gasPrice: gasPrice,
          maxGas: gasLimit.toInt(),
        ),
        chainId: 11155111, // Mumbai testnet (Polygon)
        // For other networks use:
        // 1 for Ethereum Mainnet
        // 11155111 for Sepolia
        // 5 for Goerli
      );

      // Update balance after transaction
      await fetchBalance();
      return txHash;
    } catch (e) {
      debugPrint("❌ TX Error: $e");
      throw Exception(_parseTxError(e.toString()));
    }
  }

  // Helper: make RPC errors readable
  String _parseTxError(String raw) {
    if (raw.contains('insufficient funds')) {
      return 'Insufficient balance to cover gas + amount.';
    } else if (raw.contains('intrinsic gas too low')) {
      return 'Gas limit too low. Try again.';
    } else if (raw.contains('underpriced')) {
      return 'Transaction underpriced. Please retry later.';
    } else if (raw.contains('rejected')) {
      return 'Transaction rejected by node.';
    }
    return 'Transaction failed: $raw';
  }
}
