class Identity {
  final String mnemonic;
  final String privateKeyHex; // hex without 0x
  final String publicAddress; // e.g. 0x...
  final String did; // e.g. did:example:pubhex

  Identity({
    required this.mnemonic,
    required this.privateKeyHex,
    required this.publicAddress,
    required this.did,
  });
}
