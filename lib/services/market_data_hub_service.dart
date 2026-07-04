// ════════════════════════════════════════════════════════════════════════════
// MARKET DATA HUB SERVICE  v54.0
// Quantum Trader AI — Enterprise Multi-Exchange WebSocket Hub
// Binance · Kraken · Coinbase · Bybit · OKX
// Features: Auto-Reconnect · Exponential Backoff · Tick-Storage · Health Monitor
// MiFID II Art.17 compliant connection management
// ════════════════════════════════════════════════════════════════════════════
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import 'websocket_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EXCHANGE HEALTH RECORD
// ─────────────────────────────────────────────────────────────────────────────

class ExchangeHealth {
  final String exchange;
  ExchangeStatus status;
  DateTime? lastTickAt;
  int tickCount;
  int reconnectCount;
  double latencyMs;
  int missedHeartbeats;
  final List<double> latencyHistory; // rolling 20

  ExchangeHealth(this.exchange)
      : status = ExchangeStatus.disconnected,
        tickCount = 0,
        reconnectCount = 0,
        latencyMs = 0,
        missedHeartbeats = 0,
        latencyHistory = [];

  bool get isStale {
    if (lastTickAt == null) return true;
    return DateTime.now().difference(lastTickAt!).inSeconds > 10;
  }

  bool get isHealthy =>
      status == ExchangeStatus.connected && !isStale;

  void recordTick(double latency) {
    tickCount++;
    lastTickAt = DateTime.now();
    latencyMs = latency;
    latencyHistory.add(latency);
    if (latencyHistory.length > 20) latencyHistory.removeAt(0);
    missedHeartbeats = 0;
  }

  double get avgLatency {
    if (latencyHistory.isEmpty) return 0;
    return latencyHistory.reduce((a, b) => a + b) / latencyHistory.length;
  }

  String get statusLabel {
    switch (status) {
      case ExchangeStatus.connected: return isStale ? 'STALE' : 'LIVE';
      case ExchangeStatus.connecting: return 'CONNECTING';
      case ExchangeStatus.disconnected: return 'OFFLINE';
      case ExchangeStatus.error: return 'ERROR';
      case ExchangeStatus.rateLimit: return 'RATE LIMIT';
    }
  }

  String get uptimeDisplay {
    if (tickCount == 0) return '—';
    return '${tickCount.toString()} ticks';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TICK RING BUFFER — Last N ticks per symbol per exchange
// ─────────────────────────────────────────────────────────────────────────────

class TickBuffer {
  static const int maxSize = 500;
  final List<PriceTick> _buffer = [];

  void add(PriceTick tick) {
    _buffer.add(tick);
    if (_buffer.length > maxSize) _buffer.removeAt(0);
  }

  List<PriceTick> get all => List.unmodifiable(_buffer);

  List<PriceTick> forSymbol(String symbol) =>
      _buffer.where((t) => t.symbol == symbol).toList();

  List<PriceTick> forExchange(String exchange) =>
      _buffer.where((t) => t.exchange == exchange).toList();

  PriceTick? latest(String symbol) {
    for (int i = _buffer.length - 1; i >= 0; i--) {
      if (_buffer[i].symbol == symbol) return _buffer[i];
    }
    return null;
  }

  double? vwap(String symbol, {int lastN = 50}) {
    final ticks = forSymbol(symbol).reversed.take(lastN).toList();
    if (ticks.isEmpty) return null;
    double sumPV = 0, sumV = 0;
    for (final t in ticks) {
      sumPV += t.price * t.volume24h;
      sumV += t.volume24h;
    }
    return sumV > 0 ? sumPV / sumV : null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MULTI-FEED AGGREGATOR — Best-price selection across all exchanges
// ─────────────────────────────────────────────────────────────────────────────

class MultiFeedAggregator {
  final Map<String, Map<String, PriceTick>> _exchangeTicks = {};
  // symbol → exchangeName → PriceTick

  void update(PriceTick tick) {
    _exchangeTicks.putIfAbsent(tick.symbol, () => {});
    _exchangeTicks[tick.symbol]![tick.exchange] = tick;
  }

  /// Returns best bid from all exchanges for a symbol
  double? bestBid(String symbol) {
    final map = _exchangeTicks[symbol];
    if (map == null || map.isEmpty) return null;
    return map.values
        .map((t) => t.bid)
        .where((b) => b > 0)
        .fold<double?>(null, (best, b) => best == null || b > best ? b : best);
  }

  /// Returns best ask from all exchanges for a symbol
  double? bestAsk(String symbol) {
    final map = _exchangeTicks[symbol];
    if (map == null || map.isEmpty) return null;
    return map.values
        .map((t) => t.ask)
        .where((a) => a > 0)
        .fold<double?>(null, (best, a) => best == null || a < best ? a : best);
  }

  /// Spread in bps between best bid and best ask
  double? spreadBps(String symbol) {
    final bid = bestBid(symbol);
    final ask = bestAsk(symbol);
    if (bid == null || ask == null || bid == 0) return null;
    return (ask - bid) / bid * 10000;
  }

  /// Volume-weighted average price from all exchanges
  PriceTick? compositeTick(String symbol) {
    final map = _exchangeTicks[symbol];
    if (map == null || map.isEmpty) return null;

    final ticks = map.values.where((t) => t.price > 0).toList();
    if (ticks.isEmpty) return null;

    double totalVol = ticks.fold(0.0, (s, t) => s + t.volume24h);
    if (totalVol == 0) return ticks.first;

    double wPrice = 0, wChange = 0;
    for (final t in ticks) {
      final w = t.volume24h / totalVol;
      wPrice += t.price * w;
      wChange += t.change24h * w;
    }

    final best = ticks.reduce((a, b) =>
        a.volume24h > b.volume24h ? a : b);

    return PriceTick(
      symbol: symbol,
      price: wPrice,
      change24h: wChange,
      volume24h: totalVol,
      high24h: ticks.map((t) => t.high24h).reduce(max),
      low24h: ticks.map((t) => t.low24h).where((v) => v > 0).reduce(min),
      bid: bestBid(symbol) ?? best.bid,
      ask: bestAsk(symbol) ?? best.ask,
      exchange: 'COMPOSITE',
      timestamp: DateTime.now(),
      isLive: true,
    );
  }

  Map<String, PriceTick> get allLatestBySymbol {
    final result = <String, PriceTick>{};
    for (final sym in _exchangeTicks.keys) {
      final composite = compositeTick(sym);
      if (composite != null) result[sym] = composite;
    }
    return result;
  }

  Map<String, PriceTick>? ticksForSymbol(String symbol) =>
      _exchangeTicks[symbol];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARKET DATA HUB SERVICE  — Central Singleton
// ─────────────────────────────────────────────────────────────────────────────

class MarketDataHubService extends ChangeNotifier {
  static final MarketDataHubService _instance = MarketDataHubService._();
  factory MarketDataHubService() => _instance;
  MarketDataHubService._();

  // ── Sub-systems ────────────────────────────────────────────────────────────
  final WebSocketManager _wsManager = WebSocketManager();
  final MultiFeedAggregator _aggregator = MultiFeedAggregator();
  final TickBuffer _tickBuffer = TickBuffer();

  // ── Exchange Health Map ────────────────────────────────────────────────────
  final Map<String, ExchangeHealth> _health = {
    'Binance':  ExchangeHealth('Binance'),
    'Coinbase': ExchangeHealth('Coinbase'),
    'Kraken':   ExchangeHealth('Kraken'),
    'Bybit':    ExchangeHealth('Bybit'),
    'OKX':      ExchangeHealth('OKX'),
  };

  // ── State ──────────────────────────────────────────────────────────────────
  bool _running = false;
  bool _killSwitchActive = false;
  DateTime? _startedAt;
  Timer? _healthMonitor;
  Timer? _staleCheckTimer;
  final List<StreamSubscription> _subs = [];

  // ── Composite price cache ──────────────────────────────────────────────────
  final Map<String, PriceTick> _compositePrices = {};

  // ── Stream for downstream consumers ───────────────────────────────────────
  final StreamController<PriceTick> _tickStreamCtrl =
      StreamController<PriceTick>.broadcast();

  final StreamController<Map<String, ExchangeHealth>> _healthStreamCtrl =
      StreamController<Map<String, ExchangeHealth>>.broadcast();

  // ── Public accessors ───────────────────────────────────────────────────────
  Stream<PriceTick> get tickStream => _tickStreamCtrl.stream;
  Stream<Map<String, ExchangeHealth>> get healthStream =>
      _healthStreamCtrl.stream;

  Map<String, PriceTick> get prices => Map.unmodifiable(_compositePrices);
  Map<String, ExchangeHealth> get health => Map.unmodifiable(_health);
  TickBuffer get tickBuffer => _tickBuffer;
  MultiFeedAggregator get aggregator => _aggregator;
  bool get isRunning => _running;
  bool get killSwitchActive => _killSwitchActive;
  DateTime? get startedAt => _startedAt;
  WebSocketManager get wsManager => _wsManager;

  int get connectedExchanges =>
      _health.values.where((h) => h.status == ExchangeStatus.connected).length;

  int get healthyExchanges =>
      _health.values.where((h) => h.isHealthy).length;

  double get totalTickRate {
    if (_startedAt == null) return 0;
    final seconds =
        DateTime.now().difference(_startedAt!).inSeconds.clamp(1, 999999);
    final total =
        _health.values.fold<int>(0, (sum, h) => sum + h.tickCount);
    return total / seconds;
  }

  // ── Start Hub ──────────────────────────────────────────────────────────────
  Future<void> start({List<String>? symbols}) async {
    if (_running || _killSwitchActive) return;
    _running = true;
    _startedAt = DateTime.now();

    final syms = symbols ?? WebSocketManager.defaultSymbols;
    if (kDebugMode) debugPrint('[HUB] Starting with ${syms.length} symbols');

    // Start underlying WS manager
    await _wsManager.start(symbols: syms);

    // Subscribe to all exchange tick streams
    _wireTicks(_wsManager.binance);
    _wireTicks(_wsManager.coinbase);
    _wireTicks(_wsManager.kraken);
    _wireTicks(_wsManager.bybit);
    _wireTicks(_wsManager.okx);

    // Subscribe to status streams for health tracking
    _wireStatus(_wsManager.binance);
    _wireStatus(_wsManager.coinbase);
    _wireStatus(_wsManager.kraken);
    _wireStatus(_wsManager.bybit);
    _wireStatus(_wsManager.okx);

    // Start health monitor (every 5 seconds)
    _healthMonitor = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkHealth();
    });

    // Stale detection (every 15 seconds)
    _staleCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkStaleConnections(syms);
    });

    notifyListeners();
  }

  void _wireTicks(ExchangeConnector connector) {
    final sub = connector.tickStream.listen((tick) {
      if (_killSwitchActive) return;
      final sendTime = DateTime.now().millisecondsSinceEpoch.toDouble();
      final latency = DateTime.now().millisecondsSinceEpoch - sendTime;

      _health[connector.name]?.recordTick(latency.abs().clamp(0, 9999));
      _aggregator.update(tick);
      _tickBuffer.add(tick);

      // Compute composite
      final composite = _aggregator.compositeTick(tick.symbol);
      if (composite != null) {
        _compositePrices[tick.symbol] = composite;
        _tickStreamCtrl.add(composite);
      }

      notifyListeners();
    });
    _subs.add(sub);
  }

  void _wireStatus(ExchangeConnector connector) {
    final sub = connector.statusStream.listen((status) {
      _health[connector.name]?.status = status;
      if (status == ExchangeStatus.error ||
          status == ExchangeStatus.disconnected) {
        _health[connector.name]?.reconnectCount++;
      }
      _healthStreamCtrl.add(Map.unmodifiable(_health));
      notifyListeners();
    });
    _subs.add(sub);
  }

  void _checkHealth() {
    bool changed = false;
    for (final h in _health.values) {
      final prevStatus = h.status;
      // Sync status from actual connector
      final connector = _connectorFor(h.exchange);
      if (connector != null && h.status != connector.status) {
        h.status = connector.status;
        changed = true;
      }
      if (h.isStale && h.status == ExchangeStatus.connected) {
        h.missedHeartbeats++;
        changed = true;
      }
      if (kDebugMode && prevStatus != h.status) {
        debugPrint('[HUB] ${h.exchange}: $prevStatus → ${h.status}');
      }
    }
    if (changed) {
      _healthStreamCtrl.add(Map.unmodifiable(_health));
      notifyListeners();
    }
  }

  void _checkStaleConnections(List<String> syms) {
    for (final h in _health.values) {
      if (h.isStale && h.status == ExchangeStatus.connected) {
        if (kDebugMode) debugPrint('[HUB] Stale: ${h.exchange} — triggering reconnect');
        final connector = _connectorFor(h.exchange);
        connector?.disconnect();
        Future.delayed(const Duration(seconds: 2), () {
          if (_running && !_killSwitchActive) {
            connector?.connect(syms);
          }
        });
      }
    }
  }

  ExchangeConnector? _connectorFor(String name) {
    switch (name) {
      case 'Binance': return _wsManager.binance;
      case 'Coinbase': return _wsManager.coinbase;
      case 'Kraken': return _wsManager.kraken;
      case 'Bybit': return _wsManager.bybit;
      case 'OKX': return _wsManager.okx;
      default: return null;
    }
  }

  // ── Kill Switch (MiFID II Art. 17) ────────────────────────────────────────
  void activateKillSwitch({String reason = 'Manual kill switch'}) {
    _killSwitchActive = true;
    if (kDebugMode) debugPrint('[HUB][KILL-SWITCH] Activated: $reason');
    stop();
    notifyListeners();
  }

  void deactivateKillSwitch() {
    _killSwitchActive = false;
    notifyListeners();
  }

  // ── Stop ──────────────────────────────────────────────────────────────────
  void stop() {
    _running = false;
    _healthMonitor?.cancel();
    _staleCheckTimer?.cancel();
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    _wsManager.stop();
    notifyListeners();
  }

  // ── Manual reconnect single exchange ──────────────────────────────────────
  Future<void> reconnectExchange(String name, List<String> symbols) async {
    if (_killSwitchActive) return;
    final connector = _connectorFor(name);
    if (connector == null) return;
    connector.disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await connector.connect(symbols);
    _wireTicks(connector);
    _wireStatus(connector);
    notifyListeners();
  }

  // ── Price Accessors ────────────────────────────────────────────────────────
  PriceTick? getCompositePrice(String symbol) => _compositePrices[symbol];

  PriceTick? getPriceFromExchange(String symbol, String exchange) =>
      _aggregator.ticksForSymbol(symbol)?[exchange];

  double? bestBid(String symbol) => _aggregator.bestBid(symbol);
  double? bestAsk(String symbol) => _aggregator.bestAsk(symbol);
  double? spreadBps(String symbol) => _aggregator.spreadBps(symbol);

  List<PriceTick> recentTicks(String symbol, {int n = 20}) =>
      _tickBuffer.forSymbol(symbol).reversed.take(n).toList();

  List<PriceTick> exchangeTicks(String exchange, {int n = 20}) =>
      _tickBuffer.forExchange(exchange).reversed.take(n).toList();

  // ── Hub Statistics ─────────────────────────────────────────────────────────
  Map<String, dynamic> get stats => {
    'running': _running,
    'connected_exchanges': connectedExchanges,
    'healthy_exchanges': healthyExchanges,
    'total_tick_rate': totalTickRate.toStringAsFixed(1),
    'buffer_size': _tickBuffer.all.length,
    'tracked_symbols': _compositePrices.length,
    'kill_switch': _killSwitchActive,
    'uptime_seconds': _startedAt != null
        ? DateTime.now().difference(_startedAt!).inSeconds
        : 0,
  };

  @override
  void dispose() {
    stop();
    _wsManager.dispose();
    _tickStreamCtrl.close();
    _healthStreamCtrl.close();
    super.dispose();
  }
}


