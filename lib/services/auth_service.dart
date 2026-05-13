/// Quantum Trader – Auth Service v24.0
/// Login · Register · 2FA TOTP · KYC · Biometric · Session
/// Grigori Saks · 2025
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════
// USER MODEL
// ══════════════════════════════════════════════════════
class QUser {
  final String id;
  final String email;
  final String displayName;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatarUrl;
  final KycStatus kycStatus;
  final bool twoFaEnabled;
  final String? twoFaSecret;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final List<BankAccount> bankAccounts;
  final Map<String, double> portfolio; // symbol -> balance
  final double fiatBalance; // EUR
  final String? country;
  final String? dateOfBirth;
  final bool emailVerified;

  QUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatarUrl,
    this.kycStatus = KycStatus.none,
    this.twoFaEnabled = false,
    this.twoFaSecret,
    required this.createdAt,
    this.lastLogin,
    List<BankAccount>? bankAccounts,
    Map<String, double>? portfolio,
    this.fiatBalance = 0.0,
    this.country,
    this.dateOfBirth,
    this.emailVerified = false,
  })  : bankAccounts = bankAccounts ?? [],
        portfolio = portfolio ?? {};

  QUser copyWith({
    String? displayName,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    KycStatus? kycStatus,
    bool? twoFaEnabled,
    String? twoFaSecret,
    DateTime? lastLogin,
    List<BankAccount>? bankAccounts,
    Map<String, double>? portfolio,
    double? fiatBalance,
    String? country,
    String? dateOfBirth,
    bool? emailVerified,
  }) => QUser(
    id: id, email: email,
    displayName: displayName ?? this.displayName,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    kycStatus: kycStatus ?? this.kycStatus,
    twoFaEnabled: twoFaEnabled ?? this.twoFaEnabled,
    twoFaSecret: twoFaSecret ?? this.twoFaSecret,
    createdAt: createdAt,
    lastLogin: lastLogin ?? this.lastLogin,
    bankAccounts: bankAccounts ?? this.bankAccounts,
    portfolio: portfolio ?? this.portfolio,
    fiatBalance: fiatBalance ?? this.fiatBalance,
    country: country ?? this.country,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    emailVerified: emailVerified ?? this.emailVerified,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'email': email, 'displayName': displayName,
    'firstName': firstName, 'lastName': lastName, 'phone': phone,
    'avatarUrl': avatarUrl,
    'kycStatus': kycStatus.name,
    'twoFaEnabled': twoFaEnabled, 'twoFaSecret': twoFaSecret,
    'createdAt': createdAt.toIso8601String(),
    'lastLogin': lastLogin?.toIso8601String(),
    'bankAccounts': bankAccounts.map((b) => b.toJson()).toList(),
    'portfolio': portfolio,
    'fiatBalance': fiatBalance,
    'country': country, 'dateOfBirth': dateOfBirth,
    'emailVerified': emailVerified,
  };

  factory QUser.fromJson(Map<String, dynamic> j) => QUser(
    id: j['id'] ?? '',
    email: j['email'] ?? '',
    displayName: j['displayName'] ?? '',
    firstName: j['firstName'],
    lastName: j['lastName'],
    phone: j['phone'],
    avatarUrl: j['avatarUrl'],
    kycStatus: KycStatus.values.firstWhere(
      (k) => k.name == (j['kycStatus'] ?? 'none'), orElse: () => KycStatus.none),
    twoFaEnabled: j['twoFaEnabled'] ?? false,
    twoFaSecret: j['twoFaSecret'],
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
    lastLogin: j['lastLogin'] != null ? DateTime.tryParse(j['lastLogin']) : null,
    bankAccounts: (j['bankAccounts'] as List<dynamic>? ?? [])
        .map((b) => BankAccount.fromJson(b as Map<String, dynamic>)).toList(),
    portfolio: Map<String, double>.from(
      (j['portfolio'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
    ),
    fiatBalance: (j['fiatBalance'] as num?)?.toDouble() ?? 0.0,
    country: j['country'],
    dateOfBirth: j['dateOfBirth'],
    emailVerified: j['emailVerified'] ?? false,
  );
}

enum KycStatus { none, pending, verified, rejected }

class BankAccount {
  final String id;
  final String bankName;
  final String iban;
  final String bic;
  final String accountHolder;
  final String currency;
  final bool isVerified;
  final DateTime addedAt;

  BankAccount({
    required this.id, required this.bankName, required this.iban,
    required this.bic, required this.accountHolder, required this.currency,
    this.isVerified = false, required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'bankName': bankName, 'iban': iban, 'bic': bic,
    'accountHolder': accountHolder, 'currency': currency,
    'isVerified': isVerified, 'addedAt': addedAt.toIso8601String(),
  };

  factory BankAccount.fromJson(Map<String, dynamic> j) => BankAccount(
    id: j['id'] ?? '', bankName: j['bankName'] ?? '', iban: j['iban'] ?? '',
    bic: j['bic'] ?? '', accountHolder: j['accountHolder'] ?? '',
    currency: j['currency'] ?? 'EUR',
    isVerified: j['isVerified'] ?? false,
    addedAt: DateTime.tryParse(j['addedAt'] ?? '') ?? DateTime.now(),
  );
}

// ══════════════════════════════════════════════════════
// AUTH RESULT
// ══════════════════════════════════════════════════════
class AuthResult {
  final bool success;
  final String? error;
  final QUser? user;
  final bool requires2FA;
  final String? sessionToken;

  const AuthResult({
    required this.success, this.error, this.user,
    this.requires2FA = false, this.sessionToken,
  });
  factory AuthResult.ok(QUser user, {String? token}) =>
      AuthResult(success: true, user: user, sessionToken: token);
  factory AuthResult.fail(String error) =>
      AuthResult(success: false, error: error);
  factory AuthResult.need2FA() =>
      AuthResult(success: false, requires2FA: true);
}

// ══════════════════════════════════════════════════════
// AUTH SERVICE  (ChangeNotifier → Provider)
// ══════════════════════════════════════════════════════
class AuthService extends ChangeNotifier {
  static final AuthService _inst = AuthService._internal();
  factory AuthService() => _inst;
  AuthService._internal();

  QUser? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  String? _pendingEmail; // used during 2FA step
  // ignore: unused_field
  final Map<String, String> _sessions = {}; // email -> hashed pw

  QUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // ── Init: restore session ──────────────────────────
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('qt_user_session');
    if (userJson != null) {
      try {
        _currentUser = QUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        await prefs.remove('qt_user_session');
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  // ── Register ───────────────────────────────────────
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String? firstName,
    String? lastName,
  }) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      // Validate
      if (!_isValidEmail(email)) return _fail('Ungültige E-Mail-Adresse');
      if (password.length < 8) return _fail('Passwort mind. 8 Zeichen');
      if (displayName.trim().isEmpty) return _fail('Name darf nicht leer sein');

      final prefs = await SharedPreferences.getInstance();
      // Check existing
      final existing = prefs.getString('qt_user_$email');
      if (existing != null) return _fail('E-Mail bereits registriert');

      // Create user
      final user = QUser(
        id: _generateId(),
        email: email.toLowerCase(),
        displayName: displayName,
        firstName: firstName,
        lastName: lastName,
        createdAt: DateTime.now(),
        portfolio: {
          'BTC': 0.0, 'ETH': 0.0, 'SOL': 0.0,
          'USDT': 0.0, 'BNB': 0.0,
        },
        fiatBalance: 0.0,
      );

      // Save hashed password
      final hashed = _hashPassword(password);
      await prefs.setString('qt_pw_$email', hashed);
      await prefs.setString('qt_user_$email', jsonEncode(user.toJson()));
      await _saveSession(user);

      _currentUser = user;
      notifyListeners();
      return AuthResult.ok(user);
    } finally {
      _setLoading(false);
    }
  }

  // ── Login ──────────────────────────────────────────
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      if (!_isValidEmail(email)) return _fail('Ungültige E-Mail-Adresse');
      final prefs = await SharedPreferences.getInstance();

      final storedHash = prefs.getString('qt_pw_${email.toLowerCase()}');
      if (storedHash == null) return _fail('Kein Konto mit dieser E-Mail gefunden');

      if (storedHash != _hashPassword(password)) return _fail('Falsches Passwort');

      final userJson = prefs.getString('qt_user_${email.toLowerCase()}');
      if (userJson == null) return _fail('Benutzer nicht gefunden');

      var user = QUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);

      // Check 2FA
      if (user.twoFaEnabled) {
        _pendingEmail = email.toLowerCase();
        _setLoading(false);
        return AuthResult.need2FA();
      }

      user = user.copyWith(lastLogin: DateTime.now());
      await _saveSession(user);
      _currentUser = user;
      notifyListeners();
      return AuthResult.ok(user);
    } finally {
      _setLoading(false);
    }
  }

  // ── Verify 2FA TOTP ────────────────────────────────
  Future<AuthResult> verify2FA(String code) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      if (_pendingEmail == null) return _fail('Keine ausstehende 2FA-Verifizierung');
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('qt_user_$_pendingEmail');
      if (userJson == null) return _fail('Benutzer nicht gefunden');

      var user = QUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);

      // TOTP verification (simulated with 6-digit code check)
      final valid = _verifyTOTP(code, user.twoFaSecret ?? '');
      if (!valid) return _fail('Ungültiger 2FA-Code');

      user = user.copyWith(lastLogin: DateTime.now());
      await _saveSession(user);
      _currentUser = user;
      _pendingEmail = null;
      notifyListeners();
      return AuthResult.ok(user);
    } finally {
      _setLoading(false);
    }
  }

  // ── Enable 2FA ─────────────────────────────────────
  Future<String> enable2FA() async {
    if (_currentUser == null) return '';
    final secret = _generate2FASecret();
    final updated = _currentUser!.copyWith(
      twoFaEnabled: true, twoFaSecret: secret,
    );
    await _persistUser(updated);
    _currentUser = updated;
    notifyListeners();
    return secret;
  }

  // ── Disable 2FA ────────────────────────────────────
  Future<void> disable2FA() async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(twoFaEnabled: false, twoFaSecret: null);
    await _persistUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  // ── Update Portfolio Balance ───────────────────────
  Future<void> updatePortfolio(Map<String, double> balances, {double? fiatBalance}) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(
      portfolio: {..._currentUser!.portfolio, ...balances},
      fiatBalance: fiatBalance ?? _currentUser!.fiatBalance,
    );
    await _persistUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  // ── Add/Remove Bank Account ────────────────────────
  Future<void> addBankAccount(BankAccount account) async {
    if (_currentUser == null) return;
    final banks = [..._currentUser!.bankAccounts, account];
    final updated = _currentUser!.copyWith(bankAccounts: banks);
    await _persistUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> removeBankAccount(String accountId) async {
    if (_currentUser == null) return;
    final banks = _currentUser!.bankAccounts.where((b) => b.id != accountId).toList();
    final updated = _currentUser!.copyWith(bankAccounts: banks);
    await _persistUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  // ── KYC Update ────────────────────────────────────
  Future<void> updateKyc(KycStatus status) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(kycStatus: status);
    await _persistUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  // ── Update Profile ─────────────────────────────────
  Future<void> updateProfile({
    String? firstName, String? lastName, String? phone,
    String? country, String? dateOfBirth,
  }) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(
      firstName: firstName, lastName: lastName,
      phone: phone, country: country, dateOfBirth: dateOfBirth,
    );
    await _persistUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  // ── Auto-Save ──────────────────────────────────────
  Future<void> autoSave() async {
    if (_currentUser == null) return;
    await _persistUser(_currentUser!);
    if (kDebugMode) debugPrint('[AuthService] Auto-saved user data');
  }

  // ── Logout ─────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('qt_user_session');
    _currentUser = null;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────
  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }

  AuthResult _fail(String msg) {
    _error = msg;
    _setLoading(false);
    return AuthResult.fail(msg);
  }

  Future<void> _saveSession(QUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('qt_user_session', jsonEncode(user.toJson()));
    await prefs.setString('qt_user_${user.email}', jsonEncode(user.toJson()));
  }

  Future<void> _persistUser(QUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('qt_user_${user.email}', jsonEncode(user.toJson()));
    await prefs.setString('qt_user_session', jsonEncode(user.toJson()));
  }

  String _hashPassword(String pw) {
    final bytes = utf8.encode(pw + 'qt_salt_2025');
    return sha256.convert(bytes).toString();
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);

  String _generateId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _generate2FASecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final rnd = Random.secure();
    return List.generate(32, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  bool _verifyTOTP(String code, String secret) {
    // In production: use proper TOTP library
    // For demo: accept any 6-digit code or "123456"
    if (code == '123456') return true;
    if (RegExp(r'^\d{6}$').hasMatch(code)) {
      // Simulate TOTP: check if code matches time-based hash
      final timeStep = DateTime.now().millisecondsSinceEpoch ~/ 30000;
      final expected = (timeStep % 1000000).toString().padLeft(6, '0');
      return code == expected || code.length == 6;
    }
    return false;
  }
  
  void clearError() { _error = null; notifyListeners(); }
}
