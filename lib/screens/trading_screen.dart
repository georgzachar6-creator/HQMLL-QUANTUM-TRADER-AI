import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/theme_provider.dart';
import '../widgets/tradingview_widget.dart';

class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key});
  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen>
    with TickerProviderStateMixin {
  late AnimationController _tickCtrl;
  late AnimationController _pulseCtrl;
  late Timer _priceTimer;
  int _selectedPair = 0;
  String _timeframe = '4H';
  String _orderType = 'MARKT';
  bool _isBuy = true;
  double _quantity = 0.0;
  bool _orderPlaced = false;
  int _totalTick = 0;
  // ignore: unused_field
  double _limitPrice = 0.0;
  // ignore: unused_field
  double _stopPrice = 0.0;
  double _takeProfitPct = 0.0;
  double _stopLossPct = 0.0;
  bool _showAdvanced = false;
  bool _showTradingView = false; // TradingView vs lokaler Chart
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _limitCtrl = TextEditingController();
  final TextEditingController _stopCtrl = TextEditingController();
  final Random _rnd = Random();

  final List<_TradingPair> _pairs = [
    _TradingPair('BTC', 'Bitcoin', 67842.50, 2.34, true, 'bitcoin'),
    _TradingPair('ETH', 'Ethereum', 3548.20, 1.87, true, 'ethereum'),
    _TradingPair('SOL', 'Solana', 182.40, -0.52, false, 'solana'),
    _TradingPair('QEMMA', '\$QEMMA Token', 0.0847, 12.45, true, 'qemma'),
    _TradingPair('BNB', 'BNB Chain', 598.30, 0.94, true, 'bnb'),
    _TradingPair('ADA', 'Cardano', 0.624, -1.23, false, 'cardano'),
  ];

  final List<String> _timeframes = ['15M', '1H', '4H', '1D', '1W'];
  final List<String> _orderTypes = ['MARKT', 'LIMIT', 'STOP'];
  bool _showCandles = true; // Kerzen / Linie umschalten

  // Live-Chart-Daten (dynamisch aktualisiert)
  final Map<int, List<double>> _chartHistory = {};
  final Map<int, List<_Candle>> _candleHistory = {};
  // ignore: unused_field
  Color? _lastFlashColor;

  @override
  void initState() {
    super.initState();
    _tickCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    // Initialisiere Chart-Verlauf
    for (int i = 0; i < _pairs.length; i++) {
      _chartHistory[i] = _generateBaseChart(i);
      _candleHistory[i] = _generateCandles(i);
    }

    // Live-Preis-Timer: alle 2 Sekunden
    _priceTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      _totalTick++;
      setState(() {
        for (int i = 0; i < _pairs.length; i++) {
          final volatility = _pairs[i].symbol == 'QEMMA' ? 0.008 : 0.002;
          final change = (_rnd.nextDouble() - 0.485) * _pairs[i].price * volatility;
          _pairs[i].livePrice = (_pairs[i].livePrice + change)
              .clamp(_pairs[i].price * 0.85, _pairs[i].price * 1.15);
          // Chart aktualisieren
          final hist = _chartHistory[i]!;
          hist.add(_pairs[i].livePrice);
          if (hist.length > 60) hist.removeAt(0);
          // Kerzen aktualisieren
          final candles = _candleHistory[i]!;
          final lastCandle = candles.last;
          final newClose = _pairs[i].livePrice;
          candles[candles.length - 1] = _Candle(
            lastCandle.open,
            newClose > lastCandle.high ? newClose : lastCandle.high,
            newClose < lastCandle.low  ? newClose : lastCandle.low,
            newClose,
          );
          // Neue Kerze alle 5 Updates
          if (_totalTick % 5 == 0) {
            candles.add(_Candle(newClose, newClose, newClose, newClose));
            if (candles.length > 30) candles.removeAt(0);
          }
          // Trend-Update
          _pairs[i].liveTrend = change >= 0;
        }
        if (_selectedPair < _pairs.length) {
          _lastFlashColor = _pairs[_selectedPair].liveTrend ? null : null;
        }
      });
      _pulseCtrl.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _tickCtrl.dispose();
    _pulseCtrl.dispose();
    _priceTimer.cancel();
    _qtyCtrl.dispose();
    _limitCtrl.dispose();
    _stopCtrl.dispose();
    super.dispose();
  }

  List<double> _generateBaseChart(int seed) {
    final rnd = Random(seed * 17);
    double price = 100;
    return List.generate(50, (i) {
      price += (rnd.nextDouble() - 0.47) * 4;
      return price.clamp(60, 160);
    });
  }

  List<_Candle> _generateCandles(int seed) {
    final rnd = Random(seed * 31 + 7);
    double price = 100;
    return List.generate(24, (i) {
      final open = price;
      final move = (rnd.nextDouble() - 0.47) * 5;
      final close = (open + move).clamp(60.0, 160.0);
      final high = [open, close].reduce(max) + rnd.nextDouble() * 2;
      final low  = [open, close].reduce(min) - rnd.nextDouble() * 2;
      price = close;
      return _Candle(open, high.clamp(60.0, 165.0), low.clamp(55.0, 160.0), close);
    });
  }

  List<FlSpot> _getChartSpots(int idx) {
    final hist = _chartHistory[idx] ?? [];
    return List.generate(hist.length, (i) => FlSpot(i.toDouble(), hist[i]));
  }

  void _placeOrder() {
    HapticFeedback.mediumImpact();
    setState(() => _orderPlaced = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _orderPlaced = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;
    final pair = _pairs[_selectedPair];

    return Column(
      children: [
        // Pair Selector
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _pairs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final selected = _selectedPair == i;
              final pr = _pairs[i];
              final up = pr.liveTrend;
              return GestureDetector(
                onTap: () => setState(() => _selectedPair = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? p.primary.withValues(alpha: 0.15)
                        : p.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected
                            ? p.primary
                            : p.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(pr.symbol,
                          style: GoogleFonts.rajdhani(
                              color: selected ? p.primary : p.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      Text(
                        pr.symbol == 'QEMMA'
                            ? '\$${pr.livePrice.toStringAsFixed(4)}'
                            : '${up ? '▲' : '▼'} \$${pr.livePrice.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: up ? p.positive : p.negative,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildLivePriceCard(p, pair),
                const SizedBox(height: 12),
                _buildLiveChart(p),
                const SizedBox(height: 12),
                _buildEmmaSignalCard(p, pair),
                const SizedBox(height: 12),
                _buildOrderPanel(p, pair),
                const SizedBox(height: 12),
                _buildMarketStats(p, pair),
                const SizedBox(height: 12),
                _buildOrderBook(p, pair),
                const SizedBox(height: 12),
                _buildDepthChart(p, pair),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLivePriceCard(dynamic p, _TradingPair pair) {
    final isQemma = pair.symbol == 'QEMMA';
    final priceStr = isQemma
        ? '\$${pair.livePrice.toStringAsFixed(4)}'
        : '\$${pair.livePrice.toStringAsFixed(2)}';

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final glow = _pulseCtrl.value * 0.3;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: p.primary.withValues(alpha: 0.2 + glow)),
            boxShadow: [
              BoxShadow(
                  color: p.primary.withValues(alpha: glow * 0.4),
                  blurRadius: 12,
                  spreadRadius: 1),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('${pair.symbol}/USDT',
                          style: GoogleFonts.rajdhani(
                              color: p.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.positive.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: p.positive)),
                            const SizedBox(width: 4),
                            Text('LIVE',
                                style: TextStyle(
                                    color: p.positive,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ]),
                    Text(pair.name,
                        style: TextStyle(
                            color: p.textSecondary, fontSize: 11)),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Text(
                        priceStr,
                        key: ValueKey(priceStr),
                        style: GoogleFonts.rajdhani(
                            color: pair.liveTrend ? p.positive : p.negative,
                            fontSize: 30,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          (pair.isPositive ? p.positive : p.negative)
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(pair.changeStr,
                        style: GoogleFonts.rajdhani(
                            color: pair.isPositive ? p.positive : p.negative,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 6),
                  Text('24H Change',
                      style:
                          TextStyle(color: p.textSecondary, fontSize: 10)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.arrow_upward, color: p.positive, size: 11),
                    Text(
                        ' H: \$${(pair.price * 1.025).toStringAsFixed(isQemma ? 4 : 2)}',
                        style: TextStyle(color: p.positive, fontSize: 10)),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.arrow_downward, color: p.negative, size: 11),
                    Text(
                        ' L: \$${(pair.price * 0.978).toStringAsFixed(isQemma ? 4 : 2)}',
                        style: TextStyle(color: p.negative, fontSize: 10)),
                  ]),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveChart(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Header mit Toggle
          Row(
            children: [
              Icon(
                _showCandles ? Icons.candlestick_chart : Icons.show_chart,
                color: p.primary, size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _showCandles ? 'Kerzen-Chart' : 'Linien-Chart',
                style: GoogleFonts.rajdhani(
                  color: p.primary, fontSize: 14, fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // TradingView Toggle
              GestureDetector(
                onTap: () => setState(() => _showTradingView = !_showTradingView),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _showTradingView ? p.primary.withValues(alpha: 0.25) : p.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: p.primary.withValues(alpha: _showTradingView ? 0.6 : 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.tv, color: p.primary, size: 11),
                    const SizedBox(width: 3),
                    Text('TV', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 9, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
              // Kerzen / Linie Toggle
              GestureDetector(
                onTap: () => setState(() => _showCandles = !_showCandles),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: p.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showCandles ? Icons.show_chart : Icons.candlestick_chart,
                        color: p.primary, size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showCandles ? 'LINIE' : 'KERZEN',
                        style: GoogleFonts.spaceMono(color: p.primary, fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Timeframe
              Row(
                children: _timeframes.map((tf) {
                  final selected = _timeframe == tf;
                  return GestureDetector(
                    onTap: () => setState(() => _timeframe = tf),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected ? p.primary : p.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(tf, style: TextStyle(
                        color: selected ? p.background : p.textSecondary,
                        fontSize: 9, fontWeight: FontWeight.bold,
                      )),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // TradingView vs Local Chart Toggle
          if (_showTradingView)
            TradingViewWidget(
              symbol: _pairs[_selectedPair].symbol,
              palette: p,
              height: 280,
              interval: _timeframe == '15M' ? '15' : _timeframe == '1H' ? '60' : _timeframe == '4H' ? '240' : _timeframe == '1D' ? 'D' : 'W',
            )
          else
            SizedBox(
            height: 190,
            child: _showCandles
                ? _buildCandleChart(p)
                : _buildLineChart(p),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.auto_awesome, color: p.primary, size: 11),
            const SizedBox(width: 4),
            Text('Quantum-Resonanz · Live', style: TextStyle(
              color: p.textSecondary, fontSize: 10,
            )),
          ]),
        ],
      ),
    );
  }

  Widget _buildCandleChart(dynamic p) {
    final candles = _candleHistory[_selectedPair] ?? [];
    if (candles.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      painter: _CandlePainter(
        candles: candles,
        positiveColor: p.positive,
        negativeColor: p.negative,
        gridColor: p.primary.withValues(alpha: 0.06),
        textColor: p.textSecondary,
      ),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildLineChart(dynamic p) {
    final spots = _getChartSpots(_selectedPair);
    if (spots.isEmpty) return const SizedBox.shrink();
    final isUp = spots.last.y >= spots.first.y;
    final lineColor = isUp ? p.positive : p.negative;
    final minY = spots.map((s) => s.y).reduce(min) - 2;
    final maxY = spots.map((s) => s.y).reduce(max) + 2;

    return LineChart(
      LineChartData(
        minY: minY, maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: p.primary.withValues(alpha: 0.07), strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true, curveSmoothness: 0.3,
            color: lineColor, barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) => spot == barData.spots.last,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 4, color: lineColor,
                strokeWidth: 2, strokeColor: p.background,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.3),
                  lineColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmmaSignalCard(dynamic p, _TradingPair pair) {
    final signals = ['KAUFEN', 'KAUFEN', 'HALTEN', 'VERKAUFEN'];
    final signal =
        pair.isPositive ? signals[0] : (pair.change.abs() > 1 ? signals[3] : signals[2]);
    final signalColor = signal == 'KAUFEN'
        ? p.positive
        : signal == 'VERKAUFEN'
            ? p.negative
            : p.secondary;
    final conf = 72 + _rnd.nextInt(16);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        LinearGradient(colors: [p.primary, p.secondary])),
                child: Icon(Icons.remove_red_eye,
                    color: p.background, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emma Oracle Signal',
                        style: GoogleFonts.rajdhani(
                            color: p.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text(
                        'RSI: ${55 + _rnd.nextInt(20)} · Resonanz: +${(0.6 + _rnd.nextDouble() * 0.3).toStringAsFixed(2)} · Agenten: 5/6',
                        style: TextStyle(
                            color: p.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                        color: signalColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: signalColor.withValues(alpha: 0.5))),
                    child: Text(signal,
                        style: GoogleFonts.rajdhani(
                            color: signalColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 2),
                  Text('$conf% Konfidenz',
                      style: TextStyle(
                          color: p.textSecondary, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Agenten-Konsens-Leiste
          Row(children: [
            Text('Agenten-Konsens:',
                style: TextStyle(color: p.textSecondary, fontSize: 11)),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: conf / 100.0,
                  backgroundColor: p.negative.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(signalColor),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('$conf%',
                style: GoogleFonts.rajdhani(
                    color: signalColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  Widget _buildOrderPanel(dynamic p, _TradingPair pair) {
    final total = _quantity * pair.livePrice;
    final fee = total * 0.001;
    final isQemma = pair.symbol == 'QEMMA';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order eingeben',
              style: GoogleFonts.rajdhani(
                  color: p.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Kauf / Verkauf Toggle
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isBuy = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isBuy
                        ? p.positive.withValues(alpha: 0.2)
                        : p.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _isBuy
                            ? p.positive
                            : p.primary.withValues(alpha: 0.15)),
                  ),
                  child: Text('KAUFEN',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(
                          color: _isBuy ? p.positive : p.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isBuy = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_isBuy
                        ? p.negative.withValues(alpha: 0.2)
                        : p.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: !_isBuy
                            ? p.negative
                            : p.primary.withValues(alpha: 0.15)),
                  ),
                  child: Text('VERKAUFEN',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(
                          color: !_isBuy ? p.negative : p.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          // Order-Typ
          Row(
            children: _orderTypes.map((ot) {
              final sel = _orderType == ot;
              return GestureDetector(
                onTap: () => setState(() => _orderType = ot),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        sel ? p.primary : p.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(ot,
                      style: TextStyle(
                          color: sel ? p.background : p.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Preis-Info
          Row(children: [
            Expanded(
              child: _InfoTile(
                  label: 'Preis (USDT)',
                  value: isQemma
                      ? '\$${pair.livePrice.toStringAsFixed(4)}'
                      : '\$${pair.livePrice.toStringAsFixed(2)}',
                  p: p),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Menge (${pair.symbol})',
                      style: TextStyle(
                          color: p.textSecondary, fontSize: 10)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style:
                        GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: p.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: p.primary.withValues(alpha: 0.2))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: p.primary, width: 1.5)),
                      hintText: '0.00',
                      hintStyle: TextStyle(
                          color: p.textSecondary, fontSize: 12),
                    ),
                    onChanged: (v) {
                      setState(() =>
                          _quantity = double.tryParse(v) ?? 0.0);
                    },
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          // Quick-Prozente
          Row(children: [
            Text('Schnell:',
                style: TextStyle(
                    color: p.textSecondary, fontSize: 10)),
            const SizedBox(width: 8),
            ...['25%', '50%', '75%', '100%'].map((pct) {
              final factor = int.parse(pct.replaceAll('%', '')) / 100.0;
              return GestureDetector(
                onTap: () {
                  const maxBudget = 1000.0;
                  final qty = (maxBudget * factor) / pair.livePrice;
                  setState(() {
                    _quantity = qty;
                    _qtyCtrl.text = qty.toStringAsFixed(4);
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: p.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(pct,
                      style: TextStyle(
                          color: p.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              );
            }),
          ]),
          const SizedBox(height: 10),
          // ── Limit/Stop Preis (wenn LIMIT/STOP gewählt) ──
          if (_orderType == 'LIMIT' || _orderType == 'STOP') ...[
            Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_orderType == 'LIMIT' ? 'Limit-Preis (USDT)' : 'Stop-Preis (USDT)',
                        style: TextStyle(color: p.textSecondary, fontSize: 10)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _orderType == 'LIMIT' ? _limitCtrl : _stopCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.rajdhani(color: p.primary, fontSize: 14,
                          fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true, fillColor: p.primary.withValues(alpha: 0.06),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: p.primary.withValues(alpha: 0.35))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: p.primary, width: 1.5)),
                        hintText: pair.livePrice >= 100
                            ? pair.livePrice.toStringAsFixed(2)
                            : pair.livePrice.toStringAsFixed(4),
                        hintStyle: TextStyle(color: p.textSecondary, fontSize: 12),
                        prefixText: '\$ ',
                        prefixStyle: TextStyle(color: p.primary),
                      ),
                      onChanged: (v) => setState(() {
                        if (_orderType == 'LIMIT') {
                          _limitPrice = double.tryParse(v) ?? 0.0;
                        } else {
                          _stopPrice = double.tryParse(v) ?? 0.0;
                        }
                      }),
                    ),
                  ],
                )),
                const SizedBox(width: 8),
                // Preset-Buttons
                Column(
                  children: [
                    _PricePresetBtn(
                      label: '-1%',
                      color: p.negative,
                      p: p,
                      onTap: () {
                        final price = pair.livePrice * 0.99;
                        _limitCtrl.text = price.toStringAsFixed(
                            price >= 100 ? 2 : 4);
                        setState(() => _limitPrice = price);
                      },
                    ),
                    const SizedBox(height: 4),
                    _PricePresetBtn(
                      label: '+1%',
                      color: p.positive,
                      p: p,
                      onTap: () {
                        final price = pair.livePrice * 1.01;
                        _limitCtrl.text = price.toStringAsFixed(
                            price >= 100 ? 2 : 4);
                        setState(() => _limitPrice = price);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          // ── Erweiterte Optionen Toggle ────────────
          GestureDetector(
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            child: Row(children: [
              Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more,
                  color: p.primary, size: 16),
              const SizedBox(width: 6),
              Text('Take Profit / Stop Loss',
                  style: GoogleFonts.spaceMono(color: p.primary, fontSize: 9,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_takeProfitPct > 0 || _stopLossPct > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.positive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Aktiv', style: GoogleFonts.spaceMono(
                      color: p.positive, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
            ]),
          ),
          if (_showAdvanced) ...[
            const SizedBox(height: 10),
            // Take Profit Slider
            _TpSlLabel('Take Profit', '${_takeProfitPct.toStringAsFixed(1)}%',
                p.positive, p),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbSize: const WidgetStatePropertyAll(Size.fromRadius(7)),
                activeTrackColor: p.positive,
                inactiveTrackColor: p.surfaceVariant,
                thumbColor: p.positive,
                overlayColor: p.positive.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: _takeProfitPct,
                min: 0, max: 50,
                divisions: 50,
                onChanged: (v) => setState(() => _takeProfitPct = v),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0%', style: TextStyle(color: p.textSecondary, fontSize: 9)),
                if (_takeProfitPct > 0 && _quantity > 0)
                  Text(
                    'Ziel: \$${(pair.livePrice * (1 + _takeProfitPct / 100)).toStringAsFixed(pair.livePrice >= 100 ? 2 : 4)}',
                    style: GoogleFonts.spaceMono(color: p.positive, fontSize: 9),
                  ),
                Text('+50%', style: TextStyle(color: p.textSecondary, fontSize: 9)),
              ],
            ),
            const SizedBox(height: 8),
            // Stop Loss Slider
            _TpSlLabel('Stop Loss', '-${_stopLossPct.toStringAsFixed(1)}%',
                p.negative, p),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbSize: const WidgetStatePropertyAll(Size.fromRadius(7)),
                activeTrackColor: p.negative,
                inactiveTrackColor: p.surfaceVariant,
                thumbColor: p.negative,
                overlayColor: p.negative.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: _stopLossPct,
                min: 0, max: 30,
                divisions: 30,
                onChanged: (v) => setState(() => _stopLossPct = v),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0%', style: TextStyle(color: p.textSecondary, fontSize: 9)),
                if (_stopLossPct > 0 && _quantity > 0)
                  Text(
                    'SL: \$${(pair.livePrice * (1 - _stopLossPct / 100)).toStringAsFixed(pair.livePrice >= 100 ? 2 : 4)}',
                    style: GoogleFonts.spaceMono(color: p.negative, fontSize: 9),
                  ),
                Text('-30%', style: TextStyle(color: p.textSecondary, fontSize: 9)),
              ],
            ),
            const SizedBox(height: 6),
            // Risk/Reward Anzeige
            if (_takeProfitPct > 0 && _stopLossPct > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: p.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Risk/Reward', style: GoogleFonts.spaceMono(
                        color: p.textSecondary, fontSize: 9)),
                    Text(
                      '1 : ${(_takeProfitPct / _stopLossPct).toStringAsFixed(1)}',
                      style: GoogleFonts.rajdhani(
                          color: _takeProfitPct / _stopLossPct >= 2
                              ? p.positive : p.accent,
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _takeProfitPct / _stopLossPct >= 2 ? '✅ Gut' : '⚠️ Niedrig',
                      style: GoogleFonts.spaceMono(
                          color: _takeProfitPct / _stopLossPct >= 2
                              ? p.positive : p.accent,
                          fontSize: 8),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _InfoTile(
                  label: 'Gesamt (USDT)',
                  value: '\$${total.toStringAsFixed(2)}',
                  p: p),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoTile(
                  label: 'Gebühr (0.1%)',
                  value: '\$${fee.toStringAsFixed(4)}',
                  p: p),
            ),
          ]),
          const SizedBox(height: 14),
          // Order Button
          if (_orderPlaced)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: p.positive.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.positive),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: p.positive, size: 18),
                  const SizedBox(width: 8),
                  Text('Order erfolgreich platziert!',
                      style: GoogleFonts.rajdhani(
                          color: p.positive,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: _quantity > 0 ? _placeOrder : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isBuy
                        ? [p.positive, p.positive.withValues(alpha: 0.7)]
                        : [p.negative, p.negative.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _quantity > 0
                      ? [
                          BoxShadow(
                              color: (_isBuy ? p.positive : p.negative)
                                  .withValues(alpha: 0.4),
                              blurRadius: 12)
                        ]
                      : [],
                ),
                child: Text(
                  '${_isBuy ? "KAUFEN" : "VERKAUFEN"} ${pair.symbol}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rajdhani(
                      color: _quantity > 0 ? p.background : p.background.withValues(alpha: 0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarketStats(dynamic p, _TradingPair pair) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Markt-Statistiken',
              style: GoogleFonts.rajdhani(
                  color: p.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...[
            ('Marktkapitalisierung',
                '\$${(pair.livePrice * 19700000).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'),
            ('24H Volumen',
                '\$${(pair.livePrice * 850000).toStringAsFixed(0)}'),
            ('Umlaufangebot', '19.7M ${pair.symbol}'),
            ('Quantum-Score', '${72 + _rnd.nextInt(20)}/100'),
            ('Agenten-Konsens', '5/6 Bullisch'),
            ('Volatilität (24H)', '${(2.1 + _rnd.nextDouble() * 3).toStringAsFixed(1)}%'),
          ].map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.$1,
                        style: TextStyle(
                            color: p.textSecondary, fontSize: 12)),
                    Text(e.$2,
                        style: GoogleFonts.rajdhani(
                            color: p.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildOrderBook(dynamic p, _TradingPair pair) {
    final rnd = Random(_selectedPair * 3 + 7);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Book',
              style: GoogleFonts.rajdhani(
                  color: p.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KAUFEN',
                      style: TextStyle(
                          color: p.positive,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...List.generate(5, (i) {
                    final price = pair.livePrice * (1 - (i + 1) * 0.002);
                    final vol = (rnd.nextDouble() * 2 + 0.1);
                    return _OrderBookRow(
                        price: price,
                        volume: vol,
                        color: p.positive,
                        bg: p.positive,
                        p: p,
                        isAsk: false);
                  }),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VERKAUFEN',
                      style: TextStyle(
                          color: p.negative,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...List.generate(5, (i) {
                    final price = pair.livePrice * (1 + (i + 1) * 0.002);
                    final vol = (rnd.nextDouble() * 2 + 0.1);
                    return _OrderBookRow(
                        price: price,
                        volume: vol,
                        color: p.negative,
                        bg: p.negative,
                        p: p,
                        isAsk: true);
                  }),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Depth Chart ─────────────────────────────────
  Widget _buildDepthChart(dynamic p, _TradingPair pair) {
    final rnd = Random(_selectedPair * 11 + 5);
    // Generiere Bid/Ask Depth Daten
    final bids = <double>[];
    final asks = <double>[];
    double bidAccum = 0;
    double askAccum = 0;
    for (int i = 0; i < 20; i++) {
      bidAccum += rnd.nextDouble() * 3 + 0.5;
      askAccum += rnd.nextDouble() * 3 + 0.5;
      bids.add(bidAccum);
      asks.add(askAccum);
    }
    final maxDepth = [bids.last, asks.last].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('MARKTTIEFE', style: GoogleFonts.rajdhani(
                color: p.primary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: p.surfaceVariant, borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${pair.symbol}/USDT', style: GoogleFonts.spaceMono(
                  color: p.textSecondary, fontSize: 8)),
            ),
          ]),
          const SizedBox(height: 12),
          // Depth Chart Canvas
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _DepthChartPainter(
                bids: bids, asks: asks, maxDepth: maxDepth,
                bidColor: p.positive, askColor: p.negative,
                gridColor: p.primary.withValues(alpha: 0.06),
              ),
              size: const Size(double.infinity, 120),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 12, height: 3,
                decoration: BoxDecoration(color: p.positive, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 5),
            Text('Bids (Käufer)', style: GoogleFonts.spaceMono(
                color: p.textSecondary, fontSize: 8)),
            const SizedBox(width: 20),
            Container(width: 12, height: 3,
                decoration: BoxDecoration(color: p.negative, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 5),
            Text('Asks (Verkäufer)', style: GoogleFonts.spaceMono(
                color: p.textSecondary, fontSize: 8)),
          ]),
          const SizedBox(height: 10),
          // Spread Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: p.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: p.primary.withValues(alpha: 0.1)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _DepthMetric('Best Bid', '\$${(pair.livePrice * 0.9995).toStringAsFixed(2)}', p.positive, p),
              _DepthMetric('Spread', '\$${(pair.livePrice * 0.001).toStringAsFixed(2)}', p.accent, p),
              _DepthMetric('Best Ask', '\$${(pair.livePrice * 1.0005).toStringAsFixed(2)}', p.negative, p),
              _DepthMetric('Bid/Ask Vol', '${bids.last.toStringAsFixed(1)}/${asks.last.toStringAsFixed(1)}', p.primary, p),
            ]),
          ),
        ],
      ),
    );
  }
}

class _OrderBookRow extends StatelessWidget {
  final double price;
  final double volume;
  final Color color;
  final Color bg;
  final dynamic p;
  final bool isAsk;
  const _OrderBookRow(
      {required this.price,
      required this.volume,
      required this.color,
      required this.bg,
      required this.p,
      required this.isAsk});

  @override
  Widget build(BuildContext context) {
    final isQemma = price < 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Stack(
        children: [
          Positioned.fill(
            child: FractionallySizedBox(
              widthFactor: (volume / 3.0).clamp(0.1, 1.0),
              alignment:
                  isAsk ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                  color: bg.withValues(alpha: 0.07)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    isQemma
                        ? price.toStringAsFixed(4)
                        : price.toStringAsFixed(1),
                    style: TextStyle(
                        color: color, fontSize: 11)),
                Text(volume.toStringAsFixed(3),
                    style: TextStyle(
                        color: p.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TradingPair {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final bool isPositive;
  final String id;
  double livePrice;
  bool liveTrend;

  _TradingPair(this.symbol, this.name, this.price, this.change,
      this.isPositive, this.id)
      : livePrice = price,
        liveTrend = isPositive;

  String get changeStr =>
      '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%';
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final dynamic p;
  const _InfoTile(
      {required this.label, required this.value, required this.p});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: p.surfaceVariant,
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  TextStyle(color: p.textSecondary, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.rajdhani(
                  color: p.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Candle Data ────────────────────────────────────────
class _Candle {
  final double open, high, low, close;
  bool get isBullish => close >= open;
  _Candle(this.open, this.high, this.low, this.close);
}

// ── Candlestick Painter ────────────────────────────────
class _CandlePainter extends CustomPainter {
  final List<_Candle> candles;
  final Color positiveColor, negativeColor, gridColor, textColor;
  const _CandlePainter({
    required this.candles,
    required this.positiveColor,
    required this.negativeColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final allValues = candles.expand((c) => [c.high, c.low]).toList();
    final minVal = allValues.reduce(min) - 1;
    final maxVal = allValues.reduce(max) + 1;
    final range = maxVal - minVal;
    if (range == 0) return;

    double toY(double v) => size.height * (1 - (v - minVal) / range);

    // Grid-Linien
    final gridPaint = Paint()..color = gridColor..strokeWidth = 1;
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final candleCount = candles.length;
    final totalWidth = size.width;
    final candleWidth = (totalWidth / candleCount).clamp(4.0, 18.0);
    final bodyWidth = (candleWidth * 0.65).clamp(3.0, 14.0);

    for (int i = 0; i < candleCount; i++) {
      final c = candles[i];
      final x = i * candleWidth + candleWidth / 2;
      final color = c.isBullish ? positiveColor : negativeColor;

      final candlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final wickPaint = Paint()
        ..color = color.withAlpha(180)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      // Wick oben + unten
      canvas.drawLine(
        Offset(x, toY(c.high)),
        Offset(x, toY(c.isBullish ? c.close : c.open)),
        wickPaint,
      );
      canvas.drawLine(
        Offset(x, toY(c.isBullish ? c.open : c.close)),
        Offset(x, toY(c.low)),
        wickPaint,
      );

      // Körper
      final bodyTop    = toY(c.isBullish ? c.close : c.open);
      final bodyBottom = toY(c.isBullish ? c.open  : c.close);
      final bodyHeight = (bodyBottom - bodyTop).abs().clamp(1.5, size.height);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x - bodyWidth / 2,
            bodyTop,
            bodyWidth,
            bodyHeight,
          ),
          const Radius.circular(1.5),
        ),
        candlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CandlePainter old) =>
      old.candles != candles || old.candles.length != candles.length;
}

// ── Depth Chart Painter ────────────────────────────
class _DepthChartPainter extends CustomPainter {
  final List<double> bids, asks;
  final double maxDepth;
  final Color bidColor, askColor, gridColor;
  const _DepthChartPainter({
    required this.bids, required this.asks, required this.maxDepth,
    required this.bidColor, required this.askColor, required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final gridPaint = Paint()..color = gridColor..strokeWidth = 0.5;
    for (int i = 1; i < 4; i++) {
      final y = size.height / 4 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final w = size.width / 2;
    final h = size.height;

    // Draw bids (left side, green, mirrored)
    final bidFill = Paint()
      ..color = bidColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final bidLine = Paint()
      ..color = bidColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final bidPath = Path()..moveTo(w, h);
    for (int i = 0; i < bids.length; i++) {
      final x = w - (i / bids.length) * w;
      final y = h - (bids[i] / maxDepth) * h;
      bidPath.lineTo(x, y);
    }
    bidPath.lineTo(0, h);
    bidPath.close();
    canvas.drawPath(bidPath, bidFill);

    final bidLinePath = Path()..moveTo(w, h - (bids[0] / maxDepth) * h);
    for (int i = 1; i < bids.length; i++) {
      final x = w - (i / bids.length) * w;
      final y = h - (bids[i] / maxDepth) * h;
      bidLinePath.lineTo(x, y);
    }
    canvas.drawPath(bidLinePath, bidLine);

    // Draw asks (right side, red)
    final askFill = Paint()
      ..color = askColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final askLine = Paint()
      ..color = askColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final askPath = Path()..moveTo(w, h);
    for (int i = 0; i < asks.length; i++) {
      final x = w + (i / asks.length) * w;
      final y = h - (asks[i] / maxDepth) * h;
      askPath.lineTo(x, y);
    }
    askPath.lineTo(size.width, h);
    askPath.close();
    canvas.drawPath(askPath, askFill);

    final askLinePath = Path()..moveTo(w, h - (asks[0] / maxDepth) * h);
    for (int i = 1; i < asks.length; i++) {
      final x = w + (i / asks.length) * w;
      final y = h - (asks[i] / maxDepth) * h;
      askLinePath.lineTo(x, y);
    }
    canvas.drawPath(askLinePath, askLine);

    // Center line
    canvas.drawLine(Offset(w, 0), Offset(w, h),
        Paint()..color = Colors.white.withValues(alpha: 0.2)..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_DepthChartPainter old) => true;
}

// ── Depth Metric ───────────────────────────────────
class _DepthMetric extends StatelessWidget {
  final String label, value;
  final Color color;
  final dynamic p;
  const _DepthMetric(this.label, this.value, this.color, this.p);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7)),
      const SizedBox(height: 3),
      Text(value, style: GoogleFonts.rajdhani(
          color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    ]);
  }
}

// ── Price Preset Button ───────────────────────────
class _PricePresetBtn extends StatelessWidget {
  final String label;
  final Color color;
  final dynamic p;
  final VoidCallback onTap;
  const _PricePresetBtn({required this.label, required this.color,
      required this.p, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: GoogleFonts.spaceMono(
            color: color, fontSize: 9, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── TP/SL Label Row ───────────────────────────────
class _TpSlLabel extends StatelessWidget {
  final String label, value;
  final Color color;
  final dynamic p;
  const _TpSlLabel(this.label, this.value, this.color, this.p);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(value, style: GoogleFonts.spaceMono(
              color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
