// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/exchange_service.dart';

// ═══════════════════════════════════════════════════════════
//  INTELLIGENCE MODULE — GEHEIMDIENST SECURE ENCRYPTION
//  Quantum Trader AI System v14.0
// ═══════════════════════════════════════════════════════════

class IntelligenceScreen extends StatefulWidget {
  const IntelligenceScreen({super.key});
  @override
  State<IntelligenceScreen> createState() => _IntelligenceScreenState();
}

class _IntelligenceScreenState extends State<IntelligenceScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _scanAnim; // ignore: unused_field
  late Animation<double> _pulseAnim;

  int _activeTab = 0;
  bool _isEncrypting = false;
  String _inputText = '';
  String _keyText = '';
  bool _isDecrypting = false;
  bool _vaultLocked = true;
  String _encryptedOutput = '';
  String _decryptedOutput = '';
  double _encryptProgress = 0.0;
  Timer? _progressTimer;

  final TextEditingController _inputCtrl = TextEditingController();
  final TextEditingController _keyCtrl = TextEditingController();

  // Intelligence Operations Log
  final List<Map<String, dynamic>> _opLog = [
    {'time': '09:42:17', 'op': 'KEY_GEN', 'status': 'SUCCESS', 'detail': 'RSA-4096 Schlüsselpaar generiert', 'level': 'CLASSIFIED'},
    {'time': '09:38:55', 'op': 'ENCRYPT', 'status': 'SUCCESS', 'detail': 'AES-256-GCM Datei verschlüsselt (2.4 MB)', 'level': 'TOP SECRET'},
    {'time': '09:35:12', 'op': 'VERIFY', 'status': 'SUCCESS', 'detail': 'Digitale Signatur verifiziert', 'level': 'SECRET'},
    {'time': '09:31:44', 'op': 'TUNNEL', 'status': 'ACTIVE', 'detail': 'Quantum-Tunnel Verbindung aktiv', 'level': 'CONFIDENTIAL'},
    {'time': '09:28:03', 'op': 'SCAN', 'status': 'ALERT', 'detail': 'Anomalie erkannt: Unbekannte IP 192.168.1.105', 'level': 'URGENT'},
    {'time': '09:22:31', 'op': 'HASH', 'status': 'SUCCESS', 'detail': 'SHA-3-512 Hash erstellt', 'level': 'RESTRICTED'},
    {'time': '09:18:07', 'op': 'AUTH', 'status': 'FAILED', 'detail': '3 fehlgeschlagene Login-Versuche', 'level': 'ALERT'},
    {'time': '09:14:50', 'op': 'BACKUP', 'status': 'SUCCESS', 'detail': 'Verschlüsseltes Backup erstellt', 'level': 'SECRET'},
  ];

  // Secure Agents
  final List<Map<String, dynamic>> _agents = [
    {
      'name': 'AGENT ALPHA',
      'codename': 'QUANTUM-7',
      'status': 'ACTIVE',
      'clearance': 'LEVEL 5',
      'location': 'Frankfurt DEX Node',
      'lastSeen': '2 Min. ago',
      'encrypted': true,
      'tasks': 3,
    },
    {
      'name': 'AGENT BETA',
      'codename': 'CIPHER-3',
      'status': 'STANDBY',
      'clearance': 'LEVEL 4',
      'location': 'London Exchange Hub',
      'lastSeen': '15 Min. ago',
      'encrypted': true,
      'tasks': 1,
    },
    {
      'name': 'AGENT GAMMA',
      'codename': 'NEXUS-9',
      'status': 'OFFLINE',
      'clearance': 'LEVEL 3',
      'location': 'Unbekannt',
      'lastSeen': '2 Std. ago',
      'encrypted': false,
      'tasks': 0,
    },
    {
      'name': 'AGENT DELTA',
      'codename': 'GHOST-1',
      'status': 'ACTIVE',
      'clearance': 'LEVEL 5',
      'location': 'Tokyo Liquidity Pool',
      'lastSeen': '5 Min. ago',
      'encrypted': true,
      'tasks': 7,
    },
  ];

  // Encryption Algorithms
  final List<Map<String, dynamic>> _algorithms = [
    {'name': 'AES-256-GCM', 'type': 'Symmetric', 'keyBits': 256, 'active': true, 'rating': 'QUANTUM-SAFE'},
    {'name': 'RSA-4096', 'type': 'Asymmetric', 'keyBits': 4096, 'active': true, 'rating': 'HIGH'},
    {'name': 'ChaCha20', 'type': 'Stream Cipher', 'keyBits': 256, 'active': false, 'rating': 'QUANTUM-SAFE'},
    {'name': 'Kyber-1024', 'type': 'Post-Quantum', 'keyBits': 1024, 'active': true, 'rating': 'ULTRA'},
    {'name': 'CRYSTALS-Dilithium', 'type': 'PQ Signature', 'keyBits': 2048, 'active': false, 'rating': 'ULTRA'},
    {'name': 'SHA-3-512', 'type': 'Hash', 'keyBits': 512, 'active': true, 'rating': 'HIGH'},
  ];

  String _selectedAlgo = 'AES-256-GCM';

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _scanAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_scanCtrl);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _progressTimer?.cancel();
    _inputCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  void _simulateEncrypt() {
    if (_inputCtrl.text.isEmpty) return;
    setState(() {
      _isEncrypting = true;
      _encryptProgress = 0.0;
      _encryptedOutput = '';
    });
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      setState(() {
        _encryptProgress += 0.02;
        if (_encryptProgress >= 1.0) {
          _encryptProgress = 1.0;
          _isEncrypting = false;
          _encryptedOutput = _generateFakeEncrypted(_inputCtrl.text);
          t.cancel();
        }
      });
    });
  }

  void _simulateDecrypt() {
    if (_encryptedOutput.isEmpty) return;
    setState(() {
      _isDecrypting = true;
      _encryptProgress = 0.0;
    });
    _progressTimer = Timer.periodic(const Duration(milliseconds: 40), (t) {
      setState(() {
        _encryptProgress += 0.025;
        if (_encryptProgress >= 1.0) {
          _encryptProgress = 1.0;
          _isDecrypting = false;
          _decryptedOutput = _inputCtrl.text;
          t.cancel();
        }
      });
    });
  }

  String _generateFakeEncrypted(String input) {
    final rng = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
    final sb = StringBuffer();
    sb.write('$_selectedAlgo::\$2y\$12\$');
    for (int i = 0; i < 80 + input.length * 2; i++) {
      if (i > 0 && i % 32 == 0) sb.write('\n');
      sb.write(chars[rng.nextInt(chars.length)]);
    }
    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ex = context.watch<ExchangeService>();
    return Scaffold(
      backgroundColor: const Color(0xFF040A14),
      body: Column(
        children: [
          _buildHeader(ex),
          _buildTabBar(),
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ExchangeService ex) {
    final btcPrice = ex.getPrice('BTC');
    final ethPrice = ex.getPrice('ETH');
    final isLive = ex.getTick('BTC')?.isLive ?? false;
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (ctx, _) => Container(
        padding: const EdgeInsets.fromLTRB(16, 52, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF040A14),
              const Color(0xFF0A1628),
              Color.lerp(const Color(0xFF0D2137), const Color(0xFF12304A), _glowAnim.value)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(
            bottom: BorderSide(
              color: Color.lerp(const Color(0xFF00FF88), const Color(0xFF00AAFF), _glowAnim.value)!.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color.lerp(const Color(0xFF00FF88), const Color(0xFF00AAFF), _glowAnim.value)!,
                    const Color(0xFF001020),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.lerp(const Color(0xFF00FF88), const Color(0xFF00AAFF), _glowAnim.value)!.withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INTELLIGENCE MODULE',
                  style: GoogleFonts.spaceMono(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Row(children: [
                  Text(
                    btcPrice > 0
                        ? 'BTC \$${btcPrice.toStringAsFixed(0)}  ETH \$${ethPrice.toStringAsFixed(0)}'
                        : 'GEHEIMDIENST • SECURE ENCRYPTION v14.0',
                    style: GoogleFonts.spaceMono(
                      color: Color.lerp(const Color(0xFF00FF88), const Color(0xFF00AAFF), _glowAnim.value),
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (isLive) ...[const SizedBox(width: 6),
                    Container(width: 5, height: 5,
                      decoration: const BoxDecoration(shape: BoxShape.circle,
                        color: Color(0xFF00FF88),
                        boxShadow: [BoxShadow(color: Color(0x9900FF88), blurRadius: 5)])),
                  ],
                ]),
              ],
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (c, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: _pulseAnim.value * 0.8)),
                  borderRadius: BorderRadius.circular(4),
                  color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00FF88).withValues(alpha: _pulseAnim.value),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'SECURE',
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFF00FF88),
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['ENCRYPT', 'AGENTS', 'ALGORITHMS', 'OP-LOG', 'VAULT'];
    return Container(
      height: 44,
      color: const Color(0xFF040A14),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: tabs.length,
        itemBuilder: (ctx, i) {
          final active = i == _activeTab;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: active
                    ? const LinearGradient(colors: [Color(0xFF00FF88), Color(0xFF00AAFF)])
                    : null,
                border: active
                    ? null
                    : Border.all(color: const Color(0xFF1A3A5C)),
                color: active ? null : const Color(0xFF0A1628),
              ),
              child: Text(
                tabs[i],
                style: GoogleFonts.spaceMono(
                  color: active ? Colors.black : const Color(0xFF7AAFC8),
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildEncryptTab();
      case 1:
        return _buildAgentsTab();
      case 2:
        return _buildAlgorithmsTab();
      case 3:
        return _buildOpLogTab();
      case 4:
        return _buildVaultTab();
      default:
        return _buildEncryptTab();
    }
  }

  // ── TAB 0: ENCRYPT / DECRYPT ─────────────────────────────
  Widget _buildEncryptTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Algorithm Selector
          _sectionTitle('ALGORITHMUS AUSWÄHLEN'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _algorithms.map((a) {
                final sel = a['name'] == _selectedAlgo;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAlgo = a['name']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: sel ? const Color(0xFF00FF88) : const Color(0xFF1A3A5C),
                        width: sel ? 1.5 : 1,
                      ),
                      color: sel
                          ? const Color(0xFF00FF88).withValues(alpha: 0.1)
                          : const Color(0xFF0A1628),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a['name'],
                          style: GoogleFonts.spaceMono(
                            color: sel ? const Color(0xFF00FF88) : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          a['type'],
                          style: GoogleFonts.spaceMono(
                            color: const Color(0xFF7AAFC8),
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: _ratingColor(a['rating']).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            a['rating'],
                            style: TextStyle(
                              color: _ratingColor(a['rating']),
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Input
          _sectionTitle('KLARTEXT / NACHRICHT'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1A3A5C)),
              color: const Color(0xFF0A1628),
            ),
            child: TextField(
              controller: _inputCtrl,
              maxLines: 5,
              style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Geheime Nachricht oder Daten eingeben...',
                hintStyle: GoogleFonts.spaceMono(
                  color: const Color(0xFF3A6080),
                  fontSize: 12,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (v) => setState(() => _inputText = v),
            ),
          ),
          const SizedBox(height: 12),

          // Encryption Key
          _sectionTitle('VERSCHLÜSSELUNGSSCHLÜSSEL'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1A3A5C)),
              color: const Color(0xFF0A1628),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keyCtrl,
                    obscureText: true,
                    style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Schlüssel eingeben oder generieren...',
                      hintStyle: GoogleFonts.spaceMono(
                        color: const Color(0xFF3A6080),
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onChanged: (v) => setState(() => _keyText = v),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final rng = Random();
                    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
                    final key = String.fromCharCodes(
                      List.generate(32, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
                    );
                    _keyCtrl.text = key;
                    setState(() => _keyText = key);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00FF88), Color(0xFF00AAFF)],
                      ),
                    ),
                    child: Text(
                      'GEN',
                      style: GoogleFonts.spaceMono(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isEncrypting ? null : _simulateEncrypt,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: _isEncrypting
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF00FF88), Color(0xFF00BBAA)],
                            ),
                      color: _isEncrypting ? const Color(0xFF1A3A5C) : null,
                    ),
                    child: Center(
                      child: _isEncrypting
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00FF88)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'VERSCHLÜSSLE...',
                                  style: GoogleFonts.spaceMono(
                                    color: const Color(0xFF00FF88),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              '🔒 VERSCHLÜSSELN',
                              style: GoogleFonts.spaceMono(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _isDecrypting ? null : _simulateDecrypt,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isDecrypting ? const Color(0xFF1A3A5C) : const Color(0xFF00AAFF),
                      ),
                      color: _isDecrypting
                          ? const Color(0xFF0A1628)
                          : const Color(0xFF00AAFF).withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: _isDecrypting
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00AAFF)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ENTSCHLÜSSLE...',
                                  style: GoogleFonts.spaceMono(
                                    color: const Color(0xFF00AAFF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              '🔓 ENTSCHLÜSSELN',
                              style: GoogleFonts.spaceMono(
                                color: const Color(0xFF00AAFF),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Progress Bar
          if (_isEncrypting || _isDecrypting) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _encryptProgress,
                backgroundColor: const Color(0xFF1A3A5C),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isEncrypting ? const Color(0xFF00FF88) : const Color(0xFF00AAFF),
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(_encryptProgress * 100).toInt()}% — $_selectedAlgo',
              style: GoogleFonts.spaceMono(
                color: const Color(0xFF7AAFC8),
                fontSize: 9,
              ),
            ),
          ],

          // Output
          if (_encryptedOutput.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                _sectionTitle('VERSCHLÜSSELTER OUTPUT'),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _encryptedOutput));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Verschlüsselte Daten kopiert!',
                          style: GoogleFonts.spaceMono(color: Colors.black),
                        ),
                        backgroundColor: const Color(0xFF00FF88),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.copy, color: Color(0xFF00FF88), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'KOPIEREN',
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFF00FF88),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.3)),
                color: const Color(0xFF001A0A),
              ),
              child: Text(
                _encryptedOutput,
                style: GoogleFonts.spaceMono(
                  color: const Color(0xFF00FF88),
                  fontSize: 10,
                  height: 1.6,
                ),
              ),
            ),
          ],

          if (_decryptedOutput.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle('ENTSCHLÜSSELTER OUTPUT'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00AAFF).withValues(alpha: 0.3)),
                color: const Color(0xFF001828),
              ),
              child: Text(
                _decryptedOutput,
                style: GoogleFonts.spaceMono(
                  color: const Color(0xFF00AAFF),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── TAB 1: AGENTS ────────────────────────────────────────
  Widget _buildAgentsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _agents.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('GEHEIMDIENSTLICHE AGENTEN'),
              const SizedBox(height: 4),
              Text(
                'Aktive Operationen • Sicherheitsstufe: TOP SECRET',
                style: GoogleFonts.spaceMono(
                  color: const Color(0xFF7AAFC8),
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }
        final agent = _agents[i - 1];
        return _buildAgentCard(agent);
      },
    );
  }

  Widget _buildAgentCard(Map<String, dynamic> agent) {
    Color statusColor;
    switch (agent['status']) {
      case 'ACTIVE':
        statusColor = const Color(0xFF00FF88);
        break;
      case 'STANDBY':
        statusColor = const Color(0xFFFFAA00);
        break;
      default:
        statusColor = const Color(0xFF666666);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: agent['status'] == 'ACTIVE'
              ? const Color(0xFF00FF88).withValues(alpha: 0.3)
              : const Color(0xFF1A3A5C),
        ),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A1628),
            agent['status'] == 'ACTIVE'
                ? const Color(0xFF00FF88).withValues(alpha: 0.05)
                : const Color(0xFF0A1628),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.15),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Icon(Icons.person_outlined, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agent['name'],
                    style: GoogleFonts.spaceMono(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'CODENAME: ${agent['codename']}',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF7AAFC8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: statusColor.withValues(alpha: 0.15),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  agent['status'],
                  style: GoogleFonts.spaceMono(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _agentChip(Icons.security, agent['clearance'], const Color(0xFFFFAA00)),
              _agentChip(Icons.location_on_outlined, agent['location'], const Color(0xFF7AAFC8)),
              _agentChip(Icons.access_time, agent['lastSeen'], const Color(0xFF666666)),
              _agentChip(
                agent['encrypted'] ? Icons.lock : Icons.lock_open,
                agent['encrypted'] ? 'ENCRYPTED' : 'UNENCRYPTED',
                agent['encrypted'] ? const Color(0xFF00FF88) : const Color(0xFFFF4466),
              ),
              if (agent['tasks'] > 0)
                _agentChip(Icons.task_alt, '${agent['tasks']} Tasks', const Color(0xFF00AAFF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _agentChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.spaceMono(color: color, fontSize: 9),
        ),
      ],
    );
  }

  // ── TAB 2: ALGORITHMS ────────────────────────────────────
  Widget _buildAlgorithmsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('KRYPTOGRAPHIE-ALGORITHMEN'),
        const SizedBox(height: 4),
        Text(
          'Post-Quantum sichere Verschlüsselung • NIST-zertifiziert',
          style: GoogleFonts.spaceMono(color: const Color(0xFF7AAFC8), fontSize: 9),
        ),
        const SizedBox(height: 16),
        ..._algorithms.map((a) => _buildAlgoCard(a)),
        const SizedBox(height: 20),
        _buildQuantumStrengthMeter(),
      ],
    );
  }

  Widget _buildAlgoCard(Map<String, dynamic> algo) {
    final active = algo['active'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? _ratingColor(algo['rating']).withValues(alpha: 0.4) : const Color(0xFF1A3A5C),
        ),
        color: active
            ? _ratingColor(algo['rating']).withValues(alpha: 0.05)
            : const Color(0xFF0A1628),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _ratingColor(algo['rating']).withValues(alpha: 0.15),
            ),
            child: Center(
              child: Text(
                '${algo['keyBits']}',
                style: GoogleFonts.spaceMono(
                  color: _ratingColor(algo['rating']),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  algo['name'],
                  style: GoogleFonts.spaceMono(
                    color: active ? Colors.white : const Color(0xFF7AAFC8),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${algo['type']} • ${algo['keyBits']}-bit Key',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: _ratingColor(algo['rating']).withValues(alpha: 0.2),
                ),
                child: Text(
                  algo['rating'],
                  style: TextStyle(
                    color: _ratingColor(algo['rating']),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                active ? '● AKTIV' : '○ INAKTIV',
                style: GoogleFonts.spaceMono(
                  color: active ? const Color(0xFF00FF88) : const Color(0xFF666666),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantumStrengthMeter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.3)),
        gradient: const LinearGradient(
          colors: [Color(0xFF001A0A), Color(0xFF001828)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUANTUM-SICHERHEITSSTÄRKE',
            style: GoogleFonts.spaceMono(
              color: const Color(0xFF00FF88),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in [
            {'label': 'Encryption Strength', 'value': 0.95, 'color': const Color(0xFF00FF88)},
            {'label': 'Key Entropy', 'value': 0.88, 'color': const Color(0xFF00AAFF)},
            {'label': 'Post-Quantum Resistance', 'value': 0.72, 'color': const Color(0xFFFFAA00)},
            {'label': 'Side-Channel Protection', 'value': 0.81, 'color': const Color(0xFFAA44FF)},
          ])
            _buildStrengthBar(
              entry['label'] as String,
              entry['value'] as double,
              entry['color'] as Color,
            ),
        ],
      ),
    );
  }

  Widget _buildStrengthBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: GoogleFonts.spaceMono(color: const Color(0xFF7AAFC8), fontSize: 9)),
              const Spacer(),
              Text(
                '${(value * 100).toInt()}%',
                style: GoogleFonts.spaceMono(color: color, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: const Color(0xFF1A3A5C),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 3: OP-LOG ────────────────────────────────────────
  Widget _buildOpLogTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _sectionTitle('OPERATIONS LOG'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: const Color(0xFFFF4466).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFFFF4466).withValues(alpha: 0.4)),
                ),
                child: Text(
                  '1 ALERT',
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFFFF4466),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Terminal header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: const Color(0xFF0A1628),
          child: Row(
            children: [
              Text(
                'TIME     ',
                style: GoogleFonts.spaceMono(color: const Color(0xFF3A6080), fontSize: 9),
              ),
              Text(
                'OPERATION  ',
                style: GoogleFonts.spaceMono(color: const Color(0xFF3A6080), fontSize: 9),
              ),
              Text(
                'STATUS   ',
                style: GoogleFonts.spaceMono(color: const Color(0xFF3A6080), fontSize: 9),
              ),
              Expanded(
                child: Text(
                  'DETAILS',
                  style: GoogleFonts.spaceMono(color: const Color(0xFF3A6080), fontSize: 9),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _opLog.length,
            itemBuilder: (ctx, i) => _buildOpLogRow(_opLog[i], i),
          ),
        ),
      ],
    );
  }

  Widget _buildOpLogRow(Map<String, dynamic> op, int idx) {
    Color statusColor;
    switch (op['status']) {
      case 'SUCCESS':
        statusColor = const Color(0xFF00FF88);
        break;
      case 'ACTIVE':
        statusColor = const Color(0xFF00AAFF);
        break;
      case 'ALERT':
        statusColor = const Color(0xFFFF4466);
        break;
      case 'FAILED':
        statusColor = const Color(0xFFFF6600);
        break;
      default:
        statusColor = const Color(0xFF7AAFC8);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: op['status'] == 'ALERT'
              ? const Color(0xFFFF4466).withValues(alpha: 0.3)
              : const Color(0xFF1A3A5C),
        ),
        color: op['status'] == 'ALERT'
            ? const Color(0xFFFF4466).withValues(alpha: 0.05)
            : const Color(0xFF0A1628),
      ),
      child: Row(
        children: [
          Text(
            op['time'],
            style: GoogleFonts.spaceMono(
              color: const Color(0xFF7AAFC8),
              fontSize: 9,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text(
              op['op'],
              style: GoogleFonts.spaceMono(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: statusColor.withValues(alpha: 0.15),
            ),
            child: Text(
              op['status'],
              style: GoogleFonts.spaceMono(
                color: statusColor,
                fontSize: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              op['detail'],
              style: GoogleFonts.spaceMono(
                color: const Color(0xFF7AAFC8),
                fontSize: 9,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 4: VAULT ─────────────────────────────────────────
  Widget _buildVaultTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Lock/Unlock Vault
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (ctx, _) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (_vaultLocked
                          ? const Color(0xFFFF4466)
                          : const Color(0xFF00FF88))
                      .withValues(alpha: 0.4 + _glowAnim.value * 0.3),
                  width: 1.5,
                ),
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    (_vaultLocked
                            ? const Color(0xFFFF4466)
                            : const Color(0xFF00FF88))
                        .withValues(alpha: 0.08),
                    const Color(0xFF040A14),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _vaultLocked ? Icons.lock : Icons.lock_open,
                    size: 64,
                    color: _vaultLocked ? const Color(0xFFFF4466) : const Color(0xFF00FF88),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _vaultLocked ? 'VAULT GESPERRT' : 'VAULT ENTSPERRT',
                    style: GoogleFonts.spaceMono(
                      color: _vaultLocked ? const Color(0xFFFF4466) : const Color(0xFF00FF88),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _vaultLocked
                        ? 'Quantum-verschlüsselt • AES-256-GCM + Kyber-1024'
                        : 'Zugriff gewährt • Sitzung läuft ab in 15:00',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF7AAFC8),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => setState(() => _vaultLocked = !_vaultLocked),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: _vaultLocked
                              ? [const Color(0xFF00FF88), const Color(0xFF00AAFF)]
                              : [const Color(0xFFFF4466), const Color(0xFFFF8800)],
                        ),
                      ),
                      child: Text(
                        _vaultLocked ? '🔓 VAULT ENTSPERREN' : '🔒 VAULT SPERREN',
                        style: GoogleFonts.spaceMono(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Vault Contents
          if (!_vaultLocked) ...[
            _sectionTitle('VAULT-INHALTE'),
            const SizedBox(height: 12),
            for (final item in [
              {'icon': Icons.key, 'name': 'Master-Schlüssel', 'type': 'RSA-4096 Private Key', 'size': '4.1 KB', 'color': const Color(0xFFFFAA00)},
              {'icon': Icons.wallet, 'name': 'Wallet Seeds', 'type': 'BIP-39 Mnemonics (12)', 'size': '256 B', 'color': const Color(0xFF00FF88)},
              {'icon': Icons.article_outlined, 'name': 'API-Secrets', 'type': 'Encrypted JSON', 'size': '1.2 KB', 'color': const Color(0xFF00AAFF)},
              {'icon': Icons.fingerprint, 'name': 'Biometric Hash', 'type': 'SHA-3-512 Digest', 'size': '64 B', 'color': const Color(0xFFAA44FF)},
              {'icon': Icons.analytics_outlined, 'name': 'Trading Configs', 'type': 'Encrypted YAML', 'size': '8.7 KB', 'color': const Color(0xFF00FFCC)},
            ])
              _buildVaultItem(item),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1A3A5C)),
                color: const Color(0xFF0A1628),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF7AAFC8), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Entsperre den Vault um auf verschlüsselte Inhalte zuzugreifen.',
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFF7AAFC8),
                        fontSize: 10,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVaultItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (item['color'] as Color).withValues(alpha: 0.2)),
        color: (item['color'] as Color).withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (item['color'] as Color).withValues(alpha: 0.15),
            ),
            child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: GoogleFonts.spaceMono(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item['type'] as String,
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFF7AAFC8),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item['size'] as String,
            style: GoogleFonts.spaceMono(
              color: item['color'] as Color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceMono(
        color: const Color(0xFF00AAFF),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'ULTRA':
        return const Color(0xFFAA44FF);
      case 'QUANTUM-SAFE':
        return const Color(0xFF00FF88);
      case 'HIGH':
        return const Color(0xFF00AAFF);
      default:
        return const Color(0xFF7AAFC8);
    }
  }
}
