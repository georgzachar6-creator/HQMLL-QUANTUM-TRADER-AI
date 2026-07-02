// HQMLL Quantum Trader — Market Data Ingestion Screen v51.0
// Multi-Provider WebSocket Gateway · OHLCV · Feature Extraction
// Grigori Saks · 2025
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/market_data_ingestion_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
class MarketDataIngestionScreen extends StatefulWidget {
  const MarketDataIngestionScreen({super.key});
  @override
  State<MarketDataIngestionScreen> createState() =>
      _MarketDataIngestionScreenState();
}

class _MarketDataIngestionScreenState extends State<MarketDataIngestionScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  final List<MarketTick> _recentTicks = [];
  StreamSubscription<MarketTick>? _tickSub;
  StreamSubscription<OhlcvBar>? _barSub;
  final List<OhlcvBar> _recentBars = [];
  String _selectedSymbol = 'BTC/USDT';
  String _selectedInterval = 'm1';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachStreams());
  }

  void _attachStreams() {
    final svc = context.read<MarketDataIngestionService>();
    _tickSub = svc.tickStream.listen((tick) {
      if (mounted && tick.symbol == _selectedSymbol) {
        setState(() {
          _recentTicks.insert(0, tick);
          if (_recentTicks.length > 50) _recentTicks.removeLast();
        });
      }
    });
    _barSub = svc.barStream.listen((bar) {
      if (mounted && bar.symbol == _selectedSymbol) {
        setState(() {
          _recentBars.insert(0, bar);
          if (_recentBars.length > 30) _recentBars.removeLast();
        });
      }
    });
  }

  @override
  void dispose() {
    _tickSub?.cancel();
    _barSub?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp  = context.watch<ThemeProvider>();
    final p   = tp.palette;
    final svc = context.watch<MarketDataIngestionService>();

    return Scaffold(
      backgroundColor: p.background,
      body: Column(
        children: [
          _buildHeader(p, svc),
          _buildSymbolSelector(p, svc),
          _buildTabBar(p),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _ProvidersTab(svc: svc, p: p),
                _TickStreamTab(ticks: _recentTicks, p: p),
                _OhlcvTab(bars: _recentBars, symbol: _selectedSymbol,
                    interval: _selectedInterval, p: p,
                    onIntervalChange: (v) => setState(() => _selectedInterval = v)),
                _FeaturesTab(svc: svc, symbol: _selectedSymbol, p: p),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (svc.isRunning) {
            svc.stop();
          } else {
            svc.start();
          }
        },
        backgroundColor: svc.isRunning ? Colors.red : const Color(0xFF00E5FF),
        icon: Icon(svc.isRunning ? Icons.stop : Icons.play_arrow,
            color: svc.isRunning ? Colors.white : Colors.black),
        label: Text(svc.isRunning ? 'Stop' : 'Start',
            style: TextStyle(
                color: svc.isRunning ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(dynamic p, MarketDataIngestionService svc) {
    final active   = svc.connectedProviderCount;
    final total    = DataProvider.values.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.primary.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (svc.isRunning ? const Color(0xFF00E5FF) : Colors.grey)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.sensors,
                color: svc.isRunning ? const Color(0xFF00E5FF) : Colors.grey,
                size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Market Data Gateway',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('$active/$total Provider aktiv · ${svc.subscribedSymbols.length} Sym.',  
                    style: TextStyle(color: p.primary, fontSize: 11)),
              ],
            ),
          ),
          _StatusPill(active: svc.isRunning),
        ],
      ),
    );
  }

  // ── Symbol Selector ────────────────────────────────────────────────────────
  Widget _buildSymbolSelector(dynamic p, MarketDataIngestionService svc) {
    final symbols = svc.subscribedSymbols.toList();
    return Container(
      height: 44,
      color: p.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: symbols.length,
        itemBuilder: (ctx, i) {
          final sym = symbols[i];
          final tick = svc.getLatestTick(sym);
          final selected = sym == _selectedSymbol;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSymbol = sym;
                _recentTicks.clear();
                _recentBars.clear();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? p.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected ? p.primary : Colors.grey.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(sym, style: TextStyle(
                      color: selected ? p.primary : Colors.grey,
                      fontSize: 11, fontWeight: FontWeight.bold)),
                  if (tick != null) ...[
                    const SizedBox(width: 4),
                    Text('\$${_formatPrice(tick.lastPrice)}',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar(dynamic p) {
    return Container(
      color: p.surface,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: p.primary,
        labelColor: p.primary,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(icon: Icon(Icons.cloud, size: 16), text: 'PROVIDER'),
          Tab(icon: Icon(Icons.bolt, size: 16), text: 'TICKS'),
          Tab(icon: Icon(Icons.candlestick_chart, size: 16), text: 'OHLCV'),
          Tab(icon: Icon(Icons.biotech, size: 16), text: 'FEATURES'),
        ],
      ),
    );
  }

  String _formatPrice(double p) {
    if (p >= 10000) return p.toStringAsFixed(0);
    if (p >= 100)   return p.toStringAsFixed(2);
    if (p >= 1)     return p.toStringAsFixed(4);
    return p.toStringAsFixed(6);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — PROVIDER STATUS
// ══════════════════════════════════════════════════════════════════════════════
class _ProvidersTab extends StatelessWidget {
  final MarketDataIngestionService svc;
  final dynamic p;
  const _ProvidersTab({required this.svc, required this.p});

  @override
  Widget build(BuildContext context) {
    // Build a Map<DataProvider, ProviderConnectionState> from the List
    final stateMap = { for (final s in svc.connectionStates) s.provider: s };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatGrid(svc: svc, p: p),
        const SizedBox(height: 16),
        ...DataProvider.values.map((dp) {
          final state = stateMap[dp];
          return _ProviderCard(provider: dp, state: state, p: p,
              onSubscribe: () => svc.subscribe(_firstSymbol(dp)));
        }),
      ],
    );
  }

  String _firstSymbol(DataProvider dp) {
    return switch (dp) {
      DataProvider.kraken   => 'ETH/USDT',
      DataProvider.binance  => 'SOL/USDT',
      DataProvider.alpaca   => 'AAPL/USD',
      _ => 'BTC/USDT',
    };
  }
}

class _StatGrid extends StatelessWidget {
  final MarketDataIngestionService svc;
  final dynamic p;
  const _StatGrid({required this.svc, required this.p});

  @override
  Widget build(BuildContext context) {
    final connected = svc.connectedProviderCount;
    final totalMsgs = svc.connectionStates.fold<int>(0, (a, s) => a + s.messageCount);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gateway Übersicht',
              style: TextStyle(color: p.primary, fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCell('Provider', '$connected/${DataProvider.values.length}', 
                  Icons.cloud, Colors.green, p),
              _StatCell('Symbole', '${svc.subscribedSymbols.length}',
                  Icons.tag, const Color(0xFF00E5FF), p),
              _StatCell('Nachrichten', '$totalMsgs',
                  Icons.message, Colors.orange, p),
              _StatCell('Status',
                  svc.isRunning ? 'AKTIV' : 'GESTOPPT',
                  Icons.circle,
                  svc.isRunning ? Colors.green : Colors.red, p),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final dynamic p;
  const _StatCell(this.label, this.value, this.icon, this.color, this.p);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 13,
              fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final DataProvider provider;
  final ProviderConnectionState? state;
  final dynamic p;
  final VoidCallback onSubscribe;
  const _ProviderCard({required this.provider, required this.state,
    required this.p, required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    final connected = state?.status == ConnectionStatus.connected;
    final color = connected ? Colors.green : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: connected ? [BoxShadow(
                      color: Colors.green.withValues(alpha: 0.4), blurRadius: 6)] : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(provider.label,
                  style: TextStyle(color: color, fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(provider.primaryAssetClass.name,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(provider.wsUrl, style: TextStyle(color: Colors.grey.shade600,
              fontSize: 10), overflow: TextOverflow.ellipsis),
          if (state != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _ProviderStat('Status', state!.statusLabel,
                    connected ? Colors.green : Colors.red),
                _ProviderStat('Nachrichten', '${state!.messageCount}',
                    Colors.white),
                _ProviderStat('Reconnects', '${state!.reconnectCount}',
                    state!.reconnectCount > 0 ? Colors.orange : Colors.grey),
                _ProviderStat('msg/s',
                    state!.messagesPerSecond.toStringAsFixed(1), Colors.white),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProviderStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ProviderStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 12,
              fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 9)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — TICK STREAM
// ══════════════════════════════════════════════════════════════════════════════
class _TickStreamTab extends StatelessWidget {
  final List<MarketTick> ticks;
  final dynamic p;
  const _TickStreamTab({required this.ticks, required this.p});

  @override
  Widget build(BuildContext context) {
    if (ticks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt, color: Colors.grey, size: 56),
            SizedBox(height: 12),
            Text('Warte auf Tick-Daten...',
                style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('Starten Sie den Market Data Gateway',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: ticks.length,
      itemBuilder: (ctx, i) => _TickRow(tick: ticks[i], p: p),
    );
  }
}

class _TickRow extends StatelessWidget {
  final MarketTick tick;
  final dynamic p;
  const _TickRow({required this.tick, required this.p});

  @override
  Widget build(BuildContext context) {
    final priceColor = tick.change24hPct >= 0 ? Colors.green : Colors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(tick.symbol,
                style: const TextStyle(color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(_fmt(tick.lastPrice),
                style: TextStyle(color: priceColor, fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
          Text('${tick.change24hPct >= 0 ? '+' : ''}${tick.change24hPct.toStringAsFixed(2)}%',
              style: TextStyle(color: priceColor, fontSize: 11)),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(tick.provider.label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  String _fmt(double price) {
    if (price >= 10000) return '\$${price.toStringAsFixed(0)}';
    if (price >= 100)   return '\$${price.toStringAsFixed(2)}';
    return '\$${price.toStringAsFixed(4)}';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3 — OHLCV BARS
// ══════════════════════════════════════════════════════════════════════════════
class _OhlcvTab extends StatelessWidget {
  final List<OhlcvBar> bars;
  final String symbol, interval;
  final dynamic p;
  final ValueChanged<String> onIntervalChange;
  const _OhlcvTab({required this.bars, required this.symbol,
    required this.interval, required this.p, required this.onIntervalChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Interval Selector
        Container(
          height: 40,
          color: p.surface,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: BarInterval.values.map((bi) {
              final selected = bi.label == interval;
              return GestureDetector(
                onTap: () => onIntervalChange(bi.label),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: selected ? p.primary.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: selected ? p.primary : Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: Text(bi.label,
                      style: TextStyle(
                          color: selected ? p.primary : Colors.grey,
                          fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              );
            }).toList(),
          ),
        ),
        // Bars Liste
        Expanded(
          child: bars.isEmpty
              ? const Center(child: Text('Warte auf OHLCV-Daten...',
                  style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: bars.length,
                  itemBuilder: (ctx, i) => _BarRow(bar: bars[i], p: p),
                ),
        ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final OhlcvBar bar;
  final dynamic p;
  const _BarRow({required this.bar, required this.p});

  @override
  Widget build(BuildContext context) {
    final bullish = bar.isBullish;
    final color   = bullish ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(bullish ? Icons.arrow_upward : Icons.arrow_downward,
              color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(bar.symbol,
                style: const TextStyle(color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          _OhlcCell('O', bar.open, Colors.grey.shade400),
          _OhlcCell('H', bar.high, Colors.green),
          _OhlcCell('L', bar.low, Colors.red),
          _OhlcCell('C', bar.close, color),
        ],
      ),
    );
  }
}

class _OhlcCell extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _OhlcCell(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 8)),
          Text(value >= 1000
              ? value.toStringAsFixed(0)
              : value.toStringAsFixed(2),
              style: TextStyle(color: color, fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 4 — ML FEATURES
// ══════════════════════════════════════════════════════════════════════════════
class _FeaturesTab extends StatelessWidget {
  final MarketDataIngestionService svc;
  final String symbol;
  final dynamic p;
  const _FeaturesTab({required this.svc, required this.symbol, required this.p});

  @override
  Widget build(BuildContext context) {
    final features = svc.getFeatures(symbol);
    if (features == null) {
      return const Center(
        child: Text('Nicht genug Daten für Feature-Berechnung',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final regime = features.regime; // String: 'TRENDING_UP', 'TRENDING_DOWN', 'RANGING', 'VOLATILE'
    final regimeColor = regime.contains('UP')
        ? Colors.green : regime.contains('DOWN')
        ? Colors.red : regime == 'VOLATILE'
        ? Colors.purple : Colors.orange;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Regime
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [regimeColor.withValues(alpha: 0.2), regimeColor.withValues(alpha: 0.05)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: regimeColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.show_chart, color: regimeColor, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Markt-Regime', style: TextStyle(color: Colors.grey.shade400,
                      fontSize: 11)),
                  Text(regime, style: TextStyle(color: regimeColor,
                      fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Returns
        _FeatureGroup(title: 'Returns', color: const Color(0xFF00E5FF), p: p,
            features: [
              _FeatureItem('1m Return', features.returnsPct1m, '%', isPercent: true),
              _FeatureItem('5m Return', features.returnsPct5m, '%', isPercent: true),
              _FeatureItem('1h Return', features.returnsPct1h, '%', isPercent: true),
            ]),
        const SizedBox(height: 12),
        // Volatilität
        _FeatureGroup(title: 'Volatilität', color: Colors.orange, p: p,
            features: [
              _FeatureItem('Vol 1h', features.volatility1h, '%', isPercent: true),
              _FeatureItem('Vol 1d', features.volatility1d, '%', isPercent: true),
            ]),
        const SizedBox(height: 12),
        // Indikatoren
        _FeatureGroup(title: 'Technische Indikatoren', color: Colors.purple, p: p,
            features: [
              _FeatureItem('RSI(14)', features.rsi14, '', isRsi: true),
              _FeatureItem('MACD Signal', features.macdSignal, ''),
              _FeatureItem('BB Position', features.bbPosition, '',
                  valueColor: _bbColor(features.bbPosition)),
            ]),
        const SizedBox(height: 12),
        // Orderbuch
        _FeatureGroup(title: 'Orderbuch / Liquidität', color: Colors.green, p: p,
            features: [
              _FeatureItem('OB Imbalance', features.obImbalance, '',
                  valueColor: features.obImbalance > 0 ? Colors.green : Colors.red),
              _FeatureItem('Volume Ratio', features.volumeRatio, 'x'),
            ]),
        const SizedBox(height: 16),
        // Feature-Vektor
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('11D Feature-Vektor (ML-Input)',
                  style: TextStyle(color: p.primary, fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '[${features.returnsPct1m.toStringAsFixed(4)}, '
                '${features.returnsPct5m.toStringAsFixed(4)}, '
                '${features.returnsPct1h.toStringAsFixed(4)}, '
                '${features.volatility1h.toStringAsFixed(4)}, '
                '${features.volatility1d.toStringAsFixed(4)}, '
                '${features.obImbalance.toStringAsFixed(4)}, '
                '${features.volumeRatio.toStringAsFixed(4)}, '
                '${features.rsi14.toStringAsFixed(4)}, '
                '${features.macdSignal.toStringAsFixed(4)}, '
                '${features.bbPosition.toStringAsFixed(4)}, '
                '${(features.regime.contains('UP') ? 1.0 : features.regime.contains('DOWN') ? -1.0 : 0.0).toStringAsFixed(1)}]',
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                    fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _bbColor(double pos) {
    if (pos > 0.8) return Colors.red;
    if (pos < 0.2) return Colors.green;
    return Colors.orange;
  }
}

class _FeatureGroup extends StatelessWidget {
  final String title;
  final Color color;
  final dynamic p;
  final List<_FeatureItem> features;
  const _FeatureGroup({required this.title, required this.color,
    required this.p, required this.features});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Text(title, style: TextStyle(color: color, fontSize: 12,
                fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          ...features.map((fi) => _FeatureRow(item: fi, p: p)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final String label, unit;
  final double value;
  final bool isPercent, isRsi;
  final Color? valueColor;
  const _FeatureItem(this.label, this.value, this.unit,
      {this.isPercent = false, this.isRsi = false, this.valueColor});
}

class _FeatureRow extends StatelessWidget {
  final _FeatureItem item;
  final dynamic p;
  const _FeatureRow({required this.item, required this.p});

  @override
  Widget build(BuildContext context) {
    Color valueColor = item.valueColor ?? Colors.white;
    if (item.isPercent && item.valueColor == null) {
      valueColor = item.value >= 0 ? Colors.green : Colors.red;
    }
    if (item.isRsi && item.valueColor == null) {
      valueColor = item.value > 70 ? Colors.red
          : item.value < 30 ? Colors.green : Colors.white;
    }

    final display = item.isPercent
        ? '${item.value >= 0 ? '+' : ''}${(item.value * 100).toStringAsFixed(2)}%'
        : '${item.value.toStringAsFixed(4)}${item.unit}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item.label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          Row(
            children: [
              if (item.isRsi) ...[
                SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    value: item.value / 100,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: AlwaysStoppedAnimation(valueColor),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(display, style: TextStyle(color: valueColor, fontSize: 12,
                  fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final bool active;
  const _StatusPill({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (active ? Colors.green : Colors.grey).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: (active ? Colors.green : Colors.grey).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 4),
          Text(active ? 'AKTIV' : 'OFFLINE',
              style: TextStyle(
                  color: active ? Colors.green : Colors.grey,
                  fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
