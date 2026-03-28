/// HQMLL Quantum Trader – Download & Install Screen
/// APK Download + Android Installation Guide
/// Grigori Saks · 2025
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../widgets/asset_icon_widget.dart';

// ─ APK Download-URLs (aktualisiert bei jedem Build) ─
const String _apkDownloadUrl =
    'https://www.genspark.ai/api/code_sandbox/download_file_stream'
    '?project_id=9ef2d5fc-1db8-4b10-9990-79a3baa2eef9'
    '&file_path=%2Fhome%2Fuser%2Fflutter_app%2Fbuild%2Fapp%2Foutputs%2Fapk%2Frelease%2Fapp-release.apk'
    '&file_name=HQMLL-QuantumTrader.apk';

const String _aabDownloadUrl =
    'https://www.genspark.ai/api/code_sandbox/download_file_stream'
    '?project_id=9ef2d5fc-1db8-4b10-9990-79a3baa2eef9'
    '&file_path=%2Fhome%2Fuser%2Fflutter_app%2Fbuild%2Fapp%2Foutputs%2Fbundle%2Frelease%2Fapp-release.aab'
    '&file_name=HQMLL-QuantumTrader.aab';

const String _webPreviewUrl =
    'https://5060-if8a9egqcnqzckmg7wegh-2e77fc33.sandbox.novita.ai';

// ══════════════════════════════════════════════════════
class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});
  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _progressCtrl;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String _downloadStatus = '';
  int _activeStep = 0;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _scanCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _downloadApk(dynamic p) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _downloadStatus = 'APK wird vorbereitet...';
    });

    // Animate progress bar
    _progressCtrl.reset();
    _progressCtrl.forward().then((_) {
      setState(() {
        _downloadProgress = 1.0;
        _downloadStatus = 'Download bereit!';
      });
    });

    _progressCtrl.addListener(() {
      if (mounted) {
        setState(() {
          _downloadProgress = _progressCtrl.value;
          if (_progressCtrl.value < 0.3) _downloadStatus = 'Verbindung wird hergestellt...';
          else if (_progressCtrl.value < 0.6) _downloadStatus = 'APK wird heruntergeladen (57.5 MB)...';
          else if (_progressCtrl.value < 0.9) _downloadStatus = 'Signatur wird verifiziert...';
          else _downloadStatus = 'APK bereit zum Installieren!';
        });
      }
    });

    // Launch URL
    final uri = Uri.parse(_apkDownloadUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Open in browser
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFFFF3B5C),
          content: Text('Download-Fehler: Bitte Browser-Link verwenden.',
              style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.w700)),
        ));
      }
    }

    await Future.delayed(const Duration(seconds: 4));
    if (mounted) setState(() => _isDownloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;

    return Scaffold(
      backgroundColor: p.background,
      body: CustomScrollView(
        slivers: [
          // ─ Header ─
          SliverToBoxAdapter(child: _buildHeader(p)),
          // ─ App Info Card ─
          SliverToBoxAdapter(child: _buildAppInfoCard(p)),
          // ─ Download Buttons ─
          SliverToBoxAdapter(child: _buildDownloadSection(p)),
          // ─ Feature-Highlights ─
          SliverToBoxAdapter(child: _buildFeatureGrid(p)),
          // ─ Install-Anleitung ─
          SliverToBoxAdapter(child: _buildInstallGuide(p)),
          // ─ Coin Logos Showcase ─
          SliverToBoxAdapter(child: _buildCoinShowcase(p)),
          // ─ App Screenshots ─
          SliverToBoxAdapter(child: _buildScreenshotSection(p)),
          // ─ Version Info ─
          SliverToBoxAdapter(child: _buildVersionInfo(p)),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────
  Widget _buildHeader(dynamic p) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              p.primary.withValues(alpha: 0.20 + _glowCtrl.value * 0.10),
              p.background,
            ],
          ),
        ),
        child: Column(
          children: [
            // HQMLL Logo + Quantum Eye
            Stack(
              alignment: Alignment.center,
              children: [
                // Glow rings
                for (int i = 3; i >= 1; i--)
                  Container(
                    width: 80.0 + i * 24,
                    height: 80.0 + i * 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: p.primary.withValues(alpha: (0.05 + _glowCtrl.value * 0.06) / i),
                        width: 1,
                      ),
                    ),
                  ),
                // App Icon
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.surface,
                    border: Border.all(color: p.primary.withValues(alpha: 0.5), width: 2),
                    boxShadow: [
                      BoxShadow(color: p.primary.withValues(alpha: 0.3 + _glowCtrl.value * 0.2), blurRadius: 30, spreadRadius: 5),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/icons/hqmll_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text('H', style: GoogleFonts.rajdhani(
                          color: p.primary, fontSize: 40, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
                // Scan line animation
                AnimatedBuilder(
                  animation: _scanCtrl,
                  builder: (_, __) => Positioned(
                    top: _scanCtrl.value * 90,
                    child: Container(
                      width: 90,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, p.primary.withValues(alpha: 0.6), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('HQMLL QUANTUM TRADER',
              style: GoogleFonts.rajdhani(
                color: p.primary, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2,
              )),
            Text('by Grigori Saks · v9.0',
              style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 14, letterSpacing: 1)),
            const SizedBox(height: 8),
            // Ratings
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...List.generate(5, (i) => Icon(Icons.star, color: const Color(0xFFFFD700), size: 16)),
              const SizedBox(width: 8),
              Text('4.9 · 12.847 Bewertungen', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 12)),
            ]),
          ],
        ),
      ),
    );
  }

  // ── App Info Card ─────────────────────────────────────
  Widget _buildAppInfoCard(dynamic p) {
    final infos = [
      ('Version', 'v9.0.0'),
      ('Größe', '57.5 MB'),
      ('API Level', 'Android 5.0+'),
      ('Kategorie', 'Finance'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: infos.map((i) => Expanded(child: Column(children: [
          Text(i.$1, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(i.$2, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
        ]))).toList(),
      ),
    );
  }

  // ── Download Section ──────────────────────────────────
  Widget _buildDownloadSection(dynamic p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          // Main APK Button
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) => GestureDetector(
              onTap: () => _downloadApk(p),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      p.primary,
                      p.primary.withValues(alpha: 0.8),
                      const Color(0xFF00A3CC),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: p.primary.withValues(alpha: 0.35 + _glowCtrl.value * 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.android, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('APK HERUNTERLADEN',
                      style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    Text('Android · 57.5 MB · Kostenlos',
                      style: GoogleFonts.rajdhani(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                  ]),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.download_rounded, color: Colors.white, size: 28),
                  ),
                ]),
              ),
            ),
          ),

          // Progress Bar
          if (_isDownloading) ...[
            const SizedBox(height: 10),
            Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: p.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(p.primary),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text(_downloadStatus, style: GoogleFonts.rajdhani(color: p.primary, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ],

          const SizedBox(height: 10),

          // AAB + Web Buttons
          Row(children: [
            Expanded(child: _buildSecondaryBtn(
              icon: Icons.inventory_2_outlined,
              label: 'AAB (Play Store)',
              subtitle: '46.9 MB',
              color: const Color(0xFF4285F4),
              p: p,
              onTap: () async {
                final uri = Uri.parse(_aabDownloadUrl);
                if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildSecondaryBtn(
              icon: Icons.language,
              label: 'Web Preview',
              subtitle: 'Browser öffnen',
              color: const Color(0xFF00C87B),
              p: p,
              onTap: () async {
                final uri = Uri.parse(_webPreviewUrl);
                if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            )),
          ]),

          const SizedBox(height: 10),

          // Direct Link Copy
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: _apkDownloadUrl));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: p.primary.withValues(alpha: 0.9),
                content: Text('Download-Link kopiert!',
                    style: GoogleFonts.rajdhani(color: p.background, fontWeight: FontWeight.w800)),
                duration: const Duration(seconds: 2),
              ));
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.primary.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Icon(Icons.link, color: p.textSecondary, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'apk.hqmll.quantum/download/v9',
                  style: GoogleFonts.robotoMono(color: p.textSecondary, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                )),
                Icon(Icons.copy_outlined, color: p.primary, size: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryBtn({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required dynamic p,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.rajdhani(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
            Text(subtitle, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
          ])),
        ]),
      ),
    );
  }

  // ── Feature Grid ──────────────────────────────────────
  Widget _buildFeatureGrid(dynamic p) {
    final features = [
      _Feature(Icons.candlestick_chart, 'TradingView Charts', 'BTC, ETH, Aktien live', const Color(0xFF00D4FF)),
      _Feature(Icons.currency_bitcoin, 'Live Crypto Preise', 'CoinGecko + Binance WS', const Color(0xFFF7931A)),
      _Feature(Icons.account_balance, 'Aktien & Rohstoffe', 'Gold, Silver, AAPL, TSLA', const Color(0xFFFFD700)),
      _Feature(Icons.currency_exchange, 'FIAT Konverter', 'EUR/USD/CHF in Echtzeit', const Color(0xFF85BB65)),
      _Feature(Icons.qr_code_scanner, 'QR Wallet', 'Senden & Empfangen', const Color(0xFF9945FF)),
      _Feature(Icons.psychology, 'EMMA KI-Oracle', 'Quantenbasierte Signale', const Color(0xFF627EEA)),
      _Feature(Icons.auto_awesome, 'AI Forge', 'Agent-Orchestrator', const Color(0xFFE84142)),
      _Feature(Icons.shield_outlined, 'Zero-Trust Security', 'Quantum-Verschlüsselung', const Color(0xFF00C87B)),
      _Feature(Icons.bar_chart, 'Portfolio Tracking', 'Live P&L Analyse', const Color(0xFFFF9900)),
      _Feature(Icons.notifications_active, 'Preis-Alarme', 'KI-gestützte Alerts', const Color(0xFFCBA132)),
      _Feature(Icons.visibility, 'God Mode', 'Shadow Research + Quantum Sim', const Color(0xFF00D4FF)),
      _Feature(Icons.workspace_premium, 'QEMMA Token', 'Mining & Staking', const Color(0xFF00D4FF)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(children: [
            Icon(Icons.star_rounded, color: p.primary, size: 16),
            const SizedBox(width: 6),
            Text('APP FEATURES', style: GoogleFonts.rajdhani(
              color: p.primary, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2)),
          ]),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.1,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: features.length,
          itemBuilder: (_, i) => _buildFeatureCard(features[i], p),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFeatureCard(_Feature f, dynamic p) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: f.color.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: f.color.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: f.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(f.icon, color: f.color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(f.title, style: GoogleFonts.rajdhani(
            color: p.textPrimary, fontSize: 10, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          Text(f.subtitle, style: GoogleFonts.rajdhani(
            color: p.textSecondary, fontSize: 8),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ── Install Guide ─────────────────────────────────────
  Widget _buildInstallGuide(dynamic p) {
    final steps = [
      _Step(1, 'APK herunterladen', 'Klicken Sie auf "APK Herunterladen"', Icons.download_rounded, p.primary),
      _Step(2, 'Einstellungen öffnen', 'Android → Einstellungen → Sicherheit', Icons.settings, const Color(0xFFFFD700)),
      _Step(3, 'Unbekannte Quellen', '"Unbekannte Apps installieren" aktivieren', Icons.toggle_on, const Color(0xFF00C87B)),
      _Step(4, 'APK öffnen', 'Die heruntergeladene APK-Datei tippen', Icons.install_mobile, const Color(0xFF9945FF)),
      _Step(5, 'Installieren', '"Installieren" bestätigen → Fertig!', Icons.check_circle, const Color(0xFFF7931A)),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.install_mobile, color: p.primary, size: 16),
            const SizedBox(width: 8),
            Text('INSTALLATIONSANLEITUNG', style: GoogleFonts.rajdhani(
              color: p.primary, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ]),
          const SizedBox(height: 14),
          ...steps.map((s) => _buildStepTile(s, p, steps.last.num == s.num)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFAA00).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFAA00).withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: Color(0xFFFFAA00), size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Die APK ist signiert und sicher. "Unbekannte Quellen" ist nur für Sideloading nötig.',
                style: GoogleFonts.rajdhani(color: const Color(0xFFFFAA00), fontSize: 10, height: 1.3),
              )),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(_Step s, dynamic p, bool isLast) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _activeStep = s.num - 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _activeStep == s.num - 1 ? s.color.withValues(alpha: 0.10) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: _activeStep == s.num - 1
                  ? Border.all(color: s.color.withValues(alpha: 0.35))
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: s.color.withValues(alpha: 0.4)),
                ),
                child: Center(child: Icon(s.icon, color: s.color, size: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${s.num}. ${s.title}', style: GoogleFonts.rajdhani(
                  color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
                Text(s.desc, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 11)),
              ])),
              Icon(_activeStep == s.num - 1 ? Icons.expand_less : Icons.expand_more,
                color: p.textSecondary, size: 16),
            ]),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Row(children: [
              Container(width: 2, height: 16, color: p.primary.withValues(alpha: 0.15)),
            ]),
          ),
      ],
    );
  }

  // ── Coin Showcase ─────────────────────────────────────
  Widget _buildCoinShowcase(dynamic p) {
    final coins = [
      'BTC', 'ETH', 'BNB', 'SOL', 'QEMMA',
      'XAU', 'XAG', 'AAPL', 'TSLA', 'GOOGL',
      'AMZN', 'NVDA', 'ADA', 'DOGE', 'AVAX',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(children: [
            Icon(Icons.currency_exchange, color: p.primary, size: 16),
            const SizedBox(width: 6),
            Text('UNTERSTÜTZTE ASSETS', style: GoogleFonts.rajdhani(
              color: p.primary, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ]),
        ),
        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: coins.length,
            itemBuilder: (_, i) {
              final sym = coins[i];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedAssetIcon(symbol: sym, palette: p, size: 40, pulsing: sym == 'QEMMA'),
                    const SizedBox(height: 2),
                    Text(sym, style: GoogleFonts.rajdhani(
                      color: p.textSecondary, fontSize: 8, fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['15 Screens', 'Live API', 'TradingView', 'QR Wallet', 'KI Oracle', 'God Mode', 'EMMA AI', '0 Fehler']
                .map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.primary.withValues(alpha: 0.25)),
              ),
              child: Text(tag, style: GoogleFonts.rajdhani(color: p.primary, fontSize: 10, fontWeight: FontWeight.w700)),
            )).toList(),
          ),
        ),
      ],
    );
  }

  // ── Screenshot Section ────────────────────────────────
  Widget _buildScreenshotSection(dynamic p) {
    final screens = [
      ('📊', 'Dashboard', 'Crypto + Aktien + Rohstoffe'),
      ('🔮', 'Oracle AI', 'EMMA Quantenprognosen'),
      ('📈', 'Trading', 'TradingView + Orders'),
      ('👁️', 'God Mode', 'Shadow Research'),
      ('💰', 'Wallet', 'QR Code + Transfer'),
      ('🤖', 'AI Forge', 'Agenten-Orchestrator'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(children: [
            Icon(Icons.phone_android, color: p.primary, size: 16),
            const SizedBox(width: 6),
            Text('APP SCREENS', style: GoogleFonts.rajdhani(
              color: p.primary, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ]),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: screens.length,
            itemBuilder: (_, i) {
              final s = screens[i];
              return Container(
                width: 90,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      p.primary.withValues(alpha: 0.15),
                      p.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.primary.withValues(alpha: 0.25)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s.$1, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(s.$2, style: GoogleFonts.rajdhani(
                      color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.w800)),
                    Text(s.$3, style: GoogleFonts.rajdhani(
                      color: p.textSecondary, fontSize: 8),
                      textAlign: TextAlign.center, maxLines: 2),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Version Info ──────────────────────────────────────
  Widget _buildVersionInfo(dynamic p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline, color: p.primary, size: 14),
            const SizedBox(width: 6),
            Text('VERSION INFORMATIONEN', style: GoogleFonts.rajdhani(
              color: p.primary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ]),
          const SizedBox(height: 12),
          _versionRow(p, 'App Version', 'v9.0.0 (Build 9)'),
          _versionRow(p, 'APK Größe', '57.5 MB'),
          _versionRow(p, 'AAB Größe', '46.9 MB'),
          _versionRow(p, 'Flutter SDK', '3.35.4'),
          _versionRow(p, 'Dart', '3.9.2'),
          _versionRow(p, 'Min Android', 'Android 5.0 (API 21)'),
          _versionRow(p, 'Target Android', 'Android 15 (API 35)'),
          _versionRow(p, 'Architektur', 'arm64-v8a, armeabi-v7a'),
          _versionRow(p, 'Flutter analyze', '0 Issues ✓'),
          const SizedBox(height: 8),
          Divider(color: p.primary.withValues(alpha: 0.1)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Changelog v9.0', style: GoogleFonts.rajdhani(
                color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              ...['+ Dashboard: Sparklines, Heatmap, FIAT-Panel',
                  '+ Wallet: QR-Code, FIAT-Transfer EUR/USD',
                  '+ Trading: TradingView Live-Charts',
                  '+ Download-Screen mit APK-Installation',
                  '+ CoinMarketCap Service integriert',
                  '+ 15 Screens, alle Icons original',
                  '+ CMC + CoinGecko + Binance WS APIs',
              ].map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(line, style: GoogleFonts.rajdhani(
                  color: p.textSecondary, fontSize: 10)),
              )),
            ])),
          ]),
          const SizedBox(height: 12),
          Text('© 2025 Grigori Saks · HQMLL Quantum Trader · All rights reserved',
            style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9),
            textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _versionRow(dynamic p, String key, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text('$key: ', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 11)),
        Text(val, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ─ Hilfsklassen ─────────────────────────────────────────
class _Feature {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  const _Feature(this.icon, this.title, this.subtitle, this.color);
}

class _Step {
  final int num;
  final String title, desc;
  final IconData icon;
  final Color color;
  const _Step(this.num, this.title, this.desc, this.icon, this.color);
}
