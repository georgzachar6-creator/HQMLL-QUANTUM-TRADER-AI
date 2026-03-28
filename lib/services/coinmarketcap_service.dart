/// HQMLL Quantum Trader – CoinMarketCap Service
/// CMC Pro API v1 Integration
/// Grigori Saks · 2025
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ── CMC Quote Model ──────────────────────────────────
class CmcQuote {
  final int id;
  final String symbol;
  final String name;
  final String slug;
  final double price;
  final double change1h;
  final double change24h;
  final double change7d;
  final double volume24h;
  final double marketCap;
  final int cmcRank;
  final DateTime updatedAt;

  const CmcQuote({
    required this.id, required this.symbol, required this.name,
    required this.slug, required this.price, required this.change1h,
    required this.change24h, required this.change7d, required this.volume24h,
    required this.marketCap, required this.cmcRank, required this.updatedAt,
  });

  String get iconUrl => 'https://s2.coinmarketcap.com/static/img/coins/64x64/$id.png';
  bool get isPositive24h => change24h >= 0;
  String get formattedPrice {
    if (price >= 1000) return '\$${price.toStringAsFixed(0)}';
    if (price >= 1) return '\$${price.toStringAsFixed(2)}';
    return '\$${price.toStringAsFixed(4)}';
  }
}

// ── CoinMarketCap Service ────────────────────────────
class CoinMarketCapService with ChangeNotifier {
  static final CoinMarketCapService _instance = CoinMarketCapService._internal();
  factory CoinMarketCapService() => _instance;
  CoinMarketCapService._internal() {
    _initSeedData();
  }

  // ── NOTE: In production, store API key securely (e.g. env var)
  // For demo purposes, we use simulated data with realistic values
  static const String _apiBase = 'https://pro-api.coinmarketcap.com/v1';

  final Map<String, CmcQuote> _quotes = {};
  final List<CmcQuote> _trending = [];
  bool _isLoaded = false;
  String? _lastError;
  Timer? _refreshTimer;
  final Random _rng = Random(99);

  Map<String, CmcQuote> get quotes => Map.unmodifiable(_quotes);
  List<CmcQuote> get trending => List.unmodifiable(_trending);
  bool get isLoaded => _isLoaded;
  String? get lastError => _lastError;
  List<CmcQuote> get topByMarketCap {
    final list = _quotes.values.toList();
    list.sort((a, b) => a.cmcRank.compareTo(b.cmcRank));
    return list;
  }

  // ── CMC IDs für bekannte Coins ─────────────────────
  static const Map<String, int> cmcIds = {
    'BTC': 1, 'ETH': 1027, 'BNB': 1839, 'SOL': 5426,
    'ADA': 2010, 'DOGE': 74, 'AVAX': 5805, 'DOT': 6636,
    'MATIC': 3890, 'LINK': 1975, 'XRP': 52, 'LTC': 2,
    'SHIB': 5994, 'UNI': 7083, 'ATOM': 3794, 'FIL': 2280,
  };

  void _initSeedData() {
    final seeds = [
      _makeSeed(1,    'BTC',   'Bitcoin',          'bitcoin',     67842.50, -0.12,  2.34, 8.45, 32.1e9, 1284e9,  1),
      _makeSeed(1027, 'ETH',   'Ethereum',         'ethereum',     3548.20,  0.43,  1.87, 5.21, 18.4e9,  426e9,  2),
      _makeSeed(1839, 'BNB',   'BNB',              'bnb',           598.30, -0.22,  0.94, 2.12,  1.8e9,   88e9,  3),
      _makeSeed(52,   'XRP',   'XRP',              'xrp',             0.524,  0.11,  0.78, 3.45,  1.1e9,   28e9,  4),
      _makeSeed(5426, 'SOL',   'Solana',           'solana',         182.40,  0.33, -0.52, 12.4,  3.2e9,   80e9,  5),
      _makeSeed(74,   'DOGE',  'Dogecoin',         'dogecoin',      0.0892, -0.55, -3.44, -8.1,  850e6,   12e9,  6),
      _makeSeed(2010, 'ADA',   'Cardano',          'cardano',        0.452, -0.18, -1.23,  0.45,  420e6, 15.8e9,  7),
      _makeSeed(5805, 'AVAX',  'Avalanche',        'avalanche',      36.80,  1.24,  4.56, 18.3,  580e6, 14.9e9,  8),
      _makeSeed(6636, 'DOT',   'Polkadot',         'polkadot',        7.24, -0.42, -0.88,  2.1,  240e6,  9.8e9,  9),
      _makeSeed(3890, 'MATIC', 'Polygon',          'polygon',         0.712,  0.88,  2.11,  6.7,  380e6,  7.1e9, 10),
      _makeSeed(1975, 'LINK',  'Chainlink',        'chainlink',       14.32,  0.92,  3.45, 10.2,  420e6,  8.2e9, 11),
      _makeSeed(2,    'LTC',   'Litecoin',         'litecoin',        82.40,  0.34,  1.22,  4.5,  380e6,  6.1e9, 12),
      _makeSeed(5994, 'SHIB',  'Shiba Inu',        'shiba-inu',  0.0000089,  2.14,  5.67, 22.1,  1.2e9,  5.2e9, 13),
      _makeSeed(7083, 'UNI',   'Uniswap',          'uniswap',         8.45,  1.11,  2.89,  7.3,  180e6,  5.1e9, 14),
      _makeSeed(3794, 'ATOM',  'Cosmos',           'cosmos',          9.12, -0.33,  1.45,  3.8,  220e6,  3.5e9, 15),
    ];

    for (final s in seeds) {
      _quotes[s.symbol] = s;
    }

    _trending.addAll(_quotes.values
        .where((q) => q.change24h > 2.0)
        .toList()
      ..sort((a, b) => b.change24h.compareTo(a.change24h)));

    _isLoaded = true;
    notifyListeners();
  }

  CmcQuote _makeSeed(int id, String sym, String name, String slug,
      double price, double ch1h, double ch24h, double ch7d,
      double vol, double mcap, int rank) {
    return CmcQuote(
      id: id, symbol: sym, name: name, slug: slug,
      price: price, change1h: ch1h, change24h: ch24h, change7d: ch7d,
      volume24h: vol, marketCap: mcap, cmcRank: rank,
      updatedAt: DateTime.now(),
    );
  }

  // ── Live CMC API Fetch ────────────────────────────
  // NOTE: Replace 'YOUR_CMC_API_KEY' with actual CMC Pro API key
  Future<void> fetchLiveData({String apiKey = ''}) async {
    if (apiKey.isEmpty) {
      _simulateLiveTick();
      return;
    }

    try {
      const symbols = 'BTC,ETH,BNB,XRP,SOL,DOGE,ADA,AVAX,DOT,MATIC,LINK,LTC,SHIB,UNI,ATOM';
      final url = '$_apiBase/cryptocurrency/quotes/latest?symbol=$symbols&convert=USD';

      final resp = await http.get(
        Uri.parse(url),
        headers: {
          'X-CMC_PRO_API_KEY': apiKey,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final quotesData = data['data'] as Map<String, dynamic>;

        quotesData.forEach((sym, info) {
          final q = info as Map<String, dynamic>;
          final usdData = (q['quote'] as Map<String, dynamic>?)?['USD'] as Map<String, dynamic>?;
          if (usdData == null) return;

          _quotes[sym] = CmcQuote(
            id: (q['id'] as num).toInt(),
            symbol: sym,
            name: q['name'] as String? ?? sym,
            slug: q['slug'] as String? ?? sym.toLowerCase(),
            price: (usdData['price'] as num?)?.toDouble() ?? 0,
            change1h: (usdData['percent_change_1h'] as num?)?.toDouble() ?? 0,
            change24h: (usdData['percent_change_24h'] as num?)?.toDouble() ?? 0,
            change7d: (usdData['percent_change_7d'] as num?)?.toDouble() ?? 0,
            volume24h: (usdData['volume_24h'] as num?)?.toDouble() ?? 0,
            marketCap: (usdData['market_cap'] as num?)?.toDouble() ?? 0,
            cmcRank: (q['cmc_rank'] as num?)?.toInt() ?? 999,
            updatedAt: DateTime.now(),
          );
        });

        _lastError = null;
        notifyListeners();
      }
    } catch (e) {
      _lastError = 'CMC: ${e.toString().substring(0, min(50, e.toString().length))}';
      if (kDebugMode) debugPrint('CMC error: $e');
      _simulateLiveTick(); // Fallback to simulation
    }
  }

  void _simulateLiveTick() {
    for (final sym in _quotes.keys) {
      final q = _quotes[sym]!;
      final noise = (_rng.nextDouble() - 0.499) * q.price * 0.001;
      final newPrice = (q.price + noise).clamp(q.price * 0.95, q.price * 1.05);
      _quotes[sym] = CmcQuote(
        id: q.id, symbol: q.symbol, name: q.name, slug: q.slug,
        price: newPrice, change1h: q.change1h, change24h: q.change24h,
        change7d: q.change7d, volume24h: q.volume24h, marketCap: q.marketCap,
        cmcRank: q.cmcRank, updatedAt: DateTime.now(),
      );
    }
    notifyListeners();
  }

  void startAutoRefresh({String apiKey = ''}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchLiveData(apiKey: apiKey);
    });
  }

  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── Global Market Stats ───────────────────────────
  double get totalMarketCap => _quotes.values.fold(0, (s, q) => s + q.marketCap);
  double get btcDominance {
    final btc = _quotes['BTC']?.marketCap ?? 0;
    final total = totalMarketCap;
    return total > 0 ? (btc / total) * 100 : 0;
  }
  int get fearGreedIndex {
    final btcChange = _quotes['BTC']?.change24h ?? 0;
    final ethChange = _quotes['ETH']?.change24h ?? 0;
    final avg = (btcChange + ethChange) / 2;
    return (50 + avg * 3).clamp(0, 100).round();
  }
  String get fearGreedLabel {
    final idx = fearGreedIndex;
    if (idx < 20) return 'Extreme Angst';
    if (idx < 40) return 'Angst';
    if (idx < 60) return 'Neutral';
    if (idx < 80) return 'Gier';
    return 'Extreme Gier';
  }
}
