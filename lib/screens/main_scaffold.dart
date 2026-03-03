import 'package:flutter/material.dart';
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

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.remove_red_eye_outlined, activeIcon: Icons.remove_red_eye, label: 'Oracle'),
    _NavItem(icon: Icons.candlestick_chart_outlined, activeIcon: Icons.candlestick_chart, label: 'Trading'),
    _NavItem(icon: Icons.pie_chart_outline, activeIcon: Icons.pie_chart, label: 'Portfolio'),
    _NavItem(icon: Icons.token_outlined, activeIcon: Icons.token, label: '\$QEMMA'),
    _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Wallet'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;

    final screens = [
      const OracleScreen(),
      const TradingScreen(),
      const PortfolioScreen(),
      const TokenScreen(),
      const WalletScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            QuantumEyeWidget(palette: p, size: 36, animate: tp.quantumAnimations),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HQMLL QUANTUM',
                  style: GoogleFonts.rajdhani(
                    color: p.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                  ),
                ),
                Text(
                  'Emma Oracle · G. Saks',
                  style: GoogleFonts.exo(
                    color: p.textSecondary,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (tp.godModeEnabled)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [p.primary, p.secondary]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'GOD MODE',
                style: GoogleFonts.rajdhani(
                  color: p.background,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: p.textSecondary, size: 22),
            onPressed: () => _showNotificationPanel(context, p),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: p.primary.withValues(alpha: 0.15),
        elevation: 0,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuantumMonitorScreen()),
        ),
        tooltip: 'Quantum Monitor',
        child: Icon(Icons.waves, color: p.primary, size: 20),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(top: BorderSide(color: p.primary.withValues(alpha: 0.15))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final selected = _selectedIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      color: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: selected ? 40 : 0,
                            height: 2,
                            decoration: BoxDecoration(
                              color: p.primary,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            selected ? item.activeIcon : item.icon,
                            color: selected ? p.primary : p.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: GoogleFonts.rajdhani(
                              color: selected ? p.primary : p.textSecondary,
                              fontSize: 10,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
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
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NotificationPanel(palette: p),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _NotificationPanel extends StatelessWidget {
  final dynamic palette;
  const _NotificationPanel({required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final notifications = [
      ('BTC Resonanz-Signal', 'Konstruktive Interferenz erkannt – 82% Konfidenz', Icons.show_chart, true),
      ('\$QEMMA Mining', '12.5 \$QEMMA verdient – Quest abgeschlossen', Icons.token, true),
      ('Portfolio Alert', 'ETH +5.2% – Emma empfiehlt Teilgewinnmitnahme', Icons.pie_chart, false),
      ('System', 'HQMLL Meta-Agenten aktiv – Alle 6 Agenten online', Icons.hub, false),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Icon(Icons.notifications, color: p.primary, size: 20),
            const SizedBox(width: 8),
            Text('Benachrichtigungen', style: TextStyle(color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          ...notifications.map((n) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(n.$3, color: p.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(n.$1, style: TextStyle(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    if (n.$4) ...[const SizedBox(width: 6), Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(4)),
                      child: Text('NEU', style: TextStyle(color: p.background, fontSize: 9, fontWeight: FontWeight.bold)),
                    )],
                  ]),
                  Text(n.$2, style: TextStyle(color: p.textSecondary, fontSize: 11)),
                ],
              )),
            ]),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
