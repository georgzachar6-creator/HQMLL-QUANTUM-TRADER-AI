// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/exchange_service.dart';

// ═══════════════════════════════════════════════════════════════
//  HQMLL WRITER — Document Intelligence & AI Drafting Module
//  Quantum Trader AI System v15.0
// ═══════════════════════════════════════════════════════════════

class WriterScreen extends StatefulWidget {
  const WriterScreen({super.key});
  @override
  State<WriterScreen> createState() => _WriterScreenState();
}

class _WriterScreenState extends State<WriterScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _typingCtrl;
  late Animation<double> _glowAnim;

  final TextEditingController _docCtrl = TextEditingController();
  final TextEditingController _promptCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  int _activeTab = 0;
  bool _isGenerating = false;
  bool _isSaving = false;
  String _selectedTemplate = 'Trading Report';
  String _selectedStyle = 'Professional';
  String _aiStatus = 'BEREIT';
  int _wordCount = 0;
  int _charCount = 0;
  double _genProgress = 0.0;
  Timer? _genTimer;
  Timer? _autoSaveTimer;
  String _lastSaved = 'Nie';

  // ── Dokument-Vorlagen ─────────────────────────────────────
  final Map<String, String> _templates = {
    'Trading Report': '''# Trading Analyse Report
**Datum:** ${_today()}
**Analyst:** HQMLL Quantum AI

## Markt-Übersicht
[KI generiert Marktanalyse hier...]

## Portfolio Performance
- Gesamtrendite: +0.00%
- Gewinn/Verlust: \$0.00

## Top-Performer
1. [Asset] +0.00%
2. [Asset] +0.00%

## Risiko-Bewertung
**Risiko-Level:** MITTEL

## Empfehlungen
[AI-gestützte Handlungsempfehlungen...]
''',
    'Whitepaper': '''# HQMLL Quantum Token — Whitepaper v1.0

## Executive Summary
HQMLL ist ein revolutionäres KI-gestütztes Trading-Ökosystem...

## Technologie
### Quantum AI Engine
Die proprietäre TR2 Recursive Reasoning Engine...

## Tokenomics
**Total Supply:** 21,000,000 QEMMA
**Distribution:**
- 40% Community Mining
- 25% Development Fund
- 20% Liquidity Pool
- 15% Team & Advisors

## Roadmap
**Q1 2025:** Mainnet Launch
**Q2 2025:** DEX Integration
**Q3 2025:** Cross-Chain Bridge
**Q4 2025:** AI Governance

## Disclaimer
[Rechtliche Hinweise...]
''',
    'Market Memo': '''# Markt-Memo
**An:** Trading Team
**Von:** HQMLL AI System
**Betreff:** Tagesanalyse

## Kernaussagen
- BTC hält Support bei \$67,000
- ETH zeigt Bullish Divergenz
- Altcoin-Saison Indikatoren positiv

## Kritische Level
[Wichtige Preiszonen...]

## Handlungsbedarf
[Sofortmaßnahmen...]
''',
    'Investment Thesis': '''# Investment Thesis
**Asset:** [SYMBOL]
**Zeitraum:** [Datum]

## Bullish Case
1. Starkes Fundamentalbild
2. Technische Aufstellung positiv
3. Makro-Umfeld günstig

## Bearish Risiken
1. Regulatorische Unsicherheit
2. Marktvolatilität
3. Konkurrenzdruck

## Kursziel
**12-Monats-Ziel:** \$[X]
**Stop-Loss:** \$[Y]

## Fazit
[Zusammenfassung & Empfehlung]
''',
    'Smart Contract': '''// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title QEMMA Token
 * @dev HQMLL Quantum Trading Ecosystem Token
 */
contract QEMMAToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 21_000_000 * 10**18;
    
    mapping(address => bool) public miners;
    
    constructor() ERC20("QEMMA Token", "QEMMA") {
        _mint(msg.sender, 1_000_000 * 10**18);
    }
    
    function mine(address to, uint256 amount) external {
        require(miners[msg.sender], "Not authorized miner");
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        _mint(to, amount);
    }
    
    // Add your functions here...
}
''',
  };

  // ── Gespeicherte Dokumente ────────────────────────────────
  final List<Map<String, dynamic>> _savedDocs = [
    {
      'title': 'BTC Analyse Q2 2025',
      'type': 'Trading Report',
      'words': 842,
      'modified': 'Heute 09:34',
      'color': const Color(0xFFF7931A),
      'pinned': true,
    },
    {
      'title': 'QEMMA Whitepaper v2.1',
      'type': 'Whitepaper',
      'words': 3204,
      'modified': 'Gestern 15:22',
      'color': const Color(0xFF00FF88),
      'pinned': true,
    },
    {
      'title': 'Portfolio Memo April',
      'type': 'Market Memo',
      'words': 412,
      'modified': 'Mo. 11:08',
      'color': const Color(0xFF00AAFF),
      'pinned': false,
    },
    {
      'title': 'SOL Investment Thesis',
      'type': 'Investment Thesis',
      'words': 1087,
      'modified': '10. Apr',
      'color': const Color(0xFF9945FF),
      'pinned': false,
    },
    {
      'title': 'QEMMA Smart Contract v3',
      'type': 'Smart Contract',
      'words': 156,
      'modified': '08. Apr',
      'color': const Color(0xFFFFAA00),
      'pinned': false,
    },
  ];

  // ── AI Schreib-Prompts ────────────────────────────────────
  final List<String> _quickPrompts = [
    'Analysiere BTC Preisbewegung',
    'Erstelle Portfolio-Zusammenfassung',
    'Schreibe Risiko-Bewertung',
    'Erkläre DeFi-Strategie',
    'Generiere Markt-Report',
    'Smart Contract Template',
    'Tokenomics Erklärung',
    'Trading-Strategie Memo',
  ];

  final List<Map<String, dynamic>> _aiResponses = [];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _typingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
    // Starte mit Template
    _loadTemplate(_selectedTemplate);
    // Auto-save timer
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_docCtrl.text.isNotEmpty) _triggerAutoSave();
    });
    _docCtrl.addListener(_updateCounts);
    // Live BTC-Preis in Market-Memo-Template nachträglich einsetzen
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ex = context.read<ExchangeService>();
      await ex.initialize();
      if (!mounted) return;
      final btc = ex.getPrice('BTC');
      if (btc > 0 && _docCtrl.text.contains('67,000')) {
        final btcStr = '\$${(btc / 1000).toStringAsFixed(1)}K';
        final updated = _docCtrl.text.replaceFirst(
          r'$67,000', btcStr,
        );
        _docCtrl.value = TextEditingValue(
          text: updated,
          selection: TextSelection.collapsed(
              offset: _docCtrl.selection.baseOffset.clamp(0, updated.length)),
        );
      }
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _typingCtrl.dispose();
    _docCtrl.dispose();
    _promptCtrl.dispose();
    _scrollCtrl.dispose();
    _genTimer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _updateCounts() {
    final text = _docCtrl.text;
    setState(() {
      _charCount = text.length;
      _wordCount = text.isEmpty
          ? 0
          : text.trim().split(RegExp(r'\s+')).length;
    });
  }

  void _loadTemplate(String name) {
    final tmpl = _templates[name] ?? '';
    _docCtrl.text = tmpl;
    _updateCounts();
  }

  void _triggerAutoSave() {
    setState(() {
      _isSaving = true;
      _lastSaved = 'Gerade eben';
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isSaving = false);
    });
  }

  void _runAIGenerate() {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;
    setState(() {
      _isGenerating = true;
      _genProgress = 0.0;
      _aiStatus = 'GENERIERT...';
    });
    _genTimer = Timer.periodic(const Duration(milliseconds: 60), (t) {
      setState(() => _genProgress += 0.025);
      if (_genProgress >= 1.0) {
        t.cancel();
        final response = _buildAIResponse(prompt);
        setState(() {
          _isGenerating = false;
          _aiStatus = 'BEREIT';
          _genProgress = 0.0;
          _aiResponses.insert(0, {
            'prompt': prompt,
            'response': response,
            'time': _timeNow(),
          });
          // Insert into document
          final cursor = _docCtrl.selection.baseOffset;
          final txt = _docCtrl.text;
          final insert = '\n\n## AI-Generiert: $prompt\n$response\n';
          if (cursor >= 0 && cursor <= txt.length) {
            _docCtrl.text = txt.substring(0, cursor) + insert + txt.substring(cursor);
          } else {
            _docCtrl.text = txt + insert;
          }
          _updateCounts();
          _promptCtrl.clear();
        });
      }
    });
  }

  String _buildAIResponse(String prompt) {
    final rng = Random();
    final responses = [
      'Die aktuelle Marktlage zeigt ein bullisches Muster mit starkem Support bei den wichtigsten Fibonacci-Levels. Das RSI-Indikator deutet auf eine Fortsetzung des Aufwärtstrends hin. Volumenanalyse bestätigt institutionelles Interesse.',
      'Basierend auf der TR2 Quantum-Analyse wurden folgende Schlüsselfaktoren identifiziert: (1) Makroökonomische Stabilität, (2) Positiver On-Chain-Daten-Flow, (3) Technischer Ausbruch über Widerstandszone. Empfehlung: KAUFEN mit Stopp bei -8%.',
      'Das HQMLL Neural Network hat 47 Marktmuster analysiert und eine 73,4%ige Wahrscheinlichkeit für eine bullische Bewegung innerhalb der nächsten 72 Stunden berechnet. Kritische Preisniveaus sind zu beachten.',
      'Quantumbasierte Sentiment-Analyse ergibt einen Gesamtscore von 7.8/10 (Bullish). Social-Media-Daten, On-Chain-Metriken und institutionelle Flow-Daten werden kombiniert ausgewertet. Risikostufe: MITTEL.',
      'Die QEMMA-Token-Ökonomie zeigt gesunde Metriken: Deflationäre Mechanismen aktiv, Mining-Rate optimiert, Liquiditätspools stabil. TR2 Empfehlung: Akkumulationsphase läuft.',
    ];
    return responses[rng.nextInt(responses.length)];
  }

  static String _today() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}.${n.month.toString().padLeft(2, '0')}.${n.year}';
  }

  static String _timeNow() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040A14),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────
  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF040A14),
              Color.lerp(const Color(0xFF0D2137), const Color(0xFF1A0A2E),
                  _glowAnim.value)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(
            bottom: BorderSide(
              color: Color.lerp(const Color(0xFFAA44FF), const Color(0xFF00AAFF),
                  _glowAnim.value)!
                  .withValues(alpha: 0.4),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Color.lerp(const Color(0xFFAA44FF), const Color(0xFF00AAFF),
                      _glowAnim.value)!,
                  const Color(0xFF1A0028),
                ]),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFAA44FF).withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HQMLL WRITER',
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'AI DOCUMENT INTELLIGENCE v15.0',
                  style: GoogleFonts.spaceMono(
                    color: Color.lerp(const Color(0xFFAA44FF), const Color(0xFF00AAFF),
                        _glowAnim.value),
                    fontSize: 9,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$_wordCount Wörter',
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFF00FF88),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isSaving ? '💾 Speichert...' : '✓ $_lastSaved',
                  style: GoogleFonts.spaceMono(
                    color: _isSaving
                        ? const Color(0xFFFFAA00)
                        : const Color(0xFF7AAFC8),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB BAR ───────────────────────────────────────────────
  Widget _buildTabBar() {
    final tabs = [
      ('EDITOR', Icons.edit_outlined),
      ('DOKUMENTE', Icons.folder_outlined),
      ('AI FORGE', Icons.auto_awesome_outlined),
      ('VORLAGEN', Icons.article_outlined),
    ];
    return Container(
      height: 46,
      color: const Color(0xFF040A14),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == _activeTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: active
                      ? const LinearGradient(
                          colors: [Color(0xFFAA44FF), Color(0xFF00AAFF)])
                      : null,
                  border: active
                      ? null
                      : Border.all(color: const Color(0xFF1A3A5C)),
                  color: active ? null : const Color(0xFF0A1628),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[i].$2,
                        size: 13,
                        color: active ? Colors.black : const Color(0xFF7AAFC8)),
                    const SizedBox(width: 4),
                    Text(
                      tabs[i].$1,
                      style: GoogleFonts.spaceMono(
                        color: active ? Colors.black : const Color(0xFF7AAFC8),
                        fontSize: 8,
                        fontWeight:
                            active ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── BODY ──────────────────────────────────────────────────
  Widget _buildBody() {
    switch (_activeTab) {
      case 0:
        return _buildEditor();
      case 1:
        return _buildDocuments();
      case 2:
        return _buildAIForge();
      case 3:
        return _buildTemplates();
      default:
        return _buildEditor();
    }
  }

  // ── TAB 0: EDITOR ─────────────────────────────────────────
  Widget _buildEditor() {
    return Column(
      children: [
        // Toolbar
        _buildEditorToolbar(),
        // AI Quick Input
        _buildAIQuickBar(),
        // Main editor area
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1A3A5C)),
              color: const Color(0xFF060E1A),
            ),
            child: Column(
              children: [
                // Document title bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF1A3A5C)),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined,
                          color: Color(0xFFAA44FF), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        _selectedTemplate,
                        style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$_charCount Zeichen',
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFF3A6080),
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                // Text editor
                Expanded(
                  child: TextField(
                    controller: _docCtrl,
                    scrollController: _scrollCtrl,
                    maxLines: null,
                    expands: true,
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFFCCE8FF),
                      fontSize: 11,
                      height: 1.7,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Beginne zu schreiben oder wähle eine Vorlage...',
                      hintStyle: GoogleFonts.spaceMono(
                        color: const Color(0xFF3A6080),
                        fontSize: 11,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Status bar
        _buildStatusBar(),
      ],
    );
  }

  Widget _buildEditorToolbar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFF0A1628),
      child: Row(
        children: [
          _toolBtn(Icons.format_bold, () => _insertMarkdown('**', '**')),
          _toolBtn(Icons.format_italic, () => _insertMarkdown('*', '*')),
          _toolBtn(Icons.format_list_bulleted, () => _insertLine('- ')),
          _toolBtn(Icons.format_list_numbered, () => _insertLine('1. ')),
          _toolBtn(Icons.title, () => _insertLine('## ')),
          const VerticalDivider(color: Color(0xFF1A3A5C), width: 16),
          _toolBtn(Icons.content_copy, () {
            Clipboard.setData(ClipboardData(text: _docCtrl.text));
            _showSnack('Kopiert!', const Color(0xFF00FF88));
          }),
          _toolBtn(Icons.delete_outline, () {
            _docCtrl.clear();
            _updateCounts();
          }),
          const Spacer(),
          // Style selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF1A3A5C)),
            ),
            child: DropdownButton<String>(
              value: _selectedStyle,
              isDense: true,
              underline: const SizedBox(),
              style: GoogleFonts.spaceMono(
                color: const Color(0xFF00AAFF),
                fontSize: 9,
              ),
              dropdownColor: const Color(0xFF0A1628),
              items: ['Professional', 'Technical', 'Casual', 'Legal']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedStyle = v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 16, color: const Color(0xFF7AAFC8)),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
    );
  }

  void _insertMarkdown(String before, String after) {
    final sel = _docCtrl.selection;
    final txt = _docCtrl.text;
    if (sel.isValid && !sel.isCollapsed) {
      final selected = txt.substring(sel.start, sel.end);
      _docCtrl.text = txt.substring(0, sel.start) +
          before + selected + after +
          txt.substring(sel.end);
    } else {
      _docCtrl.text = txt + before + 'Text' + after;
    }
    _updateCounts();
  }

  void _insertLine(String prefix) {
    final txt = _docCtrl.text;
    _docCtrl.text = '$txt\n$prefix';
    _updateCounts();
  }

  Widget _buildAIQuickBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFAA44FF), Color(0xFF00AAFF)],
              ),
            ),
            child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _promptCtrl,
              style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 11),
              decoration: InputDecoration(
                hintText: 'AI-Prompt eingeben...',
                hintStyle: GoogleFonts.spaceMono(
                    color: const Color(0xFF3A6080), fontSize: 11),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
              onSubmitted: (_) => _runAIGenerate(),
            ),
          ),
          if (_isGenerating)
            SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _genProgress,
                      backgroundColor: const Color(0xFF1A3A5C),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFFAA44FF)),
                      minHeight: 3,
                    ),
                  ),
                  Text(
                    '${(_genProgress * 100).toInt()}%',
                    style: GoogleFonts.spaceMono(
                        color: const Color(0xFFAA44FF), fontSize: 7),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: _runAIGenerate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFAA44FF), Color(0xFF00AAFF)],
                  ),
                ),
                child: Text(
                  'GENERIEREN',
                  style: GoogleFonts.spaceMono(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: const Color(0xFF0A1628),
      child: Row(
        children: [
          _statusChip(Icons.psychology, _aiStatus,
              _isGenerating ? const Color(0xFFAA44FF) : const Color(0xFF00FF88)),
          const SizedBox(width: 12),
          _statusChip(Icons.text_fields, '$_wordCount Wörter',
              const Color(0xFF7AAFC8)),
          const SizedBox(width: 12),
          _statusChip(Icons.style, _selectedStyle, const Color(0xFF7AAFC8)),
          const Spacer(),
          _statusChip(
              Icons.save_outlined,
              _isSaving ? 'Speichert...' : 'Auto-Save aktiv',
              _isSaving ? const Color(0xFFFFAA00) : const Color(0xFF00FF88)),
        ],
      ),
    );
  }

  Widget _statusChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: GoogleFonts.spaceMono(color: color, fontSize: 8)),
      ],
    );
  }

  // ── TAB 1: DOKUMENTE ──────────────────────────────────────
  Widget _buildDocuments() {
    final pinned = _savedDocs.where((d) => d['pinned'] == true).toList();
    final rest = _savedDocs.where((d) => d['pinned'] != true).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          children: [
            Text('MEINE DOKUMENTE',
                style: GoogleFonts.rajdhani(
                  color: const Color(0xFF00AAFF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                )),
            const Spacer(),
            GestureDetector(
              onTap: () {
                setState(() => _activeTab = 0);
                _loadTemplate(_selectedTemplate);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                      colors: [Color(0xFFAA44FF), Color(0xFF00AAFF)]),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text('NEU',
                        style: GoogleFonts.spaceMono(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (pinned.isNotEmpty) ...[
          Text('📌 ANGEPINNT',
              style: GoogleFonts.spaceMono(
                  color: const Color(0xFF7AAFC8), fontSize: 9)),
          const SizedBox(height: 8),
          ...pinned.map((d) => _buildDocCard(d, true)),
          const SizedBox(height: 16),
          Text('📄 ALLE DOKUMENTE',
              style: GoogleFonts.spaceMono(
                  color: const Color(0xFF7AAFC8), fontSize: 9)),
          const SizedBox(height: 8),
        ],
        ...rest.map((d) => _buildDocCard(d, false)),
      ],
    );
  }

  Widget _buildDocCard(Map<String, dynamic> doc, bool isPinned) {
    return GestureDetector(
      onTap: () {
        _selectedTemplate = doc['type'];
        _loadTemplate(doc['type']);
        setState(() => _activeTab = 0);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (doc['color'] as Color).withValues(alpha: 0.3),
          ),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0A1628),
              (doc['color'] as Color).withValues(alpha: 0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: (doc['color'] as Color).withValues(alpha: 0.15),
              ),
              child: Icon(
                doc['type'] == 'Smart Contract'
                    ? Icons.code
                    : Icons.description_outlined,
                color: doc['color'] as Color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc['title'],
                    style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${doc['type']} • ${doc['words']} Wörter',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF7AAFC8),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  doc['modified'],
                  style: GoogleFonts.spaceMono(
                      color: const Color(0xFF3A6080), fontSize: 8),
                ),
                if (isPinned)
                  Text('📌',
                      style: const TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB 2: AI FORGE ───────────────────────────────────────
  Widget _buildAIForge() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('AI SCHREIB-ASSISTENT',
            style: GoogleFonts.rajdhani(
              color: const Color(0xFFAA44FF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            )),
        const SizedBox(height: 4),
        Text('HQMLL TR2 Neural Engine • Powered by Quantum Reasoning',
            style: GoogleFonts.spaceMono(
                color: const Color(0xFF7AAFC8), fontSize: 9)),
        const SizedBox(height: 16),
        // Quick prompts
        Text('SCHNELL-PROMPTS',
            style: GoogleFonts.spaceMono(
                color: const Color(0xFF7AAFC8), fontSize: 9)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickPrompts.map((p) {
            return GestureDetector(
              onTap: () {
                _promptCtrl.text = p;
                setState(() => _activeTab = 0);
                _runAIGenerate();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: const Color(0xFFAA44FF).withValues(alpha: 0.4)),
                  color: const Color(0xFFAA44FF).withValues(alpha: 0.08),
                ),
                child: Text(p,
                    style: GoogleFonts.spaceMono(
                        color: const Color(0xFFCC88FF), fontSize: 10)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        // AI history
        if (_aiResponses.isNotEmpty) ...[
          Text('AI VERLAUF',
              style: GoogleFonts.spaceMono(
                  color: const Color(0xFF7AAFC8), fontSize: 9)),
          const SizedBox(height: 8),
          ..._aiResponses.map((r) => _buildAIResponseCard(r)),
        ] else
          _buildAIEmptyState(),
        const SizedBox(height: 20),
        // AI capabilities
        _buildAICapabilities(),
      ],
    );
  }

  Widget _buildAIResponseCard(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFFAA44FF).withValues(alpha: 0.3)),
        color: const Color(0xFF0A0818),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: Color(0xFFAA44FF), size: 12),
              const SizedBox(width: 6),
              Text(r['prompt'],
                  style: GoogleFonts.spaceMono(
                      color: const Color(0xFFAA44FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(r['time'],
                  style: GoogleFonts.spaceMono(
                      color: const Color(0xFF3A6080), fontSize: 8)),
            ],
          ),
          const SizedBox(height: 8),
          Text(r['response'],
              style: GoogleFonts.spaceMono(
                  color: const Color(0xFFCCE8FF), fontSize: 10, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildAIEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFFAA44FF).withValues(alpha: 0.2)),
        color: const Color(0xFF0A0818),
      ),
      child: Column(
        children: [
          const Icon(Icons.psychology_outlined,
              color: Color(0xFFAA44FF), size: 40),
          const SizedBox(height: 12),
          Text('HQMLL AI BEREIT',
              style: GoogleFonts.rajdhani(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'Wähle einen Schnell-Prompt oder gib einen eigenen Befehl im Editor ein',
            style: GoogleFonts.spaceMono(
                color: const Color(0xFF7AAFC8), fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAICapabilities() {
    final caps = [
      {'icon': Icons.trending_up, 'label': 'Marktanalyse', 'desc': 'AI-gestützte Technische & Fundamentalanalyse', 'color': const Color(0xFF00FF88)},
      {'icon': Icons.account_balance, 'label': 'Finanz-Reports', 'desc': 'Professionelle Berichte & Dokumente', 'color': const Color(0xFF00AAFF)},
      {'icon': Icons.code, 'label': 'Smart Contracts', 'desc': 'Solidity & Web3 Code-Generierung', 'color': const Color(0xFFFFAA00)},
      {'icon': Icons.translate, 'label': 'Mehrsprachig', 'desc': 'DE/EN/FR automatische Übersetzung', 'color': const Color(0xFFAA44FF)},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI FÄHIGKEITEN',
            style: GoogleFonts.spaceMono(
                color: const Color(0xFF7AAFC8), fontSize: 9)),
        const SizedBox(height: 8),
        ...caps.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: (c['color'] as Color).withValues(alpha: 0.2)),
                color: (c['color'] as Color).withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  Icon(c['icon'] as IconData,
                      color: c['color'] as Color, size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['label'] as String,
                          style: GoogleFonts.rajdhani(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      Text(c['desc'] as String,
                          style: GoogleFonts.spaceMono(
                              color: const Color(0xFF7AAFC8), fontSize: 9)),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ── TAB 3: VORLAGEN ───────────────────────────────────────
  Widget _buildTemplates() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('DOKUMENT-VORLAGEN',
            style: GoogleFonts.rajdhani(
              color: const Color(0xFF00AAFF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            )),
        const SizedBox(height: 4),
        Text('Professionelle Vorlagen für Trading & Crypto',
            style: GoogleFonts.spaceMono(
                color: const Color(0xFF7AAFC8), fontSize: 9)),
        const SizedBox(height: 16),
        ..._templates.entries.map((e) => _buildTemplateCard(e.key, e.value)),
      ],
    );
  }

  Widget _buildTemplateCard(String name, String content) {
    final colors = {
      'Trading Report': const Color(0xFF00FF88),
      'Whitepaper': const Color(0xFFAA44FF),
      'Market Memo': const Color(0xFF00AAFF),
      'Investment Thesis': const Color(0xFFFFAA00),
      'Smart Contract': const Color(0xFFFF6600),
    };
    final icons = {
      'Trading Report': Icons.candlestick_chart,
      'Whitepaper': Icons.article,
      'Market Memo': Icons.email_outlined,
      'Investment Thesis': Icons.insights,
      'Smart Contract': Icons.code,
    };
    final color = colors[name] ?? const Color(0xFF00AAFF);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTemplate = name;
          _activeTab = 0;
        });
        _loadTemplate(name);
        _showSnack('Vorlage "$name" geladen', color);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          gradient: LinearGradient(
            colors: [const Color(0xFF0A1628), color.withValues(alpha: 0.06)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(icons[name] ?? Icons.article_outlined,
                  color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.rajdhani(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      )),
                  Text(
                    '${content.split('\n').length} Zeilen • Professionelle Vorlage',
                    style: GoogleFonts.spaceMono(
                        color: const Color(0xFF7AAFC8), fontSize: 9),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: color.withValues(alpha: 0.6), size: 14),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.spaceMono(
              color: Colors.black, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    ));
  }
}
