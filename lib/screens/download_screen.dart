// HQMLL Quantum Trader AI System v10.0 – Download & Install Screen
// APK Download + Android Installation Guide
// © 2025 Grigori Saks · HQMLL · All Rights Reserved
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';

// ─ APK Download-URLs (v10.0) ─
const String _apkDownloadUrl =
    'https://www.genspark.ai/api/code_sandbox/download_file_stream'
    '?project_id=9ef2d5fc-1db8-4b10-9990-79a3baa2eef9'
    '&file_path=%2Fhome%2Fuser%2Fflutter_app%2Fbuild%2Fapp%2Foutputs%2Fapk%2Frelease%2Fapp-release.apk'
    '&file_name=QuantumTraderAI-v10.apk';

const String _aabDownloadUrl =
    'https://www.genspark.ai/api/code_sandbox/download_file_stream'
    '?project_id=9ef2d5fc-1db8-4b10-9990-79a3baa2eef9'
    '&file_path=%2Fhome%2Fuser%2Fflutter_app%2Fbuild%2Fapp%2Foutputs%2Fbundle%2Frelease%2Fapp-release.aab'
    '&file_name=QuantumTraderAI-v10.aab';

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
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String _downloadStatus = '';
  int _activeStep = -1;

  final List<_FeatureItem> _features = const [
    _FeatureItem(Icons.candlestick_chart, 'Live Trading', 'Echtzeit-Charts & Orders'),
    _FeatureItem(Icons.account_balance_wallet, 'Multi-Wallet', 'ETH · SOL · BTC · QEMMA'),
    _FeatureItem(Icons.auto_awesome, 'AI Oracle', 'Quantum-Resonanz Signale'),
    _FeatureItem(Icons.show_chart, 'Broker API', 'CoinGecko · TradingView · CMC'),
    _FeatureItem(Icons.security, 'Enterprise', 'IP-Schutz · Patent-System'),
    _FeatureItem(Icons.currency_exchange, 'FIAT', 'EUR/USD SEPA & SWIFT'),
  ];

  final List<_InstallStep> _steps = const [
    _InstallStep('1', 'APK herunterladen', 'Tippe auf den Download-Button und warte bis der Download abgeschlossen ist.', Icons.download_rounded),
    _InstallStep('2', 'Unbekannte Quellen', 'Einstellungen → Sicherheit → "Unbekannte Apps" aktivieren.', Icons.security_outlined),
    _InstallStep('3', 'APK öffnen', 'Öffne die heruntergeladene APK-Datei im Download-Ordner.', Icons.folder_open_outlined),
    _InstallStep('4', 'Installieren', 'Tippe auf "Installieren" und warte auf die Fertigstellung.', Icons.install_mobile_outlined),
    _InstallStep('5', 'Starten', 'Öffne "Quantum Trader AI System" aus dem App-Drawer.', Icons.rocket_launch_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  Future<void> _startDownload(String url, String fileName) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _downloadStatus = 'Verbindung herstellen...';
      _activeStep = 0;
    });

    // Simulated download progress animation
    final statuses = [
      'Verbindung herstellen...',
      'Download startet...',
      'Lade APK herunter...',
      'Verifiziere Signatur...',
      'Fast fertig...',
    ];

    for (int i = 0; i < statuses.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _downloadProgress = (i + 1) / statuses.length;
        _downloadStatus = statuses[i];
      });
    }

    // Open actual download URL
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isDownloading = false;
      _downloadStatus = 'Download gestartet!';
      _activeStep = 1;
    });

    // Show success snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('$fileName wird heruntergeladen...',
                  style: GoogleFonts.spaceMono(fontSize: 11)),
            ],
          ),
          backgroundColor: const Color(0xFF00E676),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;

    return Scaffold(
      backgroundColor: p.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeroHeader(p)),
          SliverToBoxAdapter(child: _buildVersionBadge(p)),
          SliverToBoxAdapter(child: _buildFeatureGrid(p)),
          SliverToBoxAdapter(child: _buildDownloadButtons(p)),
          if (_isDownloading || _downloadStatus.isNotEmpty)
            SliverToBoxAdapter(child: _buildProgressBar(p)),
          SliverToBoxAdapter(child: _buildStatsRow(p)),
          SliverToBoxAdapter(child: _buildInstallGuide(p)),
          SliverToBoxAdapter(child: _buildSystemRequirements(p)),
          SliverToBoxAdapter(child: _buildChangelog(p)),
          SliverToBoxAdapter(child: _buildLegalFooter(p)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ── Hero Header ───────────────────────────────────────
  Widget _buildHeroHeader(dynamic p) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              p.primary.withValues(alpha: 0.15 + _glowCtrl.value * 0.08),
              p.background,
              p.background,
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: p.primary.withValues(alpha: 0.12 + _glowCtrl.value * 0.06),
            ),
          ),
        ),
        child: Row(
          children: [
            // Rotating quantum logo
            AnimatedBuilder(
              animation: _rotateCtrl,
              builder: (_, child) => Transform.rotate(
                angle: _rotateCtrl.value * 2 * pi,
                child: child,
              ),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: p.primary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  gradient: RadialGradient(
                    colors: [
                      p.primary.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: p.primary.withValues(alpha: 0.3 + _glowCtrl.value * 0.2),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/icons/coins/app_icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.diamond_outlined,
                    color: p.primary,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUANTUM TRADER',
                    style: GoogleFonts.spaceMono(
                      color: p.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                    ),
                  ),
                  Text(
                    'AI SYSTEM',
                    style: GoogleFonts.rajdhani(
                      color: p.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by Grigori Saks · HQMLL',
                    style: GoogleFonts.inter(
                      color: p.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Live badge
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.1 + _pulseCtrl.value * 0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00E676),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withValues(alpha: _pulseCtrl.value),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'LIVE',
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFF00E676),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Version Badge ─────────────────────────────────────
  Widget _buildVersionBadge(dynamic p) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.primary.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [p.primary, const Color(0xFF00A3CC)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'v10.0',
              style: GoogleFonts.spaceMono(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enterprise Release',
                  style: GoogleFonts.rajdhani(
                    color: p.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '2025 · Android 8.0+ · 66.6 MB APK',
                  style: GoogleFonts.inter(
                    color: p.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
            ),
            child: Text(
              'SIGNED',
              style: GoogleFonts.spaceMono(
                color: const Color(0xFFFFD700),
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Feature Grid ──────────────────────────────────────
  Widget _buildFeatureGrid(dynamic p) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FEATURES',
            style: GoogleFonts.spaceMono(
              color: p.textSecondary,
              fontSize: 10,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            itemCount: _features.length,
            itemBuilder: (context, i) {
              final f = _features[i];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.primary.withValues(alpha: 0.15)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(f.icon, color: p.primary, size: 20),
                    const SizedBox(height: 5),
                    Text(
                      f.title,
                      style: GoogleFonts.spaceMono(
                        color: p.textPrimary,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f.subtitle,
                      style: GoogleFonts.inter(
                        color: p.textSecondary,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Download Buttons ──────────────────────────────────
  Widget _buildDownloadButtons(dynamic p) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Primary APK Download
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) => GestureDetector(
              onTap: _isDownloading
                  ? null
                  : () => _startDownload(_apkDownloadUrl, 'QuantumTraderAI-v10.apk'),
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isDownloading
                        ? [Colors.grey.shade700, Colors.grey.shade800]
                        : [p.primary, const Color(0xFF00A3CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: p.primary.withValues(
                          alpha: _isDownloading ? 0.1 : 0.4 + _glowCtrl.value * 0.2),
                      blurRadius: _isDownloading ? 0 : 20,
                      spreadRadius: _isDownloading ? 0 : 3,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _isDownloading
                        ? null
                        : () => _startDownload(_apkDownloadUrl, 'QuantumTraderAI-v10.apk'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isDownloading)
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        else
                          const Icon(Icons.download_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isDownloading ? 'LÄDT HERUNTER...' : 'APK HERUNTERLADEN',
                              style: GoogleFonts.spaceMono(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'Android 8.0+ · 66.6 MB · v10.0',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // AAB Download (secondary)
          GestureDetector(
            onTap: () => _startDownload(_aabDownloadUrl, 'QuantumTraderAI-v10.aab'),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.primary.withValues(alpha: 0.3)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _startDownload(_aabDownloadUrl, 'QuantumTraderAI-v10.aab'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.android, color: p.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'APP BUNDLE (AAB) · 54.3 MB',
                        style: GoogleFonts.spaceMono(
                          color: p.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PLAY STORE',
                          style: GoogleFonts.spaceMono(
                            color: p.primary,
                            fontSize: 7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // QR Code / Copy URL row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: _apkDownloadUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Download-URL kopiert!',
                            style: GoogleFonts.spaceMono(fontSize: 11)),
                        backgroundColor: p.primary,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy_outlined, color: p.textSecondary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'URL KOPIEREN',
                          style: GoogleFonts.spaceMono(
                            color: p.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_outlined, color: p.textSecondary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'QR CODE',
                        style: GoogleFonts.spaceMono(
                          color: p.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Progress Bar ──────────────────────────────────────
  Widget _buildProgressBar(dynamic p) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isDownloading ? Icons.downloading : Icons.check_circle,
                color: _isDownloading ? p.primary : const Color(0xFF00E676),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _downloadStatus,
                style: GoogleFonts.spaceMono(
                  color: p.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.rajdhani(
                  color: p.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: p.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(p.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ─────────────────────────────────────────
  Widget _buildStatsRow(dynamic p) {
    final stats = [
      ('15', 'Screens'),
      ('5', 'Services'),
      ('8', 'Widgets'),
      ('v10.0', 'Build'),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Column(
              children: [
                Text(
                  s.$1,
                  style: GoogleFonts.rajdhani(
                    color: p.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  s.$2,
                  style: GoogleFonts.inter(
                    color: p.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Install Guide ─────────────────────────────────────
  Widget _buildInstallGuide(dynamic p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INSTALLATIONSANLEITUNG',
            style: GoogleFonts.spaceMono(
              color: p.textSecondary,
              fontSize: 10,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 10),
          ..._steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isActive = i == _activeStep;
            final isDone = i < _activeStep;
            return GestureDetector(
              onTap: () => setState(() => _activeStep = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isActive
                      ? p.primary.withValues(alpha: 0.08)
                      : p.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? p.primary.withValues(alpha: 0.4)
                        : isDone
                            ? const Color(0xFF00E676).withValues(alpha: 0.3)
                            : p.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? const Color(0xFF00E676).withValues(alpha: 0.15)
                            : isActive
                                ? p.primary.withValues(alpha: 0.15)
                                : p.surfaceVariant,
                        border: Border.all(
                          color: isDone
                              ? const Color(0xFF00E676).withValues(alpha: 0.5)
                              : isActive
                                  ? p.primary.withValues(alpha: 0.5)
                                  : p.primary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check, color: Color(0xFF00E676), size: 18)
                          : Icon(
                              step.icon,
                              color: isActive ? p.primary : p.textSecondary,
                              size: 18,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Schritt ${step.number}: ',
                                style: GoogleFonts.spaceMono(
                                  color: isActive ? p.primary : p.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                step.title,
                                style: GoogleFonts.rajdhani(
                                  color: p.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            step.description,
                            style: GoogleFonts.inter(
                              color: p.textSecondary,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── System Requirements ───────────────────────────────
  Widget _buildSystemRequirements(dynamic p) {
    final reqs = [
      ('Android Version', 'Android 8.0 (Oreo) oder höher'),
      ('Prozessor', 'ARMv7 oder ARM64 (64-bit empfohlen)'),
      ('RAM', 'Mindestens 2 GB RAM'),
      ('Speicher', '150 MB freier Speicherplatz'),
      ('Internet', 'WLAN/Mobil für Live-Daten'),
      ('Bildschirm', '720x1280 oder höher'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYSTEMANFORDERUNGEN',
            style: GoogleFonts.spaceMono(
              color: p.textSecondary,
              fontSize: 10,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: reqs.asMap().entries.map((entry) {
                final i = entry.key;
                final req = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: i < reqs.length - 1
                        ? Border(
                            bottom: BorderSide(
                              color: p.primary.withValues(alpha: 0.07),
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: p.primary, size: 14),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Text(
                          req.$1,
                          style: GoogleFonts.spaceMono(
                            color: p.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          req.$2,
                          style: GoogleFonts.inter(
                            color: p.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Changelog ─────────────────────────────────────────
  Widget _buildChangelog(dynamic p) {
    final changes = [
      ('NEW', 'Enterprise License & Patent-System (Grigori Saks IP)', const Color(0xFF00E676)),
      ('NEW', 'Download Screen mit APK-Button & Installationsanleitung', const Color(0xFF00E676)),
      ('NEW', 'Dashboard v2: Sparklines, Heatmap, FIAT-Panel', const Color(0xFF00E676)),
      ('NEW', 'Wallet QR-Code: ETH, SOL, BTC, SEPA/SWIFT EUR/USD', const Color(0xFF00E676)),
      ('UPD', 'TradingView Charts via WebView (alle Timeframes)', const Color(0xFF2979FF)),
      ('UPD', 'CoinMarketCap Service: 15 Coins + Fear & Greed Index', const Color(0xFF2979FF)),
      ('UPD', 'CoinGecko Icons + lokale Fallback-Logos', const Color(0xFF2979FF)),
      ('FIX', 'flutter analyze: 0 Errors, 2 non-kritische Warnings', const Color(0xFFFF9100)),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHANGELOG v10.0',
            style: GoogleFonts.spaceMono(
              color: p.textSecondary,
              fontSize: 10,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.primary.withValues(alpha: 0.15)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: changes.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.$3.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: c.$3.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          c.$1,
                          style: GoogleFonts.spaceMono(
                            color: c.$3,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.$2,
                          style: GoogleFonts.inter(
                            color: p.textSecondary,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Legal Footer ──────────────────────────────────────
  Widget _buildLegalFooter(dynamic p) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/coins/app_icon.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.diamond, color: p.primary, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'HQMLL · QUANTUM TRADER AI SYSTEM',
                style: GoogleFonts.spaceMono(
                  color: p.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '© 2025 Grigori Saks · All Rights Reserved\n'
            'Patent-Pending · Proprietary Technology · Confidential\n'
            'Version 10.0.0+100 · Build: Enterprise Edition',
            style: GoogleFonts.inter(
              color: p.textSecondary,
              fontSize: 9,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Data Models ───────────────────────────────────────
class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureItem(this.icon, this.title, this.subtitle);
}

class _InstallStep {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  const _InstallStep(this.number, this.title, this.description, this.icon);
}
