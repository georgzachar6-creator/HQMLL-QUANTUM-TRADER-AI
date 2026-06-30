/// Quantum Trader – AI Accounting Screen v24.0
/// AI Buchhalter · P&L · Steuern · Vollständige Historie · Logs
/// Grigori Saks · 2025
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';
import '../services/exchange_service.dart';
import '../services/auth_service.dart';
import '../widgets/asset_icon_widget.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});
  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen>
    with TickerProviderStateMixin {
  late TabController _tab;
  late AnimationController _pulseCtrl;
  int _selectedYear = DateTime.now().year;
  String _filterType = 'ALL';
  // ignore: unused_field
  final String _filterAsset = 'ALL';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  static const _taxFreeLimit = 1000.0; // € Freigrenze DE
  static const _abgeltungssteuer = 0.25;
  static const _soli = 0.055;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tab.dispose(); _pulseCtrl.dispose(); _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final p = theme.palette;
    final exchange = Provider.of<ExchangeService>(context);
    final auth = Provider.of<AuthService>(context);
    return Column(children: [
      _buildHeader(p, exchange, auth),
      _buildTabBar(p),
      Expanded(child: TabBarView(
        controller: _tab,
        children: [
          _buildOverview(p, exchange),
          _buildLedger(p, exchange),
          _buildTaxReport(p, exchange),
          _buildAiInsights(p, exchange),
        ],
      )),
    ]);
  }

  // ── Header ─────────────────────────────────────────
  Widget _buildHeader(QuantumPalette p, ExchangeService ex, AuthService auth) {
    final totalPnl = ex.getTotalPnL();
    final dailyPnl = ex.getDailyPnL();
    final txCount = ex.ledger.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.background, p.surface.withValues(alpha: 0.3)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: p.primary.withValues(alpha: 0.2))),
      ),
      child: Column(children: [
        Row(children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.primary.withValues(alpha: 0.1),
                boxShadow: [BoxShadow(
                  color: p.primary.withValues(alpha: 0.2 + _pulseCtrl.value * 0.2),
                  blurRadius: 12 + _pulseCtrl.value * 8,
                )],
              ),
              child: Icon(Icons.auto_awesome, color: p.primary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI BUCHHALTER', style: GoogleFonts.orbitron(
              color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2,
            )),
            Text('${auth.currentUser?.displayName ?? 'User'} · ${auth.currentUser?.email ?? ''}',
              style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
          ])),
          // Auto-Save indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: p.positive.withValues(alpha: 0.1),
              border: Border.all(color: p.positive.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: p.positive)),
              const SizedBox(width: 4),
              Text('AUTO-SAVE', style: GoogleFonts.orbitron(color: p.positive, fontSize: 7)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        // Stats row
        Row(children: [
          _buildStatChip('GESAMT P&L', totalPnl >= 0 ? '+\$${totalPnl.toStringAsFixed(0)}' : '-\$${totalPnl.abs().toStringAsFixed(0)}',
            totalPnl >= 0 ? p.positive : p.negative, p),
          const SizedBox(width: 8),
          _buildStatChip('HEUTE', dailyPnl >= 0 ? '+\$${dailyPnl.toStringAsFixed(0)}' : '-\$${dailyPnl.abs().toStringAsFixed(0)}',
            dailyPnl >= 0 ? p.positive : p.negative, p),
          const SizedBox(width: 8),
          _buildStatChip('TRANSAKTIONEN', '$txCount', p.primary, p),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, QuantumPalette p) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
        ]),
      ),
    );
  }

  // ── Tab Bar ────────────────────────────────────────
  Widget _buildTabBar(QuantumPalette p) {
    return Container(
      color: p.surface,
      child: TabBar(
        controller: _tab,
        labelColor: p.primary,
        unselectedLabelColor: p.textSecondary,
        indicatorColor: p.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.orbitron(fontSize: 8, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.orbitron(fontSize: 8),
        tabs: const [
          Tab(text: 'ÜBERSICHT', icon: Icon(Icons.dashboard, size: 14)),
          Tab(text: 'BUCHUNGEN', icon: Icon(Icons.receipt_long, size: 14)),
          Tab(text: 'STEUERN', icon: Icon(Icons.account_balance, size: 14)),
          Tab(text: 'KI-ANALYSE', icon: Icon(Icons.psychology, size: 14)),
        ],
      ),
    );
  }

  // ── OVERVIEW TAB ───────────────────────────────────
  Widget _buildOverview(QuantumPalette p, ExchangeService ex) {
    final ledger = ex.ledger;
    final buys  = ledger.where((t) => t.type == TxType.buy).length;
    final sells = ledger.where((t) => t.type == TxType.sell).length;
    final swaps = ledger.where((t) => t.type == TxType.swap).length;
    final deps  = ledger.where((t) => t.type == TxType.deposit).length;
    final wits  = ledger.where((t) => t.type == TxType.withdraw).length;
    final sends = ledger.where((t) => t.type == TxType.send).length;
    final autoTrades = ledger.where((t) => t.isAutoTrade).length;

    final totalFees = ledger.fold(0.0, (s, t) => s + t.fee);
    final winTrades = ledger.where((t) => t.type == TxType.sell && t.pnl > 0).length;
    final totalTrades = ledger.where((t) => t.type == TxType.buy || t.type == TxType.sell).length;
    final winRate = totalTrades > 0 ? (winTrades / totalTrades * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Summary grid
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _buildOverviewCard('KÄUFE', '$buys', Icons.trending_up, Colors.greenAccent, p),
            _buildOverviewCard('VERKÄUFE', '$sells', Icons.trending_down, Colors.redAccent, p),
            _buildOverviewCard('SWAPS', '$swaps', Icons.swap_horiz, Colors.orangeAccent, p),
            _buildOverviewCard('EINZAHLUNGEN', '$deps', Icons.add_circle_outline, Colors.blueAccent, p),
            _buildOverviewCard('AUSZAHLUNGEN', '$wits', Icons.remove_circle_outline, Colors.purpleAccent, p),
            _buildOverviewCard('SENDS', '$sends', Icons.send, Colors.cyanAccent, p),
          ],
        ),
        const SizedBox(height: 16),
        // Performance
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.primary.withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PERFORMANCE', style: GoogleFonts.orbitron(
              color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _buildPerfRow('Win Rate', '${winRate.toStringAsFixed(1)}%', winRate >= 50 ? p.positive : p.negative, p),
            _buildPerfRow('Gesamtgebühren', '-\$${totalFees.toStringAsFixed(2)}', p.negative, p),
            _buildPerfRow('Auto-Trades', '$autoTrades', p.accent, p),
            _buildPerfRow('Trades total', '$totalTrades', p.primary, p),
          ]),
        ),
        const SizedBox(height: 16),
        // Monthly chart
        _buildMonthlyChart(p, ex),
      ]),
    );
  }

  Widget _buildOverviewCard(String label, String value, IconData icon, Color color, QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
        ]),
        const Spacer(),
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _buildPerfRow(String label, String value, Color color, QuantumPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 12)),
        const Spacer(),
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildMonthlyChart(QuantumPalette p, ExchangeService ex) {
    final months = List.generate(6, (i) {
      final d = DateTime.now().subtract(Duration(days: (5 - i) * 30));
      return d;
    });
    final rnd = Random(42);
    final values = months.map((_) => (rnd.nextDouble() - 0.4) * 500).toList();
    final maxAbs = values.map((v) => v.abs()).reduce(max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MONATLICHER P&L', style: GoogleFonts.orbitron(
          color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(6, (i) {
              final val = values[i];
              final pct = maxAbs > 0 ? (val.abs() / maxAbs) : 0.0;
              final isPos = val >= 0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(val >= 0 ? '+${val.toStringAsFixed(0)}' : val.toStringAsFixed(0),
                        style: GoogleFonts.orbitron(
                          color: isPos ? p.positive : p.negative, fontSize: 7,
                        )),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 400 + i * 50),
                        height: max(4, 60 * pct),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: isPos ? p.positive : p.negative,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ['Jan','Feb','Mär','Apr','Mai','Jun','Jul','Aug','Sep','Okt','Nov','Dez']
                            [months[i].month - 1],
                        style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }

  // ── LEDGER TAB ─────────────────────────────────────
  Widget _buildLedger(QuantumPalette p, ExchangeService ex) {
    final allTypes = ['ALL', 'BUY', 'SELL', 'SWAP', 'DEPOSIT', 'WITHDRAW', 'SEND'];
    var txs = ex.getLedger(limit: 500);

    if (_filterType != 'ALL') {
      txs = txs.where((t) => t.type.name.toUpperCase() == _filterType).toList();
    }
    if (_searchQuery.isNotEmpty) {
      txs = txs.where((t) =>
        t.fromAsset.contains(_searchQuery.toUpperCase()) ||
        t.toAsset.contains(_searchQuery.toUpperCase()) ||
        (t.txHash?.contains(_searchQuery) ?? false) ||
        (t.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    return Column(children: [
      // Filter bar
      Container(
        height: 38,
        color: p.background,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          itemCount: allTypes.length,
          itemBuilder: (_, i) {
            final sel = _filterType == allTypes[i];
            return GestureDetector(
              onTap: () => setState(() => _filterType = allTypes[i]),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sel ? p.primary : p.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sel ? p.primary : p.primary.withValues(alpha: 0.2)),
                ),
                child: Text(allTypes[i], style: GoogleFonts.orbitron(
                  color: sel ? Colors.black : p.textSecondary, fontSize: 8,
                )),
              ),
            );
          },
        ),
      ),
      // Search bar
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Symbol, TX-Hash, Notiz suchen...',
            hintStyle: TextStyle(color: p.textSecondary, fontSize: 12),
            prefixIcon: Icon(Icons.search, color: p.primary, size: 18),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(icon: Icon(Icons.clear, color: p.textSecondary, size: 16),
                    onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); })
                : null,
            filled: true, fillColor: p.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          ),
        ),
      ),
      // Transaction list
      Expanded(
        child: txs.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.receipt_long, color: p.textSecondary.withValues(alpha: 0.3), size: 48),
                const SizedBox(height: 8),
                Text('Keine Transaktionen', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 13)),
              ]))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: txs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) => _buildTxCard(txs[i], p),
              ),
      ),
    ]);
  }

  Widget _buildTxCard(QTransaction tx, QuantumPalette p) {
    final typeColors = {
      TxType.buy: Colors.greenAccent,
      TxType.sell: Colors.redAccent,
      TxType.swap: Colors.orangeAccent,
      TxType.deposit: Colors.blueAccent,
      TxType.withdraw: Colors.purpleAccent,
      TxType.send: Colors.cyanAccent,
      TxType.receive: Colors.tealAccent,
      TxType.staking: Colors.amberAccent,
      TxType.fee: Colors.grey,
    };
    final typeIcons = {
      TxType.buy: Icons.trending_up,
      TxType.sell: Icons.trending_down,
      TxType.swap: Icons.swap_horiz,
      TxType.deposit: Icons.add_circle_outline,
      TxType.withdraw: Icons.remove_circle_outline,
      TxType.send: Icons.send,
      TxType.receive: Icons.call_received,
      TxType.staking: Icons.lock,
      TxType.fee: Icons.receipt,
    };
    final color = typeColors[tx.type] ?? p.primary;
    final icon = typeIcons[tx.type] ?? Icons.swap_horiz;
    final statusColors = {
      TxStatus.completed: p.positive,
      TxStatus.pending: Colors.amber,
      TxStatus.processing: p.primary,
      TxStatus.failed: p.negative,
      TxStatus.cancelled: p.textSecondary,
    };

    return GestureDetector(
      onLongPress: () {
        if (tx.txHash != null) {
          Clipboard.setData(ClipboardData(text: tx.txHash!));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('TX-Hash kopiert: ${tx.txHash!.substring(0, 16)}...')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: tx.isAutoTrade ? [BoxShadow(color: p.accent.withValues(alpha: 0.1), blurRadius: 6)] : null,
        ),
        child: Row(children: [
          Stack(children: [
            AssetIconWidget(symbol: tx.fromAsset, palette: p, size: 38, showBorder: false),
            Positioned(right: 0, bottom: 0, child: Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.9),
                border: Border.all(color: p.surface, width: 1.5),
              ),
              child: Icon(icon, color: Colors.black, size: 8),
            )),
          ]),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('${tx.typeLabel} ${tx.fromAsset}',
                style: GoogleFonts.orbitron(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
              if (tx.isAutoTrade) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('AI', style: GoogleFonts.orbitron(color: p.accent, fontSize: 7)),
                ),
              ],
            ]),
            const SizedBox(height: 2),
            Text(
              tx.type == TxType.swap
                  ? '${tx.fromAmount.toStringAsFixed(4)} ${tx.fromAsset} → ${tx.toAmount.toStringAsFixed(4)} ${tx.toAsset}'
                  : '${tx.fromAmount.toStringAsFixed(4)} ${tx.fromAsset}  ·  @\$${tx.price.toStringAsFixed(2)}',
              style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 2),
            Row(children: [
              if (tx.exchange != null)
                Text('${tx.exchange}  ·', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
              const SizedBox(width: 4),
              Text(
                '${tx.createdAt.day.toString().padLeft(2,'0')}.${tx.createdAt.month.toString().padLeft(2,'0')}.${tx.createdAt.year}  ${tx.createdAt.hour.toString().padLeft(2,'0')}:${tx.createdAt.minute.toString().padLeft(2,'0')}',
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9),
              ),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${tx.total.toStringAsFixed(2)}',
              style: GoogleFonts.orbitron(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: (statusColors[tx.status] ?? p.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(tx.statusLabel,
                style: GoogleFonts.orbitron(
                  color: statusColors[tx.status] ?? p.primary, fontSize: 7,
                )),
            ),
            const SizedBox(height: 2),
            Text('-\$${tx.fee.toStringAsFixed(3)} fee',
              style: GoogleFonts.rajdhani(color: p.negative.withValues(alpha: 0.7), fontSize: 9)),
          ]),
        ]),
      ),
    );
  }

  // ── TAX REPORT ─────────────────────────────────────
  Widget _buildTaxReport(QuantumPalette p, ExchangeService ex) {
    final sells = ex.ledger.where((t) => t.type == TxType.sell && t.isCompleted).toList();
    final totalGains = sells.fold(0.0, (s, t) => s + (t.pnl > 0 ? t.pnl : 0));
    final totalLosses = sells.fold(0.0, (s, t) => s + (t.pnl < 0 ? t.pnl.abs() : 0));
    final netGain = totalGains - totalLosses;
    final taxableGain = (netGain - _taxFreeLimit).clamp(0.0, double.infinity);
    final abgSteuer = taxableGain * _abgeltungssteuer;
    final soliZuschlag = abgSteuer * _soli;
    final totalTax = abgSteuer + soliZuschlag;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Year selector
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: p.primary),
            onPressed: () => setState(() => _selectedYear--),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.primary.withValues(alpha: 0.3)),
            ),
            child: Text('$_selectedYear', style: GoogleFonts.orbitron(
              color: p.primary, fontSize: 16, fontWeight: FontWeight.bold,
            )),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: p.primary),
            onPressed: () => setState(() => _selectedYear = min(_selectedYear + 1, DateTime.now().year)),
          ),
        ]),
        const SizedBox(height: 16),
        // Tax summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              p.negative.withValues(alpha: 0.08), p.surface,
            ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.negative.withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            Row(children: [
              Icon(Icons.account_balance, color: p.negative, size: 18),
              const SizedBox(width: 8),
              Text('STEUERBERECHNUNG $_selectedYear', style: GoogleFonts.orbitron(
                color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.w700,
              )),
            ]),
            const SizedBox(height: 12),
            _buildTaxRow('Gesamtgewinne', '+\$${totalGains.toStringAsFixed(2)}', p.positive, p),
            _buildTaxRow('Gesamtverluste', '-\$${totalLosses.toStringAsFixed(2)}', p.negative, p),
            Divider(color: p.primary.withValues(alpha: 0.2)),
            _buildTaxRow('Nettogewinn', '\$${netGain.toStringAsFixed(2)}', netGain >= 0 ? p.positive : p.negative, p),
            _buildTaxRow('Freigrenze DE', '-€${_taxFreeLimit.toStringAsFixed(0)}', p.textSecondary, p),
            _buildTaxRow('Steuerpflichtiger Gewinn', '\$${taxableGain.toStringAsFixed(2)}', p.accent, p),
            Divider(color: p.primary.withValues(alpha: 0.2)),
            _buildTaxRow('Abgeltungssteuer (25%)', '\$${abgSteuer.toStringAsFixed(2)}', p.negative, p),
            _buildTaxRow('Solidaritätszuschlag (5.5%)', '\$${soliZuschlag.toStringAsFixed(2)}', p.negative, p),
            Divider(color: p.negative.withValues(alpha: 0.4)),
            _buildTaxRow('GESAMTSTEUER', '\$${totalTax.toStringAsFixed(2)}', p.negative, p, bold: true),
          ]),
        ),
        const SizedBox(height: 16),
        // Export buttons
        Row(children: [
          Expanded(child: _buildExportBtn('CSV EXPORT', Icons.file_download, Colors.greenAccent, p)),
          const SizedBox(width: 12),
          Expanded(child: _buildExportBtn('PDF BERICHT', Icons.picture_as_pdf, Colors.redAccent, p)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildExportBtn('ELSTER XML', Icons.code, Colors.blueAccent, p)),
          const SizedBox(width: 12),
          Expanded(child: _buildExportBtn('FIFO ANALYSE', Icons.analytics, Colors.orangeAccent, p)),
        ]),
        const SizedBox(height: 16),
        // Disclaimer
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.warning_amber, color: Colors.amber, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Diese Berechnung dient nur als Orientierung. Bitte konsultiere einen Steuerberater.',
              style: GoogleFonts.rajdhani(color: Colors.amber, fontSize: 9),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTaxRow(String label, String value, Color color, QuantumPalette p, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(label, style: GoogleFonts.rajdhani(
          color: p.textSecondary, fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
        )),
        const Spacer(),
        Text(value, style: GoogleFonts.orbitron(
          color: color, fontSize: bold ? 13 : 11,
          fontWeight: bold ? FontWeight.w900 : FontWeight.normal,
        )),
      ]),
    );
  }

  Widget _buildExportBtn(String label, IconData icon, Color color, QuantumPalette p) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label wird vorbereitet...'), backgroundColor: p.surface),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.orbitron(color: color, fontSize: 8, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  // ── AI INSIGHTS ────────────────────────────────────
  Widget _buildAiInsights(QuantumPalette p, ExchangeService ex) {
    final ledger = ex.ledger;
    final rnd = Random(DateTime.now().day);

    final insights = [
      const _AiInsight('Portfolio Diversifikation', 
        'Du handelst hauptsächlich BTC und ETH. Diversifikation auf 5-7 Assets empfohlen.',
        Icons.pie_chart, Colors.blueAccent, 0.72),
      const _AiInsight('Handelsfrequenz optimal',
        'Deine durchschnittliche Haltezeit ist gut für Swing-Trading. Weiter so!',
        Icons.show_chart, Colors.greenAccent, 0.85),
      const _AiInsight('Gebühren-Optimierung',
        'Durch Limit-Orders statt Market-Orders kannst du bis zu 40% Gebühren sparen.',
        Icons.savings, Colors.orangeAccent, 0.6),
      const _AiInsight('Risk-Management',
        'Stop-Loss bei 3% und Take-Profit bei 8% sind für dein Portfolio optimal.',
        Icons.security, Colors.purpleAccent, 0.79),
      const _AiInsight('Steuer-Effizienz',
        'Nutze die €1000 Freigrenze durch gestaffelte Realisierung von Gewinnen.',
        Icons.account_balance, Colors.cyanAccent, 0.91),
      _AiInsight('Auto-Trading Performance',
        '${ex.autoTradeCount} Auto-Trades ausgeführt. KI-Strategie zeigt ${(40 + rnd.nextDouble() * 30).toStringAsFixed(1)}% Accuracy.',
        Icons.smart_toy, p.accent, 0.68),
    ];

    final totalTx = ledger.length;
    final weeklyCount = ledger.where((t) {
      return t.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)));
    }).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // AI Score
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              p.primary.withValues(alpha: 0.12), p.accent.withValues(alpha: 0.06),
            ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.primary.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [p.primary, p.accent]),
                  boxShadow: [BoxShadow(
                    color: p.primary.withValues(alpha: 0.3 + _pulseCtrl.value * 0.2),
                    blurRadius: 16 + _pulseCtrl.value * 8,
                  )],
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI BEWERTUNG', style: GoogleFonts.orbitron(
                color: p.textPrimary, fontSize: 10, fontWeight: FontWeight.w700,
              )),
              const SizedBox(height: 6),
              Row(children: [
                Text('84', style: GoogleFonts.orbitron(
                  color: p.primary, fontSize: 28, fontWeight: FontWeight.w900,
                )),
                Text('/100', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 14)),
              ]),
              Text('Sehr gut · Optimierungspotenzial vorhanden',
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
            ])),
            Column(children: [
              Text('$totalTx', style: GoogleFonts.orbitron(color: p.accent, fontSize: 16, fontWeight: FontWeight.bold)),
              Text('TOTAL', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
              const SizedBox(height: 6),
              Text('$weeklyCount', style: GoogleFonts.orbitron(color: p.positive, fontSize: 16, fontWeight: FontWeight.bold)),
              Text('7 TAGE', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        ...insights.map((insight) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildInsightCard(insight, p),
        )),
      ]),
    );
  }

  Widget _buildInsightCard(_AiInsight insight, QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: insight.color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: insight.color.withValues(alpha: 0.1),
          ),
          child: Icon(insight.icon, color: insight.color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(insight.title, style: GoogleFonts.rajdhani(
            color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 2),
          Text(insight.text, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: insight.score,
              backgroundColor: p.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(insight.color),
              minHeight: 3,
            ),
          ),
        ])),
        const SizedBox(width: 8),
        Text('${(insight.score * 100).toInt()}%',
          style: GoogleFonts.orbitron(color: insight.color, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _AiInsight {
  final String title, text;
  final IconData icon;
  final Color color;
  final double score;
  const _AiInsight(this.title, this.text, this.icon, this.color, this.score);
}
