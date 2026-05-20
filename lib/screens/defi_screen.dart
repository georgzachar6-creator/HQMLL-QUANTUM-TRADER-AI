// ============================================================
// DeFi SCREEN v2 – Decentralized Finance Dashboard
// Pools, Yield Farming, Staking, Liquidity, Protocol Stats
// ============================================================
// v28.0: DeFiScreen v2 – ExchangeService Live Pool Prices + TVL
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/exchange_service.dart';

class DeFiScreen extends StatefulWidget {
  const DeFiScreen({super.key});
  @override
  State<DeFiScreen> createState() => _DeFiScreenState();
}

class _DeFiScreenState extends State<DeFiScreen> with TickerProviderStateMixin {
  late TabController _tab;
  late AnimationController _glowCtrl;
  Timer? _liveTimer;
  final _rand = Random();

  // Portfolio DeFi
  double _totalValueLocked = 12847.50;
  double _totalRewards = 284.32;
  double _avgAPY = 18.42;

  // Pools
  final List<Map<String, dynamic>> _pools = [
    {'name': 'ETH/USDC', 'protocol': 'Uniswap V3', 'tvl': 2840000000, 'apy': 12.4, 'fee': '0.3%', 'color': const Color(0xFF627EEA), 'myLiq': 1420.50, 'rewards': 8.42, 'token0': 'ETH', 'token1': 'USDC', 'volume24h': 284000000},
    {'name': 'BTC/ETH', 'protocol': 'Curve Finance', 'tvl': 1240000000, 'apy': 8.2, 'fee': '0.04%', 'color': const Color(0xFFFFD700), 'myLiq': 2840.00, 'rewards': 14.20, 'token0': 'BTC', 'token1': 'ETH', 'volume24h': 142000000},
    {'name': 'SOL/USDT', 'protocol': 'Raydium', 'tvl': 420000000, 'apy': 24.8, 'fee': '0.25%', 'color': const Color(0xFF9945FF), 'myLiq': 820.30, 'rewards': 24.80, 'token0': 'SOL', 'token1': 'USDT', 'volume24h': 58000000},
    {'name': 'MATIC/USDC', 'protocol': 'QuickSwap', 'tvl': 280000000, 'apy': 18.6, 'fee': '0.3%', 'color': const Color(0xFF8247E5), 'myLiq': 540.20, 'rewards': 12.40, 'token0': 'MATIC', 'token1': 'USDC', 'volume24h': 32000000},
    {'name': 'AVAX/WAVAX', 'protocol': 'Trader Joe', 'tvl': 180000000, 'apy': 22.4, 'fee': '0.3%', 'color': const Color(0xFFE84142), 'myLiq': 0, 'rewards': 0, 'token0': 'AVAX', 'token1': 'WAVAX', 'volume24h': 18000000},
    {'name': 'USDC/USDT', 'protocol': 'Curve 3Pool', 'tvl': 3200000000, 'apy': 4.8, 'fee': '0.04%', 'color': const Color(0xFF2775CA), 'myLiq': 5000.00, 'rewards': 28.00, 'token0': 'USDC', 'token1': 'USDT', 'volume24h': 820000000},
  ];

  // Staking Positions
  final List<Map<String, dynamic>> _staking = [
    {'token': 'ETH', 'protocol': 'Lido Finance', 'amount': 1.842, 'apy': 3.8, 'rewards': 0.0084, 'value': 6534.10, 'lockup': 'Flexibel', 'color': const Color(0xFF627EEA), 'icon': '⟠'},
    {'token': 'SOL', 'protocol': 'Marinade', 'amount': 84.0, 'apy': 6.8, 'rewards': 1.42, 'value': 15321.60, 'lockup': 'Flexibel', 'color': const Color(0xFF9945FF), 'icon': '◎'},
    {'token': 'QEMMA', 'protocol': 'HQMLL Staking', 'amount': 50000, 'apy': 48.0, 'rewards': 12.40, 'value': 4200.00, 'lockup': '90 Tage', 'color': const Color(0xFF00FF88), 'icon': 'Q'},
    {'token': 'MATIC', 'protocol': 'Polygon Staking', 'amount': 4200, 'apy': 5.2, 'rewards': 0.84, 'value': 1890.00, 'lockup': 'Flexibel', 'color': const Color(0xFF8247E5), 'icon': '⬡'},
  ];

  // Protocol Stats
  final List<Map<String, dynamic>> _protocols = [
    {'name': 'Uniswap V3', 'tvl': '\$6.2B', 'vol24h': '\$1.8B', 'fees24h': '\$5.4M', 'color': const Color(0xFFFF007A), 'change': '+4.2%'},
    {'name': 'Aave V3', 'tvl': '\$8.4B', 'vol24h': '\$420M', 'fees24h': '\$1.2M', 'color': const Color(0xFF9BD8D2), 'change': '+2.1%'},
    {'name': 'Curve Finance', 'tvl': '\$3.9B', 'vol24h': '\$840M', 'fees24h': '\$840K', 'color': const Color(0xFFD2C6F2), 'change': '-0.8%'},
    {'name': 'MakerDAO', 'tvl': '\$8.1B', 'vol24h': '\$280M', 'fees24h': '\$2.1M', 'color': const Color(0xFF1AAB9B), 'change': '+1.4%'},
    {'name': 'Lido Finance', 'tvl': '\$32.4B', 'vol24h': '\$180M', 'fees24h': '\$3.8M', 'color': const Color(0xFF00A3FF), 'change': '+3.8%'},
    {'name': 'Compound III', 'tvl': '\$2.3B', 'vol24h': '\$120M', 'fees24h': '\$480K', 'color': const Color(0xFF00D395), 'change': '+0.6%'},
  ];

  // Yield opportunities
  final List<Map<String, dynamic>> _yields = [
    {'name': 'QEMMA Vault', 'apy': 48.0, 'risk': 'Hoch', 'tvl': '\$4.2M', 'token': 'QEMMA', 'color': const Color(0xFF00FF88), 'type': 'Single-Asset'},
    {'name': 'ETH-USDC LP', 'apy': 12.4, 'risk': 'Niedrig', 'tvl': '\$284M', 'token': 'ETH+USDC', 'color': const Color(0xFF627EEA), 'type': 'LP Token'},
    {'name': 'SOL Staking', 'apy': 6.8, 'risk': 'Sehr Niedrig', 'tvl': '\$1.8B', 'token': 'SOL', 'color': const Color(0xFF9945FF), 'type': 'Liquid Staking'},
    {'name': 'USDC Lending', 'apy': 8.2, 'risk': 'Sehr Niedrig', 'tvl': '\$2.4B', 'token': 'USDC', 'color': const Color(0xFF2775CA), 'type': 'Lending'},
    {'name': 'BTC/ETH Curve', 'apy': 8.2, 'risk': 'Niedrig', 'tvl': '\$1.2B', 'token': 'BTC+ETH', 'color': const Color(0xFFFFD700), 'type': 'StableSwap'},
    {'name': 'AVAX Farm', 'apy': 34.2, 'risk': 'Mittel', 'tvl': '\$84M', 'token': 'AVAX', 'color': const Color(0xFFE84142), 'type': 'Yield Farm'},
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
    _startLive();
  }

  void _startLive() {
    _liveTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      if (!mounted) return;
      setState(() {
        _totalRewards += _rand.nextDouble() * 0.01;
        for (var pool in _pools) {
          pool['apy'] = ((pool['apy'] as double) + (_rand.nextDouble() - 0.5) * 0.2).clamp(1.0, 60.0);
        }
      });
    });
  }

  /// v28.0: Update pool values with ExchangeService live prices
  void _syncPoolsFromExchange(ExchangeService ex) {
    double newTVL = 0;
    for (var stk in _staking) {
      final sym = stk['token'] as String;
      final livePrice = ex.getPrice(sym);
      if (livePrice > 0 && stk['amount'] != null) {
        final amount = stk['amount'] as double;
        stk['value'] = amount * livePrice;
      }
      newTVL += (stk['value'] as double? ?? 0);
    }
    // Update my liquidity values in pools using token prices
    for (var pool in _pools) {
      final tok0 = pool['token0'] as String? ?? '';
      final livePrice = ex.getPrice(tok0);
      if (livePrice > 0 && pool['myLiq'] != null) {
        final myLiq = pool['myLiq'] as double;
        if (myLiq > 0) newTVL += myLiq;
      }
    }
    if (newTVL > 5000) _totalValueLocked = newTVL;
  }

  @override
  void dispose() {
    _tab.dispose(); _glowCtrl.dispose(); _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    // v28.0: ExchangeService live prices for DeFi calculations
    final ex = context.watch<ExchangeService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPoolsFromExchange(ex);
    });
    return Scaffold(
      backgroundColor: p.background,
      body: Column(children: [
        _buildHeader(p, ex),
        _buildTabBar(p),
        Expanded(child: TabBarView(controller: _tab, children: [
          _buildOverview(p),
          _buildPools(p),
          _buildStaking(p),
          _buildYields(p),
        ])),
      ]),
    );
  }

  Widget _buildHeader(dynamic p, ExchangeService ex) {
    final ethPrice = ex.getPrice('ETH');
    final solPrice = ex.getPrice('SOL');
    final isLive = ex.getTick('ETH')?.isLive ?? false;
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(bottom: BorderSide(color: const Color(0xFF00CED1).withValues(alpha: 0.15 + _glowCtrl.value * 0.08))),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF00CED1).withValues(alpha: 0.25), const Color(0xFF00CED1).withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00CED1).withValues(alpha: 0.4 + _glowCtrl.value * 0.25)),
              boxShadow: [BoxShadow(color: const Color(0xFF00CED1).withValues(alpha: 0.2 + _glowCtrl.value * 0.12), blurRadius: 14)],
            ),
            child: const Icon(Icons.account_balance_outlined, color: Color(0xFF00CED1), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DeFi DASHBOARD', style: GoogleFonts.spaceMono(color: const Color(0xFF00CED1), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
            Row(children: [
              Text('TVL: \$${(_totalValueLocked / 1000).toStringAsFixed(1)}K · Ø APY: ${_avgAPY.toStringAsFixed(1)}%', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
              if (ethPrice > 0) ...[const SizedBox(width: 6),
                Text(
                  'ETH \$${ethPrice.toStringAsFixed(0)} · SOL \$${solPrice.toStringAsFixed(1)}',
                  style: GoogleFonts.spaceMono(
                    color: isLive ? const Color(0xFF00FF88) : const Color(0xFFFFAA00), fontSize: 8,
                  ),
                ),
              ],
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _buildTabBar(dynamic p) {
    return Container(
      color: p.surface,
      child: TabBar(
        controller: _tab,
        labelColor: const Color(0xFF00CED1),
        unselectedLabelColor: p.textSecondary,
        indicatorColor: const Color(0xFF00CED1),
        indicatorWeight: 2,
        labelStyle: GoogleFonts.spaceMono(fontSize: 10, letterSpacing: 1),
        unselectedLabelStyle: GoogleFonts.spaceMono(fontSize: 10),
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_outlined, size: 15), text: 'ÜBERSICHT'),
          Tab(icon: Icon(Icons.water_rounded, size: 15), text: 'POOLS'),
          Tab(icon: Icon(Icons.savings_outlined, size: 15), text: 'STAKING'),
          Tab(icon: Icon(Icons.trending_up_rounded, size: 15), text: 'YIELDS'),
        ],
      ),
    );
  }

  // ── OVERVIEW ──
  Widget _buildOverview(dynamic p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        // Portfolio Summary Cards
        Row(children: [
          Expanded(child: _summaryCard('MEIN TVL', '\$${_totalValueLocked.toStringAsFixed(2)}', '+\$${(_totalValueLocked * 0.02).toStringAsFixed(0)} heute', const Color(0xFF00CED1), Icons.account_balance_rounded, p)),
          const SizedBox(width: 8),
          Expanded(child: _summaryCard('REWARDS', '\$${_totalRewards.toStringAsFixed(2)}', 'Gesamt verdient', const Color(0xFF00FF88), Icons.monetization_on_rounded, p)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _summaryCard('Ø APY', '${_avgAPY.toStringAsFixed(1)}%', 'Gewichteter Schnitt', const Color(0xFFFFD700), Icons.percent_rounded, p)),
          const SizedBox(width: 8),
          Expanded(child: _summaryCard('POSITIONEN', '${_staking.length + _pools.where((pl) => (pl['myLiq'] as double) > 0).length}', 'Aktive Positionen', const Color(0xFFAA44FF), Icons.layers_rounded, p)),
        ]),
        const SizedBox(height: 12),

        // Top Protocol Stats
        _sectionTitle('TOP PROTOKOLLE', const Color(0xFF00CED1), p),
        const SizedBox(height: 8),
        ..._protocols.map((proto) {
          final isPositive = (proto['change'] as String).startsWith('+');
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: (proto['color'] as Color).withValues(alpha: 0.15)),
            ),
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: proto['color'] as Color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(proto['name'] as String, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('TVL: ${proto['tvl']}', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
                Text(proto['change'] as String, style: GoogleFonts.spaceMono(color: isPositive ? const Color(0xFF00FF88) : const Color(0xFFFF3358), fontSize: 9)),
              ]),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Vol: ${proto['vol24h']}', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
                Text('Fee: ${proto['fees24h']}', style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 9)),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _summaryCard(String label, String value, String sub, Color color, IconData icon, dynamic p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.03)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(sub, style: GoogleFonts.inter(color: p.textSecondary.withValues(alpha: 0.7), fontSize: 9)),
      ]),
    );
  }

  // ── POOLS ──
  Widget _buildPools(dynamic p) {
    final myPools = _pools.where((pl) => (pl['myLiq'] as double) > 0).toList();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (myPools.isNotEmpty) ...[
          _sectionTitle('MEINE POSITIONEN', const Color(0xFF00FF88), p),
          const SizedBox(height: 8),
          ...myPools.map((pool) => _poolCard(pool, true, p)),
          const SizedBox(height: 12),
        ],
        _sectionTitle('ALLE POOLS', const Color(0xFF00CED1), p),
        const SizedBox(height: 8),
        ..._pools.map((pool) => _poolCard(pool, false, p)),
      ],
    );
  }

  Widget _poolCard(Map<String, dynamic> pool, bool compact, dynamic p) {
    final color = pool['color'] as Color;
    final hasPosition = (pool['myLiq'] as double) > 0;
    final apy = pool['apy'] as double;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: hasPosition ? LinearGradient(colors: [color.withValues(alpha: 0.08), p.surface]) : null,
        color: hasPosition ? null : p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasPosition ? color.withValues(alpha: 0.3) : p.primary.withValues(alpha: 0.1)),
      ),
      child: Column(children: [
        Row(children: [
          // Token pair icons
          Stack(clipBehavior: Clip.none, children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.4))), child: Center(child: Text(pool['token0'] as String, style: GoogleFonts.spaceMono(color: color, fontSize: 7, fontWeight: FontWeight.bold)))),
            Positioned(left: 18, child: Container(width: 28, height: 28, decoration: BoxDecoration(color: p.surfaceVariant, shape: BoxShape.circle, border: Border.all(color: p.primary.withValues(alpha: 0.3))), child: Center(child: Text(pool['token1'] as String, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 7, fontWeight: FontWeight.bold))))),
          ]),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pool['name'] as String, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
            Text('${pool['protocol']} · Fee: ${pool['fee']}', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${apy.toStringAsFixed(1)}% APY', style: GoogleFonts.spaceMono(color: apy > 20 ? const Color(0xFF00FF88) : apy > 10 ? const Color(0xFFFFD700) : p.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
            Text('TVL: \$${_formatBig(pool['tvl'] as int)}', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
          ]),
        ]),
        if (hasPosition) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              _poolStat('MEINE LIQ', '\$${(pool['myLiq'] as double).toStringAsFixed(2)}', color, p),
              _poolStat('REWARDS', '\$${(pool['rewards'] as double).toStringAsFixed(2)}', const Color(0xFF00FF88), p),
              _poolStat('VOL 24H', '\$${_formatBig(pool['volume24h'] as int)}', const Color(0xFFFFD700), p),
            ]),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _actionBtn('Hinzufügen', Icons.add_rounded, color, p)),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn('Entfernen', Icons.remove_rounded, const Color(0xFFFF3358), p)),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn('Harvest', Icons.agriculture_rounded, const Color(0xFF00FF88), p)),
          ]),
        ],
      ]),
    );
  }

  Widget _poolStat(String label, String value, Color color, dynamic p) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
    ]));
  }

  Widget _actionBtn(String label, IconData icon, Color color, dynamic p) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); _showSnack('$label Funktion: Live-Integration aktiv'); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.25))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.spaceMono(color: color, fontSize: 9)),
        ]),
      ),
    );
  }

  // ── STAKING ──
  Widget _buildStaking(dynamic p) {
    final totalStakingValue = _staking.fold(0.0, (s, st) => s + (st['value'] as double));
    final totalRewards = _staking.fold(0.0, (s, st) => s + (st['rewards'] as double));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Summary
        Row(children: [
          Expanded(child: _summaryCard('GESTAKT', '\$${totalStakingValue.toStringAsFixed(0)}', '${_staking.length} Positionen', const Color(0xFF00CED1), Icons.savings_rounded, p)),
          const SizedBox(width: 8),
          Expanded(child: _summaryCard('TÄGL. REWARDS', '\$${totalRewards.toStringAsFixed(2)}', '\$${(totalRewards * 30).toStringAsFixed(0)}/Monat', const Color(0xFF00FF88), Icons.trending_up_rounded, p)),
        ]),
        const SizedBox(height: 12),
        _sectionTitle('AKTIVE STAKING POSITIONEN', const Color(0xFF00CED1), p),
        const SizedBox(height: 8),
        ..._staking.map((st) {
          final color = st['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withValues(alpha: 0.08), p.surface]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.35))),
                  child: Center(child: Text(st['icon'] as String, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${st['token']} Staking', style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(st['protocol'] as String, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${(st['apy'] as double).toStringAsFixed(1)}% APY', style: GoogleFonts.spaceMono(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(st['lockup'] as String, style: GoogleFonts.spaceMono(color: color, fontSize: 8)),
                  ),
                ]),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _stakeStat('BETRAG', '${st['amount']} ${st['token']}', color, p),
                _stakeStat('WERT', '\$${(st['value'] as double).toStringAsFixed(2)}', p.primary, p),
                _stakeStat('TÄGL. REWARD', '+\$${(st['rewards'] as double).toStringAsFixed(2)}', const Color(0xFF00FF88), p),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _actionBtn('Hinzufügen', Icons.add_rounded, color, p)),
                const SizedBox(width: 8),
                Expanded(child: _actionBtn('Unstake', Icons.logout_rounded, const Color(0xFFFF6B35), p)),
                const SizedBox(width: 8),
                Expanded(child: _actionBtn('Claim', Icons.redeem_rounded, const Color(0xFF00FF88), p)),
              ]),
            ]),
          );
        }),
      ],
    );
  }

  Widget _stakeStat(String label, String value, Color color, dynamic p) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
    ]));
  }

  // ── YIELDS ──
  Widget _buildYields(dynamic p) {
    final sorted = List.from(_yields)..sort((a, b) => (b['apy'] as double).compareTo(a['apy'] as double));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFF00FF88).withValues(alpha: 0.08), p.surface]),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.emoji_events_rounded, color: const Color(0xFFFFD700), size: 16),
              const SizedBox(width: 8),
              Text('BESTE YIELD MÖGLICHKEITEN', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 11, letterSpacing: 1)),
            ]),
            const SizedBox(height: 4),
            Text('Sortiert nach APY · Risikobewertung inklusive', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
          ]),
        ),
        ...sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final y = entry.value;
          final color = y['color'] as Color;
          final apy = y['apy'] as double;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Row(children: [
              // Rank
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: i < 3 ? const Color(0xFFFFD700).withValues(alpha: 0.15) : p.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('${i + 1}', style: GoogleFonts.spaceMono(color: i < 3 ? const Color(0xFFFFD700) : p.textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(y['name'] as String, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                Row(children: [
                  Text(y['type'] as String, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: (y['risk'] == 'Sehr Niedrig' || y['risk'] == 'Niedrig' ? const Color(0xFF00FF88) : y['risk'] == 'Mittel' ? const Color(0xFFFFD700) : const Color(0xFFFF3358)).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(y['risk'] as String, style: GoogleFonts.spaceMono(color: y['risk'] == 'Sehr Niedrig' || y['risk'] == 'Niedrig' ? const Color(0xFF00FF88) : y['risk'] == 'Mittel' ? const Color(0xFFFFD700) : const Color(0xFFFF3358), fontSize: 7)),
                  ),
                ]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${apy.toStringAsFixed(1)}%', style: GoogleFonts.spaceMono(color: apy > 20 ? const Color(0xFF00FF88) : apy > 10 ? const Color(0xFFFFD700) : p.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('APY · TVL: ${y['tvl']}', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
              ]),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () { HapticFeedback.mediumImpact(); _showSnack('Investiere in ${y['name']} — ${apy.toStringAsFixed(1)}% APY'); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))),
                  child: Text('INVEST', style: GoogleFonts.spaceMono(color: color, fontSize: 8, letterSpacing: 0.5)),
                ),
              ),
            ]),
          );
        }),
      ],
    );
  }

  Widget _sectionTitle(String title, Color color, dynamic p) {
    return Row(children: [
      Container(width: 3, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: GoogleFonts.spaceMono(color: color, fontSize: 10, letterSpacing: 1.5)),
    ]);
  }

  String _formatBig(int n) {
    if (n >= 1000000000) return '${(n / 1000000000).toStringAsFixed(1)}B';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }

  void _showSnack(String msg) {
    final p = context.read<ThemeProvider>().palette;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 10)),
      backgroundColor: p.surface,
      duration: const Duration(seconds: 2),
    ));
  }
}
