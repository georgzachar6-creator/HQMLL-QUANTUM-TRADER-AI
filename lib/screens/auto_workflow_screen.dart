/// HQMLL Quantum Trader — Auto-Workflow Screen v52.0
/// Task-Liste · Pipeline-Runner · Auto-Fix-Log · Auto-Save-Status
/// Grigori Saks · 2025
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auto_workflow_service.dart';

class AutoWorkflowScreen extends StatefulWidget {
  const AutoWorkflowScreen({super.key});

  @override
  State<AutoWorkflowScreen> createState() => _AutoWorkflowScreenState();
}

class _AutoWorkflowScreenState extends State<AutoWorkflowScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  StreamSubscription<String>? _logSub;
  StreamSubscription<AutoSaveState>? _saveSub;
  StreamSubscription<AutoFixRecord>? _fixSub;

  final List<String> _liveLogs = [];
  AutoSaveState? _liveAutoSave;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachStreams());
  }

  void _attachStreams() {
    final svc = context.read<AutoWorkflowService>();
    _logSub = svc.logStream.listen((msg) {
      if (mounted) setState(() {
        _liveLogs.insert(0, msg);
        if (_liveLogs.length > 200) _liveLogs.removeLast();
      });
    });
    _saveSub = svc.saveStream.listen((state) {
      if (mounted) setState(() => _liveAutoSave = state);
    });
    _fixSub = svc.fixStream.listen((_) {
      if (mounted) setState(() {});
    });
    // Initialen AutoSave-State laden
    _liveAutoSave = svc.autoSaveState;
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _saveSub?.cancel();
    _fixSub?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp  = context.watch<ThemeProvider>();
    final p   = tp.palette;
    final svc = context.watch<AutoWorkflowService>();

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.surface,
        elevation: 0,
        title: Text(
          'AUTO-WORKFLOW ENGINE',
          style: GoogleFonts.spaceMono(
            color: p.primary, fontSize: 13, letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Auto-Save Toggle
          _AutoSaveToggleBtn(svc: svc, palette: p),
          // Run Full Pipeline
          IconButton(
            icon: Icon(Icons.play_circle_outline, color: p.primary),
            tooltip: 'Full-Sync Pipeline starten',
            onPressed: () => _runFullPipeline(context, svc),
          ),
          const SizedBox(width: 6),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: p.primary,
          labelColor: p.primary,
          unselectedLabelColor: p.textSecondary,
          labelStyle: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'AUTO-SAVE'),
            Tab(text: 'TASKS'),
            Tab(text: 'PIPELINE'),
            Tab(text: 'AUTO-FIX'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _AutoSaveTab(svc: svc, liveState: _liveAutoSave, palette: p),
          _TasksTab(svc: svc, palette: p),
          _PipelineTab(svc: svc, logs: _liveLogs, palette: p),
          _AutoFixTab(svc: svc, palette: p),
        ],
      ),
    );
  }

  Future<void> _runFullPipeline(BuildContext ctx, AutoWorkflowService svc) async {
    final p = context.read<ThemeProvider>().palette;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('Full-Sync Pipeline gestartet...',
          style: GoogleFonts.spaceMono(fontSize: 11)),
        backgroundColor: p.surface,
        duration: const Duration(seconds: 2),
      ),
    );
    final result = await svc.runFullSyncPipeline();
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? '✅ Pipeline abgeschlossen (${result.totalDuration.inMilliseconds}ms)'
              : '❌ Pipeline fehlgeschlagen',
          style: GoogleFonts.spaceMono(fontSize: 11),
        ),
        backgroundColor: result.success ? Colors.green.withValues(alpha: 0.8) : Colors.red.withValues(alpha: 0.8),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AUTO-SAVE TOGGLE BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class _AutoSaveToggleBtn extends StatelessWidget {
  final AutoWorkflowService svc;
  final dynamic palette;
  const _AutoSaveToggleBtn({required this.svc, required this.palette});

  @override
  Widget build(BuildContext context) {
    final isOn = svc.isRunning;
    return GestureDetector(
      onTap: () => isOn ? svc.stopAutoSave() : svc.startAutoSave(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: (isOn ? Colors.green : Colors.grey).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isOn ? Colors.green : Colors.grey).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOn ? Icons.save_outlined : Icons.cloud_off_outlined,
              size: 12,
              color: isOn ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              isOn ? 'AUTO-SAVE EIN' : 'AUTO-SAVE AUS',
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isOn ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — AUTO-SAVE STATUS
// ══════════════════════════════════════════════════════════════════════════════
class _AutoSaveTab extends StatelessWidget {
  final AutoWorkflowService svc;
  final AutoSaveState? liveState;
  final dynamic palette;
  const _AutoSaveTab({required this.svc, required this.liveState, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final state = liveState ?? svc.autoSaveState;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Status Banner ───────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (state.isActive ? Colors.green : Colors.grey).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (state.isActive ? Colors.green : Colors.grey).withValues(alpha: 0.4),
            ),
          ),
          child: Row(children: [
            Icon(
              state.isActive ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              size: 36,
              color: state.isActive ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isActive ? 'AUTO-SAVE AKTIV' : 'AUTO-SAVE INAKTIV',
                  style: GoogleFonts.spaceMono(
                    color: state.isActive ? Colors.green : Colors.grey,
                    fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.statusText,
                  style: GoogleFonts.inter(color: p.textSecondary, fontSize: 11),
                ),
              ],
            )),
            if (state.hasUnsavedChanges)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: Text('UNGESPEICHERT',
                  style: GoogleFonts.spaceMono(
                    color: Colors.orange, fontSize: 8, fontWeight: FontWeight.bold,
                  )),
              ),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Statistiken ─────────────────────────────────────────────────────
        _SectionHeader(title: 'STATISTIKEN', palette: p),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _StatCard(
              label: 'SPEICHERUNGEN',
              value: state.saveCount.toString(),
              icon: Icons.save_outlined,
              color: Colors.green,
              palette: p,
            ),
            _StatCard(
              label: 'INTERVALL',
              value: _fmtDuration(state.interval),
              icon: Icons.timer_outlined,
              color: p.primary,
              palette: p,
            ),
            _StatCard(
              label: 'TASKS TOTAL',
              value: svc.totalRunCount.toString(),
              icon: Icons.play_arrow_outlined,
              color: Colors.blue,
              palette: p,
            ),
            _StatCard(
              label: 'FEHLER',
              value: svc.totalFailCount.toString(),
              icon: Icons.error_outline,
              color: svc.totalFailCount > 0 ? Colors.red : Colors.green,
              palette: p,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Intervall-Steuerung ─────────────────────────────────────────────
        _SectionHeader(title: 'INTERVALL KONFIGURATION', palette: p),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Speicher-Intervall wählen',
                style: GoogleFonts.inter(color: p.textSecondary, fontSize: 11)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Duration(seconds: 30),
                  const Duration(minutes: 1),
                  const Duration(minutes: 2),
                  const Duration(minutes: 5),
                  const Duration(minutes: 10),
                ].map((d) {
                  final isSelected = state.interval == d;
                  return GestureDetector(
                    onTap: () => svc.startAutoSave(interval: d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? p.primary.withValues(alpha: 0.2)
                            : p.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? p.primary.withValues(alpha: 0.6)
                              : p.primary.withValues(alpha: 0.2),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        _fmtDuration(d),
                        style: GoogleFonts.spaceMono(
                          color: isSelected ? p.primary : p.textSecondary,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Aktionen ────────────────────────────────────────────────────────
        _SectionHeader(title: 'AKTIONEN', palette: p),
        const SizedBox(height: 8),
        _ActionButton(
          label: 'JETZT SPEICHERN',
          icon: Icons.save_outlined,
          color: Colors.green,
          palette: p,
          onTap: () => svc.markUnsaved('manual'),
        ),
        const SizedBox(height: 6),
        _ActionButton(
          label: 'HEALTH-CHECK PIPELINE',
          icon: Icons.health_and_safety_outlined,
          color: Colors.blue,
          palette: p,
          onTap: () => svc.runHealthCheckPipeline(),
        ),
        const SizedBox(height: 6),
        _ActionButton(
          label: 'AUTO-FIX PIPELINE',
          icon: Icons.build_circle_outlined,
          color: Colors.orange,
          palette: p,
          onTap: () => svc.runAutoFixPipeline(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _fmtDuration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    return '${d.inHours}h';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — TASKS LISTE
// ══════════════════════════════════════════════════════════════════════════════
class _TasksTab extends StatelessWidget {
  final AutoWorkflowService svc;
  final dynamic palette;
  const _TasksTab({required this.svc, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final tasks = svc.tasks;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Task Zusammenfassung ────────────────────────────────────────────
        Row(children: [
          Expanded(child: _MiniStat(label: 'TASKS', value: tasks.length.toString(), color: p.primary, palette: p)),
          const SizedBox(width: 8),
          Expanded(child: _MiniStat(label: 'LÄUFT', value: svc.runningCount.toString(), color: Colors.blue, palette: p)),
          const SizedBox(width: 8),
          Expanded(child: _MiniStat(label: 'GEPLANT', value: svc.scheduledCount.toString(), color: Colors.orange, palette: p)),
          const SizedBox(width: 8),
          Expanded(child: _MiniStat(label: 'FEHLER', value: svc.totalFailCount.toString(), color: Colors.red, palette: p)),
        ]),
        const SizedBox(height: 16),

        // ── Task Liste ──────────────────────────────────────────────────────
        _SectionHeader(title: 'ALLE TASKS (${tasks.length})', palette: p),
        const SizedBox(height: 8),
        ...tasks.map((task) => _TaskCard(
          task: task,
          palette: p,
          onRun: () => svc.runTask(task.id),
        )),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final WorkflowTask task;
  final dynamic palette;
  final VoidCallback onRun;
  const _TaskCard({required this.task, required this.palette, required this.onRun});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final statusColor = _statusColor(task.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              task.status.emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.name,
                style: GoogleFonts.spaceMono(
                  color: p.primary, fontSize: 11, fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Priority Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _priorityColor(task.priority).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _priorityColor(task.priority).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                task.priority.label.toUpperCase(),
                style: GoogleFonts.spaceMono(
                  color: _priorityColor(task.priority),
                  fontSize: 8, fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Run Button
            GestureDetector(
              onTap: task.status == WorkflowStatus.running ? null : onRun,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: p.primary.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  task.status == WorkflowStatus.running
                      ? Icons.hourglass_top_rounded
                      : Icons.play_arrow_rounded,
                  size: 14,
                  color: task.status == WorkflowStatus.running
                      ? Colors.orange
                      : p.primary,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            task.description,
            style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.repeat, size: 10, color: p.textSecondary),
            const SizedBox(width: 3),
            Text(
              task.trigger.name,
              style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9),
            ),
            if (task.interval != null) ...[
              Text(' · ', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
              Text(
                _fmtInterval(task.interval!),
                style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9),
              ),
            ],
            const Spacer(),
            Text(
              'Runs: ${task.runCount}',
              style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9),
            ),
            if (task.failCount > 0) ...[
              Text(' · ', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
              Text(
                'Fails: ${task.failCount}',
                style: GoogleFonts.spaceMono(color: Colors.red, fontSize: 9),
              ),
            ],
          ]),
          if (task.lastResult != null) ...[
            const SizedBox(height: 4),
            Text(
              task.lastResult!,
              style: GoogleFonts.inter(
                color: task.lastError != null ? Colors.red : Colors.green,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(WorkflowStatus s) {
    switch (s) {
      case WorkflowStatus.idle:      return Colors.grey;
      case WorkflowStatus.running:   return Colors.blue;
      case WorkflowStatus.completed: return Colors.green;
      case WorkflowStatus.failed:    return Colors.red;
      case WorkflowStatus.scheduled: return Colors.orange;
      case WorkflowStatus.paused:    return Colors.purple;
    }
  }

  Color _priorityColor(WorkflowPriority p) {
    switch (p) {
      case WorkflowPriority.low:      return Colors.grey;
      case WorkflowPriority.normal:   return Colors.blue;
      case WorkflowPriority.high:     return Colors.orange;
      case WorkflowPriority.critical: return Colors.red;
    }
  }

  String _fmtInterval(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}min';
    return '${d.inHours}h';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3 — PIPELINE RUNNER
// ══════════════════════════════════════════════════════════════════════════════
class _PipelineTab extends StatelessWidget {
  final AutoWorkflowService svc;
  final List<String> logs;
  final dynamic palette;
  const _PipelineTab({required this.svc, required this.logs, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final history = svc.pipelineHistory;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Pipeline Aktionen ───────────────────────────────────────────────
        _SectionHeader(title: 'PIPELINE STARTEN', palette: p),
        const SizedBox(height: 8),
        _PipelineActionCard(
          name: 'FULL-SYNC PIPELINE',
          description: 'Vollständige Datensynchronisation: Market, Signals, KYC, Portfolio',
          icon: Icons.sync_outlined,
          color: p.primary,
          palette: p,
          onRun: () => svc.runFullSyncPipeline(),
          context: context,
        ),
        const SizedBox(height: 8),
        _PipelineActionCard(
          name: 'HEALTH-CHECK PIPELINE',
          description: 'System-Gesundheitsprüfung: Connections, Errors, Cache',
          icon: Icons.health_and_safety_outlined,
          color: Colors.teal,
          palette: p,
          onRun: () => svc.runHealthCheckPipeline(),
          context: context,
        ),
        const SizedBox(height: 8),
        _PipelineActionCard(
          name: 'AUTO-FIX PIPELINE',
          description: 'Automatische Fehlerbehebung: Verbindungen, Cache, Fehler',
          icon: Icons.build_circle_outlined,
          color: Colors.orange,
          palette: p,
          onRun: () => svc.runAutoFixPipeline(),
          context: context,
        ),
        const SizedBox(height: 16),

        // ── Pipeline History ────────────────────────────────────────────────
        _SectionHeader(title: 'PIPELINE HISTORY (${history.length})', palette: p),
        const SizedBox(height: 8),
        if (history.isEmpty)
          _EmptyCard(message: 'Noch keine Pipelines ausgeführt', palette: p)
        else
          ...history.reversed.take(10).map((r) => _PipelineResultTile(result: r, palette: p)),
        const SizedBox(height: 16),

        // ── Live Log ────────────────────────────────────────────────────────
        Row(children: [
          Expanded(child: _SectionHeader(title: 'LIVE LOG', palette: p)),
          GestureDetector(
            onTap: () {},
            child: Text('${logs.length} Einträge',
              style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
          ),
        ]),
        const SizedBox(height: 8),
        Container(
          height: 280,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.primary.withValues(alpha: 0.2)),
          ),
          child: logs.isEmpty
              ? Center(child: Text('Warte auf Log-Einträge...',
                  style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 11)))
              : ListView.builder(
                  reverse: false,
                  itemCount: logs.length,
                  itemBuilder: (ctx, i) {
                    final msg = logs[i];
                    final isError = msg.contains('❌') || msg.contains('FEHLER');
                    final isOk    = msg.contains('✅');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        msg,
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          color: isError ? Colors.red
                              : isOk ? Colors.green
                              : p.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PipelineActionCard extends StatefulWidget {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final dynamic palette;
  final Future<PipelineRunResult> Function() onRun;
  final BuildContext context;

  const _PipelineActionCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.palette,
    required this.onRun,
    required this.context,
  });

  @override
  State<_PipelineActionCard> createState() => _PipelineActionCardState();
}

class _PipelineActionCardState extends State<_PipelineActionCard> {
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(widget.icon, color: widget.color, size: 28),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name, style: GoogleFonts.spaceMono(
              color: p.primary, fontSize: 11, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 2),
            Text(widget.description, style: GoogleFonts.inter(
              color: p.textSecondary, fontSize: 10,
            )),
          ],
        )),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _running ? null : () async {
            if (!mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            setState(() => _running = true);
            try {
              final result = await widget.onRun();
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    result.success
                        ? '✅ ${widget.name} — ${result.totalDuration.inMilliseconds}ms'
                        : '❌ ${widget.name} fehlgeschlagen',
                    style: GoogleFonts.spaceMono(fontSize: 10),
                  ),
                  backgroundColor: result.success
                      ? Colors.green.withValues(alpha: 0.8)
                      : Colors.red.withValues(alpha: 0.8),
                  duration: const Duration(seconds: 3),
                ),
              );
            } finally {
              if (mounted) setState(() => _running = false);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.color.withValues(alpha: 0.4)),
            ),
            child: _running
                ? SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: widget.color,
                    ),
                  )
                : Text('STARTEN', style: GoogleFonts.spaceMono(
                    color: widget.color, fontSize: 9, fontWeight: FontWeight.bold,
                  )),
          ),
        ),
      ]),
    );
  }
}

class _PipelineResultTile extends StatelessWidget {
  final PipelineRunResult result;
  final dynamic palette;
  const _PipelineResultTile({required this.result, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final ok = result.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (ok ? Colors.green : Colors.red).withValues(alpha: 0.3),
        ),
      ),
      child: Row(children: [
        Text(ok ? '✅' : '❌', style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.pipelineName, style: GoogleFonts.spaceMono(
              color: p.primary, fontSize: 11, fontWeight: FontWeight.bold,
            )),
            Text(
              '${result.stepResults.length} Steps · ${result.totalDuration.inMilliseconds}ms',
              style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9),
            ),
          ],
        )),
        Text(
          _fmtTime(result.completedAt),
          style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9),
        ),
      ]),
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 4 — AUTO-FIX LOG
// ══════════════════════════════════════════════════════════════════════════════
class _AutoFixTab extends StatelessWidget {
  final AutoWorkflowService svc;
  final dynamic palette;
  const _AutoFixTab({required this.svc, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final fixes = svc.fixRecords;
    final successful = fixes.where((f) => f.wasSuccessful).length;
    final failed = fixes.length - successful;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Statistiken ─────────────────────────────────────────────────────
        Row(children: [
          Expanded(child: _MiniStat(label: 'GESAMT', value: fixes.length.toString(), color: p.primary, palette: p)),
          const SizedBox(width: 8),
          Expanded(child: _MiniStat(label: 'ERFOLGREICH', value: successful.toString(), color: Colors.green, palette: p)),
          const SizedBox(width: 8),
          Expanded(child: _MiniStat(label: 'FEHLGESCHL.', value: failed.toString(), color: Colors.red, palette: p)),
        ]),
        const SizedBox(height: 16),

        // ── Manuelle Auto-Fix Trigger ────────────────────────────────────
        _SectionHeader(title: 'AUTO-FIX MANUELL AUSLÖSEN', palette: p),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AutoFixType.values.map((t) => GestureDetector(
            onTap: () => svc.triggerAutoFix(t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.primary.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_fixIcon(t), size: 12, color: p.primary),
                const SizedBox(width: 4),
                Text(_fixLabel(t), style: GoogleFonts.spaceMono(
                  color: p.primary, fontSize: 9, fontWeight: FontWeight.bold,
                )),
              ]),
            ),
          )).toList(),
        ),
        const SizedBox(height: 16),

        // ── Fix Records ──────────────────────────────────────────────────
        _SectionHeader(title: 'AUTO-FIX VERLAUF (${fixes.length})', palette: p),
        const SizedBox(height: 8),
        if (fixes.isEmpty)
          _EmptyCard(message: 'Noch keine Auto-Fix Aktionen', palette: p)
        else
          ...fixes.reversed.take(30).map((f) => _FixRecordTile(record: f, palette: p)),
        const SizedBox(height: 24),
      ],
    );
  }

  String _fixLabel(AutoFixType t) {
    switch (t) {
      case AutoFixType.nullSafety:       return 'NULL SAFETY';
      case AutoFixType.connectionRetry:  return 'RECONNECT';
      case AutoFixType.cacheInvalidation:return 'CACHE CLEAR';
      case AutoFixType.serviceRestart:   return 'SVC RESTART';
      case AutoFixType.dataRefresh:      return 'DATA REFRESH';
      case AutoFixType.errorClear:       return 'ERROR CLEAR';
      case AutoFixType.memoryPurge:      return 'MEM PURGE';
    }
  }

  IconData _fixIcon(AutoFixType t) {
    switch (t) {
      case AutoFixType.nullSafety:       return Icons.security_outlined;
      case AutoFixType.connectionRetry:  return Icons.refresh_outlined;
      case AutoFixType.cacheInvalidation:return Icons.delete_sweep_outlined;
      case AutoFixType.serviceRestart:   return Icons.restart_alt_outlined;
      case AutoFixType.dataRefresh:      return Icons.sync_outlined;
      case AutoFixType.errorClear:       return Icons.clear_all_outlined;
      case AutoFixType.memoryPurge:      return Icons.memory_outlined;
    }
  }
}

class _FixRecordTile extends StatelessWidget {
  final AutoFixRecord record;
  final dynamic palette;
  const _FixRecordTile({required this.record, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final ok = record.wasSuccessful;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (ok ? Colors.green : Colors.red).withValues(alpha: 0.25),
        ),
      ),
      child: Row(children: [
        Text(ok ? '✅' : '❌', style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.description, style: GoogleFonts.spaceMono(
              color: p.primary, fontSize: 10, fontWeight: FontWeight.bold,
            )),
            if (record.detail != null)
              Text(record.detail!, style: GoogleFonts.inter(
                color: p.textSecondary, fontSize: 9,
              )),
          ],
        )),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              record.type.name,
              style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9),
            ),
            Text(
              _fmtTime(record.appliedAt),
              style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8),
            ),
          ],
        ),
      ]),
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}';
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED HELPER WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final dynamic palette;
  const _SectionHeader({required this.title, required this.palette});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: GoogleFonts.spaceMono(
      color: palette.primary, fontSize: 11,
      fontWeight: FontWeight.bold, letterSpacing: 1.5,
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  final String message;
  final dynamic palette;
  const _EmptyCard({required this.message, required this.palette});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: palette.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: palette.primary.withValues(alpha: 0.15)),
    ),
    child: Text(message,
      style: GoogleFonts.inter(color: palette.textSecondary, fontSize: 12),
      textAlign: TextAlign.center,
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final dynamic palette;
  const _StatCard({
    required this.label, required this.value,
    required this.icon, required this.color, required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.spaceMono(
              color: p.textSecondary, fontSize: 9, letterSpacing: 0.5,
            )),
          ]),
          Text(value, style: GoogleFonts.spaceMono(
            color: color, fontSize: 18, fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final dynamic palette;
  const _MiniStat({required this.label, required this.value,
    required this.color, required this.palette});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(children: [
      Text(label, style: GoogleFonts.spaceMono(
        color: palette.textSecondary, fontSize: 8, letterSpacing: 0.5,
      )),
      const SizedBox(height: 2),
      Text(value, style: GoogleFonts.spaceMono(
        color: color, fontSize: 14, fontWeight: FontWeight.bold,
      )),
    ]),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final dynamic palette;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label, required this.icon,
    required this.color, required this.palette, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.spaceMono(
          color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1,
        )),
        const Spacer(),
        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
      ]),
    ),
  );
}
