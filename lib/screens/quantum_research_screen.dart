// ============================================================
// QUANTUM DEEP RESEARCH SCREEN v40.0 – HQMLL Quantum Trader
// Quantum Resonanz · Frequenz-Spektrum · Funkwellen · Gravity
// Time Gate Portal · Raum-Zeit-Analyse · Live Market Oracle
// System Log · TX-History · Persistent Research State
// Grigori Saks · 2025
// ============================================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/exchange_service.dart';
import '../services/persistence_service.dart';
import '../theme/app_themes.dart';

// ── Frequenz-Resonanz Datenmodell ─────────────────────────
class FrequencyNode {
  final String id;
  final String label;
  final double frequency;   // Hz
  final double amplitude;   // 0..1
  final double phase;       // radians
  final Color color;
  final String category;    // 'market', 'gravity', 'quantum', 'time'

  const FrequencyNode({
    required this.id,
    required this.label,
    required this.frequency,
    required this.amplitude,
    required this.phase,
    required this.color,
    required this.category,
  });
}

// ── Time Gate Portal ──────────────────────────────────────
class TimePortal {
  final String id;
  final String label;
  final String period;
  final String resonance;
  final double stability;   // 0..1
  final Color gateColor;

  const TimePortal({
    required this.id,
    required this.label,
    required this.period,
    required this.resonance,
    required this.stability,
    required this.gateColor,
  });
}

// ── Gravity Analysis Node ─────────────────────────────────
class GravityField {
  final String symbol;
  final double mass;        // market cap proxy 0..1
  final double velocity;    // price momentum
  final double orbitRadius;
  final Color color;

  const GravityField({
    required this.symbol,
    required this.mass,
    required this.velocity,
    required this.orbitRadius,
    required this.color,
  });
}

// ═══════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════
class QuantumResearchScreen extends StatefulWidget {
  const QuantumResearchScreen({super.key});
  @override
  State<QuantumResearchScreen> createState() => _QuantumResearchScreenState();
}

class _QuantumResearchScreenState extends State<QuantumResearchScreen>
    with TickerProviderStateMixin {

  // Animation controllers
  late AnimationController _waveCtrl;
  late AnimationController _orbitCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _portalCtrl;
  late TabController _tabCtrl;

  // State
  int _selectedFreq = 0;
  int _selectedPortal = 0;
  double _scanProgress = 0.0;
  bool _deepScanActive = false;
  bool _gravityFieldActive = true;
  Timer? _scanTimer;
  Timer? _autoSaveTimer;
  final List<String> _researchLog = [];
  int _quantumScore = 0;
  bool _logLoaded = false;
  final ScrollController _sysLogScrollCtrl = ScrollController();
  String _txFilter = 'ALL';
  String _sysFilter = 'ALL';

  // Frequency nodes — market resonance spectrum
  static const List<FrequencyNode> _freqNodes = [
    FrequencyNode(id: 'F1', label: 'BTC Resonanz', frequency: 1.618, amplitude: 0.95, phase: 0.0, color: Color(0xFFF7931A), category: 'market'),
    FrequencyNode(id: 'F2', label: 'ETH Welle', frequency: 2.718, amplitude: 0.87, phase: 0.5, color: Color(0xFF627EEA), category: 'market'),
    FrequencyNode(id: 'F3', label: 'SOL Frequenz', frequency: 3.141, amplitude: 0.79, phase: 1.0, color: Color(0xFF9945FF), category: 'market'),
    FrequencyNode(id: 'F4', label: 'Quanten-Feld', frequency: 4.321, amplitude: 0.92, phase: 1.5, color: Color(0xFF00F0FF), category: 'quantum'),
    FrequencyNode(id: 'F5', label: 'Schwerkraft α', frequency: 9.81, amplitude: 0.68, phase: 2.0, color: Color(0xFF00FF88), category: 'gravity'),
    FrequencyNode(id: 'F6', label: 'Zeit-Welle τ', frequency: 0.707, amplitude: 0.83, phase: 2.5, color: Color(0xFFFF6B35), category: 'time'),
    FrequencyNode(id: 'F7', label: 'Gamma-Strahlung', frequency: 7.777, amplitude: 0.61, phase: 3.0, color: Color(0xFFFF00FF), category: 'quantum'),
    FrequencyNode(id: 'F8', label: 'Markt-Entropie', frequency: 1.414, amplitude: 0.74, phase: 3.5, color: Color(0xFFFFF200), category: 'market'),
  ];

  // Time Gate Portals
  static const List<TimePortal> _portals = [
    TimePortal(id: 'T1', label: 'ZEITTOR ALPHA', period: '4H', resonance: 'φ=1.618', stability: 0.92, gateColor: Color(0xFF00F0FF)),
    TimePortal(id: 'T2', label: 'ZEITTOR BETA',  period: '1D', resonance: 'π=3.141', stability: 0.87, gateColor: Color(0xFF9945FF)),
    TimePortal(id: 'T3', label: 'ZEITTOR GAMMA', period: '1W', resonance: 'e=2.718', stability: 0.78, gateColor: Color(0xFFF7931A)),
    TimePortal(id: 'T4', label: 'OMEGA-TOR',     period: '1M', resonance: 'Ω=∞',    stability: 0.63, gateColor: Color(0xFFFF6B35)),
  ];

  // Gravity fields
  static const List<GravityField> _gravFields = [
    GravityField(symbol: 'BTC', mass: 1.0,  velocity: 0.8, orbitRadius: 0.25, color: Color(0xFFF7931A)),
    GravityField(symbol: 'ETH', mass: 0.6,  velocity: 0.9, orbitRadius: 0.40, color: Color(0xFF627EEA)),
    GravityField(symbol: 'SOL', mass: 0.25, velocity: 1.2, orbitRadius: 0.55, color: Color(0xFF9945FF)),
    GravityField(symbol: 'BNB', mass: 0.20, velocity: 0.7, orbitRadius: 0.65, color: Color(0xFFF3BA2F)),
    GravityField(symbol: 'XRP', mass: 0.18, velocity: 0.6, orbitRadius: 0.75, color: Color(0xFF00AAE4)),
    GravityField(symbol: 'ADA', mass: 0.12, velocity: 0.5, orbitRadius: 0.85, color: Color(0xFF0033AD)),
  ];

  @override
  void initState() {
    super.initState();
    _waveCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _scanCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _portalCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _tabCtrl = TabController(length: 6, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ex = context.read<ExchangeService>();
      final ps = context.read<PersistenceService>();
      await ex.initialize();
      if (mounted) {
        final saved = ps.researchLogs;
        final savedScore = ps.quantumScore;
        setState(() {
          if (saved.isNotEmpty) {
            _researchLog.addAll(saved);
            _quantumScore = savedScore;
          } else {
            _quantumScore = 847 + (ex.getPrice('BTC') > 0 ? 100 : 0);
          }
          _researchLog.add('[BOOT] Quantum Research Engine v40.0 gestartet');
          _researchLog.add('[INIT] Frequenz-Matrix geladen — 8 Resonanz-Knoten aktiv');
          _researchLog.add('[SCAN] Raum-Zeit-Gitter stabilisiert');
          _researchLog.add('[LIVE] Marktdaten-Synchronisation aktiv');
          _logLoaded = true;
        });
        await ps.saveResearchLog(_researchLog, _quantumScore);
        ps.addSystemLog('RESONANZ',
            'QuantumResearchScreen v40 initialisiert — Score: \$_quantumScore',
            level: SysLogLevel.success);
        _autoSaveTimer = Timer.periodic(const Duration(seconds: 90), (_) {
          if (!mounted) return;
          ps.saveResearchLog(_researchLog, _quantumScore);
        });
      }
    });
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _orbitCtrl.dispose();
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    _portalCtrl.dispose();
    _tabCtrl.dispose();
    _scanTimer?.cancel();
    _autoSaveTimer?.cancel();
    _sysLogScrollCtrl.dispose();
    super.dispose();
  }

  void _startDeepScan() {
    if (_deepScanActive) return;
    final ps = context.read<PersistenceService>();
    setState(() {
      _deepScanActive = true;
      _scanProgress = 0.0;
      _researchLog.add('[DEEP SCAN] Initiiere Quanten-Tiefenscan...');
    });
    ps.addSystemLog('FREQUENZ', 'Deep-Scan gestartet', level: SysLogLevel.info);
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _scanProgress += 0.015;
        if (_scanProgress >= 1.0) {
          _scanProgress = 1.0;
          _deepScanActive = false;
          _quantumScore += 37;
          _researchLog.add('[DEEP SCAN] ✓ Analyse abgeschlossen — Score: +37 pts');
          _researchLog.add('[RESULT] Quanten-Kohärenz: ${(87 + _quantumScore % 10).clamp(0, 100)}%');
          t.cancel();
          ps.saveResearchLog(_researchLog, _quantumScore);
          ps.addSystemLog('RESONANZ', 'Deep-Scan abgeschlossen — Score: $_quantumScore',
              level: SysLogLevel.success);
        }
      });
    });
  }

  void _addLog(String entry, {int scoreIncrement = 0, String sysCategory = 'SYSTEM'}) {
    if (!mounted) return;
    final ps = context.read<PersistenceService>();
    setState(() {
      _researchLog.add(entry);
      if (scoreIncrement > 0) _quantumScore += scoreIncrement;
    });
    ps.addResearchLogEntry(entry, newScore: scoreIncrement > 0 ? _quantumScore : null);
    ps.addSystemLog(sysCategory, entry);
  }

  // ── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    final ex = context.watch<ExchangeService>();
    final ps = context.watch<PersistenceService>();

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(p, ex),
            _buildQuantumBar(p),
            TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: p.primary,
              indicatorWeight: 2,
              labelStyle: GoogleFonts.orbitron(fontSize: 8, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.orbitron(fontSize: 7),
              labelColor: p.primary,
              unselectedLabelColor: p.textSecondary,
              tabs: const [
                Tab(text: 'FREQUENZ'),
                Tab(text: 'GRAVITATION'),
                Tab(text: 'TIME GATE'),
                Tab(text: 'DEEP LOG'),
                Tab(text: 'SYSTEM LOG'),
                Tab(text: 'TX HISTORY'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildFrequencyTab(p, ex),
                  _buildGravityTab(p, ex),
                  _buildTimeGateTab(p, ex),
                  _buildDeepLogTab(p, ps),
                  _buildSystemLogTab(p, ps),
                  _buildTxHistoryTab(p, ex),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────
  Widget _buildHeader(QuantumPalette p, ExchangeService ex) {
    final btc = ex.getPrice('BTC');
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              p.background,
              const Color(0xFF00F0FF).withValues(alpha: 0.04 + _pulseCtrl.value * 0.03),
              p.background,
            ],
          ),
          border: Border(bottom: BorderSide(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.2 + _pulseCtrl.value * 0.15),
          )),
        ),
        child: Row(
          children: [
            // Quantum Eye orb
            AnimatedBuilder(
              animation: _orbitCtrl,
              builder: (_, __) => Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFF00F0FF).withValues(alpha: 0.5 + _pulseCtrl.value * 0.3),
                    const Color(0xFF9945FF).withValues(alpha: 0.2),
                    Colors.transparent,
                  ]),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.4 + _pulseCtrl.value * 0.2),
                      blurRadius: 14 + _pulseCtrl.value * 8,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(44, 44),
                      painter: _QuantumOrbPainter(_orbitCtrl.value, const Color(0xFF00F0FF)),
                    ),
                    const Icon(Icons.radar, color: Color(0xFF00F0FF), size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('QUANTUM DEEP RESEARCH',
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFF00F0FF),
                      fontSize: 13, fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: const Color(0xFF00F0FF).withValues(alpha: 0.6), blurRadius: 8)],
                    )),
                Row(children: [
                  _liveChip('RESONANZ', 'AKTIV', const Color(0xFF00FF88)),
                  const SizedBox(width: 6),
                  _liveChip('BTC', btc > 0 ? '\$${(btc / 1000).toStringAsFixed(1)}K' : '…', const Color(0xFFF7931A)),
                ]),
              ]),
            ),
            // Deep Scan button
            GestureDetector(
              onTap: _startDeepScan,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(colors: [
                      const Color(0xFF00F0FF).withValues(alpha: 0.15 + _pulseCtrl.value * 0.1),
                      const Color(0xFF9945FF).withValues(alpha: 0.1),
                    ]),
                    border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                    boxShadow: _deepScanActive ? [BoxShadow(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                      blurRadius: 8,
                    )] : [],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      _deepScanActive ? Icons.radar : Icons.search,
                      color: const Color(0xFF00F0FF), size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _deepScanActive ? 'SCAN...' : 'TIEFEN-\nSCAN',
                      style: GoogleFonts.orbitron(
                        color: const Color(0xFF00F0FF), fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveChip(String label, String value, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withValues(alpha: 0.35)),
        color: c.withValues(alpha: 0.08),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
        const SizedBox(width: 3),
        Text('$label: $value', style: GoogleFonts.spaceMono(color: c, fontSize: 8)),
      ]),
    );
  }

  // ── Quantum Score Bar ────────────────────────────────────
  Widget _buildQuantumBar(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.2),
        border: Border(bottom: BorderSide(color: p.primary.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          _buildQuantumStat('Q-SCORE', '$_quantumScore', const Color(0xFF00F0FF)),
          const SizedBox(width: 14),
          _buildQuantumStat('KOHÄRENZ', '${(87 + _quantumScore % 10).clamp(0, 99)}%', const Color(0xFF00FF88)),
          const SizedBox(width: 14),
          _buildQuantumStat('KNOTEN', '${_freqNodes.length}', const Color(0xFF9945FF)),
          const SizedBox(width: 14),
          _buildQuantumStat('PORTALE', '${_portals.length}', const Color(0xFFF7931A)),
          if (_deepScanActive) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TIEFEN-SCAN', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF), fontSize: 7)),
                const SizedBox(height: 3),
                LinearProgressIndicator(
                  value: _scanProgress,
                  backgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                  minHeight: 3,
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantumStat(String label, String value, Color c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: GoogleFonts.orbitron(color: c, fontSize: 11, fontWeight: FontWeight.bold,
          shadows: [Shadow(color: c.withValues(alpha: 0.5), blurRadius: 4)])),
      Text(label, style: GoogleFonts.rajdhani(color: c.withValues(alpha: 0.6), fontSize: 8)),
    ]);
  }

  // ═══════════════════════════════════════════════════════
  // TAB 1 — FREQUENZ-SPEKTRUM
  // ═══════════════════════════════════════════════════════
  Widget _buildFrequencyTab(QuantumPalette p, ExchangeService ex) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Spectrum Visualizer
          _buildSpectrumTitle(p, 'FREQUENZ-SPEKTRUM ANALYSE', Icons.graphic_eq),
          const SizedBox(height: 10),
          _buildSpectrumVisualizer(p),
          const SizedBox(height: 16),

          // Frequency Nodes Grid
          _buildSpectrumTitle(p, 'RESONANZ-KNOTEN', Icons.hub_outlined),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.4,
            ),
            itemCount: _freqNodes.length,
            itemBuilder: (_, i) => _buildFreqNodeCard(_freqNodes[i], i == _selectedFreq, p),
          ),
          const SizedBox(height: 16),

          // Waveform detail for selected node
          _buildSpectrumTitle(p, 'WELLEN-DETAIL: ${_freqNodes[_selectedFreq].label.toUpperCase()}', Icons.waves),
          const SizedBox(height: 8),
          _buildWaveformDetail(p, _freqNodes[_selectedFreq], ex),
          const SizedBox(height: 16),

          // Market correlations
          _buildSpectrumTitle(p, 'MARKT-KORRELATIONEN', Icons.compare_arrows),
          const SizedBox(height: 8),
          _buildCorrelationMatrix(p, ex),
        ],
      ),
    );
  }

  Widget _buildSpectrumTitle(QuantumPalette p, String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: const Color(0xFF00F0FF), size: 14),
      const SizedBox(width: 6),
      Text(title, style: GoogleFonts.orbitron(
        color: const Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.bold,
      )),
    ]);
  }

  Widget _buildSpectrumVisualizer(QuantumPalette p) {
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (_, __) => Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: p.surface.withValues(alpha: 0.3),
          border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: _SpectrumPainter(
              time: _waveCtrl.value,
              nodes: _freqNodes,
              selectedIdx: _selectedFreq,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFreqNodeCard(FrequencyNode node, bool selected, QuantumPalette p) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFreq = _freqNodes.indexOf(node)),
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(colors: [
              node.color.withValues(alpha: selected ? 0.18 : 0.07),
              node.color.withValues(alpha: selected ? 0.08 : 0.02),
            ]),
            border: Border.all(
              color: node.color.withValues(alpha: selected ? 0.6 + _pulseCtrl.value * 0.2 : 0.2),
              width: selected ? 1.5 : 1.0,
            ),
            boxShadow: selected ? [BoxShadow(
              color: node.color.withValues(alpha: 0.2 + _pulseCtrl.value * 0.15),
              blurRadius: 8,
            )] : [],
          ),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: node.color.withValues(alpha: 0.15),
                border: Border.all(color: node.color.withValues(alpha: 0.4)),
              ),
              child: Icon(_categoryIcon(node.category), color: node.color, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(node.label, style: GoogleFonts.rajdhani(
                color: node.color, fontSize: 9, fontWeight: FontWeight.bold,
              ), overflow: TextOverflow.ellipsis),
              Text('${node.frequency.toStringAsFixed(3)} Hz  A:${(node.amplitude * 100).toInt()}%',
                  style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7)),
            ])),
          ]),
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'market': return Icons.candlestick_chart;
      case 'quantum': return Icons.blur_circular;
      case 'gravity': return Icons.public;
      case 'time': return Icons.schedule;
      default: return Icons.radio_button_on;
    }
  }

  Widget _buildWaveformDetail(QuantumPalette p, FrequencyNode node, ExchangeService ex) {
    final price = ex.getPrice(node.label.contains('BTC') ? 'BTC' : node.label.contains('ETH') ? 'ETH' : node.label.contains('SOL') ? 'SOL' : 'BTC');
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: node.color.withValues(alpha: 0.06),
          border: Border.all(color: node.color.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 70,
                child: CustomPaint(
                  painter: _WaveformPainter(
                    time: _waveCtrl.value,
                    freq: node.frequency,
                    amp: node.amplitude,
                    phase: node.phase,
                    color: node.color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _waveStatRow('FREQ', '${node.frequency.toStringAsFixed(3)} Hz', node.color),
              _waveStatRow('AMP',  '${(node.amplitude * 100).toInt()}%', node.color),
              _waveStatRow('PHASE', '${(node.phase * 180 / pi).toStringAsFixed(0)}°', node.color),
              if (price > 0)
                _waveStatRow('PREIS', '\$${price.toStringAsFixed(0)}', node.color),
            ]),
          ]),
          const SizedBox(height: 8),
          Text(
            _getFreqInsight(node, price),
            style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9),
          ),
        ]),
      ),
    );
  }

  Widget _waveStatRow(String label, String value, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$label: ', style: GoogleFonts.spaceMono(color: c.withValues(alpha: 0.6), fontSize: 8)),
        Text(value, style: GoogleFonts.spaceMono(color: c, fontSize: 8, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  String _getFreqInsight(FrequencyNode node, double price) {
    switch (node.category) {
      case 'market':
        return price > 0
            ? '${node.label} resoniert mit Live-Preis \$${price.toStringAsFixed(0)} — Quanten-Kohärenz erkannt'
            : '${node.label} — Warte auf Marktdaten-Synchronisation';
      case 'quantum':
        return 'Quanten-Feld-Interferenz bei ${node.frequency.toStringAsFixed(3)} Hz — Superposition aktiv';
      case 'gravity':
        return 'Schwerkraft-Vektor α: ${node.frequency} m/s² — Marktmasse-Attraktion kalkuliert';
      case 'time':
        return 'Zeit-Dilatations-Koeffizient τ = ${node.frequency.toStringAsFixed(3)} — Raum-Zeit-Krümmung analysiert';
      default:
        return 'Analyse läuft...';
    }
  }

  Widget _buildCorrelationMatrix(QuantumPalette p, ExchangeService ex) {
    final pairs = [
      ('BTC', 'ETH', 0.87), ('BTC', 'SOL', 0.79), ('ETH', 'SOL', 0.82),
      ('BTC', 'BNB', 0.72), ('ETH', 'LINK', 0.68), ('SOL', 'AVAX', 0.74),
    ];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: p.surface.withValues(alpha: 0.2),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: pairs.asMap().entries.map((e) {
          final (sym1, sym2, corr) = e.value;
          final isPos = corr >= 0.7;
          final c = isPos ? const Color(0xFF00FF88) : const Color(0xFFFF6B35);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(children: [
              SizedBox(width: 38, child: Text(sym1,
                  style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 9, fontWeight: FontWeight.bold))),
              const SizedBox(width: 4),
              Icon(Icons.compare_arrows, color: p.textSecondary, size: 12),
              const SizedBox(width: 4),
              SizedBox(width: 38, child: Text(sym2,
                  style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 9, fontWeight: FontWeight.bold))),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: corr.toDouble(),
                    minHeight: 5,
                    backgroundColor: c.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(c.withValues(alpha: 0.7)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(corr * 100).toInt()}%',
                  style: GoogleFonts.spaceMono(color: c, fontSize: 9, fontWeight: FontWeight.bold)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 2 — GRAVITY / ORBITAL ANALYSE
  // ═══════════════════════════════════════════════════════
  Widget _buildGravityTab(QuantumPalette p, ExchangeService ex) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpectrumTitle(p, 'GRAVITATIONSFELD-ANALYSE', Icons.public),
          const SizedBox(height: 10),
          // Gravity orbital view
          Container(
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: p.surface.withValues(alpha: 0.2),
              border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.15)),
            ),
            child: AnimatedBuilder(
              animation: _orbitCtrl,
              builder: (_, __) => ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  painter: _GravityOrbitalPainter(
                    time: _orbitCtrl.value,
                    fields: _gravFields,
                    prices: {
                      for (final f in _gravFields) f.symbol: ex.getPrice(f.symbol),
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildSpectrumTitle(p, 'MARKT-MASSEN TABELLE', Icons.table_chart_outlined),
          const SizedBox(height: 8),

          // Gravity fields table
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: p.surface.withValues(alpha: 0.2),
              border: Border.all(color: p.primary.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                _gravTableHeader(p),
                ..._gravFields.map((f) => _buildGravFieldRow(f, p, ex)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildSpectrumTitle(p, 'SCHWARZES-LOCH INDIKATOR', Icons.blur_on),
          const SizedBox(height: 8),
          _buildBlackHoleIndicator(p, ex),
        ],
      ),
    );
  }

  Widget _gravTableHeader(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: p.primary.withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(color: p.primary.withValues(alpha: 0.15))),
      ),
      child: Row(children: [
        SizedBox(width: 42, child: Text('ASSET', style: GoogleFonts.orbitron(color: p.textSecondary, fontSize: 7))),
        Expanded(child: Text('MASSE', style: GoogleFonts.orbitron(color: p.textSecondary, fontSize: 7))),
        SizedBox(width: 55, child: Text('PREIS', style: GoogleFonts.orbitron(color: p.textSecondary, fontSize: 7))),
        SizedBox(width: 55, child: Text('ORBIT R', style: GoogleFonts.orbitron(color: p.textSecondary, fontSize: 7))),
      ]),
    );
  }

  Widget _buildGravFieldRow(GravityField f, QuantumPalette p, ExchangeService ex) {
    final price = ex.getPrice(f.symbol);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        SizedBox(width: 42, child: Text(f.symbol,
            style: GoogleFonts.spaceMono(color: f.color, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: f.mass,
                minHeight: 6,
                backgroundColor: f.color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(f.color.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(width: 6),
            Text('${(f.mass * 100).toInt()}', style: GoogleFonts.spaceMono(color: f.color, fontSize: 8)),
          ]),
        ),
        SizedBox(width: 55, child: Text(
          price > 0 ? '\$${_formatPrice(price)}' : '…',
          style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 8),
        )),
        SizedBox(width: 55, child: Text(
          '${(f.orbitRadius * 100).toInt()} AU',
          style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8),
        )),
      ]),
    );
  }

  String _formatPrice(double p) {
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(1)}K';
    if (p >= 1)   return p.toStringAsFixed(2);
    return p.toStringAsFixed(4);
  }

  Widget _buildBlackHoleIndicator(QuantumPalette p, ExchangeService ex) {
    final btc = ex.getPrice('BTC');
    final eth = ex.getPrice('ETH');
    final domBtc = btc > 0 && eth > 0 ? (btc / (btc + eth * 15) * 100) : 62.0;
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: RadialGradient(
            colors: [
              const Color(0xFF1A0030).withValues(alpha: 0.9),
              const Color(0xFF000510).withValues(alpha: 0.5),
            ],
          ),
          border: Border.all(color: const Color(0xFF9945FF).withValues(alpha: 0.3 + _pulseCtrl.value * 0.2)),
        ),
        child: Row(children: [
          AnimatedBuilder(
            animation: _orbitCtrl,
            builder: (_, __) => Container(
              width: 56, height: 56,
              child: CustomPaint(
                painter: _BlackHolePainter(_orbitCtrl.value, _pulseCtrl.value),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BITCOIN DOMINANZ', style: GoogleFonts.orbitron(color: const Color(0xFF9945FF), fontSize: 9, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${domBtc.toStringAsFixed(1)}% der Marktmasse',
                style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 10)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: domBtc / 100.0,
                minHeight: 8,
                backgroundColor: const Color(0xFF9945FF).withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF9945FF).withValues(alpha: 0.8 + _pulseCtrl.value * 0.2),
                ),
              ),
            ),
          ])),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 3 — TIME GATE PORTAL
  // ═══════════════════════════════════════════════════════
  Widget _buildTimeGateTab(QuantumPalette p, ExchangeService ex) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpectrumTitle(p, 'TIME GATE PORTAL — RAUM-ZEIT ANALYSE', Icons.schedule),
          const SizedBox(height: 12),

          // Main portal visualization
          AnimatedBuilder(
            animation: _portalCtrl,
            builder: (_, __) => Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withValues(alpha: 0.4),
                border: Border.all(color: _portals[_selectedPortal].gateColor.withValues(alpha: 0.35)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  painter: _TimeGatePainter(
                    time: _portalCtrl.value,
                    gateColor: _portals[_selectedPortal].gateColor,
                    stability: _portals[_selectedPortal].stability,
                    pulseVal: _pulseCtrl.value,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Portal selector
          Row(
            children: _portals.asMap().entries.map((e) {
              final idx = e.key;
              final portal = e.value;
              final sel = idx == _selectedPortal;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedPortal = idx);
                    _addLog('[PORTAL] ${portal.label} aktiviert — ${portal.period} Fenster',
                        sysCategory: 'GRAVITY');
                  },
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      margin: EdgeInsets.only(right: idx < _portals.length - 1 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(colors: [
                          portal.gateColor.withValues(alpha: sel ? 0.2 : 0.05),
                          portal.gateColor.withValues(alpha: sel ? 0.08 : 0.02),
                        ]),
                        border: Border.all(
                          color: portal.gateColor.withValues(alpha: sel ? 0.7 : 0.25),
                          width: sel ? 1.5 : 1.0,
                        ),
                        boxShadow: sel ? [BoxShadow(
                          color: portal.gateColor.withValues(alpha: 0.2 + _pulseCtrl.value * 0.15),
                          blurRadius: 8,
                        )] : [],
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(portal.period, style: GoogleFonts.orbitron(
                          color: portal.gateColor, fontSize: 11, fontWeight: FontWeight.bold,
                        )),
                        Text(portal.resonance, style: GoogleFonts.spaceMono(
                          color: portal.gateColor.withValues(alpha: 0.7), fontSize: 7,
                        )),
                        Text('${(portal.stability * 100).toInt()}% stabil',
                            style: GoogleFonts.rajdhani(color: portal.gateColor.withValues(alpha: 0.6), fontSize: 8)),
                      ]),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Portal detail info
          _buildPortalDetail(p, _portals[_selectedPortal], ex),
          const SizedBox(height: 16),

          // Raum-Zeit Messungen
          _buildSpectrumTitle(p, 'RAUM-ZEIT MESSUNGEN', Icons.science_outlined),
          const SizedBox(height: 8),
          _buildSpacetimeMeasurements(p, ex),
        ],
      ),
    );
  }

  Widget _buildPortalDetail(QuantumPalette p, TimePortal portal, ExchangeService ex) {
    final btc = ex.getPrice('BTC');
    final c = portal.gateColor;
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              c.withValues(alpha: 0.08),
              c.withValues(alpha: 0.03),
            ],
          ),
          border: Border.all(color: c.withValues(alpha: 0.25 + _pulseCtrl.value * 0.1)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.access_time_filled, color: c, size: 16),
            const SizedBox(width: 8),
            Text(portal.label, style: GoogleFonts.orbitron(
              color: c, fontSize: 11, fontWeight: FontWeight.bold,
              shadows: [Shadow(color: c.withValues(alpha: 0.4), blurRadius: 6)],
            )),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: c.withValues(alpha: 0.12),
                border: Border.all(color: c.withValues(alpha: 0.35)),
              ),
              child: Text('${portal.period} FENSTER',
                  style: GoogleFonts.orbitron(color: c, fontSize: 8)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _portalStat('RESONANZ', portal.resonance, c)),
            Expanded(child: _portalStat('STABILITÄT', '${(portal.stability * 100).toInt()}%', c)),
            Expanded(child: _portalStat('BTC REFERENZ', btc > 0 ? '\$${(btc / 1000).toStringAsFixed(1)}K' : '…', c)),
          ]),
          const SizedBox(height: 10),
          Text(
            _getPortalInsight(portal, btc),
            style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9, height: 1.5),
          ),
        ]),
      ),
    );
  }

  Widget _portalStat(String label, String value, Color c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.rajdhani(color: c.withValues(alpha: 0.6), fontSize: 8)),
      Text(value, style: GoogleFonts.orbitron(color: c, fontSize: 9, fontWeight: FontWeight.bold)),
    ]);
  }

  String _getPortalInsight(TimePortal portal, double btcPrice) {
    final priceStr = btcPrice > 0 ? '\$${(btcPrice / 1000).toStringAsFixed(1)}K' : '[lädt...]';
    switch (portal.id) {
      case 'T1': return 'Alpha-Zeittor: Kurzfristige 4H-Resonanz aktiv. BTC $priceStr zeigt φ=1.618 Fibonacci-Konvergenz. Quanten-Wahrscheinlichkeit für Aufwärtsbewegung: ${(portal.stability * 100).toInt()}%.';
      case 'T2': return 'Beta-Zeittor: Tages-Zyklus synchronisiert. Raum-Zeit-Krümmung im ${(portal.stability * 100).toInt()}% Stabilitätskorridor. Marktenergie akkumuliert sich bei $priceStr.';
      case 'T3': return 'Gamma-Zeittor: Wöchentliche Resonanzwelle detektiert. Euler-Zahl e=2.718 Konvergenzpunkt überschritten. Mittelfristiger Trend: Quanten-Aufwärtsbias.';
      case 'T4': return 'Omega-Tor: Langfristiger Raum-Zeit-Tunnel aktiv. Grenzkorridor erreicht — Vorsicht geboten. Quantenfeld-Instabilität bei ${((1 - portal.stability) * 100).toInt()}% Divergenz.';
      default: return 'Analyse läuft...';
    }
  }

  Widget _buildSpacetimeMeasurements(QuantumPalette p, ExchangeService ex) {
    final btc = ex.getPrice('BTC');
    final eth = ex.getPrice('ETH');
    final measurements = [
      ('Schwerkraft-Konstante G', 'BTC/ETH Verhältnis', btc > 0 && eth > 0 ? '${(btc / eth).toStringAsFixed(2)}' : '…', const Color(0xFF00F0FF)),
      ('Lichtgeschwindigk. c', 'Tick-Geschwindigkeit', '${ex.ticks.length} tps', const Color(0xFF00FF88)),
      ('Planck-Konstante h', 'Min. Quantum-Einheit', '0.000001 BTC', const Color(0xFF9945FF)),
      ('Zeit-Dilatation τ', 'Markt-Zeitkrümmung', _portals[_selectedPortal].resonance, const Color(0xFFF7931A)),
      ('Entropie S', 'Markt-Unordnung', '${(72 + (DateTime.now().second % 15))}%', const Color(0xFFFF6B35)),
    ];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: p.surface.withValues(alpha: 0.2),
        border: Border.all(color: p.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: measurements.asMap().entries.map((e) {
          final idx = e.key;
          final (name, desc, value, c) = e.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: idx < measurements.length - 1
                ? BoxDecoration(border: Border(bottom: BorderSide(color: p.primary.withValues(alpha: 0.07))))
                : null,
            child: Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: GoogleFonts.orbitron(color: c, fontSize: 8, fontWeight: FontWeight.bold)),
                Text(desc, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
              ])),
              Text(value, style: GoogleFonts.spaceMono(color: c, fontSize: 9, fontWeight: FontWeight.bold)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 4 — DEEP LOG (Research Log — persistent)
  // ═══════════════════════════════════════════════════════
  Widget _buildDeepLogTab(QuantumPalette p, PersistenceService ps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            _buildSpectrumTitle(p, 'QUANTUM RESEARCH LOG', Icons.terminal),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                await ps.clearResearchLog();
                setState(() {
                  _researchLog.clear();
                  _quantumScore = 847;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFF3355).withValues(alpha: 0.4)),
                  color: const Color(0xFFFF3355).withValues(alpha: 0.06),
                ),
                child: Text('CLR', style: GoogleFonts.orbitron(color: const Color(0xFFFF3355), fontSize: 8)),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _addLog(
                '[USER] Manuelle Log-Einheit: ${DateTime.now().toIso8601String().substring(11, 19)}',
                scoreIncrement: 5,
                sysCategory: 'SYSTEM',
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.06),
                ),
                child: Text('+ LOG', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF), fontSize: 8)),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 4, height: 4, decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF00FF88))),
                const SizedBox(width: 4),
                Text('AUTO-SAVE AKTIV', style: GoogleFonts.orbitron(
                    color: const Color(0xFF00FF88), fontSize: 7)),
              ]),
            ),
            const SizedBox(width: 8),
            Text('${_researchLog.length} Eintraege',
                style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
          ]),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.3),
              border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.15)),
            ),
            child: _researchLog.isEmpty
                ? Center(child: Text('Log leer — starte Deep Scan', style: GoogleFonts.spaceMono(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.4), fontSize: 10)))
                : ListView.builder(
                    itemCount: _researchLog.length,
                    reverse: true,
                    itemBuilder: (_, i) {
                      final entry = _researchLog[_researchLog.length - 1 - i];
                      final isError = entry.contains('[ERROR]');
                      final isResult = entry.contains('[RESULT]') || entry.contains('✓');
                      final isUser = entry.contains('[USER]');
                      final c = isError
                          ? const Color(0xFFFF3355)
                          : isResult
                              ? const Color(0xFF00FF88)
                              : isUser
                                  ? const Color(0xFFF7931A)
                                  : const Color(0xFF00F0FF);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('> ', style: GoogleFonts.spaceMono(color: c.withValues(alpha: 0.5), fontSize: 9)),
                          Expanded(child: Text(entry,
                              style: GoogleFonts.spaceMono(color: c.withValues(alpha: 0.85), fontSize: 9, height: 1.4))),
                        ]),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 5 — SYSTEM LOG (zentrale persistente Protokollierung)
  // ═══════════════════════════════════════════════════════
  Widget _buildSystemLogTab(QuantumPalette p, PersistenceService ps) {
    final logs = ps.systemLogs.toList().reversed.toList();
    final filtered = _sysFilter == 'ALL'
        ? logs
        : logs.where((l) => l.category == _sysFilter).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            _buildSpectrumTitle(p, 'SYSTEM LOG', Icons.monitor_heart),
            const Spacer(),
            Text('${logs.length}', style: GoogleFonts.orbitron(
                color: const Color(0xFF9945FF), fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async => await ps.clearSystemLogs(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFF3355).withValues(alpha: 0.4)),
                  color: const Color(0xFFFF3355).withValues(alpha: 0.06),
                ),
                child: Text('CLR', style: GoogleFonts.orbitron(color: const Color(0xFFFF3355), fontSize: 8)),
              ),
            ),
          ]),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Row(
            children: ['ALL', 'RESONANZ', 'FREQUENZ', 'GRAVITY', 'TX', 'WS', 'AI', 'SYSTEM', 'BANK']
                .map((cat) {
              final isActive = _sysFilter == cat;
              const c = Color(0xFF9945FF);
              return GestureDetector(
                onTap: () => setState(() => _sysFilter = cat),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: c.withValues(alpha: isActive ? 0.2 : 0.05),
                    border: Border.all(color: c.withValues(alpha: isActive ? 0.7 : 0.2)),
                  ),
                  child: Text(cat, style: GoogleFonts.orbitron(
                      color: isActive ? c : p.textSecondary, fontSize: 7,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('Keine System-Events', style: GoogleFonts.spaceMono(
                  color: const Color(0xFF9945FF).withValues(alpha: 0.4), fontSize: 10)))
              : ListView.builder(
                  controller: _sysLogScrollCtrl,
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _buildSysLogEntry(p, filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildSysLogEntry(QuantumPalette p, SystemLogEntry entry) {
    Color c;
    switch (entry.level) {
      case SysLogLevel.success: c = const Color(0xFF00FF88); break;
      case SysLogLevel.warning: c = const Color(0xFFF7931A); break;
      case SysLogLevel.error:   c = const Color(0xFFFF3355); break;
      case SysLogLevel.quantum: c = const Color(0xFF9945FF); break;
      default:                  c = const Color(0xFF00F0FF);
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: c.withValues(alpha: 0.04),
        border: Border.all(color: c.withValues(alpha: 0.15)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: c.withValues(alpha: 0.12),
          ),
          child: Text(entry.category,
              style: GoogleFonts.orbitron(color: c, fontSize: 6, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.message,
                style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 10, height: 1.3)),
            const SizedBox(height: 2),
            Row(children: [
              Text(entry.prefix, style: GoogleFonts.spaceMono(color: c, fontSize: 8)),
              const SizedBox(width: 4),
              Text(
                '${entry.timestamp.hour.toString().padLeft(2,'0')}:'
                '${entry.timestamp.minute.toString().padLeft(2,'0')}:'
                '${entry.timestamp.second.toString().padLeft(2,'0')}'
                ' · ${entry.timestamp.day}.${entry.timestamp.month}.${entry.timestamp.year}',
                style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 6 — TX HISTORY (vollstaendige Transaktions-Historie)
  // ═══════════════════════════════════════════════════════
  Widget _buildTxHistoryTab(QuantumPalette p, ExchangeService ex) {
    final allTx = ex.getLedger();
    final txFilters = ['ALL', 'BUY', 'SELL', 'SWAP', 'SEND', 'RECEIVE', 'DEPOSIT'];
    final currentTxFilter = _txFilter.startsWith('TX:')
        ? _txFilter.substring(3)
        : (_txFilter == 'ALL' ? 'ALL' : 'ALL');
    final filtered = currentTxFilter == 'ALL'
        ? allTx
        : allTx.where((t) => t.typeLabel == currentTxFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            _buildSpectrumTitle(p, 'TX HISTORY', Icons.receipt_long),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 4, height: 4, decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFF00FF88))),
                const SizedBox(width: 4),
                Text('LIVE SYNC', style: GoogleFonts.orbitron(
                    color: const Color(0xFF00FF88), fontSize: 7)),
              ]),
            ),
          ]),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Row(
            children: txFilters.map((f) {
              final isActive = currentTxFilter == f;
              const c = Color(0xFF00FF88);
              return GestureDetector(
                onTap: () => setState(() => _txFilter = 'TX:$f'),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: c.withValues(alpha: isActive ? 0.2 : 0.05),
                    border: Border.all(color: c.withValues(alpha: isActive ? 0.7 : 0.2)),
                  ),
                  child: Text(f, style: GoogleFonts.orbitron(
                      color: isActive ? c : p.textSecondary, fontSize: 7,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
        ),
        if (allTx.isNotEmpty) Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Row(children: [
            _txStat(p, 'TOTAL', '${allTx.length}', const Color(0xFF00F0FF)),
            const SizedBox(width: 12),
            _txStat(p, 'PNL', '\$${ex.getTotalPnL().toStringAsFixed(2)}',
                ex.getTotalPnL() >= 0 ? const Color(0xFF00FF88) : const Color(0xFFFF3355)),
            const SizedBox(width: 12),
            _txStat(p, 'HEUTE', '\$${ex.getDailyPnL().toStringAsFixed(2)}',
                ex.getDailyPnL() >= 0 ? const Color(0xFF00FF88) : const Color(0xFFFF3355)),
          ]),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.receipt_long, color: const Color(0xFF00F0FF).withValues(alpha: 0.3), size: 40),
                  const SizedBox(height: 12),
                  Text('Keine Transaktionen', style: GoogleFonts.orbitron(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.4), fontSize: 11)),
                  const SizedBox(height: 6),
                  Text('Starte Trading um die History zu befuellen',
                      style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final tx = filtered[filtered.length - 1 - i];
                    return _buildTxRow(p, tx, ex);
                  },
                ),
        ),
      ],
    );
  }

  Widget _txStat(QuantumPalette p, String label, String value, Color c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: GoogleFonts.orbitron(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 7)),
    ]);
  }

  Widget _buildTxRow(QuantumPalette p, QTransaction tx, ExchangeService ex) {
    Color typeColor;
    IconData typeIcon;
    switch (tx.type) {
      case TxType.buy:      typeColor = const Color(0xFF00FF88); typeIcon = Icons.arrow_downward; break;
      case TxType.sell:     typeColor = const Color(0xFFFF3355); typeIcon = Icons.arrow_upward;   break;
      case TxType.swap:     typeColor = const Color(0xFF00F0FF); typeIcon = Icons.swap_horiz;     break;
      case TxType.send:     typeColor = const Color(0xFFF7931A); typeIcon = Icons.send;           break;
      case TxType.receive:  typeColor = const Color(0xFF9945FF); typeIcon = Icons.download;       break;
      case TxType.deposit:  typeColor = const Color(0xFF00FF88); typeIcon = Icons.add_circle;     break;
      case TxType.withdraw: typeColor = const Color(0xFFFF6B35); typeIcon = Icons.remove_circle;  break;
      default:              typeColor = const Color(0xFF00F0FF); typeIcon = Icons.circle;         break;
    }
    final statusColor = tx.status == TxStatus.completed
        ? const Color(0xFF00FF88)
        : tx.status == TxStatus.failed
            ? const Color(0xFFFF3355)
            : const Color(0xFFF7931A);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: typeColor.withValues(alpha: 0.04),
        border: Border.all(color: typeColor.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: typeColor.withValues(alpha: 0.12),
            border: Border.all(color: typeColor.withValues(alpha: 0.35)),
          ),
          child: Icon(typeIcon, color: typeColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(tx.typeLabel, style: GoogleFonts.orbitron(
                  color: typeColor, fontSize: 9, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Text('${tx.fromAsset}→${tx.toAsset}',
                  style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: statusColor.withValues(alpha: 0.12),
                ),
                child: Text(tx.statusLabel,
                    style: GoogleFonts.orbitron(color: statusColor, fontSize: 6)),
              ),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              Text(
                '${tx.fromAmount.toStringAsFixed(tx.fromAmount < 1 ? 6 : 4)} ${tx.fromAsset}',
                style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 9, fontWeight: FontWeight.bold),
              ),
              if (tx.price > 0) ...[
                const SizedBox(width: 6),
                Text('@\$${tx.price.toStringAsFixed(tx.price > 100 ? 0 : 2)}',
                    style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
              ],
              const Spacer(),
              Text(
                '${tx.createdAt.day}.${tx.createdAt.month} '
                '${tx.createdAt.hour.toString().padLeft(2,'0')}:${tx.createdAt.minute.toString().padLeft(2,'0')}',
                style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7),
              ),
            ]),
            if (tx.pnl != 0)
              Text(
                'PnL: ${tx.pnl >= 0 ? '+' : ''}\$${tx.pnl.toStringAsFixed(2)}',
                style: GoogleFonts.spaceMono(
                    color: tx.pnl >= 0 ? const Color(0xFF00FF88) : const Color(0xFFFF3355),
                    fontSize: 8),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════

/// Frequenz-Spektrum Visualizer — multi-wave interference pattern
class _SpectrumPainter extends CustomPainter {
  final double time;
  final List<FrequencyNode> nodes;
  final int selectedIdx;

  const _SpectrumPainter({required this.time, required this.nodes, required this.selectedIdx});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background grid
    final gridPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 8; i++) {
      final x = w / 8 * i;
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (int j = 0; j <= 4; j++) {
      final y = h / 4 * j;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Draw each frequency wave
    for (int ni = 0; ni < nodes.length; ni++) {
      final node = nodes[ni];
      final isSelected = ni == selectedIdx;
      final paint = Paint()
        ..color = node.color.withValues(alpha: isSelected ? 0.85 : 0.3)
        ..strokeWidth = isSelected ? 2.0 : 1.0
        ..style = PaintingStyle.stroke;

      final path = Path();
      bool first = true;
      for (int px = 0; px < w.toInt(); px++) {
        final t = px / w;
        final y = h / 2 - (h * 0.35) * node.amplitude *
            sin(2 * pi * node.frequency * t + node.phase + time * 2 * pi);
        if (first) { path.moveTo(px.toDouble(), y); first = false; }
        else { path.lineTo(px.toDouble(), y); }
      }
      canvas.drawPath(path, paint);
    }

    // Selected wave glow
    final selNode = nodes[selectedIdx];
    final glowPaint = Paint()
      ..color = selNode.color.withValues(alpha: 0.15)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final glowPath = Path();
    bool gFirst = true;
    for (int px = 0; px < w.toInt(); px++) {
      final t = px / w;
      final y = h / 2 - (h * 0.35) * selNode.amplitude *
          sin(2 * pi * selNode.frequency * t + selNode.phase + time * 2 * pi);
      if (gFirst) { glowPath.moveTo(px.toDouble(), y); gFirst = false; }
      else { glowPath.lineTo(px.toDouble(), y); }
    }
    canvas.drawPath(glowPath, glowPaint);
  }

  @override
  bool shouldRepaint(_SpectrumPainter old) =>
      old.time != time || old.selectedIdx != selectedIdx;
}

/// Single waveform painter
class _WaveformPainter extends CustomPainter {
  final double time;
  final double freq;
  final double amp;
  final double phase;
  final Color color;

  const _WaveformPainter({
    required this.time, required this.freq,
    required this.amp, required this.phase, required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = h / 2;

    // Grid line
    canvas.drawLine(Offset(0, mid), Offset(w, mid),
        Paint()..color = color.withValues(alpha: 0.15)..strokeWidth = 0.5);

    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int px = 0; px < w.toInt(); px++) {
      final t = px / w;
      final y = mid - mid * 0.75 * amp * sin(2 * pi * freq * t + phase + time * 2 * pi);
      if (px == 0) path.moveTo(px.toDouble(), y);
      else path.lineTo(px.toDouble(), y);
    }
    canvas.drawPath(path, paint);

    // Fill under curve
    final fillPath = Path()..addPath(path, Offset.zero);
    fillPath.lineTo(w, mid);
    fillPath.lineTo(0, mid);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()
      ..color = color.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.time != time;
}

/// Gravity orbital painter
class _GravityOrbitalPainter extends CustomPainter {
  final double time;
  final List<GravityField> fields;
  final Map<String, double> prices;

  const _GravityOrbitalPainter({
    required this.time, required this.fields, required this.prices,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = min(cx, cy) * 0.85;

    // Background star field
    final rng = Random(42);
    for (int i = 0; i < 60; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 1.2,
        Paint()..color = Colors.white.withValues(alpha: 0.15 + rng.nextDouble() * 0.2),
      );
    }

    // Central mass (BTC gravity well)
    final glowPaint = Paint()
      ..color = const Color(0xFFF7931A).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(cx, cy), 30, glowPaint);
    canvas.drawCircle(Offset(cx, cy), 18,
        Paint()..color = const Color(0xFFF7931A).withValues(alpha: 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(Offset(cx, cy), 10,
        Paint()..color = const Color(0xFFF7931A));

    // Draw orbiting bodies
    for (int i = 1; i < fields.length; i++) {
      final f = fields[i];
      final r = f.orbitRadius * maxR;
      final speed = f.velocity * 0.4;
      final angle = 2 * pi * (time * speed + i / fields.length);

      // Orbit ring
      canvas.drawCircle(Offset(cx, cy), r,
          Paint()
            ..color = f.color.withValues(alpha: 0.12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8);

      // Body position
      final bx = cx + r * cos(angle);
      final by = cy + r * sin(angle);
      final radius = 6.0 + f.mass * 12;

      // Glow
      canvas.drawCircle(Offset(bx, by), radius + 6,
          Paint()..color = f.color.withValues(alpha: 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

      // Body
      canvas.drawCircle(Offset(bx, by), radius,
          Paint()..color = f.color.withValues(alpha: 0.9));

      // Symbol label
      final tp = TextPainter(
        text: TextSpan(text: f.symbol,
            style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(bx - tp.width / 2, by - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_GravityOrbitalPainter old) => old.time != time;
}

/// Time Gate Portal painter
class _TimeGatePainter extends CustomPainter {
  final double time;
  final Color gateColor;
  final double stability;
  final double pulseVal;

  const _TimeGatePainter({
    required this.time, required this.gateColor,
    required this.stability, required this.pulseVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Void background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.black.withValues(alpha: 0.6));

    // Spiral portal rings
    for (int ring = 5; ring >= 1; ring--) {
      final r = (ring / 5) * min(cx, cy) * 0.85;
      final alpha = (ring / 5) * 0.3 + pulseVal * 0.15;
      canvas.drawCircle(
        Offset(cx, cy), r,
        Paint()
          ..color = gateColor.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring == 1 ? 2.5 : 1.0,
      );
    }

    // Portal glow center
    canvas.drawCircle(Offset(cx, cy), 24,
        Paint()..color = gateColor.withValues(alpha: 0.12 + pulseVal * 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));

    // Rotating energy lines
    for (int i = 0; i < 12; i++) {
      final angle = 2 * pi * i / 12 + time * 2 * pi;
      final innerR = 18.0;
      final outerR = 30.0 + stability * 20;
      canvas.drawLine(
        Offset(cx + innerR * cos(angle), cy + innerR * sin(angle)),
        Offset(cx + outerR * cos(angle), cy + outerR * sin(angle)),
        Paint()
          ..color = gateColor.withValues(alpha: 0.5 + 0.3 * sin(angle + time * pi))
          ..strokeWidth = 1.5,
      );
    }

    // Counter-rotating outer ring
    for (int i = 0; i < 6; i++) {
      final angle = 2 * pi * i / 6 - time * 2 * pi * 0.7;
      final r = min(cx, cy) * 0.6;
      canvas.drawCircle(
        Offset(cx + r * cos(angle), cy + r * sin(angle)), 3,
        Paint()..color = gateColor.withValues(alpha: 0.6),
      );
    }

    // Scanline
    final scanY = (cy - 40) + (time % 1.0) * 80;
    canvas.drawLine(
      Offset(cx - 60, scanY),
      Offset(cx + 60, scanY),
      Paint()..color = gateColor.withValues(alpha: 0.25)..strokeWidth = 1,
    );

    // Center dot
    canvas.drawCircle(Offset(cx, cy), 5,
        Paint()..color = gateColor.withValues(alpha: 0.9 + pulseVal * 0.1));
    canvas.drawCircle(Offset(cx, cy), 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_TimeGatePainter old) =>
      old.time != time || old.gateColor != gateColor;
}

/// Quantum orb rotating painter (header icon)
class _QuantumOrbPainter extends CustomPainter {
  final double time;
  final Color color;
  const _QuantumOrbPainter(this.time, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    for (int i = 0; i < 3; i++) {
      final angle = 2 * pi * i / 3 + time * 2 * pi;
      canvas.drawCircle(
        Offset(cx + 16 * cos(angle), cy + 16 * sin(angle)), 3,
        Paint()..color = color.withValues(alpha: 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(_QuantumOrbPainter old) => old.time != time;
}

/// Black hole dominance painter
class _BlackHolePainter extends CustomPainter {
  final double time;
  final double pulse;
  const _BlackHolePainter(this.time, this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Accretion disk
    for (int ring = 3; ring >= 1; ring--) {
      final r = ring * 8.0;
      canvas.drawCircle(Offset(cx, cy), r,
          Paint()
            ..color = const Color(0xFF9945FF).withValues(alpha: (4 - ring) * 0.1 + pulse * 0.08)
            ..style = PaintingStyle.stroke
            ..strokeWidth = ring == 1 ? 2.0 : 1.0);
    }

    // Rotating dot
    final angle = time * 2 * pi;
    canvas.drawCircle(
      Offset(cx + 18 * cos(angle), cy + 18 * sin(angle)), 3,
      Paint()..color = const Color(0xFFF7931A).withValues(alpha: 0.8),
    );

    // Event horizon
    canvas.drawCircle(Offset(cx, cy), 7,
        Paint()..color = Colors.black);
    canvas.drawCircle(Offset(cx, cy), 5,
        Paint()..color = const Color(0xFF9945FF).withValues(alpha: 0.3 + pulse * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  @override
  bool shouldRepaint(_BlackHolePainter old) => old.time != time;
}
