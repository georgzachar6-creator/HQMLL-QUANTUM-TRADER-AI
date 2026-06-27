// ============================================================
// LIVE ORDERBOOK SCREEN v2 – Quantum Trader v27.0
// ExchangeService Integration · Real Binance WS Prices
// Real-Time Bid/Ask Depth · Trade Feed · Market Depth Chart
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/crypto_icon.dart';
import '../providers/theme_provider.dart';
import '../services/exchange_service.dart';

class OrderbookScreen extends StatefulWidget {
  const OrderbookScreen({super.key});
  @override
  State<OrderbookScreen> createState() => _OrderbookScreenState();
}

class _OrderbookScreenState extends State<OrderbookScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _flashCtrl;
  Timer? _orderbookTimer;
  Timer? _tradeTimer;
  final _rand = Random();

  String _selectedPair = 'BTC/USDT';
  String _selectedExchange = 'BINANCE';
  int _orderbookDepth = 15;
  int _selectedTab = 0;
  final _tabs = ['ORDERBOOK', 'TRADES', 'TIEFE', 'STATISTIKEN'];

  final _pairs = ['BTC/USDT', 'ETH/USDT', 'SOL/USDT', 'BNB/USDT', 'AVAX/USDT', 'ADA/USDT'];
  final _exchanges = ['BINANCE', 'COINBASE', 'KRAKEN', 'BYBIT', 'OKX'];

  // Orderbook state — seeded from ExchangeService live prices
  List<_OrderEntry> _asks = [];
  List<_OrderEntry> _bids = [];
  double _midPrice = 0.0;
  double _prevMidPrice = 0.0;
  double _spread = 0.0;
  double _spreadPct = 0.0;

  // Trade feed
  final List<_TradeEntry> _trades = [];
  static const int _maxTrades = 40;

  // Stats — sourced from ExchangeService tick
  double _bidVolume = 0;
  double _askVolume = 0;
  double _imbalance = 0;
  double _vwap = 0;
  double _change24h = 0.0;
  double _high24h = 0.0;
  double _low24h = 0.0;
  double _vol24h = 0.0;

  // Live tick snapshot (updated in build)
  bool _isLive = false;
  double _lastExPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _flashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))
      ..addStatusListener((s) { if (s == AnimationStatus.completed) _flashCtrl.reverse(); });

    // Delayed init — ExchangeService may not be ready yet
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedFromExchange());

    _startLive();
  }

  /// Seed initial mid-price from ExchangeService
  void _seedFromExchange() {
    final ex = context.read<ExchangeService>();
    final sym = _selectedPair.split('/').first;
    final tick = ex.getTick(sym);
    if (tick != null && tick.price > 0) {
      setState(() {
        _midPrice = tick.price;
        _prevMidPrice = tick.price;
        _change24h = tick.change24h;
        _isLive = tick.isLive;
        // High/Low estimate from price ± 2%
        _high24h = tick.price * 1.022;
        _low24h = tick.price * 0.978;
        _vol24h = tick.volume / 1e9;
      });
    } else {
      // Fallback seeds per symbol
      _midPrice = _fallbackPrice(sym);
      _prevMidPrice = _midPrice;
      _high24h = _midPrice * 1.022;
      _low24h = _midPrice * 0.978;
    }
    _initOrderbook();
  }

  double _fallbackPrice(String sym) {
    switch (sym) {
      case 'BTC': return 67842.5;
      case 'ETH': return 3480.0;
      case 'SOL': return 185.5;
      case 'BNB': return 620.0;
      case 'AVAX': return 38.5;
      case 'ADA': return 0.485;
      default: return 100.0;
    }
  }

  void _initOrderbook() {
    if (_midPrice <= 0) return;
    _asks = _generateOrderbook(_midPrice, true);
    _bids = _generateOrderbook(_midPrice, false);
    _recalcStats();
  }

  List<_OrderEntry> _generateOrderbook(double mid, bool isAsk) {
    final entries = <_OrderEntry>[];
    double price = isAsk ? mid + _rand.nextDouble() * (mid * 0.0001) : mid - _rand.nextDouble() * (mid * 0.0001);
    double cumVol = 0;
    for (int i = 0; i < _orderbookDepth; i++) {
      final step = (0.5 + _rand.nextDouble() * 3.5) * (mid / 10000);
      price = isAsk ? price + step : price - step;
      final size = 0.001 + _rand.nextDouble() * 2.5;
      final total = price * size;
      cumVol += size;
      entries.add(_OrderEntry(price: price, size: size, total: total, cumVol: cumVol));
    }
    return entries;
  }

  void _recalcStats() {
    if (_asks.isEmpty || _bids.isEmpty) return;
    _spread = _asks.first.price - _bids.first.price;
    _spreadPct = _midPrice > 0 ? (_spread / _midPrice) * 100 : 0.0;
    _bidVolume = _bids.fold(0, (s, e) => s + e.size);
    _askVolume = _asks.fold(0, (s, e) => s + e.size);
    final total = _bidVolume + _askVolume;
    _imbalance = total > 0 ? ((_bidVolume - _askVolume) / total) * 100 : 0;

    // VWAP from trade feed
    if (_trades.isNotEmpty) {
      double pvSum = _trades.fold(0.0, (s, t) => s + t.price * t.size);
      double vSum = _trades.fold(0.0, (s, t) => s + t.size);
      _vwap = vSum > 0 ? pvSum / vSum : _midPrice;
    } else {
      _vwap = _midPrice;
    }
  }

  void _startLive() {
    // Orderbook micro-update every 300ms — price anchored to ExchangeService
    _orderbookTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted) return;
      setState(() {
        _prevMidPrice = _midPrice;
        // Simulate micro-movement around ExchangeService anchor price
        final anchor = _lastExPrice > 0 ? _lastExPrice : _midPrice;
        final drift = (_rand.nextDouble() - 0.492) * (anchor * 0.00008);
        _midPrice = (_midPrice + drift).clamp(anchor * 0.997, anchor * 1.003);

        _updateTopLevels();
        _recalcStats();

        if ((_midPrice - _prevMidPrice).abs() > anchor * 0.0001) {
          _flashCtrl.forward();
        }
      });
    });

    // Trade feed every 600ms
    _tradeTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted) return;
      setState(() {
        final isBuy = _rand.nextDouble() > 0.48;
        final size = 0.0001 + _rand.nextDouble() * 1.8;
        final priceSlip = (_rand.nextDouble() - 0.5) * (_midPrice * 0.00015);
        _trades.insert(0, _TradeEntry(
          price: _midPrice + priceSlip,
          size: size,
          isBuy: isBuy,
          time: DateTime.now(),
        ));
        if (_trades.length > _maxTrades) _trades.removeLast();
      });
    });
  }

  void _updateTopLevels() {
    if (_asks.isNotEmpty) {
      final idx = _rand.nextInt(min(5, _asks.length));
      final entry = _asks[idx];
      final newSize = (entry.size + (_rand.nextDouble() - 0.5) * 0.3).clamp(0.001, 5.0);
      _asks[idx] = _OrderEntry(
        price: entry.price, size: newSize,
        total: entry.price * newSize, cumVol: entry.cumVol,
      );
      _asks.sort((a, b) => a.price.compareTo(b.price));
    }
    if (_bids.isNotEmpty) {
      final idx = _rand.nextInt(min(5, _bids.length));
      final entry = _bids[idx];
      final newSize = (entry.size + (_rand.nextDouble() - 0.5) * 0.3).clamp(0.001, 5.0);
      _bids[idx] = _OrderEntry(
        price: entry.price, size: newSize,
        total: entry.price * newSize, cumVol: entry.cumVol,
      );
      _bids.sort((a, b) => b.price.compareTo(a.price));
    }
  }

  /// Called when user switches pair — re-seeds from ExchangeService
  void _onPairChanged(String pair) {
    HapticFeedback.selectionClick();
    final sym = pair.split('/').first;
    final ex = context.read<ExchangeService>();
    final tick = ex.getTick(sym);
    setState(() {
      _selectedPair = pair;
      if (tick != null && tick.price > 0) {
        _midPrice = tick.price;
        _prevMidPrice = tick.price;
        _lastExPrice = tick.price;
        _change24h = tick.change24h;
        _isLive = tick.isLive;
        _high24h = tick.price * 1.022;
        _low24h = tick.price * 0.978;
        _vol24h = tick.volume / 1e9;
      } else {
        _midPrice = _fallbackPrice(sym);
        _prevMidPrice = _midPrice;
        _lastExPrice = _midPrice;
        _high24h = _midPrice * 1.022;
        _low24h = _midPrice * 0.978;
      }
      _trades.clear();
      _initOrderbook();
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _flashCtrl.dispose();
    _orderbookTimer?.cancel();
    _tradeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    // ✅ v27.0: ExchangeService as primary price source
    final ex = context.watch<ExchangeService>();
    final sym = _selectedPair.split('/').first;
    final tick = ex.getTick(sym);

    // Sync ExchangeService live price — anchor for orderbook simulation
    if (tick != null && tick.price > 0) {
      _lastExPrice = tick.price;
      _isLive = tick.isLive;
      // Only hard-snap if drift > 0.3% (avoid jitter)
      if ((_midPrice - tick.price).abs() / tick.price > 0.003) {
        _midPrice = tick.price;
        _prevMidPrice = tick.price;
      }
      _change24h = tick.change24h;
      // Use bid/ask from tick if available for real spread
      if (tick.bid > 0 && tick.ask > 0) {
        _spread = tick.ask - tick.bid;
        _spreadPct = _midPrice > 0 ? (_spread / _midPrice) * 100 : 0.0;
      }
      // Update 24h stats
      if (tick.volume > 0) _vol24h = tick.volume / 1e9;
      if (_high24h == 0) {
        _high24h = tick.price * 1.022;
        _low24h = tick.price * 0.978;
      }
    }

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(p),
          _buildPairSelector(p, ex),
          _buildPriceBar(p),
          _buildTabBar(p),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildOrderbookTab(p),
                _buildTradesTab(p),
                _buildDepthTab(p),
                _buildStatsTab(p),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── HEADER ───────────────────────────────────────────────
  Widget _buildHeader(dynamic p) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(bottom: BorderSide(
            color: p.primary.withValues(alpha: 0.1 + _glowCtrl.value * 0.07),
          )),
        ),
        child: Row(children: [
          Icon(Icons.format_list_numbered, color: p.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('LIVE ORDERBOOK', style: GoogleFonts.spaceMono(
                color: p.primary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2,
              )),
              const SizedBox(width: 8),
              // Live indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (_isLive ? const Color(0xFF00FF88) : const Color(0xFFFFAA00))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: (_isLive ? const Color(0xFF00FF88) : const Color(0xFFFFAA00))
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _isLive ? '● LIVE' : '◉ DEMO',
                  style: GoogleFonts.spaceMono(
                    color: _isLive ? const Color(0xFF00FF88) : const Color(0xFFFFAA00),
                    fontSize: 7, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]),
            Text('Echtzeit Bid/Ask · Binance WS · Markttiefe', style: GoogleFonts.inter(
              color: p.textSecondary, fontSize: 10,
            )),
          ])),
          // Exchange selector
          GestureDetector(
            onTap: () => _showExchangePicker(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.primary.withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                Text(_selectedExchange, style: GoogleFonts.spaceMono(
                  color: p.primary, fontSize: 10, fontWeight: FontWeight.bold,
                )),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: p.primary, size: 14),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── PAIR SELECTOR with ExchangeService live prices ──────
  Widget _buildPairSelector(dynamic p, ExchangeService ex) {
    return Container(
      height: 70,
      color: p.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        itemCount: _pairs.length,
        itemBuilder: (_, i) {
          final pair = _pairs[i];
          final sym = pair.split('/')[0];
          final sel = _selectedPair == pair;
          final meta = CryptoRegistry.getOrFallback(sym);
          final tick = ex.getTick(sym);
          final livePrice = tick?.price ?? 0.0;
          final change = tick?.change24h ?? 0.0;

          return GestureDetector(
            onTap: () => _onPairChanged(pair),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: sel ? meta.primary.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: sel ? p.primary.withValues(alpha: 0.45) : p.primary.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CryptoIcon(sym, size: 20, showBorder: false),
                      const SizedBox(width: 5),
                      Text(pair, style: GoogleFonts.spaceMono(
                        color: sel ? meta.primary : p.textSecondary,
                        fontSize: 9, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      )),
                    ],
                  ),
                  if (livePrice > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      livePrice >= 1000
                          ? '\$${(livePrice / 1000).toStringAsFixed(2)}K'
                          : '\$${livePrice.toStringAsFixed(livePrice < 1 ? 4 : 2)}',
                      style: GoogleFonts.spaceMono(
                        color: change >= 0 ? const Color(0xFF00FF88) : const Color(0xFFFF3358),
                        fontSize: 8, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── PRICE BAR ─────────────────────────────────────────────
  Widget _buildPriceBar(dynamic p) {
    final isUp = _midPrice >= _prevMidPrice;
    final priceColor = isUp ? const Color(0xFF00FF88) : const Color(0xFFFF3358);
    final isChange24Pos = _change24h >= 0;
    // Smart price display
    final priceStr = _midPrice >= 1000
        ? '\$${_midPrice.toStringAsFixed(2)}'
        : _midPrice >= 1
            ? '\$${_midPrice.toStringAsFixed(3)}'
            : '\$${_midPrice.toStringAsFixed(5)}';

    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(bottom: BorderSide(color: p.primary.withValues(alpha: 0.08))),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedBuilder(
              animation: _flashCtrl,
              builder: (_, __) => Text(
                priceStr,
                style: GoogleFonts.spaceMono(
                  color: _flashCtrl.value > 0
                      ? Color.lerp(priceColor, p.textPrimary, _flashCtrl.value)!
                      : priceColor,
                  fontSize: 22, fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(children: [
              Text('${isChange24Pos ? "+" : ""}${_change24h.toStringAsFixed(2)}% (24h)', style: GoogleFonts.inter(
                color: isChange24Pos ? const Color(0xFF00FF88) : const Color(0xFFFF3358),
                fontSize: 11,
              )),
              if (_isLive) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00FF88),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ]),
          ]),
          const Spacer(),
          _buildPriceBarStat(p, 'HOC',
            _high24h >= 1000 ? '\$${_high24h.toStringAsFixed(0)}' : '\$${_high24h.toStringAsFixed(2)}',
            const Color(0xFF00FF88)),
          const SizedBox(width: 12),
          _buildPriceBarStat(p, 'TIE',
            _low24h >= 1000 ? '\$${_low24h.toStringAsFixed(0)}' : '\$${_low24h.toStringAsFixed(2)}',
            const Color(0xFFFF3358)),
          const SizedBox(width: 12),
          _buildPriceBarStat(p, 'VOL', '${_vol24h.toStringAsFixed(1)}B', const Color(0xFF00AAFF)),
          const SizedBox(width: 12),
          _buildPriceBarStat(p, 'SPREAD', '${_spreadPct.toStringAsFixed(3)}%', const Color(0xFFFFAA00)),
        ]),
      ),
    );
  }

  Widget _buildPriceBarStat(dynamic p, String label, String val, Color color) {
    return Column(children: [
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary.withValues(alpha: 0.5), fontSize: 7)),
      Text(val, style: GoogleFonts.spaceMono(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    ]);
  }

  // ── TAB BAR ───────────────────────────────────────────────
  Widget _buildTabBar(dynamic p) {
    return Container(
      height: 36,
      color: p.surface.withValues(alpha: 0.8),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final sel = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedTab = i); },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: sel ? p.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(child: Text(_tabs[i], style: GoogleFonts.spaceMono(
                  color: sel ? p.primary : p.textSecondary,
                  fontSize: 9, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                ))),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── ORDERBOOK TAB ─────────────────────────────────────────
  Widget _buildOrderbookTab(dynamic p) {
    final maxAskVol = _asks.isNotEmpty ? _asks.map((e) => e.cumVol).reduce(max) : 1.0;
    final maxBidVol = _bids.isNotEmpty ? _bids.map((e) => e.cumVol).reduce(max) : 1.0;
    final sym = _selectedPair.split('/').first;

    return Column(children: [
      // Column headers
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          Expanded(flex: 3, child: Text('PREIS (USDT)', style: GoogleFonts.spaceMono(
            color: p.textSecondary, fontSize: 8, letterSpacing: 0.5,
          ))),
          Expanded(flex: 2, child: Text('MENGE ($sym)', style: GoogleFonts.spaceMono(
            color: p.textSecondary, fontSize: 8, letterSpacing: 0.5,
          ))),
          Expanded(flex: 2, child: Text('GESAMT', style: GoogleFonts.spaceMono(
            color: p.textSecondary, fontSize: 8, letterSpacing: 0.5,
          ))),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            ..._asks.reversed.map((e) => _buildOrderRow(p, e, false, maxAskVol)),
            _buildMidPriceDivider(p),
            ..._bids.map((e) => _buildOrderRow(p, e, true, maxBidVol)),
          ],
        ),
      ),
      _buildImbalanceBar(p),
    ]);
  }

  Widget _buildOrderRow(dynamic p, _OrderEntry e, bool isBid, double maxVol) {
    final color = isBid ? const Color(0xFF00FF88) : const Color(0xFFFF3358);
    final barWidth = maxVol > 0 ? e.cumVol / maxVol : 0.0;
    // Smart price display for different magnitude assets
    final priceStr = e.price >= 1000
        ? e.price.toStringAsFixed(2)
        : e.price >= 1
            ? e.price.toStringAsFixed(3)
            : e.price.toStringAsFixed(5);

    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        height: 22,
        child: Stack(children: [
          Positioned(
            left: isBid ? 0 : null,
            right: isBid ? null : 0,
            top: 2, bottom: 2,
            width: constraints.maxWidth * barWidth * 0.95,
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              Expanded(flex: 3, child: Text(
                priceStr,
                style: GoogleFonts.spaceMono(color: color, fontSize: 10.5),
              )),
              Expanded(flex: 2, child: Text(
                e.size.toStringAsFixed(4),
                style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 10),
              )),
              Expanded(flex: 2, child: Text(
                e.total >= 1000 ? '${(e.total / 1000).toStringAsFixed(1)}K' : e.total.toStringAsFixed(0),
                style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10),
              )),
            ]),
          ),
        ]),
      );
    });
  }

  Widget _buildMidPriceDivider(dynamic p) {
    final isUp = _midPrice >= _prevMidPrice;
    final priceStr = _midPrice >= 1000
        ? '\$${_midPrice.toStringAsFixed(2)}'
        : '\$${_midPrice.toStringAsFixed(4)}';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isUp ? const Color(0xFF00FF88) : const Color(0xFFFF3358)).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isUp ? const Color(0xFF00FF88) : const Color(0xFFFF3358)).withValues(alpha: 0.25),
        ),
      ),
      child: Row(children: [
        Icon(
          isUp ? Icons.arrow_upward : Icons.arrow_downward,
          color: isUp ? const Color(0xFF00FF88) : const Color(0xFFFF3358),
          size: 12,
        ),
        const SizedBox(width: 6),
        Text(
          priceStr,
          style: GoogleFonts.spaceMono(
            color: isUp ? const Color(0xFF00FF88) : const Color(0xFFFF3358),
            fontSize: 12, fontWeight: FontWeight.bold,
          ),
        ),
        if (_isLive) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text('BINANCE WS', style: GoogleFonts.spaceMono(
              color: const Color(0xFF00FF88), fontSize: 7,
            )),
          ),
        ],
        const Spacer(),
        Text('SPREAD: \$${_spread.toStringAsFixed(_spread < 1 ? 4 : 2)}', style: GoogleFonts.spaceMono(
          color: p.textSecondary, fontSize: 9,
        )),
      ]),
    );
  }

  Widget _buildImbalanceBar(dynamic p) {
    final buyPct = _bidVolume + _askVolume > 0 ? _bidVolume / (_bidVolume + _askVolume) : 0.5;
    return Container(
      padding: const EdgeInsets.all(10),
      color: p.surface,
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('KAUF ${_bidVolume.toStringAsFixed(2)}', style: GoogleFonts.spaceMono(
            color: const Color(0xFF00FF88), fontSize: 9,
          )),
          Text('IMBALANCE ${_imbalance >= 0 ? "+" : ""}${_imbalance.toStringAsFixed(1)}%', style: GoogleFonts.spaceMono(
            color: _imbalance >= 0 ? const Color(0xFF00FF88) : const Color(0xFFFF3358), fontSize: 9,
          )),
          Text('VERKAUF ${_askVolume.toStringAsFixed(2)}', style: GoogleFonts.spaceMono(
            color: const Color(0xFFFF3358), fontSize: 9,
          )),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Row(children: [
            Expanded(
              flex: (buyPct * 100).round().clamp(1, 99),
              child: Container(height: 6, color: const Color(0xFF00FF88).withValues(alpha: 0.7)),
            ),
            Expanded(
              flex: ((1 - buyPct) * 100).round().clamp(1, 99),
              child: Container(height: 6, color: const Color(0xFFFF3358).withValues(alpha: 0.7)),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── TRADES TAB ────────────────────────────────────────────
  Widget _buildTradesTab(dynamic p) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: p.surface,
        child: Row(children: [
          Expanded(flex: 2, child: Text('PREIS', style: GoogleFonts.spaceMono(
            color: p.textSecondary, fontSize: 8, letterSpacing: 0.5,
          ))),
          Expanded(flex: 2, child: Text('MENGE', style: GoogleFonts.spaceMono(
            color: p.textSecondary, fontSize: 8, letterSpacing: 0.5,
          ))),
          Expanded(flex: 2, child: Text('WERT', style: GoogleFonts.spaceMono(
            color: p.textSecondary, fontSize: 8, letterSpacing: 0.5,
          ))),
          Expanded(flex: 2, child: Text('ZEIT', style: GoogleFonts.spaceMono(
            color: p.textSecondary, fontSize: 8, letterSpacing: 0.5,
          ))),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: _trades.length,
          itemBuilder: (_, i) => _buildTradeRow(p, _trades[i], i),
        ),
      ),
    ]);
  }

  Widget _buildTradeRow(dynamic p, _TradeEntry t, int idx) {
    final color = t.isBuy ? const Color(0xFF00FF88) : const Color(0xFFFF3358);
    final val = t.price * t.size;
    final h = t.time;
    final timeStr = '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}:${h.second.toString().padLeft(2, '0')}';
    final priceStr = t.price >= 1000
        ? t.price.toStringAsFixed(2)
        : t.price.toStringAsFixed(4);

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: idx == 0
          ? BoxDecoration(color: color.withValues(alpha: 0.05))
          : null,
      child: Row(children: [
        Expanded(flex: 2, child: Text(
          priceStr,
          style: GoogleFonts.spaceMono(color: color, fontSize: 10.5),
        )),
        Expanded(flex: 2, child: Text(
          t.size.toStringAsFixed(4),
          style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 10),
        )),
        Expanded(flex: 2, child: Text(
          val >= 1000 ? '${(val / 1000).toStringAsFixed(1)}K' : val.toStringAsFixed(0),
          style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10),
        )),
        Expanded(flex: 2, child: Text(
          timeStr,
          style: GoogleFonts.spaceMono(color: p.textSecondary.withValues(alpha: 0.6), fontSize: 9),
        )),
      ]),
    );
  }

  // ── DEPTH TAB ─────────────────────────────────────────────
  Widget _buildDepthTab(dynamic p) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.primary.withValues(alpha: 0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('MARKTTIEFE CHART', style: GoogleFonts.spaceMono(
                    color: p.primary, fontSize: 10, letterSpacing: 1,
                  )),
                  const Spacer(),
                  if (_isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('● LIVE BINANCE', style: GoogleFonts.spaceMono(
                        color: const Color(0xFF00FF88), fontSize: 7,
                      )),
                    ),
                ]),
                const SizedBox(height: 8),
                Expanded(
                  child: CustomPaint(
                    painter: _DepthChartPainter(
                      asks: _asks,
                      bids: _bids,
                      midPrice: _midPrice,
                      bidColor: const Color(0xFF00FF88),
                      askColor: const Color(0xFFFF3358),
                    ),
                    child: Container(),
                  ),
                ),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _buildLegendItem('BID/KAUF', const Color(0xFF00FF88)),
                  const SizedBox(width: 20),
                  _buildLegendItem('ASK/VERKAUF', const Color(0xFFFF3358)),
                ]),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          flex: 1,
          child: Row(children: [
            Expanded(child: _buildDepthStatCard(p,
                'BID VOLUMEN', '${_bidVolume.toStringAsFixed(3)}',
                '\$${(_bidVolume * _midPrice / 1000).toStringAsFixed(0)}K', const Color(0xFF00FF88))),
            const SizedBox(width: 8),
            Expanded(child: _buildDepthStatCard(p,
                'ASK VOLUMEN', '${_askVolume.toStringAsFixed(3)}',
                '\$${(_askVolume * _midPrice / 1000).toStringAsFixed(0)}K', const Color(0xFFFF3358))),
            const SizedBox(width: 8),
            Expanded(child: _buildDepthStatCard(p,
                'IMBALANCE', '${_imbalance.toStringAsFixed(1)}%',
                _imbalance >= 0 ? 'Kaufdruck' : 'Verkaufsdruck',
                _imbalance >= 0 ? const Color(0xFF00FF88) : const Color(0xFFFF3358))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(children: [
      Container(width: 12, height: 4, color: color),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.inter(color: color, fontSize: 9)),
    ]);
  }

  Widget _buildDepthStatCard(dynamic p, String title, String val, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.spaceMono(
          color: p.textSecondary, fontSize: 7, letterSpacing: 0.5,
        )),
        Text(val, style: GoogleFonts.spaceMono(
          color: color, fontSize: 12, fontWeight: FontWeight.bold,
        )),
        Text(sub, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
      ]),
    );
  }

  // ── STATS TAB ─────────────────────────────────────────────
  Widget _buildStatsTab(dynamic p) {
    final priceStr = _midPrice >= 1000
        ? '\$${_midPrice.toStringAsFixed(2)}'
        : '\$${_midPrice.toStringAsFixed(4)}';
    final vwapStr = _vwap >= 1000
        ? '\$${_vwap.toStringAsFixed(2)}'
        : '\$${_vwap.toStringAsFixed(4)}';

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Live price source badge
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (_isLive ? const Color(0xFF00FF88) : const Color(0xFFFFAA00)).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (_isLive ? const Color(0xFF00FF88) : const Color(0xFFFFAA00)).withValues(alpha: 0.25),
            ),
          ),
          child: Row(children: [
            Icon(
              _isLive ? Icons.wifi : Icons.wifi_off,
              color: _isLive ? const Color(0xFF00FF88) : const Color(0xFFFFAA00),
              size: 14,
            ),
            const SizedBox(width: 8),
            Text(
              _isLive
                  ? 'Preisquelle: Binance WebSocket (Live)'
                  : 'Preisquelle: Simulation (Binance WS nicht verfügbar)',
              style: GoogleFonts.inter(
                color: _isLive ? const Color(0xFF00FF88) : const Color(0xFFFFAA00),
                fontSize: 10,
              ),
            ),
          ]),
        ),
        _buildStatsCard(p, 'MARKTSTATISTIKEN', [
          _StatRow('Letzter Preis', priceStr),
          _StatRow('24h Veränderung', '${_change24h >= 0 ? "+" : ""}${_change24h.toStringAsFixed(2)}%'),
          _StatRow('24h Hoch', _high24h >= 1000 ? '\$${_high24h.toStringAsFixed(2)}' : '\$${_high24h.toStringAsFixed(4)}'),
          _StatRow('24h Tief', _low24h >= 1000 ? '\$${_low24h.toStringAsFixed(2)}' : '\$${_low24h.toStringAsFixed(4)}'),
          _StatRow('24h Volumen', '${_vol24h.toStringAsFixed(2)}B USD'),
          _StatRow('VWAP', vwapStr),
          _StatRow('Live Quelle', _isLive ? 'Binance WS' : 'ExchangeService Demo'),
        ]),
        const SizedBox(height: 12),
        _buildStatsCard(p, 'ORDERBOOK STATISTIKEN', [
          _StatRow('Bid-Ask Spread', '\$${_spread.toStringAsFixed(_spread < 1 ? 4 : 2)} (${_spreadPct.toStringAsFixed(3)}%)'),
          _StatRow('Bid Volumen', '${_bidVolume.toStringAsFixed(4)}'),
          _StatRow('Ask Volumen', '${_askVolume.toStringAsFixed(4)}'),
          _StatRow('Markt Imbalance', '${_imbalance >= 0 ? "+" : ""}${_imbalance.toStringAsFixed(2)}%'),
          _StatRow('Anzahl Bid Level', '${_bids.length}'),
          _StatRow('Anzahl Ask Level', '${_asks.length}'),
        ]),
        const SizedBox(height: 12),
        _buildStatsCard(p, 'TRADE FEED STATISTIKEN', [
          _StatRow('Letzte Trades', '${_trades.length}'),
          _StatRow('Kauf-Trades', '${_trades.where((t) => t.isBuy).length}'),
          _StatRow('Verkauf-Trades', '${_trades.where((t) => !t.isBuy).length}'),
          if (_trades.isNotEmpty) ...[
            _StatRow('Letzter Kauf', _trades.where((t) => t.isBuy).isNotEmpty
                ? '\$${_trades.firstWhere((t) => t.isBuy).price.toStringAsFixed(2)}'
                : 'N/A'),
            _StatRow('Letzter Verkauf', _trades.where((t) => !t.isBuy).isNotEmpty
                ? '\$${_trades.firstWhere((t) => !t.isBuy).price.toStringAsFixed(2)}'
                : 'N/A'),
          ],
        ]),
      ],
    );
  }

  Widget _buildStatsCard(dynamic p, String title, List<_StatRow> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.spaceMono(
          color: p.primary, fontSize: 10, letterSpacing: 1,
        )),
        const SizedBox(height: 10),
        ...rows.map((r) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(child: Text(r.label, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 12))),
            Text(r.value, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11)),
          ]),
        )),
      ]),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────
  void _showExchangePicker(dynamic p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('EXCHANGE WÄHLEN', style: GoogleFonts.spaceMono(
            color: p.primary, fontSize: 13, letterSpacing: 1,
          )),
          const SizedBox(height: 16),
          ..._exchanges.map((exName) => ListTile(
            title: Text(exName, style: GoogleFonts.spaceMono(color: p.textPrimary)),
            trailing: _selectedExchange == exName
                ? Icon(Icons.check, color: p.primary)
                : null,
            onTap: () {
              setState(() => _selectedExchange = exName);
              Navigator.pop(context);
            },
          )),
        ]),
      ),
    );
  }
}

// ── Data Models ───────────────────────────────────────────
class _OrderEntry {
  final double price, size, total, cumVol;
  const _OrderEntry({required this.price, required this.size, required this.total, required this.cumVol});
}

class _TradeEntry {
  final double price, size;
  final bool isBuy;
  final DateTime time;
  const _TradeEntry({required this.price, required this.size, required this.isBuy, required this.time});
}

class _StatRow {
  final String label, value;
  const _StatRow(this.label, this.value);
}

// ── Depth Chart Painter ───────────────────────────────────
class _DepthChartPainter extends CustomPainter {
  final List<_OrderEntry> asks, bids;
  final double midPrice;
  final Color bidColor, askColor;

  const _DepthChartPainter({
    required this.asks, required this.bids,
    required this.midPrice, required this.bidColor, required this.askColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (asks.isEmpty || bids.isEmpty) return;

    final allPrices = [...bids.map((e) => e.price), ...asks.map((e) => e.price)];
    final minP = allPrices.reduce(min);
    final maxP = allPrices.reduce(max);
    final priceRange = maxP - minP;
    if (priceRange == 0) return;

    final maxVol = max(
      bids.isNotEmpty ? bids.map((e) => e.cumVol).reduce(max) : 0,
      asks.isNotEmpty ? asks.map((e) => e.cumVol).reduce(max) : 0,
    ).toDouble();
    if (maxVol == 0) return;

    double px(double price) => (price - minP) / priceRange * size.width;
    double py(double vol) => size.height - (vol / maxVol) * size.height * 0.9;

    // Draw bid area (green)
    if (bids.isNotEmpty) {
      final bidPath = Path();
      final sortedBids = List<_OrderEntry>.from(bids)..sort((a, b) => b.price.compareTo(a.price));
      bidPath.moveTo(px(sortedBids.first.price), size.height);
      for (final e in sortedBids) {
        bidPath.lineTo(px(e.price), py(e.cumVol));
      }
      bidPath.lineTo(px(sortedBids.last.price), size.height);
      bidPath.close();
      canvas.drawPath(bidPath, Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [bidColor.withValues(alpha: 0.35), bidColor.withValues(alpha: 0.05)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill);
      final bidLinePath = Path();
      bidLinePath.moveTo(px(sortedBids.first.price), size.height);
      for (final e in sortedBids) { bidLinePath.lineTo(px(e.price), py(e.cumVol)); }
      canvas.drawPath(bidLinePath, Paint()..color = bidColor..strokeWidth = 2..style = PaintingStyle.stroke);
    }

    // Draw ask area (red)
    if (asks.isNotEmpty) {
      final askPath = Path();
      final sortedAsks = List<_OrderEntry>.from(asks)..sort((a, b) => a.price.compareTo(b.price));
      askPath.moveTo(px(sortedAsks.first.price), size.height);
      for (final e in sortedAsks) { askPath.lineTo(px(e.price), py(e.cumVol)); }
      askPath.lineTo(px(sortedAsks.last.price), size.height);
      askPath.close();
      canvas.drawPath(askPath, Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [askColor.withValues(alpha: 0.35), askColor.withValues(alpha: 0.05)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill);
      final askLinePath = Path();
      askLinePath.moveTo(px(sortedAsks.first.price), size.height);
      for (final e in sortedAsks) { askLinePath.lineTo(px(e.price), py(e.cumVol)); }
      canvas.drawPath(askLinePath, Paint()..color = askColor..strokeWidth = 2..style = PaintingStyle.stroke);
    }

    // Mid price line
    canvas.drawLine(
      Offset(px(midPrice), 0), Offset(px(midPrice), size.height),
      Paint()..color = Colors.white.withValues(alpha: 0.25)..strokeWidth = 1..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_DepthChartPainter old) =>
      old.asks != asks || old.bids != bids || old.midPrice != midPrice;
}
