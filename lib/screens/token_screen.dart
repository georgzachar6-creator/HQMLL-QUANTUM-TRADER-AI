import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/theme_provider.dart';
import '../widgets/quantum_eye_widget.dart';

class TokenScreen extends StatefulWidget {
  const TokenScreen({super.key});
  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _mineCtrl;
  final double _miningProgress = 0.67;
  int _selectedQuest = -1;
  final Random _rnd = Random(99);

  final List<_Quest> _quests = [
    _Quest('BTC-Trendanalyse', 'Analysiere den aktuellen BTC-Trend mit Emma', 10, false, Icons.show_chart),
    _Quest('Sentiment-Rätsel', 'Beantworte 3 Marktfragen korrekt', 15, false, Icons.psychology),
    _Quest('Resonanz-Kalibrierung', 'Bestätige 5 Quantum-Signale', 25, true, Icons.waves),
    _Quest('Portfolio-Optimierung', 'Folge Emmas Rebalancing-Empfehlung', 20, false, Icons.pie_chart),
    _Quest('Agenten-Debatte', 'Beobachte alle 6 Agenten-Insights', 30, false, Icons.hub),
  ];

  @override
  void initState() {
    super.initState();
    _mineCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _mineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildTokenHeader(p),
          const SizedBox(height: 12),
          _buildMiningCard(p),
          const SizedBox(height: 12),
          _buildQuestsCard(p),
          const SizedBox(height: 12),
          _buildTokenomicsCard(p),
          const SizedBox(height: 12),
          _buildListingRoadmap(p),
        ],
      ),
    );
  }

  Widget _buildTokenHeader(dynamic p) {
    final spots = List.generate(30, (i) => FlSpot(i.toDouble(), 0.04 + i * 0.002 + _rnd.nextDouble() * 0.015));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [p.surface, p.surfaceVariant], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.secondary.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              QuantumEyeWidget(palette: p, size: 50, animate: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('\$QEMMA Token', style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Text('Quantum Emma AI · Solana Network', style: TextStyle(color: p.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: p.positive, boxShadow: [BoxShadow(color: p.positive.withValues(alpha: 0.7), blurRadius: 5)])),
                      const SizedBox(width: 5),
                      Text('Devnet Live', style: TextStyle(color: p.positive, fontSize: 11)),
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$0.0847', style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('+12.45%', style: TextStyle(color: p.positive, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 70,
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [LineChartBarData(
                spots: spots, isCurved: true, color: p.positive, barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [p.positive.withValues(alpha: 0.25), Colors.transparent],
                )),
              )],
            )),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TokenStat('Mein Bestand', '1.284 QEMMA', '\$108.75', p),
              _TokenStat('Market Cap', '\$84.7M', '', p),
              _TokenStat('Volumen 24H', '\$2.4M', '', p),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiningCard(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: p.primary, size: 18),
              const SizedBox(width: 8),
              Text('AI Proof-of-Intelligence Mining', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          // Mining animation
          Center(
            child: AnimatedBuilder(
              animation: _mineCtrl,
              builder: (_, __) {
                return SizedBox(
                  width: 100, height: 100,
                  child: CustomPaint(painter: _MiningPainter(_mineCtrl.value, p)),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mining-Fortschritt', style: TextStyle(color: p.textSecondary, fontSize: 12)),
              Text('${(_miningProgress * 100).toStringAsFixed(0)}%', style: TextStyle(color: p.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _miningProgress,
              backgroundColor: p.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(p.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MineInfo('Heute', '47.5 QEMMA', p.positive, p),
              _MineInfo('Gesamt', '1.284 QEMMA', p.primary, p),
              _MineInfo('Rate', '~70/Tag', p.secondary, p),
              _MineInfo('Nächste Quest', '14 Min', p.accent, p),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestsCard(dynamic p) {
    return Container(
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.primary.withValues(alpha: 0.15))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Icon(Icons.quiz_outlined, color: p.primary, size: 16),
              const SizedBox(width: 8),
              Text('Aktive Quests', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${_quests.where((q) => !q.completed).length} verfügbar', style: TextStyle(color: p.textSecondary, fontSize: 11)),
            ]),
          ),
          ..._quests.asMap().entries.map((e) {
            final i = e.key;
            final q = e.value;
            return GestureDetector(
              onTap: () => setState(() => _selectedQuest = _selectedQuest == i ? -1 : i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedQuest == i ? p.primary.withValues(alpha: 0.08) : p.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedQuest == i ? p.primary.withValues(alpha: 0.4) : Colors.transparent),
                ),
                child: Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: q.completed ? p.positive.withValues(alpha: 0.15) : p.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: Icon(q.completed ? Icons.check_circle : q.icon, color: q.completed ? p.positive : p.primary, size: 18)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(q.name, style: TextStyle(color: q.completed ? p.textSecondary : p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600, decoration: q.completed ? TextDecoration.lineThrough : null)),
                    Text(q.description, style: TextStyle(color: p.textSecondary, fontSize: 10)),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('+${q.reward} QEMMA', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 11, fontWeight: FontWeight.bold))),
                ]),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildTokenomicsCard(dynamic p) {
    final data = [
      ('Grigori Saks Reserve', 21, p.secondary),
      ('Mining Pool', 35, p.primary),
      ('Liquidität', 20, p.accent),
      ('Entwicklung', 14, p.positive),
      ('Community', 10, p.positive.withValues(alpha: 0.6)),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.primary.withValues(alpha: 0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tokenomics · 1 Mrd. \$QEMMA', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...data.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(d.$1, style: TextStyle(color: p.textPrimary, fontSize: 12)),
                  Text('${d.$2}%', style: TextStyle(color: d.$3, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(value: d.$2 / 100, backgroundColor: p.surfaceVariant, valueColor: AlwaysStoppedAnimation<Color>(d.$3), minHeight: 5),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildListingRoadmap(dynamic p) {
    final phases = [
      ('Phase 1', 'Plattform-interne DEX (Raydium)', true),
      ('Phase 2', 'Jupiter + Top DEXes', true),
      ('Phase 3', 'CEX-Listings (Binance, Bybit)', false),
      ('Phase 4', 'Alle Börsen · Globaler Umlauf', false),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.primary.withValues(alpha: 0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listing-Roadmap', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...phases.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Column(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: e.value.$3 ? p.positive : p.surfaceVariant,
                    border: Border.all(color: e.value.$3 ? p.positive : p.primary.withValues(alpha: 0.3)),
                  ),
                  child: Icon(e.value.$3 ? Icons.check : Icons.radio_button_unchecked, color: e.value.$3 ? p.background : p.textSecondary, size: 14),
                ),
                if (e.key < phases.length - 1) Container(width: 2, height: 20, color: p.primary.withValues(alpha: 0.2)),
              ]),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.value.$1, style: GoogleFonts.rajdhani(color: e.value.$3 ? p.positive : p.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(e.value.$2, style: TextStyle(color: p.textSecondary, fontSize: 11)),
              ]),
            ]),
          )),
        ],
      ),
    );
  }
}

class _Quest {
  final String name, description;
  final int reward;
  final bool completed;
  final IconData icon;
  _Quest(this.name, this.description, this.reward, this.completed, this.icon);
}

class _TokenStat extends StatelessWidget {
  final String label, value, sub;
  final dynamic p;
  const _TokenStat(this.label, this.value, this.sub, this.p);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: TextStyle(color: p.textSecondary, fontSize: 10)),
      Text(value, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
      if (sub.isNotEmpty) Text(sub, style: TextStyle(color: p.positive, fontSize: 10)),
    ]);
  }
}

class _MineInfo extends StatelessWidget {
  final String label, value;
  final Color color;
  final dynamic p;
  const _MineInfo(this.label, this.value, this.color, this.p);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: TextStyle(color: p.textSecondary, fontSize: 9)),
      Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _MiningPainter extends CustomPainter {
  final double t;
  final dynamic p;
  _MiningPainter(this.t, this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;

    // Outer circle
    canvas.drawCircle(center, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = p.primary.withValues(alpha: 0.25));

    // Rotating arc
    final arcPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = p.primary..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), t * 2 * pi, pi * 1.2, false, arcPaint);

    // Inner pulsing dot
    final dotR = 12.0 + sin(t * 2 * pi) * 4;
    final dotPaint = Paint()..shader = RadialGradient(colors: [p.primary, p.secondary]).createShader(Rect.fromCircle(center: center, radius: dotR));
    canvas.drawCircle(center, dotR, dotPaint);

    // Mining particles
    for (int i = 0; i < 6; i++) {
      final angle = t * 2 * pi + i * pi / 3;
      final pr = r * (0.5 + sin(t * 2 * pi + i) * 0.2);
      final pos = center + Offset(cos(angle) * pr, sin(angle) * pr);
      canvas.drawCircle(pos, 2.5, Paint()..color = p.accent.withValues(alpha: 0.7));
    }
  }

  @override
  bool shouldRepaint(_MiningPainter old) => old.t != t;
}
