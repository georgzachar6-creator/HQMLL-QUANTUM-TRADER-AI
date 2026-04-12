/// HQMLL Quantum Trader – DeFi Dashboard
/// Yield Farming · Staking · Liquidity Pools · Protocol Analytics
/// Grigori Saks · 2025
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';

// ── Models ─────────────────────────────────────────────
class StakingPool {
  final String id;
  final String protocol;
  final String asset;
  final double apy;
  final double tvl;
  final double myStaked;
  final double earned;
  final String lockPeriod;
  final Color color;

  StakingPool({
    required this.id, required this.protocol, required this.asset,
    required this.apy, required this.tvl, required this.myStaked,
    required this.earned, required this.lockPeriod, required this.color,
  });
}

class LiquidityPool {
  final String id;
  final String pair;
  final String protocol;
  final double apr;
  final double tvl;
  final double myLiquidity;
  final double feesEarned;
  final bool hasImpermanentLoss;
  final Color color;

  LiquidityPool({
    required this.id, required this.pair, required this.protocol,
    required this.apr, required this.tvl, required this.myLiquidity,
    required this.feesEarned, required this.hasImpermanentLoss,
    required this.color,
  });
}

// ═══════════════════════════════════════════════════════
// DEFI SCREEN
// ═══════════════════════════════════════════════════════
class DeFiScreen extends StatefulWidget {
  const DeFiScreen({super.key});
  @override
  State<DeFiScreen> createState() => _DeFiScreenState();
}

class _DeFiScreenState extends State<DeFiScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _glowCtrl;
  Timer? _yieldTimer;
  final Random _rng = Random(55);

  final List<StakingPool> _stakingPools = [];
  final List<LiquidityPool> _liquidityPools = [];

  double _totalStaked = 0;
  double _totalEarned = 0;
  double _totalTvl    = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _initPools();
    _startYieldUpdates();
    _calcStats();
  }

  void _initPools() {
    _stakingPools.addAll([
      StakingPool(id: 's1', protocol: 'Ethereum 2.0', asset: 'ETH',
          apy: 4.2, tvl: 48.6e9, myStaked: 2.5, earned: 0.0842,
          lockPeriod: 'Flexibel', color: const Color(0xFF627EEA)),
      StakingPool(id: 's2', protocol: 'Lido Finance', asset: 'stETH',
          apy: 4.0, tvl: 24.2e9, myStaked: 1.8, earned: 0.0612,
          lockPeriod: 'Flexibel', color: const Color(0xFF00A3FF)),
      StakingPool(id: 's3', protocol: 'QEMMA Network', asset: 'QEMMA',
          apy: 42.0, tvl: 12.4e6, myStaked: 5000.0, earned: 142.8,
          lockPeriod: '30 Tage', color: const Color(0xFF00D4FF)),
      StakingPool(id: 's4', protocol: 'Aave v3', asset: 'USDC',
          apy: 5.8, tvl: 8.4e9, myStaked: 1500.0, earned: 28.4,
          lockPeriod: 'Flexibel', color: const Color(0xFF2EBAC6)),
      StakingPool(id: 's5', protocol: 'Cosmos Hub', asset: 'ATOM',
          apy: 18.5, tvl: 2.8e9, myStaked: 120.0, earned: 8.4,
          lockPeriod: '21 Tage', color: const Color(0xFF6F7390)),
      StakingPool(id: 's6', protocol: 'Solana', asset: 'SOL',
          apy: 6.8, tvl: 14.2e9, myStaked: 8.4, earned: 0.412,
          lockPeriod: '2-3 Tage', color: const Color(0xFF9945FF)),
    ]);

    _liquidityPools.addAll([
      LiquidityPool(id: 'l1', pair: 'ETH/USDC', protocol: 'Uniswap v3',
          apr: 24.8, tvl: 1.84e9, myLiquidity: 2840.0, feesEarned: 42.8,
          hasImpermanentLoss: false, color: const Color(0xFFFF007A)),
      LiquidityPool(id: 'l2', pair: 'BTC/ETH', protocol: 'Curve Finance',
          apr: 12.4, tvl: 3.2e9, myLiquidity: 1420.0, feesEarned: 18.4,
          hasImpermanentLoss: true, color: const Color(0xFF0066FF)),
      LiquidityPool(id: 'l3', pair: 'QEMMA/USDT', protocol: 'PancakeSwap',
          apr: 84.0, tvl: 2.4e6, myLiquidity: 500.0, feesEarned: 28.2,
          hasImpermanentLoss: false, color: const Color(0xFFD1884F)),
      LiquidityPool(id: 'l4', pair: 'SOL/USDC', protocol: 'Raydium',
          apr: 18.6, tvl: 840e6, myLiquidity: 980.0, feesEarned: 12.4,
          hasImpermanentLoss: false, color: const Color(0xFF9945FF)),
      LiquidityPool(id: 'l5', pair: 'BNB/BUSD', protocol: 'PancakeSwap',
          apr: 9.4, tvl: 1.2e9, myLiquidity: 340.0, feesEarned: 4.8,
          hasImpermanentLoss: false, color: const Color(0xFFF3BA2F)),
    ]);
  }

  void _calcStats() {
    _totalStaked = _stakingPools.fold(0.0, (s, p) => s + p.myStaked);
    _totalEarned = _stakingPools.fold(0.0, (s, p) => s + p.earned)
        + _liquidityPools.fold(0.0, (s, p) => s + p.feesEarned);
    _totalTvl = _stakingPools.fold(0.0, (s, p) => s + p.tvl);
  }

  void _startYieldUpdates() {
    _yieldTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _stakingPools.length; i++) {
          final pool = _stakingPools[i];
          final increment = pool.myStaked * pool.apy / 100 / 365 / 24 / 720;
          _stakingPools[i] = StakingPool(
            id: pool.id, protocol: pool.protocol, asset: pool.asset,
            apy: pool.apy + (_rng.nextDouble() - 0.5) * 0.1,
            tvl: pool.tvl + (_rng.nextDouble() - 0.5) * pool.tvl * 0.001,
            myStaked: pool.myStaked, earned: pool.earned + increment,
            lockPeriod: pool.lockPeriod, color: pool.color,
          );
        }
        _calcStats();
      });
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _glowCtrl.dispose();
    _yieldTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: p.background,
      body: Column(
        children: [
          _buildHeader(p),
          _buildOverviewBar(p),
          _buildTabBar(p),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildOverviewTab(p),
                _buildStakingTab(p),
                _buildLiquidityTab(p),
                _buildProtocolsTab(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────
  Widget _buildHeader(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.surface, p.background],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF00FFB2).withValues(alpha: 0.35))),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, child) => Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFF00FFB2), Color(0xFF00D4FF)]),
                boxShadow: [BoxShadow(
                    color: const Color(0xFF00FFB2)
                        .withValues(alpha: 0.3 + _glowCtrl.value * 0.3),
                    blurRadius: 12 + _glowCtrl.value * 8)],
              ),
              child: child,
            ),
            child: const Center(
                child: Icon(Icons.account_balance, color: Colors.white, size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DeFi DASHBOARD',
                    style: GoogleFonts.orbitron(
                        color: p.textPrimary, fontSize: 15,
                        fontWeight: FontWeight.w900, letterSpacing: 2)),
                Text('Staking · Farming · Liquidity Pools',
                    style: TextStyle(color: p.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF00FFB2).withValues(alpha: 0.12),
              border: Border.all(
                  color: const Color(0xFF00FFB2).withValues(alpha: 0.4)),
            ),
            child: Text('+\$${_totalEarned.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Color(0xFF00FFB2),
                    fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Overview bar ──────────────────────────────────
  Widget _buildOverviewBar(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: p.surface,
      child: Row(
        children: [
          _overviewChip('Mein Staking', _formatValue(_totalStaked),
              const Color(0xFF00FFB2), p),
          const SizedBox(width: 8),
          _overviewChip('Earned', '+\$${_totalEarned.toStringAsFixed(2)}',
              Colors.greenAccent, p),
          const SizedBox(width: 8),
          _overviewChip('Total TVL', _formatBig(_totalTvl),
              Colors.blueAccent, p),
        ],
      ),
    );
  }

  Widget _overviewChip(String label, String value, Color color, QuantumPalette p) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(
                color: color, fontSize: 8, fontWeight: FontWeight.w700)),
            Text(value, style: TextStyle(
                color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────
  Widget _buildTabBar(QuantumPalette p) {
    return Container(
      color: p.surface,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: const Color(0xFF00FFB2),
        indicatorWeight: 2,
        labelColor: const Color(0xFF00FFB2),
        unselectedLabelColor: p.textSecondary,
        labelStyle: const TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        tabs: const [
          Tab(text: 'ÜBERSICHT',  icon: Icon(Icons.dashboard,       size: 15)),
          Tab(text: 'STAKING',    icon: Icon(Icons.lock_outline,     size: 15)),
          Tab(text: 'LIQUIDITY',  icon: Icon(Icons.water_drop,       size: 15)),
          Tab(text: 'PROTOCOLS',  icon: Icon(Icons.hub,              size: 15)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // OVERVIEW TAB
  // ══════════════════════════════════════════════════
  Widget _buildOverviewTab(QuantumPalette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildYieldChart(p),
          const SizedBox(height: 12),
          _buildAllocationChart(p),
          const SizedBox(height: 12),
          _buildTopYieldOpportunities(p),
        ],
      ),
    );
  }

  Widget _buildYieldChart(QuantumPalette p) {
    final spots = List.generate(30, (i) {
      return FlSpot(i.toDouble(),
          100 + i * 3.2 + _rng.nextDouble() * 15);
    });
    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: p.surface,
        border: Border.all(
            color: const Color(0xFF00FFB2).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EARNINGS VERLAUF (30 TAGE)',
              style: GoogleFonts.orbitron(
                  color: const Color(0xFF00FFB2), fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF00FFB2),
                  barWidth: 2.5,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF00FFB2).withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationChart(QuantumPalette p) {
    final items = [
      ('ETH Staking', 2.5, const Color(0xFF627EEA)),
      ('QEMMA Pool', 5000.0, const Color(0xFF00D4FF)),
      ('USDC Lending', 1500.0, const Color(0xFF2EBAC6)),
      ('SOL Staking', 8.4, const Color(0xFF9945FF)),
      ('Liquidity', 6080.0, const Color(0xFFFF007A)),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: p.surface,
        border: Border.all(
            color: p.textSecondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ALLOKATION',
              style: GoogleFonts.orbitron(
                  color: p.textPrimary, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 12),
          ...items.map((item) {
            final total = items.fold(0.0, (s, e) => s + e.$2);
            final pct = item.$2 / total * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.$1, style: TextStyle(
                          color: p.textSecondary, fontSize: 11)),
                      Text('${pct.toStringAsFixed(1)}%', style: TextStyle(
                          color: item.$3, fontWeight: FontWeight.w700, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: item.$3.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(item.$3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopYieldOpportunities(QuantumPalette p) {
    final all = [
      ..._stakingPools.map((s) => (s.asset, s.protocol, s.apy, s.color)),
      ..._liquidityPools.map((l) => (l.pair, l.protocol, l.apr, l.color)),
    ]..sort((a, b) => b.$3.compareTo(a.$3));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: p.surface,
        border: Border.all(
            color: Colors.greenAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('TOP YIELD OPPORTUNITIES', Icons.trending_up, Colors.greenAccent, p),
          const SizedBox(height: 10),
          ...all.take(6).map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.$4.withValues(alpha: 0.15),
                      ),
                      child: Center(child: Text(
                        item.$1.length > 4 ? item.$1.substring(0, 4) : item.$1,
                        style: TextStyle(
                            color: item.$4, fontSize: 8, fontWeight: FontWeight.w900),
                      )),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$1, style: TextStyle(
                              color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                          Text(item.$2, style: TextStyle(
                              color: p.textSecondary, fontSize: 10)),
                        ],
                      ),
                    ),
                    Text('${item.$3.toStringAsFixed(1)}% APY',
                        style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w800, fontSize: 12)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // STAKING TAB
  // ══════════════════════════════════════════════════
  Widget _buildStakingTab(QuantumPalette p) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _stakingPools.length,
      itemBuilder: (_, i) => _buildStakingCard(_stakingPools[i], p),
    );
  }

  Widget _buildStakingCard(StakingPool pool, QuantumPalette p) {
    final hasPosition = pool.myStaked > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: p.surface,
        border: Border.all(color: pool.color.withValues(alpha: 0.3)),
        boxShadow: hasPosition
            ? [BoxShadow(color: pool.color.withValues(alpha: 0.1), blurRadius: 15)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pool.color.withValues(alpha: 0.15),
                  border: Border.all(color: pool.color.withValues(alpha: 0.5)),
                ),
                child: Center(child: Text(
                  pool.asset.length > 3 ? pool.asset.substring(0, 3) : pool.asset,
                  style: TextStyle(color: pool.color, fontWeight: FontWeight.w900, fontSize: 11),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pool.protocol, style: TextStyle(
                        color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('Lock: ${pool.lockPeriod}', style: TextStyle(
                        color: p.textSecondary, fontSize: 10)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${pool.apy.toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: Colors.greenAccent, fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  const Text('APY', style: TextStyle(
                      color: Colors.greenAccent, fontSize: 9)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _poolStat('Mein Stake', '${pool.myStaked.toStringAsFixed(4)} ${pool.asset}', pool.color, p)),
              Expanded(child: _poolStat('Earned', '+${pool.earned.toStringAsFixed(4)}', Colors.greenAccent, p)),
              Expanded(child: _poolStat('TVL', _formatBig(pool.tvl), Colors.blueAccent, p)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showAction('Stake', pool.asset, pool.color),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: pool.color.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('STAKE',
                      style: TextStyle(color: pool.color, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: hasPosition
                      ? () => _showAction('Unstake', pool.asset, pool.color)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pool.color.withValues(alpha: 0.2),
                    foregroundColor: pool.color,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('UNSTAKE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
              if (hasPosition) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showAction('Claim', pool.asset, Colors.greenAccent),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.withValues(alpha: 0.15),
                      foregroundColor: Colors.greenAccent,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('CLAIM',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _poolStat(String label, String value, Color color, QuantumPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: p.textSecondary, fontSize: 9)),
        Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    );
  }

  void _showAction(String action, String asset, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$action $asset wird ausgeführt...'),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    ));
  }

  // ══════════════════════════════════════════════════
  // LIQUIDITY TAB
  // ══════════════════════════════════════════════════
  Widget _buildLiquidityTab(QuantumPalette p) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _liquidityPools.length,
      itemBuilder: (_, i) => _buildLiquidityCard(_liquidityPools[i], p),
    );
  }

  Widget _buildLiquidityCard(LiquidityPool pool, QuantumPalette p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: p.surface,
        border: Border.all(color: pool.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: pool.color.withValues(alpha: 0.15),
                  border: Border.all(color: pool.color.withValues(alpha: 0.4)),
                ),
                child: Text(pool.pair, style: TextStyle(
                    color: pool.color, fontWeight: FontWeight.w900, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(pool.protocol, style: TextStyle(
                    color: p.textSecondary, fontSize: 11)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${pool.apr.toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: Colors.greenAccent, fontSize: 16,
                          fontWeight: FontWeight.w900)),
                  const Text('APR', style: TextStyle(
                      color: Colors.greenAccent, fontSize: 9)),
                ],
              ),
            ],
          ),
          if (pool.hasImpermanentLoss) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.orangeAccent.withValues(alpha: 0.1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber, color: Colors.orangeAccent, size: 12),
                  SizedBox(width: 4),
                  Text('Impermanent Loss möglich', style: TextStyle(
                      color: Colors.orangeAccent, fontSize: 9)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _poolStat('Meine Liquidität',
                  '\$${pool.myLiquidity.toStringAsFixed(2)}', pool.color, p)),
              Expanded(child: _poolStat('Fees Earned',
                  '+\$${pool.feesEarned.toStringAsFixed(2)}', Colors.greenAccent, p)),
              Expanded(child: _poolStat('Pool TVL',
                  _formatBig(pool.tvl), Colors.blueAccent, p)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showAction('Add Liquidity to', pool.pair, pool.color),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pool.color.withValues(alpha: 0.2),
                    foregroundColor: pool.color,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('+ ADD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showAction('Remove Liquidity from', pool.pair, Colors.redAccent),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('− REMOVE', style: TextStyle(
                      color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // PROTOCOLS TAB
  // ══════════════════════════════════════════════════
  Widget _buildProtocolsTab(QuantumPalette p) {
    final protocols = [
      ('Uniswap v3', 'DEX · Ethereum', 5.84e9, const Color(0xFFFF007A), Icons.swap_horiz),
      ('Aave v3', 'Lending · Multi-Chain', 8.4e9, const Color(0xFF2EBAC6), Icons.account_balance),
      ('Curve Finance', 'Stablecoin AMM', 3.2e9, const Color(0xFF0066FF), Icons.show_chart),
      ('Lido Finance', 'Liquid Staking', 24.2e9, const Color(0xFF00A3FF), Icons.lock),
      ('PancakeSwap', 'DEX · BNB Chain', 2.1e9, const Color(0xFFD1884F), Icons.cake),
      ('Raydium', 'DEX · Solana', 840e6, const Color(0xFF9945FF), Icons.speed),
      ('QEMMA Protocol', 'AI DeFi · HQMLL', 12.4e6, const Color(0xFF00D4FF), Icons.auto_awesome),
      ('Compound', 'Lending · Ethereum', 2.8e9, const Color(0xFF00D395), Icons.account_balance_wallet),
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: protocols.map((proto) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: p.surface,
          border: Border.all(color: proto.$4.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: proto.$4.withValues(alpha: 0.15),
              ),
              child: Icon(proto.$5, color: proto.$4, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(proto.$1, style: TextStyle(
                      color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(proto.$2, style: TextStyle(color: p.textSecondary, fontSize: 10)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('TVL', style: TextStyle(color: p.textSecondary, fontSize: 9)),
                Text(_formatBig(proto.$3), style: TextStyle(
                    color: proto.$4, fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  // ── Helpers ────────────────────────────────────────
  String _formatBig(double v) {
    if (v >= 1e12) return '\$${(v / 1e12).toStringAsFixed(2)}T';
    if (v >= 1e9)  return '\$${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6)  return '\$${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3)  return '\$${(v / 1e3).toStringAsFixed(2)}K';
    return '\$${v.toStringAsFixed(2)}';
  }

  String _formatValue(double v) {
    if (v >= 1e6)  return '\$${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3)  return '\$${(v / 1e3).toStringAsFixed(2)}K';
    return '\$${v.toStringAsFixed(2)}';
  }

  Widget _label(String t, IconData icon, Color color, QuantumPalette p) {
    return Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 6),
      Text(t, style: GoogleFonts.orbitron(
          color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
    ]);
  }
}
