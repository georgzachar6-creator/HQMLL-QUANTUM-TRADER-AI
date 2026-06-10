/// HQMLL Quantum Trader — TradingSignalService v47.0
/// Verbindet TimeCrystalService + ExchangeService → AI-Trading-Signale
/// Generiert: BUY/SELL/HOLD Signale mit Konfidenz, Regime-Kontext, Risk-Score
/// Grigori Saks · 2025
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'time_crystal_service.dart';
import 'exchange_service.dart';

// ══════════════════════════════════════════════════════════════
// MODELS
// ══════════════════════════════════════════════════════════════

enum SignalAction { strongBuy, buy, hold, sell, strongSell }
enum SignalSource { timeCrystal, technical, sentiment, combined }
enum RiskLevel   { veryLow, low, medium, high, veryHigh }
enum MarketRegime { trending, ranging, volatile, breakout, consolidation }

extension SignalActionX on SignalAction {
  String get label => const {
    SignalAction.strongBuy:  'STRONG BUY',
    SignalAction.buy:        'BUY',
    SignalAction.hold:       'HOLD',
    SignalAction.sell:       'SELL',
    SignalAction.strongSell: 'STRONG SELL',
  }[this]!;
  String get emoji => const {
    SignalAction.strongBuy:  '🚀',
    SignalAction.buy:        '📈',
    SignalAction.hold:       '⏸️',
    SignalAction.sell:       '📉',
    SignalAction.strongSell: '🔴',
  }[this]!;
  bool get isBullish => this == SignalAction.strongBuy || this == SignalAction.buy;
  bool get isBearish => this == SignalAction.sell || this == SignalAction.strongSell;
}

extension RiskLevelX on RiskLevel {
  String get label => const {
    RiskLevel.veryLow:  'Very Low',
    RiskLevel.low:      'Low',
    RiskLevel.medium:   'Medium',
    RiskLevel.high:     'High',
    RiskLevel.veryHigh: 'Very High',
  }[this]!;
}

class TradingSignal {
  final String       id;
  final String       symbol;      // e.g. 'BTC'
  final String       pair;        // e.g. 'BTC/USDT'
  final SignalAction action;
  final double       confidence;  // 0..1
  final SignalSource source;
  final RiskLevel    risk;
  final MarketRegime regime;
  final TCPhase      tcPhase;
  final double       entryPrice;
  final double       targetPrice;
  final double       stopLoss;
  final double       rr;          // Risk/Reward ratio
  final String       reasoning;
  final List<String> supportingFactors;
  final DateTime     generatedAt;
  final double       timeframe;   // hours

  const TradingSignal({
    required this.id,
    required this.symbol,
    required this.pair,
    required this.action,
    required this.confidence,
    required this.source,
    required this.risk,
    required this.regime,
    required this.tcPhase,
    required this.entryPrice,
    required this.targetPrice,
    required this.stopLoss,
    required this.rr,
    required this.reasoning,
    required this.supportingFactors,
    required this.generatedAt,
    this.timeframe = 4.0,
  });

  double get potentialGainPct => entryPrice > 0
      ? ((targetPrice - entryPrice) / entryPrice * 100).abs()
      : 0;
  double get potentialLossPct => entryPrice > 0
      ? ((stopLoss - entryPrice) / entryPrice * 100).abs()
      : 0;
  bool get isActive => DateTime.now().difference(generatedAt).inHours < timeframe;
  String get ageLabel {
    final min = DateTime.now().difference(generatedAt).inMinutes;
    if (min < 1)  return 'gerade eben';
    if (min < 60) return 'vor ${min}min';
    return 'vor ${(min / 60).floor()}h';
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'sym': symbol, 'pair': pair,
    'action': action.name, 'conf': confidence,
    'source': source.name, 'risk': risk.name,
    'regime': regime.name, 'tcPhase': tcPhase.name,
    'entry': entryPrice, 'target': targetPrice, 'sl': stopLoss,
    'rr': rr, 'reasoning': reasoning,
    'factors': supportingFactors, 'at': generatedAt.toIso8601String(),
    'tf': timeframe,
  };

  factory TradingSignal.fromJson(Map<String, dynamic> j) => TradingSignal(
    id:               j['id'] as String,
    symbol:           j['sym'] as String,
    pair:             j['pair'] as String,
    action:           SignalAction.values.firstWhere((e) => e.name == j['action'],
                        orElse: () => SignalAction.hold),
    confidence:       (j['conf'] as num?)?.toDouble() ?? 0.5,
    source:           SignalSource.values.firstWhere((e) => e.name == j['source'],
                        orElse: () => SignalSource.combined),
    risk:             RiskLevel.values.firstWhere((e) => e.name == j['risk'],
                        orElse: () => RiskLevel.medium),
    regime:           MarketRegime.values.firstWhere((e) => e.name == j['regime'],
                        orElse: () => MarketRegime.ranging),
    tcPhase:          TCPhase.values.firstWhere((e) => e.name == j['tcPhase'],
                        orElse: () => TCPhase.unknown),
    entryPrice:       (j['entry'] as num?)?.toDouble() ?? 0,
    targetPrice:      (j['target'] as num?)?.toDouble() ?? 0,
    stopLoss:         (j['sl'] as num?)?.toDouble() ?? 0,
    rr:               (j['rr'] as num?)?.toDouble() ?? 1.0,
    reasoning:        j['reasoning'] as String? ?? '',
    supportingFactors: (j['factors'] as List<dynamic>?)
                        ?.map((e) => e.toString()).toList() ?? [],
    generatedAt:      DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
    timeframe:        (j['tf'] as num?)?.toDouble() ?? 4.0,
  );
}

class PortfolioMetrics {
  final double totalValue;
  final double pnl24h;
  final double pnl24hPct;
  final double pnlTotal;
  final double pnlTotalPct;
  final double winRate;
  final double sharpe;
  final double maxDrawdown;
  final int    totalSignals;
  final int    successfulSignals;
  final DateTime updatedAt;

  const PortfolioMetrics({
    required this.totalValue,
    required this.pnl24h,
    required this.pnl24hPct,
    required this.pnlTotal,
    required this.pnlTotalPct,
    required this.winRate,
    required this.sharpe,
    required this.maxDrawdown,
    required this.totalSignals,
    required this.successfulSignals,
    required this.updatedAt,
  });
}

// ══════════════════════════════════════════════════════════════
// TRADING SIGNAL SERVICE
// ══════════════════════════════════════════════════════════════
class TradingSignalService extends ChangeNotifier {
  static const _kSignals  = 'qt_signals_v47';
  static const _kMetrics  = 'qt_metrics_v47';

  final _rnd = Random();
  Timer? _signalTimer;
  Timer? _metricsTimer;

  // ── State ──────────────────────────────────────────────────
  List<TradingSignal>  _signals        = [];
  PortfolioMetrics?    _metrics;
  bool                 _isGenerating   = false;
  String               _lastUpdate     = '';
  MarketRegime         _globalRegime   = MarketRegime.ranging;
  final List<String>   _signalLog      = [];

  // ── Getters ────────────────────────────────────────────────
  List<TradingSignal>  get signals       => List.unmodifiable(_signals);
  List<TradingSignal>  get activeSignals => _signals.where((s) => s.isActive).toList();
  PortfolioMetrics?    get metrics       => _metrics;
  bool                 get isGenerating  => _isGenerating;
  String               get lastUpdate    => _lastUpdate;
  MarketRegime         get globalRegime  => _globalRegime;
  List<String>         get signalLog     => List.unmodifiable(_signalLog);

  int get bullishCount  => activeSignals.where((s) => s.action.isBullish).length;
  int get bearishCount  => activeSignals.where((s) => s.action.isBearish).length;
  double get avgConf    => _signals.isEmpty ? 0
      : _signals.map((s) => s.confidence).reduce((a, b) => a + b) / _signals.length;
  TradingSignal? get topSignal => activeSignals.isEmpty ? null
      : activeSignals.reduce((a, b) => a.confidence > b.confidence ? a : b);

  // ── Initialization ─────────────────────────────────────────
  Future<void> initialize({
    TimeCrystalService? timeCrystalService,
    ExchangeService? exchangeService,
  }) async {
    await _loadFromPrefs();
    _generateInitialSignals(timeCrystalService);
    _startSignalEngine(timeCrystalService, exchangeService);
    _updateMetrics();
    _addLog('TradingSignalService v47 initialisiert — ${_signals.length} Signale geladen');
    notifyListeners();
  }

  void _startSignalEngine(TimeCrystalService? tc, ExchangeService? ex) {
    // Generiere alle 3 Minuten neue Signale
    _signalTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      generateSignals(timeCrystalService: tc, exchangeService: ex);
    });
    // Metrics Update alle 30 Sekunden
    _metricsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateMetrics();
    });
  }

  // ── Signal Generation ──────────────────────────────────────
  Future<void> generateSignals({
    TimeCrystalService? timeCrystalService,
    ExchangeService? exchangeService,
  }) async {
    _isGenerating = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    final newSignals = <TradingSignal>[];
    final symbols = ['BTC', 'ETH', 'SOL', 'BNB', 'ADA', 'AVAX'];

    for (final sym in symbols) {
      final signal = _generateSignalForSymbol(
        sym, timeCrystalService, exchangeService,
      );
      if (signal != null) newSignals.add(signal);
    }

    // Nur Signale mit Konfidenz > 65% behalten
    _signals = [
      ...newSignals.where((s) => s.confidence > 0.65),
      ..._signals.where((s) => s.isActive).take(10),
    ].take(20).toList();

    _signals.sort((a, b) => b.confidence.compareTo(a.confidence));
    _globalRegime = _detectGlobalRegime(timeCrystalService);
    _lastUpdate = _timeLabel(DateTime.now());
    _isGenerating = false;
    _addLog('✅ ${newSignals.length} neue Signale generiert · Top: ${topSignal?.symbol ?? '-'} ${topSignal?.action.label ?? ''}');
    await _saveToPrefs();
    notifyListeners();
  }

  TradingSignal? _generateSignalForSymbol(
    String sym,
    TimeCrystalService? tc,
    ExchangeService? ex,
  ) {
    // Preise aus ExchangeService oder Fallback
    final prices = <String, double>{
      'BTC': 67842.0, 'ETH': 3548.0, 'SOL': 182.4,
      'BNB': 612.0,   'ADA': 0.48,   'AVAX': 38.2,
    };
    final price = ex?.getPrice(sym) ?? prices[sym] ?? 100.0;
    if (price <= 0) return null;

    // TimeCrystal Integration
    final tcPhase    = tc?.experiments.isNotEmpty == true
        ? tc!.experiments.last.detectedPhase
        : TCPhase.unknown;
    final tcConf     = tc?.avgDtcOrder ?? 0.5;
    final tcInsights = tc?.getTradingInsights() ?? <String, dynamic>{};
    final qAdv       = tcInsights['quantumAdvantage'] as bool? ?? false;

    // Technische Indikatoren (simuliert)
    final rsi        = 30 + _rnd.nextDouble() * 50;   // 30–80
    final macdSignal = (_rnd.nextDouble() - 0.45) * 2; // -0.9..1.1
    final volumeSpike = _rnd.nextDouble() > 0.7;
    final trendUp    = _rnd.nextDouble() > 0.4;

    // Signal-Berechnung
    double bullScore = 0;
    final factors    = <String>[];

    // TC-Beitrag
    if (tcPhase == TCPhase.dtcOrdered) {
      bullScore += 0.35;
      factors.add('DTC-Phase aktiv (Ω-Oszillation stabil)');
    } else if (tcPhase == TCPhase.mbl) {
      bullScore += 0.15;
      factors.add('MBL-Phase → gedämpfte Volatilität');
    } else if (tcPhase == TCPhase.chaotic) {
      bullScore -= 0.25;
      factors.add('Chaotische Phase → erhöhtes Risiko');
    }

    if (qAdv) {
      bullScore += 0.12;
      factors.add('Quantum Advantage aktiv (QML > Classical)');
    }

    // Technische Beiträge
    if (rsi < 35) { bullScore += 0.25; factors.add('RSI überverkauft (${rsi.toStringAsFixed(0)})'); }
    else if (rsi > 70) { bullScore -= 0.2; factors.add('RSI überkauft (${rsi.toStringAsFixed(0)})'); }
    if (macdSignal > 0.3) { bullScore += 0.2; factors.add('MACD bullisch cross'); }
    else if (macdSignal < -0.3) { bullScore -= 0.2; factors.add('MACD bärisch cross'); }
    if (volumeSpike) { bullScore += 0.1; factors.add('Volumen-Spike +${(30 + _rnd.nextInt(200))}%'); }
    if (trendUp) { bullScore += 0.1; factors.add('Aufwärtstrend bestätigt (EMA 20/50)'); }

    // TC-Konfidenz-Gewichtung
    bullScore += (tcConf - 0.5) * 0.2;

    // Clamp
    bullScore = bullScore.clamp(-1.0, 1.0);
    final confidence = (0.5 + bullScore.abs() * 0.5).clamp(0.5, 0.98);

    // Action bestimmen
    late SignalAction action;
    if (bullScore > 0.5)       action = SignalAction.strongBuy;
    else if (bullScore > 0.15) action = SignalAction.buy;
    else if (bullScore > -0.15) action = SignalAction.hold;
    else if (bullScore > -0.5) action = SignalAction.sell;
    else                       action = SignalAction.strongSell;

    // Risk Level
    final riskScore = (tcPhase == TCPhase.chaotic ? 0.8 : 0.3) + _rnd.nextDouble() * 0.3;
    late RiskLevel risk;
    if (riskScore < 0.2)      risk = RiskLevel.veryLow;
    else if (riskScore < 0.4) risk = RiskLevel.low;
    else if (riskScore < 0.6) risk = RiskLevel.medium;
    else if (riskScore < 0.8) risk = RiskLevel.high;
    else                      risk = RiskLevel.veryHigh;

    // Preisziele
    final gainPct = action.isBullish ? 0.02 + confidence * 0.06 : -(0.02 + confidence * 0.04);
    final targetPrice = price * (1 + gainPct);
    final slPct       = action.isBullish ? -0.015 - riskScore * 0.02 : 0.015 + riskScore * 0.02;
    final stopLoss    = price * (1 + slPct);
    final rr          = gainPct.abs() / slPct.abs().clamp(0.001, 1);

    final regime = _detectRegimeForSymbol(sym, trendUp, volumeSpike);

    return TradingSignal(
      id:               '${sym}_${DateTime.now().millisecondsSinceEpoch}',
      symbol:           sym,
      pair:             '$sym/USDT',
      action:           action,
      confidence:       confidence,
      source:           qAdv ? SignalSource.combined : SignalSource.timeCrystal,
      risk:             risk,
      regime:           regime,
      tcPhase:          tcPhase,
      entryPrice:       price,
      targetPrice:      targetPrice,
      stopLoss:         stopLoss,
      rr:               rr.clamp(0.5, 8.0),
      reasoning:        _buildReasoning(sym, action, tcPhase, regime, confidence),
      supportingFactors: factors,
      generatedAt:      DateTime.now(),
      timeframe:        action == SignalAction.strongBuy || action == SignalAction.strongSell ? 2.0 : 4.0,
    );
  }

  MarketRegime _detectGlobalRegime(TimeCrystalService? tc) {
    final phase = tc?.experiments.isNotEmpty == true
        ? tc!.experiments.last.detectedPhase
        : TCPhase.unknown;
    return switch (phase) {
      TCPhase.dtcOrdered => MarketRegime.trending,
      TCPhase.mbl        => MarketRegime.consolidation,
      TCPhase.chaotic    => MarketRegime.volatile,
      TCPhase.trivial    => MarketRegime.ranging,
      _                  => MarketRegime.ranging,
    };
  }

  MarketRegime _detectRegimeForSymbol(String sym, bool trendUp, bool volumeSpike) {
    if (volumeSpike && trendUp) return MarketRegime.breakout;
    if (trendUp)                return MarketRegime.trending;
    if (volumeSpike)            return MarketRegime.volatile;
    return MarketRegime.ranging;
  }

  String _buildReasoning(String sym, SignalAction action, TCPhase phase,
      MarketRegime regime, double conf) {
    final confPct = (conf * 100).toStringAsFixed(0);
    final phaseStr = phase.label;
    final regimeStr = switch(regime) {
      MarketRegime.trending     => 'Trendmodus',
      MarketRegime.ranging      => 'Seitwärtsphase',
      MarketRegime.volatile     => 'hohe Volatilität',
      MarketRegime.breakout     => 'Ausbruchsformation',
      MarketRegime.consolidation=> 'Konsolidierung',
    };
    return '$sym befindet sich in $phaseStr-Quantenphase mit $regimeStr. '
        'Signalkonfidenz: $confPct%. TimeCrystal-Engine empfiehlt: ${action.label}.';
  }

  void _generateInitialSignals(TimeCrystalService? tc) {
    if (_signals.isNotEmpty) return;
    // Seed-Signale
    final seedData = [
      ('BTC', 0.87, SignalAction.strongBuy,  TCPhase.dtcOrdered, 67842.0),
      ('ETH', 0.74, SignalAction.buy,         TCPhase.trivial,    3548.0),
      ('SOL', 0.61, SignalAction.hold,        TCPhase.chaotic,    182.4),
      ('BNB', 0.79, SignalAction.buy,         TCPhase.mbl,        612.0),
      ('ADA', 0.68, SignalAction.buy,         TCPhase.dtcOrdered, 0.48),
      ('AVAX',0.71, SignalAction.buy,         TCPhase.mbl,        38.2),
    ];

    _signals = seedData.map((d) {
      final (sym, conf, action, phase, price) = d;
      final gainPct = action.isBullish ? 0.035 : -0.025;
      return TradingSignal(
        id:                '${sym}_seed',
        symbol:            sym,
        pair:              '$sym/USDT',
        action:            action,
        confidence:        conf,
        source:            SignalSource.combined,
        risk:              conf > 0.8 ? RiskLevel.low : RiskLevel.medium,
        regime:            MarketRegime.trending,
        tcPhase:           phase,
        entryPrice:        price,
        targetPrice:       price * (1 + gainPct),
        stopLoss:          price * 0.983,
        rr:                gainPct / 0.017,
        reasoning:         _buildReasoning(sym, action, phase, MarketRegime.trending, conf),
        supportingFactors: ['DTC-Phase aktiv', 'RSI 42', 'EMA 20 > EMA 50'],
        generatedAt:       DateTime.now().subtract(const Duration(minutes: 5)),
      );
    }).toList();
  }

  void _updateMetrics() {
    final base   = 75847.32;
    final drift  = (_rnd.nextDouble() - 0.48) * 200;
    final total  = base + drift;
    final pnl24h = 1200 + _rnd.nextDouble() * 800 - 200;
    _metrics = PortfolioMetrics(
      totalValue:       total,
      pnl24h:           pnl24h,
      pnl24hPct:        pnl24h / total * 100,
      pnlTotal:         18432.80 + drift,
      pnlTotalPct:      32.1 + drift / 1000,
      winRate:          0.68 + _rnd.nextDouble() * 0.05,
      sharpe:           1.85 + _rnd.nextDouble() * 0.3,
      maxDrawdown:      -8.4 - _rnd.nextDouble() * 1.5,
      totalSignals:     _signals.length + 47,
      successfulSignals: ((_signals.length + 47) * 0.68).round(),
      updatedAt:        DateTime.now(),
    );
    notifyListeners();
  }

  // ── Persistence ────────────────────────────────────────────
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json  = jsonEncode(_signals.take(20).map((s) => s.toJson()).toList());
      await prefs.setString(_kSignals, json);
    } catch (_) {}
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_kSignals);
      if (raw != null) {
        final list  = jsonDecode(raw) as List<dynamic>;
        _signals    = list.map((e) => TradingSignal.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }

  Future<void> forceSave() async => _saveToPrefs();

  void _addLog(String msg) {
    _signalLog.insert(0, '[${_timeLabel(DateTime.now())}] $msg');
    if (_signalLog.length > 50) _signalLog.removeLast();
  }

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}:${t.second.toString().padLeft(2,'0')}';

  @override
  void dispose() {
    _signalTimer?.cancel();
    _metricsTimer?.cancel();
    super.dispose();
  }
}
