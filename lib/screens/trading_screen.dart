import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/theme_provider.dart';

class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key});
  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _tickCtrl;
  int _selectedPair = 0;
  String _timeframe = '4H';

  final List<_TradingPair> _pairs = [
    _TradingPair('BTC', 'Bitcoin', 67842.50, 2.34, true),
    _TradingPair('ETH', 'Ethereum', 3548.20, 1.87, true),
    _TradingPair('SOL', 'Solana', 182.40, -0.52, false),
    _TradingPair('QEMMA', '\$QEMMA Token', 0.0847, 12.45, true),
    _TradingPair('BNB', 'BNB Chain', 598.30, 0.94, true),
    _TradingPair('ADA', 'Cardano', 0.624, -1.23, false),
  ];

  final List<String> _timeframes = ['15M', '1H', '4H', '1D', '1W'];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _tickCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _tickCtrl.dispose();
    super.dispose();
  }

  List<FlSpot> _generateChartData(int seed) {
    final rnd = Random(seed);
    double price = 100;
    return List.generate(50, (i) {
      price += (rnd.nextDouble() - 0.47) * 5;
      return FlSpot(i.toDouble(), price.clamp(50, 180));
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;
    final pair = _pairs[_selectedPair];

    return Column(
      children: [
        // Scrollable Pair Selector
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _pairs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final selected = _selectedPair == i;
              final pr = _pairs[i];
              return GestureDetector(
                onTap: () => setState(() => _selectedPair = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? p.primary.withValues(alpha: 0.15) : p.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? p.primary : p.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(pr.symbol, style: GoogleFonts.rajdhani(color: selected ? p.primary : p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(pr.changeStr, style: TextStyle(color: pr.isPositive ? p.positive : p.negative, fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Price Header Card
                _buildPriceCard(p, pair),
                const SizedBox(height: 12),
                // Chart
                _buildChartCard(p, pair),
                const SizedBox(height: 12),
                // Emma Signal
                _buildEmmaSignalCard(p, pair),
                const SizedBox(height: 12),
                // Order Panel
                _buildOrderPanel(p, pair),
                const SizedBox(height: 12),
                // Market Stats
                _buildMarketStats(p, pair),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard(dynamic p, _TradingPair pair) {
    return AnimatedBuilder(
      animation: _tickCtrl,
      builder: (_, __) {
        final flicker = sin(_tickCtrl.value * 2 * pi) * 0.5 * (_rnd.nextDouble() * 20 - 10);
        final displayPrice = pair.price + flicker * 0.01;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${pair.symbol}/USDT', style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Text(pair.name, style: TextStyle(color: p.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text('\$${displayPrice.toStringAsFixed(pair.symbol == 'QEMMA' ? 4 : 2)}',
                        style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (pair.isPositive ? p.positive : p.negative).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(pair.changeStr,
                        style: GoogleFonts.rajdhani(color: pair.isPositive ? p.positive : p.negative, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Text('24H Change', style: TextStyle(color: p.textSecondary, fontSize: 10)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.arrow_upward, color: p.positive, size: 12),
                    Text('H: \$${(pair.price * 1.025).toStringAsFixed(2)}', style: TextStyle(color: p.positive, fontSize: 11)),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_downward, color: p.negative, size: 12),
                    Text('L: \$${(pair.price * 0.978).toStringAsFixed(2)}', style: TextStyle(color: p.negative, fontSize: 11)),
                  ]),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartCard(dynamic p, _TradingPair pair) {
    final spots = _generateChartData(_selectedPair * 100);
    final isUp = spots.last.y > spots.first.y;
    final lineColor = isUp ? p.positive : p.negative;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Preis-Chart', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 14, fontWeight: FontWeight.bold)),
              Row(
                children: _timeframes.map((tf) {
                  final selected = _timeframe == tf;
                  return GestureDetector(
                    onTap: () => setState(() => _timeframe = tf),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected ? p.primary : p.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(tf, style: TextStyle(color: selected ? p.background : p.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: p.primary.withValues(alpha: 0.08), strokeWidth: 1),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [lineColor.withValues(alpha: 0.3), lineColor.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: p.primary, size: 12),
              const SizedBox(width: 4),
              Text('Quantum-Resonanz-Overlay aktiv', style: TextStyle(color: p.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmmaSignalCard(dynamic p, _TradingPair pair) {
    final signal = pair.isPositive ? 'KAUFEN' : 'HALTEN';
    final signalColor = pair.isPositive ? p.positive : p.secondary;
    final confidence = 72 + _rnd.nextInt(15);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
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
                Text('Emma Oracle Signal', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                Text('RSI: ${55 + _rnd.nextInt(20)} · Resonanz: +${(0.6 + _rnd.nextDouble() * 0.3).toStringAsFixed(2)}', style: TextStyle(color: p.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: signalColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: signalColor.withValues(alpha: 0.5))),
                child: Text(signal, style: GoogleFonts.rajdhani(color: signalColor, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 2),
              Text('$confidence% Konfidenz', style: TextStyle(color: p.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderPanel(dynamic p, _TradingPair pair) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order eingeben', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _OrderTypeBtn(label: 'KAUFEN', color: p.positive, bg: p.background)),
            const SizedBox(width: 8),
            Expanded(child: _OrderTypeBtn(label: 'VERKAUFEN', color: p.negative, bg: p.background)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _InfoTile(label: 'Preis (USDT)', value: '\$${pair.price.toStringAsFixed(2)}', p: p)),
            const SizedBox(width: 8),
            Expanded(child: _InfoTile(label: 'Menge', value: '0.00 ${pair.symbol}', p: p)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _InfoTile(label: 'Gesamt', value: '\$0.00', p: p)),
            const SizedBox(width: 8),
            Expanded(child: _InfoTile(label: 'Gebühr (0.1%)', value: '\$0.00', p: p)),
          ]),
        ],
      ),
    );
  }

  Widget _buildMarketStats(dynamic p, _TradingPair pair) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Markt-Statistiken', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...[
            ('Marktkapitalisierung', '\$${(pair.price * 19700000).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'),
            ('24H Volumen', '\$${(pair.price * 850000).toStringAsFixed(0)}'),
            ('Umlaufangebot', '19.7M ${pair.symbol}'),
            ('Quantum-Score', '${72 + _rnd.nextInt(20)}/100'),
            ('Agenten-Konsens', '5/6 Bullisch'),
          ].map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.$1, style: TextStyle(color: p.textSecondary, fontSize: 12)),
                Text(e.$2, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _TradingPair {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final bool isPositive;
  _TradingPair(this.symbol, this.name, this.price, this.change, this.isPositive);
  String get changeStr => '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%';
}

class _OrderTypeBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _OrderTypeBtn({required this.label, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final dynamic p;
  const _InfoTile({required this.label, required this.value, required this.p});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: p.surfaceVariant, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: p.textSecondary, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
