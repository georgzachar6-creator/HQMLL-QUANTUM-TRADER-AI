// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
//  HQMLL PREMIUM BUTTON LIBRARY — v15.0
//  Quantum Trader AI System — UI Components
// ═══════════════════════════════════════════════════════════════

// ── 1. Quantum Glow Button ────────────────────────────────────
class QuantumGlowButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color primaryColor;
  final Color secondaryColor;
  final double width;
  final double height;
  final bool isLoading;
  final bool outlined;

  const QuantumGlowButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.primaryColor = const Color(0xFF00FF88),
    this.secondaryColor = const Color(0xFF00AAFF),
    this.width = double.infinity,
    this.height = 52,
    this.isLoading = false,
    this.outlined = false,
  });

  @override
  State<QuantumGlowButton> createState() => _QuantumGlowButtonState();
}

class _QuantumGlowButtonState extends State<QuantumGlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: widget.outlined
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Color.lerp(widget.primaryColor,
                          widget.secondaryColor, _glow.value)!,
                      width: 1.5,
                    ),
                    color: widget.primaryColor.withValues(alpha: 0.08),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor
                            .withValues(alpha: _glow.value * 0.2),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  )
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [widget.primaryColor, widget.secondaryColor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor
                            .withValues(alpha: _glow.value * 0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            widget.outlined
                                ? widget.primaryColor
                                : Colors.black),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon,
                              size: 18,
                              color: widget.outlined
                                  ? Color.lerp(widget.primaryColor,
                                      widget.secondaryColor, _glow.value)
                                  : Colors.black),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: GoogleFonts.rajdhani(
                            color: widget.outlined
                                ? Color.lerp(widget.primaryColor,
                                    widget.secondaryColor, _glow.value)
                                : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 2. Quantum Pulse Icon Button ──────────────────────────────
class QuantumPulseIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final double size;
  final String? badge;
  final String? tooltip;

  const QuantumPulseIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color = const Color(0xFF00FF88),
    this.size = 48,
    this.badge,
    this.tooltip,
  });

  @override
  State<QuantumPulseIconButton> createState() =>
      _QuantumPulseIconButtonState();
}

class _QuantumPulseIconButtonState extends State<QuantumPulseIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget btn = AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.12),
                border: Border.all(
                    color: widget.color.withValues(alpha: _pulse.value * 0.7),
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: _pulse.value * 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(widget.icon, color: widget.color, size: widget.size * 0.44),
            ),
            if (widget.badge != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFF4466),
                  ),
                  child: Center(
                    child: Text(widget.badge!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}

// ── 3. Quantum Toggle Button ──────────────────────────────────
class QuantumToggleButton extends StatefulWidget {
  final String labelOn;
  final String labelOff;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;

  const QuantumToggleButton({
    super.key,
    required this.labelOn,
    required this.labelOff,
    required this.value,
    this.onChanged,
    this.activeColor = const Color(0xFF00FF88),
  });

  @override
  State<QuantumToggleButton> createState() => _QuantumToggleButtonState();
}

class _QuantumToggleButtonState extends State<QuantumToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.value) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant QuantumToggleButton old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) {
      widget.value ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged?.call(!widget.value),
      child: AnimatedBuilder(
        animation: _slide,
        builder: (_, __) => Container(
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Color.lerp(
                    const Color(0xFF1A3A5C), widget.activeColor, _slide.value)!
                    .withValues(alpha: 0.6)),
            color: Color.lerp(const Color(0xFF0A1628),
                widget.activeColor.withValues(alpha: 0.12), _slide.value),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 10),
              // Slider thumb
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.value
                      ? widget.activeColor
                      : const Color(0xFF3A6080),
                  boxShadow: widget.value
                      ? [
                          BoxShadow(
                            color: widget.activeColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                          )
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.value ? widget.labelOn : widget.labelOff,
                style: GoogleFonts.spaceMono(
                  color: widget.value ? widget.activeColor : const Color(0xFF7AAFC8),
                  fontSize: 10,
                  fontWeight: widget.value ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 4. Quantum Chip Tag ───────────────────────────────────────
class QuantumChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool active;
  final VoidCallback? onTap;

  const QuantumChip({
    super.key,
    required this.label,
    this.color = const Color(0xFF00AAFF),
    this.icon,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? color : color.withValues(alpha: 0.3),
              width: active ? 1.5 : 1),
          color: active ? color.withValues(alpha: 0.15) : const Color(0xFF0A1628),
          boxShadow: active
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: active ? color : color.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.spaceMono(
                color: active ? color : color.withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 5. Quantum Progress Button ────────────────────────────────
class QuantumProgressButton extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;
  final VoidCallback? onTap;

  const QuantumProgressButton({
    super.key,
    required this.label,
    required this.progress,
    this.color = const Color(0xFF00FF88),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          color: const Color(0xFF0A1628),
        ),
        child: Stack(
          children: [
            // Progress fill
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
                  ),
                ),
              ),
            ),
            // Label
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.spaceMono(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: GoogleFonts.spaceMono(color: color, fontSize: 11),
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

// ── 6. Quantum Action FAB ─────────────────────────────────────
class QuantumFAB extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final String? label;

  const QuantumFAB({
    super.key,
    required this.icon,
    this.onTap,
    this.color = const Color(0xFF00FF88),
    this.label,
  });

  @override
  State<QuantumFAB> createState() => _QuantumFABState();
}

class _QuantumFABState extends State<QuantumFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ring;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _ring = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ring,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring
            Container(
              width: 64 + _ring.value * 12,
              height: 64 + _ring.value * 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withValues(alpha: (1 - _ring.value) * 0.5),
                  width: 1.5,
                ),
              ),
            ),
            // Main FAB
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [widget.color, widget.color.withValues(alpha: 0.6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.black, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 7. Quantum Danger Button ──────────────────────────────────
class QuantumDangerButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const QuantumDangerButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFF4466).withValues(alpha: 0.5)),
          gradient: const LinearGradient(
            colors: [Color(0xFF2A0A14), Color(0xFF1A0A0A)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4466).withValues(alpha: 0.2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: const Color(0xFFFF4466), size: 16),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.rajdhani(
                color: const Color(0xFFFF4466),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 8. Quantum Segmented Control ─────────────────────────────
class QuantumSegmentedControl extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;
  final Color activeColor;

  const QuantumSegmentedControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    this.onChanged,
    this.activeColor = const Color(0xFF00FF88),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1A3A5C)),
        color: const Color(0xFF0A1628),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final active = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged?.call(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: active ? activeColor : Colors.transparent,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    options[i],
                    style: GoogleFonts.spaceMono(
                      color: active ? Colors.black : const Color(0xFF7AAFC8),
                      fontSize: 9,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
