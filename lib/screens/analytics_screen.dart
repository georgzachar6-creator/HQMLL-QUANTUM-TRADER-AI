/// HQMLL Quantum Trader – Advanced Analytics Screen
/// Heatmap · Korrelations-Matrix · Risk Metrics · Sentiment
/// Grigori Saks · 2025
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _pulseCtrl;
  Timer? _refreshTimer;
  final Random _rng = Random(42);

  // ── Heatmap data ───────────────────────────────────
  final List<_HeatCell> _heatData = [];

  // ── Correlation data ───────────────────────────────
  final List<String> _corrSymbols = ['BTC','ETH','SOL','BNB','AAPL','TSLA','XAU','EUR'];
  late List<List<double>> _corrMatrix;

  // ── Fear & Greed index ─────────────────────────────
  double _fearGreed = 72;
  String get _fearGreedLabel {
    if (_fearGreed >= 80) return 'EXTREME GIER';
    if (_fearGreed >= 60) return 'GIER';
    if (_fearGreed >= 40) return 'NEUTRAL';
    if (_fearGreed >= 20) return 'ANGST';
    return 'EXTREME ANGST';
  }
  Color get _fearGreedColor {
    if (_fearGreed >= 60) return Colors.greenAccent;
    if (_fearGreed >= 40) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _initHeatmap();
    _initCorrelation();
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _updateHeatmap();
        _fearGreed = (_fearGreed + (_rng.nextDouble() - 0.5) * 2)
            .clamp(5.0, 95.0);
      });
    });
  }

  void _initHeatmap() {
    final assets = [
      ('BTC', 'Bitcoin', 2.34, 1284e9),
      ('ETH', 'Ethereum', 1.87, 426e9),
      ('BNB', 'BNB', 0.94, 88e9),
      ('SOL', 'Solana', -0.52, 80e9),
      ('QEMMA', 'QEMMA', 12.45, 156e6),
      ('XRP', 'Ripple', 0.78, 28.4e9),
      ('ADA', 'Cardano', -1.23, 15.8e9),
      ('DOGE', 'Dogecoin', -3.44, 12.7e9),
      ('AVAX', 'Avalanche', 4.56, 14.9e9),
      ('DOT', 'Polkadot', -0.88, 9.8e9),
      ('MATIC', 'Polygon', 2.11, 7.1e9),
      ('LINK', 'Chainlink', 3.45, 8.2e9),
      ('AAPL', 'Apple', -0.42, 2930e9),
      ('TSLA', 'Tesla', 2.18, 783e9),
      ('NVDA', 'NVIDIA', 3.21, 2160e9),
      ('GOOGL', 'Google', 0.84, 2060e9),
      ('MSFT', 'Microsoft', 0.56, 3090e9),
      ('META', 'Meta', 1.78, 1220e9),
      ('XAU', 'Gold', 0.34, 0),
      ('XAG', 'Silver', 0.71, 0),
    ];
    for (final a in assets) {
      _heatData.add(_HeatCell(
        symbol: a.$1,
        name: a.$2,
        change: a.$3.toDouble(),
        marketCap: a.$4.toDouble(),
      ));
    }
  }

  void _updateHeatmap() {
    for (int i = 0; i < _heatData.length; i++) {
      final delta = (_rng.nextDouble() - 0.499) * 0.3;
      _heatData[i] = _HeatCell(
        symbol: _heatData[i].symbol,
        name: _heatData[i].name,
        change: (_heatData[i].change + delta).toDouble(),
        marketCap: _heatData[i].marketCap,
      );
    }
  }

  void _initCorrelation() {
    // Realistic correlation matrix
    final base = [
      [1.00, 0.88, 0.82, 0.79, 0.12, 0.18, 0.24, -0.15],
      [0.88, 1.00, 0.85, 0.81, 0.14, 0.20, 0.22, -0.12],
      [0.82, 0.85, 1.00, 0.78, 0.08, 0.15, 0.18, -0.10],
      [0.79, 0.81, 0.78, 1.00, 0.11, 0.17, 0.16, -0.08],
      [0.12, 0.14, 0.08, 0.11, 1.00, 0.65, 0.08,  0.04],
      [0.18, 0.20, 0.15, 0.17, 0.65, 1.00, 0.12,  0.06],
      [0.24, 0.22, 0.18, 0.16, 0.08, 0.12, 1.00,  0.42],
      [-0.15,-0.12,-0.10,-0.08, 0.04, 0.06, 0.42, 1.00],
    ];
    _corrMatrix = base;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: p.background,
      body: Column(
        children: [
          _buildHeader(p),
          _buildTabBar(p),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildHeatmapTab(p),
                _buildCorrelationTab(p),
                _buildRiskTab(p),
                _buildSentimentTab(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────
  Widget _buildHeader(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.surface, p.background],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
              color: Colors.tealAccent.withValues(alpha: 0.35))),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Colors.tealAccent, Color(0xFF00D4FF)]),
              boxShadow: [
                BoxShadow(
                    color: Colors.tealAccent.withValues(alpha: 0.4),
                    blurRadius: 12)
              ],
            ),
            child: const Center(
                child: Icon(Icons.analytics, color: Colors.white, size: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ANALYTICS',
                    style: GoogleFonts.orbitron(
                        color: p.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
                Text('Heatmap · Korrelation · Risk · Sentiment',
                    style:
                        TextStyle(color: p.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.tealAccent
                    .withValues(alpha: 0.1 + _pulseCtrl.value * 0.08),
                border: Border.all(
                    color:
                        Colors.tealAccent.withValues(alpha: 0.5)),
              ),
              child: const Text('LIVE',
                  style: TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────
  Widget _buildTabBar(QuantumPalette p) {
    return Container(
      color: p.surface,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: Colors.tealAccent,
        indicatorWeight: 2,
        labelColor: Colors.tealAccent,
        unselectedLabelColor: p.textSecondary,
        labelStyle: const TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        tabs: const [
          Tab(text: 'HEATMAP',    icon: Icon(Icons.grid_view, size: 15)),
          Tab(text: 'KORRELATION',icon: Icon(Icons.hub,       size: 15)),
          Tab(text: 'RISK',       icon: Icon(Icons.shield,    size: 15)),
          Tab(text: 'SENTIMENT',  icon: Icon(Icons.psychology,size: 15)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // HEATMAP TAB
  // ══════════════════════════════════════════════════
  Widget _buildHeatmapTab(QuantumPalette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('MARKT HEATMAP · 24H', Icons.grid_view,
              Colors.tealAccent, p),
          const SizedBox(height: 8),
          _buildHeatGrid(p),
          const SizedBox(height: 16),
          _buildTopGainersLosers(p),
        ],
      ),
    );
  }

  Widget _buildHeatGrid(QuantumPalette p) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _heatData.length,
      itemBuilder: (_, i) {
        final cell = _heatData[i];
        final chg = cell.change;
        final isPos = chg >= 0;
        // Intensity 0-1
        final intensity = (chg.abs() / 10).clamp(0.0, 1.0);
        final bg = isPos
            ? Color.lerp(Colors.green.shade900,
                Colors.greenAccent, intensity)!
            : Color.lerp(Colors.red.shade900,
                Colors.redAccent, intensity)!;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: bg.withValues(alpha: 0.25 + intensity * 0.5),
            border: Border.all(
                color: bg.withValues(alpha: 0.4), width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(cell.symbol,
                  style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                '${isPos ? '+' : ''}${chg.toStringAsFixed(2)}%',
                style: TextStyle(
                    color: isPos ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopGainersLosers(QuantumPalette p) {
    final sorted = [..._heatData]
      ..sort((a, b) => b.change.compareTo(a.change));
    final gainers = sorted.take(5).toList();
    final losers = sorted.reversed.take(5).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildRankList('TOP GAINERS', gainers, true, p)),
        const SizedBox(width: 8),
        Expanded(child: _buildRankList('TOP LOSERS', losers, false, p)),
      ],
    );
  }

  Widget _buildRankList(
      String title, List<_HeatCell> cells, bool isGain, QuantumPalette p) {
    final color = isGain ? Colors.greenAccent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: p.surface,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.orbitron(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          ...cells.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(c.symbol,
                        style: TextStyle(
                            color: p.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11)),
                    const Spacer(),
                    Text(
                      '${c.change >= 0 ? '+' : ''}${c.change.toStringAsFixed(2)}%',
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // CORRELATION TAB
  // ══════════════════════════════════════════════════
  Widget _buildCorrelationTab(QuantumPalette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('KORRELATIONS-MATRIX', Icons.hub,
              Colors.blueAccent, p),
          const SizedBox(height: 4),
          Text(
            '+1.0 = perfekte Korrelation   −1.0 = inverse Korrelation',
            style: TextStyle(color: p.textSecondary, fontSize: 9),
          ),
          const SizedBox(height: 10),
          _buildCorrMatrix(p),
          const SizedBox(height: 16),
          _buildCorrInsights(p),
        ],
      ),
    );
  }

  Widget _buildCorrMatrix(QuantumPalette p) {
    const cell = 36.0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              SizedBox(width: cell + 4),
              ..._corrSymbols.map((s) => SizedBox(
                    width: cell,
                    child: Center(
                      child: Text(s,
                          style: TextStyle(
                              color: p.textSecondary,
                              fontSize: 8,
                              fontWeight: FontWeight.w700)),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 4),
          ..._corrSymbols.asMap().entries.map((rowE) {
            final r = rowE.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: cell + 4,
                    child: Text(_corrSymbols[r],
                        style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 8,
                            fontWeight: FontWeight.w700)),
                  ),
                  ..._corrSymbols.asMap().entries.map((colE) {
                    final c = colE.key;
                    final val = _corrMatrix[r][c];
                    final isPos = val >= 0;
                    final intensity = val.abs().clamp(0.0, 1.0);
                    final bg = r == c
                        ? Colors.grey.shade700
                        : isPos
                            ? Color.lerp(
                                Colors.transparent,
                                Colors.greenAccent,
                                intensity)!
                            : Color.lerp(
                                Colors.transparent,
                                Colors.redAccent,
                                intensity)!;
                    return Container(
                      width: cell,
                      height: cell,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: bg.withValues(alpha: 0.35),
                        border: Border.all(
                            color: bg.withValues(alpha: 0.25),
                            width: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          val.toStringAsFixed(2),
                          style: TextStyle(
                              color: r == c
                                  ? Colors.white
                                  : isPos
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCorrInsights(QuantumPalette p) {
    final insights = [
      ('BTC ↔ ETH', 0.88, 'Sehr stark positiv korreliert'),
      ('Crypto ↔ Stocks', 0.12, 'Schwache Korrelation – gute Diversifizierung'),
      ('XAU ↔ EUR', 0.42, 'Moderate Korrelation – beide als Safe Haven'),
      ('Crypto ↔ Gold', 0.22, 'Geringe Korrelation – diversifiziert gut'),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: p.surface,
        border:
            Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ERKENNTNISSE', Icons.lightbulb_outline,
              Colors.orangeAccent, p),
          const SizedBox(height: 8),
          ...insights.map((ins) {
            final isPos = ins.$2 >= 0;
            final color =
                ins.$2.abs() > 0.6 ? Colors.orangeAccent : Colors.blueAccent;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: color.withValues(alpha: 0.12),
                    ),
                    child: Text(ins.$1,
                        style: TextStyle(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isPos ? '+' : ''}${ins.$2.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: isPos
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(ins.$3,
                        style: TextStyle(
                            color: p.textSecondary, fontSize: 10)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // RISK TAB
  // ══════════════════════════════════════════════════
  Widget _buildRiskTab(QuantumPalette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildRiskGauge(p),
          const SizedBox(height: 12),
          _buildRiskMetricsGrid(p),
          const SizedBox(height: 12),
          _buildVaRChart(p),
          const SizedBox(height: 12),
          _buildRiskBreakdown(p),
        ],
      ),
    );
  }

  Widget _buildRiskGauge(QuantumPalette p) {
    // Risk score 0-100
    const riskScore = 38.0;
    final riskColor = riskScore < 30
        ? Colors.greenAccent
        : riskScore < 60
            ? Colors.orangeAccent
            : Colors.redAccent;
    final riskLabel = riskScore < 30
        ? 'NIEDRIG'
        : riskScore < 60
            ? 'MITTEL'
            : 'HOCH';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: p.surface,
        border:
            Border.all(color: riskColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: riskColor.withValues(alpha: 0.1), blurRadius: 20)
        ],
      ),
      child: Column(
        children: [
          Text('PORTFOLIO RISIKO',
              style: GoogleFonts.orbitron(
                  color: p.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: riskScore / 100,
                    strokeWidth: 12,
                    backgroundColor:
                        riskColor.withValues(alpha: 0.1),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(riskColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      riskScore.toStringAsFixed(0),
                      style: GoogleFonts.orbitron(
                          color: riskColor,
                          fontSize: 36,
                          fontWeight: FontWeight.w900),
                    ),
                    Text(riskLabel,
                        style: TextStyle(
                            color: riskColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Portfolio ist gut diversifiziert',
              style: TextStyle(color: p.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRiskMetricsGrid(QuantumPalette p) {
    final metrics = [
      ('Value at Risk (1d)', '-\$842', Colors.redAccent),
      ('Sharpe Ratio', '2.14', Colors.greenAccent),
      ('Sortino Ratio', '3.28', Colors.greenAccent),
      ('Beta (vs BTC)', '0.72', Colors.blueAccent),
      ('Max Drawdown', '-12.5%', Colors.redAccent),
      ('Volatilität 30d', '18.4%', Colors.orangeAccent),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8),
      itemCount: metrics.length,
      itemBuilder: (_, i) {
        final m = metrics[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: p.surface,
            border:
                Border.all(color: m.$3.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(m.$1,
                  style:
                      TextStyle(color: p.textSecondary, fontSize: 9)),
              const SizedBox(height: 4),
              Text(m.$2,
                  style: TextStyle(
                      color: m.$3,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVaRChart(QuantumPalette p) {
    final spots = List.generate(40, (i) {
      final x = i.toDouble();
      final y = -500 + _rng.nextDouble() * 1000 + (i < 10 ? -300 : i > 30 ? 300 : 0);
      return FlSpot(x, y);
    });

    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: p.surface,
        border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DAILY P&L DISTRIBUTION',
              style: GoogleFonts.orbitron(
                  color: Colors.redAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.center,
                barGroups: spots
                    .map((s) => BarChartGroupData(
                          x: s.x.toInt(),
                          barRods: [
                            BarChartRodData(
                              toY: s.y,
                              color: s.y >= 0
                                  ? Colors.greenAccent
                                      .withValues(alpha: 0.7)
                                  : Colors.redAccent
                                      .withValues(alpha: 0.7),
                              width: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ],
                        ))
                    .toList(),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBreakdown(QuantumPalette p) {
    final items = [
      ('Crypto-Risiko',  65.0, Colors.orangeAccent),
      ('Aktien-Risiko',  20.0, Colors.blueAccent),
      ('FX-Risiko',       8.0, const Color(0xFF003399)),
      ('Rohstoff-Risiko', 7.0, const Color(0xFFFFD700)),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: p.surface,
        border: Border.all(
            color: p.textSecondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('RISIKO AUFSCHLÜSSELUNG', Icons.pie_chart,
              Colors.orangeAccent, p),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.$1,
                            style: TextStyle(
                                color: p.textSecondary, fontSize: 11)),
                        Text('${item.$2.toStringAsFixed(0)}%',
                            style: TextStyle(
                                color: item.$3,
                                fontWeight: FontWeight.w700,
                                fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: item.$2 / 100,
                      backgroundColor:
                          item.$3.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(item.$3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // SENTIMENT TAB
  // ══════════════════════════════════════════════════
  Widget _buildSentimentTab(QuantumPalette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildFearGreedGauge(p),
          const SizedBox(height: 12),
          _buildSentimentGrid(p),
          const SizedBox(height: 12),
          _buildSocialMetrics(p),
          const SizedBox(height: 12),
          _buildSentimentHistory(p),
        ],
      ),
    );
  }

  Widget _buildFearGreedGauge(QuantumPalette p) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: p.surface,
          border: Border.all(
              color: _fearGreedColor.withValues(
                  alpha: 0.3 + _pulseCtrl.value * 0.15)),
          boxShadow: [
            BoxShadow(
                color: _fearGreedColor.withValues(alpha: 0.1),
                blurRadius: 20)
          ],
        ),
        child: Column(
          children: [
            Text('FEAR & GREED INDEX',
                style: GoogleFonts.orbitron(
                    color: p.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            const SizedBox(height: 16),
            Text(
              _fearGreed.toStringAsFixed(0),
              style: GoogleFonts.orbitron(
                  color: _fearGreedColor,
                  fontSize: 56,
                  fontWeight: FontWeight.w900),
            ),
            Text(_fearGreedLabel,
                style: TextStyle(
                    color: _fearGreedColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2)),
            const SizedBox(height: 12),
            // Gauge bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _fearGreed / 100,
                minHeight: 12,
                backgroundColor: p.background,
                valueColor: AlwaysStoppedAnimation<Color>(_fearGreedColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Extreme\nAngst',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.redAccent, fontSize: 8)),
                Text('Neutral',
                    style:
                        TextStyle(color: p.textSecondary, fontSize: 8)),
                Text('Extreme\nGier',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.greenAccent, fontSize: 8)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentGrid(QuantumPalette p) {
    final data = [
      ('Bitcoin', 74.0, Icons.currency_bitcoin, const Color(0xFFF7931A)),
      ('Ethereum', 68.0, Icons.architecture, const Color(0xFF627EEA)),
      ('QEMMA', 88.0, Icons.token, const Color(0xFF00D4FF)),
      ('Altcoins', 58.0, Icons.alt_route, Colors.purpleAccent),
      ('DeFi', 62.0, Icons.account_balance, Colors.tealAccent),
      ('NFT', 42.0, Icons.image, Colors.pinkAccent),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.0,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final d = data[i];
        final sentColor = d.$2 >= 60
            ? Colors.greenAccent
            : d.$2 >= 40
                ? Colors.orangeAccent
                : Colors.redAccent;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: p.surface,
            border: Border.all(color: d.$4.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(d.$3, color: d.$4, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(d.$1,
                        style: TextStyle(
                            color: p.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11)),
                    Text('${d.$2.toStringAsFixed(0)}/100',
                        style: TextStyle(
                            color: sentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSocialMetrics(QuantumPalette p) {
    final metrics = [
      (Icons.reddit, 'Reddit Mentions', '+2,840', Colors.orangeAccent),
      (Icons.tag, 'Twitter/X Mentions', '+18,420', const Color(0xFF1DA1F2)),
      (Icons.telegram, 'Telegram Activity', '+4,280', Colors.blueAccent),
      (Icons.search, 'Google Trends', '+34%', Colors.greenAccent),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: p.surface,
        border: Border.all(
            color: p.textSecondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('SOCIAL METRIKEN (24H)',
              Icons.share, Colors.blueAccent, p),
          const SizedBox(height: 10),
          ...metrics.map((m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(m.$1, color: m.$4, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(m.$2,
                          style: TextStyle(
                              color: p.textSecondary, fontSize: 12)),
                    ),
                    Text(m.$3,
                        style: TextStyle(
                            color: m.$4,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSentimentHistory(QuantumPalette p) {
    final history = List.generate(14, (i) {
      final val = 40 + _rng.nextDouble() * 50;
      return FlSpot(i.toDouble(), val);
    });
    return Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: p.surface,
        border: Border.all(
            color: Colors.orangeAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SENTIMENT VERLAUF (14 TAGE)',
              style: GoogleFonts.orbitron(
                  color: Colors.orangeAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: history,
                    isCurved: true,
                    color: Colors.orangeAccent,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.orangeAccent.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper ─────────────────────────────────────────
  Widget _sectionTitle(
      String title, IconData icon, Color color, QuantumPalette p) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Text(title,
            style: GoogleFonts.orbitron(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
      ],
    );
  }
}

// ── Helper class ───────────────────────────────────────
class _HeatCell {
  final String symbol;
  final String name;
  final double change;
  final double marketCap;
  const _HeatCell({
    required this.symbol,
    required this.name,
    required this.change,
    required this.marketCap,
  });
}
