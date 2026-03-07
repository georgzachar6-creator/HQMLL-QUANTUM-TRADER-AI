import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});
  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _alertFlashCtrl;
  late Timer _checkTimer;
  final Random _rnd = Random();

  int _tabIndex = 0; // 0=Aktive Alarme, 1=Signale, 2=Verlauf

  final List<_PriceAlert> _alerts = [
    _PriceAlert('BTC', 'Bitcoin', 70000, true, true, 67842.50),
    _PriceAlert('ETH', 'Ethereum', 3200, false, true, 3548.20),
    _PriceAlert('QEMMA', '\$QEMMA Token', 0.10, true, true, 0.0847),
    _PriceAlert('SOL', 'Solana', 170, false, false, 182.40),
    _PriceAlert('BNB', 'BNB', 600, true, false, 598.30),
  ];

  final List<_QuantumSignal> _signals = [
    _QuantumSignal('BTC/USDT', 'KAUFEN', 84, 'Konstruktive 17T-Resonanz', DateTime.now().subtract(const Duration(minutes: 3)), true),
    _QuantumSignal('ETH/USDT', 'KAUFEN', 79, 'RSI 58 · Merge-Effekt', DateTime.now().subtract(const Duration(minutes: 8)), true),
    _QuantumSignal('QEMMA/USDT', 'STARK KAUFEN', 92, 'Max Momentum · Mining-Boost', DateTime.now().subtract(const Duration(minutes: 12)), true),
    _QuantumSignal('SOL/USDT', 'HALTEN', 61, 'Destruktive Interferenz', DateTime.now().subtract(const Duration(minutes: 25)), false),
    _QuantumSignal('BNB/USDT', 'KAUFEN', 74, 'RSI 52 · Neutral-Bullisch', DateTime.now().subtract(const Duration(hours: 1)), true),
    _QuantumSignal('ADA/USDT', 'VERKAUFEN', 68, 'RSI Überkauft · Reversion', DateTime.now().subtract(const Duration(hours: 2)), false),
  ];

  final List<_AlertHistory> _history = [
    _AlertHistory('BTC > \$69.000', 'Getriggert', true, DateTime.now().subtract(const Duration(hours: 3))),
    _AlertHistory('ETH Quantum Signal', 'KAUFEN 82%', true, DateTime.now().subtract(const Duration(hours: 5))),
    _AlertHistory('QEMMA Mining Quest', '+25 QEMMA', true, DateTime.now().subtract(const Duration(hours: 8))),
    _AlertHistory('SOL < \$175', 'Getriggert', false, DateTime.now().subtract(const Duration(days: 1))),
    _AlertHistory('Portfolio Risiko', 'Score 6.5/10', false, DateTime.now().subtract(const Duration(days: 1, hours: 4))),
    _AlertHistory('BTC Resonanz-Peak', 'Konfidenz 88%', true, DateTime.now().subtract(const Duration(days: 2))),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _alertFlashCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    // Simuliere eingehende Signale
    _checkTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      _simulateNewSignal();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _alertFlashCtrl.dispose();
    _checkTimer.cancel();
    super.dispose();
  }

  void _simulateNewSignal() {
    final coins = ['BTC/USDT', 'ETH/USDT', 'QEMMA/USDT', 'SOL/USDT'];
    final types = ['KAUFEN', 'HALTEN', 'KAUFEN'];
    final desc = [
      'Quantum-Resonanz-Peak erkannt',
      'Agenten-Konsens 5/6 bullisch',
      'RSI-Divergenz Signal',
      'On-Chain Whale-Bewegung',
    ];
    if (_rnd.nextDouble() < 0.4) {
      setState(() {
        _signals.insert(0, _QuantumSignal(
          coins[_rnd.nextInt(coins.length)],
          types[_rnd.nextInt(types.length)],
          65 + _rnd.nextInt(28),
          desc[_rnd.nextInt(desc.length)],
          DateTime.now(),
          _rnd.nextBool(),
        ));
        if (_signals.length > 20) _signals.removeLast();
      });
      _alertFlashCtrl.forward(from: 0);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;

    return Column(
      children: [
        _buildHeader(p),
        _buildTabBar(p),
        Expanded(child: _buildContent(p)),
      ],
    );
  }

  Widget _buildHeader(dynamic p) {
    final activeCount = _alerts.where((a) => a.isActive).length;
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(bottom: BorderSide(color: p.primary.withValues(alpha: 0.15))),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: [p.primary, p.secondary]),
                boxShadow: [BoxShadow(
                  color: p.primary.withValues(alpha: 0.3 + _pulseCtrl.value * 0.2),
                  blurRadius: 12,
                )],
              ),
              child: Stack(
                children: [
                  Center(child: Icon(Icons.notifications_active, color: p.background, size: 22)),
                  if (activeCount > 0) Positioned(
                    right: 6, top: 6,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: p.negative,
                        shape: BoxShape.circle,
                        border: Border.all(color: p.background, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ALARM CENTER',
                      style: GoogleFonts.rajdhani(color: p.primary, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  Text('$activeCount aktive Alarme · ${_signals.length} Signale',
                      style: TextStyle(color: p.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            // Live-Indikator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: p.positive.withValues(alpha: 0.1 + _pulseCtrl.value * 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.positive.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: p.positive,
                        boxShadow: [BoxShadow(color: p.positive.withValues(alpha: 0.8), blurRadius: 5)])),
                const SizedBox(width: 5),
                Text('LIVE', style: GoogleFonts.rajdhani(color: p.positive, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(dynamic p) {
    final tabs = ['Meine Alarme', 'Emma Signale', 'Verlauf'];
    return Container(
      height: 42,
      color: p.surface,
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final sel = _tabIndex == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                    color: sel ? p.primary : Colors.transparent, width: 2)),
                ),
                child: Center(child: Text(e.value,
                    style: GoogleFonts.rajdhani(
                        color: sel ? p.primary : p.textSecondary,
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(dynamic p) {
    switch (_tabIndex) {
      case 0: return _buildAlertsTab(p);
      case 1: return _buildSignalsTab(p);
      case 2: return _buildHistoryTab(p);
      default: return _buildAlertsTab(p);
    }
  }

  // ── Alarme Tab ─────────────────────────────────
  Widget _buildAlertsTab(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Emma-Alarm-Vorschläge
        _buildEmmaAlarmSuggestion(p),
        const SizedBox(height: 14),
        // Alarms hinzufügen
        Row(children: [
          Icon(Icons.notification_add_outlined, color: p.primary, size: 15),
          const SizedBox(width: 6),
          Text('AKTIVE PREIS-ALARME', style: GoogleFonts.rajdhani(
              color: p.primary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const Spacer(),
          GestureDetector(
            onTap: () => _showAddAlarmDialog(context, p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.primary.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                Icon(Icons.add, color: p.primary, size: 14),
                const SizedBox(width: 4),
                Text('NEU', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        ..._alerts.map((a) => _buildAlertCard(p, a)),
      ],
    );
  }

  Widget _buildEmmaAlarmSuggestion(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 32, height: 32,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [p.primary, p.secondary])),
                child: Icon(Icons.remove_red_eye, color: p.background, size: 16)),
            const SizedBox(width: 10),
            Text('EMMA ALARM-VORSCHLÄGE', style: GoogleFonts.rajdhani(
                color: p.primary, fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          ...[
            ('BTC', 'Alarm bei \$64.000 (Support)', Icons.arrow_downward),
            ('QEMMA', 'Alarm bei \$0.12 (ATH-Ziel)', Icons.arrow_upward),
            ('ETH', 'Alarm bei \$3.800 (Resistance)', Icons.arrow_upward),
          ].map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: p.surfaceVariant, borderRadius: BorderRadius.circular(6)),
                child: Text(s.$1, style: GoogleFonts.rajdhani(color: p.primary, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Icon(s.$3, color: s.$3 == Icons.arrow_upward ? p.positive : p.negative, size: 14),
              const SizedBox(width: 4),
              Expanded(child: Text(s.$2, style: TextStyle(color: p.textSecondary, fontSize: 11))),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: p.surface,
                    content: Text('Alarm für ${s.$1} aktiviert!', style: TextStyle(color: p.textPrimary)),
                    duration: const Duration(seconds: 2),
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('+ Setzen', style: TextStyle(color: p.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildAlertCard(dynamic p, _PriceAlert alert) {
    final isTriggered = alert.isAbove
        ? alert.currentPrice >= alert.targetPrice
        : alert.currentPrice <= alert.targetPrice;
    final progress = (alert.currentPrice / alert.targetPrice).clamp(0.0, 1.5);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTriggered
            ? p.positive.withValues(alpha: 0.07)
            : p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isTriggered
                ? p.positive.withValues(alpha: 0.5)
                : p.primary.withValues(alpha: alert.isActive ? 0.2 : 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Coin Icon
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.primary.withValues(alpha: 0.12),
                  border: Border.all(color: p.primary.withValues(alpha: 0.3)),
                ),
                child: Center(child: Text(alert.symbol[0],
                    style: GoogleFonts.rajdhani(color: p.primary, fontSize: 16, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.symbol, style: GoogleFonts.rajdhani(
                        color: p.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(alert.name, style: TextStyle(color: p.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Aktiv-Toggle
                  GestureDetector(
                    onTap: () => setState(() => alert.isActive = !alert.isActive),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44, height: 24,
                      decoration: BoxDecoration(
                        color: alert.isActive ? p.positive : p.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: alert.isActive ? 22 : 2, right: alert.isActive ? 2 : 22, top: 2, bottom: 2),
                        child: Container(
                          decoration: BoxDecoration(
                            color: alert.isActive ? p.background : p.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _alerts.remove(alert)),
                child: Icon(Icons.close, color: p.textSecondary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Alarm-Ziel
          Row(children: [
            Icon(alert.isAbove ? Icons.arrow_upward : Icons.arrow_downward,
                color: alert.isAbove ? p.positive : p.negative, size: 14),
            const SizedBox(width: 4),
            Text('Alarm wenn ${alert.isAbove ? ">" : "<"}',
                style: TextStyle(color: p.textSecondary, fontSize: 11)),
            const SizedBox(width: 4),
            Text(alert.symbol == 'QEMMA'
                ? '\$${alert.targetPrice.toStringAsFixed(4)}'
                : '\$${alert.targetPrice.toStringAsFixed(2)}',
                style: GoogleFonts.rajdhani(
                    color: alert.isAbove ? p.positive : p.negative,
                    fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('Aktuell: ',
                style: TextStyle(color: p.textSecondary, fontSize: 11)),
            Text(alert.symbol == 'QEMMA'
                ? '\$${alert.currentPrice.toStringAsFixed(4)}'
                : '\$${alert.currentPrice.toStringAsFixed(2)}',
                style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          // Fortschritts-Leiste
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: p.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(
                  isTriggered ? p.positive : (progress > 0.85 ? p.secondary : p.primary)),
            ),
          ),
          if (isTriggered) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.check_circle, color: p.positive, size: 14),
              const SizedBox(width: 6),
              Text('ALARM AUSGELÖST!',
                  style: GoogleFonts.rajdhani(color: p.positive, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          ],
        ],
      ),
    );
  }

  // ── Signale Tab ────────────────────────────────
  Widget _buildSignalsTab(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Live-Status Banner
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.05 + _pulseCtrl.value * 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.primary.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: p.positive,
                      boxShadow: [BoxShadow(color: p.positive.withValues(alpha: 0.8), blurRadius: 6)])),
              const SizedBox(width: 10),
              Text('EMMA QUANTUM-SIGNALE LIVE',
                  style: GoogleFonts.rajdhani(color: p.primary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const Spacer(),
              Text('${_signals.length} Signale', style: TextStyle(color: p.textSecondary, fontSize: 11)),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        // Signal Cards
        ..._signals.map((s) => _buildSignalCard(p, s)),
      ],
    );
  }

  Widget _buildSignalCard(dynamic p, _QuantumSignal signal) {
    final isBuy = signal.type == 'KAUFEN' || signal.type == 'STARK KAUFEN';
    final isStrong = signal.type == 'STARK KAUFEN';
    final signalColor = isBuy ? p.positive : (signal.type == 'VERKAUFEN' ? p.negative : p.secondary);
    final elapsed = DateTime.now().difference(signal.time);
    final timeStr = elapsed.inMinutes < 60
        ? 'vor ${elapsed.inMinutes}min'
        : 'vor ${elapsed.inHours}h';

    return AnimatedBuilder(
      animation: _alertFlashCtrl,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: signalColor.withValues(
              alpha: elapsed.inMinutes < 2 ? 0.6 : 0.2)),
          boxShadow: elapsed.inMinutes < 2 ? [
            BoxShadow(color: signalColor.withValues(alpha: 0.2), blurRadius: 12),
          ] : [],
        ),
        child: Row(
          children: [
            // Signal-Typ Icon
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: signalColor.withValues(alpha: 0.12),
                border: Border.all(color: signalColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isBuy ? Icons.trending_up : (signal.type == 'VERKAUFEN'
                      ? Icons.trending_down : Icons.trending_flat),
                      color: signalColor, size: 18),
                  if (isStrong) Icon(Icons.star, color: signalColor, size: 8),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(signal.pair, style: GoogleFonts.rajdhani(
                        color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (elapsed.inMinutes < 5)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.positive.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('NEU', style: TextStyle(color: p.positive, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                  ]),
                  Text(signal.description, style: TextStyle(color: p.textSecondary, fontSize: 11)),
                  const SizedBox(height: 4),
                  // Konfidenz-Leiste
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: signal.confidence / 100.0,
                          minHeight: 3,
                          backgroundColor: p.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation(signalColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${signal.confidence}%', style: TextStyle(
                        color: signalColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: signalColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: signalColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(signal.type,
                      style: GoogleFonts.rajdhani(color: signalColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Text(timeStr, style: TextStyle(color: p.textSecondary, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Verlauf Tab ─────────────────────────────────
  Widget _buildHistoryTab(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(children: [
          Icon(Icons.history, color: p.primary, size: 15),
          const SizedBox(width: 6),
          Text('ALARM-VERLAUF', style: GoogleFonts.rajdhani(
              color: p.primary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 12),
        ..._history.map((h) => _buildHistoryItem(p, h)),
      ],
    );
  }

  Widget _buildHistoryItem(dynamic p, _AlertHistory h) {
    final elapsed = DateTime.now().difference(h.time);
    final timeStr = elapsed.inHours < 24 ? 'vor ${elapsed.inHours}h' : 'vor ${elapsed.inDays}T';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.1)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: h.isPositive ? p.positive.withValues(alpha: 0.12) : p.negative.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(h.isPositive ? Icons.notifications_active : Icons.notifications_off,
              color: h.isPositive ? p.positive : p.negative, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(h.title, style: TextStyle(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(h.detail, style: TextStyle(color: p.textSecondary, fontSize: 11)),
          ],
        )),
        Text(timeStr, style: TextStyle(color: p.textSecondary, fontSize: 10)),
      ]),
    );
  }

  void _showAddAlarmDialog(BuildContext context, dynamic p) {
    String selectedCoin = 'BTC';
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: p.primary.withValues(alpha: 0.4))),
        title: Row(children: [
          Icon(Icons.notification_add, color: p.primary, size: 20),
          const SizedBox(width: 8),
          Text('Neuer Preis-Alarm', style: TextStyle(color: p.textPrimary, fontSize: 16)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Coin Auswahl
            Row(children: [
              Text('Coin: ', style: TextStyle(color: p.textSecondary, fontSize: 12)),
              ...['BTC', 'ETH', 'SOL', 'QEMMA'].map((c) => GestureDetector(
                onTap: () => selectedCoin = c,
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: p.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(c, style: TextStyle(color: p.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              )),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Zielpreis eingeben...',
                hintStyle: TextStyle(color: p.textSecondary),
                filled: true, fillColor: p.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: p.primary)),
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: p.primary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Abbrechen', style: TextStyle(color: p.textSecondary))),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceCtrl.text) ?? 0;
              if (price > 0) {
                setState(() => _alerts.insert(0, _PriceAlert(
                    selectedCoin, selectedCoin, price, true, true, price * 0.97)));
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: p.primary, foregroundColor: p.background),
            child: Text('Alarm setzen', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Data Classes ─────────────────────────────────
class _PriceAlert {
  final String symbol, name;
  final double targetPrice;
  final bool isAbove;
  bool isActive;
  final double currentPrice;
  _PriceAlert(this.symbol, this.name, this.targetPrice, this.isAbove, this.isActive, this.currentPrice);
}

class _QuantumSignal {
  final String pair, type, description;
  final int confidence;
  final DateTime time;
  final bool isBullish;
  _QuantumSignal(this.pair, this.type, this.confidence, this.description, this.time, this.isBullish);
}

class _AlertHistory {
  final String title, detail;
  final bool isPositive;
  final DateTime time;
  _AlertHistory(this.title, this.detail, this.isPositive, this.time);
}
