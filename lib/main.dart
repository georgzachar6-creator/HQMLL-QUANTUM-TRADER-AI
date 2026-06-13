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
import 'services/persistence_service.dart';
import 'services/wallet_service.dart';
import 'services/payment_service.dart';
import 'services/market_service.dart';
import 'services/auto_save_service.dart';
import 'services/time_crystal_service.dart';
import 'services/trading_signal_service.dart';
import 'services/error_handler_service.dart';
import 'services/live_data_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // ── Error Handler — FIRST (catches startup errors) ────────
  final errorHandler = ErrorHandlerService();

  // ── Initialize core services ──────────────────────────────
  final authService          = AuthService();
  final exchangeService      = ExchangeService();
  final persistenceService   = PersistenceService();
  final walletService        = WalletService();
  final paymentService       = PaymentService();
  final marketService        = MarketService();
  final autoSaveService      = AutoSaveService();
  final timeCrystalService   = TimeCrystalService();
  final tradingSignalService = TradingSignalService();
  final liveDataService      = LiveDataService();

  // ── Safe initialization with error capture ────────────────
  await errorHandler.runSafe(
    () => authService.initialize(),
    source: 'AuthService',
  );
  await errorHandler.runSafe(
    () => exchangeService.initialize(),
    source: 'ExchangeService',
  );

  // ── Boot AutoSave Service ──────────────────────────────────
  await errorHandler.runSafe(
    () => autoSaveService.initialize(
      persistenceService: persistenceService,
      walletService:      walletService,
      paymentService:     paymentService,
      marketService:      marketService,
      timeCrystalService: timeCrystalService,
    ),
    source: 'AutoSaveService',
  );

  // ── Start Realtime Services ────────────────────────────────
  await errorHandler.runSafe(
    () => tradingSignalService.initialize(
      timeCrystalService: timeCrystalService,
      exchangeService:    exchangeService,
    ),
    source: 'TradingSignalService',
  );
  await errorHandler.runSafe(
    () => liveDataService.initialize(),
    source: 'LiveDataService',
  );

  // ── Startup Log ───────────────────────────────────────────
  persistenceService.addSystemLog(
    'SYSTEM',
    'HQMLL Quantum Trader v49 gestartet — '
    'AutoSave (${autoSaveService.intervalLabel}) · '
    'TradingSignals · TimeCrystal · LiveData · ErrorHandler aktiv',
    level: SysLogLevel.quantum,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LivePriceProvider()),
        ChangeNotifierProvider(create: (_) => LiveMarketService()),
        ChangeNotifierProvider(create: (_) => CoinMarketCapService()),
        ChangeNotifierProvider(create: (_) => SecureVaultService()),
        ChangeNotifierProvider.value(value: persistenceService),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: exchangeService),
        ChangeNotifierProvider.value(value: walletService),
        ChangeNotifierProvider.value(value: paymentService),
        ChangeNotifierProvider.value(value: marketService),
        ChangeNotifierProvider.value(value: autoSaveService),
        ChangeNotifierProvider.value(value: timeCrystalService),
        ChangeNotifierProvider.value(value: tradingSignalService),
        ChangeNotifierProvider.value(value: errorHandler),
        ChangeNotifierProvider.value(value: liveDataService),
      ],
      child: const HQMLLApp(),
    ),
  );
}

class HQMLLApp extends StatelessWidget {
  const HQMLLApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tp   = context.watch<ThemeProvider>();
    final auth = context.watch<AuthService>();

    return MaterialApp(
      title: 'HQMLL Quantum Trader',
      debugShowCheckedModeBanner: false,
      theme: tp.themeData,
      // ── Global Error Overlay wraps everything ──────────────
      builder: (context, child) => GlobalErrorOverlay(
        child: QuantumErrorBoundary(
          boundaryName: 'Root',
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: SplashScreen(
        nextScreen: auth.isLoggedIn
            ? const MainScaffold()
            : const AuthScreen(),
      ),
    );
  }
}
