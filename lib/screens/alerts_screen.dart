import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/crypto_icon.dart';
import '../providers/theme_provider.dart';
import '../services/exchange_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// PRICE ALERTS MANAGER SCREEN v2 (v28.0)
// Quantum Trader AI — ExchangeService Live Prices + Real Alert Triggering
// ════════════════════════════════════════════════════════════════════════════

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _bellAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _bellSwing;

  Timer? _priceTimer;
  final _rand = Random();

  // v28.0: Live prices sourced from ExchangeService (fallback to static)
  final Map<String, double> _prices = {
    'BTC': 67842.0,
    'ETH': 3548.0,
    'SOL': 185.4,
    'BNB': 620.0,
    'ADA': 0.485,
    'DOT': 7.2,
    'AVAX': 38.5,
    'LINK': 17.8,
    'MATIC': 0.892,
    'ATOM': 9.4,
  };

  // v28.0: newly triggered alerts (shown as notifications)
  final List<Map<String, dynamic>> _triggeredNow = [];

  // Alert list
  late List<_Alert> _alerts;

  // Alert history
  final List<_AlertEvent> _history = [
    const _AlertEvent('BTC', 'Preis > \$41.500', '2024-01-15 09:23', true, Colors.green),
    const _AlertEvent('ETH', 'Preis < \$2.600', '2024-01-14 22:41', true, Colors.red),
    const _AlertEvent('SOL', 'Preis > \$180', '2024-01-14 15:17', true, Colors.green),
    const _AlertEvent('BNB', '%Änderung > 5%', '2024-01-13 11:02', true, Color(0xFFF3BA2F)),
    const _AlertEvent('ADA', 'Preis < \$0.55', '2024-01-12 08:44', false, Colors.red),
    const _AlertEvent('BTC', 'RSI > 70 (Overbought)', '2024-01-11 16:30', true, Colors.orange),
    const _AlertEvent('LINK', 'Preis > \$18', '2024-01-10 13:15', true, Colors.blue),
    const _AlertEvent('DOT', '%Änderung < -8%', '2024-01-09 19:55', true, Colors.red),
  ];

  // Stats
  int _totalTriggered = 23;
  int _activeAlerts = 0;
  final double _accuracy = 87.3;

  bool _showCreateForm = false; // ignore: unused_field
  String _newSymbol = 'BTC';
  String _newCondition = 'Preis >';
  String _newValue = '';
  String _newChannel = 'Push';
  final bool _newEnabled = true; // ignore: unused_field

  final _conditionOptions = [
    'Preis >',
    'Preis <',
    '% Änderung >',
    '% Änderung <',
    'RSI >',
    'RSI <',
    'Vol. >',
    'MA Kreuzung',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _bellAnim = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseCtrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _bellSwing = Tween<double>(begin: -0.2, end: 0.2).animate(
      CurvedAnimation(parent: _bellAnim, curve: Curves.elasticIn),
    );

    _alerts = [
      _Alert('BTC', 'Preis >', 45000, 'Push', true, Colors.orange, (_prices['BTC'] ?? 0)),
      _Alert('BTC', 'Preis <', 38000, 'Email + Push', true, Colors.orange, (_prices['BTC'] ?? 0)),
      _Alert('ETH', 'Preis >', 3200, 'Push', true, const Color(0xFF627EEA), (_prices['ETH'] ?? 0)),
      _Alert('ETH', '% Änderung >', 10, 'Telegram', false, const Color(0xFF627EEA), (_prices['ETH'] ?? 0)),
      _Alert('SOL', 'Preis >', 200, 'Push', true, const Color(0xFF9945FF), (_prices['SOL'] ?? 0)),
      _Alert('SOL', 'RSI >', 75, 'Email', false, const Color(0xFF9945FF), (_prices['SOL'] ?? 0)),
      _Alert('BNB', 'MA Kreuzung', 420, 'Push', true, const Color(0xFFF3BA2F), (_prices['BNB'] ?? 0)),
      _Alert('ADA', 'Preis <', 0.50, 'Push', true, const Color(0xFF0033AD), (_prices['ADA'] ?? 0)),
      _Alert('AVAX', '% Änderung >', 15, 'Push + Email', false, const Color(0xFFE84142), (_prices['AVAX'] ?? 0)),
      _Alert('LINK', 'Preis >', 20, 'Push', true, const Color(0xFF2A5ADA), (_prices['LINK'] ?? 0)),
    ];
    _activeAlerts = _alerts.where((a) => a.enabled).length;

    // v28.0: Timer only for micro-simulation between ExchangeService refreshes
    _priceTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted) return;
      setState(() {
        // Micro drift around ExchangeService anchor
        for (final key in _prices.keys) {
          final change = (_rand.nextDouble() - 0.5) * 0.0008;
          _prices[key] = (_prices[key] ?? 0) * (1 + change);
        }
        _syncAlertsAndCheck();
      });
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _bellAnim.dispose();
    _pulseCtrl.dispose();
    _priceTimer?.cancel();
    super.dispose();
  }

  void _ringBell() {
    _bellAnim.forward(from: 0).then((_) => _bellAnim.reverse());
  }

  // v28.0: Sync prices from ExchangeService and check alert conditions
  void _syncPricesFromExchange(ExchangeService ex) {
    for (final sym in _prices.keys.toList()) {
      final live = ex.getPrice(sym);
      if (live > 0) _prices[sym] = live;
    }
    _syncAlertsAndCheck();
  }

  void _syncAlertsAndCheck() {
    for (var alert in _alerts) {
      final price = _prices[alert.symbol] ?? alert.currentPrice;
      final prevPrice = alert.currentPrice;
      alert.currentPrice = price;
      if (!alert.enabled) continue;
      // Check trigger conditions
      bool triggered = false;
      if (alert.condition == 'Preis >') triggered = price > alert.targetValue;
      if (alert.condition == 'Preis <') triggered = price < alert.targetValue;
      if (alert.condition == '% Änderung >') {
        final chg = ((price - prevPrice) / prevPrice) * 100;
        triggered = chg.abs() > alert.targetValue;
      }
      if (triggered && !alert.wasTriggered) {
        alert.wasTriggered = true;
        _totalTriggered++;
        _triggeredNow.add({
          'symbol': alert.symbol,
          'condition': '${alert.condition} ${alert.targetValue}',
          'price': price,
          'time': DateTime.now(),
        });
        if (_triggeredNow.length > 5) _triggeredNow.removeAt(0);
      } else if (!triggered) {
        alert.wasTriggered = false;
      }
    }
    _activeAlerts = _alerts.where((a) => a.enabled).length;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>();
    final pal = p.palette;
    // v28.0: ExchangeService live prices
    final ex = context.watch<ExchangeService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPricesFromExchange(ex);
    });

    return Scaffold(
      backgroundColor: pal.background,
      appBar: _buildAppBar(pal),
      body: Column(
        children: [
          _buildLivePriceBand(pal, ex),
          _buildStatsHeader(pal),
          _buildTabBar(pal),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildAlertsTab(pal),
                _buildCreateTab(pal),
                _buildHistoryTab(pal),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {
          _tabCtrl.animateTo(1);
          _showCreateForm = true;
        }),
        backgroundColor: const Color(0xFFFF0080),
        child: const Icon(Icons.add_alert, color: Colors.white),
      ),
    );
  }

  /// v28.0: Live price band showing ExchangeService prices
  Widget _buildLivePriceBand(dynamic pal, ExchangeService ex) {
    final syms = ['BTC', 'ETH', 'SOL', 'BNB', 'ADA', 'AVAX'];
    return Container(
      height: 30,
      color: pal.surface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: const Color(0xFFFF0080).withValues(alpha: 0.15),
            child: Text('LIVE', style: GoogleFonts.spaceMono(
              color: const Color(0xFFFF0080), fontSize: 7, fontWeight: FontWeight.bold,
            )),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: syms.map((sym) {
                  final p = ex.getPrice(sym);
                  final tick = ex.getTick(sym);
                  final chg = tick?.change24h ?? 0.0;
                  if (p <= 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(children: [
                      Text(sym, style: GoogleFonts.spaceMono(
                        color: pal.textSecondary, fontSize: 8, fontWeight: FontWeight.bold,
                      )),
                      const SizedBox(width: 4),
                      Text(
                        p >= 1000 ? '\$${p.toStringAsFixed(0)}' : '\$${p.toStringAsFixed(3)}',
                        style: GoogleFonts.spaceMono(color: pal.textPrimary, fontSize: 8),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${chg >= 0 ? '+' : ''}${chg.toStringAsFixed(1)}%',
                        style: GoogleFonts.spaceMono(
                          color: chg >= 0 ? const Color(0xFF00FF88) : const Color(0xFFFF3358),
                          fontSize: 7,
                        ),
                      ),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(dynamic pal) {
    return AppBar(
      backgroundColor: pal.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: pal.accent),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(
        children: [
          AnimatedBuilder(
            animation: _bellSwing,
            builder: (_, child) => Transform.rotate(
              angle: _bellSwing.value,
              child: child,
            ),
            child: GestureDetector(
              onTap: _ringBell,
              child: const Icon(Icons.notifications_active,
                  color: Color(0xFFFF0080), size: 26),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Price Alerts',
                  style: GoogleFonts.spaceMono(
                      color: pal.text, fontSize: 14, fontWeight: FontWeight.bold)),
              Text('ALARM SYSTEM v22.0',
                  style: GoogleFonts.spaceMono(
                      color: const Color(0xFFFF0080), fontSize: 9)),
            ],
          ),
        ],
      ),
      actions: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00C896)
                  .withValues(alpha: 0.1 + _pulseCtrl.value * 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF00C896)
                    .withValues(alpha: 0.3 + _pulseCtrl.value * 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00C896),
                  ),
                ),
                const SizedBox(width: 4),
                Text('LIVE',
                    style: GoogleFonts.spaceMono(
                        color: const Color(0xFF00C896),
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(dynamic pal) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF0080).withValues(alpha: 0.12),
            const Color(0xFFFF6B35).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF0080).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statPill(pal, Icons.notifications_active, '$_activeAlerts',
              'AKTIV', const Color(0xFFFF0080)),
          _divider(),
          _statPill(pal, Icons.check_circle_outline, '$_totalTriggered',
              'AUSGELÖST', const Color(0xFF00C896)),
          _divider(),
          _statPill(pal, Icons.precision_manufacturing, '${_accuracy.toStringAsFixed(0)}%',
              'GENAUIGKEIT', const Color(0xFF00D4FF)),
          _divider(),
          _statPill(pal, Icons.currency_bitcoin, '${(_prices['BTC'] ?? 0) < 42180 ? '▼' : '▲'}\$${((_prices['BTC'] ?? 0) / 1000).toStringAsFixed(1)}K',
              'BTC LIVE', Colors.orange),
        ],
      ),
    );
  }

  Widget _statPill(dynamic pal, IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.spaceMono(
                color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label,
            style: GoogleFonts.spaceMono(color: pal.textSecondary, fontSize: 7)),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: Colors.white.withValues(alpha: 0.1),
      );

  Widget _buildTabBar(dynamic pal) {
    return Container(
      color: pal.surface,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: const Color(0xFFFF0080),
        labelColor: const Color(0xFFFF0080),
        unselectedLabelColor: pal.textSecondary,
        labelStyle:
            GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'ALARMS'),
          Tab(text: 'ERSTELLEN'),
          Tab(text: 'VERLAUF'),
        ],
      ),
    );
  }

  // ── TAB 1: ALERTS LIST ────────────────────────────────────────────────────
  Widget _buildAlertsTab(dynamic pal) {
    // Group by symbol
    final Map<String, List<_Alert>> grouped = {};
    for (final a in _alerts) {
      grouped.putIfAbsent(a.symbol, () => []).add(a);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_alerts.length} ALARMS KONFIGURIERT',
                style: GoogleFonts.spaceMono(
                    color: pal.textSecondary, fontSize: 10)),
            TextButton.icon(
              onPressed: () => setState(() {
                for (final a in _alerts) {
                  a.enabled = true;
                }
                _activeAlerts = _alerts.length;
              }),
              icon: Icon(Icons.select_all, color: pal.accent, size: 14),
              label: Text('ALLE AN',
                  style: GoogleFonts.spaceMono(color: pal.accent, fontSize: 9)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...grouped.entries.map((e) => _buildSymbolGroup(pal, e.key, e.value)),
      ],
    );
  }

  Widget _buildSymbolGroup(dynamic pal, String symbol, List<_Alert> alerts) {
    final currentPrice = _prices[symbol] ?? 0;
    final color = alerts.first.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CryptoIcon(symbol, size: 36, showShadow: false),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(symbol,
                          style: GoogleFonts.spaceMono(
                              color: pal.text, fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      Text('${alerts.length} Alarms', style: GoogleFonts.spaceMono(color: pal.textSecondary, fontSize: 9)),
                    ],
                  ),
                ),
                Text('\$${currentPrice < 1 ? currentPrice.toStringAsFixed(3) : currentPrice.toStringAsFixed(currentPrice > 100 ? 0 : 2)}',
                    style: GoogleFonts.spaceMono(
                        color: color, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Alert rows
          ...alerts.map((a) => _buildAlertRow(pal, a, currentPrice)),
        ],
      ),
    );
  }

  Widget _buildAlertRow(dynamic pal, _Alert a, double currentPrice) {
    final isNear = _isNearTrigger(a, currentPrice);
    final condColor = a.enabled ? (isNear ? Colors.amber : a.color) : pal.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: pal.text.withValues(alpha: 0.06))),
        color: isNear && a.enabled
            ? Colors.amber.withValues(alpha: 0.05)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          // Condition icon
          Icon(
            _conditionIcon(a.condition),
            color: condColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${a.condition} ${_formatValue(a)}',
                        style: GoogleFonts.spaceMono(
                            color: a.enabled ? pal.text : pal.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    if (isNear && a.enabled) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('NAHE!',
                            style: GoogleFonts.spaceMono(
                                color: Colors.amber, fontSize: 7,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.notifications, color: pal.textSecondary, size: 10),
                    const SizedBox(width: 4),
                    Text(a.channel,
                        style: GoogleFonts.spaceMono(
                            color: pal.textSecondary, fontSize: 8)),
                    if (isNear && a.enabled) ...[
                      const SizedBox(width: 8),
                      Text(
                          'Abstand: ${_distancePct(a, currentPrice).toStringAsFixed(1)}%',
                          style: GoogleFonts.spaceMono(
                              color: Colors.amber, fontSize: 8)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Toggle
          Switch(
            value: a.enabled,
            activeThumbColor: a.color,
            onChanged: (v) => setState(() {
              a.enabled = v;
              _activeAlerts = _alerts.where((al) => al.enabled).length;
            }),
          ),
          // Delete
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.withValues(alpha: 0.5), size: 18),
            onPressed: () => setState(() {
              _alerts.remove(a);
              _activeAlerts = _alerts.where((al) => al.enabled).length;
            }),
          ),
        ],
      ),
    );
  }

  bool _isNearTrigger(_Alert a, double currentPrice) {
    final pct = _distancePct(a, currentPrice).abs();
    return pct < 3.0 && a.condition.startsWith('Preis');
  }

  double _distancePct(_Alert a, double currentPrice) {
    if (currentPrice == 0) return 100.0;
    return ((a.targetValue - currentPrice) / currentPrice * 100);
  }

  String _formatValue(_Alert a) {
    if (a.symbol == 'ADA' || a.symbol == 'MATIC') {
      return '\$${a.targetValue.toStringAsFixed(3)}';
    }
    if (a.condition.contains('%')) return '${a.targetValue.toStringAsFixed(0)}%';
    if (a.condition.contains('RSI')) return a.targetValue.toStringAsFixed(0);
    if (a.targetValue > 1000) return '\$${(a.targetValue / 1000).toStringAsFixed(1)}K';
    return '\$${a.targetValue.toStringAsFixed(a.targetValue < 10 ? 2 : 0)}';
  }

  IconData _conditionIcon(String condition) {
    if (condition.contains('>')) return Icons.arrow_upward;
    if (condition.contains('<')) return Icons.arrow_downward;
    if (condition.contains('RSI')) return Icons.show_chart;
    if (condition.contains('MA')) return Icons.swap_horiz;
    return Icons.notifications;
  }

  // ── TAB 2: CREATE ALERT ───────────────────────────────────────────────────
  Widget _buildCreateTab(dynamic pal) {
    final symbols = _prices.keys.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF0080).withValues(alpha: 0.15),
                  const Color(0xFFFF6B35).withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_alert, color: Color(0xFFFF0080), size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NEUEN ALARM ERSTELLEN',
                        style: GoogleFonts.spaceMono(
                            color: pal.text, fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    Text('Wähle Asset, Bedingung und Zielwert',
                        style: GoogleFonts.spaceMono(
                            color: pal.textSecondary, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Asset selector
          Text('ASSET',
              style: GoogleFonts.spaceMono(
                  color: pal.textSecondary, fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: symbols.map((s) {
              final selected = _newSymbol == s;
              return GestureDetector(
                onTap: () => setState(() => _newSymbol = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFF0080).withValues(alpha: 0.2)
                        : pal.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFF0080)
                          : pal.text.withValues(alpha: 0.15),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(s,
                          style: GoogleFonts.spaceMono(
                              color: selected ? const Color(0xFFFF0080) : pal.text,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      Text(
                          '\$${(_prices[s] ?? 0) > 1000 ? '${((_prices[s] ?? 0) / 1000).toStringAsFixed(1)}K' : (_prices[s] ?? 0).toStringAsFixed(2)}',
                          style: GoogleFonts.spaceMono(
                              color: pal.textSecondary, fontSize: 8)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Condition selector
          Text('BEDINGUNG',
              style: GoogleFonts.spaceMono(
                  color: pal.textSecondary, fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _conditionOptions.map((c) {
              final selected = _newCondition == c;
              return GestureDetector(
                onTap: () => setState(() => _newCondition = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF00D4FF).withValues(alpha: 0.15)
                        : pal.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF00D4FF)
                          : pal.text.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(c,
                      style: GoogleFonts.spaceMono(
                          color: selected
                              ? const Color(0xFF00D4FF)
                              : pal.text,
                          fontSize: 9,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Value input
          Text('ZIELWERT',
              style: GoogleFonts.spaceMono(
                  color: pal.textSecondary, fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: pal.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFF0080).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _newCondition.contains('%') ? '%' : '\$',
                    style: GoogleFonts.spaceMono(
                        color: const Color(0xFFFF0080),
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: TextField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.spaceMono(
                        color: pal.text, fontSize: 18,
                        fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: (_prices[_newSymbol] ?? 0).toStringAsFixed(0),
                      hintStyle: GoogleFonts.spaceMono(
                          color: pal.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (v) => _newValue = v,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Notification channel
          Text('BENACHRICHTIGUNG',
              style: GoogleFonts.spaceMono(
                  color: pal.textSecondary, fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Push', 'Email', 'Telegram', 'Push + Email'].map((ch) {
              final selected = _newChannel == ch;
              return ChoiceChip(
                label: Text(ch,
                    style: GoogleFonts.spaceMono(
                        color: selected ? Colors.black : pal.text,
                        fontSize: 9)),
                selected: selected,
                selectedColor: const Color(0xFFFF0080),
                backgroundColor: pal.surface,
                onSelected: (_) => setState(() => _newChannel = ch),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Create button
          GestureDetector(
            onTap: _createAlert,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF0080), Color(0xFFFF6B35)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF0080).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_alert, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('ALARM ERSTELLEN',
                        style: GoogleFonts.spaceMono(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          _buildQuickAlerts(pal),
        ],
      ),
    );
  }

  Widget _buildQuickAlerts(dynamic pal) {
    final quickAlerts = [
      ('BTC > \$50K', 'BTC', 'Preis >', 50000.0, Colors.orange),
      ('ETH > \$3.5K', 'ETH', 'Preis >', 3500.0, const Color(0xFF627EEA)),
      ('BTC < \$35K', 'BTC', 'Preis <', 35000.0, Colors.orange),
      ('SOL > \$250', 'SOL', 'Preis >', 250.0, const Color(0xFF9945FF)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SCHNELL-ALARMS',
            style: GoogleFonts.spaceMono(
                color: pal.textSecondary, fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: quickAlerts.map((qa) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _alerts.add(_Alert(
                    qa.$2, qa.$3, qa.$4, 'Push', true, qa.$5,
                    (_prices[qa.$2] ?? 0),
                  ));
                  _activeAlerts = _alerts.where((a) => a.enabled).length;
                  _tabCtrl.animateTo(0);
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('✅ ${qa.$1} Alarm hinzugefügt',
                      style: GoogleFonts.spaceMono()),
                  backgroundColor: qa.$5,
                  duration: const Duration(seconds: 2),
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: qa.$5.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: qa.$5.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flash_on, color: qa.$5, size: 14),
                    const SizedBox(width: 4),
                    Text(qa.$1,
                        style: GoogleFonts.spaceMono(
                            color: pal.text, fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _createAlert() {
    if (_newValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bitte Zielwert eingeben!', style: GoogleFonts.spaceMono()),
        backgroundColor: Colors.red,
      ));
      return;
    }
    final value = double.tryParse(_newValue);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ungültiger Wert!', style: GoogleFonts.spaceMono()),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final colorMap = {
      'BTC': Colors.orange,
      'ETH': const Color(0xFF627EEA),
      'SOL': const Color(0xFF9945FF),
      'BNB': const Color(0xFFF3BA2F),
      'ADA': const Color(0xFF0033AD),
      'DOT': const Color(0xFFE6007A),
      'AVAX': const Color(0xFFE84142),
      'LINK': const Color(0xFF2A5ADA),
      'MATIC': const Color(0xFF8247E5),
      'ATOM': const Color(0xFF6F4E7C),
    };

    setState(() {
      _alerts.add(_Alert(
        _newSymbol,
        _newCondition,
        value,
        _newChannel,
        true,
        colorMap[_newSymbol] ?? const Color(0xFF00D4FF),
        (_prices[_newSymbol] ?? 0),
      ));
      _activeAlerts = _alerts.where((a) => a.enabled).length;
      _newValue = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '🔔 Alarm erstellt: $_newSymbol $_newCondition \$$value',
          style: GoogleFonts.spaceMono()),
      backgroundColor: const Color(0xFF00C896),
    ));

    _tabCtrl.animateTo(0);
    _ringBell();
  }

  // ── TAB 3: HISTORY ────────────────────────────────────────────────────────
  Widget _buildHistoryTab(dynamic pal) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Stats row
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pal.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('23',
                        style: GoogleFonts.spaceMono(
                            color: const Color(0xFF00C896),
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    Text('Ausgelöst (30d)',
                        style: GoogleFonts.spaceMono(
                            color: pal.textSecondary, fontSize: 8)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pal.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('87.3%',
                        style: GoogleFonts.spaceMono(
                            color: const Color(0xFF00D4FF),
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    Text('Trefferquote',
                        style: GoogleFonts.spaceMono(
                            color: pal.textSecondary, fontSize: 8)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pal.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('+\$4.2K',
                        style: GoogleFonts.spaceMono(
                            color: const Color(0xFFFFD700),
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    Text('Profit dank Alarms',
                        style: GoogleFonts.spaceMono(
                            color: pal.textSecondary, fontSize: 8)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('ALARM VERLAUF',
            style: GoogleFonts.spaceMono(
                color: pal.textSecondary, fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: pal.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: _history
                .asMap()
                .entries
                .map((e) => _buildHistoryRow(pal, e.value, e.key))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        _buildWeeklyChart(pal),
      ],
    );
  }

  Widget _buildHistoryRow(dynamic pal, _AlertEvent ev, int idx) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: idx < _history.length - 1
                  ? pal.text.withValues(alpha: 0.06)
                  : Colors.transparent),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ev.color.withValues(alpha: 0.15),
            ),
            child: Center(
              child: Icon(Icons.notifications_active, color: ev.color, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(ev.symbol,
                        style: GoogleFonts.spaceMono(
                            color: ev.color, fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(ev.condition,
                          style: GoogleFonts.spaceMono(
                              color: pal.text, fontSize: 10)),
                    ),
                  ],
                ),
                Text(ev.time,
                    style: GoogleFonts.spaceMono(
                        color: pal.textSecondary, fontSize: 8)),
              ],
            ),
          ),
          Icon(
            ev.triggered ? Icons.check_circle : Icons.cancel_outlined,
            color: ev.triggered ? const Color(0xFF00C896) : Colors.red,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(dynamic pal) {
    final dailyTriggers = [2, 4, 1, 5, 3, 6, 2];
    final maxVal = dailyTriggers.reduce(max).toDouble();
    final days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ALARM AKTIVITÄT (LETZTE WOCHE)',
              style: GoogleFonts.spaceMono(
                  color: pal.text, fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final h = (dailyTriggers[i] / maxVal * 80).clamp(10.0, 80.0);
              return Column(
                children: [
                  Container(
                    width: 32,
                    height: h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF0080),
                          Color(0xFFFF6B35),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${dailyTriggers[i]}',
                      style: GoogleFonts.spaceMono(
                          color: const Color(0xFFFF0080),
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                  Text(days[i],
                      style: GoogleFonts.spaceMono(
                          color: pal.textSecondary, fontSize: 8)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── DATA MODELS ──────────────────────────────────────────────────────────────

class _Alert {
  final String symbol;
  final String condition;
  final double targetValue;
  final String channel;
  bool enabled;
  final Color color;
  double currentPrice;
  bool wasTriggered = false; // v28.0: real trigger state tracking

  _Alert(this.symbol, this.condition, this.targetValue, this.channel,
      this.enabled, this.color, this.currentPrice);
}

class _AlertEvent {
  final String symbol;
  final String condition;
  final String time;
  final bool triggered;
  final Color color;

  const _AlertEvent(this.symbol, this.condition, this.time, this.triggered, this.color);
}
