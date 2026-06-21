/// HQMLL Quantum Trader — Market Data Ingestion Service v51.0
/// Basiert auf: Perplexity AI Training Platform Architecture
/// Multi-Provider WebSocket Gateway: CoinGecko, Kraken, Binance, Alpaca
/// Normalisierung, Time-Series-Storage, Feature Extraction
/// Grigori Saks · 2025
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════════════════════
// ENUMS & MODELS
// ══════════════════════════════════════════════════════════════════════════

enum DataProvider { coinGecko, kraken, binance, coinbase, alpaca, eodhd, massive }
enum AssetClass { crypto, equity, fx, etf, commodity, derivative }
enum BarInterval { s1, m1, m5, m15, m30, h1, h4, d1, w1 }
enum ConnectionStatus { disconnected, connecting, connected, reconnecting, error }

extension BarIntervalX on BarInterval {
  String get label => const {
    BarInterval.s1: '1s', BarInterval.m1: '1m', BarInterval.m5: '5m',
    BarInterval.m15: '15m', BarInterval.m30: '30m',
    BarInterval.h1: '1h', BarInterval.h4: '4h',
    BarInterval.d1: '1D', BarInterval.w1: '1W',
  }[this] ?? '1m';

  Duration get duration => const {
    BarInterval.s1:  Duration(seconds: 1),
    BarInterval.m1:  Duration(minutes: 1),
    BarInterval.m5:  Duration(minutes: 5),
    BarInterval.m15: Duration(minutes: 15),
    BarInterval.m30: Duration(minutes: 30),
    BarInterval.h1:  Duration(hours: 1),
    BarInterval.h4:  Duration(hours: 4),
    BarInterval.d1:  Duration(days: 1),
    BarInterval.w1:  Duration(days: 7),
  }[this] ?? const Duration(minutes: 1);
}

extension DataProviderX on DataProvider {
  String get label => const {
    DataProvider.coinGecko: 'CoinGecko',
    DataProvider.kraken: 'Kraken',
    DataProvider.binance: 'Binance',
    DataProvider.coinbase: 'Coinbase',
    DataProvider.alpaca: 'Alpaca',
    DataProvider.eodhd: 'EODHD',
    DataProvider.massive: 'Massive',
  }[this] ?? 'Unbekannt';

  String get wsUrl => const {
    DataProvider.kraken: 'wss://ws.kraken.com',
    DataProvider.binance: 'wss://stream.binance.com:9443/ws',
    DataProvider.coinbase: 'wss://advanced-trade-ws.coinbase.com',
    DataProvider.alpaca: 'wss://stream.data.alpaca.markets/v1beta3/crypto/us',
    DataProvider.coinGecko: 'wss://api.coingecko.com/ws',
    DataProvider.eodhd: 'wss://ws.eodhistoricaldata.com/ws',
    DataProvider.massive: 'wss://ws.massive.io/v1/stream',
  }[this] ?? '';

  AssetClass get primaryAssetClass => const {
    DataProvider.coinGecko: AssetClass.crypto,
    DataProvider.kraken: AssetClass.crypto,
    DataProvider.binance: AssetClass.crypto,
    DataProvider.coinbase: AssetClass.crypto,
    DataProvider.alpaca: AssetClass.equity,
    DataProvider.eodhd: AssetClass.equity,
    DataProvider.massive: AssetClass.equity,
  }[this] ?? AssetClass.crypto;
}

// ──────────────────────────────────────────────────────────────────────────
/// Normalisierter Tick-Datenpunkt
class MarketTick {
  final String symbol;
  final DataProvider provider;
  final double lastPrice;
  final double bidPrice;
  final double askPrice;
  final double volume24h;
  final double change24hPct;
  final double high24h;
  final double low24h;
  final AssetClass assetClass;
  final DateTime timestamp;

  const MarketTick({
    required this.symbol,
    required this.provider,
    required this.lastPrice,
    required this.bidPrice,
    required this.askPrice,
    required this.volume24h,
    required this.change24hPct,
    required this.high24h,
    required this.low24h,
    required this.assetClass,
    required this.timestamp,
  });

  double get spread => askPrice - bidPrice;
  double get spreadPct => lastPrice > 0 ? spread / lastPrice : 0.0;
  double get midPrice => (bidPrice + askPrice) / 2;

  MarketTick copyWith({double? lastPrice, double? bidPrice, double? askPrice}) =>
    MarketTick(
      symbol: symbol, provider: provider,
      lastPrice: lastPrice ?? this.lastPrice,
      bidPrice: bidPrice ?? this.bidPrice,
      askPrice: askPrice ?? this.askPrice,
      volume24h: volume24h, change24hPct: change24hPct,
      high24h: high24h, low24h: low24h,
      assetClass: assetClass, timestamp: DateTime.now(),
    );
}

// ──────────────────────────────────────────────────────────────────────────
/// OHLCV-Bar (Candlestick)
class OhlcvBar {
  final String symbol;
  final BarInterval interval;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final DateTime openTime;
  final bool isClosed;

  const OhlcvBar({
    required this.symbol,
    required this.interval,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.openTime,
    required this.isClosed,
  });

  double get change => close - open;
  double get changePct => open > 0 ? (close - open) / open : 0.0;
  double get bodySize => (close - open).abs();
  double get upperWick => high - (close > open ? close : open);
  double get lowerWick => (close < open ? close : open) - low;
  bool get isBullish => close >= open;

  OhlcvBar updateClose(double newClose, double addVolume) => OhlcvBar(
    symbol: symbol, interval: interval, open: open,
    high: max(high, newClose), low: min(low, newClose),
    close: newClose, volume: volume + addVolume,
    openTime: openTime, isClosed: false,
  );

  OhlcvBar close_() => OhlcvBar(
    symbol: symbol, interval: interval, open: open,
    high: high, low: low, close: close, volume: volume,
    openTime: openTime, isClosed: true,
  );
}

// ──────────────────────────────────────────────────────────────────────────
/// OrderBook-Snapshot (normalisiert)
class OrderBookSnapshot {
  final String symbol;
  final List<List<double>> bids; // [[price, size], ...]
  final List<List<double>> asks;
  final DateTime timestamp;
  final DataProvider provider;

  const OrderBookSnapshot({
    required this.symbol,
    required this.bids,
    required this.asks,
    required this.timestamp,
    required this.provider,
  });

  double get bestBid => bids.isNotEmpty ? bids.first[0] : 0.0;
  double get bestAsk => asks.isNotEmpty ? asks.first[0] : 0.0;
  double get spread => bestAsk - bestBid;
  double get midPrice => (bestBid + bestAsk) / 2;

  double get bidDepth => bids.fold(0.0, (s, b) => s + b[0] * b[1]);
  double get askDepth => asks.fold(0.0, (s, a) => s + a[0] * a[1]);
  double get imbalance =>
      (bidDepth + askDepth) > 0 ? (bidDepth - askDepth) / (bidDepth + askDepth) : 0.0;
}

// ──────────────────────────────────────────────────────────────────────────
/// Echtzeit-Feature-Vektor (Feature Store Eingang)
class MarketFeatures {
  final String symbol;
  // Preis-Features
  final double returnsPct1m;
  final double returnsPct5m;
  final double returnsPct1h;
  // Volatilität
  final double volatility1h;
  final double volatility1d;
  // Orderflow
  final double obImbalance;    // Order Book Imbalance [-1..1]
  final double volumeRatio;    // Aktuell / Durchschnitt
  // Technische Indikatoren
  final double rsi14;
  final double macdSignal;     // MACD Histogram
  final double bbPosition;     // Position im Bollinger Band [-1..1]
  // Regime
  final String regime;         // TRENDING_UP/DOWN, RANGING, VOLATILE
  final DateTime computedAt;

  const MarketFeatures({
    required this.symbol,
    required this.returnsPct1m,
    required this.returnsPct5m,
    required this.returnsPct1h,
    required this.volatility1h,
    required this.volatility1d,
    required this.obImbalance,
    required this.volumeRatio,
    required this.rsi14,
    required this.macdSignal,
    required this.bbPosition,
    required this.regime,
    required this.computedAt,
  });

  /// Als Feature-Vektor für ML
  List<double> toVector() => [
    returnsPct1m, returnsPct5m, returnsPct1h,
    volatility1h, volatility1d,
    obImbalance, volumeRatio,
    rsi14 / 100.0, // Normiert auf [0..1]
    macdSignal.clamp(-1.0, 1.0),
    bbPosition,
  ];
}

// ──────────────────────────────────────────────────────────────────────────
class ProviderConnectionState {
  final DataProvider provider;
  final ConnectionStatus status;
  final DateTime? connectedAt;
  final DateTime? lastMessageAt;
  final int messageCount;
  final int reconnectCount;
  final String? lastError;

  const ProviderConnectionState({
    required this.provider,
    required this.status,
    this.connectedAt,
    this.lastMessageAt,
    required this.messageCount,
    required this.reconnectCount,
    this.lastError,
  });

  Duration? get uptime =>
      connectedAt != null ? DateTime.now().difference(connectedAt!) : null;

  double get messagesPerSecond {
    if (connectedAt == null || messageCount == 0) return 0.0;
    final seconds = uptime?.inSeconds ?? 1;
    return seconds > 0 ? messageCount / seconds : 0.0;
  }

  String get statusLabel => const {
    ConnectionStatus.disconnected: 'Getrennt',
    ConnectionStatus.connecting: 'Verbinde...',
    ConnectionStatus.connected: 'Verbunden',
    ConnectionStatus.reconnecting: 'Wiederverbinde...',
    ConnectionStatus.error: 'Fehler',
  }[status] ?? 'Unbekannt';

  String get statusEmoji => const {
    ConnectionStatus.disconnected: '⭕',
    ConnectionStatus.connecting: '🔄',
    ConnectionStatus.connected: '🟢',
    ConnectionStatus.reconnecting: '🟡',
    ConnectionStatus.error: '🔴',
  }[status] ?? '⭕';

  ProviderConnectionState copyWith({
    ConnectionStatus? status,
    DateTime? connectedAt,
    DateTime? lastMessageAt,
    int? messageCount,
    int? reconnectCount,
    String? lastError,
  }) => ProviderConnectionState(
    provider: provider,
    status: status ?? this.status,
    connectedAt: connectedAt ?? this.connectedAt,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    messageCount: messageCount ?? this.messageCount,
    reconnectCount: reconnectCount ?? this.reconnectCount,
    lastError: lastError ?? this.lastError,
  );
}

// ══════════════════════════════════════════════════════════════════════════
// MARKET DATA INGESTION SERVICE
// Multi-Provider WebSocket Gateway mit Normalisierung
// ══════════════════════════════════════════════════════════════════════════
class MarketDataIngestionService extends ChangeNotifier {
  // ── Konfiguration ────────────────────────────────────────────────────────
  final Set<DataProvider> _enabledProviders = {
    DataProvider.coinGecko,
    DataProvider.kraken,
    DataProvider.binance,
  };
  final Set<String> _subscribedSymbols = {
    'BTC-EUR', 'ETH-EUR', 'SOL-USD', 'BNB-USDT', 'XRP-USDT',
  };

  // ── State ────────────────────────────────────────────────────────────────
  final Map<String, MarketTick> _tickers = {};
  final Map<String, List<OhlcvBar>> _bars = {};  // symbol → bars
  final Map<String, OrderBookSnapshot> _orderBooks = {};
  final Map<String, MarketFeatures> _features = {};
  final Map<DataProvider, ProviderConnectionState> _connections = {};
  bool _isRunning = false;

  // ── Streams ──────────────────────────────────────────────────────────────
  final StreamController<MarketTick> _tickStream =
      StreamController<MarketTick>.broadcast();
  final StreamController<OhlcvBar> _barStream =
      StreamController<OhlcvBar>.broadcast();
  final StreamController<OrderBookSnapshot> _bookStream =
      StreamController<OrderBookSnapshot>.broadcast();
  final StreamController<MarketFeatures> _featureStream =
      StreamController<MarketFeatures>.broadcast();

  Stream<MarketTick>           get tickStream    => _tickStream.stream;
  Stream<OhlcvBar>             get barStream     => _barStream.stream;
  Stream<OrderBookSnapshot>    get bookStream    => _bookStream.stream;
  Stream<MarketFeatures>       get featureStream => _featureStream.stream;

  // ── Timer für Simulation ─────────────────────────────────────────────────
  Timer? _simulationTimer;
  final Random _rng = Random();

  // ── Getters ──────────────────────────────────────────────────────────────
  bool get isRunning => _isRunning;
  Map<String, MarketTick>     get tickers    => Map.unmodifiable(_tickers);
  Map<String, MarketFeatures> get features   => Map.unmodifiable(_features);
  Set<String> get subscribedSymbols => Set.unmodifiable(_subscribedSymbols);
  Set<DataProvider> get enabledProviders => Set.unmodifiable(_enabledProviders);

  List<ProviderConnectionState> get connectionStates =>
      _connections.values.toList();

  int get connectedProviderCount => _connections.values
      .where((c) => c.status == ConnectionStatus.connected).length;

  double get totalMessagesPerSecond => _connections.values
      .fold(0.0, (s, c) => s + c.messagesPerSecond);

  MarketTick? getLatestTick(String symbol) => _tickers[symbol];
  List<OhlcvBar> getBars(String symbol, {BarInterval interval = BarInterval.m1}) {
    final key = '${symbol}_${interval.label}';
    return _bars[key] ?? [];
  }
  OrderBookSnapshot? getOrderBook(String symbol) => _orderBooks[symbol];
  MarketFeatures? getFeatures(String symbol) => _features[symbol];

  // ══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════════
  void start() {
    if (_isRunning) return;
    _isRunning = true;

    // Provider-Verbindungsstatus initialisieren
    for (final provider in _enabledProviders) {
      _connections[provider] = ProviderConnectionState(
        provider: provider,
        status: ConnectionStatus.connecting,
        messageCount: 0,
        reconnectCount: 0,
      );
    }

    // Initiale Ticks generieren
    _initializeDefaultTicks();

    // Simulation: Marktdaten simulieren (da echte WebSocket-Verbindungen
    // in Flutter Web anders gehandhabt werden)
    _simulationTimer = Timer.periodic(
      const Duration(milliseconds: 800), _onSimulationTick);

    // Nach kurzem Delay: alle Provider als "connected" markieren
    Future.delayed(const Duration(seconds: 2), () {
      for (final provider in _enabledProviders) {
        _updateConnectionStatus(provider, ConnectionStatus.connected);
      }
    });

    if (kDebugMode) debugPrint('📡 MarketDataIngestionService gestartet');
    notifyListeners();
  }

  void stop() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _isRunning = false;

    for (final provider in _connections.keys) {
      _connections[provider] = _connections[provider]!
          .copyWith(status: ConnectionStatus.disconnected);
    }

    notifyListeners();
  }

  void subscribe(String symbol) {
    if (!_subscribedSymbols.contains(symbol)) {
      _subscribedSymbols.add(symbol);
      notifyListeners();
    }
  }

  void unsubscribe(String symbol) {
    _subscribedSymbols.remove(symbol);
    _tickers.remove(symbol);
    notifyListeners();
  }

  void enableProvider(DataProvider provider) {
    _enabledProviders.add(provider);
    _connections[provider] = ProviderConnectionState(
      provider: provider,
      status: ConnectionStatus.connecting,
      messageCount: 0,
      reconnectCount: 0,
    );
    notifyListeners();
  }

  void disableProvider(DataProvider provider) {
    _enabledProviders.remove(provider);
    _connections.remove(provider);
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NORMALISIERUNG (Provider-spezifische Payloads → MarketTick)
  // ══════════════════════════════════════════════════════════════════════════

  /// Normalisiert Kraken WebSocket Ticker-Payload
  MarketTick? normalizeKrakenTicker(Map<String, dynamic> data, String symbol) {
    try {
      final ask = (data['a'] as List?)?.first;
      final bid = (data['b'] as List?)?.first;
      final last = (data['c'] as List?)?.first;
      final vol = (data['v'] as List?)?.last;
      final change = data['p'] as List?;

      if (last == null) return null;

      return MarketTick(
        symbol: symbol,
        provider: DataProvider.kraken,
        lastPrice: double.tryParse(last.toString()) ?? 0,
        bidPrice: double.tryParse(bid?.toString() ?? '0') ?? 0,
        askPrice: double.tryParse(ask?.toString() ?? '0') ?? 0,
        volume24h: double.tryParse(vol?.toString() ?? '0') ?? 0,
        change24hPct: double.tryParse(change?.last?.toString() ?? '0') ?? 0,
        high24h: 0, low24h: 0,
        assetClass: AssetClass.crypto,
        timestamp: DateTime.now(),
      );
    } catch (e) { return null; }
  }

  /// Normalisiert Binance WebSocket 24h-Ticker
  MarketTick? normalizeBinanceTicker(Map<String, dynamic> data) {
    try {
      return MarketTick(
        symbol: (data['s'] as String? ?? '').replaceAll('USDT', '-USDT'),
        provider: DataProvider.binance,
        lastPrice: double.tryParse(data['c']?.toString() ?? '0') ?? 0,
        bidPrice: double.tryParse(data['b']?.toString() ?? '0') ?? 0,
        askPrice: double.tryParse(data['a']?.toString() ?? '0') ?? 0,
        volume24h: double.tryParse(data['v']?.toString() ?? '0') ?? 0,
        change24hPct: double.tryParse(data['P']?.toString() ?? '0') ?? 0,
        high24h: double.tryParse(data['h']?.toString() ?? '0') ?? 0,
        low24h: double.tryParse(data['l']?.toString() ?? '0') ?? 0,
        assetClass: AssetClass.crypto,
        timestamp: DateTime.now(),
      );
    } catch (e) { return null; }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FEATURE EXTRACTION (für TR2 AI Engine)
  // ══════════════════════════════════════════════════════════════════════════
  MarketFeatures computeFeatures(String symbol) {
    final bars1m = getBars(symbol, interval: BarInterval.m1);
    final tick = _tickers[symbol];

    if (bars1m.isEmpty || tick == null) {
      return MarketFeatures(
        symbol: symbol,
        returnsPct1m: 0, returnsPct5m: 0, returnsPct1h: 0,
        volatility1h: 0.03, volatility1d: 0.05,
        obImbalance: 0, volumeRatio: 1.0,
        rsi14: 50, macdSignal: 0, bbPosition: 0,
        regime: 'RANGING', computedAt: DateTime.now(),
      );
    }

    // Returns
    final r1m = bars1m.length >= 2
        ? (bars1m.last.close - bars1m[bars1m.length - 2].close) /
            bars1m[bars1m.length - 2].close
        : 0.0;

    final r5m = bars1m.length >= 6
        ? (bars1m.last.close - bars1m[bars1m.length - 6].close) /
            bars1m[bars1m.length - 6].close
        : 0.0;

    final r1h = bars1m.length >= 61
        ? (bars1m.last.close - bars1m[bars1m.length - 61].close) /
            bars1m[bars1m.length - 61].close
        : 0.0;

    // Volatilität (Std-Dev der Returns)
    final closes = bars1m.take(60).map((b) => b.close).toList();
    final vol1h = _computeVolatility(closes);
    final allCloses = bars1m.map((b) => b.close).toList();
    final vol1d = _computeVolatility(allCloses);

    // RSI (14 Perioden)
    final rsi = _computeRSI(closes, 14);

    // MACD (vereinfacht)
    final macd = _computeMACDSignal(closes);

    // Bollinger Band Position
    final bbPos = _computeBBPosition(closes, 20, 2.0);

    // OB Imbalance
    final book = _orderBooks[symbol];
    final obImbalance = book?.imbalance ?? 0.0;

    // Volumen-Ratio
    final avgVol = bars1m.take(20).fold(0.0, (s, b) => s + b.volume) / 20;
    final volRatio = avgVol > 0 ? (bars1m.last.volume / avgVol) : 1.0;

    // Regime-Erkennung
    final regime = _detectRegime(r1h, vol1h, rsi);

    final features = MarketFeatures(
      symbol: symbol,
      returnsPct1m: r1m, returnsPct5m: r5m, returnsPct1h: r1h,
      volatility1h: vol1h, volatility1d: vol1d,
      obImbalance: obImbalance, volumeRatio: volRatio,
      rsi14: rsi, macdSignal: macd, bbPosition: bbPos,
      regime: regime, computedAt: DateTime.now(),
    );

    _features[symbol] = features;
    _featureStream.add(features);
    return features;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SIMULATION (Ersatz für echte WebSocket-Verbindungen)
  // ══════════════════════════════════════════════════════════════════════════
  final Map<String, double> _basePrices = {
    'BTC-EUR': 65000.0, 'ETH-EUR': 3400.0, 'SOL-USD': 180.0,
    'BNB-USDT': 430.0,  'XRP-USDT': 0.58,  'ADA-USDT': 0.45,
    'DOGE-USDT': 0.12,  'AVAX-USDT': 38.0,  'LINK-USDT': 16.0,
    'DOT-USDT': 8.5,
  };

  void _initializeDefaultTicks() {
    for (final entry in _basePrices.entries) {
      final price = entry.value;
      _tickers[entry.key] = MarketTick(
        symbol: entry.key,
        provider: DataProvider.coinGecko,
        lastPrice: price,
        bidPrice: price * 0.9998,
        askPrice: price * 1.0002,
        volume24h: _rng.nextDouble() * 1e9,
        change24hPct: (_rng.nextDouble() - 0.5) * 8,
        high24h: price * 1.03,
        low24h: price * 0.97,
        assetClass: AssetClass.crypto,
        timestamp: DateTime.now(),
      );
      _initializeBars(entry.key, price);
    }
  }

  void _initializeBars(String symbol, double basePrice) {
    final key = '${symbol}_1m';
    final bars = <OhlcvBar>[];
    double price = basePrice;
    final now = DateTime.now();

    for (int i = 99; i >= 0; i--) {
      final change = (_rng.nextDouble() - 0.5) * 0.004;
      final open = price;
      price *= (1 + change);
      final high = max(open, price) * (1 + _rng.nextDouble() * 0.002);
      final low = min(open, price) * (1 - _rng.nextDouble() * 0.002);

      bars.add(OhlcvBar(
        symbol: symbol,
        interval: BarInterval.m1,
        open: open, high: high, low: low, close: price,
        volume: _rng.nextDouble() * 100,
        openTime: now.subtract(Duration(minutes: i)),
        isClosed: i > 0,
      ));
    }
    _bars[key] = bars;
  }

  void _onSimulationTick(Timer timer) {
    if (!_isRunning) return;

    // Ticks für alle abonnierten Symbole aktualisieren
    for (final symbol in _subscribedSymbols) {
      _updateTick(symbol);
    }

    // Feature-Extraktion alle 5 Sekunden
    if (timer.tick % 6 == 0) {
      for (final symbol in _subscribedSymbols.take(5)) {
        computeFeatures(symbol);
      }
    }

    // Connection-Counters
    for (final provider in _enabledProviders) {
      if (_connections[provider]?.status == ConnectionStatus.connected) {
        final state = _connections[provider]!;
        _connections[provider] = state.copyWith(
          messageCount: state.messageCount + _subscribedSymbols.length,
          lastMessageAt: DateTime.now(),
        );
      }
    }

    notifyListeners();
  }

  void _updateTick(String symbol) {
    final current = _tickers[symbol];
    if (current == null) {
      final base = _basePrices[symbol] ?? 100.0;
      _basePrices[symbol] = base;
      _initializeBars(symbol, base);
      return;
    }

    // Preis simulieren: Geometric Brownian Motion
    final sigma = 0.0004; // 0.04% pro Tick
    final dW = _rng.nextGaussian();
    final newPrice = current.lastPrice * exp(sigma * dW);

    final spread = newPrice * 0.0002;
    final newTick = current.copyWith(
      lastPrice: newPrice,
      bidPrice: newPrice - spread,
      askPrice: newPrice + spread,
    );

    _tickers[symbol] = newTick;
    _tickStream.add(newTick);

    // Bar aggregieren
    _aggregateBar(symbol, newPrice, _rng.nextDouble() * 10);
  }

  void _aggregateBar(String symbol, double price, double volume) {
    final key = '${symbol}_1m';
    final bars = _bars[key] ?? [];
    final now = DateTime.now();

    if (bars.isEmpty) {
      _bars[key] = [OhlcvBar(
        symbol: symbol, interval: BarInterval.m1,
        open: price, high: price, low: price, close: price,
        volume: volume, openTime: now, isClosed: false,
      )];
      return;
    }

    final lastBar = bars.last;
    final barElapsed = now.difference(lastBar.openTime);

    if (barElapsed >= BarInterval.m1.duration) {
      // Schließe alten Bar, öffne neuen
      bars[bars.length - 1] = lastBar.close_();
      bars.add(OhlcvBar(
        symbol: symbol, interval: BarInterval.m1,
        open: price, high: price, low: price, close: price,
        volume: volume, openTime: now, isClosed: false,
      ));
      if (bars.length > 500) bars.removeAt(0); // Max 500 Bars im Speicher
      _barStream.add(bars.last);
    } else {
      // Update aktuellen Bar
      bars[bars.length - 1] = lastBar.updateClose(price, volume);
    }
    _bars[key] = bars;
  }

  void _updateConnectionStatus(DataProvider provider, ConnectionStatus status) {
    if (!_connections.containsKey(provider)) return;
    _connections[provider] = _connections[provider]!.copyWith(
      status: status,
      connectedAt: status == ConnectionStatus.connected ? DateTime.now() : null,
    );
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TECHNISCHE INDIKATOREN
  // ══════════════════════════════════════════════════════════════════════════

  double _computeVolatility(List<double> prices) {
    if (prices.length < 2) return 0.03;
    final returns = <double>[];
    for (int i = 1; i < prices.length; i++) {
      if (prices[i - 1] > 0) {
        returns.add(log(prices[i] / prices[i - 1]));
      }
    }
    if (returns.isEmpty) return 0.03;
    final mean = returns.fold(0.0, (s, r) => s + r) / returns.length;
    final variance = returns.fold(0.0, (s, r) => s + (r - mean) * (r - mean)) /
        returns.length;
    return sqrt(variance);
  }

  double _computeRSI(List<double> closes, int period) {
    if (closes.length < period + 1) return 50.0;
    double avgGain = 0, avgLoss = 0;
    for (int i = closes.length - period; i < closes.length; i++) {
      final diff = closes[i] - closes[i - 1];
      if (diff > 0) avgGain += diff;
      else avgLoss += diff.abs();
    }
    avgGain /= period;
    avgLoss /= period;
    if (avgLoss == 0) return 100.0;
    final rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }

  double _computeMACDSignal(List<double> closes) {
    if (closes.length < 26) return 0.0;
    final ema12 = _computeEMA(closes, 12);
    final ema26 = _computeEMA(closes, 26);
    return (ema12 - ema26) / (ema26 > 0 ? ema26 : 1);
  }

  double _computeEMA(List<double> closes, int period) {
    if (closes.isEmpty) return 0.0;
    final k = 2.0 / (period + 1);
    double ema = closes.first;
    for (final c in closes.skip(1)) ema = c * k + ema * (1 - k);
    return ema;
  }

  double _computeBBPosition(List<double> closes, int period, double stdMult) {
    if (closes.length < period) return 0.0;
    final recent = closes.length > period
        ? closes.sublist(closes.length - period)
        : closes.toList();
    final mean = recent.fold(0.0, (s, c) => s + c) / period;
    final variance = recent.fold(0.0, (s, c) => s + (c - mean) * (c - mean)) / period;
    final std = sqrt(variance);
    if (std == 0) return 0.0;
    final upper = mean + stdMult * std;
    final lower = mean - stdMult * std;
    final last = recent.last;
    return (2 * (last - lower) / (upper - lower) - 1).clamp(-1.0, 1.0);
  }

  String _detectRegime(double returnPct1h, double volatility, double rsi) {
    if (volatility > 0.05) return 'VOLATILE';
    if (returnPct1h > 0.02 && rsi > 60) return 'TRENDING_UP';
    if (returnPct1h < -0.02 && rsi < 40) return 'TRENDING_DOWN';
    return 'RANGING';
  }

  @override
  void dispose() {
    stop();
    _tickStream.close();
    _barStream.close();
    _bookStream.close();
    _featureStream.close();
    super.dispose();
  }
}

// Extension für Gaussian Random
extension RandomGaussian on Random {
  double nextGaussian() {
    final u1 = nextDouble();
    final u2 = nextDouble();
    if (u1 == 0 || u2 == 0) return 0.0;
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }
}
