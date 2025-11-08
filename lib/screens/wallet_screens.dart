import 'package:dapp/provider/provider.dart';
import 'package:dapp/screens/biometric_screen.dart';
import 'package:dapp/screens/send_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter/services.dart';

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
                title: const Text('Wallet Public Address'),
                subtitle: Text(model.publicAddress ?? '-'),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    if (model.publicAddress != null &&
                        model.publicAddress!.isNotEmpty) {
                      await Clipboard.setData(
                        ClipboardData(text: model.publicAddress!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Address copied to clipboard'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No address to copy')),
                      );
                    }
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
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text("Send Token"),
              onPressed: () {
                showDialog(context: context, builder: (_) => SendDialog());
              },
            ),
            // Card(
            //   elevation: 3,
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(16),
            //   ),
            //   child: ListTile(
            //     title: const Text('Crytographic DID Identifier'),
            //     subtitle: Text(model.did ?? '-'),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
