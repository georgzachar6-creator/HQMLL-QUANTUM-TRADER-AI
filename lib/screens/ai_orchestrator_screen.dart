// ════════════════════════════════════════════════════════════════════════════
// AI ORCHESTRATOR SCREEN  v26.0
// Quantum Trader AI — Multi-Layer Reasoning Engine
// Features: Strategy Agents, Live Signals mit Confidence, Auto-Trading Sessions,
//           Multi-Layer Pipeline (Data → Strategy → Risk → Execution),
//           Performance Analytics, Agent Management
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/exchange_service.dart';
import '../widgets/crypto_icon.dart';
import '../providers/theme_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum AgentStatus { idle, analyzing, executing, waiting, error }
enum SignalSide { buy, sell, hold }
enum RiskLevel { low, medium, high, extreme }

class StrategyAgent {
  final String id;
  final String name;
  final String description;
  final String type;       // trend, mean_reversion, momentum, arbitrage, ml
  final List<String> pairs;
  AgentStatus status;
  bool enabled;
  double winRate;          // 0-1
  double totalPnl;         // USD
  int totalTrades;
  int activeSince;         // days
  double confidence;       // current confidence 0-1
  String lastAction;

  StrategyAgent({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.pairs,
    this.status = AgentStatus.idle,
    this.enabled = true,
    required this.winRate,
    required this.totalPnl,
    required this.totalTrades,
    required this.activeSince,
    this.confidence = 0.0,
    this.lastAction = 'Monitoring market...',
  });
}

class AiSignal {
  final String id;
  final String agentId;
  final String agentName;
  final String symbol;
  final SignalSide side;
  final double entryPrice;
  final double targetPrice;
  final double stopLoss;
  final double confidence;    // 0-1
  final RiskLevel risk;
  final String reasoning;
  final DateTime createdAt;
  bool executed;
  bool? outcome;             // true=win, false=loss, null=open
  double? pnl;

  AiSignal({
    required this.id,
    required this.agentId,
    required this.agentName,
    required this.symbol,
    required this.side,
    required this.entryPrice,
    required this.targetPrice,
    required this.stopLoss,
    required this.confidence,
    required this.risk,
    required this.reasoning,
    required this.createdAt,
    this.executed = false,
    this.outcome,
    this.pnl,
  });

  double get riskReward => entryPrice > 0
      ? (targetPrice - entryPrice).abs() / (entryPrice - stopLoss).abs()
      : 0.0;

  String get sideLabel => side.name.toUpperCase();
  Color get sideColor => side == SignalSide.buy
      ? const Color(0xFF00C896)
      : side == SignalSide.sell
          ? const Color(0xFFFF3355)
          : const Color(0xFFFFB800);
}

class OrchestratorSession {
  bool isActive;
  DateTime? startedAt;
  double allocatedCapital;
  double realizedPnl;
  double unrealizedPnl;
  int totalSignals;
  int executedTrades;
  int wins;
  int losses;
  String mode;             // conservative, balanced, aggressive
  List<String> activeAgents;

  OrchestratorSession({
    this.isActive = false,
    this.startedAt,
    this.allocatedCapital = 10000.0,
    this.realizedPnl = 0.0,
    this.unrealizedPnl = 0.0,
    this.totalSignals = 0,
    this.executedTrades = 0,
    this.wins = 0,
    this.losses = 0,
    this.mode = 'balanced',
    this.activeAgents = const [],
  });

  double get totalPnl => realizedPnl + unrealizedPnl;
  double get winRate => executedTrades > 0 ? wins / executedTrades : 0.0;
  double get roi => allocatedCapital > 0 ? (totalPnl / allocatedCapital) * 100 : 0.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// AI ORCHESTRATOR SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class AiOrchestratorScreen extends StatefulWidget {
  const AiOrchestratorScreen({super.key});

  @override
  State<AiOrchestratorScreen> createState() => _AiOrchestratorScreenState();
}

class _AiOrchestratorScreenState extends State<AiOrchestratorScreen>
    with TickerProviderStateMixin {

  late TabController _tabCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _scanCtrl;
  Timer? _agentTimer;
  Timer? _signalTimer;

  int _tab = 0;
  final _rnd = Random();

  late OrchestratorSession _session;
  final List<StrategyAgent> _agents = [];
  final List<AiSignal> _signals = [];
  final List<Map<String, dynamic>> _pipeline = []; // execution log

  // Pipeline visualization state
  int _pipelineStep = 0; // 0=Data 1=Strategy 2=Risk 3=Execution
  bool _pipelineActive = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() => setState(() => _tab = _tabCtrl.index));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();

    _session = OrchestratorSession(
      realizedPnl: 847.32,
      unrealizedPnl: 124.55,
      executedTrades: 143,
      wins: 98,
      losses: 45,
      totalSignals: 312,
    );

    _initAgents();
    _generateInitialSignals();

    _agentTimer = Timer.periodic(const Duration(seconds: 8), (_) => _updateAgents());
    _signalTimer = Timer.periodic(const Duration(seconds: 15), (_) => _maybeGenerateSignal());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    _agentTimer?.cancel();
    _signalTimer?.cancel();
    super.dispose();
  }

  void _initAgents() {
    _agents.addAll([
      StrategyAgent(
        id: 'agent-trend-btc',
        name: 'TrendFollower-Ω',
        description: 'Multi-timeframe trend detection using EMA/MACD cross signals with volume confirmation',
        type: 'trend',
        pairs: ['BTC', 'ETH', 'SOL'],
        winRate: 0.67,
        totalPnl: 2847.50,
        totalTrades: 89,
        activeSince: 127,
        confidence: 0.72,
        lastAction: 'BTC — Bull flag confirmed (4H TF)',
      ),
      StrategyAgent(
        id: 'agent-mr-eth',
        name: 'MeanReversion-Σ',
        description: 'Statistical arbitrage on Bollinger Band deviations, RSI extremes, Z-score normalization',
        type: 'mean_reversion',
        pairs: ['ETH', 'BNB', 'AVAX', 'MATIC'],
        winRate: 0.74,
        totalPnl: 1654.80,
        totalTrades: 234,
        activeSince: 89,
        confidence: 0.58,
        lastAction: 'ETH oversold at -2.1σ, accumulating',
      ),
      StrategyAgent(
        id: 'agent-mom-sol',
        name: 'Momentum-Λ',
        description: 'Breakout detection using ATR channels, volume surge triggers, order flow analysis',
        type: 'momentum',
        pairs: ['SOL', 'ARB', 'OP', 'INJ'],
        winRate: 0.61,
        totalPnl: 987.30,
        totalTrades: 67,
        activeSince: 54,
        confidence: 0.85,
        lastAction: 'SOL breakout above \$148 confirmed',
      ),
      StrategyAgent(
        id: 'agent-ml-alpha',
        name: 'MLAlpha-Θ',
        description: 'LSTM neural network ensemble with 48-hour price prediction, sentiment & on-chain data fusion',
        type: 'ml',
        pairs: ['BTC', 'ETH', 'SOL', 'BNB', 'AVAX'],
        winRate: 0.71,
        totalPnl: 3102.45,
        totalTrades: 156,
        activeSince: 203,
        confidence: 0.63,
        lastAction: 'Model re-training on 72h data window',
      ),
      StrategyAgent(
        id: 'agent-arb-cex',
        name: 'CEX-Arbitrage-Δ',
        description: 'Cross-exchange price discrepancy detection between Binance, Kraken, and Bybit with latency optimization',
        type: 'arbitrage',
        pairs: ['BTC', 'ETH', 'SOL', 'USDT'],
        status: AgentStatus.analyzing,
        winRate: 0.88,
        totalPnl: 541.20,
        totalTrades: 412,
        activeSince: 18,
        confidence: 0.91,
        lastAction: 'Scanning BTC spread: Binance/Kraken Δ=0.03%',
      ),
      StrategyAgent(
        id: 'agent-dca',
        name: 'DCA-Optimizer-Ψ',
        description: 'Dynamic dollar-cost averaging with volatility-adjusted entry intervals and drawdown recovery',
        type: 'trend',
        pairs: ['BTC', 'ETH'],
        winRate: 0.93,
        totalPnl: 1280.60,
        totalTrades: 48,
        activeSince: 365,
        confidence: 0.78,
        lastAction: 'Next DCA entry: BTC @ \$64,200 (limit)',
      ),
    ]);
  }

  void _generateInitialSignals() {
    final now = DateTime.now();
    final demoSignals = [
      AiSignal(
        id: 'sig-001',
        agentId: 'agent-trend-btc',
        agentName: 'TrendFollower-Ω',
        symbol: 'BTC',
        side: SignalSide.buy,
        entryPrice: 65200.0,
        targetPrice: 68500.0,
        stopLoss: 63800.0,
        confidence: 0.78,
        risk: RiskLevel.medium,
        reasoning: 'BTC 4H EMA(21) crossed above EMA(55). Volume +34% above 20-period avg. RSI(14)=58, not overbought. Bull flag pattern target: \$68,500.',
        createdAt: now.subtract(const Duration(minutes: 14)),
        executed: true,
        outcome: null,
        pnl: null,
      ),
      AiSignal(
        id: 'sig-002',
        agentId: 'agent-ml-alpha',
        agentName: 'MLAlpha-Θ',
        symbol: 'ETH',
        side: SignalSide.buy,
        entryPrice: 3180.0,
        targetPrice: 3420.0,
        stopLoss: 3060.0,
        confidence: 0.71,
        risk: RiskLevel.medium,
        reasoning: 'LSTM 48h prediction: +7.5% probability 0.71. On-chain: whale accumulation +12%. Sentiment: neutral→positive shift. Funding rate: -0.01% (shorts dominant = squeeze potential).',
        createdAt: now.subtract(const Duration(minutes: 32)),
        executed: false,
        outcome: null,
      ),
      AiSignal(
        id: 'sig-003',
        agentId: 'agent-mom-sol',
        agentName: 'Momentum-Λ',
        symbol: 'SOL',
        side: SignalSide.buy,
        entryPrice: 148.50,
        targetPrice: 162.0,
        stopLoss: 142.0,
        confidence: 0.85,
        risk: RiskLevel.low,
        reasoning: 'SOL broke out of 3-day consolidation at \$148 with 2.8x average volume. ATR(14) channel breach confirmed. Order flow: 67% buy pressure.',
        createdAt: now.subtract(const Duration(minutes: 8)),
        executed: true,
        outcome: true,
        pnl: 187.50,
      ),
      AiSignal(
        id: 'sig-004',
        agentId: 'agent-mr-eth',
        agentName: 'MeanReversion-Σ',
        symbol: 'BNB',
        side: SignalSide.sell,
        entryPrice: 596.0,
        targetPrice: 575.0,
        stopLoss: 608.0,
        confidence: 0.64,
        risk: RiskLevel.medium,
        reasoning: 'BNB Z-score = +2.3σ (overbought). BB upper band touch with declining volume. RSI divergence on 1H. Short-term reversion to \$575 expected.',
        createdAt: now.subtract(const Duration(hours: 2)),
        executed: true,
        outcome: false,
        pnl: -45.20,
      ),
      AiSignal(
        id: 'sig-005',
        agentId: 'agent-arb-cex',
        agentName: 'CEX-Arbitrage-Δ',
        symbol: 'BTC',
        side: SignalSide.buy,
        entryPrice: 65187.0,
        targetPrice: 65215.0,
        stopLoss: 65170.0,
        confidence: 0.91,
        risk: RiskLevel.low,
        reasoning: 'Binance-Kraken spread: 0.043% (\$28). Latency: 12ms. Execution window: 8s. After fees (0.02% each): net \$15.40 profit per BTC.',
        createdAt: now.subtract(const Duration(minutes: 3)),
        executed: true,
        outcome: true,
        pnl: 15.40,
      ),
    ];
    _signals.addAll(demoSignals);
  }

  void _updateAgents() {
    if (!mounted) return;
    setState(() {
      for (final agent in _agents) {
        if (!agent.enabled) continue;
        agent.confidence = (agent.confidence + (_rnd.nextDouble() - 0.48) * 0.08).clamp(0.2, 0.98);
        final statuses = [AgentStatus.idle, AgentStatus.analyzing, AgentStatus.analyzing, AgentStatus.executing];
        if (_rnd.nextDouble() < 0.3) {
          agent.status = statuses[_rnd.nextInt(statuses.length)];
        }
      }
      if (_session.isActive) {
        _session.unrealizedPnl += (_rnd.nextDouble() - 0.47) * 20;
        _pipelineStep = (_pipelineStep + 1) % 4;
      }
    });
  }

  void _maybeGenerateSignal() {
    if (!mounted || !_session.isActive) return;
    if (_rnd.nextDouble() < 0.3) {
      final symbols = ['BTC', 'ETH', 'SOL', 'BNB', 'AVAX'];
      final sym = symbols[_rnd.nextInt(symbols.length)];
      final ex = context.read<ExchangeService>();
      final price = ex.getPrice(sym);
      if (price <= 0) return;

      final isBuy = _rnd.nextBool();
      final conf = 0.55 + _rnd.nextDouble() * 0.35;
      final agent = _agents[_rnd.nextInt(_agents.length)];
      final riskLevels = RiskLevel.values;

      setState(() {
        _session.totalSignals++;
        _signals.insert(0, AiSignal(
          id: 'sig-${DateTime.now().millisecondsSinceEpoch}',
          agentId: agent.id,
          agentName: agent.name,
          symbol: sym,
          side: isBuy ? SignalSide.buy : SignalSide.sell,
          entryPrice: price,
          targetPrice: price * (isBuy ? 1.04 + _rnd.nextDouble() * 0.03 : 0.96 - _rnd.nextDouble() * 0.03),
          stopLoss: price * (isBuy ? 0.975 - _rnd.nextDouble() * 0.01 : 1.025 + _rnd.nextDouble() * 0.01),
          confidence: conf,
          risk: riskLevels[_rnd.nextInt(riskLevels.length - 1)],
          reasoning: 'Auto-generated signal from ${agent.name}. Market conditions: confidence ${(conf * 100).toStringAsFixed(0)}%.',
          createdAt: DateTime.now(),
        ));
        if (_signals.length > 30) _signals.removeLast();
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ex = context.watch<ExchangeService>();
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: _buildAppBar(p),
      body: Column(
        children: [
          _buildSessionHeader(p),
          _buildTabBar(p),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSignalsTab(ex, p),
                _buildAgentsTab(p),
                _buildPipelineTab(p),
                _buildPerformanceTab(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(dynamic p) {
    return AppBar(
      backgroundColor: p.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: p.textSecondary, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _session.isActive
                  ? Color.lerp(const Color(0xFF00C896), const Color(0xFF00FF88), _pulseCtrl.value)!
                  : Colors.grey[700]!,
              boxShadow: _session.isActive
                  ? [BoxShadow(color: const Color(0xFF00C896).withValues(alpha: 0.6 * _pulseCtrl.value), blurRadius: 10, spreadRadius: 2)]
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI ORCHESTRATOR',
            style: GoogleFonts.rajdhani(color: p.primary, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2)),
          Text('Multi-Layer Reasoning Engine · v26.0',
            style: TextStyle(color: p.textSecondary.withValues(alpha: 0.5), fontSize: 8, letterSpacing: 0.5)),
        ]),
      ]),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          child: GestureDetector(
            onTap: _toggleSession,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _session.isActive
                    ? const Color(0xFFFF3355).withValues(alpha: 0.15)
                    : const Color(0xFF00C896).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _session.isActive ? const Color(0xFFFF3355) : const Color(0xFF00C896),
                  width: 1.5,
                ),
              ),
              child: Text(
                _session.isActive ? 'STOP' : 'START',
                style: GoogleFonts.rajdhani(
                  color: _session.isActive ? const Color(0xFFFF3355) : const Color(0xFF00C896),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SESSION HEADER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSessionHeader(dynamic p) {
    final isUp = _session.totalPnl >= 0;
    final pnlColor = isUp ? const Color(0xFF00C896) : const Color(0xFFFF3355);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: p.surface,
      child: Row(
        children: [
          _buildStatChip('PnL', '\$${_session.totalPnl.toStringAsFixed(0)}', pnlColor),
          const SizedBox(width: 8),
          _buildStatChip('ROI', '${_session.roi.toStringAsFixed(1)}%', pnlColor),
          const SizedBox(width: 8),
          _buildStatChip('TRADES', '${_session.executedTrades}', Colors.grey[400]!),
          const SizedBox(width: 8),
          _buildStatChip('WIN%', '${(_session.winRate * 100).toStringAsFixed(0)}%', const Color(0xFF00C896)),
          const Spacer(),
          if (_session.isActive)
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C896).withValues(alpha: 0.1 + 0.05 * _pulseCtrl.value),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF00C896), shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('LIVE', style: GoogleFonts.spaceMono(color: const Color(0xFF00C896), fontSize: 9, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 8, letterSpacing: 0.5)),
        Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB BAR
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTabBar(dynamic p) {
    final tabs = [
      (Icons.bolt_rounded,       'SIGNALS',     const Color(0xFFFFB800)),
      (Icons.smart_toy_outlined, 'AGENTS',      const Color(0xFF4A90E2)),
      (Icons.account_tree_outlined, 'PIPELINE', const Color(0xFF9945FF)),
      (Icons.bar_chart_rounded,  'PERFORMANCE', const Color(0xFF00C896)),
    ];

    return Container(
      height: 48,
      color: p.surface,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () { _tabCtrl.animateTo(i); setState(() => _tab = i); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isActive ? tabs[i].$3 : Colors.transparent, width: 2.5)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(tabs[i].$1, size: 14, color: isActive ? tabs[i].$3 : Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(tabs[i].$2, style: TextStyle(
                    color: isActive ? tabs[i].$3 : Colors.grey[600],
                    fontSize: 8,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    letterSpacing: 0.5,
                  )),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 0: SIGNALS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSignalsTab(ExchangeService ex, dynamic p) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _signals.length,
      itemBuilder: (_, i) => _buildSignalCard(_signals[i], ex, p),
    );
  }

  Widget _buildSignalCard(AiSignal sig, ExchangeService ex, dynamic p) {
    final price = ex.getPrice(sig.symbol);
    final currentPrice = price > 0 ? price : sig.entryPrice;
    final isOpen = sig.outcome == null;
    final unrealPnl = sig.executed && isOpen
        ? (sig.side == SignalSide.buy
            ? (currentPrice - sig.entryPrice) / sig.entryPrice * 100
            : (sig.entryPrice - currentPrice) / sig.entryPrice * 100)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: sig.executed
              ? sig.outcome == true ? const Color(0xFF00C896).withValues(alpha: 0.3)
                : sig.outcome == false ? const Color(0xFFFF3355).withValues(alpha: 0.3)
                : sig.sideColor.withValues(alpha: 0.4)
              : sig.sideColor.withValues(alpha: 0.15),
          width: sig.executed ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                CryptoIcon(sig.symbol, size: 32, showBorder: false),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(sig.symbol, style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sig.sideColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: sig.sideColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(sig.sideLabel, style: TextStyle(
                            color: sig.sideColor, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
                        ),
                        const SizedBox(width: 6),
                        _buildRiskBadge(sig.risk),
                      ]),
                      const SizedBox(height: 2),
                      Text(sig.agentName, style: TextStyle(color: Colors.grey[500], fontSize: 9)),
                    ],
                  ),
                ),
                // Confidence arc
                _buildConfidenceCircle(sig.confidence),
              ],
            ),
          ),

          // Price levels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(children: [
              _buildPriceLevel('ENTRY', sig.entryPrice, Colors.white),
              const SizedBox(width: 8),
              _buildPriceLevel('TARGET', sig.targetPrice, const Color(0xFF00C896)),
              const SizedBox(width: 8),
              _buildPriceLevel('STOP', sig.stopLoss, const Color(0xFFFF3355)),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('R:R', style: TextStyle(color: Colors.grey[600], fontSize: 8)),
                Text('1:${sig.riskReward.toStringAsFixed(1)}',
                  style: GoogleFonts.spaceMono(
                    color: sig.riskReward >= 2 ? const Color(0xFF00C896) : const Color(0xFFFFB800),
                    fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ]),
          ),

          // Reasoning (collapsible)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(sig.reasoning,
                style: TextStyle(color: Colors.grey[400], fontSize: 9, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(children: [
              Icon(Icons.schedule, size: 11, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(_formatAgo(sig.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 9)),
              const Spacer(),
              if (sig.executed) ...[
                if (sig.outcome == null) // open
                  _buildPnlBadge('${unrealPnl >= 0 ? '+' : ''}${unrealPnl.toStringAsFixed(2)}%', unrealPnl >= 0)
                else if (sig.outcome == true)
                  _buildPnlBadge('\$+${sig.pnl?.toStringAsFixed(2) ?? '0.00'}', true)
                else
                  _buildPnlBadge('\$${sig.pnl?.toStringAsFixed(2) ?? '0.00'}', false),
                const SizedBox(width: 8),
              ],
              if (!sig.executed && _session.isActive)
                GestureDetector(
                  onTap: () => _executeSignal(sig),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sig.sideColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: sig.sideColor.withValues(alpha: 0.5)),
                    ),
                    child: Text('EXECUTE', style: TextStyle(color: sig.sideColor, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
              if (sig.executed)
                Row(children: [
                  Icon(
                    sig.outcome == null ? Icons.radio_button_checked : sig.outcome! ? Icons.check_circle : Icons.cancel,
                    size: 12,
                    color: sig.outcome == null ? const Color(0xFFFFB800) : sig.outcome! ? const Color(0xFF00C896) : const Color(0xFFFF3355),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sig.outcome == null ? 'OPEN' : sig.outcome! ? 'WIN' : 'LOSS',
                    style: TextStyle(
                      color: sig.outcome == null ? const Color(0xFFFFB800) : sig.outcome! ? const Color(0xFF00C896) : const Color(0xFFFF3355),
                      fontSize: 9, fontWeight: FontWeight.bold,
                    ),
                  ),
                ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(RiskLevel risk) {
    final (label, color) = switch (risk) {
      RiskLevel.low     => ('LOW',     const Color(0xFF00C896)),
      RiskLevel.medium  => ('MED',     const Color(0xFFFFB800)),
      RiskLevel.high    => ('HIGH',    const Color(0xFFFF7733)),
      RiskLevel.extreme => ('EXTREME', const Color(0xFFFF3355)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildConfidenceCircle(double conf) {
    final color = conf >= 0.75 ? const Color(0xFF00C896) : conf >= 0.55 ? const Color(0xFFFFB800) : const Color(0xFFFF3355);
    return SizedBox(
      width: 44, height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: conf,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(color),
            strokeWidth: 3,
          ),
          Text('${(conf * 100).toStringAsFixed(0)}%',
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
        ],
      ),
    );
  }

  Widget _buildPriceLevel(String label, double price, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 7, letterSpacing: 0.5)),
        Text(price >= 1000 ? '\$${price.toStringAsFixed(0)}' : '\$${price.toStringAsFixed(3)}',
          style: GoogleFonts.spaceMono(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPnlBadge(String text, bool isPositive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: (isPositive ? const Color(0xFF00C896) : const Color(0xFFFF3355)).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
        style: TextStyle(
          color: isPositive ? const Color(0xFF00C896) : const Color(0xFFFF3355),
          fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 1: AGENTS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAgentsTab(dynamic p) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _agents.length,
      itemBuilder: (_, i) => _buildAgentCard(_agents[i], p),
    );
  }

  Widget _buildAgentCard(StrategyAgent agent, dynamic p) {
    final statusColor = switch (agent.status) {
      AgentStatus.idle      => Colors.grey[600]!,
      AgentStatus.analyzing => const Color(0xFF4A90E2),
      AgentStatus.executing => const Color(0xFF00C896),
      AgentStatus.waiting   => const Color(0xFFFFB800),
      AgentStatus.error     => const Color(0xFFFF3355),
    };
    final typeColor = switch (agent.type) {
      'trend'          => const Color(0xFF00C896),
      'mean_reversion' => const Color(0xFF9945FF),
      'momentum'       => const Color(0xFFFFB800),
      'ml'             => const Color(0xFF4A90E2),
      'arbitrage'      => const Color(0xFFFF7733),
      _                => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: agent.enabled ? statusColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                // Status indicator
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: agent.enabled ? statusColor : Colors.grey[700]!,
                      boxShadow: agent.status == AgentStatus.executing ? [
                        BoxShadow(color: statusColor.withValues(alpha: 0.5 * _pulseCtrl.value), blurRadius: 8, spreadRadius: 1)
                      ] : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(agent.name,
                          style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: typeColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(agent.type.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(color: typeColor, fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ),
                      ]),
                      Text(agent.description,
                        style: TextStyle(color: Colors.grey[500], fontSize: 9, height: 1.4),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                // Enable toggle
                Switch(
                  value: agent.enabled,
                  onChanged: (v) => setState(() => agent.enabled = v),
                  activeColor: const Color(0xFF00C896),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _buildAgentStat('WIN RATE', '${(agent.winRate * 100).toStringAsFixed(0)}%', const Color(0xFF00C896)),
                const SizedBox(width: 16),
                _buildAgentStat('PnL', '\$${agent.totalPnl.toStringAsFixed(0)}', agent.totalPnl >= 0 ? const Color(0xFF00C896) : const Color(0xFFFF3355)),
                const SizedBox(width: 16),
                _buildAgentStat('TRADES', '${agent.totalTrades}', Colors.grey[400]!),
                const SizedBox(width: 16),
                _buildAgentStat('DAYS', '${agent.activeSince}', Colors.grey[400]!),
                const Spacer(),
                // Confidence bar
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('CONFIDENCE', style: TextStyle(color: Colors.grey[600], fontSize: 7)),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: agent.confidence,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(
                          agent.confidence >= 0.7 ? const Color(0xFF00C896) : agent.confidence >= 0.5 ? const Color(0xFFFFB800) : const Color(0xFFFF3355)
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  Text('${(agent.confidence * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.spaceMono(color: Colors.grey[400], fontSize: 8)),
                ]),
              ],
            ),
          ),

          // Pairs
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Row(
              children: agent.pairs.map((sym) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Row(children: [
                  CryptoIcon(sym, size: 16, showBorder: false),
                  const SizedBox(width: 3),
                  Text(sym, style: GoogleFonts.spaceMono(color: Colors.grey[500], fontSize: 8)),
                ]),
              )).toList(),
            ),
          ),

          // Last action
          Container(
            margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(Icons.terminal, size: 11, color: statusColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text('» ${agent.lastAction}',
                  style: TextStyle(color: statusColor, fontSize: 9, fontFamily: 'SpaceMono'),
                  overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentStat(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 7, letterSpacing: 0.3)),
      Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2: PIPELINE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPipelineTab(dynamic p) {
    final stages = [
      (
        icon: Icons.satellite_alt_rounded,
        label: 'MARKET DATA',
        sublabel: 'Binance WS + CoinGecko REST',
        color: const Color(0xFF4A90E2),
        details: ['Binance WebSocket: 15 pairs', 'CoinGecko REST: 25 coins/30s', 'Latency: <12ms', 'Uptime: 99.97%'],
      ),
      (
        icon: Icons.psychology_rounded,
        label: 'STRATEGY LAYER',
        sublabel: '6 agents · Multi-timeframe',
        color: const Color(0xFF9945FF),
        details: ['6 active strategy agents', 'Timeframes: 1m/5m/1h/4h/1d', 'Indicators: EMA, MACD, RSI, BB, ATR', 'ML ensemble: LSTM+XGBoost'],
      ),
      (
        icon: Icons.security_rounded,
        label: 'RISK ENGINE',
        sublabel: 'MiFID II · VAR-based limits',
        color: const Color(0xFFFF7733),
        details: ['Max position size: 2% equity', 'Daily VAR limit: 3%', 'Drawdown circuit breaker: -8%', 'Correlation filter: >0.85 blocked'],
      ),
      (
        icon: Icons.flash_on_rounded,
        label: 'EXECUTION',
        sublabel: 'OMS · CEX routing',
        color: const Color(0xFF00C896),
        details: ['Smart order routing: Binance/Kraken', 'Order types: Market, Limit, Stop', 'Slippage tolerance: 0.05%', 'Average fill time: 340ms'],
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Mode selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(children: ['CONSERVATIVE', 'BALANCED', 'AGGRESSIVE'].map((mode) {
              final isSel = _session.mode == mode.toLowerCase();
              final color = mode == 'CONSERVATIVE' ? const Color(0xFF00C896)
                  : mode == 'BALANCED' ? const Color(0xFF4A90E2) : const Color(0xFFFF3355);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _session.mode = mode.toLowerCase()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? color.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      border: isSel ? Border.all(color: color.withValues(alpha: 0.5)) : null,
                    ),
                    child: Center(
                      child: Text(mode, style: TextStyle(
                        color: isSel ? color : Colors.grey[500],
                        fontSize: 10,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        letterSpacing: 0.5,
                      )),
                    ),
                  ),
                ),
              );
            }).toList()),
          ),
          const SizedBox(height: 20),

          // Pipeline stages
          ...List.generate(stages.length, (i) {
            final stage = stages[i];
            final isActive = _session.isActive && _pipelineStep == i;
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: isActive ? stage.color.withValues(alpha: 0.1) : p.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive ? stage.color : Colors.white.withValues(alpha: 0.06),
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow: isActive ? [BoxShadow(color: stage.color.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 0)] : null,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: stage.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(stage.icon, color: stage.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(stage.label,
                                style: TextStyle(color: stage.color, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              if (isActive) ...[
                                const SizedBox(width: 8),
                                AnimatedBuilder(
                                  animation: _scanCtrl,
                                  builder: (_, __) => Container(
                                    width: 40, height: 4,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(2)),
                                    clipBehavior: Clip.antiAlias,
                                    child: LinearProgressIndicator(
                                      value: _scanCtrl.value,
                                      backgroundColor: stage.color.withValues(alpha: 0.1),
                                      valueColor: AlwaysStoppedAnimation(stage.color),
                                    ),
                                  ),
                                ),
                              ],
                            ]),
                            Text(stage.sublabel,
                              style: TextStyle(color: Colors.grey[500], fontSize: 9)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6, runSpacing: 4,
                              children: stage.details.map((d) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(d, style: TextStyle(color: Colors.grey[400], fontSize: 8)),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color: stage.color.withValues(alpha: isActive ? 0.3 : 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                            style: TextStyle(color: stage.color, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < stages.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: AnimatedBuilder(
                      animation: _scanCtrl,
                      builder: (_, __) {
                        final active = _session.isActive && _pipelineStep == i;
                        return Column(
                          children: List.generate(3, (dot) => Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            width: 4, height: 4,
                            decoration: BoxDecoration(
                              color: active
                                  ? stages[i].color.withValues(alpha: _scanCtrl.value > dot / 3 ? 1.0 : 0.2)
                                  : Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                          )),
                        );
                      },
                    ),
                  ),
              ],
            );
          }),

          const SizedBox(height: 20),
          _buildActionButton(
            label: _session.isActive ? 'STOP ORCHESTRATOR' : 'START ORCHESTRATOR',
            color: _session.isActive ? const Color(0xFFFF3355) : const Color(0xFF00C896),
            icon: _session.isActive ? Icons.stop_circle_outlined : Icons.play_circle_outline,
            onTap: _toggleSession,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 3: PERFORMANCE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPerformanceTab(dynamic p) {
    final dailyPnl = [42.5, -18.3, 87.2, 34.1, -12.8, 156.4, 89.3, -45.2, 234.8, 67.4, 123.5, 89.0, -34.7, 78.3, 145.2, 92.8, -67.1, 187.4, 56.3, 201.7, 134.5, -23.8, 78.9, 167.3, 89.4, 45.2, -12.3, 234.1, 156.8, 89.5];
    final cumPnl = <double>[0];
    for (final d in dailyPnl) { cumPnl.add(cumPnl.last + d); }

    final maxDrawdown = -8.3;
    final sharpe = 1.84;
    final sortino = 2.31;
    final calmar = 1.17;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.0,
            children: [
              _buildKpiCard('TOTAL PnL', '\$${_session.totalPnl.toStringAsFixed(0)}', _session.totalPnl >= 0 ? const Color(0xFF00C896) : const Color(0xFFFF3355)),
              _buildKpiCard('ROI', '${_session.roi.toStringAsFixed(1)}%', const Color(0xFF4A90E2)),
              _buildKpiCard('WIN RATE', '${(_session.winRate * 100).toStringAsFixed(0)}%', const Color(0xFF00C896)),
              _buildKpiCard('SHARPE', sharpe.toStringAsFixed(2), const Color(0xFFFFB800)),
              _buildKpiCard('MAX DD', '$maxDrawdown%', const Color(0xFFFF3355)),
              _buildKpiCard('SORTINO', sortino.toStringAsFixed(2), const Color(0xFF9945FF)),
              _buildKpiCard('CALMAR', calmar.toStringAsFixed(2), const Color(0xFF00C896)),
              _buildKpiCard('SIGNALS', '${_session.totalSignals}', Colors.grey[400]!),
            ],
          ),

          const SizedBox(height: 20),

          // Cumulative PnL chart (simple bar chart)
          Text('CUMULATIVE PnL (30 DAYS)', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Container(
            height: 130,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyPnl.asMap().entries.map((e) {
                final isUp = e.value >= 0;
                final maxAbs = dailyPnl.map((v) => v.abs()).reduce(max);
                final ratio = maxAbs > 0 ? e.value.abs() / maxAbs : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 80 * ratio + 4,
                        decoration: BoxDecoration(
                          color: (isUp ? const Color(0xFF00C896) : const Color(0xFFFF3355)).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Agent performance breakdown
          Text('AGENT PERFORMANCE', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          ..._agents.map((a) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(children: [
              Container(
                width: 6, height: 30,
                decoration: BoxDecoration(
                  color: a.totalPnl >= 0 ? const Color(0xFF00C896) : const Color(0xFFFF3355),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  Text('${a.totalTrades} trades · ${a.activeSince}d active',
                    style: TextStyle(color: Colors.grey[500], fontSize: 8)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('\$${a.totalPnl.toStringAsFixed(0)}',
                  style: GoogleFonts.spaceMono(
                    color: a.totalPnl >= 0 ? const Color(0xFF00C896) : const Color(0xFFFF3355),
                    fontSize: 12, fontWeight: FontWeight.bold)),
                Text('${(a.winRate * 100).toStringAsFixed(0)}% win',
                  style: TextStyle(color: Colors.grey[500], fontSize: 9)),
              ]),
              const SizedBox(width: 12),
              SizedBox(
                width: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: a.winRate,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation(
                      a.winRate >= 0.7 ? const Color(0xFF00C896) : const Color(0xFFFFB800)
                    ),
                    minHeight: 5,
                  ),
                ),
              ),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 8, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────────────────────────────────

  void _toggleSession() {
    setState(() {
      _session.isActive = !_session.isActive;
      if (_session.isActive) {
        _session.startedAt = DateTime.now();
        _pipelineActive = true;
        _session.activeAgents = _agents.where((a) => a.enabled).map((a) => a.id).toList();
        _showSuccessSnack('AI Orchestrator started. ${_session.activeAgents.length} agents active.');
      } else {
        _pipelineActive = false;
        _showSnack('AI Orchestrator stopped. Session saved.');
      }
    });
  }

  void _executeSignal(AiSignal sig) {
    setState(() {
      sig.executed = true;
      _session.executedTrades++;
      // Simulate outcome
      final win = _rnd.nextDouble() < 0.65;
      sig.outcome = win;
      sig.pnl = win ? (sig.riskReward * 50) : -50.0;
      if (win) {
        _session.wins++;
        _session.realizedPnl += sig.pnl!;
      } else {
        _session.losses++;
        _session.realizedPnl += sig.pnl!;
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 12)),
      backgroundColor: const Color(0xFF1E2028),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Color(0xFF00C896), size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 11))),
      ]),
      backgroundColor: const Color(0xFF0D1F17),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _buildActionButton({required String label, required Color color, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.8), color]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 0, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ]),
      ),
    );
  }

  String _formatAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
