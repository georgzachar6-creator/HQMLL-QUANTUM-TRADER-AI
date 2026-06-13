/// HQMLL Quantum Trader — QML Research Screen v48.0
/// TimeCrystal Deep Reasoning: 6 Tabs
///   TAB 1 — PIPELINE      : Deep Reasoning Full Pipeline (NEU v48)
///   TAB 2 — DATA LAB      : Floquet-Experimente + Zeitreihen-Visualisierung
///   TAB 3 — MODEL TRAINER : QML / Deep Learning Training + Metriken
///   TAB 4 — SYMBOLIC AI   : Symbolische Regression + Theorembeweise
///   TAB 5 — EXPERIMENT AI : Adaptive Experiment-Designer (RL-Agent)
///   TAB 6 — TRADING BRIDGE: TimeCrystal → Market Intelligence
/// Grigori Saks · 2025
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/time_crystal_service.dart';
import '../services/persistence_service.dart';
import '../services/auto_save_service.dart';
import '../services/trading_signal_service.dart';
import '../theme/app_themes.dart';

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class QMLResearchScreen extends StatefulWidget {
  const QMLResearchScreen({super.key});
  @override
  State<QMLResearchScreen> createState() => _QMLResearchScreenState();
}

class _QMLResearchScreenState extends State<QMLResearchScreen>
    with TickerProviderStateMixin {

  late TabController  _tabCtrl;
  // Pipeline state
  TCPlatform  _pipePlatform = TCPlatform.nvCenter;
  TCModelType _pipeModel    = TCModelType.pennylane;
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;

  // Experiment parameters (Data Lab)
  TCPlatform _selPlatform   = TCPlatform.nvCenter;
  double     _driveAmp      = 0.785;
  double     _disorderW     = 0.3;
  int        _systemSize    = 10;
  int        _floquetCycles = 200;

  // Model trainer
  TCModelType _selModel = TCModelType.lstm;
  int         _epochs   = 50;

  // Hypothesis input
  final TextEditingController _hypCtrl = TextEditingController();
  final ScrollController _logScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabCtrl   = TabController(length: 6, vsync: this);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _waveCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final tc = context.read<TimeCrystalService>();
      final ps = context.read<PersistenceService>();
      await tc.initialize();
      ps.addSystemLog('QML', 'QML Research Screen geladen — ${tc.totalExperiments} Experimente',
          level: SysLogLevel.quantum);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _hypCtrl.dispose();
    _logScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp  = context.watch<ThemeProvider>();
    final p   = tp.palette;
    final tc  = context.watch<TimeCrystalService>();
    final tss = context.watch<TradingSignalService>();

    return Column(children: [
      // ── Header ─────────────────────────────────────────────
      _buildHeader(p, tc),
      // ── Stats Row ──────────────────────────────────────────
      _buildStatsRow(p, tc),
      // ── TabBar ─────────────────────────────────────────────
      _buildTabBar(p),
      // ── Tab Content ────────────────────────────────────────
      Expanded(
        child: TabBarView(
          controller: _tabCtrl,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildDeepReasoningPipeline(p, tc),
            _buildDataLab(p, tc),
            _buildModelTrainer(p, tc),
            _buildSymbolicAI(p, tc),
            _buildExperimentDesigner(p, tc),
            _buildTradingBridge(p, tc, tss),
          ],
        ),
      ),
    ]);
  }

  // ══════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════
  Widget _buildHeader(QuantumPalette p, TimeCrystalService tc) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final glow = 0.6 + _pulseCtrl.value * 0.4;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [p.surface, const Color(0xFF0A0020), p.surface],
            ),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF9945FF).withValues(alpha: glow),
                  const Color(0xFF14F195).withValues(alpha: glow * 0.4),
                ]),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF9945FF).withValues(alpha: glow * 0.6),
                  blurRadius: 16, spreadRadius: 2,
                )],
              ),
              child: const Icon(Icons.science_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ZEITKRISTALL DEEP REASONING',
                  style: GoogleFonts.rajdhani(
                    color: const Color(0xFF9945FF), fontSize: 14,
                    fontWeight: FontWeight.w700, letterSpacing: 2,
                  )),
                Text('QML · Symbolische KI · Adaptive Experimente · Trading Bridge',
                  style: GoogleFonts.rajdhani(
                    color: p.textSecondary, fontSize: 10,
                  )),
              ],
            )),
            // Status indicator
            if (tc.isSimulating || tc.isTraining || tc.isSymbolicRunning)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF9945FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF9945FF).withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  SizedBox(
                    width: 10, height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: const Color(0xFF14F195),
                      value: tc.isSimulating ? tc.simulationProgress
                           : tc.isTraining   ? tc.trainingProgress
                           : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tc.isSimulating ? 'SIMULIERE'
                    : tc.isTraining ? 'TRAINING'
                    : 'SYMBOLIK',
                    style: GoogleFonts.rajdhani(
                      color: const Color(0xFF14F195), fontSize: 9, fontWeight: FontWeight.w700,
                    )),
                ]),
              ),
          ]),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  // STATS ROW
  // ══════════════════════════════════════════════════════════
  Widget _buildStatsRow(QuantumPalette p, TimeCrystalService tc) {
    final insights = tc.getTradingInsights();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(children: [
        _statChip(p, '${tc.totalExperiments}', 'EXP', const Color(0xFF00F0FF)),
        const SizedBox(width: 6),
        _statChip(p, '${tc.dtcCount}', 'DTC', const Color(0xFF14F195)),
        const SizedBox(width: 6),
        _statChip(p, '${(tc.avgDtcOrder * 100).toStringAsFixed(0)}%', 'ORDER', const Color(0xFFF7931A)),
        const SizedBox(width: 6),
        _statChip(p, '${(tc.bestAccuracy * 100).toStringAsFixed(0)}%', 'ACC', const Color(0xFF9945FF)),
        const SizedBox(width: 6),
        _statChip(p, '${tc.hypotheses.length}', 'HYP', const Color(0xFFFF6B35)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF14F195).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF14F195).withValues(alpha: 0.3)),
          ),
          child: Text(
            insights['regimeInsight'] as String? ?? '',
            style: GoogleFonts.rajdhani(color: const Color(0xFF14F195), fontSize: 9),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }

  Widget _statChip(QuantumPalette p, String val, String lbl, Color c) {
    return Column(children: [
      Text(val, style: GoogleFonts.rajdhani(color: c, fontSize: 13, fontWeight: FontWeight.w700)),
      Text(lbl, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
    ]);
  }

  // ══════════════════════════════════════════════════════════
  // TABBAR
  // ══════════════════════════════════════════════════════════
  Widget _buildTabBar(QuantumPalette p) {
    final tabs = [
      (Icons.account_tree_outlined,  'PIPELINE'),
      (Icons.biotech_outlined,       'DATA LAB'),
      (Icons.psychology_outlined,    'MODEL'),
      (Icons.functions_outlined,     'SYMBOLIK'),
      (Icons.explore_outlined,       'EXP. AI'),
      (Icons.candlestick_chart,      'TRADING'),
    ];
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.surfaceVariant, width: 1)),
      ),
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        padding: EdgeInsets.zero,
        tabAlignment: TabAlignment.start,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        indicatorColor: const Color(0xFF9945FF),
        labelColor: const Color(0xFF9945FF),
        unselectedLabelColor: p.textSecondary,
        indicatorWeight: 2,
        tabs: tabs.map((t) => Tab(
          height: 42,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(t.$1, size: 14),
            const SizedBox(width: 4),
            Text(t.$2, style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        )).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 1 — DEEP REASONING PIPELINE v48
  // ══════════════════════════════════════════════════════════
  Widget _buildDeepReasoningPipeline(QuantumPalette p, TimeCrystalService tc) {
    final run    = tc.currentPipelineRun;
    final isRunning = tc.isPipelineRunning;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Intro Banner ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF9945FF).withValues(alpha: 0.12),
                const Color(0xFF14F195).withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF9945FF).withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [Color(0xFF9945FF), Color(0xFF14F195)]),
              ),
              child: const Icon(Icons.account_tree_outlined, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('DEEP REASONING PIPELINE v48',
                style: GoogleFonts.rajdhani(
                  color: const Color(0xFF9945FF), fontSize: 13,
                  fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              Text(
                'Vollautomatischer 7-Stufen-Workflow: Datenerfassung → KI → Symbolik → Hypothesen → Adaptive Experimente → Trading',
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9.5),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
            ])),
            if (tc.pipelineRunCount > 0)
              Column(children: [
                Text('${tc.pipelineRunCount}',
                  style: GoogleFonts.rajdhani(color: const Color(0xFF14F195), fontSize: 18, fontWeight: FontWeight.w800)),
                Text('RUNS', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
              ]),
          ]),
        ),

        const SizedBox(height: 14),

        // ── Konfiguration ─────────────────────────────────────
        _sectionHeader(p, 'PIPELINE-KONFIGURATION', Icons.settings_outlined),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Plattform', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, children: TCPlatform.values.map((pl) {
              final sel = _pipePlatform == pl;
              return GestureDetector(
                onTap: () => setState(() => _pipePlatform = pl),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF9945FF).withValues(alpha: 0.2) : p.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: sel ? const Color(0xFF9945FF) : p.surfaceVariant),
                  ),
                  child: Text(pl.short, style: GoogleFonts.rajdhani(
                    color: sel ? const Color(0xFF9945FF) : p.textSecondary,
                    fontWeight: FontWeight.w700, fontSize: 10)),
                ),
              );
            }).toList()),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DL-Modell', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, children: [
              TCModelType.pennylane, TCModelType.lstm, TCModelType.tfq, TCModelType.cnn,
            ].map((m) {
              final sel = _pipeModel == m;
              final isQml = m == TCModelType.pennylane || m == TCModelType.tfq;
              return GestureDetector(
                onTap: () => setState(() => _pipeModel = m),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel ? (isQml ? const Color(0xFF9945FF) : const Color(0xFF627EEA)).withValues(alpha: 0.2) : p.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: sel ? (isQml ? const Color(0xFF9945FF) : const Color(0xFF627EEA)) : p.surfaceVariant),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(m.name.toUpperCase(), style: GoogleFonts.rajdhani(
                      color: sel ? (isQml ? const Color(0xFF9945FF) : const Color(0xFF627EEA)) : p.textSecondary,
                      fontWeight: FontWeight.w700, fontSize: 9)),
                    if (isQml) ...[
                      const SizedBox(width: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9945FF).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text('Q', style: GoogleFonts.rajdhani(
                          color: const Color(0xFF9945FF), fontSize: 7, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ]),
                ),
              );
            }).toList()),
          ])),
        ]),

        const SizedBox(height: 14),

        // ── Start Button ──────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final glow = 0.6 + _pulseCtrl.value * 0.4;
              return ElevatedButton.icon(
                onPressed: isRunning ? null : () => _runPipeline(tc),
                icon: isRunning
                    ? SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF14F195),
                          value: run?.overallProgress,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(
                  isRunning
                      ? 'PIPELINE LÄUFT... ${run != null ? "${(run.overallProgress * 100).toStringAsFixed(0)}%" : ""}'
                      : 'DEEP REASONING PIPELINE STARTEN',
                  style: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRunning
                      ? const Color(0xFF9945FF).withValues(alpha: 0.4)
                      : const Color(0xFF9945FF).withValues(alpha: 0.8 + glow * 0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: isRunning ? 0 : 4,
                  shadowColor: const Color(0xFF9945FF).withValues(alpha: 0.5),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // ── Pipeline-Stufen Visualizer ────────────────────────
        _sectionHeader(p, '7-STUFEN PIPELINE', Icons.account_tree_outlined),
        const SizedBox(height: 8),
        ...DRPipelineStage.values.map((stage) =>
          _buildPipelineStageCard(p, tc, stage, run)),

        const SizedBox(height: 16),

        // ── Trading Features (wenn Pipeline gelaufen) ─────────
        if (tc.tradingFeatures.isNotEmpty) ...[
          _sectionHeader(p, 'QUANTEN-TRADING-FEATURES', Icons.insights_outlined),
          const SizedBox(height: 8),
          ...tc.tradingFeatures.map((f) => _buildTradingFeatureCard(p, f)),
          const SizedBox(height: 16),
        ],

        // ── Pipeline History ───────────────────────────────────
        if (tc.pipelineHistory.isNotEmpty) ...[
          _sectionHeader(p, 'PIPELINE-HISTORY', Icons.history_outlined),
          const SizedBox(height: 8),
          ...tc.pipelineHistory.take(3).map((r) => _buildPipelineHistoryCard(p, r)),
        ],

        const SizedBox(height: 16),

        // ── Research-Log ──────────────────────────────────────
        _sectionHeader(p, 'DEEP REASONING LOG', Icons.terminal_outlined),
        const SizedBox(height: 8),
        Container(
          height: 160,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.surfaceVariant),
          ),
          child: ListView.builder(
            controller: _logScroll,
            reverse: false,
            itemCount: tc.log.length.clamp(0, 30),
            itemBuilder: (_, i) {
              final line = tc.log[i];
              final color = line.contains('✅') || line.contains('✓')
                  ? const Color(0xFF14F195)
                  : line.contains('⚠') || line.contains('ERROR')
                  ? const Color(0xFFFF4444)
                  : line.contains('⟨ψ⟩') || line.contains('🔬')
                  ? const Color(0xFF9945FF)
                  : line.contains('📡') || line.contains('🧠') || line.contains('📈')
                  ? const Color(0xFF00F0FF)
                  : p.textSecondary;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(line,
                  style: GoogleFonts.robotoMono(color: color, fontSize: 9),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildPipelineStageCard(
    QuantumPalette p,
    TimeCrystalService tc,
    DRPipelineStage stage,
    DRPipelineRun? run,
  ) {
    final status   = run?.stageStatus[stage] ?? DRStageStatus.idle;
    final progress = run?.stageProgress[stage] ?? 0.0;
    final output   = run?.stageOutput[stage];
    final isCurrent = tc.currentStage == stage && tc.isPipelineRunning;

    Color stageColor;
    IconData stageIcon;
    switch (status) {
      case DRStageStatus.completed:
        stageColor = const Color(0xFF14F195);
        stageIcon  = Icons.check_circle_outline;
        break;
      case DRStageStatus.running:
        stageColor = const Color(0xFFF7931A);
        stageIcon  = Icons.sync_outlined;
        break;
      case DRStageStatus.failed:
        stageColor = const Color(0xFFFF4444);
        stageIcon  = Icons.error_outline;
        break;
      default:
        stageColor = p.textSecondary.withValues(alpha: 0.5);
        stageIcon  = Icons.radio_button_unchecked;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFFF7931A).withValues(alpha: 0.06)
            : status == DRStageStatus.completed
            ? const Color(0xFF14F195).withValues(alpha: 0.04)
            : p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFFF7931A).withValues(alpha: 0.5)
              : status == DRStageStatus.completed
              ? const Color(0xFF14F195).withValues(alpha: 0.3)
              : p.surfaceVariant,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          dense: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          leading: SizedBox(
            width: 28, height: 28,
            child: status == DRStageStatus.running
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    color: stageColor,
                    value: progress > 0 ? progress : null,
                  )
                : Icon(stageIcon, color: stageColor, size: 20),
          ),
          title: Row(children: [
            Text(stage.icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Expanded(child: Text(stage.label,
              style: GoogleFonts.rajdhani(
                color: status == DRStageStatus.idle ? p.textSecondary : p.textPrimary,
                fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5))),
          ]),
          subtitle: status == DRStageStatus.running
              ? LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  backgroundColor: p.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation(stageColor),
                  minHeight: 2,
                )
              : null,
          trailing: status == DRStageStatus.completed
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14F195).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('✓ OK', style: GoogleFonts.rajdhani(
                    color: const Color(0xFF14F195), fontSize: 9, fontWeight: FontWeight.w700)),
                )
              : null,
          children: [
            // Description
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Framework: ', style: GoogleFonts.rajdhani(
                    color: p.textSecondary, fontSize: 9)),
                  Text(stage.framework, style: GoogleFonts.rajdhani(
                    color: const Color(0xFF00F0FF), fontSize: 9, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 4),
                Text(stage.description, style: GoogleFonts.rajdhani(
                  color: p.textSecondary, fontSize: 9.5)),
                if (output != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: stageColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: stageColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(output, style: GoogleFonts.robotoMono(
                      color: stageColor, fontSize: 8.5)),
                  ),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradingFeatureCard(QuantumPalette p, DRTradingFeature f) {
    final phaseColor = _phaseColor(f.sourcePhase);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.surfaceVariant),
      ),
      child: Row(children: [
        // Value gauge
        SizedBox(
          width: 44, height: 44,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: f.value.clamp(0.0, 1.0),
              backgroundColor: p.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(phaseColor),
              strokeWidth: 4,
            ),
            Text('${(f.value * 100).toStringAsFixed(0)}',
              style: GoogleFonts.rajdhani(
                color: phaseColor, fontSize: 10, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.name, style: GoogleFonts.rajdhani(
            color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(f.description, style: GoogleFonts.rajdhani(
            color: p.textSecondary, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: phaseColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(f.tradingImplication, style: GoogleFonts.rajdhani(
              color: phaseColor, fontSize: 9, fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${(f.confidence * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.rajdhani(
              color: const Color(0xFF14F195), fontSize: 13, fontWeight: FontWeight.w800)),
          Text('KONFIDENZ', style: GoogleFonts.rajdhani(
            color: p.textSecondary, fontSize: 7)),
        ]),
      ]),
    );
  }

  Widget _buildPipelineHistoryCard(QuantumPalette p, DRPipelineRun run) {
    final completed = run.completedAt != null
        ? run.completedAt!.difference(run.startedAt).inSeconds
        : null;
    final completedStages = run.stageStatus.values
        .where((s) => s == DRStageStatus.completed).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: run.isCompleted
            ? const Color(0xFF14F195).withValues(alpha: 0.25)
            : p.surfaceVariant),
      ),
      child: Row(children: [
        Icon(
          run.isCompleted ? Icons.check_circle_outline : Icons.error_outline,
          color: run.isCompleted ? const Color(0xFF14F195) : const Color(0xFFFF4444),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(run.id, style: GoogleFonts.robotoMono(
            color: p.textSecondary, fontSize: 8)),
          Text(
            '${run.startedAt.hour.toString().padLeft(2,"0")}:'
            '${run.startedAt.minute.toString().padLeft(2,"0")} — '
            '$completedStages/${DRPipelineStage.values.length} Stufen',
            style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 10)),
        ])),
        if (completed != null)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${completed}s', style: GoogleFonts.rajdhani(
              color: const Color(0xFF00F0FF), fontSize: 12, fontWeight: FontWeight.w700)),
            Text('DAUER', style: GoogleFonts.rajdhani(
              color: p.textSecondary, fontSize: 7)),
          ]),
      ]),
    );
  }

  // Actions
  Future<void> _runPipeline(TimeCrystalService tc) async {
    HapticFeedback.mediumImpact();
    try {
      await tc.runDeepReasoningPipeline(
        platform:  _pipePlatform,
        modelType: _pipeModel,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Deep Reasoning Pipeline abgeschlossen!',
            style: GoogleFonts.rajdhani(color: Colors.white)),
          backgroundColor: const Color(0xFF14F195).withValues(alpha: 0.8),
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('⚠ Pipeline-Fehler: $e',
            style: GoogleFonts.rajdhani(color: Colors.white)),
          backgroundColor: const Color(0xFFFF4444).withValues(alpha: 0.8),
        ));
      }
    }
  }

  // ══════════════════════════════════════════════════════════
  // TAB 2 — DATA LAB
  // ══════════════════════════════════════════════════════════
  Widget _buildDataLab(QuantumPalette p, TimeCrystalService tc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Platform selector
        _sectionHeader(p, 'EXPERIMENTELLE PLATTFORM', Icons.device_hub_outlined),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: TCPlatform.values.map((plat) {
          final sel = _selPlatform == plat;
          return GestureDetector(
            onTap: () => setState(() => _selPlatform = plat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF9945FF).withValues(alpha: 0.2) : p.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: sel ? const Color(0xFF9945FF) : p.surfaceVariant, width: 1),
              ),
              child: Column(children: [
                Text(plat.short,
                  style: GoogleFonts.rajdhani(
                    color: sel ? const Color(0xFF9945FF) : p.textPrimary,
                    fontWeight: FontWeight.w700, fontSize: 13,
                  )),
                Text(plat.label,
                  style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
              ]),
            ),
          );
        }).toList()),

        const SizedBox(height: 16),
        // Parameter sliders
        _sectionHeader(p, 'FLOQUET-PARAMETER', Icons.tune_outlined),
        const SizedBox(height: 8),
        _buildParamCard(p, [
          _buildSlider(p, 'Drive-Amplitude Ω', _driveAmp, 0.1, 2.0, '${_driveAmp.toStringAsFixed(3)} rad/µs',
              (v) => setState(() => _driveAmp = v), const Color(0xFF00F0FF)),
          _buildSlider(p, 'Unordnung W', _disorderW, 0.0, 1.0, _disorderW.toStringAsFixed(2),
              (v) => setState(() => _disorderW = v), const Color(0xFF14F195)),
          _buildSlider(p, 'Systemgröße N', _systemSize.toDouble(), 4, 20, '$_systemSize Spins',
              (v) => setState(() => _systemSize = v.round()), const Color(0xFFF7931A)),
          _buildSlider(p, 'Floquet-Zyklen', _floquetCycles.toDouble(), 50, 500, '$_floquetCycles',
              (v) => setState(() => _floquetCycles = v.round()), const Color(0xFF9945FF)),
        ]),

        const SizedBox(height: 12),
        // Phase prediction badge
        _buildPhasePredictionBadge(p),

        const SizedBox(height: 12),
        // Phase Diagram
        _sectionHeader(p, 'FLOQUET-PHASENDIAGRAMM', Icons.scatter_plot_outlined),
        const SizedBox(height: 8),
        _buildPhaseDiagram(p, tc),

        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: tc.isSimulating ? null : () => _runExperiment(tc),
            icon: tc.isSimulating
                ? SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 1.5,
                      color: const Color(0xFF14F195),
                      value: tc.simulationProgress))
                : const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(
              tc.isSimulating
                  ? 'SIMULIERE... ${(tc.simulationProgress * 100).toStringAsFixed(0)}%'
                  : 'FLOQUET-SIMULATION STARTEN',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9945FF).withValues(alpha: 0.8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),

        const SizedBox(height: 16),
        // Experiment list
        _sectionHeader(p, 'EXPERIMENT-ARCHIV', Icons.history_outlined),
        const SizedBox(height: 8),
        ...tc.experiments.take(6).map((exp) => _buildExperimentCard(p, exp)),
      ]),
    );
  }

  Widget _buildPhasePredictionBadge(QuantumPalette p) {
    final isDtc  = _disorderW > 0.1 && _driveAmp > 0.5 && _driveAmp < 1.4;
    final isMbl  = _disorderW > 0.6;
    final isChaos = _driveAmp > 1.5;
    final phase  = isDtc ? TCPhase.dtcOrdered
                 : isMbl ? TCPhase.mbl
                 : isChaos ? TCPhase.chaotic
                 : TCPhase.trivial;
    final color = const {
      TCPhase.dtcOrdered: Color(0xFF14F195),
      TCPhase.mbl:        Color(0xFFF7931A),
      TCPhase.chaotic:    Color(0xFFFF4444),
      TCPhase.trivial:    Color(0xFF627EEA),
      TCPhase.unknown:    Color(0xFF888888),
    }[phase]!;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.auto_awesome, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VORHERGESAGTE PHASE: ${phase.label.toUpperCase()}',
              style: GoogleFonts.rajdhani(color: color, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1)),
            Text(_phaseDescription(phase),
              style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
          ],
        )),
      ]),
    );
  }

  String _phaseDescription(TCPhase phase) {
    switch (phase) {
      case TCPhase.dtcOrdered:
        return 'Zeitkristall-Ordnung aktiv — Sub-harmonische Oszillation erwartet';
      case TCPhase.mbl:
        return 'Many-Body-Lokalisierung — Thermalisierung verhindert';
      case TCPhase.chaotic:
        return 'Chaotisches Regime — Keine kohärente Oszillation';
      case TCPhase.trivial:
        return 'Triviale Phase — Normales Abkling-Verhalten';
      default:
        return 'Phase unbekannt — Parameterraum unerforschbar';
    }
  }

  Widget _buildExperimentCard(QuantumPalette p, TCExperiment exp) {
    final phaseColor = _phaseColor(exp.detectedPhase);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.surfaceVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: phaseColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: phaseColor.withValues(alpha: 0.4)),
            ),
            child: Text(exp.detectedPhase.label,
              style: GoogleFonts.rajdhani(color: phaseColor, fontSize: 9, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Text(exp.platform.short,
            style: GoogleFonts.rajdhani(color: const Color(0xFF9945FF), fontSize: 10, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${exp.floquetCycles} Zyklen',
            style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
        ]),
        const SizedBox(height: 4),
        Text(exp.label, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(children: [
          _expMetric(p, 'Ω', exp.driveAmplitude.toStringAsFixed(2), const Color(0xFF00F0FF)),
          const SizedBox(width: 12),
          _expMetric(p, 'W', exp.disorderW.toStringAsFixed(2), const Color(0xFF14F195)),
          const SizedBox(width: 12),
          _expMetric(p, 'DTC', '${(exp.dtcOrderParameter * 100).toStringAsFixed(0)}%', const Color(0xFFF7931A)),
          const SizedBox(width: 12),
          _expMetric(p, 'Kohärenz', '${(exp.coherenceScore * 100).toStringAsFixed(0)}%', const Color(0xFF9945FF)),
        ]),
        // Mini time series chart
        const SizedBox(height: 8),
        _buildMiniTimeSeries(p, exp, phaseColor),
      ]),
    );
  }

  Widget _expMetric(QuantumPalette p, String label, String value, Color c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
      Text(value, style: GoogleFonts.rajdhani(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _buildMiniTimeSeries(QuantumPalette p, TCExperiment exp, Color lineColor) {
    if (exp.data.isEmpty) return const SizedBox.shrink();
    final data = exp.data;
    final maxVal = 1.0;
    return SizedBox(
      height: 32,
      child: CustomPaint(
        size: const Size(double.infinity, 32),
        painter: _TimeSeriesPainter(data, lineColor, p),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 2 — MODEL TRAINER
  // ══════════════════════════════════════════════════════════
  Widget _buildModelTrainer(QuantumPalette p, TimeCrystalService tc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        _sectionHeader(p, 'MODELL AUSWÄHLEN', Icons.model_training_outlined),
        const SizedBox(height: 8),
        // Model grid
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3, childAspectRatio: 1.4,
          mainAxisSpacing: 8, crossAxisSpacing: 8,
          children: TCModelType.values.map((m) {
            final sel = _selModel == m;
            final info = _modelInfo(m);
            return GestureDetector(
              onTap: () => setState(() => _selModel = m),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sel ? info.$3.withValues(alpha: 0.15) : p.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? info.$3 : p.surfaceVariant, width: sel ? 1.5 : 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(info.$1, color: sel ? info.$3 : p.textSecondary, size: 20),
                    const SizedBox(height: 4),
                    Text(info.$2,
                      style: GoogleFonts.rajdhani(
                        color: sel ? info.$3 : p.textPrimary,
                        fontSize: 9, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    if (m == TCModelType.pennylane || m == TCModelType.tfq)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9945FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text('QML',
                          style: GoogleFonts.rajdhani(
                            color: const Color(0xFF9945FF), fontSize: 7, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 14),
        _sectionHeader(p, 'TRAININGS-PARAMETER', Icons.settings_outlined),
        const SizedBox(height: 8),
        _buildParamCard(p, [
          _buildSlider(p, 'Epochen', _epochs.toDouble(), 10, 200, '$_epochs',
              (v) => setState(() => _epochs = v.round()), const Color(0xFF627EEA)),
        ]),

        const SizedBox(height: 12),
        if (tc.isTraining) ...[
          LinearProgressIndicator(
            value: tc.trainingProgress,
            backgroundColor: p.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF9945FF)),
          ),
          const SizedBox(height: 8),
          Text('Training: ${(tc.trainingProgress * 100).toStringAsFixed(0)}% / Epoche ${
            (_epochs * tc.trainingProgress).round()}/$_epochs',
            style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
          const SizedBox(height: 12),
        ],

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: tc.isTraining ? null : () => _trainModel(tc),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text('MODELL TRAINIEREN',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF627EEA).withValues(alpha: 0.8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),

        const SizedBox(height: 16),
        // Results
        if (tc.modelResults.isNotEmpty) ...[
          _sectionHeader(p, 'TRAININGS-ERGEBNISSE', Icons.bar_chart_outlined),
          const SizedBox(height: 8),
          ...tc.modelResults.take(4).map((r) => _buildModelResultCard(p, r)),
        ],
      ]),
    );
  }

  Widget _buildModelResultCard(QuantumPalette p, TCModelResult r) {
    final info = _modelInfo(r.modelType);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.surfaceVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(info.$1, color: info.$3, size: 16),
          const SizedBox(width: 6),
          Text(info.$2, style: GoogleFonts.rajdhani(color: info.$3, fontWeight: FontWeight.w700, fontSize: 11)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (r.theoremValid ? const Color(0xFF14F195) : const Color(0xFFFF4444)).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(r.theoremValid ? 'THEOREM ✓' : 'THEOREM ✗',
              style: GoogleFonts.rajdhani(
                color: r.theoremValid ? const Color(0xFF14F195) : const Color(0xFFFF4444),
                fontSize: 8, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          _modelMetric(p, 'Accuracy', '${(r.accuracy * 100).toStringAsFixed(1)}%', const Color(0xFF14F195)),
          const SizedBox(width: 16),
          _modelMetric(p, 'Loss', r.loss.toStringAsFixed(4), const Color(0xFFF7931A)),
          const SizedBox(width: 16),
          _modelMetric(p, 'Epochen', '${r.epochs}', const Color(0xFF00F0FF)),
        ]),
        const SizedBox(height: 6),
        // Accuracy bar
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: r.accuracy,
            backgroundColor: p.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(info.$3),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 6),
        Text(r.hypothesis,
          style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9),
          maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _modelMetric(QuantumPalette p, String lbl, String val, Color c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(lbl, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
      Text(val, style: GoogleFonts.rajdhani(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
    ]);
  }

  // ══════════════════════════════════════════════════════════
  // TAB 3 — SYMBOLIC AI
  // ══════════════════════════════════════════════════════════
  Widget _buildSymbolicAI(QuantumPalette p, TimeCrystalService tc) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          _sectionHeader(p, 'SYMBOLISCHE REGRESSION + THEOREMBEWEISE', Icons.functions_outlined),
          const SizedBox(height: 8),

          // Run button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: tc.isSymbolicRunning ? null : () => _runSymbolic(tc),
              icon: tc.isSymbolicRunning
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                  : const Icon(Icons.functions, size: 18),
              label: Text(
                tc.isSymbolicRunning ? 'SYMBOLIK LÄUFT...' : 'SYMBOLISCHE ANALYSE STARTEN',
                style: GoogleFonts.rajdhani(fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35).withValues(alpha: 0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Add hypothesis
          Row(children: [
            Expanded(
              child: TextField(
                controller: _hypCtrl,
                style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 11),
                decoration: InputDecoration(
                  hintText: 'Neue Hypothese eingeben...',
                  hintStyle: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 11),
                  filled: true, fillColor: p.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: p.surfaceVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: p.surfaceVariant),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                tc.addManualHypothesis(_hypCtrl.text.trim());
                _hypCtrl.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9945FF).withValues(alpha: 0.6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('ADD', style: GoogleFonts.rajdhani(fontWeight: FontWeight.w700)),
            ),
          ]),
        ]),
      ),

      // Hypotheses list
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          itemCount: tc.hypotheses.length,
          itemBuilder: (context, i) {
            final h = tc.hypotheses[i];
            final isQml    = h.startsWith('QML') || h.contains('QML');
            final isSymbol = h.contains('SYMBOLIK');
            final isManual = h.contains('MANUELL');
            final color = isQml ? const Color(0xFF9945FF)
                        : isSymbol ? const Color(0xFFFF6B35)
                        : isManual ? const Color(0xFF14F195)
                        : const Color(0xFF00F0FF);
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(color: color, width: 3),
                  top: BorderSide(color: color.withValues(alpha: 0.2)),
                  right: BorderSide(color: color.withValues(alpha: 0.2)),
                  bottom: BorderSide(color: color.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  margin: const EdgeInsets.only(top: 1),
                  child: Text('${i + 1}.',
                    style: GoogleFonts.rajdhani(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(h,
                  style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 10))),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: h));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kopiert'), duration: Duration(seconds: 1)));
                  },
                  child: Icon(Icons.copy_outlined, size: 12, color: p.textSecondary),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  // ══════════════════════════════════════════════════════════
  // TAB 4 — EXPERIMENT DESIGNER (RL Agent)
  // ══════════════════════════════════════════════════════════
  Widget _buildExperimentDesigner(QuantumPalette p, TimeCrystalService tc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(p, 'ADAPTIVER EXPERIMENT-DESIGNER', Icons.explore_outlined),
        const SizedBox(height: 4),
        Text('RL-Agent schlägt optimale Parameter für maximalen Informationsgewinn vor',
          style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
        const SizedBox(height: 12),

        ...tc.suggestions.map((s) => _buildSuggestionCard(p, tc, s)),

        const SizedBox(height: 16),
        // Service log
        _sectionHeader(p, 'REASONING LOG', Icons.terminal_outlined),
        const SizedBox(height: 8),
        Container(
          height: 200,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF9945FF).withValues(alpha: 0.3)),
          ),
          child: ListView.builder(
            controller: _logScroll,
            reverse: true,
            itemCount: tc.log.length,
            itemBuilder: (context, i) {
              final log = tc.log[i];
              final isSuccess = log.contains('✓');
              final isWarning = log.contains('⚠');
              final isQuantum = log.contains('⟨ψ⟩');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(log,
                  style: GoogleFonts.robotoMono(
                    color: isQuantum ? const Color(0xFF9945FF)
                         : isSuccess ? const Color(0xFF14F195)
                         : isWarning ? const Color(0xFFF7931A)
                         : const Color(0xFF888888),
                    fontSize: 8,
                  )),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildSuggestionCard(QuantumPalette p, TimeCrystalService tc, TCExperimentSuggestion s) {
    final phaseColor = _phaseColor(s.targetPhase);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: phaseColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: phaseColor.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_fix_high, color: phaseColor, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(s.rationale,
            style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('+${s.expectedInfoGain.toStringAsFixed(1)} bits',
              style: GoogleFonts.rajdhani(
                color: const Color(0xFF00F0FF), fontSize: 9, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _suggChip(p, 'Ω', s.suggestedDrive.toStringAsFixed(2), phaseColor),
          const SizedBox(width: 8),
          _suggChip(p, 'W', s.suggestedDisorder.toStringAsFixed(2), phaseColor),
          const SizedBox(width: 8),
          _suggChip(p, 'N', '${s.suggestedSize}', phaseColor),
          const SizedBox(width: 8),
          _suggChip(p, 'Zyklen', '${s.suggestedCycles}', phaseColor),
          const Spacer(),
          // Stability bar
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Stabilität', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
            SizedBox(
              width: 60, height: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: s.stabilityEstimate,
                  backgroundColor: p.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation(phaseColor),
                ),
              ),
            ),
          ]),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: tc.isSimulating ? null : () {
              setState(() {
                _selPlatform   = TCPlatform.nvCenter;
                _driveAmp      = s.suggestedDrive;
                _disorderW     = s.suggestedDisorder;
                _systemSize    = s.suggestedSize;
                _floquetCycles = s.suggestedCycles;
              });
              _tabCtrl.animateTo(0);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: phaseColor,
              side: BorderSide(color: phaseColor.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('PARAMETER ÜBERNEHMEN → DATA LAB',
              style: GoogleFonts.rajdhani(fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _suggChip(QuantumPalette p, String lbl, String val, Color c) {
    return Column(children: [
      Text(lbl, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
      Text(val, style: GoogleFonts.rajdhani(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    ]);
  }

  // ══════════════════════════════════════════════════════════
  // TAB 5 — TRADING BRIDGE
  // ══════════════════════════════════════════════════════════
  Widget _buildTradingBridge(QuantumPalette p, TimeCrystalService tc, TradingSignalService tss) {
    final ins = tc.getTradingInsights();
    final dtcRate   = (ins['dtcStabilityRate'] as double) * 100;
    final avgOrder  = (ins['avgDtcOrder'] as double) * 100;
    final avgCoh    = (ins['avgCoherence'] as double) * 100;
    final bestAcc   = (ins['bestModelAccuracy'] as double) * 100;
    final isQAdv    = ins['quantumAdvantage'] as bool;
    final regime    = ins['regimeInsight'] as String;
    final topHyp    = ins['topHypothesis'] as String;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(p, 'QUANTUM → TRADING BRIDGE', Icons.candlestick_chart_outlined),
        const SizedBox(height: 4),
        Text('Zeitkristall-Erkenntnisse als Meta-Features für Handelsstrategien',
          style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
        const SizedBox(height: 12),

        // Regime insight card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF14F195).withValues(alpha: 0.08), const Color(0xFF9945FF).withValues(alpha: 0.08)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF14F195).withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.insights, color: Color(0xFF14F195), size: 18),
              const SizedBox(width: 8),
              Text('REGIME-ANALYSE', style: GoogleFonts.rajdhani(
                color: const Color(0xFF14F195), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ]),
            const SizedBox(height: 8),
            Text(regime,
              style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
            if (topHyp.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('⟨ψ⟩ $topHyp',
                style: GoogleFonts.rajdhani(color: const Color(0xFF9945FF), fontSize: 9),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),

        const SizedBox(height: 12),
        // 4-metric grid
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, childAspectRatio: 2.2,
          mainAxisSpacing: 8, crossAxisSpacing: 8,
          children: [
            _tradingMetricCard(p, 'DTC-Stabilität', '${dtcRate.toStringAsFixed(0)}%',
              'Experimente in DTC-Phase', const Color(0xFF14F195), dtcRate / 100),
            _tradingMetricCard(p, 'DTC-Ordnungsparameter', '${avgOrder.toStringAsFixed(0)}%',
              'Ø Sub-harm. Amplitude', const Color(0xFFF7931A), avgOrder / 100),
            _tradingMetricCard(p, 'Kohärenzqualität', '${avgCoh.toStringAsFixed(0)}%',
              'Ø Signalkohärenz', const Color(0xFF00F0FF), avgCoh / 100),
            _tradingMetricCard(p, 'Modell-Genauigkeit', '${bestAcc.toStringAsFixed(0)}%',
              isQAdv ? 'QML-Vorteil aktiv ⟨ψ⟩' : 'Klassisches Modell', const Color(0xFF9945FF), bestAcc / 100),
          ],
        ),

        const SizedBox(height: 16),
        _sectionHeader(p, 'STRATEGIE-MAPPING', Icons.compare_arrows_outlined),
        const SizedBox(height: 8),
        ..._buildStrategyMapping(p, dtcRate),

        const SizedBox(height: 16),
        _sectionHeader(p, 'FRAMEWORKS', Icons.code_outlined),
        const SizedBox(height: 8),
        _buildFrameworksGrid(p),

        const SizedBox(height: 16),
        // Emmy-GS Oracle integration hint
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF9945FF).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF9945FF).withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF9945FF), size: 16),
              const SizedBox(width: 8),
              Text('EMMY-G·S ORACLE INTEGRATION',
                style: GoogleFonts.rajdhani(color: const Color(0xFF9945FF),
                  fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ]),
            const SizedBox(height: 8),
            Text(
              'Quantum-Physics-Research Domain-Mode: '
              'TimeCrystal-Services ersetzen Market-Data-Services. '
              'Symbolische Hypothesen fließen als Meta-Features in Trading-Modelle ein. '
              'Regime-Erkennung basiert auf DTC/MBL-Phasenklassifikation.',
              style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: [
              _techBadge(p, 'PennyLane VQC', const Color(0xFF9945FF)),
              _techBadge(p, 'TFQ Keras', const Color(0xFF627EEA)),
              _techBadge(p, 'QuTiP Floquet', const Color(0xFF00F0FF)),
              _techBadge(p, 'AI-Descartes', const Color(0xFFFF6B35)),
              _techBadge(p, 'RL-Experiment', const Color(0xFF14F195)),
            ]),
          ]),
        ),

        const SizedBox(height: 16),
        // ── LIVE SIGNAL OUTPUT — v47 TradingSignalService ────
        _sectionHeader(p, 'LIVE SIGNAL OUTPUT v47', Icons.bolt_rounded),
        const SizedBox(height: 8),
        _buildLiveSignalPanel(p, tss),
      ]),
    );
  }

  // Live Signal Panel (nutzt TradingSignalService direkt)
  Widget _buildLiveSignalPanel(QuantumPalette p, TradingSignalService tss) {
    final signals = tss.activeSignals.take(6).toList();
    final m       = tss.metrics;

    return Column(children: [
      // Metrics Summary
      if (m != null)
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF14F195).withValues(alpha: 0.06), const Color(0xFF00F0FF).withValues(alpha: 0.06)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF14F195).withValues(alpha: 0.25)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _tsMetric(p, 'WIN RATE', '${(m.winRate * 100).toStringAsFixed(0)}%', const Color(0xFF14F195)),
            _tsMetric(p, 'SHARPE',  m.sharpe.toStringAsFixed(2),               const Color(0xFF00F0FF)),
            _tsMetric(p, 'SIGNALE', '${m.totalSignals}',                        const Color(0xFFF7931A)),
            _tsMetric(p, 'P&L 24H', m.pnl24h >= 0
              ? '+\$${m.pnl24h.toStringAsFixed(0)}'
              : '-\$${m.pnl24h.abs().toStringAsFixed(0)}',
              m.pnl24h >= 0 ? const Color(0xFF14F195) : const Color(0xFFFF3358)),
          ]),
        ),

      // Signal Cards
      ...signals.map((s) {
        final col = s.action.isBullish
          ? const Color(0xFF14F195)
          : s.action.isBearish
            ? const Color(0xFFFF3358)
            : const Color(0xFFFFD700);
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: col.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: col.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            // Action Badge
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: col.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(children: [
                Text(s.action.emoji, style: const TextStyle(fontSize: 14)),
                Text(s.action.label, style: GoogleFonts.spaceMono(color: col, fontSize: 6, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(s.pair, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                // TC Phase Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9945FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(s.tcPhase.label, style: GoogleFonts.rajdhani(
                    color: const Color(0xFF9945FF), fontSize: 7, fontWeight: FontWeight.w700)),
                ),
              ]),
              Text(s.reasoning, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              // Confidence bar
              Row(children: [
                Text('CONF ${(s.confidence * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.spaceMono(color: col, fontSize: 7)),
                const SizedBox(width: 6),
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: s.confidence,
                    backgroundColor: col.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(col),
                    minHeight: 3,
                  ),
                )),
                const SizedBox(width: 6),
                Text('R/R ${s.rr.toStringAsFixed(1)}',
                  style: GoogleFonts.spaceMono(color: const Color(0xFF9945FF), fontSize: 7)),
              ]),
            ])),
            const SizedBox(width: 8),
            // Price targets
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('IN:  \$${_tsFmt(s.entryPrice)}',
                style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7)),
              Text('TP:  \$${_tsFmt(s.targetPrice)}',
                style: GoogleFonts.spaceMono(color: const Color(0xFF14F195), fontSize: 7)),
              Text('SL:  \$${_tsFmt(s.stopLoss)}',
                style: GoogleFonts.spaceMono(color: const Color(0xFFFF3358), fontSize: 7)),
              const SizedBox(height: 2),
              Text(s.ageLabel,
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 7)),
            ]),
          ]),
        );
      }),

      // Signal Log (letzte 5 Einträge)
      if (tss.signalLog.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: p.surfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SIGNAL LOG', style: GoogleFonts.spaceMono(
                color: p.textSecondary, fontSize: 8, letterSpacing: 1)),
              const SizedBox(height: 6),
              ...tss.signalLog.take(4).map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(log,
                  style: GoogleFonts.spaceMono(
                    color: log.contains('✅')
                      ? const Color(0xFF14F195).withValues(alpha: 0.7)
                      : p.textSecondary,
                    fontSize: 7),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
            ],
          ),
        ),
      ],
    ]);
  }

  Widget _tsMetric(QuantumPalette p, String label, String value, Color c) {
    return Column(children: [
      Text(value, style: GoogleFonts.spaceMono(color: c, fontSize: 11, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 7)),
    ]);
  }

  String _tsFmt(double price) {
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(1)}K';
    if (price >= 1)    return price.toStringAsFixed(2);
    return price.toStringAsFixed(4);
  }

  List<Widget> _buildStrategyMapping(QuantumPalette p, double dtcRate) {
    final mappings = [
      ('DTC-Ordered (η > 0.6)', 'Trend-Following / Momentum-Strategie',
       'Sub-harmonische Stabilität → persistente Trenddynamik', const Color(0xFF14F195)),
      ('MBL-Regime (W > 0.6)', 'Mean-Reversion / Arbitrage',
       'Lokalisierung → keine thermische Dispersion → Rückkehr zum Mittel', const Color(0xFFF7931A)),
      ('Chaotisches Regime', 'Market-Neutral / Delta-Hedging',
       'Keine Vorhersagbarkeit → Delta-neutrales Portfolio schützt vor Verlusten', const Color(0xFFFF4444)),
      ('Floquet-Übergang', 'Regime-Switch-Detektion',
       'Phasengrenze ↔ Marktregimewechsel → Positions-Adjustment Signal', const Color(0xFF00F0FF)),
    ];
    return mappings.map((m) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: m.$4.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: m.$4.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(width: 3, height: 40, color: m.$4,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.$1, style: GoogleFonts.rajdhani(color: m.$4, fontSize: 10, fontWeight: FontWeight.w700)),
          Text(m.$2, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          Text(m.$3, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
        ])),
      ]),
    )).toList();
  }

  Widget _buildFrameworksGrid(QuantumPalette p) {
    final fw = [
      ('PennyLane', 'VQC + Auto-Diff', const Color(0xFF9945FF), 'pennylane.ai'),
      ('TFQ',       'Keras QML Layer', const Color(0xFF627EEA), 'tensorflow.org'),
      ('QuTiP',     'Floquet Sim.',    const Color(0xFF00F0FF), 'qutip.org'),
      ('AI-Desc.',  'Symb. Regression', const Color(0xFFFF6B35), 'ai-descartes'),
    ];
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, childAspectRatio: 2.8,
      mainAxisSpacing: 6, crossAxisSpacing: 6,
      children: fw.map((f) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: f.$3.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: f.$3.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(Icons.code, color: f.$3, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(f.$1, style: GoogleFonts.rajdhani(color: f.$3, fontWeight: FontWeight.w700, fontSize: 11)),
              Text(f.$2, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
            ])),
        ]),
      )).toList(),
    );
  }

  Widget _tradingMetricCard(QuantumPalette p, String title, String value, String sub, Color c, double progress) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Text(title, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
          const Spacer(),
          Text(value, style: GoogleFonts.rajdhani(color: c, fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
        Text(sub, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8),
          overflow: TextOverflow.ellipsis),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: p.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(c),
            minHeight: 3,
          ),
        ),
      ]),
    );
  }

  Widget _techBadge(QuantumPalette p, String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text(label,
        style: GoogleFonts.rajdhani(color: c, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PHASE DIAGRAM — Floquet Parameter Space Visualizer
  // ══════════════════════════════════════════════════════════
  Widget _buildPhaseDiagram(QuantumPalette p, TimeCrystalService tc) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9945FF).withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, __) => CustomPaint(
            size: const Size(double.infinity, 200),
            painter: _PhaseDiagramPainter(
              experiments: tc.experiments,
              currentDrive: _driveAmp,
              currentDisorder: _disorderW,
              animValue: _waveCtrl.value,
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ══════════════════════════════════════════════════════════
  Widget _sectionHeader(QuantumPalette p, String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: const Color(0xFF9945FF), size: 14),
      const SizedBox(width: 6),
      Text(title,
        style: GoogleFonts.rajdhani(
          color: const Color(0xFF9945FF), fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 1.5,
        )),
    ]);
  }

  Widget _buildParamCard(QuantumPalette p, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.surfaceVariant),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSlider(QuantumPalette p, String label, double value, double min, double max,
      String display, ValueChanged<double> onChanged, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(width: 130,
          child: Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10))),
        Expanded(child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            thumbColor: accent,
            inactiveTrackColor: p.surfaceVariant,
            overlayColor: accent.withValues(alpha: 0.1),
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        )),
        SizedBox(width: 70,
          child: Text(display,
            style: GoogleFonts.rajdhani(color: accent, fontSize: 10, fontWeight: FontWeight.w700),
            textAlign: TextAlign.right)),
      ]),
    );
  }

  Color _phaseColor(TCPhase phase) => const {
    TCPhase.dtcOrdered: Color(0xFF14F195),
    TCPhase.mbl:        Color(0xFFF7931A),
    TCPhase.chaotic:    Color(0xFFFF4444),
    TCPhase.trivial:    Color(0xFF627EEA),
    TCPhase.unknown:    Color(0xFF888888),
  }[phase]!;

  (IconData, String, Color) _modelInfo(TCModelType t) => const {
    TCModelType.cnn:          (Icons.layers_outlined, 'CNN 1D', Color(0xFF00F0FF)),
    TCModelType.lstm:         (Icons.timeline_outlined, 'LSTM', Color(0xFF627EEA)),
    TCModelType.svm:          (Icons.scatter_plot_outlined, 'SVM', Color(0xFFF7931A)),
    TCModelType.randomForest: (Icons.park_outlined, 'RandomForest', Color(0xFF14F195)),
    TCModelType.pennylane:    (Icons.blur_circular_outlined, 'PennyLane', Color(0xFF9945FF)),
    TCModelType.tfq:          (Icons.waves_outlined, 'TFQ', Color(0xFFFF6B35)),
  }[t]!;

  // ── Actions ───────────────────────────────────────────────
  void _runExperiment(TimeCrystalService tc) {
    final as2 = context.read<AutoSaveService>();
    tc.runExperiment(
      platform:      _selPlatform,
      driveAmplitude: _driveAmp,
      disorderW:     _disorderW,
      systemSize:    _systemSize,
      floquetCycles: _floquetCycles,
    ).then((_) {
      as2.onSettingChanged('TC-Experiment', _selPlatform.name);
    });
  }

  void _trainModel(TimeCrystalService tc) {
    final as2 = context.read<AutoSaveService>();
    tc.trainModel(modelType: _selModel, epochs: _epochs).then((_) {
      as2.onSettingChanged('TC-Model', _selModel.name);
    });
  }

  void _runSymbolic(TimeCrystalService tc) {
    tc.runSymbolicReasoning().then((eqs) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${eqs.length} symbolische Gleichungen + 3 Theoreme validiert'),
        backgroundColor: const Color(0xFF9945FF),
        duration: const Duration(seconds: 2),
      ));
    });
  }
}

// ══════════════════════════════════════════════════════════════
// CUSTOM PAINTER — Floquet Phase Diagram (Ω vs W parameter space)
// ══════════════════════════════════════════════════════════════
class _PhaseDiagramPainter extends CustomPainter {
  final List<TCExperiment> experiments;
  final double currentDrive;
  final double currentDisorder;
  final double animValue;

  const _PhaseDiagramPainter({
    required this.experiments,
    required this.currentDrive,
    required this.currentDisorder,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF050012));

    // Axis labels
    final axisPaint = Paint()..color = const Color(0xFF334455)..strokeWidth = 0.5;
    // Grid lines
    for (int i = 0; i <= 4; i++) {
      final x = w * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, h), axisPaint);
      final y = h * i / 4;
      canvas.drawLine(Offset(0, y), Offset(w, y), axisPaint);
    }

    // Phase regions — paint background zones
    // x-axis = Drive Amplitude Ω (0..2)
    // y-axis = Disorder W (0..1), inverted (bottom=0, top=1)
    final xScale = w / 2.0;   // 0..2 → 0..w
    final yScale = h / 1.0;   // 0..1 → 0..h, inverted

    double xOf(double omega) => omega * xScale;
    double yOf(double disorder) => h - disorder * yScale;

    // DTC region (Ω ∈ [0.5,1.4], W ∈ [0.1,0.6])
    final dtcPath = Path()
      ..moveTo(xOf(0.5), yOf(0.1))
      ..lineTo(xOf(1.4), yOf(0.1))
      ..lineTo(xOf(1.4), yOf(0.6))
      ..lineTo(xOf(0.5), yOf(0.6))
      ..close();
    canvas.drawPath(dtcPath, Paint()
      ..color = const Color(0xFF14F195).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill);
    canvas.drawPath(dtcPath, Paint()
      ..color = const Color(0xFF14F195).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);

    // MBL region (W > 0.6)
    final mblPath = Path()
      ..moveTo(0, yOf(0.6))
      ..lineTo(w, yOf(0.6))
      ..lineTo(w, yOf(1.0))
      ..lineTo(0, yOf(1.0))
      ..close();
    canvas.drawPath(mblPath, Paint()
      ..color = const Color(0xFFF7931A).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill);

    // Chaotic region (Ω > 1.5)
    final chaosPath = Path()
      ..moveTo(xOf(1.5), 0)
      ..lineTo(w, 0)
      ..lineTo(w, yOf(0.6))
      ..lineTo(xOf(1.5), yOf(0.6))
      ..close();
    canvas.drawPath(chaosPath, Paint()
      ..color = const Color(0xFFFF4444).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill);

    // Phase region labels
    final tp = TextPainter(textDirection: TextDirection.ltr);

    void drawLabel(String text, double omega, double disorder, Color color) {
      tp.text = TextSpan(text: text, style: TextStyle(
        color: color.withValues(alpha: 0.7),
        fontSize: 9,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ));
      tp.layout();
      tp.paint(canvas, Offset(xOf(omega) - tp.width / 2, yOf(disorder) - tp.height / 2));
    }

    drawLabel('DTC', 0.95, 0.35, const Color(0xFF14F195));
    drawLabel('MBL', 1.0, 0.8, const Color(0xFFF7931A));
    drawLabel('CHAOTISCH', 1.75, 0.3, const Color(0xFFFF4444));
    drawLabel('TRIVIAL', 0.25, 0.3, const Color(0xFF627EEA));

    // Axis labels
    void drawAxisLabel(String text, Offset pos) {
      tp.text = TextSpan(text: text, style: const TextStyle(
        color: Color(0xFF556677), fontSize: 7, fontFamily: 'monospace',
      ));
      tp.layout();
      tp.paint(canvas, pos);
    }
    drawAxisLabel('Ω=0', Offset(2, h - 12));
    drawAxisLabel('Ω=1', Offset(xOf(1.0) - 8, h - 12));
    drawAxisLabel('Ω=2', Offset(w - 20, h - 12));
    drawAxisLabel('W=0', Offset(2, h - 14));
    drawAxisLabel('W=1', const Offset(2, 2));

    // Experiment data points
    for (final exp in experiments) {
      final px = xOf(exp.driveAmplitude);
      final py = yOf(exp.disorderW);
      final col = _phaseColor(exp.detectedPhase);
      canvas.drawCircle(Offset(px, py), 5,
          Paint()..color = col.withValues(alpha: 0.85)..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(px, py), 5,
          Paint()..color = col..style = PaintingStyle.stroke..strokeWidth = 1.0);
    }

    // Current parameter crosshair (animated pulse)
    final cx = xOf(currentDrive);
    final cy = yOf(currentDisorder);
    final pulse = 0.5 + animValue * 0.5;

    // Crosshair lines
    canvas.drawLine(Offset(cx, 0), Offset(cx, h),
        Paint()..color = Colors.white.withValues(alpha: 0.15)..strokeWidth = 0.5);
    canvas.drawLine(Offset(0, cy), Offset(w, cy),
        Paint()..color = Colors.white.withValues(alpha: 0.15)..strokeWidth = 0.5);

    // Pulsing dot
    canvas.drawCircle(Offset(cx, cy), 8 + pulse * 4,
        Paint()..color = Colors.white.withValues(alpha: 0.06 * pulse)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), 6,
        Paint()..color = Colors.white.withValues(alpha: 0.9)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), 6,
        Paint()..color = const Color(0xFF9945FF)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Param label near dot
    tp.text = TextSpan(
      text: 'Ω=${currentDrive.toStringAsFixed(2)}\nW=${currentDisorder.toStringAsFixed(2)}',
      style: const TextStyle(color: Colors.white, fontSize: 7, fontFamily: 'monospace'),
    );
    tp.layout();
    final labelX = (cx + 10).clamp(0.0, w - tp.width - 2);
    final labelY = (cy - 20).clamp(2.0, h - tp.height - 2);
    tp.paint(canvas, Offset(labelX, labelY));
  }

  Color _phaseColor(TCPhase phase) => const {
    TCPhase.dtcOrdered: Color(0xFF14F195),
    TCPhase.mbl:        Color(0xFFF7931A),
    TCPhase.chaotic:    Color(0xFFFF4444),
    TCPhase.trivial:    Color(0xFF627EEA),
    TCPhase.unknown:    Color(0xFF888888),
  }[phase]!;

  @override
  bool shouldRepaint(covariant _PhaseDiagramPainter old) =>
      old.currentDrive != currentDrive ||
      old.currentDisorder != currentDisorder ||
      old.animValue != animValue ||
      old.experiments.length != experiments.length;
}

// ══════════════════════════════════════════════════════════════
// CUSTOM PAINTER — Mini Time Series
// ══════════════════════════════════════════════════════════════
class _TimeSeriesPainter extends CustomPainter {
  final List<TCDataPoint> data;
  final Color lineColor;
  final QuantumPalette p;

  const _TimeSeriesPainter(this.data, this.lineColor, this.p);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final mid = h / 2;

    // Zero line
    canvas.drawLine(Offset(0, mid), Offset(w, mid),
        Paint()..color = p.surfaceVariant..strokeWidth = 0.5);

    // Data line
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * w;
      final y = mid - (data[i].observable * mid * 0.85);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Glow
    canvas.drawPath(path, Paint()
      ..color = lineColor.withValues(alpha: 0.15)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
  }

  @override
  bool shouldRepaint(covariant _TimeSeriesPainter old) =>
      old.data != data || old.lineColor != lineColor;
}
