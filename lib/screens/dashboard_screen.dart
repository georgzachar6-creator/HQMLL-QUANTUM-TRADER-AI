/// HQMLL Quantum Trader – Professional Dashboard v2
/// Live Crypto + Stocks + Commodities + FIAT · Original Icons
/// Grigori Saks · 2025
library;


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/theme_provider.dart';
import '../services/live_market_service.dart';
import '../widgets/asset_icon_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _tickerCtrl;
  int _categoryTab = 0; // 0=Alle 1=Crypto 2=Aktien 3=Rohstoffe 4=FIAT
  bool _showHeatmap = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _tickerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<LiveMarketService>();
      svc.startAutoRefresh();
      svc.connectBinanceWebSocket();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _tickerCtrl.dispose();
    super.dispose();
  }

  List<AssetQuote> _filteredAssets(LiveMarketService svc) {
    switch (_categoryTab) {
      case 1: return svc.cryptoAssets;
      case 2: return svc.stockAssets;
      case 3: return svc.commodityAssets;
      case 4: return []; // FIAT handled separately
      default:
        final all = svc.quotes.values.toList();
        all.sort((a, b) => b.marketCap.compareTo(a.marketCap));
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;
    final svc = context.watch<LiveMarketService>();

    return Scaffold(
      backgroundColor: p.background,
      body: RefreshIndicator(
        onRefresh: () => svc.fetchCoinGeckoData(),
        color: p.primary,
        backgroundColor: p.surface,
        child: CustomScrollView(
          slivers: [
            // ─ Portfolio Header ─
            SliverToBoxAdapter(child: _buildPortfolioHeader(p, svc)),
            // ─ Live Status ─
            SliverToBoxAdapter(child: _buildLiveBar(p, svc)),
            // ─ Schnellzugriff: Top Movers ─
            SliverToBoxAdapter(child: _buildTopMovers(p, svc)),
            // ─ Mini Sparklines ─
            SliverToBoxAdapter(child: _buildSparklineRow(p, svc)),
            // ─ Kategorie-Tabs ─
            SliverToBoxAdapter(child: _buildCategoryTabs(p)),
            // ─ Ansicht-Toggle ─
            SliverToBoxAdapter(child: _buildViewToggle(p)),
            // ─ FIAT-Kurs-Banner ─
            if (_categoryTab == 4)
              SliverToBoxAdapter(child: _buildFiatPanel(p, svc))
            // ─ Heatmap ─
            else if (_showHeatmap)
              SliverToBoxAdapter(child: _buildHeatmap(p, svc))
            // ─ Asset-Liste ─
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final assets = _filteredAssets(svc);
                    if (i >= assets.length) return null;
                    return _buildAssetRow(assets[i], p, i + 1, svc);
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ── Portfolio Header ─────────────────────────────────
  Widget _buildPortfolioHeader(dynamic p, LiveMarketService svc) {
    final btcPrice = svc.quote('BTC')?.price ?? 67842.5;
    final ethPrice = svc.quote('ETH')?.price ?? 3548.2;
    final portfolio = (0.42 * btcPrice) + (3.85 * ethPrice) + (12 * (svc.quote('SOL')?.price ?? 182.4)) + (1284 * (svc.quote('QEMMA')?.price ?? 0.0847)) + 1480;
    final portfolioEur = portfolio * 0.923;
    const change = 2.87;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.primary.withValues(alpha: 0.18),
            p.secondary.withValues(alpha: 0.10),
            p.background,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.primary.withValues(alpha: 0.25), width: 1),
        boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // HQMLL Logo
              Image.asset('assets/icons/hqmll_logo.png', width: 32, height: 32, errorBuilder: (_, __, ___) =>
                  Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: p.primary.withValues(alpha: 0.2)),
                    child: Center(child: Text('H', style: TextStyle(color: p.primary, fontWeight: FontWeight.w900, fontSize: 14))))),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PORTFOLIO ÜBERSICHT', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 11, letterSpacing: 1.5)),
                  Text('Quantum Trader', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ],
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C87B).withValues(alpha: 0.12 + _pulseCtrl.value * 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00C87B).withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00C87B).withValues(alpha: 0.6 + _pulseCtrl.value * 0.4))),
                    const SizedBox(width: 5),
                    Text('LIVE', style: GoogleFonts.rajdhani(color: const Color(0xFF00C87B), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ─ Gesamt Wert ─
          Text(
            '\$${_fmtNum(portfolio)}',
            style: GoogleFonts.rajdhani(
              color: p.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            '≈ €${_fmtNum(portfolioEur)}',
            style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          // ─ Change + Balken ─
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C87B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('+$change%  ↑', style: GoogleFonts.rajdhani(color: const Color(0xFF00C87B), fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text('24h Performance', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 12)),
              const Spacer(),
              Text('BTC: ${svc.quote('BTC')?.formattedPrice ?? '\$67,842'}',
                style: GoogleFonts.rajdhani(color: p.primary, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          // ─ Mini-Allocation-Bar ─
          _buildAllocationBar(p, svc),
        ],
      ),
    );
  }

  Widget _buildAllocationBar(dynamic p, LiveMarketService svc) {
    final allocations = [
      ('BTC', 0.35, const Color(0xFFF7931A)),
      ('ETH', 0.22, const Color(0xFF627EEA)),
      ('SOL', 0.14, const Color(0xFF9945FF)),
      ('QEMMA', 0.12, const Color(0xFF00D4FF)),
      ('Sonstige', 0.17, const Color(0xFF444466)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: allocations.map((a) => Expanded(
              flex: (a.$2 * 100).round(),
              child: Container(height: 6, color: a.$3),
            )).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: allocations.map((a) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: a.$3, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('${a.$1} ${(a.$2 * 100).round()}%', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
            ],
          )).toList(),
        ),
      ],
    );
  }

  // ── Live Status Bar ──────────────────────────────────
  Widget _buildLiveBar(dynamic p, LiveMarketService svc) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          _liveBarItem(p, 'GESAMT', '${svc.quotes.length}', Icons.list, p.primary),
          _liveBarDivider(p),
          _liveBarItem(p, 'LIVE', svc.isLive ? 'CoinGecko' : 'Simulated', Icons.wifi, svc.isLive ? const Color(0xFF00C87B) : const Color(0xFFFF9900)),
          _liveBarDivider(p),
          _liveBarItem(p, 'TOP GAINER', svc.topGainers.isNotEmpty ? svc.topGainers.first.symbol : '-', Icons.trending_up, const Color(0xFF00C87B)),
          _liveBarDivider(p),
          _liveBarItem(p, 'TOP LOSER', svc.topLosers.isNotEmpty ? svc.topLosers.first.symbol : '-', Icons.trending_down, const Color(0xFFFF3B5C)),
        ],
      ),
    );
  }

  Widget _liveBarItem(dynamic p, String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 2),
          Text(val, style: GoogleFonts.rajdhani(color: color, fontSize: 11, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
          Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _liveBarDivider(dynamic p) => Container(width: 1, height: 30, color: p.primary.withValues(alpha: 0.12));

  // ── Top Movers ───────────────────────────────────────
  Widget _buildTopMovers(dynamic p, LiveMarketService svc) {
    final gainers = svc.topGainers.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            Icon(Icons.rocket_launch, color: p.primary, size: 16),
            const SizedBox(width: 6),
            Text('TOP MOVER · 24H', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ]),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: gainers.length,
            itemBuilder: (ctx, i) => _buildMoverCard(gainers[i], p),
          ),
        ),
      ],
    );
  }

  Widget _buildMoverCard(AssetQuote q, dynamic p) {
    final isPos = q.isPositive;
    final color = isPos ? const Color(0xFF00C87B) : const Color(0xFFFF3B5C);
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              AssetIconWidget(symbol: q.symbol, palette: p, size: 28, showBorder: false),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(5)),
                child: Text(q.formattedChange, style: GoogleFonts.rajdhani(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ]),
            Text(q.symbol, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
            Text(q.formattedPrice, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ── Sparkline Row ────────────────────────────────────
  Widget _buildSparklineRow(dynamic p, LiveMarketService svc) {
    final symbols = ['BTC', 'ETH', 'XAU', 'AAPL', 'TSLA', 'QEMMA'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('SPARKLINES · 24H', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: symbols.length,
            itemBuilder: (ctx, i) => _buildSparkCard(symbols[i], p, svc),
          ),
        ),
      ],
    );
  }

  Widget _buildSparkCard(String sym, dynamic p, LiveMarketService svc) {
    final q = svc.quote(sym);
    final candles = svc.candles(sym).take(20).toList();
    final isPos = q?.isPositive ?? true;
    final color = isPos ? const Color(0xFF00C87B) : const Color(0xFFFF3B5C);

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            AssetIconWidget(symbol: sym, palette: p, size: 18, showBorder: false),
            const SizedBox(width: 4),
            Text(sym, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.w800)),
          ]),
          Expanded(
            child: candles.length > 2
                ? LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(candles.length, (i) => FlSpot(i.toDouble(), candles[i].close)),
                          isCurved: true,
                          color: color,
                          barWidth: 1.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(),
          ),
          Text(q?.formattedChange ?? '0%', style: GoogleFonts.rajdhani(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── Kategorie Tabs ───────────────────────────────────
  Widget _buildCategoryTabs(dynamic p) {
    final tabs = ['ALLE', 'CRYPTO', 'AKTIEN', 'ROHSTOFFE', 'FIAT'];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == _categoryTab;
          return GestureDetector(
            onTap: () { setState(() => _categoryTab = i); HapticFeedback.selectionClick(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: active ? p.primary : p.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: active ? p.primary : p.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                tabs[i],
                style: GoogleFonts.rajdhani(
                  color: active ? p.background : p.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── View Toggle (Liste / Heatmap) ─────────────────────
  Widget _buildViewToggle(dynamic p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Text(
            _categoryTab == 0 ? 'ALLE ASSETS (${context.read<LiveMarketService>().quotes.length})' : _tabLabel(),
            style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 11, letterSpacing: 1),
          ),
          const Spacer(),
          if (_categoryTab != 4)
            GestureDetector(
              onTap: () => setState(() => _showHeatmap = !_showHeatmap),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _showHeatmap ? p.primary.withValues(alpha: 0.2) : p.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: p.primary.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(_showHeatmap ? Icons.grid_view : Icons.list, color: p.primary, size: 14),
                  const SizedBox(width: 4),
                  Text(_showHeatmap ? 'HEATMAP' : 'LISTE', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  String _tabLabel() {
    const labels = ['ALLE', 'CRYPTO', 'AKTIEN', 'ROHSTOFFE', 'FIAT'];
    return labels[_categoryTab];
  }

  // ── Asset Row ────────────────────────────────────────
  Widget _buildAssetRow(AssetQuote q, dynamic p, int rank, LiveMarketService svc) {
    final isPos = q.isPositive;
    final color = isPos ? const Color(0xFF00C87B) : const Color(0xFFFF3B5C);
    final candles = svc.candles(q.symbol).take(12).toList();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showAssetDetail(q, p, svc);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.primary.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 22,
              child: Text('$rank', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 11)),
            ),
            // Icon
            AssetIconWidget(symbol: q.symbol, palette: p, size: 40),
            const SizedBox(width: 12),
            // Name + Symbol
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.symbol, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                  Text(q.name, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
                  // Category badge
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: _categoryColor(q.category).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(_categoryLabel(q.category), style: GoogleFonts.rajdhani(color: _categoryColor(q.category), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
            // Sparkline
            if (candles.length > 2)
              SizedBox(
                width: 50,
                height: 30,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(candles.length, (i) => FlSpot(i.toDouble(), candles[i].close)),
                        isCurved: true,
                        color: color,
                        barWidth: 1.5,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 10),
            // Price + Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(q.formattedPrice, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(q.formattedChange, style: GoogleFonts.rajdhani(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                if (q.marketCap > 0)
                  Text('MCap: ${_fmtBig(q.marketCap)}', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'crypto': return const Color(0xFF00D4FF);
      case 'stock': return const Color(0xFF4285F4);
      case 'commodity': return const Color(0xFFFFD700);
      default: return const Color(0xFF85BB65);
    }
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'crypto': return 'CRYPTO';
      case 'stock': return 'AKTIE';
      case 'commodity': return 'ROHSTOFF';
      default: return 'FIAT';
    }
  }

  // ── Heatmap ──────────────────────────────────────────
  Widget _buildHeatmap(dynamic p, LiveMarketService svc) {
    final assets = _filteredAssets(svc);
    return Container(
      margin: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: assets.length,
        itemBuilder: (ctx, i) {
          final q = assets[i];
          final isPos = q.isPositive;
          final intensity = (q.change24h.abs() / 10).clamp(0.1, 1.0);
          final color = isPos
              ? Color.lerp(const Color(0xFF001A0D), const Color(0xFF00C87B), intensity)!
              : Color.lerp(const Color(0xFF1A0005), const Color(0xFFFF3B5C), intensity)!;
          return Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AssetIconWidget(symbol: q.symbol, palette: p, size: 24, showBorder: false),
                const SizedBox(height: 2),
                Text(q.symbol, style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                Text(q.formattedChange, style: GoogleFonts.rajdhani(color: Colors.white.withValues(alpha: 0.85), fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── FIAT Panel ───────────────────────────────────────
  Widget _buildFiatPanel(dynamic p, LiveMarketService svc) {
    final fiats = [
      const _FiatItem('EUR', 'Euro', '€', 0.923, 0.12, 'DE · Euro-Zone'),
      const _FiatItem('USD', 'US-Dollar', '\$', 1.000, 0.0, 'US · Leitwährung'),
      const _FiatItem('GBP', 'Brit. Pfund', '£', 0.792, -0.08, 'GB · Pfund Sterling'),
      const _FiatItem('CHF', 'Schweizer Franken', '₣', 0.902, 0.05, 'CH · Franken'),
      const _FiatItem('JPY', 'Japanischer Yen', '¥', 154.2, -0.34, 'JP · Yen'),
      const _FiatItem('CNY', 'Chinesischer Yuan', '¥', 7.25, 0.02, 'CN · Renminbi'),
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            const Icon(Icons.currency_exchange, color: Color(0xFF85BB65), size: 16),
            const SizedBox(width: 6),
            Text('FIAT-KURSE vs USD', style: GoogleFonts.rajdhani(color: const Color(0xFF85BB65), fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ]),
        ),
        ...fiats.map((f) => _buildFiatRow(f, p)),
        const SizedBox(height: 12),
        // EUR/USD Broker Transfer
        _buildFiatTransferCard(p, svc),
      ],
    );
  }

  Widget _buildFiatRow(_FiatItem f, dynamic p) {
    final isPos = f.change >= 0;
    final color = isPos ? const Color(0xFF00C87B) : const Color(0xFFFF3B5C);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 3, 16, 3),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Currency Symbol Circle
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF85BB65).withValues(alpha: 0.15),
              border: Border.all(color: const Color(0xFF85BB65).withValues(alpha: 0.3)),
            ),
            child: Center(child: Text(f.symbol, style: GoogleFonts.rajdhani(color: const Color(0xFF85BB65), fontSize: 16, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.code, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
              Text(f.detail, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(f.code == 'JPY' ? '${f.rate.toStringAsFixed(2)} JPY' : f.rate.toStringAsFixed(3),
              style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            Text('${isPos ? '+' : ''}${f.change.toStringAsFixed(2)}%',
              style: GoogleFonts.rajdhani(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }

  Widget _buildFiatTransferCard(dynamic p, LiveMarketService svc) {
    final btcEur = svc.toEur(svc.quote('BTC')?.price ?? 67842.5);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF003399).withValues(alpha: 0.2), const Color(0xFF006400).withValues(alpha: 0.2)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF85BB65).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.swap_horiz, color: Color(0xFF85BB65), size: 18),
            const SizedBox(width: 6),
            Text('EUR / USD CONVERTER', style: GoogleFonts.rajdhani(color: const Color(0xFF85BB65), fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _fiatConvertBox('EUR', '€', '1.000,00', p)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, color: p.primary, size: 20),
              ),
              Expanded(child: _fiatConvertBox('USD', '\$', '1.083,15', p)),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: p.primary.withValues(alpha: 0.15)),
          const SizedBox(height: 8),
          Row(children: [
            Text('1 BTC = ', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 12)),
            Text('€${_fmtNum(btcEur)}', style: GoogleFonts.rajdhani(color: const Color(0xFFF7931A), fontSize: 14, fontWeight: FontWeight.w800)),
            Text(' / ', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 12)),
            Text('\$${_fmtNum(svc.quote('BTC')?.price ?? 67842.5)}', style: GoogleFonts.rajdhani(color: const Color(0xFF85BB65), fontSize: 14, fontWeight: FontWeight.w800)),
          ]),
        ],
      ),
    );
  }

  Widget _fiatConvertBox(String code, String sym, String val, dynamic p) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(code, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10, letterSpacing: 1)),
          Text('$sym $val', style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── Asset Detail Bottom Sheet ─────────────────────────
  void _showAssetDetail(AssetQuote q, dynamic p, LiveMarketService svc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: p.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scroll) => _AssetDetailSheet(q: q, palette: p, svc: svc, scrollCtrl: scroll),
      ),
    );
  }

  // ── Formatierungshelfer ──────────────────────────────
  String _fmtNum(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1000) {
      final s = v.toStringAsFixed(2);
      return s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
    }
    return v.toStringAsFixed(2);
  }

  String _fmtBig(double v) {
    if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(1)}T';
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(0)}M';
    return v.toStringAsFixed(0);
  }
}

// ═══════════════════════════════════════════════════════
// ASSET DETAIL SHEET
// ═══════════════════════════════════════════════════════
class _AssetDetailSheet extends StatelessWidget {
  final AssetQuote q;
  final dynamic palette;
  final LiveMarketService svc;
  final ScrollController scrollCtrl;

  const _AssetDetailSheet({required this.q, required this.palette, required this.svc, required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final isPos = q.isPositive;
    final color = isPos ? const Color(0xFF00C87B) : const Color(0xFFFF3B5C);
    final candles = svc.candles(q.symbol).take(50).toList();

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(20),
      children: [
        // Handle
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: p.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        // Header
        Row(children: [
          AnimatedAssetIcon(symbol: q.symbol, palette: p, size: 52, pulsing: true),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(q.name, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(q.symbol, style: GoogleFonts.rajdhani(color: p.primary, fontSize: 13, letterSpacing: 1)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(q.formattedPrice, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(q.formattedChange, style: GoogleFonts.rajdhani(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ]),
        ]),
        const SizedBox(height: 20),
        // Chart
        if (candles.length > 2)
          Container(
            height: 160,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.primary.withValues(alpha: 0.1))),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: p.primary.withValues(alpha: 0.05), strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(candles.length, (i) => FlSpot(i.toDouble(), candles[i].close)),
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        // Stats Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            _statTile(p, '24H HOCH', '\$${q.high24h.toStringAsFixed(2)}', Icons.arrow_upward, const Color(0xFF00C87B)),
            _statTile(p, '24H TIEF', '\$${q.low24h.toStringAsFixed(2)}', Icons.arrow_downward, const Color(0xFFFF3B5C)),
            _statTile(p, 'VOLUMEN', _fmtBig(q.volume24h), Icons.bar_chart, p.primary),
            _statTile(p, 'MARKET CAP', _fmtBig(q.marketCap), Icons.account_balance, const Color(0xFFFFD700)),
          ],
        ),
        const SizedBox(height: 16),
        // Buy/Sell Buttons
        Row(children: [
          Expanded(child: ElevatedButton.icon(
            onPressed: () { HapticFeedback.mediumImpact(); Navigator.pop(context); },
            icon: const Icon(Icons.add_shopping_cart, size: 16),
            label: Text('KAUFEN', style: GoogleFonts.rajdhani(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C87B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton.icon(
            onPressed: () { HapticFeedback.mediumImpact(); Navigator.pop(context); },
            icon: const Icon(Icons.sell, size: 16),
            label: Text('VERKAUFEN', style: GoogleFonts.rajdhani(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B5C), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
        ]),
      ],
    );
  }

  Widget _statTile(dynamic p, String label, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.primary.withValues(alpha: 0.1))),
      child: Row(children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8, letterSpacing: 0.5)),
          Text(val, style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  String _fmtBig(double v) {
    if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(1)}T';
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(0)}M';
    return v.toStringAsFixed(0);
  }
}

// ─ Hilfsklassen ─────────────────────────────────────────
class _FiatItem {
  final String code, name, symbol, detail;
  final double rate, change;
  const _FiatItem(this.code, this.name, this.symbol, this.rate, this.change, this.detail);
}
