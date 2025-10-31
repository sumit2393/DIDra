# 🪪 DID Wallet — Flutter + Dart

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)]()
[![Dart](https://img.shields.io/badge/Dart-2.x-blue.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)]()

> A simple, secure **Decentralized Identity (DID)** wallet built with **Flutter & Dart**.  
> It generates a mnemonic, derives private/public keys, creates a DID, connects to **Ankr RPC**, and displays your on-chain balance.

---

## 🧭 Overview

This project demonstrates a minimal DID wallet using **Flutter** for UI and **Dart** for blockchain logic.  
It helps developers understand the basics of decentralized identity, key management, and blockchain connectivity using open-source libraries.

**Use cases**
- Learning decentralized identity (DID) & Web3 basics  
- Building your own Flutter wallet  
- Showing off blockchain integration skills on GitHub

---

## ✨ Features

✅ Generate **BIP-39 mnemonic** (12/24 words)  
✅ Derive **HD private/public keys** and **Ethereum-compatible address**  
✅ Create a DID identifier like `did:ethr:0xYourAddress`  
✅ Connect to **Ankr RPC** (Ethereum / Polygon / BSC etc.)  
✅ Fetch and display on-chain **balance**  
✅ Securely store private keys using **flutter_secure_storage**  
✅ Clean architecture — easy to extend and integrate

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-------------|
| Framework | Flutter (Dart) |
| Blockchain SDK | [web3dart](https://pub.dev/packages/web3dart) |
| Mnemonic | [bip39](https://pub.dev/packages/bip39) |
<!-- | Crypto Utilities | pointycastle / ethereum_util | -->
| Secure Storage | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) |
| Networking | http |
| State Management | Provider|
