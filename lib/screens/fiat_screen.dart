/// HQMLL Quantum Trader – Fiat Transaction Screen v3
/// EUR/USD Live Broker API · Bank Transfer · SEPA · SWIFT
/// v38.0: Secure Bank Account Integration (local encrypted storage)
/// Grigori Saks · 2025
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';
import '../services/exchange_service.dart';
import '../services/persistence_service.dart';

// ── Fiat Transaction Model ─────────────────────────────
class FiatTransaction {
  final String id;
  final String type; // deposit | withdraw | exchange | transfer
  final String fromCurrency;
  final String toCurrency;
  final double amount;
  final double convertedAmount;
  final double rate;
  final double fee;
  final String status; // pending | completed | failed | processing
  final DateTime createdAt;
  final String? reference;
  final String? bankName;

  FiatTransaction({
    required this.id,
    required this.type,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    required this.convertedAmount,
    required this.rate,
    required this.fee,
    required this.status,
    required this.createdAt,
    this.reference,
    this.bankName,
  });
}

// ── Live FX Rate Model ─────────────────────────────────
class FxRate {
  final String pair;
  final double bid;
  final double ask;
  final double mid;
  final double change24h;
  final DateTime updatedAt;

  FxRate({
    required this.pair,
    required this.bid,
    required this.ask,
    required this.mid,
    required this.change24h,
    required this.updatedAt,
  });

  bool get isPositive => change24h >= 0;
  String get formattedMid => mid.toStringAsFixed(4);
  String get spread => ((ask - bid) * 10000).toStringAsFixed(1);
}

// ═══════════════════════════════════════════════════════
// FIAT SCREEN
// ═══════════════════════════════════════════════════════
class FiatScreen extends StatefulWidget {
  const FiatScreen({super.key});
  @override
  State<FiatScreen> createState() => _FiatScreenState();
}

class _FiatScreenState extends State<FiatScreen> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  Timer? _fxTimer;
  final Random _rng = Random(77);

  // FX Rates
  final List<FxRate> _fxRates = [];
  final List<FiatTransaction> _transactions = [];

  // v36.0: Live crypto-to-USD rates — seeded by ExchangeService on first frame
  static const _fallbackCryptoRates = <String, double>{
    'BTC': 67842.0, 'ETH': 3548.0, 'SOL': 182.0, 'BNB': 598.0,
    'USDT': 1.0, 'USDC': 1.0,
  };
  final Map<String, double> _cryptoToUsd = {
    'BTC': 67842.0, 'ETH': 3548.0, 'SOL': 182.0, 'BNB': 598.0,
    'USDT': 1.0, 'USDC': 1.0,
  };

  // Form controllers
  final _fromCtrl = TextEditingController(text: '1000');
  final _toCtrl = TextEditingController();
  String _fromCurrency = 'EUR';
  String _toCurrency = 'USD';
  String _txType = 'exchange'; // deposit | withdraw | exchange | transfer
  bool _isProcessing = false;

  // Account balances
  final Map<String, double> _balances = {
    'EUR': 8420.50,
    'USD': 12340.80,
    'GBP': 3210.00,
    'CHF': 2150.75,
    'JPY': 145000.00,
    'BTC': 0.2841,
    'ETH': 3.4512,
    'USDT': 5500.00,
  };

  static const List<String> _fiatCurrencies = ['EUR', 'USD', 'GBP', 'CHF', 'JPY', 'CAD', 'AUD'];
  static const List<String> _cryptoCurrencies = ['BTC', 'ETH', 'USDT', 'USDC', 'BNB'];

  // v36.0: Sync live crypto rates from ExchangeService into _cryptoToUsd state field
  void _syncCryptoRatesFromExchange(ExchangeService ex) {
    bool updated = false;
    for (final sym in _fallbackCryptoRates.keys) {
      if (sym == 'USDT' || sym == 'USDC') continue;
      final live = ex.getPrice(sym);
      if (live > 0 && live != _cryptoToUsd[sym]) {
        _cryptoToUsd[sym] = live;
        updated = true;
      }
    }
    if (updated) _updateConvertedAmount();
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _initFxRates();
    _initTransactions();
    _startFxUpdates();
    _updateConvertedAmount();
    // v36.0: Ersten-Frame Seed — Crypto-Kreuzraten sofort live
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ex = context.read<ExchangeService>();
      setState(() => _syncCryptoRatesFromExchange(ex));
    });
  }

  void _initFxRates() {
    final pairs = [
      ('EUR/USD', 1.0842, 1.0844, 0.23),
      ('GBP/USD', 1.2654, 1.2656, -0.14),
      ('USD/JPY', 154.82, 154.84, 0.08),
      ('USD/CHF', 0.9012, 0.9014, -0.31),
      ('EUR/GBP', 0.8568, 0.8570, 0.11),
      ('EUR/CHF', 0.9770, 0.9772, -0.09),
      ('AUD/USD', 0.6542, 0.6544, 0.44),
      ('USD/CAD', 1.3621, 1.3623, 0.18),
    ];
    for (final p in pairs) {
      _fxRates.add(FxRate(
        pair: p.$1,
        bid: p.$2,
        ask: p.$3,
        mid: (p.$2 + p.$3) / 2,
        change24h: p.$4,
        updatedAt: DateTime.now(),
      ));
    }
  }

  void _initTransactions() {
    final types = ['deposit', 'withdraw', 'exchange', 'transfer'];
    final statuses = ['completed', 'completed', 'completed', 'processing', 'pending'];
    final banks = ['Deutsche Bank', 'Commerzbank', 'ING', 'N26', 'Revolut'];
    for (int i = 0; i < 15; i++) {
      final type = types[i % types.length];
      final from = i % 2 == 0 ? 'EUR' : 'USD';
      final to = i % 2 == 0 ? 'USD' : 'EUR';
      final amt = 100.0 + _rng.nextDouble() * 4900;
      _transactions.add(FiatTransaction(
        id: 'FX${1000 + i}',
        type: type,
        fromCurrency: from,
        toCurrency: to,
        amount: amt,
        convertedAmount: amt * (1.0842 + _rng.nextDouble() * 0.01),
        rate: 1.0842 + _rng.nextDouble() * 0.01,
        fee: amt * 0.001,
        status: statuses[i % statuses.length],
        createdAt: DateTime.now().subtract(Duration(hours: i * 4 + _rng.nextInt(3))),
        reference: 'REF${100000 + i}',
        bankName: type == 'deposit' || type == 'withdraw' ? banks[i % banks.length] : null,
      ));
    }
    _transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _startFxUpdates() {
    _fxTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _fxRates.length; i++) {
          final r = _fxRates[i];
          final delta = (_rng.nextDouble() - 0.5) * 0.0008;
          _fxRates[i] = FxRate(
            pair: r.pair,
            bid: r.bid + delta,
            ask: r.ask + delta,
            mid: r.mid + delta,
            change24h: r.change24h + (_rng.nextDouble() - 0.5) * 0.02,
            updatedAt: DateTime.now(),
          );
        }
      });
      _updateConvertedAmount();
    });
  }

  double _getRate(String from, String to) {
    final pair = '$from/$to';
    final pairRev = '$to/$from';
    for (final r in _fxRates) {
      if (r.pair == pair) return r.mid;
      if (r.pair == pairRev) return 1.0 / r.mid;
    }
    // v36.0: Use live _cryptoToUsd state field (seeded by ExchangeService on first frame)
    const fiatToUsd = {
      'USD': 1.0, 'EUR': 1.0842, 'GBP': 1.2654,
      'CHF': 1.0 / 0.9012, 'JPY': 1.0 / 154.82, 'CAD': 1.0 / 1.3621, 'AUD': 0.6543,
    };
    final fromUsd = _cryptoToUsd[from] ?? fiatToUsd[from] ?? 1.0;
    final toUsd = _cryptoToUsd[to] ?? fiatToUsd[to] ?? 1.0;
    return fromUsd / toUsd;
  }

  void _updateConvertedAmount() {
    final amt = double.tryParse(_fromCtrl.text) ?? 0;
    final rate = _getRate(_fromCurrency, _toCurrency);
    final converted = amt * rate;
    if (mounted) {
      _toCtrl.text = converted.toStringAsFixed(
        _toCurrency == 'JPY' ? 0 : (_cryptoCurrencies.contains(_toCurrency) ? 6 : 2)
      );
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _fxTimer?.cancel();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    final ex = context.watch<ExchangeService>();
    // v36.0: Reactive live rate sync on every ExchangeService update
    _syncCryptoRatesFromExchange(ex);
    return Scaffold(
      backgroundColor: p.background,
      body: Column(
        children: [
          _buildHeader(p, ex),
          _buildTabBar(p),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildFxRatesTab(p),
                _buildExchangeTab(p),
                _buildTransactionsTab(p),
                _buildBankingTab(p),
                _buildMyAccountsTab(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────
  Widget _buildHeader(QuantumPalette p, ExchangeService ex) {
    final btcPrice = ex.getPrice('BTC');
    final ethPrice = ex.getPrice('ETH');
    final isLive = ex.getTick('BTC')?.isLive ?? false;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.surface, p.background],
        ),
        border: Border(bottom: BorderSide(color: const Color(0xFF003399).withValues(alpha: 0.4))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFF003399), Color(0xFFFFCC00)]),
                  boxShadow: [BoxShadow(color: const Color(0xFF003399).withValues(alpha: 0.4), blurRadius: 10)],
                ),
                child: const Center(child: Text('€\$', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FIAT BROKER', style: GoogleFonts.orbitron(
                      color: p.textPrimary, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    Row(children: [
                      if (btcPrice > 0)
                        Text('BTC \$${btcPrice.toStringAsFixed(0)}  ETH \$${ethPrice.toStringAsFixed(0)}',
                            style: TextStyle(color: p.textSecondary, fontSize: 10)),
                      if (isLive) ...[const SizedBox(width: 5),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFF00FF88).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
                          child: Text('LIVE', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 7, letterSpacing: 1)))],
                      if (btcPrice <= 0) Text('EUR · USD · GBP · CHF', style: TextStyle(color: p.textSecondary, fontSize: 10)),
                    ]),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green.withValues(alpha: 0.15 + _pulseCtrl.value * 0.1),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withValues(alpha: 0.7 + _pulseCtrl.value * 0.3),
                      )),
                      const SizedBox(width: 5),
                      Text('LIVE FX', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBalanceChip('EUR', _balances['EUR']!, '€', const Color(0xFF003399), p),
              const SizedBox(width: 8),
              _buildBalanceChip('USD', _balances['USD']!, '\$', Colors.green, p),
              const SizedBox(width: 8),
              _buildBalanceChip('GBP', _balances['GBP']!, '£', const Color(0xFF003399), p),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceChip(String currency, double balance, String symbol, Color color, QuantumPalette p) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currency, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
            Text('$symbol${balance.toStringAsFixed(currency == 'JPY' ? 0 : 2)}',
                style: TextStyle(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────
  Widget _buildTabBar(QuantumPalette p) {
    return Container(
      color: p.surface,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: const Color(0xFF003399),
        indicatorWeight: 2,
        labelColor: const Color(0xFF003399),
        unselectedLabelColor: p.textSecondary,
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        tabs: const [
          Tab(text: 'FX RATES', icon: Icon(Icons.currency_exchange, size: 14)),
          Tab(text: 'EXCHANGE', icon: Icon(Icons.swap_horiz, size: 14)),
          Tab(text: 'HISTORY', icon: Icon(Icons.history, size: 14)),
          Tab(text: 'BANKING', icon: Icon(Icons.account_balance, size: 14)),
          Tab(text: 'MY BANK', icon: Icon(Icons.credit_card, size: 14)),
        ],
      ),
    );
  }

  // ── FX Rates Tab ──────────────────────────────────
  Widget _buildFxRatesTab(QuantumPalette p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionTitle('LIVE FX RATES', Icons.timeline, const Color(0xFF003399), p),
        const SizedBox(height: 8),
        ...List.generate(_fxRates.length, (i) => _buildFxRateCard(_fxRates[i], p)),
        const SizedBox(height: 16),
        _buildSectionTitle('CRYPTO/FIAT PAIRS', Icons.currency_bitcoin, const Color(0xFF00D4FF), p),
        const SizedBox(height: 8),
        _buildCryptoFiatGrid(p),
      ],
    );
  }

  Widget _buildFxRateCard(FxRate rate, QuantumPalette p) {
    final isPos = rate.isPositive;
    final chgColor = isPos ? Colors.greenAccent : Colors.redAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: p.surface,
        border: Border.all(color: p.textSecondary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: const Color(0xFF003399).withValues(alpha: 0.1),
              border: Border.all(color: const Color(0xFF003399).withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(rate.pair.substring(0, 3),
                style: const TextStyle(color: Color(0xFF003399), fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rate.pair, style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                Text('Spread: ${rate.spread} pips', style: TextStyle(color: p.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rate.formattedMid, style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
              Text('${isPos ? '+' : ''}${rate.change24h.toStringAsFixed(3)}%',
                style: TextStyle(color: chgColor, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('B: ${rate.bid.toStringAsFixed(4)}', style: TextStyle(color: Colors.greenAccent, fontSize: 9)),
              Text('A: ${rate.ask.toStringAsFixed(4)}', style: TextStyle(color: Colors.redAccent, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoFiatGrid(QuantumPalette p) {
    final pairs = [
      ('BTC/EUR', _getRate('BTC', 'EUR')),
      ('BTC/USD', _getRate('BTC', 'USD')),
      ('ETH/EUR', _getRate('ETH', 'EUR')),
      ('ETH/USD', _getRate('ETH', 'USD')),
      ('BNB/EUR', _getRate('BNB', 'EUR')),
      ('USDT/EUR', _getRate('USDT', 'EUR')),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 2.6, crossAxisSpacing: 8, mainAxisSpacing: 8,
      ),
      itemCount: pairs.length,
      itemBuilder: (_, i) {
        final pair = pairs[i];
        final isCrypto = pair.$1.startsWith('BTC') || pair.$1.startsWith('ETH') || pair.$1.startsWith('BNB');
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: p.surface,
            border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(pair.$1, style: TextStyle(color: isCrypto ? const Color(0xFF00D4FF) : const Color(0xFFFFCC00),
                  fontSize: 10, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(pair.$2 >= 1000 ? pair.$2.toStringAsFixed(0) : pair.$2.toStringAsFixed(4),
                style: TextStyle(color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
        );
      },
    );
  }

  // ── Exchange Tab ──────────────────────────────────
  Widget _buildExchangeTab(QuantumPalette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildExchangeCard(p),
          const SizedBox(height: 16),
          _buildTransactionTypeSelector(p),
          const SizedBox(height: 16),
          _buildExecuteButton(p),
          const SizedBox(height: 16),
          _buildRateInfo(p),
        ],
      ),
    );
  }

  Widget _buildExchangeCard(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: p.surface,
        border: Border.all(color: const Color(0xFF003399).withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: const Color(0xFF003399).withValues(alpha: 0.1), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Text('CURRENCY EXCHANGE', style: GoogleFonts.orbitron(
            color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 16),
          // From
          _buildCurrencyInput('Von', _fromCurrency, _fromCtrl, _fiatCurrencies + _cryptoCurrencies, true, p),
          const SizedBox(height: 8),
          // Swap button
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  final tmp = _fromCurrency;
                  _fromCurrency = _toCurrency;
                  _toCurrency = tmp;
                  _updateConvertedAmount();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF003399).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFF003399).withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.swap_vert, color: Color(0xFF003399), size: 22),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // To
          _buildCurrencyInput('Nach', _toCurrency, _toCtrl, _fiatCurrencies + _cryptoCurrencies, false, p),
          const SizedBox(height: 12),
          // Rate summary
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF003399).withValues(alpha: 0.05),
              border: Border.all(color: const Color(0xFF003399).withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rate:', style: TextStyle(color: p.textSecondary, fontSize: 12)),
                Text('1 $_fromCurrency = ${_getRate(_fromCurrency, _toCurrency).toStringAsFixed(4)} $_toCurrency',
                  style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyInput(String label, String currency, TextEditingController ctrl,
      List<String> currencies, bool editable, QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: p.background,
        border: Border.all(color: p.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: p.textSecondary, fontSize: 10)),
                const SizedBox(height: 4),
                TextField(
                  controller: ctrl,
                  enabled: editable,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: editable ? (_) => _updateConvertedAmount() : null,
                  style: TextStyle(color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showCurrencyPicker(currencies, currency, (c) {
              setState(() {
                if (editable) _fromCurrency = c;
                else _toCurrency = c;
                _updateConvertedAmount();
              });
            }, p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF003399).withValues(alpha: 0.1),
                border: Border.all(color: const Color(0xFF003399).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(currency, style: const TextStyle(color: Color(0xFF003399),
                      fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: Color(0xFF003399), size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(List<String> currencies, String selected,
      ValueChanged<String> onSelect, QuantumPalette p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Währung wählen', style: TextStyle(
              color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          ...currencies.map((c) => ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currencyColor(c).withValues(alpha: 0.15),
              ),
              child: Center(child: Text(_currencySymbol(c),
                style: TextStyle(color: _currencyColor(c), fontWeight: FontWeight.w900))),
            ),
            title: Text(c, style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600)),
            subtitle: Text(_currencyName(c), style: TextStyle(color: p.textSecondary, fontSize: 11)),
            trailing: c == selected ? Icon(Icons.check, color: const Color(0xFF003399)) : null,
            onTap: () {
              Navigator.pop(context);
              onSelect(c);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTransactionTypeSelector(QuantumPalette p) {
    final types = [
      ('exchange', Icons.swap_horiz, 'EXCHANGE'),
      ('deposit', Icons.add_circle_outline, 'DEPOSIT'),
      ('withdraw', Icons.remove_circle_outline, 'WITHDRAW'),
      ('transfer', Icons.send, 'TRANSFER'),
    ];
    return Row(
      children: types.map((t) {
        final isSelected = _txType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _txType = t.$1),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isSelected ? const Color(0xFF003399).withValues(alpha: 0.2) : p.surface,
                border: Border.all(
                  color: isSelected ? const Color(0xFF003399) : p.textSecondary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Icon(t.$2, color: isSelected ? const Color(0xFF003399) : p.textSecondary, size: 18),
                  const SizedBox(height: 3),
                  Text(t.$3, style: TextStyle(
                    color: isSelected ? const Color(0xFF003399) : p.textSecondary,
                    fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExecuteButton(QuantumPalette p) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _executeTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003399),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isProcessing
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                _txType == 'exchange' ? '⚡ JETZT KONVERTIEREN'
                  : _txType == 'deposit' ? '📥 EINZAHLEN'
                  : _txType == 'withdraw' ? '📤 AUSZAHLEN'
                  : '📡 ÜBERWEISEN',
                style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
      ),
    );
  }

  Future<void> _executeTransaction() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final amt = double.tryParse(_fromCtrl.text) ?? 0;
    final converted = double.tryParse(_toCtrl.text) ?? 0;
    final rate = _getRate(_fromCurrency, _toCurrency);
    setState(() {
      _isProcessing = false;
      _transactions.insert(0, FiatTransaction(
        id: 'FX${DateTime.now().millisecondsSinceEpoch % 100000}',
        type: _txType,
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
        amount: amt,
        convertedAmount: converted,
        rate: rate,
        fee: amt * 0.001,
        status: 'completed',
        createdAt: DateTime.now(),
        reference: 'REF${DateTime.now().millisecondsSinceEpoch % 1000000}',
      ));
      if (_balances.containsKey(_fromCurrency)) _balances[_fromCurrency] = (_balances[_fromCurrency]! - amt).clamp(0, double.infinity);
      if (_balances.containsKey(_toCurrency)) _balances[_toCurrency] = (_balances[_toCurrency]! + converted);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ $_txType: $amt $_fromCurrency → ${converted.toStringAsFixed(2)} $_toCurrency'),
      backgroundColor: Colors.green.shade700,
    ));
  }

  Widget _buildRateInfo(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: p.surface,
        border: Border.all(color: p.textSecondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          _buildInfoRow('Gebühr', '0.10%', p),
          _buildInfoRow('Abwicklung', 'Instant', p),
          _buildInfoRow('Limit/Tag', '€10,000', p),
          _buildInfoRow('Provider', 'HQMLL Broker', p),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, QuantumPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: p.textSecondary, fontSize: 12)),
          Text(value, style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Transactions Tab ──────────────────────────────
  Widget _buildTransactionsTab(QuantumPalette p) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _transactions.length,
      itemBuilder: (_, i) => _buildTransactionCard(_transactions[i], p),
    );
  }

  Widget _buildTransactionCard(FiatTransaction tx, QuantumPalette p) {
    final color = tx.type == 'deposit' ? Colors.greenAccent
        : tx.type == 'withdraw' ? Colors.redAccent
        : const Color(0xFF003399);
    final statusColor = tx.status == 'completed' ? Colors.greenAccent
        : tx.status == 'processing' ? Colors.orangeAccent
        : tx.status == 'pending' ? Colors.blueAccent : Colors.redAccent;
    final icon = tx.type == 'deposit' ? Icons.add_circle_outline
        : tx.type == 'withdraw' ? Icons.remove_circle_outline
        : tx.type == 'exchange' ? Icons.swap_horiz : Icons.send;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: p.surface,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tx.fromCurrency} → ${tx.toCurrency}',
                  style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                Text('${tx.type.toUpperCase()} · ${tx.reference}',
                  style: TextStyle(color: p.textSecondary, fontSize: 10)),
                if (tx.bankName != null)
                  Text(tx.bankName!, style: TextStyle(color: const Color(0xFF003399), fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${tx.amount.toStringAsFixed(2)} ${tx.fromCurrency}',
                style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w800, fontSize: 12)),
              Text('→ ${tx.convertedAmount.toStringAsFixed(2)} ${tx.toCurrency}',
                style: TextStyle(color: color, fontSize: 10)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: statusColor.withValues(alpha: 0.12),
                ),
                child: Text(tx.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Banking Tab ───────────────────────────────────
  Widget _buildBankingTab(QuantumPalette p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionTitle('BANK ACCOUNTS', Icons.account_balance, const Color(0xFF003399), p),
        const SizedBox(height: 8),
        ..._buildBankCards(p),
        const SizedBox(height: 16),
        _buildSectionTitle('PAYMENT METHODS', Icons.payment, Colors.orangeAccent, p),
        const SizedBox(height: 8),
        _buildPaymentMethodsGrid(p),
        const SizedBox(height: 16),
        _buildSectionTitle('SEPA / SWIFT', Icons.public, Colors.blueAccent, p),
        const SizedBox(height: 8),
        _buildSepaCard(p),
      ],
    );
  }

  List<Widget> _buildBankCards(QuantumPalette p) {
    final banks = [
      ('Deutsche Bank', 'DE89 3704 0044 0532 0130 00', 'DEUTDEDB', 'EUR', 8420.50),
      ('N26', 'DE42 1001 0010 0420 1269 00', 'NTSBDEB1', 'EUR', 2840.00),
      ('Revolut', 'GB29 REVO 0099 6959 4571 64', 'REVOGB21', 'GBP', 3210.00),
    ];
    return banks.map((b) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [const Color(0xFF003399).withValues(alpha: 0.15), p.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF003399).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xFF003399).withValues(alpha: 0.2),
                ),
                child: Text(b.$1, style: const TextStyle(color: Color(0xFF003399), fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const Spacer(),
              Text('${b.$4} ${b.$5.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(b.$2, style: TextStyle(color: p.textSecondary, fontSize: 11, letterSpacing: 1)),
          Text('BIC: ${b.$3}', style: TextStyle(color: p.textSecondary, fontSize: 10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => Clipboard.setData(ClipboardData(text: b.$2)),
                icon: const Icon(Icons.copy, size: 14, color: Color(0xFF003399)),
                label: const Text('IBAN kopieren', style: TextStyle(color: Color(0xFF003399), fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    )).toList();
  }

  Widget _buildPaymentMethodsGrid(QuantumPalette p) {
    final methods = [
      (Icons.credit_card, 'VISA / MC', Colors.blue),
      (Icons.account_balance, 'SEPA', const Color(0xFF003399)),
      (Icons.send, 'SWIFT', Colors.purple),
      (Icons.smartphone, 'Apple Pay', Colors.grey),
      (Icons.g_mobiledata, 'Google Pay', Colors.green),
      (Icons.currency_bitcoin, 'Crypto', const Color(0xFF00D4FF)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 1.4, crossAxisSpacing: 8, mainAxisSpacing: 8,
      ),
      itemCount: methods.length,
      itemBuilder: (_, i) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: p.surface,
          border: Border.all(color: methods[i].$3.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(methods[i].$1, color: methods[i].$3, size: 24),
            const SizedBox(height: 4),
            Text(methods[i].$2, style: TextStyle(color: p.textPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSepaCard(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: p.surface,
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.public, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text('SEPA INSTANT TRANSFER', style: TextStyle(
                color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Max. Betrag', '€100,000', p),
          _buildInfoRow('Gebühr', 'Kostenlos', p),
          _buildInfoRow('Abwicklung', '< 10 Sekunden', p),
          _buildInfoRow('Verfügbarkeit', '24/7 · 365 Tage', p),
          _buildInfoRow('Länder', '36 SEPA-Länder', p),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.public, color: Colors.purpleAccent, size: 16),
              const SizedBox(width: 6),
              Text('SWIFT INTERNATIONAL', style: TextStyle(
                color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          _buildInfoRow('Gebühr', '€15 - €35', p),
          _buildInfoRow('Abwicklung', '1-3 Werktage', p),
          _buildInfoRow('Weltweit', '200+ Länder', p),
        ],
      ),
    );
  }

  // ── Helper ────────────────────────────────────────
  Widget _buildSectionTitle(String title, IconData icon, Color color, QuantumPalette p) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(title, style: GoogleFonts.orbitron(
          color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
      ],
    );
  }

  String _currencySymbol(String c) => const {
    'EUR': '€', 'USD': '\$', 'GBP': '£', 'CHF': '₣',
    'JPY': '¥', 'CAD': 'C\$', 'AUD': 'A\$',
    'BTC': '₿', 'ETH': 'Ξ', 'USDT': '₮', 'USDC': '\$C', 'BNB': 'B',
  }[c] ?? c.substring(0, 1);

  String _currencyName(String c) => const {
    'EUR': 'Euro', 'USD': 'US Dollar', 'GBP': 'British Pound',
    'CHF': 'Swiss Franc', 'JPY': 'Japanese Yen',
    'CAD': 'Canadian Dollar', 'AUD': 'Australian Dollar',
    'BTC': 'Bitcoin', 'ETH': 'Ethereum',
    'USDT': 'Tether', 'USDC': 'USD Coin', 'BNB': 'BNB Chain',
  }[c] ?? c;

  Color _currencyColor(String c) {
    if (c == 'EUR') return const Color(0xFF003399);
    if (c == 'USD') return Colors.green;
    if (c == 'GBP') return Colors.blue;
    if (c == 'JPY') return Colors.red;
    if (c == 'CHF') return Colors.red;
    if (c == 'BTC') return const Color(0xFFF7931A);
    if (c == 'ETH') return const Color(0xFF627EEA);
    if (c == 'USDT') return const Color(0xFF26A17B);
    return const Color(0xFF00D4FF);
  }

  // ══════════════════════════════════════════════════════════
  // v38.0: MY BANK ACCOUNTS TAB — Secure local storage
  // ══════════════════════════════════════════════════════════
  Widget _buildMyAccountsTab(QuantumPalette p) {
    final ps = context.watch<PersistenceService>();
    final accounts = ps.bankAccounts;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        // ── Total Balance Card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF003399), const Color(0xFF0055CC)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFF003399).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.account_balance, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text('FIAT GUTHABEN GESAMT', style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 10, letterSpacing: 1.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('LOKAL VERSCHLÜSSELT', style: GoogleFonts.spaceMono(color: Colors.white60, fontSize: 7)),
              ),
            ]),
            const SizedBox(height: 12),
            Text(
              '€ ${ps.totalFiatBalance.toStringAsFixed(2)}',
              style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${accounts.length} Konto${accounts.length != 1 ? "s" : ""} verknüpft',
              style: GoogleFonts.spaceMono(color: Colors.white60, fontSize: 10),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Security Notice ──
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Icon(Icons.lock, color: Colors.amber, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(
              '🔒 Bankdaten werden NUR lokal auf diesem Gerät gespeichert. Keine Cloud-Übertragung.',
              style: GoogleFonts.spaceMono(color: Colors.amber, fontSize: 9),
            )),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Account Cards ──
        if (accounts.isEmpty)
          _buildAddAccountPrompt(p)
        else ...[
          ...accounts.map((acc) => _buildBankCard(acc, p, ps)),
          const SizedBox(height: 8),
        ],

        // ── Add Account Button ──
        GestureDetector(
          onTap: () => _showAddAccountDialog(p),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: p.primary.withValues(alpha: 0.4), style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_circle_outline, color: p.primary, size: 20),
              const SizedBox(width: 8),
              Text('Bankkonto hinzufügen', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildAddAccountPrompt(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        Icon(Icons.account_balance_wallet_outlined, color: p.textSecondary, size: 48),
        const SizedBox(height: 12),
        Text('Noch kein Bankkonto', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        Text('Füge dein Sparkasse- oder\nanderem Bankkonto hinzu', textAlign: TextAlign.center,
          style: GoogleFonts.spaceMono(color: p.textSecondary.withValues(alpha: 0.6), fontSize: 10)),
      ]),
    );
  }

  Widget _buildBankCard(BankAccount acc, QuantumPalette p, PersistenceService ps) {
    final isSparkasse = acc.bankName.toLowerCase().contains('sparkasse');
    final cardColor = isSparkasse ? const Color(0xFFFF0000) : const Color(0xFF1A237E);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(children: [
        // Card background
        Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cardColor, cardColor.withValues(alpha: 0.7)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: cardColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 6))],
          ),
        ),
        // Decorative circles
        Positioned(right: -20, top: -20, child: Container(width: 120, height: 120,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),
        Positioned(right: 20, bottom: -30, child: Container(width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),
        // Card content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(acc.bankName,
                style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
              if (acc.isDefault)
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                  child: Text('STANDARD', style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 7))),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showEditBalanceDialog(acc, p, ps),
                child: Icon(Icons.edit, color: Colors.white60, size: 16),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => ps.removeBankAccount(acc.id),
                child: Icon(Icons.delete_outline, color: Colors.white38, size: 16),
              ),
            ]),
            const Spacer(),
            Text(acc.maskedIban, style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 10, letterSpacing: 1)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('GUTHABEN', style: GoogleFonts.spaceMono(color: Colors.white60, fontSize: 8)),
                Text('€ ${acc.balance.toStringAsFixed(2)}',
                  style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(acc.cardType.toUpperCase(), style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 8)),
                Text(acc.cardDisplay, style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 10)),
              ]),
            ]),
            const SizedBox(height: 4),
            Text(acc.accountHolder, style: GoogleFonts.spaceMono(color: Colors.white60, fontSize: 9)),
          ]),
        ),
      ]),
    );
  }

  void _showAddAccountDialog(QuantumPalette p) {
    final labelCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final holderCtrl = TextEditingController();
    final ibanCtrl = TextEditingController();
    final bicCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: '0.00');
    final cardLastCtrl = TextEditingController();
    final cardExpCtrl = TextEditingController();
    String cardType = 'girocard';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: p.surface,
        title: Text('Bankkonto hinzufügen', style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 13)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('🔒 Daten werden nur lokal gespeichert', style: GoogleFonts.spaceMono(color: Colors.amber, fontSize: 9))),
          const SizedBox(height: 12),
          _dialogField(labelCtrl, 'Bezeichnung', 'z.B. Sparkasse Girokonto', p),
          _dialogField(bankCtrl, 'Bank', 'z.B. Sparkasse Dortmund', p),
          _dialogField(holderCtrl, 'Kontoinhaber', 'Vor- und Nachname', p),
          _dialogField(ibanCtrl, 'IBAN', 'DE00 0000 0000 0000 0000 00', p),
          _dialogField(bicCtrl, 'BIC', 'z.B. DORTDE33XXX', p),
          _dialogField(balanceCtrl, 'Aktuelles Guthaben (€)', '0.00', p,
            type: TextInputType.numberWithOptions(decimal: true)),
          _dialogField(cardLastCtrl, 'Letzte 4 Stellen Kartennr.', '0000', p,
            type: TextInputType.number, maxLen: 4),
          _dialogField(cardExpCtrl, 'Gültig bis', 'MM/YY', p),
          DropdownButtonFormField<String>(
            value: cardType,
            dropdownColor: p.surface,
            style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11),
            decoration: InputDecoration(labelText: 'Kartentyp',
              labelStyle: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10)),
            items: ['girocard', 'Debitkarte', 'Kreditkarte', 'Prepaid']
              .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setS(() => cardType = v ?? cardType),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Abbrechen', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: p.primary),
            onPressed: () {
              if (ibanCtrl.text.isEmpty || bankCtrl.text.isEmpty) return;
              final ps = context.read<PersistenceService>();
              ps.addBankAccount(BankAccount(
                id: ps.generateId(),
                label: labelCtrl.text.isEmpty ? '${bankCtrl.text} Konto' : labelCtrl.text,
                bankName: bankCtrl.text,
                accountHolder: holderCtrl.text,
                iban: ibanCtrl.text.replaceAll(' ', ''),
                bic: bicCtrl.text,
                currency: 'EUR',
                balance: double.tryParse(balanceCtrl.text.replaceAll(',', '.')) ?? 0.0,
                cardNumber: cardLastCtrl.text.padLeft(4, '0'),
                cardExpiry: cardExpCtrl.text,
                cardType: cardType,
                isDefault: false,
                addedAt: DateTime.now(),
              ));
              Navigator.pop(ctx);
            },
            child: Text('Hinzufügen', style: GoogleFonts.spaceMono(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      )),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, String hint, QuantumPalette p,
      {TextInputType? type, int? maxLen}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        maxLength: maxLen,
        style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11),
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          labelStyle: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10),
          hintStyle: GoogleFonts.spaceMono(color: p.textSecondary.withValues(alpha: 0.5), fontSize: 10),
          counterText: '',
        ),
      ),
    );
  }

  void _showEditBalanceDialog(BankAccount acc, QuantumPalette p, PersistenceService ps) {
    final ctrl = TextEditingController(text: acc.balance.toStringAsFixed(2));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: p.surface,
      title: Text('Guthaben aktualisieren', style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 12)),
      content: TextField(
        controller: ctrl, autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          prefixText: '€ ',
          prefixStyle: GoogleFonts.spaceMono(color: p.primary, fontSize: 16),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: Text('Abbrechen', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: p.primary),
          onPressed: () {
            final val = double.tryParse(ctrl.text.replaceAll(',', '.'));
            if (val != null) ps.updateBalance(acc.id, val);
            Navigator.pop(ctx);
          },
          child: Text('Speichern', style: GoogleFonts.spaceMono(color: Colors.black, fontSize: 10)),
        ),
      ],
    ));
  }
}
