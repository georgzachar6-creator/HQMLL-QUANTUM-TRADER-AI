/// HQMLL Quantum Trader AI System – Enterprise License & Owner Screen
/// © 2025 Grigori Saks · All Rights Reserved
/// Patent-Pending · Confidential · Proprietary Technology
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../widgets/quantum_eye_widget.dart';

// ══════════════════════════════════════════════════════
// ENTERPRISE SCREEN – Grigori Saks IP & License System
// ══════════════════════════════════════════════════════
class EnterpriseScreen extends StatefulWidget {
  const EnterpriseScreen({super.key});
  @override
  State<EnterpriseScreen> createState() => _EnterpriseScreenState();
}

class _EnterpriseScreenState extends State<EnterpriseScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  int _activeSection = 0;

  // ─ Sections ─
  final _sections = ['LIZENZ', 'PATENTE', 'EIGENTÜMER', 'SYSTEM'];

  @override
  void initState() {
    super.initState();
    _glowCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _scanCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _pulseCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p  = tp.palette;

    return Scaffold(
      backgroundColor: p.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildOwnerHeader(p, tp)),
          SliverToBoxAdapter(child: _buildSectionTabs(p)),
          SliverToBoxAdapter(child: _buildSectionContent(p)),
          SliverToBoxAdapter(child: _buildPatentBlock(p)),
          SliverToBoxAdapter(child: _buildSystemFingerprint(p)),
          SliverToBoxAdapter(child: _buildLicenseBlock(p)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ── Owner Header ─────────────────────────────────────
  Widget _buildOwnerHeader(dynamic p, ThemeProvider tp) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0E1A),
              p.primary.withValues(alpha: 0.12 + _glowCtrl.value * 0.08),
              const Color(0xFF0A1628),
            ],
          ),
          border: Border(
            bottom: BorderSide(color: p.primary.withValues(alpha: 0.3), width: 1),
          ),
        ),
        child: Column(
          children: [
            // Quantum Eye + Rotating Ring
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer rotating ring
                AnimatedBuilder(
                  animation: _rotateCtrl,
                  builder: (_, __) => Transform.rotate(
                    angle: _rotateCtrl.value * 2 * pi,
                    child: Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: p.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: CustomPaint(painter: _DashedCirclePainter(p.primary)),
                    ),
                  ),
                ),
                // Inner glow
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: p.primary.withValues(alpha: 0.2 + _pulseCtrl.value * 0.3),
                          blurRadius: 30 + _pulseCtrl.value * 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                // Quantum Eye
                QuantumEyeWidget(palette: p, size: 80, animate: tp.quantumAnimations),
                // Scan line
                AnimatedBuilder(
                  animation: _scanCtrl,
                  builder: (_, __) => Positioned(
                    top: 15 + _scanCtrl.value * 55,
                    child: Container(
                      width: 80, height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          p.primary.withValues(alpha: 0.7),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Owner Name
            Text('GRIGORI SAKS',
              style: GoogleFonts.rajdhani(
                color: p.primary, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4,
              )),
            const SizedBox(height: 4),
            Text('SOLE PROPRIETOR & INVENTOR',
              style: GoogleFonts.rajdhani(
                color: p.textSecondary, fontSize: 11, letterSpacing: 3,
              )),
            const SizedBox(height: 12),

            // Enterprise Badge Row
            Wrap(
              spacing: 8, runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _badge('ENTERPRISE', const Color(0xFFFFD700), Icons.workspace_premium),
                _badge('PATENT PENDING', p.primary, Icons.verified_user),
                _badge('CONFIDENTIAL', const Color(0xFFFF3B5C), Icons.lock),
                _badge('© 2025', p.textSecondary, Icons.copyright),
              ],
            ),
            const SizedBox(height: 14),

            // Unique License ID
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: p.primary.withValues(alpha: 0.3 + _pulseCtrl.value * 0.2),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.key, color: p.primary, size: 14),
                  const SizedBox(width: 8),
                  SelectableText(
                    'LIC-HQMLL-GS-1985-QTAIS-ENT-2025',
                    style: GoogleFonts.robotoMono(color: p.primary, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: 'LIC-HQMLL-GS-1985-QTAIS-ENT-2025'));
                      HapticFeedback.lightImpact();
                    },
                    child: Icon(Icons.copy, color: p.textSecondary, size: 14),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.rajdhani(
          color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
      ]),
    );
  }

  // ── Section Tabs ─────────────────────────────────────
  Widget _buildSectionTabs(dynamic p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: List.generate(_sections.length, (i) {
          final active = i == _activeSection;
          return Expanded(
            child: GestureDetector(
              onTap: () { setState(() => _activeSection = i); HapticFeedback.selectionClick(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? p.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(_sections[i],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rajdhani(
                    color: active ? p.background : p.textSecondary,
                    fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1,
                  )),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Section Content ───────────────────────────────────
  Widget _buildSectionContent(dynamic p) {
    switch (_activeSection) {
      case 0: return _buildLicenseSection(p);
      case 1: return _buildPatentsSection(p);
      case 2: return _buildOwnerSection(p);
      case 3: return _buildSystemSection(p);
      default: return _buildLicenseSection(p);
    }
  }

  Widget _buildLicenseSection(dynamic p) {
    return _infoCard(p, Icons.gavel, 'SOFTWARE-LIZENZ', const Color(0xFFFFD700), [
      ('Lizenztyp', 'Enterprise Commercial License v1.0'),
      ('Lizenzinhaber', 'Grigori Saks (Alleininhaber)'),
      ('Lizenz-ID', 'LIC-HQMLL-GS-1985-QTAIS-ENT-2025'),
      ('Gültig ab', '01. Januar 2025'),
      ('Gültig bis', 'Unbefristet (Perpetual)'),
      ('Territorium', 'Weltweit (International)'),
      ('Nutzungsrecht', 'Exklusiv · Nicht übertragbar'),
      ('Quellcode', 'Vertraulich · All Rights Reserved'),
      ('Drittparteien', 'Alle Rechte vorbehalten · Keine Sublizenz'),
      ('Kontakt', 'grischasaks@gmail.com'),
    ]);
  }

  Widget _buildPatentsSection(dynamic p) {
    final patents = [
      ('PAT-001', 'HQMLL Quantum Emma AI System', 'Angemeldet 2025', 'KI-gestützte Trading-Engine mit Quantum-Resonanz'),
      ('PAT-002', 'Meta-Genius TR2 Recursive Loop', 'Angemeldet 2025', 'Selbstverbesserndes Handelssystem mit Meta-Lernmodul'),
      ('PAT-003', 'Quantum Eye Authentication', 'Angemeldet 2025', 'Biometrisches Quantum-Auge Authentifizierungssystem'),
      ('PAT-004', 'QEMMA Token Protocol', 'Angemeldet 2025', 'Proof-of-Intelligence Blockchain-Protokoll'),
      ('PAT-005', 'KI Oracle Prediction Engine', 'Angemeldet 2025', 'Quantenbasiertes Marktvorhersage-Framework'),
      ('PAT-006', 'Self-Improvement Trading Module', 'Angemeldet 2025', 'Autonomes Selbstlern-Handelssystem'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: patents.map((pat) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.primary.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: p.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.verified_user, color: Color(0xFFFFD700), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(pat.$1, style: GoogleFonts.robotoMono(color: p.primary, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Text(pat.$3, style: GoogleFonts.rajdhani(color: const Color(0xFF00C87B), fontSize: 10)),
              ]),
              const SizedBox(height: 3),
              Text(pat.$2, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
              Text(pat.$4, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
            ])),
          ]),
        )).toList(),
      ),
    );
  }

  Widget _buildOwnerSection(dynamic p) {
    return _infoCard(p, Icons.person_pin, 'EIGENTÜMER-PROFIL', p.primary, [
      ('Name', 'Grigori Saks'),
      ('Rolle', 'Sole Proprietor · Lead Inventor'),
      ('Unternehmen', 'HQMLL Quantum Technologies'),
      ('E-Mail', 'grischasaks@gmail.com'),
      ('Account-ID', 'G-S-1212-1985'),
      ('Alt. ID', 'G12121985s · Gs12121985'),
      ('Gründungsjahr', '2025'),
      ('Hauptsitz', 'International'),
      ('Geheimhaltung', 'NDA Level 5 · Quantum Sealed'),
      ('IP-Status', 'Vollständiger IP-Inhaber · Keine Drittrechte'),
      ('Kompetenzen', 'AI · Blockchain · QuantumTrading · DevOps'),
      ('Kontakt', 'grischasaks@gmail.com'),
    ]);
  }

  Widget _buildSystemSection(dynamic p) {
    return _infoCard(p, Icons.memory, 'SYSTEM-INFORMATIONEN', const Color(0xFF9945FF), [
      ('App-Name', 'Quantum Trader AI System'),
      ('Version', 'v9.0.0 Enterprise'),
      ('Build', '9 (Release)'),
      ('Package', 'com.quantumtrader.trade'),
      ('Flutter', '3.35.4'),
      ('Dart', '3.9.2'),
      ('Android SDK', 'API 35 (Android 15)'),
      ('Architektur', 'arm64-v8a · armeabi-v7a'),
      ('Screens', '16 (inkl. Enterprise)'),
      ('Services', '5 (Live · CMC · Broker · AI · DevOps)'),
      ('Widgets', '9 (Custom Enterprise)'),
      ('Analyze', '0 Errors · Production Ready'),
    ]);
  }

  Widget _infoCard(dynamic p, IconData icon, String title, Color color, List<(String, String)> items) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.rajdhani(color: color, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ]),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 110,
                child: Text('${item.$1}:', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 11)),
              ),
              Expanded(child: Text(item.$2, style: GoogleFonts.rajdhani(
                color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.w700))),
            ]),
          )),
        ],
      ),
    );
  }

  // ── Patent Block ─────────────────────────────────────
  Widget _buildPatentBlock(dynamic p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.08),
          const Color(0xFF0A1628),
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.shield, color: Color(0xFFFFD700), size: 18),
          const SizedBox(width: 8),
          Text('GEISTIGES EIGENTUM & PATENTE', style: GoogleFonts.rajdhani(
            color: const Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 12),
        Text(
          'Die gesamte Software, Algorithmen, KI-Modelle, Handelslogik, '
          'UI/UX-Designs, Markenzeichen (insbesondere "Quantum Eye" / '
          '"HQMLL" / "QEMMA"), Protokolle und sämtliche technischen '
          'Konzepte dieser Anwendung sind ausschließliches geistiges '
          'Eigentum von GRIGORI SAKS.\n\n'
          'Jede Vervielfältigung, Weitergabe, Reverse Engineering oder '
          'kommerzielle Nutzung ohne ausdrückliche schriftliche Genehmigung '
          'des Eigentümers ist streng verboten und wird rechtlich verfolgt.\n\n'
          '© 2025 Grigori Saks · All Rights Reserved · Patent Pending',
          style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 11, height: 1.6),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _legalChip('NDA Level 5', Icons.lock, const Color(0xFFFF3B5C), p)),
          const SizedBox(width: 8),
          Expanded(child: _legalChip('Patent Pending', Icons.verified_user, const Color(0xFFFFD700), p)),
          const SizedBox(width: 8),
          Expanded(child: _legalChip('Trademark ™', Icons.workspace_premium, p.primary, p)),
        ]),
      ]),
    );
  }

  Widget _legalChip(String label, IconData icon, Color color, dynamic p) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.rajdhani(color: color, fontSize: 9, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center),
      ]),
    );
  }

  // ── System Fingerprint ───────────────────────────────
  Widget _buildSystemFingerprint(dynamic p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.fingerprint, color: p.primary, size: 16),
          const SizedBox(width: 8),
          Text('SYSTEM FINGERPRINT', style: GoogleFonts.rajdhani(
            color: p.primary, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00C87B),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF00C87B).withValues(alpha: 0.6 * _pulseCtrl.value),
                  blurRadius: 8,
                )],
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        _fpRow(p, 'App Hash', 'SHA256:a4f8e2d1c9b3...HQMLL2025'),
        _fpRow(p, 'Owner ID', 'GS-1985-QTAI-ENT'),
        _fpRow(p, 'Build Sig', 'RSA-4096:Grigori-Saks-2025'),
        _fpRow(p, 'QEMMA Addr', 'HQMLLqEmma85SaksGrigori...XqZ9'),
        _fpRow(p, 'BTC Addr', '1HQMLL9Grigori1985Saks...XqZkJ'),
        _fpRow(p, 'ETH Addr', '0x7Gf2QmL9kXs3aBvNpR4cYhW8dFtJ5eZ'),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.verified, color: const Color(0xFF00C87B), size: 14),
          const SizedBox(width: 6),
          Text('Authentizität verifiziert · Quantum-Signed',
            style: GoogleFonts.rajdhani(color: const Color(0xFF00C87B), fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  Widget _fpRow(dynamic p, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 90, child: Text('$label:', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10))),
        Expanded(child: SelectableText(val, style: GoogleFonts.robotoMono(color: p.textPrimary, fontSize: 9))),
      ]),
    );
  }

  // ── License Block ─────────────────────────────────────
  Widget _buildLicenseBlock(dynamic p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          p.primary.withValues(alpha: 0.06),
          p.surface,
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.article, color: p.primary, size: 16),
          const SizedBox(width: 8),
          Text('ENTERPRISE LICENSE AGREEMENT', style: GoogleFonts.rajdhani(
            color: p.primary, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ]),
        const SizedBox(height: 12),
        Text(
          'QUANTUM TRADER AI SYSTEM – ENTERPRISE EDITION\n'
          'Version 9.0 · © 2025 Grigori Saks\n\n'
          '1. EIGENTUMSRECHTE\n'
          'Diese Software und alle damit verbundenen Materialien sind '
          'ausschließliches Eigentum von Grigori Saks. Alle Rechte, '
          'Titel und Interessen verbleiben beim Eigentümer.\n\n'
          '2. GEHEIMHALTUNGSPFLICHT\n'
          'Der Lizenznehmer verpflichtet sich zur strikten '
          'Geheimhaltung aller technischen Details, Algorithmen, '
          'KI-Modelle und Geschäftsgeheimnisse (NDA Level 5).\n\n'
          '3. EINGESCHRÄNKTE NUTZUNG\n'
          'Die Nutzung ist ausschließlich durch den lizenzierten '
          'Eigentümer (Grigori Saks) gestattet. Eine Weitergabe, '
          'Kopie oder Sublizenzierung ist ohne schriftliche Genehmigung '
          'untersagt.\n\n'
          '4. HAFTUNGSAUSSCHLUSS\n'
          'Die Software wird "wie besehen" bereitgestellt. Der Eigentümer '
          'haftet nicht für finanzielle Verluste aus Handelsentscheidungen.\n\n'
          '5. PATENTE & MARKENZEICHEN\n'
          '"HQMLL", "QEMMA", "Quantum Eye", "Meta-Genius", "TR2" und '
          '"Quantum Trader AI System" sind angemeldete Markenzeichen '
          'von Grigori Saks. Alle Patente sind angemeldet.\n\n'
          '© 2025 Grigori Saks · grischasaks@gmail.com\n'
          'ALL RIGHTS RESERVED · PATENT PENDING · CONFIDENTIAL',
          style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10, height: 1.6),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: 'grischasaks@gmail.com'));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: p.primary.withValues(alpha: 0.9),
                content: Text('E-Mail kopiert!', style: GoogleFonts.rajdhani(color: p.background, fontWeight: FontWeight.w800)),
                duration: const Duration(seconds: 2),
              ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [p.primary, const Color(0xFF00A3CC)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.email, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('grischasaks@gmail.com', style: GoogleFonts.rajdhani(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Dashed Circle Painter ────────────────────────────
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const dashCount = 24;
    const dashAngle = (2 * pi) / dashCount;
    for (int i = 0; i < dashCount; i += 2) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * 0.6;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweepAngle, false, paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => false;
}
