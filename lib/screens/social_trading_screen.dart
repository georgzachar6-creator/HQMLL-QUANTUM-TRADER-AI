// ============================================================
// SOCIAL TRADING SCREEN v3 – Quantum Social Hub (v27.0)
// ExchangeService Live Prices · Copy Trading · Leaderboard · Live Signals
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';
import '../services/exchange_service.dart';

class SocialTradingScreen extends StatefulWidget {
  const SocialTradingScreen({super.key});
  @override
  State<SocialTradingScreen> createState() => _SocialTradingScreenState();
}

class _SocialTradingScreenState extends State<SocialTradingScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _pulseCtrl;
  Timer? _liveTimer;
  final _rand = Random();

  int _selectedTab = 0;
  final List<String> _tabs = ['LEADERBOARD', 'COPY TRADE', 'FEED', 'MY SIGNAL', 'STATS'];

  // Top Traders
  final List<Map<String, dynamic>> _traders = [
    {'rank': 1, 'name': 'QuantumWolf', 'avatar': 'QW', 'roi': 847.3, 'win': 91.2, 'followers': 12847, 'trades': 2341, 'style': 'SCALP', 'badge': 'LEGEND', 'pnl': 284700.0, 'copying': false},
    {'rank': 2, 'name': 'NexusMaster', 'avatar': 'NM', 'roi': 612.8, 'win': 87.4, 'followers': 8923, 'trades': 1847, 'style': 'SWING', 'badge': 'ELITE', 'pnl': 184200.0, 'copying': true},
    {'rank': 3, 'name': 'CryptoOracle9', 'avatar': 'CO', 'roi': 534.1, 'win': 84.9, 'followers': 6781, 'trades': 1234, 'style': 'ALGO', 'badge': 'PRO', 'pnl': 142800.0, 'copying': false},
    {'rank': 4, 'name': 'TR2Phantom', 'avatar': 'TP', 'roi': 478.6, 'win': 82.1, 'followers': 5420, 'trades': 984, 'style': 'AI', 'badge': 'PRO', 'pnl': 127300.0, 'copying': false},
    {'rank': 5, 'name': 'DeepAlpha', 'avatar': 'DA', 'roi': 391.2, 'win': 79.8, 'followers': 3847, 'trades': 762, 'style': 'SWING', 'badge': 'VERIFIED', 'pnl': 98400.0, 'copying': true},
    {'rank': 6, 'name': 'SatoshiSage', 'avatar': 'SS', 'roi': 284.7, 'win': 76.3, 'followers': 2341, 'trades': 584, 'style': 'HOLD', 'badge': 'VERIFIED', 'pnl': 71200.0, 'copying': false},
    {'rank': 7, 'name': 'FlashTrader', 'avatar': 'FT', 'roi': 241.9, 'win': 74.1, 'followers': 1847, 'trades': 4782, 'style': 'HFT', 'badge': 'VERIFIED', 'pnl': 58400.0, 'copying': false},
    {'rank': 8, 'name': 'BlockchainBull', 'avatar': 'BB', 'roi': 198.4, 'win': 71.2, 'followers': 1284, 'trades': 328, 'style': 'SWING', 'badge': 'VERIFIED', 'pnl': 44700.0, 'copying': false},
  ];

  // Copy Trade settings
  double _copyAmount = 500.0;
  bool _autoCopy = false;
  double _maxRisk = 2.0;
  final bool _copyingNexus = true; // ignore: unused_field
  final bool _copyingDeepAlpha = true; // ignore: unused_field

  // Community feed
  final List<Map<String, dynamic>> _feed = [
    {'user': 'QuantumWolf', 'avatar': 'QW', 'time': '2m ago', 'type': 'SIGNAL', 'text': '🚀 BTC LONG entry at \$67,840 – targeting \$71,200. AI confidence 91.4%. R:R 1:2.1', 'likes': 847, 'comments': 124, 'badge': 'LEGEND'},
    {'user': 'NexusMaster', 'avatar': 'NM', 'time': '7m ago', 'type': 'TRADE', 'text': '✅ ETH LONG closed +\$2,847 profit! Entered at \$3,380, exited at \$3,420. Another win for the books 📈', 'likes': 423, 'comments': 67, 'badge': 'ELITE'},
    {'user': 'CryptoOracle9', 'avatar': 'CO', 'time': '15m ago', 'type': 'ANALYSIS', 'text': '📊 BTC Weekly Outlook: Bull flag forming on 4H. Support at \$66K holding strong. Expecting breakout to \$72-75K range within 72h. NFA.', 'likes': 621, 'comments': 89, 'badge': 'PRO'},
    {'user': 'TR2Phantom', 'avatar': 'TP', 'time': '28m ago', 'type': 'SIGNAL', 'text': '⚡ SOL SHORT confirmed by TR2 neural model. Entry \$178.4, TP \$162, SL \$186. Model accuracy 94.2%', 'likes': 312, 'comments': 41, 'badge': 'PRO'},
    {'user': 'DeepAlpha', 'avatar': 'DA', 'time': '1h ago', 'type': 'ANALYSIS', 'text': '🧠 Market structure update: Risk-off mood fading. AI models detecting accumulation patterns in top 10 alts. Watch AVAX, DOT, LINK.', 'likes': 284, 'comments': 37, 'badge': 'VERIFIED'},
  ];

  // My signal stats
  double _myRoi = 142.8;
  int _myFollowers = 284;
  final int _myTrades = 127;
  final double _myWinRate = 73.4;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _liveTimer = Timer.periodic(const Duration(seconds: 3), (_) => _updateLive());
  }

  void _updateLive() {
    if (!mounted) return;
    setState(() {
      _myRoi += (_rand.nextDouble() - 0.45) * 0.5;
      _myFollowers += _rand.nextInt(3);
      for (var t in _traders) {
        t['roi'] = (t['roi'] as double) + (_rand.nextDouble() - 0.48) * 0.3;
        t['followers'] = (t['followers'] as int) + _rand.nextInt(5);
        // Update trader PnL based on ROI
        t['pnl'] = (t['pnl'] as double) * (1 + (_rand.nextDouble() - 0.48) * 0.001);
      }
      // Update feed likes
      for (var f in _feed) {
        f['likes'] = (f['likes'] as int) + _rand.nextInt(3);
      }
    });
  }

  /// v27.0: Update feed signals with live ExchangeService prices
  void _updateFeedWithLivePrices(ExchangeService ex) {
    final btcPrice = ex.getPrice('BTC');
    final ethPrice = ex.getPrice('ETH');
    final solPrice = ex.getPrice('SOL');
    if (btcPrice > 0 && _feed.isNotEmpty) {
      // Refresh live price context in signal text (first signal only for performance)
      if (_feed[0]['type'] == 'SIGNAL' && !_feed[0]['priceUpdated']) {
        _feed[0]['livePrice'] = btcPrice;
        _feed[0]['ethPrice'] = ethPrice;
        _feed[0]['solPrice'] = solPrice;
      }
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _pulseCtrl.dispose();
    _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    // v27.0: ExchangeService live prices for signal context
    final ex = context.watch<ExchangeService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateFeedWithLivePrices(ex);
    });
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(p, ex),
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

  Widget _buildHeader(QuantumPalette p, ExchangeService ex) {
    final btcPrice = ex.getPrice('BTC');
    final btcTick = ex.getTick('BTC');
    final isLive = btcTick?.isLive ?? false;
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            p.background,
            p.secondary.withValues(alpha: 0.08),
          ]),
          border: Border(bottom: BorderSide(
            color: p.secondary.withValues(alpha: 0.3 + _glowCtrl.value * 0.2),
          )),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  p.secondary.withValues(alpha: 0.4 + _glowCtrl.value * 0.3),
                  p.secondary.withValues(alpha: 0.1),
                ]),
                boxShadow: [BoxShadow(color: p.secondary.withValues(alpha: 0.5), blurRadius: 16)],
              ),
              child: Icon(Icons.people, color: p.secondary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SOCIAL TRADING', style: GoogleFonts.orbitron(
                  color: p.primary, fontSize: 16, fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: p.primary.withValues(alpha: 0.5), blurRadius: 8)],
                )),
                Row(children: [
                  Text('Community · Copy Trade · Signals', style: GoogleFonts.rajdhani(
                    color: p.textSecondary, fontSize: 11,
                  )),
                  if (btcPrice > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      'BTC \$${btcPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.spaceMono(
                        color: isLive ? const Color(0xFF00FF88) : const Color(0xFFFFAA00),
                        fontSize: 9, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ]),
              ]),
            ),
            _buildHeaderBadge(p, Icons.people_alt, '${_traders.fold<int>(0, (a, b) => a + (b['followers'] as int))}', 'FOLLOWERS', p.primary),
            const SizedBox(width: 8),
            _buildHeaderBadge(p, Icons.copy, '2', 'COPYING', p.accent),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(QuantumPalette p, IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
        ]),
      ]),
    );
  }

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
              child: Center(child: Text(_tabs[i], style: GoogleFonts.orbitron(
                color: sel ? p.primary : p.textSecondary,
                fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              ))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent(QuantumPalette p) {
    switch (_selectedTab) {
      case 0: return _buildLeaderboard(p);
      case 1: return _buildCopyTrade(p);
      case 2: return _buildFeed(p);
      case 3: return _buildMySignal(p);
      case 4: return _buildStats(p);
      default: return _buildLeaderboard(p);
    }
  }

  // ── LEADERBOARD ──
  Widget _buildLeaderboard(QuantumPalette p) {
    return ListView(
      key: const ValueKey('lb'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildLeaderboardHeader(p),
        const SizedBox(height: 10),
        ..._traders.asMap().entries.map((e) => _buildTraderCard(p, e.value, e.key)),
      ],
    );
  }

  Widget _buildLeaderboardHeader(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          p.primary.withValues(alpha: 0.1),
          p.accent.withValues(alpha: 0.05),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOP TRADERS', style: GoogleFonts.orbitron(
                color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold,
              )),
              Text('${_traders.length} verified traders · Updated live',
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('30D PERIOD', style: GoogleFonts.orbitron(
              color: p.primary, fontSize: 10, fontWeight: FontWeight.bold,
            )),
            Text('All pairs', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
          ]),
        ],
      ),
    );
  }

  Widget _buildTraderCard(QuantumPalette p, Map<String, dynamic> t, int idx) {
    final rankColors = [Colors.amber, Colors.grey.shade300, const Color(0xFFCD7F32)];
    final rankColor = idx < 3 ? rankColors[idx] : p.textSecondary;
    final badgeColors = {
      'LEGEND': const Color(0xFFFFAA00),
      'ELITE': p.primary,
      'PRO': p.accent,
      'VERIFIED': p.positive,
    };
    final badgeColor = badgeColors[t['badge']] ?? p.textSecondary;
    final isCopying = t['copying'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: idx < 3
            ? rankColor.withValues(alpha: 0.05)
            : p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: idx < 3 ? rankColor.withValues(alpha: 0.4) : p.surface.withValues(alpha: 0.6),
          width: idx < 3 ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rank
              SizedBox(
                width: 28,
                child: Text('#${t['rank']}', style: GoogleFonts.orbitron(
                  color: rankColor, fontSize: 12, fontWeight: FontWeight.bold,
                )),
              ),
              // Avatar
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    rankColor.withValues(alpha: 0.3),
                    rankColor.withValues(alpha: 0.08),
                  ]),
                  border: Border.all(color: rankColor.withValues(alpha: 0.5)),
                ),
                child: Center(child: Text(t['avatar'], style: GoogleFonts.orbitron(
                  color: rankColor, fontSize: 11, fontWeight: FontWeight.bold,
                ))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(t['name'], style: GoogleFonts.rajdhani(
                      color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold,
                    )),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(t['badge'], style: GoogleFonts.rajdhani(
                        color: badgeColor, fontSize: 8, fontWeight: FontWeight.bold,
                      )),
                    ),
                  ]),
                  Text('${t['style']} · ${t['trades']} trades · ${_formatNumber(t['followers'])} followers',
                    style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
                ]),
              ),
              // ROI
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('+${(t['roi'] as double).toStringAsFixed(1)}%', style: GoogleFonts.orbitron(
                  color: p.positive, fontSize: 14, fontWeight: FontWeight.bold,
                )),
                Text('ROI 30D', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildTraderStat(p, 'WIN RATE', '${(t['win'] as double).toStringAsFixed(1)}%', p.positive)),
              Expanded(child: _buildTraderStat(p, 'P&L', '\$${_formatNumber(t['pnl'])}', p.positive)),
              Expanded(child: _buildTraderStat(p, 'FOLLOWERS', _formatNumber(t['followers']), p.primary)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => t['copying'] = !(t['copying'] as bool)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isCopying ? LinearGradient(colors: [p.primary.withValues(alpha: 0.4), p.accent.withValues(alpha: 0.2)]) : null,
                    color: isCopying ? null : p.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isCopying ? p.primary : p.textSecondary.withValues(alpha: 0.4)),
                  ),
                  child: Text(isCopying ? 'COPYING' : 'COPY', style: GoogleFonts.orbitron(
                    color: isCopying ? p.primary : p.textSecondary,
                    fontSize: 9, fontWeight: FontWeight.bold,
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTraderStat(QuantumPalette p, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── COPY TRADE ──
  Widget _buildCopyTrade(QuantumPalette p) {
    final copying = _traders.where((t) => t['copying'] == true).toList();
    return ListView(
      key: const ValueKey('copy'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildCopySettings(p),
        const SizedBox(height: 12),
        Text('ACTIVE COPY POSITIONS', style: GoogleFonts.orbitron(
          color: p.primary, fontSize: 11, fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 8),
        if (copying.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('No active copy positions.\nSelect a trader to start copying.',
              style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 14),
              textAlign: TextAlign.center),
          ))
        else
          ...copying.map((t) => _buildCopyPosition(p, t)),
        const SizedBox(height: 12),
        _buildCopyPerformance(p),
      ],
    );
  }

  Widget _buildCopySettings(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.settings_remote, color: p.accent, size: 16),
            const SizedBox(width: 8),
            Text('COPY SETTINGS', style: GoogleFonts.orbitron(
              color: p.accent, fontSize: 11, fontWeight: FontWeight.bold,
            )),
          ]),
          const SizedBox(height: 14),
          // Copy Amount
          Row(children: [
            Text('Copy Amount per Trade', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 12)),
            const Spacer(),
            Text('\$${_copyAmount.toStringAsFixed(0)}', style: GoogleFonts.orbitron(
              color: p.primary, fontSize: 13, fontWeight: FontWeight.bold,
            )),
          ]),
          SliderTheme(
            data: SliderThemeData(thumbColor: p.primary, activeTrackColor: p.primary, inactiveTrackColor: p.surface),
            child: Slider(
              value: _copyAmount,
              min: 50,
              max: 5000,
              divisions: 99,
              onChanged: (v) => setState(() => _copyAmount = v),
            ),
          ),
          // Max Risk
          Row(children: [
            Text('Max Risk per Trade', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 12)),
            const Spacer(),
            Text('${_maxRisk.toStringAsFixed(1)}%', style: GoogleFonts.orbitron(
              color: p.negative, fontSize: 13, fontWeight: FontWeight.bold,
            )),
          ]),
          SliderTheme(
            data: SliderThemeData(thumbColor: p.negative, activeTrackColor: p.negative, inactiveTrackColor: p.surface),
            child: Slider(
              value: _maxRisk,
              min: 0.5,
              max: 10.0,
              divisions: 19,
              onChanged: (v) => setState(() => _maxRisk = v),
            ),
          ),
          // Auto Copy Toggle
          Row(children: [
            Text('Auto Copy New Signals', style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 12)),
            const Spacer(),
            Switch(
              value: _autoCopy,
              onChanged: (v) => setState(() => _autoCopy = v),
              activeThumbColor: p.primary,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildCopyPosition(QuantumPalette p, Map<String, dynamic> t) {
    final pnl = (_rand.nextDouble() - 0.3) * 200;
    final isProfit = pnl >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.primary.withValues(alpha: 0.15),
              border: Border.all(color: p.primary.withValues(alpha: 0.4)),
            ),
            child: Center(child: Text(t['avatar'], style: GoogleFonts.orbitron(
              color: p.primary, fontSize: 10, fontWeight: FontWeight.bold,
            ))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t['name'], style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              Text('Allocated: \$${_copyAmount.toStringAsFixed(0)} · Risk: ${_maxRisk.toStringAsFixed(1)}%',
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${isProfit ? '+' : ''}\$${pnl.toStringAsFixed(2)}', style: GoogleFonts.orbitron(
              color: isProfit ? p.positive : p.negative,
              fontSize: 12, fontWeight: FontWeight.bold,
            )),
            Text('Today P&L', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
          ]),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => t['copying'] = false),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: p.negative.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: p.negative.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.stop, color: p.negative, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyPerformance(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.positive.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.analytics, color: p.positive, size: 16),
            const SizedBox(width: 8),
            Text('COPY PERFORMANCE', style: GoogleFonts.orbitron(
              color: p.positive, fontSize: 11, fontWeight: FontWeight.bold,
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildPerfStat(p, 'Total Copied', '\$24,800', p.primary)),
            Expanded(child: _buildPerfStat(p, 'Total Profit', '+\$3,847', p.positive)),
            Expanded(child: _buildPerfStat(p, 'Best Trade', '+\$892', p.positive)),
            Expanded(child: _buildPerfStat(p, 'Win Rate', '74.2%', p.positive)),
          ]),
        ],
      ),
    );
  }

  Widget _buildPerfStat(QuantumPalette p, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
      ],
    );
  }

  // ── FEED ──
  Widget _buildFeed(QuantumPalette p) {
    return ListView(
      key: const ValueKey('feed'),
      padding: const EdgeInsets.all(12),
      children: _feed.map((f) => _buildFeedPost(p, f)).toList(),
    );
  }

  Widget _buildFeedPost(QuantumPalette p, Map<String, dynamic> f) {
    final typeColors = {'SIGNAL': p.positive, 'TRADE': p.primary, 'ANALYSIS': p.accent};
    final typeColor = typeColors[f['type']] ?? p.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: typeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: typeColor.withValues(alpha: 0.15),
                  border: Border.all(color: typeColor.withValues(alpha: 0.4)),
                ),
                child: Center(child: Text(f['avatar'], style: GoogleFonts.orbitron(
                  color: typeColor, fontSize: 10, fontWeight: FontWeight.bold,
                ))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(f['user'], style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(f['type'], style: GoogleFonts.rajdhani(
                        color: typeColor, fontSize: 8, fontWeight: FontWeight.bold,
                      )),
                    ),
                  ]),
                  Text(f['time'], style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
                ],
              )),
              Icon(Icons.more_horiz, color: p.textSecondary, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(f['text'], style: GoogleFonts.rajdhani(
            color: p.textPrimary, fontSize: 12, height: 1.5,
          )),
          const SizedBox(height: 10),
          Row(children: [
            _buildFeedAction(p, Icons.thumb_up_outlined, '${f['likes']}', p.primary),
            const SizedBox(width: 16),
            _buildFeedAction(p, Icons.chat_bubble_outline, '${f['comments']}', p.accent),
            const Spacer(),
            _buildFeedAction(p, Icons.share_outlined, 'Share', p.textSecondary),
          ]),
        ],
      ),
    );
  }

  Widget _buildFeedAction(QuantumPalette p, IconData icon, String label, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 15),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.rajdhani(color: color, fontSize: 11)),
    ]);
  }

  // ── MY SIGNAL ──
  Widget _buildMySignal(QuantumPalette p) {
    return ListView(
      key: const ValueKey('mysignal'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildMyProfile(p),
        const SizedBox(height: 12),
        _buildMyPerformance(p),
        const SizedBox(height: 12),
        _buildPostSignalForm(p),
      ],
    );
  }

  Widget _buildMyProfile(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          p.primary.withValues(alpha: 0.1),
          p.accent.withValues(alpha: 0.05),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                p.primary.withValues(alpha: 0.4),
                p.primary.withValues(alpha: 0.1),
              ]),
              border: Border.all(color: p.primary.withValues(alpha: 0.6), width: 2),
            ),
            child: Center(child: Text('ME', style: GoogleFonts.orbitron(
              color: p.primary, fontSize: 14, fontWeight: FontWeight.bold,
            ))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Trader Profile', style: GoogleFonts.rajdhani(
                color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.bold,
              )),
              Text('VERIFIED · Signal Provider',
                style: GoogleFonts.orbitron(color: p.positive, fontSize: 9)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('+${_myRoi.toStringAsFixed(1)}%', style: GoogleFonts.orbitron(
              color: p.positive, fontSize: 16, fontWeight: FontWeight.bold,
            )),
            Text('Total ROI', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
          ]),
        ],
      ),
    );
  }

  Widget _buildMyPerformance(QuantumPalette p) {
    return Row(
      children: [
        Expanded(child: _buildMyStatCard(p, 'FOLLOWERS', '$_myFollowers', p.primary, Icons.people)),
        const SizedBox(width: 8),
        Expanded(child: _buildMyStatCard(p, 'TRADES', '$_myTrades', p.accent, Icons.swap_horiz)),
        const SizedBox(width: 8),
        Expanded(child: _buildMyStatCard(p, 'WIN RATE', '${_myWinRate.toStringAsFixed(1)}%', p.positive, Icons.trending_up)),
        const SizedBox(width: 8),
        Expanded(child: _buildMyStatCard(p, 'AVG R:R', '1:2.1', p.primary, Icons.balance)),
      ],
    );
  }

  Widget _buildMyStatCard(QuantumPalette p, String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
      ]),
    );
  }

  Widget _buildPostSignalForm(QuantumPalette p) {
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
            Icon(Icons.post_add, color: p.primary, size: 16),
            const SizedBox(width: 8),
            Text('POST NEW SIGNAL', style: GoogleFonts.orbitron(
              color: p.primary, fontSize: 11, fontWeight: FontWeight.bold,
            )),
          ]),
          const SizedBox(height: 12),
          _buildFormField(p, 'Pair', 'e.g. BTC/USDT'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _buildFormField(p, 'Entry Price', '\$67,840')),
            const SizedBox(width: 8),
            Expanded(child: _buildFormField(p, 'Take Profit', '\$71,200')),
            const SizedBox(width: 8),
            Expanded(child: _buildFormField(p, 'Stop Loss', '\$66,100')),
          ]),
          const SizedBox(height: 8),
          _buildFormField(p, 'Analysis', 'Share your market analysis...'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: p.primary.withValues(alpha: 0.2),
                side: BorderSide(color: p.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {},
              child: Text('PUBLISH SIGNAL', style: GoogleFonts.orbitron(
                color: p.primary, fontSize: 11, fontWeight: FontWeight.bold,
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(QuantumPalette p, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: p.background.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: p.primary.withValues(alpha: 0.2)),
          ),
          child: Text(hint, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 12)),
        ),
      ],
    );
  }

  // ── STATS ──
  Widget _buildStats(QuantumPalette p) {
    return ListView(
      key: const ValueKey('stats'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildGlobalStats(p),
        const SizedBox(height: 12),
        _buildTopPairsCard(p),
        const SizedBox(height: 12),
        _buildActivityCard(p),
      ],
    );
  }

  Widget _buildGlobalStats(QuantumPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PLATFORM STATISTICS', style: GoogleFonts.orbitron(
          color: p.primary, fontSize: 11, fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _buildGlobalStatCard(p, 'Total Traders', '12,847', p.primary, Icons.person)),
          const SizedBox(width: 8),
          Expanded(child: _buildGlobalStatCard(p, 'Signals Today', '3,421', p.positive, Icons.flash_on)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _buildGlobalStatCard(p, 'Volume Copied', '\$8.4M', p.accent, Icons.copy)),
          const SizedBox(width: 8),
          Expanded(child: _buildGlobalStatCard(p, 'Avg Win Rate', '73.8%', p.positive, Icons.trending_up)),
        ]),
      ],
    );
  }

  Widget _buildGlobalStatCard(QuantumPalette p, String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
          ],
        )),
      ]),
    );
  }

  Widget _buildTopPairsCard(QuantumPalette p) {
    final pairs = ['BTC/USDT', 'ETH/USDT', 'SOL/USDT', 'BNB/USDT', 'AVAX/USDT'];
    final counts = [847, 623, 412, 384, 271];
    final max = counts[0].toDouble();
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
          Text('TOP TRADED PAIRS', style: GoogleFonts.orbitron(
            color: p.primary, fontSize: 11, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 12),
          ...List.generate(pairs.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              SizedBox(width: 90, child: Text(pairs[i], style: GoogleFonts.rajdhani(
                color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold,
              ))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: counts[i] / max,
                    backgroundColor: p.surface,
                    valueColor: AlwaysStoppedAnimation(p.primary.withValues(alpha: 0.7 - i * 0.1)),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${counts[i]} signals', style: GoogleFonts.rajdhani(
                color: p.textSecondary, fontSize: 10,
              )),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildActivityCard(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('24H ACTIVITY', style: GoogleFonts.orbitron(
            color: p.accent, fontSize: 11, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildActStat(p, 'New Traders', '+247', p.positive)),
            Expanded(child: _buildActStat(p, 'Signals Posted', '3,421', p.primary)),
            Expanded(child: _buildActStat(p, 'Trades Closed', '8,847', p.accent)),
            Expanded(child: _buildActStat(p, 'Profitable', '74.2%', p.positive)),
          ]),
        ],
      ),
    );
  }

  Widget _buildActStat(QuantumPalette p, String label, String value, Color color) {
    return Column(children: [
      Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
    ]);
  }

  // Helpers
  String _formatNumber(dynamic n) {
    if (n is double) {
      if (n >= 1000000) return '\$${(n / 1000000).toStringAsFixed(1)}M';
      if (n >= 1000) return '\$${(n / 1000).toStringAsFixed(1)}K';
      return n.toStringAsFixed(0);
    }
    if (n is int) {
      if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
      if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
      return n.toString();
    }
    return n.toString();
  }
}
