import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

// ═══════════════════════════════════════════════════════
//  GOD MODE DASHBOARD  –  PIN: 1985
// ═══════════════════════════════════════════════════════
class GodModeScreen extends StatefulWidget {
  const GodModeScreen({super.key});
  @override
  State<GodModeScreen> createState() => _GodModeScreenState();
}

class _GodModeScreenState extends State<GodModeScreen>
    with TickerProviderStateMixin {
  // PIN-Gate
  bool _unlocked = false;
  String _pinInput = '';
  bool _pinError = false;
  int _pinAttempts = 0;
  bool _locked = false;
  Timer? _lockTimer;
  int _lockSeconds = 0;

  // Animationen
  late AnimationController _glowCtrl;
  late AnimationController _matrixCtrl;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  Timer? _metricTimer;

  // Dashboard-State
  int _activeTab = 0;
  final Random _rng = Random(42);

  // Live-Metriken
  double _totalProfit = 184720.45;
  double _dailyPnl = 2847.33;

  int _totalTrades = 4287;
  double _winRate = 73.4;
  double _emmaAccuracy = 94.4;
  final int _agentUptime = 99;
  double _qemmaPrice = 0.0847;
  final double _qemmaSupply = 21000000;
  final double _qemmaMined = 14782344;
  bool _maintenanceMode = false;
  bool _devLogsEnabled = true;
  bool _quantumBoostEnabled = true;
  bool _autoTradeEnabled = false;

  // Agenten-Status
  final List<_AgentStatus> _agents = [
    _AgentStatus('META-ORCHESTRATOR', 99.8, 0, 'v3.2.1', true),
    _AgentStatus('TREND-SENSOR',      98.2, 2, 'v2.8.4', true),
    _AgentStatus('SENTIMENT-AGENT',   97.1, 5, 'v2.1.9', true),
    _AgentStatus('RISK-SENTINEL',     99.5, 1, 'v3.0.0', true),
    _AgentStatus('QUANTUM-RESONATOR', 96.8, 8, 'v2.4.2', true),
    _AgentStatus('EMMA-CORE',         99.9, 0, 'v4.1.0', true),
  ];

  // Trade-Log
  final List<_TradeLog> _trades = [
    _TradeLog('BTC',  'KAUF',  67842.50, 0.05,  2.34, true,  DateTime.now().subtract(const Duration(minutes: 8))),
    _TradeLog('ETH',  'KAUF',   3548.20, 0.30,  1.87, true,  DateTime.now().subtract(const Duration(minutes: 23))),
    _TradeLog('SOL',  'VERKAUF', 184.10, 5.00, -0.52, false, DateTime.now().subtract(const Duration(hours: 1))),
    _TradeLog('QEMMA','KAUF',     0.0812,5000, 12.45, true,  DateTime.now().subtract(const Duration(hours: 2))),
    _TradeLog('BNB',  'KAUF',   596.80, 1.20,  0.94, true,  DateTime.now().subtract(const Duration(hours: 3))),
    _TradeLog('ADA',  'VERKAUF',  0.631, 800, -1.23, false,  DateTime.now().subtract(const Duration(hours: 5))),
    _TradeLog('BTC',  'KAUF',  66210.00, 0.08,  3.21, true,  DateTime.now().subtract(const Duration(hours: 12))),
    _TradeLog('ETH',  'VERKAUF', 3480.50, 0.50, -0.45, false, DateTime.now().subtract(const Duration(days: 1))),
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _matrixCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 1),
    )..repeat();

    _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.linear));

    _metricTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_unlocked) return;
      setState(() {
        _dailyPnl    += (_rng.nextDouble() - 0.45) * 120;
        _totalProfit += (_rng.nextDouble() - 0.3) * 50;
        _qemmaPrice  = (_qemmaPrice * (1 + (_rng.nextDouble() - 0.48) * 0.01)).clamp(0.05, 0.5);
        _totalTrades += _rng.nextInt(3);
        _winRate     = (_winRate + (_rng.nextDouble() - 0.5) * 0.1).clamp(60.0, 85.0);
        _emmaAccuracy= (_emmaAccuracy + (_rng.nextDouble() - 0.5) * 0.05).clamp(90.0, 99.0);
      });
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _matrixCtrl.dispose();
    _shakeCtrl.dispose();
    _metricTimer?.cancel();
    _lockTimer?.cancel();
    super.dispose();
  }

  // ── PIN-Eingabe ───────────────────────────────────────
  void _onPinKey(String key) {
    if (_locked) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pinError = false;
      if (key == 'DEL') {
        if (_pinInput.isNotEmpty) _pinInput = _pinInput.substring(0, _pinInput.length - 1);
      } else if (_pinInput.length < 4) {
        _pinInput += key;
        if (_pinInput.length == 4) _checkPin();
      }
    });
  }

  void _checkPin() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      if (_pinInput == '1985') {
        setState(() => _unlocked = true);
        context.read<ThemeProvider>().setGodMode(true);
        HapticFeedback.heavyImpact();
      } else {
        _pinAttempts++;
        setState(() {
          _pinError = true;
          _pinInput = '';
        });
        _shakeCtrl.forward(from: 0);
        if (_pinAttempts >= 3) {
          setState(() { _locked = true; _lockSeconds = 30; });
          _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
            if (!mounted) { t.cancel(); return; }
            setState(() => _lockSeconds--);
            if (_lockSeconds <= 0) {
              t.cancel();
              setState(() { _locked = false; _pinAttempts = 0; });
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: p.background,
      body: _unlocked ? _buildDashboard(p) : _buildPinGate(p),
    );
  }

  // ═══════════════════════════════════════════════
  //  PIN-GATE
  // ═══════════════════════════════════════════════
  Widget _buildPinGate(dynamic p) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(_shakeAnim.value, 0),
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.background, p.surface, p.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: p.textSecondary, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ]),
              ),
              const Spacer(),
              // GOD MODE Logo
              AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, __) => Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: p.primary.withValues(alpha: 0.4 + _glowCtrl.value * 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: p.primary.withValues(alpha: 0.15 + _glowCtrl.value * 0.2),
                        blurRadius: 24 + _glowCtrl.value * 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(Icons.security, color: p.primary, size: 40),
                ),
              ),
              const SizedBox(height: 20),
              Text('GOD MODE', style: GoogleFonts.spaceMono(
                color: p.primary, fontSize: 22,
                fontWeight: FontWeight.bold, letterSpacing: 6,
              )),
              const SizedBox(height: 6),
              Text('Sicherheitsprotokoll aktiv', style: GoogleFonts.inter(
                color: p.textSecondary, fontSize: 12,
              )),
              const SizedBox(height: 36),
              // PIN-Punkte
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pinInput.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _pinError
                          ? p.negative
                          : filled
                          ? p.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: _pinError
                            ? p.negative
                            : filled
                            ? p.primary
                            : p.textSecondary.withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: filled && !_pinError ? [
                        BoxShadow(color: p.primary.withValues(alpha: 0.4), blurRadius: 8),
                      ] : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              AnimatedOpacity(
                opacity: _pinError ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _locked
                      ? 'Gesperrt – bitte warten ($_lockSeconds s)'
                      : 'Falscher PIN (${3 - _pinAttempts} Versuche)',
                  style: GoogleFonts.spaceMono(color: p.negative, fontSize: 10),
                ),
              ),
              const SizedBox(height: 28),
              // Numpad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _buildNumRow(['1', '2', '3'], p),
                    const SizedBox(height: 12),
                    _buildNumRow(['4', '5', '6'], p),
                    const SizedBox(height: 12),
                    _buildNumRow(['7', '8', '9'], p),
                    const SizedBox(height: 12),
                    _buildNumRow(['', '0', 'DEL'], p),
                  ],
                ),
              ),
              const Spacer(),
              Text('© HQMLL · G. Saks · v1.0.0', style: GoogleFonts.spaceMono(
                color: p.textSecondary.withValues(alpha: 0.4), fontSize: 9,
              )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumRow(List<String> keys, dynamic p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox(width: 72, height: 72);
        return GestureDetector(
          onTap: () => _onPinKey(k),
          child: AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) => Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.surface,
                border: Border.all(color: p.primary.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: p.primary.withValues(alpha: 0.04 + _glowCtrl.value * 0.04),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Center(
                child: k == 'DEL'
                    ? Icon(Icons.backspace_outlined, color: p.textSecondary, size: 22)
                    : Text(k, style: GoogleFonts.rajdhani(
                        color: p.textPrimary, fontSize: 26, fontWeight: FontWeight.bold,
                      )),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════
  //  DASHBOARD
  // ═══════════════════════════════════════════════
  Widget _buildDashboard(dynamic p) {
    final tabs = ['ÜBERSICHT', 'AGENTEN', 'TRADES', 'SYSTEM'];
    return Column(
      children: [
        // Header
        _buildDashHeader(p),
        // Tab-Bar
        Container(
          height: 38,
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final active = _activeTab == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: active ? p.primary.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: active ? Border.all(color: p.primary.withValues(alpha: 0.4)) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(tabs[i], style: GoogleFonts.spaceMono(
                      color: active ? p.primary : p.textSecondary,
                      fontSize: 8, fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    )),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
        // Content
        Expanded(
          child: IndexedStack(
            index: _activeTab,
            children: [
              _buildOverview(p),
              _buildAgentMonitor(p),
              _buildTradeLog(p),
              _buildSystem(p),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashHeader(dynamic p) {
    return Container(
      color: p.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios, color: p.primary, size: 18),
              onPressed: () {
                context.read<ThemeProvider>().setGodMode(false);
                Navigator.pop(context);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 10),
            AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.primary.withValues(alpha: 0.8 + _glowCtrl.value * 0.2),
                  boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.6), blurRadius: 6)],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('GOD MODE', style: GoogleFonts.spaceMono(
              color: p.primary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 3,
            )),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: p.primary.withValues(alpha: 0.3)),
              ),
              child: Text('G. SAKS · OWNER', style: GoogleFonts.spaceMono(
                color: p.primary, fontSize: 7,
              )),
            ),
            const Spacer(),
            // Lock button
            GestureDetector(
              onTap: () {
                setState(() { _unlocked = false; _pinInput = ''; });
                context.read<ThemeProvider>().setGodMode(false);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: p.negative.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: p.negative.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.lock_outline, color: p.negative, size: 16),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── TAB 0: ÜBERSICHT ─────────────────────────────────
  Widget _buildOverview(dynamic p) {
    final pnlPositive = _dailyPnl >= 0;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      children: [
        // Big P&L Card
        AnimatedBuilder(
          animation: _glowCtrl,
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  p.primary.withValues(alpha: 0.12 + _glowCtrl.value * 0.06),
                  p.primary.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: p.primary.withValues(alpha: 0.25 + _glowCtrl.value * 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: p.primary.withValues(alpha: 0.08 + _glowCtrl.value * 0.08),
                  blurRadius: 20, spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('GESAMT-PORTFOLIO', style: GoogleFonts.spaceMono(
                    color: p.textSecondary, fontSize: 9, letterSpacing: 1.5,
                  )),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: p.positive.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: p.positive.withValues(alpha: 0.4)),
                    ),
                    child: Text('LIVE', style: GoogleFonts.spaceMono(
                      color: p.positive, fontSize: 7, fontWeight: FontWeight.bold,
                    )),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(
                  '\$${_totalProfit.toStringAsFixed(2)}',
                  style: GoogleFonts.rajdhani(
                    color: p.textPrimary, fontSize: 34, fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(
                    pnlPositive ? Icons.trending_up : Icons.trending_down,
                    color: pnlPositive ? p.positive : p.negative, size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${pnlPositive ? '+' : ''}\$${_dailyPnl.toStringAsFixed(2)} heute',
                    style: GoogleFonts.rajdhani(
                      color: pnlPositive ? p.positive : p.negative,
                      fontSize: 14, fontWeight: FontWeight.bold,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Metriken-Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.1,
          children: [
            _MetricCard('WIN RATE', '${_winRate.toStringAsFixed(1)}%', Icons.emoji_events_outlined, p.positive, p),
            _MetricCard('EMMA GENAUIGKEIT', '${_emmaAccuracy.toStringAsFixed(1)}%', Icons.psychology, p.primary, p),
            _MetricCard('TRADES GESAMT', '$_totalTrades', Icons.swap_horiz, p.accent, p),
            _MetricCard('AGENTEN-UPTIME', '$_agentUptime%', Icons.hub, p.positive, p),
          ],
        ),
        const SizedBox(height: 10),
        // QEMMA Token Stats
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.token, color: p.primary, size: 16),
                const SizedBox(width: 8),
                Text('\$QEMMA TOKEN', style: GoogleFonts.spaceMono(
                  color: p.textSecondary, fontSize: 9, letterSpacing: 1,
                )),
                const Spacer(),
                Text(
                  '\$${_qemmaPrice.toStringAsFixed(4)}',
                  style: GoogleFonts.rajdhani(
                    color: p.primary, fontSize: 15, fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              _buildTokenBar('Gemint', _qemmaMined, _qemmaSupply, p.primary, p),
              const SizedBox(height: 6),
              Row(children: [
                _tokenStat('SUPPLY', '${(_qemmaSupply / 1e6).toStringAsFixed(0)}M', p),
                _tokenStat('GEMINT', '${(_qemmaMined / 1e6).toStringAsFixed(2)}M', p),
                _tokenStat('VERBLEIBEND', '${((_qemmaSupply - _qemmaMined) / 1e6).toStringAsFixed(2)}M', p),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Schnell-Aktionen
        Row(children: [
          _QuickAction('SIGNAL PUSHEN', Icons.notifications_active, p.primary, p, () {
            _showSnack(context, '📡 Quantum-Signal an alle Nutzer gesendet!', p.positive);
          }),
          const SizedBox(width: 8),
          _QuickAction('MINING BOOST', Icons.bolt, p.accent, p, () {
            _showSnack(context, '⚡ Mining-Rate x2 für 1h aktiviert!', p.accent);
          }),
          const SizedBox(width: 8),
          _QuickAction('NOTFALL STOP', Icons.stop_circle_outlined, p.negative, p, () {
            _showStopDialog(context, p);
          }),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTokenBar(String label, double value, double max, Color color, dynamic p) {
    final pct = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: p.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${(pct * 100).toStringAsFixed(1)}% gemint',
          style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8),
        ),
      ],
    );
  }

  Widget _tokenStat(String label, String value, dynamic p) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.rajdhani(
            color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold,
          )),
          Text(label, style: GoogleFonts.spaceMono(
            color: p.textSecondary, fontSize: 7, letterSpacing: 0.3,
          )),
        ],
      ),
    );
  }

  // ── TAB 1: AGENTEN ────────────────────────────────────
  Widget _buildAgentMonitor(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('META-AGENTEN MONITOR', style: GoogleFonts.spaceMono(
          color: p.textSecondary, fontSize: 9, letterSpacing: 1.5,
        )),
        const SizedBox(height: 10),
        ..._agents.map((a) => _buildAgentCard(a, p)),
        const SizedBox(height: 10),
        // System-Load Grafik
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SYSTEM-RESSOURCEN', style: GoogleFonts.spaceMono(
                color: p.textSecondary, fontSize: 9, letterSpacing: 1,
              )),
              const SizedBox(height: 12),
              _buildResourceBar('CPU', 34.2, p.primary, p),
              const SizedBox(height: 8),
              _buildResourceBar('RAM', 61.8, p.accent, p),
              const SizedBox(height: 8),
              _buildResourceBar('GPU', 22.5, p.positive, p),
              const SizedBox(height: 8),
              _buildResourceBar('NETZ', 8.3, p.textSecondary, p),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgentCard(_AgentStatus a, dynamic p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: a.active
              ? p.positive.withValues(alpha: 0.2)
              : p.negative.withValues(alpha: 0.2),
        ),
      ),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: a.active ? p.positive : p.negative,
            boxShadow: [BoxShadow(
              color: (a.active ? p.positive : p.negative).withValues(alpha: 0.5),
              blurRadius: 6,
            )],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.name, style: GoogleFonts.spaceMono(
                color: p.textPrimary, fontSize: 10, fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: a.uptime / 100,
                  backgroundColor: p.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(p.positive),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${a.uptime.toStringAsFixed(1)}%', style: GoogleFonts.rajdhani(
              color: p.positive, fontSize: 12, fontWeight: FontWeight.bold,
            )),
            Text(a.version, style: GoogleFonts.spaceMono(
              color: p.textSecondary, fontSize: 8,
            )),
          ],
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => a.active = !a.active),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: a.active
                  ? p.positive.withValues(alpha: 0.1)
                  : p.negative.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: a.active
                    ? p.positive.withValues(alpha: 0.4)
                    : p.negative.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              a.active ? 'AN' : 'AUS',
              style: GoogleFonts.spaceMono(
                color: a.active ? p.positive : p.negative,
                fontSize: 8, fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildResourceBar(String label, double value, Color color, dynamic p) {
    return Row(children: [
      SizedBox(
        width: 40,
        child: Text(label, style: GoogleFonts.spaceMono(
          color: p.textSecondary, fontSize: 9,
        )),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: p.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text('${value.toStringAsFixed(1)}%', style: GoogleFonts.rajdhani(
        color: color, fontSize: 11, fontWeight: FontWeight.bold,
      )),
    ]);
  }

  // ── TAB 2: TRADES ─────────────────────────────────────
  Widget _buildTradeLog(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(children: [
          Text('TRADE-PROTOKOLL', style: GoogleFonts.spaceMono(
            color: p.textSecondary, fontSize: 9, letterSpacing: 1.5,
          )),
          const Spacer(),
          Text('${_trades.length} Einträge', style: GoogleFonts.inter(
            color: p.textSecondary, fontSize: 10,
          )),
        ]),
        const SizedBox(height: 10),
        ..._trades.map((t) => _buildTradeRow(t, p)),
        const SizedBox(height: 10),
        // Statistiken
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TRADE-STATISTIKEN', style: GoogleFonts.spaceMono(
                color: p.textSecondary, fontSize: 9, letterSpacing: 1,
              )),
              const SizedBox(height: 12),
              Row(children: [
                _StatBox('KÄUFE', '${_trades.where((t) => t.side == 'KAUF').length}', p.positive, p),
                _StatBox('VERKÄUFE', '${_trades.where((t) => t.side == 'VERKAUF').length}', p.negative, p),
                _StatBox('WIN RATE', '${_winRate.toStringAsFixed(0)}%', p.primary, p),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTradeRow(_TradeLog t, dynamic p) {
    final isBuy = t.side == 'KAUF';
    final pnl = t.amount * t.price * (t.changePercent / 100);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBuy
              ? p.positive.withValues(alpha: 0.15)
              : p.negative.withValues(alpha: 0.15),
        ),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isBuy ? p.positive : p.negative).withValues(alpha: 0.12),
            border: Border.all(
              color: (isBuy ? p.positive : p.negative).withValues(alpha: 0.4),
            ),
          ),
          child: Center(
            child: Text(
              isBuy ? 'K' : 'V',
              style: GoogleFonts.spaceMono(
                color: isBuy ? p.positive : p.negative,
                fontSize: 11, fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(t.symbol, style: GoogleFonts.spaceMono(
                  color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold,
                )),
                const SizedBox(width: 6),
                Text(t.side, style: GoogleFonts.spaceMono(
                  color: isBuy ? p.positive : p.negative, fontSize: 9,
                )),
              ]),
              Text(
                '${t.amount % 1 == 0 ? t.amount.toStringAsFixed(0) : t.amount.toStringAsFixed(4)} × \$${t.price >= 100 ? t.price.toStringAsFixed(0) : t.price.toStringAsFixed(4)}',
                style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
              style: GoogleFonts.rajdhani(
                color: pnl >= 0 ? p.positive : p.negative,
                fontSize: 12, fontWeight: FontWeight.bold,
              ),
            ),
            Text(_fmtAge(t.time), style: GoogleFonts.inter(
              color: p.textSecondary, fontSize: 9,
            )),
          ],
        ),
      ]),
    );
  }

  String _fmtAge(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays > 0) return 'vor ${diff.inDays}T';
    if (diff.inHours > 0) return 'vor ${diff.inHours}h';
    return 'vor ${diff.inMinutes}m';
  }

  // ── TAB 3: SYSTEM ─────────────────────────────────────
  Widget _buildSystem(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('SYSTEM-KONTROLLE', style: GoogleFonts.spaceMono(
          color: p.textSecondary, fontSize: 9, letterSpacing: 1.5,
        )),
        const SizedBox(height: 10),
        // Toggles
        _buildToggleCard(
          'WARTUNGSMODUS',
          'Sperrt alle Nutzer-Transaktionen',
          Icons.build_outlined,
          _maintenanceMode,
          p.negative,
          p,
          (v) => setState(() => _maintenanceMode = v),
        ),
        _buildToggleCard(
          'AUTO-TRADING',
          'Emma handelt automatisch für Sie',
          Icons.smart_toy_outlined,
          _autoTradeEnabled,
          p.primary,
          p,
          (v) => setState(() => _autoTradeEnabled = v),
        ),
        _buildToggleCard(
          'QUANTUM BOOST',
          'Erhöhte Resonanz-Berechnungen',
          Icons.bolt,
          _quantumBoostEnabled,
          p.accent,
          p,
          (v) => setState(() => _quantumBoostEnabled = v),
        ),
        _buildToggleCard(
          'DEV LOGS',
          'Zeigt interne Debugging-Logs',
          Icons.terminal,
          _devLogsEnabled,
          p.textSecondary,
          p,
          (v) => setState(() => _devLogsEnabled = v),
        ),
        const SizedBox(height: 10),
        // App-Info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              _infoRow('APP VERSION', 'v1.0.0 (Build 1)', p),
              _infoRow('PACKAGE', 'com.quantumtrader.trade', p),
              _infoRow('FLUTTER SDK', '3.35.4', p),
              _infoRow('DART', '3.9.2', p),
              _infoRow('BUILD', 'Release / Signed', p),
              _infoRow('ZERTIFIKAT', 'B9:5B:08:CA…6F:04:26', p),
              _infoRow('OWNER', 'Grigori Saks', p),
              _infoRow('ORGANISATION', 'HQMLL Platform', p),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Danger Zone
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.negative.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.negative.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DANGER ZONE', style: GoogleFonts.spaceMono(
                color: p.negative, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: _DangerBtn('CACHE LÖSCHEN', Icons.delete_sweep, p, () {
                    _showSnack(context, '🗑 Cache erfolgreich gelöscht', p.positive);
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DangerBtn('RESET AGENTEN', Icons.restart_alt, p, () {
                    _showSnack(context, '🔄 Alle Agenten neu gestartet', p.accent);
                  }),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildToggleCard(
    String title, String subtitle, IconData icon,
    bool value, Color color, dynamic p, void Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value ? color.withValues(alpha: 0.3) : p.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: value ? 0.15 : 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: value ? color : p.textSecondary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.spaceMono(
                color: value ? p.textPrimary : p.textSecondary,
                fontSize: 10, fontWeight: FontWeight.bold,
              )),
              Text(subtitle, style: GoogleFonts.inter(
                color: p.textSecondary, fontSize: 10,
              )),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: color,
          inactiveTrackColor: p.surfaceVariant,
        ),
      ]),
    );
  }

  Widget _infoRow(String k, String v, dynamic p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(k, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9, letterSpacing: 0.5)),
        const Spacer(),
        Text(v, style: GoogleFonts.inter(color: p.textPrimary, fontSize: 11)),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────
  void _showSnack(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    ));
  }

  void _showStopDialog(BuildContext ctx, dynamic p) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.negative.withValues(alpha: 0.5)),
        ),
        title: Row(children: [
          Icon(Icons.warning_amber, color: p.negative, size: 22),
          const SizedBox(width: 8),
          Text('NOTFALL STOP', style: GoogleFonts.spaceMono(
            color: p.negative, fontSize: 14, fontWeight: FontWeight.bold,
          )),
        ]),
        content: Text(
          'Alle laufenden Trades und Agenten werden sofort gestoppt.\n\nSind Sie sicher?',
          style: GoogleFonts.inter(color: p.textPrimary, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Abbrechen', style: TextStyle(color: p.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              for (final a in _agents) { setState(() => a.active = false); }
              _showSnack(ctx, '🛑 Notfall-Stop ausgeführt – alle Agenten gestoppt', p.negative);
            },
            style: ElevatedButton.styleFrom(backgroundColor: p.negative, foregroundColor: Colors.white),
            child: Text('STOPPEN', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final dynamic palette;
  const _MetricCard(this.label, this.value, this.icon, this.color, this.palette);

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: GoogleFonts.rajdhani(
                color: color, fontSize: 16, fontWeight: FontWeight.bold,
              )),
              Text(label, style: GoogleFonts.spaceMono(
                color: p.textSecondary, fontSize: 7, letterSpacing: 0.3,
              )),
            ],
          ),
        ),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final dynamic palette;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.color, this.palette, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center,
                style: GoogleFonts.spaceMono(color: color, fontSize: 7, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  final dynamic palette;
  const _StatBox(this.label, this.value, this.color, this.palette);

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Expanded(
      child: Column(children: [
        Text(value, style: GoogleFonts.rajdhani(
          color: color, fontSize: 18, fontWeight: FontWeight.bold,
        )),
        Text(label, style: GoogleFonts.spaceMono(
          color: p.textSecondary, fontSize: 8,
        )),
      ]),
    );
  }
}

class _DangerBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final dynamic palette;
  final VoidCallback onTap;
  const _DangerBtn(this.label, this.icon, this.palette, this.onTap);

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: p.negative.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: p.negative.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: p.negative, size: 14),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.spaceMono(
              color: p.negative, fontSize: 8, fontWeight: FontWeight.bold,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Data Classes ───────────────────────────────────────
class _AgentStatus {
  final String name, version;
  final double uptime;
  final int errors;
  bool active;
  _AgentStatus(this.name, this.uptime, this.errors, this.version, this.active);
}

class _TradeLog {
  final String symbol, side;
  final double price, amount, changePercent;
  final bool isWin;
  final DateTime time;
  _TradeLog(this.symbol, this.side, this.price, this.amount, this.changePercent, this.isWin, this.time);
}
