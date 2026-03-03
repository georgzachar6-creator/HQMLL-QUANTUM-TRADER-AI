import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  QUANTUM THEME ENUM
// ─────────────────────────────────────────────
enum QuantumTheme {
  enterprise,  // Blau / Cyan
  luxury,      // Lila / Gold
  matrix,      // Grün / Dunkel
}

// ─────────────────────────────────────────────
//  THEME PALETTE – alle Farben pro Theme
// ─────────────────────────────────────────────
class QuantumPalette {
  final String name;
  final String subtitle;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color onSurface;
  final Color positive;
  final Color negative;
  final Color textPrimary;
  final Color textSecondary;
  final List<Color> gradientColors;
  final List<Color> eyeGradient;
  final IconData icon;

  const QuantumPalette({
    required this.name,
    required this.subtitle,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.onSurface,
    required this.positive,
    required this.negative,
    required this.textPrimary,
    required this.textSecondary,
    required this.gradientColors,
    required this.eyeGradient,
    required this.icon,
  });
}

class AppThemes {
  static const Map<QuantumTheme, QuantumPalette> palettes = {
    QuantumTheme.enterprise: QuantumPalette(
      name: 'Quantum Enterprise',
      subtitle: 'Blau · Cyan · Schwarz',
      primary: Color(0xFF00D4FF),
      secondary: Color(0xFF0080FF),
      accent: Color(0xFF00FFC8),
      background: Color(0xFF050A12),
      surface: Color(0xFF0D1621),
      surfaceVariant: Color(0xFF122030),
      onSurface: Color(0xFF1A2E45),
      positive: Color(0xFF00FFC8),
      negative: Color(0xFFFF4D6A),
      textPrimary: Color(0xFFE8F4FF),
      textSecondary: Color(0xFF7BA8CC),
      gradientColors: [Color(0xFF050A12), Color(0xFF0D1E35)],
      eyeGradient: [Color(0xFF00D4FF), Color(0xFF0040FF), Color(0xFF00FFC8)],
      icon: Icons.remove_red_eye_outlined,
    ),
    QuantumTheme.luxury: QuantumPalette(
      name: 'Quantum Oracle Luxury',
      subtitle: 'Lila · Gold · Dunkel',
      primary: Color(0xFFB060FF),
      secondary: Color(0xFFFFD700),
      accent: Color(0xFFFF80FF),
      background: Color(0xFF080510),
      surface: Color(0xFF120D20),
      surfaceVariant: Color(0xFF1C1530),
      onSurface: Color(0xFF261D40),
      positive: Color(0xFFFFD700),
      negative: Color(0xFFFF4D6A),
      textPrimary: Color(0xFFF0E8FF),
      textSecondary: Color(0xFF9B80CC),
      gradientColors: [Color(0xFF080510), Color(0xFF150D28)],
      eyeGradient: [Color(0xFFB060FF), Color(0xFF6020C0), Color(0xFFFFD700)],
      icon: Icons.auto_awesome,
    ),
    QuantumTheme.matrix: QuantumPalette(
      name: 'Quantum Matrix',
      subtitle: 'Grün · Smaragd · Schwarz',
      primary: Color(0xFF00FF88),
      secondary: Color(0xFF00CC66),
      accent: Color(0xFF80FFB8),
      background: Color(0xFF030A05),
      surface: Color(0xFF0A1A0D),
      surfaceVariant: Color(0xFF102815),
      onSurface: Color(0xFF163520),
      positive: Color(0xFF00FF88),
      negative: Color(0xFFFF4D6A),
      textPrimary: Color(0xFFE0FFE8),
      textSecondary: Color(0xFF60AA80),
      gradientColors: [Color(0xFF030A05), Color(0xFF0A1E10)],
      eyeGradient: [Color(0xFF00FF88), Color(0xFF008844), Color(0xFF80FFB8)],
      icon: Icons.grid_on,
    ),
  };

  static QuantumPalette getPalette(QuantumTheme theme) => palettes[theme]!;

  static ThemeData buildTheme(QuantumTheme quantumTheme) {
    final p = getPalette(quantumTheme);
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      colorScheme: ColorScheme.dark(
        primary: p.primary,
        secondary: p.secondary,
        surface: p.surface,
        onSurface: p.textPrimary,
        error: p.negative,
      ),
      textTheme: GoogleFonts.exoTextTheme(base.textTheme).copyWith(
        bodyLarge: GoogleFonts.exo(color: p.textPrimary, fontSize: 15),
        bodyMedium: GoogleFonts.exo(color: p.textSecondary, fontSize: 13),
        titleLarge: GoogleFonts.rajdhani(
            color: p.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.rajdhani(
            color: p.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.rajdhani(
            color: p.primary, fontSize: 14, fontWeight: FontWeight.w600),
        headlineLarge: GoogleFonts.rajdhani(
            color: p.primary, fontSize: 32, fontWeight: FontWeight.bold),
        labelLarge: GoogleFonts.rajdhani(
            color: p.primary, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.rajdhani(
          color: p.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.primary.withValues(alpha: 0.18), width: 1),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.primary,
        unselectedItemColor: p.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.exo(color: p.textSecondary, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerColor: p.primary.withValues(alpha: 0.12),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.background,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.rajdhani(
              fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.primary : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? p.primary.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.3)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.primary,
        thumbColor: p.primary,
        overlayColor: p.primary.withValues(alpha: 0.2),
        inactiveTrackColor: p.primary.withValues(alpha: 0.2),
      ),
    );
  }
}
