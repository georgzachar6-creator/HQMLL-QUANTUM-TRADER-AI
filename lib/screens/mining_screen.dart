/// HQMLL – Coin Mining System Screen
/// All Coins · Hashrate · Earnings · Pool Stats
/// © 2025 Grigori Saks · HQMLL · Patent-Pending
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

class MiningScreen extends StatefulWidget {
  const MiningScreen({super.key});
  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _pulseCtrl;
  final Random _rng = Random();
  Timer? _mineTimer;

  bool _miningActive = true;
  int _tab = 0;

  // All minable coins
  late List<MinableCoin> _coins;
  double _totalHashrate = 0;
  double _dailyEarnings = 0;
  double _totalMined = 0;

  @override
  void initState() {
    super.initState();
    _glowCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _initCoins();
    _startMining();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _pulseCtrl.dispose();
    _mineTimer?.cancel();
    super.dispose();
  }

  void _initCoins() {
    _coins = [
      MinableCoin('QEMMA','HQMLL Token',  0.0847,  '12.45',  'SHA-3 Quantum',  true,  42.5,  1250.0),
      MinableCoin('BTC',  'Bitcoin',       67842.5, '1.23',   'SHA-256',         false, 180.2, 0.00012),
      MinableCoin('ETH',  'Ethereum',      3548.2,  '2.11',   'Ethash PoS',      true,  95.4,  0.0085),
      MinableCoin('LTC',  'Litecoin',      82.4,    '-0.5',   'Scrypt',          true,  22.1,  0.42),
      MinableCoin('RVN',  'Ravencoin',     0.021,   '5.3',    'KawPoW',          true,  310.5, 52.3),
      MinableCoin('XMR',  'Monero',        167.8,   '0.8',    'RandomX',         true,  4.8,   0.18),
      MinableCoin('ETC',  'Ethereum Classic', 26.4, '1.9',    'Etchash',         true,  88.6,  0.95),
      MinableCoin('FLUX', 'Flux',          0.82,    '3.1',    'ZelHash',         true,  44.2,  8.4),
      MinableCoin('ERG',  'Ergo',          1.24,    '2.8',    'Autolykos',       true,  67.3,  5.2),
      MinableCoin('KAS',  'Kaspa',         0.112,   '8.4',    'kHeavyHash',      true,  2840.0,480.0),
      MinableCoin('ZEC',  'Zcash',         28.6,    '-1.2',   'Equihash',        false, 12.4,  0.22),
      MinableCoin('DOGE', 'Dogecoin',      0.148,   '4.2',    'Scrypt',          true,  880.0, 120.0),
      MinableCoin('BCH',  'Bitcoin Cash',  456.3,   '0.6',    'SHA-256',         false, 28.3,  0.035),
      MinableCoin('XNA',  'Neurai',        0.0014,  '11.2',   'KawPoW',          true,  1200.0,4800.0),
      MinableCoin('ALPH', 'Alephium',      0.86,    '6.3',    'Blake3',          true,  3.2,   1.8),
    ];
    _computeTotals();
  }

  void _computeTotals() {
    final active = _coins.where((c) => c.isActive);
    _totalHashrate = active.fold(0.0, (s, c) => s + c.hashrate);
    _dailyEarnings = active.fold(0.0, (s, c) => s + c.minedToday * c.price);
    _totalMined    = active.fold(0.0, (s, c) => s + c.totalMined);
  }

  void _startMining() {
    _mineTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || !_miningActive) return;
      setState(() {
        for (final coin in _coins.where((c) => c.isActive)) {
          coin.hashrate   *= (1 + (_rng.nextDouble() - 0.5) * 0.04);
          coin.minedToday += coin.hashrate * 0.000001 * _rng.nextDouble();
          coin.totalMined += coin.minedToday * 0.001;
          coin.temperature = 62 + _rng.nextInt(20);
          coin.shares++;
        }
        _computeTotals();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    final mineColor = const Color(0xFFFF9100);

    return Scaffold(
      backgroundColor: p.background,
      body: Column(
        children: [
          _buildHeader(p, mineColor),
          _buildSummaryBar(p, mineColor),
          _buildTabBar(p, mineColor),
          Expanded(child: _buildContent(p, mineColor)),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic p, Color c) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.withValues(alpha: 0.12 + _glowCtrl.value * 0.06), p.background],
          ),
          border: Border(bottom: BorderSide(color: c.withValues(alpha: 0.2))),
        ),
        child: Row(children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.withValues(alpha: 0.6), width: 2),
                boxShadow: [BoxShadow(
                  color: c.withValues(alpha: _miningActive ? 0.4 + _pulseCtrl.value * 0.2 : 0.1),
                  blurRadius: 16,
                )],
              ),
              child: Icon(Icons.hardware, color: c, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MINING SYSTEM',
              style: GoogleFonts.spaceMono(color: c, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2)),
            Text('${_coins.where((c) => c.isActive).length} Coins aktiv · HQMLL Pool',
              style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
          ])),
          // Toggle Mining
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              setState(() => _miningActive = !_miningActive);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _miningActive
                    ? const Color(0xFF00E676).withValues(alpha: 0.15)
                    : p.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _miningActive
                      ? const Color(0xFF00E676).withValues(alpha: 0.6)
                      : p.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (_miningActive) Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00E676)),
                ),
                Text(_miningActive ? 'MINING' : 'GESTOPPT',
                  style: GoogleFonts.spaceMono(
                    color: _miningActive ? const Color(0xFF00E676) : p.textSecondary,
                    fontSize: 9, fontWeight: FontWeight.bold,
                  )),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSummaryBar(dynamic p, Color c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCol('HASHRATE', '${_totalHashrate.toStringAsFixed(1)} MH/s', c, p),
          Container(width: 1, height: 32, color: p.surfaceVariant),
          _statCol('HEUTE', '\$${_dailyEarnings.toStringAsFixed(2)}', const Color(0xFF00E676), p),
          Container(width: 1, height: 32, color: p.surfaceVariant),
          _statCol('GESAMT', '${_totalMined.toStringAsFixed(2)}', const Color(0xFF7B00D4), p),
          Container(width: 1, height: 32, color: p.surfaceVariant),
          _statCol('POOL', 'HQMLL', const Color(0xFF00E5FF), p),
        ],
      ),
    );
  }

  Widget _statCol(String l, String v, Color c, dynamic p) => Column(children: [
    Text(v, style: GoogleFonts.rajdhani(color: c, fontSize: 14, fontWeight: FontWeight.bold)),
    Text(l, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7)),
  ]);

  Widget _buildTabBar(dynamic p, Color c) {
    final tabs = ['ALLE COINS', 'AKTIV', 'STATS', 'POOLS'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 34,
      decoration: BoxDecoration(
        color: p.surface, borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final sel = _tab == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: sel ? c : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(child: Text(e.value,
                  style: GoogleFonts.spaceMono(
                    color: sel ? Colors.black : p.textSecondary,
                    fontSize: 7, fontWeight: FontWeight.bold,
                  ))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(dynamic p, Color c) {
    final coins = _tab == 1
        ? _coins.where((c) => c.isActive).toList()
        : _coins;
    if (_tab == 2) return _buildStatsTab(p, c);
    if (_tab == 3) return _buildPoolsTab(p, c);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: coins.length,
      itemBuilder: (_, i) => _buildCoinCard(coins[i], p, c),
    );
  }

  Widget _buildCoinCard(MinableCoin coin, dynamic p, Color accent) {
    final isPos = coin.change.startsWith('+') || !coin.change.startsWith('-');
    final changeColor = isPos ? const Color(0xFF00E676) : const Color(0xFFFF1744);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: coin.isActive
              ? const Color(0xFF00E676).withValues(alpha: 0.2)
              : p.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Row(children: [
            // Coin icon
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: coin.isActive
                    ? const Color(0xFF00E676).withValues(alpha: 0.1)
                    : p.surfaceVariant,
                border: Border.all(
                  color: coin.isActive
                      ? const Color(0xFF00E676).withValues(alpha: 0.4)
                      : p.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Center(
                child: Text(
                  coin.symbol.substring(0, min(2, coin.symbol.length)),
                  style: GoogleFonts.spaceMono(
                    color: coin.isActive ? const Color(0xFF00E676) : p.textSecondary,
                    fontSize: 10, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(coin.symbol,
                style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(coin.name,
                style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('\$${coin.price >= 1000 ? coin.price.toStringAsFixed(0) : coin.price >= 1 ? coin.price.toStringAsFixed(2) : coin.price.toStringAsFixed(4)}',
                style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              Text('${isPos ? '+' : ''}${coin.change}%',
                style: GoogleFonts.spaceMono(color: changeColor, fontSize: 9)),
            ]),
            const SizedBox(width: 8),
            // Toggle
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  coin.isActive = !coin.isActive;
                  _computeTotals();
                });
              },
              child: Container(
                width: 40, height: 22,
                decoration: BoxDecoration(
                  color: coin.isActive
                      ? const Color(0xFF00E676).withValues(alpha: 0.2)
                      : p.surfaceVariant,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: coin.isActive
                        ? const Color(0xFF00E676).withValues(alpha: 0.5)
                        : p.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Align(
                  alignment: coin.isActive ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 16, height: 16, margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: coin.isActive ? const Color(0xFF00E676) : p.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ]),
          if (coin.isActive) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _mineChip('${coin.hashrate.toStringAsFixed(1)} MH/s', Icons.speed, accent, p),
                const SizedBox(width: 6),
                _mineChip(coin.algorithm, Icons.code, const Color(0xFF7B00D4), p),
                const SizedBox(width: 6),
                _mineChip('${coin.temperature}°C', Icons.thermostat, const Color(0xFFFF9100), p),
                const SizedBox(width: 6),
                _mineChip('${coin.shares} shares', Icons.check_circle_outline, const Color(0xFF00E676), p),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Heute: ${coin.minedToday.toStringAsFixed(4)} ${coin.symbol}',
                  style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
                Text('≈ \$${(coin.minedToday * coin.price).toStringAsFixed(2)}',
                  style: GoogleFonts.rajdhani(color: const Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _mineChip(String text, IconData icon, Color color, dynamic p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 9),
        const SizedBox(width: 3),
        Text(text, style: GoogleFonts.spaceMono(color: color, fontSize: 7)),
      ]),
    );
  }

  Widget _buildStatsTab(dynamic p, Color c) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: [
        _buildStatCard('Mining Effizienz', '94.3%', Icons.bolt, const Color(0xFF00E676), p),
        _buildStatCard('Power Verbrauch', '420W', Icons.power, const Color(0xFFFF9100), p),
        _buildStatCard('Pool-Gebühr', '1.0%', Icons.percent, const Color(0xFF7B00D4), p),
        _buildStatCard('Uptime', '99.7%', Icons.timer, const Color(0xFF00E5FF), p),
        _buildStatCard('Rejected Shares', '0.3%', Icons.cancel_outlined, const Color(0xFFFF1744), p),
        _buildStatCard('Gesamt Coins', '${_coins.length}', Icons.list, c, p),
      ],
    );
  }

  Widget _buildStatCard(String l, String v, IconData icon, Color color, dynamic p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(l, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 12))),
        Text(v, style: GoogleFonts.rajdhani(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildPoolsTab(dynamic p, Color c) {
    final pools = [
      ('HQMLL Pool', 'Eigentümer · 0% Gebühr · Beste Rate', const Color(0xFF00E5FF), true),
      ('Ethermine', 'Ethereum · 1% · Global', const Color(0xFF627EEA), false),
      ('F2Pool', 'Multi-Coin · 2.5% · China', const Color(0xFFFF6B35), false),
      ('NiceHash', 'Auto-Switching · 2% · Global', const Color(0xFF00E676), false),
      ('2Miners', 'GPU Mining · 1% · EU', const Color(0xFF7B00D4), false),
      ('Unmineable', 'Alt-Coins · 1% · Global', const Color(0xFFFF9100), false),
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: pools.map((pool) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface, borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: pool.$4 ? pool.$3.withValues(alpha: 0.5) : pool.$3.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pool.$3.withValues(alpha: 0.1),
              border: Border.all(color: pool.$3.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.pool, color: pool.$3, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pool.$1, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
            Text(pool.$2, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
          ])),
          if (pool.$4)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
              ),
              child: Text('AKTIV',
                style: GoogleFonts.spaceMono(color: const Color(0xFF00E676), fontSize: 8, fontWeight: FontWeight.bold)),
            ),
        ]),
      )).toList(),
    );
  }
}

class MinableCoin {
  final String symbol, name, change, algorithm;
  double price, hashrate, minedToday, totalMined;
  bool isActive;
  int temperature, shares;

  MinableCoin(this.symbol, this.name, this.price, this.change, this.algorithm,
      this.isActive, this.hashrate, this.minedToday)
      : totalMined = minedToday * 100,
        temperature = 72,
        shares = 0;
}
