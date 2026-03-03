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
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late AnimationController _waveCtrl;
  bool _isThinking = false;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: 'Willkommen, Grigori Saks. Ich bin Emma – Ihr Quantum Oracle AI Assistent.\n\nDas HQMLL Meta-Team ist aktiv. Alle 6 Agenten sind online.\n\nWie kann ich Ihnen heute helfen?',
      isEmma: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  final List<String> _quickQuestions = [
    'BTC Resonanz-Analyse',
    'Portfolio-Risiko prüfen',
    'QEMMA Mining Status',
    'Markt-Sentiment heute',
    'God Mode aktivieren',
    'Top Signale anzeigen',
  ];

  static const List<_EmmaResponse> _responses = [
    _EmmaResponse(
      trigger: 'btc',
      text: '🔮 BTC Quantum-Resonanz-Analyse:\n\n📊 Dominante Frequenz: 17-Tage-Zyklus\n⚡ RSI (4H): 62.4 – Neutrale Zone\n🌊 Wellen-Interferenz: Konstruktiv (+0.78)\n\n⚠️ Die 17-Tage-Resonanz interferiert KONSTRUKTIV mit der 89-Tage-Welle.\n\n📈 Prognose: Aufwärtsbewegung in den nächsten 6-12 Stunden hochwahrscheinlich.\nKonfidenz: 82%\n\nEmpfehlung: Vorsichtiges Nachkaufen – 5% des Kapitals.',
    ),
    _EmmaResponse(
      trigger: 'portfolio',
      text: '📊 Portfolio-Risiko-Analyse:\n\n🔴 Risiko-Score: 6.2/10 (Mittel-Hoch)\n\nAllokation:\n• BTC: 45% – ✅ Optimal\n• ETH: 28% – ✅ Gut\n• Altcoins: 20% – ⚠️ Leicht erhöht\n• Stablecoins: 7% – 🔴 Zu niedrig\n\n💡 Empfehlung:\nStablecoin-Reserve auf 15% erhöhen.\nSharpe Ratio: 1.84 (gut)\nMax Drawdown: -12.3%\n\nEmmma-Score: B+ Portfolio',
    ),
    _EmmaResponse(
      trigger: 'mining',
      text: '⛏️ QEMMA Mining Status:\n\n🟢 Mining aktiv – Proof-of-Intelligence\n\n📈 Statistiken:\n• Heute verdient: 47.5 \$QEMMA\n• Gesamt: 1.284 \$QEMMA\n• Aktive Quests: 3/5\n• Nächste Quest in: 14 Min\n\n🏆 Aktuelle Quests:\n1. BTC-Trendanalyse – 10 \$QEMMA\n2. Sentiment-Rätsel – 15 \$QEMMA\n3. Resonanz-Kalibrierung – 25 \$QEMMA\n\nWeiter so, Grigori! 🚀',
    ),
    _EmmaResponse(
      trigger: 'sentiment',
      text: '🧠 Markt-Sentiment-Analyse (Live):\n\n😊 Gesamt: POSITIV (72/100)\n\n📱 Social Media:\n• Twitter/X: +68% bullish\n• Reddit: +74% bullish\n• Telegram: Neutral (52%)\n\n📰 News-Sentiment: +0.71\n⛓️ On-Chain:\n• Whale-Bewegungen: +12% Akkumulation\n• Exchange Flows: Outflow dominant ✅\n\n⚡ Quantum-Resonanz: Die kollektive Marktpsychologie zeigt FOMO-Signale. Vorsicht bei Überhitzung.',
    ),
    _EmmaResponse(
      trigger: 'god',
      text: '🔓 GOD MODE Aktivierungs-Anfrage erkannt.\n\nSicherheits-Protokoll: PIN erforderlich.\n\n[Aus Sicherheitsgründen im Demo-Modus deaktiviert]\n\nGod Mode Features:\n• Unbegrenzte Agenten-Kontrolle\n• Live-Modell-Gewichte anpassen\n• Shadow Research (Tor-Netzwerk)\n• Quantum Simulator (parallele Szenarien)\n• Direkter Zugriff auf alle 6 HQMLL-Agenten\n\nIn den Einstellungen > Erweitert aktivieren.',
    ),
    _EmmaResponse(
      trigger: 'signal',
      text: '📡 Top Quantum-Signale (Echtzeit):\n\n🟢 BTC/USDT – KAUFEN\n   Konfidenz: 84% | Resonanz: +0.82\n\n🟢 ETH/USDT – KAUFEN\n   Konfidenz: 79% | RSI: 58\n\n🟡 SOL/USDT – HALTEN\n   Konfidenz: 61% | Trend: Neutral\n\n🔴 DOGE/USDT – VERKAUFEN\n   Konfidenz: 71% | Überverkauft-Signal\n\n⚡ Generiert von: Pattern Genesis Agent + Quantum Oracle\nAktualisiert: gerade eben',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
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
        // Quick Questions
        SizedBox(
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
        // Messages
        Expanded(
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
        // Input
        Container(
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
