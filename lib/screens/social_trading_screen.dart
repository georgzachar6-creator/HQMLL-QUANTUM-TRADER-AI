/// HQMLL Quantum Trader – Social Trading Screen
/// Copy Trading · Leaderboard · Follow Traders · Portfolio Mirror
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

// ── Trader Model ───────────────────────────────────────
class Trader {
  final String id;
  final String username;
  final String avatarUrl;
  final double totalReturn;
  final double monthlyReturn;
  final double winRate;
  final int followers;
  final int totalTrades;
  final double copiedVolume;
  final String strategy;
  final List<String> topAssets;
  final bool verified;
  final int rank;

  Trader({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.totalReturn,
    required this.monthlyReturn,
    required this.winRate,
    required this.followers,
    required this.totalTrades,
    required this.copiedVolume,
    required this.strategy,
    required this.topAssets,
    required this.verified,
    required this.rank,
  });
}

// ═══════════════════════════════════════════════════════
// SOCIAL TRADING SCREEN
// ═══════════════════════════════════════════════════════
class SocialTradingScreen extends StatefulWidget {
  const SocialTradingScreen({super.key});
  @override
  State<SocialTradingScreen> createState() => _SocialTradingScreenState();
}

class _SocialTradingScreenState extends State<SocialTradingScreen> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  Timer? _updateTimer;
  final Random _rng = Random(99);

  final List<Trader> _traders = [];
  final List<Trader> _following = [];
  String _sortBy = 'return'; // return | winrate | followers

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _initTraders();
    _startLiveUpdates();
  }

  void _initTraders() {
    final usernames = [
      'CryptoKing', 'QuantumWhale', 'DeFiMaster', 'MoonLambo', 'DiamondHands',
      'BTCMaximalist', 'AltcoinHunter', 'ScalpingPro', 'HODLer2025', 'YieldFarmer',
      'LeverageLord', 'TrendFollower', 'ValueInvestor', 'SwingTrader', 'ArbitrageBot',
    ];
    final strategies = ['Trend Following', 'Scalping', 'Grid Trading', 'Arbitrage', 'DCA', 'Swing Trading'];
    final assets = [
      ['BTC', 'ETH', 'SOL'],
      ['ETH', 'MATIC', 'LINK'],
      ['BTC', 'BNB', 'ADA'],
      ['SOL', 'AVAX', 'DOT'],
      ['DOGE', 'SHIB', 'QEMMA'],
    ];

    for (int i = 0; i < 15; i++) {
      _traders.add(Trader(
        id: 'trader_${i + 1}',
        username: usernames[i],
        avatarUrl: '',
        totalReturn: 20 + _rng.nextDouble() * 280,
        monthlyReturn: -5 + _rng.nextDouble() * 35,
        winRate: 50 + _rng.nextDouble() * 40,
        followers: 100 + _rng.nextInt(4900),
        totalTrades: 50 + _rng.nextInt(950),
        copiedVolume: 10000 + _rng.nextDouble() * 490000,
        strategy: strategies[i % strategies.length],
        topAssets: assets[i % assets.length],
        verified: i < 5,
        rank: i + 1,
      ));
    }

    _following.addAll(_traders.take(3));
    _sortTraders();
  }

  void _startLiveUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _traders.length; i++) {
          final t = _traders[i];
          _traders[i] = Trader(
            id: t.id,
            username: t.username,
            avatarUrl: t.avatarUrl,
            totalReturn: t.totalReturn + (_rng.nextDouble() - 0.5) * 2,
            monthlyReturn: t.monthlyReturn + (_rng.nextDouble() - 0.5) * 0.8,
            winRate: t.winRate + (_rng.nextDouble() - 0.5) * 0.5,
            followers: t.followers + (_rng.nextBool() ? 1 : 0),
            totalTrades: t.totalTrades + (_rng.nextBool() ? 1 : 0),
            copiedVolume: t.copiedVolume,
            strategy: t.strategy,
            topAssets: t.topAssets,
            verified: t.verified,
            rank: t.rank,
          );
        }
      });
    });
  }

  void _sortTraders() {
    setState(() {
      if (_sortBy == 'return') {
        _traders.sort((a, b) => b.totalReturn.compareTo(a.totalReturn));
      } else if (_sortBy == 'winrate') {
        _traders.sort((a, b) => b.winRate.compareTo(a.winRate));
      } else if (_sortBy == 'followers') {
        _traders.sort((a, b) => b.followers.compareTo(a.followers));
      }
      for (int i = 0; i < _traders.length; i++) {
        _traders[i] = Trader(
          id: _traders[i].id,
          username: _traders[i].username,
          avatarUrl: _traders[i].avatarUrl,
          totalReturn: _traders[i].totalReturn,
          monthlyReturn: _traders[i].monthlyReturn,
          winRate: _traders[i].winRate,
          followers: _traders[i].followers,
          totalTrades: _traders[i].totalTrades,
          copiedVolume: _traders[i].copiedVolume,
          strategy: _traders[i].strategy,
          topAssets: _traders[i].topAssets,
          verified: _traders[i].verified,
          rank: i + 1,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _updateTimer?.cancel();
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
          _buildSortBar(p),
          _buildTabBar(p),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildLeaderboardTab(p),
                _buildFollowingTab(p),
                _buildPortfolioMirrorTab(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────
  Widget _buildHeader(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.surface, p.background],
        ),
        border: Border(bottom: BorderSide(color: Colors.purpleAccent.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Colors.purpleAccent, Colors.pinkAccent]),
              boxShadow: [BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.4), blurRadius: 12)],
            ),
            child: const Center(child: Icon(Icons.groups, color: Colors.white, size: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SOCIAL TRADING', style: GoogleFonts.orbitron(
                  color: p.textPrimary, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2)),
                Text('Copy Top Traders · Mirror Portfolios', style: TextStyle(color: p.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.purpleAccent.withValues(alpha: 0.15),
              border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)),
            ),
            child: Text('${_following.length} FOLLOWING', style: const TextStyle(
              color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Sort Bar ──────────────────────────────────────
  Widget _buildSortBar(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: p.surface,
      child: Row(
        children: [
          Text('SORTIEREN:', style: TextStyle(color: p.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          _buildSortChip('RETURN', 'return', Colors.greenAccent, p),
          const SizedBox(width: 6),
          _buildSortChip('WIN RATE', 'winrate', Colors.blueAccent, p),
          const SizedBox(width: 6),
          _buildSortChip('FOLLOWERS', 'followers', Colors.orangeAccent, p),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value, Color color, QuantumPalette p) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        _sortBy = value;
        _sortTraders();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(color: isSelected ? color : p.textSecondary.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(
          color: isSelected ? color : p.textSecondary,
          fontSize: 9, fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────
  Widget _buildTabBar(QuantumPalette p) {
    return Container(
      color: p.surface,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: Colors.purpleAccent,
        indicatorWeight: 2,
        labelColor: Colors.purpleAccent,
        unselectedLabelColor: p.textSecondary,
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        tabs: const [
          Tab(text: 'LEADERBOARD', icon: Icon(Icons.leaderboard, size: 16)),
          Tab(text: 'FOLLOWING', icon: Icon(Icons.favorite, size: 16)),
          Tab(text: 'MIRROR', icon: Icon(Icons.content_copy, size: 16)),
        ],
      ),
    );
  }

  // ── Leaderboard Tab ───────────────────────────────
  Widget _buildLeaderboardTab(QuantumPalette p) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _traders.length,
      itemBuilder: (_, i) => _buildTraderCard(_traders[i], p),
    );
  }

  Widget _buildTraderCard(Trader trader, QuantumPalette p) {
    final isFollowing = _following.any((t) => t.id == trader.id);
    final returnColor = trader.totalReturn >= 0 ? Colors.greenAccent : Colors.redAccent;
    final rankColor = trader.rank <= 3 ? Colors.amber : trader.rank <= 10 ? Colors.grey : p.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: p.surface,
        border: Border.all(color: trader.rank <= 3 ? Colors.amber.withValues(alpha: 0.3) : p.textSecondary.withValues(alpha: 0.12)),
        boxShadow: trader.rank <= 3
            ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.15), blurRadius: 15)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [
                        returnColor.withValues(alpha: 0.3),
                        returnColor.withValues(alpha: 0.1),
                      ]),
                      border: Border.all(color: returnColor.withValues(alpha: 0.5), width: 2),
                    ),
                    child: Center(child: Text(
                      trader.username.substring(0, 2).toUpperCase(),
                      style: TextStyle(color: returnColor, fontWeight: FontWeight.w900, fontSize: 16),
                    )),
                  ),
                  if (trader.verified)
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        child: const Icon(Icons.verified, color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('#${trader.rank}', style: TextStyle(color: rankColor, fontWeight: FontWeight.w900, fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(trader.username, style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                    Text(trader.strategy, style: TextStyle(color: p.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${trader.totalReturn >= 0 ? '+' : ''}${trader.totalReturn.toStringAsFixed(1)}%',
                    style: TextStyle(color: returnColor, fontSize: 16, fontWeight: FontWeight.w900)),
                  Text('Total Return', style: TextStyle(color: p.textSecondary, fontSize: 9)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTraderStat('Win Rate', '${trader.winRate.toStringAsFixed(1)}%', Colors.blueAccent, p),
              _buildTraderStat('Trades', '${trader.totalTrades}', const Color(0xFF00D4FF), p),
              _buildTraderStat('Followers', '${trader.followers}', Colors.purpleAccent, p),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 4,
                  children: trader.topAssets.map((asset) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.12),
                    ),
                    child: Text(asset, style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 9, fontWeight: FontWeight.w700)),
                  )).toList(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _toggleFollow(trader),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing ? Colors.grey.shade700 : Colors.purpleAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: Size.zero,
                ),
                child: Text(isFollowing ? 'UNFOLLOW' : 'FOLLOW',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTraderStat(String label, String value, Color color, QuantumPalette p) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: p.textSecondary, fontSize: 9)),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  void _toggleFollow(Trader trader) {
    setState(() {
      if (_following.any((t) => t.id == trader.id)) {
        _following.removeWhere((t) => t.id == trader.id);
      } else {
        _following.add(trader);
      }
    });
  }

  // ── Following Tab ─────────────────────────────────
  Widget _buildFollowingTab(QuantumPalette p) {
    if (_following.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: p.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Noch keine Trader gefolgt', style: TextStyle(color: p.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Folge Top-Tradern um deren Trades zu kopieren', style: TextStyle(color: p.textSecondary, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _following.length,
      itemBuilder: (_, i) => _buildFollowingCard(_following[i], p),
    );
  }

  Widget _buildFollowingCard(Trader trader, QuantumPalette p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: p.surface,
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
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
                  color: Colors.purpleAccent.withValues(alpha: 0.15),
                ),
                child: Center(child: Text(
                  trader.username.substring(0, 2).toUpperCase(),
                  style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.w900, fontSize: 14),
                )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trader.username, style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('${trader.totalReturn >= 0 ? '+' : ''}${trader.totalReturn.toStringAsFixed(1)}% Total Return',
                      style: TextStyle(
                        color: trader.totalReturn >= 0 ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Switch(
                value: true,
                onChanged: (_) {},
                activeColor: Colors.purpleAccent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.purpleAccent.withValues(alpha: 0.08),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Copy Trading', style: TextStyle(color: p.textSecondary, fontSize: 11)),
                Text('AKTIV', style: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Portfolio Mirror Tab ──────────────────────────
  Widget _buildPortfolioMirrorTab(QuantumPalette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMirrorStats(p),
          const SizedBox(height: 16),
          _buildMirrorChart(p),
          const SizedBox(height: 16),
          _buildMirroredAssets(p),
        ],
      ),
    );
  }

  Widget _buildMirrorStats(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: p.surface,
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PORTFOLIO MIRROR', style: GoogleFonts.orbitron(
            color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMirrorStat('Total Value', '\$12,840', Colors.greenAccent, p)),
              Expanded(child: _buildMirrorStat('P&L', '+\$2,340', Colors.greenAccent, p)),
              Expanded(child: _buildMirrorStat('Mirrored', '3 Traders', Colors.purpleAccent, p)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMirrorStat(String label, String value, Color color, QuantumPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: p.textSecondary, fontSize: 9)),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildMirrorChart(QuantumPalette p) {
    final data = List.generate(30, (i) {
      final x = i.toDouble();
      final y = 10000 + (i * 95) + (_rng.nextDouble() - 0.4) * 400;
      return FlSpot(x, y);
    });

    return Container(
      height: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: p.surface,
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              color: Colors.purpleAccent,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.purpleAccent.withValues(alpha: 0.3),
                    Colors.purpleAccent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(enabled: false),
        ),
      ),
    );
  }

  Widget _buildMirroredAssets(QuantumPalette p) {
    final assets = [
      ('BTC', 0.142, 9642.50, 18.2),
      ('ETH', 1.84, 6530.40, 12.4),
      ('SOL', 12.4, 2268.00, 8.8),
      ('BNB', 4.2, 2512.60, 6.2),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MIRRORED ASSETS', style: GoogleFonts.orbitron(
          color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 10),
        ...assets.map((a) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: p.surface,
            border: Border.all(color: p.textSecondary.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                ),
                child: Center(child: Text(a.$1,
                  style: const TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.w900, fontSize: 11))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.$1, style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                    Text('${a.$2.toStringAsFixed(4)} ${a.$1}',
                      style: TextStyle(color: p.textSecondary, fontSize: 10)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${a.$3.toStringAsFixed(2)}',
                    style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                  Text('+${a.$4.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }
}
