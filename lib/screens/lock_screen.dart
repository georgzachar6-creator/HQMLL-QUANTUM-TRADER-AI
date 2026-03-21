import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import 'main_scaffold.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with TickerProviderStateMixin {
  static const String _correctPin = '1985'; // Grigori Saks PIN

  final List<String> _enteredDigits = [];
  bool _error = false;
  bool _success = false;
  int _attempts = 0;
  bool _locked = false;
  int _lockCountdown = 30;
  Timer? _lockTimer;
  Timer? _particleTimer;

  late AnimationController _glowCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _successCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _shakeAnim;
  late Animation<double> _successScale; // ignore: unused_field

  final List<_Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    _successCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut),
    );

    _particleCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    )..repeat();

    // Partikel erzeugen
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        speed: 0.001 + _rng.nextDouble() * 0.003,
        size: 1.0 + _rng.nextDouble() * 2.5,
        opacity: 0.2 + _rng.nextDouble() * 0.5,
      ));
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _shakeCtrl.dispose();
    _successCtrl.dispose();
    _particleCtrl.dispose();
    _lockTimer?.cancel();
    _particleTimer?.cancel();
    super.dispose();
  }

  void _onDigit(String d) {
    if (_locked || _success || _enteredDigits.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _error = false;
      _enteredDigits.add(d);
    });
    if (_enteredDigits.length == 4) {
      _checkPin();
    }
  }

  void _onDelete() {
    if (_locked || _success || _enteredDigits.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _error = false;
      _enteredDigits.removeLast();
    });
  }

  void _checkPin() {
    final entered = _enteredDigits.join();
    if (entered == _correctPin) {
      HapticFeedback.heavyImpact();
      setState(() => _success = true);
      _successCtrl.forward();
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, __) => const MainScaffold(),
              transitionsBuilder: (_, anim, __, child) => FadeTransition(
                opacity: anim, child: child,
              ),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      });
    } else {
      HapticFeedback.vibrate();
      _attempts++;
      _shakeCtrl.forward(from: 0);
      setState(() => _error = true);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _enteredDigits.clear());
      });

      if (_attempts >= 3) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              _locked = true;
              _lockCountdown = 30;
            });
            _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
              if (!mounted) { t.cancel(); return; }
              setState(() => _lockCountdown--);
              if (_lockCountdown <= 0) {
                t.cancel();
                setState(() { _locked = false; _attempts = 0; });
              }
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: p.background,
      body: AnimatedBuilder(
        animation: _glowCtrl,
        builder: (_, __) => Stack(
          children: [
            // ── Animierter Hintergrund ─────────────
            CustomPaint(
              size: size,
              painter: _LockBgPainter(_glowCtrl.value, _particleCtrl.value,
                  _particles, p),
            ),
            // ── Hauptinhalt ──────────────────────
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // App Logo + Name
                  _buildHeader(p),
                  const Spacer(flex: 2),
                  // PIN-Dots
                  _buildPinIndicator(p),
                  const SizedBox(height: 16),
                  // Status Text
                  _buildStatusText(p),
                  const Spacer(flex: 2),
                  // Numpad
                  _buildNumpad(p, size),
                  const SizedBox(height: 32),
                  // Biometric Button (simuliert)
                  _buildBiometricButton(p),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic p) {
    return Column(children: [
      // Pulsierendes Logo
      AnimatedBuilder(
        animation: _glowCtrl,
        builder: (_, __) => Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _success
                  ? p.positive.withValues(alpha: 0.8)
                  : p.primary.withValues(alpha: 0.4 + _glowCtrl.value * 0.3),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (_success ? p.positive : p.primary)
                    .withValues(alpha: 0.15 + _glowCtrl.value * 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset('assets/icons/app_icon.png', fit: BoxFit.cover),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text('HQMLL QUANTUM TRADER', style: GoogleFonts.rajdhani(
          color: p.primary, fontSize: 20,
          fontWeight: FontWeight.bold, letterSpacing: 4)),
      const SizedBox(height: 6),
      Text('Sicherer Zugang · G. Saks', style: GoogleFonts.spaceMono(
          color: p.textSecondary, fontSize: 10, letterSpacing: 1)),
    ]);
  }

  Widget _buildPinIndicator(dynamic p) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, __) {
        final shake = sin(_shakeAnim.value * pi * 6) * 12;
        return Transform.translate(
          offset: Offset(_error ? shake : 0, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < _enteredDigits.length;
              final isActive = i == _enteredDigits.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _success
                      ? p.positive.withValues(alpha: 0.2)
                      : _error
                          ? p.negative.withValues(alpha: 0.2)
                          : filled
                              ? p.primary.withValues(alpha: 0.15)
                              : p.surfaceVariant,
                  border: Border.all(
                    color: _success
                        ? p.positive
                        : _error
                            ? p.negative
                            : filled
                                ? p.primary
                                : isActive
                                    ? p.primary.withValues(alpha: 0.5)
                                    : p.primary.withValues(alpha: 0.15),
                    width: filled || isActive ? 2 : 1,
                  ),
                  boxShadow: filled
                      ? [BoxShadow(
                          color: (_success ? p.positive : _error ? p.negative : p.primary)
                              .withValues(alpha: 0.3),
                          blurRadius: 12)]
                      : null,
                ),
                child: filled
                    ? Icon(
                        _success ? Icons.check : Icons.circle,
                        color: _success ? p.positive : _error ? p.negative : p.primary,
                        size: _success ? 24 : 16,
                      )
                    : null,
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildStatusText(dynamic p) {
    if (_locked) {
      return Column(children: [
        Icon(Icons.lock_clock, color: p.negative, size: 22),
        const SizedBox(height: 6),
        Text('Zu viele Versuche · $_lockCountdown Sek.',
            style: GoogleFonts.spaceMono(color: p.negative, fontSize: 11,
                fontWeight: FontWeight.bold)),
      ]);
    }
    if (_success) {
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.verified, color: p.positive, size: 18),
        const SizedBox(width: 8),
        Text('Zugang gewährt', style: GoogleFonts.rajdhani(
            color: p.positive, fontSize: 16, fontWeight: FontWeight.bold)),
      ]);
    }
    if (_error) {
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, color: p.negative, size: 16),
        const SizedBox(width: 6),
        Text(_attempts >= 2
            ? 'Falscher PIN · Noch ${3 - _attempts} Versuch(e)'
            : 'Falscher PIN',
            style: GoogleFonts.spaceMono(color: p.negative, fontSize: 10)),
      ]);
    }
    return Text(
      _enteredDigits.isEmpty ? 'PIN eingeben' : '${_enteredDigits.length} von 4',
      style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10,
          letterSpacing: 1),
    );
  }

  Widget _buildNumpad(dynamic p, Size size) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: keys.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: row.map((k) {
              if (k.isEmpty) return const SizedBox(width: 72, height: 72);
              final isDelete = k == '⌫';
              return _NumpadKey(
                label: k,
                isDelete: isDelete,
                palette: p,
                locked: _locked || _success,
                onTap: () => isDelete ? _onDelete() : _onDigit(k),
              );
            }).toList(),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildBiometricButton(dynamic p) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        // Simuliere biometrische Authentifizierung
        setState(() {
          _enteredDigits.clear();
          _enteredDigits.addAll(['1', '9', '8', '5']);
        });
        Future.delayed(const Duration(milliseconds: 300), _checkPin);
      },
      child: AnimatedBuilder(
        animation: _glowCtrl,
        builder: (_, __) => Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.surfaceVariant,
            border: Border.all(
              color: p.primary.withValues(alpha: 0.2 + _glowCtrl.value * 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: p.primary.withValues(alpha: 0.05 + _glowCtrl.value * 0.08),
                blurRadius: 16, spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(Icons.fingerprint, color: p.primary.withValues(alpha: 0.7), size: 30),
        ),
      ),
    );
  }
}

// ── Numpad Key ────────────────────────────────────
class _NumpadKey extends StatefulWidget {
  final String label;
  final bool isDelete;
  final dynamic palette;
  final bool locked;
  final VoidCallback onTap;
  const _NumpadKey({
    required this.label, required this.isDelete,
    required this.palette, required this.locked, required this.onTap,
  });
  @override
  State<_NumpadKey> createState() => _NumpadKeyState();
}

class _NumpadKeyState extends State<_NumpadKey>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return GestureDetector(
      onTapDown: (_) { if (!widget.locked) _pressCtrl.forward(); },
      onTapUp: (_) {
        _pressCtrl.reverse();
        if (!widget.locked) widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (_, __) => Transform.scale(
          scale: 1.0 - _pressCtrl.value * 0.08,
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isDelete
                  ? p.surfaceVariant
                  : p.surface.withValues(
                      alpha: 1.0 - _pressCtrl.value * 0.2),
              border: Border.all(
                color: p.primary.withValues(
                    alpha: 0.15 + _pressCtrl.value * 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: p.primary.withValues(
                      alpha: 0.05 + _pressCtrl.value * 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: widget.isDelete
                  ? Icon(Icons.backspace_outlined,
                      color: p.textSecondary, size: 22)
                  : Text(widget.label,
                      style: GoogleFonts.rajdhani(
                          color: p.textPrimary, fontSize: 26,
                          fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Background Painter ────────────────────────────
class _LockBgPainter extends CustomPainter {
  final double t;
  final double pt;
  final List<_Particle> particles;
  final dynamic palette;
  _LockBgPainter(this.t, this.pt, this.particles, this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    // Hintergrund-Gradient
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.3),
        radius: 1.2,
        colors: [
          palette.primary.withValues(alpha: 0.06 + t * 0.04),
          palette.background,
          palette.background,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid-Linien
    final gridPaint = Paint()
      ..color = palette.primary.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Schwebende Partikel
    for (final p in particles) {
      final px = (p.x + pt * p.speed * 10) % 1.0;
      final py = (p.y + pt * p.speed * 5) % 1.0;
      final paint = Paint()
        ..color = palette.primary.withValues(
            alpha: p.opacity * (0.5 + sin(pt * pi * 2) * 0.3));
      canvas.drawCircle(
        Offset(px * size.width, py * size.height),
        p.size, paint,
      );
    }

    // Kreisförmige Wellen
    for (int i = 0; i < 3; i++) {
      final phase = (t + i * 0.33) % 1.0;
      final wavePaint = Paint()
        ..color = palette.primary.withValues(alpha: (1 - phase) * 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.28),
        phase * size.width * 0.6,
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_LockBgPainter old) => old.t != t || old.pt != pt;
}

class _Particle {
  final double x, y, speed, size, opacity;
  const _Particle({
    required this.x, required this.y, required this.speed,
    required this.size, required this.opacity,
  });
}
