// HQMLL Quantum Trader – Payment Service v41.0
// Bank Transfers · SEPA · Crypto Payments · Auto-Save after every change
// All transfer data saved immediately — survives app restart
// Grigori Saks · 2025
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════
// PAYMENT MODELS
// ══════════════════════════════════════════════════════
enum PaymentType { sepa, swift, cryptoTransfer, internalTransfer, cardPayment }
enum PaymentStatus { draft, pending, processing, completed, failed, cancelled, refunded }

class PaymentEntry {
  final String id;
  final PaymentType type;
  final PaymentStatus status;
  final String fromAccount;   // IBAN or wallet address
  final String toAccount;     // IBAN or wallet address
  final String toName;        // Recipient name
  final double amount;
  final String currency;      // EUR, USD, BTC, ETH...
  final double amountUsd;     // USD equivalent at time of payment
  final double fee;
  final String? reference;    // SEPA Verwendungszweck / TX hash
  final String? bankName;
  final String? note;
  final DateTime createdAt;
  final DateTime? executedAt;
  final bool isRecurring;
  final String? recurringInterval; // daily/weekly/monthly

  const PaymentEntry({
    required this.id, required this.type, required this.status,
    required this.fromAccount, required this.toAccount, required this.toName,
    required this.amount, required this.currency, required this.amountUsd,
    required this.fee, this.reference, this.bankName, this.note,
    required this.createdAt, this.executedAt,
    this.isRecurring = false, this.recurringInterval,
  });

  String get typeLabel => type.name.toUpperCase();
  String get statusLabel => status.name.toUpperCase();
  String get shortToAccount => toAccount.length > 12
      ? '${toAccount.substring(0, 6)}...${toAccount.substring(toAccount.length - 4)}'
      : toAccount;
  bool get isCompleted => status == PaymentStatus.completed;
  bool get isCrypto => !['EUR','USD','GBP','JPY','CHF'].contains(currency);

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type.name, 'status': status.name,
    'fromAccount': fromAccount, 'toAccount': toAccount, 'toName': toName,
    'amount': amount, 'currency': currency, 'amountUsd': amountUsd, 'fee': fee,
    'reference': reference, 'bankName': bankName, 'note': note,
    'createdAt': createdAt.toIso8601String(),
    'executedAt': executedAt?.toIso8601String(),
    'isRecurring': isRecurring, 'recurringInterval': recurringInterval,
  };

  factory PaymentEntry.fromJson(Map<String, dynamic> j) => PaymentEntry(
    id: j['id'] as String? ?? '',
    type: PaymentType.values.firstWhere((t) => t.name == j['type'],
        orElse: () => PaymentType.sepa),
    status: PaymentStatus.values.firstWhere((s) => s.name == j['status'],
        orElse: () => PaymentStatus.pending),
    fromAccount: j['fromAccount'] as String? ?? '',
    toAccount: j['toAccount'] as String? ?? '',
    toName: j['toName'] as String? ?? '',
    amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
    currency: j['currency'] as String? ?? 'EUR',
    amountUsd: (j['amountUsd'] as num?)?.toDouble() ?? 0.0,
    fee: (j['fee'] as num?)?.toDouble() ?? 0.0,
    reference: j['reference'] as String?,
    bankName: j['bankName'] as String?,
    note: j['note'] as String?,
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    executedAt: j['executedAt'] != null
        ? DateTime.tryParse(j['executedAt'] as String) : null,
    isRecurring: j['isRecurring'] as bool? ?? false,
    recurringInterval: j['recurringInterval'] as String?,
  );
}

// ── Saved Recipient (Adressbuch) ──────────────────────
class PaymentRecipient {
  final String id;
  final String name;
  final String account;     // IBAN or address
  final String currency;
  final String? bankName;
  final String? bic;
  final bool isFavorite;
  final DateTime addedAt;

  const PaymentRecipient({
    required this.id, required this.name, required this.account,
    required this.currency, this.bankName, this.bic,
    this.isFavorite = false, required this.addedAt,
  });

  String get shortAccount => account.length > 12
      ? '${account.substring(0, 6)}...${account.substring(account.length - 4)}'
      : account;

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'account': account, 'currency': currency,
    'bankName': bankName, 'bic': bic, 'isFavorite': isFavorite,
    'addedAt': addedAt.toIso8601String(),
  };

  factory PaymentRecipient.fromJson(Map<String, dynamic> j) => PaymentRecipient(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    account: j['account'] as String? ?? '',
    currency: j['currency'] as String? ?? 'EUR',
    bankName: j['bankName'] as String?,
    bic: j['bic'] as String?,
    isFavorite: j['isFavorite'] as bool? ?? false,
    addedAt: DateTime.tryParse(j['addedAt'] as String? ?? '') ?? DateTime.now(),
  );

  PaymentRecipient copyWith({bool? isFavorite}) => PaymentRecipient(
    id: id, name: name, account: account, currency: currency,
    bankName: bankName, bic: bic,
    isFavorite: isFavorite ?? this.isFavorite, addedAt: addedAt,
  );
}

// ══════════════════════════════════════════════════════
// PAYMENT SERVICE
// ══════════════════════════════════════════════════════
class PaymentService extends ChangeNotifier {
  static const _kPayments    = 'qt_payments_v41';
  static const _kRecipients  = 'qt_recipients_v41';
  static const _kDraftPayment = 'qt_draft_payment_v41'; // ignore: unused_field
  static const _kLastFromAcc  = 'qt_last_from_acc_v41';
  static const _kLastCurrency = 'qt_last_currency_v41';
  static const _kLastAmount   = 'qt_last_amount_v41';
  static const _kLastNetwork  = 'qt_last_network_v41';

  final List<PaymentEntry>    _payments   = [];
  final List<PaymentRecipient> _recipients = [];
  String _lastFromAccount = '';
  String _lastCurrency    = 'EUR';
  double _lastAmount      = 0.0;
  String _lastNetwork     = 'Ethereum';
  bool   _loaded          = false;

  List<PaymentEntry>     get payments        => List.unmodifiable(_payments);
  List<PaymentRecipient> get recipients       => List.unmodifiable(_recipients);
  List<PaymentRecipient> get favoriteRecipients =>
      _recipients.where((r) => r.isFavorite).toList();
  String  get lastFromAccount => _lastFromAccount;
  String  get lastCurrency    => _lastCurrency;
  double  get lastAmount      => _lastAmount;
  String  get lastNetwork     => _lastNetwork;
  bool    get isLoaded        => _loaded;

  double get totalOutgoing => _payments
      .where((p) => p.isCompleted && p.amountUsd > 0)
      .fold(0.0, (s, p) => s + p.amountUsd);

  List<PaymentEntry> getRecent({int limit = 20}) {
    final sorted = List<PaymentEntry>.from(_payments)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  PaymentService() { _load(); }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawP = prefs.getString(_kPayments);
      if (rawP != null) {
        final list = jsonDecode(rawP) as List<dynamic>;
        _payments.clear();
        for (final j in list) {
          try { _payments.add(PaymentEntry.fromJson(j as Map<String, dynamic>)); }
          catch (_) {}
        }
      }
      final rawR = prefs.getString(_kRecipients);
      if (rawR != null) {
        final list = jsonDecode(rawR) as List<dynamic>;
        _recipients.clear();
        for (final j in list) {
          try { _recipients.add(PaymentRecipient.fromJson(j as Map<String, dynamic>)); }
          catch (_) {}
        }
      }
      _lastFromAccount = prefs.getString(_kLastFromAcc)   ?? '';
      _lastCurrency    = prefs.getString(_kLastCurrency)  ?? 'EUR';
      _lastAmount      = prefs.getDouble(_kLastAmount)    ?? 0.0;
      _lastNetwork     = prefs.getString(_kLastNetwork)   ?? 'Ethereum';
      _loaded = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('PaymentService._load error: $e');
      _loaded = true;
      notifyListeners();
    }
  }

  // ── Payment CRUD ──────────────────────────────────────
  Future<PaymentEntry> createPayment({
    required PaymentType type,
    required String fromAccount, required String toAccount, required String toName,
    required double amount, required String currency,
    double amountUsd = 0.0, double fee = 0.0,
    String? reference, String? bankName, String? note,
    bool isRecurring = false, String? recurringInterval,
  }) async {
    final entry = PaymentEntry(
      id: 'PAY${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      type: type, status: PaymentStatus.pending,
      fromAccount: fromAccount, toAccount: toAccount, toName: toName,
      amount: amount, currency: currency, amountUsd: amountUsd, fee: fee,
      reference: reference, bankName: bankName, note: note,
      createdAt: DateTime.now(),
      isRecurring: isRecurring, recurringInterval: recurringInterval,
    );
    _payments.add(entry);
    // Auto-save last-used fields
    await _savePayments();
    await saveTransferDefaults(
      fromAccount: fromAccount, currency: currency,
      amount: amount, network: lastNetwork,
    );
    notifyListeners();
    return entry;
  }

  Future<void> updatePaymentStatus(String id, PaymentStatus status,
      {DateTime? executedAt}) async {
    final idx = _payments.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      final old = _payments[idx];
      _payments[idx] = PaymentEntry(
        id: old.id, type: old.type, status: status,
        fromAccount: old.fromAccount, toAccount: old.toAccount, toName: old.toName,
        amount: old.amount, currency: old.currency, amountUsd: old.amountUsd, fee: old.fee,
        reference: old.reference, bankName: old.bankName, note: old.note,
        createdAt: old.createdAt, executedAt: executedAt ?? old.executedAt,
        isRecurring: old.isRecurring, recurringInterval: old.recurringInterval,
      );
      await _savePayments();
      notifyListeners();
    }
  }

  // ── Recipient CRUD ─────────────────────────────────────
  Future<void> addRecipient(PaymentRecipient recipient) async {
    _recipients.add(recipient);
    await _saveRecipients();
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final idx = _recipients.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      _recipients[idx] = _recipients[idx].copyWith(
          isFavorite: !_recipients[idx].isFavorite);
      await _saveRecipients();
      notifyListeners();
    }
  }

  Future<void> removeRecipient(String id) async {
    _recipients.removeWhere((r) => r.id == id);
    await _saveRecipients();
    notifyListeners();
  }

  // ── Auto-Save Transfer Defaults ─────────────────────────
  Future<void> saveTransferDefaults({
    String? fromAccount, String? currency, double? amount, String? network,
  }) async {
    if (fromAccount != null) _lastFromAccount = fromAccount;
    if (currency    != null) _lastCurrency    = currency;
    if (amount      != null && amount > 0) _lastAmount = amount;
    if (network     != null) _lastNetwork     = network;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (fromAccount != null) await prefs.setString(_kLastFromAcc, _lastFromAccount);
      if (currency    != null) await prefs.setString(_kLastCurrency, _lastCurrency);
      if (amount      != null && amount > 0) await prefs.setDouble(_kLastAmount, _lastAmount);
      if (network     != null) await prefs.setString(_kLastNetwork, _lastNetwork);
    } catch (_) {}
  }

  Future<void> _savePayments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep last 200 payments
      final toSave = _payments.length > 200
          ? _payments.sublist(_payments.length - 200) : _payments;
      await prefs.setString(_kPayments,
          jsonEncode(toSave.map((p) => p.toJson()).toList()));
    } catch (e) { if (kDebugMode) debugPrint('PaymentService._savePayments: $e'); }
  }

  Future<void> _saveRecipients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRecipients,
          jsonEncode(_recipients.map((r) => r.toJson()).toList()));
    } catch (e) { if (kDebugMode) debugPrint('PaymentService._saveRecipients: $e'); }
  }

  /// Public forceSave — called by AutoSaveService
  Future<void> forceSave() async {
    await _savePayments();
    await _saveRecipients();
  }

  String generateId() =>
      'PAY${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
}
