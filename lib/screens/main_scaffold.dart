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
import 'news_screen.dart';

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
    _NavItem(icon: Icons.remove_red_eye_outlined, activeIcon: Icons.remove_red_eye, label: 'ORACLE'),
    _NavItem(icon: Icons.candlestick_chart_outlined, activeIcon: Icons.candlestick_chart, label: 'TRADING'),
    _NavItem(icon: Icons.bar_chart_rounded, activeIcon: Icons.bar_chart, label: 'MARKT'),
    _NavItem(icon: Icons.newspaper_outlined, activeIcon: Icons.newspaper_rounded, label: 'NEWS'),
    _NavItem(icon: Icons.pie_chart_outline, activeIcon: Icons.pie_chart, label: 'PORTFOLIO'),
    _NavItem(icon: Icons.token_outlined, activeIcon: Icons.token, label: 'QEMMA'),
    _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'WALLET'),
    _NavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: 'AI FORGE'),
    _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'ALARMS'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'SETTINGS'),
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
      const OracleScreen(),
      const TradingScreen(),
      const MarketScreen(),
      const NewsScreen(),
      const PortfolioScreen(),
      const TokenScreen(),
      const WalletScreen(),
      const AIForgeScreen(),
      const AlarmScreen(),
      const SettingsScreen(),
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
        body: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
        floatingActionButton: _buildFAB(p),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                      // Logo + Titel
                      QuantumEyeWidget(
                        palette: p,
                        size: 32,
                        animate: tp.quantumAnimations,
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

  Widget _buildFAB(dynamic p) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.primary.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: p.primary.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuantumMonitorScreen()),
          ),
          child: Icon(Icons.monitor_heart_outlined, color: p.primary, size: 20),
        ),
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
