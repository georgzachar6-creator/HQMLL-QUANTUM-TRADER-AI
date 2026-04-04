/// HQMLL Quantum Trader – SecureVault Screen
/// AES-256 Encryption Module + Geheimdienst UI
/// © 2025 Grigori Saks · HQMLL · Patent-Pending · CONFIDENTIAL
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../services/secure_vault_service.dart';

class SecureVaultScreen extends StatefulWidget {
  const SecureVaultScreen({super.key});
  @override
  State<SecureVaultScreen> createState() => _SecureVaultScreenState();
}

class _SecureVaultScreenState extends State<SecureVaultScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _pulseCtrl;

  final _passwordCtrl = TextEditingController();
  final _labelCtrl    = TextEditingController();
  final _dataCtrl     = TextEditingController();
  bool _obscurePassword = true;
  int _tab = 0; // 0=vault, 1=encrypt, 2=keygen, 3=logs
  String? _decryptedText;
  String? _generatedKey;
  String? _generatedToken;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _scanCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _passwordCtrl.dispose();
    _labelCtrl.dispose();
    _dataCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp    = context.watch<ThemeProvider>();
    final p     = tp.palette;
    final vault = context.watch<SecureVaultService>();

    return Scaffold(
      backgroundColor: p.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(p, vault)),
          if (!vault.vaultUnlocked)
            SliverToBoxAdapter(child: _buildLockScreen(p, vault))
          else ...[
            SliverToBoxAdapter(child: _buildTabBar(p)),
            SliverToBoxAdapter(child: _buildTabContent(p, vault)),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────
  Widget _buildHeader(dynamic p, SecureVaultService vault) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF7B00D4).withValues(alpha: 0.2 + _glowCtrl.value * 0.1),
              p.background,
            ],
          ),
          border: Border(bottom: BorderSide(color: const Color(0xFF7B00D4).withValues(alpha: 0.2))),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _scanCtrl,
              builder: (_, __) => Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF7B00D4).withValues(alpha: 0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B00D4).withValues(alpha: 0.3 + _glowCtrl.value * 0.2),
                      blurRadius: 16, spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  vault.vaultUnlocked ? Icons.lock_open : Icons.lock,
                  color: vault.vaultUnlocked ? const Color(0xFF00E676) : const Color(0xFF7B00D4),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SECURE VAULT',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF7B00D4),
                      fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2.5,
                    ),
                  ),
                  Text('AES-256-CBC · HQMLL Geheimdienst',
                    style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10),
                  ),
                ],
              ),
            ),
            // Stats
            _buildStatChip('ENC', vault.encryptionCount.toString(), const Color(0xFF7B00D4), p),
            const SizedBox(width: 6),
            _buildStatChip('DEC', vault.decryptionCount.toString(), const Color(0xFF00E5FF), p),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, dynamic p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.rajdhani(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7)),
        ],
      ),
    );
  }

  // ── Lock Screen ───────────────────────────────────────
  Widget _buildLockScreen(dynamic p, SecureVaultService vault) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7B00D4).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B00D4).withValues(alpha: 0.1),
            blurRadius: 20, spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7B00D4).withValues(alpha: 0.1 + _pulseCtrl.value * 0.05),
                border: Border.all(
                  color: const Color(0xFF7B00D4).withValues(alpha: 0.4 + _pulseCtrl.value * 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B00D4).withValues(alpha: _pulseCtrl.value * 0.4),
                    blurRadius: 20, spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.lock, color: Color(0xFF7B00D4), size: 36),
            ),
          ),
          const SizedBox(height: 20),
          Text('VAULT GESPERRT',
            style: GoogleFonts.spaceMono(
              color: const Color(0xFF7B00D4),
              fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text('Master-Passwort eingeben um fortzufahren',
            style: GoogleFonts.inter(color: p.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Password Field
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            style: GoogleFonts.robotoMono(color: p.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Master-Passwort...',
              hintStyle: GoogleFonts.inter(color: p.textSecondary, fontSize: 12),
              filled: true,
              fillColor: p.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: const Color(0xFF7B00D4).withValues(alpha: 0.6)),
              ),
              prefixIcon: const Icon(Icons.password, color: Color(0xFF7B00D4), size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: p.textSecondary, size: 18,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            onSubmitted: (_) => _unlockVault(vault),
          ),
          const SizedBox(height: 14),
          // Unlock Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => _unlockVault(vault),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B00D4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isProcessing
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('VAULT ENTSPERREN',
                      style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ),
          const SizedBox(height: 10),
          Text('Hint: Erstes Mal? Neues Passwort wird gespeichert.',
            style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Future<void> _unlockVault(SecureVaultService vault) async {
    if (_passwordCtrl.text.isEmpty) return;
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 800));
    final ok = await vault.initVault(_passwordCtrl.text);
    if (mounted) {
      setState(() => _isProcessing = false);
      _passwordCtrl.clear();
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falsches Passwort!', style: GoogleFonts.spaceMono(fontSize: 11)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Tab Bar ───────────────────────────────────────────
  Widget _buildTabBar(dynamic p) {
    final tabs = ['VAULT', 'VERSCHLÜSSELN', 'KEYGEN', 'PROTOKOLL'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      height: 38,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF7B00D4).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final sel = _tab == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF7B00D4) : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(e.value,
                    style: GoogleFonts.spaceMono(
                      color: sel ? Colors.white : p.textSecondary,
                      fontSize: 7, fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Tab Content ───────────────────────────────────────
  Widget _buildTabContent(dynamic p, SecureVaultService vault) {
    switch (_tab) {
      case 0: return _buildVaultList(p, vault);
      case 1: return _buildEncryptTab(p, vault);
      case 2: return _buildKeygenTab(p, vault);
      case 3: return _buildLogsTab(p, vault);
      default: return const SizedBox();
    }
  }

  // ── Vault List ────────────────────────────────────────
  Widget _buildVaultList(dynamic p, SecureVaultService vault) {
    if (vault.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(children: [
            Icon(Icons.lock_open_outlined, color: p.textSecondary, size: 48),
            const SizedBox(height: 12),
            Text('Vault ist leer', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 13)),
          ]),
        ),
      );
    }
    return Column(
      children: vault.entries.map((entry) => _buildEntryCard(entry, p, vault)).toList(),
    );
  }

  Widget _buildEntryCard(VaultEntry entry, dynamic p, SecureVaultService vault) {
    final typeColors = {
      VaultEntryType.privateKey: const Color(0xFFFF6B35),
      VaultEntryType.seed: const Color(0xFF7B00D4),
      VaultEntryType.apiKey: const Color(0xFF00E5FF),
      VaultEntryType.password: const Color(0xFFFF1744),
      VaultEntryType.document: const Color(0xFF2979FF),
      VaultEntryType.text: const Color(0xFF00E676),
    };
    final color = typeColors[entry.type] ?? p.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(entry.icon, color: color, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.label,
                      style: GoogleFonts.spaceMono(
                        color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('${entry.algorithm} · ${entry.originalSize}B · ${_formatDate(entry.createdAt)}',
                      style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9),
                    ),
                  ],
                ),
              ),
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionBtn(Icons.lock_open_outlined, color, () => _decryptEntry(entry, vault, p)),
                  const SizedBox(width: 6),
                  _actionBtn(Icons.copy_outlined, p.textSecondary, () {
                    Clipboard.setData(ClipboardData(text: entry.encryptedData));
                    _showSnack(context, 'Verschlüsselter Text kopiert', p);
                  }),
                  const SizedBox(width: 6),
                  _actionBtn(Icons.delete_outline, Colors.red.shade700, () {
                    vault.deleteEntry(entry.id);
                  }),
                ],
              ),
            ],
          ),
          // Encrypted preview
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: p.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              entry.encryptedData.length > 60
                  ? '${entry.encryptedData.substring(0, 60)}...'
                  : entry.encryptedData,
              style: GoogleFonts.robotoMono(color: p.textSecondary.withValues(alpha: 0.6), fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: color, size: 14),
      ),
    );
  }

  void _decryptEntry(VaultEntry entry, SecureVaultService vault, dynamic p) {
    final result = vault.decryptEntry(entry);
    if (result.success) {
      setState(() => _decryptedText = result.plaintext);
      _showDecryptDialog(result.plaintext!, p);
    } else {
      _showSnack(context, result.error ?? 'Fehler', p, error: true);
    }
  }

  void _showDecryptDialog(String plaintext, dynamic p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(top: BorderSide(color: const Color(0xFF7B00D4).withValues(alpha: 0.3))),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.lock_open, color: Color(0xFF00E676), size: 18),
              const SizedBox(width: 8),
              Text('ENTSCHLÜSSELT',
                style: GoogleFonts.spaceMono(color: const Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () => Clipboard.setData(ClipboardData(text: plaintext)),
                color: p.textSecondary,
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
              ),
              child: SelectableText(
                plaintext,
                style: GoogleFonts.robotoMono(color: p.textPrimary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            Text('⚠ Nicht speichern · Bildschirm abdecken · In sicherer Umgebung öffnen',
              style: GoogleFonts.inter(color: Colors.orange.shade400, fontSize: 9),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Encrypt Tab ───────────────────────────────────────
  Widget _buildEncryptTab(dynamic p, SecureVaultService vault) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Label
          _inputField(_labelCtrl, 'Bezeichnung (z.B. "ETH Private Key")',
              Icons.label_outline, p),
          const SizedBox(height: 10),
          // Data
          Container(
            decoration: BoxDecoration(
              color: p.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF7B00D4).withValues(alpha: 0.2)),
            ),
            child: TextField(
              controller: _dataCtrl,
              maxLines: 5,
              style: GoogleFonts.robotoMono(color: p.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Geheimtext eingeben...',
                hintStyle: GoogleFonts.inter(color: p.textSecondary, fontSize: 11),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 4, top: 12),
                  child: Icon(Icons.lock, color: const Color(0xFF7B00D4), size: 18),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Encrypt Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_labelCtrl.text.isEmpty || _dataCtrl.text.isEmpty) {
                  _showSnack(context, 'Bezeichnung & Daten eingeben', p, error: true);
                  return;
                }
                final result = vault.encryptText(_dataCtrl.text, _labelCtrl.text);
                if (result.success) {
                  _labelCtrl.clear();
                  _dataCtrl.clear();
                  setState(() => _tab = 0);
                  _showSnack(context, 'Erfolgreich verschlüsselt!', p);
                } else {
                  _showSnack(context, result.error ?? 'Fehler', p, error: true);
                }
              },
              icon: const Icon(Icons.enhanced_encryption, size: 18),
              label: Text('AES-256 VERSCHLÜSSELN',
                style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B00D4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7B00D4).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF7B00D4).withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.info_outline, color: Color(0xFF7B00D4), size: 14),
                  const SizedBox(width: 6),
                  Text('VERSCHLÜSSELUNGSDETAILS',
                    style: GoogleFonts.spaceMono(color: const Color(0xFF7B00D4), fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ]),
                const SizedBox(height: 8),
                ...[
                  'Algorithmus: AES-256-CBC',
                  'Key-Derivation: SHA-256 (doppelt gehasht)',
                  'IV: 128-bit zufällig generiert',
                  'Integrität: HMAC-SHA256',
                  'Padding: PKCS7',
                  'Schlüssel: Master-Passwort deriviert',
                ].map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF00E676), size: 12),
                    const SizedBox(width: 6),
                    Text(t, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
                  ]),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Keygen Tab ────────────────────────────────────────
  Widget _buildKeygenTab(dynamic p, SecureVaultService vault) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text('QUANTUM KEY GENERATOR',
            style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10, letterSpacing: 2),
          ),
          const SizedBox(height: 14),
          // Key size buttons
          Row(
            children: [128, 256, 512].map((bits) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () {
                      final key = vault.generateQuantumKey(bits);
                      setState(() => _generatedKey = key);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B00D4).withValues(alpha: 0.15),
                      foregroundColor: const Color(0xFF7B00D4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFF7B00D4), width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('$bits-BIT',
                      style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          if (_generatedKey != null) _buildKeyDisplay(_generatedKey!, 'QUANTUM KEY', const Color(0xFF7B00D4), p),
          const SizedBox(height: 10),
          // HQMLL Token
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final token = vault.generateHQMLLToken();
                setState(() => _generatedToken = token);
              },
              icon: const Icon(Icons.diamond_outlined, size: 16),
              label: Text('HQMLL-TOKEN GENERIEREN',
                style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9100).withValues(alpha: 0.15),
                foregroundColor: const Color(0xFFFF9100),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFFF9100), width: 1),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_generatedToken != null) ...[
            const SizedBox(height: 10),
            _buildKeyDisplay(_generatedToken!, 'HQMLL TOKEN', const Color(0xFFFF9100), p),
          ],
          const SizedBox(height: 16),
          // Key types info
          _buildKeyTypesGrid(p),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildKeyDisplay(String key, String label, Color color, dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label, style: GoogleFonts.spaceMono(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: key));
                _showSnack(context, '$label kopiert!', p);
              },
              child: Icon(Icons.copy, color: p.textSecondary, size: 16),
            ),
          ]),
          const SizedBox(height: 6),
          SelectableText(
            key,
            style: GoogleFonts.robotoMono(color: p.textPrimary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyTypesGrid(dynamic p) {
    final types = [
      ('AES-256', 'Symmetric', const Color(0xFF7B00D4)),
      ('RSA-4096', 'Asymmetric', const Color(0xFF2979FF)),
      ('ED25519', 'Wallet Keys', const Color(0xFF00E676)),
      ('ECDSA', 'Signatures', const Color(0xFFFF9100)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('UNTERSTÜTZTE ALGORITHMEN',
          style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9, letterSpacing: 2),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3,
          children: types.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: t.$3.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.$3.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: t.$3)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(t.$1, style: GoogleFonts.spaceMono(color: t.$3, fontSize: 9, fontWeight: FontWeight.bold)),
                    Text(t.$2, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 8)),
                  ],
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  // ── Logs Tab ──────────────────────────────────────────
  Widget _buildLogsTab(dynamic p, SecureVaultService vault) {
    if (vault.logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('Keine Protokolleinträge', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 12)),
        ),
      );
    }
    return Column(
      children: vault.logs.map((log) {
        final color = log.success ? const Color(0xFF00E676) : Colors.red.shade400;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Row(
            children: [
              Icon(log.success ? Icons.check_circle_outline : Icons.error_outline,
                color: color, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.message,
                      style: GoogleFonts.inter(color: p.textPrimary, fontSize: 11),
                    ),
                    Text(_formatDate(log.timestamp),
                      style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(log.type,
                  style: GoogleFonts.spaceMono(color: color, fontSize: 7, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Helpers ───────────────────────────────────────────
  Widget _inputField(TextEditingController ctrl, String hint, IconData icon, dynamic p) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.inter(color: p.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: p.textSecondary, fontSize: 11),
        filled: true,
        fillColor: p.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color(0xFF7B00D4).withValues(alpha: 0.6)),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF7B00D4), size: 18),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2,'0')}.${dt.month.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  void _showSnack(BuildContext ctx, String msg, dynamic p, {bool error = false}) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.spaceMono(fontSize: 11)),
      backgroundColor: error ? Colors.red.shade700 : const Color(0xFF7B00D4),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }
}
