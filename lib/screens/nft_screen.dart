// ============================================================
// NFT GALLERY & MARKETPLACE – Quantum Trader v21
// Collections · Floor Prices · Trending · My NFTs · Trade
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';

class NFTScreen extends StatefulWidget {
  const NFTScreen({super.key});
  @override
  State<NFTScreen> createState() => _NFTScreenState();
}

class _NFTScreenState extends State<NFTScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _shimmerCtrl;
  Timer? _liveTimer;
  final _rand = Random();

  int _selectedTab = 0;
  final _tabs = ['TRENDING', 'COLLECTIONS', 'MEINE NFTs', 'WATCHLIST', 'MINT'];
  String _chain = 'ETH';
  final _chains = ['ETH', 'SOL', 'BTC', 'MATIC', 'APT'];

  // ── Collections ──────────────────────────────────────────
  final List<Map<String, dynamic>> _collections = [
    {
      'name': 'Quantum Apes', 'symbol': 'QAPE',
      'floor': 12.4, 'floorChg': 8.2,
      'vol24h': 842.5, 'volChg': 34.1,
      'owners': 4821, 'supply': 10000,
      'listed': 312, 'sales24h': 48,
      'marketCap': 124000.0,
      'color': const Color(0xFF9945FF),
      'emoji': '🦍', 'verified': true, 'chain': 'ETH',
      'desc': 'The premier AI-generated Quantum Ape collection',
      'sparkline': <double>[],
    },
    {
      'name': 'Neural Punks', 'symbol': 'NPNK',
      'floor': 8.75, 'floorChg': -2.3,
      'vol24h': 634.2, 'volChg': -12.4,
      'owners': 3241, 'supply': 10000,
      'listed': 589, 'sales24h': 31,
      'marketCap': 87500.0,
      'color': const Color(0xFF00FF88),
      'emoji': '🤖', 'verified': true, 'chain': 'ETH',
      'desc': 'Cyberpunk neural interface art collection',
      'sparkline': <double>[],
    },
    {
      'name': 'Crypto Wizards', 'symbol': 'CWIZ',
      'floor': 3.21, 'floorChg': 15.8,
      'vol24h': 421.7, 'volChg': 68.2,
      'owners': 6742, 'supply': 8888,
      'listed': 124, 'sales24h': 67,
      'marketCap': 28529.0,
      'color': const Color(0xFF00AAFF),
      'emoji': '🧙', 'verified': true, 'chain': 'SOL',
      'desc': 'Magic-themed wizards ruling the crypto realm',
      'sparkline': <double>[],
    },
    {
      'name': 'Quantum Dragons', 'symbol': 'QDGN',
      'floor': 0.48, 'floorChg': 42.1,
      'vol24h': 318.9, 'volChg': 156.3,
      'owners': 9123, 'supply': 12000,
      'listed': 892, 'sales24h': 204,
      'marketCap': 5760.0,
      'color': const Color(0xFFFF6B00),
      'emoji': '🐉', 'verified': false, 'chain': 'MATIC',
      'desc': 'Fire-breathing dragons on Polygon',
      'sparkline': <double>[],
    },
    {
      'name': 'Bitcoin Ordinals', 'symbol': 'BORD',
      'floor': 0.0082, 'floorChg': 21.4,
      'vol24h': 28.4, 'volChg': 44.8,
      'owners': 2104, 'supply': 2100,
      'listed': 98, 'sales24h': 12,
      'marketCap': 17.2,
      'color': const Color(0xFFF7931A),
      'emoji': '₿', 'verified': true, 'chain': 'BTC',
      'desc': 'Rare Bitcoin Ordinal inscriptions',
      'sparkline': <double>[],
    },
    {
      'name': 'Solana Monkeys', 'symbol': 'SMB',
      'floor': 22.8, 'floorChg': 5.6,
      'vol24h': 1124.0, 'volChg': 18.9,
      'owners': 5532, 'supply': 5000,
      'listed': 201, 'sales24h': 89,
      'marketCap': 114000.0,
      'color': const Color(0xFF9945FF),
      'emoji': '🐵', 'verified': true, 'chain': 'SOL',
      'desc': 'OG Solana blue-chip monkey collection',
      'sparkline': <double>[],
    },
  ];

  // ── My NFTs ───────────────────────────────────────────────
  final List<Map<String, dynamic>> _myNfts = [
    {
      'name': 'Quantum Ape #4821', 'collection': 'Quantum Apes',
      'buyPrice': 9.2, 'currentPrice': 12.4,
      'color': const Color(0xFF9945FF), 'emoji': '🦍',
      'chain': 'ETH', 'tokenId': '#4821',
      'rarity': 'Rare', 'rank': 847,
    },
    {
      'name': 'Neural Punk #0042', 'collection': 'Neural Punks',
      'buyPrice': 11.0, 'currentPrice': 8.75,
      'color': const Color(0xFF00FF88), 'emoji': '🤖',
      'chain': 'ETH', 'tokenId': '#0042',
      'rarity': 'Legendary', 'rank': 12,
    },
    {
      'name': 'Crypto Wizard #1337', 'collection': 'Crypto Wizards',
      'buyPrice': 2.1, 'currentPrice': 3.21,
      'color': const Color(0xFF00AAFF), 'emoji': '🧙',
      'chain': 'SOL', 'tokenId': '#1337',
      'rarity': 'Epic', 'rank': 233,
    },
    {
      'name': 'Bitcoin Ordinal #88', 'collection': 'Bitcoin Ordinals',
      'buyPrice': 0.006, 'currentPrice': 0.0082,
      'color': const Color(0xFFF7931A), 'emoji': '₿',
      'chain': 'BTC', 'tokenId': '#88',
      'rarity': 'Uncommon', 'rank': 412,
    },
  ];

  // ── Watchlist ─────────────────────────────────────────────
  final Set<String> _watchlist = {'Quantum Apes', 'Bitcoin Ordinals', 'Solana Monkeys'};

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();

    // Init sparklines
    for (var c in _collections) {
      final sp = c['sparkline'] as List<double>;
      double v = (c['floor'] as double) * 0.8;
      for (int i = 0; i < 20; i++) {
        v = v * (1 + (_rand.nextDouble() - 0.47) * 0.08);
        sp.add(v);
      }
      sp.add(c['floor'] as double);
    }

    // Live price simulation
    _liveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        for (var c in _collections) {
          final fl = c['floor'] as double;
          final delta = (_rand.nextDouble() - 0.48) * 0.015;
          final newFloor = fl * (1 + delta);
          c['floor'] = newFloor;
          c['floorChg'] = (c['floorChg'] as double) + (_rand.nextDouble() - 0.5) * 0.3;
          final sp = c['sparkline'] as List<double>;
          sp.add(newFloor);
          if (sp.length > 24) sp.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
    _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(p),
          _buildChainSelector(p),
          _buildTabBar(p),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildTrendingTab(p),
                _buildCollectionsTab(p),
                _buildMyNftsTab(p),
                _buildWatchlistTab(p),
                _buildMintTab(p),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── HEADER ───────────────────────────────────────────────
  Widget _buildHeader(dynamic p) {
    // Portfolio value
    double totalValue = 0;
    double totalCost = 0;
    for (var n in _myNfts) {
      totalValue += (n['currentPrice'] as double);
      totalCost += (n['buyPrice'] as double);
    }
    final pnl = totalValue - totalCost;
    final pnlPct = totalCost > 0 ? (pnl / totalCost) * 100 : 0.0;
    final isPnlPos = pnl >= 0;

    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(bottom: BorderSide(
            color: p.primary.withValues(alpha: 0.1 + _glowCtrl.value * 0.07),
          )),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NFT GALLERY', style: GoogleFonts.spaceMono(
              color: p.primary, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2,
            )),
            Text('Portfolio · Marketplace · Collections', style: GoogleFonts.inter(
              color: p.textSecondary, fontSize: 11,
            )),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${totalValue.toStringAsFixed(2)} ETH', style: GoogleFonts.spaceMono(
              color: p.textPrimary, fontSize: 15, fontWeight: FontWeight.bold,
            )),
            Text(
              '${isPnlPos ? "+" : ""}${pnl.toStringAsFixed(2)} ETH (${pnlPct.toStringAsFixed(1)}%)',
              style: GoogleFonts.spaceMono(
                color: isPnlPos ? const Color(0xFF00FF88) : const Color(0xFFFF3358),
                fontSize: 11,
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── CHAIN SELECTOR ────────────────────────────────────────
  Widget _buildChainSelector(dynamic p) {
    final chainColors = {
      'ETH': const Color(0xFF627EEA),
      'SOL': const Color(0xFF9945FF),
      'BTC': const Color(0xFFF7931A),
      'MATIC': const Color(0xFF8247E5),
      'APT': const Color(0xFF00AAFF),
    };
    return Container(
      height: 40,
      color: p.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _chains.length,
        itemBuilder: (_, i) {
          final c = _chains[i];
          final sel = _chain == c;
          final col = chainColors[c] ?? p.primary;
          return GestureDetector(
            onTap: () => setState(() => _chain = c),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: sel ? col.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? col.withValues(alpha: 0.5) : p.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Center(child: Text(c, style: GoogleFonts.spaceMono(
                color: sel ? col : p.textSecondary, fontSize: 10,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              ))),
            ),
          );
        },
      ),
    );
  }

  // ── TAB BAR ───────────────────────────────────────────────
  Widget _buildTabBar(dynamic p) {
    return Container(
      height: 36,
      color: p.surface.withValues(alpha: 0.8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _tabs.length,
        itemBuilder: (_, i) {
          final sel = _selectedTab == i;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedTab = i); },
            child: Container(
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: sel ? p.primary.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: sel ? p.primary.withValues(alpha: 0.4) : Colors.transparent,
                ),
              ),
              child: Center(child: Text(_tabs[i], style: GoogleFonts.spaceMono(
                color: sel ? p.primary : p.textSecondary,
                fontSize: 9, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              ))),
            ),
          );
        },
      ),
    );
  }

  // ── TRENDING TAB ─────────────────────────────────────────
  Widget _buildTrendingTab(dynamic p) {
    final sorted = List<Map<String, dynamic>>.from(_collections)
      ..sort((a, b) => (b['volChg'] as double).compareTo(a['volChg'] as double));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildTrendingBanner(p),
        const SizedBox(height: 12),
        _buildSectionTitle(p, '🔥 TRENDING LAST 24H', Icons.local_fire_department),
        const SizedBox(height: 8),
        ...sorted.take(3).map((c) => _buildTrendingCard(p, c, sorted.indexOf(c) + 1)),
        const SizedBox(height: 16),
        _buildSectionTitle(p, '📈 TOP VOLUME', Icons.bar_chart),
        const SizedBox(height: 8),
        ...(List<Map<String, dynamic>>.from(_collections)
            ..sort((a, b) => (b['vol24h'] as double).compareTo(a['vol24h'] as double)))
            .map((c) => _buildCollectionRow(p, c)),
      ],
    );
  }

  Widget _buildTrendingBanner(dynamic p) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF9945FF).withValues(alpha: 0.15 + _glowCtrl.value * 0.05),
              const Color(0xFF00AAFF).withValues(alpha: 0.1),
              const Color(0xFF00FF88).withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.primary.withValues(alpha: 0.15 + _glowCtrl.value * 0.08)),
        ),
        child: Row(children: [
          const Text('🏆', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NFT MARKT ÜBERSICHT', style: GoogleFonts.spaceMono(
              color: p.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1,
            )),
            const SizedBox(height: 4),
            Row(children: [
              _buildBannerStat(p, 'GESAMTVOLUMEN', '18.4K ETH'),
              const SizedBox(width: 16),
              _buildBannerStat(p, 'AKTIVE SAMMLUNGEN', '${_collections.length}'),
              const SizedBox(width: 16),
              _buildBannerStat(p, 'MEINE NFTs', '${_myNfts.length}'),
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _buildBannerStat(dynamic p, String label, String val) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7, letterSpacing: 0.5)),
      Text(val, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildTrendingCard(dynamic p, Map<String, dynamic> c, int rank) {
    final fl = c['floor'] as double;
    final chg = c['floorChg'] as double;
    final isPos = chg >= 0;
    final color = c['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.07), blurRadius: 14)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // Rank badge
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: rank == 1
                  ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                  : rank == 2
                      ? const Color(0xFFC0C0C0).withValues(alpha: 0.15)
                      : const Color(0xFFCD7F32).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text('$rank', style: GoogleFonts.spaceMono(
              color: rank == 1
                  ? const Color(0xFFFFD700)
                  : rank == 2
                      ? const Color(0xFFC0C0C0)
                      : const Color(0xFFCD7F32),
              fontSize: 11, fontWeight: FontWeight.bold,
            ))),
          ),
          const SizedBox(width: 10),
          // NFT Icon
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(child: Text(c['emoji'] as String, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(c['name'] as String, style: GoogleFonts.spaceMono(
                color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold,
              )),
              if (c['verified'] as bool) ...[
                const SizedBox(width: 4),
                Icon(Icons.verified, color: const Color(0xFF00AAFF), size: 13),
              ],
            ]),
            Text('${c['chain']} · ${c['supply']} Items', style: GoogleFonts.inter(
              color: p.textSecondary, fontSize: 10,
            )),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${fl >= 1 ? fl.toStringAsFixed(2) : fl.toStringAsFixed(4)} ETH', style: GoogleFonts.spaceMono(
              color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold,
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isPos ? const Color(0xFF00FF88) : const Color(0xFFFF3358)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${isPos ? "+" : ""}${chg.toStringAsFixed(1)}%',
                style: GoogleFonts.spaceMono(
                  color: isPos ? const Color(0xFF00FF88) : const Color(0xFFFF3358),
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text('Vol: ${(c['vol24h'] as double).toStringAsFixed(0)} ETH', style: GoogleFonts.inter(
              color: p.textSecondary, fontSize: 9,
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _buildCollectionRow(dynamic p, Map<String, dynamic> c) {
    final fl = c['floor'] as double;
    final chg = c['floorChg'] as double;
    final isPos = chg >= 0;
    final color = c['color'] as Color;
    final sp = c['sparkline'] as List<double>;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.primary.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(c['emoji'] as String, style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c['name'] as String, style: GoogleFonts.inter(
            color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.w600,
          )),
          Text('Floor: ${fl >= 1 ? fl.toStringAsFixed(2) : fl.toStringAsFixed(4)} ETH', style: GoogleFonts.spaceMono(
            color: color, fontSize: 10,
          )),
        ])),
        // Mini sparkline
        if (sp.length > 4)
          SizedBox(
            width: 50, height: 28,
            child: CustomPaint(painter: _SparklinePainter(sp, isPos ? const Color(0xFF00FF88) : const Color(0xFFFF3358))),
          ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${(c['vol24h'] as double).toStringAsFixed(0)} ETH', style: GoogleFonts.spaceMono(
            color: p.textPrimary, fontSize: 11,
          )),
          Text(
            '${isPos ? "+" : ""}${chg.toStringAsFixed(1)}%',
            style: GoogleFonts.spaceMono(
              color: isPos ? const Color(0xFF00FF88) : const Color(0xFFFF3358),
              fontSize: 10,
            ),
          ),
        ]),
      ]),
    );
  }

  // ── COLLECTIONS TAB ──────────────────────────────────────
  Widget _buildCollectionsTab(dynamic p) {
    final filtered = _chain == 'ALL'
        ? _collections
        : _collections.where((c) => c['chain'] == _chain).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionTitle(p, 'ALLE COLLECTIONS', Icons.grid_view),
        const SizedBox(height: 8),
        ...filtered.map((c) => _buildCollectionCard(p, c)),
      ],
    );
  }

  Widget _buildCollectionCard(dynamic p, Map<String, dynamic> c) {
    final fl = c['floor'] as double;
    final chg = c['floorChg'] as double;
    final isPos = chg >= 0;
    final color = c['color'] as Color;
    final sp = c['sparkline'] as List<double>;
    final inWatchlist = _watchlist.contains(c['name']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(children: [
        // Header with gradient
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.03)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Center(child: Text(c['emoji'] as String, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(c['name'] as String, style: GoogleFonts.spaceMono(
                  color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold,
                )),
                if (c['verified'] as bool) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.verified, color: const Color(0xFF00AAFF), size: 14),
                ],
              ]),
              Text(c['desc'] as String, style: GoogleFonts.inter(
                color: p.textSecondary, fontSize: 10,
              )),
              const SizedBox(height: 4),
              Row(children: [
                _buildChainBadge(p, c['chain'] as String, color),
                const SizedBox(width: 6),
                Text('${c['symbol']}', style: GoogleFonts.spaceMono(
                  color: color, fontSize: 9,
                )),
              ]),
            ])),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (inWatchlist) _watchlist.remove(c['name']); else _watchlist.add(c['name'] as String);
                });
              },
              child: Icon(
                inWatchlist ? Icons.star : Icons.star_border,
                color: inWatchlist ? const Color(0xFFFFAA00) : p.textSecondary,
                size: 22,
              ),
            ),
          ]),
        ),
        // Stats Grid
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              _buildStatCell(p, 'FLOOR', '${fl >= 1 ? fl.toStringAsFixed(2) : fl.toStringAsFixed(4)} ETH', color),
              _buildStatCell(p, '24H CHANGE', '${isPos ? "+" : ""}${chg.toStringAsFixed(1)}%',
                  isPos ? const Color(0xFF00FF88) : const Color(0xFFFF3358)),
              _buildStatCell(p, '24H VOLUME', '${(c['vol24h'] as double).toStringAsFixed(0)} ETH', p.textPrimary),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _buildStatCell(p, 'OWNER', '${c['owners']}', p.textSecondary),
              _buildStatCell(p, 'SUPPLY', '${c['supply']}', p.textSecondary),
              _buildStatCell(p, 'LISTED', '${c['listed']}', p.textSecondary),
            ]),
          ]),
        ),
        // Sparkline
        if (sp.length > 4)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: SizedBox(
              width: double.infinity, height: 40,
              child: CustomPaint(
                painter: _SparklinePainter(sp, isPos ? const Color(0xFF00FF88) : const Color(0xFFFF3358)),
              ),
            ),
          ),
        // Action Row
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: p.primary.withValues(alpha: 0.06))),
          ),
          child: Row(children: [
            Expanded(child: _buildActionBtn(p, 'KAUFEN', color, () {})),
            const SizedBox(width: 8),
            Expanded(child: _buildActionBtn(p, 'DETAILS', p.textSecondary, () {})),
          ]),
        ),
      ]),
    );
  }

  Widget _buildChainBadge(dynamic p, String chain, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(chain, style: GoogleFonts.spaceMono(color: color, fontSize: 8)),
    );
  }

  Widget _buildStatCell(dynamic p, String label, String value, Color color) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.spaceMono(
          color: p.textSecondary.withValues(alpha: 0.5), fontSize: 7, letterSpacing: 0.5,
        )),
        Text(value, style: GoogleFonts.spaceMono(
          color: color, fontSize: 10, fontWeight: FontWeight.bold,
        )),
      ]),
    );
  }

  Widget _buildActionBtn(dynamic p, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Center(child: Text(label, style: GoogleFonts.spaceMono(
          color: color, fontSize: 10, fontWeight: FontWeight.bold,
        ))),
      ),
    );
  }

  // ── MY NFTs TAB ───────────────────────────────────────────
  Widget _buildMyNftsTab(dynamic p) {
    double totalValue = _myNfts.fold(0, (s, n) => s + (n['currentPrice'] as double));
    double totalCost = _myNfts.fold(0, (s, n) => s + (n['buyPrice'] as double));
    final pnl = totalValue - totalCost;
    final pnlPct = totalCost > 0 ? (pnl / totalCost) * 100 : 0.0;
    final isPos = pnl >= 0;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Portfolio Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.primary.withValues(alpha: 0.15)),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('NFT PORTFOLIO', style: GoogleFonts.spaceMono(
                  color: p.textSecondary, fontSize: 10, letterSpacing: 1,
                )),
                Text('${totalValue.toStringAsFixed(3)} ETH', style: GoogleFonts.spaceMono(
                  color: p.textPrimary, fontSize: 22, fontWeight: FontWeight.bold,
                )),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('GESAMT P&L', style: GoogleFonts.spaceMono(
                  color: p.textSecondary, fontSize: 10, letterSpacing: 1,
                )),
                Text(
                  '${isPos ? "+" : ""}${pnl.toStringAsFixed(3)} ETH',
                  style: GoogleFonts.spaceMono(
                    color: isPos ? const Color(0xFF00FF88) : const Color(0xFFFF3358),
                    fontSize: 16, fontWeight: FontWeight.bold,
                  ),
                ),
                Text('${pnlPct.toStringAsFixed(1)}%', style: GoogleFonts.inter(
                  color: isPos ? const Color(0xFF00FF88) : const Color(0xFFFF3358),
                  fontSize: 12,
                )),
              ]),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _buildPortfolioStat(p, '${_myNfts.length}', 'NFTs'),
              _buildPortfolioStat(p, '${totalCost.toStringAsFixed(2)}', 'Investiert (ETH)'),
              _buildPortfolioStat(p, '${totalValue.toStringAsFixed(2)}', 'Aktuell (ETH)'),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        _buildSectionTitle(p, 'MEINE SAMMLUNG', Icons.collections),
        const SizedBox(height: 8),
        ..._myNfts.map((n) => _buildMyNftCard(p, n)),
      ],
    );
  }

  Widget _buildPortfolioStat(dynamic p, String val, String label) {
    return Expanded(
      child: Column(children: [
        Text(val, style: GoogleFonts.spaceMono(
          color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold,
        )),
        Text(label, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
      ]),
    );
  }

  Widget _buildMyNftCard(dynamic p, Map<String, dynamic> n) {
    final buy = n['buyPrice'] as double;
    final cur = n['currentPrice'] as double;
    final pnl = cur - buy;
    final pnlPct = (pnl / buy) * 100;
    final isPos = pnl >= 0;
    final color = n['color'] as Color;
    final rarityColor = _rarityColor(n['rarity'] as String);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(child: Text(n['emoji'] as String, style: const TextStyle(fontSize: 28))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(n['name'] as String, style: GoogleFonts.spaceMono(
            color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold,
          )),
          Text(n['collection'] as String, style: GoogleFonts.inter(
            color: p.textSecondary, fontSize: 10,
          )),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: rarityColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(n['rarity'] as String, style: GoogleFonts.spaceMono(
                color: rarityColor, fontSize: 8,
              )),
            ),
            const SizedBox(width: 6),
            Text('Rank #${n['rank']}', style: GoogleFonts.spaceMono(
              color: p.textSecondary, fontSize: 9,
            )),
          ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${cur >= 1 ? cur.toStringAsFixed(3) : cur.toStringAsFixed(5)} ETH', style: GoogleFonts.spaceMono(
            color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold,
          )),
          Text(
            '${isPos ? "+" : ""}${pnl.toStringAsFixed(3)} (${pnlPct.toStringAsFixed(1)}%)',
            style: GoogleFonts.spaceMono(
              color: isPos ? const Color(0xFF00FF88) : const Color(0xFFFF3358),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Row(children: [
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3358).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFF3358).withValues(alpha: 0.3)),
                ),
                child: Text('LISTEN', style: GoogleFonts.spaceMono(
                  color: const Color(0xFFFF3358), fontSize: 8, fontWeight: FontWeight.bold,
                )),
              ),
            ),
          ]),
        ]),
      ]),
    );
  }

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'Legendary': return const Color(0xFFFFAA00);
      case 'Epic': return const Color(0xFFAA44FF);
      case 'Rare': return const Color(0xFF00AAFF);
      case 'Uncommon': return const Color(0xFF00FF88);
      default: return const Color(0xFF888888);
    }
  }

  // ── WATCHLIST TAB ─────────────────────────────────────────
  Widget _buildWatchlistTab(dynamic p) {
    final watchlistCollections = _collections
        .where((c) => _watchlist.contains(c['name']))
        .toList();

    return watchlistCollections.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.star_border, color: p.textSecondary, size: 48),
            const SizedBox(height: 12),
            Text('Keine Watchlist-Einträge', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 14)),
            const SizedBox(height: 6),
            Text('Sammlungen mit ⭐ zur Watchlist hinzufügen', style: GoogleFonts.inter(
              color: p.textSecondary.withValues(alpha: 0.5), fontSize: 12,
            )),
          ]))
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildSectionTitle(p, 'WATCHLIST (${watchlistCollections.length})', Icons.star),
              const SizedBox(height: 8),
              ...watchlistCollections.map((c) => _buildCollectionRow(p, c)),
            ],
          );
  }

  // ── MINT TAB ─────────────────────────────────────────────
  Widget _buildMintTab(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionTitle(p, 'NFT MINTING', Icons.add_circle_outline),
        const SizedBox(height: 12),
        // Upcoming Mints
        _buildUpcomingMint(p, 'Quantum Genesis', '🌌', const Color(0xFF9945FF),
            'Morgen 18:00 UTC', '0.08 ETH', 5000, 4820),
        _buildUpcomingMint(p, 'Cyber Warriors', '⚔️', const Color(0xFF00AAFF),
            'In 3 Tagen', '0.15 ETH', 8888, 7234),
        _buildUpcomingMint(p, 'Solar Foxes', '🦊', const Color(0xFFFF6B00),
            'In 1 Woche', '0.05 SOL', 10000, 1200),
        const SizedBox(height: 16),
        // Create NFT
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.primary.withValues(alpha: 0.15)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('EIGENES NFT ERSTELLEN', style: GoogleFonts.spaceMono(
              color: p.primary, fontSize: 12, letterSpacing: 1,
            )),
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: p.primary.withValues(alpha: 0.15),
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_photo_alternate_outlined, color: p.textSecondary, size: 32),
                const SizedBox(height: 8),
                Text('Bild hochladen', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 12)),
              ])),
            ),
            const SizedBox(height: 12),
            _buildMintField(p, 'Name', 'z.B. Quantum Dragon #001'),
            const SizedBox(height: 8),
            _buildMintField(p, 'Beschreibung', 'Beschreibe dein NFT...'),
            const SizedBox(height: 8),
            _buildMintField(p, 'Royalties (%)', '5.0'),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('NFT Minting simuliert (Demo)', style: GoogleFonts.inter(color: Colors.white)),
                  backgroundColor: p.primary,
                ));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [p.primary, p.accent]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text('NFT MINTEN', style: GoogleFonts.spaceMono(
                  color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1,
                ))),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildUpcomingMint(dynamic p, String name, String emoji, Color color,
      String time, String price, int supply, int minted) {
    final progress = minted / supply;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.spaceMono(
              color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold,
            )),
            Text('$time · $price/NFT', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text('ERINNERN', style: GoogleFonts.spaceMono(
              color: color, fontSize: 8, fontWeight: FontWeight.bold,
            )),
          ),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$minted / $supply geminted', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
          Text('${(progress * 100).toStringAsFixed(0)}%', style: GoogleFonts.spaceMono(color: color, fontSize: 10)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: p.primary.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ]),
    );
  }

  Widget _buildMintField(dynamic p, String label, String hint) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: p.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: p.primary.withValues(alpha: 0.12)),
        ),
        child: Text(hint, style: GoogleFonts.inter(color: p.textSecondary.withValues(alpha: 0.5), fontSize: 12)),
      ),
    ]);
  }

  // ── HELPERS ───────────────────────────────────────────────
  Widget _buildSectionTitle(dynamic p, String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: p.primary, size: 14),
      const SizedBox(width: 6),
      Text(title, style: GoogleFonts.spaceMono(
        color: p.primary, fontSize: 10, letterSpacing: 1.2,
      )),
    ]);
  }
}

// ── Sparkline Painter ─────────────────────────────────────
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  const _SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final mn = data.reduce(min);
    final mx = data.reduce(max);
    final range = mx - mn;
    if (range == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((data[i] - mn) / range) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    // Gradient fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.data != data;
}
