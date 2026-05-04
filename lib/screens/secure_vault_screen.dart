// ============================================================
// SECURE VAULT SCREEN v2 – Quantum Security Hub
// Hardware Wallet, Multi-Sig, Encryption, Biometric Auth
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';

class SecureVaultScreen extends StatefulWidget {
  const SecureVaultScreen({super.key});
  @override
  State<SecureVaultScreen> createState() => _SecureVaultScreenState();
}

class _SecureVaultScreenState extends State<SecureVaultScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _lockCtrl;
  late AnimationController _scanCtrl;
  Timer? _secTimer;
  final _rand = Random();

  int _selectedTab = 0;
  final List<String> _tabs = ['VAULT', 'WALLETS', 'MULTI-SIG', 'AUDIT', 'KEYS'];

  bool _vaultLocked = false;
  bool _biometricEnabled = true;
  bool _twoFactorEnabled = true;
  bool _coldStorageMode = false;

  // Vault assets
  final List<Map<String, dynamic>> _vaultAssets = [
    {'symbol': 'BTC', 'name': 'Bitcoin', 'amount': 1.248, 'value': 84721.8, 'locked': true, 'cold': true},
    {'symbol': 'ETH', 'name': 'Ethereum', 'amount': 12.47, 'value': 42532.4, 'locked': true, 'cold': false},
    {'symbol': 'SOL', 'name': 'Solana', 'amount': 248.3, 'value': 44268.5, 'locked': false, 'cold': false},
    {'symbol': 'BNB', 'name': 'Binance Coin', 'amount': 84.2, 'value': 50013.0, 'locked': true, 'cold': true},
    {'symbol': 'QEMMA', 'name': 'Quantum EMMA', 'amount': 100000.0, 'value': 28400.0, 'locked': true, 'cold': true},
    {'symbol': 'AVAX', 'name': 'Avalanche', 'amount': 412.8, 'value': 17461.5, 'locked': false, 'cold': false},
  ];

  double get _totalVaultValue =>
    _vaultAssets.fold(0.0, (sum, a) => sum + (a['value'] as double));

  // Hardware wallets
  final List<Map<String, dynamic>> _hwWallets = [
    {'name': 'Ledger Nano X', 'type': 'HARDWARE', 'connected': true, 'assets': 4, 'address': '0x7f...3a2c', 'balance': '\$127,484', 'firmware': 'v2.1.0', 'color': 0xFF00C8F5},
    {'name': 'Trezor Model T', 'type': 'HARDWARE', 'connected': false, 'assets': 2, 'address': '0x4b...8d1f', 'balance': '\$89,247', 'firmware': 'v2.5.3', 'color': 0xFF00F0C0},
    {'name': 'Cold Card MK4', 'type': 'HARDWARE', 'connected': false, 'assets': 1, 'address': 'bc1q...x7m3', 'balance': '\$84,721', 'firmware': 'v5.1.2', 'color': 0xFFFFAA00},
    {'name': 'Quantum Vault SW', 'type': 'SOFTWARE', 'connected': true, 'assets': 6, 'address': '0x9c...f47e', 'balance': '\$45,872', 'firmware': 'v3.0.1', 'color': 0xFF9B59B6},
  ];

  // Multi-sig wallets
  final List<Map<String, dynamic>> _multiSig = [
    {'name': 'Treasury Vault', 'required': 3, 'total': 5, 'signers': ['QW', 'NM', 'CO', 'TP', 'DA'], 'signed': ['QW', 'NM', 'CO'], 'balance': '\$284,721', 'pending': 1},
    {'name': 'Trading Reserve', 'required': 2, 'total': 3, 'signers': ['QW', 'ME', 'DA'], 'signed': ['QW', 'ME'], 'balance': '\$127,450', 'pending': 0},
    {'name': 'Emergency Fund', 'required': 2, 'total': 2, 'signers': ['ME', 'NM'], 'signed': [], 'balance': '\$48,200', 'pending': 2},
  ];

  // Security audit log
  final List<Map<String, dynamic>> _auditLog = [
    {'event': 'Vault Unlocked', 'time': '2m ago', 'user': 'QW', 'ip': '192.168.1.100', 'status': 'SUCCESS', 'icon': Icons.lock_open},
    {'event': 'BTC Transfer: 0.5 BTC', 'time': '14m ago', 'user': 'QW', 'ip': '192.168.1.100', 'status': 'SUCCESS', 'icon': Icons.send},
    {'event': 'Multi-Sig Request', 'time': '1h ago', 'user': 'NM', 'ip': '10.0.0.42', 'status': 'PENDING', 'icon': Icons.security},
    {'event': 'Failed Login Attempt', 'time': '2h ago', 'user': 'UNKNOWN', 'ip': '185.234.x.x', 'status': 'BLOCKED', 'icon': Icons.warning},
    {'event': 'Hardware Wallet Connected', 'time': '3h ago', 'user': 'QW', 'ip': '192.168.1.100', 'status': 'SUCCESS', 'icon': Icons.usb},
    {'event': 'Backup Created', 'time': '6h ago', 'user': 'QW', 'ip': '192.168.1.100', 'status': 'SUCCESS', 'icon': Icons.backup},
    {'event': 'API Key Rotated', 'time': '1d ago', 'user': 'QW', 'ip': '192.168.1.100', 'status': 'SUCCESS', 'icon': Icons.vpn_key},
  ];

  // Encryption keys
  final List<Map<String, dynamic>> _keys = [
    {'name': 'Master Seed Phrase', 'type': 'BIP39', 'bits': 256, 'created': '2023-01-15', 'status': 'ACTIVE', 'encrypted': true},
    {'name': 'Trading API Key', 'type': 'RSA-4096', 'bits': 4096, 'created': '2024-03-10', 'status': 'ACTIVE', 'encrypted': true},
    {'name': 'Vault Encryption Key', 'type': 'AES-256', 'bits': 256, 'created': '2024-01-01', 'status': 'ACTIVE', 'encrypted': true},
    {'name': 'Backup Seed', 'type': 'BIP39', 'bits': 256, 'created': '2023-01-15', 'status': 'BACKUP', 'encrypted': true},
    {'name': 'Old Trading Key', 'type': 'RSA-2048', 'bits': 2048, 'created': '2022-06-20', 'status': 'REVOKED', 'encrypted': false},
  ];

  // Security score
  double _securityScore = 94.7;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _lockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _secTimer = Timer.periodic(const Duration(seconds: 5), (_) => _updateSecurity());
  }

  void _updateSecurity() {
    if (!mounted) return;
    setState(() {
      _securityScore = 90.0 + _rand.nextDouble() * 8.0;
      for (var a in _vaultAssets) {
        a['value'] = (a['value'] as double) * (1 + (_rand.nextDouble() - 0.49) * 0.01);
      }
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _lockCtrl.dispose();
    _scanCtrl.dispose();
    _secTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(p),
            _buildTabBar(p),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildTabContent(p),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(QuantumPalette p) {
    final lockColor = _vaultLocked ? p.negative : p.positive;
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            p.background,
            lockColor.withValues(alpha: 0.06),
          ]),
          border: Border(bottom: BorderSide(
            color: lockColor.withValues(alpha: 0.3 + _glowCtrl.value * 0.2),
          )),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                setState(() => _vaultLocked = !_vaultLocked);
              },
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    lockColor.withValues(alpha: 0.4 + _glowCtrl.value * 0.3),
                    lockColor.withValues(alpha: 0.1),
                  ]),
                  boxShadow: [BoxShadow(color: lockColor.withValues(alpha: 0.5), blurRadius: 16)],
                ),
                child: Icon(
                  _vaultLocked ? Icons.lock : Icons.lock_open,
                  color: lockColor, size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SECURE VAULT', style: GoogleFonts.orbitron(
                  color: p.primary, fontSize: 16, fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: p.primary.withValues(alpha: 0.5), blurRadius: 8)],
                )),
                Text('Quantum Encryption · ${_vaultLocked ? "LOCKED" : "UNLOCKED"}',
                  style: GoogleFonts.rajdhani(color: lockColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
            // Security score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: p.positive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.positive.withValues(alpha: 0.3)),
              ),
              child: Column(children: [
                Text('${_securityScore.toStringAsFixed(0)}%', style: GoogleFonts.orbitron(
                  color: p.positive, fontSize: 13, fontWeight: FontWeight.bold,
                )),
                Text('SECURITY', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
              ]),
            ),
            const SizedBox(width: 8),
            // Total value
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.primary.withValues(alpha: 0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('\$${(_totalVaultValue / 1000).toStringAsFixed(1)}K', style: GoogleFonts.orbitron(
                  color: p.primary, fontSize: 13, fontWeight: FontWeight.bold,
                )),
                Text('VAULT VALUE', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(QuantumPalette p) {
    return Container(
      height: 40,
      color: p.surface.withValues(alpha: 0.4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _tabs.length,
        itemBuilder: (_, i) {
          final sel = i == _selectedTab;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: sel ? p.primary.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: sel ? p.primary : Colors.transparent),
              ),
              child: Center(child: Text(_tabs[i], style: GoogleFonts.orbitron(
                color: sel ? p.primary : p.textSecondary,
                fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              ))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent(QuantumPalette p) {
    switch (_selectedTab) {
      case 0: return _buildVaultTab(p);
      case 1: return _buildWalletsTab(p);
      case 2: return _buildMultiSigTab(p);
      case 3: return _buildAuditTab(p);
      case 4: return _buildKeysTab(p);
      default: return _buildVaultTab(p);
    }
  }

  // ── VAULT TAB ──
  Widget _buildVaultTab(QuantumPalette p) {
    return ListView(
      key: const ValueKey('vault'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildSecurityDashboard(p),
        const SizedBox(height: 12),
        _buildVaultAssetsList(p),
      ],
    );
  }

  Widget _buildSecurityDashboard(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          p.positive.withValues(alpha: 0.08),
          p.primary.withValues(alpha: 0.05),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.positive.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(children: [
            Icon(Icons.verified_user, color: p.positive, size: 18),
            const SizedBox(width: 8),
            Text('SECURITY STATUS', style: GoogleFonts.orbitron(
              color: p.positive, fontSize: 12, fontWeight: FontWeight.bold,
            )),
            const Spacer(),
            Text('QUANTUM GRADE', style: GoogleFonts.rajdhani(
              color: p.accent, fontSize: 10, fontWeight: FontWeight.bold,
            )),
          ]),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildSecToggle(p, Icons.fingerprint, '2FA', _twoFactorEnabled, (v) => setState(() => _twoFactorEnabled = v))),
              const SizedBox(width: 8),
              Expanded(child: _buildSecToggle(p, Icons.face, 'BIOMETRIC', _biometricEnabled, (v) => setState(() => _biometricEnabled = v))),
              const SizedBox(width: 8),
              Expanded(child: _buildSecToggle(p, Icons.ac_unit, 'COLD MODE', _coldStorageMode, (v) => setState(() => _coldStorageMode = v))),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildSecStat(p, 'AES-256', 'Encryption', p.positive)),
            Expanded(child: _buildSecStat(p, 'BIP-39', 'Seed Std', p.primary)),
            Expanded(child: _buildSecStat(p, 'HD Wallet', 'Key Deriv', p.accent)),
            Expanded(child: _buildSecStat(p, 'FIDO2', 'Auth Std', p.positive)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSecToggle(QuantumPalette p, IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: value ? p.positive.withValues(alpha: 0.15) : p.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? p.positive.withValues(alpha: 0.5) : p.surface.withValues(alpha: 0.6),
          ),
        ),
        child: Column(children: [
          Icon(icon, color: value ? p.positive : p.textSecondary, size: 18),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.rajdhani(
            color: value ? p.positive : p.textSecondary, fontSize: 9, fontWeight: FontWeight.bold,
          )),
          Text(value ? 'ON' : 'OFF', style: GoogleFonts.orbitron(
            color: value ? p.positive : p.textSecondary, fontSize: 8,
          )),
        ]),
      ),
    );
  }

  Widget _buildSecStat(QuantumPalette p, String value, String label, Color color) {
    return Column(children: [
      Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
    ]);
  }

  Widget _buildVaultAssetsList(QuantumPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('VAULT ASSETS', style: GoogleFonts.orbitron(
            color: p.primary, fontSize: 11, fontWeight: FontWeight.bold,
          )),
          const Spacer(),
          Text('Total: \$${(_totalVaultValue / 1000).toStringAsFixed(1)}K',
            style: GoogleFonts.rajdhani(color: p.positive, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 10),
        ..._vaultAssets.map((a) => _buildVaultAssetCard(p, a)),
      ],
    );
  }

  Widget _buildVaultAssetCard(QuantumPalette p, Map<String, dynamic> a) {
    final isLocked = a['locked'] as bool;
    final isCold = a['cold'] as bool;
    final lockColor = isLocked ? p.positive : p.negative;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lockColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.primary.withValues(alpha: 0.15),
              border: Border.all(color: p.primary.withValues(alpha: 0.3)),
            ),
            child: Center(child: Text(a['symbol'], style: GoogleFonts.orbitron(
              color: p.primary, fontSize: 8, fontWeight: FontWeight.bold,
            ))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a['name'], style: GoogleFonts.rajdhani(
                color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold,
              )),
              Row(children: [
                if (isCold) Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text('COLD', style: GoogleFonts.rajdhani(
                    color: p.accent, fontSize: 8, fontWeight: FontWeight.bold,
                  )),
                ),
                Text('${a['amount']} ${a['symbol']}',
                  style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
              ]),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${(a['value'] as double).toStringAsFixed(0)}', style: GoogleFonts.orbitron(
              color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold,
            )),
            Text(_valueShare(a['value'] as double), style: GoogleFonts.rajdhani(
              color: p.textSecondary, fontSize: 9,
            )),
          ]),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => a['locked'] = !(a['locked'] as bool));
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: lockColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: lockColor.withValues(alpha: 0.3)),
              ),
              child: Icon(isLocked ? Icons.lock : Icons.lock_open, color: lockColor, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _valueShare(double value) {
    final pct = value / _totalVaultValue * 100;
    return '${pct.toStringAsFixed(1)}% of vault';
  }

  // ── WALLETS TAB ──
  Widget _buildWalletsTab(QuantumPalette p) {
    return ListView(
      key: const ValueKey('wallets'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildWalletsHeader(p),
        const SizedBox(height: 10),
        ..._hwWallets.map((w) => _buildWalletCard(p, w)),
        const SizedBox(height: 8),
        _buildAddWalletButton(p),
      ],
    );
  }

  Widget _buildWalletsHeader(QuantumPalette p) {
    return Row(children: [
      Expanded(child: _buildWalletSummaryCard(p, 'CONNECTED', '${_hwWallets.where((w) => w['connected'] == true).length}', p.positive, Icons.link)),
      const SizedBox(width: 8),
      Expanded(child: _buildWalletSummaryCard(p, 'HARDWARE', '${_hwWallets.where((w) => w['type'] == 'HARDWARE').length}', p.primary, Icons.memory)),
      const SizedBox(width: 8),
      Expanded(child: _buildWalletSummaryCard(p, 'TOTAL ASSETS', '${_hwWallets.fold<int>(0, (a, w) => a + (w['assets'] as int))}', p.accent, Icons.account_balance_wallet)),
    ]);
  }

  Widget _buildWalletSummaryCard(QuantumPalette p, String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
      ]),
    );
  }

  Widget _buildWalletCard(QuantumPalette p, Map<String, dynamic> w) {
    final color = Color(w['color'] as int);
    final isConn = w['connected'] as bool;
    final isHW = w['type'] == 'HARDWARE';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: isConn ? 0.4 : 0.2)),
      ),
      child: Column(
        children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Icon(isHW ? Icons.memory : Icons.phone_android, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w['name'], style: GoogleFonts.rajdhani(
                  color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold,
                )),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: (isHW ? p.primary : p.accent).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(w['type'], style: GoogleFonts.rajdhani(
                      color: isHW ? p.primary : p.accent, fontSize: 8, fontWeight: FontWeight.bold,
                    )),
                  ),
                  const SizedBox(width: 6),
                  Text('FW: ${w['firmware']}', style: GoogleFonts.rajdhani(
                    color: p.textSecondary, fontSize: 9,
                  )),
                ]),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isConn ? p.positive.withValues(alpha: 0.15) : p.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isConn ? p.positive.withValues(alpha: 0.4) : Colors.transparent),
              ),
              child: Row(children: [
                Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConn ? p.positive : p.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(isConn ? 'CONNECTED' : 'OFFLINE', style: GoogleFonts.rajdhani(
                  color: isConn ? p.positive : p.textSecondary,
                  fontSize: 9, fontWeight: FontWeight.bold,
                )),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _buildWalletInfo(p, 'ADDRESS', w['address'], p.textSecondary)),
            Expanded(child: _buildWalletInfo(p, 'BALANCE', w['balance'], p.positive)),
            Expanded(child: _buildWalletInfo(p, 'ASSETS', '${w['assets']} tokens', p.primary)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _buildSmallBtn(p, 'SEND', Icons.send, p.primary)),
            const SizedBox(width: 8),
            Expanded(child: _buildSmallBtn(p, 'RECEIVE', Icons.call_received, p.positive)),
            const SizedBox(width: 8),
            Expanded(child: _buildSmallBtn(p, isConn ? 'DISCONNECT' : 'CONNECT', isConn ? Icons.link_off : Icons.link, isConn ? p.negative : p.accent)),
          ]),
        ],
      ),
    );
  }

  Widget _buildWalletInfo(QuantumPalette p, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
        Text(value, style: GoogleFonts.rajdhani(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSmallBtn(QuantumPalette p, String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.rajdhani(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildAddWalletButton(QuantumPalette p) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: p.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: p.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_circle_outline, color: p.primary, size: 18),
          const SizedBox(width: 8),
          Text('ADD HARDWARE WALLET', style: GoogleFonts.orbitron(
            color: p.primary, fontSize: 11, fontWeight: FontWeight.bold,
          )),
        ]),
      ),
    );
  }

  // ── MULTI-SIG TAB ──
  Widget _buildMultiSigTab(QuantumPalette p) {
    return ListView(
      key: const ValueKey('multisig'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildMultiSigHeader(p),
        const SizedBox(height: 12),
        ..._multiSig.map((ms) => _buildMultiSigCard(p, ms)),
        const SizedBox(height: 8),
        _buildCreateMultiSigBtn(p),
      ],
    );
  }

  Widget _buildMultiSigHeader(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.accent.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.group, color: p.accent, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MULTI-SIGNATURE WALLETS', style: GoogleFonts.orbitron(
              color: p.accent, fontSize: 11, fontWeight: FontWeight.bold,
            )),
            Text('Requires multiple signers to authorize transactions',
              style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${_multiSig.length}', style: GoogleFonts.orbitron(
            color: p.accent, fontSize: 16, fontWeight: FontWeight.bold,
          )),
          Text('vaults', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
        ]),
      ]),
    );
  }

  Widget _buildMultiSigCard(QuantumPalette p, Map<String, dynamic> ms) {
    final required = ms['required'] as int;
    final total = ms['total'] as int;
    final signed = ms['signed'] as List;
    final signers = ms['signers'] as List;
    final pending = ms['pending'] as int;
    final progress = signed.length / required;
    final isComplete = signed.length >= required;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isComplete ? p.positive : p.primary).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ms['name'], style: GoogleFonts.rajdhani(
                  color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold,
                )),
                Text('$required-of-$total Multisig · ${ms['balance']} total',
                  style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
              ],
            )),
            if (pending > 0) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: p.negative.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: p.negative.withValues(alpha: 0.4)),
              ),
              child: Text('$pending PENDING', style: GoogleFonts.orbitron(
                color: p.negative, fontSize: 9, fontWeight: FontWeight.bold,
              )),
            ),
          ]),
          const SizedBox(height: 12),
          // Signers
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: signers.map<Widget>((s) {
              final hasSigned = signed.contains(s);
              return Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasSigned ? p.positive.withValues(alpha: 0.2) : p.surface,
                  border: Border.all(
                    color: hasSigned ? p.positive.withValues(alpha: 0.6) : p.textSecondary.withValues(alpha: 0.3),
                    width: hasSigned ? 1.5 : 1,
                  ),
                ),
                child: Center(child: Text(s, style: GoogleFonts.orbitron(
                  color: hasSigned ? p.positive : p.textSecondary,
                  fontSize: 9, fontWeight: FontWeight.bold,
                ))),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Text('Signatures: ${signed.length}/$required',
              style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
            const Spacer(),
            Text(isComplete ? 'AUTHORIZED' : '${required - signed.length} more needed',
              style: GoogleFonts.rajdhani(
                color: isComplete ? p.positive : p.primary,
                fontSize: 10, fontWeight: FontWeight.bold,
              )),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: p.surface,
              valueColor: AlwaysStoppedAnimation(isComplete ? p.positive : p.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateMultiSigBtn(QuantumPalette p) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: p.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.accent.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_circle_outline, color: p.accent, size: 18),
          const SizedBox(width: 8),
          Text('CREATE NEW MULTI-SIG VAULT', style: GoogleFonts.orbitron(
            color: p.accent, fontSize: 11, fontWeight: FontWeight.bold,
          )),
        ]),
      ),
    );
  }

  // ── AUDIT TAB ──
  Widget _buildAuditTab(QuantumPalette p) {
    return ListView(
      key: const ValueKey('audit'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildAuditSummary(p),
        const SizedBox(height: 12),
        Text('SECURITY EVENT LOG', style: GoogleFonts.orbitron(
          color: p.primary, fontSize: 11, fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 8),
        ..._auditLog.map((e) => _buildAuditEntry(p, e)),
      ],
    );
  }

  Widget _buildAuditSummary(QuantumPalette p) {
    return Row(children: [
      Expanded(child: _buildAuditStat(p, 'EVENTS TODAY', '18', p.primary)),
      const SizedBox(width: 8),
      Expanded(child: _buildAuditStat(p, 'BLOCKED', '3', p.negative)),
      const SizedBox(width: 8),
      Expanded(child: _buildAuditStat(p, 'PENDING', '2', p.accent)),
      const SizedBox(width: 8),
      Expanded(child: _buildAuditStat(p, 'SCORE', '${_securityScore.toInt()}%', p.positive)),
    ]);
  }

  Widget _buildAuditStat(QuantumPalette p, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 8)),
      ]),
    );
  }

  Widget _buildAuditEntry(QuantumPalette p, Map<String, dynamic> e) {
    final statusColors = {'SUCCESS': p.positive, 'BLOCKED': p.negative, 'PENDING': p.accent};
    final statusColor = statusColors[e['status']] ?? p.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withValues(alpha: 0.12),
            ),
            child: Icon(e['icon'] as IconData, color: statusColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e['event'], style: GoogleFonts.rajdhani(
                color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold,
              )),
              Text('${e['user']} · ${e['ip']} · ${e['time']}',
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(e['status'], style: GoogleFonts.rajdhani(
              color: statusColor, fontSize: 9, fontWeight: FontWeight.bold,
            )),
          ),
        ],
      ),
    );
  }

  // ── KEYS TAB ──
  Widget _buildKeysTab(QuantumPalette p) {
    return ListView(
      key: const ValueKey('keys'),
      padding: const EdgeInsets.all(12),
      children: [
        _buildKeysWarning(p),
        const SizedBox(height: 12),
        ..._keys.map((k) => _buildKeyCard(p, k)),
        const SizedBox(height: 8),
        _buildGenerateKeyBtn(p),
      ],
    );
  }

  Widget _buildKeysWarning(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.negative.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.negative.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber, color: p.negative, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(
          'Keep your keys secure. Never share seed phrases or private keys. These are encrypted and stored locally.',
          style: GoogleFonts.rajdhani(color: p.negative, fontSize: 10, height: 1.4),
        )),
      ]),
    );
  }

  Widget _buildKeyCard(QuantumPalette p, Map<String, dynamic> k) {
    final statusColors = {'ACTIVE': p.positive, 'BACKUP': p.primary, 'REVOKED': p.negative};
    final statusColor = statusColors[k['status']] ?? p.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withValues(alpha: 0.12),
            ),
            child: Icon(
              k['encrypted'] == true ? Icons.lock : Icons.lock_open,
              color: statusColor, size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(k['name'], style: GoogleFonts.rajdhani(
                color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.bold,
              )),
              Text('${k['type']} · ${k['bits']} bits · Created ${k['created']}',
                style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(k['status'], style: GoogleFonts.rajdhani(
                color: statusColor, fontSize: 9, fontWeight: FontWeight.bold,
              )),
            ),
            const SizedBox(height: 4),
            if (k['encrypted'] == true)
              Text('AES-256', style: GoogleFonts.rajdhani(color: p.accent, fontSize: 9)),
          ]),
        ],
      ),
    );
  }

  Widget _buildGenerateKeyBtn(QuantumPalette p) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: p.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.positive.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.vpn_key, color: p.positive, size: 18),
          const SizedBox(width: 8),
          Text('GENERATE NEW KEY PAIR', style: GoogleFonts.orbitron(
            color: p.positive, fontSize: 11, fontWeight: FontWeight.bold,
          )),
        ]),
      ),
    );
  }
}
