import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/theme_provider.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});
  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final List<_Asset> _assets = [
    _Asset('BTC', 'Bitcoin', 0.42, 67842.50, 45.2, 2.34, true),
    _Asset('ETH', 'Ethereum', 3.85, 3548.20, 28.1, 1.87, true),
    _Asset('SOL', 'Solana', 12.0, 182.40, 9.6, -0.52, false),
    _Asset('QEMMA', '\$QEMMA Token', 1284.0, 0.0847, 4.7, 12.45, true),
    _Asset('BNB', 'BNB Chain', 2.1, 598.30, 5.5, 0.94, true),
    _Asset('USDT', 'Tether', 1480.0, 1.0, 6.9, 0.01, true),
  ];

  final List<Color> _sectorColors = [];
  int _touchedIndex = -1;
  final Random _rnd = Random(42);

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;

    if (_sectorColors.isEmpty) {
      _sectorColors.addAll([p.primary, p.secondary, p.accent, p.positive,
        p.primary.withValues(alpha: 0.7), p.secondary.withValues(alpha: 0.6)]);
    }

    final totalValue = _assets.fold<double>(0, (s, a) => s + a.value);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Total Value Header
          _buildTotalCard(p, totalValue),
          const SizedBox(height: 12),
          // Donut Chart
          _buildDonutChart(p, totalValue),
          const SizedBox(height: 12),
          // Emma Analysis
          _buildEmmaAnalysis(p),
          const SizedBox(height: 12),
          // Assets List
          _buildAssetsList(p),
          const SizedBox(height: 12),
          // Performance Chart
          _buildPerformanceCard(p),
        ],
      ),
    );
  }

  Widget _buildTotalCard(dynamic p, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [p.surface, p.surfaceVariant], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text('Gesamtportfolio', style: GoogleFonts.exo(color: p.textSecondary, fontSize: 13, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('\$${total.toStringAsFixed(2)}',
              style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: p.positive.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(Icons.arrow_upward, color: p.positive, size: 14),
                  Text(' +\$1,240.50 (2.18%) heute', style: TextStyle(color: p.positive, fontSize: 12)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Sharpe Ratio', value: '1.84', color: p.positive),
              _StatItem(label: 'Max Drawdown', value: '-12.3%', color: p.negative),
              _StatItem(label: 'Emma Score', value: 'B+', color: p.primary),
              _StatItem(label: 'Risiko', value: '6.2/10', color: p.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(dynamic p, double total) {
    final sections = _assets.asMap().entries.map((e) {
      final isTouched = _touchedIndex == e.key;
      return PieChartSectionData(
        color: _sectorColors[e.key % _sectorColors.length],
        value: e.value.value / total * 100,
        title: isTouched ? '${e.value.symbol}\n${(e.value.value / total * 100).toStringAsFixed(1)}%' : '',
        radius: isTouched ? 58 : 50,
        titleStyle: TextStyle(color: p.background, fontSize: 10, fontWeight: FontWeight.bold),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.primary.withValues(alpha: 0.2))),
      child: Column(
        children: [
          Text('Allokation', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 140, height: 140,
                child: PieChart(PieChartData(
                  sections: sections,
                  centerSpaceRadius: 36,
                  pieTouchData: PieTouchData(touchCallback: (_, res) {
                    setState(() => _touchedIndex = res?.touchedSection?.touchedSectionIndex ?? -1);
                  }),
                )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: _assets.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: _sectorColors[e.key % _sectorColors.length], borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 6),
                      Text(e.value.symbol, style: TextStyle(color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('${e.value.allocation.toStringAsFixed(1)}%', style: TextStyle(color: p.textSecondary, fontSize: 11)),
                    ]),
                  )).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmmaAnalysis(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [p.primary, p.secondary])),
            child: Icon(Icons.remove_red_eye, color: p.background, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emma Portfolio-Analyse', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Stablecoin-Reserve (6.9%) zu niedrig – Emma empfiehlt 15%. BTC-Allokation optimal. QEMMA-Token zeigt +12.45% heute – Teilgewinnmitnahme erwägen.',
                    style: GoogleFonts.exo(color: p.textPrimary, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsList(dynamic p) {
    return Container(
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.primary.withValues(alpha: 0.15))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text('Assets', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_assets.length} Positionen', style: TextStyle(color: p.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          ..._assets.map((a) => _buildAssetRow(p, a)),
        ],
      ),
    );
  }

  Widget _buildAssetRow(dynamic p, _Asset a) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: p.primary.withValues(alpha: 0.07)))),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: p.surfaceVariant, shape: BoxShape.circle),
            child: Center(child: Text(a.symbol[0], style: GoogleFonts.rajdhani(color: p.primary, fontSize: 15, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.symbol, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
              Text('${a.amount.toStringAsFixed(a.symbol == 'USDT' ? 0 : 4)} ${a.symbol}', style: TextStyle(color: p.textSecondary, fontSize: 11)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${a.value.toStringAsFixed(2)}', style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            Text(a.changeStr, style: TextStyle(color: a.isPositive ? p.positive : p.negative, fontSize: 11)),
          ]),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(dynamic p) {
    final spots = List.generate(30, (i) {
      final base = 20000.0 + i * 450;
      return FlSpot(i.toDouble(), base + _rnd.nextDouble() * 2000 - 500);
    });
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.primary.withValues(alpha: 0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('30-Tage-Performance', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [LineChartBarData(
                spots: spots, isCurved: true, color: p.positive, barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [p.positive.withValues(alpha: 0.25), p.positive.withValues(alpha: 0.0)],
                )),
              )],
            )),
          ),
        ],
      ),
    );
  }
}

class _Asset {
  final String symbol, name;
  final double amount, price, allocation, change;
  final bool isPositive;
  _Asset(this.symbol, this.name, this.amount, this.price, this.allocation, this.change, this.isPositive);
  double get value => amount * price;
  String get changeStr => '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%';
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: GoogleFonts.rajdhani(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 9)),
    ]);
  }
}
