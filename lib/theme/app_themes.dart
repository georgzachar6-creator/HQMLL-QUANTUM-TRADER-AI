import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  QUANTUM THEME ENUM
// ─────────────────────────────────────────────
enum QuantumTheme {
  enterprise, // Quantum Deep Blue – Haupt-Theme
  luxury,     // Quantum Nebula Violet
  matrix,     // Quantum Eigenstate Green
}

// ─────────────────────────────────────────────
//  THEME PALETTE
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
    // ── QUANTUM DEEP BLUE ────────────────────────────────────────────────────
    // Inspiriert durch Cerenkov-Strahlung und Quantenverschränkung
    // Tiefes Marineblau mit kaltem Cyan-Schimmer
    QuantumTheme.enterprise: QuantumPalette(
      name: 'Quantum Deep Blue',
      subtitle: 'Cerenkov · Cyan · Void',
      primary:        Color(0xFF00C8F5),   // Cerenkov-Blau
      secondary:      Color(0xFF0066CC),   // Quantenzustand-Blau
      accent:         Color(0xFF00F0C0),   // Eigenwert-Cyan
      background:     Color(0xFF03060F),   // Quantenvakuum
      surface:        Color(0xFF080E1C),   // Superpositional-Dunkel
      surfaceVariant: Color(0xFF0D1628),   // Dekohärenz-Layer
      onSurface:      Color(0xFF142233),   // Wellenfunktion-Oberfläche
      positive:       Color(0xFF00E8A0),   // Konstruktive Interferenz
      negative:       Color(0xFFFF3358),   // Destruktive Interferenz
      textPrimary:    Color(0xFFDCEEFF),   // Photonen-Weiß
      textSecondary:  Color(0xFF5E8FAA),   // Quantenrauschen
      gradientColors: [Color(0xFF03060F), Color(0xFF060D1E)],
      eyeGradient:    [Color(0xFF00C8F5), Color(0xFF0033AA), Color(0xFF00F0C0)],
      icon: Icons.remove_red_eye_outlined,
    ),

    // ── QUANTUM NEBULA VIOLET ────────────────────────────────────────────────
    // Inspiriert durch dunkle Materie und Quantenfeldtheorie
    // Tiefviolett mit Planck-Gold-Akzenten
    QuantumTheme.luxury: QuantumPalette(
      name: 'Quantum Nebula',
      subtitle: 'Dark Matter · Planck · Void',
      primary:        Color(0xFFA040F0),   // Quantenfeld-Violett
      secondary:      Color(0xFFD4A000),   // Planck-Gold
      accent:         Color(0xFFE060FF),   // Neutrino-Magenta
      background:     Color(0xFF04020C),   // Dunkle-Materie-Void
      surface:        Color(0xFF0C0818),   // Higgs-Feld-Dunkel
      surfaceVariant: Color(0xFF160E28),   // Bose-Einstein-Layer
      onSurface:      Color(0xFF201538),   // Fermion-Oberfläche
      positive:       Color(0xFFCCA000),   // Hawking-Gold
      negative:       Color(0xFFFF2244),   // Antimaterie-Rot
      textPrimary:    Color(0xFFEEE4FF),   // Stringtheorie-Weiß
      textSecondary:  Color(0xFF8060B0),   // Quanten-Grau-Violett
      gradientColors: [Color(0xFF04020C), Color(0xFF0C0820)],
      eyeGradient:    [Color(0xFFA040F0), Color(0xFF500080), Color(0xFFD4A000)],
      icon: Icons.auto_awesome,
    ),

    // ── QUANTUM EIGENSTATE GREEN ─────────────────────────────────────────────
    // Inspiriert durch Schrödinger-Gleichungen und Materiewellen
    // Tiefes Bio-Quantengrün im Terminalstil
    QuantumTheme.matrix: QuantumPalette(
      name: 'Quantum Eigenstate',
      subtitle: 'Schrodinger · Eigenvalue · Void',
      primary:        Color(0xFF00EE70),   // Eigenwert-Grün
      secondary:      Color(0xFF00AA44),   // Wellenfunktion-Grün
      accent:         Color(0xFF60FFB0),   // Superpositional-Hellgrün
      background:     Color(0xFF020806),   // Null-Punkt-Schwarz
      surface:        Color(0xFF060F09),   // Quantenzustand-Dunkel
      surfaceVariant: Color(0xFF0B1A10),   // Hamiltonoperator-Layer
      onSurface:      Color(0xFF112A18),   // Potential-Oberfläche
      positive:       Color(0xFF00EE70),   // Konstruktiv
      negative:       Color(0xFFFF3355),   // Destruktiv
      textPrimary:    Color(0xFFDDFFE8),   // Photon-Grün-Weiß
      textSecondary:  Color(0xFF4A9060),   // Quantenrauschen-Grün
      gradientColors: [Color(0xFF020806), Color(0xFF061208)],
      eyeGradient:    [Color(0xFF00EE70), Color(0xFF006630), Color(0xFF60FFB0)],
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
        bodyLarge:   GoogleFonts.inter(color: p.textPrimary, fontSize: 14, height: 1.5),
        bodyMedium:  GoogleFonts.inter(color: p.textSecondary, fontSize: 12, height: 1.5),
        titleLarge:  GoogleFonts.spaceMono(
            color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        titleMedium: GoogleFonts.spaceMono(
            color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall:  GoogleFonts.spaceMono(
            color: p.primary, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.8),
        headlineLarge: GoogleFonts.spaceMono(
            color: p.primary, fontSize: 28, fontWeight: FontWeight.bold),
        labelLarge:  GoogleFonts.spaceMono(
            color: p.primary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2),
        labelSmall:  GoogleFonts.spaceMono(
            color: p.textSecondary, fontSize: 10, letterSpacing: 1.0),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceMono(
          color: p.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.primary.withValues(alpha: 0.14), width: 1),
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
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: p.primary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: p.primary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: p.textSecondary, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      dividerColor: p.primary.withValues(alpha: 0.1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.background,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.spaceMono(
              fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.primary : Colors.grey[600]),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? p.primary.withValues(alpha: 0.35)
                : Colors.grey.withValues(alpha: 0.2)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.primary,
        thumbColor: p.primary,
        overlayColor: p.primary.withValues(alpha: 0.15),
        inactiveTrackColor: p.primary.withValues(alpha: 0.15),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.primary.withValues(alpha: 0.25)),
        ),
      ),
    );
  }
}
