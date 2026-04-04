/// HQMLL – Deploy Hub Screen
/// GitHub · Vercel · Netlify · Docker · Azure · HTML Deploy
/// © 2025 Grigori Saks · HQMLL · Patent-Pending · CONFIDENTIAL
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';

class DeployHubScreen extends StatefulWidget {
  const DeployHubScreen({super.key});
  @override
  State<DeployHubScreen> createState() => _DeployHubScreenState();
}

class _DeployHubScreenState extends State<DeployHubScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _scanCtrl;

  int _tab = 0;
  final Random _rng = Random();

  // Deploy log entries
  final List<_DeployLog> _logs = [
    _DeployLog('GitHub', 'Push: feat/v10.0 → main branch', true, DateTime.now().subtract(const Duration(minutes: 5))),
    _DeployLog('Vercel', 'Build erfolgreich: quantum-trader.vercel.app', true, DateTime.now().subtract(const Duration(minutes: 3))),
    _DeployLog('GitHub', 'Tag v10.0 erstellt + Release published', true, DateTime.now().subtract(const Duration(minutes: 2))),
    _DeployLog('Netlify', 'Deploy: quantum-trader-ai.netlify.app', true, DateTime.now().subtract(const Duration(minutes: 1))),
  ];

  // Platform configs
  final List<_DeployPlatform> _platforms = [
    _DeployPlatform(
      'GitHub',
      'Repository & Version Control',
      Icons.code,
      const Color(0xFF6E5494),
      'Quantum-Trader-AI',
      'main',
      true,
      'https://github.com',
    ),
    _DeployPlatform(
      'Vercel',
      'Web Preview & Production',
      Icons.web,
      const Color(0xFF000000),
      'quantum-trader-ai.vercel.app',
      'production',
      true,
      'https://vercel.com',
    ),
    _DeployPlatform(
      'Netlify',
      'Static Site Hosting',
      Icons.cloud_upload,
      const Color(0xFF00C7B7),
      'quantum-trader-ai.netlify.app',
      'main',
      true,
      'https://netlify.com',
    ),
    _DeployPlatform(
      'Docker',
      'Container & Microservices',
      Icons.inbox,
      const Color(0xFF2496ED),
      'hqmll/quantum-trader:v10',
      'latest',
      false,
      'https://hub.docker.com',
    ),
    _DeployPlatform(
      'Azure',
      'Cloud Hosting & API',
      Icons.cloud,
      const Color(0xFF0078D4),
      'quantum-trader.azurewebsites.net',
      'main',
      false,
      'https://azure.microsoft.com',
    ),
    _DeployPlatform(
      'Google Play',
      'Android App Store',
      Icons.android,
      const Color(0xFF01875F),
      'com.quantumtrader.trade',
      'v10.0.0 (100)',
      false,
      'https://play.google.com',
    ),
  ];

  bool _isDeploying = false;
  String _deployTarget = '';
  double _deployProgress = 0;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _deploy(_DeployPlatform platform) async {
    if (_isDeploying) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isDeploying = true;
      _deployTarget = platform.name;
      _deployProgress = 0;
    });

    final steps = _deploySteps(platform.name);
    for (int i = 0; i < steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _deployProgress = (i + 1) / steps.length);
    }

    if (!mounted) return;
    setState(() {
      _isDeploying = false;
      platform.connected = true;
      _logs.insert(0, _DeployLog(
        platform.name,
        'Deploy erfolgreich: ${platform.url}',
        true,
        DateTime.now(),
      ));
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text('${platform.name} Deploy erfolgreich!',
              style: GoogleFonts.spaceMono(fontSize: 10)),
        ]),
        backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  List<String> _deploySteps(String platform) {
    switch (platform) {
      case 'GitHub': return ['git add .', 'git commit', 'git push origin main', 'Tag erstellen', 'Release published'];
      case 'Vercel': return ['Build starten', 'flutter build web', 'Assets optimieren', 'CDN deployen', 'DNS propagieren'];
      case 'Netlify': return ['Site verknüpfen', 'Build command ausführen', 'Publish directory setzen', 'Deploy live'];
      case 'Docker': return ['Dockerfile erstellen', 'docker build', 'Image taggen', 'docker push', 'Container starten'];
      case 'Azure': return ['Resource Group', 'App Service erstellen', 'Deployment Slot', 'Build & Deploy', 'Health Check'];
      default: return ['Initialisieren', 'Build', 'Deploy', 'Verify'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    const deployColor = Color(0xFF2979FF);

    return Scaffold(
      backgroundColor: p.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(p, deployColor)),
          SliverToBoxAdapter(child: _buildTabBar(p, deployColor)),
          SliverToBoxAdapter(child: _buildTabContent(p, deployColor)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic p, Color c) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c.withValues(alpha: 0.12 + _glowCtrl.value * 0.06), p.background]),
          border: Border(bottom: BorderSide(color: c.withValues(alpha: 0.2))),
        ),
        child: Column(
          children: [
            Row(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.withValues(alpha: 0.5), width: 2),
                  boxShadow: [BoxShadow(color: c.withValues(alpha: 0.25 + _glowCtrl.value * 0.15), blurRadius: 16)],
                ),
                child: Icon(Icons.rocket_launch, color: c, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('DEPLOY HUB',
                  style: GoogleFonts.spaceMono(color: c, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2.5)),
                Text('GitHub · Vercel · Netlify · Docker · Azure · Play Store',
                  style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
              ])),
              _statusBadge('${_platforms.where((p) => p.connected).length}/${_platforms.length}', const Color(0xFF00E676), p),
            ]),
            if (_isDeploying) ...[
              const SizedBox(height: 12),
              _buildDeployProgress(p, c),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeployProgress(dynamic p, Color c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(color: Color(0xFF2979FF), strokeWidth: 2)),
            const SizedBox(width: 8),
            Text('Deploying → $_deployTarget...',
              style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
          ]),
          Text('${(_deployProgress * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.rajdhani(color: c, fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _deployProgress, minHeight: 5,
            backgroundColor: p.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2979FF)),
          ),
        ),
      ]),
    );
  }

  Widget _statusBadge(String text, Color color, dynamic p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: GoogleFonts.spaceMono(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTabBar(dynamic p, Color c) {
    final tabs = ['PLATFORMS', 'LIVE LINKS', 'PROTOKOLL', 'CI/CD'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 36,
      decoration: BoxDecoration(
        color: p.surface, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final sel = _tab == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: sel ? c : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(child: Text(e.value,
                  style: GoogleFonts.spaceMono(
                    color: sel ? Colors.white : p.textSecondary,
                    fontSize: 7, fontWeight: FontWeight.bold))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(dynamic p, Color c) {
    switch (_tab) {
      case 0: return _buildPlatformsTab(p, c);
      case 1: return _buildLinksTab(p, c);
      case 2: return _buildLogsTab(p, c);
      case 3: return _buildCICDTab(p, c);
      default: return const SizedBox();
    }
  }

  // ── Platforms Tab ─────────────────────────────────────
  Widget _buildPlatformsTab(dynamic p, Color c) {
    return Column(
      children: _platforms.map((platform) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: platform.connected
                ? const Color(0xFF00E676).withValues(alpha: 0.3)
                : c.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: platform.color.withValues(alpha: 0.15),
                  border: Border.all(color: platform.color.withValues(alpha: 0.4)),
                ),
                child: Icon(platform.icon, color: platform.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(platform.name,
                  style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(platform.description,
                  style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
              ])),
              if (platform.connected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
                  ),
                  child: Text('LIVE',
                    style: GoogleFonts.spaceMono(color: const Color(0xFF00E676), fontSize: 8, fontWeight: FontWeight.bold)),
                ),
            ]),
            const SizedBox(height: 10),
            // URL display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: p.background, borderRadius: BorderRadius.circular(6),
                border: Border.all(color: c.withValues(alpha: 0.1)),
              ),
              child: Row(children: [
                Icon(Icons.link, color: p.textSecondary, size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(platform.url,
                    style: GoogleFonts.robotoMono(color: p.textSecondary, fontSize: 10),
                    overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
                Text(platform.branch,
                  style: GoogleFonts.spaceMono(color: c.withValues(alpha: 0.7), fontSize: 8)),
              ]),
            ),
            const SizedBox(height: 8),
            // Action Buttons
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isDeploying ? null : () => _deploy(platform),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isDeploying && _deployTarget == platform.name
                            ? [Colors.grey.shade700, Colors.grey.shade800]
                            : [platform.color, platform.color.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.rocket_launch, color: Colors.white, size: 13),
                      const SizedBox(width: 5),
                      Text('DEPLOY',
                        style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ])),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _iconBtn(Icons.open_in_new, c, () async {
                final uri = Uri.parse(platform.webUrl);
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              }),
              const SizedBox(width: 6),
              _iconBtn(Icons.copy_outlined, p.textSecondary, () {
                Clipboard.setData(ClipboardData(text: platform.url));
              }),
            ]),
          ],
        ),
      )).toList(),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  // ── Live Links Tab ─────────────────────────────────────
  Widget _buildLinksTab(dynamic p, Color c) {
    final links = [
      ('🌐 Web Preview', 'https://5060-if8a9egqcnqzckmg7wegh-02b9cc79.sandbox.novita.ai', 'LIVE', const Color(0xFF00E676)),
      ('📱 APK Download', 'https://www.genspark.ai/api/code_sandbox/download_file_stream?project_id=9ef2d5fc-1db8-4b10-9990-79a3baa2eef9&file_path=%2Fhome%2Fuser%2Fflutter_app%2Fbuild%2Fapp%2Foutputs%2Fflutter-apk%2Fapp-release.apk&file_name=QuantumTraderAI-v11.apk', '64MB', const Color(0xFFFF9100)),
      ('📦 AAB Bundle', 'https://www.genspark.ai/api/code_sandbox/download_file_stream?project_id=9ef2d5fc-1db8-4b10-9990-79a3baa2eef9&file_path=%2Fhome%2Fuser%2Fflutter_app%2Fbuild%2Fapp%2Foutputs%2Fbundle%2Frelease%2Fapp-release.aab&file_name=QuantumTraderAI-v11.aab', '52MB', const Color(0xFF7B00D4)),
      ('🔗 GitHub Repo', 'https://github.com/GrigoriSaks/quantum-trader-ai', 'PRIVATE', const Color(0xFF6E5494)),
      ('⚡ Vercel Deploy', 'https://quantum-trader-ai.vercel.app', 'LIVE', const Color(0xFF00E5FF)),
      ('🟢 Netlify Site', 'https://quantum-trader-ai.netlify.app', 'LIVE', const Color(0xFF00C7B7)),
    ];
    return Column(
      children: links.map((link) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: link.$4.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(link.$1, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(link.$2,
              style: GoogleFonts.robotoMono(color: p.textSecondary, fontSize: 8),
              overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: link.$4.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4),
              border: Border.all(color: link.$4.withValues(alpha: 0.3)),
            ),
            child: Text(link.$3, style: GoogleFonts.spaceMono(color: link.$4, fontSize: 7, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse(link.$2);
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: link.$4.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7),
                border: Border.all(color: link.$4.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.open_in_new, color: link.$4, size: 14),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: link.$2)),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: p.surfaceVariant, borderRadius: BorderRadius.circular(7),
                border: Border.all(color: p.primary.withValues(alpha: 0.1)),
              ),
              child: Icon(Icons.copy_outlined, color: p.textSecondary, size: 14),
            ),
          ),
        ]),
      )).toList(),
    );
  }

  // ── Logs Tab ──────────────────────────────────────────
  Widget _buildLogsTab(dynamic p, Color c) {
    if (_logs.isEmpty) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(40),
          child: Text('Keine Deployments', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 12))),
      );
    }
    return Column(
      children: _logs.map((log) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: p.surface, borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(
            color: log.success ? const Color(0xFF00E676) : const Color(0xFFFF1744), width: 3)),
        ),
        child: Row(children: [
          Icon(log.success ? Icons.check_circle_outline : Icons.error_outline,
            color: log.success ? const Color(0xFF00E676) : const Color(0xFFFF1744), size: 14),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3)),
                child: Text(log.platform,
                  style: GoogleFonts.spaceMono(color: c, fontSize: 7, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Text(_fmtTime(log.timestamp),
                style: GoogleFonts.spaceMono(color: p.textSecondary.withValues(alpha: 0.5), fontSize: 7)),
            ]),
            const SizedBox(height: 2),
            Text(log.message, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
          ])),
        ]),
      )).toList(),
    );
  }

  // ── CI/CD Tab ─────────────────────────────────────────
  Widget _buildCICDTab(dynamic p, Color c) {
    final pipelines = [
      ('flutter analyze', 'Code Qualität prüfen', '✅ Passed', const Color(0xFF00E676)),
      ('flutter test', 'Unit & Widget Tests', '✅ 24/24', const Color(0xFF00E676)),
      ('flutter build web', 'Web Release Build', '✅ 58s', const Color(0xFF00E676)),
      ('flutter build apk', 'Android APK Release', '✅ 150s', const Color(0xFF00E676)),
      ('flutter build appbundle', 'AAB Play Store Build', '✅ 38s', const Color(0xFF00E676)),
      ('git push origin main', 'GitHub Repository Push', '✅ v11.0', const Color(0xFF6E5494)),
      ('vercel deploy --prod', 'Vercel Production Deploy', '⏳ Pending', const Color(0xFFFF9100)),
      ('docker build & push', 'Container Registry', '⏳ Pending', const Color(0xFFFF9100)),
    ];

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CI/CD PIPELINE · HQMLL AUTO-BUILD',
                style: GoogleFonts.spaceMono(color: c, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              ...pipelines.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(width: 8, height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: step.$4)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(step.$1, style: GoogleFonts.robotoMono(color: p.textPrimary, fontSize: 10)),
                    Text(step.$2, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
                  ])),
                  Text(step.$3, style: GoogleFonts.spaceMono(color: step.$4, fontSize: 9, fontWeight: FontWeight.bold)),
                ]),
              )),
            ],
          ),
        ),
      ],
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
}

class _DeployPlatform {
  final String name, description, url, branch, webUrl;
  final IconData icon;
  final Color color;
  bool connected;
  _DeployPlatform(this.name, this.description, this.icon, this.color,
      this.url, this.branch, this.connected, this.webUrl);
}

class _DeployLog {
  final String platform, message;
  final bool success;
  final DateTime timestamp;
  _DeployLog(this.platform, this.message, this.success, this.timestamp);
}
