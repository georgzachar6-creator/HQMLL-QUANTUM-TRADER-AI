import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/live_price_provider.dart';
import 'services/live_market_service.dart';
import 'services/coinmarketcap_service.dart';
import 'services/secure_vault_service.dart';
import 'services/auth_service.dart';
import 'services/exchange_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize services
  final authService = AuthService();
  final exchangeService = ExchangeService();
  await authService.initialize();
  await exchangeService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LivePriceProvider()),
        ChangeNotifierProvider(create: (_) => LiveMarketService()),
        ChangeNotifierProvider(create: (_) => CoinMarketCapService()),
        ChangeNotifierProvider(create: (_) => SecureVaultService()),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: exchangeService),
      ],
      child: const HQMLLApp(),
    ),
  );
}

class HQMLLApp extends StatelessWidget {
  const HQMLLApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final auth = context.watch<AuthService>();
    return MaterialApp(
      title: 'HQMLL Quantum Trader',
      debugShowCheckedModeBanner: false,
      theme: tp.themeData,
      home: SplashScreen(
        nextScreen: auth.isLoggedIn
            ? const MainScaffold()
            : const AuthScreen(),
      ),
    );
  }
}

