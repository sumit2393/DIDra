import 'package:dapp/provider/provider.dart';
import 'package:dapp/screens/biometric_screen.dart';
import 'package:dapp/screens/wallet_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final identityProvider = IdentityModel();
  await identityProvider.init();
  // final hasWallet = await identityProvider.hasExistingWallet();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => identityProvider)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IdentityModel>(context);
    return MaterialApp(
      title: 'DID Wallet',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      debugShowCheckedModeBanner: false,
      home: provider.isWalletCreated
          ? const WalletDashboardScreen()
          : const CreateWalletScreen(),
    );
  }
}
