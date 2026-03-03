import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_themes.dart';

class QuantumEyeWidget extends StatefulWidget {
  final QuantumPalette palette;
  final double size;
  final bool animate;
  final bool showLabel;

  const QuantumEyeWidget({
    super.key,
    required this.palette,
    this.size = 80,
    this.animate = true,
    this.showLabel = false,
  });

  @override
  State<QuantumEyeWidget> createState() => _QuantumEyeWidgetState();
}

class _QuantumEyeWidgetState extends State<QuantumEyeWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _rotCtrl;
  late AnimationController _ringCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _rotAnim;
  late Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _rotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 8000))
      ..repeat();
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);

    _pulseAnim =
        Tween<double>(begin: 0.92, end: 1.08).animate(CurvedAnimation(
      parent: _pulseCtrl,
      curve: Curves.easeInOut,
    ));
    _rotAnim = Tween<double>(begin: 0, end: 2 * pi).animate(_rotCtrl);
    _ringAnim =
        Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(
      parent: _ringCtrl,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    if (!widget.animate) {
      return _buildStaticEye(p);
    }
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, _rotAnim, _ringAnim]),
      builder: (ctx, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _QuantumEyePainter(
              palette: p,
              pulse: _pulseAnim.value,
              rotation: _rotAnim.value,
              ringOpacity: _ringAnim.value,
            ),
            child: widget.showLabel
                ? Center(
                    child: Text(
                      'G·S',
                      style: TextStyle(
                        color: p.primary,
                        fontSize: widget.size * 0.15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildStaticEye(QuantumPalette p) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _QuantumEyePainter(
          palette: p,
          pulse: 1.0,
          rotation: 0,
          ringOpacity: 0.8,
        ),
      ),
    );
  }
}

class _QuantumEyePainter extends CustomPainter {
  final QuantumPalette palette;
  final double pulse;
  final double rotation;
  final double ringOpacity;

  _QuantumEyePainter({
    required this.palette,
    required this.pulse,
    required this.rotation,
    required this.ringOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // Outer glow rings
    for (int i = 3; i >= 1; i--) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = palette.primary
            .withValues(alpha: 0.08 * i * ringOpacity);
      canvas.drawCircle(center, maxR * (0.7 + i * 0.12) * pulse, ringPaint);
    }

    // Rotating dashed ring
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = palette.primary.withValues(alpha: 0.5);
    _drawDashedCircle(canvas, maxR * 0.85, dashPaint, 24);
    canvas.restore();

    // Rotating dashed ring reverse
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-rotation * 0.6);
    final dashPaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = palette.accent.withValues(alpha: 0.35);
    _drawDashedCircle(canvas, maxR * 0.7, dashPaint2, 16);
    canvas.restore();

    // Main eye shape (ellipse)
    final eyeRect = Rect.fromCenter(
        center: center,
        width: maxR * 1.3 * pulse,
        height: maxR * 0.78 * pulse);
    final eyePath = Path()
      ..moveTo(center.dx - maxR * 0.65 * pulse, center.dy)
      ..quadraticBezierTo(center.dx, center.dy - maxR * 0.42 * pulse,
          center.dx + maxR * 0.65 * pulse, center.dy)
      ..quadraticBezierTo(center.dx, center.dy + maxR * 0.42 * pulse,
          center.dx - maxR * 0.65 * pulse, center.dy);

    // Eye glow fill
    final eyeFillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.primary.withValues(alpha: 0.18),
          palette.secondary.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(eyeRect);
    canvas.drawPath(eyePath, eyeFillPaint);

    // Eye border
    final eyeBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = palette.primary.withValues(alpha: 0.8);
    canvas.drawPath(eyePath, eyeBorderPaint);

    // Iris gradient circle
    final irisR = maxR * 0.32 * pulse;
    final irisPaint = Paint()
      ..shader = RadialGradient(
        colors: palette.eyeGradient,
        stops: const [0.0, 0.6, 1.0],
      ).createShader(
          Rect.fromCircle(center: center, radius: irisR));
    canvas.drawCircle(center, irisR, irisPaint);

    // Iris ring
    canvas.drawCircle(
        center,
        irisR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = palette.primary.withValues(alpha: 0.9));

    // Pupil
    final pupilR = maxR * 0.13;
    final pupilPaint = Paint()..color = Colors.black87;
    canvas.drawCircle(center, pupilR, pupilPaint);
    canvas.drawCircle(
        center,
        pupilR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = palette.accent.withValues(alpha: 0.9));

    // Highlight sparkle
    final sparkleOffset = Offset(center.dx - pupilR * 0.5, center.dy - pupilR * 0.5);
    canvas.drawCircle(sparkleOffset, pupilR * 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.8));

    // Frequency lines (quantum resonance)
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = palette.primary.withValues(alpha: 0.25 * ringOpacity);
    for (int i = 0; i < 6; i++) {
      final angle = rotation + (i * pi / 3);
      final dx = cos(angle) * maxR * 0.9;
      final dy = sin(angle) * maxR * 0.9;
      canvas.drawLine(center, center + Offset(dx, dy), linePaint);
    }
  }

  void _drawDashedCircle(
      Canvas canvas, double radius, Paint paint, int dashes) {
    final path = Path();
    final dashAngle = (2 * pi) / dashes;
    for (int i = 0; i < dashes; i++) {
      if (i % 2 == 0) {
        final start = i * dashAngle;
        final end = start + dashAngle * 0.6;
        path.arcTo(
          Rect.fromCircle(center: Offset.zero, radius: radius),
          start,
          end - start,
          true,
        );
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_QuantumEyePainter old) =>
      old.pulse != pulse ||
      old.rotation != rotation ||
      old.ringOpacity != ringOpacity;
}
