/// HQMLL Quantum Trader – Persistence Service v38.0
/// Auto-Save: Settings, Bank Accounts, Transfer Prefs, Session State
/// ⚠️  NO REAL FINANCIAL DATA IS HARDCODED — user enters their own data
/// Data is stored locally on-device via SharedPreferences (encrypted at rest by OS)
/// Grigori Saks · 2025
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// ═══════════════════════════════════════════════════════════════
// PERSISTENCE SERVICE
// ═══════════════════════════════════════════════════════════════
class PersistenceService extends ChangeNotifier {
  static const _kBankAccounts = 'qt_bank_accounts_v2';
  static const _kTransferPrefs = 'qt_transfer_prefs_v2';
  static const _kLastTab = 'qt_last_tab';
  static const _kAutonomousTrading = 'qt_autonomous_trading';
  static const _kSelfHealEnabled = 'qt_self_heal';
  static const _kAgentCount = 'qt_agent_count';

  final List<BankAccount> _bankAccounts = [];
  TransferPrefs _transferPrefs = const TransferPrefs();
  int _lastTab = 0;
  bool _autonomousTradingEnabled = false;
  bool _selfHealEnabled = true;
  int _activeAgentCount = 12;

  bool _loaded = false;

  List<BankAccount> get bankAccounts => List.unmodifiable(_bankAccounts);
  BankAccount? get defaultAccount =>
      _bankAccounts.where((a) => a.isDefault).firstOrNull ??
      (_bankAccounts.isNotEmpty ? _bankAccounts.first : null);
  double get totalFiatBalance =>
      _bankAccounts.fold(0.0, (s, a) => s + a.balance);
  TransferPrefs get transferPrefs => _transferPrefs;
  int get lastTab => _lastTab;
  bool get autonomousTradingEnabled => _autonomousTradingEnabled;
  bool get selfHealEnabled => _selfHealEnabled;
  int get activeAgentCount => _activeAgentCount;
  bool get isLoaded => _loaded;

  PersistenceService() {
    _load();
  }

  // ── Load all persisted data ────────────────────────────────
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Bank accounts
      final raw = prefs.getString(_kBankAccounts);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        _bankAccounts.clear();
        for (final j in list) {
          try {
            _bankAccounts.add(BankAccount.fromJson(j as Map<String, dynamic>));
          } catch (_) {}
        }
      }

      // Transfer prefs
      final rawTp = prefs.getString(_kTransferPrefs);
      if (rawTp != null) {
        try {
          _transferPrefs = TransferPrefs.fromJson(
              jsonDecode(rawTp) as Map<String, dynamic>);
        } catch (_) {}
      }

      // Session state
      _lastTab = prefs.getInt(_kLastTab) ?? 0;
      _autonomousTradingEnabled = prefs.getBool(_kAutonomousTrading) ?? false;
      _selfHealEnabled = prefs.getBool(_kSelfHealEnabled) ?? true;
      _activeAgentCount = prefs.getInt(_kAgentCount) ?? 12;

      _loaded = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('PersistenceService._load error: $e');
      _loaded = true;
      notifyListeners();
    }
  }

  // ── Bank Account CRUD ──────────────────────────────────────
  Future<void> addBankAccount(BankAccount account) async {
    // If this is the first account, make it default
    final acc = _bankAccounts.isEmpty
        ? account.copyWith(isDefault: true)
        : account;
    _bankAccounts.add(acc);
    await _saveBankAccounts();
    notifyListeners();
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
    // If we removed the default, make first remaining default
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

  // ── Transfer Prefs ─────────────────────────────────────────
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

  // ── Session State ──────────────────────────────────────────
  Future<void> saveLastTab(int tab) async {
    _lastTab = tab;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_kLastTab, tab);
    } catch (_) {}
  }

  Future<void> setAutonomousTrading(bool v) async {
    _autonomousTradingEnabled = v;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_kAutonomousTrading, v);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setSelfHeal(bool v) async {
    _selfHealEnabled = v;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_kSelfHealEnabled, v);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setAgentCount(int count) async {
    _activeAgentCount = count.clamp(1, 12);
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_kAgentCount, _activeAgentCount);
    } catch (_) {}
    notifyListeners();
  }

  // ── Unique ID generator ────────────────────────────────────
  String generateId() =>
      'BA${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
}
