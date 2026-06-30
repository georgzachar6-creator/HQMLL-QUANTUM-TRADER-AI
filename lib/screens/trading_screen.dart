import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/theme_provider.dart';
import '../widgets/tradingview_widget.dart';
import '../widgets/crypto_icon.dart';
import '../services/exchange_service.dart';

class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key});
  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen>
    with TickerProviderStateMixin {
  late AnimationController _tickCtrl;
  late AnimationController _pulseCtrl;
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
  bool _showTradingView = true; // TradingView als Standard aktiviert
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _limitCtrl = TextEditingController();
  final TextEditingController _stopCtrl = TextEditingController();
  final Random _rnd = Random();
  Timer? _chartTimer;

  // Pair-Definitionen: symbol, name, geckoId
  static const List<_PairDef> _pairDefs = [
    _PairDef('BTC', 'Bitcoin', 'bitcoin'),
    _PairDef('ETH', 'Ethereum', 'ethereum'),
    _PairDef('SOL', 'Solana', 'solana'),
    _PairDef('QEMMA', r'$QEMMA Token', 'qemma'),
    _PairDef('BNB', 'BNB Chain', 'binancecoin'),
    _PairDef('ADA', 'Cardano', 'cardano'),
  ];

  final List<String> _timeframes = ['15M', '1H', '4H', '1D', '1W'];
  final List<String> _orderTypes = ['MARKT', 'LIMIT', 'STOP'];
  bool _showCandles = true;

  // Lokaler Chart-Verlauf (normalisiert, unabhängig von echtem Preis)
  final Map<int, List<double>> _chartHistory = {};
  final Map<int, List<_Candle>> _candleHistory = {};

  @override
  void initState() {
    super.initState();
    _tickCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    // Initialisiere Chart-Verlauf (normalisiert: 100 = Basiswert)
    for (int i = 0; i < _pairDefs.length; i++) {
      _chartHistory[i] = _generateBaseChart(i);
      _candleHistory[i] = _generateCandles(i);
    }

    // Chart-Update Timer (nur für lokale Kerzen-Visualisierung)
    _chartTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      _totalTick++;
      final ex = context.read<ExchangeService>();
      setState(() {
        for (int i = 0; i < _pairDefs.length; i++) {
          final sym = _pairDefs[i].symbol;
          final tick = ex.getTick(sym);
          // Normalisierter Chart-Update basierend auf echtem Change
          final change = tick?.change24h ?? 0;
          final volatility = sym == 'QEMMA' ? 0.006 : 0.002;
          final delta = (_rnd.nextDouble() - 0.485 + (change > 0 ? 0.005 : -0.005)) * volatility * 100;
          final hist = _chartHistory[i]!;
          final last = hist.isNotEmpty ? hist.last : 100.0;
          hist.add((last + delta).clamp(60.0, 160.0));
          if (hist.length > 60) hist.removeAt(0);
          // Kerzen aktualisieren
          final candles = _candleHistory[i]!;
          final lastCandle = candles.last;
          final newClose = (lastCandle.close + delta).clamp(60.0, 165.0);
          candles[candles.length - 1] = _Candle(
            lastCandle.open,
            newClose > lastCandle.high ? newClose : lastCandle.high,
            newClose < lastCandle.low ? newClose : lastCandle.low,
            newClose,
          );
          if (_totalTick % 5 == 0) {
            candles.add(_Candle(newClose, newClose, newClose, newClose));
            if (candles.length > 30) candles.removeAt(0);
          }
        }
      });
      _pulseCtrl.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _tickCtrl.dispose();
    _pulseCtrl.dispose();
    _chartTimer?.cancel();
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
      return price.clamp(60.0, 160.0);
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

  void _placeOrder(ExchangeService ex) {
    HapticFeedback.mediumImpact();
    final sym = _pairDefs[_selectedPair].symbol;
    final price = ex.getPrice(sym);
    if (_quantity > 0 && price > 0) {
      ex.placeOrder(symbol: sym, isBuy: _isBuy, quantity: _quantity);
    }
    setState(() => _orderPlaced = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _orderPlaced = false);
    });
  }

  TvInterval _mapTimeframe(String tf) {
    switch (tf) {
      case '15M': return TvInterval.min15;
      case '1H':  return TvInterval.hour1;
      case '4H':  return TvInterval.hour4;
      case '1D':  return TvInterval.day1;
      case '1W':  return TvInterval.week1;
      default:    return TvInterval.hour4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;
    // ExchangeService für echte Preise
    final ex = context.watch<ExchangeService>();
    final def = _pairDefs[_selectedPair];
    final tick = ex.getTick(def.symbol);
    final livePrice = ex.getPrice(def.symbol);
    final isPositive = tick?.isPositive ?? true;
    final change24h = tick?.change24h ?? 0.0;

    return Column(
      children: [
        // ── Pair Selector mit echten Live-Preisen ──
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: p.surface.withValues(alpha: 0.3),
            border: Border(bottom: BorderSide(color: p.primary.withValues(alpha: 0.1))),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            itemCount: _pairDefs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final selected = _selectedPair == i;
              final pd = _pairDefs[i];
              final pTick = ex.getTick(pd.symbol);
              final pPrice = ex.getPrice(pd.symbol);
              final pUp = pTick?.isPositive ?? true;
              final meta = CryptoRegistry.getOrFallback(pd.symbol);
              return GestureDetector(
                onTap: () => setState(() => _selectedPair = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 78,
                  decoration: BoxDecoration(
                    color: selected
                        ? meta.primary.withValues(alpha: 0.18)
                        : p.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? meta.primary : meta.primary.withValues(alpha: 0.2),
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected ? [BoxShadow(
                      color: meta.primary.withValues(alpha: 0.35),
                      blurRadius: 10, spreadRadius: 0,
                    )] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CryptoIcon(pd.symbol, size: 28, showBorder: false, showShadow: selected),
                      const SizedBox(height: 3),
                      Text('${pd.symbol}/USDT',
                          style: GoogleFonts.spaceMono(
                              color: selected ? meta.primary : p.textPrimary,
                              fontSize: 7,
                              fontWeight: FontWeight.bold)),
                      Text(
                        pd.symbol == 'QEMMA'
                            ? '\$${pPrice.toStringAsFixed(4)}'
                            : '${pUp ? '▲' : '▼'}\$${pPrice >= 1000 ? '${(pPrice / 1000).toStringAsFixed(1)}K' : pPrice.toStringAsFixed(pPrice < 1 ? 3 : 0)}',
                        style: GoogleFonts.spaceMono(
                          color: pUp ? const Color(0xFF00C896) : const Color(0xFFFF3355),
                          fontSize: 7, fontWeight: FontWeight.bold,
                        ),
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
                _buildLivePriceCard(p, def, livePrice, isPositive, change24h, tick),
                const SizedBox(height: 12),
                _buildLiveChart(p, ex),
                const SizedBox(height: 12),
                _buildEmmaSignalCard(p, def, livePrice, isPositive, change24h, ex),
                const SizedBox(height: 12),
                _buildOrderPanel(p, def, livePrice, ex),
                const SizedBox(height: 12),
                _buildMarketStats(p, def, livePrice, tick),
                const SizedBox(height: 12),
                _buildOrderBook(p, def, livePrice),
                const SizedBox(height: 12),
                _buildDepthChart(p, def, livePrice),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLivePriceCard(dynamic p, _PairDef def, double livePrice,
      bool isPositive, double change24h, LiveTick? tick) {
    final isQemma = def.symbol == 'QEMMA';
    final priceStr = isQemma
        ? '\$${livePrice.toStringAsFixed(4)}'
        : '\$${livePrice.toStringAsFixed(2)}';
    final changeStr = '${change24h >= 0 ? '+' : ''}${change24h.toStringAsFixed(2)}%';
    final high24h = tick != null ? tick.ask * 1.015 : livePrice * 1.025;
    final low24h  = tick != null ? tick.bid * 0.985 : livePrice * 0.978;
    // Live/REST Indikator
    final isLive = tick?.isLive ?? false;

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final glow = _pulseCtrl.value * 0.3;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.primary.withValues(alpha: 0.2 + glow)),
            boxShadow: [BoxShadow(
                color: p.primary.withValues(alpha: glow * 0.4),
                blurRadius: 12, spreadRadius: 1)],
          ),
          child: Row(
            children: [
              CryptoIcon(def.symbol, size: 52, showShadow: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('${def.symbol}/USDT',
                          style: GoogleFonts.spaceMono(
                              color: p.textPrimary, fontSize: 16,
                              fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(width: 8),
                      // Live-Badge: grün=WebSocket, orange=REST
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isLive ? p.positive : const Color(0xFFFFAA00)).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 5, height: 5,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isLive ? p.positive : const Color(0xFFFFAA00))),
                          const SizedBox(width: 4),
                          Text(isLive ? 'WS LIVE' : 'REST',
                              style: TextStyle(
                                  color: isLive ? p.positive : const Color(0xFFFFAA00),
                                  fontSize: 8, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ]),
                    Text(def.name, style: TextStyle(color: p.textSecondary, fontSize: 11)),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Text(priceStr,
                          key: ValueKey(priceStr),
                          style: GoogleFonts.rajdhani(
                              color: isPositive ? p.positive : p.negative,
                              fontSize: 30, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isPositive ? p.positive : p.negative).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(changeStr,
                        style: GoogleFonts.rajdhani(
                            color: isPositive ? p.positive : p.negative,
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 6),
                  Text('24H Change', style: TextStyle(color: p.textSecondary, fontSize: 10)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.arrow_upward, color: p.positive, size: 11),
                    Text(' H: \$${high24h.toStringAsFixed(isQemma ? 4 : 2)}',
                        style: TextStyle(color: p.positive, fontSize: 10)),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.arrow_downward, color: p.negative, size: 11),
                    Text(' L: \$${low24h.toStringAsFixed(isQemma ? 4 : 2)}',
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

  Widget _buildLiveChart(dynamic p, ExchangeService ex) {
    final def = _pairDefs[_selectedPair];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Header mit Toggles
          Row(
            children: [
              Icon(_showCandles ? Icons.candlestick_chart : Icons.show_chart,
                  color: p.primary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _showTradingView ? 'TradingView · ${def.symbol}/USDT' :
                  (_showCandles ? 'Kerzen-Chart' : 'Linien-Chart'),
                  style: GoogleFonts.rajdhani(
                      color: p.primary, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              // TradingView Toggle (aktiv = blau)
              GestureDetector(
                onTap: () => setState(() => _showTradingView = !_showTradingView),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _showTradingView
                        ? p.primary.withValues(alpha: 0.25)
                        : p.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: p.primary.withValues(alpha: _showTradingView ? 0.6 : 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.tv, color: _showTradingView ? p.primary : p.textSecondary, size: 11),
                    const SizedBox(width: 3),
                    Text('TV', style: GoogleFonts.rajdhani(
                        color: _showTradingView ? p.primary : p.textSecondary,
                        fontSize: 9, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
              if (!_showTradingView) ...[
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
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_showCandles ? Icons.show_chart : Icons.candlestick_chart,
                          color: p.primary, size: 12),
                      const SizedBox(width: 4),
                      Text(_showCandles ? 'LINIE' : 'KERZEN',
                          style: GoogleFonts.spaceMono(color: p.primary, fontSize: 8)),
                    ]),
                  ),
                ),
                const SizedBox(width: 6),
              ],
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
                          fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // TradingView (Standard) oder lokaler Chart
          if (_showTradingView)
            TradingViewChart(
              symbol: def.symbol,
              exchange: 'BINANCE',
              height: 300,
              interval: _mapTimeframe(_timeframe),
              showToolbar: true,
              showVolume: true,
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
            Text(
              _showTradingView
                  ? 'TradingView · Echte Marktdaten'
                  : 'Quantum-Resonanz · Live',
              style: TextStyle(color: p.textSecondary, fontSize: 10),
            ),
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

    return LineChart(LineChartData(
      minY: minY, maxY: maxY,
      gridData: FlGridData(
        show: true, drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: p.primary.withValues(alpha: 0.07), strokeWidth: 1),
      ),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(
        spots: spots, isCurved: true, curveSmoothness: 0.3,
        color: lineColor, barWidth: 2.5,
        dotData: FlDotData(
          show: true,
          checkToShowDot: (spot, barData) => spot == barData.spots.last,
          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 4, color: lineColor, strokeWidth: 2, strokeColor: p.background),
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [lineColor.withValues(alpha: 0.3), lineColor.withValues(alpha: 0.0)],
          ),
        ),
      )],
    ));
  }

  Widget _buildEmmaSignalCard(dynamic p, _PairDef def, double livePrice,
      bool isPositive, double change24h, ExchangeService ex) {
    // Signal aus echtem Change und Preis ableiten
    final String signal;
    if (change24h > 3) {
      signal = 'STARK KAUFEN';
    } else if (change24h > 0.5) {
      signal = 'KAUFEN';
    } else if (change24h < -3) {
      signal = 'STARK VERKAUFEN';
    } else if (change24h < -0.5) {
      signal = 'VERKAUFEN';
    } else {
      signal = 'HALTEN';
    }

    final signalColor = signal.contains('KAUFEN')
        ? p.positive
        : signal.contains('VERKAUFEN') ? p.negative : p.secondary;
    final conf = (65 + (change24h.abs() * 3).clamp(0, 25)).round();
    // RSI simuliert basierend auf 24h Change
    final rsi = (50 + change24h * 2.5).clamp(20.0, 80.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [p.primary, p.secondary])),
            child: Icon(Icons.remove_red_eye, color: p.background, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Emma Oracle Signal',
                  style: GoogleFonts.rajdhani(
                      color: p.primary, fontSize: 14, fontWeight: FontWeight.bold)),
              Text(
                'RSI: ${rsi.toStringAsFixed(1)} · 24H: ${change24h >= 0 ? '+' : ''}${change24h.toStringAsFixed(2)}% · Agenten: 5/6',
                style: TextStyle(color: p.textSecondary, fontSize: 11),
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                  color: signalColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: signalColor.withValues(alpha: 0.5))),
              child: Text(signal,
                  style: GoogleFonts.rajdhani(
                      color: signalColor, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 2),
            Text('$conf% Konfidenz', style: TextStyle(color: p.textSecondary, fontSize: 10)),
          ]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Text('Agenten-Konsens:', style: TextStyle(color: p.textSecondary, fontSize: 11)),
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
          Text('$conf%', style: GoogleFonts.rajdhani(
              color: signalColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _buildOrderPanel(dynamic p, _PairDef def, double livePrice, ExchangeService ex) {
    final total = _quantity * livePrice;
    final fee = total * 0.001;
    final isQemma = def.symbol == 'QEMMA';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Order eingeben',
            style: GoogleFonts.rajdhani(
                color: p.primary, fontSize: 15, fontWeight: FontWeight.bold)),
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
                  color: _isBuy ? p.positive.withValues(alpha: 0.2) : p.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _isBuy ? p.positive : p.primary.withValues(alpha: 0.15)),
                ),
                child: Text('KAUFEN',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                        color: _isBuy ? p.positive : p.textSecondary,
                        fontSize: 14, fontWeight: FontWeight.bold)),
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
                  color: !_isBuy ? p.negative.withValues(alpha: 0.2) : p.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: !_isBuy ? p.negative : p.primary.withValues(alpha: 0.15)),
                ),
                child: Text('VERKAUFEN',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                        color: !_isBuy ? p.negative : p.textSecondary,
                        fontSize: 14, fontWeight: FontWeight.bold)),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? p.primary : p.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(ot,
                    style: TextStyle(
                        color: sel ? p.background : p.textSecondary,
                        fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Preis-Info (echter Preis aus ExchangeService)
        Row(children: [
          Expanded(
            child: _InfoTile(
                label: 'Preis (USDT)',
                value: isQemma
                    ? '\$${livePrice.toStringAsFixed(4)}'
                    : '\$${livePrice.toStringAsFixed(2)}',
                p: p),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Menge (${def.symbol})',
                  style: TextStyle(color: p.textSecondary, fontSize: 10)),
              const SizedBox(height: 4),
              TextField(
                controller: _qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  filled: true, fillColor: p.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: p.primary.withValues(alpha: 0.2))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: p.primary, width: 1.5)),
                  hintText: '0.00',
                  hintStyle: TextStyle(color: p.textSecondary, fontSize: 12),
                ),
                onChanged: (v) => setState(() => _quantity = double.tryParse(v) ?? 0.0),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        // Quick-Prozente
        Row(children: [
          Text('Schnell:', style: TextStyle(color: p.textSecondary, fontSize: 10)),
          const SizedBox(width: 8),
          ...['25%', '50%', '75%', '100%'].map((pct) {
            final factor = int.parse(pct.replaceAll('%', '')) / 100.0;
            return GestureDetector(
              onTap: () {
                const maxBudget = 1000.0;
                final qty = (maxBudget * factor) / livePrice;
                setState(() {
                  _quantity = qty;
                  _qtyCtrl.text = qty.toStringAsFixed(4);
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: p.primary.withValues(alpha: 0.3)),
                ),
                child: Text(pct, style: TextStyle(
                    color: p.primary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            );
          }),
        ]),
        const SizedBox(height: 10),
        // Limit/Stop Preis
        if (_orderType == 'LIMIT' || _orderType == 'STOP') ...[
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_orderType == 'LIMIT' ? 'Limit-Preis (USDT)' : 'Stop-Preis (USDT)',
                    style: TextStyle(color: p.textSecondary, fontSize: 10)),
                const SizedBox(height: 4),
                TextField(
                  controller: _orderType == 'LIMIT' ? _limitCtrl : _stopCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.rajdhani(color: p.primary, fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true, fillColor: p.primary.withValues(alpha: 0.06),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: p.primary.withValues(alpha: 0.35))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: p.primary, width: 1.5)),
                    hintText: livePrice >= 100
                        ? livePrice.toStringAsFixed(2) : livePrice.toStringAsFixed(4),
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
              ]),
            ),
            const SizedBox(width: 8),
            Column(children: [
              _PricePresetBtn(label: '-1%', color: p.negative, p: p, onTap: () {
                final price = livePrice * 0.99;
                _limitCtrl.text = price.toStringAsFixed(price >= 100 ? 2 : 4);
                setState(() => _limitPrice = price);
              }),
              const SizedBox(height: 4),
              _PricePresetBtn(label: '+1%', color: p.positive, p: p, onTap: () {
                final price = livePrice * 1.01;
                _limitCtrl.text = price.toStringAsFixed(price >= 100 ? 2 : 4);
                setState(() => _limitPrice = price);
              }),
            ]),
          ]),
          const SizedBox(height: 10),
        ],
        // Take Profit / Stop Loss Toggle
        GestureDetector(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          child: Row(children: [
            Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more,
                color: p.primary, size: 16),
            const SizedBox(width: 6),
            Text('Take Profit / Stop Loss',
                style: GoogleFonts.spaceMono(
                    color: p.primary, fontSize: 9, fontWeight: FontWeight.bold)),
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
          _TpSlLabel('Take Profit', '${_takeProfitPct.toStringAsFixed(1)}%', p.positive, p),
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
              value: _takeProfitPct, min: 0, max: 50, divisions: 50,
              onChanged: (v) => setState(() => _takeProfitPct = v),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('0%', style: TextStyle(color: p.textSecondary, fontSize: 9)),
            if (_takeProfitPct > 0 && _quantity > 0)
              Text(
                'Ziel: \$${(livePrice * (1 + _takeProfitPct / 100)).toStringAsFixed(livePrice >= 100 ? 2 : 4)}',
                style: GoogleFonts.spaceMono(color: p.positive, fontSize: 9),
              ),
            Text('+50%', style: TextStyle(color: p.textSecondary, fontSize: 9)),
          ]),
          const SizedBox(height: 8),
          _TpSlLabel('Stop Loss', '-${_stopLossPct.toStringAsFixed(1)}%', p.negative, p),
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
              value: _stopLossPct, min: 0, max: 30, divisions: 30,
              onChanged: (v) => setState(() => _stopLossPct = v),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('0%', style: TextStyle(color: p.textSecondary, fontSize: 9)),
            if (_stopLossPct > 0 && _quantity > 0)
              Text(
                'SL: \$${(livePrice * (1 - _stopLossPct / 100)).toStringAsFixed(livePrice >= 100 ? 2 : 4)}',
                style: GoogleFonts.spaceMono(color: p.negative, fontSize: 9),
              ),
            Text('-30%', style: TextStyle(color: p.textSecondary, fontSize: 9)),
          ]),
          const SizedBox(height: 6),
          if (_takeProfitPct > 0 && _stopLossPct > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.primary.withValues(alpha: 0.15)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Risk/Reward',
                    style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
                Text(
                  '1 : ${(_takeProfitPct / _stopLossPct).toStringAsFixed(1)}',
                  style: GoogleFonts.rajdhani(
                      color: _takeProfitPct / _stopLossPct >= 2 ? p.positive : p.accent,
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  _takeProfitPct / _stopLossPct >= 2 ? '✅ Gut' : '⚠️ Niedrig',
                  style: GoogleFonts.spaceMono(
                      color: _takeProfitPct / _stopLossPct >= 2 ? p.positive : p.accent,
                      fontSize: 8),
                ),
              ]),
            ),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _InfoTile(label: 'Gesamt (USDT)', value: '\$${total.toStringAsFixed(2)}', p: p)),
          const SizedBox(width: 8),
          Expanded(
              child: _InfoTile(label: 'Gebühr (0.1%)', value: '\$${fee.toStringAsFixed(4)}', p: p)),
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
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle, color: p.positive, size: 18),
              const SizedBox(width: 8),
              Text('Order erfolgreich platziert!',
                  style: GoogleFonts.rajdhani(
                      color: p.positive, fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
          )
        else
          GestureDetector(
            onTap: _quantity > 0 ? () => _placeOrder(ex) : null,
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
                    ? [BoxShadow(
                        color: (_isBuy ? p.positive : p.negative).withValues(alpha: 0.4),
                        blurRadius: 12)]
                    : [],
              ),
              child: Text(
                '${_isBuy ? "KAUFEN" : "VERKAUFEN"} ${def.symbol}',
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                    color: _quantity > 0
                        ? p.background
                        : p.background.withValues(alpha: 0.5),
                    fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildMarketStats(dynamic p, _PairDef def, double livePrice, LiveTick? tick) {
    final vol = tick?.volume ?? livePrice * 850000;
    final mcap = livePrice * 19700000;
    final change = tick?.change24h ?? 0.0;
    final volStr = vol >= 1e9
        ? '\$${(vol / 1e9).toStringAsFixed(2)}B'
        : vol >= 1e6
            ? '\$${(vol / 1e6).toStringAsFixed(1)}M'
            : '\$${vol.toStringAsFixed(0)}';
    final mcapStr = mcap >= 1e9
        ? '\$${(mcap / 1e9).toStringAsFixed(2)}B'
        : '\$${mcap.toStringAsFixed(0)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Markt-Statistiken',
            style: GoogleFonts.rajdhani(
                color: p.primary, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...[
          ('Marktkapitalisierung', mcapStr),
          ('24H Volumen', volStr),
          ('Umlaufangebot', '19.7M ${def.symbol}'),
          ('24H Änderung', '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%'),
          ('Quantum-Score', '${(72 + change.abs() * 2).clamp(60, 98).round()}/100'),
          ('Volatilität (24H)', '${(2.1 + change.abs() * 0.5).toStringAsFixed(1)}%'),
        ].map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.$1, style: TextStyle(color: p.textSecondary, fontSize: 12)),
                Text(e.$2,
                    style: GoogleFonts.rajdhani(
                        color: e.$1 == '24H Änderung'
                            ? (change >= 0 ? p.positive : p.negative)
                            : p.textPrimary,
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            )),
      ]),
    );
  }

  Widget _buildOrderBook(dynamic p, _PairDef def, double livePrice) {
    final rnd = Random(_selectedPair * 3 + 7);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Order Book', style: GoogleFonts.rajdhani(
            color: p.primary, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('KAUFEN', style: TextStyle(
                  color: p.positive, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...List.generate(5, (i) {
                final price = livePrice * (1 - (i + 1) * 0.002);
                final vol = (rnd.nextDouble() * 2 + 0.1);
                return _OrderBookRow(price: price, volume: vol, color: p.positive,
                    bg: p.positive, p: p, isAsk: false);
              }),
            ]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('VERKAUFEN', style: TextStyle(
                  color: p.negative, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...List.generate(5, (i) {
                final price = livePrice * (1 + (i + 1) * 0.002);
                final vol = (rnd.nextDouble() * 2 + 0.1);
                return _OrderBookRow(price: price, volume: vol, color: p.negative,
                    bg: p.negative, p: p, isAsk: true);
              }),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _buildDepthChart(dynamic p, _PairDef def, double livePrice) {
    final rnd = Random(_selectedPair * 11 + 5);
    final bids = <double>[];
    final asks = <double>[];
    double bidAccum = 0, askAccum = 0;
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('MARKTTIEFE', style: GoogleFonts.rajdhani(
              color: p.primary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: p.surfaceVariant, borderRadius: BorderRadius.circular(6)),
            child: Text('${def.symbol}/USDT',
                style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
          ),
        ]),
        const SizedBox(height: 12),
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
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 12, height: 3,
              decoration: BoxDecoration(color: p.positive, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 5),
          Text('Bids (Käufer)', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
          const SizedBox(width: 20),
          Container(width: 12, height: 3,
              decoration: BoxDecoration(color: p.negative, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 5),
          Text('Asks (Verkäufer)', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: p.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: p.primary.withValues(alpha: 0.1)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _DepthMetric('Best Bid', '\$${(livePrice * 0.9995).toStringAsFixed(2)}', p.positive, p),
            _DepthMetric('Spread', '\$${(livePrice * 0.001).toStringAsFixed(2)}', p.accent, p),
            _DepthMetric('Best Ask', '\$${(livePrice * 1.0005).toStringAsFixed(2)}', p.negative, p),
            _DepthMetric('Vol B/A', '${bids.last.toStringAsFixed(1)}/${asks.last.toStringAsFixed(1)}', p.primary, p),
          ]),
        ),
      ]),
    );
  }
}

// ── Pair Definition ────────────────────────────────────────
class _PairDef {
  final String symbol;
  final String name;
  final String geckoId;
  const _PairDef(this.symbol, this.name, this.geckoId);
}

// ── Order Book Row ─────────────────────────────────────────
class _OrderBookRow extends StatelessWidget {
  final double price, volume;
  final Color color, bg;
  final dynamic p;
  final bool isAsk;
  const _OrderBookRow({required this.price, required this.volume,
      required this.color, required this.bg, required this.p, required this.isAsk});
  @override
  Widget build(BuildContext context) {
    final isQemma = price < 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Stack(children: [
        Positioned.fill(
          child: FractionallySizedBox(
            widthFactor: (volume / 3.0).clamp(0.1, 1.0),
            alignment: isAsk ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(color: bg.withValues(alpha: 0.07)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(isQemma ? price.toStringAsFixed(4) : price.toStringAsFixed(1),
                style: TextStyle(color: color, fontSize: 11)),
            Text(volume.toStringAsFixed(3),
                style: TextStyle(color: p.textSecondary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}

// ── Info Tile ──────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final String label, value;
  final dynamic p;
  const _InfoTile({required this.label, required this.value, required this.p});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: p.surfaceVariant, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: p.textSecondary, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.rajdhani(
                color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Candle Data ────────────────────────────────────────────
class _Candle {
  final double open, high, low, close;
  bool get isBullish => close >= open;
  _Candle(this.open, this.high, this.low, this.close);
}

// ── Candlestick Painter ────────────────────────────────────
class _CandlePainter extends CustomPainter {
  final List<_Candle> candles;
  final Color positiveColor, negativeColor, gridColor, textColor;
  const _CandlePainter({
    required this.candles, required this.positiveColor,
    required this.negativeColor, required this.gridColor, required this.textColor,
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
    final gridPaint = Paint()..color = gridColor..strokeWidth = 1;
    for (int i = 1; i < 5; i++) {
      canvas.drawLine(Offset(0, size.height * i / 5),
          Offset(size.width, size.height * i / 5), gridPaint);
    }
    final candleWidth = (size.width / candles.length).clamp(4.0, 18.0);
    final bodyWidth = (candleWidth * 0.65).clamp(3.0, 14.0);
    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = i * candleWidth + candleWidth / 2;
      final color = c.isBullish ? positiveColor : negativeColor;
      final wickPaint = Paint()
        ..color = color.withAlpha(180)
        ..strokeWidth = 1.2 ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(x, toY(c.high)),
          Offset(x, toY(c.isBullish ? c.close : c.open)), wickPaint);
      canvas.drawLine(Offset(x, toY(c.isBullish ? c.open : c.close)),
          Offset(x, toY(c.low)), wickPaint);
      final bodyTop = toY(c.isBullish ? c.close : c.open);
      final bodyBottom = toY(c.isBullish ? c.open : c.close);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - bodyWidth / 2, bodyTop, bodyWidth,
              (bodyBottom - bodyTop).abs().clamp(1.5, size.height)),
          const Radius.circular(1.5),
        ),
        Paint()..color = color..style = PaintingStyle.fill,
      );
    }
  }
  @override
  bool shouldRepaint(_CandlePainter old) =>
      old.candles != candles || old.candles.length != candles.length;
}

// ── Depth Chart Painter ────────────────────────────────────
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
    final gridPaint = Paint()..color = gridColor..strokeWidth = 0.5;
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(Offset(0, size.height / 4 * i),
          Offset(size.width, size.height / 4 * i), gridPaint);
    }
    final w = size.width / 2;
    final h = size.height;
    final bidFill = Paint()..color = bidColor.withValues(alpha: 0.15)..style = PaintingStyle.fill;
    final bidLine = Paint()..color = bidColor.withValues(alpha: 0.8)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final bidPath = Path()..moveTo(w, h);
    for (int i = 0; i < bids.length; i++) {
      bidPath.lineTo(w - (i / bids.length) * w, h - (bids[i] / maxDepth) * h);
    }
    bidPath.lineTo(0, h); bidPath.close();
    canvas.drawPath(bidPath, bidFill);
    final bidLinePath = Path()..moveTo(w, h - (bids[0] / maxDepth) * h);
    for (int i = 1; i < bids.length; i++) {
      bidLinePath.lineTo(w - (i / bids.length) * w, h - (bids[i] / maxDepth) * h);
    }
    canvas.drawPath(bidLinePath, bidLine);
    final askFill = Paint()..color = askColor.withValues(alpha: 0.15)..style = PaintingStyle.fill;
    final askLine = Paint()..color = askColor.withValues(alpha: 0.8)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final askPath = Path()..moveTo(w, h);
    for (int i = 0; i < asks.length; i++) {
      askPath.lineTo(w + (i / asks.length) * w, h - (asks[i] / maxDepth) * h);
    }
    askPath.lineTo(size.width, h); askPath.close();
    canvas.drawPath(askPath, askFill);
    final askLinePath = Path()..moveTo(w, h - (asks[0] / maxDepth) * h);
    for (int i = 1; i < asks.length; i++) {
      askLinePath.lineTo(w + (i / asks.length) * w, h - (asks[i] / maxDepth) * h);
    }
    canvas.drawPath(askLinePath, askLine);
    canvas.drawLine(Offset(w, 0), Offset(w, h),
        Paint()..color = Colors.white.withValues(alpha: 0.2)..strokeWidth = 1);
  }
  @override
  bool shouldRepaint(_DepthChartPainter old) => true;
}

// ── Depth Metric ───────────────────────────────────────────
class _DepthMetric extends StatelessWidget {
  final String label, value;
  final Color color;
  final dynamic p;
  const _DepthMetric(this.label, this.value, this.color, this.p);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7)),
    const SizedBox(height: 3),
    Text(value, style: GoogleFonts.rajdhani(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
  ]);
}

// ── Price Preset Button ────────────────────────────────────
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

// ── TP/SL Label Row ────────────────────────────────────────
class _TpSlLabel extends StatelessWidget {
  final String label, value;
  final Color color;
  final dynamic p;
  const _TpSlLabel(this.label, this.value, this.color, this.p);
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
        child: Text(value, style: GoogleFonts.spaceMono(
            color: color, fontSize: 9, fontWeight: FontWeight.bold)),
      ),
    ]);
  }
}
