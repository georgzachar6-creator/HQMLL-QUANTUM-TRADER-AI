// ============================================================
// ENTERPRISE SCREEN v2 – License, Team, API Keys, White-Label
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class EnterpriseScreen extends StatefulWidget {
  const EnterpriseScreen({super.key});
  @override
  State<EnterpriseScreen> createState() => _EnterpriseScreenState();
}

class _EnterpriseScreenState extends State<EnterpriseScreen>
    with TickerProviderStateMixin {
  late TabController _tab;
  late AnimationController _glowCtrl;

  // License
  final String _licenseKey = 'HQMLL-ENT-2025-X9K4-F8M2-QT17';
  final String _licenseType = 'Enterprise Ultimate';
  final DateTime _validUntil = DateTime(2026, 12, 31);
  final int _seatsUsed = 7;
  final int _seatTotal = 25;

  // Team Members
  final List<Map<String, dynamic>> _team = [
    {'name': 'G. Saks', 'role': 'Owner', 'email': 'saks@hqmll.io', 'status': 'online', 'perms': 'Full Access', 'color': const Color(0xFF00FF88), 'joined': '2024-01-01'},
    {'name': 'M. Müller', 'role': 'Senior Trader', 'email': 'm.mueller@hqmll.io', 'status': 'online', 'perms': 'Trading + Portfolio', 'color': const Color(0xFF00AAFF), 'joined': '2024-03-15'},
    {'name': 'A. Schmidt', 'role': 'Analyst', 'email': 'a.schmidt@hqmll.io', 'status': 'away', 'perms': 'Read + Analytics', 'color': const Color(0xFFFFD700), 'joined': '2024-06-01'},
    {'name': 'K. Weber', 'role': 'Developer', 'email': 'k.weber@hqmll.io', 'status': 'online', 'perms': 'Deploy + CMD', 'color': const Color(0xFFAA44FF), 'joined': '2024-08-22'},
    {'name': 'L. Fischer', 'role': 'Risk Manager', 'email': 'l.fischer@hqmll.io', 'status': 'offline', 'perms': 'Portfolio + Vault', 'color': const Color(0xFFFF6B35), 'joined': '2024-11-10'},
    {'name': 'T. Bauer', 'role': 'Compliance', 'email': 't.bauer@hqmll.io', 'status': 'online', 'perms': 'Read + Intel', 'color': const Color(0xFF00CED1), 'joined': '2025-01-20'},
    {'name': 'N. Hoffmann', 'role': 'DeFi Specialist', 'email': 'n.hoffmann@hqmll.io', 'status': 'away', 'perms': 'DeFi + Wallet', 'color': const Color(0xFFFF69B4), 'joined': '2025-03-05'},
  ];

  // API Keys
  final List<Map<String, dynamic>> _apiKeys = [
    {'name': 'Production API', 'key': 'hqmll_prod_x9k4f8m2qt17...', 'full': 'hqmll_prod_x9k4f8m2qt17_sk_live_3a9z', 'created': '2025-01-15', 'lastUsed': 'vor 2min', 'calls': 142840, 'status': 'active', 'scopes': ['read', 'trade', 'deploy'], 'color': const Color(0xFF00FF88)},
    {'name': 'Analytics Key', 'key': 'hqmll_anal_7x2n1p4...', 'full': 'hqmll_anal_7x2n1p4_sk_live_8b2w', 'created': '2025-02-01', 'lastUsed': 'vor 15min', 'calls': 28420, 'status': 'active', 'scopes': ['read', 'analytics'], 'color': const Color(0xFF00AAFF)},
    {'name': 'Bot Trading Key', 'key': 'hqmll_bot_m8k2j5w1...', 'full': 'hqmll_bot_m8k2j5w1_sk_live_6c4r', 'created': '2025-03-10', 'lastUsed': 'vor 3s', 'calls': 840210, 'status': 'active', 'scopes': ['trade', 'market'], 'color': const Color(0xFFAA44FF)},
    {'name': 'Staging Key', 'key': 'hqmll_stg_p2x8n4...', 'full': 'hqmll_stg_p2x8n4_sk_test_9d5s', 'created': '2025-03-20', 'lastUsed': 'vor 2h', 'calls': 4820, 'status': 'inactive', 'scopes': ['read'], 'color': const Color(0xFFFFD700)},
  ];

  // Usage Stats
  final Map<String, dynamic> _usage = {
    'apiCallsMonth': 1248400,
    'apiCallsLimit': 5000000,
    'storageGB': 4.8,
    'storageLimitGB': 100,
    'users': 7,
    'usersLimit': 25,
    'tradesMonth': 8420,
    'tradesLimit': 100000,
  };

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tab.dispose(); _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: p.background,
      body: Column(children: [
        _buildHeader(p),
        _buildTabBar(p),
        Expanded(child: TabBarView(controller: _tab, children: [
          _buildLicense(p),
          _buildTeam(p),
          _buildApiKeys(p),
          _buildUsage(p),
        ])),
      ]),
    );
  }

  Widget _buildHeader(dynamic p) {
    final daysLeft = _validUntil.difference(DateTime.now()).inDays;
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(bottom: BorderSide(color: const Color(0xFFFFD700).withValues(alpha: 0.15 + _glowCtrl.value * 0.08))),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFFFFD700).withValues(alpha: 0.25), const Color(0xFFFFD700).withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4 + _glowCtrl.value * 0.25)),
              boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.2 + _glowCtrl.value * 0.12), blurRadius: 14)],
            ),
            child: const Icon(Icons.verified_rounded, color: Color(0xFFFFD700), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('ENTERPRISE', style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFFD700).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3))),
                child: Text('ULTIMATE', style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 8, letterSpacing: 1)),
              ),
            ]),
            Text('$_seatsUsed/$_seatTotal Seats · Gültig noch $daysLeft Tage', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildTabBar(dynamic p) {
    return Container(
      color: p.surface,
      child: TabBar(
        controller: _tab,
        labelColor: const Color(0xFFFFD700),
        unselectedLabelColor: p.textSecondary,
        indicatorColor: const Color(0xFFFFD700),
        indicatorWeight: 2,
        labelStyle: GoogleFonts.spaceMono(fontSize: 10, letterSpacing: 1),
        unselectedLabelStyle: GoogleFonts.spaceMono(fontSize: 10),
        tabs: const [
          Tab(icon: Icon(Icons.verified_outlined, size: 15), text: 'LIZENZ'),
          Tab(icon: Icon(Icons.group_outlined, size: 15), text: 'TEAM'),
          Tab(icon: Icon(Icons.vpn_key_outlined, size: 15), text: 'API KEYS'),
          Tab(icon: Icon(Icons.bar_chart_rounded, size: 15), text: 'NUTZUNG'),
        ],
      ),
    );
  }

  // ── LICENSE ──
  Widget _buildLicense(dynamic p) {
    final daysLeft = _validUntil.difference(DateTime.now()).inDays;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        // License Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFFFFD700).withValues(alpha: 0.12), const Color(0xFFFF6B35).withValues(alpha: 0.06), p.surface],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
            boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.star_rounded, color: const Color(0xFFFFD700), size: 22),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_licenseType, style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                Text('HQMLL Technologies GmbH', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 11)),
              ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF00FF88).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.3))),
                child: Text('AKTIV', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 9, letterSpacing: 1)),
              ),
            ]),
            const SizedBox(height: 16),
            // License Key
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF020608), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.2))),
              child: Row(children: [
                Icon(Icons.vpn_key_rounded, color: const Color(0xFFFFD700), size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(_licenseKey, style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 11, letterSpacing: 0.5))),
                GestureDetector(
                  onTap: () { Clipboard.setData(ClipboardData(text: _licenseKey)); HapticFeedback.lightImpact(); },
                  child: Icon(Icons.copy_rounded, color: p.textSecondary, size: 16),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            // Validity
            Row(children: [
              Icon(Icons.calendar_today_rounded, color: p.textSecondary, size: 13),
              const SizedBox(width: 6),
              Text('Gültig bis: ${_validUntil.day}.${_validUntil.month}.${_validUntil.year} · Noch $daysLeft Tage', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: daysLeft / 365,
                backgroundColor: const Color(0xFFFFD700).withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
                minHeight: 5,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // Features
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.primary.withValues(alpha: 0.1))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ENTERPRISE FEATURES', style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            ...[ 
              ('Unbegrenzte API-Calls', true, const Color(0xFF00FF88)),
              ('25 Team-Mitglieder', true, const Color(0xFF00FF88)),
              ('White-Label Branding', true, const Color(0xFF00FF88)),
              ('Dedizierter Support', true, const Color(0xFF00FF88)),
              ('Custom Integrationen', true, const Color(0xFF00FF88)),
              ('SLA: 99.9% Uptime', true, const Color(0xFF00FF88)),
              ('On-Premise Deployment', true, const Color(0xFF00FF88)),
              ('Compliance Reports', true, const Color(0xFF00FF88)),
              ('AI Modell Training', true, const Color(0xFF00AAFF)),
              ('Quantum Vault', true, const Color(0xFFFFD700)),
            ].map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Icon(f.$2 ? Icons.check_circle_rounded : Icons.cancel_rounded, color: f.$3, size: 16),
                const SizedBox(width: 10),
                Text(f.$1, style: GoogleFonts.inter(color: p.textPrimary, fontSize: 12)),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 12),
        // Renew button
        GestureDetector(
          onTap: () { HapticFeedback.mediumImpact(); },
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF6B35)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.25), blurRadius: 12)],
            ),
            child: Center(child: Text('LIZENZ ERNEUERN / UPGRADEN', style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold))),
          ),
        ),
      ]),
    );
  }

  // ── TEAM ──
  Widget _buildTeam(dynamic p) {
    final onlineCount = _team.where((m) => m['status'] == 'online').length;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.primary.withValues(alpha: 0.1))),
          child: Row(children: [
            Expanded(child: _teamStat('GESAMT', '${_team.length}/$_seatTotal', const Color(0xFFFFD700), p)),
            Expanded(child: _teamStat('ONLINE', '$onlineCount', const Color(0xFF00FF88), p)),
            Expanded(child: _teamStat('ABWESEND', '${_team.where((m) => m['status'] == 'away').length}', const Color(0xFFFFD700), p)),
            Expanded(child: _teamStat('OFFLINE', '${_team.where((m) => m['status'] == 'offline').length}', const Color(0xFFFF3358), p)),
          ]),
        ),
        ..._team.map((member) {
          final color = member['color'] as Color;
          final statusColor = member['status'] == 'online' ? const Color(0xFF00FF88) : member['status'] == 'away' ? const Color(0xFFFFD700) : const Color(0xFFFF3358);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.12))),
            child: Row(children: [
              Stack(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.08)]), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.3))),
                  child: Center(child: Text((member['name'] as String).split(' ').map((w) => w[0]).take(2).join(), style: GoogleFonts.spaceMono(color: color, fontSize: 14, fontWeight: FontWeight.bold))),
                ),
                Positioned(bottom: 0, right: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, border: Border.all(color: p.surface, width: 2)))),
              ]),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(member['name'] as String, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(member['role'] as String, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
                Text(member['email'] as String, style: GoogleFonts.inter(color: p.textSecondary.withValues(alpha: 0.6), fontSize: 9)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(member['perms'] as String, style: GoogleFonts.spaceMono(color: color, fontSize: 7)),
                ),
                const SizedBox(height: 4),
                Text('ab ${member['joined']}', style: GoogleFonts.inter(color: p.textSecondary.withValues(alpha: 0.5), fontSize: 8)),
              ]),
            ]),
          );
        }),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () { HapticFeedback.mediumImpact(); },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.25), style: BorderStyle.solid),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.person_add_rounded, color: const Color(0xFFFFD700), size: 18),
              const SizedBox(width: 8),
              Text('MITGLIED EINLADEN', style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 11, letterSpacing: 1)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _teamStat(String label, String value, Color color, dynamic p) {
    return Column(children: [
      Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
    ]);
  }

  // ── API KEYS ──
  Widget _buildApiKeys(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFF00AAFF).withValues(alpha: 0.08), p.surface]),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF00AAFF).withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.security_rounded, color: const Color(0xFF00AAFF), size: 16),
              const SizedBox(width: 8),
              Text('API KEY VERWALTUNG', style: GoogleFonts.spaceMono(color: const Color(0xFF00AAFF), fontSize: 11, letterSpacing: 1)),
            ]),
            const SizedBox(height: 4),
            Text('Alle Keys sind AES-256 verschlüsselt. Nie öffentlich teilen!', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10, height: 1.4)),
          ]),
        ),
        ..._apiKeys.map((key) {
          final color = key['color'] as Color;
          final isActive = key['status'] == 'active';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.vpn_key_rounded, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(key['name'] as String, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('Erstellt: ${key['created']} · Zuletzt: ${key['lastUsed']}', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: (isActive ? const Color(0xFF00FF88) : const Color(0xFFFF3358)).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(isActive ? 'AKTIV' : 'INAKTIV', style: GoogleFonts.spaceMono(color: isActive ? const Color(0xFF00FF88) : const Color(0xFFFF3358), fontSize: 8)),
                ),
              ]),
              const SizedBox(height: 10),
              // Key display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF020608), borderRadius: BorderRadius.circular(7)),
                child: Row(children: [
                  Expanded(child: Text(key['key'] as String, style: GoogleFonts.spaceMono(color: color.withValues(alpha: 0.8), fontSize: 10))),
                  GestureDetector(
                    onTap: () { Clipboard.setData(ClipboardData(text: key['full'] as String)); HapticFeedback.lightImpact(); },
                    child: Icon(Icons.copy_rounded, color: p.textSecondary, size: 14),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              // Scopes
              Row(children: [
                ...(key['scopes'] as List<String>).map((s) => Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.2))),
                  child: Text(s, style: GoogleFonts.spaceMono(color: color, fontSize: 8)),
                )),
                const Spacer(),
                Text('${(key['calls'] as int).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')} calls', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
              ]),
            ]),
          );
        }),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () { HapticFeedback.mediumImpact(); },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF00AAFF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00AAFF).withValues(alpha: 0.25)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.add_rounded, color: Color(0xFF00AAFF), size: 18),
              const SizedBox(width: 8),
              Text('NEUEN API KEY ERSTELLEN', style: GoogleFonts.spaceMono(color: const Color(0xFF00AAFF), fontSize: 11, letterSpacing: 1)),
            ]),
          ),
        ),
      ],
    );
  }

  // ── USAGE ──
  Widget _buildUsage(dynamic p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        _usageCard('API CALLS / MONAT', _usage['apiCallsMonth'], _usage['apiCallsLimit'], 'Calls', const Color(0xFF00AAFF), p),
        const SizedBox(height: 10),
        _usageCard('SPEICHER', (_usage['storageGB'] * 1).round(), _usage['storageLimitGB'], 'GB', const Color(0xFFAA44FF), p),
        const SizedBox(height: 10),
        _usageCard('NUTZER / SEATS', _usage['users'], _usage['usersLimit'], 'Seats', const Color(0xFFFFD700), p),
        const SizedBox(height: 10),
        _usageCard('TRADES / MONAT', _usage['tradesMonth'], _usage['tradesLimit'], 'Trades', const Color(0xFF00FF88), p),
        const SizedBox(height: 14),

        // Billing Summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFFFFD700).withValues(alpha: 0.08), p.surface]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ABRECHNUNG', style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            ...[
              ('Enterprise Plan (monatlich)', '\$2,499'),
              ('Zusatz-Seats (0x)', '\$0'),
              ('Overage API Calls (0)', '\$0'),
              ('Support Premium', 'inkl.'),
            ].map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: Text(item.$1, style: GoogleFonts.inter(color: p.textPrimary, fontSize: 11))),
                Text(item.$2, style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            )),
            const Divider(color: Color(0xFFFFD700), height: 1, thickness: 0.3),
            const SizedBox(height: 8),
            Row(children: [
              Text('GESAMT / MONAT', style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('\$2,499', style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _usageCard(String label, dynamic used, dynamic limit, String unit, Color color, dynamic p) {
    final double pct = (used / limit).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(children: [
        Row(children: [
          Text(label, style: GoogleFonts.spaceMono(color: color, fontSize: 10, letterSpacing: 1)),
          const Spacer(),
          Text('${_formatNum(used)} / ${_formatNum(limit)} $unit', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: pct, minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(pct > 0.9 ? const Color(0xFFFF3358) : pct > 0.7 ? const Color(0xFFFFD700) : color),
          ),
        ),
        const SizedBox(height: 4),
        Row(children: [
          Text('${(pct * 100).toStringAsFixed(1)}% genutzt', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
          const Spacer(),
          Text('${_formatNum(limit - (used as int))} $unit verbleibend', style: GoogleFonts.spaceMono(color: color, fontSize: 9)),
        ]),
      ]),
    );
  }

  String _formatNum(dynamic n) {
    final i = n as int;
    if (i >= 1000000) return '${(i / 1000000).toStringAsFixed(1)}M';
    if (i >= 1000) return '${(i / 1000).toStringAsFixed(0)}K';
    return '$i';
  }
}
