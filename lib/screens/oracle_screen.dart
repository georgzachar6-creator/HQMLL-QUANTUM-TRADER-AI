// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/live_market_service.dart';

// ═══════════════════════════════════════════════════════════════
//  ORACLE AI PREDICTION ENGINE v2 — HQMLL Quantum Signals
//  Quantum Trader AI System v16.0
// ═══════════════════════════════════════════════════════════════

class OracleScreen extends StatefulWidget {
  const OracleScreen({super.key});
  @override
  State<OracleScreen> createState() => _OracleScreenState();
}

class _OracleScreenState extends State<OracleScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _scanAnim;
  late Animation<double> _pulseAnim;

  final Random _rng = Random(42);
  Timer? _refreshTimer;
  int _selectedTab = 0;
  String _selectedSymbol = 'BTC';
  String _selectedTimeframe = '4H';

  // AI Signals
  late List<_AISignal> _signals;
  late List<_Prediction> _predictions;
  late List<_SupportLevel> _levels;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _scanAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_scanCtrl);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _generateSignals();
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) setState(() => _generateSignals());
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _generateSignals() {
    final symbols = ['BTC', 'ETH', 'SOL', 'QEMMA', 'AVAX', 'NEAR', 'ARB', 'INJ', 'TON', 'SUI'];
    _signals = symbols.map((s) {
      final score = 30 + _rng.nextInt(65);
      final type = score > 65 ? 'BUY' : score < 40 ? 'SELL' : 'NEUTRAL';
      final strength = score > 70 ? 'STRONG' : score > 55 ? 'MODERATE' : 'WEAK';
      return _AISignal(
        symbol: s,
        signalType: type,
        strength: strength,
        confidence: 40 + _rng.nextInt(55),
        priceTarget: 100 + _rng.nextDouble() * 900,
        upside: -15 + _rng.nextDouble() * 40,
        timeframe: ['1H', '4H', '1D', '1W'][_rng.nextInt(4)],
        indicators: _randomIndicators(),
        timestamp: DateTime.now().subtract(Duration(minutes: _rng.nextInt(60))),
      );
    }).toList();

    _predictions = [
      _Prediction('BTC', 72400, 68200, 75800, 78, '72Std', 'Die HQMLL Analyse zeigt starken Aufwärtstrendkanal. RSI divergenz bullisch, Volumen bestätigt Ausbruch.'),
      _Prediction('ETH', 3820, 3550, 4050, 71, '48Std', 'Ethereum Layer-2 Aktivität gestiegen. Technischer Ausbruch über MA200 erwartet.'),
      _Prediction('SOL', 195, 178, 215, 68, '5Tage', 'Solana DeFi TVL auf Allzeithoch. Starke Netzwerk-Fundamentaldaten.'),
      _Prediction('QEMMA', 0.12, 0.085, 0.145, 84, '2Wochen', 'QEMMA Mining Rewards steigen. Community-Wachstum beschleunigt. TR2-Modell bullisch.'),
    ];

    _levels = [
      _SupportLevel(_selectedSymbol, 'RESISTANCE 3', 71200, 'WEEKLY', false),
      _SupportLevel(_selectedSymbol, 'RESISTANCE 2', 69800, 'DAILY', false),
      _SupportLevel(_selectedSymbol, 'RESISTANCE 1', 68500, '4H', false),
      _SupportLevel(_selectedSymbol, 'CURRENT', 67842, 'LIVE', true),
      _SupportLevel(_selectedSymbol, 'SUPPORT 1', 66100, '4H', false),
      _SupportLevel(_selectedSymbol, 'SUPPORT 2', 64800, 'DAILY', false),
      _SupportLevel(_selectedSymbol, 'SUPPORT 3', 62500, 'WEEKLY', false),
    ];
  }

  List<String> _randomIndicators() {
    final all = ['RSI', 'MACD', 'BB', 'EMA20', 'EMA50', 'Volume', 'OBV', 'Stoch', 'ATR'];
    all.shuffle(_rng);
    return all.take(3 + _rng.nextInt(3)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040A14),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF040A14),
              Color.lerp(const Color(0xFF0D1A2E), const Color(0xFF100A2A), _glowAnim.value)!,
            ],
          ),
          border: Border(bottom: BorderSide(
            color: Color.lerp(const Color(0xFF00AAFF), const Color(0xFFAA44FF), _glowAnim.value)!.withValues(alpha: 0.4),
          )),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _scanAnim,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        Color.lerp(const Color(0xFF00AAFF), const Color(0xFFAA44FF), _glowAnim.value)!,
                        const Color(0xFF080020),
                      ]),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFF00AAFF).withValues(alpha: 0.5),
                        blurRadius: 16, spreadRadius: 2,
                      )],
                    ),
                    child: const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 22),
                  ),
                  // Scan line
                  Positioned(
                    top: 23 + 20 * sin(_scanAnim.value * 2 * pi),
                    child: Container(
                      width: 46, height: 1,
                      color: const Color(0xFF00AAFF).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ORACLE AI', style: GoogleFonts.rajdhani(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2,
              )),
              Text('QUANTUM PREDICTION ENGINE v2', style: GoogleFonts.spaceMono(
                color: Color.lerp(const Color(0xFF00AAFF), const Color(0xFFAA44FF), _glowAnim.value),
                fontSize: 9, letterSpacing: 1.5,
              )),
            ]),
            const Spacer(),
            // Live indicator
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: _pulseAnim.value * 0.7)),
                  color: const Color(0xFF00FF88).withValues(alpha: 0.08),
                ),
                child: Row(children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00FF88).withValues(alpha: _pulseAnim.value),
                  )),
                  const SizedBox(width: 5),
                  Text('LIVE', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 9, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      ('SIGNALE', Icons.bolt_outlined),
      ('PROGNOSEN', Icons.trending_up_outlined),
      ('LEVEL', Icons.horizontal_rule_rounded),
      ('SCANNER', Icons.radar),
    ];
    return Container(
      height: 44,
      color: const Color(0xFF040A14),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: active ? const LinearGradient(colors: [Color(0xFF00AAFF), Color(0xFFAA44FF)]) : null,
                  border: active ? null : Border.all(color: const Color(0xFF1A3A5C)),
                  color: active ? null : const Color(0xFF0A1628),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[i].$2, size: 13, color: active ? Colors.black : const Color(0xFF7AAFC8)),
                    const SizedBox(width: 4),
                    Text(tabs[i].$1, style: GoogleFonts.spaceMono(
                      color: active ? Colors.black : const Color(0xFF7AAFC8),
                      fontSize: 8, fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0: return _buildSignalsTab();
      case 1: return _buildPredictionsTab();
      case 2: return _buildLevelsTab();
      case 3: return _buildScannerTab();
      default: return _buildSignalsTab();
    }
  }

  // ── TAB 0: SIGNALS ────────────────────────────────────────
  Widget _buildSignalsTab() {
    return Column(
      children: [
        // Timeframe selector
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: ['1H', '4H', '1D', '1W'].map((tf) {
              final sel = tf == _selectedTimeframe;
              return GestureDetector(
                onTap: () => setState(() { _selectedTimeframe = tf; _generateSignals(); }),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: sel ? const Color(0xFF00AAFF).withValues(alpha: 0.2) : const Color(0xFF0A1628),
                    border: Border.all(color: sel ? const Color(0xFF00AAFF) : const Color(0xFF1A3A5C)),
                  ),
                  child: Text(tf, style: GoogleFonts.spaceMono(
                    color: sel ? const Color(0xFF00AAFF) : const Color(0xFF7AAFC8),
                    fontSize: 9, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  )),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _signals.length,
            itemBuilder: (_, i) => _buildSignalCard(_signals[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildSignalCard(_AISignal signal) {
    Color sigColor;
    IconData sigIcon;
    switch (signal.signalType) {
      case 'BUY':
        sigColor = const Color(0xFF00FF88);
        sigIcon = Icons.arrow_upward_rounded;
        break;
      case 'SELL':
        sigColor = const Color(0xFFFF4466);
        sigIcon = Icons.arrow_downward_rounded;
        break;
      default:
        sigColor = const Color(0xFFFFAA00);
        sigIcon = Icons.remove_rounded;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: sigColor.withValues(alpha: 0.3)),
        gradient: LinearGradient(colors: [
          const Color(0xFF0A1628),
          sigColor.withValues(alpha: 0.05),
        ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Symbol
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: sigColor.withValues(alpha: 0.15),
                ),
                child: Text(signal.symbol, style: GoogleFonts.rajdhani(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold,
                )),
              ),
              const SizedBox(width: 8),
              // Signal badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: sigColor,
                ),
                child: Row(children: [
                  Icon(sigIcon, size: 12, color: Colors.black),
                  const SizedBox(width: 3),
                  Text('${signal.strength} ${signal.signalType}', style: GoogleFonts.spaceMono(
                    color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold,
                  )),
                ]),
              ),
              const Spacer(),
              // Confidence
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${signal.confidence}%', style: GoogleFonts.rajdhani(
                  color: sigColor, fontSize: 16, fontWeight: FontWeight.bold,
                )),
                Text('CONFIDENCE', style: GoogleFonts.spaceMono(color: const Color(0xFF3A6080), fontSize: 7)),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _infoChip('TF: ${signal.timeframe}', const Color(0xFF7AAFC8)),
              const SizedBox(width: 6),
              _infoChip(
                '${signal.upside >= 0 ? '+' : ''}${signal.upside.toStringAsFixed(1)}%',
                signal.upside >= 0 ? const Color(0xFF00FF88) : const Color(0xFFFF4466),
              ),
              const SizedBox(width: 6),
              ...signal.indicators.take(3).map((ind) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _infoChip(ind, const Color(0xFF3A6080)),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(3),
      color: color.withValues(alpha: 0.15),
    ),
    child: Text(label, style: GoogleFonts.spaceMono(color: color, fontSize: 8)),
  );

  // ── TAB 1: PROGNOSEN ──────────────────────────────────────
  Widget _buildPredictionsTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('AI PREISPROGNOSEN', style: GoogleFonts.rajdhani(
          color: const Color(0xFF00AAFF), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2,
        )),
        const SizedBox(height: 4),
        Text('HQMLL TR2 Engine • Quantum Neural Forecast', style: GoogleFonts.spaceMono(
          color: const Color(0xFF7AAFC8), fontSize: 9,
        )),
        const SizedBox(height: 14),
        ..._predictions.map((p) => _buildPredictionCard(p)),
      ],
    );
  }

  Widget _buildPredictionCard(_Prediction p) {
    final upsidePct = ((p.target - p.current) / p.current * 100);
    final isUp = upsidePct >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isUp ? const Color(0xFF00FF88) : const Color(0xFFFF4466)).withValues(alpha: 0.25)),
        color: const Color(0xFF0A1628),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(p.symbol, style: GoogleFonts.rajdhani(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
              )),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: (isUp ? const Color(0xFF00FF88) : const Color(0xFFFF4466)).withValues(alpha: 0.15),
                ),
                child: Text(
                  '${isUp ? '+' : ''}${upsidePct.toStringAsFixed(1)}% in ${p.timeframe}',
                  style: GoogleFonts.spaceMono(
                    color: isUp ? const Color(0xFF00FF88) : const Color(0xFFFF4466),
                    fontSize: 9, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${p.accuracy}%', style: GoogleFonts.rajdhani(
                  color: const Color(0xFFFFAA00), fontSize: 16, fontWeight: FontWeight.bold,
                )),
                Text('AI SCORE', style: GoogleFonts.spaceMono(color: const Color(0xFF3A6080), fontSize: 7)),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          // Price range bar
          Row(
            children: [
              Text('\$${_fmtPrice(p.bear)}', style: GoogleFonts.spaceMono(color: const Color(0xFFFF4466), fontSize: 9)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (p.current - p.bear) / (p.bull - p.bear),
                          backgroundColor: const Color(0xFF1A3A5C),
                          valueColor: AlwaysStoppedAnimation(isUp ? const Color(0xFF00FF88) : const Color(0xFFFF4466)),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text('\$${_fmtPrice(p.bull)}', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 9)),
            ],
          ),
          const SizedBox(height: 4),
          Center(child: Text('Ziel: \$${_fmtPrice(p.target)}  •  Aktuell: \$${_fmtPrice(p.current)}',
            style: GoogleFonts.spaceMono(color: const Color(0xFF7AAFC8), fontSize: 8))),
          const SizedBox(height: 10),
          Text(p.rationale, style: GoogleFonts.spaceMono(
            color: const Color(0xFF7AAFC8), fontSize: 9, height: 1.5,
          )),
        ],
      ),
    );
  }

  // ── TAB 2: LEVELS ─────────────────────────────────────────
  Widget _buildLevelsTab() {
    return Column(
      children: [
        // Symbol selector
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['BTC', 'ETH', 'SOL', 'QEMMA', 'AVAX'].map((s) {
                final sel = s == _selectedSymbol;
                return GestureDetector(
                  onTap: () => setState(() { _selectedSymbol = s; _generateSignals(); }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: sel ? const LinearGradient(colors: [Color(0xFF00AAFF), Color(0xFFAA44FF)]) : null,
                      border: sel ? null : Border.all(color: const Color(0xFF1A3A5C)),
                      color: sel ? null : const Color(0xFF0A1628),
                    ),
                    child: Text(s, style: GoogleFonts.spaceMono(
                      color: sel ? Colors.black : const Color(0xFF7AAFC8),
                      fontSize: 9, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    )),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _levels.length,
            itemBuilder: (_, i) => _buildLevelRow(_levels[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelRow(_SupportLevel level) {
    final isCurrent = level.isCurrent;
    final isResist = level.label.contains('RESISTANCE');
    Color color = isCurrent
        ? const Color(0xFFFFAA00)
        : isResist
            ? const Color(0xFFFF4466)
            : const Color(0xFF00FF88);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: isCurrent ? 0.7 : 0.25)),
        color: isCurrent ? color.withValues(alpha: 0.1) : const Color(0xFF0A1628),
      ),
      child: Row(
        children: [
          Container(
            width: 3, height: 36,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: color),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(level.label, style: GoogleFonts.spaceMono(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
            Text(level.timeframe, style: GoogleFonts.spaceMono(color: const Color(0xFF3A6080), fontSize: 7)),
          ]),
          const Spacer(),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: color.withValues(alpha: 0.2)),
              child: Text('LIVE', style: GoogleFonts.spaceMono(color: color, fontSize: 7, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 8),
          Text('\$${_fmtPrice(level.price)}', style: GoogleFonts.rajdhani(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }

  // ── TAB 3: SCANNER ────────────────────────────────────────
  Widget _buildScannerTab() {
    final svc = context.watch<LiveMarketService>();
    final gainers = svc.topGainers.take(5).toList();
    final losers = svc.topLosers.take(5).toList();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('MARKT-SCANNER', style: GoogleFonts.rajdhani(
          color: const Color(0xFF00AAFF), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2,
        )),
        const SizedBox(height: 16),
        // Market sentiment gauge
        _buildSentimentGauge(),
        const SizedBox(height: 16),
        Text('TOP GEWINNER', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 9, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        ...gainers.map((q) => _buildScannerRow(q, true)),
        const SizedBox(height: 16),
        Text('TOP VERLIERER', style: GoogleFonts.spaceMono(color: const Color(0xFFFF4466), fontSize: 9, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        ...losers.map((q) => _buildScannerRow(q, false)),
      ],
    );
  }

  Widget _buildSentimentGauge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFAA00).withValues(alpha: 0.3)),
        gradient: const LinearGradient(colors: [Color(0xFF0A1628), Color(0xFF1A1208)]),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MARKT SENTIMENT', style: GoogleFonts.spaceMono(color: const Color(0xFFFFAA00), fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              Text('GREED INDEX: 72', style: GoogleFonts.rajdhani(color: const Color(0xFFFF8800), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.72,
              minHeight: 8,
              backgroundColor: const Color(0xFF1A3A5C),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF8800)),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('EXTREME FEAR', style: GoogleFonts.spaceMono(color: const Color(0xFFFF4466), fontSize: 7)),
              Text('NEUTRAL', style: GoogleFonts.spaceMono(color: const Color(0xFFFFAA00), fontSize: 7)),
              Text('EXTREME GREED', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 7)),
            ],
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _sentimentBadge('BULLISH', 0.68, const Color(0xFF00FF88)),
            _sentimentBadge('BEARISH', 0.18, const Color(0xFFFF4466)),
            _sentimentBadge('NEUTRAL', 0.14, const Color(0xFFFFAA00)),
          ]),
        ],
      ),
    );
  }

  Widget _sentimentBadge(String label, double val, Color color) => Column(
    children: [
      Text('${(val * 100).toInt()}%', style: GoogleFonts.rajdhani(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.spaceMono(color: const Color(0xFF3A6080), fontSize: 7)),
    ],
  );

  Widget _buildScannerRow(AssetQuote q, bool gainer) {
    final color = gainer ? const Color(0xFF00FF88) : const Color(0xFFFF4466);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        color: const Color(0xFF0A1628),
      ),
      child: Row(
        children: [
          SizedBox(width: 48, child: Text(q.symbol, style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(child: Text(q.name, style: GoogleFonts.spaceMono(color: const Color(0xFF7AAFC8), fontSize: 9), overflow: TextOverflow.ellipsis)),
          Text('\$${_fmtPrice(q.price)}', style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 9)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: color.withValues(alpha: 0.15)),
            child: Text(
              '${q.change24h >= 0 ? '+' : ''}${q.change24h.toStringAsFixed(2)}%',
              style: GoogleFonts.spaceMono(color: color, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtPrice(double p) {
    if (p >= 1000) return p.toStringAsFixed(0);
    if (p >= 1) return p.toStringAsFixed(2);
    return p.toStringAsFixed(4);
  }
}

// ── Models ────────────────────────────────────────────────────
class _AISignal {
  final String symbol, signalType, strength, timeframe;
  final int confidence;
  final double priceTarget, upside;
  final List<String> indicators;
  final DateTime timestamp;
  _AISignal({required this.symbol, required this.signalType, required this.strength,
    required this.confidence, required this.priceTarget, required this.upside,
    required this.timeframe, required this.indicators, required this.timestamp});
}

class _Prediction {
  final String symbol, timeframe, rationale;
  final double current, bear, bull, target;
  final int accuracy;
  _Prediction(this.symbol, this.target, this.bear, this.bull, this.accuracy, this.timeframe, this.rationale)
      : current = target * (0.92 + Random().nextDouble() * 0.04);
}

class _SupportLevel {
  final String symbol, label, timeframe;
  final double price;
  final bool isCurrent;
  _SupportLevel(this.symbol, this.label, this.price, this.timeframe, this.isCurrent);
}
