// ============================================================
// AI CHAT INTERFACE – Agents, Assistants, Codex, Professional
// HQMLL Quantum Trader AI System v17.0
// ============================================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../services/exchange_service.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────

enum AgentType { assistant, codex, analyst, trader, researcher, developer }

enum MessageRole { user, agent, system }

class AgentProfile {
  final AgentType type;
  final String name;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> capabilities;
  final List<String> samplePrompts;

  const AgentProfile({
    required this.type,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.capabilities,
    required this.samplePrompts,
  });
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final AgentType? agentType;
  final bool isStreaming;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.agentType,
    this.isStreaming = false,
  });

  ChatMessage copyWith({String? content, bool? isStreaming}) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      agentType: agentType,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Agent Profiles
// ─────────────────────────────────────────────────────────────

const List<AgentProfile> _agents = [
  AgentProfile(
    type: AgentType.assistant,
    name: 'QEMMA',
    subtitle: 'Quantum Market Assistant',
    description: 'Allgemeiner KI-Assistent für Marktanalyse und Portfolio-Verwaltung. Beantwortet Fragen zu Krypto, Aktien und Trading-Strategien.',
    icon: Icons.assistant_rounded,
    color: Color(0xFF00FF88),
    capabilities: ['Marktanalyse', 'Portfolio Review', 'Risikobewertung', 'News Zusammenfassung', 'Preisprognosen'],
    samplePrompts: [
      'Analysiere mein Portfolio auf Risiken',
      'Was sind die Top-Coins heute?',
      'Erkläre mir DeFi in 3 Sätzen',
      'Wie ist der aktuelle BTC-Trend?',
    ],
  ),
  AgentProfile(
    type: AgentType.codex,
    name: 'CODEX',
    subtitle: 'Smart Contract & Code Intelligence',
    description: 'Spezialist für Smart Contract Analyse, Solidity, Rust und Blockchain-Entwicklung. Prüft Code auf Sicherheitslücken.',
    icon: Icons.code_rounded,
    color: Color(0xFF00AAFF),
    capabilities: ['Solidity Audit', 'Rust Code Review', 'Gas Optimierung', 'Security Scan', 'DeFi Protocol Analyse'],
    samplePrompts: [
      'Prüfe diesen Smart Contract auf Vulnerabilities',
      'Optimiere meine Gas-Kosten',
      'Erkläre diesen Solidity Code',
      'Schreibe einen ERC-20 Token',
    ],
  ),
  AgentProfile(
    type: AgentType.analyst,
    name: 'ORACLE',
    subtitle: 'Predictive Market Analyst',
    description: 'Deep-Learning basierter Analyst mit Zugang zu technischen Indikatoren, On-Chain-Daten und Sentiment-Analyse.',
    icon: Icons.insights_rounded,
    color: Color(0xFFFF6B35),
    capabilities: ['Technische Analyse', 'On-Chain Metriken', 'Sentiment Score', 'Whale Tracking', 'Pattern Recognition'],
    samplePrompts: [
      'Technische Analyse für ETH/USDT',
      'Zeige Whale-Bewegungen für BTC',
      'Sentiment-Score für SOL',
      'Identifiziere bullische Patterns',
    ],
  ),
  AgentProfile(
    type: AgentType.trader,
    name: 'TR2',
    subtitle: 'Autonomous Trading Agent',
    description: 'Meta-Reasoning Trading Engine mit rekursiver Selbstoptimierung. Entwickelt und backtestet Handelsstrategien autonom.',
    icon: Icons.psychology_rounded,
    color: Color(0xFFAA44FF),
    capabilities: ['Strategie-Entwicklung', 'Backtest-Engine', 'Risk Management', 'Portfolio Rebalancing', 'Auto-Trading Logik'],
    samplePrompts: [
      'Entwickle eine BTC-Swing-Trading-Strategie',
      'Backteste meine RSI-Strategie',
      'Optimiere mein Stop-Loss',
      'Erstelle einen Trading-Algorithmus',
    ],
  ),
  AgentProfile(
    type: AgentType.researcher,
    name: 'NEXUS',
    subtitle: 'Research & Intelligence Agent',
    description: 'Forschungsagent für Tiefenanalyse von Projekten, Whitepapers, Tokenomics und Marktdynamiken.',
    icon: Icons.search_rounded,
    color: Color(0xFFFFD700),
    capabilities: ['Whitepaper Analyse', 'Tokenomics Review', 'Team Research', 'Roadmap Evaluation', 'Competitor Analysis'],
    samplePrompts: [
      'Analysiere das Solana-Ökosystem',
      'Bewerte die Tokenomics von QEMMA',
      'Vergleiche ETH vs SOL vs AVAX',
      'Was ist Layer 2 und welche sind führend?',
    ],
  ),
  AgentProfile(
    type: AgentType.developer,
    name: 'FORGE',
    subtitle: 'Professional Development Agent',
    description: 'Professioneller Entwicklungsagent für dApp-Entwicklung, API-Integration, Flutter/Web3 und Blockchain-Infrastruktur.',
    icon: Icons.build_rounded,
    color: Color(0xFF00CED1),
    capabilities: ['dApp Development', 'Web3 Integration', 'API Design', 'Flutter/Dart', 'Blockchain Infrastructure'],
    samplePrompts: [
      'Erstelle eine Web3 Flutter App',
      'Wie integriere ich MetaMask?',
      'Erkläre WalletConnect v2',
      'Baue einen DEX in Solidity',
    ],
  ),
];

// ─────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with TickerProviderStateMixin {
  // Controllers
  late TabController _tabController;
  late AnimationController _glowCtrl;
  late AnimationController _pulseCtrl;
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // State
  int _selectedAgent = 0;
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isAgentSelectorOpen = false;
  String _selectedMode = 'Professional';
  final Random _rand = Random();
  Timer? _streamTimer;

  // Professional Modes
  final List<Map<String, dynamic>> _modes = [
    {'name': 'Professional', 'icon': Icons.work_rounded, 'color': const Color(0xFF00FF88)},
    {'name': 'Developer', 'icon': Icons.code_rounded, 'color': const Color(0xFF00AAFF)},
    {'name': 'Analyst', 'icon': Icons.analytics_rounded, 'color': const Color(0xFFFF6B35)},
    {'name': 'Research', 'icon': Icons.science_rounded, 'color': const Color(0xFFFFD700)},
    {'name': 'Auto', 'icon': Icons.auto_awesome_rounded, 'color': const Color(0xFFAA44FF)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Welcome message
    _addSystemMessage();
  }

  void _addSystemMessage() {
    final agent = _agents[_selectedAgent];
    _messages.add(ChatMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.system,
      content:
          '🔮 ${agent.name} initialisiert — ${agent.subtitle}\n\nIch bin bereit. Wie kann ich dir helfen?',
      timestamp: DateTime.now(),
      agentType: agent.type,
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _glowCtrl.dispose();
    _pulseCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _streamTimer?.cancel();
    super.dispose();
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

  void _sendMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isTyping) return;

    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();
    HapticFeedback.lightImpact();

    // Simulate AI response with streaming
    Future.delayed(const Duration(milliseconds: 800), () {
      _simulateAgentResponse(text);
    });
  }

  void _simulateAgentResponse(String userInput) {
    final agent = _agents[_selectedAgent];
    final response = _generateContextualResponse(agent, userInput);

    final msgId = 'agent_${DateTime.now().millisecondsSinceEpoch}';
    final agentMsg = ChatMessage(
      id: msgId,
      role: MessageRole.agent,
      content: '',
      timestamp: DateTime.now(),
      agentType: agent.type,
      isStreaming: true,
    );

    setState(() {
      _messages.add(agentMsg);
    });

    // Stream response character by character
    int charIndex = 0;
    _streamTimer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      if (charIndex < response.length) {
        setState(() {
          final msgIdx =
              _messages.indexWhere((m) => m.id == msgId);
          if (msgIdx != -1) {
            _messages[msgIdx] = _messages[msgIdx].copyWith(
              content: response.substring(0, charIndex + 1),
            );
          }
        });
        charIndex++;
        if (charIndex % 30 == 0) _scrollToBottom();
      } else {
        timer.cancel();
        setState(() {
          final msgIdx =
              _messages.indexWhere((m) => m.id == msgId);
          if (msgIdx != -1) {
            _messages[msgIdx] = _messages[msgIdx].copyWith(
              isStreaming: false,
            );
          }
          _isTyping = false;
        });
        _scrollToBottom();
      }
    });
  }

  String _generateContextualResponse(AgentProfile agent, String input) {
    final lower = input.toLowerCase();
    // Live-Preise aus ExchangeService
    final ex = context.read<ExchangeService>();
    final btcLive = ex.getPrice('BTC');
    final ethLive = ex.getPrice('ETH');
    final solLive = ex.getPrice('SOL');
    final btcPrice = btcLive > 0 ? btcLive : 67842.0;
    final ethPrice = ethLive > 0 ? ethLive : 3548.0;
    final solPrice = solLive > 0 ? solLive : 182.0;
    final btcTick = ex.getTick('BTC');
    final btcChg = btcTick != null ? btcTick.change24h : 2.34;
    final btcChgStr = '${btcChg >= 0 ? '+' : ''}${btcChg.toStringAsFixed(2)}%';
    // Preis-Formatter: 67842.5 -> $67,842
    String fmtP(double v) {
      if (v <= 0) return r'$0';
      final s = v >= 100 ? v.toStringAsFixed(0) : v >= 1 ? v.toStringAsFixed(2) : v.toStringAsFixed(4);
      final parts = s.split('.');
      final intPart = parts[0];
      final decPart = parts.length > 1 ? '.${parts[1]}' : '';
      final buf = StringBuffer();
      for (int i = 0; i < intPart.length; i++) {
        if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
        buf.write(intPart[i]);
      }
      return '\$${buf.toString()}$decPart';
    }
    final btcStr = fmtP(btcPrice);
    final ethStr = fmtP(ethPrice);
    final solStr = fmtP(solPrice);

    // Context-aware responses per agent
    if (agent.type == AgentType.assistant) {
      if (lower.contains('bitcoin') || lower.contains('btc')) {
        return '📊 **Bitcoin (BTC) Marktanalyse**\n\nAktueller Preis: $btcStr ($btcChgStr)\nMarktkapitalisierung: \$1.28 Billionen\n\n**Technische Signale:**\n• RSI(14): 58 → Neutral-Bullisch\n• MACD: Positiver Crossover\n• 200-Tage-MA: Preis darüber (+12%)\n• Volumen: 24h Volumen \$32.1B ↑\n\n**Unterstützung & Widerstand:**\n• Support: \$64,500 / \$61,200\n• Resistance: \$68,800 / \$72,000\n\n**QEMMA-Einschätzung:** BTC bei $btcStr, ETH bei $ethStr, SOL bei $solStr. Die Marktstimmung ist positiv. Institutionelle Zuflüsse steigen. Langfristig bullisch mit kurzfristiger Konsolidierung möglich.\n\n⚡ Soll ich eine detailliertere Analyse oder Trading-Strategie erstellen?';
      }
      if (lower.contains('portfolio') || lower.contains('risiko')) {
        return '🎯 **Portfolio-Risikoanalyse**\n\nIch analysiere dein Portfolio:\n\n**Diversifikation Score:** 7.2/10\n**Risikoprofil:** Mittel-Hoch\n**Sharpe Ratio:** 1.42\n\n**Empfehlungen:**\n• 📉 BTC-Gewichtung bei 42% — ideal wäre 30-35%\n• 📊 ETH Exposure: Solide bei 18%\n• ⚠️ Altcoins über 25% erhöhen das Risiko\n• 💰 Stablecoin-Reserve von 10% empfohlen\n\n**Rebalancing-Vorschlag:**\n→ -7% BTC → +5% ETH, +2% Stablecoins\n\nMöchtest du einen automatischen Rebalancing-Plan?';
      }
    }

    if (agent.type == AgentType.codex) {
      if (lower.contains('solidity') || lower.contains('contract') || lower.contains('smart')) {
        return '💻 **Smart Contract Analyse**\n\n```solidity\n// ERC-20 Token - Sicherheitsgeprüft\npragma solidity ^0.8.20;\n\nimport "@openzeppelin/contracts/token/ERC20/ERC20.sol";\nimport "@openzeppelin/contracts/security/ReentrancyGuard.sol";\n\ncontract QEMMAToken is ERC20, ReentrancyGuard {\n    address public immutable owner;\n    uint256 public constant MAX_SUPPLY = 100_000_000e18;\n    \n    constructor() ERC20("QEMMA", "QMMA") {\n        owner = msg.sender;\n        _mint(msg.sender, 10_000_000e18);\n    }\n}\n```\n\n**Security Audit:**\n✅ Reentrancy Guard aktiviert\n✅ Immutable Owner-Variable\n✅ Integer Overflow: Solidity 0.8+ schützt automatisch\n✅ OpenZeppelin Standard-Bibliothek\n\n⚠️ Empfehlung: Füge Timelock für Admin-Funktionen hinzu\n\nSoll ich den vollständigen Token mit Staking & Governance erstellen?';
      }
      return '🔍 **CODEX Analyse**\n\nIch analysiere deinen Code:\n\n**Erkannte Sprache:** Solidity / Rust / TypeScript\n\n**Security Score:** 84/100\n\n**Gefundene Patterns:**\n• 2 potentielle Optimierungen gefunden\n• Gas-Verbrauch kann um ~15% reduziert werden\n• Best Practice: Events für State-Änderungen hinzufügen\n\n**Empfohlene Tools:**\n• Slither für statische Analyse\n• Foundry für Tests\n• Hardhat für Deployment\n\nTeile deinen Code und ich führe einen vollständigen Audit durch!';
    }

    if (agent.type == AgentType.analyst) {
      final target = fmtP(btcPrice * 1.05);
      return '📈 **ORACLE Predictive Analyse**\n\nML-Modell v3.2 | Konfidenz: 78%\nBTC aktuell: $btcStr ($btcChgStr)\n\n**Marktstruktur:**\nHöhere Hochs und höhere Tiefs → Uptrend intakt\n\n**Key Indikatoren:**\n• RSI: 62 (Bullisch, kein Overkauf)\n• MACD: Golden Cross vor 3 Tagen\n• Bollinger Bands: Preis im oberen Drittel\n• OBV: Steigend → Akkumulation\n\n**On-Chain Daten:**\n• Whale Wallets: +2,300 BTC in 48h akkumuliert\n• Exchange Outflows: Hoch (bullisch)\n• Miner Capitulation: Keine Anzeichen\n\n**72h Prognose:**\n→ Bullisch: 68% Wahrscheinlichkeit\n→ Bearisch: 22% Wahrscheinlichkeit\n→ Seitwärts: 10%\n\n🎯 Kursziel: $target (±5%)';
    }

    if (agent.type == AgentType.trader) {
      final entryZone = fmtP(btcPrice * 0.96);
      final tp1 = fmtP(btcPrice * 1.025);
      final tp2 = fmtP(btcPrice * 1.06);
      return '⚡ **TR2 Meta-Reasoning Engine**\n\nRekursive Analyse Level 3 abgeschlossen...\nBTC Live: $btcStr ($btcChgStr)\n\n**Strategie-Entwicklung:**\n\n📋 **Swing-Trading Strategie (BTC/USDT)**\n• Timeframe: 4H Chart\n• Entry-Zone: $entryZone (RSI < 40 + MACD Divergenz)\n• TP1: $tp1 | TP2: $tp2\n• Stop-Loss: -2.5% | R:R = 1:2.5\n\n**Backtest-Ergebnisse (90 Tage):**\n• Win Rate: 64%\n• Profit Factor: 1.87\n• Max Drawdown: -8.3%\n• Sharpe Ratio: 1.94\n• Nettogewinn: +23.4%\n\n**Risikomanagement:**\n• Max 2% pro Trade\n• Kein Margin > 3x\n• Tägliches Verlustlimit: -5%\n\nSoll TR2 diese Strategie automatisch ausführen?';
    }

    if (agent.type == AgentType.researcher) {
      return '🔬 **NEXUS Research Bericht**\n\n**Tiefenanalyse angefordert**\n\n**Ökosystem-Übersicht:**\n\n🏆 **Top DeFi Protokolle 2025:**\n1. Uniswap V4 — \$8.2B TVL\n2. Aave V3 — \$6.7B TVL\n3. Curve Finance — \$3.9B TVL\n4. MakerDAO — \$8.1B TVL\n5. Compound III — \$2.3B TVL\n\n**Wachstumssektoren:**\n• RWA (Real World Assets): +340% YoY\n• LSD/LST Protokolle: +180% YoY\n• zkEVM Layer 2: Massenadoption\n• AI + Blockchain: Emerging Sector\n\n**Risiken:**\n⚠️ Regulatorisches Umfeld im Wandel\n⚠️ Smart Contract Risiken\n⚠️ Liquiditätsrisiken bei Altcoins\n\nSoll ich einen vollständigen 20-Seiten-Report erstellen?';
    }

    if (agent.type == AgentType.developer) {
      return '🛠️ **FORGE Development Guide**\n\n**Flutter Web3 Integration:**\n\n```dart\n// Web3 Connection Service\nclass Web3Service {\n  static Future<void> connectWallet() async {\n    // WalletConnect v2\n    final wcClient = Web3App(\n      core: Core(projectId: "YOUR_PROJECT_ID"),\n      metadata: PairingMetadata(\n        name: "QEMMA Trader",\n        description: "Quantum Trading System",\n        url: "https://qemma.io",\n        icons: ["https://qemma.io/icon.png"],\n      ),\n    );\n    await wcClient.init();\n  }\n}\n```\n\n**Stack-Empfehlung:**\n• Frontend: Flutter + WalletConnect v2\n• Smart Contracts: Solidity + Hardhat\n• Indexing: The Graph Protocol\n• Backend: Node.js + Ethers.js\n• Deployment: IPFS + ENS\n\n**Nächste Schritte:**\n1. MetaMask SDK Integration\n2. On-Chain Data Fetching\n3. Transaction Signing\n\nSoll ich den kompletten Boilerplate-Code erstellen?';
    }

    // Generic fallback
    final responses = [
      '🤖 **${agent.name} verarbeitet deine Anfrage...**\n\nIch habe deine Frage analysiert und folgendes festgestellt:\n\n• Die Anfrage enthält interessante Aspekte über ${lower.split(' ').take(3).join(', ')}\n• Meine Analyse zeigt mehrere relevante Datenpunkte\n• Basierend auf meinem Training gebe ich dir eine fundierte Antwort\n\n**Zusammenfassung:**\nDeine Anfrage ist gut strukturiert. Lass mich dir mit meiner Expertise als ${agent.subtitle} helfen.\n\nHast du spezifischere Details oder möchtest du eines meiner Beispiel-Prompts ausprobieren?',
      '🔮 **${agent.name} — ${agent.subtitle}**\n\nAnalyse abgeschlossen mit ${65 + _rand.nextInt(30)}% Konfidenz.\n\n**Relevante Erkenntnisse:**\n• Marktbedingungen aktuell: Neutral-Bullisch\n• Empfohlene Aktion basierend auf deiner Anfrage\n• Weitere Daten würden die Genauigkeit erhöhen\n\nTeile mehr Details, damit ich präzisere Empfehlungen geben kann!',
    ];
    return responses[_rand.nextInt(responses.length)];
  }

  // ─────────────────────────────────────────────────────────────
  // Build Methods
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;

    return Scaffold(
      backgroundColor: p.background,
      body: Column(
        children: [
          _buildHeader(p),
          _buildTabBar(p),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatView(p),
                _buildAgentsView(p),
                _buildHistoryView(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic p) {
    final agent = _agents[_selectedAgent];
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(
            bottom: BorderSide(
              color: agent.color.withValues(alpha: 0.15 + _glowCtrl.value * 0.1),
            ),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Agent Avatar
                GestureDetector(
                  onTap: () => setState(() {
                    _isAgentSelectorOpen = !_isAgentSelectorOpen;
                    _tabController.animateTo(1);
                  }),
                  child: AnimatedBuilder(
                    animation: _glowCtrl,
                    builder: (_, __) => Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            agent.color.withValues(alpha: 0.3),
                            agent.color.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: agent.color.withValues(
                              alpha: 0.4 + _glowCtrl.value * 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: agent.color.withValues(
                                alpha: 0.2 + _glowCtrl.value * 0.15),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(agent.icon, color: agent.color, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            agent.name,
                            style: GoogleFonts.spaceMono(
                              color: agent.color,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: const Color(0xFF00FF88)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'ONLINE',
                              style: GoogleFonts.spaceMono(
                                color: const Color(0xFF00FF88),
                                fontSize: 8,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        agent.subtitle,
                        style: GoogleFonts.inter(
                          color: p.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Mode Selector
                GestureDetector(
                  onTap: _showModeSelector,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: p.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: p.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded,
                            color: p.primary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _selectedMode,
                          style: GoogleFonts.spaceMono(
                            color: p.primary,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: p.primary, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Capabilities chips
            SizedBox(
              height: 26,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: agent.capabilities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: agent.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: agent.color.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    agent.capabilities[i],
                    style: GoogleFonts.spaceMono(
                      color: agent.color.withValues(alpha: 0.85),
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(dynamic p) {
    return Container(
      color: p.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: p.primary,
        unselectedLabelColor: p.textSecondary,
        indicatorColor: p.primary,
        indicatorWeight: 2,
        labelStyle: GoogleFonts.spaceMono(fontSize: 10, letterSpacing: 1),
        unselectedLabelStyle:
            GoogleFonts.spaceMono(fontSize: 10, letterSpacing: 0.5),
        tabs: const [
          Tab(icon: Icon(Icons.chat_bubble_outline_rounded, size: 16), text: 'CHAT'),
          Tab(icon: Icon(Icons.group_work_outlined, size: 16), text: 'AGENTEN'),
          Tab(icon: Icon(Icons.history_rounded, size: 16), text: 'VERLAUF'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Chat View
  // ─────────────────────────────────────────────────────────────

  Widget _buildChatView(dynamic p) {
    return Column(
      children: [
        // Messages List
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyChat(p)
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _buildMessage(_messages[i], p),
                ),
        ),
        // Sample Prompts (shown when < 2 messages)
        if (_messages.length < 2) _buildSamplePrompts(p),
        // Typing Indicator
        if (_isTyping) _buildTypingIndicator(p),
        // Input Bar
        _buildInputBar(p),
      ],
    );
  }

  Widget _buildEmptyChat(dynamic p) {
    final agent = _agents[_selectedAgent];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    agent.color.withValues(alpha: 0.2 + _pulseCtrl.value * 0.1),
                    agent.color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: agent.color.withValues(alpha: 0.3 + _pulseCtrl.value * 0.2),
                ),
              ),
              child: Icon(agent.icon, color: agent.color, size: 38),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            agent.name,
            style: GoogleFonts.spaceMono(
              color: agent.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            agent.subtitle,
            style: GoogleFonts.inter(color: p.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              agent.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: p.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg, dynamic p) {
    final isUser = msg.role == MessageRole.user;
    final isSystem = msg.role == MessageRole.system;
    final agent = _agents[_selectedAgent];

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: agent.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: agent.color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: agent.color, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg.content,
                style: GoogleFonts.spaceMono(
                  color: agent.color.withValues(alpha: 0.85),
                  fontSize: 10,
                  height: 1.5,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    agent.color.withValues(alpha: 0.25),
                    agent.color.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: agent.color.withValues(alpha: 0.3)),
              ),
              child: Icon(agent.icon, color: agent.color, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [
                          p.primary.withValues(alpha: 0.2),
                          p.primary.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          p.surface,
                          p.surface.withValues(alpha: 0.8),
                        ],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
                border: Border.all(
                  color: isUser
                      ? p.primary.withValues(alpha: 0.3)
                      : agent.color.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(msg.content, isUser, agent, p),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(msg.timestamp),
                        style: GoogleFonts.spaceMono(
                          color: p.textSecondary.withValues(alpha: 0.5),
                          fontSize: 9,
                        ),
                      ),
                      if (msg.isStreaming) ...[
                        const SizedBox(width: 6),
                        _buildStreamingDot(agent.color),
                      ],
                      if (!isUser && !msg.isStreaming) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: msg.content));
                            HapticFeedback.lightImpact();
                          },
                          child: Icon(
                            Icons.copy_rounded,
                            color: p.textSecondary.withValues(alpha: 0.4),
                            size: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    p.primary.withValues(alpha: 0.3),
                    p.primary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.primary.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.person_rounded, color: p.primary, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(
      String content, bool isUser, AgentProfile agent, dynamic p) {
    // Parse markdown-like formatting
    final lines = content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('**') && line.endsWith('**') && line.length > 4) {
          final text = line.substring(2, line.length - 2);
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: isUser ? p.primary : agent.color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
        if (line.startsWith('```') || line.endsWith('```')) {
          return const SizedBox.shrink();
        }
        if (line.startsWith('//') || line.startsWith('pragma') ||
            line.startsWith('import') || line.startsWith('contract') ||
            line.startsWith('function') || line.startsWith('    ') && !isUser) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: agent.color.withValues(alpha: 0.1)),
            ),
            child: Text(
              line,
              style: GoogleFonts.spaceMono(
                color: const Color(0xFF00FF88),
                fontSize: 9,
              ),
            ),
          );
        }
        if (line.isEmpty) return const SizedBox(height: 4);
        return Text(
          line,
          style: GoogleFonts.inter(
            color: isUser
                ? p.primary.withValues(alpha: 0.9)
                : p.textPrimary.withValues(alpha: 0.88),
            fontSize: 12,
            height: 1.5,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStreamingDot(Color color) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (i) => Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: color.withValues(
                  alpha: i == (_pulseCtrl.value * 3).floor() % 3 ? 1.0 : 0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSamplePrompts(dynamic p) {
    final agent = _agents[_selectedAgent];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SCHNELLSTART',
            style: GoogleFonts.spaceMono(
              color: p.textSecondary.withValues(alpha: 0.5),
              fontSize: 9,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: agent.samplePrompts
                .map((prompt) => GestureDetector(
                      onTap: () {
                        _inputCtrl.text = prompt;
                        _sendMessage();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: agent.color.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: agent.color.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flash_on_rounded,
                                color: agent.color, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              prompt,
                              style: GoogleFonts.inter(
                                color: agent.color.withValues(alpha: 0.8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(dynamic p) {
    final agent = _agents[_selectedAgent];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(agent.icon, color: agent.color, size: 14),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Text(
              '${agent.name} schreibt${List.filled((_pulseCtrl.value * 3).floor() + 1, '.').join()}',
              style: GoogleFonts.spaceMono(
                color: agent.color.withValues(alpha: 0.6),
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(dynamic p) {
    final agent = _agents[_selectedAgent];
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: p.surface,
        border:
            Border(top: BorderSide(color: p.primary.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          // Attach / Tools button
          GestureDetector(
            onTap: _showToolsMenu,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.primary.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.add_rounded, color: p.primary, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          // Text Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: p.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? agent.color.withValues(alpha: 0.4)
                      : p.primary.withValues(alpha: 0.15),
                ),
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                style: GoogleFonts.inter(
                  color: p.textPrimary,
                  fontSize: 13,
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Frage ${agent.name}...',
                  hintStyle: GoogleFonts.inter(
                    color: p.textSecondary.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send Button
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [agent.color, agent.color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: agent.color.withValues(
                          alpha: 0.3 + _glowCtrl.value * 0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: _isTyping
                    ? Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Agents View
  // ─────────────────────────────────────────────────────────────

  Widget _buildAgentsView(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.group_work_rounded, color: p.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'AI AGENTEN SYSTEM',
                    style: GoogleFonts.spaceMono(
                      color: p.primary,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Wähle einen spezialisierten Agenten für deine Aufgabe. Jeder Agent hat einzigartige Fähigkeiten und Expertise.',
                style: GoogleFonts.inter(
                  color: p.textSecondary,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        // Agents Grid
        ..._agents.asMap().entries.map((entry) {
          final i = entry.key;
          final agent = entry.value;
          final isSelected = _selectedAgent == i;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedAgent = i;
                _messages.clear();
                _addSystemMessage();
              });
              _tabController.animateTo(0);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          agent.color.withValues(alpha: 0.12),
                          agent.color.withValues(alpha: 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : p.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? agent.color.withValues(alpha: 0.4)
                      : p.primary.withValues(alpha: 0.1),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: agent.color.withValues(alpha: 0.15),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          agent.color.withValues(alpha: 0.25),
                          agent.color.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: agent.color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(agent.icon, color: agent.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              agent.name,
                              style: GoogleFonts.spaceMono(
                                color: isSelected ? agent.color : p.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: agent.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'AKTIV',
                                  style: GoogleFonts.spaceMono(
                                    color: agent.color,
                                    fontSize: 8,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          agent.subtitle,
                          style: GoogleFonts.inter(
                            color: p.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: agent.capabilities
                              .take(3)
                              .map((cap) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: agent.color.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      cap,
                                      style: GoogleFonts.spaceMono(
                                        color: agent.color.withValues(alpha: 0.7),
                                        fontSize: 8,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: isSelected
                        ? agent.color
                        : p.textSecondary.withValues(alpha: 0.3),
                    size: isSelected ? 20 : 14,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // History View
  // ─────────────────────────────────────────────────────────────

  Widget _buildHistoryView(dynamic p) {
    final sessions = [
      {'agent': 'QEMMA', 'preview': 'Bitcoin Analyse und Portfolio-Review...', 'time': 'Heute 14:32', 'msgs': 8, 'color': const Color(0xFF00FF88)},
      {'agent': 'CODEX', 'preview': 'ERC-20 Token Smart Contract Audit...', 'time': 'Heute 11:15', 'msgs': 12, 'color': const Color(0xFF00AAFF)},
      {'agent': 'ORACLE', 'preview': 'ETH technische Analyse 4H Chart...', 'time': 'Gestern 18:44', 'msgs': 6, 'color': const Color(0xFFFF6B35)},
      {'agent': 'TR2', 'preview': 'Swing-Trading Strategie Entwicklung...', 'time': 'Gestern 10:22', 'msgs': 15, 'color': const Color(0xFFAA44FF)},
      {'agent': 'NEXUS', 'preview': 'DeFi Ökosystem Research Report...', 'time': 'Mo 09:05', 'msgs': 9, 'color': const Color(0xFFFFD700)},
      {'agent': 'FORGE', 'preview': 'Flutter Web3 Integration Guide...', 'time': 'So 16:33', 'msgs': 20, 'color': const Color(0xFF00CED1)},
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(Icons.history_rounded, color: p.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'CHAT VERLAUF',
                style: GoogleFonts.spaceMono(
                  color: p.primary,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text(
                '${sessions.length} Sessions',
                style: GoogleFonts.spaceMono(
                  color: p.textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
        ...sessions.map((session) {
          final color = session['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Center(
                    child: Text(
                      (session['agent'] as String).substring(0, 1),
                      style: GoogleFonts.spaceMono(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            session['agent'] as String,
                            style: GoogleFonts.spaceMono(
                              color: color,
                              fontSize: 11,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            session['time'] as String,
                            style: GoogleFonts.spaceMono(
                              color: p.textSecondary.withValues(alpha: 0.5),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        session['preview'] as String,
                        style: GoogleFonts.inter(
                          color: p.textSecondary,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${session['msgs']} Nachrichten',
                        style: GoogleFonts.spaceMono(
                          color: p.textSecondary.withValues(alpha: 0.4),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: p.textSecondary.withValues(alpha: 0.3), size: 16),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Dialogs & Actions
  // ─────────────────────────────────────────────────────────────

  void _showModeSelector() {
    final p = context.read<ThemeProvider>().palette;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ENTWICKLUNGS-MODUS',
              style: GoogleFonts.spaceMono(
                color: p.primary,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Wähle den Expertise-Level für die Antworten',
              style: GoogleFonts.inter(color: p.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 16),
            ..._modes.map((mode) {
              final isSelected = _selectedMode == mode['name'];
              final color = mode['color'] as Color;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedMode = mode['name'] as String);
                  Navigator.pop(context);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.12)
                        : p.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? color.withValues(alpha: 0.4)
                          : p.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(mode['icon'] as IconData,
                          color: color, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        mode['name'] as String,
                        style: GoogleFonts.spaceMono(
                          color: isSelected ? color : p.textPrimary,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: color, size: 18),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showToolsMenu() {
    final p = context.read<ThemeProvider>().palette;
    final tools = [
      {'icon': Icons.attach_file_rounded, 'label': 'Datei anhängen', 'color': const Color(0xFF00AAFF)},
      {'icon': Icons.camera_alt_rounded, 'label': 'Screenshot', 'color': const Color(0xFFFF6B35)},
      {'icon': Icons.bar_chart_rounded, 'label': 'Chart einfügen', 'color': const Color(0xFF00FF88)},
      {'icon': Icons.code_rounded, 'label': 'Code-Block', 'color': const Color(0xFFAA44FF)},
      {'icon': Icons.link_rounded, 'label': 'URL analysieren', 'color': const Color(0xFFFFD700)},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TOOLS',
              style: GoogleFonts.spaceMono(
                color: p.primary,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: tools.map((tool) {
                final color = tool['color'] as Color;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    HapticFeedback.lightImpact();
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: color.withValues(alpha: 0.3)),
                        ),
                        child: Icon(tool['icon'] as IconData,
                            color: color, size: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tool['label'] as String,
                        style: GoogleFonts.inter(
                          color: p.textSecondary,
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
