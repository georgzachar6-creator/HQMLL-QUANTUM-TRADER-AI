import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/exchange_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// AI PORTFOLIO REBALANCER SCREEN v2 (v27.0)
// Quantum Trader AI — Live Prices via ExchangeService · Smart AI-driven portfolio optimization
// ════════════════════════════════════════════════════════════════════════════

class RebalancerScreen extends StatefulWidget {
  const RebalancerScreen({super.key});
  @override
  State<RebalancerScreen> createState() => _RebalancerScreenState();
}

class _RebalancerScreenState extends State<RebalancerScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _aiAnim;
  late AnimationController _pulseAnim;
  late Animation<double> _aiGlow;
  late Animation<double> _pulse; // ignore: unused_field

  // v27.0: Static fallback prices (overridden by ExchangeService in build)
  // ignore: unused_field
  static const Map<String, double> _fallbackPrices = {
    'BTC': 67842.0, 'ETH': 3548.0, 'SOL': 185.4, 'BNB': 620.0,
    'ADA': 0.485, 'DOT': 7.2, 'AVAX': 38.5, 'LINK': 17.8,
  };

  // Portfolio Allocation data — prices updated by ExchangeService
  final List<_AssetAlloc> _current = [
    _AssetAlloc('BTC', 'Bitcoin', 38.5, 0.3850, Colors.orange, 67842.0),
    _AssetAlloc('ETH', 'Ethereum', 22.3, 0.2230, const Color(0xFF627EEA), 3548.0),
    _AssetAlloc('SOL', 'Solana', 11.8, 0.1180, const Color(0xFF9945FF), 185.4),
    _AssetAlloc('BNB', 'BNB', 8.6, 0.0860, const Color(0xFFF3BA2F), 620.0),
    _AssetAlloc('ADA', 'Cardano', 5.4, 0.0540, const Color(0xFF0033AD), 0.485),
    _AssetAlloc('DOT', 'Polkadot', 4.2, 0.0420, const Color(0xFFE6007A), 7.2),
    _AssetAlloc('AVAX', 'Avalanche', 3.9, 0.0390, const Color(0xFFE84142), 38.5),
    _AssetAlloc('LINK', 'Chainlink', 3.1, 0.0310, const Color(0xFF2A5ADA), 17.8),
    _AssetAlloc('Other', 'Others', 2.2, 0.0220, Colors.grey, 0.0),
  ];

  // AI-Suggested optimal allocations
  final List<_AssetAlloc> _target = [
    _AssetAlloc('BTC', 'Bitcoin', 30.0, 0.3000, Colors.orange, 67842.0),
    _AssetAlloc('ETH', 'Ethereum', 25.0, 0.2500, const Color(0xFF627EEA), 3548.0),
    _AssetAlloc('SOL', 'Solana', 15.0, 0.1500, const Color(0xFF9945FF), 185.4),
    _AssetAlloc('BNB', 'BNB', 8.0, 0.0800, const Color(0xFFF3BA2F), 620.0),
    _AssetAlloc('ADA', 'Cardano', 4.0, 0.0400, const Color(0xFF0033AD), 0.485),
    _AssetAlloc('DOT', 'Polkadot', 5.0, 0.0500, const Color(0xFFE6007A), 7.2),
    _AssetAlloc('AVAX', 'Avalanche', 7.0, 0.0700, const Color(0xFFE84142), 38.5),
    _AssetAlloc('LINK', 'Chainlink', 4.0, 0.0400, const Color(0xFF2A5ADA), 17.8),
    _AssetAlloc('Other', 'Others', 2.0, 0.0200, Colors.grey, 0.0),
  ];

  // AI Strategy Profiles
  final List<_Strategy> _strategies = [
    const _Strategy('Konservativ', 'Niedrig', 12.4, 0.62, 'BTC/ETH fokussiert, minimales Risiko', Icons.shield_outlined, Color(0xFF00C896)),
    const _Strategy('Ausgewogen', 'Mittel', 28.7, 1.24, 'Diversifiziert über Top-20 Assets', Icons.balance, Color(0xFF00D4FF)),
    const _Strategy('Wachstum', 'Hoch', 45.2, 1.87, 'Wachstums-Assets und DeFi-Protokolle', Icons.trending_up, Color(0xFFFF6B35)),
    const _Strategy('Aggressiv', 'Sehr hoch', 89.3, 2.41, 'Alt-Coins und Micro-Caps', Icons.rocket_launch, Color(0xFFFF0080)),
    const _Strategy('AI Optimal', 'KI-gesteuert', 34.1, 1.56, 'Quantales AI-Modell Empfehlung', Icons.auto_awesome, Color(0xFFFFD700)),
  ];
  int _selectedStrategy = 4;

  // Rebalancing trades — prices updated by ExchangeService in build
  final List<_RebTrade> _trades = [
    _RebTrade('ETH', 'Kaufen', 2.153, 3548.0, 7637.0, true),
    _RebTrade('SOL', 'Kaufen', 17.4, 185.4, 3226.0, true),
    _RebTrade('AVAX', 'Kaufen', 8.05, 38.5, 309.8, true),
    _RebTrade('BTC', 'Verkaufen', 0.126, 67842.0, 8548.1, false),
    _RebTrade('ADA', 'Verkaufen', 2887.6, 0.485, 1400.5, false),
    _RebTrade('LINK', 'Kaufen', 5.06, 17.8, 90.1, true),
  ];

  // AI Insights
  final List<_Insight> _insights = [
    const _Insight('Übergewicht BTC', 'BTC ist 8.5% übergewichtet gegenüber optimalem Niveau. Reduzierung empfohlen.', 0.85, Icons.warning_amber, Colors.orange, 'HOCH'),
    const _Insight('ETH Momentum stark', 'ETH zeigt Bull-Signal auf allen Timeframes. Erhöhung auf 25% erhöht Sharpe Ratio.', 0.92, Icons.trending_up, Color(0xFF627EEA), 'SIGNAL'),
    const _Insight('SOL DeFi Wachstum', 'SOL-Ökosystem wächst 340% YoY. Untergewichtet mit Upside-Potenzial.', 0.78, Icons.bolt, Color(0xFF9945FF), 'CHANCE'),
    const _Insight('Korrelationsrisiko', 'BNB/AVAX zeigen hohe Korrelation (0.87). Diversifikation verbessern.', 0.71, Icons.link, Colors.yellow, 'RISIKO'),
    const _Insight('Sharpe Ratio Optimierung', 'Ziel-Portfolio verbessert Sharpe Ratio von 1.24 → 1.56 (+25.8%).', 0.96, Icons.auto_awesome, Color(0xFFFFD700), 'AI'),
  ];

  double _portfolioValue = 87432.0;
  bool _isAnalyzing = false;
  final bool _showTrades = false; // ignore: unused_field
  double _slippage = 0.5;
  double _maxTradePct = 15.0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _aiAnim = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _aiGlow = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _aiAnim, curve: Curves.easeInOut),
    );
    _pulse = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseAnim, curve: Curves.easeInOut),
    );
    // v34.0: Sofort beim ersten Frame live Preise in Allokationen laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ex = context.read<ExchangeService>();
      setState(() => _syncPricesFromExchange(ex));
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _aiAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  void _runAIAnalysis() {
    setState(() => _isAnalyzing = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isAnalyzing = false);
    });
  }

  /// v27.0: Sync allocation prices from ExchangeService
  void _syncPricesFromExchange(ExchangeService ex) {
    bool changed = false;
    for (final alloc in _current) {
      final livePrice = ex.getPrice(alloc.symbol);
      if (livePrice > 0 && (livePrice - alloc.price).abs() / alloc.price > 0.001) {
        alloc.price = livePrice;
        changed = true;
      }
    }
    for (final alloc in _target) {
      final livePrice = ex.getPrice(alloc.symbol);
      if (livePrice > 0) alloc.price = livePrice;
    }
    for (final trade in _trades) {
      final livePrice = ex.getPrice(trade.symbol);
      if (livePrice > 0) {
        trade.price = livePrice;
        trade.value = trade.qty * livePrice;
      }
    }
    if (changed) {
      // Recalculate portfolio value with live prices
      double newValue = 0;
      for (final alloc in _current) {
        if (alloc.symbol != 'Other') {
          final qty = _portfolioValue * alloc.weight / (alloc.price > 0 ? alloc.price : 1);
          newValue += qty * alloc.price;
        }
      }
      if (newValue > 50000) _portfolioValue = newValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>();
    final pal = p.palette;
    // v27.0: ExchangeService live prices for portfolio rebalancing
    final ex = context.watch<ExchangeService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPricesFromExchange(ex);
    });

    return Scaffold(
      backgroundColor: pal.background,
      appBar: _buildAppBar(pal),
      body: Column(
        children: [
          _buildPortfolioSummary(pal),
          _buildTabBar(pal),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildAllocationTab(pal),
                _buildStrategyTab(pal),
                _buildTradesTab(pal),
                _buildInsightsTab(pal),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(pal),
    );
  }

  AppBar _buildAppBar(dynamic pal) {
    return AppBar(
      backgroundColor: pal.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: pal.accent),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(
        children: [
          AnimatedBuilder(
            animation: _aiGlow,
            builder: (_, __) => Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: _aiGlow.value),
                    const Color(0xFFFF6B35).withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Rebalancer',
                  style: GoogleFonts.spaceMono(
                      color: pal.text, fontSize: 14, fontWeight: FontWeight.bold)),
              Text('Quantum Portfolio Engine',
                  style: GoogleFonts.spaceMono(color: pal.accent, fontSize: 9)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: pal.accent),
          onPressed: _runAIAnalysis,
          tooltip: 'AI Analyse',
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: pal.accent),
          onPressed: () => _showSettings(pal),
        ),
      ],
    );
  }

  Widget _buildPortfolioSummary(dynamic pal) {
    final currentSharpe = _strategies[_selectedStrategy].sharpe;
    const targetSharpe = 1.56;
    final improvement = ((targetSharpe - currentSharpe) / currentSharpe * 100).abs();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.15),
            const Color(0xFFFF6B35).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statBox(pal, 'Portfolio', '\$${(_portfolioValue / 1000).toStringAsFixed(1)}K',
              const Color(0xFFFFD700)),
          _statBox(pal, 'Sharpe Ratio', currentSharpe.toStringAsFixed(2),
              const Color(0xFF00C896)),
          _statBox(pal, 'AI Verbesserung', '+${improvement.toStringAsFixed(1)}%',
              const Color(0xFF00D4FF)),
          _statBox(pal, 'Trades', '${_trades.length} nötig',
              const Color(0xFFFF6B35)),
        ],
      ),
    );
  }

  Widget _statBox(dynamic pal, String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.spaceMono(
                color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.spaceMono(color: pal.textSecondary, fontSize: 9)),
      ],
    );
  }

  Widget _buildTabBar(dynamic pal) {
    return Container(
      color: pal.surface,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: const Color(0xFFFFD700),
        labelColor: const Color(0xFFFFD700),
        unselectedLabelColor: pal.textSecondary,
        labelStyle: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'ALLOKATION'),
          Tab(text: 'STRATEGIE'),
          Tab(text: 'TRADES'),
          Tab(text: 'AI INSIGHTS'),
        ],
      ),
    );
  }

  // ── TAB 1: ALLOCATION ────────────────────────────────────────────────────
  Widget _buildAllocationTab(dynamic pal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildPieSection(pal, 'AKTUELL', _current)),
              const SizedBox(width: 12),
              Expanded(child: _buildPieSection(pal, 'AI ZIEL', _target, isTarget: true)),
            ],
          ),
          const SizedBox(height: 16),
          _buildAllocationTable(pal),
        ],
      ),
    );
  }

  Widget _buildPieSection(dynamic pal, String title, List<_AssetAlloc> allocs,
      {bool isTarget = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTarget
              ? const Color(0xFFFFD700).withValues(alpha: 0.4)
              : pal.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: GoogleFonts.spaceMono(
                      color: isTarget ? const Color(0xFFFFD700) : pal.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              if (isTarget)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('AI',
                      style: GoogleFonts.spaceMono(
                          color: const Color(0xFFFFD700), fontSize: 8,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: _PiePainter(allocs),
              size: const Size(140, 140),
            ),
          ),
          const SizedBox(height: 12),
          ...allocs.take(5).map((a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration:
                            BoxDecoration(color: a.color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(a.symbol,
                        style: GoogleFonts.spaceMono(
                            color: pal.text, fontSize: 9,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${a.pct.toStringAsFixed(1)}%',
                        style: GoogleFonts.spaceMono(
                            color: a.color, fontSize: 9)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAllocationTable(dynamic pal) {
    return Container(
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.compare_arrows, color: pal.accent, size: 16),
                const SizedBox(width: 8),
                Text('ALLOKATIONS VERGLEICH',
                    style: GoogleFonts.spaceMono(
                        color: pal.text, fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('ASSET',
                        style: GoogleFonts.spaceMono(
                            color: pal.textSecondary, fontSize: 9))),
                Expanded(
                    child: Text('IST %',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceMono(
                            color: pal.textSecondary, fontSize: 9))),
                Expanded(
                    child: Text('SOLL %',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceMono(
                            color: const Color(0xFFFFD700), fontSize: 9))),
                Expanded(
                    child: Text('DELTA',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.spaceMono(
                            color: pal.textSecondary, fontSize: 9))),
              ],
            ),
          ),
          const Divider(height: 1),
          ...List.generate(_current.length, (i) {
            final cur = _current[i];
            final tgt = _target[i];
            final delta = tgt.pct - cur.pct;
            final color = delta > 0 ? const Color(0xFF00C896) : Colors.red;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: pal.text.withValues(alpha: 0.05))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: cur.color, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(cur.symbol,
                            style: GoogleFonts.spaceMono(
                                color: pal.text,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text('${cur.pct.toStringAsFixed(1)}%',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceMono(
                            color: pal.text, fontSize: 10)),
                  ),
                  Expanded(
                    child: Text('${tgt.pct.toStringAsFixed(1)}%',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceMono(
                            color: const Color(0xFFFFD700), fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text(
                        '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}%',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.spaceMono(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── TAB 2: STRATEGY ──────────────────────────────────────────────────────
  Widget _buildStrategyTab(dynamic pal) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('AI STRATEGIE PROFILE',
            style: GoogleFonts.spaceMono(
                color: pal.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._strategies.asMap().entries.map((e) {
          final idx = e.key;
          final s = e.value;
          final selected = idx == _selectedStrategy;
          return GestureDetector(
            onTap: () => setState(() => _selectedStrategy = idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected
                    ? s.color.withValues(alpha: 0.15)
                    : pal.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? s.color
                      : s.color.withValues(alpha: 0.3),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.color.withValues(alpha: 0.2),
                    ),
                    child: Icon(s.icon, color: s.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(s.name,
                                style: GoogleFonts.spaceMono(
                                    color: pal.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: s.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(s.risk,
                                  style: GoogleFonts.spaceMono(
                                      color: s.color, fontSize: 9,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(s.desc,
                            style: GoogleFonts.spaceMono(
                                color: pal.textSecondary, fontSize: 9)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _miniStat('Erw. Rendite', '${s.expectedReturn.toStringAsFixed(1)}%',
                                const Color(0xFF00C896)),
                            const SizedBox(width: 16),
                            _miniStat('Sharpe', s.sharpe.toStringAsFixed(2),
                                const Color(0xFF00D4FF)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, color: s.color, size: 24),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        _buildRiskSliders(pal),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: GoogleFonts.spaceMono(
                color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(label,
            style: GoogleFonts.spaceMono(
                color: Colors.grey, fontSize: 8)),
      ],
    );
  }

  Widget _buildRiskSliders(dynamic pal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REBALANCING EINSTELLUNGEN',
              style: GoogleFonts.spaceMono(
                  color: pal.text, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _slider(pal, 'Max Trade Größe', _maxTradePct, 5, 50, '%',
              (v) => setState(() => _maxTradePct = v)),
          const SizedBox(height: 12),
          _slider(pal, 'Max Slippage', _slippage, 0.1, 2.0, '%',
              (v) => setState(() => _slippage = v)),
        ],
      ),
    );
  }

  Widget _slider(dynamic pal, String label, double value, double min, double max,
      String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.spaceMono(
                    color: pal.textSecondary, fontSize: 10)),
            Text('${value.toStringAsFixed(1)}$unit',
                style: GoogleFonts.spaceMono(
                    color: const Color(0xFFFFD700),
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: const Color(0xFFFFD700),
          inactiveColor: pal.text.withValues(alpha: 0.1),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ── TAB 3: TRADES ────────────────────────────────────────────────────────
  Widget _buildTradesTab(dynamic pal) {
    final totalBuy = _trades.where((t) => t.isBuy).fold(0.0, (s, t) => s + t.value);
    final totalSell = _trades.where((t) => !t.isBuy).fold(0.0, (s, t) => s + t.value);
    final estFees = (totalBuy + totalSell) * 0.001;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
                child: _tradeStatCard(pal, 'KAUFEN',
                    '\$${(totalBuy / 1000).toStringAsFixed(1)}K',
                    const Color(0xFF00C896),
                    _trades.where((t) => t.isBuy).length)),
            const SizedBox(width: 10),
            Expanded(
                child: _tradeStatCard(pal, 'VERKAUFEN',
                    '\$${(totalSell / 1000).toStringAsFixed(1)}K',
                    Colors.redAccent,
                    _trades.where((t) => !t.isBuy).length)),
            const SizedBox(width: 10),
            Expanded(
                child: _tradeStatCard(pal, 'EST. GEBÜHREN',
                    '\$${estFees.toStringAsFixed(0)}',
                    Colors.amber,
                    _trades.length)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: pal.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('REBALANCING TRADES',
                      style: GoogleFonts.spaceMono(
                          color: pal.text,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('AI GENERIERT',
                        style: GoogleFonts.spaceMono(
                            color: const Color(0xFF00D4FF),
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._trades.map((t) => _buildTradeRow(pal, t)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Execute button
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFF6B35)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showExecuteDialog(pal),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, color: Colors.black, size: 20),
                    const SizedBox(width: 8),
                    Text('REBALANCING AUSFÜHREN',
                        style: GoogleFonts.spaceMono(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tradeStatCard(dynamic pal, String label, String value, Color color, int count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: GoogleFonts.spaceMono(
                  color: color, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.spaceMono(
                  color: pal.text, fontSize: 14, fontWeight: FontWeight.bold)),
          Text('$count Trades',
              style: GoogleFonts.spaceMono(color: pal.textSecondary, fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildTradeRow(dynamic pal, _RebTrade t) {
    final color = t.isBuy ? const Color(0xFF00C896) : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: pal.text.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Center(
              child: Text(t.symbol,
                  style: GoogleFonts.spaceMono(
                      color: color, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(t.action,
                        style: GoogleFonts.spaceMono(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Text(t.symbol,
                        style: GoogleFonts.spaceMono(
                            color: pal.text,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(
                    '${t.qty.toStringAsFixed(3)} @ \$${t.price.toStringAsFixed(0)}',
                    style: GoogleFonts.spaceMono(
                        color: pal.textSecondary, fontSize: 9)),
              ],
            ),
          ),
          Text('\$${t.value.toStringAsFixed(0)}',
              style: GoogleFonts.spaceMono(
                  color: pal.text, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── TAB 4: AI INSIGHTS ───────────────────────────────────────────────────
  Widget _buildInsightsTab(dynamic pal) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // AI confidence meter
        _buildAIConfidenceMeter(pal),
        const SizedBox(height: 16),
        Text('AI ANALYSE ERGEBNISSE',
            style: GoogleFonts.spaceMono(
                color: pal.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ..._insights.map((ins) => _buildInsightCard(pal, ins)),
        const SizedBox(height: 16),
        _buildRiskMetrics(pal),
      ],
    );
  }

  Widget _buildAIConfidenceMeter(dynamic pal) {
    return AnimatedBuilder(
      animation: _aiGlow,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFD700).withValues(alpha: 0.1 + _aiGlow.value * 0.08),
              const Color(0xFFFF6B35).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFD700)
                .withValues(alpha: 0.3 + _aiGlow.value * 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome,
                    color: Color(0xFFFFD700), size: 20),
                const SizedBox(width: 8),
                Text('QUANTUM AI CONFIDENCE',
                    style: GoogleFonts.spaceMono(
                        color: const Color(0xFFFFD700),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: 0.87,
                    strokeWidth: 8,
                    backgroundColor:
                        pal.text.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
                  ),
                ),
                Column(
                  children: [
                    Text('87%',
                        style: GoogleFonts.spaceMono(
                            color: const Color(0xFFFFD700),
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                    Text('KONFIDENZ',
                        style: GoogleFonts.spaceMono(
                            color: pal.textSecondary, fontSize: 8)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Basierend auf 47 Marktindikatoren, on-chain Daten & Sentiment',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceMono(
                    color: pal.textSecondary, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(dynamic pal, _Insight ins) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ins.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ins.icon, color: ins.color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(ins.title,
                    style: GoogleFonts.spaceMono(
                        color: pal.text,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ins.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(ins.tag,
                    style: GoogleFonts.spaceMono(
                        color: ins.color,
                        fontSize: 8,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(ins.desc,
              style: GoogleFonts.spaceMono(
                  color: pal.textSecondary, fontSize: 9, height: 1.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('KONFIDENZ: ',
                  style: GoogleFonts.spaceMono(
                      color: pal.textSecondary, fontSize: 8)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ins.confidence,
                    backgroundColor: pal.text.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(ins.color),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(ins.confidence * 100).toInt()}%',
                  style: GoogleFonts.spaceMono(
                      color: ins.color, fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskMetrics(dynamic pal) {
    final metrics = [
      ('Sharpe Ratio', '1.56', const Color(0xFF00C896), '▲ +0.32'),
      ('Sortino Ratio', '2.14', const Color(0xFF00D4FF), '▲ +0.41'),
      ('Max Drawdown', '-18.3%', Colors.orange, '▼ -4.2%'),
      ('Beta', '0.87', Colors.purple, '▼ -0.13'),
      ('Volatilität', '24.6%', Colors.amber, '▼ -3.1%'),
      ('Value at Risk', '-5.2%', Colors.red, '▲ +1.3%'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RISIKO METRIKEN (ZIEL vs IST)',
              style: GoogleFonts.spaceMono(
                  color: pal.text, fontSize: 11,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.5,
            children: metrics.map((m) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: m.$3.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: m.$3.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(m.$2,
                            style: GoogleFonts.spaceMono(
                                color: m.$3,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        Text(m.$4,
                            style: GoogleFonts.spaceMono(
                                color: m.$4.startsWith('▲')
                                    ? const Color(0xFF00C896)
                                    : Colors.red,
                                fontSize: 8)),
                      ],
                    ),
                    Text(m.$1,
                        style: GoogleFonts.spaceMono(
                            color: pal.textSecondary, fontSize: 8)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── DIALOGS ──────────────────────────────────────────────────────────────
  void _showExecuteDialog(dynamic pal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pal.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.bolt, color: Color(0xFFFFD700), size: 20),
            const SizedBox(width: 8),
            Text('Rebalancing ausführen?',
                style: GoogleFonts.spaceMono(
                    color: pal.text, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
            '${_trades.length} Trades werden ausgeführt.\n'
            'Geschätzte Gebühren: \$${((_trades.fold(0.0, (s, t) => s + t.value) * 0.001)).toStringAsFixed(0)}\n\n'
            'Dies ist eine Demo-Version. In der Live-Version würden diese Trades über deine konfigurierten Broker ausgeführt.',
            style: GoogleFonts.spaceMono(color: pal.textSecondary, fontSize: 10)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ABBRECHEN',
                style: GoogleFonts.spaceMono(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('✅ Rebalancing initiiert (Demo)',
                    style: GoogleFonts.spaceMono()),
                backgroundColor: const Color(0xFFFFD700),
              ));
            },
            child: Text('AUSFÜHREN',
                style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSettings(dynamic pal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: pal.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REBALANCER EINSTELLUNGEN',
                style: GoogleFonts.spaceMono(
                    color: pal.text, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.refresh, color: pal.accent),
              title: Text('Auto-Rebalancing', style: GoogleFonts.spaceMono(color: pal.text)),
              subtitle: Text('Monatlich', style: GoogleFonts.spaceMono(color: pal.textSecondary, fontSize: 10)),
              trailing: Switch(value: false, onChanged: (_) {}, activeThumbColor: const Color(0xFFFFD700)),
            ),
            ListTile(
              leading: Icon(Icons.notifications, color: pal.accent),
              title: Text('Drift-Alarm', style: GoogleFonts.spaceMono(color: pal.text)),
              subtitle: Text('Bei >5% Abweichung', style: GoogleFonts.spaceMono(color: pal.textSecondary, fontSize: 10)),
              trailing: Switch(value: true, onChanged: (_) {}, activeThumbColor: const Color(0xFFFFD700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(dynamic pal) {
    if (_isAnalyzing) {
      return FloatingActionButton.extended(
        onPressed: null,
        backgroundColor: const Color(0xFFFFD700),
        label: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.black),
            ),
            const SizedBox(width: 8),
            Text('ANALYSIERE...',
                style: GoogleFonts.spaceMono(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    return FloatingActionButton.extended(
      onPressed: _runAIAnalysis,
      backgroundColor: const Color(0xFFFFD700),
      icon: const Icon(Icons.auto_awesome, color: Colors.black),
      label: Text('AI ANALYSE',
          style: GoogleFonts.spaceMono(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

// ── DATA MODELS ──────────────────────────────────────────────────────────────

class _AssetAlloc {
  final String symbol;
  final String name;
  final double pct;
  final double weight;
  final Color color;
  double price; // v27.0: mutable — updated by ExchangeService
  _AssetAlloc(this.symbol, this.name, this.pct, this.weight, this.color, this.price);
}

class _Strategy {
  final String name;
  final String risk;
  final double expectedReturn;
  final double sharpe;
  final String desc;
  final IconData icon;
  final Color color;
  const _Strategy(this.name, this.risk, this.expectedReturn, this.sharpe,
      this.desc, this.icon, this.color);
}

class _RebTrade {
  final String symbol;
  final String action;
  final double qty; // v27.0: renamed from amount for clarity
  double price;     // v27.0: mutable — updated by ExchangeService
  double value;     // v27.0: mutable — qty * live price
  final bool isBuy;
  _RebTrade(this.symbol, this.action, this.qty, this.price, this.value, this.isBuy);
}

class _Insight {
  final String title;
  final String desc;
  final double confidence;
  final IconData icon;
  final Color color;
  final String tag;
  const _Insight(this.title, this.desc, this.confidence, this.icon,
      this.color, this.tag);
}

// ── CUSTOM PAINTERS ──────────────────────────────────────────────────────────

class _PiePainter extends CustomPainter {
  final List<_AssetAlloc> allocs;
  const _PiePainter(this.allocs);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final innerRadius = radius * 0.55;

    double startAngle = -pi / 2;

    for (final a in allocs) {
      final sweepAngle = 2 * pi * (a.pct / 100);
      final paint = Paint()
        ..color = a.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = (radius - innerRadius);

      final midRadius = (radius + innerRadius) / 2;
      final path = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: midRadius),
          startAngle,
          sweepAngle - 0.04,
        );
      canvas.drawPath(path, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
