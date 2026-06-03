/// HQMLL Quantum Trader – AutoSave Service v41.0
/// Universal auto-save coordinator for ALL services
/// Coordinates: PersistenceService · WalletService · PaymentService · MarketService
/// Periodic save every 30s + immediate save on any critical change
/// Grigori Saks · 2025
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'persistence_service.dart';
import 'wallet_service.dart';
import 'payment_service.dart';
import 'market_service.dart';

// ══════════════════════════════════════════════════════════════
// AUTO-SAVE STATE MODEL
// ══════════════════════════════════════════════════════════════
class AutoSaveState {
  final DateTime lastSaved;
  final int saveCount;
  final bool isSaving;
  final String lastSavedService;

  const AutoSaveState({
    required this.lastSaved,
    required this.saveCount,
    required this.isSaving,
    required this.lastSavedService,
  });

  String get lastSavedAgo {
    final diff = DateTime.now().difference(lastSaved);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  AutoSaveState copyWith({
    DateTime? lastSaved,
    int? saveCount,
    bool? isSaving,
    String? lastSavedService,
  }) => AutoSaveState(
    lastSaved: lastSaved ?? this.lastSaved,
    saveCount: saveCount ?? this.saveCount,
    isSaving: isSaving ?? this.isSaving,
    lastSavedService: lastSavedService ?? this.lastSavedService,
  );
}

// ══════════════════════════════════════════════════════════════
// AUTO-SAVE SERVICE — Universal Coordinator
// ══════════════════════════════════════════════════════════════
class AutoSaveService extends ChangeNotifier {
  static const _kSaveCount  = 'qt_auto_save_count_v41';
  static const _kLastSaved  = 'qt_auto_save_last_v41';
  static const _kAutoSaveOn = 'qt_auto_save_enabled_v41';
  static const _kInterval   = 'qt_auto_save_interval_v41';

  // Linked services
  PersistenceService? _persistenceService;
  WalletService?      _walletService;
  PaymentService?     _paymentService;
  MarketService?      _marketService;

  // Internal state
  Timer?  _periodicTimer;
  bool    _isInitialized = false;
  bool    _autoSaveEnabled = true;
  int     _intervalSeconds = 30;

  AutoSaveState _state = AutoSaveState(
    lastSaved: DateTime.now(),
    saveCount: 0,
    isSaving: false,
    lastSavedService: 'none',
  );

  // ── Public Getters ────────────────────────────────────────
  AutoSaveState get state        => _state;
  bool          get autoSaveOn   => _autoSaveEnabled;
  int           get intervalSec  => _intervalSeconds;
  bool          get isInitialized => _isInitialized;

  // ══════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════
  Future<void> initialize({
    required PersistenceService persistenceService,
    required WalletService walletService,
    required PaymentService paymentService,
    required MarketService marketService,
  }) async {
    _persistenceService = persistenceService;
    _walletService      = walletService;
    _paymentService     = paymentService;
    _marketService      = marketService;

    final prefs = await SharedPreferences.getInstance();
    final savedCount  = prefs.getInt(_kSaveCount) ?? 0;
    final lastSavedMs = prefs.getInt(_kLastSaved);
    _autoSaveEnabled  = prefs.getBool(_kAutoSaveOn) ?? true;
    _intervalSeconds  = prefs.getInt(_kInterval) ?? 30;

    _state = AutoSaveState(
      lastSaved: lastSavedMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSavedMs)
          : DateTime.now(),
      saveCount: savedCount,
      isSaving: false,
      lastSavedService: 'init',
    );

    // Start periodic timer
    if (_autoSaveEnabled) {
      _startTimer();
    }

    _isInitialized = true;
    notifyListeners();

    if (kDebugMode) {
      debugPrint('[AutoSaveService] Initialized — saveCount: $savedCount, interval: ${_intervalSeconds}s');
    }
  }

  // ══════════════════════════════════════════════════════════
  // TIMER MANAGEMENT
  // ══════════════════════════════════════════════════════════
  void _startTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      Duration(seconds: _intervalSeconds),
      (_) => saveAll(trigger: 'periodic'),
    );
  }

  void _stopTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Toggle auto-save on/off and persist setting
  Future<void> setAutoSaveEnabled(bool enabled) async {
    _autoSaveEnabled = enabled;
    if (enabled) {
      _startTimer();
    } else {
      _stopTimer();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoSaveOn, enabled);
    notifyListeners();
  }

  /// Change save interval (min 10s, max 300s)
  Future<void> setInterval(int seconds) async {
    _intervalSeconds = seconds.clamp(10, 300);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kInterval, _intervalSeconds);
    if (_autoSaveEnabled) _startTimer();
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // CORE SAVE METHODS
  // ══════════════════════════════════════════════════════════

  /// Save ALL services at once
  Future<void> saveAll({String trigger = 'manual'}) async {
    if (_state.isSaving) return; // Prevent concurrent saves

    _state = _state.copyWith(isSaving: true, lastSavedService: trigger);
    notifyListeners();

    try {
      final futures = <Future<void>>[];

      // Save wallet portfolios
      if (_walletService != null) {
        futures.add(_walletService!.forceSave());
      }

      // Save payment history + defaults
      if (_paymentService != null) {
        futures.add(_paymentService!.forceSave());
      }

      // Save market watchlist + alerts + settings
      if (_marketService != null) {
        futures.add(_marketService!.forceSave());
      }

      await Future.wait(futures);

      // Update meta
      final prefs = await SharedPreferences.getInstance();
      final newCount = _state.saveCount + 1;
      final now = DateTime.now();
      await prefs.setInt(_kSaveCount, newCount);
      await prefs.setInt(_kLastSaved, now.millisecondsSinceEpoch);

      _state = AutoSaveState(
        lastSaved: now,
        saveCount: newCount,
        isSaving: false,
        lastSavedService: trigger,
      );

      // Log to SystemLog
      _persistenceService?.addSystemLog(
        'AUTOSAVE',
        'Alle Services gespeichert [$trigger] — Save #$newCount',
        level: SysLogLevel.info,
      );

    } catch (e) {
      _state = _state.copyWith(isSaving: false);
      _persistenceService?.addSystemLog(
        'AUTOSAVE',
        'Fehler beim Speichern: $e',
        level: SysLogLevel.error,
      );
    }
    notifyListeners();
  }

  /// Save only WalletService — called after any wallet change
  Future<void> saveWallets({String reason = ''}) async {
    if (_walletService == null) return;
    await _walletService!.forceSave();
    _persistenceService?.addSystemLog(
      'WALLET',
      'Wallet gespeichert${reason.isNotEmpty ? " — $reason" : ""}',
      level: SysLogLevel.info,
    );
    _updateMeta('wallet');
  }

  /// Save only PaymentService — called after any payment/transfer
  Future<void> savePayments({String reason = ''}) async {
    if (_paymentService == null) return;
    await _paymentService!.forceSave();
    _persistenceService?.addSystemLog(
      'PAYMENT',
      'Zahlung gespeichert${reason.isNotEmpty ? " — $reason" : ""}',
      level: SysLogLevel.info,
    );
    _updateMeta('payment');
  }

  /// Save only MarketService — called after watchlist/alert change
  Future<void> saveMarket({String reason = ''}) async {
    if (_marketService == null) return;
    await _marketService!.forceSave();
    _persistenceService?.addSystemLog(
      'MARKET',
      'Markt gespeichert${reason.isNotEmpty ? " — $reason" : ""}',
      level: SysLogLevel.info,
    );
    _updateMeta('market');
  }

  /// Save PersistenceService settings (theme, WS config, etc.)
  Future<void> saveSettings({String reason = ''}) async {
    _persistenceService?.addSystemLog(
      'SETTINGS',
      'Einstellungen gespeichert${reason.isNotEmpty ? " — $reason" : ""}',
      level: SysLogLevel.info,
    );
    _updateMeta('settings');
  }

  void _updateMeta(String service) async {
    final prefs = await SharedPreferences.getInstance();
    final newCount = _state.saveCount + 1;
    final now = DateTime.now();
    await prefs.setInt(_kSaveCount, newCount);
    await prefs.setInt(_kLastSaved, now.millisecondsSinceEpoch);
    _state = AutoSaveState(
      lastSaved: now,
      saveCount: newCount,
      isSaving: false,
      lastSavedService: service,
    );
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // NOTIFICATION TRIGGER HOOKS
  // These are called by screens/widgets after user actions
  // ══════════════════════════════════════════════════════════

  /// Called when any setting changes (theme, language, notifications)
  void onSettingChanged(String settingName, dynamic value) {
    _persistenceService?.addSystemLog(
      'CONFIG',
      'Einstellung geaendert: $settingName = $value',
      level: SysLogLevel.info,
    );
    // Immediate save for settings changes
    saveSettings(reason: settingName);
  }

  /// Called when WS connection config changes
  void onConnectionChanged(String endpoint) {
    _persistenceService?.addSystemLog(
      'WS',
      'Verbindung geaendert: $endpoint',
      level: SysLogLevel.info,
    );
    saveSettings(reason: 'WS-Config: $endpoint');
  }

  /// Called when a transfer/payment is initiated
  void onTransferInitiated(String from, String to, double amount, String currency) {
    _persistenceService?.addSystemLog(
      'TX',
      'Transfer: $amount $currency von $from nach $to',
      level: SysLogLevel.quantum,
    );
    savePayments(reason: '$amount $currency');
  }

  /// Called when wallet balance updates
  void onWalletUpdated(String walletId) {
    saveWallets(reason: 'wallet: $walletId');
  }

  /// Called when market watchlist changes
  void onWatchlistChanged(String symbol, bool added) {
    saveMarket(reason: '${added ? "+" : "-"}$symbol');
  }

  /// Called when a market alert is set or triggered
  void onAlertChanged(String symbol, String type) {
    saveMarket(reason: 'Alert $type $symbol');
  }

  // ══════════════════════════════════════════════════════════
  // FACTORY RESET
  // ══════════════════════════════════════════════════════════
  Future<void> factoryReset() async {
    _stopTimer();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSaveCount);
    await prefs.remove(_kLastSaved);
    _state = AutoSaveState(
      lastSaved: DateTime.now(),
      saveCount: 0,
      isSaving: false,
      lastSavedService: 'reset',
    );
    if (_autoSaveEnabled) _startTimer();
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // STATUS DISPLAY HELPERS
  // ══════════════════════════════════════════════════════════
  String get statusText {
    if (_state.isSaving) return 'Speichere...';
    if (!_autoSaveEnabled) return 'Auto-Save deaktiviert';
    return 'Gespeichert ${_state.lastSavedAgo}';
  }

  String get intervalLabel {
    if (_intervalSeconds < 60) return '${_intervalSeconds}s';
    return '${_intervalSeconds ~/ 60}m';
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
