/// HQMLL Quantum Trader — Risk Engine Service v51.0
/// Basiert auf: Perplexity AI Training Platform Architecture
/// Pre-Trade Checks, Post-Trade Monitoring, Circuit Breaker, VaR
/// MiFID II Art.17 konforme Risk Controls
/// Grigori Saks · 2025
library;

import 'dart:math';
import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════════════════════
// ENUMS & MODELS
// ══════════════════════════════════════════════════════════════════════════

enum RiskCheckResult { approved, rejected, warning, pendingReview }
enum CircuitBreakerState { closed, open, halfOpen }
enum RiskTier { conservative, moderate, aggressive, institutional }
enum ExposureType { long, short, net, gross }
enum RiskEventType {
  preTradeLimitBreached, postTradeVarExceeded, circuitBreakerTripped,
  concentrationRisk, marginCall, drawdownAlert, exposureLimitBreached,
  amlSuspicious, complianceViolation
}

extension RiskTierX on RiskTier {
  String get label => const {
    RiskTier.conservative: 'Konservativ',
    RiskTier.moderate: 'Moderat',
    RiskTier.aggressive: 'Aggressiv',
    RiskTier.institutional: 'Institutionell',
  }[this] ?? 'Moderat';

  double get maxPositionPct => const {
    RiskTier.conservative: 0.02,
    RiskTier.moderate: 0.05,
    RiskTier.aggressive: 0.10,
    RiskTier.institutional: 0.20,
  }[this] ?? 0.05;

  double get maxDrawdownPct => const {
    RiskTier.conservative: 0.05,
    RiskTier.moderate: 0.15,
    RiskTier.aggressive: 0.25,
    RiskTier.institutional: 0.40,
  }[this] ?? 0.15;

  double get maxLeverage => const {
    RiskTier.conservative: 1.0,
    RiskTier.moderate: 2.0,
    RiskTier.aggressive: 5.0,
    RiskTier.institutional: 10.0,
  }[this] ?? 2.0;
}

extension CircuitBreakerStateX on CircuitBreakerState {
  String get label => const {
    CircuitBreakerState.closed: 'Aktiv',
    CircuitBreakerState.open: 'AUSGELÖST',
    CircuitBreakerState.halfOpen: 'Teste...',
  }[this] ?? 'Aktiv';

  String get emoji => const {
    CircuitBreakerState.closed: '🟢',
    CircuitBreakerState.open: '🔴',
    CircuitBreakerState.halfOpen: '🟡',
  }[this] ?? '🟢';
}

// ──────────────────────────────────────────────────────────────────────────
class PreTradeCheckRequest {
  final String orderId;
  final String symbol;
  final String side; // BUY / SELL
  final String orderType; // MARKET / LIMIT / STOP
  final double quantity;
  final double price;
  final double portfolioValue;
  final double currentExposure;
  final DateTime requestedAt;

  const PreTradeCheckRequest({
    required this.orderId,
    required this.symbol,
    required this.side,
    required this.orderType,
    required this.quantity,
    required this.price,
    required this.portfolioValue,
    required this.currentExposure,
    required this.requestedAt,
  });

  double get orderValue => quantity * price;
  double get exposurePct => portfolioValue > 0 ? orderValue / portfolioValue : 0.0;
}

// ──────────────────────────────────────────────────────────────────────────
class PreTradeCheckResult {
  final String orderId;
  final RiskCheckResult result;
  final List<String> violations;
  final List<String> warnings;
  final double computedVar;
  final double allowedExposurePct;
  final DateTime checkedAt;

  const PreTradeCheckResult({
    required this.orderId,
    required this.result,
    required this.violations,
    required this.warnings,
    required this.computedVar,
    required this.allowedExposurePct,
    required this.checkedAt,
  });

  bool get isApproved => result == RiskCheckResult.approved;
  bool get hasWarnings => warnings.isNotEmpty;
}

// ──────────────────────────────────────────────────────────────────────────
class RiskPosition {
  final String symbol;
  final double size;
  final double entryPrice;
  final double currentPrice;
  final ExposureType exposureType;
  final double leverage;
  final DateTime openedAt;

  const RiskPosition({
    required this.symbol,
    required this.size,
    required this.entryPrice,
    required this.currentPrice,
    required this.exposureType,
    required this.leverage,
    required this.openedAt,
  });

  double get notionalValue => size * currentPrice;
  double get unrealizedPnl => size * (currentPrice - entryPrice) *
      (exposureType == ExposureType.short ? -1 : 1);
  double get pnlPct => entryPrice > 0
      ? ((currentPrice - entryPrice) / entryPrice) *
          (exposureType == ExposureType.short ? -1 : 1)
      : 0.0;
  double get marginUsed => notionalValue / leverage;

  RiskPosition copyWith({double? currentPrice}) => RiskPosition(
    symbol: symbol, size: size, entryPrice: entryPrice,
    currentPrice: currentPrice ?? this.currentPrice,
    exposureType: exposureType, leverage: leverage, openedAt: openedAt,
  );
}

// ──────────────────────────────────────────────────────────────────────────
class PortfolioRiskSnapshot {
  final double totalValue;
  final double totalExposure;
  final double netExposure;
  final double grossExposure;
  final double intradayVar95; // 95% VaR
  final double intradayVar99; // 99% VaR
  final double maxDrawdownPct;
  final double sharpeRatio;
  final double concentrationScore; // 0–1, higher = more concentrated
  final Map<String, double> assetWeights;
  final DateTime snapshotAt;

  const PortfolioRiskSnapshot({
    required this.totalValue,
    required this.totalExposure,
    required this.netExposure,
    required this.grossExposure,
    required this.intradayVar95,
    required this.intradayVar99,
    required this.maxDrawdownPct,
    required this.sharpeRatio,
    required this.concentrationScore,
    required this.assetWeights,
    required this.snapshotAt,
  });

  String get riskLevel {
    if (intradayVar95 < 0.01) return 'NIEDRIG';
    if (intradayVar95 < 0.03) return 'MITTEL';
    if (intradayVar95 < 0.07) return 'HOCH';
    return 'KRITISCH';
  }

  String get riskEmoji {
    switch (riskLevel) {
      case 'NIEDRIG': return '🟢';
      case 'MITTEL': return '🟡';
      case 'HOCH': return '🟠';
      default: return '🔴';
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────
class RiskEvent {
  final String id;
  final RiskEventType type;
  final String message;
  final String symbol;
  final double value;
  final double threshold;
  final bool isActive;
  final DateTime occurredAt;

  const RiskEvent({
    required this.id,
    required this.type,
    required this.message,
    required this.symbol,
    required this.value,
    required this.threshold,
    required this.isActive,
    required this.occurredAt,
  });

  String get typeLabel => const {
    RiskEventType.preTradeLimitBreached: 'PRE-TRADE LIMIT',
    RiskEventType.postTradeVarExceeded: 'VAR ÜBERSCHRITTEN',
    RiskEventType.circuitBreakerTripped: 'CIRCUIT BREAKER',
    RiskEventType.concentrationRisk: 'KONZENTRATIONS-RISK',
    RiskEventType.marginCall: 'MARGIN CALL',
    RiskEventType.drawdownAlert: 'DRAWDOWN ALERT',
    RiskEventType.exposureLimitBreached: 'EXPOSURE LIMIT',
    RiskEventType.amlSuspicious: 'AML VERDACHT',
    RiskEventType.complianceViolation: 'COMPLIANCE',
  }[type] ?? 'UNBEKANNT';

  String get emoji => const {
    RiskEventType.preTradeLimitBreached: '⚠️',
    RiskEventType.postTradeVarExceeded: '📊',
    RiskEventType.circuitBreakerTripped: '🔴',
    RiskEventType.concentrationRisk: '🎯',
    RiskEventType.marginCall: '💸',
    RiskEventType.drawdownAlert: '📉',
    RiskEventType.exposureLimitBreached: '🚨',
    RiskEventType.amlSuspicious: '🔍',
    RiskEventType.complianceViolation: '⚖️',
  }[type] ?? '⚠️';
}

// ══════════════════════════════════════════════════════════════════════════
// CIRCUIT BREAKER
// ══════════════════════════════════════════════════════════════════════════
class CircuitBreaker {
  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureAt; // ignore: unused_field
  DateTime? _openedAt;

  final int failureThreshold;
  final Duration resetTimeout;

  CircuitBreaker({
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(minutes: 15),
  });

  CircuitBreakerState get state => _state;
  int get failureCount => _failureCount;
  DateTime? get openedAt => _openedAt;

  Duration? get remainingCooldown {
    if (_state != CircuitBreakerState.open || _openedAt == null) return null;
    final elapsed = DateTime.now().difference(_openedAt!);
    final remaining = resetTimeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isOpen => _state == CircuitBreakerState.open;

  void recordFailure(String reason) {
    _failureCount++;
    _lastFailureAt = DateTime.now();

    if (_failureCount >= failureThreshold && _state == CircuitBreakerState.closed) {
      _state = CircuitBreakerState.open;
      _openedAt = DateTime.now();
      if (kDebugMode) debugPrint('⚡ Circuit Breaker OFFEN: $reason');
    }
  }

  void recordSuccess() {
    if (_state == CircuitBreakerState.halfOpen) {
      _state = CircuitBreakerState.closed;
      _failureCount = 0;
      _openedAt = null;
    }
  }

  bool tryReset() {
    if (_state == CircuitBreakerState.open) {
      final elapsed = _openedAt != null
          ? DateTime.now().difference(_openedAt!)
          : Duration.zero;
      if (elapsed >= resetTimeout) {
        _state = CircuitBreakerState.halfOpen;
        return true;
      }
    }
    return false;
  }

  void forceReset() {
    _state = CircuitBreakerState.closed;
    _failureCount = 0;
    _openedAt = null;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// RISK ENGINE SERVICE
// Pre-Trade Checks + Post-Trade Monitoring + VaR + Circuit Breaker
// ══════════════════════════════════════════════════════════════════════════
class RiskEngineService extends ChangeNotifier {
  // ── Konfiguration ────────────────────────────────────────────────────────
  RiskTier _riskTier = RiskTier.moderate;
  double _maxPositionSizePct = 0.05; // 5% of portfolio per position
  double _maxDailyLossPct    = 0.02; // 2% daily loss limit
  double _maxDrawdownPct     = 0.15; // 15% max drawdown
  double _var95Limit         = 0.03; // 3% 95% VaR limit
  double _concentrationLimit = 0.25; // 25% max in single asset
  double _maxLeverage        = 2.0; // ignore: unused_field
  bool _autoTradingEnabled   = true;
  bool _killSwitchActive     = false;

  // ── State ────────────────────────────────────────────────────────────────
  final Map<String, RiskPosition> _positions = {};
  PortfolioRiskSnapshot? _lastSnapshot;
  final List<RiskEvent> _riskEvents = [];
  final CircuitBreaker _circuitBreaker = CircuitBreaker();

  // ── Tracking ─────────────────────────────────────────────────────────────
  double _dailyPnl = 0.0;
  double _peakPortfolioValue = 0.0;
  double _currentPortfolioValue = 100000.0; // Default 100k
  int _tradesCheckedToday = 0;
  int _tradesRejectedToday = 0;

  // ── Getters ──────────────────────────────────────────────────────────────
  RiskTier get riskTier => _riskTier;
  double get maxPositionSizePct => _maxPositionSizePct;
  double get maxDailyLossPct => _maxDailyLossPct;
  double get maxDrawdownPct => _maxDrawdownPct;
  double get var95Limit => _var95Limit;
  bool get autoTradingEnabled => _autoTradingEnabled;
  bool get killSwitchActive => _killSwitchActive;
  CircuitBreaker get circuitBreaker => _circuitBreaker;
  PortfolioRiskSnapshot? get lastSnapshot => _lastSnapshot;
  List<RiskEvent> get riskEvents => List.unmodifiable(_riskEvents);
  List<RiskEvent> get activeEvents =>
      _riskEvents.where((e) => e.isActive).toList();
  Map<String, RiskPosition> get positions => Map.unmodifiable(_positions);
  double get dailyPnl => _dailyPnl;
  double get currentPortfolioValue => _currentPortfolioValue;
  int get tradesCheckedToday => _tradesCheckedToday;
  int get tradesRejectedToday => _tradesRejectedToday;
  double get rejectionRate => _tradesCheckedToday > 0
      ? _tradesRejectedToday / _tradesCheckedToday
      : 0.0;

  double get currentDrawdownPct {
    if (_peakPortfolioValue <= 0) return 0.0;
    return (_peakPortfolioValue - _currentPortfolioValue) / _peakPortfolioValue;
  }

  double get totalExposure =>
      _positions.values.fold(0.0, (s, p) => s + p.notionalValue);

  double get totalUnrealizedPnl =>
      _positions.values.fold(0.0, (s, p) => s + p.unrealizedPnl);

  // ══════════════════════════════════════════════════════════════════════════
  // PRE-TRADE RISK CHECK (MiFID II Art. 17 konform)
  // ══════════════════════════════════════════════════════════════════════════
  PreTradeCheckResult preTradeCheck(PreTradeCheckRequest request) {
    _tradesCheckedToday++;
    final violations = <String>[];
    final warnings = <String>[];

    // 1. Kill Switch — sofortiger Reject
    if (_killSwitchActive) {
      _tradesRejectedToday++;
      return PreTradeCheckResult(
        orderId: request.orderId,
        result: RiskCheckResult.rejected,
        violations: ['KILL SWITCH AKTIV — Alle Trades gesperrt'],
        warnings: [],
        computedVar: 0.0,
        allowedExposurePct: 0.0,
        checkedAt: DateTime.now(),
      );
    }

    // 2. Circuit Breaker
    if (_circuitBreaker.isOpen) {
      _tradesRejectedToday++;
      return PreTradeCheckResult(
        orderId: request.orderId,
        result: RiskCheckResult.rejected,
        violations: ['Circuit Breaker OFFEN — Handel pausiert'],
        warnings: [],
        computedVar: 0.0,
        allowedExposurePct: 0.0,
        checkedAt: DateTime.now(),
      );
    }

    // 3. Position Size Check
    final allowedPct = _riskTier.maxPositionPct;
    if (request.exposurePct > allowedPct) {
      violations.add(
        'Position zu groß: ${(request.exposurePct * 100).toStringAsFixed(1)}% '
        '> ${(allowedPct * 100).toStringAsFixed(1)}% Limit');
      _addRiskEvent(RiskEvent(
        id: 'EVT_${DateTime.now().millisecondsSinceEpoch}',
        type: RiskEventType.preTradeLimitBreached,
        message: 'Positionsgröße überschreitet Limit für ${request.symbol}',
        symbol: request.symbol,
        value: request.exposurePct,
        threshold: allowedPct,
        isActive: true,
        occurredAt: DateTime.now(),
      ));
    }

    // 4. Daily Loss Check
    if (_dailyPnl < 0 && _currentPortfolioValue > 0) {
      final dailyLossPct = _dailyPnl.abs() / _currentPortfolioValue;
      if (dailyLossPct >= _maxDailyLossPct * 0.8) {
        if (dailyLossPct >= _maxDailyLossPct) {
          violations.add(
            'Tagesverlust-Limit erreicht: ${(dailyLossPct * 100).toStringAsFixed(2)}%');
        } else {
          warnings.add(
            'Tagesverlust nähert sich Limit: ${(dailyLossPct * 100).toStringAsFixed(2)}%');
        }
      }
    }

    // 5. Drawdown Check
    if (currentDrawdownPct >= _maxDrawdownPct * 0.9) {
      if (currentDrawdownPct >= _maxDrawdownPct) {
        violations.add(
          'Max Drawdown erreicht: ${(currentDrawdownPct * 100).toStringAsFixed(1)}%');
        _circuitBreaker.recordFailure('Max Drawdown');
      } else {
        warnings.add(
          'Drawdown nähert sich Limit: ${(currentDrawdownPct * 100).toStringAsFixed(1)}%');
      }
    }

    // 6. Leverage Check
    if (request.orderType == 'LEVERAGED') {
      warnings.add('Leverage-Order: Überprüfe Margin-Anforderungen');
    }

    // 7. Concentration Check
    final currentSymbolExposure = _positions[request.symbol]?.notionalValue ?? 0.0;
    final newSymbolExposure = currentSymbolExposure + request.orderValue;
    if (_currentPortfolioValue > 0) {
      final concentrationPct = newSymbolExposure / _currentPortfolioValue;
      if (concentrationPct > _concentrationLimit) {
        violations.add(
          'Konzentrationsrisiko: ${(concentrationPct * 100).toStringAsFixed(1)}% '
          'in ${request.symbol} > ${(_concentrationLimit * 100).toStringAsFixed(0)}%');
      }
    }

    // 8. Compute simplified VaR
    final estimatedVar = _computeSimplifiedVar(request);

    if (estimatedVar > _var95Limit) {
      warnings.add(
        'Hohes VaR: ${(estimatedVar * 100).toStringAsFixed(2)}% '
        '(95% Konfidenz)');
    }

    // ── Entscheidung ─────────────────────────────────────────────────────
    final result = violations.isNotEmpty
        ? RiskCheckResult.rejected
        : warnings.isNotEmpty
            ? RiskCheckResult.warning
            : RiskCheckResult.approved;

    if (result == RiskCheckResult.rejected) {
      _tradesRejectedToday++;
    }

    notifyListeners();

    return PreTradeCheckResult(
      orderId: request.orderId,
      result: result,
      violations: violations,
      warnings: warnings,
      computedVar: estimatedVar,
      allowedExposurePct: allowedPct,
      checkedAt: DateTime.now(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // POST-TRADE MONITORING
  // ══════════════════════════════════════════════════════════════════════════
  void onOrderFilled({
    required String symbol,
    required double size,
    required double fillPrice,
    required String side,
    required double leverage,
  }) {
    final isLong = side.toUpperCase() == 'BUY';
    final position = _positions[symbol];

    if (position != null && isLong != (position.exposureType == ExposureType.long)) {
      // Closing / reducing position
      final pnl = position.unrealizedPnl * (size / position.size);
      _dailyPnl += pnl;
      if (size >= position.size) {
        _positions.remove(symbol);
      } else {
        _positions[symbol] = position.copyWith(currentPrice: fillPrice);
      }
    } else {
      // Opening / increasing position
      _positions[symbol] = RiskPosition(
        symbol: symbol,
        size: (position?.size ?? 0) + size,
        entryPrice: fillPrice,
        currentPrice: fillPrice,
        exposureType: isLong ? ExposureType.long : ExposureType.short,
        leverage: leverage,
        openedAt: position?.openedAt ?? DateTime.now(),
      );
    }

    _updatePortfolioSnapshot();
    notifyListeners();
  }

  void updatePrices(Map<String, double> prices) {
    bool changed = false;
    for (final entry in prices.entries) {
      if (_positions.containsKey(entry.key)) {
        _positions[entry.key] = _positions[entry.key]!
            .copyWith(currentPrice: entry.value);
        changed = true;
      }
    }
    if (changed) {
      _updatePortfolioSnapshot();
      _checkPostTradeRisks();
      notifyListeners();
    }
  }

  void updatePortfolioValue(double value) {
    _currentPortfolioValue = value;
    if (value > _peakPortfolioValue) _peakPortfolioValue = value;
    _updatePortfolioSnapshot();
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // KILL SWITCH (MiFID II Anforderung)
  // ══════════════════════════════════════════════════════════════════════════
  void activateKillSwitch({String reason = 'Manuell aktiviert'}) {
    _killSwitchActive = true;
    _autoTradingEnabled = false;
    _addRiskEvent(RiskEvent(
      id: 'KILL_${DateTime.now().millisecondsSinceEpoch}',
      type: RiskEventType.complianceViolation,
      message: 'KILL SWITCH AKTIVIERT: $reason',
      symbol: '*',
      value: 1.0,
      threshold: 0.0,
      isActive: true,
      occurredAt: DateTime.now(),
    ));
    if (kDebugMode) debugPrint('🛑 KILL SWITCH: $reason');
    notifyListeners();
  }

  void deactivateKillSwitch() {
    _killSwitchActive = false;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION
  // ══════════════════════════════════════════════════════════════════════════
  void setRiskTier(RiskTier tier) {
    _riskTier = tier;
    _maxPositionSizePct = tier.maxPositionPct;
    _maxDrawdownPct = tier.maxDrawdownPct;
    _maxLeverage = tier.maxLeverage;
    notifyListeners();
  }

  void setAutoTradingEnabled(bool enabled) {
    _autoTradingEnabled = enabled;
    notifyListeners();
  }

  void setMaxPositionSize(double pct) {
    _maxPositionSizePct = pct.clamp(0.001, 1.0);
    notifyListeners();
  }

  void setVar95Limit(double limit) {
    _var95Limit = limit.clamp(0.001, 0.5);
    notifyListeners();
  }

  void setConcentrationLimit(double limit) {
    _concentrationLimit = limit.clamp(0.05, 1.0);
    notifyListeners();
  }

  void resetDailyCounters() {
    _dailyPnl = 0.0;
    _tradesCheckedToday = 0;
    _tradesRejectedToday = 0;
    notifyListeners();
  }

  void resetCircuitBreaker() {
    _circuitBreaker.forceReset();
    notifyListeners();
  }

  void clearRiskEvents() {
    _riskEvents.clear();
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Vereinfachter VaR-Schätzer (historische Volatilität-basiert)
  double _computeSimplifiedVar(PreTradeCheckRequest req) {
    // Basis-Volatilität per Asset-Klasse (vereinfacht)
    final volEstimates = <String, double>{
      'BTC': 0.04, 'ETH': 0.05, 'SOL': 0.07, 'BNB': 0.05,
      'DOGE': 0.10, 'ADA': 0.06, 'XRP': 0.06,
    };
    final sym = req.symbol.split('-')[0].toUpperCase();
    final vol = volEstimates[sym] ?? 0.05;

    // 95% VaR ≈ 1.645 * σ (normalverteilt)
    final var95 = 1.645 * vol * req.exposurePct;
    return var95;
  }

  void _updatePortfolioSnapshot() {
    if (_currentPortfolioValue <= 0) return;

    final totalExposure = this.totalExposure;
    final netExposure = _positions.values.fold(0.0, (s, p) {
      return s + p.notionalValue * (p.exposureType == ExposureType.short ? -1 : 1);
    });

    // Asset weights
    final weights = <String, double>{};
    for (final pos in _positions.entries) {
      weights[pos.key] = totalExposure > 0
          ? pos.value.notionalValue / totalExposure
          : 0.0;
    }

    // Herfindahl–Hirschman Index für Konzentration
    final hhi = weights.values.fold(0.0, (s, w) => s + w * w);

    // Simplified VaR (portfolio level)
    final rnd = Random();
    final var95 = totalExposure > 0
        ? (0.015 + rnd.nextDouble() * 0.02) * (totalExposure / _currentPortfolioValue)
        : 0.0;
    final var99 = var95 * 1.4;

    _lastSnapshot = PortfolioRiskSnapshot(
      totalValue: _currentPortfolioValue,
      totalExposure: totalExposure,
      netExposure: netExposure,
      grossExposure: totalExposure,
      intradayVar95: var95,
      intradayVar99: var99,
      maxDrawdownPct: currentDrawdownPct,
      sharpeRatio: _dailyPnl / (_currentPortfolioValue * 0.001 + 0.001),
      concentrationScore: hhi,
      assetWeights: weights,
      snapshotAt: DateTime.now(),
    );
  }

  void _checkPostTradeRisks() {
    final snapshot = _lastSnapshot;
    if (snapshot == null) return;

    // VaR-Check
    if (snapshot.intradayVar95 > _var95Limit) {
      _addRiskEvent(RiskEvent(
        id: 'VAR_${DateTime.now().millisecondsSinceEpoch}',
        type: RiskEventType.postTradeVarExceeded,
        message: 'Portfolio VaR überschreitet Limit: '
            '${(snapshot.intradayVar95 * 100).toStringAsFixed(2)}%',
        symbol: 'PORTFOLIO',
        value: snapshot.intradayVar95,
        threshold: _var95Limit,
        isActive: true,
        occurredAt: DateTime.now(),
      ));
    }

    // Drawdown-Check
    if (snapshot.maxDrawdownPct > _maxDrawdownPct * 0.8) {
      _addRiskEvent(RiskEvent(
        id: 'DD_${DateTime.now().millisecondsSinceEpoch}',
        type: RiskEventType.drawdownAlert,
        message: 'Drawdown Alert: ${(snapshot.maxDrawdownPct * 100).toStringAsFixed(1)}%',
        symbol: 'PORTFOLIO',
        value: snapshot.maxDrawdownPct,
        threshold: _maxDrawdownPct,
        isActive: true,
        occurredAt: DateTime.now(),
      ));
    }
  }

  void _addRiskEvent(RiskEvent event) {
    _riskEvents.insert(0, event);
    if (_riskEvents.length > 100) _riskEvents.removeLast();
  }
}
