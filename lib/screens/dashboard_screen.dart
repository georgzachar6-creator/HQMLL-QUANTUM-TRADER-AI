// ============================================================
// DASHBOARD v3 – HQMLL Quantum Trader
// Live Portfolio, P&L Timeline, AI Signals, News, Watchlist
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/live_price_provider.dart';
import '../widgets/crypto_icon.dart';

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

    // Initialize live price provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lp = context.read<LivePriceProvider>();
      await lp.initialize();
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

  void _startLive() {
    _liveTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted) return;
      setState(() {
        // Animate portfolio value
        _totalValue += (_rand.nextDouble() - 0.48) * 120;
        _pnlDay = _totalValue - 73662.82;
        _pnlDayPct = (_pnlDay / 73662.82) * 100;

        // Animate prices
        for (var w in _watchlist) {
          final p = w['price'] as double;
          final np = p * (1 + (_rand.nextDouble() - 0.5) * 0.004);
          w['price'] = np;
          w['change'] = (w['change'] as double) + (_rand.nextDouble() - 0.5) * 0.05;
          (w['hist'] as List<double>).add(np);
          if ((w['hist'] as List<double>).length > 20) (w['hist'] as List<double>).removeAt(0);
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
    final lp = context.watch<LivePriceProvider>();

    // Sync watchlist prices from live provider
    for (var w in _watchlist) {
      final sym = w['sym'] as String;
      final q = lp.getQuote(sym);
      if (q != null) {
        final prev = w['price'] as double;
        w['price'] = q.price;
        w['change'] = q.change24h;
        if (prev != q.price) {
          (w['hist'] as List<double>).add(q.price);
          if ((w['hist'] as List<double>).length > 20) (w['hist'] as List<double>).removeAt(0);
        }
      }
    }

    return Scaffold(
      backgroundColor: p.background,
      body: RefreshIndicator(
        color: p.primary,
        backgroundColor: p.surface,
        onRefresh: () async {
          await lp.refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(children: [
            _buildHeader(p, lp),
            _buildPortfolioCard(p),
            _buildAllocationRow(p),
            _buildAISignalBanner(p),
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

  // ── HEADER ──
  Widget _buildHeader(dynamic p, LivePriceProvider lp) {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Guten Morgen' : now.hour < 18 ? 'Guten Tag' : 'Guten Abend';
    final isWsConnected = lp.wsConnected;
    final connCount = lp.connectedExchanges;
    final tps = lp.ticksPerSecond;
    final liveColor = isWsConnected ? const Color(0xFF00FF88) : const Color(0xFFFFAA00);
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
            if (isWsConnected && connCount > 0)
              Text('$connCount Börsen · ${tps}t/s', style: GoogleFonts.spaceMono(
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
              Text(isWsConnected ? 'WS LIVE' : 'REST', style: GoogleFonts.spaceMono(color: liveColor, fontSize: 10, letterSpacing: 1)),
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
  Widget _buildAISignalBanner(dynamic p) {
    final topSignal = _signals.first;
    final color = topSignal['color'] as Color;
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3 + _glowCtrl.value * 0.15)),
        ),
        child: Row(children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3 + _pulseCtrl.value * 0.25), blurRadius: 10)],
              ),
              child: Icon(Icons.psychology_rounded, color: color, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('TR2 AI SIGNAL', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9, letterSpacing: 1)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
                child: Text(topSignal['tf'] as String, style: GoogleFonts.spaceMono(color: color, fontSize: 8)),
              ),
            ]),
            Text('${topSignal['pair']} — ${topSignal['action']}', style: GoogleFonts.spaceMono(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(topSignal['reason'] as String, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
          ])),
          Column(children: [
            Text('${topSignal['conf']}%', style: GoogleFonts.spaceMono(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('CONF', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
          ]),
        ]),
      ),
    );
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
