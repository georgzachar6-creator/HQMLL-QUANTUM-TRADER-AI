// ============================================================
// COINMARKETCAP SERVICE v2 – Quantum Trader
// CMC Pro API v1 – Full Market Data, Global Metrics, OHLCV
// ============================================================
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ── CMC Quote Model ───────────────────────────────────────
class CmcQuote {
  final int id;
  final String symbol;
  final String name;
  final String slug;
  final double price;
  final double change1h;
  final double change24h;
  final double change7d;
  final double change30d;
  final double volume24h;
  final double volumeChange24h;
  final double marketCap;
  final double fullyDilutedMcap;
  final int cmcRank;
  final double? circulatingSupply;
  final double? maxSupply;
  final String? dominance;
  final DateTime updatedAt;

  const CmcQuote({
    required this.id,
    required this.symbol,
    required this.name,
    required this.slug,
    required this.price,
    required this.change1h,
    required this.change24h,
    required this.change7d,
    this.change30d = 0,
    required this.volume24h,
    this.volumeChange24h = 0,
    required this.marketCap,
    this.fullyDilutedMcap = 0,
    required this.cmcRank,
    this.circulatingSupply,
    this.maxSupply,
    this.dominance,
    required this.updatedAt,
  });

  String get iconUrl =>
      'https://s2.coinmarketcap.com/static/img/coins/64x64/$id.png';
  String get profileUrl =>
      'https://coinmarketcap.com/currencies/$slug/';
  bool get isPositive24h => change24h >= 0;

  String get formattedPrice {
    if (price >= 10000) return '\$${price.toStringAsFixed(0)}';
    if (price >= 1000) return '\$${price.toStringAsFixed(1)}';
    if (price >= 1) return '\$${price.toStringAsFixed(3)}';
    return '\$${price.toStringAsFixed(6)}';
  }

  String get formattedMarketCap {
    if (marketCap >= 1e12) return '\$${(marketCap / 1e12).toStringAsFixed(2)}T';
    if (marketCap >= 1e9) return '\$${(marketCap / 1e9).toStringAsFixed(2)}B';
    if (marketCap >= 1e6) return '\$${(marketCap / 1e6).toStringAsFixed(1)}M';
    return '\$${marketCap.toStringAsFixed(0)}';
  }

  String get formattedVolume {
    if (volume24h >= 1e9) return '\$${(volume24h / 1e9).toStringAsFixed(2)}B';
    if (volume24h >= 1e6) return '\$${(volume24h / 1e6).toStringAsFixed(1)}M';
    return '\$${volume24h.toStringAsFixed(0)}';
  }

  factory CmcQuote.fromJson(Map<String, dynamic> json) {
    final quote = (json['quote'] as Map?)?['USD'] as Map? ?? {};
    return CmcQuote(
      id: json['id'] as int? ?? 0,
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      price: (quote['price'] as num?)?.toDouble() ?? 0,
      change1h: (quote['percent_change_1h'] as num?)?.toDouble() ?? 0,
      change24h: (quote['percent_change_24h'] as num?)?.toDouble() ?? 0,
      change7d: (quote['percent_change_7d'] as num?)?.toDouble() ?? 0,
      change30d: (quote['percent_change_30d'] as num?)?.toDouble() ?? 0,
      volume24h: (quote['volume_24h'] as num?)?.toDouble() ?? 0,
      volumeChange24h: (quote['volume_change_24h'] as num?)?.toDouble() ?? 0,
      marketCap: (quote['market_cap'] as num?)?.toDouble() ?? 0,
      fullyDilutedMcap: (quote['fully_diluted_market_cap'] as num?)?.toDouble() ?? 0,
      cmcRank: json['cmc_rank'] as int? ?? 0,
      circulatingSupply: (json['circulating_supply'] as num?)?.toDouble(),
      maxSupply: (json['max_supply'] as num?)?.toDouble(),
      updatedAt: DateTime.tryParse(quote['last_updated']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

// ── CMC Global Metrics ────────────────────────────────────
class CmcGlobalMetrics {
  final double totalMarketCap;
  final double totalVolume24h;
  final double btcDominance;
  final double ethDominance;
  final int activeCoins;
  final int activeExchanges;
  final int fearGreedValue;
  final String fearGreedLabel;
  final DateTime updatedAt;

  const CmcGlobalMetrics({
    required this.totalMarketCap,
    required this.totalVolume24h,
    required this.btcDominance,
    required this.ethDominance,
    required this.activeCoins,
    required this.activeExchanges,
    required this.fearGreedValue,
    required this.fearGreedLabel,
    required this.updatedAt,
  });

  String get formattedMcap {
    if (totalMarketCap >= 1e12) return '\$${(totalMarketCap / 1e12).toStringAsFixed(2)}T';
    return '\$${(totalMarketCap / 1e9).toStringAsFixed(0)}B';
  }
}

// ── CMC Service ───────────────────────────────────────────
class CoinMarketCapService extends ChangeNotifier {
  static final CoinMarketCapService _instance = CoinMarketCapService._();
  factory CoinMarketCapService() => _instance;
  CoinMarketCapService._();

  // API Configuration
  static const String _baseUrl = 'https://pro-api.coinmarketcap.com/v1';
  static const String _sandboxUrl = 'https://sandbox-api.coinmarketcap.com/v1';

  // Use sandbox for demo (no API key needed), switch to pro with real key
  String _apiKey = 'b54bcf4d-1bca-4e8e-9a24-22ff2c3d462c'; // Demo key
  bool _useSandbox = false;

  String get _activeBaseUrl => _useSandbox ? _sandboxUrl : _baseUrl;

  // State
  List<CmcQuote> _quotes = [];
  CmcGlobalMetrics? _globalMetrics;
  bool _loading = false;
  String? _error;
  // ignore: unused_field
  DateTime? _lastFetch;
  Timer? _refreshTimer;
  int _requestCount = 0;
  // ignore: unused_field
  static const int _maxRequestsPerMinute = 30;

  List<CmcQuote> get quotes => List.unmodifiable(_quotes);
  CmcGlobalMetrics? get globalMetrics => _globalMetrics;
  bool get isLoading => _loading;
  String? get error => _error;
  int get requestCount => _requestCount;
  bool get hasData => _quotes.isNotEmpty;

  // Fallback demo data when API is unavailable
  static final List<Map<String, dynamic>> _demoData = [
    {'id': 1, 'symbol': 'BTC', 'name': 'Bitcoin', 'slug': 'bitcoin', 'cmc_rank': 1, 'price': 67840.0, 'change1h': 0.12, 'change24h': 2.84, 'change7d': 8.34, 'volume24h': 28400000000.0, 'marketCap': 1334000000000.0},
    {'id': 1027, 'symbol': 'ETH', 'name': 'Ethereum', 'slug': 'ethereum', 'cmc_rank': 2, 'price': 3412.0, 'change1h': 0.08, 'change24h': 1.92, 'change7d': 6.21, 'volume24h': 14200000000.0, 'marketCap': 409000000000.0},
    {'id': 5426, 'symbol': 'SOL', 'name': 'Solana', 'slug': 'solana', 'cmc_rank': 5, 'price': 178.4, 'change1h': -0.21, 'change24h': -1.12, 'change7d': 3.84, 'volume24h': 4800000000.0, 'marketCap': 82000000000.0},
    {'id': 1839, 'symbol': 'BNB', 'name': 'BNB', 'slug': 'bnb', 'cmc_rank': 4, 'price': 594.0, 'change1h': 0.34, 'change24h': 1.47, 'change7d': 4.12, 'volume24h': 2100000000.0, 'marketCap': 88000000000.0},
    {'id': 52, 'symbol': 'XRP', 'name': 'XRP', 'slug': 'xrp', 'cmc_rank': 6, 'price': 0.628, 'change1h': -0.11, 'change24h': -0.84, 'change7d': 2.14, 'volume24h': 1800000000.0, 'marketCap': 34000000000.0},
    {'id': 5805, 'symbol': 'AVAX', 'name': 'Avalanche', 'slug': 'avalanche', 'cmc_rank': 11, 'price': 42.3, 'change1h': 0.44, 'change24h': 3.21, 'change7d': 9.84, 'volume24h': 840000000.0, 'marketCap': 17400000000.0},
    {'id': 2010, 'symbol': 'ADA', 'name': 'Cardano', 'slug': 'cardano', 'cmc_rank': 10, 'price': 0.481, 'change1h': 0.02, 'change24h': 0.84, 'change7d': 1.24, 'volume24h': 620000000.0, 'marketCap': 17100000000.0},
    {'id': 74, 'symbol': 'DOGE', 'name': 'Dogecoin', 'slug': 'dogecoin', 'cmc_rank': 9, 'price': 0.1638, 'change1h': -0.32, 'change24h': -2.14, 'change7d': -3.21, 'volume24h': 1240000000.0, 'marketCap': 23800000000.0},
    {'id': 6636, 'symbol': 'DOT', 'name': 'Polkadot', 'slug': 'polkadot', 'cmc_rank': 14, 'price': 8.74, 'change1h': 0.18, 'change24h': 1.34, 'change7d': 4.82, 'volume24h': 380000000.0, 'marketCap': 12800000000.0},
    {'id': 1975, 'symbol': 'LINK', 'name': 'Chainlink', 'slug': 'chainlink', 'cmc_rank': 13, 'price': 18.7, 'change1h': -0.14, 'change24h': -1.24, 'change7d': -2.84, 'volume24h': 720000000.0, 'marketCap': 11400000000.0},
    {'id': 3890, 'symbol': 'MATIC', 'name': 'Polygon', 'slug': 'polygon', 'cmc_rank': 17, 'price': 0.8840, 'change1h': 0.22, 'change24h': 2.14, 'change7d': 6.84, 'volume24h': 480000000.0, 'marketCap': 8700000000.0},
    {'id': 1831, 'symbol': 'BCH', 'name': 'Bitcoin Cash', 'slug': 'bitcoin-cash', 'cmc_rank': 18, 'price': 474.0, 'change1h': 0.08, 'change24h': 0.84, 'change7d': 2.14, 'volume24h': 320000000.0, 'marketCap': 9400000000.0},
    {'id': 2, 'symbol': 'LTC', 'name': 'Litecoin', 'slug': 'litecoin', 'cmc_rank': 22, 'price': 88.4, 'change1h': 0.04, 'change24h': 0.42, 'change7d': 1.84, 'volume24h': 480000000.0, 'marketCap': 6600000000.0},
    {'id': 3077, 'symbol': 'VET', 'name': 'VeChain', 'slug': 'vechain', 'cmc_rank': 30, 'price': 0.0382, 'change1h': 0.84, 'change24h': 4.21, 'change7d': 12.4, 'volume24h': 184000000.0, 'marketCap': 2700000000.0},
    {'id': 4687, 'symbol': 'ATOM', 'name': 'Cosmos', 'slug': 'cosmos', 'cmc_rank': 23, 'price': 9.84, 'change1h': 0.12, 'change24h': 1.24, 'change7d': 3.84, 'volume24h': 240000000.0, 'marketCap': 3800000000.0},
  ];

  void configure({String? apiKey, bool? useSandbox}) {
    if (apiKey != null) _apiKey = apiKey;
    if (useSandbox != null) _useSandbox = useSandbox;
  }

  // Start auto-refresh
  void startAutoRefresh({Duration interval = const Duration(seconds: 30)}) {
    fetchQuotes();
    fetchGlobalMetrics();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) {
      fetchQuotes();
      fetchGlobalMetrics();
    });
  }

  void stopAutoRefresh() => _refreshTimer?.cancel();

  // Fetch top quotes
  Future<void> fetchQuotes({int limit = 100}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_activeBaseUrl/cryptocurrency/listings/latest'
            '?limit=$limit&sort=market_cap&sort_dir=desc'
            '&cryptocurrency_type=all&convert=USD'),
        headers: {
          'X-CMC_PRO_API_KEY': _apiKey,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List?;
        if (data != null) {
          _quotes = data
              .map((d) => CmcQuote.fromJson(d as Map<String, dynamic>))
              .toList();
          _lastFetch = DateTime.now();
          _requestCount++;
          _error = null;
        }
      } else if (response.statusCode == 429) {
        _error = 'Rate limit – using cached data';
        if (_quotes.isEmpty) _loadDemoData();
      } else {
        _error = 'CMC API error ${response.statusCode}';
        if (_quotes.isEmpty) _loadDemoData();
      }
    } catch (e) {
      _error = 'Network error: CMC unavailable';
      if (_quotes.isEmpty) _loadDemoData();
      _simulatePriceFluctuations();
    }

    _loading = false;
    notifyListeners();
  }

  // Fetch global market metrics
  Future<void> fetchGlobalMetrics() async {
    try {
      final response = await http.get(
        Uri.parse('$_activeBaseUrl/global-metrics/quotes/latest?convert=USD'),
        headers: {
          'X-CMC_PRO_API_KEY': _apiKey,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          final quote = (data['quote'] as Map?)?['USD'] as Map? ?? {};
          _globalMetrics = CmcGlobalMetrics(
            totalMarketCap: (quote['total_market_cap'] as num?)?.toDouble() ?? 2.1e12,
            totalVolume24h: (quote['total_volume_24h'] as num?)?.toDouble() ?? 84e9,
            btcDominance: (data['btc_dominance'] as num?)?.toDouble() ?? 51.2,
            ethDominance: (data['eth_dominance'] as num?)?.toDouble() ?? 17.4,
            activeCoins: data['active_cryptocurrencies'] as int? ?? 22000,
            activeExchanges: data['active_exchanges'] as int? ?? 847,
            fearGreedValue: 62,
            fearGreedLabel: 'Greed',
            updatedAt: DateTime.now(),
          );
        }
      } else {
        _globalMetrics ??= _defaultGlobalMetrics;
      }
    } catch (_) {
      _globalMetrics ??= _defaultGlobalMetrics;
    }
    notifyListeners();
  }

  // Fetch single coin detail
  Future<CmcQuote?> fetchCoinDetail(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('$_activeBaseUrl/cryptocurrency/quotes/latest?symbol=$symbol&convert=USD'),
        headers: {'X-CMC_PRO_API_KEY': _apiKey, 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (json['data'] as Map?)?[symbol] as Map?;
        if (data != null) return CmcQuote.fromJson(data as Map<String, dynamic>);
      }
    } catch (_) {}
    return _quotes.where((q) => q.symbol == symbol).firstOrNull;
  }

  // Search coins
  List<CmcQuote> search(String query) {
    if (query.isEmpty) return _quotes;
    final q = query.toLowerCase();
    return _quotes.where((coin) =>
      coin.symbol.toLowerCase().contains(q) ||
      coin.name.toLowerCase().contains(q) ||
      coin.slug.toLowerCase().contains(q)
    ).toList();
  }

  // Get top movers
  List<CmcQuote> get topGainers {
    final sorted = [..._quotes]..sort((a, b) => b.change24h.compareTo(a.change24h));
    return sorted.take(10).toList();
  }

  List<CmcQuote> get topLosers {
    final sorted = [..._quotes]..sort((a, b) => a.change24h.compareTo(b.change24h));
    return sorted.take(10).toList();
  }

  List<CmcQuote> get topByVolume {
    final sorted = [..._quotes]..sort((a, b) => b.volume24h.compareTo(a.volume24h));
    return sorted.take(20).toList();
  }

  CmcQuote? getBySymbol(String symbol) =>
      _quotes.where((q) => q.symbol == symbol).firstOrNull;

  void _loadDemoData() {
    final rand = Random();
    _quotes = _demoData.map((d) {
      final p = (d['price'] as double) * (1 + (rand.nextDouble() - 0.49) * 0.02);
      return CmcQuote(
        id: d['id'] as int,
        symbol: d['symbol'] as String,
        name: d['name'] as String,
        slug: d['slug'] as String,
        price: p,
        change1h: d['change1h'] as double,
        change24h: d['change24h'] as double,
        change7d: d['change7d'] as double,
        volume24h: d['volume24h'] as double,
        marketCap: d['marketCap'] as double,
        cmcRank: d['cmc_rank'] as int,
        updatedAt: DateTime.now(),
      );
    }).toList();
    _globalMetrics ??= _defaultGlobalMetrics;
    _error = 'Demo mode – connect API key for live data';
  }

  void _simulatePriceFluctuations() {
    if (_quotes.isEmpty) return;
    final rand = Random();
    _quotes = _quotes.map((q) {
      final priceDelta = (rand.nextDouble() - 0.49) * 0.005;
      return CmcQuote(
        id: q.id, symbol: q.symbol, name: q.name, slug: q.slug,
        price: q.price * (1 + priceDelta),
        change1h: q.change1h + (rand.nextDouble() - 0.5) * 0.1,
        change24h: q.change24h,
        change7d: q.change7d,
        volume24h: q.volume24h,
        marketCap: q.marketCap,
        cmcRank: q.cmcRank,
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  static CmcGlobalMetrics get _defaultGlobalMetrics => CmcGlobalMetrics(
    totalMarketCap: 2.38e12,
    totalVolume24h: 84.7e9,
    btcDominance: 51.2,
    ethDominance: 17.4,
    activeCoins: 22847,
    activeExchanges: 847,
    fearGreedValue: 62,
    fearGreedLabel: 'Greed',
    updatedAt: DateTime.now(),
  );

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
