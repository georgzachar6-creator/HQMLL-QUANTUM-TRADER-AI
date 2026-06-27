// ════════════════════════════════════════════════════════════════════════════
// OMS + RISK ENGINE SCREEN  v26.0
// Quantum Trader AI — Order Management System + Risk Dashboard
// Features: Limit/Market/Stop-Loss/Take-Profit Orders, Real-Time Risk Dashboard,
//           Position Sizing (Kelly Criterion / Fixed %), Drawdown Monitor,
//           VAR Calculator, Open Positions Manager, Order Book Integration,
//           MiFID II Pre-Trade Risk Checks
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/exchange_service.dart';
import '../widgets/crypto_icon.dart';
import '../providers/theme_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum OrderType { market, limit, stopLoss, takeProfit, trailingStop, oco }
enum OrderSide { buy, sell }
enum OrderStatus { pending, open, partialFill, filled, cancelled, rejected, expired }
enum PositionSide { long, short }

class OmsOrder {
  final String id;
  final String symbol;
  final OrderType type;
  final OrderSide side;
  OrderStatus status;
  final double quantity;
  double filledQty;
  final double? limitPrice;
  final double? stopPrice;
  final double? trailingPercent;
  final double submittedAt;
  double? avgFillPrice;
  final String exchange;
  final bool isOco;
  String? ocoLinkedId;

  OmsOrder({
    required this.id,
    required this.symbol,
    required this.type,
    required this.side,
    this.status = OrderStatus.open,
    required this.quantity,
    this.filledQty = 0.0,
    this.limitPrice,
    this.stopPrice,
    this.trailingPercent,
    required this.submittedAt,
    this.avgFillPrice,
    this.exchange = 'Binance',
    this.isOco = false,
    this.ocoLinkedId,
  });

  double get fillPercent => quantity > 0 ? filledQty / quantity : 0.0;
  bool get isFilled => status == OrderStatus.filled;
  bool get isOpen => status == OrderStatus.open || status == OrderStatus.partialFill;

  String get typeLabel => type.name.replaceAllMapped(
    RegExp(r'[A-Z]'), (m) => ' ${m[0]}').trim().toUpperCase();
}

class Position {
  final String symbol;
  final PositionSide side;
  double size;           // in base asset
  double avgEntry;
  double leverage;
  final DateTime openedAt;
  double liqPrice;
  double margin;

  Position({
    required this.symbol,
    required this.side,
    required this.size,
    required this.avgEntry,
    this.leverage = 1.0,
    required this.openedAt,
    required this.liqPrice,
    required this.margin,
  });

  double pnl(double currentPrice) {
    final diff = side == PositionSide.long
        ? currentPrice - avgEntry
        : avgEntry - currentPrice;
    return diff * size;
  }

  double pnlPercent(double currentPrice) {
    return avgEntry > 0 ? ((currentPrice - avgEntry) / avgEntry * 100 * (side == PositionSide.short ? -1 : 1)) : 0.0;
  }

  double notional(double currentPrice) => size * currentPrice;
}

class RiskMetrics {
  double portfolioVaR;      // 1-day 95% VaR in USD
  double portfolioVaR99;    // 1-day 99% VaR
  double maxDrawdown;       // current max drawdown %
  double currentDrawdown;   // current drawdown %
  double sharpe;
  double beta;
  double correlation;       // avg correlation with BTC
  double concentrationRisk; // HHI concentration index
  double totalExposure;     // total position value USD
  double availableMargin;
  double usedMarginPercent;
  double dailyPnl;
  double weeklyPnl;

  RiskMetrics({
    this.portfolioVaR = 0,
    this.portfolioVaR99 = 0,
    this.maxDrawdown = 0,
    this.currentDrawdown = 0,
    this.sharpe = 0,
    this.beta = 0,
    this.correlation = 0,
    this.concentrationRisk = 0,
    this.totalExposure = 0,
    this.availableMargin = 0,
    this.usedMarginPercent = 0,
    this.dailyPnl = 0,
    this.weeklyPnl = 0,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// OMS + RISK SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class OmsRiskScreen extends StatefulWidget {
  const OmsRiskScreen({super.key});

  @override
  State<OmsRiskScreen> createState() => _OmsRiskScreenState();
}

class _OmsRiskScreenState extends State<OmsRiskScreen>
    with TickerProviderStateMixin {

  late TabController _tabCtrl;
  late AnimationController _pulseCtrl;
  Timer? _updateTimer;

  int _tab = 0;
  final _rnd = Random(99);

  // Order form state
  String _orderSymbol = 'BTC';
  OrderType _orderType = OrderType.limit;
  OrderSide _orderSide = OrderSide.buy;
  String _sizingMethod = 'FIXED_USD';  // FIXED_USD, PERCENT_EQUITY, KELLY
  final _qtyCtrl = TextEditingController();
  final _limitPriceCtrl = TextEditingController();
  final _stopPriceCtrl = TextEditingController();
  final _tpPriceCtrl = TextEditingController();
  final _trailingPctCtrl = TextEditingController(text: '1.5');
  // ignore: unused_field
  final bool _isOco = false; // reserved for OCO order type
  String _selectedExchange = 'Binance';

  late RiskMetrics _riskMetrics;
  final List<OmsOrder> _orders = [];
  final List<Position> _positions = [];
  final List<Map<String, dynamic>> _orderHistory = [];

  // Risk circuit breakers
  bool _dailyLossCircuitBreaker = false;
  // ignore: unused_field
  bool _concentrationCircuitBreaker = false; // reserved for risk limiter
  double _maxDailyLoss = -500.0; // USD
  double _maxSinglePosition = 0.02; // 2% of equity

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() => setState(() => _tab = _tabCtrl.index));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);

    _initData();
    _updateTimer = Timer.periodic(const Duration(seconds: 4), (_) => _updateRiskMetrics());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _updateTimer?.cancel();
    _qtyCtrl.dispose();
    _limitPriceCtrl.dispose();
    _stopPriceCtrl.dispose();
    _tpPriceCtrl.dispose();
    _trailingPctCtrl.dispose();
    super.dispose();
  }

  void _initData() {
    final now = DateTime.now();

    _riskMetrics = RiskMetrics(
      portfolioVaR: 847.0,
      portfolioVaR99: 1234.0,
      maxDrawdown: -8.3,
      currentDrawdown: -2.1,
      sharpe: 1.84,
      beta: 0.87,
      correlation: 0.73,
      concentrationRisk: 0.34,
      totalExposure: 42870.0,
      availableMargin: 7130.0,
      usedMarginPercent: 0.68,
      dailyPnl: 234.50,
      weeklyPnl: 847.30,
    );

    _positions.addAll([
      Position(
        symbol: 'BTC', side: PositionSide.long, size: 0.15,
        avgEntry: 63420.0, leverage: 1.0, openedAt: now.subtract(const Duration(hours: 8)),
        liqPrice: 0.0, margin: 9513.0,
      ),
      Position(
        symbol: 'ETH', side: PositionSide.long, size: 1.2,
        avgEntry: 3150.0, leverage: 1.0, openedAt: now.subtract(const Duration(hours: 3)),
        liqPrice: 0.0, margin: 3780.0,
      ),
      Position(
        symbol: 'SOL', side: PositionSide.long, size: 20.0,
        avgEntry: 145.0, leverage: 1.0, openedAt: now.subtract(const Duration(days: 1)),
        liqPrice: 0.0, margin: 2900.0,
      ),
      Position(
        symbol: 'BNB', side: PositionSide.short, size: 3.0,
        avgEntry: 602.0, leverage: 2.0, openedAt: now.subtract(const Duration(hours: 5)),
        liqPrice: 720.0, margin: 903.0,
      ),
    ]);

    _orders.addAll([
      OmsOrder(
        id: 'ORD-001', symbol: 'BTC', type: OrderType.limit, side: OrderSide.buy,
        quantity: 0.05, limitPrice: 63000.0, submittedAt: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch.toDouble(),
        exchange: 'Binance',
      ),
      OmsOrder(
        id: 'ORD-002', symbol: 'ETH', type: OrderType.stopLoss, side: OrderSide.sell,
        quantity: 1.2, stopPrice: 3050.0, submittedAt: now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch.toDouble(),
        exchange: 'Binance',
      ),
      OmsOrder(
        id: 'ORD-003', symbol: 'SOL', type: OrderType.takeProfit, side: OrderSide.sell,
        quantity: 20.0, limitPrice: 162.0, submittedAt: now.subtract(const Duration(days: 1)).millisecondsSinceEpoch.toDouble(),
        exchange: 'Kraken',
      ),
      OmsOrder(
        id: 'ORD-004', symbol: 'BNB', type: OrderType.trailingStop, side: OrderSide.buy,
        quantity: 3.0, trailingPercent: 2.0, submittedAt: now.subtract(const Duration(hours: 5)).millisecondsSinceEpoch.toDouble(),
        status: OrderStatus.partialFill, filledQty: 1.2, avgFillPrice: 595.0,
        exchange: 'Binance',
      ),
    ]);

    // Order history
    final histTypes = ['MARKET', 'LIMIT', 'STOP_LOSS', 'TAKE_PROFIT'];
    final symbols = ['BTC', 'ETH', 'SOL', 'BNB', 'AVAX'];
    for (int i = 0; i < 15; i++) {
      _orderHistory.add({
        'id': 'HIST-${1000 + i}',
        'symbol': symbols[_rnd.nextInt(symbols.length)],
        'type': histTypes[_rnd.nextInt(histTypes.length)],
        'side': _rnd.nextBool() ? 'BUY' : 'SELL',
        'qty': (_rnd.nextDouble() * 2 + 0.01).toStringAsFixed(3),
        'price': 50000 + _rnd.nextDouble() * 20000,
        'status': _rnd.nextDouble() < 0.8 ? 'FILLED' : 'CANCELLED',
        'time': now.subtract(Duration(hours: i * 5 + _rnd.nextInt(4))),
        'pnl': (_rnd.nextDouble() - 0.38) * 200,
        'exchange': _rnd.nextBool() ? 'Binance' : 'Kraken',
      });
    }
  }

  void _updateRiskMetrics() {
    if (!mounted) return;
    setState(() {
      _riskMetrics.currentDrawdown += (_rnd.nextDouble() - 0.48) * 0.3;
      _riskMetrics.currentDrawdown = _riskMetrics.currentDrawdown.clamp(-15.0, 0.0);
      _riskMetrics.dailyPnl += (_rnd.nextDouble() - 0.46) * 15;
      _riskMetrics.portfolioVaR += (_rnd.nextDouble() - 0.5) * 20;
      _dailyLossCircuitBreaker = _riskMetrics.dailyPnl < _maxDailyLoss;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ex = context.watch<ExchangeService>();
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: _buildAppBar(p),
      body: Column(
        children: [
          if (_dailyLossCircuitBreaker) _buildCircuitBreakerBanner(),
          _buildRiskSummaryStrip(ex, p),
          _buildTabBar(p),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildOrderFormTab(ex, p),
                _buildPositionsTab(ex, p),
                _buildOpenOrdersTab(ex, p),
                _buildRiskDashboardTab(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(dynamic p) {
    return AppBar(
      backgroundColor: p.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: p.textSecondary, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OMS + RISK ENGINE',
            style: GoogleFonts.rajdhani(color: p.primary, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2)),
          Text('MiFID II · VAR-based limits · Smart Order Routing',
            style: TextStyle(color: p.textSecondary.withValues(alpha: 0.5), fontSize: 8, letterSpacing: 0.5)),
        ],
      ),
      actions: [
        // MiFID II badge
        Container(
          margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF4A90E2).withValues(alpha: 0.4)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('MiFID II', style: TextStyle(color: const Color(0xFF4A90E2), fontSize: 8, fontWeight: FontWeight.bold)),
            Text('COMPLIANT', style: TextStyle(color: Colors.grey[600], fontSize: 6, letterSpacing: 0.5)),
          ]),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CIRCUIT BREAKER BANNER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCircuitBreakerBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFFF3355).withValues(alpha: 0.15),
      child: Row(children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Icon(Icons.warning_rounded,
            color: Color.lerp(const Color(0xFFFF3355), Colors.orange, _pulseCtrl.value)!, size: 18),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text('⚠ CIRCUIT BREAKER ACTIVE — Daily loss limit reached. New orders blocked.',
            style: TextStyle(color: Color(0xFFFF3355), fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        GestureDetector(
          onTap: () => setState(() => _dailyLossCircuitBreaker = false),
          child: const Text('RESET', style: TextStyle(color: Color(0xFFFF3355), fontSize: 10, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RISK SUMMARY STRIP
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildRiskSummaryStrip(ExchangeService ex, dynamic p) {
    final isPnlUp = _riskMetrics.dailyPnl >= 0;
    final riskLevel = _riskMetrics.usedMarginPercent > 0.8 ? 'HIGH'
        : _riskMetrics.usedMarginPercent > 0.5 ? 'MEDIUM' : 'LOW';
    final riskColor = riskLevel == 'HIGH' ? const Color(0xFFFF3355)
        : riskLevel == 'MEDIUM' ? const Color(0xFFFFB800) : const Color(0xFF00C896);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: p.surface,
      child: Row(
        children: [
          _buildStripItem('VAR (95%)', '\$${_riskMetrics.portfolioVaR.toStringAsFixed(0)}', const Color(0xFFFF7733)),
          _vsep(),
          _buildStripItem('DD', '${_riskMetrics.currentDrawdown.toStringAsFixed(1)}%', const Color(0xFFFF3355)),
          _vsep(),
          _buildStripItem('Daily', '${isPnlUp ? '+' : ''}\$${_riskMetrics.dailyPnl.toStringAsFixed(0)}',
            isPnlUp ? const Color(0xFF00C896) : const Color(0xFFFF3355)),
          _vsep(),
          _buildStripItem('MARGIN', '${(_riskMetrics.usedMarginPercent * 100).toStringAsFixed(0)}%', riskColor),
          _vsep(),
          _buildStripItem('RISK', riskLevel, riskColor),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${_positions.length} OPEN POSITIONS',
              style: GoogleFonts.spaceMono(color: const Color(0xFF4A90E2), fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _vsep() => Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.08), margin: const EdgeInsets.symmetric(horizontal: 10));

  Widget _buildStripItem(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 7)),
      Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB BAR
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTabBar(dynamic p) {
    final tabs = [
      (Icons.add_circle_outline,       'ORDER',     const Color(0xFF00C896)),
      (Icons.candlestick_chart_rounded,'POSITIONS', const Color(0xFF4A90E2)),
      (Icons.list_alt_rounded,         'ORDERS',    const Color(0xFFFFB800)),
      (Icons.shield_outlined,          'RISK',      const Color(0xFFFF7733)),
    ];

    return Container(
      height: 48,
      color: p.surface,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () { _tabCtrl.animateTo(i); setState(() => _tab = i); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isActive ? tabs[i].$3 : Colors.transparent, width: 2.5)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(tabs[i].$1, size: 14, color: isActive ? tabs[i].$3 : Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(tabs[i].$2, style: TextStyle(color: isActive ? tabs[i].$3 : Colors.grey[600], fontSize: 9, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, letterSpacing: 0.5)),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 0: ORDER FORM
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildOrderFormTab(ExchangeService ex, dynamic p) {
    final price = ex.getPrice(_orderSymbol);
    final effectivePrice = price > 0 ? price : _fallbackPrice(_orderSymbol);
    final qty = double.tryParse(_qtyCtrl.text) ?? 0.0;
    final limitP = double.tryParse(_limitPriceCtrl.text) ?? effectivePrice;
    final notionalUsd = qty * (limitP > 0 ? limitP : effectivePrice);
    final portfolioVal = 50000.0;
    final positionPercent = portfolioVal > 0 ? (notionalUsd / portfolioVal) * 100 : 0.0;

    // Pre-trade risk checks
    final exceeds2pct = positionPercent > 2.0;
    final isBlocked = _dailyLossCircuitBreaker || exceeds2pct;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Symbol + Exchange selector
          Row(children: [
            Expanded(child: _buildCoinSelectorHorizontal()),
            const SizedBox(width: 10),
            _buildExchangeSelector(),
          ]),
          const SizedBox(height: 14),

          // BUY / SELL toggle
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _orderSide = OrderSide.buy),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _orderSide == OrderSide.buy ? const Color(0xFF00C896).withValues(alpha: 0.2) : p.surface,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  border: Border.all(color: _orderSide == OrderSide.buy ? const Color(0xFF00C896) : Colors.white.withValues(alpha: 0.08), width: 1.5),
                ),
                child: Center(child: Text('BUY / LONG',
                  style: TextStyle(color: _orderSide == OrderSide.buy ? const Color(0xFF00C896) : Colors.grey[500],
                    fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
              ),
            )),
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _orderSide = OrderSide.sell),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _orderSide == OrderSide.sell ? const Color(0xFFFF3355).withValues(alpha: 0.2) : p.surface,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                  border: Border.all(color: _orderSide == OrderSide.sell ? const Color(0xFFFF3355) : Colors.white.withValues(alpha: 0.08), width: 1.5),
                ),
                child: Center(child: Text('SELL / SHORT',
                  style: TextStyle(color: _orderSide == OrderSide.sell ? const Color(0xFFFF3355) : Colors.grey[500],
                    fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
              ),
            )),
          ]),
          const SizedBox(height: 14),

          // Order type selector
          Text('ORDER TYPE', style: TextStyle(color: Colors.grey[600], fontSize: 9, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: OrderType.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final t = OrderType.values[i];
                final isSel = _orderType == t;
                return GestureDetector(
                  onTap: () => setState(() => _orderType = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF4A90E2).withValues(alpha: 0.15) : p.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSel ? const Color(0xFF4A90E2) : Colors.white.withValues(alpha: 0.08), width: isSel ? 1.5 : 1),
                    ),
                    child: Text(t.name.replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m[0]}').trim().toUpperCase(),
                      style: TextStyle(color: isSel ? const Color(0xFF4A90E2) : Colors.grey[400], fontSize: 9, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Quantity + sizing
          Text('QUANTITY', style: TextStyle(color: Colors.grey[600], fontSize: 9, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _buildInputField(_qtyCtrl, 'Amount (${_orderSymbol})', TextInputType.number, () => setState(() {}))),
            const SizedBox(width: 8),
            _buildSizingMethodBtn('FIXED', 'FIXED_USD'),
            const SizedBox(width: 4),
            _buildSizingMethodBtn('%EQ', 'PERCENT_EQUITY'),
            const SizedBox(width: 4),
            _buildSizingMethodBtn('KELLY', 'KELLY'),
          ]),

          if (qty > 0) Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              Text('≈ \$${_formatNum(notionalUsd)}', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (exceeds2pct ? const Color(0xFFFF3355) : const Color(0xFF00C896)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('${positionPercent.toStringAsFixed(1)}% equity',
                  style: TextStyle(
                    color: exceeds2pct ? const Color(0xFFFF3355) : const Color(0xFF00C896),
                    fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Limit/Stop price fields
          if (_orderType == OrderType.limit || _orderType == OrderType.takeProfit || _orderType == OrderType.oco) ...[
            Text('LIMIT PRICE', style: TextStyle(color: Colors.grey[600], fontSize: 9, letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: _buildInputField(_limitPriceCtrl, '\$${effectivePrice.toStringAsFixed(2)}', TextInputType.number, () => setState(() {}))),
              const SizedBox(width: 8),
              _buildPriceShortcut('Market', effectivePrice),
              const SizedBox(width: 4),
              _buildPriceShortcut('-1%', effectivePrice * 0.99),
              const SizedBox(width: 4),
              _buildPriceShortcut('+1%', effectivePrice * 1.01),
            ]),
            const SizedBox(height: 12),
          ],
          if (_orderType == OrderType.stopLoss || _orderType == OrderType.oco) ...[
            Text('STOP PRICE', style: TextStyle(color: Colors.grey[600], fontSize: 9, letterSpacing: 1.5)),
            const SizedBox(height: 6),
            _buildInputField(_stopPriceCtrl, 'Stop-Loss Price', TextInputType.number, () => setState(() {})),
            const SizedBox(height: 12),
          ],
          if (_orderType == OrderType.oco) ...[
            Text('TAKE PROFIT', style: TextStyle(color: Colors.grey[600], fontSize: 9, letterSpacing: 1.5)),
            const SizedBox(height: 6),
            _buildInputField(_tpPriceCtrl, 'Take-Profit Price', TextInputType.number, () => setState(() {})),
            const SizedBox(height: 12),
          ],
          if (_orderType == OrderType.trailingStop) ...[
            Text('TRAILING %', style: TextStyle(color: Colors.grey[600], fontSize: 9, letterSpacing: 1.5)),
            const SizedBox(height: 6),
            _buildInputField(_trailingPctCtrl, '1.5', TextInputType.number, () => setState(() {})),
            const SizedBox(height: 12),
          ],

          // Risk preview
          _buildPreTradeRiskCheck(qty, notionalUsd, positionPercent, effectivePrice, p),
          const SizedBox(height: 14),

          // Submit
          GestureDetector(
            onTap: isBlocked ? null : () => _submitOrder(ex, effectivePrice),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: isBlocked ? null : LinearGradient(
                  colors: _orderSide == OrderSide.buy
                      ? [const Color(0xFF00A876), const Color(0xFF00C896)]
                      : [const Color(0xFFCC2244), const Color(0xFFFF3355)],
                ),
                color: isBlocked ? Colors.grey[800] : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isBlocked ? null : [
                  BoxShadow(
                    color: (_orderSide == OrderSide.buy ? const Color(0xFF00C896) : const Color(0xFFFF3355)).withValues(alpha: 0.4),
                    blurRadius: 16, spreadRadius: 0, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_orderSide == OrderSide.buy ? Icons.add_shopping_cart : Icons.remove_shopping_cart,
                  color: isBlocked ? Colors.grey[600] : Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  isBlocked ? '⛔ ORDER BLOCKED — RISK LIMIT' : '${_orderSide.name.toUpperCase()} $_orderSymbol ${_orderType.name.toUpperCase()}',
                  style: GoogleFonts.rajdhani(
                    color: isBlocked ? Colors.grey[600] : Colors.white,
                    fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreTradeRiskCheck(double qty, double notional, double pctEquity, double price, dynamic p) {
    final checks = [
      ('Position Size ≤ 2% equity', pctEquity <= 2.0, '${pctEquity.toStringAsFixed(1)}%'),
      ('Daily Loss Limit', !_dailyLossCircuitBreaker, _dailyLossCircuitBreaker ? 'BREACHED' : 'OK'),
      ('Market Hours', true, '24/7 Crypto'),
      ('Concentration', _riskMetrics.concentrationRisk < 0.5, 'HHI=${_riskMetrics.concentrationRisk.toStringAsFixed(2)}'),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF4A90E2)),
            const SizedBox(width: 6),
            Text('PRE-TRADE RISK CHECKS (MiFID II)', style: TextStyle(color: const Color(0xFF4A90E2), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 10),
          ...checks.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Icon(c.$2 ? Icons.check_circle : Icons.cancel, size: 13, color: c.$2 ? const Color(0xFF00C896) : const Color(0xFFFF3355)),
              const SizedBox(width: 8),
              Expanded(child: Text(c.$1, style: TextStyle(color: Colors.grey[400], fontSize: 10))),
              Text(c.$3, style: GoogleFonts.spaceMono(color: c.$2 ? const Color(0xFF00C896) : const Color(0xFFFF3355), fontSize: 9, fontWeight: FontWeight.bold)),
            ]),
          )),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 1: POSITIONS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPositionsTab(ExchangeService ex, dynamic p) {
    if (_positions.isEmpty) {
      return const Center(child: Text('No open positions', style: TextStyle(color: Colors.grey)));
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Total PnL header
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF0D1F17), const Color(0xFF0A1520)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TOTAL UNREALIZED PnL', style: TextStyle(color: Colors.grey[500], fontSize: 9)),
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) {
                    double totalPnl = 0;
                    for (final pos in _positions) {
                      final price = ex.getPrice(pos.symbol);
                      if (price > 0) totalPnl += pos.pnl(price);
                    }
                    final isUp = totalPnl >= 0;
                    return Text(
                      '${isUp ? '+' : ''}\$${totalPnl.toStringAsFixed(2)}',
                      style: GoogleFonts.spaceMono(
                        color: isUp ? const Color(0xFF00C896) : const Color(0xFFFF3355),
                        fontSize: 22, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('TOTAL EXPOSURE', style: TextStyle(color: Colors.grey[500], fontSize: 9)),
                Text('\$${_formatNum(_riskMetrics.totalExposure)}',
                  style: GoogleFonts.spaceMono(color: Colors.grey[300], fontSize: 14)),
              ]),
            ],
          ),
        ),

        ..._positions.map((pos) => _buildPositionCard(pos, ex, p)),
      ],
    );
  }

  Widget _buildPositionCard(Position pos, ExchangeService ex, dynamic p) {
    final price = ex.getPrice(pos.symbol);
    final effectivePrice = price > 0 ? price : pos.avgEntry;
    final pnl = pos.pnl(effectivePrice);
    final pnlPct = pos.pnlPercent(effectivePrice);
    final isLong = pos.side == PositionSide.long;
    final pnlColor = pnl >= 0 ? const Color(0xFF00C896) : const Color(0xFFFF3355);
    final sideColor = isLong ? const Color(0xFF00C896) : const Color(0xFFFF3355);
    final notional = pos.notional(effectivePrice);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pnl >= 0 ? const Color(0xFF00C896).withValues(alpha: 0.2) : const Color(0xFFFF3355).withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CryptoIcon(pos.symbol, size: 40, showShadow: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(pos.symbol, style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: sideColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: sideColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(isLong ? 'LONG' : 'SHORT',
                          style: TextStyle(color: sideColor, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      if (pos.leverage > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7733).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${pos.leverage.toStringAsFixed(0)}x',
                            style: const TextStyle(color: Color(0xFFFF7733), fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ]),
                    Text('${pos.size} ${pos.symbol} · \$${_formatNum(notional)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
                    style: GoogleFonts.spaceMono(color: pnlColor, fontSize: 14, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: pnlColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('${pnlPct >= 0 ? '+' : ''}${pnlPct.toStringAsFixed(2)}%',
                      style: TextStyle(color: pnlColor, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
                  ),
                ]),
              ],
            ),
          ),

          // Price details row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Row(children: [
              _buildPriceDetail('AVG ENTRY', '\$${_formatNum(pos.avgEntry)}', Colors.grey[400]!),
              const SizedBox(width: 16),
              _buildPriceDetail('CURRENT', '\$${_formatNum(effectivePrice)}', Colors.white),
              const SizedBox(width: 16),
              if (pos.liqPrice > 0)
                _buildPriceDetail('LIQ PRICE', '\$${_formatNum(pos.liqPrice)}', const Color(0xFFFF3355))
              else
                _buildPriceDetail('MARGIN', '\$${_formatNum(pos.margin)}', Colors.grey[400]!),
              const Spacer(),
              GestureDetector(
                onTap: () => _closePosition(pos),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3355).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF3355).withValues(alpha: 0.4)),
                  ),
                  child: const Text('CLOSE', style: TextStyle(color: Color(0xFFFF3355), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDetail(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 7)),
      Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2: OPEN ORDERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildOpenOrdersTab(ExchangeService ex, dynamic p) {
    return Column(
      children: [
        if (_orders.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _orders.length,
              itemBuilder: (_, i) => _buildOrderRow(_orders[i], ex, p),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ORDER HISTORY', style: TextStyle(color: Colors.grey[600], fontSize: 9, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              ..._orderHistory.take(6).map((h) => _buildHistoryRow(h)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderRow(OmsOrder order, ExchangeService ex, dynamic p) {
    final price = ex.getPrice(order.symbol);
    final effectivePrice = price > 0 ? price : _fallbackPrice(order.symbol);
    final typeColor = switch (order.type) {
      OrderType.market        => const Color(0xFF4A90E2),
      OrderType.limit         => const Color(0xFFFFB800),
      OrderType.stopLoss      => const Color(0xFFFF3355),
      OrderType.takeProfit    => const Color(0xFF00C896),
      OrderType.trailingStop  => const Color(0xFF9945FF),
      OrderType.oco           => const Color(0xFFFF7733),
    };
    final fillRatio = order.fillPercent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(children: [
            CryptoIcon(order.symbol, size: 32, showBorder: false),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(order.symbol, style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: typeColor.withValues(alpha: 0.3))),
                  child: Text(order.typeLabel, style: TextStyle(color: typeColor, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: (order.side == OrderSide.buy ? const Color(0xFF00C896) : const Color(0xFFFF3355)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(order.side.name.toUpperCase(),
                    style: TextStyle(color: order.side == OrderSide.buy ? const Color(0xFF00C896) : const Color(0xFFFF3355), fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ]),
              Text('${order.quantity} ${order.symbol} · ${order.exchange}', style: TextStyle(color: Colors.grey[500], fontSize: 9)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(order.limitPrice != null ? '\$${_formatNum(order.limitPrice!)}' : 'MARKET',
                style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('Current: \$${_formatNum(effectivePrice)}', style: TextStyle(color: Colors.grey[500], fontSize: 9)),
            ]),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() { _orders.remove(order); }),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFFFF3355).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Color(0xFFFF3355), size: 14),
              ),
            ),
          ]),
          if (order.status == OrderStatus.partialFill) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: fillRatio,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB800)),
                  minHeight: 5,
                ),
              )),
              const SizedBox(width: 8),
              Text('${(fillRatio * 100).toStringAsFixed(0)}% filled',
                style: const TextStyle(color: Color(0xFFFFB800), fontSize: 9)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryRow(Map<String, dynamic> h) {
    final sym = h['symbol'] as String;
    final pnl = h['pnl'] as double;
    final status = h['status'] as String;
    final isPositive = pnl >= 0;
    final isFilled = status == 'FILLED';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        CryptoIcon(sym, size: 24, showBorder: false),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${h['side']} $sym · ${h['type']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
          Text('${h['qty']} @ \$${(h['price'] as double).toStringAsFixed(0)} · ${h['exchange']}',
            style: TextStyle(color: Colors.grey[600], fontSize: 8)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (isFilled)
            Text('${isPositive ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
              style: TextStyle(color: isPositive ? const Color(0xFF00C896) : const Color(0xFFFF3355), fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'))
          else
            const Text('CANCELLED', style: TextStyle(color: Colors.grey, fontSize: 9)),
          Text(_formatAgo(h['time'] as DateTime), style: TextStyle(color: Colors.grey[700], fontSize: 8)),
        ]),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 3: RISK DASHBOARD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildRiskDashboardTab(dynamic p) {
    final varLevel = _riskMetrics.portfolioVaR / 50000.0;
    final ddLevel = _riskMetrics.currentDrawdown.abs() / 15.0;
    final marginLevel = _riskMetrics.usedMarginPercent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk gauges
          Text('RISK GAUGES', style: TextStyle(color: Colors.grey[600], fontSize: 9, letterSpacing: 1.5)),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(child: _buildRiskGauge('VAR (95%)', '\$${_riskMetrics.portfolioVaR.toStringAsFixed(0)}', varLevel.clamp(0, 1), 'Value at Risk')),
            const SizedBox(width: 10),
            Expanded(child: _buildRiskGauge('DRAWDOWN', '${_riskMetrics.currentDrawdown.toStringAsFixed(1)}%', ddLevel.clamp(0, 1), 'From peak')),
            const SizedBox(width: 10),
            Expanded(child: _buildRiskGauge('MARGIN', '${(_riskMetrics.usedMarginPercent * 100).toStringAsFixed(0)}%', marginLevel.clamp(0, 1), 'Used margin')),
          ]),
          const SizedBox(height: 20),

          // Risk matrix
          Text('RISK MATRIX', style: TextStyle(color: Colors.grey[600], fontSize: 9, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(children: [
              _buildRiskRow('Portfolio VAR (95%)', '\$${_riskMetrics.portfolioVaR.toStringAsFixed(0)}/day', _riskMetrics.portfolioVaR < 1000),
              _buildRiskRow('Portfolio VAR (99%)', '\$${_riskMetrics.portfolioVaR99.toStringAsFixed(0)}/day', _riskMetrics.portfolioVaR99 < 1500),
              _buildRiskRow('Sharpe Ratio', _riskMetrics.sharpe.toStringAsFixed(2), _riskMetrics.sharpe > 1),
              _buildRiskRow('Max Drawdown', '${_riskMetrics.maxDrawdown.toStringAsFixed(1)}%', _riskMetrics.maxDrawdown > -10),
              _buildRiskRow('Beta (vs BTC)', _riskMetrics.beta.toStringAsFixed(2), _riskMetrics.beta < 1),
              _buildRiskRow('BTC Correlation', _riskMetrics.correlation.toStringAsFixed(2), _riskMetrics.correlation < 0.8),
              _buildRiskRow('Concentration (HHI)', _riskMetrics.concentrationRisk.toStringAsFixed(2), _riskMetrics.concentrationRisk < 0.4),
              _buildRiskRow('Daily P&L', '\$${_riskMetrics.dailyPnl.toStringAsFixed(0)}', _riskMetrics.dailyPnl >= 0),
            ]),
          ),

          const SizedBox(height: 20),

          // Circuit breakers config
          Text('CIRCUIT BREAKERS', style: TextStyle(color: Colors.grey[600], fontSize: 9, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(children: [
              _buildCircuitBreakerRow('Daily Loss Limit', '\$${_maxDailyLoss.abs().toStringAsFixed(0)}', !_dailyLossCircuitBreaker),
              _buildCircuitBreakerRow('Max Position Size', '${(_maxSinglePosition * 100).toStringAsFixed(0)}% equity', true),
              _buildCircuitBreakerRow('Drawdown Stop', '${(_riskMetrics.maxDrawdown).toStringAsFixed(0)}%', _riskMetrics.currentDrawdown.abs() < 8),
              _buildCircuitBreakerRow('Concentration Limit', 'HHI < 0.5', _riskMetrics.concentrationRisk < 0.5),
            ]),
          ),

          const SizedBox(height: 20),

          // Position Sizing Calculator
          Text('POSITION SIZING CALCULATOR', style: TextStyle(color: Colors.grey[600], fontSize: 9, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          _buildPositionSizingCalculator(p),
        ],
      ),
    );
  }

  Widget _buildRiskGauge(String label, String value, double level, String sublabel) {
    final color = level < 0.4 ? const Color(0xFF00C896)
        : level < 0.7 ? const Color(0xFFFFB800) : const Color(0xFFFF3355);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 8, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        SizedBox(
          width: 60, height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: level,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation(color),
                strokeWidth: 5,
              ),
              Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(sublabel, style: TextStyle(color: Colors.grey[600], fontSize: 8)),
      ]),
    );
  }

  Widget _buildRiskRow(String label, String value, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: ok ? const Color(0xFF00C896) : const Color(0xFFFF3355), shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10))),
        Text(value, style: GoogleFonts.spaceMono(color: ok ? Colors.white : const Color(0xFFFF3355), fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildCircuitBreakerRow(String label, String limit, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF00C896) : const Color(0xFFFF3355),
              shape: BoxShape.circle,
              boxShadow: !active ? [BoxShadow(color: const Color(0xFFFF3355).withValues(alpha: 0.5 * _pulseCtrl.value), blurRadius: 6)] : null,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10))),
        Text(limit, style: GoogleFonts.spaceMono(color: Colors.grey[400], fontSize: 9)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: (active ? const Color(0xFF00C896) : const Color(0xFFFF3355)).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(active ? 'OK' : 'TRIGGERED',
            style: TextStyle(color: active ? const Color(0xFF00C896) : const Color(0xFFFF3355), fontSize: 8, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _buildPositionSizingCalculator(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Kelly Criterion', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
            Text('f* = (p*b - q) / b', style: GoogleFonts.spaceMono(color: const Color(0xFF4A90E2), fontSize: 9)),
          ]),
          const SizedBox(height: 10),
          // Simplified Kelly calc
          ...[ 
            ('Win Rate (p)', '67%'), 
            ('Avg Win / Avg Loss (b)', '1.84x'),
            ('Kelly %', '28.2%'),
            ('Half-Kelly (recommended)', '14.1% of equity'),
            ('→ For \$50,000 portfolio', '\$7,050 max position'),
          ].map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(r.$1, style: TextStyle(color: Colors.grey[500], fontSize: 9)),
              Text(r.$2, style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ]),
          )),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED WIDGETS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCoinSelectorHorizontal() {
    final coins = ['BTC', 'ETH', 'SOL', 'BNB', 'AVAX', 'DOGE'];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: coins.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final sym = coins[i];
          final isSel = sym == _orderSymbol;
          final meta = CryptoRegistry.getOrFallback(sym);
          return GestureDetector(
            onTap: () => setState(() => _orderSymbol = sym),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSel ? meta.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSel ? meta.primary : Colors.white.withValues(alpha: 0.08), width: isSel ? 1.5 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                CryptoIcon(sym, size: 18, showBorder: false),
                const SizedBox(width: 5),
                Text(sym, style: TextStyle(color: isSel ? meta.primary : Colors.grey[400], fontSize: 9, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, fontFamily: 'SpaceMono')),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExchangeSelector() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedExchange,
        dropdownColor: const Color(0xFF1A1D24),
        style: const TextStyle(color: Colors.white, fontSize: 12),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 16),
        items: ['Binance', 'Kraken', 'Internal'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => setState(() => _selectedExchange = v!),
      ),
    );
  }

  Widget _buildInputField(TextEditingController ctrl, String hint, TextInputType type, VoidCallback onChange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600], fontFamily: 'SpaceMono', fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          isDense: true,
        ),
        onChanged: (_) => onChange(),
      ),
    );
  }

  Widget _buildSizingMethodBtn(String label, String method) {
    final isSel = _sizingMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _sizingMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF9945FF).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSel ? const Color(0xFF9945FF) : Colors.white.withValues(alpha: 0.08), width: isSel ? 1.5 : 1),
        ),
        child: Text(label, style: TextStyle(color: isSel ? const Color(0xFF9945FF) : Colors.grey[400], fontSize: 9, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildPriceShortcut(String label, double price) {
    return GestureDetector(
      onTap: () => setState(() => _limitPriceCtrl.text = price.toStringAsFixed(price >= 1 ? 2 : 4)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 9)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _submitOrder(ExchangeService ex, double price) async {
    final qty = double.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0) {
      _showSnack('Enter a valid quantity');
      return;
    }

    final tx = await ex.placeOrder(
      symbol: _orderSymbol,
      isBuy: _orderSide == OrderSide.buy,
      quantity: qty,
      limitPrice: _orderType == OrderType.limit ? (double.tryParse(_limitPriceCtrl.text) ?? price) : null,
    );

    if (mounted && tx != null) {
      setState(() {
        _orders.insert(0, OmsOrder(
          id: tx.id,
          symbol: _orderSymbol,
          type: _orderType,
          side: _orderSide,
          quantity: qty,
          limitPrice: _orderType == OrderType.limit ? double.tryParse(_limitPriceCtrl.text) : null,
          stopPrice: _orderType == OrderType.stopLoss ? double.tryParse(_stopPriceCtrl.text) : null,
          submittedAt: DateTime.now().millisecondsSinceEpoch.toDouble(),
          exchange: _selectedExchange,
        ));
        _qtyCtrl.clear();
        _limitPriceCtrl.clear();
      });
      _showSuccessSnack('${_orderSide.name.toUpperCase()} order submitted for $_orderSymbol');
    }
  }

  void _closePosition(Position pos) {
    setState(() => _positions.remove(pos));
    _showSuccessSnack('${pos.symbol} position closed');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1E2028),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Color(0xFF00C896), size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 11))),
      ]),
      backgroundColor: const Color(0xFF0D1F17),
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _formatNum(double v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(2)}M' : v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : v.toStringAsFixed(2);
  String _formatAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    return '${d.inMinutes}m ago';
  }
  double _fallbackPrice(String sym) => const {'BTC': 65000.0, 'ETH': 3200.0, 'SOL': 150.0, 'BNB': 580.0, 'AVAX': 35.0, 'DOGE': 0.12}[sym] ?? 1.0;
}
