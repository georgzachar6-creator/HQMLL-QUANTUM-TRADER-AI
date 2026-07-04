// ════════════════════════════════════════════════════════════════════════════
// AUTO TRADING SERVICE  v54.0
// Quantum Trader AI — Enterprise Autonomous Trading Engine
// Features: Multi-Strategy Orchestrator · Live Order Execution
//           MiFID II Art.17 Kill-Switch · Pre-Trade Risk Checks
//           Self-Learning Strategy Scoring · Position Management
// ════════════════════════════════════════════════════════════════════════════
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import 'broker_api_service.dart';
import 'market_data_hub_service.dart';
import 'risk_engine_service.dart';
import 'websocket_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STRATEGY MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum StrategyType {
  trend,
  meanReversion,
  momentum,
  gridTrading,
  dca,
  arbitrage,
  scalping,
  breakout,
}

enum SignalStrength { none, weak, moderate, strong, veryStrong }

enum BotStatus { idle, running, paused, stopped, killSwitchActive }

class TradingSignal {
  final String symbol;
  final OrderSide side;
  final SignalStrength strength;
  final String strategyId;
  final String reason;
  final double entryPrice;
  final double? stopLoss;
  final double? takeProfit;
  final double suggestedQuantity;
  final double confidence; // 0..1
  final DateTime generatedAt;

  const TradingSignal({
    required this.symbol,
    required this.side,
    required this.strength,
    required this.strategyId,
    required this.reason,
    required this.entryPrice,
    this.stopLoss,
    this.takeProfit,
    required this.suggestedQuantity,
    required this.confidence,
    required this.generatedAt,
  });

  bool get isActionable =>
      strength.index >= SignalStrength.moderate.index && confidence >= 0.55;

  String get strengthLabel {
    switch (strength) {
      case SignalStrength.none: return 'NONE';
      case SignalStrength.weak: return 'WEAK';
      case SignalStrength.moderate: return 'MODERATE';
      case SignalStrength.strong: return 'STRONG';
      case SignalStrength.veryStrong: return 'VERY STRONG';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STRATEGY BASE
// ─────────────────────────────────────────────────────────────────────────────

abstract class TradingStrategy {
  String get id;
  String get name;
  StrategyType get type;
  bool enabled;
  double allocation; // 0..1 of available capital
  double score;      // adaptive performance score

  TradingStrategy({
    this.enabled = true,
    this.allocation = 0.1,
    this.score = 1.0,
  });

  TradingSignal? evaluate(PriceTick tick, List<double> priceHistory);

  void updateScore(bool wasProfit, double pnlPct) {
    // Bayesian-style score update
    if (wasProfit) {
      score = (score * 0.9 + 1.0 * 0.1).clamp(0.1, 2.0);
    } else {
      score = (score * 0.9 + 0.0 * 0.1).clamp(0.1, 2.0);
    }
  }
}

// ── TREND FOLLOWING ────────────────────────────────────────────────────────

class TrendStrategy extends TradingStrategy {
  final int fastPeriod;
  final int slowPeriod;

  TrendStrategy({
    this.fastPeriod = 10,
    this.slowPeriod = 30,
    super.enabled,
    super.allocation = 0.15,
  }) : super(score: 1.0);

  @override
  String get id => 'TREND_${fastPeriod}_$slowPeriod';
  @override
  String get name => 'Trend Following ($fastPeriod/$slowPeriod EMA)';
  @override
  StrategyType get type => StrategyType.trend;

  @override
  TradingSignal? evaluate(PriceTick tick, List<double> priceHistory) {
    if (priceHistory.length < slowPeriod + 5) return null;

    final fast = _ema(priceHistory, fastPeriod);
    final slow = _ema(priceHistory, slowPeriod);
    final prevFast = _ema(priceHistory.sublist(0, priceHistory.length - 1), fastPeriod);
    final prevSlow = _ema(priceHistory.sublist(0, priceHistory.length - 1), slowPeriod);

    final crossedUp = prevFast <= prevSlow && fast > slow;
    final crossedDown = prevFast >= prevSlow && fast < slow;
    final gap = (fast - slow).abs() / slow;

    if (crossedUp) {
      final strength = gap > 0.02 ? SignalStrength.strong : SignalStrength.moderate;
      return TradingSignal(
        symbol: tick.symbol,
        side: OrderSide.buy,
        strength: strength,
        strategyId: id,
        reason: 'EMA $fastPeriod x $slowPeriod Kreuzung aufwärts (Gap: ${(gap * 100).toStringAsFixed(2)}%)',
        entryPrice: tick.price,
        stopLoss: tick.price * 0.97,
        takeProfit: tick.price * 1.05,
        suggestedQuantity: _calcQty(tick.price),
        confidence: 0.6 + gap.clamp(0, 0.3),
        generatedAt: DateTime.now(),
      );
    }
    if (crossedDown) {
      final strength = gap > 0.02 ? SignalStrength.strong : SignalStrength.moderate;
      return TradingSignal(
        symbol: tick.symbol,
        side: OrderSide.sell,
        strength: strength,
        strategyId: id,
        reason: 'EMA $fastPeriod x $slowPeriod Kreuzung abwärts (Gap: ${(gap * 100).toStringAsFixed(2)}%)',
        entryPrice: tick.price,
        stopLoss: tick.price * 1.03,
        takeProfit: tick.price * 0.95,
        suggestedQuantity: _calcQty(tick.price),
        confidence: 0.6 + gap.clamp(0, 0.3),
        generatedAt: DateTime.now(),
      );
    }
    return null;
  }

  double _ema(List<double> prices, int period) {
    if (prices.isEmpty || period <= 0) return 0;
    final slice = prices.length > period
        ? prices.sublist(prices.length - period)
        : prices;
    final k = 2.0 / (period + 1);
    double ema = slice.first;
    for (int i = 1; i < slice.length; i++) {
      ema = slice[i] * k + ema * (1 - k);
    }
    return ema;
  }

  double _calcQty(double price) {
    if (price <= 0) return 0.001;
    const tradeSize = 1000.0; // USD
    return (tradeSize / price).clamp(0.0001, 100.0);
  }
}

// ── MEAN REVERSION ─────────────────────────────────────────────────────────

class MeanReversionStrategy extends TradingStrategy {
  final int period;
  final double zScoreThreshold;

  MeanReversionStrategy({
    this.period = 20,
    this.zScoreThreshold = 2.0,
    super.enabled,
    super.allocation = 0.1,
  }) : super(score: 1.0);

  @override
  String get id => 'MEAN_REV_$period';
  @override
  String get name => 'Mean Reversion ($period period, z≥$zScoreThreshold)';
  @override
  StrategyType get type => StrategyType.meanReversion;

  @override
  TradingSignal? evaluate(PriceTick tick, List<double> priceHistory) {
    if (priceHistory.length < period + 2) return null;

    final slice = priceHistory.sublist(priceHistory.length - period);
    final mean = slice.reduce((a, b) => a + b) / slice.length;
    final variance = slice.map((p) => pow(p - mean, 2)).reduce((a, b) => a + b) / slice.length;
    final std = sqrt(variance.toDouble());
    if (std == 0) return null;

    final zScore = (tick.price - mean) / std;

    if (zScore < -zScoreThreshold) {
      return TradingSignal(
        symbol: tick.symbol,
        side: OrderSide.buy,
        strength: zScore.abs() > 3 ? SignalStrength.veryStrong : SignalStrength.strong,
        strategyId: id,
        reason: 'Z-Score ${zScore.toStringAsFixed(2)} → stark überverkauft, Reversion erwartet',
        entryPrice: tick.price,
        stopLoss: tick.price * 0.96,
        takeProfit: mean,
        suggestedQuantity: _calcQty(tick.price),
        confidence: (zScore.abs() / 4).clamp(0.5, 0.95),
        generatedAt: DateTime.now(),
      );
    }
    if (zScore > zScoreThreshold) {
      return TradingSignal(
        symbol: tick.symbol,
        side: OrderSide.sell,
        strength: zScore > 3 ? SignalStrength.veryStrong : SignalStrength.strong,
        strategyId: id,
        reason: 'Z-Score ${zScore.toStringAsFixed(2)} → stark überkauft, Reversion erwartet',
        entryPrice: tick.price,
        stopLoss: tick.price * 1.04,
        takeProfit: mean,
        suggestedQuantity: _calcQty(tick.price),
        confidence: (zScore / 4).clamp(0.5, 0.95),
        generatedAt: DateTime.now(),
      );
    }
    return null;
  }

  double _calcQty(double price) =>
      price > 0 ? (800.0 / price).clamp(0.0001, 50.0) : 0.001;
}

// ── MOMENTUM STRATEGY ───────────────────────────────────────────────────────

class MomentumStrategy extends TradingStrategy {
  final int rsiPeriod;
  final double rsiOversold;
  final double rsiOverbought;

  MomentumStrategy({
    this.rsiPeriod = 14,
    this.rsiOversold = 30,
    this.rsiOverbought = 70,
    super.enabled,
    super.allocation = 0.12,
  }) : super(score: 1.0);

  @override
  String get id => 'MOMENTUM_RSI_$rsiPeriod';
  @override
  String get name => 'Momentum RSI($rsiPeriod) [$rsiOversold/$rsiOverbought]';
  @override
  StrategyType get type => StrategyType.momentum;

  @override
  TradingSignal? evaluate(PriceTick tick, List<double> priceHistory) {
    final rsi = _computeRsi(priceHistory);
    if (rsi == null) return null;

    if (rsi < rsiOversold) {
      return TradingSignal(
        symbol: tick.symbol,
        side: OrderSide.buy,
        strength: rsi < 20 ? SignalStrength.veryStrong : SignalStrength.moderate,
        strategyId: id,
        reason: 'RSI ${rsi.toStringAsFixed(1)} < $rsiOversold — überverkauft',
        entryPrice: tick.price,
        stopLoss: tick.price * 0.95,
        takeProfit: tick.price * 1.08,
        suggestedQuantity: _calcQty(tick.price),
        confidence: (rsiOversold - rsi) / rsiOversold * 1.5,
        generatedAt: DateTime.now(),
      );
    }
    if (rsi > rsiOverbought) {
      return TradingSignal(
        symbol: tick.symbol,
        side: OrderSide.sell,
        strength: rsi > 80 ? SignalStrength.veryStrong : SignalStrength.moderate,
        strategyId: id,
        reason: 'RSI ${rsi.toStringAsFixed(1)} > $rsiOverbought — überkauft',
        entryPrice: tick.price,
        stopLoss: tick.price * 1.05,
        takeProfit: tick.price * 0.92,
        suggestedQuantity: _calcQty(tick.price),
        confidence: (rsi - rsiOverbought) / (100 - rsiOverbought) * 1.5,
        generatedAt: DateTime.now(),
      );
    }
    return null;
  }

  double? _computeRsi(List<double> prices) {
    if (prices.length < rsiPeriod + 1) return null;
    final slice = prices.sublist(prices.length - rsiPeriod - 1);
    double gains = 0, losses = 0;
    for (int i = 1; i < slice.length; i++) {
      final diff = slice[i] - slice[i - 1];
      if (diff > 0) {
        gains += diff;
      } else {
        losses += diff.abs();
      }
    }
    if (losses == 0) return 100;
    final rs = gains / losses;
    return 100 - (100 / (1 + rs));
  }

  double _calcQty(double price) =>
      price > 0 ? (1200.0 / price).clamp(0.0001, 100.0) : 0.001;
}

// ── DCA STRATEGY ───────────────────────────────────────────────────────────

class DCAStrategy extends TradingStrategy {
  final String symbol;
  final double amountPerBuy;
  final Duration interval;
  DateTime? _lastBuy;

  DCAStrategy({
    required this.symbol,
    this.amountPerBuy = 500.0,
    this.interval = const Duration(days: 7),
    super.enabled,
    super.allocation = 0.05,
  }) : super(score: 1.0);

  @override
  String get id => 'DCA_${symbol}_${interval.inDays}d';
  @override
  String get name => 'DCA $symbol (${interval.inDays}d / \$${amountPerBuy.toInt()})';
  @override
  StrategyType get type => StrategyType.dca;

  @override
  TradingSignal? evaluate(PriceTick tick, List<double> priceHistory) {
    if (tick.symbol != symbol) return null;
    final now = DateTime.now();
    if (_lastBuy != null && now.difference(_lastBuy!) < interval) return null;

    _lastBuy = now;
    return TradingSignal(
      symbol: symbol,
      side: OrderSide.buy,
      strength: SignalStrength.moderate,
      strategyId: id,
      reason: 'DCA Kaufintervall erreicht — ${interval.inDays}d Rhythmus',
      entryPrice: tick.price,
      suggestedQuantity: (amountPerBuy / tick.price).clamp(0.0001, 100.0),
      confidence: 0.8,
      generatedAt: now,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OPEN POSITION TRACKER
// ─────────────────────────────────────────────────────────────────────────────

class OpenPosition {
  final String symbol;
  final OrderSide side;
  final double entryPrice;
  double currentPrice;
  final double quantity;
  final String strategyId;
  final double? stopLoss;
  final double? takeProfit;
  final DateTime openedAt;
  DateTime updatedAt;
  String orderId;

  OpenPosition({
    required this.symbol,
    required this.side,
    required this.entryPrice,
    required this.currentPrice,
    required this.quantity,
    required this.strategyId,
    this.stopLoss,
    this.takeProfit,
    required this.openedAt,
    required this.updatedAt,
    required this.orderId,
  });

  double get unrealizedPnl {
    final diff = side == OrderSide.buy
        ? (currentPrice - entryPrice) * quantity
        : (entryPrice - currentPrice) * quantity;
    return diff;
  }

  double get unrealizedPnlPct {
    if (entryPrice == 0) return 0;
    final diff = side == OrderSide.buy
        ? (currentPrice - entryPrice) / entryPrice * 100
        : (entryPrice - currentPrice) / entryPrice * 100;
    return diff;
  }

  bool get shouldStopLoss =>
      stopLoss != null &&
      (side == OrderSide.buy
          ? currentPrice <= stopLoss!
          : currentPrice >= stopLoss!);

  bool get shouldTakeProfit =>
      takeProfit != null &&
      (side == OrderSide.buy
          ? currentPrice >= takeProfit!
          : currentPrice <= takeProfit!);
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTO TRADING SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class AutoTradingService extends ChangeNotifier {
  static final AutoTradingService _instance = AutoTradingService._();
  factory AutoTradingService() => _instance;
  AutoTradingService._() {
    _initDefaultStrategies();
  }

  // ── Core Services ──────────────────────────────────────────────────────────
  final BrokerApiService _broker = BrokerApiService();
  final MarketDataHubService _hub = MarketDataHubService();
  // RiskEngineService für zukünftige direkte Risikointegration
  // ignore: unused_field
  final RiskEngineService _risk = RiskEngineService();

  // ── State ──────────────────────────────────────────────────────────────────
  BotStatus _status = BotStatus.idle;
  final List<TradingStrategy> _strategies = [];
  final List<TradingSignal> _signalLog = [];
  final List<OpenPosition> _openPositions = [];
  final List<Map<String, dynamic>> _tradeHistory = [];
  StreamSubscription<PriceTick>? _tickSub;
  Timer? _positionMonitorTimer;

  double _totalPnL = 0;
  double _todayPnL = 0;
  int _totalTrades = 0;
  int _winCount = 0;
  int _lossCount = 0;
  DateTime? _startedAt;

  // ── MiFID II Kill-Switch ───────────────────────────────────────────────────
  bool _killSwitchActive = false;
  double _maxDailyDrawdown = -3.0; // % - MiFID II compliance
  double _maxPositionSizePct = 5.0; // % of portfolio — enforced via pre-trade check
  double _portfolioValue = 100000.0;

  // ── Getters ────────────────────────────────────────────────────────────────
  BotStatus get status => _status;
  bool get isRunning => _status == BotStatus.running;
  bool get killSwitchActive => _killSwitchActive;
  List<TradingStrategy> get strategies => List.unmodifiable(_strategies);
  List<TradingStrategy> get activeStrategies =>
      _strategies.where((s) => s.enabled).toList();
  List<TradingSignal> get signalLog =>
      List.unmodifiable(_signalLog.reversed.take(100).toList());
  List<OpenPosition> get openPositions => List.unmodifiable(_openPositions);
  List<Map<String, dynamic>> get tradeHistory =>
      List.unmodifiable(_tradeHistory.take(200).toList());

  double get totalPnL => _totalPnL;
  double get todayPnL => _todayPnL;
  int get totalTrades => _totalTrades;
  double get winRate => _totalTrades > 0 ? _winCount / _totalTrades * 100 : 0;
  double get avgWin => _winCount > 0 ? _totalPnL / _winCount : 0;
  DateTime? get startedAt => _startedAt;

  int get activeStrategyCount => activeStrategies.length;
  int get openPositionCount => _openPositions.length;

  // ── Initialize Default Strategies ─────────────────────────────────────────
  void _initDefaultStrategies() {
    _strategies.addAll([
      TrendStrategy(fastPeriod: 10, slowPeriod: 30, enabled: true),
      TrendStrategy(fastPeriod: 20, slowPeriod: 50, enabled: false),
      MeanReversionStrategy(period: 20, zScoreThreshold: 2.0, enabled: true),
      MomentumStrategy(rsiPeriod: 14, rsiOversold: 30, rsiOverbought: 70, enabled: true),
      MomentumStrategy(rsiPeriod: 7, rsiOversold: 25, rsiOverbought: 75, enabled: false),
      DCAStrategy(symbol: 'BTC', amountPerBuy: 500, interval: const Duration(days: 7), enabled: false),
      DCAStrategy(symbol: 'ETH', amountPerBuy: 300, interval: const Duration(days: 7), enabled: false),
    ]);
  }

  // ── Start Engine ───────────────────────────────────────────────────────────
  Future<void> start() async {
    if (_killSwitchActive) {
      throw Exception('Kill switch active — cannot start trading');
    }
    if (_status == BotStatus.running) return;

    _status = BotStatus.running;
    _startedAt = DateTime.now();

    // Subscribe to hub tick stream
    _tickSub = _hub.tickStream.listen(_onTick);

    // Position monitor (every 10 seconds)
    _positionMonitorTimer = Timer.periodic(
        const Duration(seconds: 10), (_) => _monitorPositions());

    if (kDebugMode) debugPrint('[AUTO-TRADE] Engine started with $activeStrategyCount strategies');
    notifyListeners();
  }

  void pause() {
    if (_status != BotStatus.running) return;
    _status = BotStatus.paused;
    _tickSub?.pause();
    notifyListeners();
  }

  void resume() {
    if (_status != BotStatus.paused) return;
    _status = BotStatus.running;
    _tickSub?.resume();
    notifyListeners();
  }

  void stop() {
    _status = BotStatus.stopped;
    _tickSub?.cancel();
    _positionMonitorTimer?.cancel();
    notifyListeners();
  }

  // ── Kill Switch (MiFID II Art. 17) ────────────────────────────────────────
  void activateKillSwitch({String reason = 'Manual'}) {
    _killSwitchActive = true;
    _status = BotStatus.killSwitchActive;
    _tickSub?.cancel();
    _positionMonitorTimer?.cancel();
    _broker.activateKillSwitch();
    _hub.activateKillSwitch(reason: reason);
    if (kDebugMode) debugPrint('[AUTO-TRADE][KILL-SWITCH] $reason');
    notifyListeners();
  }

  void deactivateKillSwitch() {
    _killSwitchActive = false;
    _broker.deactivateKillSwitch();
    _hub.deactivateKillSwitch();
    _status = BotStatus.idle;
    notifyListeners();
  }

  // ── Tick Handler ───────────────────────────────────────────────────────────
  void _onTick(PriceTick tick) {
    if (_status != BotStatus.running) return;
    if (_killSwitchActive) return;

    // MiFID II daily drawdown guard
    if (_todayPnL / _portfolioValue * 100 < _maxDailyDrawdown) {
      activateKillSwitch(reason: 'Daily drawdown limit breached');
      return;
    }

    // Update open position prices
    for (final pos in _openPositions) {
      if (pos.symbol == tick.symbol) {
        pos.currentPrice = tick.price;
        pos.updatedAt = DateTime.now();
      }
    }

    // Run strategies
    final priceHistory = _hub.tickBuffer
        .forSymbol(tick.symbol)
        .map((t) => t.price)
        .toList();

    for (final strategy in activeStrategies) {
      try {
        final signal = strategy.evaluate(tick, priceHistory);
        if (signal != null && signal.isActionable) {
          _processSignal(signal, strategy);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[AUTO-TRADE] Strategy error ${strategy.id}: $e');
      }
    }
  }

  // ── Signal Processing ──────────────────────────────────────────────────────
  void _processSignal(TradingSignal signal, TradingStrategy strategy) {
    // Log signal
    _signalLog.add(signal);
    if (_signalLog.length > 500) _signalLog.removeAt(0);

    // Pre-trade risk check (MiFID II) — includes max position size guard
    final maxQty = (_portfolioValue * _maxPositionSizePct / 100) /
        (signal.entryPrice > 0 ? signal.entryPrice : 1);
    final adjQty = signal.suggestedQuantity.clamp(0.0001, maxQty);
    final check = _broker.preTradeCheck(
      symbol: signal.symbol,
      side: signal.side,
      quantity: adjQty,
      currentPrice: signal.entryPrice,
      limitPrice: null,
    );

    if (!check.approved) {
      if (kDebugMode) debugPrint('[AUTO-TRADE] Pre-trade check FAILED: ${check.violations}');
      notifyListeners();
      return;
    }

    // Execute order
    _executeSignal(signal, strategy);
    notifyListeners();
  }

  Future<void> _executeSignal(
      TradingSignal signal, TradingStrategy strategy) async {
    try {
      final maxQtyExec = (_portfolioValue * _maxPositionSizePct / 100) /
          (signal.entryPrice > 0 ? signal.entryPrice : 1);
      final execQty = signal.suggestedQuantity.clamp(0.0001, maxQtyExec);
      final order = await _broker.placeOrder(
        symbol: signal.symbol,
        side: signal.side,
        quantity: execQty,
        type: OrderType.market,
        currentPrice: signal.entryPrice,
      );

      if (order.status == OrderStatus.filled ||
          order.status == OrderStatus.submitted) {
        _openPositions.add(OpenPosition(
          symbol: signal.symbol,
          side: signal.side,
          entryPrice: signal.entryPrice,
          currentPrice: signal.entryPrice,
          quantity: signal.suggestedQuantity,
          strategyId: strategy.id,
          stopLoss: signal.stopLoss,
          takeProfit: signal.takeProfit,
          openedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          orderId: order.id,
        ));
        _totalTrades++;
        if (kDebugMode) {
          debugPrint('[AUTO-TRADE] Order placed: ${order.sideLabel} ${signal.symbol} @ ${signal.entryPrice}');
        }
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AUTO-TRADE] Order error: $e');
    }
  }

  // ── Position Monitor ───────────────────────────────────────────────────────
  void _monitorPositions() {
    final toClose = <OpenPosition>[];

    for (final pos in _openPositions) {
      if (pos.shouldStopLoss || pos.shouldTakeProfit) {
        toClose.add(pos);
      }
    }

    for (final pos in toClose) {
      _closePosition(pos,
          reason: pos.shouldStopLoss ? 'Stop Loss' : 'Take Profit');
    }
  }

  Future<void> _closePosition(OpenPosition pos, {String reason = 'Manual'}) async {
    try {
      final closeSide =
          pos.side == OrderSide.buy ? OrderSide.sell : OrderSide.buy;
      await _broker.placeOrder(
        symbol: pos.symbol,
        side: closeSide,
        quantity: pos.quantity,
        type: OrderType.market,
        currentPrice: pos.currentPrice,
      );

      final pnl = pos.unrealizedPnl;
      _totalPnL += pnl;
      _todayPnL += pnl;
      if (pnl > 0) {
        _winCount++;
      } else {
        _lossCount++;
      }

      // Find & update strategy score
      final strategy = _strategies.firstWhere(
        (s) => s.id == pos.strategyId,
        orElse: () => _strategies.first,
      );
      strategy.updateScore(pnl > 0, pos.unrealizedPnlPct);

      // Log trade
      _tradeHistory.insert(0, {
        'symbol': pos.symbol,
        'side': pos.side.name,
        'quantity': pos.quantity,
        'entryPrice': pos.entryPrice,
        'exitPrice': pos.currentPrice,
        'pnl': pnl,
        'pnlPct': pos.unrealizedPnlPct,
        'strategyId': pos.strategyId,
        'reason': reason,
        'closedAt': DateTime.now().toIso8601String(),
      });

      _openPositions.remove(pos);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[AUTO-TRADE] Close position error: $e');
    }
  }

  // ── Manual Close ───────────────────────────────────────────────────────────
  Future<void> closePosition(String symbol) async {
    final pos = _openPositions.firstWhere(
      (p) => p.symbol == symbol,
      orElse: () => throw Exception('Position not found'),
    );
    await _closePosition(pos, reason: 'Manuell geschlossen');
  }

  // ── Strategy Management ────────────────────────────────────────────────────
  void toggleStrategy(String strategyId, bool enabled) {
    final s = _strategies.firstWhere((s) => s.id == strategyId,
        orElse: () => throw Exception('Strategy not found'));
    s.enabled = enabled;
    notifyListeners();
  }

  void setStrategyAllocation(String strategyId, double alloc) {
    final s = _strategies.firstWhere((s) => s.id == strategyId,
        orElse: () => throw Exception('Strategy not found'));
    s.allocation = alloc.clamp(0.01, 0.5);
    notifyListeners();
  }

  // ── Risk Parameter Updates ─────────────────────────────────────────────────
  void setMaxDailyDrawdown(double pct) {
    _maxDailyDrawdown = pct.clamp(-50.0, 0.0);
    notifyListeners();
  }

  void setMaxPositionSize(double pct) {
    _maxPositionSizePct = pct.clamp(0.5, 20.0);
    notifyListeners();
  }

  void setPortfolioValue(double value) {
    _portfolioValue = value.clamp(100, 1e9);
    notifyListeners();
  }

  void resetDailyPnL() {
    _todayPnL = 0;
    notifyListeners();
  }

  // ── Performance Stats ──────────────────────────────────────────────────────
  Map<String, dynamic> get performanceStats => {
    'total_pnl': _totalPnL,
    'today_pnl': _todayPnL,
    'total_trades': _totalTrades,
    'win_count': _winCount,
    'loss_count': _lossCount,
    'win_rate': winRate,
    'open_positions': _openPositions.length,
    'active_strategies': activeStrategyCount,
    'status': _status.name,
    'kill_switch': _killSwitchActive,
    'uptime_seconds': _startedAt != null
        ? DateTime.now().difference(_startedAt!).inSeconds
        : 0,
  };

  // ── Strategy Leaderboard ───────────────────────────────────────────────────
  List<TradingStrategy> get strategyLeaderboard {
    final sorted = [..._strategies];
    sorted.sort((a, b) => b.score.compareTo(a.score));
    return sorted;
  }

  @override
  void dispose() {
    stop();
    _tickSub?.cancel();
    _positionMonitorTimer?.cancel();
    super.dispose();
  }
}
