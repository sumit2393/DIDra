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
      providers: [
        ChangeNotifierProvider(create: (_) => identityProvider),
        ChangeNotifierProvider(create: (_) => identityProvider),
      ],
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
      title: 'DappPay',
      debugShowCheckedModeBanner: false,
      themeMode: provider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.black, // 👈 Dark background
        cardColor: const Color(0xFF1E1E1E), // 👈 Slightly lighter card
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      home: provider.isWalletCreated
          ? const WalletDashboardScreen()
          : const CreateWalletScreen(),
    );
  }
}
