/// HQMLL Quantum Trader – AI Trading Bot Screen
/// Auto-Trading · Strategies · Backtesting · Performance Analytics
/// Grigori Saks · 2025
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/theme_provider.dart';
import '../services/live_market_service.dart';
import '../theme/app_themes.dart';

// ── Trading Bot Model ──────────────────────────────────
class TradingBot {
  final String id;
  final String name;
  final String strategy;
  final String status; // active | paused | stopped
  final double pnl;
  final double winRate;
  final int totalTrades;
  final double capital;
  final List<String> assets;
  final DateTime createdAt;

  TradingBot({
    required this.id,
    required this.name,
    required this.strategy,
    required this.status,
    required this.pnl,
    required this.winRate,
    required this.totalTrades,
    required this.capital,
    required this.assets,
    required this.createdAt,
  });
}

// ── Strategy Model ─────────────────────────────────────
class Strategy {
  final String id;
  final String name;
  final String description;
  final String type; // trend | scalping | arbitrage | grid | dca
  final double avgReturn;
  final double sharpeRatio;
  final double maxDrawdown;
  final IconData icon;
  final Color color;

  Strategy({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.avgReturn,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.icon,
    required this.color,
  });
}

// ═══════════════════════════════════════════════════════
// TRADING BOT SCREEN
// ═══════════════════════════════════════════════════════
class TradingBotScreen extends StatefulWidget {
  const TradingBotScreen({super.key});
  @override
  State<TradingBotScreen> createState() => _TradingBotScreenState();
}

class _TradingBotScreenState extends State<TradingBotScreen> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  Timer? _perfTimer;
  final Random _rng = Random(88);

  final List<TradingBot> _bots = [];
  final List<Strategy> _strategies = [];
  final List<Map<String, dynamic>> _recentTrades = [];

  // Performance tracking
  double _totalPnL = 0;
  double _todayPnL = 0;
  int _activeBots = 0;
  int _totalTrades = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _initStrategies();
    _initBots();
    _initRecentTrades();
    _startPerformanceUpdates();
    _calculateStats();
  }

  void _initStrategies() {
    _strategies.addAll([
      Strategy(
        id: 'trend_following',
        name: 'Trend Following',
        description: 'Folgt starken Markttrends mit EMA/MACD',
        type: 'trend',
        avgReturn: 8.4,
        sharpeRatio: 1.8,
        maxDrawdown: 12.3,
        icon: Icons.trending_up,
        color: Colors.greenAccent,
      ),
      Strategy(
        id: 'scalping',
        name: 'Quantum Scalping',
        description: 'Ultra-schnelle Trades in volatilen Märkten',
        type: 'scalping',
        avgReturn: 12.8,
        sharpeRatio: 2.1,
        maxDrawdown: 8.5,
        icon: Icons.flash_on,
        color: Colors.orangeAccent,
      ),
      Strategy(
        id: 'arbitrage',
        name: 'Cross-Exchange Arbitrage',
        description: 'Preisdifferenzen zwischen Börsen ausnutzen',
        type: 'arbitrage',
        avgReturn: 6.2,
        sharpeRatio: 2.8,
        maxDrawdown: 3.4,
        icon: Icons.swap_horiz,
        color: const Color(0xFF00D4FF),
      ),
      Strategy(
        id: 'grid_trading',
        name: 'Grid Trading',
        description: 'Automatisches Kaufen/Verkaufen in festgelegten Intervallen',
        type: 'grid',
        avgReturn: 7.5,
        sharpeRatio: 1.6,
        maxDrawdown: 9.8,
        icon: Icons.grid_on,
        color: Colors.purpleAccent,
      ),
      Strategy(
        id: 'dca',
        name: 'Dollar Cost Averaging',
        description: 'Regelmäßige Investitionen unabhängig vom Preis',
        type: 'dca',
        avgReturn: 5.8,
        sharpeRatio: 1.4,
        maxDrawdown: 15.2,
        icon: Icons.trending_flat,
        color: Colors.blueAccent,
      ),
      Strategy(
        id: 'mean_reversion',
        name: 'Mean Reversion',
        description: 'Kaufen bei Überverkauf, Verkaufen bei Überkauf',
        type: 'scalping',
        avgReturn: 9.2,
        sharpeRatio: 1.9,
        maxDrawdown: 11.5,
        icon: Icons.show_chart,
        color: Colors.tealAccent,
      ),
    ]);
  }

  void _initBots() {
    _bots.addAll([
      TradingBot(
        id: 'bot_001',
        name: 'Quantum Alpha',
        strategy: 'Trend Following',
        status: 'active',
        pnl: 2840.50,
        winRate: 68.5,
        totalTrades: 284,
        capital: 10000,
        assets: ['BTC', 'ETH', 'SOL'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      TradingBot(
        id: 'bot_002',
        name: 'Scalper Pro',
        strategy: 'Quantum Scalping',
        status: 'active',
        pnl: 1245.80,
        winRate: 72.3,
        totalTrades: 842,
        capital: 5000,
        assets: ['BTC', 'ETH'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      TradingBot(
        id: 'bot_003',
        name: 'Arbitrage Hunter',
        strategy: 'Cross-Exchange Arbitrage',
        status: 'active',
        pnl: 980.20,
        winRate: 88.2,
        totalTrades: 124,
        capital: 8000,
        assets: ['USDT', 'USDC'],
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      TradingBot(
        id: 'bot_004',
        name: 'Grid Master',
        strategy: 'Grid Trading',
        status: 'paused',
        pnl: -125.40,
        winRate: 45.8,
        totalTrades: 56,
        capital: 3000,
        assets: ['BNB', 'MATIC'],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      TradingBot(
        id: 'bot_005',
        name: 'DCA Accumulator',
        strategy: 'Dollar Cost Averaging',
        status: 'active',
        pnl: 540.30,
        winRate: 100.0,
        totalTrades: 30,
        capital: 12000,
        assets: ['BTC', 'ETH', 'QEMMA'],
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
    ]);
  }

  void _initRecentTrades() {
    final sides = ['BUY', 'SELL'];
    final symbols = ['BTC', 'ETH', 'SOL', 'BNB', 'ADA', 'MATIC'];
    final bots = _bots.map((b) => b.name).toList();
    for (int i = 0; i < 20; i++) {
      final side = sides[i % 2];
      final pnl = (_rng.nextDouble() - 0.3) * 50;
      _recentTrades.add({
        'id': 'TRD${1000 + i}',
        'bot': bots[i % bots.length],
        'symbol': symbols[i % symbols.length],
        'side': side,
        'price': 100 + _rng.nextDouble() * 900,
        'quantity': 0.01 + _rng.nextDouble() * 0.5,
        'pnl': pnl,
        'timestamp': DateTime.now().subtract(Duration(minutes: i * 5 + _rng.nextInt(4))),
      });
    }
    _recentTrades.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
  }

  void _startPerformanceUpdates() {
    _perfTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _bots.length; i++) {
          if (_bots[i].status == 'active') {
            final delta = (_rng.nextDouble() - 0.48) * 20;
            _bots[i] = TradingBot(
              id: _bots[i].id,
              name: _bots[i].name,
              strategy: _bots[i].strategy,
              status: _bots[i].status,
              pnl: _bots[i].pnl + delta,
              winRate: _bots[i].winRate + (_rng.nextDouble() - 0.5) * 0.5,
              totalTrades: _bots[i].totalTrades + (_rng.nextBool() ? 1 : 0),
              capital: _bots[i].capital,
              assets: _bots[i].assets,
              createdAt: _bots[i].createdAt,
            );
          }
        }
        _calculateStats();
      });
    });
  }

  void _calculateStats() {
    _totalPnL = _bots.fold(0.0, (sum, bot) => sum + bot.pnl);
    _todayPnL = _totalPnL * 0.08; // Simulate today's portion
    _activeBots = _bots.where((b) => b.status == 'active').length;
    _totalTrades = _bots.fold(0, (sum, bot) => sum + bot.totalTrades);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _perfTimer?.cancel();
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
          _buildStatsBar(p),
          _buildTabBar(p),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildMyBotsTab(p),
                _buildStrategiesTab(p),
                _buildTradesTab(p),
                _buildBacktestTab(p),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildCreateBotFAB(p),
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
        border: Border(bottom: BorderSide(color: const Color(0xFF00D4FF).withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _rotateCtrl,
            builder: (_, child) => Transform.rotate(
              angle: _rotateCtrl.value * 2 * pi,
              child: child,
            ),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [Color(0xFF00D4FF), Color(0xFF7B00D4)]),
                boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withValues(alpha: 0.4), blurRadius: 12)],
              ),
              child: const Center(child: Icon(Icons.smart_toy, color: Colors.white, size: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI TRADING BOTS', style: GoogleFonts.orbitron(
                  color: p.textPrimary, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2)),
                Text('Quantum Auto-Trading System', style: TextStyle(color: p.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.greenAccent.withValues(alpha: 0.12 + _pulseCtrl.value * 0.08),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent.withValues(alpha: 0.7 + _pulseCtrl.value * 0.3),
                  )),
                  const SizedBox(width: 5),
                  Text('$_activeBots ACTIVE', style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Bar ─────────────────────────────────────
  Widget _buildStatsBar(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: p.surface,
      child: Row(
        children: [
          _buildStatChip('Total P&L', '\$${_totalPnL.toStringAsFixed(2)}', _totalPnL >= 0 ? Colors.greenAccent : Colors.redAccent, p),
          const SizedBox(width: 8),
          _buildStatChip('Today', '\$${_todayPnL.toStringAsFixed(2)}', _todayPnL >= 0 ? Colors.greenAccent : Colors.redAccent, p),
          const SizedBox(width: 8),
          _buildStatChip('Trades', '$_totalTrades', const Color(0xFF00D4FF), p),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, QuantumPalette p) {
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
            Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            Text(value, style: TextStyle(color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────
  Widget _buildTabBar(QuantumPalette p) {
    return Container(
      color: p.surface,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: const Color(0xFF00D4FF),
        indicatorWeight: 2,
        labelColor: const Color(0xFF00D4FF),
        unselectedLabelColor: p.textSecondary,
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        tabs: const [
          Tab(text: 'MY BOTS', icon: Icon(Icons.smart_toy, size: 16)),
          Tab(text: 'STRATEGIES', icon: Icon(Icons.psychology, size: 16)),
          Tab(text: 'TRADES', icon: Icon(Icons.receipt_long, size: 16)),
          Tab(text: 'BACKTEST', icon: Icon(Icons.assessment, size: 16)),
        ],
      ),
    );
  }

  // ── My Bots Tab ───────────────────────────────────
  Widget _buildMyBotsTab(QuantumPalette p) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _bots.length,
      itemBuilder: (_, i) => _buildBotCard(_bots[i], p),
    );
  }

  Widget _buildBotCard(TradingBot bot, QuantumPalette p) {
    final isActive = bot.status == 'active';
    final isPaused = bot.status == 'paused';
    final statusColor = isActive ? Colors.greenAccent : isPaused ? Colors.orangeAccent : Colors.grey;
    final pnlColor = bot.pnl >= 0 ? Colors.greenAccent : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: p.surface,
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: isActive
            ? [BoxShadow(color: const Color(0xFF00D4FF).withValues(alpha: 0.15), blurRadius: 15)]
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
                  gradient: LinearGradient(colors: [statusColor.withValues(alpha: 0.3), statusColor.withValues(alpha: 0.1)]),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Center(child: Icon(Icons.smart_toy, color: statusColor, size: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bot.name, style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(bot.strategy, style: TextStyle(color: p.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: statusColor.withValues(alpha: 0.15),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(bot.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildBotStat('P&L', '\$${bot.pnl.toStringAsFixed(2)}', pnlColor, p)),
              Expanded(child: _buildBotStat('Win Rate', '${bot.winRate.toStringAsFixed(1)}%', Colors.blueAccent, p)),
              Expanded(child: _buildBotStat('Trades', '${bot.totalTrades}', const Color(0xFF00D4FF), p)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: p.textSecondary, size: 14),
              const SizedBox(width: 4),
              Text('Capital: \$${bot.capital.toStringAsFixed(0)}', style: TextStyle(color: p.textSecondary, fontSize: 11)),
              const SizedBox(width: 12),
              ...bot.assets.map((asset) => Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.12),
                ),
                child: Text(asset, style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 9, fontWeight: FontWeight.w700)),
              )),
              const Spacer(),
              IconButton(
                onPressed: () => _toggleBot(bot),
                icon: Icon(isActive ? Icons.pause : Icons.play_arrow, color: statusColor, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _deleteBot(bot),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotStat(String label, String value, Color color, QuantumPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: p.textSecondary, fontSize: 9)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    );
  }

  void _toggleBot(TradingBot bot) {
    setState(() {
      final idx = _bots.indexWhere((b) => b.id == bot.id);
      if (idx != -1) {
        _bots[idx] = TradingBot(
          id: bot.id,
          name: bot.name,
          strategy: bot.strategy,
          status: bot.status == 'active' ? 'paused' : 'active',
          pnl: bot.pnl,
          winRate: bot.winRate,
          totalTrades: bot.totalTrades,
          capital: bot.capital,
          assets: bot.assets,
          createdAt: bot.createdAt,
        );
        _calculateStats();
      }
    });
  }

  void _deleteBot(TradingBot bot) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bot löschen?'),
        content: Text('Möchten Sie "${bot.name}" wirklich löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () {
              setState(() => _bots.removeWhere((b) => b.id == bot.id));
              _calculateStats();
              Navigator.pop(context);
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ── Strategies Tab ────────────────────────────────
  Widget _buildStrategiesTab(QuantumPalette p) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _strategies.length,
      itemBuilder: (_, i) => _buildStrategyCard(_strategies[i], p),
    );
  }

  Widget _buildStrategyCard(Strategy strategy, QuantumPalette p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: p.surface,
        border: Border.all(color: strategy.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: strategy.color.withValues(alpha: 0.15),
                  border: Border.all(color: strategy.color.withValues(alpha: 0.4)),
                ),
                child: Icon(strategy.icon, color: strategy.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strategy.name, style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(strategy.description, style: TextStyle(color: p.textSecondary, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetric('Avg Return', '${strategy.avgReturn.toStringAsFixed(1)}%', Colors.greenAccent, p)),
              Expanded(child: _buildMetric('Sharpe', strategy.sharpeRatio.toStringAsFixed(2), Colors.blueAccent, p)),
              Expanded(child: _buildMetric('Max DD', '${strategy.maxDrawdown.toStringAsFixed(1)}%', Colors.redAccent, p)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _createBotWithStrategy(strategy),
              style: ElevatedButton.styleFrom(
                backgroundColor: strategy.color.withValues(alpha: 0.15),
                foregroundColor: strategy.color,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('BOT ERSTELLEN', style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color, QuantumPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: p.textSecondary, fontSize: 9)),
        Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    );
  }

  void _createBotWithStrategy(Strategy strategy) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🤖 Bot mit "${strategy.name}" wird erstellt...'), backgroundColor: strategy.color),
    );
    // TODO: Implement bot creation dialog
  }

  // ── Trades Tab ────────────────────────────────────
  Widget _buildTradesTab(QuantumPalette p) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _recentTrades.length,
      itemBuilder: (_, i) {
        final trade = _recentTrades[i];
        final pnl = trade['pnl'] as double;
        final pnlColor = pnl >= 0 ? Colors.greenAccent : Colors.redAccent;
        final side = trade['side'] as String;
        final sideColor = side == 'BUY' ? Colors.greenAccent : Colors.redAccent;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: p.surface,
            border: Border.all(color: p.textSecondary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sideColor.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Icon(side == 'BUY' ? Icons.arrow_upward : Icons.arrow_downward,
                    color: sideColor, size: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${trade['symbol']} ${trade['side']}',
                      style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                    Text(trade['bot'] as String, style: TextStyle(color: p.textSecondary, fontSize: 10)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
                    style: TextStyle(color: pnlColor, fontSize: 12, fontWeight: FontWeight.w800)),
                  Text('\$${(trade['price'] as double).toStringAsFixed(2)}',
                    style: TextStyle(color: p.textSecondary, fontSize: 10)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Backtest Tab ──────────────────────────────────
  Widget _buildBacktestTab(QuantumPalette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildPerformanceChart(p),
          const SizedBox(height: 16),
          _buildBacktestMetrics(p),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(QuantumPalette p) {
    final data = List.generate(60, (i) {
      final x = i.toDouble();
      final y = 10000 + (i * 80) + (_rng.nextDouble() - 0.4) * 500;
      return FlSpot(x, y);
    });

    return Container(
      height: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: p.surface,
        border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BACKTEST PERFORMANCE', style: GoogleFonts.orbitron(
            color: const Color(0xFF00D4FF), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    isCurved: true,
                    color: const Color(0xFF00D4FF),
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF00D4FF).withValues(alpha: 0.3),
                          const Color(0xFF00D4FF).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBacktestMetrics(QuantumPalette p) {
    final metrics = [
      ('Total Return', '+48.2%', Colors.greenAccent),
      ('Sharpe Ratio', '2.14', Colors.blueAccent),
      ('Max Drawdown', '-12.5%', Colors.redAccent),
      ('Win Rate', '68.4%', Colors.greenAccent),
      ('Profit Factor', '2.8', Colors.tealAccent),
      ('Avg Trade', '+\$42.50', Colors.greenAccent),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: metrics.length,
      itemBuilder: (_, i) {
        final m = metrics[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: p.surface,
            border: Border.all(color: m.$3.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(m.$1, style: TextStyle(color: p.textSecondary, fontSize: 10)),
              const SizedBox(height: 4),
              Text(m.$2, style: TextStyle(color: m.$3, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        );
      },
    );
  }

  // ── Create Bot FAB ────────────────────────────────
  Widget _buildCreateBotFAB(QuantumPalette p) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateBotDialog(),
      backgroundColor: const Color(0xFF00D4FF),
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text('BOT ERSTELLEN', style: GoogleFonts.orbitron(
        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  void _showCreateBotDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Neuen Bot erstellen'),
        content: const Text('Bot-Erstellung wird implementiert...'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}
