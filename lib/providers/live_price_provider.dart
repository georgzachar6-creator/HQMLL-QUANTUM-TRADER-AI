// ============================================================
// LIVE PRICE PROVIDER – Quantum Trader v20
// Unified State: WebSocket + CoinGecko + CMC + TradingView
// ============================================================
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../services/websocket_service.dart';
import '../services/coingecko_service.dart';
import '../services/coinmarketcap_service.dart';

// ── Price Source Enum ─────────────────────────────────────
enum PriceSource { websocket, coinGecko, coinMarketCap, simulation }

// ── Unified Asset Quote ───────────────────────────────────
class LiveQuote {
  final String symbol;
  final String name;
  final String? iconUrl;
  final double price;
  final double change24h;   // percent
  final double change1h;
  final double volume24h;
  final double marketCap;
  final double high24h;
  final double low24h;
  final double bid;
  final double ask;
  final double spread;
  final int rank;
  final PriceSource source;
  final DateTime updatedAt;
  final List<double> sparkline; // last 24 price points
  final bool isLive;

  const LiveQuote({
    required this.symbol,
    required this.name,
    this.iconUrl,
    required this.price,
    required this.change24h,
    this.change1h = 0,
    required this.volume24h,
    required this.marketCap,
    required this.high24h,
    required this.low24h,
    this.bid = 0,
    this.ask = 0,
    this.rank = 0,
    required this.source,
    required this.updatedAt,
    this.sparkline = const [],
    this.isLive = true,
  }) : spread = ask > 0 && bid > 0 ? ask - bid : 0;

  bool get isPositive => change24h >= 0;
  bool get isStale => DateTime.now().difference(updatedAt).inSeconds > 10;

  String get formattedPrice {
    if (price >= 10000) return '\$${price.toStringAsFixed(0)}';
    if (price >= 1000) return '\$${price.toStringAsFixed(1)}';
    if (price >= 1) return '\$${price.toStringAsFixed(3)}';
    return '\$${price.toStringAsFixed(6)}';
  }

  String get formattedChange =>
      '${change24h >= 0 ? "+" : ""}${change24h.toStringAsFixed(2)}%';

  String get formattedVolume {
    if (volume24h >= 1e9) return '\$${(volume24h / 1e9).toStringAsFixed(2)}B';
    if (volume24h >= 1e6) return '\$${(volume24h / 1e6).toStringAsFixed(1)}M';
    return '\$${volume24h.toStringAsFixed(0)}';
  }

  String get formattedMcap {
    if (marketCap >= 1e12) return '\$${(marketCap / 1e12).toStringAsFixed(2)}T';
    if (marketCap >= 1e9) return '\$${(marketCap / 1e9).toStringAsFixed(2)}B';
    if (marketCap >= 1e6) return '\$${(marketCap / 1e6).toStringAsFixed(1)}M';
    return '\$${marketCap.toStringAsFixed(0)}';
  }

  LiveQuote mergeWithTick(PriceTick tick) => LiveQuote(
    symbol: symbol,
    name: name,
    iconUrl: iconUrl,
    price: tick.price,
    change24h: tick.change24h,
    change1h: change1h,
    volume24h: tick.volume24h > 0 ? tick.volume24h : volume24h,
    marketCap: marketCap,
    high24h: tick.high24h > 0 ? tick.high24h : high24h,
    low24h: tick.low24h > 0 ? tick.low24h : low24h,
    bid: tick.bid,
    ask: tick.ask,
    rank: rank,
    source: PriceSource.websocket,
    updatedAt: tick.timestamp,
    sparkline: [...sparkline.takeLast(23), tick.price],
    isLive: true,
  );
}

// ── Live Price Provider ───────────────────────────────────
class LivePriceProvider extends ChangeNotifier {
  static final LivePriceProvider _instance = LivePriceProvider._();
  factory LivePriceProvider() => _instance;
  LivePriceProvider._();

  // Services
  final _wsManager = WebSocketManager();
  final _gecko = CoinGeckoService();
  final _cmc = CoinMarketCapService();

  // State
  final Map<String, LiveQuote> _quotes = {};
  bool _initialized = false;
  bool _wsActive = false;
  bool _geckoActive = false;
  bool _cmcActive = false;
  String? _globalError;
  int _ticksPerSecond = 0;
  int _totalTicks = 0;
  DateTime? _lastTick;
  Timer? _statsTimer;
  Timer? _simTimer;
  StreamSubscription? _wsSub;
  int _tickCountBuffer = 0;

  // Config
  bool wsEnabled = true;
  bool geckoEnabled = true;
  bool cmcEnabled = true;
  bool simulationFallback = true;

  // Active exchange filter for display
  String _activeExchangeFilter = 'ALL';
  String get activeExchangeFilter => _activeExchangeFilter;

  // Getters
  Map<String, LiveQuote> get quotes => Map.unmodifiable(_quotes);
  bool get isInitialized => _initialized;
  bool get wsConnected => _wsActive;
  bool get geckoActive => _geckoActive;
  bool get cmcActive => _cmcActive;
  String? get globalError => _globalError;
  int get ticksPerSecond => _ticksPerSecond;
  int get totalTicks => _totalTicks;
  DateTime? get lastTickTime => _lastTick;
  int get connectedExchanges => _wsManager.connectedCount;

  List<LiveQuote> get sortedByRank {
    final list = _quotes.values.toList();
    list.sort((a, b) => (a.rank == 0 ? 999 : a.rank).compareTo(b.rank == 0 ? 999 : b.rank));
    return list;
  }

  List<LiveQuote> get topGainers {
    final list = _quotes.values.toList();
    list.sort((a, b) => b.change24h.compareTo(a.change24h));
    return list.take(10).toList();
  }

  List<LiveQuote> get topLosers {
    final list = _quotes.values.toList();
    list.sort((a, b) => a.change24h.compareTo(b.change24h));
    return list.take(10).toList();
  }

  List<LiveQuote> get topByVolume {
    final list = _quotes.values.toList();
    list.sort((a, b) => b.volume24h.compareTo(a.volume24h));
    return list.take(20).toList();
  }

  LiveQuote? getQuote(String symbol) => _quotes[symbol.toUpperCase()];

  double? getPrice(String symbol) => _quotes[symbol.toUpperCase()]?.price;

  Map<String, ExchangeStatus> get exchangeStatuses =>
      _wsManager.exchangeStatuses;

  // ── Initialize ────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Load from CoinGecko first (fastest REST data)
    if (geckoEnabled) {
      _gecko.addListener(_onGeckoUpdate);
      _gecko.startAutoRefresh(interval: const Duration(seconds: 45));
      _geckoActive = true;
    }

    // 2. Load from CMC for additional data
    if (cmcEnabled) {
      _cmc.addListener(_onCmcUpdate);
      _cmc.startAutoRefresh(interval: const Duration(seconds: 60));
      _cmcActive = true;
    }

    // 3. Start WebSocket for real-time ticks
    if (wsEnabled) {
      await _wsManager.start();
      _wsActive = true;
      _wsSub = _wsManager.addListener(_onWsUpdate) as StreamSubscription?;
      // Listen to WS ticks via the manager
      _startWsListening();
    }

    // 4. Stats timer
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _ticksPerSecond = _tickCountBuffer;
      _tickCountBuffer = 0;
      notifyListeners();
    });

    // 5. Simulation fallback if no live data
    if (simulationFallback) {
      _simTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        _simulateIfStale();
      });
    }

    notifyListeners();
  }

  void _startWsListening() {
    // Subscribe to all exchange tick streams
    _wsManager.binance.tickStream.listen(_processTick);
    _wsManager.coinbase.tickStream.listen(_processTick);
    _wsManager.kraken.tickStream.listen(_processTick);
    _wsManager.bybit.tickStream.listen(_processTick);
    _wsManager.okx.tickStream.listen(_processTick);
  }

  void _processTick(PriceTick tick) {
    final sym = tick.symbol.toUpperCase();
    final existing = _quotes[sym];
    if (existing != null) {
      _quotes[sym] = existing.mergeWithTick(tick);
    } else {
      _quotes[sym] = LiveQuote(
        symbol: sym,
        name: sym,
        price: tick.price,
        change24h: tick.change24h,
        volume24h: tick.volume24h,
        marketCap: 0,
        high24h: tick.high24h,
        low24h: tick.low24h,
        bid: tick.bid,
        ask: tick.ask,
        source: PriceSource.websocket,
        updatedAt: tick.timestamp,
      );
    }
    _tickCountBuffer++;
    _totalTicks++;
    _lastTick = DateTime.now();
    notifyListeners();
  }

  void _onGeckoUpdate() {
    if (!_gecko.hasData) return;
    for (final g in _gecko.markets) {
      final sym = g.symbol.toUpperCase();
      final existing = _quotes[sym];
      // Only update from Gecko if no live WS data or WS data is stale
      if (existing == null || existing.source != PriceSource.websocket || existing.isStale) {
        _quotes[sym] = LiveQuote(
          symbol: sym,
          name: g.name,
          iconUrl: g.image,
          price: g.price,
          change24h: g.changePct24h,
          volume24h: g.volume24h,
          marketCap: g.marketCap,
          high24h: g.high24h,
          low24h: g.low24h,
          rank: g.marketCapRank,
          source: PriceSource.coinGecko,
          updatedAt: g.lastUpdated ?? DateTime.now(),
        );
      }
    }
    notifyListeners();
  }

  void _onCmcUpdate() {
    if (!_cmc.hasData) return;
    for (final c in _cmc.quotes) {
      final sym = c.symbol.toUpperCase();
      final existing = _quotes[sym];
      if (existing == null) {
        _quotes[sym] = LiveQuote(
          symbol: sym,
          name: c.name,
          iconUrl: c.iconUrl,
          price: c.price,
          change24h: c.change24h,
          change1h: c.change1h,
          volume24h: c.volume24h,
          marketCap: c.marketCap,
          high24h: 0,
          low24h: 0,
          rank: c.cmcRank,
          source: PriceSource.coinMarketCap,
          updatedAt: c.updatedAt,
        );
      } else if (existing.rank == 0) {
        _quotes[sym] = LiveQuote(
          symbol: existing.symbol,
          name: existing.name.isEmpty ? c.name : existing.name,
          iconUrl: existing.iconUrl ?? c.iconUrl,
          price: existing.price,
          change24h: existing.change24h,
          change1h: c.change1h,
          volume24h: existing.volume24h > 0 ? existing.volume24h : c.volume24h,
          marketCap: existing.marketCap > 0 ? existing.marketCap : c.marketCap,
          high24h: existing.high24h,
          low24h: existing.low24h,
          rank: c.cmcRank,
          source: existing.source,
          updatedAt: existing.updatedAt,
        );
      }
    }
    notifyListeners();
  }

  void _onWsUpdate() {
    // WS manager notified of status change
    notifyListeners();
  }

  void _simulateIfStale() {
    if (_quotes.isEmpty) return;
    final rand = Random();
    bool changed = false;
    _quotes.forEach((sym, q) {
      if (q.isStale) {
        final delta = (rand.nextDouble() - 0.49) * 0.003;
        _quotes[sym] = LiveQuote(
          symbol: q.symbol,
          name: q.name,
          iconUrl: q.iconUrl,
          price: q.price * (1 + delta),
          change24h: q.change24h + (rand.nextDouble() - 0.5) * 0.05,
          change1h: q.change1h,
          volume24h: q.volume24h,
          marketCap: q.marketCap,
          high24h: q.high24h,
          low24h: q.low24h,
          bid: q.bid > 0 ? q.bid * (1 + delta) : 0,
          ask: q.ask > 0 ? q.ask * (1 + delta) : 0,
          rank: q.rank,
          source: PriceSource.simulation,
          updatedAt: DateTime.now(),
          sparkline: [...q.sparkline.takeLast(23), q.price * (1 + delta)],
          isLive: false,
        );
        changed = true;
        _tickCountBuffer++;
        _totalTicks++;
      }
    });
    if (changed) notifyListeners();
  }

  // Exchange toggle
  void toggleExchange(String name, bool enabled) {
    _wsManager.toggleExchange(name, enabled);
    notifyListeners();
  }

  void setExchangeFilter(String exchange) {
    _activeExchangeFilter = exchange;
    notifyListeners();
  }

  // Manual refresh
  Future<void> refresh() async {
    await Future.wait([
      if (geckoEnabled) _gecko.fetchMarkets(),
      if (cmcEnabled) _cmc.fetchQuotes(),
    ]);
  }

  // Get TradingView symbol for a coin
  static String tradingViewSymbol(String symbol, {String exchange = 'BINANCE'}) {
    return '$exchange:${symbol}USDT';
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _simTimer?.cancel();
    _wsSub?.cancel();
    _gecko.removeListener(_onGeckoUpdate);
    _cmc.removeListener(_onCmcUpdate);
    _gecko.dispose();
    _cmc.dispose();
    _wsManager.dispose();
    super.dispose();
  }
}

// Extension for takeLast
extension TakeLast<T> on List<T> {
  List<T> takeLast(int n) => length <= n ? this : sublist(length - n);
}
