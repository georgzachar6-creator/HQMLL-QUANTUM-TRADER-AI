/// HQMLL Quantum Trader – AI Genius Meta-Reasoning Engine
/// TR2 Recursive Thinking · Memory Library · Deep Meta-Loops
/// © 2025 Grigori Saks · HQMLL · Patent-Pending · CONFIDENTIAL
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

// ══════════════════════════════════════════════════════════════
// AI GENIUS META-REASONING ENGINE
// ══════════════════════════════════════════════════════════════
class AIGeniusScreen extends StatefulWidget {
  const AIGeniusScreen({super.key});
  @override
  State<AIGeniusScreen> createState() => _AIGeniusScreenState();
}

class _AIGeniusScreenState extends State<AIGeniusScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _scanCtrl;

  final Random _rng = Random();
  Timer? _thinkTimer;
  Timer? _memTimer;

  // ─ TR2 State ─
  bool _tr2Running = false;
  int _loopCount = 0;
  int _depthLevel = 0;
  double _coherence = 0.0;
  double _entropy = 0.0;
  double _confidence = 0.0;
  int _tab = 0;

  // ─ Memory Library ─
  final List<MemoryNode> _memory = [];
  final List<ThinkingLog> _thinkLogs = [];
  final List<ReasoningChain> _chains = [];
  final _commandCtrl = TextEditingController();

  // ─ Agent States ─
  final List<AgentModule> _agents = [
    AgentModule('META-ANALYST', Icons.analytics, 'AKTIV', 0.94),
    AgentModule('QUANTEN-ORACLE', Icons.remove_red_eye, 'AKTIV', 0.89),
    AgentModule('TR2-CORE', Icons.memory, 'AKTIV', 0.97),
    AgentModule('MEMORY-MGR', Icons.storage, 'AKTIV', 0.91),
    AgentModule('REASONING-LOOP', Icons.loop, 'AKTIV', 0.88),
    AgentModule('GENIUS-SYNTH', Icons.auto_awesome, 'AKTIV', 0.96),
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _pulseCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _scanCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

    _initMemory();
    _initChains();
    _startBackgroundProcessing();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _scanCtrl.dispose();
    _thinkTimer?.cancel();
    _memTimer?.cancel();
    _commandCtrl.dispose();
    super.dispose();
  }

  void _initMemory() {
    _memory.addAll([
      MemoryNode('MEM-001', 'BTC Resistance at \$72,000', MemoryType.market, 0.95, DateTime.now().subtract(const Duration(hours: 2))),
      MemoryNode('MEM-002', 'ETH/USD correlation: 0.87', MemoryType.pattern, 0.88, DateTime.now().subtract(const Duration(hours: 5))),
      MemoryNode('MEM-003', 'QEMMA launch anomaly detected', MemoryType.anomaly, 0.92, DateTime.now().subtract(const Duration(minutes: 30))),
      MemoryNode('MEM-004', 'Fed Rate decision: -0.25% expected', MemoryType.macro, 0.78, DateTime.now().subtract(const Duration(days: 1))),
      MemoryNode('MEM-005', 'Fibonacci 0.618 retracement SOL', MemoryType.technical, 0.91, DateTime.now().subtract(const Duration(hours: 1))),
      MemoryNode('MEM-006', 'Portfolio Sharpe Ratio: 2.34', MemoryType.portfolio, 0.97, DateTime.now().subtract(const Duration(minutes: 15))),
      MemoryNode('MEM-007', 'Grigori Saks IP: Patent-Pending', MemoryType.system, 1.0, DateTime.now().subtract(const Duration(days: 30))),
      MemoryNode('MEM-008', 'HQMLL Quantum Algo v10: deployed', MemoryType.system, 1.0, DateTime.now()),
    ]);
  }

  void _initChains() {
    _chains.addAll([
      ReasoningChain(
        id: 'TR2-A1',
        title: 'BTC Markt-Analyse',
        steps: ['Preisdaten laden', 'Technische Analyse', 'Sentiment-Scan', 'ML-Prognose', 'Signal ausgeben'],
        currentStep: 4,
        confidence: 0.87,
        result: 'KAUFEN – Konfidenz 87%',
      ),
      ReasoningChain(
        id: 'TR2-B2',
        title: 'Portfolio-Optimierung',
        steps: ['Assets bewerten', 'Risiko kalkulieren', 'Korrelation prüfen', 'Rebalancing-Plan', 'Ausführen'],
        currentStep: 3,
        confidence: 0.92,
        result: 'ETH +5%, SOL -2%',
      ),
      ReasoningChain(
        id: 'TR2-C3',
        title: 'QEMMA Token-Strategie',
        steps: ['Tokenomics analysieren', 'Wallet-Daten prüfen', 'Mining-Rate optimieren', 'Deploy Signal'],
        currentStep: 2,
        confidence: 0.94,
        result: 'Mining +12.3% möglich',
      ),
    ]);
  }

  void _startBackgroundProcessing() {
    _thinkTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted) return;
      setState(() {
        if (_tr2Running) {
          _loopCount++;
          _depthLevel = (_depthLevel + 1) % 7;
          _coherence = 0.75 + _rng.nextDouble() * 0.24;
          _entropy = _rng.nextDouble() * 0.3;
          _confidence = 0.80 + _rng.nextDouble() * 0.19;

          if (_loopCount % 5 == 0) {
            _addThinkLog();
          }
          for (final agent in _agents) {
            agent.load = 0.7 + _rng.nextDouble() * 0.29;
          }
        }
      });
    });
  }

  void _addThinkLog() {
    final thoughts = [
      'TR2-LOOP: Mustererkennung abgeschlossen – 94% Übereinstimmung',
      'MEMORY: 3 neue Knoten verknüpft – Cluster erweitert',
      'GENIUS: Hypothese generiert – BTC Breakout Wahrscheinlichkeit 78%',
      'META: Selbst-Evaluation – Reasoning-Qualität: OPTIMAL',
      'TR2: Rekursive Tiefe 6/7 erreicht – Emergenz erkannt',
      'ORACLE: Quantenresonanz-Welle positiv – Kauf-Signal',
      'SYNTH: Neue Verbindung: Makro ↔ Technisch ↔ Sentiment',
      'LOOP: Feedback-Integration – Modell verbessert +0.3%',
    ];
    _thinkLogs.insert(0, ThinkingLog(
      thought: thoughts[_rng.nextInt(thoughts.length)],
      timestamp: DateTime.now(),
      depth: _depthLevel,
      type: ThinkLogType.values[_rng.nextInt(ThinkLogType.values.length)],
    ));
    if (_thinkLogs.length > 50) _thinkLogs.removeRange(50, _thinkLogs.length);
  }

  void _toggleTR2() {
    HapticFeedback.heavyImpact();
    setState(() {
      _tr2Running = !_tr2Running;
      if (!_tr2Running) {
        _loopCount = 0;
        _depthLevel = 0;
      }
    });
  }

  void _processCommand(String cmd) {
    if (cmd.isEmpty) return;
    HapticFeedback.selectionClick();
    final responses = {
      'analyze': 'META-ANALYSE gestartet – BTC/ETH/SOL wird verarbeitet...',
      'think': 'TR2-LOOP initiiert – Tiefe 7 wird angesteuert...',
      'remember': 'MEMORY gespeichert – Knoten MEM-${_memory.length + 1} erstellt',
      'optimize': 'PORTFOLIO-OPTIMIERUNG gestartet – Berechnung läuft...',
      'predict': 'PROGNOSE-MODELL aktiviert – 72h Vorhersage generiert',
      'scan': 'MARKT-SCAN gestartet – 500 Assets werden analysiert...',
    };
    final lower = cmd.toLowerCase();
    String response = 'BEFEHL VERARBEITET: $cmd';
    for (final entry in responses.entries) {
      if (lower.contains(entry.key)) {
        response = entry.value;
        break;
      }
    }
    _thinkLogs.insert(0, ThinkingLog(
      thought: '> $cmd → $response',
      timestamp: DateTime.now(),
      depth: 0,
      type: ThinkLogType.command,
    ));
    _commandCtrl.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;
    final accentColor = const Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: p.background,
      body: Column(
        children: [
          _buildHeader(p, accentColor),
          _buildTR2Panel(p, accentColor),
          _buildTabBar(p, accentColor),
          Expanded(
            child: _buildTabContent(p, accentColor),
          ),
          _buildCommandInput(p, accentColor),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────
  Widget _buildHeader(dynamic p, Color accent) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.12 + _glowCtrl.value * 0.06),
              p.background,
            ],
          ),
          border: Border(bottom: BorderSide(color: accent.withValues(alpha: 0.2))),
        ),
        child: Row(
          children: [
            // Rotating quantum brain
            AnimatedBuilder(
              animation: _rotateCtrl,
              builder: (_, __) => Transform.rotate(
                angle: _tr2Running ? _rotateCtrl.value * pi * 2 : 0,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.5), width: 2),
                    gradient: RadialGradient(colors: [
                      accent.withValues(alpha: 0.2),
                      Colors.transparent,
                    ]),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: _tr2Running ? 0.4 : 0.15),
                        blurRadius: 16, spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(Icons.psychology, color: accent, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI GENIUS ENGINE',
                    style: GoogleFonts.spaceMono(
                      color: accent, fontSize: 15,
                      fontWeight: FontWeight.bold, letterSpacing: 2,
                    ),
                  ),
                  Text('TR2 Meta-Reasoning · Memory Library · Deep Loops',
                    style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9),
                  ),
                ],
              ),
            ),
            // TR2 Toggle
            GestureDetector(
              onTap: _toggleTR2,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _tr2Running
                        ? const Color(0xFF00E676).withValues(alpha: 0.15 + _pulseCtrl.value * 0.05)
                        : p.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _tr2Running
                          ? const Color(0xFF00E676).withValues(alpha: 0.6)
                          : p.primary.withValues(alpha: 0.3),
                    ),
                    boxShadow: _tr2Running ? [
                      BoxShadow(
                        color: const Color(0xFF00E676).withValues(alpha: _pulseCtrl.value * 0.3),
                        blurRadius: 10,
                      ),
                    ] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_tr2Running)
                        Container(
                          width: 6, height: 6,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00E676),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFF00E676).withValues(alpha: _pulseCtrl.value),
                              blurRadius: 6,
                            )],
                          ),
                        ),
                      Text(
                        _tr2Running ? 'TR2 AKTIV' : 'TR2 START',
                        style: GoogleFonts.spaceMono(
                          color: _tr2Running ? const Color(0xFF00E676) : p.textSecondary,
                          fontSize: 9, fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TR2 Stats Panel ───────────────────────────────────
  Widget _buildTR2Panel(dynamic p, Color accent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _metricTile('LOOPS', _loopCount.toString(), accent, p),
              _divider(),
              _metricTile('TIEFE', '$_depthLevel/7', const Color(0xFF7B00D4), p),
              _divider(),
              _metricTile('KOHÄRENZ', '${(_coherence * 100).toStringAsFixed(0)}%', const Color(0xFF00E676), p),
              _divider(),
              _metricTile('KONFIDENZ', '${(_confidence * 100).toStringAsFixed(0)}%', const Color(0xFFFF9100), p),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bars
          Row(
            children: [
              Expanded(child: _progressBar('Kohärenz', _coherence, const Color(0xFF00E676), p)),
              const SizedBox(width: 8),
              Expanded(child: _progressBar('Entropie', _entropy, const Color(0xFFFF1744), p)),
              const SizedBox(width: 8),
              Expanded(child: _progressBar('Konfidenz', _confidence, const Color(0xFFFF9100), p)),
            ],
          ),
          // Agent Grid
          const SizedBox(height: 10),
          Row(
            children: _agents.map((agent) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: p.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: p.primary.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Icon(agent.icon, color: p.primary, size: 12),
                    const SizedBox(height: 2),
                    Text('${(agent.load * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.rajdhani(
                        color: agent.load > 0.9 ? const Color(0xFF00E676) : p.primary,
                        fontSize: 9, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, Color color, dynamic p) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
            style: GoogleFonts.rajdhani(
              color: color, fontSize: 16, fontWeight: FontWeight.bold,
            ),
          ),
          Text(label,
            style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.06));

  Widget _progressBar(String label, double value, Color color, dynamic p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 8)),
            Text('${(value * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.spaceMono(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: value, minHeight: 4,
            backgroundColor: p.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ── Tab Bar ───────────────────────────────────────────
  Widget _buildTabBar(dynamic p, Color accent) {
    final tabs = ['REASONING', 'MEMORY', 'AGENTEN', 'PROTOKOLL'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 36,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final sel = _tab == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: sel ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(e.value,
                    style: GoogleFonts.spaceMono(
                      color: sel ? Colors.black : p.textSecondary,
                      fontSize: 7, fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Tab Content ───────────────────────────────────────
  Widget _buildTabContent(dynamic p, Color accent) {
    switch (_tab) {
      case 0: return _buildReasoningTab(p, accent);
      case 1: return _buildMemoryTab(p, accent);
      case 2: return _buildAgentTab(p, accent);
      case 3: return _buildProtocolTab(p, accent);
      default: return const SizedBox();
    }
  }

  // ── Reasoning Tab ─────────────────────────────────────
  Widget _buildReasoningTab(dynamic p, Color accent) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: _chains.map((chain) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(chain.id,
                      style: GoogleFonts.spaceMono(color: accent, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(chain.title,
                      style: GoogleFonts.rajdhani(
                        color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  Text('${(chain.confidence * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.rajdhani(
                      color: const Color(0xFF00E676), fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              // Step chain
              Row(
                children: chain.steps.asMap().entries.map((e) {
                  final done = e.key < chain.currentStep;
                  final current = e.key == chain.currentStep;
                  final color = done
                      ? const Color(0xFF00E676)
                      : current ? accent : p.textSecondary.withValues(alpha: 0.3);
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(children: [
                            Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withValues(alpha: 0.15),
                                border: Border.all(color: color, width: current ? 2 : 1),
                              ),
                              child: done
                                  ? const Icon(Icons.check, size: 10, color: Color(0xFF00E676))
                                  : current
                                      ? Container(
                                          width: 6, height: 6, margin: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                                        )
                                      : null,
                            ),
                            const SizedBox(height: 3),
                            Text(e.value,
                              style: GoogleFonts.inter(color: color, fontSize: 6),
                              textAlign: TextAlign.center, maxLines: 2),
                          ]),
                        ),
                        if (e.key < chain.steps.length - 1)
                          Container(
                            width: 8, height: 1,
                            color: done ? const Color(0xFF00E676).withValues(alpha: 0.4) : p.surfaceVariant,
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF00E676), size: 12),
                  const SizedBox(width: 6),
                  Text('ERGEBNIS: ${chain.result}',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF00E676), fontSize: 9, fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Memory Tab ────────────────────────────────────────
  Widget _buildMemoryTab(dynamic p, Color accent) {
    final typeColors = {
      MemoryType.market: const Color(0xFF00E676),
      MemoryType.pattern: const Color(0xFF2979FF),
      MemoryType.anomaly: const Color(0xFFFF1744),
      MemoryType.macro: const Color(0xFFFF9100),
      MemoryType.technical: accent,
      MemoryType.portfolio: const Color(0xFF7B00D4),
      MemoryType.system: Colors.grey,
    };
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: [
        // Memory stats
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('KNOTEN', _memory.length.toString(), accent, p),
              _miniStat('AKTIV', '${_memory.where((m) => m.confidence > 0.85).length}', const Color(0xFF00E676), p),
              _miniStat('CLUSTER', '${MemoryType.values.length}', const Color(0xFF7B00D4), p),
              _miniStat('RETENTION', '99.9%', const Color(0xFFFF9100), p),
            ],
          ),
        ),
        ..._memory.map((node) {
          final color = typeColors[node.type] ?? p.primary;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border(left: BorderSide(color: color, width: 3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(node.type.name.toUpperCase(),
                            style: GoogleFonts.spaceMono(color: color, fontSize: 7, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                        Text(node.id,
                          style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7)),
                      ]),
                      const SizedBox(height: 4),
                      Text(node.content,
                        style: GoogleFonts.inter(color: p.textPrimary, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text('${(node.confidence * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.rajdhani(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('VERTR.', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7)),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _miniStat(String l, String v, Color c, dynamic p) => Column(children: [
    Text(v, style: GoogleFonts.rajdhani(color: c, fontSize: 16, fontWeight: FontWeight.bold)),
    Text(l, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7)),
  ]);

  // ── Agent Tab ─────────────────────────────────────────
  Widget _buildAgentTab(dynamic p, Color accent) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: _agents.map((agent) {
        final loadColor = agent.load > 0.9
            ? const Color(0xFF00E676)
            : agent.load > 0.7
                ? const Color(0xFFFF9100)
                : const Color(0xFFFF1744);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.1),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                  boxShadow: [BoxShadow(
                    color: accent.withValues(alpha: _tr2Running ? 0.3 : 0.1),
                    blurRadius: 10,
                  )],
                ),
                child: Icon(agent.icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(agent.name,
                      style: GoogleFonts.spaceMono(
                        color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: agent.load,
                        minHeight: 4,
                        backgroundColor: p.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(loadColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text('${(agent.load * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.rajdhani(
                      color: loadColor, fontSize: 14, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(agent.status,
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFF00E676), fontSize: 7, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Protocol Tab ──────────────────────────────────────
  Widget _buildProtocolTab(dynamic p, Color accent) {
    if (_thinkLogs.isEmpty) {
      return Center(
        child: Text('Keine Protokolleinträge – TR2 starten',
          style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 11)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _thinkLogs.length,
      itemBuilder: (_, i) {
        final log = _thinkLogs[i];
        final typeColors = {
          ThinkLogType.meta: const Color(0xFF7B00D4),
          ThinkLogType.memory: const Color(0xFF2979FF),
          ThinkLogType.genius: accent,
          ThinkLogType.oracle: const Color(0xFFFF9100),
          ThinkLogType.loop: const Color(0xFF00E676),
          ThinkLogType.command: Colors.grey,
        };
        final color = typeColors[log.type] ?? p.primary;
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: color, width: 2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(log.thought,
                  style: GoogleFonts.robotoMono(
                    color: log.type == ThinkLogType.command ? const Color(0xFF00E676) : p.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${log.timestamp.hour.toString().padLeft(2,'0')}:${log.timestamp.minute.toString().padLeft(2,'0')}:${log.timestamp.second.toString().padLeft(2,'0')}',
                style: GoogleFonts.spaceMono(color: p.textSecondary.withValues(alpha: 0.4), fontSize: 7),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Command Input ─────────────────────────────────────
  Widget _buildCommandInput(dynamic p, Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: accent.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          Text('> ', style: GoogleFonts.spaceMono(color: accent, fontSize: 14, fontWeight: FontWeight.bold)),
          Expanded(
            child: TextField(
              controller: _commandCtrl,
              style: GoogleFonts.robotoMono(color: const Color(0xFF00E676), fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Befehl eingeben (analyze / think / remember / predict)...',
                hintStyle: GoogleFonts.robotoMono(color: p.textSecondary.withValues(alpha: 0.4), fontSize: 10),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: _processCommand,
            ),
          ),
          GestureDetector(
            onTap: () => _processCommand(_commandCtrl.text),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.send, color: accent, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data Models ───────────────────────────────────────
enum MemoryType { market, pattern, anomaly, macro, technical, portfolio, system }
enum ThinkLogType { meta, memory, genius, oracle, loop, command }

class MemoryNode {
  final String id, content;
  final MemoryType type;
  final double confidence;
  final DateTime timestamp;
  MemoryNode(this.id, this.content, this.type, this.confidence, this.timestamp);
}

class ThinkingLog {
  final String thought;
  final DateTime timestamp;
  final int depth;
  final ThinkLogType type;
  ThinkingLog({required this.thought, required this.timestamp, required this.depth, required this.type});
}

class ReasoningChain {
  final String id, title, result;
  final List<String> steps;
  final int currentStep;
  final double confidence;
  ReasoningChain({
    required this.id, required this.title, required this.steps,
    required this.currentStep, required this.confidence, required this.result,
  });
}

class AgentModule {
  final String name, status;
  final IconData icon;
  double load;
  AgentModule(this.name, this.icon, this.status, this.load);
}
