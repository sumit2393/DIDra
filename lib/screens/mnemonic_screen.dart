import 'package:dapp/provider/provider.dart';
import 'package:dapp/screens/wallet_screens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MnemonicScreen extends StatelessWidget {
  const MnemonicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<IdentityModel>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Backup Mnemonic')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                await model.createIdentity();
              },
              child: const Text('Generate Mnemonic'),
            ),
            const SizedBox(height: 20),
            if (model.mnemonic != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  model.mnemonic!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, letterSpacing: 1.1),
                ),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: model.mnemonic == null
                  ? null
                  : () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WalletDashboardScreen(),
                        ),
                      );
                    },
              child: const Text('Continue to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
