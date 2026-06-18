/// HQMLL Quantum Trader — main.dart v50.2
/// Root-Fix: MultiProvider innerhalb HQMLLApp — kein ProviderNotFoundException möglich
/// Grigori Saks · 2025
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

// ── Singleton-Services (einmalig erstellt, vor runApp) ────────────────────────
final _errorHandler        = ErrorHandlerService();
final _authService         = AuthService();
final _exchangeService     = ExchangeService();
final _persistenceService  = PersistenceService();
final _walletService       = WalletService();
final _paymentService      = PaymentService();
final _marketService       = MarketService();
final _autoSaveService     = AutoSaveService();
final _timeCrystalService  = TimeCrystalService();
final _tradingSignalService = TradingSignalService();
final _liveDataService     = LiveDataService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // ── Safe initialization — alle Fehler werden gecaptured ───────────────────
  await _errorHandler.runSafe(() => _authService.initialize(),
      source: 'AuthService');
  await _errorHandler.runSafe(() => _exchangeService.initialize(),
      source: 'ExchangeService');
  await _errorHandler.runSafe(
    () => _autoSaveService.initialize(
      persistenceService: _persistenceService,
      walletService:      _walletService,
      paymentService:     _paymentService,
      marketService:      _marketService,
      timeCrystalService: _timeCrystalService,
    ),
    source: 'AutoSaveService',
  );
  await _errorHandler.runSafe(
    () => _tradingSignalService.initialize(
      timeCrystalService: _timeCrystalService,
      exchangeService:    _exchangeService,
    ),
    source: 'TradingSignalService',
  );
  await _errorHandler.runSafe(() => _liveDataService.initialize(),
      source: 'LiveDataService');

  // ── Startup-Log ───────────────────────────────────────────────────────────
  _persistenceService.addSystemLog(
    'SYSTEM',
    'HQMLL Quantum Trader v50.2 gestartet — '
    'AutoSave (${_autoSaveService.intervalLabel}) · '
    'TradingSignals · TimeCrystal · LiveData · ErrorHandler aktiv',
    level: SysLogLevel.quantum,
  );

  runApp(const HQMLLApp());
}

// ══════════════════════════════════════════════════════════════════════════════
// ROOT APP WIDGET
// MultiProvider ist der äußerste Wrapper — KEIN ProviderNotFoundException
// möglich weil alle Provider-Zugriffe garantiert unter MultiProvider liegen.
// ══════════════════════════════════════════════════════════════════════════════
class HQMLLApp extends StatelessWidget {
  const HQMLLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Providers die KEINE Instanz von außen brauchen ──────────────────
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LivePriceProvider()),
        ChangeNotifierProvider(create: (_) => LiveMarketService()),
        ChangeNotifierProvider(create: (_) => CoinMarketCapService()),
        ChangeNotifierProvider(create: (_) => SecureVaultService()),
        // ── Singleton-Services (bereits initialisiert in main()) ─────────────
        ChangeNotifierProvider.value(value: _persistenceService),
        ChangeNotifierProvider.value(value: _authService),
        ChangeNotifierProvider.value(value: _exchangeService),
        ChangeNotifierProvider.value(value: _walletService),
        ChangeNotifierProvider.value(value: _paymentService),
        ChangeNotifierProvider.value(value: _marketService),
        ChangeNotifierProvider.value(value: _autoSaveService),
        ChangeNotifierProvider.value(value: _timeCrystalService),
        ChangeNotifierProvider.value(value: _tradingSignalService),
        ChangeNotifierProvider.value(value: _errorHandler),
        ChangeNotifierProvider.value(value: _liveDataService),
      ],
      // _AppShell liegt INNERHALB MultiProvider → alle context.watch() sicher
      child: const _AppShell(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP SHELL — MaterialApp + Global Overlays
// Liegt garantiert unter MultiProvider → context.watch() ist immer sicher
// ══════════════════════════════════════════════════════════════════════════════
class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    final tp   = context.watch<ThemeProvider>();
    final auth = context.watch<AuthService>();

    return MaterialApp(
      title: 'HQMLL Quantum Trader',
      debugShowCheckedModeBanner: false,
      theme: tp.themeData,
      // ── Global Error Overlay wraps den gesamten Navigator ─────────────────
      builder: (ctx, child) => GlobalErrorOverlay(
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
