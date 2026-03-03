import 'dart:math';
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
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _progressAnim;

  int _logIndex = 0;
  final List<String> _bootLog = [
    'META-ORCHESTRATOR: Initialisierung...',
    'SECURITY AGENT: Zero-Trust aktiviert...',
    'DEEP RESEARCH AGENT: Datenquellen verbunden...',
    'PATTERN GENESIS AGENT: Muster-Bibliothek geladen...',
    'SENTIENT MARKET AGENT: Sentiment-Stream aktiv...',
    'PARADIGM SHIFT AGENT: Anomalie-Scanner bereit...',
    'ERROR & ANOMALY AGENT: Selbstheilung aktiv...',
    'STRATEGIC SYNTHESIS AGENT: Bereit...',
    'QUANTUM ORACLE: Resonanz-Kalibrierung...',
    'EMMA AI: Alle Systeme bereit · G. Saks Oracle aktiviert!',
  ];

  @override
  void initState() {
    super.initState();
    _masterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500))..forward();

    _fadeIn = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);
    _scaleIn = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.elasticOut));
    _progressAnim = CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut);

    _textCtrl.forward();

    // Boot log stepper
    for (int i = 0; i < _bootLog.length; i++) {
      Future.delayed(Duration(milliseconds: 300 + i * 380), () {
        if (mounted) setState(() => _logIndex = i + 1);
      });
    }

    // Navigate after splash
    Future.delayed(const Duration(milliseconds: 5200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainScaffold(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 800),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Eye
                  FadeTransition(
                    opacity: _fadeIn,
                    child: ScaleTransition(
                      scale: _scaleIn,
                      child: AnimatedBuilder(
                        animation: _masterCtrl,
                        builder: (_, __) => SizedBox(
                          width: 160,
                          height: 160,
                          child: CustomPaint(
                            painter: _SplashEyePainter(
                              t: _masterCtrl.value,
                              palette: p,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _fadeIn,
                    child: Column(
                      children: [
                        Text(
                          'HQMLL QUANTUM',
                          style: GoogleFonts.rajdhani(
                            color: p.primary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 5,
                          ),
                        ),
                        Text(
                          'HYPER-QUANTUM META-LEARNING-LOOP',
                          style: GoogleFonts.exo(
                            color: p.textSecondary,
                            fontSize: 10,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Emma Oracle · Eigentümer: Grigori Saks',
                          style: GoogleFonts.exo(
                            color: p.primary.withValues(alpha: 0.7),
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Boot Log
            Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.terminal, color: p.primary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'HQMLL BOOT SEQUENCE',
                      style: GoogleFonts.robotoMono(
                        color: p.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _logIndex,
                      itemBuilder: (_, i) {
                        final isLast = i == _logIndex - 1;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.5),
                          child: Row(
                            children: [
                              Text(
                                isLast ? '▶ ' : '✓ ',
                                style: TextStyle(
                                  color: isLast ? p.primary : p.positive,
                                  fontSize: 10,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _bootLog[i],
                                  style: GoogleFonts.robotoMono(
                                    color: isLast ? p.textPrimary : p.textSecondary,
                                    fontSize: 10,
                                    fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
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

            // Progress Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) => Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'System wird geladen...',
                              style: TextStyle(color: p.textSecondary, fontSize: 11),
                            ),
                            Text(
                              '${(_progressAnim.value * 100).toInt()}%',
                              style: TextStyle(
                                  color: p.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progressAnim.value,
                            backgroundColor: p.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(p.primary),
                            minHeight: 4,
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
    );
  }
}

class _SplashEyePainter extends CustomPainter {
  final double t;
  final dynamic palette;
  _SplashEyePainter({required this.t, required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette;
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // Outer glow rings (pulsing)
    for (int i = 5; i >= 1; i--) {
      final ringR = maxR * (0.5 + i * 0.1) + sin(t * 2 * pi + i) * 4;
      canvas.drawCircle(
        center,
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = p.primary.withValues(alpha: 0.06 * i),
      );
    }

    // Rotating orbit ring
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(t * 2 * pi);
    _drawDashedCircle(canvas, maxR * 0.9, 20, p.primary.withValues(alpha: 0.5));
    canvas.restore();

    // Counter-rotating ring
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-t * 2 * pi * 0.7);
    _drawDashedCircle(canvas, maxR * 0.72, 14, p.accent.withValues(alpha: 0.4));
    canvas.restore();

    // Eye shape
    final eyeW = maxR * 1.2;
    final eyeH = maxR * 0.72;
    final eyePath = Path()
      ..moveTo(center.dx - eyeW / 2, center.dy)
      ..quadraticBezierTo(center.dx, center.dy - eyeH / 2, center.dx + eyeW / 2, center.dy)
      ..quadraticBezierTo(center.dx, center.dy + eyeH / 2, center.dx - eyeW / 2, center.dy);

    final eyeRect = Rect.fromCenter(center: center, width: eyeW, height: eyeH);
    canvas.drawPath(
      eyePath,
      Paint()
        ..shader = RadialGradient(
          colors: [p.primary.withValues(alpha: 0.2), Colors.transparent],
        ).createShader(eyeRect),
    );
    canvas.drawPath(
      eyePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = p.primary,
    );

    // Iris
    final irisR = maxR * 0.3 + sin(t * 2 * pi) * 2;
    canvas.drawCircle(
      center,
      irisR,
      Paint()
        ..shader = RadialGradient(
          colors: p.eyeGradient,
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: irisR)),
    );
    canvas.drawCircle(
      center,
      irisR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = p.primary,
    );

    // Pupil
    final pupilR = maxR * 0.14;
    canvas.drawCircle(center, pupilR, Paint()..color = Colors.black);
    canvas.drawCircle(
      center,
      pupilR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = p.accent,
    );

    // Sparkle
    canvas.drawCircle(
      Offset(center.dx - pupilR * 0.4, center.dy - pupilR * 0.4),
      pupilR * 0.25,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );

    // Rotating frequency spokes
    for (int i = 0; i < 8; i++) {
      final angle = t * 2 * pi * 0.5 + i * pi / 4;
      final spokeLen = maxR * 0.85;
      final x = cos(angle) * spokeLen;
      final y = sin(angle) * spokeLen;
      canvas.drawLine(
        center,
        center + Offset(x, y),
        Paint()
          ..color = p.primary.withValues(alpha: 0.12)
          ..strokeWidth = 1,
      );
    }

    // Orbiting dots
    for (int i = 0; i < 3; i++) {
      final angle = t * 2 * pi + i * 2 * pi / 3;
      final orbitR = maxR * 0.9;
      final dotPos = center + Offset(cos(angle) * orbitR, sin(angle) * orbitR);
      canvas.drawCircle(dotPos, 4, Paint()..color = p.secondary.withValues(alpha: 0.8));
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
          i * dashAngle,
          dashAngle * 0.55,
          true,
        );
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SplashEyePainter old) => old.t != t;
}
