import 'package:dapp/provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SendDialog extends StatefulWidget {
  const SendDialog({super.key});

  @override
  State<SendDialog> createState() => _SendDialogState();
}

class _SendDialogState extends State<SendDialog> {
  final _toController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<IdentityModel>(context);
    return AlertDialog(
      title: const Text('Send Ether'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _toController,
            decoration: InputDecoration(
              labelText: "Recipient Address",
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data != null &&
                      data.text != null &&
                      data.text!.isNotEmpty) {
                    setState(() {
                      _toController.text = data.text!.trim();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("📋 Address pasted")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Clipboard is empty")),
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: "Amount (ETH)"),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isSending
              ? null
              : () async {
                  final to = _toController.text.trim();
                  final amt = double.tryParse(_amountController.text.trim());
                  if (to.isEmpty || amt == null) return;

                  setState(() => _isSending = true);
                  try {
                    final txHash = await model.sendTransaction(
                      toAddress: to,
                      amount: amt,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("✅ Sent! Tx Hash: $txHash")),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("❌ Failed: $e")));
                  } finally {
                    setState(() => _isSending = false);
                  }
                },
          child: _isSending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Send"),
        ),
      ],
    );
  }
}
