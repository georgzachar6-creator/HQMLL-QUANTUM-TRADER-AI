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
import 'quantum_monitor_screen.dart';
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
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _priceTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        for (final item in _items) {
          final delta = (_rng.nextDouble() - 0.5) * 0.4;
          item.price *= (1 + delta / 100);
          item.change += delta * 0.1;
          item.change = item.change.clamp(-15.0, 15.0);
          item.up = delta >= 0;
        }
      });
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
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(
          bottom: BorderSide(color: p.primary.withValues(alpha: 0.15)),
        ),
      ),
      child: AnimatedBuilder(
        animation: _scrollCtrl,
        builder: (_, __) {
          return ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: double.infinity,
              child: Transform.translate(
                offset: Offset(-_scrollCtrl.value * 900, 0),
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
  _TickerItem(this.symbol, this.price, this.change) : up = change >= 0;
}
