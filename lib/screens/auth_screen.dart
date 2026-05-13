/// Quantum Trader – Auth Screen v24.0
/// Login · Register · 2FA TOTP · KYC · Biometric
/// Grigori Saks · 2025
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';
import '../services/auth_service.dart';

enum _AuthMode { login, register, twoFA, kyc }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  _AuthMode _mode = _AuthMode.login;
  late AnimationController _bgCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _bgAnim;

  // Login fields
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _obscurePw = true;
  bool _obscurePw2 = true;
  String? _localError;
  bool _acceptTerms = false;

  // KYC fields
  int _kycStep = 0;
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _idUploaded = false;
  bool _selfieUploaded = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _pulseCtrl.dispose();
    _emailCtrl.dispose(); _pwCtrl.dispose(); _pw2Ctrl.dispose();
    _nameCtrl.dispose(); _pinCtrl.dispose();
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose();
    _dobCtrl.dispose(); _countryCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final p = theme.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: AnimatedBuilder(
        animation: _bgAnim,
        builder: (_, child) => Stack(children: [
          // Animated gradient background
          Positioned.fill(
            child: CustomPaint(painter: _AuthBgPainter(_bgAnim.value, p)),
          ),
          child!,
        ]),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              const SizedBox(height: 40),
              _buildLogo(p),
              const SizedBox(height: 32),
              _buildModeCard(p),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Logo ───────────────────────────────────────────
  Widget _buildLogo(QuantumPalette p) {
    return Column(children: [
      AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              p.primary.withValues(alpha: 0.9),
              p.accent.withValues(alpha: 0.5),
            ]),
            boxShadow: [BoxShadow(
              color: p.primary.withValues(alpha: 0.3 + _pulseCtrl.value * 0.3),
              blurRadius: 20 + _pulseCtrl.value * 20,
              spreadRadius: 2 + _pulseCtrl.value * 4,
            )],
          ),
          child: const Icon(Icons.account_balance, color: Colors.white, size: 36),
        ),
      ),
      const SizedBox(height: 14),
      Text('QUANTUM TRADER', style: GoogleFonts.orbitron(
        color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3,
      )),
      const SizedBox(height: 4),
      Text('AI-Powered Trading Platform', style: GoogleFonts.rajdhani(
        color: p.primary, fontSize: 12, letterSpacing: 1.5,
      )),
    ]);
  }

  // ── Main Card ──────────────────────────────────────
  Widget _buildModeCard(QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.1), blurRadius: 30)],
      ),
      child: Form(
        key: _formKey,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (_mode) {
            _AuthMode.login    => _buildLogin(p),
            _AuthMode.register => _buildRegister(p),
            _AuthMode.twoFA    => _buildTwoFA(p),
            _AuthMode.kyc      => _buildKYC(p),
          },
        ),
      ),
    );
  }

  // ── LOGIN ─────────────────────────────────────────
  Widget _buildLogin(QuantumPalette p) {
    final auth = Provider.of<AuthService>(context);
    return Column(key: const ValueKey('login'), children: [
      _buildSectionTitle('ANMELDEN', Icons.login, p),
      const SizedBox(height: 20),
      _buildTextField('E-Mail', Icons.email_outlined, _emailCtrl, p,
        keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 12),
      _buildTextField('Passwort', Icons.lock_outline, _pwCtrl, p,
        obscure: _obscurePw,
        suffixIcon: IconButton(
          icon: Icon(_obscurePw ? Icons.visibility_off : Icons.visibility, color: p.textSecondary, size: 18),
          onPressed: () => setState(() => _obscurePw = !_obscurePw),
        )),
      if (_localError != null) ...[
        const SizedBox(height: 8),
        _buildError(_localError!, p),
      ],
      if (auth.error != null) ...[
        const SizedBox(height: 8),
        _buildError(auth.error!, p),
      ],
      const SizedBox(height: 20),
      _buildPrimaryButton(
        auth.isLoading ? 'ANMELDEN...' : 'ANMELDEN',
        Icons.login, p,
        onTap: auth.isLoading ? null : () => _doLogin(auth),
      ),
      const SizedBox(height: 16),
      _buildDivider('oder', p),
      const SizedBox(height: 16),
      _buildSecondaryButton('KONTO ERSTELLEN', Icons.person_add, p,
        onTap: () { setState(() { _mode = _AuthMode.register; _localError = null; auth.clearError(); }); }),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () {},
        child: Text('Passwort vergessen?', style: GoogleFonts.rajdhani(
          color: p.primary, fontSize: 13, decoration: TextDecoration.underline,
        )),
      ),
    ]);
  }

  // ── REGISTER ──────────────────────────────────────
  Widget _buildRegister(QuantumPalette p) {
    final auth = Provider.of<AuthService>(context);
    return Column(key: const ValueKey('register'), children: [
      _buildSectionTitle('REGISTRIEREN', Icons.person_add, p),
      const SizedBox(height: 20),
      _buildTextField('Anzeigename', Icons.badge_outlined, _nameCtrl, p),
      const SizedBox(height: 12),
      _buildTextField('E-Mail', Icons.email_outlined, _emailCtrl, p,
        keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 12),
      _buildTextField('Passwort (min. 8 Zeichen)', Icons.lock_outline, _pwCtrl, p,
        obscure: _obscurePw,
        suffixIcon: IconButton(
          icon: Icon(_obscurePw ? Icons.visibility_off : Icons.visibility, color: p.textSecondary, size: 18),
          onPressed: () => setState(() => _obscurePw = !_obscurePw),
        )),
      const SizedBox(height: 12),
      _buildTextField('Passwort bestätigen', Icons.lock_outline, _pw2Ctrl, p,
        obscure: _obscurePw2,
        suffixIcon: IconButton(
          icon: Icon(_obscurePw2 ? Icons.visibility_off : Icons.visibility, color: p.textSecondary, size: 18),
          onPressed: () => setState(() => _obscurePw2 = !_obscurePw2),
        )),
      const SizedBox(height: 12),
      // Terms checkbox
      Row(children: [
        Checkbox(
          value: _acceptTerms, activeColor: p.primary,
          onChanged: (v) => setState(() => _acceptTerms = v ?? false),
        ),
        Expanded(child: Text(
          'Ich akzeptiere die AGB und Datenschutzerklärung',
          style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 11),
        )),
      ]),
      if (_localError != null) ...[const SizedBox(height: 8), _buildError(_localError!, p)],
      if (auth.error != null) ...[const SizedBox(height: 8), _buildError(auth.error!, p)],
      const SizedBox(height: 16),
      _buildPrimaryButton(
        auth.isLoading ? 'REGISTRIEREN...' : 'KONTO ERSTELLEN',
        Icons.check_circle, p,
        onTap: auth.isLoading ? null : () => _doRegister(auth),
      ),
      const SizedBox(height: 16),
      _buildSecondaryButton('ZURÜCK ZUM LOGIN', Icons.arrow_back, p,
        onTap: () => setState(() { _mode = _AuthMode.login; _localError = null; auth.clearError(); })),
    ]);
  }

  // ── 2FA ───────────────────────────────────────────
  Widget _buildTwoFA(QuantumPalette p) {
    final auth = Provider.of<AuthService>(context);
    final defaultPinTheme = PinTheme(
      width: 52, height: 60,
      textStyle: GoogleFonts.orbitron(fontSize: 20, color: p.textPrimary, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: p.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
      ),
    );
    return Column(key: const ValueKey('2fa'), children: [
      _buildSectionTitle('2-FAKTOR-AUTH', Icons.security, p),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.primary.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(Icons.info_outline, color: p.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(
            'Gib deinen 6-stelligen Authentifikator-Code ein',
            style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 12),
          )),
        ]),
      ),
      const SizedBox(height: 28),
      Pinput(
        controller: _pinCtrl,
        length: 6,
        defaultPinTheme: defaultPinTheme,
        focusedPinTheme: defaultPinTheme.copyDecorationWith(
          border: Border.all(color: p.primary, width: 2),
          boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.3), blurRadius: 8)],
        ),
        keyboardType: TextInputType.number,
        onCompleted: (_) => _do2FA(auth),
      ),
      if (auth.error != null) ...[const SizedBox(height: 12), _buildError(auth.error!, p)],
      const SizedBox(height: 24),
      _buildPrimaryButton(
        auth.isLoading ? 'VERIFIZIEREN...' : 'CODE BESTÄTIGEN',
        Icons.verified, p,
        onTap: auth.isLoading ? null : () => _do2FA(auth),
      ),
      const SizedBox(height: 16),
      _buildSecondaryButton('ZURÜCK', Icons.arrow_back, p,
        onTap: () => setState(() { _mode = _AuthMode.login; auth.clearError(); })),
    ]);
  }

  // ── KYC ───────────────────────────────────────────
  Widget _buildKYC(QuantumPalette p) {
    return Column(key: const ValueKey('kyc'), children: [
      _buildSectionTitle('KYC VERIFIZIERUNG', Icons.verified_user, p),
      const SizedBox(height: 8),
      // Progress steps
      Row(children: List.generate(3, (i) {
        final done = i < _kycStep;
        final active = i == _kycStep;
        return Expanded(child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: done ? p.positive : active ? p.primary : p.surfaceVariant,
          ),
        ));
      })),
      const SizedBox(height: 20),
      if (_kycStep == 0) _buildKycPersonal(p),
      if (_kycStep == 1) _buildKycDocuments(p),
      if (_kycStep == 2) _buildKycConfirm(p),
    ]);
  }

  Widget _buildKycPersonal(QuantumPalette p) {
    return Column(children: [
      Text('Persönliche Daten', style: GoogleFonts.orbitron(
        color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600,
      )),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _buildTextField('Vorname', Icons.person, _firstNameCtrl, p)),
        const SizedBox(width: 8),
        Expanded(child: _buildTextField('Nachname', Icons.person_outline, _lastNameCtrl, p)),
      ]),
      const SizedBox(height: 12),
      _buildTextField('Telefon', Icons.phone, _phoneCtrl, p,
        keyboardType: TextInputType.phone),
      const SizedBox(height: 12),
      _buildTextField('Land', Icons.flag, _countryCtrl, p),
      const SizedBox(height: 12),
      _buildTextField('Geburtsdatum (TT.MM.JJJJ)', Icons.calendar_today, _dobCtrl, p),
      const SizedBox(height: 20),
      _buildPrimaryButton('WEITER →', Icons.arrow_forward, p,
        onTap: () {
          if (_firstNameCtrl.text.isEmpty || _lastNameCtrl.text.isEmpty) {
            setState(() => _localError = 'Bitte alle Pflichtfelder ausfüllen');
            return;
          }
          setState(() { _kycStep = 1; _localError = null; });
        }),
    ]);
  }

  Widget _buildKycDocuments(QuantumPalette p) {
    return Column(children: [
      Text('Dokumente hochladen', style: GoogleFonts.orbitron(
        color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600,
      )),
      const SizedBox(height: 16),
      _buildDocUpload('Personalausweis / Reisepass', Icons.badge, _idUploaded, p,
        onTap: () => setState(() => _idUploaded = true)),
      const SizedBox(height: 12),
      _buildDocUpload('Selfie mit Ausweis', Icons.camera_alt, _selfieUploaded, p,
        onTap: () => setState(() => _selfieUploaded = true)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.shield, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(
            'Deine Daten werden SSL-verschlüsselt übertragen und gemäß DSGVO gespeichert.',
            style: GoogleFonts.rajdhani(color: Colors.amber, fontSize: 10),
          )),
        ]),
      ),
      if (_localError != null) ...[const SizedBox(height: 8), _buildError(_localError!, p)],
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: _buildSecondaryButton('← ZURÜCK', Icons.arrow_back, p,
          onTap: () => setState(() { _kycStep = 0; _localError = null; }))),
        const SizedBox(width: 12),
        Expanded(child: _buildPrimaryButton('WEITER →', Icons.arrow_forward, p,
          onTap: () {
            if (!_idUploaded || !_selfieUploaded) {
              setState(() => _localError = 'Bitte beide Dokumente hochladen');
              return;
            }
            setState(() { _kycStep = 2; _localError = null; });
          })),
      ]),
    ]);
  }

  Widget _buildKycConfirm(QuantumPalette p) {
    final auth = Provider.of<AuthService>(context);
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.positive.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.positive.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Icon(Icons.check_circle, color: p.positive, size: 48),
          const SizedBox(height: 12),
          Text('Überprüfung läuft', style: GoogleFonts.orbitron(
            color: p.positive, fontSize: 14, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 8),
          Text(
            'Deine KYC-Unterlagen wurden eingereicht. Die Überprüfung dauert 1-3 Werktage.',
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 12),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      _buildPrimaryButton('WEITER ZUR APP', Icons.rocket_launch, p,
        onTap: () async {
          await auth.updateKyc(KycStatus.pending);
          await auth.updateProfile(
            firstName: _firstNameCtrl.text,
            lastName: _lastNameCtrl.text,
            phone: _phoneCtrl.text,
            country: _countryCtrl.text,
            dateOfBirth: _dobCtrl.text,
          );
          if (mounted) setState(() => _mode = _AuthMode.login);
        }),
    ]);
  }

  Widget _buildDocUpload(String label, IconData icon, bool uploaded, QuantumPalette p, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: uploaded ? p.positive.withValues(alpha: 0.08) : p.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: uploaded ? p.positive.withValues(alpha: 0.5) : p.primary.withValues(alpha: 0.2),
            style: uploaded ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: uploaded ? p.positive.withValues(alpha: 0.15) : p.primary.withValues(alpha: 0.1),
            ),
            child: Icon(uploaded ? Icons.check : icon,
              color: uploaded ? p.positive : p.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.rajdhani(
            color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600,
          ))),
          Icon(uploaded ? Icons.check_circle : Icons.upload_file,
            color: uploaded ? p.positive : p.textSecondary, size: 20),
        ]),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────
  Future<void> _doLogin(AuthService auth) async {
    setState(() => _localError = null);
    auth.clearError();
    if (_emailCtrl.text.isEmpty || _pwCtrl.text.isEmpty) {
      setState(() => _localError = 'Bitte E-Mail und Passwort eingeben');
      return;
    }
    HapticFeedback.mediumImpact();
    final result = await auth.login(email: _emailCtrl.text.trim(), password: _pwCtrl.text);
    if (!mounted) return;
    if (result.requires2FA) {
      setState(() => _mode = _AuthMode.twoFA);
    } else if (!result.success) {
      setState(() => _localError = result.error);
    }
  }

  Future<void> _doRegister(AuthService auth) async {
    setState(() => _localError = null);
    auth.clearError();
    if (!_acceptTerms) {
      setState(() => _localError = 'Bitte akzeptiere die AGB');
      return;
    }
    if (_pwCtrl.text != _pw2Ctrl.text) {
      setState(() => _localError = 'Passwörter stimmen nicht überein');
      return;
    }
    HapticFeedback.mediumImpact();
    final result = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _pwCtrl.text,
      displayName: _nameCtrl.text.trim(),
    );
    if (!mounted) return;
    if (result.success) {
      setState(() => _mode = _AuthMode.kyc);
    } else {
      setState(() => _localError = result.error);
    }
  }

  Future<void> _do2FA(AuthService auth) async {
    if (_pinCtrl.text.length < 6) return;
    auth.clearError();
    HapticFeedback.mediumImpact();
    final result = await auth.verify2FA(_pinCtrl.text);
    if (!mounted) return;
    if (!result.success) {
      _pinCtrl.clear();
      setState(() => _localError = result.error);
    }
  }

  // ── UI Helpers ─────────────────────────────────────
  Widget _buildSectionTitle(String t, IconData icon, QuantumPalette p) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: p.primary, size: 18),
      const SizedBox(width: 8),
      Text(t, style: GoogleFonts.orbitron(
        color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2,
      )),
    ]);
  }

  Widget _buildTextField(
    String label, IconData icon, TextEditingController ctrl, QuantumPalette p, {
    bool obscure = false, Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: p.textSecondary, fontSize: 12),
        prefixIcon: Icon(icon, color: p.primary.withValues(alpha: 0.7), size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: p.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPrimaryButton(String label, IconData icon, QuantumPalette p, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [p.primary, p.accent]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.4), blurRadius: 12)],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.orbitron(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5,
          )),
        ]),
      ),
    );
  }

  Widget _buildSecondaryButton(String label, IconData icon, QuantumPalette p, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: p.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.primary.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: p.primary, size: 16),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.rajdhani(
            color: p.primary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1,
          )),
        ]),
      ),
    );
  }

  Widget _buildDivider(String label, QuantumPalette p) {
    return Row(children: [
      Expanded(child: Divider(color: p.primary.withValues(alpha: 0.2))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label, style: TextStyle(color: p.textSecondary, fontSize: 11)),
      ),
      Expanded(child: Divider(color: p.primary.withValues(alpha: 0.2))),
    ]);
  }

  Widget _buildError(String msg, QuantumPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.negative.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.negative.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline, color: p.negative, size: 14),
        const SizedBox(width: 6),
        Expanded(child: Text(msg, style: GoogleFonts.rajdhani(color: p.negative, fontSize: 12))),
      ]),
    );
  }
}

// ── Animated Background Painter ───────────────────────
class _AuthBgPainter extends CustomPainter {
  final double t;
  final dynamic p;
  _AuthBgPainter(this.t, this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(42);
    for (int i = 0; i < 8; i++) {
      final x = (rnd.nextDouble() + sin(t * pi + i) * 0.1) * size.width;
      final y = (rnd.nextDouble() + cos(t * pi * 0.7 + i) * 0.1) * size.height;
      final r = 80.0 + rnd.nextDouble() * 120;
      final paint = Paint()
        ..color = (p.primary as Color).withValues(alpha: 0.03 + rnd.nextDouble() * 0.03)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_AuthBgPainter old) => old.t != t;
}
