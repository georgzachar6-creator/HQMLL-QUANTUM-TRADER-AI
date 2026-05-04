// ============================================================
// ALARM SCREEN v2 – Quantum Smart Alert System
// AI Conditions, Price Alerts, Portfolio Triggers, Notifications
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});
  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _ringCtrl;
  Timer? _liveTimer;
  final _rand = Random();

  int _selectedTab = 0;
  final List<String> _tabs = ['ACTIVE', 'AI ALERTS', 'HISTORY', 'CREATE', 'SETTINGS'];

  // Active Alarms
  final List<Map<String, dynamic>> _activeAlarms = [
    {'id': 1, 'pair': 'BTC/USDT', 'type': 'PRICE_ABOVE', 'value': 70000.0, 'current': 67840.0, 'progress': 0.969, 'active': true, 'sound': true, 'notify': true, 'priority': 'HIGH', 'triggered': false, 'timeAgo': ''},
    {'id': 2, 'pair': 'ETH/USDT', 'type': 'PRICE_BELOW', 'value': 3200.0, 'current': 3412.0, 'progress': 0.937, 'active': true, 'sound': true, 'notify': true, 'priority': 'MEDIUM', 'triggered': false, 'timeAgo': ''},
    {'id': 3, 'pair': 'SOL/USDT', 'type': 'RSI_ABOVE', 'value': 75.0, 'current': 71.3, 'progress': 0.951, 'active': true, 'sound': false, 'notify': true, 'priority': 'LOW', 'triggered': false, 'timeAgo': ''},
    {'id': 4, 'pair': 'BNB/USDT', 'type': 'VOLUME_SPIKE', 'value': 300.0, 'current': 218.0, 'progress': 0.727, 'active': true, 'sound': true, 'notify': true, 'priority': 'HIGH', 'triggered': false, 'timeAgo': ''},
    {'id': 5, 'pair': 'PORTFOLIO', 'type': 'PNL_TARGET', 'value': 5.0, 'current': 2.87, 'progress': 0.574, 'active': true, 'sound': true, 'notify': true, 'priority': 'HIGH', 'triggered': false, 'timeAgo': ''},
    {'id': 6, 'pair': 'AVAX/USDT', 'type': 'PRICE_ABOVE', 'value': 50.0, 'current': 42.3, 'progress': 0.846, 'active': false, 'sound': false, 'notify': false, 'priority': 'LOW', 'triggered': false, 'timeAgo': ''},
  ];

  // AI Alerts (smart conditions)
  final List<Map<String, dynamic>> _aiAlerts = [
    {
      'name': 'Whale Activity Detector',
      'desc': 'Alert when wallet >1000 BTC moves to exchange',
      'active': true,
      'confidence': 91.4,
      'triggered_count': 3,
      'model': 'NEXUS-3',
      'color': 0xFF00C8F5,
    },
    {
      'name': 'Liquidation Cascade Risk',
      'desc': 'Alert when futures funding rate exceeds 0.1%/8h',
      'active': true,
      'confidence': 87.2,
      'triggered_count': 1,
      'model': 'TR2-X',
      'color': 0xFFFF4444,
    },
    {
      'name': 'Bull Run Pattern',
      'desc': 'QEMMA pattern match: historic pre-ATH structure detected',
      'active': false,
      'confidence': 78.9,
      'triggered_count': 0,
      'model': 'QEMMA-7',
      'color': 0xFF00F0C0,
    },
    {
      'name': 'Market Reversal Signal',
      'desc': 'Multiple timeframe confluence: RSI divergence + volume drop',
      'active': true,
      'confidence': 83.7,
      'triggered_count': 5,
      'model': 'ORACLE-9',
      'color': 0xFFFFAA00,
    },
    {
      'name': 'Stablecoin Inflow Alert',
      'desc': 'Large USDT/USDC inflow detected on exchange wallets',
      'active': true,
      'confidence': 94.1,
      'triggered_count': 2,
      'model': 'NEXUS-3',
      'color': 0xFF9B59B6,
    },
  ];

  // History
  final List<Map<String, dynamic>> _history = [
    {'pair': 'BTC/USDT', 'type': 'PRICE_ABOVE', 'value': 68000.0, 'time': '1h ago', 'action': 'NOTIFIED', 'result': '+2.4%'},
    {'pair': 'ETH/USDT', 'type': 'RSI_ABOVE', 'value': 70.0, 'time': '3h ago', 'action': 'NOTIFIED', 'result': '-1.2%'},
    {'pair': 'SOL/USDT', 'type': 'VOLUME_SPIKE', 'value': 250.0, 'time': '5h ago', 'action': 'TRADED', 'result': '+4.7%'},
    {'pair': 'MATIC/USDT', 'type': 'PRICE_BELOW', 'value': 0.9, 'time': '8h ago', 'action': 'NOTIFIED', 'result': '+1.1%'},
    {'pair': 'BNB/USDT', 'type': 'PRICE_ABOVE', 'value': 600.0, 'time': '12h ago', 'action': 'MISSED', 'result': '+3.2%'},
    {'pair': 'AVAX/USDT', 'type': 'AI_ALERT', 'value': 0, 'time': '1d ago', 'action': 'TRADED', 'result': '+8.4%'},
  ];

  // Notification settings
  bool _soundEnabled = true;
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _telegramEnabled = true;
  bool _vibrationEnabled = true;
  int _cooldown = 5;

  // Stats
  int _totalAlerts = 247;
  int _triggeredToday = 12;
  double _accuracyRate = 74.3;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _liveTimer = Timer.periodic(const Duration(seconds: 2), (_) => _updateLive());
  }

  void _updateLive() {
    if (!mounted) return;
    setState(() {
      _triggeredToday += _rand.nextInt(2);
      _totalAlerts += _rand.nextInt(3);
      _accuracyRate = 70.0 + _rand.nextDouble() * 10.0;
      // Animate progress bars
      for (var a in _activeAlarms) {
        if (a['active'] == true && a['triggered'] == false) {
          a['progress'] = ((a['progress'] as double) + (_rand.nextDouble() - 0.49) * 0.005)
              .clamp(0.0, 1.0);
        }
      }
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _ringCtrl.dispose();
    _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(p),
            _buildTabBar(p),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildTabContent(p),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(QuantumPalette p) {
    final triggered = _activeAlarms.where((a) => (a['progress'] as double) > 0.98 && a['active'] == true).length;
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            p.background,
            triggered > 0 ? p.negative.withValues(alpha: 0.08) : p.background,
          ]),
          border: Border(bottom: BorderSide(
            color: (triggered > 0 ? p.negative : p.primary).withValues(alpha: 0.3 + _glowCtrl.value * 0.2),
          )),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _ringCtrl,
              builder: (_, __) => Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: triggered > 0
                      ? p.negative.withValues(alpha: 0.15 + _ringCtrl.value * 0.1)
                      : p.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: (triggered > 0 ? p.negative : p.primary).withValues(
                      alpha: 0.5 + _glowCtrl.value * 0.3,
                    ),
                  ),
                ),
                child: Icon(
                  triggered > 0 ? Icons.notifications_active : Icons.notifications,
                  color: triggered > 0 ? p.negative : p.primary, size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SMART ALARMS', style: GoogleFonts.orbitron(
                  color: p.primary, fontSize: 16, fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: p.primary.withValues(alpha: 0.5), blurRadius: 8)],
                )),
                Text('AI Conditions · Price · Volume · AI Events', style: GoogleFonts.rajdhani(
                  color: p.textSecondary, fontSize: 11,
                )),
              ],
            )),
            _buildHeaderBadge(p, 'ACTIVE', '${_activeAlarms.where((a) => a['active'] == true).length}', p.positive),
            const SizedBox(width: 8),
            _buildHeaderBadge(p, 'TODAY', '$_triggeredToday', p.negative),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(QuantumPalette p, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
      ]),
    );
  }

  Widget _buildTabBar(QuantumPalette p) {
    return Container(
      height: 40,
      color: p.surface.withValues(alpha: 0.4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _tabs.length,
        itemBuilder: (_, i) {
          final sel = i == _selectedTab;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: sel ? p.primary.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: sel ? p.primary : Colors.transparent),
              ),
              child: Center(child: Text(_tabs[i], style: GoogleFonts.orbitron(
                color: sel ? p.primary : p.textSecondary,
                fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              ))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent(QuantumPalette p) {
    switch (_selectedTab) {
      case 0: return _buildActiveTab(p);
      case 1: return _buildAIAlertsTab(p);
      case 2: return _buildHistoryTab(p);
      case 3: return _buildCreateTab(p);
      case 4: return _buildSettingsTab(p);
      default: return _buildActiveTab(p);
    }
  }

  // ── ACTIVE TAB ──
  Widget _buildActiveTab(QuantumPalette p) {
    return ListView(
      key: const ValueKey('active'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildAlarmSummaryRow(p),
        const SizedBox(height: 12),
        ..._activeAlarms.map((a) => _buildAlarmCard(p, a)),
      ],
    );
  }

  Widget _buildAlarmSummaryRow(QuantumPalette p) {
    return Row(children: [
      Expanded(child: _buildSumCard(p, 'TOTAL ALARMS', '$_totalAlerts', p.primary, Icons.notifications)),
      const SizedBox(width: 8),
      Expanded(child: _buildSumCard(p, 'TRIGGERED TODAY', '$_triggeredToday', p.negative, Icons.alarm_on)),
      const SizedBox(width: 8),
      Expanded(child: _buildSumCard(p, 'ACCURACY', '${_accuracyRate.toStringAsFixed(0)}%', p.positive, Icons.gps_fixed)),
    ]);
  }

  Widget _buildSumCard(QuantumPalette p, String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
      ]),
    );
  }

  Widget _buildAlarmCard(QuantumPalette p, Map<String, dynamic> a) {
    final isActive = a['active'] as bool;
    final progress = (a['progress'] as double).clamp(0.0, 1.0);
    final isNear = progress > 0.95;
    final priorityColors = {'HIGH': p.negative, 'MEDIUM': p.accent, 'LOW': p.textSecondary};
    final priorityColor = priorityColors[a['priority']] ?? p.textSecondary;
    final typeLabels = {
      'PRICE_ABOVE': 'Price rises above',
      'PRICE_BELOW': 'Price falls below',
      'RSI_ABOVE': 'RSI rises above',
      'VOLUME_SPIKE': 'Volume spikes by',
      'PNL_TARGET': 'Portfolio P&L reaches',
    };
    final typeLabel = typeLabels[a['type']] ?? a['type'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNear && isActive ? p.negative.withValues(alpha: 0.6) : priorityColor.withValues(alpha: 0.25),
          width: isNear && isActive ? 1.5 : 1.0,
        ),
        boxShadow: isNear && isActive
            ? [BoxShadow(color: p.negative.withValues(alpha: 0.15), blurRadius: 12)]
            : [],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _ringCtrl,
                  builder: (_, __) => Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isNear && isActive
                          ? p.negative.withValues(alpha: 0.15 + _ringCtrl.value * 0.1)
                          : priorityColor.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      isNear && isActive ? Icons.notification_important : Icons.notifications_outlined,
                      color: isNear && isActive ? p.negative : priorityColor, size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['pair'], style: GoogleFonts.orbitron(
                      color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold,
                    )),
                    Text(typeLabel, style: GoogleFonts.rajdhani(
                      color: p.textSecondary, fontSize: 10,
                    )),
                  ],
                )),
                // Priority badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(a['priority'], style: GoogleFonts.rajdhani(
                    color: priorityColor, fontSize: 9, fontWeight: FontWeight.bold,
                  )),
                ),
                const SizedBox(width: 8),
                // Toggle
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => a['active'] = !(a['active'] as bool));
                  },
                  child: Container(
                    width: 38, height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isActive ? p.positive.withValues(alpha: 0.3) : p.surface,
                      border: Border.all(
                        color: isActive ? p.positive.withValues(alpha: 0.6) : p.textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 14, height: 14,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? p.positive : p.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Progress
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              children: [
                Row(children: [
                  Text('Target: ', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
                  Text(_formatAlarmValue(a), style: GoogleFonts.orbitron(
                    color: isNear ? p.negative : p.primary, fontSize: 11, fontWeight: FontWeight.bold,
                  )),
                  const Spacer(),
                  Text('Current: ${_formatCurrentValue(a)}', style: GoogleFonts.rajdhani(
                    color: p.textSecondary, fontSize: 10,
                  )),
                  const SizedBox(width: 8),
                  Text('${(progress * 100).toInt()}%', style: GoogleFonts.orbitron(
                    color: isNear ? p.negative : p.positive, fontSize: 10, fontWeight: FontWeight.bold,
                  )),
                ]),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: isActive ? progress : 0,
                    backgroundColor: p.surface,
                    valueColor: AlwaysStoppedAnimation(
                      isNear ? p.negative : progress > 0.7 ? p.accent : p.positive,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  if (a['sound'] == true) _buildAlarmFlag(p, Icons.volume_up, 'SOUND', p.primary),
                  if (a['sound'] == true) const SizedBox(width: 8),
                  if (a['notify'] == true) _buildAlarmFlag(p, Icons.notifications, 'PUSH', p.accent),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _activeAlarms.remove(a)),
                    child: Icon(Icons.delete_outline, color: p.negative.withValues(alpha: 0.6), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_outlined, color: p.textSecondary, size: 16),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmFlag(QuantumPalette p, IconData icon, String label, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 12),
      const SizedBox(width: 3),
      Text(label, style: GoogleFonts.rajdhani(color: color, fontSize: 9)),
    ]);
  }

  String _formatAlarmValue(Map<String, dynamic> a) {
    final type = a['type'] as String;
    final value = a['value'];
    if (type.contains('PRICE')) return '\$${value.toStringAsFixed(value < 100 ? 3 : 0)}';
    if (type.contains('RSI')) return '${value.toStringAsFixed(0)} RSI';
    if (type.contains('VOLUME')) return '+${value.toStringAsFixed(0)}%';
    if (type.contains('PNL')) return '+${value.toStringAsFixed(1)}%';
    return value.toString();
  }

  String _formatCurrentValue(Map<String, dynamic> a) {
    final type = a['type'] as String;
    final current = a['current'];
    if (type.contains('PRICE')) return '\$${current.toStringAsFixed(current < 100 ? 3 : 0)}';
    if (type.contains('RSI')) return '${current.toStringAsFixed(1)} RSI';
    if (type.contains('VOLUME')) return '+${current.toStringAsFixed(0)}%';
    if (type.contains('PNL')) return '+${current.toStringAsFixed(2)}%';
    return current.toString();
  }

  // ── AI ALERTS TAB ──
  Widget _buildAIAlertsTab(QuantumPalette p) {
    return ListView(
      key: const ValueKey('aialerts'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildAIAlertHeader(p),
        const SizedBox(height: 12),
        ..._aiAlerts.map((a) => _buildAIAlertCard(p, a)),
      ],
    );
  }

  Widget _buildAIAlertHeader(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          p.primary.withValues(alpha: 0.1),
          p.accent.withValues(alpha: 0.05),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.auto_awesome, color: p.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI SMART ALERTS', style: GoogleFonts.orbitron(
              color: p.primary, fontSize: 12, fontWeight: FontWeight.bold,
            )),
            Text('Powered by QEMMA, NEXUS, TR2, ORACLE models',
              style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${_aiAlerts.where((a) => a['active'] == true).length}/${_aiAlerts.length}', style: GoogleFonts.orbitron(
            color: p.positive, fontSize: 14, fontWeight: FontWeight.bold,
          )),
          Text('ACTIVE', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
        ]),
      ]),
    );
  }

  Widget _buildAIAlertCard(QuantumPalette p, Map<String, dynamic> a) {
    final color = Color(a['color'] as int);
    final isActive = a['active'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: isActive ? 0.35 : 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.psychology, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['name'], style: GoogleFonts.rajdhani(
                  color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold,
                )),
                Text('Model: ${a['model']} · ${a['triggered_count']} triggered',
                  style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
              ],
            )),
            GestureDetector(
              onTap: () => setState(() => a['active'] = !isActive),
              child: Container(
                width: 38, height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isActive ? color.withValues(alpha: 0.3) : p.surface,
                  border: Border.all(
                    color: isActive ? color.withValues(alpha: 0.6) : p.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 14, height: 14,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? color : p.textSecondary),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text(a['desc'], style: GoogleFonts.rajdhani(
            color: p.textSecondary, fontSize: 11, height: 1.4,
          )),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.analytics, color: color, size: 12),
            const SizedBox(width: 4),
            Text('AI Confidence: ${(a['confidence'] as double).toStringAsFixed(1)}%',
              style: GoogleFonts.rajdhani(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(isActive ? 'MONITORING' : 'PAUSED', style: GoogleFonts.rajdhani(
                color: color, fontSize: 9, fontWeight: FontWeight.bold,
              )),
            ),
          ]),
        ],
      ),
    );
  }

  // ── HISTORY TAB ──
  Widget _buildHistoryTab(QuantumPalette p) {
    return ListView(
      key: const ValueKey('history'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildHistoryStats(p),
        const SizedBox(height: 12),
        ..._history.map((h) => _buildHistoryEntry(p, h)),
      ],
    );
  }

  Widget _buildHistoryStats(QuantumPalette p) {
    return Row(children: [
      Expanded(child: _buildHistStat(p, 'TOTAL', '$_totalAlerts', p.primary)),
      const SizedBox(width: 8),
      Expanded(child: _buildHistStat(p, 'ACCURACY', '${_accuracyRate.toStringAsFixed(0)}%', p.positive)),
      const SizedBox(width: 8),
      Expanded(child: _buildHistStat(p, 'MISSED', '3', p.negative)),
      const SizedBox(width: 8),
      Expanded(child: _buildHistStat(p, 'TRADED ON', '42', p.accent)),
    ]);
  }

  Widget _buildHistStat(QuantumPalette p, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
      ]),
    );
  }

  Widget _buildHistoryEntry(QuantumPalette p, Map<String, dynamic> h) {
    final actionColors = {'NOTIFIED': p.primary, 'TRADED': p.positive, 'MISSED': p.negative};
    final actionColor = actionColors[h['action']] ?? p.textSecondary;
    final resultIsPos = (h['result'] as String).startsWith('+');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: actionColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: actionColor.withValues(alpha: 0.12),
            ),
            child: Icon(
              h['action'] == 'TRADED' ? Icons.swap_horiz : h['action'] == 'MISSED' ? Icons.close : Icons.notifications,
              color: actionColor, size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${h['pair']} – ${h['type']?.toString().replaceAll('_', ' ') ?? ''}', style: GoogleFonts.rajdhani(
                color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold,
              )),
              Text(h['time'], style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(h['action'], style: GoogleFonts.rajdhani(
                color: actionColor, fontSize: 9, fontWeight: FontWeight.bold,
              )),
            ),
            const SizedBox(height: 3),
            Text(h['result'], style: GoogleFonts.orbitron(
              color: resultIsPos ? p.positive : p.negative, fontSize: 10, fontWeight: FontWeight.bold,
            )),
          ]),
        ],
      ),
    );
  }

  // ── CREATE TAB ──
  Widget _buildCreateTab(QuantumPalette p) {
    return ListView(
      key: const ValueKey('create'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildCreateForm(p),
      ],
    );
  }

  Widget _buildCreateForm(QuantumPalette p) {
    final types = ['Price Above', 'Price Below', 'RSI Above', 'RSI Below', 'Volume Spike', 'Portfolio P&L', 'AI Pattern'];
    final pairs = ['BTC/USDT', 'ETH/USDT', 'SOL/USDT', 'BNB/USDT', 'AVAX/USDT', 'PORTFOLIO'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.add_alarm, color: p.primary, size: 18),
            const SizedBox(width: 8),
            Text('CREATE NEW ALARM', style: GoogleFonts.orbitron(
              color: p.primary, fontSize: 12, fontWeight: FontWeight.bold,
            )),
          ]),
          const SizedBox(height: 16),
          Text('Market Pair', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: pairs.map((pair) => GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: pair == 'BTC/USDT' ? p.primary.withValues(alpha: 0.2) : p.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: pair == 'BTC/USDT' ? p.primary : p.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(pair, style: GoogleFonts.rajdhani(
                  color: pair == 'BTC/USDT' ? p.primary : p.textSecondary,
                  fontSize: 11, fontWeight: FontWeight.bold,
                )),
              ),
            )).toList(),
          ),
          const SizedBox(height: 14),
          Text('Condition Type', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: types.map((type) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: type == 'Price Above' ? p.positive.withValues(alpha: 0.15) : p.surface.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: type == 'Price Above' ? p.positive.withValues(alpha: 0.5) : p.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(type, style: GoogleFonts.rajdhani(
                color: type == 'Price Above' ? p.positive : p.textSecondary,
                fontSize: 10,
              )),
            )).toList(),
          ),
          const SizedBox(height: 14),
          Text('Target Value', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: p.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.primary.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Text('\$70,000', style: GoogleFonts.orbitron(
                color: p.primary, fontSize: 14, fontWeight: FontWeight.bold,
              )),
              const Spacer(),
              Text('USDT', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 14),
          Text('Priority', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _buildPriorityBtn(p, 'HIGH', p.negative, true)),
            const SizedBox(width: 8),
            Expanded(child: _buildPriorityBtn(p, 'MEDIUM', p.accent, false)),
            const SizedBox(width: 8),
            Expanded(child: _buildPriorityBtn(p, 'LOW', p.textSecondary, false)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Icon(Icons.volume_up, color: p.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text('Sound', style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 12)),
            const Spacer(),
            Switch(value: true, onChanged: (_) {}, activeColor: p.primary),
          ]),
          Row(children: [
            Icon(Icons.notifications, color: p.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text('Push Notification', style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 12)),
            const Spacer(),
            Switch(value: true, onChanged: (_) {}, activeColor: p.primary),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: p.primary.withValues(alpha: 0.2),
                side: BorderSide(color: p.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
              },
              child: Text('CREATE ALARM', style: GoogleFonts.orbitron(
                color: p.primary, fontSize: 12, fontWeight: FontWeight.bold,
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBtn(QuantumPalette p, String label, Color color, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.2) : p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? color : color.withValues(alpha: 0.2)),
      ),
      child: Center(child: Text(label, style: GoogleFonts.orbitron(
        color: selected ? color : p.textSecondary, fontSize: 10, fontWeight: FontWeight.bold,
      ))),
    );
  }

  // ── SETTINGS TAB ──
  Widget _buildSettingsTab(QuantumPalette p) {
    return ListView(
      key: const ValueKey('alarmSettings'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildNotifSettings(p),
        const SizedBox(height: 12),
        _buildCooldownSettings(p),
        const SizedBox(height: 12),
        _buildIntegrationSettings(p),
      ],
    );
  }

  Widget _buildNotifSettings(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.tune, color: p.primary, size: 16),
            const SizedBox(width: 8),
            Text('NOTIFICATION CHANNELS', style: GoogleFonts.orbitron(
              color: p.primary, fontSize: 11, fontWeight: FontWeight.bold,
            )),
          ]),
          const SizedBox(height: 12),
          _buildNotifRow(p, Icons.volume_up, 'Sound Alerts', _soundEnabled, (v) => setState(() => _soundEnabled = v)),
          _buildNotifRow(p, Icons.notifications, 'Push Notifications', _pushEnabled, (v) => setState(() => _pushEnabled = v)),
          _buildNotifRow(p, Icons.email, 'Email Alerts', _emailEnabled, (v) => setState(() => _emailEnabled = v)),
          _buildNotifRow(p, Icons.telegram, 'Telegram Bot', _telegramEnabled, (v) => setState(() => _telegramEnabled = v)),
          _buildNotifRow(p, Icons.vibration, 'Vibration', _vibrationEnabled, (v) => setState(() => _vibrationEnabled = v)),
        ],
      ),
    );
  }

  Widget _buildNotifRow(QuantumPalette p, IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, color: value ? p.primary : p.textSecondary, size: 18),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.rajdhani(
          color: p.textPrimary, fontSize: 13,
        )),
        const Spacer(),
        Switch(value: value, onChanged: onChanged, activeColor: p.primary),
      ]),
    );
  }

  Widget _buildCooldownSettings(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.timer, color: p.accent, size: 16),
            const SizedBox(width: 8),
            Text('ALARM COOLDOWN', style: GoogleFonts.orbitron(
              color: p.accent, fontSize: 11, fontWeight: FontWeight.bold,
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Text('Minimum interval between alerts:',
              style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 11)),
            const Spacer(),
            Text('$_cooldown min', style: GoogleFonts.orbitron(
              color: p.accent, fontSize: 12, fontWeight: FontWeight.bold,
            )),
          ]),
          Slider(
            value: _cooldown.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            activeColor: p.accent,
            inactiveColor: p.surface,
            onChanged: (v) => setState(() => _cooldown = v.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationSettings(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.positive.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.integration_instructions, color: p.positive, size: 16),
            const SizedBox(width: 8),
            Text('INTEGRATIONS', style: GoogleFonts.orbitron(
              color: p.positive, fontSize: 11, fontWeight: FontWeight.bold,
            )),
          ]),
          const SizedBox(height: 12),
          _buildIntegRow(p, Icons.telegram, 'Telegram Bot', '@QuantumAlertBot', p.primary, true),
          _buildIntegRow(p, Icons.webhook, 'Webhook URL', 'https://hooks.quantum...', p.accent, false),
          _buildIntegRow(p, Icons.discord, 'Discord Bot', 'Not configured', p.textSecondary, false),
        ],
      ),
    );
  }

  Widget _buildIntegRow(QuantumPalette p, IconData icon, String label, String value, Color color, bool connected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(value, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: connected ? p.positive.withValues(alpha: 0.1) : p.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: connected ? p.positive.withValues(alpha: 0.4) : p.textSecondary.withValues(alpha: 0.3)),
          ),
          child: Text(connected ? 'CONNECTED' : 'SETUP', style: GoogleFonts.rajdhani(
            color: connected ? p.positive : p.textSecondary, fontSize: 9, fontWeight: FontWeight.bold,
          )),
        ),
      ]),
    );
  }
}
