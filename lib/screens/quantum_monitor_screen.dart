import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

class QuantumMonitorScreen extends StatefulWidget {
  const QuantumMonitorScreen({super.key});
  @override
  State<QuantumMonitorScreen> createState() => _QuantumMonitorScreenState();
}

class _QuantumMonitorScreenState extends State<QuantumMonitorScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _spectrumCtrl;

  final List<_ResonancePeak> _peaks = [
    _ResonancePeak('17-Tage', 0.78, 0.72, true),
    _ResonancePeak('89-Tage', 0.62, 0.58, true),
    _ResonancePeak('34-Tage', 0.45, 0.40, false),
    _ResonancePeak('5-Tage', 0.88, 0.82, true),
    _ResonancePeak('233-Tage', 0.35, 0.30, false),
    _ResonancePeak('55-Tage', 0.52, 0.48, true),
  ];

  final List<_InterferenceNote> _notes = [
    _InterferenceNote('Konstruktiv', '17T × 89T', 'BTC Aufwärtsdruck', true),
    _InterferenceNote('Destruktiv', '34T × 5T', 'ETH Korrekturdruck', false),
    _InterferenceNote('Neutral', '55T × 89T', 'SOL Konsolidierung', null),
  ];

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _spectrumCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3500))
      ..repeat();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _pulseCtrl.dispose();
    _spectrumCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.surface,
        title: Row(children: [
          Icon(Icons.waves, color: p.primary, size: 18),
          const SizedBox(width: 8),
          Text('QUANTUM MONITOR',
              style: GoogleFonts.rajdhani(
                  color: p.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
        ]),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: p.textSecondary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: p.positive.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: p.positive.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.positive,
                    boxShadow: [
                      BoxShadow(
                          color: p.positive
                              .withValues(alpha: _pulseCtrl.value * 0.8),
                          blurRadius: 6)
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text('LIVE',
                  style: GoogleFonts.rajdhani(
                      color: p.positive,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ]),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildSpectrumVisualizer(p),
            const SizedBox(height: 12),
            _buildWaveInterference(p),
            const SizedBox(height: 12),
            _buildResonancePeaks(p),
            const SizedBox(height: 12),
            _buildInterferenceNotes(p),
            const SizedBox(height: 12),
            _buildAgentStatus(p),
          ],
        ),
      ),
    );
  }

  // ── Quantum Spektrum Visualizer ──────────────────
  Widget _buildSpectrumVisualizer(dynamic p) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Grid lines
            CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _GridPainter(p),
            ),
            // Live Spectrum
            AnimatedBuilder(
              animation: _spectrumCtrl,
              builder: (_, __) => CustomPaint(
                size: const Size(double.infinity, 200),
                painter: _SpectrumPainter(_spectrumCtrl.value, p),
              ),
            ),
            // Labels
            Positioned(
              top: 10,
              left: 14,
              child: Text(
                'QUANTUM RESONANZ-SPEKTRUM',
                style: GoogleFonts.rajdhani(
                    color: p.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 14,
              child: Text(
                'Frequenz (Tage)',
                style: TextStyle(color: p.textSecondary, fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Wellen-Interferenz-Anzeige ───────────────────
  Widget _buildWaveInterference(dynamic p) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, __) => CustomPaint(
                size: const Size(double.infinity, 140),
                painter: _WaveInterferencePainter(_waveCtrl.value, p),
              ),
            ),
            Positioned(
              top: 10,
              left: 14,
              child: Text(
                'INTERFERENZ-MUSTER',
                style: GoogleFonts.rajdhani(
                    color: p.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 14,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.primary
                        .withValues(alpha: 0.1 + _pulseCtrl.value * 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: p.primary
                            .withValues(alpha: 0.3 + _pulseCtrl.value * 0.2)),
                  ),
                  child: Text(
                    'Konstruktiv: +0.78',
                    style: TextStyle(
                        color: p.positive,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Resonanz-Peaks Tabelle ────────────────────────
  Widget _buildResonancePeaks(dynamic p) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(Icons.graphic_eq, color: p.primary, size: 16),
                const SizedBox(width: 8),
                Text('RESONANZ-PEAKS',
                    style: GoogleFonts.rajdhani(
                        color: p.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5)),
                const Spacer(),
                Text('BTC/USDT · ${_timeStr()}',
                    style: TextStyle(color: p.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                    child: Text('Zyklus',
                        style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text('Amplitude',
                        style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text('Konfidenz',
                        style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold))),
                Text('Trend',
                    style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Divider(color: p.primary.withValues(alpha: 0.1), height: 1),
          ..._peaks.map((peak) => _buildPeakRow(p, peak)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPeakRow(dynamic p, _ResonancePeak peak) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(peak.cycle,
                style: GoogleFonts.rajdhani(
                    color: p.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                final liveAmp =
                    peak.amplitude + _pulseCtrl.value * 0.02 * (peak.bullish ? 1 : -1);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(liveAmp.toStringAsFixed(2),
                        style: TextStyle(
                            color: peak.bullish ? p.positive : p.negative,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: liveAmp,
                        backgroundColor: p.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            peak.bullish ? p.positive : p.negative),
                        minHeight: 3,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: Text(
              '${(peak.confidence * 100).toInt()}%',
              style: TextStyle(color: p.primary, fontSize: 12),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: (peak.bullish ? p.positive : p.negative)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  peak.bullish ? Icons.arrow_upward : Icons.arrow_downward,
                  color: peak.bullish ? p.positive : p.negative,
                  size: 11,
                ),
                Text(
                  peak.bullish ? 'Bull' : 'Bear',
                  style: TextStyle(
                      color: peak.bullish ? p.positive : p.negative,
                      fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Interferenz-Notizen ───────────────────────────
  Widget _buildInterferenceNotes(dynamic p) {
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
          Row(children: [
            Icon(Icons.auto_awesome, color: p.secondary, size: 16),
            const SizedBox(width: 8),
            Text('EMMA ORACLE INTERFERENZ-ANALYSE',
                style: GoogleFonts.rajdhani(
                    color: p.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
          ]),
          const SizedBox(height: 12),
          ..._notes.map((note) {
            final color = note.isConstructive == null
                ? p.textSecondary
                : (note.isConstructive! ? p.positive : p.negative);
            final icon = note.isConstructive == null
                ? Icons.remove
                : (note.isConstructive! ? Icons.add_circle_outline : Icons.remove_circle_outline);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(note.type,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: p.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(note.cycles,
                                style: TextStyle(
                                    color: p.textSecondary, fontSize: 9)),
                          ),
                        ]),
                        Text(note.description,
                            style: TextStyle(
                                color: p.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          Divider(color: p.primary.withValues(alpha: 0.1)),
          const SizedBox(height: 6),
          Text(
            '🔮 Emma: „Die 17-Tage-Resonanz interferiert KONSTRUKTIV mit der 89-Tage-Welle. Aufwärtsbewegung in den nächsten 6–12h hochwahrscheinlich. Konfidenz: 82%."',
            style: GoogleFonts.exo(
                color: p.textPrimary,
                fontSize: 12,
                height: 1.5,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ── Agenten-Status ────────────────────────────────
  Widget _buildAgentStatus(dynamic p) {
    final agents = [
      ('Deep Research', 0.18, Icons.manage_search, true),
      ('Pattern Genesis', 0.22, Icons.auto_graph, true),
      ('Sentient Market', 0.20, Icons.psychology, true),
      ('Paradigm Shift', 0.14, Icons.swap_vert, true),
      ('Error & Anomaly', 0.12, Icons.bug_report_outlined, true),
      ('Strategic Synthesis', 0.14, Icons.account_tree_outlined, true),
    ];
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
          Row(children: [
            Icon(Icons.hub, color: p.primary, size: 16),
            const SizedBox(width: 8),
            Text('HQMLL META-AGENTEN STATUS',
                style: GoogleFonts.rajdhani(
                    color: p.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            const Spacer(),
            Text('6/6 ONLINE',
                style: TextStyle(
                    color: p.positive,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          ...agents.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(a.$3, color: p.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(a.$1,
                          style: TextStyle(
                              color: p.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text('${(a.$2 * 100).toInt()}%',
                          style: TextStyle(color: p.primary, fontSize: 11)),
                    ]),
                    const SizedBox(height: 3),
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: a.$2 + _pulseCtrl.value * 0.01,
                          backgroundColor: p.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(p.primary),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.positive,
                  boxShadow: [BoxShadow(color: p.positive.withValues(alpha: 0.7), blurRadius: 5)],
                ),
              ),
            ]),
          )),
        ],
      ),
    );
  }

  String _timeStr() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

// ── Data Classes ──────────────────────────────────
class _ResonancePeak {
  final String cycle;
  final double amplitude;
  final double confidence;
  final bool bullish;
  _ResonancePeak(this.cycle, this.amplitude, this.confidence, this.bullish);
}

class _InterferenceNote {
  final String type, cycles, description;
  final bool? isConstructive;
  _InterferenceNote(this.type, this.cycles, this.description, this.isConstructive);
}

// ── Custom Painters ───────────────────────────────
class _GridPainter extends CustomPainter {
  final dynamic p;
  _GridPainter(this.p);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = p.primary.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (int i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  @override
  bool shouldRepaint(_GridPainter old) => false;
}

class _SpectrumPainter extends CustomPainter {
  final double t;
  final dynamic p;
  final Random _rnd = Random(42);

  _SpectrumPainter(this.t, this.p);

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 32;
    final barW = size.width / barCount;
    final baseHeights = List.generate(barCount, (i) {
      final base = sin(i * 0.4) * 0.3 + sin(i * 0.15) * 0.4 + 0.2;
      return (base + _rnd.nextDouble() * 0.1).clamp(0.05, 0.9);
    });

    for (int i = 0; i < barCount; i++) {
      final phase = t * 2 * pi + i * 0.3;
      final h = baseHeights[i] + sin(phase) * 0.08;
      final barH = h.clamp(0.05, 0.95) * (size.height - 30);
      final x = i * barW;
      final y = size.height - barH - 10;

      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          p.primary.withValues(alpha: 0.9),
          p.accent.withValues(alpha: 0.4),
        ],
      );

      canvas.drawRect(
        Rect.fromLTWH(x + 1, y, barW - 2, barH),
        Paint()
          ..shader = gradient
              .createShader(Rect.fromLTWH(x, y, barW, barH)),
      );

      // Peak dot
      canvas.drawCircle(
        Offset(x + barW / 2, y),
        2,
        Paint()..color = p.primary,
      );
    }

    // Overlay wave line
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = p.secondary.withValues(alpha: 0.6);
    final wavePath = Path();
    for (double x = 0; x <= size.width; x += 2) {
      final i = (x / size.width * barCount).clamp(0, barCount - 1).toInt();
      final h = (baseHeights[i] + sin(t * 2 * pi + i * 0.3) * 0.08)
          .clamp(0.05, 0.95);
      final y = size.height - h * (size.height - 30) - 10;
      if (x == 0) {
        wavePath.moveTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }
    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(_SpectrumPainter old) => old.t != t;
}

class _WaveInterferencePainter extends CustomPainter {
  final double t;
  final dynamic p;
  _WaveInterferencePainter(this.t, this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;

    // Wave 1: 17-day cycle
    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = p.primary.withValues(alpha: 0.7);
    final path1 = Path();
    for (double x = 0; x <= size.width; x++) {
      final y = cy + sin((x / size.width * 4 * pi) + t * 2 * pi) * (cy * 0.5);
      if (x == 0) {
        path1.moveTo(x, y);
      } else {
        path1.lineTo(x, y);
      }
    }
    canvas.drawPath(path1, paint1);

    // Wave 2: 89-day cycle
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = p.secondary.withValues(alpha: 0.6);
    final path2 = Path();
    for (double x = 0; x <= size.width; x++) {
      final y = cy + sin((x / size.width * 1.5 * pi) + t * 2 * pi * 0.3) * (cy * 0.4);
      if (x == 0) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }
    canvas.drawPath(path2, paint2);

    // Interference = sum of waves
    final paintI = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = p.accent.withValues(alpha: 0.9);
    final pathI = Path();
    for (double x = 0; x <= size.width; x++) {
      final w1 = sin((x / size.width * 4 * pi) + t * 2 * pi) * (cy * 0.5);
      final w2 = sin((x / size.width * 1.5 * pi) + t * 2 * pi * 0.3) * (cy * 0.4);
      final y = cy + (w1 + w2) * 0.6;
      if (x == 0) {
        pathI.moveTo(x, y);
      } else {
        pathI.lineTo(x, y);
      }
    }
    canvas.drawPath(pathI, paintI);

    // Center line
    canvas.drawLine(
      Offset(0, cy),
      Offset(size.width, cy),
      Paint()..color = p.textSecondary.withValues(alpha: 0.15)..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_WaveInterferencePainter old) => old.t != t;
}
