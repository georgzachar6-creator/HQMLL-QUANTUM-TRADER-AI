// ============================================================
// CRYPTO TAX CALCULATOR – Quantum Trader v21
// FIFO / LIFO / Durchschnitt · P&L · Steuerreport · Export
// ============================================================
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/crypto_icon.dart';

import '../providers/theme_provider.dart';
import '../services/exchange_service.dart';

class TaxScreen extends StatefulWidget {
  const TaxScreen({super.key});
  @override
  State<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends State<TaxScreen> with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  int _selectedTab = 0;
  final _tabs = ['ÜBERSICHT', 'TRANSAKTIONEN', 'STEUERREPORT', 'EINSTELLUNGEN'];

  String _taxMethod = 'FIFO'; // FIFO / LIFO / Durchschnitt
  String _taxYear = '2024';
  String _country = 'Deutschland';
  bool _includeStaking = true;
  bool _includeMining = true;
  bool _includeAirdrop = false;

  // Simulated transactions
  final List<_TaxTx> _transactions = [
    _TaxTx(date: DateTime(2024, 1, 15), type: 'KAUF',   symbol: 'BTC', amount: 0.5,   price: 42000, fees: 21.0),
    _TaxTx(date: DateTime(2024, 2, 3),  type: 'KAUF',   symbol: 'ETH', amount: 2.0,   price: 2200,  fees: 8.8),
    _TaxTx(date: DateTime(2024, 3, 8),  type: 'VERKAUF',symbol: 'BTC', amount: 0.2,   price: 68000, fees: 27.2),
    _TaxTx(date: DateTime(2024, 4, 12), type: 'KAUF',   symbol: 'SOL', amount: 50.0,  price: 145,   fees: 14.5),
    _TaxTx(date: DateTime(2024, 5, 22), type: 'VERKAUF',symbol: 'ETH', amount: 1.0,   price: 3800,  fees: 15.2),
    _TaxTx(date: DateTime(2024, 6, 14), type: 'STAKING',symbol: 'ETH', amount: 0.042, price: 3500,  fees: 0),
    _TaxTx(date: DateTime(2024, 7, 5),  type: 'KAUF',   symbol: 'BNB', amount: 10.0,  price: 580,   fees: 11.6),
    _TaxTx(date: DateTime(2024, 8, 30), type: 'VERKAUF',symbol: 'SOL', amount: 20.0,  price: 182,   fees: 7.28),
    _TaxTx(date: DateTime(2024, 9, 11), type: 'KAUF',   symbol: 'ADA', amount: 5000,  price: 0.35,  fees: 3.5),
    _TaxTx(date: DateTime(2024, 10, 4), type: 'MINING', symbol: 'BTC', amount: 0.001, price: 62000, fees: 0),
    _TaxTx(date: DateTime(2024, 11, 18),type: 'VERKAUF',symbol: 'BNB', amount: 5.0,   price: 625,   fees: 6.25),
    _TaxTx(date: DateTime(2024, 12, 1), type: 'AIRDROP',symbol: 'LINK',amount: 100.0, price: 15.0,  fees: 0),
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _glowCtrl.dispose(); super.dispose(); }

  // ── Tax Calculation ───────────────────────────────────────
  Map<String, dynamic> _calcTax() {
    double totalPnl = 0;
    double shortTermPnl = 0;
    double longTermPnl = 0;
    double stakingIncome = 0;
    double miningIncome = 0;
    double airdropIncome = 0;
    double totalFees = 0;
    int shortTermCount = 0;
    int longTermCount = 0;

    for (final tx in _transactions) {
      if (tx.date.year != int.parse(_taxYear)) continue;
      totalFees += tx.fees;

      if (tx.type == 'VERKAUF') {
        // Find matching buy (simplified FIFO)
        final buyTx = _transactions.firstWhere(
          (t) => t.type == 'KAUF' && t.symbol == tx.symbol && t.date.isBefore(tx.date),
          orElse: () => _TaxTx(date: tx.date, type: 'KAUF', symbol: tx.symbol,
              amount: tx.amount, price: tx.price * 0.8, fees: 0),
        );
        final pnl = (tx.price - buyTx.price) * tx.amount - tx.fees;
        final holdDays = tx.date.difference(buyTx.date).inDays;

        if (_country == 'Deutschland' && holdDays > 365) {
          longTermPnl += pnl; // Steuerfrei in DE nach 1 Jahr
          longTermCount++;
        } else {
          shortTermPnl += pnl;
          shortTermCount++;
        }
        totalPnl += pnl;
      } else if (tx.type == 'STAKING' && _includeStaking) {
        stakingIncome += tx.amount * tx.price;
      } else if (tx.type == 'MINING' && _includeMining) {
        miningIncome += tx.amount * tx.price;
      } else if (tx.type == 'AIRDROP' && _includeAirdrop) {
        airdropIncome += tx.amount * tx.price;
      }
    }

    // German tax: 25% Abgeltungssteuer + Soli
    const taxRate = 0.25;
    const soliRate = 0.055;
    final taxableAmount = shortTermPnl + stakingIncome + miningIncome + airdropIncome;
    final taxBefore = taxableAmount > 0 ? taxableAmount * taxRate : 0.0;
    final soli = taxBefore * soliRate;
    final totalTax = taxBefore + soli;

    // Freigrenze (Germany: 1000€ since 2023)
    const freigrenze = 1000.0;
    final effectiveTax = taxableAmount > freigrenze ? totalTax : 0.0;

    return {
      'totalPnl': totalPnl,
      'shortTermPnl': shortTermPnl,
      'longTermPnl': longTermPnl,
      'stakingIncome': stakingIncome,
      'miningIncome': miningIncome,
      'airdropIncome': airdropIncome,
      'totalFees': totalFees,
      'taxableAmount': taxableAmount,
      'taxBefore': taxBefore,
      'soli': soli,
      'totalTax': effectiveTax,
      'freigrenze': freigrenze,
      'shortTermCount': shortTermCount,
      'longTermCount': longTermCount,
      'isFreigrenzeReached': taxableAmount > freigrenze,
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    final ex = context.watch<ExchangeService>();
    final tax = _calcTax();
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(p, tax, ex),
          _buildTabBar(p),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildOverviewTab(p, tax),
                _buildTransactionsTab(p),
                _buildReportTab(p, tax),
                _buildSettingsTab(p),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── HEADER ───────────────────────────────────────────────
  Widget _buildHeader(dynamic p, Map<String, dynamic> tax, ExchangeService ex) {
    final totalPnl = tax['totalPnl'] as double;
    final totalTax = tax['totalTax'] as double;
    final isPnlPos = totalPnl >= 0;
    final btcPrice = ex.getPrice('BTC');
    final ethPrice = ex.getPrice('ETH');
    final isLive = ex.getTick('BTC')?.isLive ?? false;

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
            Text('CRYPTO TAX', style: GoogleFonts.spaceMono(
              color: p.primary, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2,
            )),
            Text('$_taxYear · $_country · $_taxMethod', style: GoogleFonts.inter(
              color: p.textSecondary, fontSize: 11,
            )),
            if (btcPrice > 0)
              Row(children: [
                Text('BTC \$${btcPrice.toStringAsFixed(0)}  ETH \$${ethPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
                if (isLive) ...[const SizedBox(width: 4),
                  Container(width: 4, height: 4,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00FF88))),
                ],
              ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${isPnlPos ? "+" : ""}${totalPnl.toStringAsFixed(0)} €',
              style: GoogleFonts.spaceMono(
                color: isPnlPos ? const Color(0xFF00FF88) : const Color(0xFFFF3358),
                fontSize: 16, fontWeight: FontWeight.bold,
              ),
            ),
            Text('Steuer: ${totalTax.toStringAsFixed(0)} €', style: GoogleFonts.spaceMono(
              color: totalTax > 0 ? const Color(0xFFFFAA00) : const Color(0xFF00FF88),
              fontSize: 11,
            )),
          ]),
        ]),
      ),
    );
  }

  // ── TAB BAR ───────────────────────────────────────────────
  Widget _buildTabBar(dynamic p) {
    return Container(
      height: 36,
      color: p.surface.withValues(alpha: 0.8),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final sel = _selectedTab == i;
          return Expanded(child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedTab = i); },
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: sel ? p.primary : Colors.transparent, width: 2,
                )),
              ),
              child: Center(child: Text(_tabs[i], style: GoogleFonts.spaceMono(
                color: sel ? p.primary : p.textSecondary,
                fontSize: 8, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              ))),
            ),
          ));
        }),
      ),
    );
  }

  // ── OVERVIEW TAB ─────────────────────────────────────────
  Widget _buildOverviewTab(dynamic p, Map<String, dynamic> tax) {
    final totalPnl = tax['totalPnl'] as double;
    final shortTermPnl = tax['shortTermPnl'] as double;
    final longTermPnl = tax['longTermPnl'] as double;
    final stakingIncome = tax['stakingIncome'] as double;
    final miningIncome = tax['miningIncome'] as double;
    final taxableAmount = tax['taxableAmount'] as double;
    final totalTax = tax['totalTax'] as double;
    final totalFees = tax['totalFees'] as double;
    final freigrenze = tax['freigrenze'] as double;
    final freigrenzeReached = tax['isFreigrenzeReached'] as bool;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Main Tax Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (freigrenzeReached ? const Color(0xFFFFAA00) : const Color(0xFF00FF88))
                    .withValues(alpha: 0.12),
                const Color(0xFF00AAFF).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (freigrenzeReached ? const Color(0xFFFFAA00) : const Color(0xFF00FF88))
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('STEUERLAST $_taxYear', style: GoogleFonts.spaceMono(
                  color: p.textSecondary, fontSize: 10, letterSpacing: 1,
                )),
                Text(
                  '${totalTax.toStringAsFixed(2)} €',
                  style: GoogleFonts.spaceMono(
                    color: totalTax > 0 ? const Color(0xFFFFAA00) : const Color(0xFF00FF88),
                    fontSize: 28, fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  freigrenzeReached ? '⚠️ Freigrenze überschritten' : '✅ Unter Freigrenze (${freigrenze.toStringAsFixed(0)}€)',
                  style: GoogleFonts.inter(
                    color: freigrenzeReached ? const Color(0xFFFFAA00) : const Color(0xFF00FF88),
                    fontSize: 11,
                  ),
                ),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('BASIS', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
                Text('${taxableAmount.toStringAsFixed(2)} €', style: GoogleFonts.spaceMono(
                  color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold,
                )),
                Text('Methode: $_taxMethod', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
              ]),
            ]),
            const SizedBox(height: 14),
            // Progress bar to Freigrenze
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('FREIGRENZE PROGRESS', style: GoogleFonts.spaceMono(
                  color: p.textSecondary, fontSize: 8, letterSpacing: 0.5,
                )),
                Text('${min(taxableAmount, freigrenze).toStringAsFixed(0)} / ${freigrenze.toStringAsFixed(0)} €',
                    style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 9)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (taxableAmount / freigrenze).clamp(0, 1),
                  backgroundColor: p.primary.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(
                    freigrenzeReached ? const Color(0xFFFF3358) : const Color(0xFF00FF88),
                  ),
                  minHeight: 8,
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 14),

        // P&L Breakdown
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.primary.withValues(alpha: 0.1)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('P&L AUFSCHLÜSSELUNG', style: GoogleFonts.spaceMono(
              color: p.primary, fontSize: 10, letterSpacing: 1,
            )),
            const SizedBox(height: 12),
            _buildTaxRow(p, 'Gesamt P&L', totalPnl, showSign: true),
            _buildTaxRow(p, '├ Kurzfristig (<1 Jahr, steuerpflichtig)', shortTermPnl,
                color: shortTermPnl >= 0 ? const Color(0xFF00FF88) : const Color(0xFFFF3358), showSign: true),
            _buildTaxRow(p, '└ Langfristig (>1 Jahr, steuerfrei in DE)', longTermPnl,
                color: const Color(0xFF00AAFF), showSign: true),
            const Divider(height: 16),
            if (_includeStaking)
              _buildTaxRow(p, 'Staking Einkommen', stakingIncome, color: const Color(0xFFAA88FF)),
            if (_includeMining)
              _buildTaxRow(p, 'Mining Einkommen', miningIncome, color: const Color(0xFFF7931A)),
            const Divider(height: 16),
            _buildTaxRow(p, 'Gebühren (abzugsfähig)', -totalFees,
                color: const Color(0xFFFF3358), showSign: true),
            _buildTaxRow(p, 'STEUERBARES EINKOMMEN', taxableAmount,
                isBold: true, showSign: true),
          ]),
        ),
        const SizedBox(height: 12),

        // Tax Breakdown
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.primary.withValues(alpha: 0.1)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('STEUERBERECHNUNG ($_country)', style: GoogleFonts.spaceMono(
              color: p.primary, fontSize: 10, letterSpacing: 1,
            )),
            const SizedBox(height: 12),
            _buildTaxRow(p, 'Steuerbares Einkommen', taxableAmount),
            _buildTaxRow(p, '- Freigrenze', freigrenze, color: const Color(0xFF00FF88)),
            _buildTaxRow(p, '= Netto steuerpflichtig',
                taxableAmount > freigrenze ? taxableAmount - freigrenze : 0, isBold: true),
            _buildTaxRow(p, 'Abgeltungssteuer (25%)', tax['taxBefore'] as double,
                color: const Color(0xFFFFAA00)),
            _buildTaxRow(p, 'Solidaritätszuschlag (5.5%)', tax['soli'] as double,
                color: const Color(0xFFFFAA00)),
            const Divider(height: 16),
            _buildTaxRow(p, 'GESAMT STEUER', totalTax,
                isBold: true,
                color: totalTax > 0 ? const Color(0xFFFF3358) : const Color(0xFF00FF88)),
          ]),
        ),
        const SizedBox(height: 12),

        // Yearly comparison
        _buildYearlyComparison(p),
      ],
    );
  }

  Widget _buildTaxRow(dynamic p, String label, double value,
      {Color? color, bool isBold = false, bool showSign = false}) {
    final displayColor = color ?? p.textPrimary;
    final sign = showSign && value >= 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label, style: GoogleFonts.inter(
          color: p.textSecondary, fontSize: isBold ? 12 : 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ))),
        Text('$sign${value.toStringAsFixed(2)} €', style: GoogleFonts.spaceMono(
          color: displayColor, fontSize: isBold ? 12 : 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        )),
      ]),
    );
  }

  Widget _buildYearlyComparison(dynamic p) {
    final years = ['2022', '2023', '2024'];
    final taxValues = [1240.0, 2890.0, _calcTax()['totalTax'] as double];
    final maxTax = taxValues.reduce(max);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('JÄHRLICHER VERGLEICH', style: GoogleFonts.spaceMono(
          color: p.primary, fontSize: 10, letterSpacing: 1,
        )),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (int i = 0; i < years.length; i++) ...[
            Expanded(child: Column(children: [
              Text('${taxValues[i].toStringAsFixed(0)}€', style: GoogleFonts.spaceMono(
                color: years[i] == _taxYear ? p.primary : p.textSecondary, fontSize: 9,
              )),
              const SizedBox(height: 4),
              Container(
                height: maxTax > 0 ? 60 * (taxValues[i] / maxTax) : 10,
                decoration: BoxDecoration(
                  color: years[i] == _taxYear
                      ? p.primary.withValues(alpha: 0.6)
                      : p.textSecondary.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              const SizedBox(height: 4),
              Text(years[i], style: GoogleFonts.spaceMono(
                color: years[i] == _taxYear ? p.primary : p.textSecondary, fontSize: 9,
              )),
            ])),
            if (i < years.length - 1) const SizedBox(width: 8),
          ],
        ]),
      ]),
    );
  }

  // ── TRANSACTIONS TAB ─────────────────────────────────────
  Widget _buildTransactionsTab(dynamic p) {
    final yearTxs = _transactions
        .where((t) => t.date.year == int.parse(_taxYear))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(children: [
          Text('${yearTxs.length} Transaktionen $_taxYear', style: GoogleFonts.spaceMono(
            color: p.primary, fontSize: 11, letterSpacing: 1,
          )),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('CSV Export (Demo)', style: GoogleFonts.inter(color: Colors.white)),
                backgroundColor: p.primary,
              ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: p.primary.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(Icons.download_rounded, color: p.primary, size: 12),
                const SizedBox(width: 4),
                Text('CSV', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 9)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        ...yearTxs.map((t) => _buildTxCard(p, t)),
      ],
    );
  }

  Widget _buildTxCard(dynamic p, _TaxTx tx) {
    final typeColor = _txColor(tx.type);
    final typeIcon = _txIcon(tx.type);
    final isPnlTx = tx.type == 'VERKAUF';

    double? pnl;
    if (isPnlTx) {
      final buy = _transactions.firstWhere(
        (t) => t.type == 'KAUF' && t.symbol == tx.symbol && t.date.isBefore(tx.date),
        orElse: () => _TaxTx(date: tx.date, type: 'KAUF', symbol: tx.symbol,
            amount: tx.amount, price: tx.price * 0.8, fees: 0),
      );
      pnl = (tx.price - buy.price) * tx.amount - tx.fees;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: typeColor.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Stack(
          children: [
            CryptoIcon(tx.symbol, size: 38, showShadow: false),
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: typeColor,
                  border: Border.all(color: p.surface, width: 1.5),
                ),
                child: Icon(typeIcon, color: Colors.white, size: 9),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${tx.type} ${tx.symbol}', style: GoogleFonts.spaceMono(
            color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold,
          )),
          Text('${_fmtDate(tx.date)} · Gebühr: ${tx.fees.toStringAsFixed(2)}€', style: GoogleFonts.inter(
            color: p.textSecondary, fontSize: 10,
          )),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${tx.amount} ${tx.symbol}', style: GoogleFonts.spaceMono(
            color: p.textPrimary, fontSize: 11,
          )),
          Text('@${tx.price >= 100 ? tx.price.toStringAsFixed(0) : tx.price.toStringAsFixed(4)} €', style: GoogleFonts.inter(
            color: p.textSecondary, fontSize: 10,
          )),
          if (pnl != null)
            Text(
              '${pnl >= 0 ? "+" : ""}${pnl.toStringAsFixed(2)}€',
              style: GoogleFonts.spaceMono(
                color: pnl >= 0 ? const Color(0xFF00FF88) : const Color(0xFFFF3358),
                fontSize: 10, fontWeight: FontWeight.bold,
              ),
            ),
        ]),
      ]),
    );
  }

  Color _txColor(String type) {
    switch (type) {
      case 'KAUF': return const Color(0xFF00FF88);
      case 'VERKAUF': return const Color(0xFFFF3358);
      case 'STAKING': return const Color(0xFFAA88FF);
      case 'MINING': return const Color(0xFFF7931A);
      case 'AIRDROP': return const Color(0xFF00AAFF);
      default: return const Color(0xFF888888);
    }
  }

  IconData _txIcon(String type) {
    switch (type) {
      case 'KAUF': return Icons.add_circle;
      case 'VERKAUF': return Icons.remove_circle;
      case 'STAKING': return Icons.lock;
      case 'MINING': return Icons.hardware;
      case 'AIRDROP': return Icons.cloud_download;
      default: return Icons.swap_horiz;
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  // ── REPORT TAB ────────────────────────────────────────────
  Widget _buildReportTab(dynamic p, Map<String, dynamic> tax) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.primary.withValues(alpha: 0.15)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.description_outlined, color: p.primary, size: 20),
              const SizedBox(width: 8),
              Text('STEUERREPORT $_taxYear', style: GoogleFonts.spaceMono(
                color: p.primary, fontSize: 13, letterSpacing: 1,
              )),
            ]),
            const SizedBox(height: 4),
            Text('Generiert für: $_country · Methode: $_taxMethod', style: GoogleFonts.inter(
              color: p.textSecondary, fontSize: 10,
            )),
            const Divider(height: 24),
            Text('ZUSAMMENFASSUNG', style: GoogleFonts.spaceMono(
              color: p.textSecondary, fontSize: 9, letterSpacing: 1,
            )),
            const SizedBox(height: 8),
            _buildReportLine(p, 'Realisierte Gewinne (kurzfristig)',
                '${(tax['shortTermPnl'] as double).toStringAsFixed(2)} €'),
            _buildReportLine(p, 'Steuerfreie Gewinne (>1 Jahr)',
                '${(tax['longTermPnl'] as double).toStringAsFixed(2)} €'),
            _buildReportLine(p, 'Staking Einkommen',
                '${(tax['stakingIncome'] as double).toStringAsFixed(2)} €'),
            _buildReportLine(p, 'Mining Einkommen',
                '${(tax['miningIncome'] as double).toStringAsFixed(2)} €'),
            _buildReportLine(p, 'Gezahlte Gebühren',
                '- ${(tax['totalFees'] as double).toStringAsFixed(2)} €'),
            const Divider(height: 16),
            _buildReportLine(p, 'Steuerbares Einkommen',
                '${(tax['taxableAmount'] as double).toStringAsFixed(2)} €', bold: true),
            _buildReportLine(p, 'Abgeltungssteuer (25%)',
                '${(tax['taxBefore'] as double).toStringAsFixed(2)} €'),
            _buildReportLine(p, 'Solidaritätszuschlag',
                '${(tax['soli'] as double).toStringAsFixed(2)} €'),
            const Divider(height: 16),
            _buildReportLine(p, 'GESAMTE STEUERLAST',
                '${(tax['totalTax'] as double).toStringAsFixed(2)} €', bold: true,
                color: const Color(0xFFFFAA00)),
          ]),
        ),
        const SizedBox(height: 14),
        // Export buttons
        Row(children: [
          Expanded(child: _buildExportBtn(p, 'PDF EXPORT', Icons.picture_as_pdf, const Color(0xFFFF3358))),
          const SizedBox(width: 8),
          Expanded(child: _buildExportBtn(p, 'CSV EXPORT', Icons.table_chart, const Color(0xFF00FF88))),
          const SizedBox(width: 8),
          Expanded(child: _buildExportBtn(p, 'WISO/TAXMAN', Icons.send, const Color(0xFF00AAFF))),
        ]),
        const SizedBox(height: 12),
        // Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFAA00).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFAA00).withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.warning_amber, color: Color(0xFFFFAA00), size: 14),
              const SizedBox(width: 6),
              Text('HAFTUNGSAUSSCHLUSS', style: GoogleFonts.spaceMono(
                color: const Color(0xFFFFAA00), fontSize: 9,
              )),
            ]),
            const SizedBox(height: 6),
            Text(
              'Diese Berechnung dient nur zur Orientierung. Für eine rechtssichere Steuererklärung konsultieren Sie bitte einen Steuerberater.',
              style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10, height: 1.5),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildReportLine(dynamic p, String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(label, style: GoogleFonts.inter(
          color: p.textSecondary, fontSize: bold ? 12 : 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ))),
        Text(value, style: GoogleFonts.spaceMono(
          color: color ?? p.textPrimary, fontSize: bold ? 12 : 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        )),
      ]),
    );
  }

  Widget _buildExportBtn(dynamic p, String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$label (Demo)', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: color,
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.spaceMono(color: color, fontSize: 7, letterSpacing: 0.5)),
        ]),
      ),
    );
  }

  // ── SETTINGS TAB ─────────────────────────────────────────
  Widget _buildSettingsTab(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSettingsSection(p, 'BERECHNUNGSMETHODE'),
        ...[('FIFO', 'First In, First Out'), ('LIFO', 'Last In, First Out'), ('Durchschnitt', 'Durchschnittskostenmethode')]
            .map((m) => _buildRadioTile(p, m.$1, m.$2, _taxMethod, (v) => setState(() => _taxMethod = v!))),
        const SizedBox(height: 12),
        _buildSettingsSection(p, 'STEUERJAHR'),
        ...['2022', '2023', '2024', '2025'].map((y) => _buildRadioTile(p, y, '', _taxYear, (v) => setState(() => _taxYear = v!))),
        const SizedBox(height: 12),
        _buildSettingsSection(p, 'LAND'),
        ...['Deutschland', 'Österreich', 'Schweiz', 'USA'].map((c) => _buildRadioTile(p, c, '', _country, (v) => setState(() => _country = v!))),
        const SizedBox(height: 12),
        _buildSettingsSection(p, 'EINKOMMENSARTEN'),
        _buildSwitchTile(p, 'Staking Rewards einberechnen', _includeStaking, (v) => setState(() => _includeStaking = v)),
        _buildSwitchTile(p, 'Mining Rewards einberechnen', _includeMining, (v) => setState(() => _includeMining = v)),
        _buildSwitchTile(p, 'Airdrops einberechnen', _includeAirdrop, (v) => setState(() => _includeAirdrop = v)),
      ],
    );
  }

  Widget _buildSettingsSection(dynamic p, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title, style: GoogleFonts.spaceMono(
        color: p.primary, fontSize: 9, letterSpacing: 1,
      )),
    );
  }

  Widget _buildRadioTile(dynamic p, String val, String sub, String groupVal, ValueChanged<String?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: val == groupVal ? p.primary.withValues(alpha: 0.05) : p.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: val == groupVal ? p.primary.withValues(alpha: 0.25) : p.primary.withValues(alpha: 0.06),
        ),
      ),
      // ignore: deprecated_member_use
      child: RadioListTile<String>(
        // ignore: deprecated_member_use
        value: val, groupValue: groupVal,
        // ignore: deprecated_member_use
        onChanged: onChanged,
        title: Text(val, style: GoogleFonts.inter(color: p.textPrimary, fontSize: 12)),
        subtitle: sub.isNotEmpty ? Text(sub, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)) : null,
        dense: true,
      ),
    );
  }

  Widget _buildSwitchTile(dynamic p, String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.primary.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        Expanded(child: Text(label, style: GoogleFonts.inter(color: p.textPrimary, fontSize: 12))),
        Switch(value: value, onChanged: onChanged, activeTrackColor: p.primary.withValues(alpha: 0.3)),
      ]),
    );
  }
}

// ── Model ─────────────────────────────────────────────────
class _TaxTx {
  final DateTime date;
  final String type, symbol;
  final double amount, price, fees;
  const _TaxTx({required this.date, required this.type, required this.symbol,
      required this.amount, required this.price, required this.fees});
}
