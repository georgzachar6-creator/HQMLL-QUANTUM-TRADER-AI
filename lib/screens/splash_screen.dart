import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import 'main_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _masterCtrl;
  late AnimationController _textCtrl;
  late AnimationController _progressCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _progressAnim;

  int _logIndex = 0;
  String _currentTyping = '';
  int _typingIndex = 0;
  Timer? _typingTimer;
  bool _typingDone = false;

  final List<_BootEntry> _bootLog = [
    const _BootEntry('META-ORCHESTRATOR', 'Initialisierung läuft...', true),
    const _BootEntry('SECURITY AGENT', 'Zero-Trust Protokoll aktiviert', true),
    const _BootEntry('DEEP RESEARCH', 'Datenquellen verbunden · 14 APIs', true),
    const _BootEntry('PATTERN GENESIS', 'Muster-Bibliothek geladen · 8.2K Modelle', true),
    const _BootEntry('SENTIENT MARKET', 'Sentiment-Stream aktiv · 99.4%', true),
    const _BootEntry('PARADIGM SHIFT', 'Anomalie-Scanner bereit', true),
    const _BootEntry('ERROR & ANOMALY', 'Selbstheilung aktiv · v3.2', true),
    const _BootEntry('QUANTUM RESONATOR', 'Frequenz-Kalibrierung abgeschlossen', true),
    const _BootEntry('RISK SENTINEL', 'Portfolio-Schutz aktiv', true),
    const _BootEntry('EMMA AI CORE', 'Alle 6 Agenten online · Oracle aktiviert!', false),
  ];

  // Partikel
  final List<_Particle> _particles = [];
  final Random _rng = Random(42);

  @override
  void initState() {
    super.initState();

    // Partikel erzeugen
    for (int i = 0; i < 22; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 1.0 + _rng.nextDouble() * 2.5,
        speed: 0.003 + _rng.nextDouble() * 0.006,
        angle: _rng.nextDouble() * 2 * pi,
        opacity: 0.15 + _rng.nextDouble() * 0.45,
      ));
    }

    _masterCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2800),
    )..repeat();

    _particleCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 6),
    )..repeat();

    _textCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _progressCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 5000),
    )..forward();

    _fadeIn = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);
    _scaleIn = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.elasticOut));
    _progressAnim = CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut);

    _textCtrl.forward();

    // Boot Log Stepper
    for (int i = 0; i < _bootLog.length; i++) {
      Future.delayed(Duration(milliseconds: 200 + i * 420), () {
        if (mounted) setState(() => _logIndex = i + 1);
      });
    }

    // Typing-Effekt für letzten Eintrag
    Future.delayed(const Duration(milliseconds: 4400), () {
      if (!mounted) return;
      const finalMsg = '► HQMLL QUANTUM TRADER  —  Eigentümer: Grigori Saks';
      _typingTimer = Timer.periodic(const Duration(milliseconds: 35), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() {
          if (_typingIndex < finalMsg.length) {
            _currentTyping = finalMsg.substring(0, ++_typingIndex);
          } else {
            _typingDone = true;
            t.cancel();
          }
        });
      });
    });

    // Navigation
    Future.delayed(const Duration(milliseconds: 6000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainScaffold(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 900),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _textCtrl.dispose();
    _progressCtrl.dispose();
    _particleCtrl.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          // Partikel-Hintergrund
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) {
              for (final pt in _particles) {
                pt.x += cos(pt.angle) * pt.speed * 0.3;
                pt.y += sin(pt.angle) * pt.speed * 0.3;
                if (pt.x < 0) pt.x = 1;
                if (pt.x > 1) pt.x = 0;
                if (pt.y < 0) pt.y = 1;
                if (pt.y > 1) pt.y = 0;
              }
              return CustomPaint(
                painter: _ParticlePainter(_particles, p.primary),
                size: size,
              );
            },
          ),

          // Hauptinhalt
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ── Logo + Auge ──────────────────────────────
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon + Auge überlagert
                      FadeTransition(
                        opacity: _fadeIn,
                        child: ScaleTransition(
                          scale: _scaleIn,
                          child: AnimatedBuilder(
                            animation: _masterCtrl,
                            builder: (_, __) => Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 160,
                                  height: 160,
                                  child: CustomPaint(
                                    painter: _SplashEyePainter(
                                      t: _masterCtrl.value,
                                      palette: p,
                                    ),
                                  ),
                                ),
                                // App Icon im Zentrum
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: p.primary.withValues(alpha: 0.6),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: p.primary.withValues(alpha: 0.4 * _masterCtrl.value),
                                        blurRadius: 20,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/icons/app_icon.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeTransition(
                        opacity: _fadeIn,
                        child: Column(
                          children: [
                            // App-Name mit Glow
                            AnimatedBuilder(
                              animation: _masterCtrl,
                              builder: (_, __) => Text(
                                'HQMLL QUANTUM',
                                style: GoogleFonts.rajdhani(
                                  color: p.primary,
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 6,
                                  shadows: [
                                    Shadow(
                                      color: p.primary.withValues(
                                        alpha: 0.3 + _masterCtrl.value * 0.3,
                                      ),
                                      blurRadius: 16 + _masterCtrl.value * 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'HYPER-QUANTUM META-LEARNING-LOOP',
                              style: GoogleFonts.exo(
                                color: p.textSecondary,
                                fontSize: 9,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Status-Badges
                            Wrap(
                              spacing: 6, runSpacing: 6,
                              alignment: WrapAlignment.center,
                              children: [
                                _Badge('6 AGENTEN', p.positive, p),
                                _Badge('AI ORACLE', p.primary, p),
                                _Badge('G. SAKS', p.accent, p),
                                _Badge('v1.0.0', p.textSecondary, p),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Boot Log ──────────────────────────────────
                Expanded(
                  flex: 4,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: p.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 7, height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.positive,
                              boxShadow: [
                                BoxShadow(
                                  color: p.positive.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('BOOT SEQUENCE', style: GoogleFonts.spaceMono(
                            color: p.primary, fontSize: 10,
                            fontWeight: FontWeight.bold, letterSpacing: 2,
                          )),
                          const Spacer(),
                          Text(
                            '$_logIndex/${_bootLog.length}',
                            style: GoogleFonts.spaceMono(
                              color: p.textSecondary, fontSize: 9,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _logIndex,
                            reverse: true,
                            itemBuilder: (_, i) {
                              final idx = _logIndex - 1 - i;
                              if (idx < 0 || idx >= _bootLog.length) {
                                return const SizedBox.shrink();
                              }
                              final entry = _bootLog[idx];
                              final isLatest = i == 0;
                              final isLast = !entry.isSuccess;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isLatest ? '▶ ' : '✓ ',
                                      style: TextStyle(
                                        color: isLatest
                                            ? p.primary
                                            : isLast ? p.accent : p.positive,
                                        fontSize: 9,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '[${entry.agent}]  ',
                                      style: GoogleFonts.spaceMono(
                                        color: isLatest
                                            ? p.primary
                                            : p.textSecondary.withValues(alpha: 0.7),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        entry.message,
                                        style: GoogleFonts.spaceMono(
                                          color: isLatest
                                              ? p.textPrimary
                                              : p.textSecondary.withValues(alpha: 0.6),
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Typewriter + Fortschritt ──────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  child: Column(
                    children: [
                      // Typewriter
                      if (_currentTyping.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: p.primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: p.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _currentTyping,
                                style: GoogleFonts.spaceMono(
                                  color: p.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!_typingDone)
                                AnimatedBuilder(
                                  animation: _masterCtrl,
                                  builder: (_, __) => Opacity(
                                    opacity: _masterCtrl.value > 0.5 ? 1 : 0,
                                    child: Text('|', style: TextStyle(
                                      color: p.primary, fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    )),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      // Fortschrittsbalken
                      AnimatedBuilder(
                        animation: _progressAnim,
                        builder: (_, __) => Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _progressAnim.value < 1.0
                                      ? 'Quantensystem wird initialisiert...'
                                      : 'Alle Systeme bereit ✓',
                                  style: GoogleFonts.inter(
                                    color: _progressAnim.value < 1.0
                                        ? p.textSecondary
                                        : p.positive,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  '${(_progressAnim.value * 100).toInt()}%',
                                  style: GoogleFonts.spaceMono(
                                    color: _progressAnim.value < 1.0
                                        ? p.primary
                                        : p.positive,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _progressAnim.value,
                                backgroundColor: p.surfaceVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _progressAnim.value > 0.99 ? p.positive : p.primary,
                                ),
                                minHeight: 5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge Widget ───────────────────────────────────────
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final dynamic palette;
  const _Badge(this.text, this.color, this.palette);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(text, style: GoogleFonts.spaceMono(
        color: color, fontSize: 8, fontWeight: FontWeight.bold,
      )),
    );
  }
}

// ── Partikel Painter ───────────────────────────────────
class _Particle {
  double x, y;
  final double size, speed, angle, opacity;
  _Particle({
    required this.x, required this.y,
    required this.size, required this.speed,
    required this.angle, required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  const _ParticlePainter(this.particles, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        Paint()..color = color.withValues(alpha: p.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ── Boot Entry ─────────────────────────────────────────
class _BootEntry {
  final String agent, message;
  final bool isSuccess;
  const _BootEntry(this.agent, this.message, this.isSuccess);
}

// ── Eye Painter (verbessert) ───────────────────────────
class _SplashEyePainter extends CustomPainter {
  final double t;
  final dynamic palette;
  _SplashEyePainter({required this.t, required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette;
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // Äußere Glow-Ringe
    for (int i = 5; i >= 1; i--) {
      final ringR = maxR * (0.45 + i * 0.1) + sin(t * 2 * pi + i) * 3.5;
      canvas.drawCircle(
        center, ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = p.primary.withValues(alpha: 0.05 * i),
      );
    }

    // Rotierende gestrichelte Ringe
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(t * 2 * pi);
    _drawDashedCircle(canvas, maxR * 0.88, 24, p.primary.withValues(alpha: 0.5));
    canvas.restore();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-t * 2 * pi * 0.6);
    _drawDashedCircle(canvas, maxR * 0.7, 16, p.accent.withValues(alpha: 0.35));
    canvas.restore();

    // Datenstrahl-Hintergrund
    for (int i = 0; i < 12; i++) {
      final angle = t * 2 * pi * 0.4 + i * pi / 6;
      final len = maxR * (0.5 + sin(t * 2 * pi + i * 0.7) * 0.2);
      canvas.drawLine(
        center,
        center + Offset(cos(angle) * len, sin(angle) * len),
        Paint()
          ..color = p.primary.withValues(alpha: 0.07)
          ..strokeWidth = 1,
      );
    }

    // Auge
    final eyeW = maxR * 1.3;
    final eyeH = maxR * 0.75;
    final eyePath = Path()
      ..moveTo(center.dx - eyeW / 2, center.dy)
      ..quadraticBezierTo(center.dx, center.dy - eyeH / 2, center.dx + eyeW / 2, center.dy)
      ..quadraticBezierTo(center.dx, center.dy + eyeH / 2, center.dx - eyeW / 2, center.dy);

    final eyeRect = Rect.fromCenter(center: center, width: eyeW, height: eyeH);
    canvas.drawPath(eyePath, Paint()
      ..shader = RadialGradient(
        colors: [p.primary.withValues(alpha: 0.18), Colors.transparent],
      ).createShader(eyeRect),
    );
    canvas.drawPath(eyePath, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = p.primary,
    );

    // Iris mit Glow
    final irisR = maxR * 0.28 + sin(t * 2 * pi) * 2;
    canvas.drawCircle(center, irisR + 4,
        Paint()..color = p.primary.withValues(alpha: 0.15));
    canvas.drawCircle(center, irisR, Paint()
      ..shader = RadialGradient(
        colors: p.eyeGradient, stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: irisR)),
    );
    canvas.drawCircle(center, irisR, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = p.primary,
    );

    // Pupille
    final pupilR = maxR * 0.13;
    canvas.drawCircle(center, pupilR, Paint()..color = const Color(0xFF050A14));
    canvas.drawCircle(center, pupilR, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = p.accent,
    );

    // Glanz
    canvas.drawCircle(
      Offset(center.dx - pupilR * 0.38, center.dy - pupilR * 0.38),
      pupilR * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    // Orbitierende Punkte
    for (int i = 0; i < 4; i++) {
      final angle = t * 2 * pi + i * pi / 2;
      final orbitR = maxR * 0.88;
      final dotPos = center + Offset(cos(angle) * orbitR, sin(angle) * orbitR);
      final dotSize = 3.0 + sin(t * 2 * pi + i) * 1.5;
      canvas.drawCircle(dotPos, dotSize,
          Paint()..color = p.secondary.withValues(alpha: 0.85));
      canvas.drawCircle(dotPos, dotSize + 3,
          Paint()..color = p.secondary.withValues(alpha: 0.15));
    }
  }

  void _drawDashedCircle(Canvas canvas, double radius, int dashes, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;
    final path = Path();
    final dashAngle = 2 * pi / dashes;
    for (int i = 0; i < dashes; i++) {
      if (i % 2 == 0) {
        path.arcTo(
          Rect.fromCircle(center: Offset.zero, radius: radius),
          i * dashAngle, dashAngle * 0.55, true,
        );
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SplashEyePainter old) => old.t != t;
}
