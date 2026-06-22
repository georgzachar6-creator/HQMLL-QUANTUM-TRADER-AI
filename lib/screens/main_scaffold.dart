import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../widgets/quantum_eye_widget.dart';
import 'oracle_screen.dart';
import 'trading_screen.dart';
import 'portfolio_screen.dart';
import 'token_screen.dart';
import 'settings_screen.dart';
import 'wallet_screen.dart';
import 'alarm_screen.dart';
import 'market_screen.dart';
import 'ai_forge_screen.dart';
import 'god_mode_screen.dart';
import 'dashboard_screen.dart';
import 'download_screen.dart';
import 'enterprise_screen.dart';
import 'secure_vault_screen.dart';
import 'ai_genius_screen.dart';
import 'mining_screen.dart';
import 'deploy_hub_screen.dart';
import 'command_center_screen.dart';
import 'fiat_screen.dart';
import 'trading_bot_screen.dart';
import 'social_trading_screen.dart';
import 'analytics_screen.dart';
import 'defi_screen.dart';
import 'intelligence_screen.dart';
import 'news_screen.dart';
import 'writer_screen.dart';
import 'tr2_preview_screen.dart';
import 'ai_chat_screen.dart';
import 'connector_screen.dart';
import 'nft_screen.dart';
import 'orderbook_screen.dart';
import 'tax_screen.dart';
import 'staking_screen.dart';
import 'rebalancer_screen.dart';
import 'alerts_screen.dart';
import 'accounting_screen.dart';
import 'enterprise_wallet_screen.dart';
import 'ai_orchestrator_screen.dart';
import 'oms_risk_screen.dart';
import 'quantum_research_screen.dart';
import 'qml_research_screen.dart';
import 'kyc_aml_screen.dart';
import 'market_data_ingestion_screen.dart';
import 'performance_screen.dart';
import 'auto_workflow_screen.dart';
import 'auth_screen.dart';
import '../services/auth_service.dart';
import '../services/exchange_service.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _glowCtrl;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'DASHBOARD'),
    _NavItem(icon: Icons.remove_red_eye_outlined, activeIcon: Icons.remove_red_eye, label: 'ORACLE'),
    _NavItem(icon: Icons.candlestick_chart_outlined, activeIcon: Icons.candlestick_chart, label: 'TRADING'),
    _NavItem(icon: Icons.bar_chart_rounded, activeIcon: Icons.bar_chart, label: 'MARKT'),
    _NavItem(icon: Icons.pie_chart_outline, activeIcon: Icons.pie_chart, label: 'PORTFOLIO'),
    _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'WALLET'),
    _NavItem(icon: Icons.wallet_rounded, activeIcon: Icons.wallet, label: 'ENT.WALLET'),
    _NavItem(icon: Icons.psychology_alt_outlined, activeIcon: Icons.psychology_alt, label: 'AI-ORCH'),
    _NavItem(icon: Icons.balance_outlined, activeIcon: Icons.balance, label: 'OMS/RISK'),
    _NavItem(icon: Icons.token_outlined, activeIcon: Icons.token, label: 'QEMMA'),
    _NavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: 'AI FORGE'),
    _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'ALARMS'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'SETTINGS'),
    _NavItem(icon: Icons.download_rounded, activeIcon: Icons.download, label: 'DOWNLOAD'),
    _NavItem(icon: Icons.verified_outlined, activeIcon: Icons.verified, label: 'ENTERPRISE'),
    _NavItem(icon: Icons.enhanced_encryption, activeIcon: Icons.enhanced_encryption, label: 'VAULT'),
    _NavItem(icon: Icons.psychology_outlined, activeIcon: Icons.psychology, label: 'AI GENIUS'),
    _NavItem(icon: Icons.hardware_outlined, activeIcon: Icons.hardware, label: 'MINING'),
    _NavItem(icon: Icons.rocket_launch_outlined, activeIcon: Icons.rocket_launch, label: 'DEPLOY'),
    _NavItem(icon: Icons.terminal_outlined, activeIcon: Icons.terminal, label: 'CMD'),
    _NavItem(icon: Icons.euro_outlined, activeIcon: Icons.euro, label: 'FIAT'),
    _NavItem(icon: Icons.smart_toy_outlined, activeIcon: Icons.smart_toy, label: 'BOT'),
    _NavItem(icon: Icons.groups_outlined, activeIcon: Icons.groups, label: 'SOCIAL'),
    _NavItem(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'ANALYTICS'),
    _NavItem(icon: Icons.account_balance_outlined, activeIcon: Icons.account_balance, label: 'DeFi'),
    _NavItem(icon: Icons.shield_outlined, activeIcon: Icons.shield, label: 'INTEL'),
    _NavItem(icon: Icons.newspaper_outlined, activeIcon: Icons.newspaper, label: 'NEWS'),
    _NavItem(icon: Icons.edit_note_rounded, activeIcon: Icons.edit_note, label: 'WRITER'),
    _NavItem(icon: Icons.hub_outlined, activeIcon: Icons.hub, label: 'TR2'),
    _NavItem(icon: Icons.smart_toy_rounded, activeIcon: Icons.smart_toy_rounded, label: 'AI CHAT'),
    _NavItem(icon: Icons.hub_rounded, activeIcon: Icons.hub, label: 'CONNECTOR'),
    _NavItem(icon: Icons.image_outlined, activeIcon: Icons.image, label: 'NFT'),
    _NavItem(icon: Icons.format_list_numbered, activeIcon: Icons.format_list_numbered, label: 'ORDERBOOK'),
    _NavItem(icon: Icons.calculate_outlined, activeIcon: Icons.calculate, label: 'STEUER'),
    _NavItem(icon: Icons.savings_outlined, activeIcon: Icons.savings, label: 'STAKING'),
    _NavItem(icon: Icons.auto_awesome, activeIcon: Icons.auto_awesome, label: 'REBALANCER'),
    _NavItem(icon: Icons.notifications_active_outlined, activeIcon: Icons.notifications_active, label: 'ALARMS'),
    _NavItem(icon: Icons.auto_awesome, activeIcon: Icons.auto_awesome, label: 'BUCHHALTER'),
    _NavItem(icon: Icons.science_outlined, activeIcon: Icons.science, label: 'QUANTUM'),
    _NavItem(icon: Icons.biotech_outlined, activeIcon: Icons.biotech, label: 'QML LAB'),
    _NavItem(icon: Icons.verified_user_outlined, activeIcon: Icons.verified_user, label: 'KYC/AML'),
    _NavItem(icon: Icons.sensors_outlined, activeIcon: Icons.sensors, label: 'MKTDATA'),
    _NavItem(icon: Icons.speed_outlined, activeIcon: Icons.speed, label: 'PERF'),
    _NavItem(icon: Icons.account_tree_outlined, activeIcon: Icons.account_tree, label: 'WORKFLOW'),
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;

    final screens = [
      const DashboardScreen(),
      const OracleScreen(),
      const TradingScreen(),
      const MarketScreen(),
      const PortfolioScreen(),
      const WalletScreen(),
      const EnterpriseWalletScreen(),
      const AiOrchestratorScreen(),
      const OmsRiskScreen(),
      const TokenScreen(),
      const AIForgeScreen(),
      const AlarmScreen(),
      const SettingsScreen(),
      const DownloadScreen(),
      const EnterpriseScreen(),
      const SecureVaultScreen(),
      const AIGeniusScreen(),
      const MiningScreen(),
      const DeployHubScreen(),
      const CommandCenterScreen(),
      const FiatScreen(),
      const TradingBotScreen(),
      const SocialTradingScreen(),
      const AnalyticsScreen(),
      const DeFiScreen(),
      const IntelligenceScreen(),
      const NewsScreen(),
      const WriterScreen(),
      const TR2PreviewScreen(),
      const AIChatScreen(),
      const ConnectorScreen(),
      const NFTScreen(),
      const OrderbookScreen(),
      const TaxScreen(),
      const StakingScreen(),
      const RebalancerScreen(),
      const AlertsScreen(),
      const AccountingScreen(),
      const QuantumResearchScreen(),
      const QMLResearchScreen(),
      const KycAmlScreen(),
      const MarketDataIngestionScreen(),
      const PerformanceScreen(),
      const AutoWorkflowScreen(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: p.surface,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: p.background,
        appBar: _buildAppBar(context, tp, p),
        body: Column(
          children: [
            _LiveTickerBanner(palette: p),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: screens,
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildNavBar(p),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeProvider tp, dynamic p) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(58),
      child: AnimatedBuilder(
        animation: _glowCtrl,
        builder: (_, __) {
          return Container(
            decoration: BoxDecoration(
              color: p.background,
              border: Border(
                bottom: BorderSide(
                  color: p.primary.withValues(alpha: 0.08 + _glowCtrl.value * 0.06),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 58,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Logo + Titel – pulsierender Glow-Ring
                      AnimatedBuilder(
                        animation: _glowCtrl,
                        builder: (_, child) => Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: p.primary.withValues(
                                    alpha: 0.15 + _glowCtrl.value * 0.25),
                                blurRadius: 10 + _glowCtrl.value * 8,
                                spreadRadius: 1 + _glowCtrl.value * 2,
                              ),
                            ],
                          ),
                          child: child,
                        ),
                        child: QuantumEyeWidget(
                          palette: p,
                          size: 32,
                          animate: tp.quantumAnimations,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HQMLL',
                            style: GoogleFonts.spaceMono(
                              color: p.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3.0,
                            ),
                          ),
                          Text(
                            'Quantum Trader',
                            style: GoogleFonts.inter(
                              color: p.textSecondary,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // God Mode Badge
                      if (tp.godModeEnabled)
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(color: p.primary.withValues(alpha: 0.7)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'GOD MODE',
                            style: GoogleFonts.spaceMono(
                              color: p.primary,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      // Agent Status
                      _AgentStatusIndicator(palette: p),
                      const SizedBox(width: 8),
                      // God Mode Button
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GodModeScreen()),
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: tp.godModeEnabled
                                ? p.primary.withValues(alpha: 0.15)
                                : p.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: tp.godModeEnabled
                                  ? p.primary.withValues(alpha: 0.6)
                                  : p.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.security,
                            color: tp.godModeEnabled ? p.primary : p.textSecondary,
                            size: 17,
                          ),
                        ),
                      ),
                      // Auto-Trade Toggle
                      Consumer<ExchangeService>(
                        builder: (_, ex, __) => GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            ex.setAutoTrade(!ex.autoTradeEnabled);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ex.autoTradeEnabled
                                  ? '🤖 Auto-Trading AKTIVIERT'
                                  : '⏹ Auto-Trading DEAKTIVIERT'),
                              backgroundColor: ex.autoTradeEnabled ? const Color(0xFF00C853) : const Color(0xFFB71C1C),
                              duration: const Duration(seconds: 2),
                            ));
                          },
                          child: AnimatedBuilder(
                            animation: _glowCtrl,
                            builder: (_, __) => Container(
                              width: 36, height: 36,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: ex.autoTradeEnabled
                                    ? p.positive.withValues(alpha: 0.15 + _glowCtrl.value * 0.1)
                                    : p.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: ex.autoTradeEnabled
                                      ? p.positive.withValues(alpha: 0.6 + _glowCtrl.value * 0.3)
                                      : p.primary.withValues(alpha: 0.2),
                                  width: ex.autoTradeEnabled ? 1.5 : 1,
                                ),
                                boxShadow: ex.autoTradeEnabled ? [BoxShadow(
                                  color: p.positive.withValues(alpha: 0.2 + _glowCtrl.value * 0.2),
                                  blurRadius: 8 + _glowCtrl.value * 4,
                                )] : null,
                              ),
                              child: Icon(
                                ex.autoTradeEnabled ? Icons.smart_toy : Icons.smart_toy_outlined,
                                color: ex.autoTradeEnabled ? p.positive : p.textSecondary,
                                size: 17,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // User Avatar / Logout
                      Consumer<AuthService>(
                        builder: (_, auth, __) => GestureDetector(
                          onLongPress: () async {
                            await auth.autoSave();
                            await auth.logout();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const AuthScreen()),
                                (_) => false,
                              );
                            }
                          },
                          onTap: () => _showUserPanel(context, p, auth),
                          child: Container(
                            width: 36, height: 36,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: p.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: p.primary.withValues(alpha: 0.4)),
                            ),
                            child: Center(child: Text(
                              auth.currentUser?.displayName.isNotEmpty == true
                                  ? auth.currentUser!.displayName[0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.orbitron(color: p.primary, fontSize: 13, fontWeight: FontWeight.bold),
                            )),
                          ),
                        ),
                      ),
                      // Notification Button
                      GestureDetector(
                        onTap: () => _showNotificationPanel(context, p),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: p.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            color: p.textSecondary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavBar(dynamic p) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(
          top: BorderSide(color: p.primary.withValues(alpha: 0.12), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final selected = _selectedIndex == i;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedIndex = i);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: selected ? 72 : 58,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: selected ? p.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          color: selected ? p.primary : p.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: GoogleFonts.spaceMono(
                            color: selected ? p.primary : p.textSecondary,
                            fontSize: 7,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationPanel(BuildContext context, dynamic p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NotificationPanel(palette: p),
    );
  }

  void _showUserPanel(BuildContext context, dynamic p, AuthService auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: p.primary.withValues(alpha: 0.3))),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: p.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          CircleAvatar(radius: 28,
            backgroundColor: p.primary.withValues(alpha: 0.15),
            child: Text(
              auth.currentUser?.displayName.isNotEmpty == true
                  ? auth.currentUser!.displayName[0].toUpperCase() : 'U',
              style: GoogleFonts.orbitron(color: p.primary, fontSize: 22, fontWeight: FontWeight.bold),
            )),
          const SizedBox(height: 10),
          Text(auth.currentUser?.displayName ?? 'User',
            style: GoogleFonts.orbitron(color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          Text(auth.currentUser?.email ?? '',
            style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _kycColor(auth.currentUser?.kycStatus ?? KycStatus.none).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kycColor(auth.currentUser?.kycStatus ?? KycStatus.none).withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.verified_user,
                color: _kycColor(auth.currentUser?.kycStatus ?? KycStatus.none), size: 12),
              const SizedBox(width: 4),
              Text('KYC: ${(auth.currentUser?.kycStatus.name ?? 'none').toUpperCase()}',
                style: GoogleFonts.orbitron(
                  color: _kycColor(auth.currentUser?.kycStatus ?? KycStatus.none), fontSize: 9)),
            ]),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.account_circle, color: p.primary),
            title: Text('Profil bearbeiten', style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 14)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.security, color: p.accent),
            title: Text('2FA Einstellungen', style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 14)),
            trailing: Switch(
              value: auth.currentUser?.twoFaEnabled ?? false,
              activeColor: p.accent,
              onChanged: (v) async {
                if (v) { await auth.enable2FA(); }
                else { await auth.disable2FA(); }
              },
            ),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.logout, color: p.negative),
            title: Text('Abmelden', style: GoogleFonts.rajdhani(color: p.negative, fontSize: 14)),
            onTap: () async {
              Navigator.pop(context);
              await auth.autoSave();
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()), (_) => false);
              }
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Color _kycColor(KycStatus s) {
    switch (s) {
      case KycStatus.verified: return const Color(0xFF00C853);
      case KycStatus.pending:  return const Color(0xFFFFAB00);
      case KycStatus.rejected: return const Color(0xFFD50000);
      default:                 return const Color(0xFF607D8B);
    }
  }
}

// ── Agent Status Indicator ─────────────────────────────────
class _AgentStatusIndicator extends StatelessWidget {
  final dynamic palette;
  const _AgentStatusIndicator({required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: p.positive.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: p.positive,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: p.positive.withValues(alpha: 0.6), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '6/6',
            style: GoogleFonts.spaceMono(
              color: p.positive,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

// ── Notification Panel ─────────────────────────────────────
class _NotificationPanel extends StatelessWidget {
  final dynamic palette;
  const _NotificationPanel({required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final notifications = [
      const _Notification(
        title: 'BTC Resonanz-Signal',
        body: 'Konstruktive Interferenz erkannt — 82% Konfidenz',
        icon: Icons.show_chart,
        isNew: true,
        type: 'SIGNAL',
      ),
      const _Notification(
        title: 'QEMMA Mining',
        body: '12.5 QEMMA verdient — Quest abgeschlossen',
        icon: Icons.memory_outlined,
        isNew: true,
        type: 'MINING',
      ),
      const _Notification(
        title: 'Portfolio Alert',
        body: 'ETH +5.2% — Teilgewinnmitnahme empfohlen',
        icon: Icons.pie_chart_outline,
        isNew: false,
        type: 'ALERT',
      ),
      const _Notification(
        title: 'System Status',
        body: 'HQMLL Meta-Agenten aktiv — Alle 6 Agenten online',
        icon: Icons.hub_outlined,
        isNew: false,
        type: 'SYS',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: p.primary.withValues(alpha: 0.2))),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(children: [
            Text(
              'BENACHRICHTIGUNGEN',
              style: GoogleFonts.spaceMono(
                color: p.textSecondary,
                fontSize: 10,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: p.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                '2 NEU',
                style: GoogleFonts.spaceMono(
                  color: p.primary,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          ...notifications.map((n) => _buildNotificationItem(n, p)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(_Notification n, dynamic p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: n.isNew
            ? p.primary.withValues(alpha: 0.05)
            : p.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: n.isNew
              ? p.primary.withValues(alpha: 0.2)
              : p.primary.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: p.primary.withValues(alpha: 0.2)),
            ),
            child: Icon(n.icon, color: p.primary, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      n.title,
                      style: GoogleFonts.spaceMono(
                        color: p.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: n.isNew
                          ? p.primary.withValues(alpha: 0.15)
                          : p.surfaceVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      n.type,
                      style: GoogleFonts.spaceMono(
                        color: n.isNew ? p.primary : p.textSecondary,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(
                  n.body,
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
    );
  }
}

class _Notification {
  final String title, body, type;
  final IconData icon;
  final bool isNew;
  const _Notification({
    required this.title,
    required this.body,
    required this.icon,
    required this.isNew,
    required this.type,
  });
}

// ═══════════════════════════════════════════════════════
// Live Ticker Banner
// ═══════════════════════════════════════════════════════
class _LiveTickerBanner extends StatefulWidget {
  final dynamic palette;
  const _LiveTickerBanner({required this.palette});
  @override
  State<_LiveTickerBanner> createState() => _LiveTickerBannerState();
}

class _LiveTickerBannerState extends State<_LiveTickerBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _scrollCtrl;
  late Timer _priceTimer;
  final Random _rng = Random();

  // v33.0: Fallback-Seed-Preise (werden sofort durch ExchangeService überschrieben)
  static const _fallbackPrices = <String, double>{
    'BTC': 67842.50, 'ETH': 3548.20, 'SOL': 182.40, 'BNB': 598.30,
    'ADA': 0.452, 'AVAX': 36.80, 'MATIC': 0.892, 'DOT': 7.92,
    'LINK': 14.62, 'XRP': 0.624, 'LTC': 84.30,
  };

  final List<_TickerItem> _items = [
    _TickerItem('BTC',  67842.50, 2.34),
    _TickerItem('ETH',  3548.20,  1.87),
    _TickerItem('QEMMA',0.0847,  12.45),
    _TickerItem('SOL',  182.40,  -0.52),
    _TickerItem('BNB',  598.30,   0.94),
    _TickerItem('ADA',  0.452,   -1.23),
    _TickerItem('AVAX', 36.80,    4.56),
    _TickerItem('MATIC',0.892,   -2.34),
    _TickerItem('DOT',  7.92,    -0.88),
    _TickerItem('LINK', 14.62,    2.11),
    _TickerItem('XRP',  0.624,    1.05),
    _TickerItem('LTC',  84.30,   -0.34),
  ];

  // v33.0: Sofort-Sync aus ExchangeService — überschreibt Fallback-Seed-Preise
  void _syncTickerFromExchange(ExchangeService ex) {
    for (final item in _items) {
      final tick = ex.getTick(item.symbol);
      if (tick != null && tick.price > 0) {
        item.price = tick.price;
        item.change = tick.change24h;
        item.isLive = tick.isLive;
      } else {
        final live = ex.getPrice(item.symbol);
        if (live > 0) item.price = live;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    // v33.0: Sofort beim ersten Frame live Preise laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final ex = Provider.of<ExchangeService>(context, listen: false);
        setState(() => _syncTickerFromExchange(ex));
      } catch (_) {}
    });
    _priceTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      // Pull live prices from ExchangeService
      try {
        final ex = Provider.of<ExchangeService>(context, listen: false);
        setState(() {
          for (final item in _items) {
            final tick = ex.getTick(item.symbol);
            if (tick != null) {
              final prevPrice = item.price;
              item.price = tick.price;
              item.change = tick.change24h;
              item.up = tick.price >= prevPrice;
              item.isLive = tick.isLive;
            } else {
              final delta = (_rng.nextDouble() - 0.5) * 0.4;
              item.price *= (1 + delta / 100);
              item.change += delta * 0.1;
              item.change = item.change.clamp(-15.0, 15.0);
              item.up = delta >= 0;
            }
          }
        });
      } catch (_) {
        // ExchangeService not yet available
        setState(() {
          for (final item in _items) {
            final delta = (_rng.nextDouble() - 0.5) * 0.4;
            item.price *= (1 + delta / 100);
            item.change += delta * 0.1;
            item.change = item.change.clamp(-15.0, 15.0);
            item.up = delta >= 0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _priceTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final ex = Provider.of<ExchangeService>(context);
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(
          bottom: BorderSide(color: p.primary.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(children: [
        // WS status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 5, height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ex.wsConnected ? const Color(0xFF00C853) : Colors.orange,
              ),
            ),
            const SizedBox(width: 4),
            Text(ex.wsConnected ? 'WS' : 'REST',
              style: GoogleFonts.orbitron(
                color: ex.wsConnected ? const Color(0xFF00C853) : Colors.orange,
                fontSize: 7, fontWeight: FontWeight.bold,
              )),
          ]),
        ),
        Container(width: 1, height: 14, color: p.primary.withValues(alpha: 0.15)),
        Expanded(
          child: AnimatedBuilder(
            animation: _scrollCtrl,
            builder: (_, __) {
              return ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  maxWidth: double.infinity,
                  child: Transform.translate(
                    offset: Offset(-_scrollCtrl.value * 1100, 0),
                    child: Row(
                      children: [
                        ..._items.map((item) => _buildTickerChip(item, p)),
                        ..._items.map((item) => _buildTickerChip(item, p)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildTickerChip(_TickerItem item, dynamic p) {
    final color = item.up ? p.positive : p.negative;
    final priceStr = item.price >= 1000
        ? '\$${item.price.toStringAsFixed(0)}'
        : item.price >= 1
            ? '\$${item.price.toStringAsFixed(2)}'
            : '\$${item.price.toStringAsFixed(4)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.symbol,
              style: GoogleFonts.spaceMono(
                  color: p.textSecondary, fontSize: 9,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          Text(priceStr,
              style: GoogleFonts.rajdhani(
                  color: p.textPrimary, fontSize: 11,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Icon(item.up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: color, size: 14),
          Text('${item.change >= 0 ? '+' : ''}${item.change.toStringAsFixed(2)}%',
              style: GoogleFonts.spaceMono(color: color, fontSize: 8)),
          // WS live indicator
          if (item.isLive)
            Container(
              width: 4, height: 4, margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(shape: BoxShape.circle, color: p.positive),
            ),
          Container(
            width: 1, height: 14, margin: const EdgeInsets.only(left: 12),
            color: p.primary.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }
}

class _TickerItem {
  final String symbol;
  double price;
  double change;
  bool up;
  bool isLive;
  _TickerItem(this.symbol, this.price, this.change) : up = change >= 0, isLive = false;
}
