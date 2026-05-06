// ============================================================
// WEBSOCKET SERVICE – Quantum Trader v20
// Binance · Coinbase · Kraken · Bybit · OKX Live Streams
// ============================================================
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// ── Tick Model ────────────────────────────────────────────
class PriceTick {
  final String symbol;
  final double price;
  final double change24h;
  final double volume24h;
  final double high24h;
  final double low24h;
  final double bid;
  final double ask;
  final String exchange;
  final DateTime timestamp;
  final bool isLive;

  const PriceTick({
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.volume24h,
    required this.high24h,
    required this.low24h,
    required this.bid,
    required this.ask,
    required this.exchange,
    required this.timestamp,
    this.isLive = true,
  });

  PriceTick copyWith({double? price, double? change24h, double? bid, double? ask}) => PriceTick(
    symbol: symbol,
    price: price ?? this.price,
    change24h: change24h ?? this.change24h,
    volume24h: volume24h,
    high24h: high24h,
    low24h: low24h,
    bid: bid ?? this.bid,
    ask: ask ?? this.ask,
    exchange: exchange,
    timestamp: DateTime.now(),
    isLive: isLive,
  );

  String get formattedPrice {
    if (price >= 10000) return '\$${price.toStringAsFixed(0)}';
    if (price >= 1000) return '\$${price.toStringAsFixed(1)}';
    if (price >= 1) return '\$${price.toStringAsFixed(3)}';
    return '\$${price.toStringAsFixed(5)}';
  }

  String get formattedChange =>
      '${change24h >= 0 ? "+" : ""}${change24h.toStringAsFixed(2)}%';

  bool get isPositive => change24h >= 0;
}

// ── Orderbook Entry ──────────────────────────────────────
class OrderbookEntry {
  final double price;
  final double amount;
  final bool isBid;
  const OrderbookEntry(this.price, this.amount, this.isBid);
}

// ── Trade Entry ──────────────────────────────────────────
class TradeEntry {
  final String symbol;
  final double price;
  final double amount;
  final bool isBuy;
  final DateTime time;
  const TradeEntry(this.symbol, this.price, this.amount, this.isBuy, this.time);
}

// ── Exchange Connector Base ───────────────────────────────
enum ExchangeStatus { disconnected, connecting, connected, error, rateLimit }

abstract class ExchangeConnector {
  String get name;
  String get wsUrl;
  ExchangeStatus status = ExchangeStatus.disconnected;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  int _reconnectAttempts = 0;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  final _tickController = StreamController<PriceTick>.broadcast();
  final _tradeController = StreamController<TradeEntry>.broadcast();
  final _statusController = StreamController<ExchangeStatus>.broadcast();

  Stream<PriceTick> get tickStream => _tickController.stream;
  Stream<TradeEntry> get tradeStream => _tradeController.stream;
  Stream<ExchangeStatus> get statusStream => _statusController.stream;

  bool get isConnected => status == ExchangeStatus.connected;

  Future<void> connect(List<String> symbols) async {
    if (status == ExchangeStatus.connecting || status == ExchangeStatus.connected) return;
    _setStatus(ExchangeStatus.connecting);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _channel!.ready.timeout(const Duration(seconds: 10));
      _setStatus(ExchangeStatus.connected);
      _reconnectAttempts = 0;
      _sub = _channel!.stream.listen(
        (data) => _handleMessage(data),
        onError: (_) => _scheduleReconnect(symbols),
        onDone: () => _scheduleReconnect(symbols),
      );
      subscribe(symbols);
      _startPing();
    } catch (_) {
      _setStatus(ExchangeStatus.error);
      _scheduleReconnect(symbols);
    }
  }

  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _setStatus(ExchangeStatus.disconnected);
  }

  void _scheduleReconnect(List<String> symbols) {
    if (status == ExchangeStatus.disconnected) return;
    _setStatus(ExchangeStatus.error);
    final delay = Duration(seconds: min(30, 2 * (++_reconnectAttempts)));
    _reconnectTimer = Timer(delay, () => connect(symbols));
  }

  void _setStatus(ExchangeStatus s) {
    status = s;
    _statusController.add(s);
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) => sendPing());
  }

  void sendMessage(dynamic msg) {
    if (isConnected) _channel?.sink.add(jsonEncode(msg));
  }

  void emitTick(PriceTick tick) => _tickController.add(tick);
  void emitTrade(TradeEntry trade) => _tradeController.add(trade);

  void subscribe(List<String> symbols);
  void sendPing() {}
  void _handleMessage(dynamic raw);

  void dispose() {
    disconnect();
    _tickController.close();
    _tradeController.close();
    _statusController.close();
  }
}

// ── BINANCE Connector ─────────────────────────────────────
class BinanceConnector extends ExchangeConnector {
  @override
  String get name => 'Binance';

  // Build combined stream URL for multiple symbols
  List<String> _currentSymbols = [];

  @override
  String get wsUrl {
    if (_currentSymbols.isEmpty) return 'wss://stream.binance.com:9443/ws';
    final streams = _currentSymbols
        .map((s) => '${s.toLowerCase()}usdt@ticker')
        .join('/');
    return 'wss://stream.binance.com:9443/stream?streams=$streams';
  }

  @override
  Future<void> connect(List<String> symbols) async {
    _currentSymbols = symbols;
    await super.connect(symbols);
  }

  @override
  void subscribe(List<String> symbols) {
    // For combined stream URL, subscription is in the URL itself
    // Individual subscription for dynamic additions:
    sendMessage({
      'method': 'SUBSCRIBE',
      'params': symbols.map((s) => '${s.toLowerCase()}usdt@ticker').toList(),
      'id': 1,
    });
  }

  @override
  void sendPing() => sendMessage({'method': 'PING'});

  @override
  void _handleMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      // Handle combined stream wrapper
      final data = json.containsKey('data')
          ? json['data'] as Map<String, dynamic>
          : json;

      if (data['e'] == '24hrTicker') {
        final sym = (data['s'] as String).replaceAll('USDT', '');
        emitTick(PriceTick(
          symbol: sym,
          price: double.tryParse(data['c']?.toString() ?? '0') ?? 0,
          change24h: double.tryParse(data['P']?.toString() ?? '0') ?? 0,
          volume24h: double.tryParse(data['q']?.toString() ?? '0') ?? 0,
          high24h: double.tryParse(data['h']?.toString() ?? '0') ?? 0,
          low24h: double.tryParse(data['l']?.toString() ?? '0') ?? 0,
          bid: double.tryParse(data['b']?.toString() ?? '0') ?? 0,
          ask: double.tryParse(data['a']?.toString() ?? '0') ?? 0,
          exchange: 'Binance',
          timestamp: DateTime.now(),
        ));
      }
    } catch (_) {}
  }
}

// ── COINBASE Connector ────────────────────────────────────
class CoinbaseConnector extends ExchangeConnector {
  @override
  String get name => 'Coinbase';
  @override
  String get wsUrl => 'wss://advanced-trade-ws.coinbase.com';

  @override
  void subscribe(List<String> symbols) {
    sendMessage({
      'type': 'subscribe',
      'product_ids': symbols.map((s) => '$s-USD').toList(),
      'channel': 'ticker',
    });
  }

  @override
  void sendPing() {
    sendMessage({'type': 'heartbeats', 'channel': 'heartbeats', 'product_ids': []});
  }

  @override
  void _handleMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      if (json['channel'] == 'ticker') {
        final events = json['events'] as List?;
        if (events == null) return;
        for (final event in events) {
          final tickers = (event as Map)['tickers'] as List?;
          if (tickers == null) continue;
          for (final t in tickers) {
            final sym = ((t as Map)['product_id'] as String).replaceAll('-USD', '');
            final price = double.tryParse(t['price']?.toString() ?? '0') ?? 0;
            final open24h = double.tryParse(t['open_24_h']?.toString() ?? '0') ?? 0;
            final change = open24h > 0 ? (price - open24h) / open24h * 100 : 0.0;
            emitTick(PriceTick(
              symbol: sym,
              price: price,
              change24h: change,
              volume24h: double.tryParse(t['volume_24_h']?.toString() ?? '0') ?? 0,
              high24h: double.tryParse(t['high_52_weeks']?.toString() ?? '0') ?? 0,
              low24h: double.tryParse(t['low_52_weeks']?.toString() ?? '0') ?? 0,
              bid: double.tryParse(t['best_bid']?.toString() ?? '0') ?? 0,
              ask: double.tryParse(t['best_ask']?.toString() ?? '0') ?? 0,
              exchange: 'Coinbase',
              timestamp: DateTime.now(),
            ));
          }
        }
      }
    } catch (_) {}
  }
}

// ── KRAKEN Connector ──────────────────────────────────────
class KrakenConnector extends ExchangeConnector {
  @override
  String get name => 'Kraken';
  @override
  String get wsUrl => 'wss://ws.kraken.com/v2';

  final Map<String, String> _pairMap = {};

  @override
  void subscribe(List<String> symbols) {
    for (final s in symbols) {
      _pairMap['$s/USD'] = s;
    }
    sendMessage({
      'method': 'subscribe',
      'params': {
        'channel': 'ticker',
        'symbol': symbols.map((s) => '$s/USD').toList(),
      },
    });
  }

  @override
  void sendPing() => sendMessage({'method': 'ping'});

  @override
  void _handleMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      if (json['channel'] == 'ticker' && json['type'] == 'update') {
        final dataList = json['data'] as List?;
        if (dataList == null) return;
        for (final d in dataList) {
          final pair = (d as Map)['symbol'] as String;
          final sym = _pairMap[pair] ?? pair.replaceAll('/USD', '');
          final bid = (d['bid'] as num?)?.toDouble() ?? 0;
          final ask = (d['ask'] as num?)?.toDouble() ?? 0;
          final last = (d['last'] as num?)?.toDouble() ?? 0;
          final change = (d['change_pct'] as num?)?.toDouble() ?? 0;
          emitTick(PriceTick(
            symbol: sym,
            price: last,
            change24h: change,
            volume24h: (d['volume'] as num?)?.toDouble() ?? 0,
            high24h: (d['high'] as num?)?.toDouble() ?? 0,
            low24h: (d['low'] as num?)?.toDouble() ?? 0,
            bid: bid,
            ask: ask,
            exchange: 'Kraken',
            timestamp: DateTime.now(),
          ));
        }
      }
    } catch (_) {}
  }
}

// ── BYBIT Connector ───────────────────────────────────────
class BybitConnector extends ExchangeConnector {
  @override
  String get name => 'Bybit';
  @override
  String get wsUrl => 'wss://stream.bybit.com/v5/public/linear';

  @override
  void subscribe(List<String> symbols) {
    sendMessage({
      'op': 'subscribe',
      'args': symbols.map((s) => 'tickers.${s}USDT').toList(),
    });
  }

  @override
  void sendPing() => sendMessage({'op': 'ping'});

  @override
  void _handleMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      if (json['topic']?.toString().startsWith('tickers.') == true) {
        final d = json['data'] as Map<String, dynamic>?;
        if (d == null) return;
        final sym = (d['symbol'] as String).replaceAll('USDT', '');
        emitTick(PriceTick(
          symbol: sym,
          price: double.tryParse(d['lastPrice']?.toString() ?? '0') ?? 0,
          change24h: double.tryParse(d['price24hPcnt']?.toString() ?? '0') ?? 0,
          volume24h: double.tryParse(d['turnover24h']?.toString() ?? '0') ?? 0,
          high24h: double.tryParse(d['highPrice24h']?.toString() ?? '0') ?? 0,
          low24h: double.tryParse(d['lowPrice24h']?.toString() ?? '0') ?? 0,
          bid: double.tryParse(d['bid1Price']?.toString() ?? '0') ?? 0,
          ask: double.tryParse(d['ask1Price']?.toString() ?? '0') ?? 0,
          exchange: 'Bybit',
          timestamp: DateTime.now(),
        ));
      }
    } catch (_) {}
  }
}

// ── OKX Connector ─────────────────────────────────────────
class OKXConnector extends ExchangeConnector {
  @override
  String get name => 'OKX';
  @override
  String get wsUrl => 'wss://ws.okx.com:8443/ws/v5/public';

  @override
  void subscribe(List<String> symbols) {
    sendMessage({
      'op': 'subscribe',
      'args': symbols.map((s) => {'channel': 'tickers', 'instId': '$s-USDT'}).toList(),
    });
  }

  @override
  void sendPing() => _channel?.sink.add('ping');

  WebSocketChannel? get _channel => null;

  @override
  void _handleMessage(dynamic raw) {
    if (raw == 'pong') return;
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      if (json['arg']?['channel'] == 'tickers') {
        final dataList = json['data'] as List?;
        if (dataList == null) return;
        for (final d in dataList) {
          final instId = (d as Map)['instId'] as String;
          final sym = instId.replaceAll('-USDT', '');
          final last = double.tryParse(d['last']?.toString() ?? '0') ?? 0;
          final open24h = double.tryParse(d['open24h']?.toString() ?? '0') ?? 0;
          final change = open24h > 0 ? (last - open24h) / open24h * 100 : 0.0;
          emitTick(PriceTick(
            symbol: sym,
            price: last,
            change24h: change,
            volume24h: double.tryParse(d['volCcy24h']?.toString() ?? '0') ?? 0,
            high24h: double.tryParse(d['high24h']?.toString() ?? '0') ?? 0,
            low24h: double.tryParse(d['low24h']?.toString() ?? '0') ?? 0,
            bid: double.tryParse(d['bidPx']?.toString() ?? '0') ?? 0,
            ask: double.tryParse(d['askPx']?.toString() ?? '0') ?? 0,
            exchange: 'OKX',
            timestamp: DateTime.now(),
          ));
        }
      }
    } catch (_) {}
  }
}

// ── MAIN WebSocket Manager ────────────────────────────────
class WebSocketManager extends ChangeNotifier {
  static final WebSocketManager _instance = WebSocketManager._();
  factory WebSocketManager() => _instance;
  WebSocketManager._();

  final BinanceConnector binance = BinanceConnector();
  final CoinbaseConnector coinbase = CoinbaseConnector();
  final KrakenConnector kraken = KrakenConnector();
  final BybitConnector bybit = BybitConnector();
  final OKXConnector okx = OKXConnector();

  // Unified price map: symbol → best (lowest latency) PriceTick
  final Map<String, PriceTick> _prices = {};
  final Map<String, List<double>> _priceHistory = {};
  final List<TradeEntry> _recentTrades = [];

  // Which exchanges are enabled
  bool binanceEnabled = true;
  bool coinbaseEnabled = true;
  bool krakenEnabled = false;
  bool bybitEnabled = true;
  bool okxEnabled = false;

  // Active exchange (for primary display)
  String _primaryExchange = 'Binance';
  String get primaryExchange => _primaryExchange;

  List<StreamSubscription> _subs = [];
  bool _started = false;

  static const List<String> defaultSymbols = [
    'BTC', 'ETH', 'SOL', 'BNB', 'XRP',
    'ADA', 'AVAX', 'DOGE', 'DOT', 'LINK',
    'MATIC', 'UNI', 'ATOM', 'LTC', 'NEAR',
  ];

  Map<String, PriceTick> get prices => Map.unmodifiable(_prices);
  List<double> historyFor(String sym) => List.unmodifiable(_priceHistory[sym] ?? []);
  List<TradeEntry> get recentTrades => List.unmodifiable(_recentTrades.take(50).toList());

  // Exchange status map
  Map<String, ExchangeStatus> get exchangeStatuses => {
    'Binance': binance.status,
    'Coinbase': coinbase.status,
    'Kraken': kraken.status,
    'Bybit': bybit.status,
    'OKX': okx.status,
  };

  int get connectedCount => [binance, coinbase, kraken, bybit, okx]
      .where((e) => e.isConnected).length;

  Future<void> start({List<String>? symbols}) async {
    if (_started) return;
    _started = true;
    final syms = symbols ?? defaultSymbols;

    if (binanceEnabled) {
      await binance.connect(syms);
      _subs.add(binance.tickStream.listen(_onTick));
      _subs.add(binance.statusStream.listen((_) => notifyListeners()));
    }
    if (coinbaseEnabled) {
      await coinbase.connect(syms);
      _subs.add(coinbase.tickStream.listen(_onTick));
      _subs.add(coinbase.statusStream.listen((_) => notifyListeners()));
    }
    if (krakenEnabled) {
      await kraken.connect(syms);
      _subs.add(kraken.tickStream.listen(_onTick));
    }
    if (bybitEnabled) {
      await bybit.connect(syms);
      _subs.add(bybit.tickStream.listen(_onTick));
    }
    if (okxEnabled) {
      await okx.connect(syms);
      _subs.add(okx.tickStream.listen(_onTick));
    }
  }

  void _onTick(PriceTick tick) {
    // Priority: Binance > Bybit > Coinbase > Kraken > OKX
    final existing = _prices[tick.symbol];
    final shouldUpdate = existing == null ||
        _exchangePriority(tick.exchange) <= _exchangePriority(existing.exchange) ||
        DateTime.now().difference(existing.timestamp).inSeconds > 3;

    if (shouldUpdate) {
      _prices[tick.symbol] = tick;
      // Track price history (last 100 points)
      _priceHistory.putIfAbsent(tick.symbol, () => []);
      final hist = _priceHistory[tick.symbol]!;
      if (hist.isEmpty || (hist.last - tick.price).abs() > tick.price * 0.00001) {
        hist.add(tick.price);
        if (hist.length > 100) hist.removeAt(0);
      }
      notifyListeners();
    }
  }

  int _exchangePriority(String exchange) {
    switch (exchange) {
      case 'Binance': return 1;
      case 'Bybit': return 2;
      case 'Coinbase': return 3;
      case 'Kraken': return 4;
      default: return 5;
    }
  }

  PriceTick? getPrice(String symbol) => _prices[symbol];

  double? getChangeColor(String symbol) => _prices[symbol]?.change24h;

  void setPrimaryExchange(String ex) {
    _primaryExchange = ex;
    notifyListeners();
  }

  void toggleExchange(String name, bool enabled) {
    switch (name) {
      case 'Binance': binanceEnabled = enabled; break;
      case 'Coinbase': coinbaseEnabled = enabled; break;
      case 'Kraken': krakenEnabled = enabled; break;
      case 'Bybit': bybitEnabled = enabled; break;
      case 'OKX': okxEnabled = enabled; break;
    }
    notifyListeners();
  }

  void stop() {
    for (final sub in _subs) sub.cancel();
    _subs.clear();
    binance.disconnect();
    coinbase.disconnect();
    kraken.disconnect();
    bybit.disconnect();
    okx.disconnect();
    _started = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    binance.dispose();
    coinbase.dispose();
    kraken.dispose();
    bybit.dispose();
    okx.dispose();
    super.dispose();
  }
}
