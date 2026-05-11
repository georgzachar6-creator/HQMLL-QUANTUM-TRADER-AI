// ============================================================
// TRADINGVIEW WIDGET – Quantum Trader v20
// Full TradingView Chart Embedding via WebView
// ============================================================
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';

// ── Chart Interval Enum ───────────────────────────────────
enum TvInterval {
  min1('1', '1m'),
  min5('5', '5m'),
  min15('15', '15m'),
  min30('30', '30m'),
  hour1('60', '1H'),
  hour4('240', '4H'),
  day1('D', '1D'),
  week1('W', '1W'),
  month1('M', '1M');

  final String value;
  final String label;
  const TvInterval(this.value, this.label);
}

// ── Chart Style ───────────────────────────────────────────
enum TvChartStyle {
  candles(1, 'Candles'),
  bars(0, 'Bars'),
  line(2, 'Line'),
  area(3, 'Area'),
  heikinAshi(8, 'Heikin Ashi'),
  hollowCandles(9, 'Hollow');

  final int value;
  final String label;
  const TvChartStyle(this.value, this.label);
}

// ── TradingView Chart Widget ──────────────────────────────
class TradingViewChart extends StatefulWidget {
  final String symbol;
  final String exchange;
  final TvInterval interval;
  final TvChartStyle chartStyle;
  final bool showToolbar;
  final bool showVolume;
  final bool showIndicators;
  final double height;
  final List<String> studies;

  const TradingViewChart({
    super.key,
    required this.symbol,
    this.exchange = 'BINANCE',
    this.interval = TvInterval.hour1,
    this.chartStyle = TvChartStyle.candles,
    this.showToolbar = true,
    this.showVolume = true,
    this.showIndicators = true,
    this.height = 420,
    this.studies = const ['RSI@tv-basicstudies', 'MACD@tv-basicstudies'],
  });

  @override
  State<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<TradingViewChart> {
  late WebViewController _controller;
  bool _loaded = false;
  TvInterval _currentInterval = TvInterval.hour1;

  @override
  void initState() {
    super.initState();
    _currentInterval = widget.interval;
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF03060F))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loaded = true),
        onWebResourceError: (_) => setState(() => _loaded = true),
      ))
      ..loadHtmlString(_buildHtml());
  }

  String _buildHtml() {
    final sym = '${widget.exchange}:${widget.symbol}USDT';
    final studiesJson = widget.studies.map((s) => '"$s"').join(',');

    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { width: 100%; height: 100%; background: #03060F; overflow: hidden; }
  #tv_chart_container { width: 100%; height: 100%; }
</style>
</head>
<body>
<div id="tv_chart_container"></div>
<script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
<script type="text/javascript">
new TradingView.widget({
  "autosize": true,
  "symbol": "$sym",
  "interval": "${_currentInterval.value}",
  "timezone": "Etc/UTC",
  "theme": "dark",
  "style": "${widget.chartStyle.value}",
  "locale": "en",
  "toolbar_bg": "#0A0F1E",
  "enable_publishing": false,
  "hide_top_toolbar": ${!widget.showToolbar},
  "hide_side_toolbar": false,
  "allow_symbol_change": true,
  "container_id": "tv_chart_container",
  "withdateranges": true,
  "hide_volume": ${!widget.showVolume},
  "studies": [$studiesJson],
  "overrides": {
    "mainSeriesProperties.candleStyle.upColor": "#00F0C0",
    "mainSeriesProperties.candleStyle.downColor": "#FF4444",
    "mainSeriesProperties.candleStyle.borderUpColor": "#00F0C0",
    "mainSeriesProperties.candleStyle.borderDownColor": "#FF4444",
    "mainSeriesProperties.candleStyle.wickUpColor": "#00F0C0",
    "mainSeriesProperties.candleStyle.wickDownColor": "#FF4444",
    "paneProperties.background": "#03060F",
    "paneProperties.vertGridProperties.color": "#0A1628",
    "paneProperties.horzGridProperties.color": "#0A1628",
    "scalesProperties.textColor": "#8899AA"
  },
  "loading_screen": {
    "backgroundColor": "#03060F",
    "foregroundColor": "#00C8F5"
  }
});
</script>
</body>
</html>
''';
  }

  void changeSymbol(String symbol) {
    setState(() {
      _loaded = false;
    });
    _controller.loadHtmlString(_buildHtml());
  }

  void changeInterval(TvInterval interval) {
    setState(() {
      _currentInterval = interval;
      _loaded = false;
    });
    _controller.loadHtmlString(_buildHtml());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: WebViewWidget(controller: _controller),
          ),
          if (!_loaded)
            Container(
              decoration: BoxDecoration(
                color: p.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        color: p.primary,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Loading TradingView Chart...',
                      style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Full Chart Screen (used in Trading/Market screens) ────
class TradingViewChartScreen extends StatefulWidget {
  final String symbol;
  final String name;

  const TradingViewChartScreen({
    super.key,
    required this.symbol,
    this.name = '',
  });

  @override
  State<TradingViewChartScreen> createState() => _TradingViewChartScreenState();
}

class _TradingViewChartScreenState extends State<TradingViewChartScreen> {
  TvInterval _interval = TvInterval.hour1;
  TvChartStyle _style = TvChartStyle.candles;
  String _exchange = 'BINANCE';
  final List<String> _exchanges = ['BINANCE', 'COINBASE', 'KRAKEN', 'BYBIT', 'OKX'];

  final _chartKey = GlobalKey<_TradingViewChartState>();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(p),
            _buildIntervalBar(p),
            Expanded(
              child: TradingViewChart(
                key: _chartKey,
                symbol: widget.symbol,
                exchange: _exchange,
                interval: _interval,
                chartStyle: _style,
                showVolume: true,
                showIndicators: true,
                height: double.infinity,
              ),
            ),
            _buildBottomBar(p),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        border: Border(bottom: BorderSide(color: p.primary.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: p.primary, size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(widget.symbol, style: GoogleFonts.orbitron(
              color: p.primary, fontSize: 14, fontWeight: FontWeight.bold,
            )),
          ),
          const SizedBox(width: 8),
          if (widget.name.isNotEmpty)
            Text(widget.name, style: GoogleFonts.rajdhani(
              color: p.textSecondary, fontSize: 12,
            )),
          const Spacer(),
          // Exchange selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: p.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: p.primary.withValues(alpha: 0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _exchange,
                dropdownColor: p.surface,
                style: GoogleFonts.rajdhani(color: p.primary, fontSize: 11),
                icon: Icon(Icons.expand_more, color: p.primary, size: 14),
                items: _exchanges.map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                )).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _exchange = v);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.fullscreen, color: p.textSecondary, size: 20),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalBar(QuantumPalette p) {
    return Container(
      height: 36,
      color: p.surface.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: TvInterval.values.map((iv) {
                final sel = iv == _interval;
                return GestureDetector(
                  onTap: () => setState(() => _interval = iv),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: sel ? p.primary.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: sel ? p.primary : Colors.transparent),
                    ),
                    child: Center(child: Text(iv.label, style: GoogleFonts.orbitron(
                      color: sel ? p.primary : p.textSecondary,
                      fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    ))),
                  ),
                );
              }).toList(),
            ),
          ),
          // Chart style selector
          PopupMenuButton<TvChartStyle>(
            icon: Icon(Icons.bar_chart, color: p.textSecondary, size: 18),
            color: p.surface,
            itemBuilder: (_) => TvChartStyle.values.map((s) => PopupMenuItem(
              value: s,
              child: Text(s.label, style: GoogleFonts.rajdhani(
                color: s == _style ? p.primary : p.textPrimary, fontSize: 12,
              )),
            )).toList(),
            onSelected: (s) => setState(() => _style = s),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: p.surface.withValues(alpha: 0.4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAction(p, Icons.add_chart, 'Indicator', () {}),
          _buildAction(p, Icons.draw, 'Draw', () {}),
          _buildAction(p, Icons.compare_arrows, 'Compare', () {}),
          _buildAction(p, Icons.screenshot, 'Snapshot', () {}),
          _buildAction(p, Icons.settings_outlined, 'Settings', () {}),
        ],
      ),
    );
  }

  Widget _buildAction(QuantumPalette p, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Icon(icon, color: p.textSecondary, size: 20),
        Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
      ]),
    );
  }
}

// ── Mini Sparkline Widget (no WebView needed) ─────────────
class SparklineWidget extends StatelessWidget {
  final List<double> data;
  final Color? color;
  final double width;
  final double height;

  const SparklineWidget({
    super.key,
    required this.data,
    this.color,
    this.width = 80,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    if (data.length < 2) {
      return SizedBox(width: width, height: height);
    }
    final isPositive = data.last >= data.first;
    final lineColor = color ?? (isPositive ? p.positive : p.negative);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(data: data, color: lineColor),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  const _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    if (range == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - (data[i] - min) / range * size.height;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    // Area fill
    final fillPath = Path()..addPath(path, Offset.zero);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.data != data;
}
