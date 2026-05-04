// ============================================================
// ORACLE SCREEN v3 – Quantum AI Prediction Engine
// Neural Signals, Market Scanner, Pattern Recognition, Sentiment
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';

class OracleScreen extends StatefulWidget {
  const OracleScreen({super.key});
  @override
  State<OracleScreen> createState() => _OracleScreenState();
}

class _OracleScreenState extends State<OracleScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _scanCtrl;
  Timer? _liveTimer;
  final _rand = Random();

  int _selectedTab = 0;
  final List<String> _tabs = ['SIGNALS', 'PREDICTIONS', 'SCANNER', 'SENTIMENT', 'PATTERNS'];

  // Live AI Signals
  final List<Map<String, dynamic>> _signals = [
    {'pair': 'BTC/USDT', 'dir': 'LONG', 'confidence': 91.4, 'entry': 67840.0, 'tp': 71200.0, 'sl': 66100.0, 'timeframe': '4H', 'model': 'QEMMA-7', 'status': 'ACTIVE'},
    {'pair': 'ETH/USDT', 'dir': 'LONG', 'confidence': 87.2, 'entry': 3412.0, 'tp': 3680.0, 'sl': 3280.0, 'timeframe': '1H', 'model': 'NEXUS-3', 'status': 'ACTIVE'},
    {'pair': 'SOL/USDT', 'dir': 'SHORT', 'confidence': 79.8, 'entry': 178.4, 'tp': 162.0, 'sl': 186.0, 'timeframe': '15M', 'model': 'ORACLE-9', 'status': 'ACTIVE'},
    {'pair': 'BNB/USDT', 'dir': 'LONG', 'confidence': 83.5, 'entry': 594.0, 'tp': 628.0, 'sl': 578.0, 'timeframe': '4H', 'model': 'QEMMA-7', 'status': 'PENDING'},
    {'pair': 'XRP/USDT', 'dir': 'SHORT', 'confidence': 74.1, 'entry': 0.628, 'tp': 0.591, 'sl': 0.648, 'timeframe': '1H', 'model': 'TR2-X', 'status': 'PENDING'},
    {'pair': 'AVAX/USDT', 'dir': 'LONG', 'confidence': 88.9, 'entry': 42.3, 'tp': 47.8, 'sl': 39.7, 'timeframe': '4H', 'model': 'NEXUS-3', 'status': 'ACTIVE'},
  ];

  // Predictions
  final List<Map<String, dynamic>> _predictions = [
    {'asset': 'Bitcoin', 'ticker': 'BTC', 'price': 67840.0, 'target24h': 69200.0, 'target7d': 72400.0, 'target30d': 78500.0, 'ai_score': 94, 'trend': 'BULLISH'},
    {'asset': 'Ethereum', 'ticker': 'ETH', 'price': 3412.0, 'target24h': 3520.0, 'target7d': 3750.0, 'target30d': 4100.0, 'ai_score': 89, 'trend': 'BULLISH'},
    {'asset': 'Solana', 'ticker': 'SOL', 'price': 178.4, 'target24h': 172.0, 'target7d': 168.0, 'target30d': 195.0, 'ai_score': 72, 'trend': 'NEUTRAL'},
    {'asset': 'Binance Coin', 'ticker': 'BNB', 'price': 594.0, 'target24h': 608.0, 'target7d': 635.0, 'target30d': 660.0, 'ai_score': 81, 'trend': 'BULLISH'},
    {'asset': 'Avalanche', 'ticker': 'AVAX', 'price': 42.3, 'target24h': 44.1, 'target7d': 48.2, 'target30d': 52.0, 'ai_score': 86, 'trend': 'BULLISH'},
    {'asset': 'Chainlink', 'ticker': 'LINK', 'price': 18.7, 'target24h': 17.9, 'target7d': 16.4, 'target30d': 21.0, 'ai_score': 63, 'trend': 'BEARISH'},
  ];

  // Market Scanner results
  final List<Map<String, dynamic>> _scanResults = [
    {'pair': 'BTC/USDT', 'pattern': 'Bull Flag', 'volume': '+342%', 'rsi': 58.4, 'macd': 'BUY', 'score': 94},
    {'pair': 'ETH/USDT', 'pattern': 'Cup & Handle', 'volume': '+218%', 'rsi': 62.1, 'macd': 'BUY', 'score': 89},
    {'pair': 'SOL/USDT', 'pattern': 'Head & Shoulders', 'volume': '-12%', 'rsi': 71.3, 'macd': 'SELL', 'score': 24},
    {'pair': 'AVAX/USDT', 'pattern': 'Double Bottom', 'volume': '+156%', 'rsi': 44.8, 'macd': 'BUY', 'score': 82},
    {'pair': 'MATIC/USDT', 'pattern': 'Ascending Triangle', 'volume': '+89%', 'rsi': 51.2, 'macd': 'NEUTRAL', 'score': 71},
    {'pair': 'DOT/USDT', 'pattern': 'Wedge Breakout', 'volume': '+267%', 'rsi': 39.7, 'macd': 'BUY', 'score': 77},
    {'pair': 'ADA/USDT', 'pattern': 'Pennant', 'volume': '+44%', 'rsi': 55.9, 'macd': 'NEUTRAL', 'score': 65},
    {'pair': 'DOGE/USDT', 'pattern': 'Bearish Engulfing', 'volume': '-28%', 'rsi': 68.4, 'macd': 'SELL', 'score': 18},
  ];

  // Sentiment data
  double _btcSentiment = 74.0;
  double _ethSentiment = 68.0;
  double _marketFear = 38.0; // Fear & Greed Index
  String _marketMood = 'GREED';

  // Pattern recognition
  final List<Map<String, dynamic>> _patterns = [
    {'name': 'Bull Flag', 'found': 7, 'win_rate': 73.4, 'avg_gain': '+8.2%', 'color': 0xFF00C8F5},
    {'name': 'Double Bottom', 'found': 4, 'win_rate': 68.9, 'avg_gain': '+12.1%', 'color': 0xFF00F0C0},
    {'name': 'Cup & Handle', 'found': 3, 'win_rate': 79.2, 'avg_gain': '+15.7%', 'color': 0xFF9B59B6},
    {'name': 'Head & Shoulders', 'found': 2, 'win_rate': 71.3, 'avg_gain': '-9.4%', 'color': 0xFFFF4444},
    {'name': 'Ascending Triangle', 'found': 5, 'win_rate': 66.7, 'avg_gain': '+7.8%', 'color': 0xFFFFAA00},
    {'name': 'Wedge Breakout', 'found': 6, 'win_rate': 81.0, 'avg_gain': '+11.3%', 'color': 0xFF00C8F5},
  ];

  // Animated scan line
  double _scanProgress = 0.0;
  int _signalCount = 847;
  double _oracleAccuracy = 91.4;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _liveTimer = Timer.periodic(const Duration(seconds: 2), (_) => _updateLive());
  }

  void _updateLive() {
    if (!mounted) return;
    setState(() {
      _scanProgress = (_scanProgress + 0.05) % 1.0;
      _signalCount += _rand.nextInt(3);
      _oracleAccuracy = 89.0 + _rand.nextDouble() * 4.0;
      _btcSentiment = 65.0 + _rand.nextDouble() * 20.0;
      _ethSentiment = 58.0 + _rand.nextDouble() * 22.0;
      _marketFear = 30.0 + _rand.nextDouble() * 30.0;
      // Update some signal confidences
      for (var s in _signals) {
        s['confidence'] = (s['confidence'] as double) + (_rand.nextDouble() - 0.5) * 0.4;
        s['confidence'] = (s['confidence'] as double).clamp(50.0, 99.0);
      }
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(p),
            _buildTabBar(p),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildTabContent(p),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(QuantumPalette p) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) {
        final glow = _glowCtrl.value;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                p.background,
                Color.lerp(p.background, const Color(0xFF0A0020), 0.5)!,
              ],
            ),
            border: Border(
              bottom: BorderSide(color: p.primary.withValues(alpha: 0.3 + glow * 0.2)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    p.primary.withValues(alpha: 0.4 + glow * 0.3),
                    p.primary.withValues(alpha: 0.1),
                  ]),
                  boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.5 + glow * 0.3), blurRadius: 16)],
                ),
                child: Icon(Icons.remove_red_eye_rounded, color: p.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ORACLE AI', style: GoogleFonts.orbitron(
                      color: p.primary, fontSize: 16, fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: p.primary.withValues(alpha: 0.6), blurRadius: 8)],
                    )),
                    Text('Quantum Prediction Engine v3', style: GoogleFonts.rajdhani(
                      color: p.textSecondary, fontSize: 11,
                    )),
                  ],
                ),
              ),
              // Live stats
              _buildHeaderStat(p, 'ACCURACY', '${_oracleAccuracy.toStringAsFixed(1)}%', p.positive),
              const SizedBox(width: 12),
              _buildHeaderStat(p, 'SIGNALS', '$_signalCount', p.primary),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: p.positive.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: p.positive.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.positive,
                      boxShadow: [BoxShadow(color: p.positive, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('LIVE', style: GoogleFonts.orbitron(
                    color: p.positive, fontSize: 10, fontWeight: FontWeight.bold,
                  )),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderStat(QuantumPalette p, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── Tab Bar ──
  Widget _buildTabBar(QuantumPalette p) {
    return Container(
      height: 40,
      color: p.surface.withValues(alpha: 0.4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _tabs.length,
        itemBuilder: (_, i) {
          final sel = i == _selectedTab;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: sel ? p.primary.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: sel ? p.primary : Colors.transparent),
              ),
              child: Center(
                child: Text(_tabs[i], style: GoogleFonts.orbitron(
                  color: sel ? p.primary : p.textSecondary,
                  fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent(QuantumPalette p) {
    switch (_selectedTab) {
      case 0: return _buildSignalsTab(p);
      case 1: return _buildPredictionsTab(p);
      case 2: return _buildScannerTab(p);
      case 3: return _buildSentimentTab(p);
      case 4: return _buildPatternsTab(p);
      default: return _buildSignalsTab(p);
    }
  }

  // ── SIGNALS TAB ──
  Widget _buildSignalsTab(QuantumPalette p) {
    return ListView(
      key: const ValueKey('signals'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildSignalSummaryRow(p),
        const SizedBox(height: 12),
        ..._signals.map((s) => _buildSignalCard(p, s)),
      ],
    );
  }

  Widget _buildSignalSummaryRow(QuantumPalette p) {
    return Row(
      children: [
        Expanded(child: _buildMiniStatCard(p, 'ACTIVE', '${_signals.where((s) => s['status'] == 'ACTIVE').length}', p.positive, Icons.flash_on)),
        const SizedBox(width: 8),
        Expanded(child: _buildMiniStatCard(p, 'WIN RATE', '73.8%', p.primary, Icons.trending_up)),
        const SizedBox(width: 8),
        Expanded(child: _buildMiniStatCard(p, 'AVG R:R', '1:2.4', p.accent, Icons.balance)),
        const SizedBox(width: 8),
        Expanded(child: _buildMiniStatCard(p, 'TODAY P/L', '+\$1,847', p.positive, Icons.attach_money)),
      ],
    );
  }

  Widget _buildMiniStatCard(QuantumPalette p, String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildSignalCard(QuantumPalette p, Map<String, dynamic> s) {
    final isLong = s['dir'] == 'LONG';
    final dirColor = isLong ? p.positive : p.negative;
    final conf = s['confidence'] as double;
    final isActive = s['status'] == 'ACTIVE';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dirColor.withValues(alpha: isActive ? 0.4 : 0.2)),
        boxShadow: isActive ? [BoxShadow(color: dirColor.withValues(alpha: 0.1), blurRadius: 12)] : [],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: dirColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: dirColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: dirColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(s['dir'], style: GoogleFonts.orbitron(
                    color: dirColor, fontSize: 11, fontWeight: FontWeight.bold,
                  )),
                ),
                const SizedBox(width: 10),
                Text(s['pair'], style: GoogleFonts.orbitron(
                  color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold,
                )),
                const Spacer(),
                Text(s['timeframe'], style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 12)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? p.positive.withValues(alpha: 0.15) : p.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(s['status'], style: GoogleFonts.rajdhani(
                    color: isActive ? p.positive : p.textSecondary, fontSize: 9, fontWeight: FontWeight.bold,
                  )),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildSignalLevel(p, 'ENTRY', s['entry'], p.primary)),
                    Expanded(child: _buildSignalLevel(p, 'TAKE PROFIT', s['tp'], p.positive)),
                    Expanded(child: _buildSignalLevel(p, 'STOP LOSS', s['sl'], p.negative)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.memory, color: p.accent, size: 14),
                    const SizedBox(width: 4),
                    Text('Model: ${s['model']}', style: GoogleFonts.rajdhani(color: p.accent, fontSize: 11)),
                    const Spacer(),
                    Text('AI Confidence:', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 11)),
                    const SizedBox(width: 6),
                    Text('${conf.toStringAsFixed(1)}%', style: GoogleFonts.orbitron(
                      color: conf > 85 ? p.positive : conf > 70 ? p.primary : p.negative,
                      fontSize: 12, fontWeight: FontWeight.bold,
                    )),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: conf / 100,
                    backgroundColor: p.surface,
                    valueColor: AlwaysStoppedAnimation(
                      conf > 85 ? p.positive : conf > 70 ? p.primary : p.negative,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalLevel(QuantumPalette p, String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
        const SizedBox(height: 2),
        Text(value < 10 ? value.toStringAsFixed(4) : value.toStringAsFixed(1),
          style: GoogleFonts.orbitron(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── PREDICTIONS TAB ──
  Widget _buildPredictionsTab(QuantumPalette p) {
    return ListView(
      key: const ValueKey('predictions'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildOracleStatusCard(p),
        const SizedBox(height: 12),
        ..._predictions.map((pred) => _buildPredictionCard(p, pred)),
      ],
    );
  }

  Widget _buildOracleStatusCard(QuantumPalette p) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              p.primary.withValues(alpha: 0.1),
              p.accent.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.primary.withValues(alpha: 0.3 + _glowCtrl.value * 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: p.primary, size: 18),
                const SizedBox(width: 8),
                Text('ORACLE PREDICTION ENGINE', style: GoogleFonts.orbitron(
                  color: p.primary, fontSize: 12, fontWeight: FontWeight.bold,
                )),
                const Spacer(),
                Text('ONLINE', style: GoogleFonts.rajdhani(color: p.positive, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildOracleMetric(p, 'MODEL ACCURACY', '${_oracleAccuracy.toStringAsFixed(1)}%', p.positive)),
                Expanded(child: _buildOracleMetric(p, 'DATA POINTS', '2.4M', p.primary)),
                Expanded(child: _buildOracleMetric(p, 'ASSETS TRACKED', '847', p.accent)),
                Expanded(child: _buildOracleMetric(p, 'LAST UPDATE', '2s ago', p.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOracleMetric(QuantumPalette p, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
      ],
    );
  }

  Widget _buildPredictionCard(QuantumPalette p, Map<String, dynamic> pred) {
    final isBull = pred['trend'] == 'BULLISH';
    final isBear = pred['trend'] == 'BEARISH';
    final trendColor = isBull ? p.positive : isBear ? p.negative : p.primary;
    final score = pred['ai_score'] as int;
    final p24 = ((pred['target24h'] - pred['price']) / pred['price'] * 100);
    final p7d = ((pred['target7d'] - pred['price']) / pred['price'] * 100);
    final p30d = ((pred['target30d'] - pred['price']) / pred['price'] * 100);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: trendColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: trendColor.withValues(alpha: 0.15),
                  border: Border.all(color: trendColor.withValues(alpha: 0.4)),
                ),
                child: Center(child: Text(pred['ticker'], style: GoogleFonts.orbitron(
                  color: trendColor, fontSize: 9, fontWeight: FontWeight.bold,
                ))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pred['asset'], style: GoogleFonts.rajdhani(
                      color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold,
                    )),
                    Text('\$${(pred['price'] as double).toStringAsFixed(pred['price'] < 100 ? 4 : 1)}',
                      style: GoogleFonts.orbitron(color: p.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: trendColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(pred['trend'], style: GoogleFonts.orbitron(
                    color: trendColor, fontSize: 9, fontWeight: FontWeight.bold,
                  )),
                ),
                const SizedBox(height: 3),
                Text('AI Score: $score/100', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildPredTarget(p, '24H', pred['target24h'], p24, trendColor)),
              Expanded(child: _buildPredTarget(p, '7 DAYS', pred['target7d'], p7d, trendColor)),
              Expanded(child: _buildPredTarget(p, '30 DAYS', pred['target30d'], p30d, trendColor)),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text('AI Confidence', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
            const Spacer(),
            Text('$score%', style: GoogleFonts.orbitron(color: trendColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: p.surface,
              valueColor: AlwaysStoppedAnimation(trendColor),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredTarget(QuantumPalette p, String period, double target, double pct, Color color) {
    final isPos = pct >= 0;
    final pctColor = isPos ? p.positive : p.negative;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(period, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
          const SizedBox(height: 3),
          Text('\$${target < 100 ? target.toStringAsFixed(3) : target.toStringAsFixed(0)}',
            style: GoogleFonts.orbitron(color: p.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
          Text('${isPos ? '+' : ''}${pct.toStringAsFixed(1)}%',
            style: GoogleFonts.rajdhani(color: pctColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── SCANNER TAB ──
  Widget _buildScannerTab(QuantumPalette p) {
    return ListView(
      key: const ValueKey('scanner'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildScannerHeader(p),
        const SizedBox(height: 12),
        ..._scanResults.map((r) => _buildScanResultCard(p, r)),
      ],
    );
  }

  Widget _buildScannerHeader(QuantumPalette p) {
    return AnimatedBuilder(
      animation: _scanCtrl,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.radar, color: p.primary, size: 18),
                const SizedBox(width: 8),
                Text('MARKET SCANNER', style: GoogleFonts.orbitron(
                  color: p.primary, fontSize: 12, fontWeight: FontWeight.bold,
                )),
                const Spacer(),
                Text('SCANNING...', style: GoogleFonts.rajdhani(
                  color: p.positive, fontSize: 10, fontWeight: FontWeight.bold,
                )),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Text('Progress:', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 11)),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: _scanCtrl.value,
                      backgroundColor: p.surface,
                      valueColor: AlwaysStoppedAnimation(p.primary),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(_scanCtrl.value * 100).toInt()}%',
                  style: GoogleFonts.orbitron(color: p.primary, fontSize: 10)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _buildScanStat(p, 'Pairs Scanned', '${(_scanCtrl.value * 500).toInt()}/500', p.primary),
                const SizedBox(width: 16),
                _buildScanStat(p, 'Signals Found', '${_scanResults.length}', p.positive),
                const SizedBox(width: 16),
                _buildScanStat(p, 'High Score', '94', p.accent),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanStat(QuantumPalette p, String label, String val, Color color) {
    return Row(children: [
      Text('$label: ', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
      Text(val, style: GoogleFonts.orbitron(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildScanResultCard(QuantumPalette p, Map<String, dynamic> r) {
    final score = r['score'] as int;
    final isBull = score >= 70;
    final scoreColor = score >= 80 ? p.positive : score >= 50 ? p.primary : p.negative;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: p.surface,
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                  strokeWidth: 3,
                ),
                Text('$score', style: GoogleFonts.orbitron(
                  color: scoreColor, fontSize: 9, fontWeight: FontWeight.bold,
                )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['pair'], style: GoogleFonts.orbitron(
                  color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold,
                )),
                Text(r['pattern'], style: GoogleFonts.rajdhani(
                  color: scoreColor, fontSize: 11,
                )),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _buildScannerBadge(p, 'RSI', r['rsi'].toString(), p.accent),
            const SizedBox(height: 4),
            _buildScannerBadge(p, 'MACD', r['macd'], r['macd'] == 'BUY' ? p.positive : r['macd'] == 'SELL' ? p.negative : p.primary),
          ]),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(r['volume'], style: GoogleFonts.rajdhani(
              color: r['volume'].startsWith('+') ? p.positive : p.negative,
              fontSize: 12, fontWeight: FontWeight.bold,
            )),
            Text('Volume', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
          ]),
        ],
      ),
    );
  }

  Widget _buildScannerBadge(QuantumPalette p, String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text('$label: $val', style: GoogleFonts.rajdhani(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  // ── SENTIMENT TAB ──
  Widget _buildSentimentTab(QuantumPalette p) {
    return ListView(
      key: const ValueKey('sentiment'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildFearGreedCard(p),
        const SizedBox(height: 12),
        _buildSentimentGaugeCard(p, 'Bitcoin', 'BTC', _btcSentiment),
        const SizedBox(height: 8),
        _buildSentimentGaugeCard(p, 'Ethereum', 'ETH', _ethSentiment),
        const SizedBox(height: 12),
        _buildSocialSentimentCard(p),
      ],
    );
  }

  Widget _buildFearGreedCard(QuantumPalette p) {
    final moodColor = _marketFear > 60 ? p.negative : _marketFear > 40 ? p.primary : p.positive;
    final mood = _marketFear > 60 ? 'EXTREME GREED' : _marketFear > 40 ? 'GREED' : 'NEUTRAL';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          moodColor.withValues(alpha: 0.1),
          p.surface.withValues(alpha: 0.3),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: moodColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.psychology, color: moodColor, size: 18),
            const SizedBox(width: 8),
            Text('FEAR & GREED INDEX', style: GoogleFonts.orbitron(
              color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold,
            )),
          ]),
          const SizedBox(height: 16),
          Center(
            child: Column(children: [
              Text(_marketFear.toInt().toString(), style: GoogleFonts.orbitron(
                color: moodColor, fontSize: 48, fontWeight: FontWeight.bold,
                shadows: [Shadow(color: moodColor.withValues(alpha: 0.5), blurRadius: 16)],
              )),
              Text(mood, style: GoogleFonts.orbitron(
                color: moodColor, fontSize: 14, fontWeight: FontWeight.bold,
              )),
            ]),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _marketFear / 100,
              backgroundColor: p.negative.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(moodColor),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('FEAR', style: GoogleFonts.rajdhani(color: p.negative, fontSize: 10)),
            Text('NEUTRAL', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 10)),
            Text('GREED', style: GoogleFonts.rajdhani(color: p.positive, fontSize: 10)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSentimentGaugeCard(QuantumPalette p, String name, String ticker, double val) {
    final color = val > 60 ? p.positive : val > 40 ? p.primary : p.negative;
    final label = val > 60 ? 'BULLISH' : val > 40 ? 'NEUTRAL' : 'BEARISH';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Center(child: Text(ticker, style: GoogleFonts.orbitron(
              color: color, fontSize: 9, fontWeight: FontWeight.bold,
            ))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(label, style: GoogleFonts.orbitron(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: val / 100,
                    backgroundColor: p.surface,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('${val.toInt()}%', style: GoogleFonts.orbitron(
            color: color, fontSize: 14, fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }

  Widget _buildSocialSentimentCard(QuantumPalette p) {
    final sources = [
      {'src': 'Twitter/X', 'bull': 68, 'bear': 32, 'vol': '124K'},
      {'src': 'Reddit', 'bull': 72, 'bear': 28, 'vol': '48K'},
      {'src': 'Telegram', 'bull': 81, 'bear': 19, 'vol': '92K'},
      {'src': 'Discord', 'bull': 59, 'bear': 41, 'vol': '31K'},
      {'src': 'News', 'bull': 64, 'bear': 36, 'vol': '218'},
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.campaign, color: p.primary, size: 16),
            const SizedBox(width: 8),
            Text('SOCIAL SENTIMENT', style: GoogleFonts.orbitron(
              color: p.primary, fontSize: 11, fontWeight: FontWeight.bold,
            )),
          ]),
          const SizedBox(height: 12),
          ...sources.map((src) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(width: 80, child: Text(src['src'] as String,
                  style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 11))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Row(
                      children: [
                        Flexible(
                          flex: src['bull'] as int,
                          child: Container(height: 10, color: p.positive.withValues(alpha: 0.6)),
                        ),
                        Flexible(
                          flex: src['bear'] as int,
                          child: Container(height: 10, color: p.negative.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: Text('${src['bull']}%', style: GoogleFonts.rajdhani(color: p.positive, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 40,
                  child: Text('${src['vol']} mentions', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── PATTERNS TAB ──
  Widget _buildPatternsTab(QuantumPalette p) {
    return ListView(
      key: const ValueKey('patterns'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildPatternSummary(p),
        const SizedBox(height: 12),
        ..._patterns.map((pt) => _buildPatternCard(p, pt)),
      ],
    );
  }

  Widget _buildPatternSummary(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.pattern, color: p.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PATTERN RECOGNITION', style: GoogleFonts.orbitron(
                color: p.accent, fontSize: 11, fontWeight: FontWeight.bold,
              )),
              Text('27 patterns detected across 847 markets',
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 11)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('73.8%', style: GoogleFonts.orbitron(
              color: p.positive, fontSize: 16, fontWeight: FontWeight.bold,
            )),
            Text('avg win rate', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
          ]),
        ],
      ),
    );
  }

  Widget _buildPatternCard(QuantumPalette p, Map<String, dynamic> pt) {
    final color = Color(pt['color'] as int);
    final isProfit = (pt['avg_gain'] as String).startsWith('+');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(Icons.show_chart, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pt['name'], style: GoogleFonts.rajdhani(
                color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold,
              )),
              Text('Found in ${pt['found']} markets',
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${pt['win_rate']}%', style: GoogleFonts.orbitron(
              color: p.positive, fontSize: 12, fontWeight: FontWeight.bold,
            )),
            Text('win rate', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
          ]),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(pt['avg_gain'], style: GoogleFonts.orbitron(
              color: isProfit ? p.positive : p.negative, fontSize: 12, fontWeight: FontWeight.bold,
            )),
            Text('avg gain', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
          ]),
        ],
      ),
    );
  }
}
