/// HQMLL Quantum Trader — LiveDataService v49.0
/// Zentraler Realtime-Update-Hub (Flutter-Äquivalent zu App.jsx Realtime)
/// StreamController + Periodic Ticks → alle Screens empfangen Live-Daten
/// Grigori Saks · 2025
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════════
// LIVE DATA MODELS
// ══════════════════════════════════════════════════════════════

class LiveTickerData {
  final String  symbol;
  final double  price;
  final double  change24h;   // %
  final double  volume24h;
  final double  high24h;
  final double  low24h;
  final DateTime updatedAt;
  final bool    isUp;

  const LiveTickerData({
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.volume24h,
    required this.high24h,
    required this.low24h,
    required this.updatedAt,
    required this.isUp,
  });

  LiveTickerData copyWith({
    double? price,
    double? change24h,
    double? volume24h,
    DateTime? updatedAt,
    bool? isUp,
  }) => LiveTickerData(
    symbol:    symbol,
    price:     price     ?? this.price,
    change24h: change24h ?? this.change24h,
    volume24h: volume24h ?? this.volume24h,
    high24h:   high24h,
    low24h:    low24h,
    updatedAt: updatedAt ?? this.updatedAt,
    isUp:      isUp      ?? this.isUp,
  );
}

class LivePortfolioSnapshot {
  final double totalValue;
  final double pnlDay;
  final double pnlDayPct;
  final double pnlAllTime;
  final double pnlAllTimePct;
  final DateTime updatedAt;

  const LivePortfolioSnapshot({
    required this.totalValue,
    required this.pnlDay,
    required this.pnlDayPct,
    required this.pnlAllTime,
    required this.pnlAllTimePct,
    required this.updatedAt,
  });
}

class LiveSystemStatus {
  final bool   exchangeOnline;
  final bool   dataFeedActive;
  final bool   aiEngineRunning;
  final int    activeSignals;
  final double systemLoad;      // 0..1
  final int    wsConnections;
  final DateTime updatedAt;

  const LiveSystemStatus({
    required this.exchangeOnline,
    required this.dataFeedActive,
    required this.aiEngineRunning,
    required this.activeSignals,
    required this.systemLoad,
    required this.wsConnections,
    required this.updatedAt,
  });
}

class LiveMarketEvent {
  final String type;        // 'signal', 'alert', 'news', 'trade'
  final String title;
  final String symbol;
  final String detail;
  final DateTime timestamp;

  const LiveMarketEvent({
    required this.type,
    required this.title,
    required this.symbol,
    required this.detail,
    required this.timestamp,
  });
}

// ══════════════════════════════════════════════════════════════
// LIVE DATA SERVICE — Singleton + Streams
// ══════════════════════════════════════════════════════════════
class LiveDataService extends ChangeNotifier {
  static final LiveDataService _instance = LiveDataService._internal();
  factory LiveDataService() => _instance;
  LiveDataService._internal();

  final _rnd = Random();

  // ── Streams ───────────────────────────────────────────────
  final _tickerCtrl  = StreamController<Map<String, LiveTickerData>>.broadcast();
  final _portfolioCtrl = StreamController<LivePortfolioSnapshot>.broadcast();
  final _statusCtrl  = StreamController<LiveSystemStatus>.broadcast();
  final _eventCtrl   = StreamController<LiveMarketEvent>.broadcast();

  Stream<Map<String, LiveTickerData>> get tickerStream   => _tickerCtrl.stream;
  Stream<LivePortfolioSnapshot>       get portfolioStream => _portfolioCtrl.stream;
  Stream<LiveSystemStatus>            get statusStream    => _statusCtrl.stream;
  Stream<LiveMarketEvent>             get eventStream     => _eventCtrl.stream;

  // ── State ─────────────────────────────────────────────────
  Map<String, LiveTickerData>  _tickers       = {};
  LivePortfolioSnapshot?       _portfolio;
  LiveSystemStatus?            _systemStatus;
  final List<LiveMarketEvent>  _recentEvents  = [];
  bool                         _isRunning     = false;
  Timer?                       _tickTimer;
  Timer?                       _portfolioTimer;
  Timer?                       _statusTimer;
  Timer?                       _eventTimer;

  // Getters
  Map<String, LiveTickerData>  get tickers       => Map.unmodifiable(_tickers);
  LivePortfolioSnapshot?       get portfolio     => _portfolio;
  LiveSystemStatus?            get systemStatus  => _systemStatus;
  List<LiveMarketEvent>        get recentEvents  => List.unmodifiable(_recentEvents);
  bool                         get isRunning     => _isRunning;
  LiveTickerData?              ticker(String sym) => _tickers[sym];

  // ── Initialization ────────────────────────────────────────
  Future<void> initialize() async {
    if (_isRunning) return;
    _isRunning = true;

    // Seed initial data
    _seedTickers();
    _seedPortfolio();
    _seedStatus();

    // Start periodic updates
    _tickTimer     = Timer.periodic(const Duration(seconds: 2),  (_) => _updateTickers());
    _portfolioTimer = Timer.periodic(const Duration(seconds: 5), (_) => _updatePortfolio());
    _statusTimer   = Timer.periodic(const Duration(seconds: 8),  (_) => _updateStatus());
    _eventTimer    = Timer.periodic(const Duration(seconds: 15), (_) => _generateEvent());

    notifyListeners();
    if (kDebugMode) debugPrint('[LiveDataService] Started — ${_tickers.length} tickers');
  }

  void stop() {
    _tickTimer?.cancel();
    _portfolioTimer?.cancel();
    _statusTimer?.cancel();
    _eventTimer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  // ── Seed ──────────────────────────────────────────────────
  void _seedTickers() {
    final seeds = <String, double>{
      'BTC': 67842.50, 'ETH': 3548.20, 'SOL': 182.40,
      'BNB': 598.30,   'ADA': 0.452,   'AVAX': 36.84,
      'DOT': 7.24,     'LINK': 14.82,  'QMM': 0.0846,
      'XRP': 0.623,
    };
    final changes = <String, double>{
      'BTC': 2.34,  'ETH': 1.82,  'SOL': 4.21,
      'BNB': -0.88, 'ADA': -1.24, 'AVAX': 3.15,
      'DOT': 0.74,  'LINK': 2.88, 'QMM': 8.44,
      'XRP': 0.31,
    };
    for (final sym in seeds.keys) {
      final p = seeds[sym]!;
      final c = changes[sym]!;
      _tickers[sym] = LiveTickerData(
        symbol:    sym,
        price:     p,
        change24h: c,
        volume24h: p * (1000 + _rnd.nextInt(5000)),
        high24h:   p * 1.03,
        low24h:    p * 0.97,
        updatedAt: DateTime.now(),
        isUp:      c >= 0,
      );
    }
  }

  void _seedPortfolio() {
    _portfolio = LivePortfolioSnapshot(
      totalValue:     75847.32,
      pnlDay:         2184.50,
      pnlDayPct:      2.96,
      pnlAllTime:     18432.80,
      pnlAllTimePct:  32.1,
      updatedAt:      DateTime.now(),
    );
  }

  void _seedStatus() {
    _systemStatus = LiveSystemStatus(
      exchangeOnline:  true,
      dataFeedActive:  true,
      aiEngineRunning: true,
      activeSignals:   5,
      systemLoad:      0.42,
      wsConnections:   3,
      updatedAt:       DateTime.now(),
    );
  }

  // ── Update Tickers ─────────────────────────────────────────
  void _updateTickers() {
    final updated = <String, LiveTickerData>{};
    for (final entry in _tickers.entries) {
      final old  = entry.value;
      final delta = (_rnd.nextDouble() - 0.499) * 0.002; // ±0.2%
      final newPrice   = (old.price * (1 + delta)).clamp(old.price * 0.8, old.price * 1.2);
      final newChange  = old.change24h + (_rnd.nextDouble() - 0.5) * 0.05;
      updated[entry.key] = old.copyWith(
        price:     newPrice,
        change24h: newChange.clamp(-15, 15),
        isUp:      newPrice >= old.price,
        updatedAt: DateTime.now(),
      );
    }
    _tickers = updated;
    _tickerCtrl.add(Map.from(_tickers));
    notifyListeners();
  }

  // ── Update Portfolio ───────────────────────────────────────
  void _updatePortfolio() {
    final old = _portfolio;
    if (old == null) return;
    final delta   = (_rnd.nextDouble() - 0.48) * 150;
    final newVal  = (old.totalValue + delta).clamp(60000.0, 120000.0);
    final dayDelta = delta * 0.6;
    final newPnlDay = old.pnlDay + dayDelta;
    _portfolio = LivePortfolioSnapshot(
      totalValue:    newVal,
      pnlDay:        newPnlDay,
      pnlDayPct:     newPnlDay / newVal * 100,
      pnlAllTime:    old.pnlAllTime + delta * 0.1,
      pnlAllTimePct: (old.pnlAllTime + delta * 0.1) / newVal * 100,
      updatedAt:     DateTime.now(),
    );
    _portfolioCtrl.add(_portfolio!);
    notifyListeners();
  }

  // ── Update Status ──────────────────────────────────────────
  void _updateStatus() {
    final old = _systemStatus;
    if (old == null) return;
    _systemStatus = LiveSystemStatus(
      exchangeOnline:  _rnd.nextDouble() > 0.02,
      dataFeedActive:  _rnd.nextDouble() > 0.01,
      aiEngineRunning: true,
      activeSignals:   (old.activeSignals + _rnd.nextInt(3) - 1).clamp(1, 15),
      systemLoad:      (old.systemLoad + (_rnd.nextDouble() - 0.5) * 0.05).clamp(0.1, 0.95),
      wsConnections:   (old.wsConnections + _rnd.nextInt(3) - 1).clamp(1, 8),
      updatedAt:       DateTime.now(),
    );
    _statusCtrl.add(_systemStatus!);
    notifyListeners();
  }

  // ── Market Events ──────────────────────────────────────────
  void _generateEvent() {
    final events = [
      ('signal',  'AI Signal: BTC/USDT',    'BTC',  'STRONG BUY — Konfidenz 93%'),
      ('alert',   'Preis-Alert ausgelöst',   'ETH',  'ETH > \$3.600 — Zielpreis erreicht'),
      ('news',    'Markt-News',              'MAKRO', 'Fed: Zinspause bestätigt'),
      ('trade',   'Trade ausgeführt',        'SOL',  'KAUF 18.5 SOL @ \$182.40'),
      ('signal',  'AI Signal: AVAX/USDT',   'AVAX', 'BUY — RSI Divergenz erkannt'),
      ('alert',   'Volatilitäts-Alarm',     'BTC',  'BTC Volatilität +34% — Vorsicht'),
    ];
    final pick = events[_rnd.nextInt(events.length)];
    final event = LiveMarketEvent(
      type:      pick.$1,
      title:     pick.$2,
      symbol:    pick.$3,
      detail:    pick.$4,
      timestamp: DateTime.now(),
    );
    _recentEvents.insert(0, event);
    if (_recentEvents.length > 50) _recentEvents.removeLast();
    _eventCtrl.add(event);
    notifyListeners();
  }

  // ── Manual Trigger ─────────────────────────────────────────
  void forceRefresh() {
    _updateTickers();
    _updatePortfolio();
    _updateStatus();
  }

  @override
  void dispose() {
    stop();
    _tickerCtrl.close();
    _portfolioCtrl.close();
    _statusCtrl.close();
    _eventCtrl.close();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════
// LIVE TICKER WIDGET — RepaintBoundary optimiert
// ══════════════════════════════════════════════════════════════
class LiveTickerWidget extends StatelessWidget {
  final String symbol;
  final TextStyle? priceStyle;
  final TextStyle? changeStyle;
  final bool showArrow;

  const LiveTickerWidget({
    super.key,
    required this.symbol,
    this.priceStyle,
    this.changeStyle,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: StreamBuilder<Map<String, LiveTickerData>>(
        stream: LiveDataService().tickerStream,
        builder: (context, snap) {
          final data = LiveDataService().ticker(symbol);
          if (data == null) return const SizedBox.shrink();

          final isUp    = data.isUp;
          final color   = isUp ? const Color(0xFF14F195) : const Color(0xFFFF4444);
          final arrow   = isUp ? '▲' : '▼';
          final change  = data.change24h;

          return Row(mainAxisSize: MainAxisSize.min, children: [
            Text(
              _formatPrice(data.price),
              style: priceStyle ?? TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'Rajdhani',
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${showArrow ? "$arrow " : ""}${change >= 0 ? "+" : ""}${change.toStringAsFixed(2)}%',
              style: changeStyle ?? TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'Rajdhani',
              ),
            ),
          ]);
        },
      ),
    );
  }

  String _formatPrice(double p) {
    if (p >= 1000) return '\$${p.toStringAsFixed(2)}';
    if (p >= 1)    return '\$${p.toStringAsFixed(3)}';
    return '\$${p.toStringAsFixed(4)}';
  }
}

// ══════════════════════════════════════════════════════════════
// LIVE STATUS BANNER — für Dashboard
// ══════════════════════════════════════════════════════════════
class LiveStatusBanner extends StatelessWidget {
  const LiveStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: StreamBuilder<LiveSystemStatus>(
        stream: LiveDataService().statusStream,
        builder: (context, snap) {
          final status = LiveDataService().systemStatus;
          if (status == null) return const SizedBox.shrink();

          final allOk = status.exchangeOnline &&
                        status.dataFeedActive &&
                        status.aiEngineRunning;
          final color = allOk ? const Color(0xFF14F195) : const Color(0xFFF7931A);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 4, spreadRadius: 1,
                  )],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                allOk ? 'LIVE • ${status.activeSignals} SIGNALE AKTIV' : 'VERBINDUNG EINGESCHRÄNKT',
                style: TextStyle(
                  color: color, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 1,
                  fontFamily: 'Rajdhani',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(status.systemLoad * 100).toStringAsFixed(0)}% LOAD',
                style: TextStyle(
                  color: color.withValues(alpha: 0.7), fontSize: 8,
                  fontFamily: 'Rajdhani',
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}
