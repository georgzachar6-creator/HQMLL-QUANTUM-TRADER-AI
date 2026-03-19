import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/theme_provider.dart';
import '../widgets/quantum_eye_widget.dart';

class TokenScreen extends StatefulWidget {
  const TokenScreen({super.key});
  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen>
    with TickerProviderStateMixin {
  late AnimationController _mineCtrl;
  late AnimationController _questCtrl;
  late Timer _miningTimer;
  late Timer _priceTimer;

  double _miningProgress = 0.67;
  double _totalMined = 1284.0;
  double _todayMined = 47.5;
  double _livePrice = 0.0847;
  bool _liveTrend = true;
  int _selectedQuest = -1;
  int _questCountdown = 847; // Sekunden bis zur nächsten Quest
  final Random _rnd = Random(99);

  final List<_Quest> _quests = [
    _Quest('BTC-Trendanalyse', 'Analysiere den aktuellen BTC-Trend mit Emma', 10, false, Icons.show_chart),
    _Quest('Sentiment-Rätsel', 'Beantworte 3 Marktfragen korrekt', 15, false, Icons.psychology),
    _Quest('Resonanz-Kalibrierung', 'Bestätige 5 Quantum-Signale', 25, true, Icons.waves),
    _Quest('Portfolio-Optimierung', 'Folge Emmas Rebalancing-Empfehlung', 20, false, Icons.pie_chart),
    _Quest('Agenten-Debatte', 'Beobachte alle 6 Agenten-Insights', 30, false, Icons.hub),
    _Quest('Whale-Tracking', 'Verfolge 3 Whale-Transaktionen', 18, false, Icons.water),
    _Quest('On-Chain Analyse', 'Prüfe QEMMA On-Chain Metriken', 22, false, Icons.link),
  ];

  @override
  void initState() {
    super.initState();
    _mineCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _questCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    // Live-Mining-Timer: jede Sekunde
    _miningTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        // Mining läuft kontinuierlich
        _miningProgress = (_miningProgress + 0.00012).clamp(0.0, 1.0);
        if (_miningProgress >= 1.0) _miningProgress = 0.0;

        // Münzen akkumulieren (langsam)
        final earned = 0.00082 + _rnd.nextDouble() * 0.00041;
        _todayMined += earned;
        _totalMined += earned;

        // Countdown
        if (_questCountdown > 0) {
          _questCountdown--;
        } else {
          _questCountdown = 900 + _rnd.nextInt(300);
        }
      });
    });

    // Live-Preis-Timer: alle 2 Sekunden
    _priceTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        final delta = (_rnd.nextDouble() - 0.488) * _livePrice * 0.006;
        _livePrice = (_livePrice + delta).clamp(0.065, 0.120);
        _liveTrend = delta >= 0;
      });
    });
  }

  @override
  void dispose() {
    _mineCtrl.dispose();
    _questCtrl.dispose();
    _miningTimer.cancel();
    _priceTimer.cancel();
    super.dispose();
  }

  String get _questCountdownStr {
    final m = _questCountdown ~/ 60;
    final s = _questCountdown % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _completeQuest(int index) {
    if (_quests[index].completed) return;
    setState(() => _quests[index] = _Quest(
          _quests[index].name,
          _quests[index].description,
          _quests[index].reward,
          true,
          _quests[index].icon,
        ));
    final reward = _quests[index].reward.toDouble();
    setState(() {
      _totalMined += reward;
      _todayMined += reward;
    });
    _questCtrl.forward(from: 0);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: _QuestCompleteToast(
          questName: _quests[index].name,
          reward: reward),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildTokenHeader(p),
          const SizedBox(height: 12),
          _buildLiveMiningCard(p),
          const SizedBox(height: 12),
          _buildStakingDashboard(p),
          const SizedBox(height: 12),
          _buildQuestsCard(p),
          const SizedBox(height: 12),
          _buildTokenomicsCard(p),
          const SizedBox(height: 12),
          _buildAgentsCard(p),
          const SizedBox(height: 12),
          _buildListingRoadmap(p),
        ],
      ),
    );
  }

  // ── Staking Dashboard ──────────────────────────
  Widget _buildStakingDashboard(dynamic p) {
    // APY Rechner State (inlined mit StatefulBuilder)
    return StatefulBuilder(
      builder: (ctx, setSt) {
        double stakeAmount = 500.0;
        const double apyTier1 = 340.0; // < 1000 QEMMA
        const double apyTier2 = 520.0; // >= 1000 QEMMA
        const double apyTier3 = 780.0; // >= 10000 QEMMA

        double apy = stakeAmount < 1000 ? apyTier1 : stakeAmount < 10000 ? apyTier2 : apyTier3;
        double dailyReward = stakeAmount * (apy / 100) / 365;
        double weeklyReward = dailyReward * 7;
        double monthlyReward = dailyReward * 30;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.accent.withValues(alpha: 0.3)),
            boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.06), blurRadius: 12)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [p.accent, p.secondary]),
                    boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.4), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.savings_outlined, color: Colors.black, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('STAKING DASHBOARD', style: GoogleFonts.rajdhani(
                      color: p.accent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  Text('Proof-of-Intelligence Yield Farming', style: GoogleFonts.spaceMono(
                      color: p.textSecondary, fontSize: 9)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.positive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: p.positive.withValues(alpha: 0.3)),
                  ),
                  child: Text('AKTIV', style: GoogleFonts.spaceMono(
                      color: p.positive, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 16),

              // APY-Tier-Karten
              Row(children: [
                _StakingTierCard('SILVER', '< 1K', '${apyTier1.toInt()}%', p.primary, p),
                const SizedBox(width: 8),
                _StakingTierCard('GOLD', '1K–10K', '${apyTier2.toInt()}%', p.accent, p),
                const SizedBox(width: 8),
                _StakingTierCard('DIAMOND', '> 10K', '${apyTier3.toInt()}%', Colors.cyanAccent, p),
              ]),
              const SizedBox(height: 16),

              // Gestakter Betrag
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('MEIN STAKE', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('1.284', style: GoogleFonts.rajdhani(
                        color: p.accent, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Text('QEMMA', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10)),
                  ]),
                  Text('≈ \$108.76', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10)),
                ])),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AKTUELLER APY', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
                  const SizedBox(height: 4),
                  Text('340%', style: GoogleFonts.rajdhani(
                      color: p.positive, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Silver Tier', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10)),
                ])),
              ]),
              const SizedBox(height: 16),

              // Rewards-Übersicht
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.accent.withValues(alpha: 0.15)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _RewardColumn('TÄGLICH', '+${dailyReward.toStringAsFixed(1)}', p.positive, p),
                  Container(width: 1, height: 36, color: p.primary.withValues(alpha: 0.15)),
                  _RewardColumn('WÖCHENTLICH', '+${weeklyReward.toStringAsFixed(1)}', p.positive, p),
                  Container(width: 1, height: 36, color: p.primary.withValues(alpha: 0.15)),
                  _RewardColumn('MONATLICH', '+${monthlyReward.toStringAsFixed(1)}', p.accent, p),
                ]),
              ),
              const SizedBox(height: 16),

              // APY-Rechner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.primary.withValues(alpha: 0.2)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.calculate_outlined, color: p.primary, size: 14),
                    const SizedBox(width: 6),
                    Text('APY-RECHNER', style: GoogleFonts.spaceMono(
                        color: p.primary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ]),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Betrag: ${stakeAmount.toInt()} QEMMA',
                        style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('APY: ${apy.toInt()}%', style: GoogleFonts.rajdhani(
                        color: p.accent, fontSize: 13, fontWeight: FontWeight.bold)),
                  ]),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      activeTrackColor: p.accent,
                      inactiveTrackColor: p.surfaceVariant,
                      thumbColor: p.accent,
                      overlayColor: p.accent.withValues(alpha: 0.15),
                    ),
                    child: Slider(
                      value: stakeAmount,
                      min: 10,
                      max: 50000,
                      divisions: 100,
                      onChanged: (v) => setSt(() => stakeAmount = v),
                    ),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _CalcResult('7T', '+${(stakeAmount*(apy/100)/365*7).toStringAsFixed(1)} QEMMA', p),
                    _CalcResult('30T', '+${(stakeAmount*(apy/100)/365*30).toStringAsFixed(1)} QEMMA', p),
                    _CalcResult('1 Jahr', '+${(stakeAmount*(apy/100)).toStringAsFixed(1)} QEMMA', p),
                  ]),
                ]),
              ),
              const SizedBox(height: 14),

              // Stake/Unstake Buttons
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.accent.withValues(alpha: 0.15),
                      foregroundColor: p.accent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: p.accent.withValues(alpha: 0.4))),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: Text('Staken', style: GoogleFonts.rajdhani(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                    onPressed: () => ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      backgroundColor: p.accent.withValues(alpha: 0.9),
                      content: Text('Stake gestartet! QEMMA wird gesperrt.',
                          style: TextStyle(color: p.background)),
                      duration: const Duration(seconds: 2),
                    )),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.surfaceVariant,
                      foregroundColor: p.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: p.primary.withValues(alpha: 0.2))),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.remove_circle_outline, size: 16),
                    label: Text('Unstaken', style: GoogleFonts.rajdhani(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                    onPressed: () => ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      backgroundColor: p.surface,
                      content: Text('Cooldown: 7 Tage nach Unstaking.',
                          style: TextStyle(color: p.textSecondary)),
                      duration: const Duration(seconds: 2),
                    )),
                  ),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  // ── Token Header ───────────────────────────────
  Widget _buildTokenHeader(dynamic p) {
    final spots = List.generate(40, (i) {
      final base = 0.04 + i * 0.0013;
      return FlSpot(i.toDouble(),
          base + _rnd.nextDouble() * 0.012 + (i > 30 ? 0.008 : 0));
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [p.surface, p.surfaceVariant],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.secondary.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              QuantumEyeWidget(palette: p, size: 52, animate: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('\$QEMMA Token',
                        style: GoogleFonts.rajdhani(
                            color: p.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                    Text('Quantum Emma AI · Solana Network',
                        style: TextStyle(
                            color: p.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.positive,
                              boxShadow: [
                                BoxShadow(
                                    color: p.positive
                                        .withValues(alpha: 0.7),
                                    blurRadius: 5)
                              ])),
                      const SizedBox(width: 5),
                      Text('Devnet Live · Mining aktiv',
                          style: TextStyle(
                              color: p.positive, fontSize: 10)),
                    ]),
                  ],
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '\$${_livePrice.toStringAsFixed(4)}',
                    key: ValueKey(_livePrice.toStringAsFixed(4)),
                    style: GoogleFonts.rajdhani(
                        color:
                            _liveTrend ? p.positive : p.negative,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Text('+12.45% 24H',
                    style: TextStyle(
                        color: p.positive,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 75,
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: p.positive,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, _) =>
                        spot == spots.last,
                    getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(
                            radius: 4,
                            color: p.positive,
                            strokeWidth: 2,
                            strokeColor: p.background),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          p.positive.withValues(alpha: 0.25),
                          Colors.transparent
                        ]),
                  ),
                )
              ],
            )),
          ),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _TokenStat('Mein Bestand',
                '${_totalMined.toStringAsFixed(1)} QEMMA',
                '\$${(_totalMined * _livePrice).toStringAsFixed(2)}',
                p),
            _TokenStat('Market Cap', '\$84.7M', '', p),
            _TokenStat('Volumen 24H', '\$2.4M', '', p),
          ]),
        ],
      ),
    );
  }

  // ── Live Mining Card ───────────────────────────
  Widget _buildLiveMiningCard(dynamic p) {
    final completedCount =
        _quests.where((q) => q.completed).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.auto_awesome, color: p.primary, size: 18),
            const SizedBox(width: 8),
            Text('AI Proof-of-Intelligence Mining',
                style: GoogleFonts.rajdhani(
                    color: p.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: p.positive.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.positive)),
                const SizedBox(width: 4),
                Text('AKTIV',
                    style: TextStyle(
                        color: p.positive,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          // Mining-Animation zentral
          Center(
            child: AnimatedBuilder(
              animation: _mineCtrl,
              builder: (_, __) => SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                    painter: _MiningPainter(_mineCtrl.value, p)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Fortschrittsbalken
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mining-Zyklus',
                    style:
                        TextStyle(color: p.textSecondary, fontSize: 12)),
                Text('${(_miningProgress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: p.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: _miningProgress,
              backgroundColor: p.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(p.primary),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 14),
          // Stats Row
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MineInfo(
                    'Heute',
                    '${_todayMined.toStringAsFixed(1)} ⚡',
                    p.positive,
                    p),
                _MineInfo(
                    'Gesamt',
                    '${_totalMined.toStringAsFixed(0)} Q',
                    p.primary,
                    p),
                _MineInfo(
                    '\$/Tag', '~\$${(70 * _livePrice).toStringAsFixed(2)}',
                    p.secondary,
                    p),
                _MineInfo(
                    'Nächste Quest',
                    _questCountdownStr,
                    p.accent,
                    p),
              ]),
          const SizedBox(height: 12),
          // Quest-Fortschritt
          Row(children: [
            Text('Quests: $completedCount/${_quests.length} abgeschlossen',
                style:
                    TextStyle(color: p.textSecondary, fontSize: 11)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(
                  '+${_quests.where((q) => q.completed).map((q) => q.reward).fold(0, (a, b) => a + b)} QEMMA verdient',
                  style: GoogleFonts.rajdhani(
                      color: p.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Quests Card ────────────────────────────────
  Widget _buildQuestsCard(dynamic p) {
    return Container(
      decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: p.primary.withValues(alpha: 0.15))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Icon(Icons.quiz_outlined, color: p.primary, size: 16),
              const SizedBox(width: 8),
              Text('Aktive Quests',
                  style: GoogleFonts.rajdhani(
                      color: p.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                  '${_quests.where((q) => !q.completed).length} verfügbar',
                  style: TextStyle(
                      color: p.textSecondary, fontSize: 11)),
            ]),
          ),
          ..._quests.asMap().entries.map((e) {
            final i = e.key;
            final q = e.value;
            return GestureDetector(
              onTap: () {
                setState(() =>
                    _selectedQuest = _selectedQuest == i ? -1 : i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedQuest == i
                      ? p.primary.withValues(alpha: 0.08)
                      : p.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _selectedQuest == i
                          ? p.primary.withValues(alpha: 0.4)
                          : Colors.transparent),
                ),
                child: Column(children: [
                  Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: q.completed
                            ? p.positive.withValues(alpha: 0.15)
                            : p.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                          q.completed ? Icons.check_circle : q.icon,
                          color:
                              q.completed ? p.positive : p.primary,
                          size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                          Text(q.name,
                              style: TextStyle(
                                  color: q.completed
                                      ? p.textSecondary
                                      : p.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: q.completed
                                      ? TextDecoration.lineThrough
                                      : null)),
                          Text(q.description,
                              style: TextStyle(
                                  color: p.textSecondary,
                                  fontSize: 10)),
                        ])),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: q.completed
                              ? p.positive.withValues(alpha: 0.1)
                              : p.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('+${q.reward} Q',
                          style: GoogleFonts.rajdhani(
                              color: q.completed
                                  ? p.positive
                                  : p.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  // Expanded Quest-Detail mit Button
                  if (_selectedQuest == i && !q.completed) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _completeQuest(i),
                        icon: const Icon(Icons.play_arrow, size: 14),
                        label: Text('Quest abschließen (+${q.reward} QEMMA)',
                            style: GoogleFonts.rajdhani(
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: p.primary,
                          foregroundColor: p.background,
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ]),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Tokenomics ─────────────────────────────────
  Widget _buildTokenomicsCard(dynamic p) {
    final data = [
      ('Grigori Saks Reserve', 21, p.secondary),
      ('Mining Pool', 35, p.primary),
      ('Liquidität', 20, p.accent),
      ('Entwicklung', 14, p.positive),
      ('Community', 10, p.positive.withValues(alpha: 0.6)),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: p.primary.withValues(alpha: 0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.pie_chart_outline, color: p.primary, size: 16),
            const SizedBox(width: 6),
            Text('Tokenomics · 1 Mrd. \$QEMMA',
                style: GoogleFonts.rajdhani(
                    color: p.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          ...data.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(d.$1,
                              style: TextStyle(
                                  color: p.textPrimary,
                                  fontSize: 12)),
                          Text('${d.$2}%',
                              style: TextStyle(
                                  color: d.$3,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ]),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                          value: d.$2 / 100,
                          backgroundColor: p.surfaceVariant,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(d.$3),
                          minHeight: 5),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(Icons.local_fire_department,
                  color: p.secondary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Burn-Rate: 1.2% pro Quartal · Letzte Verbrennung: 1.2M QEMMA',
                      style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 11,
                          height: 1.4))),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Agenten-Beitrag ────────────────────────────
  Widget _buildAgentsCard(dynamic p) {
    final agents = [
      ('Quantum Oracle (Emma)', 91, p.primary),
      ('Pattern Genesis', 87, p.secondary),
      ('Risk Sentinel', 94, p.positive),
      ('Sentiment Weaver', 82, p.accent),
      ('Blockchain Scout', 78, p.primary.withValues(alpha: 0.7)),
      ('Meta Orchestrator', 96, p.positive.withValues(alpha: 0.8)),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: p.primary.withValues(alpha: 0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.hub_outlined, color: p.primary, size: 16),
            const SizedBox(width: 6),
            Text('HQMLL Agenten-Beitrag',
                style: GoogleFonts.rajdhani(
                    color: p.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('6/6 Online',
                style: TextStyle(color: p.positive, fontSize: 11)),
          ]),
          const SizedBox(height: 12),
          ...agents.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: e.value.$3.withValues(alpha: 0.15),
                        border: Border.all(
                            color: e.value.$3
                                .withValues(alpha: 0.5))),
                    child: Center(
                        child: Text('${e.key + 1}',
                            style: TextStyle(
                                color: e.value.$3,
                                fontSize: 9,
                                fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(e.value.$1,
                          style: TextStyle(
                              color: p.textSecondary,
                              fontSize: 11))),
                  SizedBox(
                    width: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: e.value.$2 / 100,
                        minHeight: 5,
                        backgroundColor:
                            p.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation(
                            e.value.$3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('${e.value.$2}%',
                      style: TextStyle(
                          color: e.value.$3,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ]),
              )),
        ],
      ),
    );
  }

  // ── Listing Roadmap ────────────────────────────
  Widget _buildListingRoadmap(dynamic p) {
    final phases = [
      ('Phase 1', 'Plattform-interne DEX (Raydium)', true, 'Q4 2024'),
      ('Phase 2', 'Jupiter + Top Solana DEXes', true, 'Q1 2025'),
      ('Phase 3', 'CEX-Listings (Bybit, OKX)', false, 'Q2 2025'),
      ('Phase 4', 'Binance + Coinbase · Global', false, 'Q3 2025'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: p.primary.withValues(alpha: 0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.rocket_launch_outlined,
                color: p.primary, size: 16),
            const SizedBox(width: 6),
            Text('Listing-Roadmap',
                style: GoogleFonts.rajdhani(
                    color: p.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          ...phases.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: e.value.$3
                              ? p.positive
                              : p.surfaceVariant,
                          border: Border.all(
                              color: e.value.$3
                                  ? p.positive
                                  : p.primary
                                      .withValues(alpha: 0.3)),
                        ),
                        child: Icon(
                            e.value.$3
                                ? Icons.check
                                : Icons.radio_button_unchecked,
                            color: e.value.$3
                                ? p.background
                                : p.textSecondary,
                            size: 14),
                      ),
                      if (e.key < phases.length - 1)
                        Container(
                            width: 2,
                            height: 24,
                            color: p.primary.withValues(alpha: 0.2)),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(e.value.$1,
                                  style: GoogleFonts.rajdhani(
                                      color: e.value.$3
                                          ? p.positive
                                          : p.primary,
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2),
                                decoration: BoxDecoration(
                                    color: (e.value.$3
                                            ? p.positive
                                            : p.primary)
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(4)),
                                child: Text(e.value.$4,
                                    style: TextStyle(
                                        color: e.value.$3
                                            ? p.positive
                                            : p.primary,
                                        fontSize: 9)),
                              ),
                            ]),
                            Text(e.value.$2,
                                style: TextStyle(
                                    color: p.textSecondary,
                                    fontSize: 11)),
                          ]),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Quest Complete Toast ───────────────────────────
class _QuestCompleteToast extends StatelessWidget {
  final String questName;
  final double reward;
  const _QuestCompleteToast(
      {required this.questName, required this.reward});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF1DE9B6)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF00C853).withValues(alpha: 0.4),
              blurRadius: 20)
        ],
      ),
      child: Row(children: [
        const Icon(Icons.star, color: Colors.white, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quest abgeschlossen! 🎉',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text('$questName · +${reward.toStringAsFixed(0)} QEMMA verdient',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ]),
        ),
      ]),
    );
  }
}

// ── Data & Helper Classes ──────────────────────────
class _Quest {
  String name, description;
  int reward;
  bool completed;
  IconData icon;
  _Quest(this.name, this.description, this.reward, this.completed,
      this.icon);
}

class _TokenStat extends StatelessWidget {
  final String label, value, sub;
  final dynamic p;
  const _TokenStat(this.label, this.value, this.sub, this.p);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label,
          style: TextStyle(color: p.textSecondary, fontSize: 10)),
      Text(value,
          style: GoogleFonts.rajdhani(
              color: p.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
      if (sub.isNotEmpty)
        Text(sub,
            style: TextStyle(color: p.positive, fontSize: 10)),
    ]);
  }
}

class _MineInfo extends StatelessWidget {
  final String label, value;
  final Color color;
  final dynamic p;
  const _MineInfo(this.label, this.value, this.color, this.p);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label,
          style: TextStyle(color: p.textSecondary, fontSize: 9)),
      Text(value,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _MiningPainter extends CustomPainter {
  final double t;
  final dynamic p;
  _MiningPainter(this.t, this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;

    // Äußere Ringe
    for (int ring = 0; ring < 3; ring++) {
      canvas.drawCircle(
          center,
          r * (0.55 + ring * 0.22),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color =
                p.primary.withValues(alpha: 0.12 + ring * 0.04));
    }

    // Rotierender Bogen
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = p.primary
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r),
        t * 2 * pi, pi * 1.3, false, arcPaint);

    // Sekundärer Bogen
    final arcPaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = p.secondary.withValues(alpha: 0.6)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: r * 0.78),
        -t * 2 * pi + pi / 2,
        pi * 0.8,
        false,
        arcPaint2);

    // Innerer Puls-Kreis
    final dotR = 14.0 + sin(t * 2 * pi) * 5;
    final dotPaint = Paint()
      ..shader = RadialGradient(colors: [
        p.primary,
        p.secondary.withValues(alpha: 0.4)
      ]).createShader(
          Rect.fromCircle(center: center, radius: dotR));
    canvas.drawCircle(center, dotR, dotPaint);

    // Mining-Partikel
    for (int i = 0; i < 8; i++) {
      final angle = t * 2 * pi + i * pi / 4;
      final pr = r * (0.5 + sin(t * 2 * pi + i * 0.8) * 0.15);
      final pos =
          center + Offset(cos(angle) * pr, sin(angle) * pr);
      final particleSize = 2.0 + sin(t * 4 * pi + i) * 1.0;
      canvas.drawCircle(
          pos,
          particleSize,
          Paint()
            ..color = (i % 2 == 0 ? p.accent : p.primary)
                .withValues(alpha: 0.8));
    }

    // Q-Symbol in der Mitte
    final textPainter = TextPainter(
      text: TextSpan(
          text: 'Q',
          style: TextStyle(
              color: p.background,
              fontSize: 14,
              fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        center -
            Offset(
                textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(_MiningPainter old) => old.t != t;
}

// ── Staking Helper Widgets ─────────────────────────
class _StakingTierCard extends StatelessWidget {
  final String tier;
  final String range;
  final String apy;
  final Color color;
  final dynamic p;
  const _StakingTierCard(this.tier, this.range, this.apy, this.color, this.p);
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(children: [
          Text(tier, style: GoogleFonts.spaceMono(
              color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(apy, style: GoogleFonts.rajdhani(
              color: color, fontSize: 17, fontWeight: FontWeight.bold)),
          Text('APY', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7)),
          const SizedBox(height: 2),
          Text(range, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7)),
        ]),
      ),
    );
  }
}

class _RewardColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final dynamic p;
  const _RewardColumn(this.label, this.value, this.color, this.p);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7)),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.rajdhani(
          color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      Text('QEMMA', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7)),
    ]);
  }
}

class _CalcResult extends StatelessWidget {
  final String period;
  final String value;
  final dynamic p;
  const _CalcResult(this.period, this.value, this.p);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(period, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
      const SizedBox(height: 2),
      Text(value, style: GoogleFonts.rajdhani(
          color: p.primary, fontSize: 11, fontWeight: FontWeight.bold)),
    ]);
  }
}
