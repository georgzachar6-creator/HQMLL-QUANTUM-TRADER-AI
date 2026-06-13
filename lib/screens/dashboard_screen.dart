// ============================================================
// DASHBOARD v49 – HQMLL Quantum Trader
// Live Portfolio, P&L, TradingSignalStream, AI Engine, News
// Realtime StreamBuilder + Error Handling + LiveDataService
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/exchange_service.dart';
import '../services/auto_save_service.dart';
import '../services/time_crystal_service.dart';
import '../services/persistence_service.dart';
import '../widgets/crypto_icon.dart';
import '../services/trading_signal_service.dart';
import '../services/live_data_service.dart';
import '../services/error_handler_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  Timer? _liveTimer;
  final _rand = Random();

  // Portfolio
  double _totalValue = 75847.32;
  double _pnlDay = 2184.50;
  double _pnlDayPct = 2.96;
  double _pnlAllTime = 18432.80;
  double _pnlAllTimePct = 32.1;
  int _newsIdx = 0;

  // Donut chart data
  final List<Map<String, dynamic>> _allocation = [
    {'label': 'Bitcoin', 'symbol': 'BTC', 'pct': 38.2, 'value': 28973.88, 'color': const Color(0xFFF7931A), 'change': 2.34},
    {'label': 'Ethereum', 'symbol': 'ETH', 'pct': 22.4, 'value': 16989.80, 'change': 1.82, 'color': const Color(0xFF627EEA)},
    {'label': 'Solana', 'symbol': 'SOL', 'pct': 14.8, 'value': 11225.40, 'change': 4.21, 'color': const Color(0xFF9945FF)},
    {'label': 'QEMMA', 'symbol': 'QMM', 'pct': 10.2, 'value': 7736.43, 'change': 8.44, 'color': const Color(0xFF00FF88)},
    {'label': 'BNB', 'symbol': 'BNB', 'pct': 7.4, 'value': 5612.70, 'change': -0.88, 'color': const Color(0xFFF0B90B)},
    {'label': 'Andere', 'symbol': '...', 'pct': 7.0, 'value': 5309.31, 'change': 1.10, 'color': const Color(0xFF445566)},
  ];

  // P&L history (30 days)
  final List<double> _pnlHistory = [];

  // Watchlist
  final List<Map<String, dynamic>> _watchlist = [
    {'sym': 'BTC', 'name': 'Bitcoin', 'price': 67842.50, 'change': 2.34, 'color': const Color(0xFFF7931A), 'hist': <double>[]},
    {'sym': 'ETH', 'name': 'Ethereum', 'price': 3548.20, 'change': 1.82, 'color': const Color(0xFF627EEA), 'hist': <double>[]},
    {'sym': 'SOL', 'name': 'Solana', 'price': 182.40, 'change': 4.21, 'color': const Color(0xFF9945FF), 'hist': <double>[]},
    {'sym': 'BNB', 'name': 'BNB', 'price': 598.30, 'change': -0.88, 'color': const Color(0xFFF0B90B), 'hist': <double>[]},
    {'sym': 'ADA', 'name': 'Cardano', 'price': 0.452, 'change': -1.24, 'color': const Color(0xFF0033AD), 'hist': <double>[]},
    {'sym': 'AVAX', 'name': 'Avalanche', 'price': 36.84, 'change': 3.15, 'color': const Color(0xFFE84142), 'hist': <double>[]},
    {'sym': 'DOT', 'name': 'Polkadot', 'price': 7.24, 'change': 0.74, 'color': const Color(0xFFE6007A), 'hist': <double>[]},
    {'sym': 'LINK', 'name': 'Chainlink', 'price': 14.82, 'change': 2.88, 'color': const Color(0xFF2A5ADA), 'hist': <double>[]},
  ];

  // AI Signals
  final List<Map<String, dynamic>> _signals = [
    {'pair': 'BTC/USDT', 'action': 'KAUFEN', 'conf': 87, 'reason': 'RSI Divergenz + Volume Spike', 'color': const Color(0xFF00FF88), 'tf': '4H'},
    {'pair': 'ETH/USDT', 'action': 'KAUFEN', 'conf': 79, 'reason': 'Golden Cross 50/200 MA', 'color': const Color(0xFF00FF88), 'tf': '1D'},
    {'pair': 'SOL/USDT', 'action': 'STARK KAUFEN', 'conf': 93, 'reason': 'Breakout + Whale Akkumulation', 'color': const Color(0xFF00AAFF), 'tf': '1H'},
    {'pair': 'BNB/USDT', 'action': 'HALTEN', 'conf': 62, 'reason': 'Seitwärtsbewegung erwartet', 'color': const Color(0xFFFFD700), 'tf': '4H'},
    {'pair': 'ADA/USDT', 'action': 'VERKAUFEN', 'conf': 71, 'reason': 'RSI Überkauft + Resistance', 'color': const Color(0xFFFF3358), 'tf': '1D'},
  ];

  // News
  final List<Map<String, dynamic>> _news = [
    {'title': 'Bitcoin erreicht \$68K – Institutionelle Zuflüsse treiben den Markt', 'time': 'vor 8min', 'tag': 'BTC', 'sentiment': 'bullisch'},
    {'title': 'Ethereum Dencun Upgrade: Gas-Gebühren auf Rekordtief', 'time': 'vor 22min', 'tag': 'ETH', 'sentiment': 'bullisch'},
    {'title': 'Fed hält Zinsen stabil – Krypto-Märkte reagieren positiv', 'time': 'vor 1h', 'tag': 'MAKRO', 'sentiment': 'neutral'},
    {'title': 'Solana übertrifft Erwartungen: 65.000 TPS in neuem Stresstest', 'time': 'vor 2h', 'tag': 'SOL', 'sentiment': 'bullisch'},
    {'title': 'SEC genehmigt weiteren Spot-ETF Antrag – Markt erwartet Kapitalzuflüsse', 'time': 'vor 3h', 'tag': 'REGULIERUNG', 'sentiment': 'bullisch'},
    {'title': 'QEMMA Token: Mining-Reward Upgrade live – Hash-Power +28%', 'time': 'vor 4h', 'tag': 'QEMMA', 'sentiment': 'bullisch'},
  ];

  // Recent Transactions
  final List<Map<String, dynamic>> _recentTx = [
    {'type': 'KAUF', 'sym': 'BTC', 'amount': '0.0124 BTC', 'value': '\$841.64', 'time': 'vor 14min', 'color': const Color(0xFF00FF88)},
    {'type': 'VERKAUF', 'sym': 'ETH', 'amount': '0.42 ETH', 'value': '\$1,490.24', 'time': 'vor 2h', 'color': const Color(0xFFFF3358)},
    {'type': 'KAUF', 'sym': 'SOL', 'amount': '18.5 SOL', 'value': '\$3,374.40', 'time': 'vor 5h', 'color': const Color(0xFF00FF88)},
    {'type': 'STAKING', 'sym': 'QEMMA', 'amount': '5,000 QMM', 'value': '\$423.00', 'time': 'gestern', 'color': const Color(0xFF00AAFF)},
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();

    // ExchangeService initialisieren (Binance WS + CoinGecko)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ex = context.read<ExchangeService>();
      await ex.initialize();
      // Initialize TimeCrystal if not already done
      if (mounted) {
        final tc = context.read<TimeCrystalService>();
        if (tc.totalExperiments == 0) await tc.initialize();
      }
    });

    // Init P&L history
    double v = 55000;
    for (int i = 0; i < 30; i++) {
      v += (_rand.nextDouble() - 0.42) * 2000;
      _pnlHistory.add(v.clamp(40000, 100000));
    }
    _pnlHistory.last = _totalValue;

    // Init watchlist sparklines
    for (var w in _watchlist) {
      final hist = w['hist'] as List<double>;
      double p = w['price'] as double;
      for (int i = 0; i < 20; i++) {
        p += ((_rand.nextDouble() - 0.5) * p * 0.015);
        hist.add(p);
      }
    }

    _startLive();
  }

  /// Berechnet _totalValue aus live Portfolio-Preisen (ExchangeService).
  /// Fallback auf gespeicherte Werte wenn kein live Preis verfügbar.
  void _syncPortfolioFromExchange(ExchangeService ex) {
    // Fallback-Preise für Assets ohne ExchangeService-Symbol
    const fallback = <String, double>{
      'BTC': 67842.0, 'ETH': 3548.0, 'SOL': 182.4,
      'BNB': 598.3, 'QMM': 0.151,
    };
    // Mengen entsprechend der initialen Werte / Fallback-Preise
    const quantities = <String, double>{
      'BTC': 0.427,   // 28973 / 67842
      'ETH': 4.789,   // 16989 / 3548
      'SOL': 61.57,   // 11225 / 182.4
      'QMM': 51234.0, // 7736 / 0.151
      'BNB': 9.38,    // 5612 / 598.3
    };

    double newTotal = 0.0;
    for (var a in _allocation) {
      final sym = a['symbol'] as String;
      if (sym == '...') {
        newTotal += a['value'] as double; // Andere: statisch
        continue;
      }
      final livePrice = ex.getPrice(sym);
      final price = livePrice > 0 ? livePrice : (fallback[sym] ?? 0.0);
      final qty = quantities[sym] ?? 0.0;
      final liveVal = price * qty;
      a['value'] = liveVal;
      newTotal += liveVal;
    }
    if (newTotal > 1000) {
      _totalValue = newTotal;
      _pnlDay = _totalValue - 73662.82;
      _pnlDayPct = (_pnlDay / 73662.82) * 100;
    }
  }

  void _startLive() {
    _liveTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted) return;
      setState(() {
        // Sparkline-History für Watchlist animieren (Preise kommen von ExchangeService)
        for (var w in _watchlist) {
          final p = w['price'] as double;
          if (p > 0) {
            (w['hist'] as List<double>).add(p);
            if ((w['hist'] as List<double>).length > 20) (w['hist'] as List<double>).removeAt(0);
          }
        }
        // Rotate news
        _newsIdx = (_newsIdx + 1) % _news.length;
      });
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose(); _pulseCtrl.dispose(); _slideCtrl.dispose();
    _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    // ExchangeService als einzige primäre Preisquelle (Binance WS + CoinGecko)
    final ex   = context.watch<ExchangeService>();
    final tc   = context.watch<TimeCrystalService>();
    final as2  = context.watch<AutoSaveService>();
    final tss  = context.watch<TradingSignalService>();
    final lds  = context.watch<LiveDataService>();
    final errs = context.watch<ErrorHandlerService>();

    // Portfolio live berechnen
    _syncPortfolioFromExchange(ex);

    // Watchlist-Preise aus ExchangeService + LiveDataService synchronisieren
    for (var w in _watchlist) {
      final sym = w['sym'] as String;
      final exTick  = ex.getTick(sym);
      final ldsTick = lds.ticker(sym);
      final prev = w['price'] as double;

      // Prefer ExchangeService, fallback to LiveDataService
      double? livePrice  = exTick?.price ?? ldsTick?.price;
      double? liveChange = exTick?.change24h ?? ldsTick?.change24h;

      if (livePrice != null && livePrice > 0) {
        w['price']  = livePrice;
        w['change'] = liveChange ?? w['change'];
        if ((prev - livePrice).abs() > prev * 0.0001) {
          (w['hist'] as List<double>).add(livePrice);
          if ((w['hist'] as List<double>).length > 20) (w['hist'] as List<double>).removeAt(0);
        }
      }
    }

    // Sync portfolio from LiveDataService if ExchangeService values aren't available
    final ldsPortfolio = lds.portfolio;
    if (ldsPortfolio != null && _totalValue < 1000) {
      _totalValue    = ldsPortfolio.totalValue;
      _pnlDay        = ldsPortfolio.pnlDay;
      _pnlDayPct     = ldsPortfolio.pnlDayPct;
      _pnlAllTime    = ldsPortfolio.pnlAllTime;
      _pnlAllTimePct = ldsPortfolio.pnlAllTimePct;
    }

    return Scaffold(
      backgroundColor: p.background,
      body: RefreshIndicator(
        color: p.primary,
        backgroundColor: p.surface,
        onRefresh: () async {
          lds.forceRefresh();
          await ex.initialize();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(children: [
            _buildHeader(p, ex, lds),
            // Live-Status Banner (Realtime)
            _buildLiveStatusBanner(p, lds, errs),
            _buildPortfolioCard(p),
            _buildAllocationRow(p),
            _buildSignalStream(p, tss),
            _buildQuantumResearchPanel(p, tc, as2),
            _buildPnLChart(p),
            _buildWatchlist(p),
            _buildRecentTx(p),
            _buildNewsSection(p),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  // ── LIVE STATUS BANNER (Realtime StreamBuilder) ──
  Widget _buildLiveStatusBanner(dynamic p, LiveDataService lds, ErrorHandlerService errs) {
    return RepaintBoundary(
      child: StreamBuilder<LiveSystemStatus>(
        stream: lds.statusStream,
        builder: (context, snap) {
          final status = lds.systemStatus;
          final activeErrors = errs.activeErrors;

          // Error state
          if (activeErrors.isNotEmpty) {
            final err = activeErrors.first;
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: err.severityColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: err.severityColor.withValues(alpha: 0.35)),
              ),
              child: Row(children: [
                Icon(err.icon, color: err.severityColor, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  '${err.typeLabel}: ${err.message}',
                  style: GoogleFonts.rajdhani(
                    color: err.severityColor, fontSize: 10,
                    fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )),
                GestureDetector(
                  onTap: () => errs.dismiss(err.id),
                  child: Icon(Icons.close, color: err.severityColor.withValues(alpha: 0.7), size: 14),
                ),
              ]),
            );
          }

          // Live status
          if (status == null) return const SizedBox.shrink();
          final allOk  = status.exchangeOnline && status.dataFeedActive;
          final color  = allOk ? const Color(0xFF14F195) : const Color(0xFFF7931A);
          final btcLds = lds.ticker('BTC');

          return Container(
            margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color.withValues(alpha: 0.07),
                Colors.transparent,
              ]),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Row(children: [
              // Pulsing dot
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [BoxShadow(
                      color: color.withValues(alpha: 0.4 + _pulseCtrl.value * 0.4),
                      blurRadius: 6, spreadRadius: 1,
                    )],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                allOk ? '● REALTIME AKTIV' : '◐ EINGESCHRÄNKT',
                style: GoogleFonts.rajdhani(
                  color: color, fontSize: 9,
                  fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              const SizedBox(width: 12),
              // BTC Live-Preis aus LiveDataService
              if (btcLds != null) ...[
                Text('BTC ', style: GoogleFonts.rajdhani(
                  color: p.textSecondary, fontSize: 9)),
                Text('\$${(btcLds.price / 1000).toStringAsFixed(1)}K',
                  style: GoogleFonts.rajdhani(
                    color: btcLds.isUp ? const Color(0xFF14F195) : const Color(0xFFFF4444),
                    fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                Text(
                  '${btcLds.change24h >= 0 ? "+" : ""}${btcLds.change24h.toStringAsFixed(2)}%',
                  style: GoogleFonts.rajdhani(
                    color: btcLds.isUp
                        ? const Color(0xFF14F195).withValues(alpha: 0.8)
                        : const Color(0xFFFF4444).withValues(alpha: 0.8),
                    fontSize: 9),
                ),
              ],
              const Spacer(),
              Text(
                '${status.activeSignals} SIGNALE · ${(status.systemLoad * 100).toStringAsFixed(0)}% LOAD',
                style: GoogleFonts.rajdhani(
                  color: p.textSecondary, fontSize: 8),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ── HEADER ──
  Widget _buildHeader(dynamic p, ExchangeService ex, LiveDataService lds) {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Guten Morgen' : now.hour < 18 ? 'Guten Tag' : 'Guten Abend';
    final btcPrice = ex.getPrice('BTC');
    final btcLds   = lds.ticker('BTC');
    // Prefer exchange price, fallback to LiveDataService
    final displayPrice = btcPrice > 0 ? btcPrice : (btcLds?.price ?? 0.0);
    final btcTick  = ex.getTick('BTC');
    final isWsLive = btcTick?.isLive ?? false;
    final liveColor = isWsLive ? const Color(0xFF00FF88) : const Color(0xFFFFAA00);
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(bottom: BorderSide(color: p.primary.withValues(alpha: 0.1 + _glowCtrl.value * 0.06))),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(greeting, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 12)),
            Text('QUANTUM TRADER', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
            if (displayPrice > 0)
              Text('BTC \$${displayPrice >= 1000 ? '${(displayPrice / 1000).toStringAsFixed(1)}K' : displayPrice.toStringAsFixed(0)}', style: GoogleFonts.spaceMono(
                color: liveColor.withValues(alpha: 0.7), fontSize: 9, letterSpacing: 0.5,
              )),
          ])),
          // Live indicator
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Row(children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: liveColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: liveColor.withValues(alpha: 0.4 + _pulseCtrl.value * 0.4), blurRadius: 8)],
                ),
              ),
              const SizedBox(width: 6),
              Text(isWsLive ? 'WS LIVE' : 'REST', style: GoogleFonts.spaceMono(color: liveColor, fontSize: 10, letterSpacing: 1)),
            ]),
          ),
          const SizedBox(width: 12),
          // Fear & Greed
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.25)),
            ),
            child: Column(children: [
              Text('GIER', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 8, letterSpacing: 1)),
              Text('74', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 13, fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── PORTFOLIO CARD ──
  Widget _buildPortfolioCard(dynamic p) {
    final isPnlPositive = _pnlDay >= 0;
    final pnlColor = isPnlPositive ? const Color(0xFF00FF88) : const Color(0xFFFF3358);
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [p.primary.withValues(alpha: 0.15), p.primary.withValues(alpha: 0.05), p.surface],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.primary.withValues(alpha: 0.25 + _glowCtrl.value * 0.1)),
          boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.08 + _glowCtrl.value * 0.06), blurRadius: 20, spreadRadius: 2)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('GESAMTPORTFOLIO', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10, letterSpacing: 1.5)),
            const Spacer(),
            Text('18 Assets', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '\$${_formatLarge(_totalValue)}',
              style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            // Donut mini
            SizedBox(
              width: 60, height: 60,
              child: CustomPaint(painter: _DonutPainter(_allocation)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            // Day P&L
            _pnlChip('HEUTE', _pnlDay, _pnlDayPct, pnlColor, p),
            const SizedBox(width: 10),
            // All time P&L
            _pnlChip('GESAMT', _pnlAllTime, _pnlAllTimePct, const Color(0xFF00FF88), p),
          ]),
        ]),
      ),
    );
  }

  Widget _pnlChip(String label, double val, double pct, Color color, dynamic p) {
    final sign = val >= 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(val >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: color, size: 12),
        const SizedBox(width: 4),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7, letterSpacing: 0.5)),
          Text('$sign\$${_formatLarge(val.abs())} ($sign${pct.toStringAsFixed(2)}%)', style: GoogleFonts.spaceMono(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  // ── ALLOCATION ROW ──
  Widget _buildAllocationRow(dynamic p) {
    return Container(
      height: 90,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _allocation.length,
        itemBuilder: (_, i) {
          final a = _allocation[i];
          final color = a['color'] as Color;
          final chg = a['change'] as double;
          return Container(
            width: 88,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const Spacer(),
                Text('${a['pct']}%', style: GoogleFonts.spaceMono(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 4),
              Text(a['symbol'] as String, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                '${chg >= 0 ? '+' : ''}${chg.toStringAsFixed(2)}%',
                style: GoogleFonts.spaceMono(color: chg >= 0 ? const Color(0xFF00FF88) : const Color(0xFFFF3358), fontSize: 9),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ── AI SIGNAL BANNER ──
  // ==========================================================
  // SIGNAL STREAM v4 — Live TradingSignalService Ausgabe
  // ==========================================================
  Widget _buildSignalStream(dynamic p, TradingSignalService tss) {
    final top    = tss.topSignal;
    final active = tss.activeSignals.take(5).toList();
    final bullCnt  = tss.bullishCount;
    final bearCnt  = tss.bearishCount;
    final avgConf  = tss.avgConf;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00041A), Color(0xFF00081F)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (top?.action.isBullish ?? true)
            ? const Color(0xFF00FF88).withValues(alpha: 0.3)
            : const Color(0xFFFF3358).withValues(alpha: 0.3),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header Row
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00FF88).withValues(alpha: 0.12),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.25 + _pulseCtrl.value * 0.2),
                    blurRadius: 10,
                  )],
                ),
                child: const Icon(Icons.bolt_rounded, color: Color(0xFF00FF88), size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TRADING SIGNAL ENGINE v47', style: GoogleFonts.spaceMono(
                color: const Color(0xFF00FF88), fontSize: 9, letterSpacing: 1.5,
              )),
              Text('TC-Phase + RSI + MACD + Volume Spike', style: GoogleFonts.rajdhani(
                color: const Color(0xFF00FF88).withValues(alpha: 0.5), fontSize: 9,
              )),
            ])),
            if (tss.isGenerating)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(
                strokeWidth: 1.5, color: Color(0xFF00FF88),
              ))
            else
              Row(children: [
                Container(width: 6, height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFF00FF88),
                  )),
                const SizedBox(width: 4),
                Text(tss.lastUpdate.isNotEmpty ? tss.lastUpdate : 'LIVE',
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFF00FF88), fontSize: 8, letterSpacing: 0.5,
                  )),
              ]),
          ]),
        ),

        // Summary Stats
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Row(children: [
            _sigStatChip('\u2191 $bullCnt BULL', const Color(0xFF00FF88)),
            const SizedBox(width: 8),
            _sigStatChip('\u2193 $bearCnt BEAR', const Color(0xFFFF3358)),
            const SizedBox(width: 8),
            _sigStatChip('CONF \u00d8${(avgConf * 100).toStringAsFixed(0)}%', const Color(0xFF00AAFF)),
            const Spacer(),
            Text('${active.length} aktiv', style: GoogleFonts.rajdhani(
              color: p.textSecondary, fontSize: 9,
            )),
          ]),
        ),

        // Top Signal Highlight
        if (top != null) ...[
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) {
              final sigColor = top.action.isBullish
                ? const Color(0xFF00FF88)
                : top.action.isBearish
                  ? const Color(0xFFFF3358)
                  : const Color(0xFFFFD700);
              final confPct  = (top.confidence * 100).toStringAsFixed(0);
              return Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sigColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sigColor.withValues(
                    alpha: 0.2 + _glowCtrl.value * 0.15)),
                ),
                child: Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(top.pair, style: GoogleFonts.spaceMono(
                      color: sigColor, fontSize: 12, fontWeight: FontWeight.bold,
                    )),
                    Text(top.action.label, style: GoogleFonts.rajdhani(
                      color: sigColor, fontSize: 10, fontWeight: FontWeight.w700,
                    )),
                    Text('${top.action.emoji} ${_priceFmt(top.entryPrice)}\u2192${_priceFmt(top.targetPrice)}',
                      style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
                  ]),
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('$confPct%', style: GoogleFonts.spaceMono(
                      color: sigColor, fontSize: 20, fontWeight: FontWeight.bold,
                    )),
                    Text('KONFIDENZ', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 7)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: top.confidence,
                          backgroundColor: sigColor.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(sigColor),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ]),
                ]),
              );
            },
          ),
        ],

        // Signal List (max 4 weitere)
        if (active.length > 1) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Column(
              children: active.skip(1).take(4).toList().asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final col = s.action.isBullish
                  ? const Color(0xFF00FF88)
                  : s.action.isBearish
                    ? const Color(0xFFFF3358)
                    : const Color(0xFFFFD700);
                return Container(
                  margin: EdgeInsets.only(top: i > 0 ? 4 : 0),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: col.withValues(alpha: 0.15)),
                  ),
                  child: Row(children: [
                    CryptoIcon(s.symbol, size: 24, showShadow: false),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.pair,
                      style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 9))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: col.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(s.action.label,
                        style: GoogleFonts.spaceMono(color: col, fontSize: 7, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${(s.confidence * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.spaceMono(color: col, fontSize: 8)),
                        const SizedBox(height: 2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: s.confidence,
                            backgroundColor: col.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(col),
                            minHeight: 2,
                          ),
                        ),
                      ]),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ),
        ],

        // Regime Badge + R/R Row
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Wrap(spacing: 6, children: [
            _regimeBadge(p, tss.globalRegime),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF9945FF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'R/R \u00d8${tss.activeSignals.isEmpty ? '--' : (tss.activeSignals.map((s) => s.rr).reduce((a, b) => a + b) / tss.activeSignals.length).toStringAsFixed(1)}',
                style: GoogleFonts.spaceMono(color: const Color(0xFF9945FF), fontSize: 8)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _sigStatChip(String label, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: c.withValues(alpha: 0.25)),
    ),
    child: Text(label, style: GoogleFonts.spaceMono(color: c, fontSize: 8, fontWeight: FontWeight.bold)),
  );

  Widget _regimeBadge(dynamic p, MarketRegime regime) {
    final label = switch (regime) {
      MarketRegime.trending      => 'TREND',
      MarketRegime.ranging       => 'RANGING',
      MarketRegime.volatile      => 'VOLATILE',
      MarketRegime.breakout      => 'BREAKOUT',
      MarketRegime.consolidation => 'CONSOL.',
    };
    final color = switch (regime) {
      MarketRegime.trending      => const Color(0xFF00FF88),
      MarketRegime.ranging       => const Color(0xFF00AAFF),
      MarketRegime.volatile      => const Color(0xFFFF3358),
      MarketRegime.breakout      => const Color(0xFFFFD700),
      MarketRegime.consolidation => const Color(0xFFF7931A),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text('REGIME: $label',
        style: GoogleFonts.spaceMono(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  String _priceFmt(double price) {
    if (price >= 1000) return '\$${(price / 1000).toStringAsFixed(1)}K';
    if (price >= 1)    return '\$${price.toStringAsFixed(2)}';
    return '\$${price.toStringAsFixed(4)}';
  }

  // ── P&L CHART ──
  Widget _buildPnLChart(dynamic p) {
    final minV = _pnlHistory.reduce(min) - 1000;
    final maxV = _pnlHistory.reduce(max) + 1000;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.show_chart_rounded, color: p.primary, size: 16),
          const SizedBox(width: 8),
          Text('PORTFOLIO VERLAUF (30T)', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 10, letterSpacing: 1.5)),
          const Spacer(),
          Text('\$${_formatLarge(_totalValue)}', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: CustomPaint(
            size: const Size(double.infinity, 100),
            painter: _PnLChartPainter(_pnlHistory, minV, maxV, p.primary),
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('vor 30 Tagen: \$${_formatLarge(_pnlHistory.first)}', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
          Text('Heute: \$${_formatLarge(_pnlHistory.last)}', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 9)),
        ]),
      ]),
    );
  }

  // ── WATCHLIST ──
  Widget _buildWatchlist(dynamic p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.1)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Icon(Icons.star_rounded, color: const Color(0xFFFFD700), size: 16),
            const SizedBox(width: 8),
            Text('WATCHLIST', style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 11, letterSpacing: 1.5)),
            const Spacer(),
            Text('${_watchlist.length} Assets', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
          ]),
        ),
        ..._watchlist.asMap().entries.map((entry) {
          final i = entry.key;
          final w = entry.value;
          final color = w['color'] as Color;
          final price = w['price'] as double;
          final change = w['change'] as double;
          final hist = w['hist'] as List<double>;
          final isPositive = change >= 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: i > 0 ? BorderSide(color: p.primary.withValues(alpha: 0.06)) : BorderSide.none),
            ),
            child: Row(children: [
              CryptoIcon(w['sym'] as String, size: 38, showShadow: false),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(w['sym'] as String, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(w['name'] as String, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
              ])),
              // Sparkline
              SizedBox(
                width: 50, height: 28,
                child: hist.length > 1
                    ? CustomPaint(painter: _SparklinePainter(hist, isPositive ? const Color(0xFF00FF88) : const Color(0xFFFF3358)))
                    : const SizedBox(),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  price >= 1000 ? '\$${price.toStringAsFixed(0)}' : price >= 1 ? '\$${price.toStringAsFixed(2)}' : '\$${price.toStringAsFixed(4)}',
                  style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                  style: GoogleFonts.spaceMono(color: isPositive ? const Color(0xFF00FF88) : const Color(0xFFFF3358), fontSize: 10),
                ),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  // ── RECENT TX ──
  Widget _buildRecentTx(dynamic p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.1)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Icon(Icons.receipt_long_rounded, color: p.primary, size: 16),
            const SizedBox(width: 8),
            Text('LETZTE TRANSAKTIONEN', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 10, letterSpacing: 1.5)),
          ]),
        ),
        ..._recentTx.asMap().entries.map((entry) {
          final i = entry.key;
          final tx = entry.value;
          final color = tx['color'] as Color;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(border: Border(top: i > 0 ? BorderSide(color: p.primary.withValues(alpha: 0.06)) : BorderSide.none)),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(
                  tx['type'] == 'KAUF' ? Icons.add_shopping_cart_rounded : tx['type'] == 'VERKAUF' ? Icons.sell_rounded : Icons.savings_rounded,
                  color: color, size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${tx['type']} ${tx['sym']}', style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(tx['amount'] as String, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(tx['value'] as String, style: GoogleFonts.spaceMono(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(tx['time'] as String, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  // ── QUANTUM RESEARCH PANEL ──
  Widget _buildQuantumResearchPanel(dynamic p, TimeCrystalService tc, AutoSaveService as2) {
    final ins = tc.getTradingInsights();
    final dtcRate   = (ins['dtcStabilityRate'] as double) * 100;
    final bestAcc   = (ins['bestModelAccuracy'] as double) * 100;
    final isQAdv    = ins['quantumAdvantage'] as bool;
    final regime    = ins['regimeInsight'] as String;

    // AutoSave status
    final saveState = as2.state;
    final saveAgo   = saveState.lastSavedAgo;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0A0020), const Color(0xFF150030)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF9945FF).withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(
          color: const Color(0xFF9945FF).withValues(alpha: 0.08),
          blurRadius: 16, spreadRadius: 1,
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [Color(0xFF9945FF), Color(0xFF14F195)]),
              ),
              child: const Icon(Icons.science_outlined, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('QUANTUM DEEP REASONING', style: GoogleFonts.spaceMono(
                color: const Color(0xFF9945FF), fontSize: 10,
                fontWeight: FontWeight.bold, letterSpacing: 1,
              )),
              Text('TimeCrystal · Floquet · QML · Trading Bridge',
                style: GoogleFonts.rajdhani(color: const Color(0xFF9945FF).withValues(alpha: 0.6), fontSize: 9)),
            ])),
            // AutoSave badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF14F195).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFF14F195).withValues(alpha: 0.3)),
              ),
              child: Text('💾 $saveAgo',
                style: GoogleFonts.rajdhani(color: const Color(0xFF14F195), fontSize: 8, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        // Stats row
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Row(children: [
            _qStatBox('EXP', '${tc.totalExperiments}', const Color(0xFF00F0FF)),
            const SizedBox(width: 10),
            _qStatBox('DTC', '${tc.dtcCount}', const Color(0xFF14F195)),
            const SizedBox(width: 10),
            _qStatBox('ORDER', '${(tc.avgDtcOrder * 100).toStringAsFixed(0)}%', const Color(0xFFF7931A)),
            const SizedBox(width: 10),
            _qStatBox('QML', bestAcc > 0 ? '${bestAcc.toStringAsFixed(0)}%' : '--', const Color(0xFF9945FF)),
            if (isQAdv) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF9945FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('QML⟨ψ⟩', style: GoogleFonts.rajdhani(
                  color: const Color(0xFF9945FF), fontSize: 8, fontWeight: FontWeight.w700)),
              ),
            ],
            const Spacer(),
            Container(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(regime,
                style: GoogleFonts.rajdhani(
                  color: const Color(0xFF14F195).withValues(alpha: 0.8), fontSize: 8),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
        // Mini phase diagram
        if (tc.experiments.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            height: 70,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                size: const Size(double.infinity, 70),
                painter: _DashboardPhaseMiniPainter(
                  experiments: tc.experiments,
                  animValue: _glowCtrl.value,
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _qStatBox(String label, String value, Color c) {
    return Column(children: [
      Text(value, style: GoogleFonts.spaceMono(color: c, fontSize: 12, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.rajdhani(color: c.withValues(alpha: 0.5), fontSize: 8)),
    ]);
  }

  // ── NEWS ──
  Widget _buildNewsSection(dynamic p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.1)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Icon(Icons.newspaper_rounded, color: p.primary, size: 16),
            const SizedBox(width: 8),
            Text('MARKT NEWS', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 10, letterSpacing: 1.5)),
            const Spacer(),
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFF00FF88).withValues(alpha: 0.5 + _pulseCtrl.value * 0.4), blurRadius: 6)],
                ),
              ),
            ),
          ]),
        ),
        ..._news.asMap().entries.map((entry) {
          final i = entry.key;
          final n = entry.value;
          final sentimentColor = n['sentiment'] == 'bullisch' ? const Color(0xFF00FF88) : n['sentiment'] == 'bärisch' ? const Color(0xFFFF3358) : const Color(0xFFFFD700);
          return GestureDetector(
            onTap: () => HapticFeedback.selectionClick(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(border: Border(top: i > 0 ? BorderSide(color: p.primary.withValues(alpha: 0.06)) : BorderSide.none)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 4, height: 4, margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: BoxDecoration(color: sentimentColor, shape: BoxShape.circle),
                ),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n['title'] as String, style: GoogleFonts.inter(color: p.textPrimary, fontSize: 11, height: 1.4)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(3)),
                      child: Text(n['tag'] as String, style: GoogleFonts.spaceMono(color: p.primary, fontSize: 8)),
                    ),
                    const SizedBox(width: 6),
                    Text(n['time'] as String, style: GoogleFonts.inter(color: p.textSecondary.withValues(alpha: 0.6), fontSize: 9)),
                  ]),
                ])),
                Icon(Icons.chevron_right_rounded, color: p.textSecondary.withValues(alpha: 0.3), size: 16),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  String _formatLarge(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(2)}K';
    return v.toStringAsFixed(2);
  }
}

// ── Custom Painters ──

class _DonutPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _DonutPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    double startAngle = -pi / 2;
    for (final d in data) {
      final sweep = (d['pct'] as double) / 100 * 2 * pi;
      final paint = Paint()
        ..color = d['color'] as Color
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 4), startAngle, sweep - 0.05, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => false;
}

class _PnLChartPainter extends CustomPainter {
  final List<double> data;
  final double minV, maxV;
  final Color color;
  _PnLChartPainter(this.data, this.minV, this.maxV, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final range = maxV - minV;
    final linePaint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()..shader = LinearGradient(
      colors: [color.withAlpha(60), color.withAlpha(0)],
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path(), fill = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minV) / range) * size.height;
      if (i == 0) { path.moveTo(x, y); fill.moveTo(x, size.height); fill.lineTo(x, y); }
      else { path.lineTo(x, y); fill.lineTo(x, y); }
    }
    fill.lineTo(size.width, size.height); fill.close();
    canvas.drawPath(fill, fillPaint);
    canvas.drawPath(path, linePaint);

    // Current dot
    final lastX = size.width;
    final lastY = size.height - ((data.last - minV) / range) * size.height;
    canvas.drawCircle(Offset(lastX, lastY), 4, Paint()..color = color);
    canvas.drawCircle(Offset(lastX, lastY), 7, Paint()..color = color.withAlpha(60)..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_PnLChartPainter old) => old.data.length != data.length || old.data.last != data.last;
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minV = data.reduce(min);
    final maxV = data.reduce(max);
    final range = max(maxV - minV, 0.001);
    final paint = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minV) / range) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.data.length != data.length;
}

// ══════════════════════════════════════════════════════════════
// DASHBOARD — Mini Phase Diagram Painter
// ══════════════════════════════════════════════════════════════
class _DashboardPhaseMiniPainter extends CustomPainter {
  final List<TCExperiment> experiments;
  final double animValue;
  const _DashboardPhaseMiniPainter({required this.experiments, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF050010));

    // Grid
    final gridP = Paint()..color = const Color(0xFF1A1A2E)..strokeWidth = 0.5;
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(Offset(w * i / 4, 0), Offset(w * i / 4, h), gridP);
      canvas.drawLine(Offset(0, h * i / 4), Offset(w, h * i / 4), gridP);
    }

    // Phase region shading
    double xOf(double o) => o / 2.0 * w;
    double yOf(double d) => h - d * h;

    // DTC region
    canvas.drawRect(
      Rect.fromLTRB(xOf(0.5), yOf(0.6), xOf(1.4), yOf(0.1)),
      Paint()..color = const Color(0xFF14F195).withValues(alpha: 0.1),
    );

    // Experiment dots
    for (final e in experiments) {
      final col = _c(e.detectedPhase);
      final px = xOf(e.driveAmplitude);
      final py = yOf(e.disorderW);
      canvas.drawCircle(Offset(px, py), 4,
          Paint()..color = col.withValues(alpha: 0.9));
    }

    // Labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    void lbl(String t, double x, double y, Color c) {
      tp.text = TextSpan(text: t, style: TextStyle(
        color: c.withValues(alpha: 0.6), fontSize: 7, fontFamily: 'monospace'));
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
    lbl('DTC', xOf(0.95), yOf(0.35), const Color(0xFF14F195));
    lbl('MBL', xOf(1.0), yOf(0.8), const Color(0xFFF7931A));
    lbl('CHAOS', xOf(1.75), yOf(0.3), const Color(0xFFFF4444));

    // X/Y axis labels
    void axLbl(String t, Offset o) {
      tp.text = TextSpan(text: t, style: const TextStyle(
        color: Color(0xFF445566), fontSize: 6, fontFamily: 'monospace'));
      tp.layout();
      tp.paint(canvas, o);
    }
    axLbl('Ω→', Offset(w - 18, h - 10));
    axLbl('W↑', const Offset(2, 2));
  }

  Color _c(TCPhase ph) => const {
    TCPhase.dtcOrdered: Color(0xFF14F195),
    TCPhase.mbl:        Color(0xFFF7931A),
    TCPhase.chaotic:    Color(0xFFFF4444),
    TCPhase.trivial:    Color(0xFF627EEA),
    TCPhase.unknown:    Color(0xFF888888),
  }[ph]!;

  @override
  bool shouldRepaint(covariant _DashboardPhaseMiniPainter old) =>
      old.experiments.length != experiments.length || old.animValue != animValue;
}
