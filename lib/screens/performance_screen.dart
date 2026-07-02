// HQMLL Quantum Trader — Performance Optimizer Screen v52.0
// FPS-Chart · Memory-Graph · Optimization-Controls · Report-Display
// Grigori Saks · 2025
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/performance_optimizer_service.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  StreamSubscription<double>? _fpsSub;
  StreamSubscription<MemorySnapshot>? _memSub;
  StreamSubscription<String>? _alertSub;

  double _liveFps = 60.0;
  MemorySnapshot? _liveMemory;
  final List<String> _alerts = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachStreams());
  }

  void _attachStreams() {
    final svc = context.read<PerformanceOptimizerService>();
    _fpsSub = svc.fpsStream.listen((fps) {
      if (mounted) setState(() => _liveFps = fps);
    });
    _memSub = svc.memStream.listen((mem) {
      if (mounted) setState(() => _liveMemory = mem);
    });
    _alertSub = svc.alertStream.listen((msg) {
      if (mounted) {
        setState(() {
        _alerts.insert(0, msg);
        if (_alerts.length > 50) _alerts.removeLast();
      });
      }
    });
  }

  @override
  void dispose() {
    _fpsSub?.cancel();
    _memSub?.cancel();
    _alertSub?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp  = context.watch<ThemeProvider>();
    final p   = tp.palette;
    final svc = context.watch<PerformanceOptimizerService>();

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.surface,
        elevation: 0,
        title: Text(
          'PERFORMANCE OPTIMIZER',
          style: GoogleFonts.spaceMono(
            color: p.primary, fontSize: 14, letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Monitoring Toggle
          _MonitoringToggleBtn(svc: svc, palette: p),
          // Generate Report
          IconButton(
            icon: Icon(Icons.assessment_outlined, color: p.primary),
            tooltip: 'Report generieren',
            onPressed: () => svc.generateReportNow(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: p.primary,
          labelColor: p.primary,
          unselectedLabelColor: p.textSecondary,
          labelStyle: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'LIVE'),
            Tab(text: 'FPS'),
            Tab(text: 'SPEICHER'),
            Tab(text: 'OPTIMIZE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _LiveTab(svc: svc, liveFps: _liveFps, liveMemory: _liveMemory, alerts: _alerts, palette: p),
          _FpsTab(svc: svc, palette: p),
          _MemoryTab(svc: svc, liveMemory: _liveMemory, palette: p),
          _OptimizeTab(svc: svc, palette: p),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MONITORING TOGGLE BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class _MonitoringToggleBtn extends StatelessWidget {
  final PerformanceOptimizerService svc;
  final dynamic palette;
  const _MonitoringToggleBtn({required this.svc, required this.palette});

  @override
  Widget build(BuildContext context) {
    final isOn = svc.isMonitoring;
    return GestureDetector(
      onTap: () => isOn ? svc.stopMonitoring() : svc.startMonitoring(),
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
              isOn ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 12,
              color: isOn ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              isOn ? 'AKTIV' : 'INAKTIV',
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
// TAB 1 — LIVE DASHBOARD
// ══════════════════════════════════════════════════════════════════════════════
class _LiveTab extends StatelessWidget {
  final PerformanceOptimizerService svc;
  final double liveFps;
  final MemorySnapshot? liveMemory;
  final List<String> alerts;
  final dynamic palette;

  const _LiveTab({
    required this.svc,
    required this.liveFps,
    required this.liveMemory,
    required this.alerts,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final tier = svc.currentTier;
    final tierColor = _tierColor(tier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Tier Badge ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tierColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tierColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Text(tier.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.label.toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        color: tierColor, fontSize: 18,
                        fontWeight: FontWeight.bold, letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Performance Tier',
                      style: GoogleFonts.inter(
                        color: p.textSecondary, fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Metriken Grid ───────────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _MetricCard(
              label: 'LIVE FPS',
              value: liveFps.toStringAsFixed(1),
              unit: 'fps',
              icon: Icons.speed,
              color: liveFps >= 55 ? Colors.green : liveFps >= 30 ? Colors.orange : Colors.red,
              palette: p,
            ),
            _MetricCard(
              label: 'Ø FPS',
              value: svc.avgFps.toStringAsFixed(1),
              unit: 'fps',
              icon: Icons.show_chart,
              color: p.primary,
              palette: p,
            ),
            _MetricCard(
              label: 'HEAP',
              value: liveMemory != null
                  ? liveMemory!.heapMb.toStringAsFixed(1)
                  : '—',
              unit: 'MB',
              icon: Icons.memory,
              color: (liveMemory?.isHighMemory ?? false) ? Colors.orange : Colors.teal,
              palette: p,
            ),
            _MetricCard(
              label: 'JANK FRAMES',
              value: svc.jankFrameCount.toString(),
              unit: 'frames',
              icon: Icons.warning_amber_outlined,
              color: svc.jankFrameCount > 10 ? Colors.red : Colors.green,
              palette: p,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Last Report ─────────────────────────────────────────────────────
        if (svc.lastReport != null) ...[
          _SectionHeader(title: 'LETZTER REPORT', palette: p),
          const SizedBox(height: 8),
          _ReportCard(report: svc.lastReport!, palette: p),
          const SizedBox(height: 16),
        ],

        // ── Alerts ──────────────────────────────────────────────────────────
        _SectionHeader(title: 'PERFORMANCE ALERTS', palette: p),
        const SizedBox(height: 8),
        if (alerts.isEmpty)
          _EmptyCard(message: 'Keine Alerts — System läuft stabil', palette: p)
        else
          ...alerts.take(10).map((a) => _AlertEntry(msg: a, palette: p)),

        const SizedBox(height: 24),
      ],
    );
  }

  Color _tierColor(PerformanceTier t) {
    switch (t) {
      case PerformanceTier.excellent: return Colors.green;
      case PerformanceTier.good:      return Colors.blue;
      case PerformanceTier.degraded:  return Colors.orange;
      case PerformanceTier.critical:  return Colors.red;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — FPS CHART
// ══════════════════════════════════════════════════════════════════════════════
class _FpsTab extends StatelessWidget {
  final PerformanceOptimizerService svc;
  final dynamic palette;
  const _FpsTab({required this.svc, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final samples = svc.fpsSamples;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Stats Row ───────────────────────────────────────────────────────
        Row(children: [
          Expanded(child: _StatPill(label: 'MIN', value: '${svc.minFps.toStringAsFixed(1)} fps', color: Colors.orange, palette: p)),
          const SizedBox(width: 8),
          Expanded(child: _StatPill(label: 'AVG', value: '${svc.avgFps.toStringAsFixed(1)} fps', color: p.primary, palette: p)),
          const SizedBox(width: 8),
          Expanded(child: _StatPill(label: 'JANK', value: '${svc.jankFrameCount}', color: Colors.red, palette: p)),
        ]),
        const SizedBox(height: 16),

        // ── FPS Verlauf Chart ───────────────────────────────────────────────
        _SectionHeader(title: 'FPS VERLAUF (letzte ${samples.length} Frames)', palette: p),
        const SizedBox(height: 8),
        Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.primary.withValues(alpha: 0.2)),
          ),
          child: samples.isEmpty
              ? Center(child: Text('Monitoring läuft...',
                  style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 12)))
              : CustomPaint(
                  painter: _FpsChartPainter(
                    samples: samples,
                    lineColor: p.primary,
                    gridColor: p.textSecondary.withValues(alpha: 0.2),
                  ),
                  child: const SizedBox.expand(),
                ),
        ),
        const SizedBox(height: 16),

        // ── Frame-Tabelle (letzte 20) ────────────────────────────────────
        _SectionHeader(title: 'LETZTE 20 FRAMES', palette: p),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: samples.reversed.take(20).map((s) {
              final isJanky = s.isJanky;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                    color: p.primary.withValues(alpha: 0.08),
                  )),
                ),
                child: Row(children: [
                  Icon(
                    isJanky ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    size: 14,
                    color: isJanky ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${s.fps.toStringAsFixed(1)} fps',
                      style: GoogleFonts.spaceMono(
                        color: isJanky ? Colors.orange : p.primary,
                        fontSize: 12, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${s.frameDuration.inMilliseconds}ms',
                    style: GoogleFonts.inter(color: p.textSecondary, fontSize: 11),
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── FPS Canvas Painter ────────────────────────────────────────────────────────
class _FpsChartPainter extends CustomPainter {
  final List<FpsSample> samples;
  final Color lineColor;
  final Color gridColor;

  const _FpsChartPainter({
    required this.samples,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Horizontale Grid-Linien bei 60, 45, 30 fps
    for (final fps in [60.0, 45.0, 30.0]) {
      final y = size.height - (fps / 70.0) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final n = samples.length;

    for (int i = 0; i < n; i++) {
      final x = (i / (n - 1).clamp(1, 9999)) * size.width;
      final y = size.height - (samples[i].fps / 70.0).clamp(0, 1) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // Jank-Punkte rot markieren
    final jankPaint = Paint()..color = Colors.red.withValues(alpha: 0.7);
    for (int i = 0; i < n; i++) {
      if (samples[i].isJanky) {
        final x = (i / (n - 1).clamp(1, 9999)) * size.width;
        final y = size.height - (samples[i].fps / 70.0).clamp(0, 1) * size.height;
        canvas.drawCircle(Offset(x, y), 3, jankPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FpsChartPainter old) =>
      old.samples != samples;
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3 — MEMORY MONITOR
// ══════════════════════════════════════════════════════════════════════════════
class _MemoryTab extends StatelessWidget {
  final PerformanceOptimizerService svc;
  final MemorySnapshot? liveMemory;
  final dynamic palette;
  const _MemoryTab({required this.svc, required this.liveMemory, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final snapshots = svc.memSnapshots;
    final mem = liveMemory;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Aktuelle Werte ──────────────────────────────────────────────────
        _SectionHeader(title: 'AKTUELLER SPEICHER', palette: p),
        const SizedBox(height: 8),
        if (mem == null)
          _EmptyCard(message: 'Warte auf Speicher-Sample...', palette: p)
        else ...[
          // Heap Usage Bar
          _MemoryUsageBar(
            label: 'HEAP USAGE',
            usedMb: mem.heapMb,
            totalMb: mem.heapCapacityBytes / (1024 * 1024),
            usagePct: mem.heapUsagePct,
            palette: p,
          ),
          const SizedBox(height: 8),
          // RSS Bar
          _MemoryUsageBar(
            label: 'RSS (RESIDENT)',
            usedMb: mem.rssMb,
            totalMb: mem.rssMb * 1.2,
            usagePct: 0.83,
            palette: p,
          ),
          const SizedBox(height: 12),

          // Detail Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _MetricCard(
                label: 'HEAP USED',
                value: mem.heapMb.toStringAsFixed(1),
                unit: 'MB',
                icon: Icons.storage,
                color: p.primary,
                palette: p,
              ),
              _MetricCard(
                label: 'HEAP %',
                value: '${(mem.heapUsagePct * 100).toStringAsFixed(0)}%',
                unit: '',
                icon: Icons.pie_chart_outline,
                color: mem.isHighMemory ? Colors.orange : Colors.green,
                palette: p,
              ),
              _MetricCard(
                label: 'RSS',
                value: mem.rssMb.toStringAsFixed(1),
                unit: 'MB',
                icon: Icons.memory,
                color: Colors.purple,
                palette: p,
              ),
              _MetricCard(
                label: 'EXTERN',
                value: (mem.externalBytes / (1024 * 1024)).toStringAsFixed(1),
                unit: 'MB',
                icon: Icons.extension_outlined,
                color: Colors.teal,
                palette: p,
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),

        // ── Verlauf Chart ───────────────────────────────────────────────────
        _SectionHeader(title: 'HEAP-VERLAUF (${snapshots.length} Samples)', palette: p),
        const SizedBox(height: 8),
        Container(
          height: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.primary.withValues(alpha: 0.2)),
          ),
          child: snapshots.length < 2
              ? Center(child: Text('Sammle Daten...',
                  style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 12)))
              : CustomPaint(
                  painter: _MemChartPainter(
                    snapshots: snapshots,
                    lineColor: Colors.teal,
                    gridColor: p.textSecondary.withValues(alpha: 0.15),
                  ),
                  child: const SizedBox.expand(),
                ),
        ),
        const SizedBox(height: 16),

        // ── Slow Widgets ────────────────────────────────────────────────────
        _SectionHeader(title: 'LANGSAME WIDGETS', palette: p),
        const SizedBox(height: 8),
        if (svc.slowWidgets.isEmpty)
          _EmptyCard(message: 'Keine langsamen Widgets erkannt', palette: p)
        else
          ...svc.slowWidgets.take(10).map((w) => _SlowWidgetTile(record: w, palette: p)),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Memory Chart Painter ──────────────────────────────────────────────────────
class _MemChartPainter extends CustomPainter {
  final List<MemorySnapshot> snapshots;
  final Color lineColor;
  final Color gridColor;

  const _MemChartPainter({
    required this.snapshots,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (snapshots.length < 2) return;

    final maxMb = snapshots.map((s) => s.heapMb).reduce((a, b) => a > b ? a : b);
    if (maxMb <= 0) return;

    final fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final fill = Path();
    final n = snapshots.length;

    for (int i = 0; i < n; i++) {
      final x = (i / (n - 1)) * size.width;
      final y = size.height - (snapshots[i].heapMb / (maxMb * 1.1)) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(fill, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MemChartPainter old) => old.snapshots != snapshots;
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 4 — OPTIMIZE
// ══════════════════════════════════════════════════════════════════════════════
class _OptimizeTab extends StatelessWidget {
  final PerformanceOptimizerService svc;
  final dynamic palette;
  const _OptimizeTab({required this.svc, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Status Flags ────────────────────────────────────────────────────
        _SectionHeader(title: 'OPTIMIERUNGS-STATUS', palette: p),
        const SizedBox(height: 8),
        _StatusFlagTile(
          label: 'Animationen reduziert',
          active: svc.animationsReduced,
          palette: p,
        ),
        _StatusFlagTile(
          label: 'Throttle aktiv',
          active: svc.throttleActive,
          palette: p,
        ),
        _StatusFlagTile(
          label: 'Max-List-Items: ${svc.maxListItems}',
          active: svc.maxListItems < 500,
          palette: p,
        ),
        _StatusFlagTile(
          label: 'Update-Interval: ${svc.updateInterval.inMilliseconds}ms',
          active: svc.updateInterval.inMilliseconds > 1000,
          palette: p,
        ),
        const SizedBox(height: 16),

        // ── Manuelle Aktionen ───────────────────────────────────────────────
        _SectionHeader(title: 'MANUELLE OPTIMIERUNGEN', palette: p),
        const SizedBox(height: 8),
        ...OptimizationAction.values.map((action) => _ActionTile(
          action: action,
          onTap: () => svc.applyOptimization(action),
          palette: p,
        )),
        const SizedBox(height: 16),

        // ── Report Anzeige ──────────────────────────────────────────────────
        _SectionHeader(title: 'PERFORMANCE REPORT', palette: p),
        const SizedBox(height: 8),
        if (svc.lastReport == null)
          _EmptyCard(message: 'Noch kein Report — tippe auf "Report generieren"', palette: p)
        else
          _ReportCard(report: svc.lastReport!, palette: p),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final dynamic palette;
  const _SectionHeader({required this.title, required this.palette});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: GoogleFonts.spaceMono(
      color: palette.primary,
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
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
    child: Text(
      message,
      style: GoogleFonts.inter(color: palette.textSecondary, fontSize: 12),
      textAlign: TextAlign.center,
    ),
  );
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final dynamic palette;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.palette,
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
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.spaceMono(
              color: p.textSecondary, fontSize: 9, letterSpacing: 0.5,
            )),
          ]),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.spaceMono(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(unit, style: GoogleFonts.inter(
                    color: p.textSecondary, fontSize: 10,
                  )),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final dynamic palette;
  const _StatPill({required this.label, required this.value,
    required this.color, required this.palette});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        Text(label, style: GoogleFonts.spaceMono(
          color: palette.textSecondary, fontSize: 9, letterSpacing: 1,
        )),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.spaceMono(
          color: color, fontSize: 13, fontWeight: FontWeight.bold,
        )),
      ],
    ),
  );
}

class _MemoryUsageBar extends StatelessWidget {
  final String label;
  final double usedMb;
  final double totalMb;
  final double usagePct;
  final dynamic palette;
  const _MemoryUsageBar({
    required this.label,
    required this.usedMb,
    required this.totalMb,
    required this.usagePct,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final barColor = usagePct > 0.8 ? Colors.red
        : usagePct > 0.6 ? Colors.orange
        : Colors.teal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: barColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label, style: GoogleFonts.spaceMono(
              color: p.textSecondary, fontSize: 10, letterSpacing: 1,
            )),
            const Spacer(),
            Text(
              '${usedMb.toStringAsFixed(1)} / ${totalMb.toStringAsFixed(1)} MB',
              style: GoogleFonts.spaceMono(color: barColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usagePct.clamp(0.0, 1.0),
              backgroundColor: barColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlowWidgetTile extends StatelessWidget {
  final WidgetBuildRecord record;
  final dynamic palette;
  const _SlowWidgetTile({required this.record, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.slow_motion_video, size: 14, color: Colors.orange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            record.widgetName,
            style: GoogleFonts.spaceMono(color: p.primary, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${record.buildTime.inMilliseconds}ms × ${record.buildCount}',
          style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10),
        ),
      ]),
    );
  }
}

class _StatusFlagTile extends StatelessWidget {
  final String label;
  final bool active;
  final dynamic palette;
  const _StatusFlagTile({required this.label, required this.active, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (active ? Colors.orange : Colors.green).withValues(alpha: 0.3),
        ),
      ),
      child: Row(children: [
        Icon(
          active ? Icons.warning_amber_rounded : Icons.check_circle_outline,
          size: 14,
          color: active ? Colors.orange : Colors.green,
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(color: p.primary, fontSize: 12)),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final OptimizationAction action;
  final VoidCallback onTap;
  final dynamic palette;
  const _ActionTile({required this.action, required this.onTap, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final label = _actionLabel(action);
    final desc  = _actionDesc(action);
    final icon  = _actionIcon(action);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: p.primary, size: 20),
        title: Text(label, style: GoogleFonts.spaceMono(
          color: p.primary, fontSize: 11, fontWeight: FontWeight.bold,
        )),
        subtitle: Text(desc, style: GoogleFonts.inter(
          color: p.textSecondary, fontSize: 10,
        )),
        trailing: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: p.primary,
            backgroundColor: p.primary.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
          ),
          child: Text('AUSFÜHREN', style: GoogleFonts.spaceMono(fontSize: 9)),
        ),
      ),
    );
  }

  String _actionLabel(OptimizationAction a) {
    switch (a) {
      case OptimizationAction.reduceAnimations:  return 'Animationen reduzieren';
      case OptimizationAction.disableParticles:  return 'Partikel deaktivieren';
      case OptimizationAction.limitListItems:    return 'Listen begrenzen';
      case OptimizationAction.throttleUpdates:   return 'Updates drosseln';
      case OptimizationAction.clearImageCache:   return 'Image-Cache leeren';
      case OptimizationAction.gcForce:           return 'GC erzwingen';
      case OptimizationAction.reducePollInterval:return 'Poll-Interval reduzieren';
      case OptimizationAction.disableBlur:       return 'Blur deaktivieren';
      case OptimizationAction.compressData:      return 'Daten komprimieren';
      case OptimizationAction.purgeHistory:      return 'History bereinigen';
    }
  }

  String _actionDesc(OptimizationAction a) {
    switch (a) {
      case OptimizationAction.reduceAnimations:  return 'Reduziert Animationsframes für bessere Performance';
      case OptimizationAction.disableParticles:  return 'Deaktiviert Partikeleffekte im Quantum Eye';
      case OptimizationAction.limitListItems:    return 'Begrenzt Listendarstellung auf 100 Einträge';
      case OptimizationAction.throttleUpdates:   return 'Verlangsamt UI-Updates auf 2s Intervall';
      case OptimizationAction.clearImageCache:   return 'Leert den Flutter Image Cache komplett';
      case OptimizationAction.gcForce:           return 'Erzwingt Garbage Collection im Dart-Heap';
      case OptimizationAction.reducePollInterval:return 'Erhöht API-Poll-Intervall auf 5 Sekunden';
      case OptimizationAction.disableBlur:       return 'Deaktiviert BackdropFilter Blur-Effekte';
      case OptimizationAction.compressData:      return 'Komprimiert gecachte Marktdaten';
      case OptimizationAction.purgeHistory:      return 'Löscht alte Log- und History-Einträge';
    }
  }

  IconData _actionIcon(OptimizationAction a) {
    switch (a) {
      case OptimizationAction.reduceAnimations:  return Icons.animation;
      case OptimizationAction.disableParticles:  return Icons.auto_fix_off;
      case OptimizationAction.limitListItems:    return Icons.format_list_numbered;
      case OptimizationAction.throttleUpdates:   return Icons.speed;
      case OptimizationAction.clearImageCache:   return Icons.image_not_supported_outlined;
      case OptimizationAction.gcForce:           return Icons.delete_sweep_outlined;
      case OptimizationAction.reducePollInterval:return Icons.timer_outlined;
      case OptimizationAction.disableBlur:       return Icons.blur_off;
      case OptimizationAction.compressData:      return Icons.compress;
      case OptimizationAction.purgeHistory:      return Icons.history_toggle_off;
    }
  }
}

class _ReportCard extends StatelessWidget {
  final PerformanceReport report;
  final dynamic palette;
  const _ReportCard({required this.report, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          Text(
            report.summary,
            style: GoogleFonts.spaceMono(
              color: p.primary, fontSize: 12, fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: p.primary.withValues(alpha: 0.15)),
          const SizedBox(height: 6),
          // Stats
          _ReportRow(label: 'Ø FPS',       value: '${report.avgFps.toStringAsFixed(1)} fps', palette: p),
          _ReportRow(label: 'Min FPS',      value: '${report.minFps.toStringAsFixed(1)} fps', palette: p),
          _ReportRow(label: 'Jank Frames',  value: report.jankFrames.toString(), palette: p),
          _ReportRow(label: 'Heap Usage',   value: '${(report.heapUsagePct * 100).toStringAsFixed(0)}%', palette: p),
          if (report.recommendations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('EMPFEHLUNGEN', style: GoogleFonts.spaceMono(
              color: p.textSecondary, fontSize: 9, letterSpacing: 1,
            )),
            const SizedBox(height: 4),
            ...report.recommendations.take(5).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(children: [
                const Icon(Icons.arrow_right, size: 14, color: Colors.orange),
                Text(r.name, style: GoogleFonts.inter(
                  color: p.textSecondary, fontSize: 11,
                )),
              ]),
            )),
          ],
          const SizedBox(height: 6),
          Text(
            'Erstellt: ${_fmt(report.generatedAt)}',
            style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2,'0')}.${dt.month.toString().padLeft(2,'0')}.${dt.year} '
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;
  final dynamic palette;
  const _ReportRow({required this.label, required this.value, required this.palette});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(children: [
      Text(label, style: GoogleFonts.inter(
        color: palette.textSecondary, fontSize: 11,
      )),
      const Spacer(),
      Text(value, style: GoogleFonts.spaceMono(
        color: palette.primary, fontSize: 11, fontWeight: FontWeight.bold,
      )),
    ]),
  );
}

class _AlertEntry extends StatelessWidget {
  final String msg;
  final dynamic palette;
  const _AlertEntry({required this.msg, required this.palette});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
    ),
    child: Row(children: [
      const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.orange),
      const SizedBox(width: 6),
      Expanded(child: Text(
        msg,
        style: GoogleFonts.inter(color: palette.primary, fontSize: 11),
        overflow: TextOverflow.ellipsis,
      )),
    ]),
  );
}
