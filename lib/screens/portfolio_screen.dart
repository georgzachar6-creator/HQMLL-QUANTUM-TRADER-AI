import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/theme_provider.dart';
import '../services/exchange_service.dart';
import 'oracle_screen.dart';
import '../widgets/crypto_icon.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});
  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _chatCtrl;
  late Timer _priceTimer;
  final Random _rnd = Random(42);
  int _touchedIndex = -1;
  String _selectedPeriod = '1M';
  bool _showRebalance = false;
  bool _showEmmaChatPanel = false;
  final ScrollController _chatScroll = ScrollController();
  final TextEditingController _chatInput = TextEditingController();
  bool _emmaThinking = false;

  final List<_ChatMessage> _chatMessages = [
    _ChatMessage(
      text: 'Portfolio-Analyse bereit. Ich habe alle 6 Agenten konsultiert. '
            'Ihr Portfolio zeigt eine gesunde Diversifikation. '
            'Fragen Sie mich zu spezifischen Positionen oder Risiken.',
      isEmma: true,
      time: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  final List<_Asset> _assets = [
    _Asset('BTC',   'Bitcoin',       0.42,   67842.50, 45.2,  2.34,  true,  'BTC'),
    _Asset('ETH',   'Ethereum',      3.85,   3548.20,  28.1,  1.87,  true,  'ETH'),
    _Asset('SOL',   'Solana',        12.0,   182.40,   9.6,  -0.52,  false, 'SOL'),
    _Asset('QEMMA', 'QEMMA Token',   1284.0, 0.0847,   4.7,  12.45,  true,  'QEM'),
    _Asset('BNB',   'BNB Chain',     2.1,    598.30,   5.5,   0.94,  true,  'BNB'),
    _Asset('USDT',  'Tether',        1480.0, 1.0,      6.9,   0.01,  true,  'USDT'),
  ];

  final List<String> _periods = ['1T', '1W', '1M', '3M', '1J'];
  List<Color> _sectorColors = [];

  // Emma Antworten fur Portfolio-Chat (v33.0: live Preise via _buildEmmaResponse())
  Map<String, String> _buildEmmaResponses(ExchangeService ex) {
    final btcP = ex.getPrice('BTC'); final btcStr = _fmtChatPrice(btcP > 0 ? btcP : 67842.0);
    final ethP = ex.getPrice('ETH'); final ethStr = _fmtChatPrice(ethP > 0 ? ethP : 3548.20);
    final solP = ex.getPrice('SOL'); final solStr = _fmtChatPrice(solP > 0 ? solP : 182.40);
    final btcBuy = _fmtChatPrice((btcP > 0 ? btcP : 67842.0) * 0.943);
    final ethBuy = _fmtChatPrice((ethP > 0 ? ethP : 3548.20) * 0.945);
    final solBuy = _fmtChatPrice((solP > 0 ? solP : 182.40) * 0.933);
    return {
      'btc': 'BTC-Analyse: Preis $btcStr. RSI: 62.4 — leicht uberkauft. '
             '17-Tage-Zyklus Phase 3/4. HQMLL-Konfidenz: 82%. '
             'Empfehlung: Halten. Nachkaufen unter $btcBuy.',
      'eth': 'ETH-Analyse: Preis $ethStr. Merge-Effekt stabil. '
             'Gas-Fees niedrig — gutes Kaufsignal. RSI: 58.2. '
             'HQMLL Agenten-Konsens: 5/6 BULLISH.',
      'qemma': 'QEMMA-Analyse: +12.45% heute. Mining-Rate optimal. '
               'Tokenomics stabil: 35% Mining-Pool noch unerschlossen. '
               'Empfehlung: 15% Teilgewinnmitnahme — Rest halten fur Mining-Boost.',
      'risiko': 'Risiko-Analyse Ihres Portfolios: Score 6.2/10. '
                'Hauptrisiko: Geringe Stablecoin-Reserve (6.9% vs. Ziel 15%). '
                'Beta: 0.82. Sharpe: 1.84. Max Drawdown: -12.3%. '
                'Massnahme: USDT auf 15% erhohen.',
      'rebalancing': 'Rebalancing-Vorschlag:\n'
                     '- USDT: 6.9% -> 15% (+\$3.840)\n'
                     '- BNB: 5.5% -> 4% (-\$844)\n'
                     '- QEMMA: 4.7% -> 5% (+\$136)\n'
                     'BTC optimal. Gesamtkosten: ~\$35 Gebuehren.',
      'sol': 'SOL-Analyse: Preis $solStr. Fundamentaldaten stark. '
             'Validator-Aktivitat +12% diese Woche. '
             'HQMLL-Empfehlung: Halten. Kaufzone: unter $solBuy.',
      'performance': 'Portfolio-Performance 1M: +\$1.240 (+2.18%). '
                     'Beste Position: QEMMA +12.45%. Schlechteste: SOL -0.52%. '
                     'Gesamt-Rendite YTD: +18.7%. Benchmark BTC: +14.2%. '
                     'Alpha: +4.5% — HQMLL-optimiert.',
    };
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _chatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    // v33.0: Sofort beim ersten Frame live Preise laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ex = context.read<ExchangeService>();
      setState(() => _syncPortfolioFromExchange(ex));
    });

    // Prüfe live Preise aus ExchangeService (alle 3s aktualisieren)
    _priceTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final ex = context.read<ExchangeService>();
      setState(() {
        _syncPortfolioFromExchange(ex);
      });
    });
  }

  // v33.0: Sync _assets live prices from ExchangeService
  void _syncPortfolioFromExchange(ExchangeService ex) {
    for (final a in _assets) {
      if (a.symbol == 'USDT') continue;
      final liveFromEx = ex.getPrice(a.symbol);
      if (liveFromEx > 0) {
        a.livePrice = liveFromEx;
      } else {
        final vol = a.symbol == 'QEMMA' ? 0.007 : 0.0015;
        final delta = (_rnd.nextDouble() - 0.49) * a.livePrice * vol;
        a.livePrice = (a.livePrice + delta).clamp(a.price * 0.88, a.price * 1.12);
      }
    }
  }

  // v33.0: Formatiert Preis für Emma-Chat (67842.5 → $67,842)
  String _fmtChatPrice(double v) {
    if (v <= 0) return 'N/A';
    if (v >= 1000) {
      final s = v.toStringAsFixed(0);
      final buf = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return '\$${buf.toString()}';
    }
    if (v >= 1) return '\$${v.toStringAsFixed(2)}';
    return '\$${v.toStringAsFixed(4)}';
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _chatCtrl.dispose();
    _priceTimer.cancel();
    _chatScroll.dispose();
    _chatInput.dispose();
    super.dispose();
  }

  double get _totalValue => _assets.fold(0.0, (s, a) => s + a.liveValue);
  double get _totalChange =>
      _assets.fold(0.0, (s, a) => s + (a.livePrice - a.price) * a.amount);

  void _sendChatMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _chatMessages.add(
          _ChatMessage(text: text, isEmma: false, time: DateTime.now()));
      _emmaThinking = true;
    });
    _chatInput.clear();
    _scrollChatToBottom();

    // v33.0: Emma-Responses mit live Preisen aus ExchangeService
    final ex = context.read<ExchangeService>();
    final responses = _buildEmmaResponses(ex);
    final lower = text.toLowerCase();
    String response = 'Ich analysiere Ihre Anfrage mit allen 6 HQMLL-Agenten. '
        'Stellen Sie spezifische Fragen zu BTC, ETH, SOL, QEMMA, Risiko, '
        'Rebalancing oder Performance.';
    for (final key in responses.keys) {
      if (lower.contains(key)) {
        response = responses[key]!;
        break;
      }
    }

    Future.delayed(
        Duration(milliseconds: 800 + _rnd.nextInt(600)), () {
      if (!mounted) return;
      setState(() {
        _emmaThinking = false;
        _chatMessages.add(
            _ChatMessage(text: response, isEmma: true, time: DateTime.now()));
      });
      _scrollChatToBottom();
    });
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;

    if (_sectorColors.isEmpty) {
      _sectorColors = [
        p.primary,
        p.secondary,
        p.accent,
        p.positive,
        p.primary.withValues(alpha: 0.6),
        p.secondary.withValues(alpha: 0.5),
      ];
    }

    return Stack(
      children: [
        // Hauptinhalt
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
          child: Column(
            children: [
              _buildTotalCard(p),
              const SizedBox(height: 12),
              _buildDonutChart(p),
              const SizedBox(height: 12),
              _buildPnLCard(p),
              const SizedBox(height: 12),
              _buildEmmaAnalysisBanner(p),
              const SizedBox(height: 12),
              _buildAssetsList(p),
              const SizedBox(height: 12),
              _buildPerformanceCard(p),
              const SizedBox(height: 12),
              _buildRiskMetrics(p),
              const SizedBox(height: 12),
              _buildTaxReportCard(p),
            ],
          ),
        ),

        // Emma Live Chat Panel (Slide-in)
        if (_showEmmaChatPanel)
          _buildEmmaChatPanel(context, p),

        // Emma Chat FAB
        Positioned(
          bottom: 16,
          right: 16,
          child: _buildEmmaChatFAB(p),
        ),
      ],
    );
  }

  // ── Emma Chat FAB ──────────────────────────────
  Widget _buildEmmaChatFAB(dynamic p) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        return GestureDetector(
          onTap: () => setState(() => _showEmmaChatPanel = !_showEmmaChatPanel),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.primary, p.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: p.primary.withValues(
                      alpha: 0.3 + _pulseCtrl.value * 0.2),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              _showEmmaChatPanel
                  ? Icons.close
                  : Icons.chat_bubble_outline,
              color: p.background,
              size: 22,
            ),
          ),
        );
      },
    );
  }

  // ── Emma Chat Panel ────────────────────────────
  Widget _buildEmmaChatPanel(BuildContext context, dynamic p) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.52,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(
            top: BorderSide(color: p.primary.withValues(alpha: 0.3)),
            left: BorderSide(color: p.primary.withValues(alpha: 0.15)),
            right: BorderSide(color: p.primary.withValues(alpha: 0.15)),
          ),
          boxShadow: [
            BoxShadow(
              color: p.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Panel Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: p.primary.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: p.positive,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: p.positive.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'EMMA PORTFOLIO-ASSISTENT',
                    style: GoogleFonts.spaceMono(
                      color: p.textSecondary,
                      fontSize: 9,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Direkt zum Oracle Button
                  GestureDetector(
                    onTap: () {
                      setState(() => _showEmmaChatPanel = false);
                      // Navigation zum Oracle-Screen via MainScaffold
                      // (Index 0 = Oracle)
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OracleScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: p.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'ORACLE OFFNEN',
                        style: GoogleFonts.spaceMono(
                          color: p.primary,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showEmmaChatPanel = false),
                    child: Icon(Icons.expand_more,
                        color: p.textSecondary, size: 20),
                  ),
                ],
              ),
            ),

            // Quick Questions
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  'BTC Analyse',
                  'Risiko pruefen',
                  'Rebalancing',
                  'QEMMA Status',
                  'Performance',
                  'SOL Analyse',
                ].map((q) {
                  return GestureDetector(
                    onTap: () => _sendChatMessage(q),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.surfaceVariant,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: p.primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        q,
                        style: GoogleFonts.spaceMono(
                          color: p.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Chat Messages
            Expanded(
              child: ListView.builder(
                controller: _chatScroll,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount:
                    _chatMessages.length + (_emmaThinking ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _chatMessages.length && _emmaThinking) {
                    return _buildThinkingBubble(p);
                  }
                  final m = _chatMessages[i];
                  return _buildChatBubble(m, p);
                },
              ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: p.primary.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: p.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: p.primary.withValues(alpha: 0.2)),
                      ),
                      child: TextField(
                        controller: _chatInput,
                        style: GoogleFonts.inter(
                            color: p.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Frage an Emma...',
                          hintStyle: GoogleFonts.inter(
                              color: p.textSecondary, fontSize: 12),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: _sendChatMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendChatMessage(_chatInput.text),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [p.primary, p.secondary],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.send,
                          color: p.background, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(_ChatMessage m, dynamic p) {
    return Align(
      alignment: m.isEmma ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: m.isEmma
              ? p.primary.withValues(alpha: 0.08)
              : p.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomLeft: m.isEmma
                ? const Radius.circular(2)
                : const Radius.circular(10),
            bottomRight: m.isEmma
                ? const Radius.circular(10)
                : const Radius.circular(2),
          ),
          border: Border.all(
            color: m.isEmma
                ? p.primary.withValues(alpha: 0.2)
                : p.primary.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.isEmma)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'EMMA',
                  style: GoogleFonts.spaceMono(
                    color: p.primary,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            Text(
              m.text,
              style: GoogleFonts.inter(
                color: p.textPrimary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingBubble(dynamic p) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: p.primary.withValues(alpha: 0.06),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomRight: Radius.circular(10),
            bottomLeft: Radius.circular(2),
          ),
          border: Border.all(color: p.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Analysiere',
              style: GoogleFonts.spaceMono(
                  color: p.primary, fontSize: 10),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation(p.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Total Value Header ─────────────────────────
  Widget _buildTotalCard(dynamic p) {
    final totalChange = _totalChange;
    final pctChange = (totalChange / (_totalValue - totalChange).abs()) * 100;
    final isUp = totalChange >= 0;

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: p.primary.withValues(
                  alpha: 0.12 + _pulseCtrl.value * 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: p.primary.withValues(
                    alpha: _pulseCtrl.value * 0.04),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GESAMTPORTFOLIO',
                    style: GoogleFonts.spaceMono(
                      color: p.textSecondary,
                      fontSize: 9,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.positive.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: p.positive.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'LIVE',
                      style: GoogleFonts.spaceMono(
                        color: p.positive,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  '\$${_totalValue.toStringAsFixed(2)}',
                  key: ValueKey(_totalValue.toStringAsFixed(0)),
                  style: GoogleFonts.spaceMono(
                    color: p.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isUp ? p.positive : p.negative)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (isUp ? p.positive : p.negative)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUp
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: isUp ? p.positive : p.negative,
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${isUp ? '+' : ''}\$${totalChange.toStringAsFixed(2)} '
                      '(${pctChange.toStringAsFixed(2)}%)',
                      style: GoogleFonts.spaceMono(
                        color: isUp ? p.positive : p.negative,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Metriken
              Row(
                children: [
                  _buildMetricItem(p, 'SHARPE', '1.84', p.positive),
                  _buildMetricDivider(p),
                  _buildMetricItem(p, 'DRAWDOWN', '-12.3%', p.negative),
                  _buildMetricDivider(p),
                  _buildMetricItem(p, 'EMMA', 'B+', p.primary),
                  _buildMetricDivider(p),
                  _buildMetricItem(p, 'RISIKO', '6.2/10', p.secondary),
                ],
              ),
              const SizedBox(height: 14),
              // Rebalancing-Button
              GestureDetector(
                onTap: () =>
                    setState(() => _showRebalance = !_showRebalance),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: p.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.balance, color: p.primary, size: 13),
                      const SizedBox(width: 8),
                      Text(
                        'EMMA REBALANCING',
                        style: GoogleFonts.spaceMono(
                          color: p.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _showRebalance
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: p.primary,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showRebalance) ...[
                const SizedBox(height: 12),
                _buildRebalanceSuggestions(p),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricItem(
      dynamic p, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.spaceMono(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.spaceMono(
              color: p.textSecondary,
              fontSize: 7,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDivider(dynamic p) {
    return Container(
      width: 1,
      height: 28,
      color: p.primary.withValues(alpha: 0.12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildRebalanceSuggestions(dynamic p) {
    final suggestions = [
      ('USDT', 'Erhoehen',  '6.9% -> 15%',  '+\$3.840', true),
      ('QEMMA', 'Halten',   '4.7% -> 5%',   '+\$136',   true),
      ('BNB',  'Reduzieren','5.5% -> 4%',   '-\$844',   false),
      ('BTC',  'Optimal',   '45.2% = Ziel', '+/-\$0',   null),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REBALANCING-VORSCHLAG',
            style: GoogleFonts.spaceMono(
              color: p.textSecondary,
              fontSize: 8,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          ...suggestions.map((s) {
            final col = s.$5 == null
                ? p.textSecondary
                : s.$5!
                    ? p.positive
                    : p.negative;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(children: [
                Container(
                  width: 32,
                  height: 22,
                  decoration: BoxDecoration(
                    color: p.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: p.primary.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Text(
                      s.$1,
                      style: GoogleFonts.spaceMono(
                        color: p.primary,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${s.$2}  ${s.$3}',
                    style: GoogleFonts.inter(
                        color: p.textPrimary, fontSize: 11),
                  ),
                ),
                Text(
                  s.$4,
                  style: GoogleFonts.spaceMono(
                    color: col,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _showRebalance = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: p.surface,
                  content: Row(children: [
                    Icon(Icons.check, color: p.positive, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Rebalancing-Plan gespeichert',
                      style: GoogleFonts.inter(color: p.textPrimary),
                    ),
                  ]),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: p.positive.withValues(alpha: 0.3)),
                  ),
                  duration: const Duration(seconds: 2),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: p.background,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7)),
              ),
              child: Text(
                'PLAN UBERNEHMEN',
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Donut Chart ────────────────────────────────
  Widget _buildDonutChart(dynamic p) {
    final total = _totalValue;
    final sections = _assets.asMap().entries.map((e) {
      final isTouched = _touchedIndex == e.key;
      final pct = e.value.liveValue / total * 100;
      return PieChartSectionData(
        color: _sectorColors[e.key % _sectorColors.length],
        value: pct,
        title: isTouched
            ? '${e.value.symbol}\n${pct.toStringAsFixed(1)}%'
            : '',
        radius: isTouched ? 60 : 50,
        titleStyle: TextStyle(
            color: p.background,
            fontSize: 9,
            fontWeight: FontWeight.bold),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ALLOKATION',
                style: GoogleFonts.spaceMono(
                  color: p.textSecondary,
                  fontSize: 9,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                '${_assets.length} Positionen',
                style: GoogleFonts.inter(
                    color: p.textSecondary, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(PieChartData(
                  sections: sections,
                  centerSpaceRadius: 34,
                  pieTouchData: PieTouchData(touchCallback: (_, res) {
                    setState(() => _touchedIndex =
                        res?.touchedSection?.touchedSectionIndex ??
                            -1);
                  }),
                  sectionsSpace: 2,
                )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: _assets.asMap().entries.map((e) {
                    final pct = e.value.liveValue / total * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _sectorColors[
                                e.key % _sectorColors.length],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          e.value.symbol,
                          style: GoogleFonts.spaceMono(
                            color: p.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${pct.toStringAsFixed(1)}%',
                              style: GoogleFonts.spaceMono(
                                color: _sectorColors[
                                    e.key % _sectorColors.length],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${e.value.liveValue.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                  color: p.textSecondary,
                                  fontSize: 9),
                            ),
                          ],
                        ),
                      ]),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Emma Analysis Banner ───────────────────────
  Widget _buildEmmaAnalysisBanner(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient:
                      LinearGradient(colors: [p.primary, p.secondary]),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(Icons.remove_red_eye,
                    color: p.background, size: 15),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EMMA PORTFOLIO-ANALYSE',
                    style: GoogleFonts.spaceMono(
                      color: p.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '6 Agenten aktiv',
                    style: GoogleFonts.inter(
                        color: p.textSecondary, fontSize: 9),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    setState(() => _showEmmaChatPanel = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        p.primary.withValues(alpha: 0.15),
                        p.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: p.primary.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          color: p.primary, size: 12),
                      const SizedBox(width: 5),
                      Text(
                        'CHAT',
                        style: GoogleFonts.spaceMono(
                          color: p.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'USDT-Reserve (${_assets.last.allocation.toStringAsFixed(1)}%) '
            'zu niedrig — Ziel 15%. BTC-Allokation optimal. '
            'QEMMA +12.45% — Teilgewinnmitnahme pruefen. '
            'Gesamtwert: \$${_totalValue.toStringAsFixed(2)}.',
            style: GoogleFonts.inter(
              color: p.textPrimary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // Konfidenz-Leisten
          ..._assets.take(4).map((a) {
            final conf = 65 + _rnd.nextInt(25);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                SizedBox(
                  width: 46,
                  child: Text(
                    a.symbol,
                    style: GoogleFonts.spaceMono(
                        color: p.textSecondary,
                        fontSize: 9),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: conf / 100.0,
                      minHeight: 4,
                      backgroundColor:
                          p.negative.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(
                          a.isPositive ? p.positive : p.negative),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: Text(
                    '$conf%',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.spaceMono(
                      color: a.isPositive ? p.positive : p.negative,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  // ── Assets Liste ───────────────────────────────
  Widget _buildAssetsList(dynamic p) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Text(
                'POSITIONEN',
                style: GoogleFonts.spaceMono(
                  color: p.textSecondary,
                  fontSize: 9,
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              Text(
                '${_assets.length} Assets',
                style: GoogleFonts.inter(
                    color: p.textSecondary, fontSize: 10),
              ),
            ]),
          ),
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const SizedBox(width: 42),
                Expanded(
                  child: Text(
                    'Asset',
                    style: GoogleFonts.spaceMono(
                        color: p.textSecondary,
                        fontSize: 8,
                        letterSpacing: 0.5),
                  ),
                ),
                Text(
                  'Wert',
                  style: GoogleFonts.spaceMono(
                      color: p.textSecondary,
                      fontSize: 8,
                      letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          Container(height: 1, color: p.primary.withValues(alpha: 0.08)),
          ..._assets.map((a) => _buildAssetRow(p, a)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildAssetRow(dynamic p, _Asset a) {
    final isUp = a.livePrice >= a.price;
    final priceChange = ((a.livePrice - a.price) / a.price * 100);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: p.primary.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          CryptoIcon(a.symbol, size: 40, showShadow: false),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.symbol,
                  style: GoogleFonts.spaceMono(
                    color: p.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${a.amount.toStringAsFixed(a.symbol == 'USDT' ? 0 : 4)} ${a.symbol}',
                  style: GoogleFonts.inter(
                      color: p.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Text(
                  '\$${a.liveValue.toStringAsFixed(2)}',
                  key: ValueKey(a.liveValue.toStringAsFixed(1)),
                  style: GoogleFonts.spaceMono(
                    color: p.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${isUp ? '+' : ''}${priceChange.toStringAsFixed(2)}%',
                style: GoogleFonts.spaceMono(
                  color: isUp ? p.positive : p.negative,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Performance Chart ──────────────────────────
  Widget _buildPerformanceCard(dynamic p) {
    final seedMap = {'1T': 1, '1W': 2, '1M': 3, '3M': 4, '1J': 5};
    final rnd2 =
        Random(seedMap[_selectedPeriod] ?? 3);
    final count = {'1T': 24, '1W': 7, '1M': 30, '3M': 90, '1J': 52}[_selectedPeriod] ?? 30;
    double base = 44000;
    final spots = List.generate(count, (i) {
      base += (rnd2.nextDouble() - 0.46) * 600;
      return FlSpot(i.toDouble(), base.clamp(30000, 65000));
    });
    final isUp = spots.last.y >= spots.first.y;
    final gain = spots.last.y - spots.first.y;
    final gainPct = gain / spots.first.y * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              'PERFORMANCE',
              style: GoogleFonts.spaceMono(
                color: p.textSecondary,
                fontSize: 9,
                letterSpacing: 2.0,
              ),
            ),
            const Spacer(),
            Row(
              children: _periods.map((pd) {
                final sel = _selectedPeriod == pd;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = pd),
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? p.primary : p.surfaceVariant,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: sel
                            ? p.primary
                            : p.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      pd,
                      style: GoogleFonts.spaceMono(
                        color: sel ? p.background : p.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Text(
              '${isUp ? '+' : ''}\$${gain.toStringAsFixed(0)} (${gainPct.toStringAsFixed(1)}%)',
              style: GoogleFonts.spaceMono(
                color: isUp ? p.positive : p.negative,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _selectedPeriod,
              style: GoogleFonts.inter(
                  color: p.textSecondary, fontSize: 10),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: p.primary.withValues(alpha: 0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: isUp ? p.positive : p.negative,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (isUp ? p.positive : p.negative)
                            .withValues(alpha: 0.2),
                        (isUp ? p.positive : p.negative)
                            .withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  // ── Risikometriken ─────────────────────────────
  Widget _buildRiskMetrics(dynamic p) {
    final metrics = [
      ('Beta (vs BTC)',      '0.82',  p.primary,   0.82),
      ('Sharpe Ratio',       '1.84',  p.positive,  0.614),
      ('Volatilitat 30T',    '18.4%', p.secondary, 0.46),
      ('Korr. BTC/ETH',      '0.87',  p.accent,    0.87),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              'RISIKOMETRIKEN',
              style: GoogleFonts.spaceMono(
                color: p.textSecondary,
                fontSize: 9,
                letterSpacing: 2.0,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: p.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: p.secondary.withValues(alpha: 0.25)),
              ),
              child: Text(
                'RISK SENTINEL',
                style: GoogleFonts.spaceMono(
                  color: p.secondary,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          ...metrics.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          m.$1,
                          style: GoogleFonts.inter(
                            color: p.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          m.$2,
                          style: GoogleFonts.spaceMono(
                            color: m.$3,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: m.$4,
                        minHeight: 3,
                        backgroundColor: p.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation(m.$3),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── P&L Dashboard ──────────────────────────────
  Widget _buildPnLCard(dynamic p) {
    final pnlData = [
      const _PnLEntry('BTC',  '+\$3.284,20', '+8.4%',  true,  0xFFF7931A),
      const _PnLEntry('ETH',  '+\$1.847,50', '+6.2%',  true,  0xFF627EEA),
      const _PnLEntry('QEMMA','+\$94,30',    '+12.4%', true,  0xFF00FFB2),
      const _PnLEntry('SOL',  '-\$124,80',   '-3.1%',  false, 0xFF9945FF),
      const _PnLEntry('BNB',  '+\$312,40',   '+5.7%',  true,  0xFFF3BA2F),
      const _PnLEntry('ADA',  '-\$48,20',    '-2.3%',  false, 0xFF0033AD),
    ];
    const totalPnL = '+\$5.365,40';
    const totalPct = '+11.2%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.positive.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.positive.withValues(alpha: 0.12),
                border: Border.all(color: p.positive.withValues(alpha: 0.4)),
              ),
              child: Icon(Icons.trending_up, color: p.positive, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('P&L ÜBERSICHT', style: GoogleFonts.rajdhani(
                  color: p.positive, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              Text('Unrealisierte Gewinne & Verluste', style: GoogleFonts.spaceMono(
                  color: p.textSecondary, fontSize: 9)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(totalPnL, style: GoogleFonts.rajdhani(
                  color: p.positive, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(totalPct, style: GoogleFonts.spaceMono(
                  color: p.positive, fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
          ]),
          const SizedBox(height: 14),
          // P&L Zeilen
          ...pnlData.map((entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: (entry.positive ? p.positive : p.negative).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (entry.positive ? p.positive : p.negative).withValues(alpha: 0.15),
              ),
            ),
            child: Row(children: [
              Container(width: 30, height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(entry.color).withValues(alpha: 0.15),
                  border: Border.all(color: Color(entry.color).withValues(alpha: 0.4)),
                ),
                child: Center(child: Text(
                  entry.symbol.substring(0, entry.symbol.length > 3 ? 3 : entry.symbol.length),
                  style: GoogleFonts.spaceMono(color: Color(entry.color), fontSize: 7, fontWeight: FontWeight.bold),
                )),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(entry.symbol, style: GoogleFonts.rajdhani(
                  color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold))),
              Text(entry.pnlAbs, style: GoogleFonts.rajdhani(
                  color: entry.positive ? p.positive : p.negative,
                  fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (entry.positive ? p.positive : p.negative).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(entry.pnlPct, style: GoogleFonts.spaceMono(
                    color: entry.positive ? p.positive : p.negative,
                    fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ]),
          )),
        ],
      ),
    );
  }

  // ── Steuer-Report ──────────────────────────────
  Widget _buildTaxReportCard(dynamic p) {
    bool generating = false;
    return StatefulBuilder(
      builder: (ctx, setSt) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.primary.withValues(alpha: 0.1),
                  border: Border.all(color: p.primary.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.receipt_long_outlined, color: p.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('STEUER-REPORT', style: GoogleFonts.rajdhani(
                    color: p.primary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                Text('Crypto-Steuerübersicht 2025/2026', style: GoogleFonts.spaceMono(
                    color: p.textSecondary, fontSize: 9)),
              ])),
            ]),
            const SizedBox(height: 14),
            // Steuer-Metriken
            Row(children: [
              Expanded(child: _TaxMetric('Realisierte Gewinne', '+\$8.240', p.positive, p)),
              const SizedBox(width: 10),
              Expanded(child: _TaxMetric('Realisierte Verluste', '-\$1.380', p.negative, p)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _TaxMetric('Steuerpflichtiger Gewinn', '+\$6.860', p.accent, p)),
              const SizedBox(width: 10),
              Expanded(child: _TaxMetric('Haltefrist > 1 Jahr', '\$4.200 steuerfrei', p.positive, p)),
            ]),
            const SizedBox(height: 14),
            // Export-Buttons
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.primary.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXPORT FORMATE', style: GoogleFonts.spaceMono(
                      color: p.textSecondary, fontSize: 8, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _ExportButton(
                      icon: Icons.table_chart_outlined, label: 'CSV Export',
                      sublabel: 'Alle Trades', color: p.positive, p: p,
                      onTap: () async {
                        setSt(() => generating = true);
                        await Future.delayed(const Duration(milliseconds: 1500));
                        setSt(() => generating = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          backgroundColor: p.positive.withValues(alpha: 0.9),
                          content: Text('CSV exportiert: quantum_trades_2025.csv',
                              style: TextStyle(color: p.background)),
                          duration: const Duration(seconds: 3),
                        ));
                        }
                      },
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _ExportButton(
                      icon: Icons.picture_as_pdf_outlined, label: 'PDF Report',
                      sublabel: 'Steuerbericht', color: p.negative, p: p,
                      onTap: () async {
                        setSt(() => generating = true);
                        await Future.delayed(const Duration(milliseconds: 1500));
                        setSt(() => generating = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          backgroundColor: p.primary.withValues(alpha: 0.9),
                          content: Text('PDF generiert: steuer_report_2025.pdf',
                              style: TextStyle(color: p.background)),
                          duration: const Duration(seconds: 3),
                        ));
                        }
                      },
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _ExportButton(
                      icon: Icons.code_outlined, label: 'API Export',
                      sublabel: 'JSON Format', color: p.accent, p: p,
                      onTap: () => ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        backgroundColor: p.accent.withValues(alpha: 0.9),
                        content: Text('API-Export: Webhook konfiguriert.',
                            style: TextStyle(color: p.background)),
                        duration: const Duration(seconds: 2),
                      )),
                    )),
                  ]),
                  if (generating) ...[
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: p.primary)),
                      const SizedBox(width: 8),
                      Text('Generiere Report...', style: GoogleFonts.spaceMono(
                          color: p.textSecondary, fontSize: 9)),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.info_outline, color: p.textSecondary, size: 12),
              const SizedBox(width: 6),
              Expanded(child: Text(
                'Nicht als Steuerberatung zu verstehen. Konsultieren Sie einen Steuerberater.',
                style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8),
              )),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Data Classes ──────────────────────────────────
class _Asset {
  final String symbol, name, icon;
  final double amount, price, allocation, change;
  final bool isPositive;
  double livePrice;

  _Asset(this.symbol, this.name, this.amount, this.price, this.allocation,
      this.change, this.isPositive, this.icon)
      : livePrice = price;

  double get liveValue => amount * livePrice;
}

class _ChatMessage {
  final String text;
  final bool isEmma;
  final DateTime time;
  const _ChatMessage(
      {required this.text, required this.isEmma, required this.time});
}

// ── P&L + Tax Helper Classes ──────────────────────
class _PnLEntry {
  final String symbol, pnlAbs, pnlPct;
  final bool positive;
  final int color;
  const _PnLEntry(this.symbol, this.pnlAbs, this.pnlPct, this.positive, this.color);
}

class _TaxMetric extends StatelessWidget {
  final String label, value;
  final Color color;
  final dynamic p;
  const _TaxMetric(this.label, this.value, this.color, this.p);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.rajdhani(
            color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final Color color;
  final dynamic p;
  final VoidCallback onTap;
  const _ExportButton({
    required this.icon, required this.label, required this.sublabel,
    required this.color, required this.p, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.rajdhani(
              color: color, fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          Text(sublabel, style: GoogleFonts.spaceMono(
              color: p.textSecondary, fontSize: 7),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
