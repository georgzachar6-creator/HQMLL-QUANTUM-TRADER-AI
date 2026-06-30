import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../services/persistence_service.dart';
import '../services/auto_save_service.dart';
import '../services/live_data_service.dart';
import '../services/error_handler_service.dart'
    show ErrorHandlerService, AppError;
import '../theme/app_themes.dart';
import '../widgets/quantum_eye_widget.dart';
import 'quantum_monitor_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp   = context.watch<ThemeProvider>();
    final p    = tp.palette;
    final as2  = context.watch<AutoSaveService>();
    final ps   = context.read<PersistenceService>();
    final lds  = context.watch<LiveDataService>();
    final errs = context.watch<ErrorHandlerService>();

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
            _SwitchTile(label: 'Quantum-Animationen', subtitle: 'Pulsierende Auge & Wellen-Effekte', value: tp.quantumAnimations, onChanged: (v) { tp.setQuantumAnimations(v); as2.onSettingChanged('Quantum-Animationen', v); ps.addSystemLog('SETTINGS', 'Quantum-Animationen: \$v', level: SysLogLevel.info); }, icon: Icons.auto_awesome, palette: p),
            _DividerLine(p: p),
            _SwitchTile(label: 'Dark Charts', subtitle: 'Dunkler Hintergrund für Charts', value: tp.darkCharts, onChanged: (v) { tp.setDarkCharts(v); as2.onSettingChanged('Dark-Charts', v); ps.addSystemLog('SETTINGS', 'Dark-Charts: \$v', level: SysLogLevel.info); }, icon: Icons.bar_chart, palette: p),
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
              onChanged: (v) { tp.setLanguage(v); as2.onSettingChanged('Sprache', v); ps.addSystemLog('SETTINGS', 'Sprache geaendert: \$v', level: SysLogLevel.info); },
            ),
            _DividerLine(p: p),
            _DropdownTile(
              label: 'Währung', icon: Icons.attach_money, palette: p,
              value: tp.currency,
              items: const ['USD', 'EUR', 'GBP', 'BTC', 'ETH'],
              onChanged: (v) { tp.setCurrency(v); as2.onSettingChanged('Waehrung', v); ps.addSystemLog('SETTINGS', 'Waehrung: \$v', level: SysLogLevel.info); },
            ),
          ]),
          const SizedBox(height: 16),

          // SECTION: Daten & Trading
          _SectionTitle(title: 'DATEN & TRADING', icon: Icons.data_usage, palette: p),
          const SizedBox(height: 8),
          _buildCard(p, children: [
            _SwitchTile(label: 'Live-Daten', subtitle: 'Echtzeit-Kurse & Quantum-Signale', value: tp.liveDataEnabled, onChanged: (v) { tp.setLiveDataEnabled(v); as2.onSettingChanged('Live-Daten', v); ps.addSystemLog('SETTINGS', 'Live-Daten: \$v', level: SysLogLevel.info); }, icon: Icons.stream, palette: p),
            _DividerLine(p: p),
            _SwitchTile(label: 'Auto-Trading', subtitle: 'Emma führt Signale automatisch aus', value: tp.autoTrade, onChanged: (v) { tp.setAutoTrade(v); as2.onSettingChanged('Auto-Trading', v); ps.addSystemLog('SETTINGS', 'Auto-Trading: \$v', level: SysLogLevel.warning); }, icon: Icons.smart_toy_outlined, palette: p),
            _DividerLine(p: p),
            _SliderTile(label: 'Risiko-Level', value: tp.riskLevel, min: 0.1, max: 1.0, divisions: 9, onChanged: tp.setRiskLevel, icon: Icons.warning_amber_outlined, palette: p, displayValue: _riskLabel(tp.riskLevel)),
          ]),
          const SizedBox(height: 16),

          // SECTION: Sicherheit
          _SectionTitle(title: 'SICHERHEIT', icon: Icons.security, palette: p),
          const SizedBox(height: 8),
          _buildCard(p, children: [
            _SwitchTile(label: 'Biometrische Authentifizierung', subtitle: 'Face-ID / Fingerabdruck', value: tp.biometricAuth, onChanged: (v) { tp.setBiometricAuth(v); as2.onSettingChanged('Biometrie', v); ps.addSystemLog('SETTINGS', 'Biometrie: \$v', level: SysLogLevel.info); }, icon: Icons.fingerprint, palette: p),
            _DividerLine(p: p),
            _SwitchTile(label: 'Zwei-Faktor-Auth (2FA)', subtitle: 'TOTP Authenticator App', value: tp.twoFactorAuth, onChanged: (v) { tp.setTwoFactorAuth(v); as2.onSettingChanged('2FA', v); ps.addSystemLog('SETTINGS', '2FA: \$v', level: SysLogLevel.info); }, icon: Icons.lock_outlined, palette: p),
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
            _SwitchTile(label: 'Push-Benachrichtigungen', subtitle: 'Signale & System-Updates', value: tp.notificationsEnabled, onChanged: (v) { tp.setNotificationsEnabled(v); as2.onSettingChanged('Benachrichtigungen', v); ps.addSystemLog('SETTINGS', 'Push-Notifications: \$v', level: SysLogLevel.info); }, icon: Icons.notifications, palette: p),
            _DividerLine(p: p),
            _SwitchTile(label: 'Sound & Vibration', subtitle: 'Audio-Feedback bei Signalen', value: tp.soundEnabled, onChanged: (v) { tp.setSoundEnabled(v); as2.onSettingChanged('Sound', v); ps.addSystemLog('SETTINGS', 'Sound: \$v', level: SysLogLevel.info); }, icon: Icons.volume_up_outlined, palette: p),
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

          // ══════ META-GENIUS & TR2 RECURSIVE ══════
          _SectionTitle(title: 'META-GENIUS · TR2 RECURSIVE', icon: Icons.psychology_alt, palette: p),
          const SizedBox(height: 8),
          _buildMetaGeniusCard(context, p, tp),
          const SizedBox(height: 16),

          // ══════ BROKER API INTEGRATION ══════
          _SectionTitle(title: 'BROKER API INTEGRATION', icon: Icons.api, palette: p),
          const SizedBox(height: 8),
          _buildBrokerApiCard(context, p, tp),
          const SizedBox(height: 16),

          // ══════ DEVOPS CONNECTOREN ══════
          _SectionTitle(title: 'DEVOPS · CLOUD CONNECTOREN', icon: Icons.cloud_outlined, palette: p),
          const SizedBox(height: 8),
          _buildDevOpsCard(context, p),
          const SizedBox(height: 16),

          // ══════ KREALOGIIK DENK-SYSTEM ══════
          _SectionTitle(title: 'KREALOGIK DENK-SYSTEM', icon: Icons.account_tree_outlined, palette: p),
          const SizedBox(height: 8),
          _buildKrealogikCard(context, p, tp),
          const SizedBox(height: 16),

          // ══════ AUTO-SAVE STATUS ══════
          _SectionTitle(title: 'AUTO-SAVE · DATENPERSISTENZ', icon: Icons.save_outlined, palette: p),
          const SizedBox(height: 8),
          _buildAutoSaveCard(context, p, as2, ps),
          const SizedBox(height: 16),

          // ══════ PERFORMANCE & REALTIME ══════
          _SectionTitle(title: 'PERFORMANCE & REALTIME', icon: Icons.speed_outlined, palette: p),
          const SizedBox(height: 8),
          _buildPerformanceCard(context, p, tp, lds, as2, ps),
          const SizedBox(height: 16),

          // ══════ ERROR LOG & DIAGNOSE ══════
          _SectionTitle(title: 'FEHLER-LOG & DIAGNOSE', icon: Icons.bug_report_outlined, palette: p),
          const SizedBox(height: 8),
          _buildErrorLogCard(context, p, errs),
          const SizedBox(height: 16),

          // SECTION: Über
          _SectionTitle(title: 'ÜBER HQMLL', icon: Icons.info_outline, palette: p),
          const SizedBox(height: 8),
          _buildCard(p, children: [
            _InfoTile(label: 'Version', subtitle: 'HQMLL Quantum v49.0 · Enterprise Edition', icon: Icons.new_releases_outlined, palette: p, onTap: () {}),
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

  // ══════════════════════════════════════════════════════════
  // PERFORMANCE & REALTIME CARD
  // ══════════════════════════════════════════════════════════
  Widget _buildPerformanceCard(
    BuildContext context,
    dynamic p,
    ThemeProvider tp,
    LiveDataService lds,
    AutoSaveService as2,
    PersistenceService ps,
  ) {
    final isRunning = lds.isRunning;
    final status    = lds.systemStatus;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.surfaceVariant),
      ),
      child: Column(children: [
        // Realtime Toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isRunning ? const Color(0xFF14F195) : const Color(0xFFF7931A)).withValues(alpha: 0.15),
              ),
              child: Icon(
                isRunning ? Icons.stream : Icons.stream_outlined,
                color: isRunning ? const Color(0xFF14F195) : const Color(0xFFF7931A),
                size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Realtime-Datenfeed',
                style: GoogleFonts.rajdhani(
                  color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
              Text(isRunning ? 'Live — 2s Ticker-Intervall' : 'Deaktiviert',
                style: GoogleFonts.rajdhani(
                  color: isRunning ? const Color(0xFF14F195) : p.textSecondary, fontSize: 10)),
            ])),
            Switch(
              value: isRunning,
              onChanged: (v) {
                if (v) {
                  lds.initialize();
                  ps.addSystemLog('SETTINGS', 'Realtime-Feed gestartet', level: SysLogLevel.info);
                } else {
                  lds.stop();
                  ps.addSystemLog('SETTINGS', 'Realtime-Feed gestoppt', level: SysLogLevel.warning);
                }
              },
              activeThumbColor: const Color(0xFF14F195),
              inactiveThumbColor: const Color(0xFFF7931A),
            ),
          ]),
        ),

        if (status != null) ...[
          Divider(color: p.surfaceVariant, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(children: [
              _statBox(p, 'EXCHANGE', status.exchangeOnline ? 'ONLINE' : 'OFFLINE',
                  status.exchangeOnline ? const Color(0xFF14F195) : const Color(0xFFFF4444)),
              const SizedBox(width: 8),
              _statBox(p, 'AI-ENGINE', status.aiEngineRunning ? 'AKTIV' : 'GESTOPPT',
                  status.aiEngineRunning ? const Color(0xFF9945FF) : const Color(0xFFF7931A)),
              const SizedBox(width: 8),
              _statBox(p, 'LOAD', '${(status.systemLoad * 100).toStringAsFixed(0)}%',
                  status.systemLoad > 0.7 ? const Color(0xFFFF4444) : const Color(0xFF00F0FF)),
              const SizedBox(width: 8),
              _statBox(p, 'SIGNALE', '${status.activeSignals}', const Color(0xFFF7931A)),
            ]),
          ),
        ],

        Divider(color: p.surfaceVariant, height: 1),

        // Update-Intervall
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.timer_outlined, color: p.textSecondary, size: 14),
              const SizedBox(width: 6),
              Text('Ticker-Intervall (Realtime)',
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
              const Spacer(),
              Text('2 Sekunden',
                style: GoogleFonts.rajdhani(
                  color: const Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.memory_outlined, color: p.textSecondary, size: 14),
              const SizedBox(width: 6),
              Text('RepaintBoundary Optimierung',
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF14F195).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('AKTIV',
                  style: GoogleFonts.rajdhani(
                    color: const Color(0xFF14F195), fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.compress_outlined, color: p.textSecondary, size: 14),
              const SizedBox(width: 6),
              Text('Stream-basierte Widget-Updates',
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF14F195).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('StreamBuilder',
                  style: GoogleFonts.rajdhani(
                    color: const Color(0xFF14F195), fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
        ),

        // Recent Events
        if (lds.recentEvents.isNotEmpty) ...[
          Divider(color: p.surfaceVariant, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('LIVE-EREIGNISSE',
                style: GoogleFonts.rajdhani(
                  color: p.textSecondary, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 6),
              ...lds.recentEvents.take(3).map((ev) {
                final evColor = ev.type == 'signal' ? const Color(0xFF14F195)
                    : ev.type == 'alert'  ? const Color(0xFFF7931A)
                    : ev.type == 'trade'  ? const Color(0xFF00F0FF)
                    : p.textSecondary;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: evColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(ev.detail,
                      style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9.5),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(
                      '${DateTime.now().difference(ev.timestamp).inMinutes}m',
                      style: GoogleFonts.rajdhani(color: p.textSecondary.withValues(alpha: 0.5), fontSize: 8)),
                  ]),
                );
              }),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _statBox(dynamic p, String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.rajdhani(
          color: color, fontSize: 11, fontWeight: FontWeight.w800)),
        Text(label, style: GoogleFonts.rajdhani(
          color: p.textSecondary, fontSize: 7, letterSpacing: 0.5)),
      ]),
    ));
  }

  // ══════════════════════════════════════════════════════════
  // ERROR LOG & DIAGNOSE CARD
  // ══════════════════════════════════════════════════════════
  Widget _buildErrorLogCard(
    BuildContext context,
    dynamic p,
    ErrorHandlerService errs,
  ) {
    final errors = errs.errors.take(8).toList();

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: errs.hasActiveErrors
              ? const Color(0xFFFF4444).withValues(alpha: 0.3)
              : p.surfaceVariant),
      ),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Icon(
              errs.hasActiveErrors ? Icons.error_outline : Icons.check_circle_outline,
              color: errs.hasActiveErrors ? const Color(0xFFFF4444) : const Color(0xFF14F195),
              size: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                errs.hasActiveErrors
                    ? '${errs.activeErrors.length} AKTIVE FEHLER'
                    : 'KEINE AKTIVEN FEHLER',
                style: GoogleFonts.rajdhani(
                  color: errs.hasActiveErrors ? const Color(0xFFFF4444) : const Color(0xFF14F195),
                  fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
              Text('Gesamt erfasst: ${errs.errorCount} · Fehlergrenze: Global + Route',
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9.5)),
            ])),
            if (errs.hasActiveErrors)
              GestureDetector(
                onTap: errs.dismissAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFF4444).withValues(alpha: 0.3)),
                  ),
                  child: Text('ALLE SCHLIESSEN',
                    style: GoogleFonts.rajdhani(
                      color: const Color(0xFFFF4444), fontSize: 8, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
        ),

        // Error List
        if (errors.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Row(children: [
              Icon(Icons.shield_outlined, color: const Color(0xFF14F195).withValues(alpha: 0.5), size: 14),
              const SizedBox(width: 8),
              Text('System stabil — Alle Services laufen fehlerfrei',
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
            ]),
          )
        else ...[
          Divider(color: p.surfaceVariant, height: 1),
          ...errors.map((err) => _buildErrorRow(p, err, errs)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(children: [
              OutlinedButton.icon(
                onPressed: errs.clearAll,
                icon: const Icon(Icons.delete_outline, size: 13),
                label: Text('Log leeren',
                  style: GoogleFonts.rajdhani(fontSize: 10, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.textSecondary,
                  side: BorderSide(color: p.surfaceVariant),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ]),
          ),
        ],

        // Error Boundary Info
        Divider(color: p.surfaceVariant, height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FEHLER-GRENZEN (ERROR BOUNDARIES)',
              style: GoogleFonts.rajdhani(
                color: p.textSecondary, fontSize: 9,
                fontWeight: FontWeight.w700, letterSpacing: 1)),
            const SizedBox(height: 6),
            _boundaryRow(p, 'Root', 'Globaler Fallback — gesamte App', Icons.public_outlined, const Color(0xFF9945FF)),
            _boundaryRow(p, 'Screen', 'Pro-Screen Widget-Boundary', Icons.phone_android_outlined, const Color(0xFF00F0FF)),
            _boundaryRow(p, 'Route', 'Navigation-Fehler Handling', Icons.route_outlined, const Color(0xFF14F195)),
            _boundaryRow(p, 'Banner', 'Live Fehler-Banner (oben)', Icons.notifications_active_outlined, const Color(0xFFF7931A)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildErrorRow(dynamic p, AppError err, ErrorHandlerService errs) {
    final color = err.severityColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.surfaceVariant, width: 0.5)),
      ),
      child: Row(children: [
        Icon(err.icon, color: color, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(err.typeLabel,
                style: GoogleFonts.rajdhani(color: color, fontSize: 7, fontWeight: FontWeight.w800)),
            ),
            if (err.source != null) ...[
              const SizedBox(width: 6),
              Text(err.source!,
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
            ],
          ]),
          const SizedBox(height: 2),
          Text(err.message,
            style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 10),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        const SizedBox(width: 8),
        Text(
          '${DateTime.now().difference(err.timestamp).inMinutes}m',
          style: GoogleFonts.rajdhani(color: p.textSecondary.withValues(alpha: 0.5), fontSize: 8)),
        const SizedBox(width: 6),
        if (!err.dismissed)
          GestureDetector(
            onTap: () => errs.dismiss(err.id),
            child: Icon(Icons.close, color: p.textSecondary, size: 14),
          ),
      ]),
    );
  }

  Widget _boundaryRow(dynamic p, String name, String desc, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 8),
        Text('$name  ', style: GoogleFonts.rajdhani(
          color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        Expanded(child: Text(desc,
          style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9.5))),
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: const Color(0xFF14F195),
            boxShadow: [BoxShadow(color: const Color(0xFF14F195).withValues(alpha: 0.5), blurRadius: 4)],
          ),
        ),
      ]),
    );
  }

  Widget _buildOwnerCard(dynamic p, ThemeProvider tp) {    return Container(
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
              onTap: () {
                tp.setTheme(theme);
                // v40.1: SystemLog Theme-Wechsel
                context.read<PersistenceService>().addSystemLog(
                  'SYSTEM',
                  'Theme gewechselt: ${theme.name.toUpperCase()}',
                  level: SysLogLevel.info,
                );
              },
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

  // ══ AUTO-SAVE STATUS CARD ══
  Widget _buildAutoSaveCard(BuildContext context, dynamic p, AutoSaveService as2, PersistenceService ps) {
    final intervals = [10, 30, 60, 120, 300];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            as2.autoSaveOn
                ? const Color(0xFF00FF88).withValues(alpha: 0.08)
                : p.surface,
            p.surface,
          ],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: as2.autoSaveOn
              ? const Color(0xFF00FF88).withValues(alpha: 0.3)
              : p.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Status header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: (as2.autoSaveOn ? const Color(0xFF00FF88) : p.textSecondary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                as2.state.isSaving ? Icons.save_alt : Icons.cloud_done_outlined,
                color: as2.autoSaveOn ? const Color(0xFF00FF88) : p.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                as2.state.isSaving ? 'SPEICHERN...' : as2.statusText,
                style: GoogleFonts.spaceMono(
                  color: as2.autoSaveOn ? const Color(0xFF00FF88) : p.textSecondary,
                  fontSize: 12, fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Saves: ${as2.state.saveCount} | Zuletzt: ${as2.state.lastSavedAgo}',
                style: TextStyle(color: p.textSecondary, fontSize: 10),
              ),
            ])),
            // Manual save button
            GestureDetector(
              onTap: () {
                as2.saveAll(trigger: 'manual');
                ps.addSystemLog('AUTOSAVE', 'Manueller Save ausgeloest', level: SysLogLevel.info);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('💾 Alle Daten gespeichert'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Color(0xFF00AA55),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.3)),
                ),
                child: Text('JETZT SPEICHERN',
                  style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
        Divider(color: p.primary.withValues(alpha: 0.08), height: 1),
        // Auto-Save toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Container(width: 34, height: 34,
              decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.autorenew, color: p.primary, size: 17)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Auto-Save aktiv', style: TextStyle(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('Alle ${as2.intervalLabel} automatisch speichern', style: TextStyle(color: p.textSecondary, fontSize: 10)),
            ])),
            Switch(
              value: as2.autoSaveOn,
              onChanged: (v) {
                as2.setAutoSaveEnabled(v);
                ps.addSystemLog('SETTINGS', 'Auto-Save ${v ? "aktiviert" : "deaktiviert"}', level: SysLogLevel.info);
              },
            ),
          ]),
        ),
        Divider(color: p.primary.withValues(alpha: 0.08), height: 1),
        // Interval selector
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Save-Intervall', style: TextStyle(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: intervals.map((sec) {
                final label = sec < 60 ? '${sec}s' : '${sec ~/ 60}m';
                final selected = as2.intervalSec == sec;
                return GestureDetector(
                  onTap: () {
                    as2.setInterval(sec);
                    ps.addSystemLog('SETTINGS', 'Save-Intervall geaendert: $label', level: SysLogLevel.info);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? p.primary.withValues(alpha: 0.2) : p.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? p.primary : p.primary.withValues(alpha: 0.15),
                        width: selected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Text(label, style: TextStyle(
                      color: selected ? p.primary : p.textSecondary,
                      fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    )),
                  ),
                );
              }).toList(),
            ),
          ]),
        ),
      ]),
    );
  }

  String _riskLabel(double v) {
    if (v <= 0.3) return 'Niedrig';
    if (v <= 0.6) return 'Mittel';
    if (v <= 0.8) return 'Hoch';
    return 'Extrem';
  }

  // ══ META-GENIUS & TR2 RECURSIVE CARD ══
  Widget _buildMetaGeniusCard(BuildContext context, dynamic p, ThemeProvider tp) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.surfaceVariant, const Color(0xFF0D0D1A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.secondary.withValues(alpha: 0.5)),
      ),
      child: Column(children: [
        // Meta-Genius Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [p.secondary.withValues(alpha: 0.2), Colors.transparent]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [p.secondary, p.primary]),
                boxShadow: [BoxShadow(color: p.secondary.withValues(alpha: 0.5), blurRadius: 12)],
              ),
              child: const Icon(Icons.psychology_alt, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('META-GENIUS ENGINE', style: GoogleFonts.rajdhani(color: p.secondary, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text('Selbstlernend · Selbstoptimierend · Rekursiv', style: TextStyle(color: p.textSecondary, fontSize: 10)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: p.positive.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: p.positive.withValues(alpha: 0.4))),
              child: Text('AKTIV', style: GoogleFonts.spaceMono(color: p.positive, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            // AI-Modus Auswahl
            _MetaSelector(
              label: 'AI-DENK-MODUS', p: p,
              options: const ['META-GENIUS', 'TR2 RECURSIVE', 'KREALOGIK', 'ORACLE-MODE', 'DEEP-RESEARCH'],
              selected: 0,
              onSelect: (i) => _showMetaModeDialog(context, p, i),
            ),
            const SizedBox(height: 12),
            // TR2 Recursive Schleife
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.primary.withValues(alpha: 0.25)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.loop, color: p.primary, size: 16),
                  const SizedBox(width: 6),
                  Text('TR2 RECURSIVE LOOP', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('Tiefe: 7 · Zyklen: ∞', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
                ]),
                const SizedBox(height: 8),
                _RecursiveLoopViz(p: p),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _MetricChip('Iterations/s', '1.247', p.primary, p)),
                  const SizedBox(width: 6),
                  Expanded(child: _MetricChip('Konfidenz', '94.7%', p.positive, p)),
                  const SizedBox(width: 6),
                  Expanded(child: _MetricChip('Meta-Ebene', 'L-7', p.secondary, p)),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            // Self-Improvement Tracker
            _buildSelfImprovementTracker(p),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _ActionBtn('KALIBRIEREN', Icons.tune, p.primary, p, () => _showCalibrationDialog(context, p))),
              const SizedBox(width: 8),
              Expanded(child: _ActionBtn('RESET', Icons.restore, p.negative, p, () {})),
              const SizedBox(width: 8),
              Expanded(child: _ActionBtn('REPORT', Icons.analytics_outlined, p.secondary, p, () => _showMetaReport(context, p))),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSelfImprovementTracker(dynamic p) {
    final metrics = [
      ('Denk-Geschwindigkeit', 0.87, p.primary),
      ('Muster-Erkennung', 0.94, p.positive),
      ('Kreativitäts-Index', 0.76, p.secondary),
      ('Fehlerkorrektur', 0.91, p.positive),
      ('Meta-Abstraktion', 0.83, p.primary),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SELBSTVERBESSERUNGS-TRACKER', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        ...metrics.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            SizedBox(width: 130, child: Text(m.$1, style: TextStyle(color: p.textSecondary, fontSize: 10))),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: m.$2, minHeight: 6,
                backgroundColor: p.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(m.$3),
              ),
            )),
            const SizedBox(width: 6),
            SizedBox(width: 34, child: Text('${(m.$2 * 100).toInt()}%', style: GoogleFonts.spaceMono(color: m.$3, fontSize: 9))),
          ]),
        )),
      ]),
    );
  }

  // ══ BROKER API CARD ══
  Widget _buildBrokerApiCard(BuildContext context, dynamic p, ThemeProvider tp) {
    final brokers = [
      _BrokerInfo('Binance', 'binance', true, true, '0.1%', p.positive),
      _BrokerInfo('Kraken', 'kraken', false, false, '0.16%', p.textSecondary),
      _BrokerInfo('Coinbase Pro', 'coinbase', false, false, '0.6%', p.textSecondary),
      _BrokerInfo('Bybit', 'bybit', false, false, '0.1%', p.textSecondary),
      _BrokerInfo('OKX', 'okx', false, false, '0.1%', p.textSecondary),
      _BrokerInfo('Bitget', 'bitget', false, false, '0.1%', p.textSecondary),
      _BrokerInfo('KuCoin', 'kucoin', false, false, '0.1%', p.textSecondary),
      _BrokerInfo('Huobi/HTX', 'huobi', false, false, '0.2%', p.textSecondary),
    ];
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(Icons.api, color: p.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('BROKER API CONNECTOREN', style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
              Text('Sidebar-Auswahl · Live-Marktdaten', style: TextStyle(color: p.textSecondary, fontSize: 11)),
            ])),
            GestureDetector(
              onTap: () => _showAddBrokerDialog(context, p),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [p.primary, p.secondary]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('+ API', style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
        Divider(color: p.primary.withValues(alpha: 0.15), height: 1),
        ...brokers.map((b) => _BrokerTile(broker: b, p: p, onTap: () => _showBrokerConfig(context, p, b))),
      ]),
    );
  }

  // ══ DEVOPS CONNECTOREN CARD ══
  Widget _buildDevOpsCard(BuildContext context, dynamic p) {
    final connectors = [
      const _DevConnector('GitHub', Icons.code, 'VERBUNDEN', Color(0xFF4078C8), true, 'quantumtrader/hqmll-app'),
      const _DevConnector('Vercel', Icons.rocket_launch_outlined, 'BEREIT', Color(0xFF000000), false, 'hqmll.vercel.app'),
      const _DevConnector('Netlify', Icons.cloud_upload_outlined, 'BEREIT', Color(0xFF00C7B7), false, 'hqmll.netlify.app'),
      const _DevConnector('Docker', Icons.inventory_2_outlined, 'BEREIT', Color(0xFF2496ED), false, 'ghcr.io/saks/hqmll'),
      const _DevConnector('Azure', Icons.cloud_outlined, 'BEREIT', Color(0xFF0089D6), false, 'hqmll.azurewebsites.net'),
      const _DevConnector('Firebase', Icons.local_fire_department_outlined, 'VERBUNDEN', Color(0xFFFFCA28), true, 'hqmll-quantum.firebaseapp.com'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(Icons.hub, color: p.secondary, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text('DEPLOYMENT · CI/CD PIPELINE', style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: p.positive.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: p.positive.withValues(alpha: 0.3))),
              child: Text('2/6 LIVE', style: GoogleFonts.spaceMono(color: p.positive, fontSize: 9)),
            ),
          ]),
        ),
        Divider(color: p.secondary.withValues(alpha: 0.15), height: 1),
        ...connectors.map((c) => _DevConnectorTile(connector: c, p: p, onTap: () => _showConnectorDialog(context, p, c))),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: _ActionBtn('DEPLOY ALL', Icons.rocket_launch, p.secondary, p, () => _showDeployDialog(context, p))),
            const SizedBox(width: 8),
            Expanded(child: _ActionBtn('CI/CD LOG', Icons.receipt_long_outlined, p.primary, p, () => _showCicdLog(context, p))),
          ]),
        ),
      ]),
    );
  }

  // ══ KREALOGIK DENK-SYSTEM CARD ══
  Widget _buildKrealogikCard(BuildContext context, dynamic p, ThemeProvider tp) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A0030), p.surfaceVariant],
          begin: Alignment.topRight, end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF673AB7)]),
              boxShadow: [BoxShadow(color: Color(0x559C27B0), blurRadius: 12)],
            ),
            child: const Icon(Icons.auto_fix_high, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('KREALOGIK™ DENK-SYSTEM', style: GoogleFonts.rajdhani(color: const Color(0xFFCE93D8), fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
            Text('Kreatives Logik · Algorithmisches Handeln', style: TextStyle(color: p.textSecondary, fontSize: 10)),
          ])),
        ]),
        const SizedBox(height: 14),
        // Denk-Loop Visualisierung
        _KrealogikLoopWidget(p: p),
        const SizedBox(height: 14),
        // Handlungs-Module
        Text('HANDLUNGS-MODULE', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          'ANALYSE', 'MUSTER', 'PROGNOSE', 'ENTSCHEIDUNG',
          'OPTIMIERUNG', 'FEEDBACK', 'ADAPTION', 'EVOLUTION',
        ].map((m) => GestureDetector(
          onTap: () => _showModuleInfo(context, p, m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.4)),
            ),
            child: Text(m, style: GoogleFonts.spaceMono(color: const Color(0xFFCE93D8), fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        )).toList()),
        const SizedBox(height: 14),
        // Zukunfts-Aussagen
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFCE93D8), size: 14),
              const SizedBox(width: 6),
              Text('QUANTUM-PROGNOSE 2025–2027', style: GoogleFonts.spaceMono(color: const Color(0xFFCE93D8), fontSize: 9)),
            ]),
            const SizedBox(height: 8),
            ...[
              'BTC erreicht \$250.000 bis Q4 2025 (Konfidenz: 78%)',
              'QEMMA Token Top-100 Listing bis Q2 2025',
              'HQMLL Platform 1M+ Nutzer bis Ende 2026',
              'Quantum-KI übertrifft menschliche Trader um 340%',
            ].map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                const Icon(Icons.arrow_forward_ios, color: Color(0xFF9C27B0), size: 9),
                const SizedBox(width: 6),
                Expanded(child: Text(s, style: TextStyle(color: p.textSecondary, fontSize: 10, height: 1.4))),
              ]),
            )),
          ]),
        ),
      ]),
    );
  }

  // ══ DIALOGE ══
  void _showMetaModeDialog(BuildContext context, dynamic p, int mode) {
    final modes = ['META-GENIUS', 'TR2 RECURSIVE', 'KREALOGIK', 'ORACLE-MODE', 'DEEP-RESEARCH'];
    final descs = [
      'Höchste KI-Ebene · Selbstlernend · Rekursive Selbstverbesserung',
      'TR2 Loop mit 7 Rekursions-Ebenen · Maximale Präzision',
      'Kreatives Denken · Innovative Handlungsstrategien',
      'Quantum-Orakel · Probabilistische Zukunftsvorhersagen',
      'Deep-Web Alpha · Versteckte Markt-Informationen',
    ];
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.primary.withValues(alpha: 0.4))),
      title: Text('AI-Modus: ${modes[mode]}', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 16, fontWeight: FontWeight.bold)),
      content: Text(descs[mode], style: TextStyle(color: p.textSecondary, fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('ABBRECHEN', style: TextStyle(color: p.textSecondary))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: p.primary),
          onPressed: () { Navigator.pop(context); },
          child: const Text('AKTIVIEREN', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  void _showCalibrationDialog(BuildContext context, dynamic p) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.secondary.withValues(alpha: 0.4))),
      title: Text('META-KALIBRIERUNG', style: GoogleFonts.rajdhani(color: p.secondary, fontSize: 16, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Starte Quantum-Kalibrierung aller Meta-Module?', style: TextStyle(color: p.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: 0.73, color: p.secondary, backgroundColor: p.surfaceVariant),
        const SizedBox(height: 6),
        Text('Letzter Kalibrierungslauf: vor 12 Std', style: TextStyle(color: p.textSecondary, fontSize: 11)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('SCHLIESSEN', style: TextStyle(color: p.textSecondary))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: p.secondary),
          onPressed: () => Navigator.pop(context),
          child: const Text('STARTEN', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  void _showMetaReport(BuildContext context, dynamic p) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.primary.withValues(alpha: 0.4))),
      title: Text('META-GENIUS REPORT', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 16, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _reportRow('TR2-Iterationen heute', '14.847', p),
        _reportRow('Erkannte Muster', '1.293', p),
        _reportRow('Entscheidungen', '847', p),
        _reportRow('Trefferquote', '94.7%', p),
        _reportRow('Lernrate', '0.0847', p),
        _reportRow('Meta-Ebene', 'L-7 (MAX)', p),
        _reportRow('Uptime', '99.97%', p),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: p.primary)))],
    ));
  }

  Widget _reportRow(String label, String value, dynamic p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: p.textSecondary, fontSize: 12))),
        Text(value, style: GoogleFonts.spaceMono(color: p.primary, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  void _showAddBrokerDialog(BuildContext context, dynamic p) {
    final ctrlKey = TextEditingController();
    final ctrlSecret = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.primary.withValues(alpha: 0.4))),
      title: Text('BROKER API HINZUFÜGEN', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 16, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: ctrlKey,
          style: TextStyle(color: p.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            labelText: 'API Key', labelStyle: TextStyle(color: p.textSecondary, fontSize: 12),
            filled: true, fillColor: p.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrlSecret,
          obscureText: true,
          style: TextStyle(color: p.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            labelText: 'API Secret', labelStyle: TextStyle(color: p.textSecondary, fontSize: 12),
            filled: true, fillColor: p.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('ABBRECHEN', style: TextStyle(color: p.textSecondary))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: p.primary),
          onPressed: () => Navigator.pop(context),
          child: const Text('VERBINDEN', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  void _showBrokerConfig(BuildContext context, dynamic p, _BrokerInfo b) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: b.statusColor.withValues(alpha: 0.4))),
      title: Text(b.name.toUpperCase(), style: GoogleFonts.rajdhani(color: b.statusColor, fontSize: 16, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _reportRow('Status', b.connected ? 'VERBUNDEN' : 'NICHT VERBUNDEN', p),
        _reportRow('API Key', b.connected ? '••••••••4F9C' : 'Nicht konfiguriert', p),
        _reportRow('Trading', b.tradingEnabled ? 'AKTIVIERT' : 'NUR LESEN', p),
        _reportRow('Gebühr', b.fee, p),
        _reportRow('Latenz', b.connected ? '12ms' : '—', p),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('SCHLIESSEN', style: TextStyle(color: p.textSecondary))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: b.statusColor),
          onPressed: () => Navigator.pop(context),
          child: Text(b.connected ? 'TRENNEN' : 'VERBINDEN', style: const TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  void _showConnectorDialog(BuildContext context, dynamic p, _DevConnector c) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.color.withValues(alpha: 0.4))),
      title: Row(children: [
        Icon(c.icon, color: c.color, size: 20),
        const SizedBox(width: 8),
        Text(c.name.toUpperCase(), style: GoogleFonts.rajdhani(color: c.color, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _reportRow('Status', c.status, p),
        _reportRow('URL', c.url, p),
        _reportRow('Auto-Deploy', c.connected ? 'AKTIVIERT' : 'MANUELL', p),
        _reportRow('Build', c.connected ? 'ERFOLGREICH' : '—', p),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('ABBRECHEN', style: TextStyle(color: p.textSecondary))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: c.color),
          onPressed: () => Navigator.pop(context),
          child: Text(c.connected ? 'KONFIGURIEREN' : 'VERBINDEN', style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ],
    ));
  }

  void _showDeployDialog(BuildContext context, dynamic p) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.secondary.withValues(alpha: 0.4))),
      title: Text('DEPLOYMENT STARTEN', style: GoogleFonts.rajdhani(color: p.secondary, fontSize: 16, fontWeight: FontWeight.bold)),
      content: Text('Alle konfigurierten Plattformen gleichzeitig deployen?\n\nVercel · Netlify · Docker · Azure', style: TextStyle(color: p.textSecondary, fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('ABBRECHEN', style: TextStyle(color: p.textSecondary))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: p.secondary),
          onPressed: () => Navigator.pop(context),
          child: const Text('DEPLOY', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  void _showCicdLog(BuildContext context, dynamic p) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.primary.withValues(alpha: 0.4))),
      title: Text('CI/CD LOG', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 16, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('[2025-03-17 14:35] ✅ GitHub Push → main', style: GoogleFonts.spaceMono(color: p.positive, fontSize: 10)),
        Text('[2025-03-17 14:36] ✅ Flutter Build Web', style: GoogleFonts.spaceMono(color: p.positive, fontSize: 10)),
        Text('[2025-03-17 14:37] ✅ APK Release Build 56.1MB', style: GoogleFonts.spaceMono(color: p.positive, fontSize: 10)),
        Text('[2025-03-17 14:38] ⏳ Vercel Deploy pending', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10)),
        Text('[2025-03-17 14:38] ⏳ Netlify Deploy pending', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10)),
        Text('[2025-03-17 14:39] 🔄 Docker Build in queue', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10)),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('SCHLIESSEN', style: TextStyle(color: p.primary)))],
    ));
  }

  void _showModuleInfo(BuildContext context, dynamic p, String module) {
    final infos = {
      'ANALYSE': 'Tiefenanalyse von Marktdaten mittels Quantum-Algorithmen',
      'MUSTER': 'Erkennung wiederkehrender Patterns in historischen Kursdaten',
      'PROGNOSE': 'Probabilistische Vorhersagen basierend auf TR2-Rekursion',
      'ENTSCHEIDUNG': 'Autonome Handelsentscheidungen mit KreaLogik',
      'OPTIMIERUNG': 'Kontinuierliche Portfolio-Optimierung in Echtzeit',
      'FEEDBACK': 'Rückkopplungsschleife für Selbstlern-Kalibrierung',
      'ADAPTION': 'Dynamische Anpassung an neue Marktbedingungen',
      'EVOLUTION': 'Evolutionäre Algorithmen für langfristige Strategien',
    };
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0x669C27B0))),
      title: Text('MODUL: $module', style: GoogleFonts.rajdhani(color: const Color(0xFFCE93D8), fontSize: 16, fontWeight: FontWeight.bold)),
      content: Text(infos[module] ?? '', style: TextStyle(color: p.textSecondary, fontSize: 13)),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Color(0xFFCE93D8))))],
    ));
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

// ═══════════════════════════════════════════════════
// META-GENIUS HELPER WIDGETS
// ═══════════════════════════════════════════════════

class _MetaSelector extends StatelessWidget {
  final String label;
  final List<String> options;
  final int selected;
  final dynamic p;
  final Function(int) onSelect;
  const _MetaSelector({required this.label, required this.options, required this.selected, required this.p, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
      const SizedBox(height: 6),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: options.asMap().entries.map((e) {
          final isSelected = e.key == selected;
          return GestureDetector(
            onTap: () => onSelect(e.key),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(colors: [p.primary, p.secondary]) : null,
                color: isSelected ? null : p.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: isSelected ? null : Border.all(color: p.primary.withValues(alpha: 0.3)),
              ),
              child: Text(e.value, style: GoogleFonts.spaceMono(
                color: isSelected ? Colors.white : p.textSecondary,
                fontSize: 9, fontWeight: FontWeight.bold,
              )),
            ),
          );
        }).toList()),
      ),
    ]);
  }
}

class _RecursiveLoopViz extends StatelessWidget {
  final dynamic p;
  const _RecursiveLoopViz({required this.p});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: CustomPaint(painter: _LoopPainter(p: p)),
    );
  }
}

class _LoopPainter extends CustomPainter {
  final dynamic p;
  const _LoopPainter({required this.p});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 2..style = PaintingStyle.stroke;
    const levels = 7;
    for (int i = 0; i < levels; i++) {
      final progress = i / levels;
      paint.color = Color.lerp(p.primary, p.secondary, progress)!.withValues(alpha: 0.7 - progress * 0.3);
      final y = size.height * 0.5;
      final x1 = size.width * (i / levels);
      final x2 = size.width * ((i + 1) / levels);
      final cp1 = Offset(x1 + (x2 - x1) * 0.3, y - 15);
      final cp2 = Offset(x1 + (x2 - x1) * 0.7, y + 15);
      final path = Path()..moveTo(x1, y)..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, x2, y);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _MetricChip extends StatelessWidget {
  final String label, value;
  final Color color;
  final dynamic p;
  const _MetricChip(this.label, this.value, this.color, this.p);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.rajdhani(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: p.textSecondary, fontSize: 8), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final dynamic p;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.icon, this.color, this.p, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.spaceMono(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

class _BrokerInfo {
  final String name, id, fee;
  final bool connected, tradingEnabled;
  final Color statusColor;
  const _BrokerInfo(this.name, this.id, this.connected, this.tradingEnabled, this.fee, this.statusColor);
}

class _BrokerTile extends StatelessWidget {
  final _BrokerInfo broker;
  final dynamic p;
  final VoidCallback onTap;
  const _BrokerTile({required this.broker, required this.p, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: p.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: broker.connected ? broker.statusColor.withValues(alpha: 0.4) : p.primary.withValues(alpha: 0.1)),
            ),
            child: Center(child: Text(broker.name[0], style: GoogleFonts.rajdhani(color: broker.connected ? broker.statusColor : p.textSecondary, fontSize: 16, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(broker.name, style: TextStyle(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('Gebühr: ${broker.fee} · ${broker.tradingEnabled ? "Trading aktiv" : "Nur lesen"}', style: TextStyle(color: p.textSecondary, fontSize: 10)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: broker.statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: broker.statusColor.withValues(alpha: 0.35)),
            ),
            child: Text(broker.connected ? 'LIVE' : 'VERBINDEN', style: GoogleFonts.spaceMono(color: broker.statusColor, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_ios, color: p.textSecondary, size: 12),
        ]),
      ),
    );
  }
}

class _DevConnector {
  final String name, status, url;
  final IconData icon;
  final Color color;
  final bool connected;
  const _DevConnector(this.name, this.icon, this.status, this.color, this.connected, this.url);
}

class _DevConnectorTile extends StatelessWidget {
  final _DevConnector connector;
  final dynamic p;
  final VoidCallback onTap;
  const _DevConnectorTile({required this.connector, required this.p, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: connector.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: connector.color.withValues(alpha: 0.4)),
            ),
            child: Icon(connector.icon, color: connector.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(connector.name, style: TextStyle(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(connector.url, style: TextStyle(color: p.textSecondary, fontSize: 10), overflow: TextOverflow.ellipsis),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: connector.connected ? p.positive.withValues(alpha: 0.12) : p.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: connector.connected ? p.positive.withValues(alpha: 0.4) : p.primary.withValues(alpha: 0.2)),
            ),
            child: Text(connector.status, style: GoogleFonts.spaceMono(color: connector.connected ? p.positive : p.textSecondary, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_ios, color: p.textSecondary, size: 12),
        ]),
      ),
    );
  }
}

class _KrealogikLoopWidget extends StatelessWidget {
  final dynamic p;
  const _KrealogikLoopWidget({required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _KreaNode('DENKEN', Icons.lightbulb_outline, Color(0xFF9C27B0)),
          Icon(Icons.arrow_forward, color: const Color(0xFF9C27B0).withValues(alpha: 0.5), size: 14),
          const _KreaNode('HANDELN', Icons.flash_on, Color(0xFF673AB7)),
          Icon(Icons.arrow_forward, color: const Color(0xFF673AB7).withValues(alpha: 0.5), size: 14),
          const _KreaNode('LERNEN', Icons.school_outlined, Color(0xFF3F51B5)),
          Icon(Icons.arrow_forward, color: const Color(0xFF3F51B5).withValues(alpha: 0.5), size: 14),
          const _KreaNode('EVOLVIEREN', Icons.trending_up, Color(0xFF2196F3)),
          Icon(Icons.loop, color: const Color(0xFF9C27B0).withValues(alpha: 0.5), size: 14),
        ],
      ),
    );
  }
}

class _KreaNode extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _KreaNode(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.bold)),
    ]);
  }
}
