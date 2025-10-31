import 'package:dapp/provider/provider.dart';
import 'package:dapp/screens/biometric_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

class WalletDashboardScreen extends StatelessWidget {
  const WalletDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<IdentityModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await model.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateWalletScreen()),
                );
              }
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                title: const Text('Public Address'),
                subtitle: Text(model.publicAddress ?? '-'),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied')),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.indigo.shade50,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                title: const Text('Balance'),
                subtitle: Text(
                  model.balance != null
                      ? '${model.balance!.getValueInUnit(EtherUnit.ether).toStringAsFixed(4)} MATIC'
                      : 'Loading...',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: model.fetchBalance,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                title: const Text('DID Identifier'),
                subtitle: Text(model.did ?? '-'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
