// HQMLL Quantum Trader – Wallet Service v41.0
// Manages crypto wallet balances, addresses, transactions
// Auto-Save: every balance/address change persisted immediately
// Grigori Saks · 2025
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════
// WALLET MODELS
// ══════════════════════════════════════════════════════
enum WalletType { hot, cold, hardware, exchange, defi }
enum NetworkType { bitcoin, ethereum, solana, bnbchain, polygon, avalanche, cosmos, polkadot }

class WalletAddress {
  final String id;
  final String label;
  final String address;
  final NetworkType network;
  final bool isOwn;
  final DateTime addedAt;

  const WalletAddress({
    required this.id, required this.label, required this.address,
    required this.network, required this.isOwn, required this.addedAt,
  });

  String get networkLabel => network.name.toUpperCase();
  String get shortAddress => address.length > 12
      ? '${address.substring(0, 6)}...${address.substring(address.length - 4)}'
      : address;

  Map<String, dynamic> toJson() => {
    'id': id, 'label': label, 'address': address,
    'network': network.name, 'isOwn': isOwn,
    'addedAt': addedAt.toIso8601String(),
  };

  factory WalletAddress.fromJson(Map<String, dynamic> j) => WalletAddress(
    id: j['id'] as String? ?? '',
    label: j['label'] as String? ?? '',
    address: j['address'] as String? ?? '',
    network: NetworkType.values.firstWhere(
      (n) => n.name == j['network'], orElse: () => NetworkType.ethereum),
    isOwn: j['isOwn'] as bool? ?? false,
    addedAt: DateTime.tryParse(j['addedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class WalletBalance {
  final String symbol;
  final double amount;
  final double usdValue;
  final DateTime updatedAt;

  const WalletBalance({
    required this.symbol, required this.amount,
    required this.usdValue, required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'symbol': symbol, 'amount': amount, 'usdValue': usdValue,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory WalletBalance.fromJson(Map<String, dynamic> j) => WalletBalance(
    symbol: j['symbol'] as String? ?? '',
    amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
    usdValue: (j['usdValue'] as num?)?.toDouble() ?? 0.0,
    updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class WalletPortfolio {
  final String id;
  final String name;
  final WalletType type;
  final Map<String, WalletBalance> balances; // symbol → balance
  final List<WalletAddress> addresses;
  final bool isDefault;
  final DateTime createdAt;

  const WalletPortfolio({
    required this.id, required this.name, required this.type,
    required this.balances, required this.addresses,
    required this.isDefault, required this.createdAt,
  });

  double get totalUsd => balances.values.fold(0.0, (s, b) => s + b.usdValue);

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'type': type.name,
    'balances': balances.map((k, v) => MapEntry(k, v.toJson())),
    'addresses': addresses.map((a) => a.toJson()).toList(),
    'isDefault': isDefault, 'createdAt': createdAt.toIso8601String(),
  };

  factory WalletPortfolio.fromJson(Map<String, dynamic> j) => WalletPortfolio(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? 'Wallet',
    type: WalletType.values.firstWhere(
      (t) => t.name == j['type'], orElse: () => WalletType.hot),
    balances: (j['balances'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, WalletBalance.fromJson(v as Map<String, dynamic>))),
    addresses: (j['addresses'] as List<dynamic>? ?? [])
        .map((a) => WalletAddress.fromJson(a as Map<String, dynamic>)).toList(),
    isDefault: j['isDefault'] as bool? ?? false,
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  WalletPortfolio copyWith({
    String? name, WalletType? type,
    Map<String, WalletBalance>? balances,
    List<WalletAddress>? addresses, bool? isDefault,
  }) => WalletPortfolio(
    id: id, name: name ?? this.name, type: type ?? this.type,
    balances: balances ?? this.balances,
    addresses: addresses ?? this.addresses,
    isDefault: isDefault ?? this.isDefault, createdAt: createdAt,
  );
}

// ══════════════════════════════════════════════════════
// WALLET SERVICE
// ══════════════════════════════════════════════════════
class WalletService extends ChangeNotifier {
  static const _kWallets    = 'qt_wallets_v41';
  static const _kAddressBook = 'qt_address_book_v41';
  static const _kLastWallet  = 'qt_last_wallet_v41';

  final List<WalletPortfolio> _wallets = [];
  final List<WalletAddress>   _addressBook = [];
  String? _activeWalletId;
  bool _loaded = false;

  List<WalletPortfolio> get wallets      => List.unmodifiable(_wallets);
  List<WalletAddress>   get addressBook  => List.unmodifiable(_addressBook);
  bool                  get isLoaded     => _loaded;

  WalletPortfolio? get activeWallet =>
      _wallets.where((w) => w.id == _activeWalletId).firstOrNull ??
      (_wallets.isNotEmpty ? _wallets.first : null);

  double get totalPortfolioUsd =>
      _wallets.fold(0.0, (s, w) => s + w.totalUsd);

  WalletService() { _load(); }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawW = prefs.getString(_kWallets);
      if (rawW != null) {
        final list = jsonDecode(rawW) as List<dynamic>;
        _wallets.clear();
        for (final j in list) {
          try { _wallets.add(WalletPortfolio.fromJson(j as Map<String, dynamic>)); }
          catch (_) {}
        }
      }
      final rawAb = prefs.getString(_kAddressBook);
      if (rawAb != null) {
        final list = jsonDecode(rawAb) as List<dynamic>;
        _addressBook.clear();
        for (final j in list) {
          try { _addressBook.add(WalletAddress.fromJson(j as Map<String, dynamic>)); }
          catch (_) {}
        }
      }
      _activeWalletId = prefs.getString(_kLastWallet);
      if (_wallets.isEmpty) _createDefaultWallet();
      _loaded = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('WalletService._load error: $e');
      _createDefaultWallet();
      _loaded = true;
      notifyListeners();
    }
  }

  void _createDefaultWallet() {
    final w = WalletPortfolio(
      id: 'W${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      name: 'Quantum Wallet',
      type: WalletType.hot,
      balances: {
        'BTC': WalletBalance(symbol: 'BTC', amount: 0.0, usdValue: 0.0, updatedAt: DateTime.now()),
        'ETH': WalletBalance(symbol: 'ETH', amount: 0.0, usdValue: 0.0, updatedAt: DateTime.now()),
        'SOL': WalletBalance(symbol: 'SOL', amount: 0.0, usdValue: 0.0, updatedAt: DateTime.now()),
        'USDT': WalletBalance(symbol: 'USDT', amount: 0.0, usdValue: 0.0, updatedAt: DateTime.now()),
      },
      addresses: [],
      isDefault: true,
      createdAt: DateTime.now(),
    );
    _wallets.add(w);
    _activeWalletId = w.id;
  }

  // ── CRUD ──────────────────────────────────────────────
  Future<void> addWallet(WalletPortfolio wallet) async {
    _wallets.add(wallet);
    if (_wallets.length == 1 || wallet.isDefault) _activeWalletId = wallet.id;
    await _saveWallets();
    notifyListeners();
  }

  Future<void> updateBalance(String walletId, String symbol, double amount, double usdValue) async {
    final idx = _wallets.indexWhere((w) => w.id == walletId);
    if (idx >= 0) {
      final updated = Map<String, WalletBalance>.from(_wallets[idx].balances);
      updated[symbol] = WalletBalance(
        symbol: symbol, amount: amount, usdValue: usdValue, updatedAt: DateTime.now());
      _wallets[idx] = _wallets[idx].copyWith(balances: updated);
      await _saveWallets();
      notifyListeners();
    }
  }

  Future<void> updateAllBalancesFromPrices(Map<String, double> prices) async {
    bool changed = false;
    for (int i = 0; i < _wallets.length; i++) {
      final updated = Map<String, WalletBalance>.from(_wallets[i].balances);
      for (final sym in updated.keys) {
        final price = prices[sym] ?? 0.0;
        if (price > 0) {
          final old = updated[sym]!;
          updated[sym] = WalletBalance(
            symbol: sym, amount: old.amount,
            usdValue: old.amount * price, updatedAt: DateTime.now());
          changed = true;
        }
      }
      if (changed) _wallets[i] = _wallets[i].copyWith(balances: updated);
    }
    if (changed) { await _saveWallets(); notifyListeners(); }
  }

  Future<void> setActiveWallet(String id) async {
    _activeWalletId = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastWallet, id);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> addToAddressBook(WalletAddress addr) async {
    _addressBook.add(addr);
    await _saveAddressBook();
    notifyListeners();
  }

  Future<void> removeFromAddressBook(String id) async {
    _addressBook.removeWhere((a) => a.id == id);
    await _saveAddressBook();
    notifyListeners();
  }

  Future<void> _saveWallets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kWallets,
          jsonEncode(_wallets.map((w) => w.toJson()).toList()));
    } catch (e) { if (kDebugMode) debugPrint('WalletService._saveWallets: $e'); }
  }

  Future<void> _saveAddressBook() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAddressBook,
          jsonEncode(_addressBook.map((a) => a.toJson()).toList()));
    } catch (e) { if (kDebugMode) debugPrint('WalletService._saveAddressBook: $e'); }
  }

  /// Public forceSave — called by AutoSaveService
  Future<void> forceSave() async {
    await _saveWallets();
    await _saveAddressBook();
  }

  String generateId() =>
      'W${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
}
