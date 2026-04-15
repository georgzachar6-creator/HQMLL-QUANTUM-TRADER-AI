// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
//  TR2 RECURSIVE PREVIEW — HQMLL Meta-Reasoning Live Visualizer
//  Quantum Trader AI System v16.0
// ═══════════════════════════════════════════════════════════════

class TR2PreviewScreen extends StatefulWidget {
  const TR2PreviewScreen({super.key});
  @override
  State<TR2PreviewScreen> createState() => _TR2PreviewScreenState();
}

class _TR2PreviewScreenState extends State<TR2PreviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _waveCtrl;
  late Animation<double> _mainAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _waveAnim;

  final Random _rng = Random();
  Timer? _thinkTimer;
  Timer? _nodeTimer;
  Timer? _logTimer;

  bool _tr2Active = false;
  int _recursionDepth = 0;
  int _totalLoops = 0;
  double _coherence = 0.0;
  double _entropy = 0.5;
  double _confidence = 0.0;
  double _convergence = 0.0;
  String _currentPhase = 'IDLE';
  int _activeNodes = 0;
  int _processedTokens = 0;
  double _thinkSpeed = 0.0;

  // Reasoning nodes for visual graph
  final List<_ReasonNode> _nodes = [];
  final List<_ReasonEdge> _edges = [];
  final List<String> _thinkLog = [];

  // Memory snapshots
  final List<Map<String, dynamic>> _memorySnapshots = [];

  // Phases
  static const _phases = [
    'BOOTSTRAP', 'META-SCAN', 'HYPOTHESIS', 'VALIDATION',
    'RECURSION', 'SYNTHESIS', 'CONVERGENCE', 'OUTPUT'
  ];
  int _phaseIdx = 0;

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _mainAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _mainCtrl, curve: Curves.easeInOut));
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _rotateAnim = Tween<double>(begin: 0.0, end: 2 * pi).animate(_rotateCtrl);
    _waveAnim = Tween<double>(begin: 0.0, end: 2 * pi).animate(_waveCtrl);
    _buildInitialNodes();
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _waveCtrl.dispose();
    _thinkTimer?.cancel();
    _nodeTimer?.cancel();
    _logTimer?.cancel();
    super.dispose();
  }

  void _buildInitialNodes() {
    _nodes.clear();
    _edges.clear();
    // Central node
    _nodes.add(_ReasonNode('ROOT', 'HQMLL\nCORE', 0.5, 0.5, const Color(0xFF00FF88), 36, true));
    // Layer 1
    final l1Positions = [
      [0.5, 0.18], [0.82, 0.35], [0.82, 0.65], [0.5, 0.82], [0.18, 0.65], [0.18, 0.35],
    ];
    final l1Labels = ['MARKET\nDATA', 'TECH\nANAL', 'SENTI\nMENT', 'RISK\nMGR', 'QUANT\nMATH', 'META\nREASON'];
    final l1Colors = [
      const Color(0xFF00AAFF), const Color(0xFFFFAA00), const Color(0xFFFF66AA),
      const Color(0xFFFF4466), const Color(0xFFAA44FF), const Color(0xFF00FFCC),
    ];
    for (int i = 0; i < 6; i++) {
      _nodes.add(_ReasonNode('L1_$i', l1Labels[i], l1Positions[i][0], l1Positions[i][1], l1Colors[i], 26, false));
      _edges.add(_ReasonEdge('ROOT', 'L1_$i', l1Colors[i]));
    }
    // Layer 2 – smaller outer nodes
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi;
      final x = 0.5 + 0.42 * cos(angle);
      final y = 0.5 + 0.42 * sin(angle);
      _nodes.add(_ReasonNode('L2_$i', '', x, y, const Color(0xFF1A4A6A), 10, false));
      _edges.add(_ReasonEdge('L1_${i ~/ 2}', 'L2_$i', const Color(0xFF1A4A6A)));
    }
  }

  void _startTR2() {
    setState(() {
      _tr2Active = true;
      _recursionDepth = 0;
      _totalLoops = 0;
      _coherence = 0.0;
      _entropy = 0.8;
      _confidence = 0.0;
      _convergence = 0.0;
      _phaseIdx = 0;
      _currentPhase = _phases[0];
      _activeNodes = 1;
      _processedTokens = 0;
      _thinkSpeed = 0.0;
      _thinkLog.clear();
      _memorySnapshots.clear();
    });
    _addLog('TR2 Engine gestartet...', const Color(0xFF00FF88));
    _addLog('Initialisiere Quantum-Reasoning-Matrix', const Color(0xFF00AAFF));
    _thinkTimer = Timer.periodic(const Duration(milliseconds: 400), _tick);
    _nodeTimer = Timer.periodic(const Duration(seconds: 2), _addDynamicNode);
    _logTimer = Timer.periodic(const Duration(milliseconds: 900), _addRandomLog);
  }

  void _stopTR2() {
    _thinkTimer?.cancel();
    _nodeTimer?.cancel();
    _logTimer?.cancel();
    setState(() {
      _tr2Active = false;
      _currentPhase = 'STOPPED';
    });
    _addLog('TR2 Engine gestoppt.', const Color(0xFFFF4466));
  }

  void _tick(Timer t) {
    if (!mounted) { t.cancel(); return; }
    setState(() {
      _totalLoops++;
      _processedTokens += _rng.nextInt(1200) + 400;
      _thinkSpeed = 1200 + _rng.nextDouble() * 800;
      // Advance metrics
      if (_coherence < 0.98) _coherence = (_coherence + 0.012 + _rng.nextDouble() * 0.008).clamp(0.0, 1.0);
      if (_entropy > 0.05) _entropy = (_entropy - 0.008 - _rng.nextDouble() * 0.005).clamp(0.05, 1.0);
      if (_confidence < 0.96) _confidence = (_confidence + 0.015 + _rng.nextDouble() * 0.01).clamp(0.0, 1.0);
      if (_convergence < 0.99) _convergence = (_convergence + 0.01).clamp(0.0, 1.0);
      _recursionDepth = (_totalLoops ~/ 8).clamp(0, 99);
      _activeNodes = (6 + _recursionDepth * 2).clamp(6, 48);
      // Phase progression
      final targetPhase = ((_convergence * (_phases.length - 1)).floor()).clamp(0, _phases.length - 1);
      if (targetPhase != _phaseIdx) {
        _phaseIdx = targetPhase;
        _currentPhase = _phases[_phaseIdx];
        _addLog('Phase: $_currentPhase', _phaseColor(_phaseIdx));
        _memorySnapshots.insert(0, {
          'phase': _currentPhase,
          'depth': _recursionDepth,
          'coherence': _coherence,
          'confidence': _confidence,
          'time': _timeNow(),
        });
        if (_memorySnapshots.length > 8) _memorySnapshots.removeLast();
      }
      // Stop when converged
      if (_convergence >= 0.99) {
        _thinkTimer?.cancel();
        _nodeTimer?.cancel();
        _logTimer?.cancel();
        _currentPhase = 'CONVERGED';
        _addLog('✓ Konvergenz erreicht! Confidence: ${(_confidence * 100).toStringAsFixed(1)}%', const Color(0xFF00FF88));
      }
    });
  }

  void _addDynamicNode(Timer t) {
    if (!mounted || _nodes.length > 60) return;
    final angle = _rng.nextDouble() * 2 * pi;
    final r = 0.25 + _rng.nextDouble() * 0.2;
    final x = (0.5 + r * cos(angle)).clamp(0.05, 0.95);
    final y = (0.5 + r * sin(angle)).clamp(0.05, 0.95);
    final colors = [const Color(0xFF00FF88), const Color(0xFF00AAFF), const Color(0xFFAA44FF), const Color(0xFFFFAA00)];
    setState(() {
      final id = 'DYN_${_nodes.length}';
      _nodes.add(_ReasonNode(id, '', x, y, colors[_rng.nextInt(colors.length)], 8, false));
      _edges.add(_ReasonEdge('ROOT', id, const Color(0xFF1A3A5C)));
    });
  }

  void _addRandomLog(Timer t) {
    if (!mounted) return;
    final logs = [
      ['Scanning BTC/ETH correlation matrix...', const Color(0xFF00AAFF)],
      ['Applying Bayesian update: P(up)=0.${67 + _rng.nextInt(15)}', const Color(0xFF00FF88)],
      ['Recursive loop depth: $_recursionDepth', const Color(0xFFFFAA00)],
      ['Token embedding: ${_processedTokens ~/ 1000}K processed', const Color(0xFF00FFCC)],
      ['Sentiment vector updated: ${_rng.nextBool() ? "BULLISH" : "NEUTRAL"}', const Color(0xFFFF66AA)],
      ['Memory consolidation: ${(_coherence * 100).toStringAsFixed(0)}% coherent', const Color(0xFFAA44FF)],
      ['Risk model recalibrated: σ=${(0.02 + _rng.nextDouble() * 0.04).toStringAsFixed(3)}', const Color(0xFFFF4466)],
      ['Hypothesis set: ${3 + _rng.nextInt(5)} active branches', const Color(0xFF00AAFF)],
    ];
    final entry = logs[_rng.nextInt(logs.length)];
    _addLog(entry[0] as String, entry[1] as Color);
  }

  void _addLog(String msg, Color color) {
    if (!mounted) return;
    setState(() {
      _thinkLog.insert(0, '${_timeNow()} | $msg');
      if (_thinkLog.length > 40) _thinkLog.removeLast();
    });
  }

  Color _phaseColor(int idx) {
    final colors = [
      const Color(0xFF7AAFC8), const Color(0xFF00AAFF), const Color(0xFFFFAA00),
      const Color(0xFF00FFCC), const Color(0xFFAA44FF), const Color(0xFF00FF88),
      const Color(0xFFFFD700), const Color(0xFF00FF88),
    ];
    return colors[idx % colors.length];
  }

  static String _timeNow() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}:${n.second.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020810),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                // Left: Neural Graph
                Expanded(flex: 5, child: _buildNeuralGraph()),
                // Right: Metrics + Log
                Expanded(flex: 4, child: _buildRightPanel()),
              ],
            ),
          ),
          _buildControlBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _mainAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 50, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF020810),
              Color.lerp(const Color(0xFF0A1A08), const Color(0xFF081228), _mainAnim.value)!,
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: Color.lerp(const Color(0xFF00FF88), const Color(0xFF00AAFF), _mainAnim.value)!.withValues(alpha: 0.4),
            ),
          ),
        ),
        child: Row(
          children: [
            // TR2 Brain Icon
            AnimatedBuilder(
              animation: _rotateAnim,
              builder: (_, __) => Transform.rotate(
                angle: _tr2Active ? _rotateAnim.value * 0.3 : 0,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Color.lerp(const Color(0xFF00FF88), const Color(0xFF00AAFF), _mainAnim.value)!,
                      const Color(0xFF001A08),
                    ]),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF00FF88).withValues(alpha: _tr2Active ? 0.6 : 0.2),
                      blurRadius: 16, spreadRadius: 2,
                    )],
                  ),
                  child: const Icon(Icons.hub_outlined, color: Colors.white, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TR2 RECURSIVE ENGINE', style: GoogleFonts.rajdhani(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2,
              )),
              Text('HQMLL META-REASONING LIVE PREVIEW', style: GoogleFonts.spaceMono(
                color: Color.lerp(const Color(0xFF00FF88), const Color(0xFF00AAFF), _mainAnim.value),
                fontSize: 9, letterSpacing: 1.5,
              )),
            ]),
            const Spacer(),
            // Status badges
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _badge(_currentPhase, _phaseColor(_phaseIdx)),
              const SizedBox(height: 4),
              _badge('DEPTH: $_recursionDepth', const Color(0xFFAA44FF)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      color: color.withValues(alpha: 0.15),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Text(text, style: GoogleFonts.spaceMono(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
  );

  // ── Neural Graph ──────────────────────────────────────────
  Widget _buildNeuralGraph() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0A2A1A)),
        color: const Color(0xFF020810),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Animated background grid
            AnimatedBuilder(
              animation: _waveAnim,
              builder: (_, __) => CustomPaint(
                painter: _GridPainter(_waveAnim.value),
                size: Size.infinite,
              ),
            ),
            // Edges + Nodes
            AnimatedBuilder(
              animation: Listenable.merge([_mainAnim, _pulseAnim, _rotateAnim]),
              builder: (_, __) => CustomPaint(
                painter: _NeuralGraphPainter(
                  nodes: _nodes,
                  edges: _edges,
                  pulseVal: _pulseAnim.value,
                  rotateVal: _rotateAnim.value,
                  active: _tr2Active,
                ),
                size: Size.infinite,
              ),
            ),
            // Center stats overlay
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 120),
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Text(
                      _tr2Active ? '${(_convergence * 100).toStringAsFixed(1)}%' : '0.0%',
                      style: GoogleFonts.rajdhani(
                        color: const Color(0xFF00FF88).withValues(alpha: _pulseAnim.value),
                        fontSize: 28, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text('CONVERGENCE', style: GoogleFonts.spaceMono(
                    color: const Color(0xFF3A6080), fontSize: 8, letterSpacing: 2,
                  )),
                ],
              ),
            ),
            // Active nodes count bottom
            Positioned(
              bottom: 12, left: 0, right: 0,
              child: Center(child: Text(
                '$_activeNodes ACTIVE NODES  •  ${(_processedTokens / 1000).toStringAsFixed(0)}K TOKENS',
                style: GoogleFonts.spaceMono(color: const Color(0xFF3A6080), fontSize: 8),
              )),
            ),
          ],
        ),
      ),
    );
  }

  // ── Right Panel ───────────────────────────────────────────
  Widget _buildRightPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: Column(
        children: [
          _buildMetricsCard(),
          const SizedBox(height: 8),
          _buildPhaseProgress(),
          const SizedBox(height: 8),
          _buildMemorySnapshots(),
          const SizedBox(height: 8),
          _buildThinkLog(),
        ],
      ),
    );
  }

  Widget _buildMetricsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.2)),
        color: const Color(0xFF020D06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LIVE METRIKEN', style: GoogleFonts.spaceMono(
            color: const Color(0xFF00FF88), fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 10),
          _metricBar('COHERENCE', _coherence, const Color(0xFF00FF88)),
          _metricBar('CONFIDENCE', _confidence, const Color(0xFF00AAFF)),
          _metricBar('CONVERGENCE', _convergence, const Color(0xFFFFAA00)),
          _metricBar('ENTROPY ▼', 1 - _entropy, const Color(0xFFFF4466)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat('LOOPS', _totalLoops.toString(), const Color(0xFFAA44FF)),
              _miniStat('DEPTH', _recursionDepth.toString(), const Color(0xFF00FFCC)),
              _miniStat('T/s', _thinkSpeed.toStringAsFixed(0), const Color(0xFFFFAA00)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: GoogleFonts.spaceMono(color: const Color(0xFF7AAFC8), fontSize: 8)),
              const Spacer(),
              Text('${(value * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.spaceMono(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF0A2A1A),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.rajdhani(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.spaceMono(color: const Color(0xFF3A6080), fontSize: 7)),
      ],
    );
  }

  Widget _buildPhaseProgress() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFAA44FF).withValues(alpha: 0.2)),
        color: const Color(0xFF08050E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REASONING PHASEN', style: GoogleFonts.spaceMono(
            color: const Color(0xFFAA44FF), fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: _phases.asMap().entries.map((e) {
              final done = e.key < _phaseIdx;
              final active = e.key == _phaseIdx;
              final color = done ? const Color(0xFF00FF88) : active ? _phaseColor(e.key) : const Color(0xFF1A3A5C);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: color.withValues(alpha: active ? 0.2 : done ? 0.1 : 0.05),
                  border: Border.all(color: color.withValues(alpha: active ? 0.8 : 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (done) const Icon(Icons.check, size: 8, color: Color(0xFF00FF88))
                  else if (active) const SizedBox(width: 6, height: 6, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFFFAA00))),
                  if (done || active) const SizedBox(width: 3),
                  Text(e.value, style: GoogleFonts.spaceMono(color: color, fontSize: 7, fontWeight: FontWeight.bold)),
                ]),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMemorySnapshots() {
    if (_memorySnapshots.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00AAFF).withValues(alpha: 0.2)),
        color: const Color(0xFF020810),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MEMORY SNAPSHOTS', style: GoogleFonts.spaceMono(
            color: const Color(0xFF00AAFF), fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 8),
          ..._memorySnapshots.take(4).map((s) => Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: const Color(0xFF0A1628),
              border: Border.all(color: const Color(0xFF1A3A5C)),
            ),
            child: Row(children: [
              Text(s['time'], style: GoogleFonts.spaceMono(color: const Color(0xFF3A6080), fontSize: 7)),
              const SizedBox(width: 6),
              Text(s['phase'], style: GoogleFonts.spaceMono(color: _phaseColor(_phases.indexOf(s['phase'])), fontSize: 8, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('D:${s['depth']}', style: GoogleFonts.spaceMono(color: const Color(0xFFAA44FF), fontSize: 7)),
              const SizedBox(width: 6),
              Text('${((s['confidence'] as double) * 100).toStringAsFixed(0)}%', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 7)),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildThinkLog() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1A3A5C)),
        color: const Color(0xFF010608),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.terminal, color: Color(0xFF00FF88), size: 12),
            const SizedBox(width: 6),
            Text('THINK LOG', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 8, letterSpacing: 1.5)),
            const Spacer(),
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _tr2Active ? const Color(0xFF00FF88).withValues(alpha: _pulseAnim.value) : const Color(0xFF3A6080),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _thinkLog.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '> ${_thinkLog[i]}',
                  style: GoogleFonts.spaceMono(
                    color: i == 0
                        ? const Color(0xFF00FF88)
                        : const Color(0xFF3A6080).withValues(alpha: 1 - i * 0.03),
                    fontSize: 8, height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      color: const Color(0xFF020810),
      child: Row(
        children: [
          // Start/Stop
          Expanded(
            child: GestureDetector(
              onTap: _tr2Active ? _stopTR2 : _startTR2,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: _tr2Active
                          ? [const Color(0xFFFF4466), const Color(0xFFFF8800)]
                          : [const Color(0xFF00FF88), const Color(0xFF00AAFF)],
                    ),
                    boxShadow: [BoxShadow(
                      color: (_tr2Active ? const Color(0xFFFF4466) : const Color(0xFF00FF88))
                          .withValues(alpha: _pulseAnim.value * 0.5),
                      blurRadius: 16, spreadRadius: 2,
                    )],
                  ),
                  child: Center(child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_tr2Active ? Icons.stop_rounded : Icons.play_arrow_rounded,
                          color: Colors.black, size: 22),
                      const SizedBox(width: 8),
                      Text(_tr2Active ? 'TR2 STOPPEN' : 'TR2 STARTEN',
                          style: GoogleFonts.rajdhani(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ],
                  )),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Reset
          GestureDetector(
            onTap: () {
              _stopTR2();
              setState(() {
                _buildInitialNodes();
                _thinkLog.clear();
                _memorySnapshots.clear();
                _convergence = 0;
                _coherence = 0;
                _confidence = 0;
                _entropy = 0.5;
                _recursionDepth = 0;
                _totalLoops = 0;
                _processedTokens = 0;
                _phaseIdx = 0;
                _currentPhase = 'IDLE';
              });
            },
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1A3A5C)),
                color: const Color(0xFF0A1628),
              ),
              child: const Icon(Icons.refresh_rounded, color: Color(0xFF7AAFC8), size: 22),
            ),
          ),
          const SizedBox(width: 10),
          // Copy log
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _thinkLog.join('\n')));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Log kopiert!', style: GoogleFonts.spaceMono(color: Colors.black)),
                backgroundColor: const Color(0xFF00FF88),
                duration: const Duration(seconds: 2),
              ));
            },
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1A3A5C)),
                color: const Color(0xFF0A1628),
              ),
              child: const Icon(Icons.copy, color: Color(0xFF7AAFC8), size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data Models ───────────────────────────────────────────────
class _ReasonNode {
  final String id, label;
  final double x, y;
  final Color color;
  final double radius;
  final bool isRoot;
  _ReasonNode(this.id, this.label, this.x, this.y, this.color, this.radius, this.isRoot);
}

class _ReasonEdge {
  final String from, to;
  final Color color;
  _ReasonEdge(this.from, this.to, this.color);
}

// ── Custom Painters ───────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final double phase;
  _GridPainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Radial glow from center
    final cx = size.width / 2;
    final cy = size.height / 2;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00FF88).withValues(alpha: 0.08 + 0.03 * sin(phase)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.45));
    canvas.drawCircle(Offset(cx, cy), size.width * 0.45, glowPaint);
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.phase != phase;
}

class _NeuralGraphPainter extends CustomPainter {
  final List<_ReasonNode> nodes;
  final List<_ReasonEdge> edges;
  final double pulseVal;
  final double rotateVal;
  final bool active;

  _NeuralGraphPainter({
    required this.nodes, required this.edges,
    required this.pulseVal, required this.rotateVal, required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Map<String, Offset> positions = {};
    for (final n in nodes) {
      positions[n.id] = Offset(n.x * size.width, n.y * size.height);
    }

    // Draw edges
    for (final e in edges) {
      final from = positions[e.from];
      final to = positions[e.to];
      if (from == null || to == null) continue;
      final paint = Paint()
        ..color = e.color.withValues(alpha: active ? 0.25 + 0.1 * pulseVal : 0.1)
        ..strokeWidth = 0.8;
      canvas.drawLine(from, to, paint);
    }

    // Draw nodes
    for (final n in nodes) {
      final pos = positions[n.id]!;
      final isRoot = n.isRoot;
      final glowAlpha = active ? 0.3 + 0.2 * pulseVal : 0.1;

      // Glow ring
      if (isRoot) {
        final glowPaint = Paint()
          ..color = n.color.withValues(alpha: glowAlpha * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(pos, n.radius + 8 + 3 * pulseVal, glowPaint);
        canvas.drawCircle(pos, n.radius + 14 + 5 * pulseVal,
            Paint()..color = n.color.withValues(alpha: glowAlpha * 0.2)..style = PaintingStyle.stroke..strokeWidth = 1);
      }

      // Node fill
      final fill = Paint()
        ..color = n.color.withValues(alpha: isRoot ? 0.25 : 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, n.radius, fill);

      // Node border
      final border = Paint()
        ..color = n.color.withValues(alpha: active ? 0.8 : 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isRoot ? 2.0 : 1.0;
      canvas.drawCircle(pos, n.radius, border);

      // Label
      if (n.label.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: n.label,
            style: TextStyle(
              color: n.color.withValues(alpha: active ? 0.9 : 0.5),
              fontSize: isRoot ? 8.0 : 6.5,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: n.radius * 2.2);
        tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_NeuralGraphPainter old) => true;
}
