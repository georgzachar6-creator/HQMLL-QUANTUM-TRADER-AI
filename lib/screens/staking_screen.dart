// ============================================================
// STAKING & YIELD DASHBOARD – Quantum Trader v21
// DeFi Yield · Staking Pools · LP Farming · APY Tracker
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';

class StakingScreen extends StatefulWidget {
  const StakingScreen({super.key});
  @override
  State<StakingScreen> createState() => _StakingScreenState();
}

class _StakingScreenState extends State<StakingScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _countCtrl;
  Timer? _yieldTimer;
  final _rand = Random();

  int _selectedTab = 0;
  final _tabs = ['ÜBERSICHT', 'STAKING', 'LP FARMING', 'VAULT', 'VERLAUF'];

  // ── My Positions ─────────────────────────────────────────
  final List<_StakePos> _positions = [
    _StakePos(symbol: 'ETH', protocol: 'Lido', type: 'Liquid Staking',
        staked: 2.5, apy: 4.2, rewards: 0.00234, rewardSymbol: 'stETH',
        color: const Color(0xFF627EEA), emoji: '💎', lockDays: 0, chain: 'ETH',
        tvl: 22.4e9, riskLevel: 'Niedrig'),
    _StakePos(symbol: 'SOL', protocol: 'Marinade', type: 'Liquid Staking',
        staked: 45.0, apy: 7.1, rewards: 0.0842, rewardSymbol: 'mSOL',
        color: const Color(0xFF9945FF), emoji: '☀️', lockDays: 0, chain: 'SOL',
        tvl: 1.8e9, riskLevel: 'Niedrig'),
    _StakePos(symbol: 'AVAX', protocol: 'Benqi', type: 'DeFi Staking',
        staked: 120.0, apy: 9.8, rewards: 3.24, rewardSymbol: 'sAVAX',
        color: const Color(0xFFE84142), emoji: '❄️', lockDays: 14, chain: 'AVAX',
        tvl: 420e6, riskLevel: 'Mittel'),
    _StakePos(symbol: 'ATOM', protocol: 'Cosmos Hub', type: 'Validator Staking',
        staked: 200.0, apy: 14.5, rewards: 8.12, rewardSymbol: 'ATOM',
        color: const Color(0xFF6F4CA1), emoji: '⚛️', lockDays: 21, chain: 'COSMOS',
        tvl: 2.1e9, riskLevel: 'Niedrig'),
    _StakePos(symbol: 'DOT', protocol: 'Polkadot', type: 'Nominated PoS',
        staked: 500.0, apy: 12.2, rewards: 16.82, rewardSymbol: 'DOT',
        color: const Color(0xFFE6007A), emoji: '⚫', lockDays: 28, chain: 'DOT',
        tvl: 3.4e9, riskLevel: 'Niedrig'),
  ];

  // ── LP Farming Pools ────────────────────────────────────
  final List<_LPPool> _lpPools = [
    _LPPool(pair: 'ETH/USDC', protocol: 'Uniswap V3', apy: 24.8,
        tvl: 1.2e9, myLiquidity: 2450.0, earned: 48.24,
        color: const Color(0xFFFF007A), chain: 'ETH',
        fee: 0.05, impermanentLoss: -2.4),
    _LPPool(pair: 'BTC/ETH', protocol: 'Curve', apy: 18.4,
        tvl: 892e6, myLiquidity: 5200.0, earned: 124.8,
        color: const Color(0xFF00AAFF), chain: 'ETH',
        fee: 0.04, impermanentLoss: -1.8),
    _LPPool(pair: 'SOL/USDT', protocol: 'Raydium', apy: 42.6,
        tvl: 280e6, myLiquidity: 1820.0, earned: 86.5,
        color: const Color(0xFF9945FF), chain: 'SOL',
        fee: 0.25, impermanentLoss: -5.2),
    _LPPool(pair: 'AVAX/USDC', protocol: 'Trader Joe', apy: 31.2,
        tvl: 145e6, myLiquidity: 980.0, earned: 32.1,
        color: const Color(0xFFE84142), chain: 'AVAX',
        fee: 0.3, impermanentLoss: -3.6),
  ];

  // ── Vaults ───────────────────────────────────────────────
  final List<_Vault> _vaults = [
    _Vault(name: 'ETH Auto-Compound', protocol: 'Yearn Finance',
        token: 'WETH', apy: 8.4, tvl: 245e6, myDeposit: 3200.0,
        color: const Color(0xFF006AE3), emoji: '🏦', risk: 'Niedrig'),
    _Vault(name: 'USDC Yield', protocol: 'Aave V3',
        token: 'USDC', apy: 5.2, tvl: 820e6, myDeposit: 10000.0,
        color: const Color(0xFF2EBAC6), emoji: '💰', risk: 'Sehr Niedrig'),
    _Vault(name: 'BTC Boost Vault', protocol: 'Beefy Finance',
        token: 'WBTC', apy: 12.8, tvl: 92e6, myDeposit: 0,
        color: const Color(0xFFF7931A), emoji: '₿', risk: 'Mittel'),
  ];

  // ── Accumulated yield (simulated) ─────────────────────────
  double _totalDailyYield = 0;
  double _totalMonthlyYield = 0;
  double _totalYearlyYield = 0;
  double _totalStakedValue = 0;
  double _totalLpValue = 0;
  double _totalVaultValue = 0;
  double _yieldTicker = 0;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _countCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _calcTotals();

    // Live yield ticker
    _yieldTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted) return;
      setState(() {
        _yieldTicker += _totalYearlyYield / (365 * 24 * 3600 * 2.5);
        // Slight APY variation
        for (var pos in _positions) {
          pos.apy += (_rand.nextDouble() - 0.5) * 0.02;
          pos.rewards += pos.staked * (pos.apy / 100) / (365 * 24 * 3600 * 2.5);
        }
        for (var pool in _lpPools) {
          pool.earned += pool.myLiquidity * (pool.apy / 100) / (365 * 24 * 3600 * 2.5);
        }
        _calcTotals();
      });
    });
  }

  void _calcTotals() {
    _totalStakedValue = _positions.fold(0, (s, p) => s + p.staked * _estPrice(p.symbol));
    _totalLpValue = _lpPools.fold(0, (s, p) => s + p.myLiquidity);
    _totalVaultValue = _vaults.fold(0, (s, v) => s + v.myDeposit);

    final total = _totalStakedValue + _totalLpValue + _totalVaultValue;
    final stakingYield = _positions.fold(0.0, (s, p) => s + p.staked * _estPrice(p.symbol) * (p.apy / 100));
    final lpYield = _lpPools.fold(0.0, (s, p) => s + p.myLiquidity * (p.apy / 100));
    final vaultYield = _vaults.fold(0.0, (s, v) => s + v.myDeposit * (v.apy / 100));

    _totalYearlyYield = stakingYield + lpYield + vaultYield;
    _totalMonthlyYield = _totalYearlyYield / 12;
    _totalDailyYield = _totalYearlyYield / 365;
  }

  double _estPrice(String sym) {
    const prices = {'ETH': 3548.0, 'SOL': 182.0, 'AVAX': 36.8, 'ATOM': 9.4, 'DOT': 7.2};
    return prices[sym] ?? 1.0;
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _countCtrl.dispose();
    _yieldTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(p),
          _buildTabBar(p),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildOverviewTab(p),
                _buildStakingTab(p),
                _buildLPTab(p),
                _buildVaultTab(p),
                _buildHistoryTab(p),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── HEADER ───────────────────────────────────────────────
  Widget _buildHeader(dynamic p) {
    final totalValue = _totalStakedValue + _totalLpValue + _totalVaultValue;
    final avgApy = totalValue > 0
        ? _totalYearlyYield / totalValue * 100
        : 0.0;

    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(bottom: BorderSide(
            color: p.primary.withValues(alpha: 0.1 + _glowCtrl.value * 0.07),
          )),
        ),
        child: Column(children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('STAKING & YIELD', style: GoogleFonts.spaceMono(
                color: p.primary, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 2,
              )),
              Text('${_positions.length} Positionen · ${_lpPools.length} LP Pools · ${_vaults.length} Vaults', style: GoogleFonts.inter(
                color: p.textSecondary, fontSize: 10,
              )),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('\$${_fmtK(totalValue)}', style: GoogleFonts.spaceMono(
                color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.bold,
              )),
              Text('∅ APY: ${avgApy.toStringAsFixed(1)}%', style: GoogleFonts.spaceMono(
                color: const Color(0xFF00FF88), fontSize: 11,
              )),
            ]),
          ]),
          const SizedBox(height: 10),
          // Yield per period
          Row(children: [
            _buildYieldChip(p, 'TÄGLICH', _totalDailyYield, const Color(0xFF00FF88)),
            const SizedBox(width: 6),
            _buildYieldChip(p, 'MONATLICH', _totalMonthlyYield, const Color(0xFF00AAFF)),
            const SizedBox(width: 6),
            _buildYieldChip(p, 'JÄHRLICH', _totalYearlyYield, const Color(0xFFAA88FF)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildYieldChip(dynamic p, String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(label, style: GoogleFonts.spaceMono(
            color: color.withValues(alpha: 0.7), fontSize: 7, letterSpacing: 0.5,
          )),
          Text('+\$${value.toStringAsFixed(2)}', style: GoogleFonts.spaceMono(
            color: color, fontSize: 11, fontWeight: FontWeight.bold,
          )),
        ]),
      ),
    );
  }

  // ── TAB BAR ───────────────────────────────────────────────
  Widget _buildTabBar(dynamic p) {
    return Container(
      height: 36,
      color: p.surface.withValues(alpha: 0.8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _tabs.length,
        itemBuilder: (_, i) {
          final sel = _selectedTab == i;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedTab = i); },
            child: Container(
              margin: const EdgeInsets.only(right: 6, bottom: 4, top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: sel ? p.primary.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: sel ? p.primary.withValues(alpha: 0.4) : Colors.transparent),
              ),
              child: Center(child: Text(_tabs[i], style: GoogleFonts.spaceMono(
                color: sel ? p.primary : p.textSecondary,
                fontSize: 9, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              ))),
            ),
          );
        },
      ),
    );
  }

  // ── OVERVIEW TAB ─────────────────────────────────────────
  Widget _buildOverviewTab(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Live yield ticker
        _buildLiveYieldTicker(p),
        const SizedBox(height: 12),
        // Allocation pie
        _buildAllocationCard(p),
        const SizedBox(height: 12),
        // Best APYs
        _buildBestApy(p),
        const SizedBox(height: 12),
        // Quick Stats
        _buildQuickStats(p),
      ],
    );
  }

  Widget _buildLiveYieldTicker(dynamic p) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00FF88).withValues(alpha: 0.1 + _glowCtrl.value * 0.04),
              const Color(0xFF00AAFF).withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00FF88).withValues(alpha: 0.2 + _glowCtrl.value * 0.1),
          ),
        ),
        child: Column(children: [
          Text('ECHTZEIT YIELD TICKER', style: GoogleFonts.spaceMono(
            color: const Color(0xFF00FF88).withValues(alpha: 0.7), fontSize: 10, letterSpacing: 1.5,
          )),
          const SizedBox(height: 6),
          Text(
            '+\$${_yieldTicker.toStringAsFixed(6)}',
            style: GoogleFonts.spaceMono(
              color: const Color(0xFF00FF88),
              fontSize: 26, fontWeight: FontWeight.bold,
            ),
          ),
          Text('Verdient seit App-Start', style: GoogleFonts.inter(
            color: const Color(0xFF00FF88).withValues(alpha: 0.6), fontSize: 10,
          )),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildTickerStat(p, 'STAKING', '\$${_fmtK(_totalStakedValue)}', const Color(0xFF00FF88)),
            _buildTickerStat(p, 'LP FARMING', '\$${_fmtK(_totalLpValue)}', const Color(0xFF00AAFF)),
            _buildTickerStat(p, 'VAULTS', '\$${_fmtK(_totalVaultValue)}', const Color(0xFFAA88FF)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildTickerStat(dynamic p, String label, String val, Color color) {
    return Column(children: [
      Text(label, style: GoogleFonts.spaceMono(color: color.withValues(alpha: 0.6), fontSize: 8)),
      Text(val, style: GoogleFonts.spaceMono(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildAllocationCard(dynamic p) {
    final total = _totalStakedValue + _totalLpValue + _totalVaultValue;
    final stakingPct = total > 0 ? _totalStakedValue / total : 0.0;
    final lpPct = total > 0 ? _totalLpValue / total : 0.0;
    final vaultPct = total > 0 ? _totalVaultValue / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ALLOCATION', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(children: [
            Expanded(flex: (stakingPct * 100).round().clamp(1, 100),
                child: Container(height: 16, color: const Color(0xFF00FF88).withValues(alpha: 0.7))),
            Expanded(flex: (lpPct * 100).round().clamp(1, 100),
                child: Container(height: 16, color: const Color(0xFF00AAFF).withValues(alpha: 0.7))),
            Expanded(flex: (vaultPct * 100).round().clamp(1, 100),
                child: Container(height: 16, color: const Color(0xFFAA88FF).withValues(alpha: 0.7))),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _buildAllocLegend(p, 'Staking', stakingPct, const Color(0xFF00FF88)),
          _buildAllocLegend(p, 'LP Farming', lpPct, const Color(0xFF00AAFF)),
          _buildAllocLegend(p, 'Vaults', vaultPct, const Color(0xFFAA88FF)),
        ]),
      ]),
    );
  }

  Widget _buildAllocLegend(dynamic p, String label, double pct, Color color) {
    return Expanded(child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
        Text('${(pct * 100).toStringAsFixed(1)}%', style: GoogleFonts.spaceMono(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    ]));
  }

  Widget _buildBestApy(dynamic p) {
    final allOpportunities = [
      ...(_positions.map((pos) => {'name': '${pos.symbol} ${pos.type}', 'apy': pos.apy, 'protocol': pos.protocol, 'color': pos.color})),
      ...(_lpPools.map((pool) => {'name': '${pool.pair} LP', 'apy': pool.apy, 'protocol': pool.protocol, 'color': pool.color})),
      ...(_vaults.map((v) => {'name': v.name, 'apy': v.apy, 'protocol': v.protocol, 'color': v.color})),
    ]..sort((a, b) => (b['apy'] as double).compareTo(a['apy'] as double));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TOP APY OPPORTUNITÄTEN', style: GoogleFonts.spaceMono(
          color: p.primary, fontSize: 10, letterSpacing: 1,
        )),
        const SizedBox(height: 8),
        ...allOpportunities.take(5).map((op) {
          final color = op['color'] as Color;
          final apy = op['apy'] as double;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(op['name'] as String, style: GoogleFonts.inter(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                Text(op['protocol'] as String, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
              ])),
              Text('${apy.toStringAsFixed(1)}% APY', style: GoogleFonts.spaceMono(
                color: const Color(0xFF00FF88), fontSize: 12, fontWeight: FontWeight.bold,
              )),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildQuickStats(dynamic p) {
    return Row(children: [
      _buildStatCard(p, '${_positions.length + _lpPools.length + _vaults.length}', 'AKTIVE POSITIONEN', const Color(0xFF00AAFF)),
      const SizedBox(width: 8),
      _buildStatCard(p, '\$${_fmtK(_totalYearlyYield)}', 'JAHRES ERTRAG', const Color(0xFF00FF88)),
      const SizedBox(width: 8),
      _buildStatCard(p, '${(_positions.fold(0.0, (s, p) => s + p.apy) / _positions.length).toStringAsFixed(1)}%', 'Ø STAKING APY', const Color(0xFFAA88FF)),
    ]);
  }

  Widget _buildStatCard(dynamic p, String val, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(val, style: GoogleFonts.spaceMono(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7, letterSpacing: 0.3)),
      ]),
    ));
  }

  // ── STAKING TAB ───────────────────────────────────────────
  Widget _buildStakingTab(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionTitle(p, 'MEINE STAKING POSITIONEN', Icons.lock),
        const SizedBox(height: 8),
        ..._positions.map((pos) => _buildStakingCard(p, pos)),
        const SizedBox(height: 12),
        _buildAddPositionBtn(p, 'Neue Staking Position'),
      ],
    );
  }

  Widget _buildStakingCard(dynamic p, _StakePos pos) {
    final value = pos.staked * _estPrice(pos.symbol);
    final yearlyEarnings = value * (pos.apy / 100);
    final riskColor = _riskColor(pos.riskLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pos.color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: pos.color.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: pos.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pos.color.withValues(alpha: 0.3)),
              ),
              child: Center(child: Text(pos.emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${pos.symbol} – ${pos.protocol}', style: GoogleFonts.spaceMono(
                color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold,
              )),
              Text(pos.type, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
              const SizedBox(height: 2),
              Row(children: [
                _buildBadge(pos.chain, pos.color),
                const SizedBox(width: 4),
                _buildBadge(pos.riskLevel, riskColor),
                if (pos.lockDays > 0) ...[
                  const SizedBox(width: 4),
                  _buildBadge('🔒 ${pos.lockDays}T', const Color(0xFFFFAA00)),
                ],
              ]),
            ])),
            // APY Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.3)),
              ),
              child: Text('${pos.apy.toStringAsFixed(1)}%', style: GoogleFonts.spaceMono(
                color: const Color(0xFF00FF88), fontSize: 14, fontWeight: FontWeight.bold,
              )),
            ),
          ]),
        ),
        // Stats
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Row(children: [
            _buildStakeCell(p, 'GESTAKED', '${pos.staked} ${pos.symbol}', pos.color),
            _buildStakeCell(p, 'WERT', '\$${value.toStringAsFixed(0)}', p.textPrimary),
            _buildStakeCell(p, 'BELOHNUNGEN', '${pos.rewards.toStringAsFixed(4)} ${pos.rewardSymbol}', const Color(0xFF00FF88)),
          ]),
        ),
        // TVL & Yearly
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: p.primary.withValues(alpha: 0.06))),
          ),
          child: Row(children: [
            Expanded(child: Text('TVL: \$${_fmtK(pos.tvl)}', style: GoogleFonts.inter(
              color: p.textSecondary, fontSize: 10,
            ))),
            Text('Jährlich: +\$${yearlyEarnings.toStringAsFixed(0)}', style: GoogleFonts.spaceMono(
              color: const Color(0xFF00FF88), fontSize: 10,
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Belohnungen eingefordert (Demo)', style: GoogleFonts.inter(color: Colors.white)),
                  backgroundColor: pos.color,
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.3)),
                ),
                child: Text('CLAIM', style: GoogleFonts.spaceMono(
                  color: const Color(0xFF00FF88), fontSize: 8, fontWeight: FontWeight.bold,
                )),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStakeCell(dynamic p, String label, String val, Color color) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.spaceMono(
        color: p.textSecondary.withValues(alpha: 0.5), fontSize: 7, letterSpacing: 0.5,
      )),
      Text(val, style: GoogleFonts.spaceMono(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    ]));
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label, style: GoogleFonts.spaceMono(color: color, fontSize: 7)),
    );
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'Sehr Niedrig': return const Color(0xFF00FF88);
      case 'Niedrig': return const Color(0xFF00AAFF);
      case 'Mittel': return const Color(0xFFFFAA00);
      case 'Hoch': return const Color(0xFFFF3358);
      default: return const Color(0xFF888888);
    }
  }

  // ── LP FARMING TAB ────────────────────────────────────────
  Widget _buildLPTab(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionTitle(p, 'LP FARMING POOLS', Icons.water),
        const SizedBox(height: 8),
        ..._lpPools.map((pool) => _buildLPCard(p, pool)),
        const SizedBox(height: 12),
        _buildAddPositionBtn(p, 'Neue LP Position'),
      ],
    );
  }

  Widget _buildLPCard(dynamic p, _LPPool pool) {
    final isILNeg = pool.impermanentLoss < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pool.color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: pool.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text('💧', style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pool.pair, style: GoogleFonts.spaceMono(
              color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold,
            )),
            Text('${pool.protocol} · ${pool.chain} · Fee: ${pool.fee}%', style: GoogleFonts.inter(
              color: p.textSecondary, fontSize: 10,
            )),
          ])),
          Text('${pool.apy.toStringAsFixed(1)}%', style: GoogleFonts.spaceMono(
            color: const Color(0xFF00FF88), fontSize: 16, fontWeight: FontWeight.bold,
          )),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _buildStakeCell(p, 'MEINE LIQUIDITÄT', '\$${pool.myLiquidity.toStringAsFixed(0)}', pool.color),
          _buildStakeCell(p, 'VERDIENT', '\$${pool.earned.toStringAsFixed(2)}', const Color(0xFF00FF88)),
          _buildStakeCell(p, 'IMP. VERLUST', '${isILNeg ? "" : "+"}${pool.impermanentLoss.toStringAsFixed(1)}%',
              isILNeg ? const Color(0xFFFFAA00) : const Color(0xFF00FF88)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text('TVL: \$${_fmtK(pool.tvl)}', style: GoogleFonts.inter(
            color: p.textSecondary, fontSize: 10,
          ))),
          _buildActionSmall(p, 'HINZUFÜGEN', pool.color),
          const SizedBox(width: 6),
          _buildActionSmall(p, 'ENTFERNEN', const Color(0xFFFF3358)),
        ]),
      ]),
    );
  }

  // ── VAULT TAB ─────────────────────────────────────────────
  Widget _buildVaultTab(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionTitle(p, 'AUTO-COMPOUND VAULTS', Icons.savings),
        const SizedBox(height: 8),
        ..._vaults.map((v) => _buildVaultCard(p, v)),
      ],
    );
  }

  Widget _buildVaultCard(dynamic p, _Vault v) {
    final riskColor = _riskColor(v.risk);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: v.color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Row(children: [
          Text(v.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v.name, style: GoogleFonts.spaceMono(
              color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold,
            )),
            Text('${v.protocol} · ${v.token}', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
            const SizedBox(height: 4),
            _buildBadge(v.risk, riskColor),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${v.apy.toStringAsFixed(1)}%', style: GoogleFonts.spaceMono(
              color: const Color(0xFF00FF88), fontSize: 16, fontWeight: FontWeight.bold,
            )),
            Text('APY', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
          ]),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _buildStakeCell(p, 'MEIN DEPOSIT', v.myDeposit > 0 ? '\$${v.myDeposit.toStringAsFixed(0)}' : '—', v.color),
          _buildStakeCell(p, 'TVL', '\$${_fmtK(v.tvl)}', p.textSecondary),
          _buildStakeCell(p, 'JÄHRLICH', v.myDeposit > 0 ? '+\$${(v.myDeposit * v.apy / 100).toStringAsFixed(0)}' : '—', const Color(0xFF00FF88)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _buildActionBtn2(p, v.myDeposit > 0 ? 'EINZAHLEN' : 'EINZAHLEN', v.color, () {})),
          if (v.myDeposit > 0) ...[
            const SizedBox(width: 8),
            Expanded(child: _buildActionBtn2(p, 'ABHEBEN', const Color(0xFFFF3358), () {})),
          ],
        ]),
      ]),
    );
  }

  // ── HISTORY TAB ───────────────────────────────────────────
  Widget _buildHistoryTab(dynamic p) {
    final events = [
      {'type': 'CLAIM', 'desc': 'ETH Staking Reward', 'amount': '+0.00234 stETH', 'time': 'vor 2h', 'color': const Color(0xFF00FF88)},
      {'type': 'STAKE', 'desc': 'SOL gestaked', 'amount': '+45 SOL', 'time': 'vor 1T', 'color': const Color(0xFF9945FF)},
      {'type': 'CLAIM', 'desc': 'ATOM Reward', 'amount': '+2.14 ATOM', 'time': 'vor 2T', 'color': const Color(0xFF00FF88)},
      {'type': 'LP ADD', 'desc': 'ETH/USDC Liquidität', 'amount': '+\$2450', 'time': 'vor 5T', 'color': const Color(0xFF00AAFF)},
      {'type': 'CLAIM', 'desc': 'DOT Reward', 'amount': '+8.5 DOT', 'time': 'vor 1W', 'color': const Color(0xFF00FF88)},
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionTitle(p, 'YIELD VERLAUF', Icons.history),
        const SizedBox(height: 8),
        ...events.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: (e['color'] as Color).withValues(alpha: 0.15)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (e['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(e['type'] as String, style: GoogleFonts.spaceMono(
                color: e['color'] as Color, fontSize: 8, fontWeight: FontWeight.bold,
              )),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(e['desc'] as String, style: GoogleFonts.inter(
              color: p.textPrimary, fontSize: 11,
            ))),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(e['amount'] as String, style: GoogleFonts.spaceMono(
                color: e['color'] as Color, fontSize: 11,
              )),
              Text(e['time'] as String, style: GoogleFonts.inter(
                color: p.textSecondary, fontSize: 9,
              )),
            ]),
          ]),
        )),
      ],
    );
  }

  // ── HELPERS ───────────────────────────────────────────────
  Widget _buildSectionTitle(dynamic p, String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: p.primary, size: 14),
      const SizedBox(width: 6),
      Text(title, style: GoogleFonts.spaceMono(color: p.primary, fontSize: 10, letterSpacing: 1)),
    ]);
  }

  Widget _buildAddPositionBtn(dynamic p, String label) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$label (Demo)', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: p.primary,
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: p.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.primary.withValues(alpha: 0.2), style: BorderStyle.solid),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add, color: p.primary, size: 18),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.spaceMono(color: p.primary, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildActionSmall(dynamic p, String label, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(label, style: GoogleFonts.spaceMono(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildActionBtn2(dynamic p, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Center(child: Text(label, style: GoogleFonts.spaceMono(
          color: color, fontSize: 9, fontWeight: FontWeight.bold,
        ))),
      ),
    );
  }

  String _fmtK(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Models ────────────────────────────────────────────────
class _StakePos {
  final String symbol, protocol, type, rewardSymbol, chain;
  double staked, apy, rewards;
  final Color color;
  final String emoji;
  final int lockDays;
  final double tvl;
  final String riskLevel;
  _StakePos({required this.symbol, required this.protocol, required this.type,
      required this.staked, required this.apy, required this.rewards,
      required this.rewardSymbol, required this.color, required this.emoji,
      required this.lockDays, required this.chain, required this.tvl,
      required this.riskLevel});
}

class _LPPool {
  final String pair, protocol, chain;
  double apy, myLiquidity, earned;
  final double tvl, fee;
  final double impermanentLoss;
  final Color color;
  _LPPool({required this.pair, required this.protocol, required this.apy,
      required this.tvl, required this.myLiquidity, required this.earned,
      required this.color, required this.chain, required this.fee,
      required this.impermanentLoss});
}

class _Vault {
  final String name, protocol, token, emoji, risk;
  final double apy, tvl, myDeposit;
  final Color color;
  const _Vault({required this.name, required this.protocol, required this.token,
      required this.apy, required this.tvl, required this.myDeposit,
      required this.color, required this.emoji, required this.risk});
}
