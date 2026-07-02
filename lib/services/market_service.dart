// HQMLL Quantum Trader – Market Service v41.0
// Live OHLCV · Orderbook · Market Stats · Watchlist persistent
// Auto-Save: watchlist, alerts, settings after every change
// Grigori Saks · 2025
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════
// MARKET MODELS
// ══════════════════════════════════════════════════════
class MarketAlert {
  final String id;
  final String symbol;
  final String type;         // 'above' | 'below' | 'change_pct'
  final double targetValue;
  final bool   isActive;
  final bool   triggered;
  final DateTime createdAt;
  final DateTime? triggeredAt;

  const MarketAlert({
    required this.id, required this.symbol, required this.type,
    required this.targetValue, required this.isActive,
    required this.triggered, required this.createdAt, this.triggeredAt,
  });

  String get typeLabel => type == 'above' ? '≥' : type == 'below' ? '≤' : '±%';

  Map<String, dynamic> toJson() => {
    'id': id, 'symbol': symbol, 'type': type, 'targetValue': targetValue,
    'isActive': isActive, 'triggered': triggered,
    'createdAt': createdAt.toIso8601String(),
    'triggeredAt': triggeredAt?.toIso8601String(),
  };

  factory MarketAlert.fromJson(Map<String, dynamic> j) => MarketAlert(
    id: j['id'] as String? ?? '',
    symbol: j['symbol'] as String? ?? '',
    type: j['type'] as String? ?? 'above',
    targetValue: (j['targetValue'] as num?)?.toDouble() ?? 0.0,
    isActive: j['isActive'] as bool? ?? true,
    triggered: j['triggered'] as bool? ?? false,
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    triggeredAt: j['triggeredAt'] != null
        ? DateTime.tryParse(j['triggeredAt'] as String) : null,
  );

  MarketAlert copyWith({bool? isActive, bool? triggered, DateTime? triggeredAt}) =>
    MarketAlert(
      id: id, symbol: symbol, type: type, targetValue: targetValue,
      isActive: isActive ?? this.isActive, triggered: triggered ?? this.triggered,
      createdAt: createdAt, triggeredAt: triggeredAt ?? this.triggeredAt,
    );
}

class WatchlistEntry {
  final String symbol;
  final String name;
  final int    order;
  final bool   showChart;
  final DateTime addedAt;

  const WatchlistEntry({
    required this.symbol, required this.name,
    this.order = 0, this.showChart = true, required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'symbol': symbol, 'name': name, 'order': order, 'showChart': showChart,
    'addedAt': addedAt.toIso8601String(),
  };

  factory WatchlistEntry.fromJson(Map<String, dynamic> j) => WatchlistEntry(
    symbol: j['symbol'] as String? ?? '',
    name: j['name'] as String? ?? '',
    order: j['order'] as int? ?? 0,
    showChart: j['showChart'] as bool? ?? true,
    addedAt: DateTime.tryParse(j['addedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class MarketSettings {
  final String defaultTimeframe;   // 1m | 5m | 15m | 1h | 4h | 1d
  final String defaultChartType;   // candlestick | line | bar
  final bool   showVolume;
  final bool   showIndicators;
  final int    decimalPrecision;
  final String defaultQuoteCurrency; // USDT | USD | BTC | ETH

  const MarketSettings({
    this.defaultTimeframe = '1h',
    this.defaultChartType = 'candlestick',
    this.showVolume = true,
    this.showIndicators = true,
    this.decimalPrecision = 2,
    this.defaultQuoteCurrency = 'USDT',
  });

  Map<String, dynamic> toJson() => {
    'defaultTimeframe': defaultTimeframe,
    'defaultChartType': defaultChartType,
    'showVolume': showVolume,
    'showIndicators': showIndicators,
    'decimalPrecision': decimalPrecision,
    'defaultQuoteCurrency': defaultQuoteCurrency,
  };

  factory MarketSettings.fromJson(Map<String, dynamic> j) => MarketSettings(
    defaultTimeframe: j['defaultTimeframe'] as String? ?? '1h',
    defaultChartType: j['defaultChartType'] as String? ?? 'candlestick',
    showVolume: j['showVolume'] as bool? ?? true,
    showIndicators: j['showIndicators'] as bool? ?? true,
    decimalPrecision: j['decimalPrecision'] as int? ?? 2,
    defaultQuoteCurrency: j['defaultQuoteCurrency'] as String? ?? 'USDT',
  );

  MarketSettings copyWith({
    String? defaultTimeframe, String? defaultChartType, bool? showVolume,
    bool? showIndicators, int? decimalPrecision, String? defaultQuoteCurrency,
  }) => MarketSettings(
    defaultTimeframe: defaultTimeframe ?? this.defaultTimeframe,
    defaultChartType: defaultChartType ?? this.defaultChartType,
    showVolume: showVolume ?? this.showVolume,
    showIndicators: showIndicators ?? this.showIndicators,
    decimalPrecision: decimalPrecision ?? this.decimalPrecision,
    defaultQuoteCurrency: defaultQuoteCurrency ?? this.defaultQuoteCurrency,
  );
}

// ══════════════════════════════════════════════════════
// MARKET SERVICE
// ══════════════════════════════════════════════════════
class MarketService extends ChangeNotifier {
  static const _kWatchlist = 'qt_watchlist_v41';
  static const _kAlerts    = 'qt_alerts_v41';
  static const _kSettings  = 'qt_market_settings_v41';
  static const _kSelectedPair = 'qt_selected_pair_v41';
  static const _kFavorites = 'qt_market_favorites_v41';

  final List<WatchlistEntry> _watchlist = [];
  final List<MarketAlert>    _alerts    = [];
  final Set<String>          _favorites = {};
  MarketSettings  _settings     = const MarketSettings();
  String          _selectedPair = 'BTC/USDT';
  bool            _loaded       = false;

  List<WatchlistEntry> get watchlist  => List.unmodifiable(_watchlist);
  List<MarketAlert>    get alerts     => List.unmodifiable(_alerts);
  List<MarketAlert>    get activeAlerts => _alerts.where((a) => a.isActive && !a.triggered).toList();
  Set<String>          get favorites  => Set.unmodifiable(_favorites);
  MarketSettings       get settings   => _settings;
  String               get selectedPair => _selectedPair;
  bool                 get isLoaded   => _loaded;

  // Default watchlist — major coins
  static const _defaultWatchlist = [
    ('BTC',  'Bitcoin'),   ('ETH',  'Ethereum'),  ('SOL',  'Solana'),
    ('BNB',  'BNB'),       ('XRP',  'XRP'),       ('ADA',  'Cardano'),
    ('AVAX', 'Avalanche'), ('MATIC','Polygon'),   ('DOT',  'Polkadot'),
    ('LINK', 'Chainlink'), ('UNI',  'Uniswap'),   ('ATOM', 'Cosmos'),
  ];

  MarketService() { _load(); }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final rawW = prefs.getString(_kWatchlist);
      if (rawW != null) {
        final list = jsonDecode(rawW) as List<dynamic>;
        _watchlist.clear();
        for (final j in list) {
          try { _watchlist.add(WatchlistEntry.fromJson(j as Map<String, dynamic>)); }
          catch (_) {}
        }
      } else {
        // Seed default watchlist
        for (int i = 0; i < _defaultWatchlist.length; i++) {
          final (sym, name) = _defaultWatchlist[i];
          _watchlist.add(WatchlistEntry(
            symbol: sym, name: name, order: i, addedAt: DateTime.now()));
        }
      }

      final rawA = prefs.getString(_kAlerts);
      if (rawA != null) {
        final list = jsonDecode(rawA) as List<dynamic>;
        _alerts.clear();
        for (final j in list) {
          try { _alerts.add(MarketAlert.fromJson(j as Map<String, dynamic>)); }
          catch (_) {}
        }
      }

      final rawS = prefs.getString(_kSettings);
      if (rawS != null) {
        try { _settings = MarketSettings.fromJson(jsonDecode(rawS) as Map<String, dynamic>); }
        catch (_) {}
      }

      final rawF = prefs.getString(_kFavorites);
      if (rawF != null) {
        try { _favorites.addAll((jsonDecode(rawF) as List<dynamic>).cast<String>()); }
        catch (_) {}
      }

      _selectedPair = prefs.getString(_kSelectedPair) ?? 'BTC/USDT';
      _loaded = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('MarketService._load error: $e');
      _loaded = true;
      notifyListeners();
    }
  }

  // ── Watchlist ─────────────────────────────────────────
  Future<void> addToWatchlist(String symbol, String name) async {
    if (_watchlist.any((w) => w.symbol == symbol)) return;
    _watchlist.add(WatchlistEntry(
      symbol: symbol, name: name, order: _watchlist.length, addedAt: DateTime.now()));
    await _saveWatchlist();
    notifyListeners();
  }

  Future<void> removeFromWatchlist(String symbol) async {
    _watchlist.removeWhere((w) => w.symbol == symbol);
    await _saveWatchlist();
    notifyListeners();
  }

  Future<void> reorderWatchlist(int oldIdx, int newIdx) async {
    if (oldIdx < newIdx) newIdx--;
    final item = _watchlist.removeAt(oldIdx);
    _watchlist.insert(newIdx, item);
    for (int i = 0; i < _watchlist.length; i++) {
      _watchlist[i] = WatchlistEntry(
        symbol: _watchlist[i].symbol, name: _watchlist[i].name,
        order: i, showChart: _watchlist[i].showChart, addedAt: _watchlist[i].addedAt);
    }
    await _saveWatchlist();
    notifyListeners();
  }

  // ── Favorites ──────────────────────────────────────────
  Future<void> toggleFavorite(String symbol) async {
    if (_favorites.contains(symbol)) { _favorites.remove(symbol); }
    else { _favorites.add(symbol); }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kFavorites, jsonEncode(_favorites.toList()));
    } catch (_) {}
    notifyListeners();
  }

  // ── Alerts ────────────────────────────────────────────
  Future<void> addAlert(MarketAlert alert) async {
    _alerts.add(alert);
    await _saveAlerts();
    notifyListeners();
  }

  Future<void> checkAlerts(Map<String, double> prices) async {
    bool changed = false;
    for (int i = 0; i < _alerts.length; i++) {
      final a = _alerts[i];
      if (!a.isActive || a.triggered) continue;
      final price = prices[a.symbol] ?? 0.0;
      if (price <= 0) continue;
      bool hit = false;
      if (a.type == 'above' && price >= a.targetValue) hit = true;
      if (a.type == 'below' && price <= a.targetValue) hit = true;
      if (hit) {
        _alerts[i] = a.copyWith(triggered: true, triggeredAt: DateTime.now());
        changed = true;
      }
    }
    if (changed) { await _saveAlerts(); notifyListeners(); }
  }

  Future<void> dismissAlert(String id) async {
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      _alerts[idx] = _alerts[idx].copyWith(isActive: false);
      await _saveAlerts();
      notifyListeners();
    }
  }

  // ── Settings ──────────────────────────────────────────
  Future<void> updateSettings(MarketSettings s) async {
    _settings = s;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSettings, jsonEncode(s.toJson()));
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setSelectedPair(String pair) async {
    _selectedPair = pair;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSelectedPair, pair);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveWatchlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kWatchlist,
          jsonEncode(_watchlist.map((w) => w.toJson()).toList()));
    } catch (e) { if (kDebugMode) debugPrint('MarketService._saveWatchlist: $e'); }
  }

  Future<void> _saveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAlerts,
          jsonEncode(_alerts.map((a) => a.toJson()).toList()));
    } catch (e) { if (kDebugMode) debugPrint('MarketService._saveAlerts: $e'); }
  }

  /// Public forceSave — called by AutoSaveService
  Future<void> forceSave() async {
    await _saveWatchlist();
    await _saveAlerts();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSettings, jsonEncode(_settings.toJson()));
      await prefs.setString(_kFavorites, jsonEncode(_favorites.toList()));
    } catch (_) {}
  }

  String generateAlertId() =>
      'ALT${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
}
