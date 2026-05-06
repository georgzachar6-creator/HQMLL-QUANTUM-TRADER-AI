// ============================================================
// MARKET SCREEN v3 – Quantum Trader
// Live Prices · WebSocket · CMC · CoinGecko · TradingView
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/live_price_provider.dart';
import '../theme/app_themes.dart';
import '../widgets/tradingview_widget.dart';
import '../services/websocket_service.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _tickCtrl;
  Timer? _uiTimer;
  final _rand = Random();
  final _searchCtrl = TextEditingController();

  int _selectedTab = 0;
  final List<String> _tabs = ['ALL', 'GAINERS', 'LOSERS', 'VOLUME', 'WATCHLIST'];

  String _sortBy = 'rank';
  bool _sortAsc = true;
  String _searchQuery = '';
  bool _showSearch = false;

  // Watchlist
  final Set<String> _watchlist = {'BTC', 'ETH', 'SOL', 'AVAX', 'BNB'};

  // Flash animation for price changes
  final Map<String, Color> _flashColors = {};
  final Map<String, double> _prevPrices = {};
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _tickCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    // Init live price provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<LivePriceProvider>();
      await provider.initialize();
    });

    // UI refresh for flash effects
    _uiTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _clearOldFlashes();
    });
  }

  void _clearOldFlashes() {
    if (_flashColors.isEmpty) return;
    if (mounted) setState(() => _flashColors.clear());
  }

  void _onNewPrice(String symbol, double newPrice) {
    final prev = _prevPrices[symbol];
    if (prev != null && (newPrice - prev).abs() > prev * 0.0001) {
      _flashColors[symbol] = newPrice > prev
          ? const Color(0xFF00F0C0).withValues(alpha: 0.3)
          : const Color(0xFFFF4444).withValues(alpha: 0.3);
    }
    _prevPrices[symbol] = newPrice;
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _tickCtrl.dispose();
    _uiTimer?.cancel();
    _flashTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    final lp = context.watch<LivePriceProvider>();

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(p, lp),
            _buildConnectionBar(p, lp),
            _buildTabBar(p),
            if (_showSearch) _buildSearchBar(p),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildTabContent(p, lp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────
  Widget _buildHeader(QuantumPalette p, LivePriceProvider lp) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            p.background,
            p.primary.withValues(alpha: 0.04),
          ]),
          border: Border(bottom: BorderSide(
            color: p.primary.withValues(alpha: 0.2 + _glowCtrl.value * 0.15),
          )),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  p.primary.withValues(alpha: 0.35 + _glowCtrl.value * 0.2),
                  p.primary.withValues(alpha: 0.08),
                ]),
                boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.4), blurRadius: 12)],
              ),
              child: Icon(Icons.show_chart, color: p.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('LIVE MARKETS', style: GoogleFonts.orbitron(
                  color: p.primary, fontSize: 15, fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: p.primary.withValues(alpha: 0.5), blurRadius: 8)],
                )),
                Row(children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: lp.wsConnected ? p.positive : p.negative,
                      boxShadow: lp.wsConnected ? [BoxShadow(color: p.positive, blurRadius: 4)] : [],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    lp.wsConnected
                        ? '${lp.connectedExchanges} Exchange${lp.connectedExchanges != 1 ? "s" : ""} Live · ${lp.ticksPerSecond}/s'
                        : 'Connecting...',
                    style: GoogleFonts.rajdhani(
                      color: lp.wsConnected ? p.positive : p.accent,
                      fontSize: 10,
                    ),
                  ),
                ]),
              ]),
            ),
            // Stats
            _buildHeaderStat(p, 'TRACKED', '${lp.quotes.length}', p.primary),
            const SizedBox(width: 8),
            _buildHeaderStat(p, 'TICKS', '${lp.totalTicks}', p.accent),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(_showSearch ? Icons.search_off : Icons.search, color: p.primary, size: 20),
              onPressed: () => setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) _searchQuery = '';
              }),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.refresh, color: p.textSecondary, size: 20),
              onPressed: () => lp.refresh(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(QuantumPalette p, String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
    ]);
  }

  // ── Connection Bar ───────────────────────────────────────
  Widget _buildConnectionBar(QuantumPalette p, LivePriceProvider lp) {
    final exchanges = [
      ('Binance', lp.exchangeStatuses['Binance'], const Color(0xFFF3BA2F)),
      ('Coinbase', lp.exchangeStatuses['Coinbase'], const Color(0xFF0052FF)),
      ('Bybit', lp.exchangeStatuses['Bybit'], const Color(0xFFFF7028)),
      ('Kraken', lp.exchangeStatuses['Kraken'], const Color(0xFF5741D9)),
      ('OKX', lp.exchangeStatuses['OKX'], const Color(0xFF000000)),
    ];

    final dataSources = [
      ('CoinGecko', lp.geckoActive, const Color(0xFF8DC647)),
      ('CMC', lp.cmcActive, const Color(0xFF17C2A4)),
      ('TradingView', true, p.primary),
    ];

    return Container(
      height: 36,
      color: p.surface.withValues(alpha: 0.5),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        children: [
          ...exchanges.map((e) => _buildConnBadge(p, e.$1, e.$2, e.$3)),
          Container(width: 1, color: p.primary.withValues(alpha: 0.2), margin: const EdgeInsets.symmetric(horizontal: 6)),
          ...dataSources.map((d) => _buildDataBadge(p, d.$1, d.$2, d.$3)),
        ],
      ),
    );
  }

  Widget _buildConnBadge(QuantumPalette p, String name, ExchangeStatus? status, Color color) {
    final isConn = status == ExchangeStatus.connected;
    final isConn2 = status == ExchangeStatus.connecting;
    final badgeColor = isConn ? color : isConn2 ? p.accent : p.textSecondary.withValues(alpha: 0.4);
    return GestureDetector(
      onTap: () => lp_toggle(p, name),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isConn ? badgeColor.withValues(alpha: 0.12) : p.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
        ),
        child: Row(children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badgeColor,
              boxShadow: isConn ? [BoxShadow(color: badgeColor, blurRadius: 3)] : [],
            ),
          ),
          const SizedBox(width: 4),
          Text(name, style: GoogleFonts.orbitron(
            color: isConn ? badgeColor : p.textSecondary,
            fontSize: 8, fontWeight: FontWeight.bold,
          )),
        ]),
      ),
    );
  }

  void lp_toggle(QuantumPalette p, String name) {}

  Widget _buildDataBadge(QuantumPalette p, String name, bool active, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.12) : p.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: active ? color.withValues(alpha: 0.5) : p.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(Icons.cloud_done, color: active ? color : p.textSecondary, size: 9),
        const SizedBox(width: 3),
        Text(name, style: GoogleFonts.orbitron(
          color: active ? color : p.textSecondary,
          fontSize: 8, fontWeight: FontWeight.bold,
        )),
      ]),
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────
  Widget _buildTabBar(QuantumPalette p) {
    return Container(
      height: 38,
      color: p.surface.withValues(alpha: 0.3),
      child: Row(children: [
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: _tabs.length,
            itemBuilder: (_, i) {
              final sel = i == _selectedTab;
              return GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: sel ? p.primary.withValues(alpha: 0.18) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: sel ? p.primary : Colors.transparent),
                  ),
                  child: Center(child: Text(_tabs[i], style: GoogleFonts.orbitron(
                    color: sel ? p.primary : p.textSecondary,
                    fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  ))),
                ),
              );
            },
          ),
        ),
        // Sort options
        PopupMenuButton<String>(
          icon: Icon(Icons.sort, color: p.textSecondary, size: 18),
          color: p.surface,
          onSelected: (v) => setState(() {
            if (_sortBy == v) _sortAsc = !_sortAsc;
            else { _sortBy = v; _sortAsc = true; }
          }),
          itemBuilder: (_) => [
            _sortMenuItem(p, 'rank', 'Rank'),
            _sortMenuItem(p, 'price', 'Price'),
            _sortMenuItem(p, 'change24h', '24h Change'),
            _sortMenuItem(p, 'volume', 'Volume'),
            _sortMenuItem(p, 'mcap', 'Market Cap'),
          ],
        ),
      ]),
    );
  }

  PopupMenuItem<String> _sortMenuItem(QuantumPalette p, String val, String label) {
    return PopupMenuItem(
      value: val,
      child: Row(children: [
        if (_sortBy == val) Icon(
          _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
          color: p.primary, size: 14,
        ) else const SizedBox(width: 14),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildSearchBar(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: p.surface.withValues(alpha: 0.4),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search coins...',
          hintStyle: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: p.primary, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: p.textSecondary, size: 16),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: p.background.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: p.primary.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: p.primary.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: p.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          isDense: true,
        ),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      ),
    );
  }

  // ── Tab Content ──────────────────────────────────────────
  Widget _buildTabContent(QuantumPalette p, LivePriceProvider lp) {
    List<LiveQuote> coins;
    switch (_selectedTab) {
      case 1: coins = lp.topGainers; break;
      case 2: coins = lp.topLosers; break;
      case 3: coins = lp.topByVolume; break;
      case 4: coins = lp.sortedByRank.where((q) => _watchlist.contains(q.symbol)).toList(); break;
      default: coins = lp.sortedByRank; break;
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      coins = coins.where((q) =>
        q.symbol.toLowerCase().contains(_searchQuery) ||
        q.name.toLowerCase().contains(_searchQuery)
      ).toList();
    }

    // Apply sort
    coins = _sortCoins(coins);

    if (coins.isEmpty && lp.isInitialized && !lp.quotes.isEmpty) {
      return Center(child: Text('No results for "$_searchQuery"',
        style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 14)));
    }

    if (coins.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(color: p.primary, strokeWidth: 2),
        ),
        const SizedBox(height: 12),
        Text('Loading live market data...', style: GoogleFonts.rajdhani(
          color: p.textSecondary, fontSize: 13,
        )),
      ]));
    }

    return Column(
      key: ValueKey(_selectedTab),
      children: [
        _buildColumnHeaders(p),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: coins.length,
            itemBuilder: (_, i) => _buildCoinRow(p, lp, coins[i], i),
          ),
        ),
      ],
    );
  }

  List<LiveQuote> _sortCoins(List<LiveQuote> coins) {
    final sorted = [...coins];
    switch (_sortBy) {
      case 'price':
        sorted.sort((a, b) => _sortAsc
            ? a.price.compareTo(b.price)
            : b.price.compareTo(a.price));
        break;
      case 'change24h':
        sorted.sort((a, b) => _sortAsc
            ? a.change24h.compareTo(b.change24h)
            : b.change24h.compareTo(a.change24h));
        break;
      case 'volume':
        sorted.sort((a, b) => _sortAsc
            ? a.volume24h.compareTo(b.volume24h)
            : b.volume24h.compareTo(a.volume24h));
        break;
      case 'mcap':
        sorted.sort((a, b) => _sortAsc
            ? a.marketCap.compareTo(b.marketCap)
            : b.marketCap.compareTo(a.marketCap));
        break;
      default: // rank
        sorted.sort((a, b) {
          final ra = a.rank == 0 ? 999 : a.rank;
          final rb = b.rank == 0 ? 999 : b.rank;
          return _sortAsc ? ra.compareTo(rb) : rb.compareTo(ra);
        });
    }
    return sorted;
  }

  Widget _buildColumnHeaders(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: p.surface.withValues(alpha: 0.3),
      child: Row(children: [
        SizedBox(width: 28, child: Text('#', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10))),
        Expanded(child: Text('COIN', style: GoogleFonts.orbitron(color: p.textSecondary, fontSize: 9))),
        SizedBox(width: 80, child: Text('PRICE', textAlign: TextAlign.right, style: GoogleFonts.orbitron(color: p.textSecondary, fontSize: 9))),
        SizedBox(width: 64, child: Text('24H %', textAlign: TextAlign.right, style: GoogleFonts.orbitron(color: p.textSecondary, fontSize: 9))),
        SizedBox(width: 72, child: Text('CHART', textAlign: TextAlign.center, style: GoogleFonts.orbitron(color: p.textSecondary, fontSize: 9))),
        SizedBox(width: 24, child: Text('', textAlign: TextAlign.right)),
      ]),
    );
  }

  Widget _buildCoinRow(QuantumPalette p, LivePriceProvider lp, LiveQuote q, int idx) {
    _onNewPrice(q.symbol, q.price);
    final flash = _flashColors[q.symbol];
    final isWatched = _watchlist.contains(q.symbol);
    final pctColor = q.isPositive ? p.positive : p.negative;

    return GestureDetector(
      onTap: () => _openChart(context, q),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: flash ?? (idx.isEven ? p.surface.withValues(alpha: 0.15) : Colors.transparent),
          border: Border(bottom: BorderSide(
            color: p.surface.withValues(alpha: 0.3), width: 0.5,
          )),
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 28,
              child: Text(
                q.rank > 0 ? '${q.rank}' : '—',
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10),
              ),
            ),
            // Icon + Name
            Expanded(
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.primary.withValues(alpha: 0.1),
                  ),
                  child: q.iconUrl != null
                      ? ClipOval(child: Image.network(
                          q.iconUrl!,
                          width: 32, height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(q.symbol.length >= 2 ? q.symbol.substring(0, 2) : q.symbol,
                              style: GoogleFonts.orbitron(color: p.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ))
                      : Center(child: Text(
                          q.symbol.length >= 2 ? q.symbol.substring(0, 2) : q.symbol,
                          style: GoogleFonts.orbitron(color: p.primary, fontSize: 9, fontWeight: FontWeight.bold),
                        )),
                ),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.symbol, style: GoogleFonts.orbitron(
                      color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold,
                    )),
                    Text(q.name.length > 12 ? '${q.name.substring(0, 12)}...' : q.name,
                      style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
                  ],
                )),
              ]),
            ),
            // Price
            SizedBox(
              width: 80,
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(q.formattedPrice, style: GoogleFonts.orbitron(
                  color: q.isLive ? p.textPrimary : p.textSecondary,
                  fontSize: 12, fontWeight: FontWeight.bold,
                )),
                if (q.source == PriceSource.websocket)
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.positive,
                        boxShadow: [BoxShadow(color: p.positive, blurRadius: 2)],
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text('LIVE', style: GoogleFonts.rajdhani(
                      color: p.positive, fontSize: 7, fontWeight: FontWeight.bold,
                    )),
                  ]),
              ]),
            ),
            // Change
            SizedBox(
              width: 64,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: pctColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(q.formattedChange, textAlign: TextAlign.center, style: GoogleFonts.orbitron(
                  color: pctColor, fontSize: 9, fontWeight: FontWeight.bold,
                )),
              ),
            ),
            // Sparkline
            SizedBox(
              width: 72,
              child: Center(
                child: SparklineWidget(
                  data: q.sparkline.isNotEmpty ? q.sparkline : [q.price * 0.98, q.price],
                  width: 64,
                  height: 28,
                ),
              ),
            ),
            // Watchlist star
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (isWatched) _watchlist.remove(q.symbol);
                  else _watchlist.add(q.symbol);
                });
              },
              child: SizedBox(
                width: 24,
                child: Icon(
                  isWatched ? Icons.star : Icons.star_border,
                  color: isWatched ? Colors.amber : p.textSecondary.withValues(alpha: 0.4),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChart(BuildContext ctx, LiveQuote q) {
    Navigator.push(ctx, MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: ctx.read<ThemeProvider>(),
        child: TradingViewChartScreen(
          symbol: q.symbol,
          name: q.name,
        ),
      ),
    ));
  }
}
