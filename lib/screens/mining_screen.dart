// ============================================================
// MINING SCREEN v2 – HQMLL Quantum Miner Dashboard
// Live Hashrate, GPU Pool, Rewards, Calculator, Pool Stats
// ============================================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/exchange_service.dart';

class MiningScreen extends StatefulWidget {
  const MiningScreen({super.key});
  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen>
    with TickerProviderStateMixin {
  late TabController _tab;
  late AnimationController _glowCtrl;
  late AnimationController _hashCtrl;
  Timer? _liveTimer;
  final _rand = Random();

  // Mining State
  bool _miningActive = false;
  double _hashrate = 0;
  final double _targetHashrate = 142.6;
  final double _poolHashrate = 4821.3;
  double _dailyReward = 0.00284;
  final double _totalMined = 1.04872;
  final double _pendingPayout = 0.00284;
  double _efficiency = 94.7;
  double _temperature = 68.4;
  final double _powerDraw = 285.0;
  int _shareCount = 1847;
  final int _rejectedShares = 12;
  double _profitUSD = 193.42;
  double _btcPrice = 67842.0; // seeded from ExchangeService
  bool _btcIsLive = false;

  // GPU Workers
  final List<Map<String, dynamic>> _gpus = [
    {'name': 'RTX 4090', 'hashrate': 123.4, 'temp': 71, 'power': 320, 'fan': 62, 'mem': 'GDDR6X 24GB', 'active': true},
    {'name': 'RTX 3080 Ti', 'hashrate': 89.2, 'temp': 68, 'power': 280, 'fan': 58, 'mem': 'GDDR6X 12GB', 'active': true},
    {'name': 'RTX 3070', 'hashrate': 61.8, 'temp': 64, 'power': 220, 'fan': 52, 'mem': 'GDDR6 8GB', 'active': false},
    {'name': 'RX 6800 XT', 'hashrate': 63.0, 'temp': 72, 'power': 250, 'fan': 65, 'mem': 'GDDR6 16GB', 'active': true},
  ];

  // Pool Options
  final List<Map<String, dynamic>> _pools = [
    {'name': 'HQMLL-POOL', 'url': 'pool.hqmll.io:3333', 'fee': '0.9%', 'miners': 3421, 'hashrate': '4.82 PH/s', 'selected': true, 'color': const Color(0xFF00FF88)},
    {'name': 'F2Pool', 'url': 'btc.f2pool.com:3333', 'fee': '2.5%', 'miners': 84200, 'hashrate': '28.4 EH/s', 'selected': false, 'color': const Color(0xFF00AAFF)},
    {'name': 'Antpool', 'url': 'stratum.antpool.com:3333', 'fee': '1.0%', 'miners': 120400, 'hashrate': '38.1 EH/s', 'selected': false, 'color': const Color(0xFFFF6B35)},
    {'name': 'Slushpool', 'url': 'btc.slushpool.com:3333', 'fee': '2.0%', 'miners': 15800, 'hashrate': '9.2 EH/s', 'selected': false, 'color': const Color(0xFFAA44FF)},
  ];

  // Hashrate history
  final List<double> _hashrateHistory = [];

  // Calculator
  final _calcHashCtrl = TextEditingController(text: '142.6');
  final _calcPowerCtrl = TextEditingController(text: '285');
  final _calcElecCtrl = TextEditingController(text: '0.12');
  double _calcProfit = 0;
  double _calcRevenue = 0;
  double _calcCost = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat(reverse: true);
    _hashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    // Init history
    for (int i = 0; i < 60; i++) {
      _hashrateHistory.add(130 + _rand.nextDouble() * 30);
    }

    _startLiveFeed();
    _calculate();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedBtcFromExchange());
  }

  void _seedBtcFromExchange() {
    if (!mounted) return;
    final ex = context.read<ExchangeService>();
    final tick = ex.getTick('BTC');
    if (tick != null && tick.price > 0) {
      setState(() {
        _btcPrice = tick.price;
        _btcIsLive = tick.isLive;
        _profitUSD = _dailyReward * _btcPrice;
      });
      _calculate();
    }
  }

  void _syncBtcFromExchange(ExchangeService ex) {
    final tick = ex.getTick('BTC');
    if (tick != null && tick.price > 0) {
      final newPrice = tick.price;
      if ((newPrice - _btcPrice).abs() / _btcPrice > 0.0005) {
        _btcPrice = newPrice;
        _btcIsLive = tick.isLive;
        _profitUSD = _dailyReward * _btcPrice;
        _calculate();
      }
    }
  }

  void _startLiveFeed() {
    _liveTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!mounted) return;
      setState(() {
        if (_miningActive) {
          _hashrate = _targetHashrate + (_rand.nextDouble() - 0.5) * 8;
          _temperature = 68 + _rand.nextDouble() * 6;
          _efficiency = 93 + _rand.nextDouble() * 4;
          _shareCount += _rand.nextInt(3);
          _dailyReward = _hashrate * 0.0000199;
          _profitUSD = _dailyReward * _btcPrice;
          _hashrateHistory.add(_hashrate);
          if (_hashrateHistory.length > 60) _hashrateHistory.removeAt(0);
          // Update GPUs slightly
          for (var gpu in _gpus) {
            if (gpu['active'] == true) {
              gpu['hashrate'] = (gpu['hashrate'] as double) + (_rand.nextDouble() - 0.5) * 2;
              gpu['temp'] = ((gpu['temp'] as int) + (_rand.nextBool() ? 1 : -1)).clamp(55, 85);
            }
          }
        }
      });
    });
  }

  void _calculate() {
    final h = double.tryParse(_calcHashCtrl.text) ?? 142.6;
    final p = double.tryParse(_calcPowerCtrl.text) ?? 285.0;
    final e = double.tryParse(_calcElecCtrl.text) ?? 0.12;
    _calcRevenue = h * 0.0000199 * _btcPrice;
    _calcCost = (p / 1000) * 24 * e;
    _calcProfit = _calcRevenue - _calcCost;
  }

  void _toggleMining() {
    HapticFeedback.mediumImpact();
    setState(() {
      _miningActive = !_miningActive;
      if (_miningActive) {
        _hashrate = _targetHashrate;
        _hashCtrl.forward(from: 0);
      } else {
        _hashrate = 0;
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _glowCtrl.dispose();
    _hashCtrl.dispose();
    _liveTimer?.cancel();
    _calcHashCtrl.dispose();
    _calcPowerCtrl.dispose();
    _calcElecCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    final ex = context.watch<ExchangeService>();
    _syncBtcFromExchange(ex);
    return Scaffold(
      backgroundColor: p.background,
      body: Column(
        children: [
          _buildHeader(p, ex),
          _buildTabBar(p),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildDashboard(p),
                _buildWorkers(p),
                _buildPools(p),
                _buildCalculator(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic p, ExchangeService ex) {
    final btcTick = ex.getTick('BTC');
    final livePrice = btcTick?.price ?? _btcPrice;
    final isLive = btcTick?.isLive ?? false;
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(bottom: BorderSide(color: const Color(0xFF00FF88).withValues(alpha: 0.15 + _glowCtrl.value * 0.1))),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF00FF88).withValues(alpha: 0.25), const Color(0xFF00FF88).withValues(alpha: 0.05)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.4 + _glowCtrl.value * 0.3)),
                boxShadow: [BoxShadow(color: const Color(0xFF00FF88).withValues(alpha: 0.2 + _glowCtrl.value * 0.15), blurRadius: 12)],
              ),
              child: const Icon(Icons.hardware_rounded, color: Color(0xFF00FF88), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('QUANTUM MINER', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(width: 8),
                    _statusBadge(_miningActive ? 'AKTIV' : 'OFFLINE', _miningActive ? const Color(0xFF00FF88) : const Color(0xFFFF3358)),
                  ]),
                  Row(children: [
                    Text('SHA-256 · Pool: HQMLL · ', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFF00FF88).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
                        child: Text('LIVE', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 7, letterSpacing: 1)),
                      ),
                    const SizedBox(width: 4),
                    Text('BTC \$${livePrice.toStringAsFixed(0)}', style: GoogleFonts.spaceMono(color: isLive ? const Color(0xFF00FF88) : p.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
            ),
            GestureDetector(
              onTap: _toggleMining,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 56, height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _miningActive
                        ? [const Color(0xFF00FF88), const Color(0xFF00AA55)]
                        : [p.surfaceVariant, p.surfaceVariant],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: _miningActive ? [BoxShadow(color: const Color(0xFF00FF88).withValues(alpha: 0.4 + _glowCtrl.value * 0.2), blurRadius: 10)] : [],
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  alignment: _miningActive ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 26, height: 26,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
                    child: Icon(_miningActive ? Icons.pause_rounded : Icons.play_arrow_rounded, color: _miningActive ? const Color(0xFF00AA55) : p.textSecondary, size: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.35))),
      child: Text(label, style: GoogleFonts.spaceMono(color: color, fontSize: 8, letterSpacing: 1)),
    );
  }

  Widget _buildTabBar(dynamic p) {
    return Container(
      color: p.surface,
      child: TabBar(
        controller: _tab,
        labelColor: const Color(0xFF00FF88),
        unselectedLabelColor: p.textSecondary,
        indicatorColor: const Color(0xFF00FF88),
        indicatorWeight: 2,
        labelStyle: GoogleFonts.spaceMono(fontSize: 10, letterSpacing: 1),
        unselectedLabelStyle: GoogleFonts.spaceMono(fontSize: 10),
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_outlined, size: 15), text: 'DASHBOARD'),
          Tab(icon: Icon(Icons.memory_outlined, size: 15), text: 'WORKERS'),
          Tab(icon: Icon(Icons.pool_outlined, size: 15), text: 'POOLS'),
          Tab(icon: Icon(Icons.calculate_outlined, size: 15), text: 'RECHNER'),
        ],
      ),
    );
  }

  // ─── DASHBOARD ───
  Widget _buildDashboard(dynamic p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Live Hashrate Card
          _buildHashrateCard(p),
          const SizedBox(height: 10),
          // Stats Row
          Row(children: [
            Expanded(child: _statCard('HASHRATE', '${_hashrate.toStringAsFixed(1)} TH/s', Icons.speed_rounded, const Color(0xFF00FF88), p)),
            const SizedBox(width: 8),
            Expanded(child: _statCard('TEMPERATUR', '${_temperature.toStringAsFixed(1)}°C', Icons.thermostat_rounded, const Color(0xFFFF6B35), p)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _statCard('EFFIZIENZ', '${_efficiency.toStringAsFixed(1)}%', Icons.bolt_rounded, const Color(0xFFFFD700), p)),
            const SizedBox(width: 8),
            Expanded(child: _statCard('POWER', '${_powerDraw.toStringAsFixed(0)} W', Icons.power_rounded, const Color(0xFFAA44FF), p)),
          ]),
          const SizedBox(height: 10),
          // Rewards Card
          _buildRewardsCard(p),
          const SizedBox(height: 10),
          // Pool Stats Card
          _buildPoolStatsCard(p),
          const SizedBox(height: 10),
          // Shares
          _buildSharesCard(p),
        ],
      ),
    );
  }

  Widget _buildHashrateCard(dynamic p) {
    final maxH = _hashrateHistory.isEmpty ? 180.0 : _hashrateHistory.reduce(max) + 10;
    final minH = _hashrateHistory.isEmpty ? 100.0 : _hashrateHistory.reduce(min) - 10;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('LIVE HASHRATE', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 11, letterSpacing: 1.5)),
            const Spacer(),
            AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: _miningActive ? const Color(0xFF00FF88) : const Color(0xFFFF3358),
                  shape: BoxShape.circle,
                  boxShadow: _miningActive ? [BoxShadow(color: const Color(0xFF00FF88).withValues(alpha: 0.5 + _glowCtrl.value * 0.4), blurRadius: 6)] : [],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(_miningActive ? 'LIVE' : 'OFFLINE', style: GoogleFonts.spaceMono(color: _miningActive ? const Color(0xFF00FF88) : const Color(0xFFFF3358), fontSize: 9)),
          ]),
          const SizedBox(height: 12),
          // Hashrate display
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              _hashrate.toStringAsFixed(2),
              style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 36, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 6),
              child: Text('TH/s', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88).withValues(alpha: 0.6), fontSize: 14)),
            ),
          ]),
          const SizedBox(height: 10),
          // Sparkline chart
          SizedBox(
            height: 60,
            child: CustomPaint(
              size: const Size(double.infinity, 60),
              painter: _HashrateSparklinePainter(_hashrateHistory, minH, maxH, const Color(0xFF00FF88)),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text('Pool HR: ${_poolHashrate.toStringAsFixed(1)} PH/s', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
            const Spacer(),
            Text('Target: $_targetHashrate TH/s', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
          ]),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, dynamic p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8, letterSpacing: 0.8)),
          Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _buildRewardsCard(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFD700).withValues(alpha: 0.08), const Color(0xFFFFD700).withValues(alpha: 0.02)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 16),
          const SizedBox(width: 8),
          Text('MINING REWARDS', style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 11, letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _rewardItem('GESAMT MINED', '${_totalMined.toStringAsFixed(5)} BTC', '≈ \$${(_totalMined * _btcPrice).toStringAsFixed(0)}', p)),
          Container(width: 1, height: 40, color: const Color(0xFFFFD700).withValues(alpha: 0.2)),
          Expanded(child: _rewardItem('24H REWARD', '${_dailyReward.toStringAsFixed(6)} BTC', '≈ \$${_profitUSD.toStringAsFixed(2)}', p)),
          Container(width: 1, height: 40, color: const Color(0xFFFFD700).withValues(alpha: 0.2)),
          Expanded(child: _rewardItem('AUSSTEHEND', '${_pendingPayout.toStringAsFixed(6)} BTC', 'Min: 0.005 BTC', p)),
        ]),
        const SizedBox(height: 12),
        // Payout progress
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Auszahlung', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
            const Spacer(),
            Text('${((_pendingPayout / 0.005) * 100).toStringAsFixed(1)}%', style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 10)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_pendingPayout / 0.005).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFFFD700).withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
              minHeight: 6,
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _rewardItem(String label, String value, String sub, dynamic p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8, letterSpacing: 0.5), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        Text(sub, style: GoogleFonts.inter(color: p.textSecondary.withValues(alpha: 0.6), fontSize: 9), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildPoolStatsCard(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.hub_outlined, color: p.primary, size: 16),
          const SizedBox(width: 8),
          Text('POOL STATISTIKEN', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 11, letterSpacing: 1.5)),
          const Spacer(),
          _statusBadge('HQMLL-POOL', const Color(0xFF00FF88)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _poolStat('POOL HR', '4.82 PH/s', p)),
          Expanded(child: _poolStat('MINER', '3,421', p)),
          Expanded(child: _poolStat('LUCK', '98.4%', p)),
          Expanded(child: _poolStat('BLÖCKE/TAG', '6.2', p)),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: p.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(Icons.access_time_rounded, color: p.textSecondary, size: 12),
            const SizedBox(width: 6),
            Text('Letzter Block: vor 8 min · Block #841,203 · Reward: 3.125 BTC', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
          ]),
        ),
      ]),
    );
  }

  Widget _poolStat(String label, String value, dynamic p) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
      const SizedBox(height: 3),
      Text(value, style: GoogleFonts.spaceMono(color: p.primary, fontSize: 11, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildSharesCard(dynamic p) {
    final acceptRate = _shareCount > 0 ? ((_shareCount - _rejectedShares) / _shareCount * 100) : 100;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00AAFF).withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00AAFF), size: 16),
          const SizedBox(width: 8),
          Text('SHARES', style: GoogleFonts.spaceMono(color: const Color(0xFF00AAFF), fontSize: 11, letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _shareStatItem('AKZEPTIERT', '$_shareCount', const Color(0xFF00FF88), p)),
          Expanded(child: _shareStatItem('ABGELEHNT', '$_rejectedShares', const Color(0xFFFF3358), p)),
          Expanded(child: _shareStatItem('AKZEPTRATE', '${acceptRate.toStringAsFixed(1)}%', const Color(0xFF00AAFF), p)),
          Expanded(child: _shareStatItem('DIFFICULTY', '93.7T', const Color(0xFFFFD700), p)),
        ]),
      ]),
    );
  }

  Widget _shareStatItem(String label, String value, Color color, dynamic p) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
    ]);
  }

  // ─── WORKERS ───
  Widget _buildWorkers(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.primary.withValues(alpha: 0.1)),
          ),
          child: Row(children: [
            Expanded(child: _workerSummaryItem('WORKERS', '${_gpus.where((g) => g['active'] == true).length}/${_gpus.length}', const Color(0xFF00FF88), p)),
            Expanded(child: _workerSummaryItem('GESAMT HR', '${_gpus.where((g) => g['active'] == true).fold(0.0, (s, g) => s + (g['hashrate'] as double)).toStringAsFixed(1)} TH/s', const Color(0xFF00AAFF), p)),
            Expanded(child: _workerSummaryItem('GESAMT POWER', '${_gpus.where((g) => g['active'] == true).fold(0, (s, g) => s + (g['power'] as int))} W', const Color(0xFFFF6B35), p)),
          ]),
        ),
        ..._gpus.asMap().entries.map((e) => _buildGPUCard(e.value, e.key, p)),
      ],
    );
  }

  Widget _workerSummaryItem(String label, String value, Color color, dynamic p) {
    return Column(children: [
      Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
    ]);
  }

  Widget _buildGPUCard(Map<String, dynamic> gpu, int idx, dynamic p) {
    final isActive = gpu['active'] as bool;
    final color = isActive ? const Color(0xFF00FF88) : p.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isActive ? const Color(0xFF00FF88) : p.textSecondary).withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(Icons.memory_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(gpu['name'] as String, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(gpu['mem'] as String, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
          ])),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _gpus[idx]['active'] = !isActive);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (isActive ? const Color(0xFF00FF88) : const Color(0xFFFF3358)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (isActive ? const Color(0xFF00FF88) : const Color(0xFFFF3358)).withValues(alpha: 0.3)),
              ),
              child: Text(isActive ? 'AKTIV' : 'GESTOPPT', style: GoogleFonts.spaceMono(color: isActive ? const Color(0xFF00FF88) : const Color(0xFFFF3358), fontSize: 9)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _gpuMetric('HASHRATE', '${(gpu['hashrate'] as double).toStringAsFixed(1)} TH/s', color, p),
          _gpuMetric('TEMP', '${gpu['temp']}°C', const Color(0xFFFF6B35), p),
          _gpuMetric('POWER', '${gpu['power']} W', const Color(0xFFAA44FF), p),
          _gpuMetric('FAN', '${gpu['fan']}%', const Color(0xFF00AAFF), p),
        ]),
        if (isActive) ...[
          const SizedBox(height: 10),
          // Temperature bar
          Row(children: [
            Text('Temp', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: ((gpu['temp'] as int) / 100).clamp(0.0, 1.0),
                  backgroundColor: p.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation(_tempColor(gpu['temp'] as int)),
                  minHeight: 5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${gpu['temp']}°C', style: GoogleFonts.spaceMono(color: _tempColor(gpu['temp'] as int), fontSize: 9)),
          ]),
        ],
      ]),
    );
  }

  Color _tempColor(int temp) {
    if (temp < 65) return const Color(0xFF00FF88);
    if (temp < 75) return const Color(0xFFFFD700);
    return const Color(0xFFFF3358);
  }

  Widget _gpuMetric(String label, String value, Color color, dynamic p) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
    ]));
  }

  // ─── POOLS ───
  Widget _buildPools(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.primary.withValues(alpha: 0.1)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('POOL AUSWAHL', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 6),
            Text('Wähle einen Mining-Pool. HQMLL-POOL bietet die niedrigsten Fees und höchste Stabilität.', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 11, height: 1.5)),
          ]),
        ),
        ..._pools.asMap().entries.map((e) {
          final pool = e.value;
          final isSelected = pool['selected'] as bool;
          final color = pool['color'] as Color;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                for (var pl in _pools) {
                  pl['selected'] = false;
                }
                _pools[e.key]['selected'] = true;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.03)]) : null,
                color: isSelected ? null : p.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? color.withValues(alpha: 0.4) : p.primary.withValues(alpha: 0.1), width: isSelected ? 1.5 : 1),
              ),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))),
                    child: Center(child: Text((pool['name'] as String)[0], style: GoogleFonts.spaceMono(color: color, fontSize: 16, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(pool['name'] as String, style: GoogleFonts.spaceMono(color: isSelected ? color : p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(pool['url'] as String, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
                  ])),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text('VERBUNDEN', style: GoogleFonts.spaceMono(color: color, fontSize: 8)),
                    ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _poolInfoItem('FEE', pool['fee'] as String, color, p),
                  _poolInfoItem('MINER', '${pool['miners']}', color, p),
                  _poolInfoItem('HASHRATE', pool['hashrate'] as String, color, p),
                ]),
              ]),
            ),
          );
        }),
      ],
    );
  }

  Widget _poolInfoItem(String label, String value, Color color, dynamic p) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
    ]));
  }

  // ─── CALCULATOR ───
  Widget _buildCalculator(dynamic p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.primary.withValues(alpha: 0.12)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MINING RECHNER', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 12, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text('Berechne deinen täglichen Profit', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 11)),
            const SizedBox(height: 16),
            _calcInput('Hashrate (TH/s)', _calcHashCtrl, Icons.speed_rounded, const Color(0xFF00FF88), p),
            const SizedBox(height: 10),
            _calcInput('Stromverbrauch (W)', _calcPowerCtrl, Icons.power_rounded, const Color(0xFFAA44FF), p),
            const SizedBox(height: 10),
            _calcInput('Stromkosten (\$/kWh)', _calcElecCtrl, Icons.electric_bolt_rounded, const Color(0xFFFFD700), p),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () { setState(_calculate); HapticFeedback.mediumImpact(); },
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [p.primary, p.primary.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.3), blurRadius: 12)],
                ),
                child: Center(child: Text('BERECHNEN', style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold))),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // Results
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (_calcProfit > 0 ? const Color(0xFF00FF88) : const Color(0xFFFF3358)).withValues(alpha: 0.08),
                p.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (_calcProfit > 0 ? const Color(0xFF00FF88) : const Color(0xFFFF3358)).withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ERGEBNIS (PER TAG)', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _resultItem('EINNAHMEN', '\$${_calcRevenue.toStringAsFixed(2)}', const Color(0xFF00FF88), p)),
              Container(width: 1, height: 50, color: p.primary.withValues(alpha: 0.1)),
              Expanded(child: _resultItem('STROMKOSTEN', '-\$${_calcCost.toStringAsFixed(2)}', const Color(0xFFFF3358), p)),
              Container(width: 1, height: 50, color: p.primary.withValues(alpha: 0.1)),
              Expanded(child: _resultItem('PROFIT', '\$${_calcProfit.toStringAsFixed(2)}', _calcProfit > 0 ? const Color(0xFF00FF88) : const Color(0xFFFF3358), p)),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: p.surfaceVariant, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, color: p.textSecondary, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text('Monatlich: \$${(_calcProfit * 30).toStringAsFixed(0)} · Jährlich: \$${(_calcProfit * 365).toStringAsFixed(0)}', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // BTC Price
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.primary.withValues(alpha: 0.1))),
          child: Row(children: [
            const Icon(Icons.currency_bitcoin_rounded, color: Color(0xFFFFD700), size: 20),
            const SizedBox(width: 8),
            Text('BTC \$${_btcPrice.toStringAsFixed(0)}', style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 11)),
            const SizedBox(width: 6),
            if (_btcIsLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFF00FF88).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
                child: Text('LIVE', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 7, letterSpacing: 1)),
              ),
            const Spacer(),
            Text('Netzwerk HR: 623.4 EH/s', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
          ]),
        ),
      ]),
    );
  }

  Widget _calcInput(String label, TextEditingController ctrl, IconData icon, Color color, dynamic p) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 13),
      onChanged: (_) => setState(_calculate),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: p.textSecondary, fontSize: 11),
        prefixIcon: Icon(icon, color: color, size: 18),
        filled: true,
        fillColor: p.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: p.primary.withValues(alpha: 0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: p.primary.withValues(alpha: 0.15))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color.withValues(alpha: 0.5))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Widget _resultItem(String label, String value, Color color, dynamic p) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
    ]);
  }
}

// ─── Sparkline Painter ───
class _HashrateSparklinePainter extends CustomPainter {
  final List<double> data;
  final double minVal;
  final double maxVal;
  final Color color;

  _HashrateSparklinePainter(this.data, this.minVal, this.maxVal, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final range = maxVal - minVal;
    if (range == 0) return;

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withAlpha(80), color.withAlpha(0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, gradientPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_HashrateSparklinePainter old) => old.data != data;
}
