// ============================================================
// CONNECTOR SCREEN v40.1 – Quantum Trader
// Broker · Exchange · Data-Source Manager
// Binance · Coinbase · Kraken · Bybit · OKX
// CoinGecko · CoinMarketCap · TradingView
// v40.1: SystemLog + WS-Config persistent
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/crypto_icon.dart';

import '../providers/theme_provider.dart';
import '../providers/live_price_provider.dart';
import '../services/persistence_service.dart';
import '../services/exchange_service.dart';
import '../services/websocket_service.dart';

class ConnectorScreen extends StatefulWidget {
  const ConnectorScreen({super.key});
  @override
  State<ConnectorScreen> createState() => _ConnectorScreenState();
}

class _ConnectorScreenState extends State<ConnectorScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _pulseCtrl;
  Timer? _refreshTimer;

  int _selectedTab = 0;
  final List<String> _tabs = ['EXCHANGES', 'DATA FEEDS', 'BROKER API', 'EINSTELLUNGEN'];

  // API Keys (simulated - masked)
  final Map<String, Map<String, String>> _apiKeys = {
    'binance': {'key': '****...****8X4F', 'secret': '****...****kQ2P', 'status': 'active'},
    'coinbase': {'key': '', 'secret': '', 'status': 'inactive'},
    'kraken': {'key': '', 'secret': '', 'status': 'inactive'},
    'bybit': {'key': '****...****7R3A', 'secret': '****...****mP9K', 'status': 'active'},
    'okx': {'key': '', 'secret': '', 'status': 'inactive'},
  };

  final Map<String, String> _dataApiKeys = {
    'coingecko': '',      // Free API
    'coinmarketcap': '',  // Needs Pro key
    'tradingview': '',    // Widget (no key needed)
  };

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);

    // v35.0: ExchangeService + LivePriceProvider beide initialisieren
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ex = context.read<ExchangeService>();
      await ex.initialize();
      if (mounted) {
        final lp = context.read<LivePriceProvider>();
        await lp.initialize();
        // v40.1: SystemLog WS connection event
        final ps = context.read<PersistenceService>();
        ps.addSystemLog('WS',
            'Connector initialisiert — Binance WS: ${ex.wsConnected ? "AKTIV" : "GETRENNT"}',
            level: ex.wsConnected ? SysLogLevel.success : SysLogLevel.warning);
        // v40.1: Persist WS config snapshot
        await ps.saveWsConfig(ps.wsConfig);
      }
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _pulseCtrl.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    final lp = context.watch<LivePriceProvider>();
    // v35.0: ExchangeService als primäre WS-Quelle
    final ex = context.watch<ExchangeService>();
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(p, lp, ex),
          _buildTabs(p),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildExchangesTab(p, lp),
                _buildDataFeedsTab(p, lp),
                _buildBrokerApiTab(p, lp),
                _buildSettingsTab(p, lp),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────
  Widget _buildHeader(dynamic p, LivePriceProvider lp, ExchangeService ex) {
    // v35.0: ExchangeService als primäre WS-Quelle, LP als Fallback
    final wsConnected = ex.wsConnected || lp.wsConnected;
    final connCount = ex.wsConnected ? (lp.connectedExchanges > 0 ? lp.connectedExchanges : 1) : lp.connectedExchanges;
    final tps = lp.ticksPerSecond;
    final totalTicks = ex.ticks.isNotEmpty ? ex.ticks.length + lp.totalTicks : lp.totalTicks;

    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(bottom: BorderSide(
            color: p.primary.withValues(alpha: 0.12 + _glowCtrl.value * 0.08),
          )),
        ),
        child: Column(children: [
          Row(children: [
            Icon(Icons.hub_rounded, color: p.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CONNECTOR HUB', style: GoogleFonts.spaceMono(
                  color: p.primary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2,
                )),
                Text('Exchange · Data · Broker Verbindungen', style: GoogleFonts.inter(
                  color: p.textSecondary, fontSize: 11,
                )),
              ]),
            ),
            _buildConnectionBadge(p, wsConnected, connCount, tps),
          ]),
          const SizedBox(height: 10),
          // Stats Row
          Row(children: [
            _buildStatChip(p, 'BÖRSEN', '$connCount / 5', const Color(0xFF00FF88)),
            const SizedBox(width: 8),
            _buildStatChip(p, 'TICKS/S', '$tps', const Color(0xFF00AAFF)),
            const SizedBox(width: 8),
            _buildStatChip(p, 'GESAMT', _formatCount(totalTicks), const Color(0xFFAA88FF)),
            const SizedBox(width: 8),
            _buildStatChip(p, 'ASSETS', '${ex.ticks.isNotEmpty ? ex.ticks.length : lp.quotes.length}', const Color(0xFFFFAA00)),
          ]),
        ]),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Widget _buildConnectionBadge(dynamic p, bool connected, int count, int tps) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: connected
              ? const Color(0xFF00FF88).withValues(alpha: 0.08 + _pulseCtrl.value * 0.04)
              : const Color(0xFFFFAA00).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: connected
                ? const Color(0xFF00FF88).withValues(alpha: 0.3 + _pulseCtrl.value * 0.2)
                : const Color(0xFFFFAA00).withValues(alpha: 0.3),
          ),
        ),
        child: Row(children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: connected ? const Color(0xFF00FF88) : const Color(0xFFFFAA00),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: (connected ? const Color(0xFF00FF88) : const Color(0xFFFFAA00))
                    .withValues(alpha: 0.4 + _pulseCtrl.value * 0.3),
                blurRadius: 6,
              )],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'WS LIVE' : 'REST',
            style: GoogleFonts.spaceMono(
              color: connected ? const Color(0xFF00FF88) : const Color(0xFFFFAA00),
              fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStatChip(dynamic p, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(children: [
          Text(label, style: GoogleFonts.spaceMono(color: color.withValues(alpha: 0.6), fontSize: 7, letterSpacing: 0.5)),
          Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  // ── TABS ─────────────────────────────────────────────────
  Widget _buildTabs(dynamic p) {
    return Container(
      height: 36,
      color: p.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _tabs.length,
        itemBuilder: (context, i) {
          final sel = _selectedTab == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: Container(
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: sel ? p.primary.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: sel ? p.primary.withValues(alpha: 0.4) : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(_tabs[i], style: GoogleFonts.spaceMono(
                  color: sel ? p.primary : p.textSecondary,
                  fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 0.5,
                )),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── EXCHANGES TAB ────────────────────────────────────────
  Widget _buildExchangesTab(dynamic p, LivePriceProvider lp) {
    final statuses = lp.exchangeStatuses;

    final exchanges = [
      {
        'id': 'binance', 'name': 'Binance', 'icon': '🟡', 'color': const Color(0xFFF0B90B),
        'desc': 'Spot · Futures · Options', 'wsUrl': 'wss://stream.binance.com:9443',
        'pairs': 1800, 'vol': '\$45.2B',
      },
      {
        'id': 'coinbase', 'name': 'Coinbase', 'icon': '🔵', 'color': const Color(0xFF0052FF),
        'desc': 'Spot · Advanced Trade', 'wsUrl': 'wss://advanced-trade-ws.coinbase.com',
        'pairs': 520, 'vol': '\$4.8B',
      },
      {
        'id': 'kraken', 'name': 'Kraken', 'icon': '🟣', 'color': const Color(0xFF5741D9),
        'desc': 'Spot · Futures · Margin', 'wsUrl': 'wss://ws.kraken.com',
        'pairs': 680, 'vol': '\$2.1B',
      },
      {
        'id': 'bybit', 'name': 'Bybit', 'icon': '🟠', 'color': const Color(0xFFF7A600),
        'desc': 'Spot · Derivatives · Copy', 'wsUrl': 'wss://stream.bybit.com/v5',
        'pairs': 1200, 'vol': '\$12.4B',
      },
      {
        'id': 'okx', 'name': 'OKX', 'icon': '⚫', 'color': const Color(0xFF00AAFF),
        'desc': 'Spot · Futures · DeFi', 'wsUrl': 'wss://ws.okx.com:8443/ws/v5',
        'pairs': 980, 'vol': '\$8.7B',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionHeader(p, 'WEBSOCKET VERBINDUNGEN', Icons.swap_horiz),
        const SizedBox(height: 8),
        ...exchanges.map((ex) {
          final id = ex['id'] as String;
          final status = statuses[id] ?? ExchangeStatus.disconnected;
          final color = ex['color'] as Color;
          return _buildExchangeCard(p, ex, status, color, lp);
        }),
        const SizedBox(height: 16),
        _buildStreamStats(p, lp),
      ],
    );
  }

  Widget _buildExchangeCard(
    dynamic p,
    Map<String, dynamic> ex,
    ExchangeStatus status,
    Color color,
    LivePriceProvider lp,
  ) {
    final isConnected = status == ExchangeStatus.connected;
    final isConnecting = status == ExchangeStatus.connecting;
    final statusColor = isConnected
        ? const Color(0xFF00FF88)
        : isConnecting
            ? const Color(0xFFFFAA00)
            : p.textSecondary;

    final statusLabel = isConnected
        ? 'VERBUNDEN'
        : isConnecting
            ? 'VERBINDE...'
            : status == ExchangeStatus.error
                ? 'FEHLER'
                : status == ExchangeStatus.rateLimit
                    ? 'RATE LIMIT'
                    : 'GETRENNT';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected
              ? color.withValues(alpha: 0.3)
              : p.primary.withValues(alpha: 0.08),
        ),
        boxShadow: isConnected
            ? [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12)]
            : null,
      ),
      child: Column(children: [
        // Header Row
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            // Icon
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Center(child: Text(ex['icon'] as String, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            // Name & Description
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ex['name'] as String, style: GoogleFonts.spaceMono(
                color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold,
              )),
              Text(ex['desc'] as String, style: GoogleFonts.inter(
                color: p.textSecondary, fontSize: 11,
              )),
              Text(ex['wsUrl'] as String, style: GoogleFonts.spaceMono(
                color: p.textSecondary.withValues(alpha: 0.5), fontSize: 9,
              )),
            ])),
            // Status
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(statusLabel, style: GoogleFonts.spaceMono(
                    color: statusColor, fontSize: 8, letterSpacing: 0.5,
                  )),
                ]),
              ),
              const SizedBox(height: 4),
              // Toggle
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  lp.toggleExchange(ex['id'] as String, !isConnected);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? const Color(0xFFFF3358).withValues(alpha: 0.1)
                        : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isConnected
                          ? const Color(0xFFFF3358).withValues(alpha: 0.3)
                          : color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isConnected ? 'TRENNEN' : 'VERBINDEN',
                    style: GoogleFonts.spaceMono(
                      color: isConnected ? const Color(0xFFFF3358) : color,
                      fontSize: 8, fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ),
        // Stats Row
        Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: p.primary.withValues(alpha: 0.06))),
          ),
          child: Row(children: [
            _buildMiniStat(p, 'PAARE', '${ex['pairs']}', color),
            const SizedBox(width: 8),
            _buildMiniStat(p, '24H VOL', ex['vol'] as String, color),
            const SizedBox(width: 8),
            _buildMiniStat(p, 'STATUS', isConnected ? 'AKTIV' : 'INAKTIV',
                isConnected ? const Color(0xFF00FF88) : p.textSecondary),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMiniStat(dynamic p, String label, String value, Color color) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.spaceMono(
          color: p.textSecondary.withValues(alpha: 0.5), fontSize: 8, letterSpacing: 0.5,
        )),
        Text(value, style: GoogleFonts.spaceMono(
          color: color, fontSize: 10, fontWeight: FontWeight.bold,
        )),
      ]),
    );
  }

  Widget _buildStreamStats(dynamic p, LivePriceProvider lp) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STREAM STATISTIKEN', style: GoogleFonts.spaceMono(
          color: p.primary, fontSize: 11, letterSpacing: 1,
        )),
        const SizedBox(height: 12),
        _buildStatRow(p, 'Verbundene Börsen', '${lp.connectedExchanges} / 5'),
        _buildStatRow(p, 'Ticks pro Sekunde', '${lp.ticksPerSecond}'),
        _buildStatRow(p, 'Gesamt Ticks', _formatCount(lp.totalTicks)),
        _buildStatRow(p, 'Geladene Assets', '${lp.quotes.length}'),
        _buildStatRow(p, 'WebSocket Status', lp.wsConnected ? '✅ Aktiv' : '⚠️ Getrennt'),
        _buildStatRow(p, 'CoinGecko Status', lp.geckoActive ? '✅ Aktiv' : '○ Inaktiv'),
        _buildStatRow(p, 'CMC Status', lp.cmcActive ? '✅ Aktiv' : '○ Inaktiv'),
        if (lp.lastTickTime != null)
          _buildStatRow(p, 'Letzter Tick', '${DateTime.now().difference(lp.lastTickTime!).inMilliseconds}ms ago'),
      ]),
    );
  }

  Widget _buildStatRow(dynamic p, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label, style: GoogleFonts.inter(
          color: p.textSecondary, fontSize: 12,
        ))),
        Text(value, style: GoogleFonts.spaceMono(
          color: p.textPrimary, fontSize: 11,
        )),
      ]),
    );
  }

  // ── DATA FEEDS TAB ───────────────────────────────────────
  Widget _buildDataFeedsTab(dynamic p, LivePriceProvider lp) {
    final feeds = [
      {
        'id': 'coingecko', 'name': 'CoinGecko', 'icon': '🦎',
        'color': const Color(0xFF8DC63F), 'type': 'REST + WS',
        'status': lp.geckoActive, 'interval': '45s',
        'features': ['Marktpreise', 'OHLCV', 'Sparklines', 'Trending'],
        'apiNeeded': false, 'plan': 'Free / Pro',
        'rateLimit': '10-50 req/min',
        'docs': 'api.coingecko.com',
        'restUrl': 'https://api.coingecko.com/api/v3',
        'wsUrl': 'wss://stream.coingecko.com/api/v3/ws',
      },
      {
        'id': 'coinmarketcap', 'name': 'CoinMarketCap', 'icon': '📊',
        'color': const Color(0xFF1652F0), 'type': 'REST API',
        'status': lp.cmcActive, 'interval': '60s',
        'features': ['Rankings', 'Market Cap', '1h/24h/7d', 'OHLCV'],
        'apiNeeded': true, 'plan': 'Basic Free / Pro',
        'rateLimit': '333 req/day (free)',
        'docs': 'pro.coinmarketcap.com',
        'restUrl': 'https://pro-api.coinmarketcap.com/v1',
        'wsUrl': '',
      },
      {
        'id': 'binancews', 'name': 'Binance WebSocket', 'icon': '⚡',
        'color': const Color(0xFFF3BA2F), 'type': 'WebSocket',
        'status': true, 'interval': 'Echtzeit',
        'features': ['Ticker 24h', 'Orderbook', 'Klines', 'Trades', 'Depth'],
        'apiNeeded': false, 'plan': 'Kostenlos',
        'rateLimit': '1200 Nachrichten/min',
        'docs': 'binance-docs.github.io',
        'restUrl': 'https://api.binance.com/api/v3',
        'wsUrl': 'wss://stream.binance.com:9443/ws',
      },
      {
        'id': 'tradingview', 'name': 'TradingView', 'icon': '📈',
        'color': const Color(0xFF2962FF), 'type': 'Widget API',
        'status': true, 'interval': 'Echtzeit',
        'features': ['Charts', 'Indikatoren', 'Alarme', 'Screener'],
        'apiNeeded': false, 'plan': 'Widget (kostenlos)',
        'rateLimit': 'Unbegrenzt',
        'docs': 'tradingview.com/widget',
        'restUrl': 'https://symbol-search.tradingview.com/symbol_search',
        'wsUrl': '',
      },
      {
        'id': 'cryptocompare', 'name': 'CryptoCompare', 'icon': '🔗',
        'color': const Color(0xFF00897B), 'type': 'REST + WS',
        'status': false, 'interval': '30s',
        'features': ['OHLCV Historisch', 'News', 'Social Data', 'Mining'],
        'apiNeeded': true, 'plan': 'Free / Hanna Pro',
        'rateLimit': '100K req/Monat (free)',
        'docs': 'min-api.cryptocompare.com',
        'restUrl': 'https://min-api.cryptocompare.com/data',
        'wsUrl': 'wss://streamer.cryptocompare.com',
      },
      {
        'id': 'kraken_pub', 'name': 'Kraken Public API', 'icon': '🐙',
        'color': const Color(0xFF5741D9), 'type': 'REST + WS',
        'status': false, 'interval': '10s',
        'features': ['Ticker', 'Orderbook', 'Trades', 'OHLCV', 'Assets'],
        'apiNeeded': false, 'plan': 'Kostenlos (public)',
        'rateLimit': '15 req/s',
        'docs': 'docs.kraken.com/api',
        'restUrl': 'https://api.kraken.com/0/public',
        'wsUrl': 'wss://ws.kraken.com/v2',
      },
      {
        'id': 'cloudflare', 'name': 'Cloudflare Workers AI', 'icon': '☁️',
        'color': const Color(0xFFF38020), 'type': 'Edge API',
        'status': false, 'interval': 'On-Demand',
        'features': ['Edge Computing', 'KV Store', 'D1 Database', 'AI Inference'],
        'apiNeeded': true, 'plan': 'Free / Workers Paid',
        'rateLimit': '100K Anfragen/Tag (free)',
        'docs': 'developers.cloudflare.com',
        'restUrl': 'https://api.cloudflare.com/client/v4',
        'wsUrl': 'wss://[workers].workers.dev',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionHeader(p, 'DATA SOURCE VERBINDUNGEN', Icons.data_usage),
        const SizedBox(height: 8),
        ...feeds.map((feed) => _buildDataFeedCard(p, feed, lp)),
        const SizedBox(height: 16),
        _buildCloudflareSection(p),
        const SizedBox(height: 8),
        _buildDataSourceGuide(p),
      ],
    );
  }

  // ── CLOUDFLARE SECTION ────────────────────────────────────
  Widget _buildCloudflareSection(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF38020).withValues(alpha: 0.12),
            const Color(0xFF2C7EFF).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF38020).withValues(alpha: 0.3),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('☁️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CLOUDFLARE INTEGRATION',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: p.accent2)),
            Text('Edge Computing · Workers · KV · D1 Database',
              style: TextStyle(fontSize: 10, color: p.textSecondary)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: const Text('KONFIGURIERBAR',
              style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 12),
        // Cloudflare API Endpoints
        ...[
          ('Workers API', 'https://api.cloudflare.com/client/v4/accounts/{id}/workers/scripts', 'REST'),
          ('Workers AI', 'https://api.cloudflare.com/client/v4/accounts/{id}/ai/run/@cf/meta/llama-3.1-8b', 'AI'),
          ('KV Storage', 'https://api.cloudflare.com/client/v4/accounts/{id}/storage/kv/namespaces', 'KV'),
          ('D1 Database', 'https://api.cloudflare.com/client/v4/accounts/{id}/d1/database', 'DB'),
          ('Pages Deploy', 'https://api.cloudflare.com/client/v4/accounts/{id}/pages/projects', 'CI/CD'),
          ('Turnstile', 'https://challenges.cloudflare.com/turnstile/v0/siteverify', 'Security'),
        ].map((e) {
          final (name, url, tag) = e;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF38020).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag, style: const TextStyle(fontSize: 8, color: Color(0xFFF38020), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$name: ${url.length > 45 ? '${url.substring(0, 45)}...' : url}',
                  style: TextStyle(fontSize: 9.5, color: p.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name URL kopiert'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: const Color(0xFFF38020),
                    ),
                  );
                },
                child: Icon(Icons.copy, size: 12, color: p.textSecondary),
              ),
            ]),
          );
        }),
        const Divider(height: 16),
        Row(children: [
          Icon(Icons.info_outline, size: 13, color: p.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'API-Token benötigt: Cloudflare Dashboard → My Profile → API Tokens',
              style: TextStyle(fontSize: 9, color: p.textSecondary),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildDataFeedCard(dynamic p, Map<String, dynamic> feed, LivePriceProvider lp) {
    final isActive = feed['status'] as bool;
    final color = feed['color'] as Color;
    final features = feed['features'] as List<String>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.3) : p.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Text(feed['icon'] as String, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(feed['name'] as String, style: GoogleFonts.spaceMono(
                color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold,
              )),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(feed['type'] as String, style: GoogleFonts.spaceMono(
                    color: color, fontSize: 8, letterSpacing: 0.5,
                  )),
                ),
                const SizedBox(width: 6),
                Text('Update: ${feed['interval']}', style: GoogleFonts.inter(
                  color: p.textSecondary, fontSize: 10,
                )),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF00FF88).withValues(alpha: 0.1)
                      : p.textSecondary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF00FF88).withValues(alpha: 0.3)
                        : p.textSecondary.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  isActive ? 'AKTIV' : 'INAKTIV',
                  style: GoogleFonts.spaceMono(
                    color: isActive ? const Color(0xFF00FF88) : p.textSecondary,
                    fontSize: 8, letterSpacing: 0.5,
                  ),
                ),
              ),
            ]),
          ]),
        ),
        // Features
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Wrap(
            spacing: 6, runSpacing: 4,
            children: features.map((f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withValues(alpha: 0.15)),
              ),
              child: Text(f, style: GoogleFonts.inter(color: color, fontSize: 10)),
            )).toList(),
          ),
        ),
        // Endpoints display
        if ((feed['restUrl'] as String? ?? '').isNotEmpty || (feed['wsUrl'] as String? ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.1)),
              ),
              child: Column(children: [
                if ((feed['restUrl'] as String? ?? '').isNotEmpty)
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
                      child: Text('REST', style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(feed['restUrl'] as String,
                      style: TextStyle(fontSize: 8.5, color: p.textSecondary), overflow: TextOverflow.ellipsis)),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: feed['restUrl'] as String));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('REST URL kopiert'),
                          duration: const Duration(seconds: 1),
                        ));
                      },
                      child: Icon(Icons.copy, size: 11, color: p.textSecondary),
                    ),
                  ]),
                if ((feed['restUrl'] as String? ?? '').isNotEmpty && (feed['wsUrl'] as String? ?? '').isNotEmpty)
                  const SizedBox(height: 4),
                if ((feed['wsUrl'] as String? ?? '').isNotEmpty)
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
                      child: Text('WS', style: TextStyle(fontSize: 8, color: Colors.green.shade400, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(feed['wsUrl'] as String,
                      style: TextStyle(fontSize: 8.5, color: p.textSecondary), overflow: TextOverflow.ellipsis)),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: feed['wsUrl'] as String));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('WS URL kopiert'),
                          duration: const Duration(seconds: 1),
                        ));
                      },
                      child: Icon(Icons.copy, size: 11, color: p.textSecondary),
                    ),
                  ]),
              ]),
            ),
          ),
        // Details
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: p.primary.withValues(alpha: 0.06))),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Plan: ${feed['plan']}', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
              Text('Rate: ${feed['rateLimit']}', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
            ])),
            // API Key input button if needed
            if (feed['apiNeeded'] as bool)
              GestureDetector(
                onTap: () => _showApiKeyDialog(context, p, feed['id'] as String, feed['name'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text('API KEY', style: GoogleFonts.spaceMono(
                    color: color, fontSize: 9, fontWeight: FontWeight.bold,
                  )),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDataSourceGuide(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.info_outline, color: p.primary, size: 16),
          const SizedBox(width: 8),
          Text('DATENQUELLEN GUIDE', style: GoogleFonts.spaceMono(
            color: p.primary, fontSize: 11, letterSpacing: 1,
          )),
        ]),
        const SizedBox(height: 10),
        _buildGuideItem(p, '1', 'CoinGecko', 'Kostenlose REST API, keine Registrierung nötig. Beste Datenqualität für Top 250 Assets.'),
        _buildGuideItem(p, '2', 'CoinMarketCap', 'Pro API Key empfohlen für Ranking-Daten. Free Plan: 333 Anfragen/Tag.'),
        _buildGuideItem(p, '3', 'WebSocket', 'Direkte Börsen-Verbindung für Echtzeit-Ticks. Kein API Key für public Streams.'),
        _buildGuideItem(p, '4', 'TradingView', 'Widget-Integration ohne Key. Charts direkt von TradingView.com.'),
      ]),
    );
  }

  Widget _buildGuideItem(dynamic p, String num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 18, height: 18,
          decoration: BoxDecoration(
            color: p.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(num, style: GoogleFonts.spaceMono(
            color: p.primary, fontSize: 9, fontWeight: FontWeight.bold,
          ))),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(desc, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
        ])),
      ]),
    );
  }

  // ── BROKER API TAB ───────────────────────────────────────
  Widget _buildBrokerApiTab(dynamic p, LivePriceProvider lp) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionHeader(p, 'BROKER API ZUGÄNGE', Icons.account_balance),
        const SizedBox(height: 8),
        _buildBrokerCard(p, 'Binance', '🟡', const Color(0xFFF0B90B),
            'Spot & Futures Trading API', _apiKeys['binance']!),
        _buildBrokerCard(p, 'Bybit', '🟠', const Color(0xFFF7A600),
            'Derivatives & Copy Trading', _apiKeys['bybit']!),
        _buildBrokerCard(p, 'Coinbase', '🔵', const Color(0xFF0052FF),
            'Advanced Trade API', _apiKeys['coinbase']!),
        _buildBrokerCard(p, 'Kraken', '🟣', const Color(0xFF5741D9),
            'Spot & Margin Trading', _apiKeys['kraken']!),
        _buildBrokerCard(p, 'OKX', '⚫', const Color(0xFF00AAFF),
            'Spot, Futures & DeFi', _apiKeys['okx']!),
        const SizedBox(height: 16),
        _buildSecurityNotice(p),
      ],
    );
  }

  Widget _buildBrokerCard(dynamic p, String name, String icon, Color color,
      String desc, Map<String, String> keys) {
    final isActive = keys['status'] == 'active';
    final hasKey = keys['key']!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.25) : p.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.spaceMono(
                color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold,
              )),
              Text(desc, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
            ])),
            GestureDetector(
              onTap: () => _showApiKeyDialog(context, p, name.toLowerCase(), name),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text('SETUP', style: GoogleFonts.spaceMono(
                  color: color, fontSize: 9, fontWeight: FontWeight.bold,
                )),
              ),
            ),
          ]),
          if (hasKey) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(children: [
                Row(children: [
                  Text('API KEY: ', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
                  Text(keys['key']!, style: GoogleFonts.spaceMono(
                    color: isActive ? const Color(0xFF00FF88) : p.textSecondary,
                    fontSize: 9,
                  )),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text('SECRET: ', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
                  Text(keys['secret']!, style: GoogleFonts.spaceMono(
                    color: p.textSecondary, fontSize: 9,
                  )),
                ]),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildSecurityNotice(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFAA00).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFAA00).withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.security, color: Color(0xFFFFAA00), size: 16),
          const SizedBox(width: 8),
          Text('SICHERHEITSHINWEIS', style: GoogleFonts.spaceMono(
            color: const Color(0xFFFFAA00), fontSize: 10, letterSpacing: 1,
          )),
        ]),
        const SizedBox(height: 8),
        Text(
          '• Nur Read + Trade Permissions aktivieren\n'
          '• IP-Whitelist in Exchange einrichten\n'
          '• Withdrawal-Rechte NIEMALS vergeben\n'
          '• API Keys werden verschlüsselt gespeichert',
          style: GoogleFonts.inter(color: p.textSecondary, fontSize: 11, height: 1.6),
        ),
      ]),
    );
  }

  // ── SETTINGS TAB ─────────────────────────────────────────
  Widget _buildSettingsTab(dynamic p, LivePriceProvider lp) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionHeader(p, 'VERBINDUNGS-EINSTELLUNGEN', Icons.settings),
        const SizedBox(height: 8),
        _buildToggleSetting(p, 'WebSocket Live Streams', 'Echtzeit-Preise von Binance, Bybit etc.',
            lp.wsEnabled, (v) {
          setState(() => lp.wsEnabled = v);
        }),
        _buildToggleSetting(p, 'CoinGecko REST API', 'Marktdaten alle 45 Sekunden',
            lp.geckoEnabled, (v) {
          setState(() => lp.geckoEnabled = v);
        }),
        _buildToggleSetting(p, 'CoinMarketCap API', 'Rankings und Marktdaten alle 60s',
            lp.cmcEnabled, (v) {
          setState(() => lp.cmcEnabled = v);
        }),
        _buildToggleSetting(p, 'Simulation Fallback', 'Simulierte Preise wenn keine Live-Daten',
            lp.simulationFallback, (v) {
          setState(() => lp.simulationFallback = v);
        }),
        const SizedBox(height: 16),
        // Manual Refresh Button
        GestureDetector(
          onTap: () async {
            HapticFeedback.mediumImpact();
            await lp.refresh();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Daten aktualisiert', style: GoogleFonts.inter(color: Colors.white)),
                backgroundColor: p.primary,
                duration: const Duration(seconds: 2),
              ));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [p.primary, p.accent]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.refresh, color: Colors.black, size: 18),
              const SizedBox(width: 8),
              Text('ALLE DATEN AKTUALISIEREN', style: GoogleFonts.spaceMono(
                color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1,
              )),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        // Filter
        _buildSectionHeader(p, 'EXCHANGE FILTER', Icons.filter_list),
        const SizedBox(height: 8),
        _buildExchangeFilterRow(p, lp),
      ],
    );
  }

  Widget _buildExchangeFilterRow(dynamic p, LivePriceProvider lp) {
    final exchanges = ['ALL', 'BINANCE', 'COINBASE', 'KRAKEN', 'BYBIT', 'OKX'];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: exchanges.map((ex) {
        final sel = lp.activeExchangeFilter == ex;
        return GestureDetector(
          onTap: () {
            lp.setExchangeFilter(ex);
            HapticFeedback.selectionClick();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? p.primary.withValues(alpha: 0.15) : p.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: sel ? p.primary.withValues(alpha: 0.5) : p.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Text(ex, style: GoogleFonts.spaceMono(
              color: sel ? p.primary : p.textSecondary,
              fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            )),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToggleSetting(dynamic p, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.primary.withValues(alpha: 0.08)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(subtitle, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
        ])),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: p.primary,
          activeTrackColor: p.primary.withValues(alpha: 0.3),
        ),
      ]),
    );
  }

  Widget _buildSectionHeader(dynamic p, String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: p.primary, size: 14),
      const SizedBox(width: 6),
      Text(title, style: GoogleFonts.spaceMono(
        color: p.primary, fontSize: 10, letterSpacing: 1.5,
      )),
    ]);
  }

  // ── API Key Dialog ────────────────────────────────────────
  void _showApiKeyDialog(BuildContext context, dynamic p, String id, String name) {
    final keyCtrl = TextEditingController(text: _apiKeys[id]?['key'] ?? _dataApiKeys[id] ?? '');
    final secretCtrl = TextEditingController(text: _apiKeys[id]?['secret'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$name API Key', style: GoogleFonts.spaceMono(
          color: p.textPrimary, fontSize: 14,
        )),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: keyCtrl,
            style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 12),
            decoration: InputDecoration(
              labelText: 'API Key',
              labelStyle: TextStyle(color: p.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: p.primary.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: p.primary),
              ),
            ),
          ),
          if (_apiKeys.containsKey(id)) ...[
            const SizedBox(height: 10),
            TextField(
              controller: secretCtrl,
              obscureText: true,
              style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                labelText: 'API Secret',
                labelStyle: TextStyle(color: p.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: p.primary.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: p.primary),
                ),
              ),
            ),
          ],
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen', style: TextStyle(color: p.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (_apiKeys.containsKey(id)) {
                  _apiKeys[id]!['key'] = keyCtrl.text;
                  _apiKeys[id]!['secret'] = secretCtrl.text;
                  _apiKeys[id]!['status'] = keyCtrl.text.isNotEmpty ? 'active' : 'inactive';
                } else {
                  _dataApiKeys[id] = keyCtrl.text;
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('API Key gespeichert', style: GoogleFonts.inter(color: Colors.white)),
                backgroundColor: p.primary,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: p.primary),
            child: const Text('Speichern', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
