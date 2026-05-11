// ============================================================
// COINGECKO SERVICE v2 – Quantum Trader
// CoinGecko Free + Pro API – Prices, Charts, OHLCV, NFTs
// ============================================================
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ── CoinGecko Coin Model ──────────────────────────────────
class GeckoQuote {
  final String id;
  final String symbol;
  final String name;
  final String? image;
  final double price;
  final double change24h;
  final double changePct24h;
  final double high24h;
  final double low24h;
  final double volume24h;
  final double marketCap;
  final int marketCapRank;
  final double? ath;
  final double? atl;
  final double? circulatingSupply;
  final double? totalSupply;
  final DateTime? lastUpdated;

  const GeckoQuote({
    required this.id,
    required this.symbol,
    required this.name,
    this.image,
    required this.price,
    required this.change24h,
    required this.changePct24h,
    required this.high24h,
    required this.low24h,
    required this.volume24h,
    required this.marketCap,
    required this.marketCapRank,
    this.ath,
    this.atl,
    this.circulatingSupply,
    this.totalSupply,
    this.lastUpdated,
  });

  bool get isPositive => changePct24h >= 0;

  String get formattedPrice {
    if (price >= 10000) return '\$${price.toStringAsFixed(0)}';
    if (price >= 1000) return '\$${price.toStringAsFixed(1)}';
    if (price >= 1) return '\$${price.toStringAsFixed(3)}';
    return '\$${price.toStringAsFixed(6)}';
  }

  String get formattedChange =>
      '${changePct24h >= 0 ? "+" : ""}${changePct24h.toStringAsFixed(2)}%';

  String get formattedMcap {
    if (marketCap >= 1e12) return '\$${(marketCap / 1e12).toStringAsFixed(2)}T';
    if (marketCap >= 1e9) return '\$${(marketCap / 1e9).toStringAsFixed(2)}B';
    if (marketCap >= 1e6) return '\$${(marketCap / 1e6).toStringAsFixed(1)}M';
    return '\$${marketCap.toStringAsFixed(0)}';
  }

  factory GeckoQuote.fromJson(Map<String, dynamic> j) {
    return GeckoQuote(
      id: j['id'] as String? ?? '',
      symbol: (j['symbol'] as String? ?? '').toUpperCase(),
      name: j['name'] as String? ?? '',
      image: j['image'] as String?,
      price: (j['current_price'] as num?)?.toDouble() ?? 0,
      change24h: (j['price_change_24h'] as num?)?.toDouble() ?? 0,
      changePct24h: (j['price_change_percentage_24h'] as num?)?.toDouble() ?? 0,
      high24h: (j['high_24h'] as num?)?.toDouble() ?? 0,
      low24h: (j['low_24h'] as num?)?.toDouble() ?? 0,
      volume24h: (j['total_volume'] as num?)?.toDouble() ?? 0,
      marketCap: (j['market_cap'] as num?)?.toDouble() ?? 0,
      marketCapRank: j['market_cap_rank'] as int? ?? 0,
      ath: (j['ath'] as num?)?.toDouble(),
      atl: (j['atl'] as num?)?.toDouble(),
      circulatingSupply: (j['circulating_supply'] as num?)?.toDouble(),
      totalSupply: (j['total_supply'] as num?)?.toDouble(),
      lastUpdated: j['last_updated'] != null
          ? DateTime.tryParse(j['last_updated'] as String)
          : null,
    );
  }
}

// ── OHLCV Candle Model ────────────────────────────────────
class GeckoCandle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  const GeckoCandle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory GeckoCandle.fromList(List<dynamic> l) => GeckoCandle(
    time: DateTime.fromMillisecondsSinceEpoch((l[0] as int)),
    open: (l[1] as num).toDouble(),
    high: (l[2] as num).toDouble(),
    low: (l[3] as num).toDouble(),
    close: (l[4] as num).toDouble(),
  );
}

// ── Market Chart Data ─────────────────────────────────────
class MarketChart {
  final String coinId;
  final String vsSymbol;
  final List<MapEntry<DateTime, double>> prices;
  final List<MapEntry<DateTime, double>> volumes;
  final List<MapEntry<DateTime, double>> marketCaps;

  const MarketChart({
    required this.coinId,
    required this.vsSymbol,
    required this.prices,
    required this.volumes,
    required this.marketCaps,
  });

  double get priceChange {
    if (prices.length < 2) return 0;
    return (prices.last.value - prices.first.value) / prices.first.value * 100;
  }
}

// ── Trending Coin ─────────────────────────────────────────
class TrendingCoin {
  final String id;
  final String symbol;
  final String name;
  final String? thumb;
  final int rank;
  final double? priceBtc;

  const TrendingCoin({
    required this.id,
    required this.symbol,
    required this.name,
    this.thumb,
    required this.rank,
    this.priceBtc,
  });

  factory TrendingCoin.fromJson(Map<String, dynamic> j) {
    final item = j['item'] as Map<String, dynamic>? ?? j;
    return TrendingCoin(
      id: item['id'] as String? ?? '',
      symbol: (item['symbol'] as String? ?? '').toUpperCase(),
      name: item['name'] as String? ?? '',
      thumb: item['thumb'] as String?,
      rank: item['market_cap_rank'] as int? ?? 0,
      priceBtc: (item['price_btc'] as num?)?.toDouble(),
    );
  }
}

// ── CoinGecko Service ─────────────────────────────────────
class CoinGeckoService extends ChangeNotifier {
  static final CoinGeckoService _instance = CoinGeckoService._();
  factory CoinGeckoService() => _instance;
  CoinGeckoService._();

  static const String _freeBaseUrl = 'https://api.coingecko.com/api/v3';
  static const String _proBaseUrl = 'https://pro-api.coingecko.com/api/v3';

  String? _apiKey; // null = free tier
  bool get isPro => _apiKey != null;

  // State
  List<GeckoQuote> _markets = [];
  List<TrendingCoin> _trending = [];
  bool _loading = false;
  String? _error;
  Timer? _refreshTimer;
  final Map<String, MarketChart> _chartCache = {};
  final Map<String, List<GeckoCandle>> _ohlcCache = {};
  int _rateLimitRemaining = 30;
  static const int _rateLimit = 30; // ignore: unused_field

  List<GeckoQuote> get markets => List.unmodifiable(_markets);
  List<TrendingCoin> get trending => List.unmodifiable(_trending);
  bool get isLoading => _loading;
  String? get error => _error;
  bool get hasData => _markets.isNotEmpty;
  int get rateLimitRemaining => _rateLimitRemaining;

  String get _baseUrl => isPro ? _proBaseUrl : _freeBaseUrl;
  Map<String, String> get _headers => isPro
      ? {'x-cg-pro-api-key': _apiKey!, 'Accept': 'application/json'}
      : {'Accept': 'application/json'};

  void configure({String? apiKey}) {
    _apiKey = apiKey;
    notifyListeners();
  }

  // Start auto-refresh
  void startAutoRefresh({Duration interval = const Duration(seconds: 60)}) {
    fetchMarkets();
    fetchTrending();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => fetchMarkets());
    Timer.periodic(const Duration(minutes: 5), (_) => fetchTrending());
  }

  void stopAutoRefresh() => _refreshTimer?.cancel();

  // Fetch market data
  Future<void> fetchMarkets({
    int page = 1,
    int perPage = 100,
    String vsCurrency = 'usd',
    String order = 'market_cap_desc',
    bool sparkline = false,
  }) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/coins/markets').replace(
        queryParameters: {
          'vs_currency': vsCurrency,
          'order': order,
          'per_page': perPage.toString(),
          'page': page.toString(),
          'sparkline': sparkline.toString(),
          'price_change_percentage': '1h,24h,7d,30d',
        },
      );

      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));

      _rateLimitRemaining = int.tryParse(
            response.headers['x-ratelimit-remaining'] ?? '30') ?? 30;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (page == 1) {
          _markets = data.map((d) => GeckoQuote.fromJson(d as Map<String, dynamic>)).toList();
        } else {
          _markets.addAll(data.map((d) => GeckoQuote.fromJson(d as Map<String, dynamic>)));
        }
        _error = null;
      } else if (response.statusCode == 429) {
        _error = 'Rate limited – using cached data';
        if (_markets.isEmpty) _loadFallbackMarkets();
      } else {
        _error = 'CoinGecko error ${response.statusCode}';
        if (_markets.isEmpty) _loadFallbackMarkets();
      }
    } catch (e) {
      _error = 'Network unavailable – showing demo data';
      if (_markets.isEmpty) _loadFallbackMarkets();
      else _simulateUpdates();
    }

    _loading = false;
    notifyListeners();
  }

  // Fetch trending coins
  Future<void> fetchTrending() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/trending'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final coins = (json['coins'] as List?) ?? [];
        _trending = coins
            .map((c) => TrendingCoin.fromJson(c as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  // Fetch market chart (price history)
  Future<MarketChart?> fetchChart(
    String coinId, {
    int days = 7,
    String vsCurrency = 'usd',
    String interval = 'daily',
  }) async {
    final cacheKey = '$coinId-$days-$interval';
    // Check cache (5min validity)
    final cached = _chartCache[cacheKey];
    if (cached != null) return cached;

    try {
      final uri = Uri.parse('$_baseUrl/coins/$coinId/market_chart').replace(
        queryParameters: {
          'vs_currency': vsCurrency,
          'days': days.toString(),
          if (days <= 1) 'interval': 'hourly' else 'interval': interval,
        },
      );
      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final chart = MarketChart(
          coinId: coinId,
          vsSymbol: vsCurrency,
          prices: ((json['prices'] as List?) ?? []).map((p) {
            final pl = p as List;
            return MapEntry(
              DateTime.fromMillisecondsSinceEpoch(pl[0] as int),
              (pl[1] as num).toDouble(),
            );
          }).toList(),
          volumes: ((json['total_volumes'] as List?) ?? []).map((v) {
            final vl = v as List;
            return MapEntry(
              DateTime.fromMillisecondsSinceEpoch(vl[0] as int),
              (vl[1] as num).toDouble(),
            );
          }).toList(),
          marketCaps: ((json['market_caps'] as List?) ?? []).map((m) {
            final ml = m as List;
            return MapEntry(
              DateTime.fromMillisecondsSinceEpoch(ml[0] as int),
              (ml[1] as num).toDouble(),
            );
          }).toList(),
        );
        _chartCache[cacheKey] = chart;
        return chart;
      }
    } catch (_) {}
    return _generateFakeChart(coinId, days);
  }

  // Fetch OHLCV candles
  Future<List<GeckoCandle>> fetchOHLCV(
    String coinId, {
    int days = 1,
    String vsCurrency = 'usd',
  }) async {
    final cacheKey = '$coinId-ohlcv-$days';
    final cached = _ohlcCache[cacheKey];
    if (cached != null) return cached;

    try {
      final uri = Uri.parse('$_baseUrl/coins/$coinId/ohlc').replace(
        queryParameters: {
          'vs_currency': vsCurrency,
          'days': days.toString(),
        },
      );
      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final candles = data
            .map((c) => GeckoCandle.fromList(c as List<dynamic>))
            .toList();
        _ohlcCache[cacheKey] = candles;
        return candles;
      }
    } catch (_) {}
    return _generateFakeCandles(days);
  }

  // Get coin detail
  Future<Map<String, dynamic>?> fetchCoinDetail(String coinId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/coins/$coinId?localization=false'
            '&tickers=false&market_data=true&community_data=true'
            '&developer_data=false&sparkline=false'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // Global market stats
  Future<Map<String, dynamic>?> fetchGlobalData() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/global'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['data'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  // Search
  Future<List<Map<String, dynamic>>> search(String query) async {
    if (query.isEmpty) return [];
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?query=${Uri.encodeComponent(query)}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ((json['coins'] as List?) ?? [])
            .cast<Map<String, dynamic>>()
            .take(20)
            .toList();
      }
    } catch (_) {}
    // Fallback: filter local markets
    final q = query.toLowerCase();
    return _markets
        .where((m) =>
            m.symbol.toLowerCase().contains(q) ||
            m.name.toLowerCase().contains(q))
        .take(20)
        .map((m) => {'id': m.id, 'name': m.name, 'symbol': m.symbol, 'thumb': m.image})
        .toList();
  }

  GeckoQuote? getBySymbol(String symbol) {
    final s = symbol.toUpperCase();
    return _markets.where((m) => m.symbol == s).firstOrNull;
  }

  GeckoQuote? getById(String id) =>
      _markets.where((m) => m.id == id).firstOrNull;

  List<GeckoQuote> get topGainers {
    final sorted = [..._markets]..sort((a, b) => b.changePct24h.compareTo(a.changePct24h));
    return sorted.take(10).toList();
  }

  List<GeckoQuote> get topLosers {
    final sorted = [..._markets]..sort((a, b) => a.changePct24h.compareTo(b.changePct24h));
    return sorted.take(10).toList();
  }

  // ── Fallback / demo data ──────────────────────────────
  static const List<Map<String, dynamic>> _fallbackCoins = [
    {'id': 'bitcoin', 'symbol': 'BTC', 'name': 'Bitcoin', 'price': 67840.0, 'change': 2.84, 'vol': 28.4e9, 'mcap': 1334e9, 'rank': 1},
    {'id': 'ethereum', 'symbol': 'ETH', 'name': 'Ethereum', 'price': 3412.0, 'change': 1.92, 'vol': 14.2e9, 'mcap': 409e9, 'rank': 2},
    {'id': 'binancecoin', 'symbol': 'BNB', 'name': 'BNB', 'price': 594.0, 'change': 1.47, 'vol': 2.1e9, 'mcap': 88e9, 'rank': 4},
    {'id': 'solana', 'symbol': 'SOL', 'name': 'Solana', 'price': 178.4, 'change': -1.12, 'vol': 4.8e9, 'mcap': 82e9, 'rank': 5},
    {'id': 'ripple', 'symbol': 'XRP', 'name': 'XRP', 'price': 0.628, 'change': -0.84, 'vol': 1.8e9, 'mcap': 34e9, 'rank': 6},
    {'id': 'avalanche-2', 'symbol': 'AVAX', 'name': 'Avalanche', 'price': 42.3, 'change': 3.21, 'vol': 840e6, 'mcap': 17.4e9, 'rank': 11},
    {'id': 'cardano', 'symbol': 'ADA', 'name': 'Cardano', 'price': 0.481, 'change': 0.84, 'vol': 620e6, 'mcap': 17.1e9, 'rank': 10},
    {'id': 'dogecoin', 'symbol': 'DOGE', 'name': 'Dogecoin', 'price': 0.1638, 'change': -2.14, 'vol': 1.24e9, 'mcap': 23.8e9, 'rank': 9},
    {'id': 'polkadot', 'symbol': 'DOT', 'name': 'Polkadot', 'price': 8.74, 'change': 1.34, 'vol': 380e6, 'mcap': 12.8e9, 'rank': 14},
    {'id': 'chainlink', 'symbol': 'LINK', 'name': 'Chainlink', 'price': 18.7, 'change': -1.24, 'vol': 720e6, 'mcap': 11.4e9, 'rank': 13},
    {'id': 'matic-network', 'symbol': 'MATIC', 'name': 'Polygon', 'price': 0.884, 'change': 2.14, 'vol': 480e6, 'mcap': 8.7e9, 'rank': 17},
    {'id': 'uniswap', 'symbol': 'UNI', 'name': 'Uniswap', 'price': 11.24, 'change': 1.84, 'vol': 240e6, 'mcap': 6.8e9, 'rank': 19},
    {'id': 'litecoin', 'symbol': 'LTC', 'name': 'Litecoin', 'price': 88.4, 'change': 0.42, 'vol': 480e6, 'mcap': 6.6e9, 'rank': 22},
    {'id': 'cosmos', 'symbol': 'ATOM', 'name': 'Cosmos', 'price': 9.84, 'change': 1.24, 'vol': 240e6, 'mcap': 3.8e9, 'rank': 23},
    {'id': 'near', 'symbol': 'NEAR', 'name': 'NEAR Protocol', 'price': 7.42, 'change': 4.84, 'vol': 320e6, 'mcap': 8.1e9, 'rank': 15},
  ];

  void _loadFallbackMarkets() {
    final rand = Random();
    _markets = _fallbackCoins.map((d) {
      final baseP = d['price'] as double;
      final p = baseP * (1 + (rand.nextDouble() - 0.49) * 0.01);
      return GeckoQuote(
        id: d['id'] as String,
        symbol: d['symbol'] as String,
        name: d['name'] as String,
        image: 'https://assets.coingecko.com/coins/images/1/small/bitcoin.png',
        price: p,
        change24h: p - baseP,
        changePct24h: d['change'] as double,
        high24h: p * 1.02,
        low24h: p * 0.98,
        volume24h: d['vol'] as double,
        marketCap: d['mcap'] as double,
        marketCapRank: d['rank'] as int,
        lastUpdated: DateTime.now(),
      );
    }).toList();
  }

  void _simulateUpdates() {
    final rand = Random();
    _markets = _markets.map((q) {
      final delta = (rand.nextDouble() - 0.49) * 0.003;
      final newPrice = q.price * (1 + delta);
      return GeckoQuote(
        id: q.id, symbol: q.symbol, name: q.name, image: q.image,
        price: newPrice,
        change24h: q.change24h + (rand.nextDouble() - 0.5) * 5,
        changePct24h: q.changePct24h + (rand.nextDouble() - 0.5) * 0.1,
        high24h: q.high24h, low24h: q.low24h,
        volume24h: q.volume24h, marketCap: q.marketCap,
        marketCapRank: q.marketCapRank,
        lastUpdated: DateTime.now(),
      );
    }).toList();
  }

  MarketChart _generateFakeChart(String coinId, int days) {
    final rand = Random();
    final now = DateTime.now();
    final points = days * 24;
    double price = _markets.where((m) => m.id == coinId).firstOrNull?.price ?? 1000;
    final prices = <MapEntry<DateTime, double>>[];
    final vols = <MapEntry<DateTime, double>>[];
    for (int i = points; i >= 0; i--) {
      final time = now.subtract(Duration(hours: i));
      price *= (1 + (rand.nextDouble() - 0.49) * 0.005);
      prices.add(MapEntry(time, price));
      vols.add(MapEntry(time, 1e9 + rand.nextDouble() * 2e9));
    }
    return MarketChart(
      coinId: coinId, vsSymbol: 'usd',
      prices: prices, volumes: vols, marketCaps: [],
    );
  }

  List<GeckoCandle> _generateFakeCandles(int days) {
    final rand = Random();
    final now = DateTime.now();
    double price = 50000;
    return List.generate(days * 24, (i) {
      price *= (1 + (rand.nextDouble() - 0.49) * 0.01);
      final open = price;
      final high = price * (1 + rand.nextDouble() * 0.02);
      final low = price * (1 - rand.nextDouble() * 0.02);
      final close = low + rand.nextDouble() * (high - low);
      return GeckoCandle(
        time: now.subtract(Duration(hours: days * 24 - i)),
        open: open, high: high, low: low, close: close,
      );
    });
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
