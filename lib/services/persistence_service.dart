// HQMLL Quantum Trader – Persistence Service v40.0
// Auto-Save: Settings, Bank Accounts, Transfer Prefs, Session State
// System Log: Resonanz, Frequenz, Funkwellen, Gravity, TX Events
// Research Log: QuantumResearchScreen persistent log + score
// WS Config: Endpoint-URLs persistent gespeichert
// ⚠️  NO REAL FINANCIAL DATA IS HARDCODED — user enters their own data
// Data is stored locally on-device via SharedPreferences (encrypted at rest by OS)
// Grigori Saks · 2025
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════════════
// SYSTEM LOG MODEL — Zentrale Protokollierung aller Events
// ══════════════════════════════════════════════════════════════
enum SysLogLevel { info, success, warning, error, quantum }

class SystemLogEntry {
  final String id;
  final DateTime timestamp;
  final SysLogLevel level;
  final String category; // 'RESONANZ' | 'FREQUENZ' | 'GRAVITY' | 'TX' | 'WS' | 'AI' | 'SYSTEM'
  final String message;

  const SystemLogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
  });

  String get levelLabel => level.name.toUpperCase();

  String get prefix {
    switch (level) {
      case SysLogLevel.success: return '✓';
      case SysLogLevel.warning: return '⚠';
      case SysLogLevel.error:   return '✗';
      case SysLogLevel.quantum: return '⟨ψ⟩';
      default:                  return '●';
    }
  }

  /// Formatted display string: [HH:MM:SS][CATEGORY] message
  String get display {
    final t = timestamp;
    final hms = '${t.hour.toString().padLeft(2,'0')}:'
                '${t.minute.toString().padLeft(2,'0')}:'
                '${t.second.toString().padLeft(2,'0')}';
    return '[$hms][$category] $message';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ts': timestamp.toIso8601String(),
    'level': level.name,
    'cat': category,
    'msg': message,
  };

  factory SystemLogEntry.fromJson(Map<String, dynamic> j) => SystemLogEntry(
    id: j['id'] as String? ?? '',
    timestamp: DateTime.tryParse(j['ts'] as String? ?? '') ?? DateTime.now(),
    level: SysLogLevel.values.firstWhere(
      (l) => l.name == j['level'],
      orElse: () => SysLogLevel.info,
    ),
    category: j['cat'] as String? ?? 'SYSTEM',
    message: j['msg'] as String? ?? '',
  );
}

// ── Bank Account Model ─────────────────────────────────────────
class BankAccount {
  final String id;
  final String label; // e.g. "Sparkasse Dortmund – Girokonto"
  final String bankName;
  final String accountHolder;
  final String iban; // stored locally, never sent anywhere
  final String bic;
  final String currency;
  final double balance; // manually entered / updated by user
  final String cardNumber; // last 4 digits only for display
  final String cardExpiry;
  final String cardType; // girocard | credit | debit
  final bool isDefault;
  final DateTime addedAt;

  const BankAccount({
    required this.id,
    required this.label,
    required this.bankName,
    required this.accountHolder,
    required this.iban,
    required this.bic,
    required this.currency,
    required this.balance,
    required this.cardNumber,
    required this.cardExpiry,
    required this.cardType,
    required this.isDefault,
    required this.addedAt,
  });

  /// Masked IBAN for display: DE59 **** **** **** **74
  String get maskedIban {
    if (iban.length < 6) return iban;
    final cc = iban.substring(0, 4);
    final last4 = iban.substring(iban.length - 4);
    return '$cc **** **** **** $last4';
  }

  /// Last 4 digits of card for display
  String get cardDisplay => '**** **** **** $cardNumber';

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'bankName': bankName,
    'accountHolder': accountHolder,
    'iban': iban,
    'bic': bic,
    'currency': currency,
    'balance': balance,
    'cardNumber': cardNumber,
    'cardExpiry': cardExpiry,
    'cardType': cardType,
    'isDefault': isDefault,
    'addedAt': addedAt.toIso8601String(),
  };

  factory BankAccount.fromJson(Map<String, dynamic> j) => BankAccount(
    id: j['id'] as String,
    label: j['label'] as String? ?? '',
    bankName: j['bankName'] as String? ?? '',
    accountHolder: j['accountHolder'] as String? ?? '',
    iban: j['iban'] as String? ?? '',
    bic: j['bic'] as String? ?? '',
    currency: j['currency'] as String? ?? 'EUR',
    balance: (j['balance'] as num?)?.toDouble() ?? 0.0,
    cardNumber: j['cardNumber'] as String? ?? '',
    cardExpiry: j['cardExpiry'] as String? ?? '',
    cardType: j['cardType'] as String? ?? 'girocard',
    isDefault: j['isDefault'] as bool? ?? false,
    addedAt: DateTime.tryParse(j['addedAt'] as String? ?? '') ?? DateTime.now(),
  );

  BankAccount copyWith({
    String? label, String? bankName, String? accountHolder,
    String? iban, String? bic, String? currency, double? balance,
    String? cardNumber, String? cardExpiry, String? cardType,
    bool? isDefault,
  }) => BankAccount(
    id: id,
    label: label ?? this.label,
    bankName: bankName ?? this.bankName,
    accountHolder: accountHolder ?? this.accountHolder,
    iban: iban ?? this.iban,
    bic: bic ?? this.bic,
    currency: currency ?? this.currency,
    balance: balance ?? this.balance,
    cardNumber: cardNumber ?? this.cardNumber,
    cardExpiry: cardExpiry ?? this.cardExpiry,
    cardType: cardType ?? this.cardType,
    isDefault: isDefault ?? this.isDefault,
    addedAt: addedAt,
  );
}

// ── Transfer Preference Model ──────────────────────────────────
class TransferPrefs {
  final String defaultFromBank; // account id
  final String defaultCurrency;
  final double defaultAmount;
  final bool rememberLastAmount;
  final bool autoConfirm;
  final String defaultNetwork; // for crypto transfers

  const TransferPrefs({
    this.defaultFromBank = '',
    this.defaultCurrency = 'EUR',
    this.defaultAmount = 0.0,
    this.rememberLastAmount = true,
    this.autoConfirm = false,
    this.defaultNetwork = 'Ethereum',
  });

  Map<String, dynamic> toJson() => {
    'defaultFromBank': defaultFromBank,
    'defaultCurrency': defaultCurrency,
    'defaultAmount': defaultAmount,
    'rememberLastAmount': rememberLastAmount,
    'autoConfirm': autoConfirm,
    'defaultNetwork': defaultNetwork,
  };

  factory TransferPrefs.fromJson(Map<String, dynamic> j) => TransferPrefs(
    defaultFromBank: j['defaultFromBank'] as String? ?? '',
    defaultCurrency: j['defaultCurrency'] as String? ?? 'EUR',
    defaultAmount: (j['defaultAmount'] as num?)?.toDouble() ?? 0.0,
    rememberLastAmount: j['rememberLastAmount'] as bool? ?? true,
    autoConfirm: j['autoConfirm'] as bool? ?? false,
    defaultNetwork: j['defaultNetwork'] as String? ?? 'Ethereum',
  );

  TransferPrefs copyWith({
    String? defaultFromBank, String? defaultCurrency, double? defaultAmount,
    bool? rememberLastAmount, bool? autoConfirm, String? defaultNetwork,
  }) => TransferPrefs(
    defaultFromBank: defaultFromBank ?? this.defaultFromBank,
    defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    defaultAmount: defaultAmount ?? this.defaultAmount,
    rememberLastAmount: rememberLastAmount ?? this.rememberLastAmount,
    autoConfirm: autoConfirm ?? this.autoConfirm,
    defaultNetwork: defaultNetwork ?? this.defaultNetwork,
  );
}

// ── WS Endpoint Config ────────────────────────────────────────
class WsEndpointConfig {
  final String binanceWsUrl;
  final String binanceRestUrl;
  final String coinGeckoUrl;
  final bool useBinanceWs;
  final bool useCoinGeckoFallback;
  final int restPollIntervalSec;

  const WsEndpointConfig({
    this.binanceWsUrl      = 'wss://stream.binance.com:9443',
    this.binanceRestUrl    = 'https://api.binance.com',
    this.coinGeckoUrl      = 'https://api.coingecko.com/api/v3',
    this.useBinanceWs      = true,
    this.useCoinGeckoFallback = true,
    this.restPollIntervalSec  = 30,
  });

  Map<String, dynamic> toJson() => {
    'binanceWsUrl':         binanceWsUrl,
    'binanceRestUrl':       binanceRestUrl,
    'coinGeckoUrl':         coinGeckoUrl,
    'useBinanceWs':         useBinanceWs,
    'useCoinGeckoFallback': useCoinGeckoFallback,
    'restPollIntervalSec':  restPollIntervalSec,
  };

  factory WsEndpointConfig.fromJson(Map<String, dynamic> j) => WsEndpointConfig(
    binanceWsUrl:        j['binanceWsUrl']        as String? ?? 'wss://stream.binance.com:9443',
    binanceRestUrl:      j['binanceRestUrl']       as String? ?? 'https://api.binance.com',
    coinGeckoUrl:        j['coinGeckoUrl']         as String? ?? 'https://api.coingecko.com/api/v3',
    useBinanceWs:        j['useBinanceWs']         as bool?   ?? true,
    useCoinGeckoFallback: j['useCoinGeckoFallback'] as bool?  ?? true,
    restPollIntervalSec: (j['restPollIntervalSec'] as num?)?.toInt() ?? 30,
  );

  WsEndpointConfig copyWith({
    String? binanceWsUrl, String? binanceRestUrl, String? coinGeckoUrl,
    bool? useBinanceWs, bool? useCoinGeckoFallback, int? restPollIntervalSec,
  }) => WsEndpointConfig(
    binanceWsUrl:        binanceWsUrl        ?? this.binanceWsUrl,
    binanceRestUrl:      binanceRestUrl      ?? this.binanceRestUrl,
    coinGeckoUrl:        coinGeckoUrl        ?? this.coinGeckoUrl,
    useBinanceWs:        useBinanceWs        ?? this.useBinanceWs,
    useCoinGeckoFallback: useCoinGeckoFallback ?? this.useCoinGeckoFallback,
    restPollIntervalSec: restPollIntervalSec ?? this.restPollIntervalSec,
  );
}

// ═══════════════════════════════════════════════════════════════
// PERSISTENCE SERVICE v40.0
// ═══════════════════════════════════════════════════════════════
class PersistenceService extends ChangeNotifier {
  // ── SharedPreferences keys ─────────────────────────────────
  static const _kBankAccounts       = 'qt_bank_accounts_v2';
  static const _kTransferPrefs      = 'qt_transfer_prefs_v2';
  static const _kLastTab            = 'qt_last_tab';
  static const _kAutonomousTrading  = 'qt_autonomous_trading';
  static const _kSelfHealEnabled    = 'qt_self_heal';
  static const _kAgentCount         = 'qt_agent_count';
  // v40 keys
  static const _kSystemLogs         = 'qt_system_logs_v40';
  static const _kResearchLogs       = 'qt_research_logs_v40';
  static const _kQuantumScore       = 'qt_quantum_score_v40';
  static const _kWsConfig           = 'qt_ws_config_v40';
  static const _kAppThemeIndex      = 'qt_app_theme_index';
  static const _kLastScreen         = 'qt_last_screen';

  /// Max entries kept in persisted system log (newest kept)
  static const int _kMaxSystemLogs  = 500;
  /// Max entries kept in research log
  static const int _kMaxResearchLogs = 200;

  // ── Internal state ─────────────────────────────────────────
  final List<BankAccount>      _bankAccounts  = [];
  final List<SystemLogEntry>   _systemLogs    = [];
  final List<String>           _researchLogs  = [];
  TransferPrefs   _transferPrefs   = const TransferPrefs();
  WsEndpointConfig _wsConfig       = const WsEndpointConfig();
  int             _lastTab         = 0;
  int             _lastScreen      = 0;
  bool            _autonomousTradingEnabled = false;
  bool            _selfHealEnabled = true;
  int             _activeAgentCount = 12;
  int             _quantumScore    = 847;
  int             _appThemeIndex   = 0;
  bool            _loaded          = false;

  // ── Public getters ──────────────────────────────────────────
  List<BankAccount>      get bankAccounts  => List.unmodifiable(_bankAccounts);
  List<SystemLogEntry>   get systemLogs    => List.unmodifiable(_systemLogs);
  List<String>           get researchLogs  => List.unmodifiable(_researchLogs);
  WsEndpointConfig       get wsConfig      => _wsConfig;
  TransferPrefs          get transferPrefs  => _transferPrefs;
  int                    get lastTab        => _lastTab;
  int                    get lastScreen     => _lastScreen;
  bool get autonomousTradingEnabled => _autonomousTradingEnabled;
  bool                   get selfHealEnabled => _selfHealEnabled;
  int                    get activeAgentCount => _activeAgentCount;
  int                    get quantumScore   => _quantumScore;
  int                    get appThemeIndex  => _appThemeIndex;
  bool                   get isLoaded       => _loaded;

  BankAccount? get defaultAccount =>
      _bankAccounts.where((a) => a.isDefault).firstOrNull ??
      (_bankAccounts.isNotEmpty ? _bankAccounts.first : null);
  double get totalFiatBalance =>
      _bankAccounts.fold(0.0, (s, a) => s + a.balance);

  PersistenceService() {
    _load();
  }

  // ════════════════════════════════════════════════════════════
  // LOAD — alle persistierten Daten wiederherstellen
  // ════════════════════════════════════════════════════════════
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Bank accounts
      final rawBa = prefs.getString(_kBankAccounts);
      if (rawBa != null) {
        final list = jsonDecode(rawBa) as List<dynamic>;
        _bankAccounts.clear();
        for (final j in list) {
          try { _bankAccounts.add(BankAccount.fromJson(j as Map<String, dynamic>)); }
          catch (_) {}
        }
      }

      // Transfer prefs
      final rawTp = prefs.getString(_kTransferPrefs);
      if (rawTp != null) {
        try { _transferPrefs = TransferPrefs.fromJson(jsonDecode(rawTp) as Map<String, dynamic>); }
        catch (_) {}
      }

      // WS endpoint config
      final rawWs = prefs.getString(_kWsConfig);
      if (rawWs != null) {
        try { _wsConfig = WsEndpointConfig.fromJson(jsonDecode(rawWs) as Map<String, dynamic>); }
        catch (_) {}
      }

      // Session state
      _lastTab              = prefs.getInt(_kLastTab)       ?? 0;
      _lastScreen           = prefs.getInt(_kLastScreen)    ?? 0;
      _autonomousTradingEnabled = prefs.getBool(_kAutonomousTrading) ?? false;
      _selfHealEnabled      = prefs.getBool(_kSelfHealEnabled) ?? true;
      _activeAgentCount     = prefs.getInt(_kAgentCount)    ?? 12;
      _appThemeIndex        = prefs.getInt(_kAppThemeIndex) ?? 0;

      // Quantum score
      _quantumScore = prefs.getInt(_kQuantumScore) ?? 847;

      // Research logs
      final rawRl = prefs.getString(_kResearchLogs);
      if (rawRl != null) {
        try {
          final list = jsonDecode(rawRl) as List<dynamic>;
          _researchLogs.clear();
          _researchLogs.addAll(list.map((e) => e.toString()));
        } catch (_) {}
      }

      // System logs
      final rawSl = prefs.getString(_kSystemLogs);
      if (rawSl != null) {
        try {
          final list = jsonDecode(rawSl) as List<dynamic>;
          _systemLogs.clear();
          for (final j in list) {
            try { _systemLogs.add(SystemLogEntry.fromJson(j as Map<String, dynamic>)); }
            catch (_) {}
          }
        } catch (_) {}
      }

      _loaded = true;
      notifyListeners();

      // Boot log entry
      _addSystemLogInternal(
        SysLogLevel.success, 'SYSTEM',
        'PersistenceService v40.0 geladen — ${_bankAccounts.length} Konten, '
        '${_systemLogs.length} Log-Einträge, Score: $_quantumScore',
        save: true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('PersistenceService._load error: $e');
      _loaded = true;
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════════
  // SYSTEM LOG — zentrales persistentes Ereignisprotokoll
  // ════════════════════════════════════════════════════════════
  void addSystemLog(String category, String message, {SysLogLevel level = SysLogLevel.info}) {
    _addSystemLogInternal(level, category, message, save: true);
    notifyListeners();
  }

  void _addSystemLogInternal(
    SysLogLevel level, String category, String message,
    {bool save = false}
  ) {
    final entry = SystemLogEntry(
      id: 'SL${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
    );
    _systemLogs.add(entry);
    // Trim to max size (keep newest)
    if (_systemLogs.length > _kMaxSystemLogs) {
      _systemLogs.removeRange(0, _systemLogs.length - _kMaxSystemLogs);
    }
    if (save) _saveSystemLogs();
  }

  Future<void> _saveSystemLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_systemLogs.map((e) => e.toJson()).toList());
      await prefs.setString(_kSystemLogs, json);
    } catch (e) {
      if (kDebugMode) debugPrint('PersistenceService._saveSystemLogs error: $e');
    }
  }

  Future<void> clearSystemLogs() async {
    _systemLogs.clear();
    await _saveSystemLogs();
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // RESEARCH LOG — QuantumResearchScreen persistent
  // ════════════════════════════════════════════════════════════
  Future<void> saveResearchLog(List<String> log, int score) async {
    _researchLogs.clear();
    final trimmed = log.length > _kMaxResearchLogs
        ? log.sublist(log.length - _kMaxResearchLogs)
        : log;
    _researchLogs.addAll(trimmed);
    _quantumScore = score;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kResearchLogs, jsonEncode(_researchLogs));
      await prefs.setInt(_kQuantumScore, _quantumScore);
    } catch (e) {
      if (kDebugMode) debugPrint('PersistenceService.saveResearchLog error: $e');
    }
    notifyListeners();
  }

  Future<void> addResearchLogEntry(String entry, {int? newScore}) async {
    _researchLogs.add(entry);
    if (newScore != null) _quantumScore = newScore;
    if (_researchLogs.length > _kMaxResearchLogs) {
      _researchLogs.removeRange(0, _researchLogs.length - _kMaxResearchLogs);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kResearchLogs, jsonEncode(_researchLogs));
      if (newScore != null) await prefs.setInt(_kQuantumScore, _quantumScore);
    } catch (e) {
      if (kDebugMode) debugPrint('PersistenceService.addResearchLogEntry error: $e');
    }
  }

  Future<void> clearResearchLog() async {
    _researchLogs.clear();
    _quantumScore = 847;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kResearchLogs);
      await prefs.setInt(_kQuantumScore, _quantumScore);
    } catch (_) {}
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // WS ENDPOINT CONFIG — Verbindungsparameter persistent
  // ════════════════════════════════════════════════════════════
  Future<void> saveWsConfig(WsEndpointConfig config) async {
    _wsConfig = config;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kWsConfig, jsonEncode(config.toJson()));
    } catch (e) {
      if (kDebugMode) debugPrint('PersistenceService.saveWsConfig error: $e');
    }
    notifyListeners();
    addSystemLog('WS', 'WS-Config gespeichert: ${config.binanceWsUrl}');
  }

  // ════════════════════════════════════════════════════════════
  // BANK ACCOUNT CRUD
  // ════════════════════════════════════════════════════════════
  Future<void> addBankAccount(BankAccount account) async {
    final acc = _bankAccounts.isEmpty
        ? account.copyWith(isDefault: true)
        : account;
    _bankAccounts.add(acc);
    await _saveBankAccounts();
    notifyListeners();
    addSystemLog('BANK', 'Konto hinzugefügt: ${acc.label}');
  }

  Future<void> updateBankAccount(BankAccount updated) async {
    final idx = _bankAccounts.indexWhere((a) => a.id == updated.id);
    if (idx >= 0) {
      _bankAccounts[idx] = updated;
      await _saveBankAccounts();
      notifyListeners();
    }
  }

  Future<void> updateBalance(String id, double newBalance) async {
    final idx = _bankAccounts.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      _bankAccounts[idx] = _bankAccounts[idx].copyWith(balance: newBalance);
      await _saveBankAccounts();
      notifyListeners();
    }
  }

  Future<void> setDefaultAccount(String id) async {
    for (int i = 0; i < _bankAccounts.length; i++) {
      _bankAccounts[i] = _bankAccounts[i].copyWith(
          isDefault: _bankAccounts[i].id == id);
    }
    await _saveBankAccounts();
    notifyListeners();
  }

  Future<void> removeBankAccount(String id) async {
    _bankAccounts.removeWhere((a) => a.id == id);
    if (_bankAccounts.isNotEmpty &&
        !_bankAccounts.any((a) => a.isDefault)) {
      _bankAccounts[0] = _bankAccounts[0].copyWith(isDefault: true);
    }
    await _saveBankAccounts();
    notifyListeners();
  }

  Future<void> _saveBankAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_bankAccounts.map((a) => a.toJson()).toList());
      await prefs.setString(_kBankAccounts, json);
    } catch (e) {
      if (kDebugMode) debugPrint('PersistenceService._saveBankAccounts error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // TRANSFER PREFS
  // ════════════════════════════════════════════════════════════
  Future<void> setTransferPrefs(TransferPrefs prefs) async {
    _transferPrefs = prefs;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kTransferPrefs, jsonEncode(prefs.toJson()));
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setLastAmount(double amt) async {
    if (!_transferPrefs.rememberLastAmount) return;
    _transferPrefs = _transferPrefs.copyWith(defaultAmount: amt);
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kTransferPrefs, jsonEncode(_transferPrefs.toJson()));
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════════
  // SESSION STATE — Tab, Screen, Theme
  // ════════════════════════════════════════════════════════════
  Future<void> saveLastTab(int tab) async {
    _lastTab = tab;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_kLastTab, tab);
    } catch (_) {}
  }

  Future<void> saveLastScreen(int screen) async {
    _lastScreen = screen;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_kLastScreen, screen);
    } catch (_) {}
  }

  Future<void> saveAppTheme(int themeIndex) async {
    _appThemeIndex = themeIndex;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_kAppThemeIndex, themeIndex);
    } catch (_) {}
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // FEATURE FLAGS — Autonomous Trading, Self-Heal, Agent Count
  // ════════════════════════════════════════════════════════════
  Future<void> setAutonomousTrading(bool v) async {
    _autonomousTradingEnabled = v;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_kAutonomousTrading, v);
    } catch (_) {}
    notifyListeners();
    addSystemLog('AI', 'Autonomes Trading: ${v ? "AKTIVIERT" : "DEAKTIVIERT"}',
        level: v ? SysLogLevel.success : SysLogLevel.warning);
  }

  Future<void> setSelfHeal(bool v) async {
    _selfHealEnabled = v;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_kSelfHealEnabled, v);
    } catch (_) {}
    notifyListeners();
    addSystemLog('AI', 'Self-Heal Engine: ${v ? "AKTIV" : "INAKTIV"}');
  }

  Future<void> setAgentCount(int count) async {
    _activeAgentCount = count.clamp(1, 12);
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_kAgentCount, _activeAgentCount);
    } catch (_) {}
    notifyListeners();
    addSystemLog('AI', 'Agenten-Orchester: $_activeAgentCount/12 aktiv');
  }

  // ════════════════════════════════════════════════════════════
  // UTILITY
  // ════════════════════════════════════════════════════════════
  String generateId() =>
      'BA${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

  String generateLogId() =>
      'SL${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

  /// Full reset — löscht ALLE gespeicherten Daten (nur für Debug/Reset)
  Future<void> factoryReset() async {
    _bankAccounts.clear();
    _systemLogs.clear();
    _researchLogs.clear();
    _transferPrefs = const TransferPrefs();
    _wsConfig = const WsEndpointConfig();
    _quantumScore = 847;
    _autonomousTradingEnabled = false;
    _selfHealEnabled = true;
    _activeAgentCount = 12;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kBankAccounts);
      await prefs.remove(_kTransferPrefs);
      await prefs.remove(_kSystemLogs);
      await prefs.remove(_kResearchLogs);
      await prefs.remove(_kQuantumScore);
      await prefs.remove(_kWsConfig);
      await prefs.remove(_kAutonomousTrading);
      await prefs.remove(_kSelfHealEnabled);
      await prefs.remove(_kAgentCount);
    } catch (_) {}
    notifyListeners();
  }
}
