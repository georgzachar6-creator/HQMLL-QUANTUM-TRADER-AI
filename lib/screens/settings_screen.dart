import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';
import '../widgets/quantum_eye_widget.dart';
import 'quantum_monitor_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Owner Card
          _buildOwnerCard(p, tp),
          const SizedBox(height: 16),
          // SECTION: Erscheinungsbild
          _SectionTitle(title: 'ERSCHEINUNGSBILD', icon: Icons.palette_outlined, palette: p),
          const SizedBox(height: 8),
          _buildThemeSelector(context, tp, p),
          const SizedBox(height: 8),
          _buildCard(p, children: [
            _SwitchTile(label: 'Quantum-Animationen', subtitle: 'Pulsierende Auge & Wellen-Effekte', value: tp.quantumAnimations, onChanged: tp.setQuantumAnimations, icon: Icons.auto_awesome, palette: p),
            _DividerLine(p: p),
            _SwitchTile(label: 'Dark Charts', subtitle: 'Dunkler Hintergrund für Charts', value: tp.darkCharts, onChanged: tp.setDarkCharts, icon: Icons.bar_chart, palette: p),
            _DividerLine(p: p),
            _SliderTile(label: 'Schriftgröße', value: tp.fontSize, min: 0.8, max: 1.4, divisions: 6, onChanged: tp.setFontSize, icon: Icons.text_fields, palette: p, displayValue: '${(tp.fontSize * 100).toInt()}%'),
          ]),
          const SizedBox(height: 16),

          // SECTION: Sprache & Region
          _SectionTitle(title: 'SPRACHE & REGION', icon: Icons.language, palette: p),
          const SizedBox(height: 8),
          _buildCard(p, children: [
            _DropdownTile(
              label: 'Sprache', icon: Icons.language, palette: p,
              value: tp.language,
              items: const ['Deutsch', 'English', 'Русский', 'Español', '中文'],
              onChanged: tp.setLanguage,
            ),
            _DividerLine(p: p),
            _DropdownTile(
              label: 'Währung', icon: Icons.attach_money, palette: p,
              value: tp.currency,
              items: const ['USD', 'EUR', 'GBP', 'BTC', 'ETH'],
              onChanged: tp.setCurrency,
            ),
          ]),
          const SizedBox(height: 16),

          // SECTION: Daten & Trading
          _SectionTitle(title: 'DATEN & TRADING', icon: Icons.data_usage, palette: p),
          const SizedBox(height: 8),
          _buildCard(p, children: [
            _SwitchTile(label: 'Live-Daten', subtitle: 'Echtzeit-Kurse & Quantum-Signale', value: tp.liveDataEnabled, onChanged: tp.setLiveDataEnabled, icon: Icons.stream, palette: p),
            _DividerLine(p: p),
            _SwitchTile(label: 'Auto-Trading', subtitle: 'Emma führt Signale automatisch aus', value: tp.autoTrade, onChanged: tp.setAutoTrade, icon: Icons.smart_toy_outlined, palette: p),
            _DividerLine(p: p),
            _SliderTile(label: 'Risiko-Level', value: tp.riskLevel, min: 0.1, max: 1.0, divisions: 9, onChanged: tp.setRiskLevel, icon: Icons.warning_amber_outlined, palette: p, displayValue: _riskLabel(tp.riskLevel)),
          ]),
          const SizedBox(height: 16),

          // SECTION: Sicherheit
          _SectionTitle(title: 'SICHERHEIT', icon: Icons.security, palette: p),
          const SizedBox(height: 8),
          _buildCard(p, children: [
            _SwitchTile(label: 'Biometrische Authentifizierung', subtitle: 'Face-ID / Fingerabdruck', value: tp.biometricAuth, onChanged: tp.setBiometricAuth, icon: Icons.fingerprint, palette: p),
            _DividerLine(p: p),
            _SwitchTile(label: 'Zwei-Faktor-Auth (2FA)', subtitle: 'TOTP Authenticator App', value: tp.twoFactorAuth, onChanged: tp.setTwoFactorAuth, icon: Icons.lock_outlined, palette: p),
            _DividerLine(p: p),
            _InfoTile(label: 'PIN ändern', subtitle: 'Eigentümer-PIN aktualisieren', icon: Icons.pin_outlined, palette: p, onTap: () => _showPinDialog(context, p)),
            _DividerLine(p: p),
            _InfoTile(label: 'Session-Protokoll', subtitle: 'Alle Anmeldungen anzeigen', icon: Icons.history, palette: p, onTap: () {}),
          ]),
          const SizedBox(height: 16),

          // SECTION: Benachrichtigungen
          _SectionTitle(title: 'BENACHRICHTIGUNGEN', icon: Icons.notifications_outlined, palette: p),
          const SizedBox(height: 8),
          _buildCard(p, children: [
            _SwitchTile(label: 'Push-Benachrichtigungen', subtitle: 'Signale & System-Updates', value: tp.notificationsEnabled, onChanged: tp.setNotificationsEnabled, icon: Icons.notifications, palette: p),
            _DividerLine(p: p),
            _SwitchTile(label: 'Sound & Vibration', subtitle: 'Audio-Feedback bei Signalen', value: tp.soundEnabled, onChanged: tp.setSoundEnabled, icon: Icons.volume_up_outlined, palette: p),
            _DividerLine(p: p),
            _InfoTile(label: 'Benachrichtigungstypen', subtitle: 'Emma-Signale, Mining, Portfolio', icon: Icons.tune, palette: p, onTap: () {}),
          ]),
          const SizedBox(height: 16),

          // SECTION: Erweitert (God Mode)
          _SectionTitle(title: 'ERWEITERT · ELITE', icon: Icons.admin_panel_settings, palette: p),
          const SizedBox(height: 8),
          _buildCard(p, children: [
            _SwitchTile(
              label: 'God Mode', subtitle: 'Volle Agenten-Kontrolle & Override',
              value: tp.godModeEnabled, onChanged: (v) => _confirmGodMode(context, tp, v, p),
              icon: Icons.all_inclusive, palette: p, highlight: true,
            ),
            _DividerLine(p: p),
            _InfoTile(label: 'Shadow Research', subtitle: 'Deep-Web Markt-Alpha Modus', icon: Icons.visibility_off_outlined, palette: p, onTap: () => _showLockedFeature(context, p, 'Shadow Research')),
            _DividerLine(p: p),
            _InfoTile(label: 'Quantum Simulator', subtitle: 'Parallele Markt-Szenarien', icon: Icons.blur_on, palette: p, onTap: () => _showLockedFeature(context, p, 'Quantum Simulator')),
            _DividerLine(p: p),
            _InfoTile(label: 'AI Forge', subtitle: 'Custom Bot-Generierung', icon: Icons.build_circle_outlined, palette: p, onTap: () => _showLockedFeature(context, p, 'AI Forge')),
            _DividerLine(p: p),
            _InfoTile(label: 'Agenten-Gewichte kalibrieren', subtitle: 'HQMLL Meta-Team justieren', icon: Icons.hub, palette: p, onTap: () => _showAgentPanel(context, p)),
            _DividerLine(p: p),
            _InfoTile(label: 'Quantum Monitor öffnen', subtitle: 'Live Resonanz-Spektrum & Interferenz', icon: Icons.waves, palette: p, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuantumMonitorScreen()))),
          ]),
          const SizedBox(height: 16),

          // SECTION: Über
          _SectionTitle(title: 'ÜBER HQMLL', icon: Icons.info_outline, palette: p),
          const SizedBox(height: 8),
          _buildCard(p, children: [
            _InfoTile(label: 'Version', subtitle: 'HQMLL Quantum v1.0.0 · Enterprise', icon: Icons.new_releases_outlined, palette: p, onTap: () {}),
            _DividerLine(p: p),
            _InfoTile(label: 'Eigentümer', subtitle: 'Grigori Saks · Ultra-Vertraulich', icon: Icons.person_outline, palette: p, onTap: () {}),
            _DividerLine(p: p),
            _InfoTile(label: 'Lizenzen & Patente', subtitle: 'Proprietär · Alle Rechte vorbehalten', icon: Icons.verified_outlined, palette: p, onTap: () {}),
            _DividerLine(p: p),
            _InfoTile(label: 'Datenschutz & DSGVO', subtitle: 'Datenschutzrichtlinie anzeigen', icon: Icons.privacy_tip_outlined, palette: p, onTap: () {}),
          ]),
          const SizedBox(height: 24),

          // Reset Button
          Center(
            child: OutlinedButton.icon(
              icon: Icon(Icons.restore, color: p.negative, size: 16),
              label: Text('Einstellungen zurücksetzen', style: TextStyle(color: p.negative)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: p.negative.withValues(alpha: 0.4))),
              onPressed: () => _showResetDialog(context, p),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOwnerCard(dynamic p, ThemeProvider tp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [p.surfaceVariant, p.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.secondary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          QuantumEyeWidget(palette: p, size: 56, animate: tp.quantumAnimations, showLabel: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grigori Saks', style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Eigentümer · HQMLL Platform', style: TextStyle(color: p.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [p.primary, p.secondary]), borderRadius: BorderRadius.circular(8)),
                    child: Text(tp.godModeEnabled ? 'GOD MODE AKTIV' : 'ENTERPRISE', style: GoogleFonts.rajdhani(color: p.background, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: p.positive.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: p.positive.withValues(alpha: 0.4))),
                    child: Text('6/6 AGENTEN', style: GoogleFonts.rajdhani(color: p.positive, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeProvider tp, dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Icon(Icons.palette, color: p.primary, size: 16),
              const SizedBox(width: 8),
              Text('Quantum-Theme auswählen', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 13, fontWeight: FontWeight.bold)),
            ]),
          ),
          ...QuantumTheme.values.map((theme) {
            final pal = AppThemes.getPalette(theme);
            final selected = tp.currentTheme == theme;
            return GestureDetector(
              onTap: () => tp.setTheme(theme),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? pal.primary.withValues(alpha: 0.1) : p.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? pal.primary : p.primary.withValues(alpha: 0.12),
                    width: selected ? 1.8 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Mini Eye Preview
                    QuantumEyeWidget(palette: pal, size: 44, animate: selected, showLabel: false),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pal.name, style: GoogleFonts.rajdhani(color: selected ? pal.primary : p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(pal.subtitle, style: TextStyle(color: p.textSecondary, fontSize: 11)),
                          const SizedBox(height: 6),
                          Row(children: [
                            _ColorDot(color: pal.primary),
                            const SizedBox(width: 4),
                            _ColorDot(color: pal.secondary),
                            const SizedBox(width: 4),
                            _ColorDot(color: pal.accent),
                            const SizedBox(width: 4),
                            _ColorDot(color: pal.background),
                          ]),
                        ],
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: pal.primary, shape: BoxShape.circle),
                        child: Icon(Icons.check, color: pal.background, size: 16),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCard(dynamic p, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Column(children: children),
    );
  }

  String _riskLabel(double v) {
    if (v <= 0.3) return 'Niedrig';
    if (v <= 0.6) return 'Mittel';
    if (v <= 0.8) return 'Hoch';
    return 'Extrem';
  }

  void _confirmGodMode(BuildContext context, ThemeProvider tp, bool enable, dynamic p) {
    if (!enable) { tp.setGodMode(false); return; }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.primary.withValues(alpha: 0.4))),
        title: Row(children: [Icon(Icons.all_inclusive, color: p.primary), const SizedBox(width: 8), Text('God Mode', style: TextStyle(color: p.textPrimary))]),
        content: Text('God Mode aktiviert unbegrenzte Agenten-Kontrolle und Override-Funktionen.\n\nNur für Eigentümer Grigori Saks.', style: TextStyle(color: p.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Abbrechen', style: TextStyle(color: p.textSecondary))),
          ElevatedButton(
            onPressed: () { tp.setGodMode(true); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: p.primary, foregroundColor: p.background),
            child: const Text('Aktivieren'),
          ),
        ],
      ),
    );
  }

  void _showPinDialog(BuildContext context, dynamic p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.primary.withValues(alpha: 0.3))),
        title: Text('PIN ändern', style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Aus Sicherheitsgründen können Sie Ihren PIN nur über den sicheren Kanal ändern.\n\nKontakt: admin@quantum-emma.ai', style: TextStyle(color: p.textSecondary, fontSize: 13)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: p.primary)))],
      ),
    );
  }

  void _showLockedFeature(BuildContext context, dynamic p, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.secondary.withValues(alpha: 0.4))),
        title: Row(children: [Icon(Icons.lock, color: p.secondary, size: 20), const SizedBox(width: 8), Text(name, style: TextStyle(color: p.textPrimary))]),
        content: Text('$name ist eine Elite-Funktion.\n\nAktivieren Sie zuerst den God Mode oder kontaktieren Sie den HQMLL Enterprise Support.', style: TextStyle(color: p.textSecondary, fontSize: 13)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: p.primary)))],
      ),
    );
  }

  void _showAgentPanel(BuildContext context, dynamic p) {
    final agents = ['Deep Research Agent', 'Pattern Genesis Agent', 'Sentient Market Agent', 'Paradigm Shift Agent', 'Error & Anomaly Agent', 'Strategic Synthesis Agent'];
    final weights = [0.18, 0.22, 0.20, 0.14, 0.12, 0.14];
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HQMLL Agenten-Gewichte', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...agents.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(e.value, style: TextStyle(color: p.textPrimary, fontSize: 12)),
                  Text('${(weights[e.key] * 100).toStringAsFixed(0)}%', style: TextStyle(color: p.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 3),
                ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: weights[e.key], backgroundColor: p.surfaceVariant, valueColor: AlwaysStoppedAnimation<Color>(p.primary), minHeight: 5)),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, dynamic p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.surface,
        title: Text('Zurücksetzen?', style: TextStyle(color: p.textPrimary)),
        content: Text('Alle Einstellungen auf Standard zurücksetzen?', style: TextStyle(color: p.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Abbrechen', style: TextStyle(color: p.textSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: p.negative, foregroundColor: Colors.white), child: const Text('Zurücksetzen')),
        ],
      ),
    );
  }
}

// ─── Reusable Setting Widgets ───────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final dynamic palette;
  const _SectionTitle({required this.title, required this.icon, required this.palette});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: palette.primary, size: 14),
      const SizedBox(width: 6),
      Text(title, style: GoogleFonts.rajdhani(color: palette.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    ]);
  }
}

class _SwitchTile extends StatelessWidget {
  final String label, subtitle;
  final bool value;
  final Function(bool) onChanged;
  final IconData icon;
  final dynamic palette;
  final bool highlight;
  const _SwitchTile({required this.label, required this.subtitle, required this.value, required this.onChanged, required this.icon, required this.palette, this.highlight = false});
  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: highlight ? p.secondary : p.primary, size: 17)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: highlight ? p.secondary : p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(subtitle, style: TextStyle(color: p.textSecondary, fontSize: 10)),
        ])),
        Switch(value: value, onChanged: onChanged),
      ]),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label, displayValue;
  final double value, min, max;
  final int divisions;
  final Function(double) onChanged;
  final IconData icon;
  final dynamic palette;
  const _SliderTile({required this.label, required this.value, required this.min, required this.max, required this.divisions, required this.onChanged, required this.icon, required this.palette, required this.displayValue});
  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Column(
        children: [
          Row(children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: p.primary, size: 17)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
            Text(displayValue, style: TextStyle(color: p.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
          Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final Function(String) onChanged;
  final IconData icon;
  final dynamic palette;
  const _DropdownTile({required this.label, required this.value, required this.items, required this.onChanged, required this.icon, required this.palette});
  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: p.primary, size: 17)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        DropdownButton<String>(
          value: value,
          dropdownColor: p.surfaceVariant,
          style: TextStyle(color: p.primary, fontSize: 13),
          underline: const SizedBox(),
          icon: Icon(Icons.keyboard_arrow_down, color: p.primary, size: 18),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final dynamic palette;
  final VoidCallback onTap;
  const _InfoTile({required this.label, required this.subtitle, required this.icon, required this.palette, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: p.primary, size: 17)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(subtitle, style: TextStyle(color: p.textSecondary, fontSize: 10)),
          ])),
          Icon(Icons.arrow_forward_ios, color: p.textSecondary, size: 14),
        ]),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  final dynamic p;
  const _DividerLine({required this.p});
  @override
  Widget build(BuildContext context) => Divider(height: 1, color: p.primary.withValues(alpha: 0.07), indent: 60);
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5)));
}
