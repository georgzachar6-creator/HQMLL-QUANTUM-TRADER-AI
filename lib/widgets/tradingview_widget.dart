/// HQMLL Quantum Trader – TradingView Chart Widget
/// Lightweight Charts via WebView
/// Grigori Saks · 2025
library;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_themes.dart';

// ════════════════════════════════════════════════════
// TRADINGVIEW WIDGET
// ════════════════════════════════════════════════════
class TradingViewWidget extends StatefulWidget {
  final String symbol;
  final String interval; // 1, 5, 15, 60, D, W
  final QuantumPalette palette;
  final double height;
  final bool showToolbar;

  const TradingViewWidget({
    super.key,
    required this.symbol,
    required this.palette,
    this.interval = '60',
    this.height = 320,
    this.showToolbar = true,
  });

  @override
  State<TradingViewWidget> createState() => _TradingViewWidgetState();
}

class _TradingViewWidgetState extends State<TradingViewWidget> {
  late WebViewController _controller;
  bool _isLoading = true;
  String _currentInterval = '60';
  String _currentSymbol = '';

  final List<_Interval> _intervals = const [
    _Interval('1m', '1'),
    _Interval('5m', '5'),
    _Interval('15m', '15'),
    _Interval('1h', '60'),
    _Interval('4h', '240'),
    _Interval('1T', 'D'),
    _Interval('1W', 'W'),
  ];

  @override
  void initState() {
    super.initState();
    _currentInterval = widget.interval;
    _currentSymbol = _normalizeSymbol(widget.symbol);
    _initController();
  }

  @override
  void didUpdateWidget(TradingViewWidget old) {
    super.didUpdateWidget(old);
    if (old.symbol != widget.symbol) {
      _currentSymbol = _normalizeSymbol(widget.symbol);
      _loadChart();
    }
  }

  String _normalizeSymbol(String sym) {
    // Map to TradingView symbols
    const tvMap = {
      'BTC':   'BINANCE:BTCUSDT',
      'ETH':   'BINANCE:ETHUSDT',
      'BNB':   'BINANCE:BNBUSDT',
      'SOL':   'BINANCE:SOLUSDT',
      'ADA':   'BINANCE:ADAUSDT',
      'DOGE':  'BINANCE:DOGEUSDT',
      'AVAX':  'BINANCE:AVAXUSDT',
      'MATIC': 'BINANCE:MATICUSDT',
      'LINK':  'BINANCE:LINKUSDT',
      'XRP':   'BINANCE:XRPUSDT',
      'LTC':   'BINANCE:LTCUSDT',
      'DOT':   'BINANCE:DOTUSDT',
      'QEMMA': 'BINANCE:SOLUSDT', // QEMMA uses SOL chart as reference
      // Stocks
      'AAPL':  'NASDAQ:AAPL',
      'TSLA':  'NASDAQ:TSLA',
      'GOOGL': 'NASDAQ:GOOGL',
      'AMZN':  'NASDAQ:AMZN',
      'MSFT':  'NASDAQ:MSFT',
      'NVDA':  'NASDAQ:NVDA',
      'META':  'NASDAQ:META',
      // Commodities
      'XAU':   'TVC:GOLD',
      'XAG':   'TVC:SILVER',
      'OIL':   'NYMEX:CL1!',
    };
    return tvMap[sym] ?? 'BINANCE:${sym}USDT';
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) => setState(() => _isLoading = false),
        onWebResourceError: (_) => setState(() => _isLoading = false),
      ))
      ..loadHtmlString(_buildHtml());
  }

  void _loadChart() {
    _controller.loadHtmlString(_buildHtml());
  }

  String _buildHtml() {
    final p = widget.palette;
    final bg = _colorToHex(p.background);
    final surface = _colorToHex(p.surface);
    final primaryColor = _colorToHex(p.primary);
    final textColor = _colorToHex(p.textPrimary);
    final textSecColor = _colorToHex(p.textSecondary);
    final positiveColor = _colorToHex(p.positive);
    final negativeColor = _colorToHex(p.negative);

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: $bg; overflow: hidden; }
  #tv_chart_container { width: 100%; height: 100vh; }
  .tradingview-widget-container { height: 100%; }
</style>
</head>
<body>
<div id="tv_chart_container"></div>
<script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
<script type="text/javascript">
try {
  new TradingView.widget({
    "autosize": true,
    "symbol": "$_currentSymbol",
    "interval": "$_currentInterval",
    "timezone": "Europe/Berlin",
    "theme": "dark",
    "style": "1",
    "locale": "de_DE",
    "toolbar_bg": "$surface",
    "enable_publishing": false,
    "withdateranges": false,
    "hide_side_toolbar": false,
    "allow_symbol_change": true,
    "save_image": false,
    "container_id": "tv_chart_container",
    "overrides": {
      "paneProperties.background": "$bg",
      "paneProperties.backgroundType": "solid",
      "paneProperties.vertGridProperties.color": "${surface}55",
      "paneProperties.horzGridProperties.color": "${surface}55",
      "scalesProperties.textColor": "$textSecColor",
      "mainSeriesProperties.candleStyle.upColor": "$positiveColor",
      "mainSeriesProperties.candleStyle.downColor": "$negativeColor",
      "mainSeriesProperties.candleStyle.wickUpColor": "$positiveColor",
      "mainSeriesProperties.candleStyle.wickDownColor": "$negativeColor",
      "mainSeriesProperties.candleStyle.borderUpColor": "$positiveColor",
      "mainSeriesProperties.candleStyle.borderDownColor": "$negativeColor"
    },
    "loading_screen": {
      "backgroundColor": "$bg",
      "foregroundColor": "$primaryColor"
    }
  });
} catch(e) {
  // Fallback: simple chart
  document.body.innerHTML = '<div style="display:flex;align-items:center;justify-content:center;height:100%;color:$textColor;font-family:monospace;font-size:14px;background:$bg;flex-direction:column;gap:8px;"><span style="color:$primaryColor;font-size:18px">📈</span><span>$_currentSymbol</span><span style="color:$textSecColor;font-size:11px">TradingView lädt...</span></div>';
}
</script>
</body>
</html>
''';
  }

  String _colorToHex(Color c) {
    return '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Interval Toolbar
        if (widget.showToolbar)
          Container(
            height: 36,
            color: widget.palette.surface,
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: _intervals.length,
                    itemBuilder: (_, i) {
                      final iv = _intervals[i];
                      final active = _currentInterval == iv.value;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _currentInterval = iv.value);
                          _loadChart();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: active ? widget.palette.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: active ? null : Border.all(color: widget.palette.primary.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            iv.label,
                            style: GoogleFonts.rajdhani(
                              color: active ? widget.palette.background : widget.palette.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Symbol info
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    widget.symbol,
                    style: GoogleFonts.rajdhani(color: widget.palette.primary, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        // WebView Chart
        SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                Container(
                  color: widget.palette.background,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: widget.palette.primary, strokeWidth: 2),
                        const SizedBox(height: 12),
                        Text(
                          'TradingView lädt ${widget.symbol}...',
                          style: GoogleFonts.rajdhani(color: widget.palette.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Interval Data ────────────────────────────────────
class _Interval {
  final String label, value;
  const _Interval(this.label, this.value);
}

// ════════════════════════════════════════════════════
// TRADINGVIEW MINI CHART (kompakt, kein Toolbar)
// ════════════════════════════════════════════════════
class TradingViewMiniChart extends StatefulWidget {
  final String symbol;
  final QuantumPalette palette;
  final double height;

  const TradingViewMiniChart({
    super.key,
    required this.symbol,
    required this.palette,
    this.height = 160,
  });

  @override
  State<TradingViewMiniChart> createState() => _TradingViewMiniChartState();
}

class _TradingViewMiniChartState extends State<TradingViewMiniChart> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_buildMiniHtml());
  }

  String _buildMiniHtml() {
    final bg = '#${widget.palette.background.toARGB32().toRadixString(16).substring(2)}';
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>*{margin:0;padding:0;}body{background:$bg;}</style>
</head>
<body>
<!-- TradingView Widget BEGIN -->
<div class="tradingview-widget-container">
  <div class="tradingview-widget-container__widget"></div>
  <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-mini-symbol-overview.js" async>
  {
    "symbol": "${_sym()}",
    "width": "100%",
    "height": "${widget.height}",
    "locale": "de_DE",
    "dateRange": "1D",
    "colorTheme": "dark",
    "trendLineColor": "rgba(0, 212, 255, 1)",
    "underLineColor": "rgba(0, 212, 255, 0.15)",
    "isTransparent": true,
    "autosize": true,
    "largeChartUrl": ""
  }
  </script>
</div>
</body>
</html>
''';
  }

  String _sym() {
    const map = {
      'BTC': 'BINANCE:BTCUSDT', 'ETH': 'BINANCE:ETHUSDT',
      'SOL': 'BINANCE:SOLUSDT', 'BNB': 'BINANCE:BNBUSDT',
      'XAU': 'TVC:GOLD', 'XAG': 'TVC:SILVER',
      'AAPL': 'NASDAQ:AAPL', 'TSLA': 'NASDAQ:TSLA',
      'GOOGL': 'NASDAQ:GOOGL',
    };
    return map[widget.symbol] ?? 'BINANCE:${widget.symbol}USDT';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: WebViewWidget(controller: _controller),
    );
  }
}
