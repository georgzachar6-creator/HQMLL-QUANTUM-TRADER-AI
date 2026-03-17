import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../widgets/quantum_eye_widget.dart';

class OracleScreen extends StatefulWidget {
  const OracleScreen({super.key});
  @override
  State<OracleScreen> createState() => _OracleScreenState();
}

class _OracleScreenState extends State<OracleScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late AnimationController _waveCtrl;
  late AnimationController _signalPulse;
  bool _isThinking = false;
  int _oracleTab = 0; // 0=Chat, 1=Signale

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: 'Willkommen, Grigori Saks. Ich bin Emma – Ihr Quantum Oracle AI Assistent.\n\nDas HQMLL Meta-Team ist aktiv. Alle 6 Agenten sind online.\n\nWie kann ich Ihnen heute helfen?',
      isEmma: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  final List<String> _quickQuestions = [
    'BTC Resonanz-Analyse',
    'ETH Analyse',
    'QEMMA Token Analyse',
    'Portfolio-Risiko prüfen',
    'QEMMA Mining Status',
    'Markt-Sentiment heute',
    'Top Signale anzeigen',
    'Agenten-Status',
    'HQMLL System',
    'Risikomanagement',
  ];

  static const List<_EmmaResponse> _responses = [
    _EmmaResponse(
      trigger: 'btc',
      text: '🔮 BTC Quantum-Resonanz-Analyse:\n\n📊 Dominante Frequenz: 17-Tage-Zyklus\n⚡ RSI (4H): 62.4 – Neutrale Zone\n🌊 Wellen-Interferenz: Konstruktiv (+0.78)\n\n⚠️ Die 17-Tage-Resonanz interferiert KONSTRUKTIV mit der 89-Tage-Welle.\n\n📈 Prognose: Aufwärtsbewegung in den nächsten 6–12 Stunden hochwahrscheinlich.\nKonfidenz: 82%\n\nEmpfehlung: Vorsichtiges Nachkaufen – 5% des Kapitals.',
    ),
    _EmmaResponse(
      trigger: 'eth',
      text: '🔵 ETH Quantum-Analyse:\n\n📊 Zyklus: 34-Tage-Resonanz dominant\n⚡ RSI (1H): 58 – Leicht bullisch\n🌊 Wellen-Score: +0.71 (konstruktiv)\n\n🔗 On-Chain:\n• ETH-Staking: +3.2% diese Woche\n• Gas-Gebühren: Rückläufig ✅\n• Whale-Akkumulation: +8%\n\n📈 Prognose: ETH folgt BTC-Trend mit 4-6h Verzögerung.\nKonfidenz: 76%\n\nEmpfehlung: Halten & auf Breakout über \$3.600 warten.',
    ),
    _EmmaResponse(
      trigger: 'sol',
      text: '🟣 SOL Quantum-Analyse:\n\n📊 Zyklus: 21-Tage-Korrekturmuster\n⚡ RSI (4H): 44 – Überverkauft-Zone\n🌊 Wellen-Interferenz: Destruktiv (-0.32)\n\n⚠️ SOL befindet sich in einer kurzfristigen Korrekturphase.\n\n🎯 Support-Level: \$170 | Resistance: \$195\n\n💡 Empfehlung: Beobachten – Einstieg bei \$172–175 möglich.\nKonfidenz: 64%',
    ),
    _EmmaResponse(
      trigger: 'qemma',
      text: '⚡ \$QEMMA Token-Analyse:\n\n🚀 Momentum: EXTREM BULLISCH\n📈 24H: +12.45% | 7D: +34.2%\n🌊 Resonanz-Score: +0.94 (max. konstruktiv)\n\n💎 Token-Fundamentals:\n• Gesamt-Supply: 100M \$QEMMA\n• Circulating: 18.4M (18.4%)\n• Mining APY: ~340%\n• Burn-Rate: 1.2% pro Quartal\n\n🔮 Prognose: Nächstes ATH bei \$0.12–0.15 möglich.\nKonfidenz: 88%\n\nHalten & weiter minen, Grigori! 💪',
    ),
    _EmmaResponse(
      trigger: 'portfolio',
      text: '📊 Portfolio-Risiko-Analyse:\n\n🔴 Risiko-Score: 6.2/10 (Mittel-Hoch)\n\nAllokation:\n• BTC: 45% – ✅ Optimal\n• ETH: 28% – ✅ Gut\n• Altcoins: 20% – ⚠️ Leicht erhöht\n• Stablecoins: 7% – 🔴 Zu niedrig\n\n💡 Empfehlung:\nStablecoin-Reserve auf 15% erhöhen.\nSharpe Ratio: 1.84 (gut)\nMax Drawdown: -12.3%\n\n📊 Gesamt-Portfolio: \$47.842 (+8.3% diese Woche)\nEmma-Score: B+ Portfolio ⭐',
    ),
    _EmmaResponse(
      trigger: 'mining',
      text: '⛏️ QEMMA Mining Status:\n\n🟢 Mining aktiv – Proof-of-Intelligence\n\n📈 Statistiken:\n• Heute verdient: 47.5 \$QEMMA (\$4.02)\n• Diese Woche: 312 \$QEMMA\n• Gesamt: 1.284 \$QEMMA (\$108.76)\n• Aktive Quests: 3/5\n• Nächste Quest in: 14 Min\n\n🏆 Aktuelle Quests:\n1. BTC-Trendanalyse – 10 \$QEMMA\n2. Sentiment-Rätsel – 15 \$QEMMA\n3. Resonanz-Kalibrierung – 25 \$QEMMA\n\n⚡ Mining-Effizienz: 94% (exzellent)\nWeiter so, Grigori! 🚀',
    ),
    _EmmaResponse(
      trigger: 'sentiment',
      text: '🧠 Markt-Sentiment-Analyse (Live):\n\n😊 Gesamt: POSITIV (72/100)\n\n📱 Social Media:\n• Twitter/X: +68% bullish\n• Reddit: +74% bullish\n• Telegram: Neutral (52%)\n• YouTube: +81% positiv\n\n📰 News-Sentiment: +0.71\n📊 Fear & Greed Index: 68 (Gier)\n\n⛓️ On-Chain:\n• Whale-Bewegungen: +12% Akkumulation\n• Exchange Flows: Outflow dominant ✅\n• Long/Short Ratio: 1.42 (Longs dominant)\n\n⚡ Quantum-Resonanz: Die kollektive Marktpsychologie zeigt moderate FOMO-Signale. Vorsicht bei Überhitzung über 80.',
    ),
    _EmmaResponse(
      trigger: 'god',
      text: '🔓 GOD MODE Aktivierungs-Anfrage erkannt.\n\nSicherheits-Protokoll aktiv.\n\nGod Mode Features:\n👁️ Unbegrenzte Agenten-Kontrolle\n⚙️ Live-Modell-Gewichte anpassen\n🕵️ Shadow Research (Tor-Netzwerk)\n🌀 Quantum Simulator (parallele Szenarien)\n🤖 Direkter Zugriff auf alle 6 HQMLL-Agenten\n🔮 Meta-Orchestrator Zugang\n\n→ Einstellungen > Erweitert > God Mode aktivieren\n   (PIN: in Ihren Zugangsdaten)',
    ),
    _EmmaResponse(
      trigger: 'signal',
      text: '📡 Top Quantum-Signale (Echtzeit):\n\n🟢 BTC/USDT – KAUFEN\n   Konfidenz: 84% | Resonanz: +0.82 | RSI: 62\n\n🟢 ETH/USDT – KAUFEN\n   Konfidenz: 79% | RSI: 58 | Trend: Bullisch\n\n🟢 QEMMA/USDT – STARK KAUFEN\n   Konfidenz: 88% | Resonanz: +0.94 | Momentum: Max\n\n🟡 SOL/USDT – HALTEN\n   Konfidenz: 61% | Trend: Neutral\n\n🔴 DOGE/USDT – VERKAUFEN\n   Konfidenz: 71% | Überverkauft\n\n⚡ Generiert von: Pattern Genesis + Quantum Oracle\nAktualisiert: gerade eben · Nächste Analyse in 4 Min',
    ),
    _EmmaResponse(
      trigger: 'agent',
      text: '🤖 HQMLL Agenten-Status (Live):\n\n1️⃣ Quantum Oracle (Emma) – 🟢 AKTIV\n   Aufgabe: Marktanalyse & NLP\n   Konfidenz: 91%\n\n2️⃣ Pattern Genesis – 🟢 AKTIV\n   Aufgabe: Chart-Mustererkennung\n   Konfidenz: 87%\n\n3️⃣ Risk Sentinel – 🟢 AKTIV\n   Aufgabe: Risikomanagement\n   Konfidenz: 94%\n\n4️⃣ Sentiment Weaver – 🟢 AKTIV\n   Aufgabe: Social-Media-Analyse\n   Konfidenz: 82%\n\n5️⃣ Blockchain Scout – 🟡 SYNC\n   Aufgabe: On-Chain-Daten\n   Konfidenz: 78%\n\n6️⃣ Meta Orchestrator – 🟢 AKTIV\n   Aufgabe: Agenten-Koordination\n   Konfidenz: 96%\n\n✅ System-Gesundheit: 98.7%',
    ),
    _EmmaResponse(
      trigger: 'hqmll',
      text: '🌀 HQMLL – Hyper-Quantum Meta-Learning-Loop\n\nDas HQMLL-System ist das Herzstück der Quantum Trader Plattform:\n\n🔬 Technologie:\n• 6 spezialisierte KI-Agenten\n• Quantum-Resonanz-Algorithmen (17T & 89T Zyklen)\n• Proof-of-Intelligence Mining\n• Meta-Orchestrator (zentrales Koordinationssystem)\n\n📊 Performance (30 Tage):\n• Treffsicherheit: 74.3%\n• Ø Signal-Konfidenz: 82%\n• Verarbeitete Datenpunkte: 847.2M\n\n💡 Entwickler: Grigori Saks\n🔗 Blockchain: Solana (\$QEMMA)\n\nDas System lernt kontinuierlich und verbessert sich täglich.',
    ),
    _EmmaResponse(
      trigger: 'risiko',
      text: '⚠️ Risikomanagement-Empfehlungen:\n\n🛡️ Risk Sentinel Analyse:\n\n📊 Aktuelles Marktrisiko: MITTEL (6.1/10)\n\n✅ Empfohlene Position:\n• Max. 5% pro Trade\n• Stop-Loss: -8% unter Einstieg\n• Take-Profit: +15% Ziel\n• Hebel: Max. 2x\n\n⚠️ Risikowarnung:\n• Correlation BTC/ETH: 0.87 (hoch)\n• Portfolio-Konzentration: 73% Top-2\n• Empfehlung: Diversifikation erhöhen\n\n💡 Defensiv-Strategie:\nStablecoins: 15% halten\nGold-Token (PAXG): 5% beimischen',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _signalPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _signalPulse.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isEmma: false, timestamp: DateTime.now()));
      _isThinking = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    Future.delayed(Duration(milliseconds: 800 + Random().nextInt(600)), () {
      final lower = text.toLowerCase();
      String responseText = '🔮 Emma analysiert Ihre Anfrage...\n\nDas HQMLL-System verarbeitet Ihre Frage mit allen 6 Meta-Agenten. Für detailliertere Analysen nutzen Sie die Schnell-Tasten oder formulieren Sie spezifischer (z.B. "BTC Analyse", "Portfolio Risiko", "Mining Status").';

      for (final r in _responses) {
        if (lower.contains(r.trigger)) {
          responseText = r.text;
          break;
        }
      }

      setState(() {
        _isThinking = false;
        _messages.add(_ChatMessage(text: responseText, isEmma: true, timestamp: DateTime.now()));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
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

    return Column(
      children: [
        // Quantum Monitor Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(bottom: BorderSide(color: p.primary.withValues(alpha: 0.15))),
          ),
          child: Row(
            children: [
              QuantumEyeWidget(palette: p, size: 52, animate: tp.quantumAnimations, showLabel: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QUANTUM ORACLE', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    Text('Emma AI · HQMLL Meta-Intelligence', style: GoogleFonts.exo(color: p.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Row(children: [
                      _StatusDot(color: p.positive),
                      const SizedBox(width: 4),
                      Text('6/6 Agenten aktiv', style: TextStyle(color: p.positive, fontSize: 10)),
                      const SizedBox(width: 12),
                      _StatusDot(color: p.primary),
                      const SizedBox(width: 4),
                      Text('Live-Daten', style: TextStyle(color: p.primary, fontSize: 10)),
                    ]),
                  ],
                ),
              ),
              _QuantumWaveIndicator(ctrl: _waveCtrl, palette: p, size: 40),
            ],
          ),
        ),
        // ── Tab-Bar: Chat | Signale ──────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: p.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            _OracleTabBtn(label: 'Chat', icon: Icons.chat_bubble_outline,
                selected: _oracleTab == 0, palette: p,
                onTap: () => setState(() => _oracleTab = 0)),
            _OracleTabBtn(label: 'Live-Signale', icon: Icons.radar,
                selected: _oracleTab == 1, palette: p,
                onTap: () => setState(() => _oracleTab = 1)),
          ]),
        ),
        // ── Signals View ─────────────────────────────
        if (_oracleTab == 1) Expanded(child: _buildSignalsView(p)),
        // Quick Questions (only in chat mode)
        if (_oracleTab == 0) SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _quickQuestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              return GestureDetector(
                onTap: () => _sendMessage(_quickQuestions[i]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: p.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(_quickQuestions[i], style: GoogleFonts.exo(color: p.primary, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              );
            },
          ),
        ),
        // Messages (Chat-Modus)
        if (_oracleTab == 0) Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length + (_isThinking ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (_isThinking && i == _messages.length) {
                return _ThinkingBubble(palette: p, ctrl: _waveCtrl);
              }
              return _MessageBubble(message: _messages[i], palette: p);
            },
          ),
        ),
        // Input (nur im Chat-Modus)
        if (_oracleTab == 0) Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(top: BorderSide(color: p.primary.withValues(alpha: 0.12))),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    style: TextStyle(color: p.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Emma fragen... (z.B. BTC Analyse)',
                      hintStyle: TextStyle(color: p.textSecondary, fontSize: 13),
                      filled: true,
                      fillColor: p.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: p.primary.withValues(alpha: 0.2))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: p.primary, width: 1.5)),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_inputCtrl.text),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [p.primary, p.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: Icon(Icons.send_rounded, color: p.background, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Live-Signale View ──────────────────────────
  Widget _buildSignalsView(dynamic p) {
    final signals = [
      const _Signal('BTC/USDT', 'Bitcoin', 'STARK KAUFEN', 84, 0.82, 62, 67842.50, 2.34, true),
      const _Signal('ETH/USDT', 'Ethereum', 'KAUFEN', 79, 0.71, 58, 3548.20, 1.87, true),
      const _Signal('QEMMA/USDT', 'QEMMA Token', 'STARK KAUFEN', 92, 0.94, 71, 0.0847, 12.45, true),
      const _Signal('SOL/USDT', 'Solana', 'HALTEN', 61, 0.12, 52, 182.40, -0.52, false),
      const _Signal('BNB/USDT', 'BNB Chain', 'KAUFEN', 74, 0.55, 60, 598.30, 0.94, true),
      const _Signal('ADA/USDT', 'Cardano', 'HALTEN', 55, -0.08, 49, 0.452, -1.23, false),
      const _Signal('DOGE/USDT', 'Dogecoin', 'VERKAUFEN', 68, -0.61, 78, 0.0892, -3.44, false),
      const _Signal('AVAX/USDT', 'Avalanche', 'KAUFEN', 76, 0.64, 57, 36.80, 4.56, true),
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Header-Info
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: p.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.primary.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            AnimatedBuilder(
              animation: _signalPulse,
              builder: (_, __) => Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: p.positive,
                  boxShadow: [BoxShadow(
                    color: p.positive.withValues(alpha: 0.6 * _signalPulse.value),
                    blurRadius: 8 * _signalPulse.value,
                  )],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'LIVE QUANTUM SIGNALE · Pattern Genesis + Oracle',
              style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9, letterSpacing: 0.5),
            )),
            Text('Refresh: 4 Min', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 8)),
          ]),
        ),
        // Signal Cards
        ...signals.map((s) => _buildSignalCard(s, p)),
      ],
    );
  }

  Widget _buildSignalCard(_Signal s, dynamic p) {
    final isBuy = s.signal.contains('KAUFEN');
    final isSell = s.signal.contains('VERKAUFEN');
    final signalColor = isBuy ? p.positive : isSell ? p.negative : p.textSecondary;
    final signalIcon = isBuy ? Icons.trending_up
        : isSell ? Icons.trending_down : Icons.remove;

    return AnimatedBuilder(
      animation: _signalPulse,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: s.signal == 'STARK KAUFEN'
                ? p.positive.withValues(alpha: 0.25 + _signalPulse.value * 0.15)
                : p.primary.withValues(alpha: 0.12),
          ),
          boxShadow: [
            if (s.signal == 'STARK KAUFEN')
              BoxShadow(
                color: p.positive.withValues(alpha: 0.05 + _signalPulse.value * 0.04),
                blurRadius: 12,
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  // Symbol
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: signalColor.withValues(alpha: 0.1),
                      border: Border.all(color: signalColor.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        s.symbol.split('/').first.substring(0, s.symbol.split('/').first.length > 3 ? 3 : s.symbol.split('/').first.length),
                        style: GoogleFonts.spaceMono(
                            color: signalColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Pair + Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.symbol, style: GoogleFonts.rajdhani(
                            color: p.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                        Text(s.name, style: GoogleFonts.spaceMono(
                            color: p.textSecondary, fontSize: 9)),
                      ],
                    ),
                  ),
                  // Price + Change
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        s.price >= 1000
                            ? '\$${s.price.toStringAsFixed(0)}'
                            : s.price >= 1
                                ? '\$${s.price.toStringAsFixed(2)}'
                                : '\$${s.price.toStringAsFixed(4)}',
                        style: GoogleFonts.rajdhani(
                            color: p.textPrimary, fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${s.change >= 0 ? '+' : ''}${s.change.toStringAsFixed(2)}%',
                        style: GoogleFonts.spaceMono(
                            color: s.change >= 0 ? p.positive : p.negative,
                            fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Signal + Metriken
              Row(
                children: [
                  // Signal Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: signalColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: signalColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(signalIcon, color: signalColor, size: 13),
                      const SizedBox(width: 5),
                      Text(s.signal, style: GoogleFonts.spaceMono(
                          color: signalColor, fontSize: 9, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const Spacer(),
                  // Konfidenz
                  _SignalMetric('KONF', '${s.confidence}%', p.primary, p),
                  const SizedBox(width: 8),
                  // Resonanz
                  _SignalMetric('RES',
                      '${s.resonance >= 0 ? '+' : ''}${s.resonance.toStringAsFixed(2)}',
                      s.resonance >= 0 ? p.positive : p.negative, p),
                  const SizedBox(width: 8),
                  // RSI
                  _SignalMetric('RSI', '${s.rsi}',
                      s.rsi > 70 ? p.negative : s.rsi < 30 ? p.positive : p.accent, p),
                ],
              ),
              const SizedBox(height: 10),
              // Konfidenz-Balken
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Konfidenz', style: GoogleFonts.spaceMono(
                          color: p.textSecondary, fontSize: 8)),
                      Text('${s.confidence}%', style: GoogleFonts.spaceMono(
                          color: p.primary, fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: s.confidence / 100,
                      backgroundColor: p.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(signalColor),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper Widget: Signal Metrik ─────────────────
class _SignalMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final dynamic palette;
  const _SignalMetric(this.label, this.value, this.color, this.palette);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: GoogleFonts.spaceMono(color: palette.textSecondary, fontSize: 7)),
        Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

// ── Oracle Tab Button ────────────────────────────
class _OracleTabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final dynamic palette;
  final VoidCallback onTap;
  const _OracleTabBtn({
    required this.label, required this.icon,
    required this.selected, required this.palette, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? p.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: selected
                ? Border.all(color: p.primary.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: selected ? p.primary : p.textSecondary, size: 13),
            const SizedBox(width: 5),
            Text(label, style: GoogleFonts.spaceMono(
                color: selected ? p.primary : p.textSecondary,
                fontSize: 9, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          ]),
        ),
      ),
    );
  }
}

// ── Signal Data Class ────────────────────────────
class _Signal {
  final String symbol;
  final String name;
  final String signal;
  final int confidence;
  final double resonance;
  final int rsi;
  final double price;
  final double change;
  final bool bullish;
  const _Signal(this.symbol, this.name, this.signal, this.confidence,
      this.resonance, this.rsi, this.price, this.change, this.bullish);
}

class _ChatMessage {
  final String text;
  final bool isEmma;
  final DateTime timestamp;
  _ChatMessage({required this.text, required this.isEmma, required this.timestamp});
}

class _EmmaResponse {
  final String trigger;
  final String text;
  const _EmmaResponse({required this.trigger, required this.text});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final dynamic palette;
  const _MessageBubble({required this.message, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final isEmma = message.isEmma;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isEmma ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isEmma) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: LinearGradient(colors: [p.primary, p.secondary])),
              child: Icon(Icons.remove_red_eye, color: p.background, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEmma ? p.surface : p.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isEmma ? 4 : 16),
                  topRight: Radius.circular(isEmma ? 16 : 4),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                border: Border.all(color: isEmma ? p.primary.withValues(alpha: 0.2) : p.primary.withValues(alpha: 0.4)),
              ),
              child: Text(message.text, style: GoogleFonts.exo(color: p.textPrimary, fontSize: 13, height: 1.5)),
            ),
          ),
          if (!isEmma) ...[
            const SizedBox(width: 8),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(shape: BoxShape.circle, color: p.surfaceVariant),
              child: Icon(Icons.person, color: p.textSecondary, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  final dynamic palette;
  final AnimationController ctrl;
  const _ThinkingBubble({required this.palette, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: LinearGradient(colors: [p.primary, p.secondary])),
            child: Icon(Icons.remove_red_eye, color: p.background, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.primary.withValues(alpha: 0.2)),
            ),
            child: AnimatedBuilder(
              animation: ctrl,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final offset = sin((ctrl.value * 2 * pi) + (i * pi / 2));
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Transform.translate(
                        offset: Offset(0, -4 * offset),
                        child: Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: p.primary),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text('Emma denkt...', style: TextStyle(color: p.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7, height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle, color: color,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4)],
      ),
    );
  }
}

class _QuantumWaveIndicator extends StatelessWidget {
  final AnimationController ctrl;
  final dynamic palette;
  final double size;
  const _QuantumWaveIndicator({required this.ctrl, required this.palette, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => SizedBox(
        width: size, height: size,
        child: CustomPaint(painter: _WavePainter(ctrl.value, palette)),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double t;
  final dynamic palette;
  _WavePainter(this.t, this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = palette.primary.withValues(alpha: 0.7);
    final path = Path();
    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 + sin((x / size.width * 4 * pi) + t * 2 * pi) * (size.height * 0.3);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = palette.accent.withValues(alpha: 0.4);
    final path2 = Path();
    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 + sin((x / size.width * 2 * pi) + t * 2 * pi + pi / 4) * (size.height * 0.2);
      if (x == 0) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
}
