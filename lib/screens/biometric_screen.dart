import 'package:dapp/provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'mnemonic_screen.dart';

class CreateWalletScreen extends StatelessWidget {
  const CreateWalletScreen({super.key});

  Future<bool> _authenticate() async {
    final auth = LocalAuthentication();
    try {
      return await auth.authenticate(
        localizedReason: 'Authenticate to create your wallet',
        biometricOnly: true,
      );
    } catch (e) {
      debugPrint("Biometric error: $e");
      return false;
    }
  }

  Future<void> _createWallet(BuildContext context) async {
    final provider = Provider.of<IdentityModel>(context, listen: false);
    await provider.createIdentity();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MnemonicScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('Create Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Create Your Secure Wallet",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // 🔐 Biometric Button
            ElevatedButton.icon(
              icon: const Icon(Icons.fingerprint, size: 28),
              label: const Text(
                'Create Wallet with Biometric',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                bool success = await _authenticate();
                if (success) {
                  await _createWallet(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Biometric authentication failed"),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 16),

            // 🧠 Manual Create Wallet Button
            OutlinedButton.icon(
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 26),
              label: const Text(
                'Create Wallet Without Biometric',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.deepPurple, width: 1.5),
                foregroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                await _createWallet(context);
              },
            ),

            const SizedBox(height: 30),
            const Text(
              "You can also create wallet manually if biometric is unavailable.",
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
