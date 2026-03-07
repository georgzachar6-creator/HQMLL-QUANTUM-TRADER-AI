import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _tickCtrl;
  Timer? _priceTimer;
  int _viewMode = 0; // 0=Liste, 1=Heatmap
  String _sortBy = 'rank'; // rank, change, volume
  String _filter = 'All'; // All, Gainers, Losers
  final Random _rng = Random(55);

  final List<_Coin> _coins = [
    _Coin('BTC',  'Bitcoin',        67842.50,  2.34,  1284000000000, 850000000),
    _Coin('ETH',  'Ethereum',        3548.20,  1.87,   426000000000, 420000000),
    _Coin('BNB',  'BNB',              598.30,  0.94,    89000000000, 120000000),
    _Coin('SOL',  'Solana',           182.40, -0.52,    79000000000, 230000000),
    _Coin('XRP',  'XRP',               0.624,  3.21,    35000000000, 890000000),
    _Coin('USDT', 'Tether',            1.000,  0.01,    95000000000, 68000000000),
    _Coin('ADA',  'Cardano',           0.452, -1.23,    16000000000, 320000000),
    _Coin('AVAX', 'Avalanche',        36.80,   4.56,    15000000000,  87000000),
    _Coin('DOT',  'Polkadot',          7.92,  -0.88,     9400000000,  64000000),
    _Coin('LINK', 'Chainlink',        14.62,   2.11,     8700000000,  45000000),
    _Coin('QEMMA','QEMMA Token',      0.0847, 12.45,      108000000,  28000000),
    _Coin('MATIC','Polygon',           0.892, -2.34,     8200000000, 390000000),
    _Coin('UNI',  'Uniswap',           8.14,   1.67,     4900000000,  72000000),
    _Coin('LTC',  'Litecoin',         82.50,   0.55,     6100000000,  38000000),
    _Coin('ATOM', 'Cosmos',            9.76,  -1.44,     3800000000,  24000000),
    _Coin('NEAR', 'NEAR Protocol',     5.32,   3.78,     5700000000,  62000000),
    _Coin('APT',  'Aptos',             9.18,   5.23,     3900000000,  84000000),
    _Coin('ARB',  'Arbitrum',          1.24,  -0.67,     1600000000, 110000000),
    _Coin('OP',   'Optimism',          2.48,   1.98,     2400000000,  95000000),
    _Coin('SUI',  'Sui',               1.86,   6.44,     2100000000, 178000000),
  ];

  @override
  void initState() {
    super.initState();
    _tickCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _priceTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() {
        for (final c in _coins) {
          final delta = (_rng.nextDouble() - 0.48) * 0.4;
          c.price = (c.price * (1 + delta / 100)).clamp(c.price * 0.98, c.price * 1.02);
          c.change = (c.change + (_rng.nextDouble() - 0.5) * 0.1).clamp(-15.0, 20.0);
        }
      });
    });
  }

  @override
  void dispose() {
    _tickCtrl.dispose();
    _priceTimer?.cancel();
    super.dispose();
  }

  List<_Coin> get _filteredAndSorted {
    var list = List<_Coin>.from(_coins);
    if (_filter == 'Gainers') list = list.where((c) => c.change > 0).toList();
    if (_filter == 'Losers') list = list.where((c) => c.change < 0).toList();
    switch (_sortBy) {
      case 'change':
        list.sort((a, b) => b.change.compareTo(a.change));
        break;
      case 'volume':
        list.sort((a, b) => b.volume.compareTo(a.volume));
        break;
      default:
        list.sort((a, b) => b.marketCap.compareTo(a.marketCap));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    final sorted = _filteredAndSorted;
    final gainers = _coins.where((c) => c.change > 0).length;
    final losers = _coins.where((c) => c.change < 0).length;
    final avgChange = _coins.fold<double>(0, (s, c) => s + c.change) / _coins.length;

    return Scaffold(
      backgroundColor: p.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(54),
        child: Container(
          color: p.background,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 54,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, color: p.primary, size: 22),
                    const SizedBox(width: 10),
                    Text('MARKT', style: GoogleFonts.spaceMono(
                      color: p.textPrimary, fontSize: 14,
                      fontWeight: FontWeight.bold, letterSpacing: 2,
                    )),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('TOP 20', style: GoogleFonts.spaceMono(
                        color: p.textSecondary, fontSize: 8, letterSpacing: 1,
                      )),
                    ),
                    const Spacer(),
                    // View toggle
                    _ViewToggle(
                      selected: _viewMode,
                      onTap: (v) => setState(() => _viewMode = v),
                      palette: p,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Market summary bar
          _buildSummaryBar(p, gainers, losers, avgChange),
          // Filters
          _buildFilters(p),
          // Content
          Expanded(
            child: _viewMode == 0
                ? _buildListView(p, sorted)
                : _buildHeatmap(p),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(dynamic p, int gainers, int losers, double avgChange) {
    final totalMcap = _coins.fold<double>(0, (s, c) => s + c.marketCap);
    final isPositive = avgChange >= 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          _SumItem(
            label: 'MARKTKAPITAL.',
            value: '\$${(totalMcap / 1e12).toStringAsFixed(2)}T',
            palette: p,
            highlight: false,
          ),
          _vertDivider(p),
          _SumItem(
            label: 'Ø VERÄNDERUNG',
            value: '${isPositive ? '+' : ''}${avgChange.toStringAsFixed(2)}%',
            palette: p,
            highlight: true,
            positive: isPositive,
          ),
          _vertDivider(p),
          _SumItem(
            label: 'STEIGER / FALL.',
            value: '$gainers / $losers',
            palette: p,
            highlight: false,
          ),
        ],
      ),
    );
  }

  Widget _vertDivider(dynamic p) => Container(
    width: 1, height: 30,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: p.primary.withValues(alpha: 0.12),
  );

  Widget _buildFilters(dynamic p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          // Filter chips
          ...[['All', 'Alle'], ['Gainers', 'Steiger'], ['Losers', 'Faller']].map((f) {
            final active = _filter == f[0];
            return GestureDetector(
              onTap: () => setState(() => _filter = f[0]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? p.primary.withValues(alpha: 0.15) : p.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: active ? p.primary.withValues(alpha: 0.6) : p.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(f[1], style: GoogleFonts.spaceMono(
                  color: active ? p.primary : p.textSecondary,
                  fontSize: 9, fontWeight: FontWeight.bold,
                )),
              ),
            );
          }),
          const Spacer(),
          // Sort dropdown
          GestureDetector(
            onTap: () => _showSortMenu(context, p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: p.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort, color: p.textSecondary, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    _sortBy == 'rank' ? 'Rang'
                        : _sortBy == 'change' ? '% Änd.'
                        : 'Volume',
                    style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortMenu(BuildContext context, dynamic p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sortierung', style: GoogleFonts.spaceMono(
              color: p.textSecondary, fontSize: 10, letterSpacing: 1.5,
            )),
            const SizedBox(height: 12),
            ...[
              ['rank', Icons.format_list_numbered, 'Nach Rang (Marktkapital.)'],
              ['change', Icons.trending_up, 'Nach % Veränderung'],
              ['volume', Icons.bar_chart, 'Nach Handelsvolumen'],
            ].map((o) => ListTile(
              leading: Icon(o[1] as IconData, color: _sortBy == o[0] ? p.primary : p.textSecondary, size: 18),
              title: Text(o[2] as String, style: GoogleFonts.inter(
                color: _sortBy == o[0] ? p.primary : p.textPrimary, fontSize: 13,
              )),
              trailing: _sortBy == o[0]
                  ? Icon(Icons.check, color: p.primary, size: 16) : null,
              onTap: () {
                setState(() => _sortBy = o[0] as String);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(dynamic p, List<_Coin> coins) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
      itemCount: coins.length,
      itemBuilder: (_, i) => _CoinRow(
        coin: coins[i],
        rank: _coins.indexOf(coins[i]) + 1,
        palette: p,
      ),
    );
  }

  Widget _buildHeatmap(dynamic p) {
    final sorted = List<_Coin>.from(_coins)
      ..sort((a, b) => b.marketCap.compareTo(a.marketCap));
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final coin = sorted[i];
        final isPos = coin.change >= 0;
        final intensity = (coin.change.abs() / 15.0).clamp(0.0, 1.0);
        final baseColor = isPos ? p.positive : p.negative;
        final tileColor = baseColor.withValues(alpha: 0.15 + intensity * 0.45);
        return Container(
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: baseColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(coin.symbol, style: GoogleFonts.spaceMono(
                color: p.textPrimary, fontSize: i < 6 ? 13 : 10,
                fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 2),
              Text(
                '${isPos ? '+' : ''}${coin.change.toStringAsFixed(2)}%',
                style: GoogleFonts.rajdhani(
                  color: isPos ? p.positive : p.negative,
                  fontSize: i < 6 ? 12 : 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── View Toggle ────────────────────────────────────────
class _ViewToggle extends StatelessWidget {
  final int selected;
  final void Function(int) onTap;
  final dynamic palette;
  const _ViewToggle({required this.selected, required this.onTap, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn(0, Icons.list_alt, p),
          _toggleBtn(1, Icons.grid_view, p),
        ],
      ),
    );
  }

  Widget _toggleBtn(int idx, IconData icon, dynamic p) {
    final active = selected == idx;
    return GestureDetector(
      onTap: () => onTap(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: active ? p.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: active ? p.primary : p.textSecondary, size: 16),
      ),
    );
  }
}

// ── Summary Item ───────────────────────────────────────
class _SumItem extends StatelessWidget {
  final String label, value;
  final dynamic palette;
  final bool highlight;
  final bool positive;
  const _SumItem({
    required this.label,
    required this.value,
    required this.palette,
    required this.highlight,
    this.positive = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    Color valColor = p.textPrimary;
    if (highlight) valColor = positive ? p.positive : p.negative;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: GoogleFonts.spaceMono(
            color: p.textSecondary, fontSize: 8, letterSpacing: 0.5,
          )),
          const SizedBox(height: 3),
          Text(value, style: GoogleFonts.rajdhani(
            color: valColor, fontSize: 13, fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }
}

// ── Coin Row ───────────────────────────────────────────
class _CoinRow extends StatelessWidget {
  final _Coin coin;
  final int rank;
  final dynamic palette;
  const _CoinRow({required this.coin, required this.rank, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final isPos = coin.change >= 0;
    final changeColor = isPos ? p.positive : p.negative;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 22,
            child: Text('$rank', style: GoogleFonts.spaceMono(
              color: p.textSecondary, fontSize: 10,
            )),
          ),
          // Icon circle
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _coinColorFor(coin.symbol, p).withValues(alpha: 0.3),
                  _coinColorFor(coin.symbol, p).withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: _coinColorFor(coin.symbol, p).withValues(alpha: 0.5),
              ),
            ),
            child: Center(
              child: Text(
                coin.symbol.length > 3 ? coin.symbol.substring(0, 3) : coin.symbol,
                style: GoogleFonts.spaceMono(
                  color: _coinColorFor(coin.symbol, p),
                  fontSize: coin.symbol.length > 3 ? 7 : 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coin.symbol, style: GoogleFonts.spaceMono(
                  color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold,
                )),
                Text(coin.name, style: GoogleFonts.inter(
                  color: p.textSecondary, fontSize: 10,
                )),
              ],
            ),
          ),
          // Mcap
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${_formatLarge(coin.marketCap)}',
                  style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10),
                ),
                Text('mcap', style: TextStyle(color: p.textSecondary.withValues(alpha: 0.5), fontSize: 8)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Price & change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                coin.price >= 100
                    ? '\$${coin.price.toStringAsFixed(0)}'
                    : coin.price >= 1
                    ? '\$${coin.price.toStringAsFixed(2)}'
                    : '\$${coin.price.toStringAsFixed(4)}',
                style: GoogleFonts.rajdhani(
                  color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isPos ? '+' : ''}${coin.change.toStringAsFixed(2)}%',
                  style: GoogleFonts.rajdhani(
                    color: changeColor, fontSize: 11, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _coinColorFor(String sym, dynamic p) {
    switch (sym) {
      case 'BTC': return const Color(0xFFF7931A);
      case 'ETH': return const Color(0xFF627EEA);
      case 'BNB': return const Color(0xFFF3BA2F);
      case 'SOL': return const Color(0xFF9945FF);
      case 'XRP': return const Color(0xFF00AAE4);
      case 'QEMMA': return p.primary;
      case 'AVAX': return const Color(0xFFE84142);
      case 'DOT': return const Color(0xFFE6007A);
      case 'LINK': return const Color(0xFF375BD2);
      case 'MATIC': return const Color(0xFF8247E5);
      case 'UNI': return const Color(0xFFFF007A);
      case 'NEAR': return const Color(0xFF00C1DE);
      case 'APT': return const Color(0xFF14C4A2);
      case 'ARB': return const Color(0xFF28A0F0);
      case 'OP': return const Color(0xFFFF0420);
      case 'SUI': return const Color(0xFF6FBCF0);
      default: return p.accent;
    }
  }

  String _formatLarge(double v) {
    if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(2)}T';
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    return v.toStringAsFixed(0);
  }
}

// ── Data ──────────────────────────────────────────────
class _Coin {
  final String symbol, name;
  double price, change;
  final double marketCap, volume;
  _Coin(this.symbol, this.name, this.price, this.change, this.marketCap, this.volume);
}
