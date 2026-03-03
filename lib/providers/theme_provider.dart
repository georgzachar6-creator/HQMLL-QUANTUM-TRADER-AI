import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_themes.dart';

class ThemeProvider extends ChangeNotifier {
  QuantumTheme _currentTheme = QuantumTheme.enterprise;
  bool _soundEnabled = true;
  bool _notificationsEnabled = true;
  bool _liveDataEnabled = true;
  bool _godModeEnabled = false;
  bool _quantumAnimations = true;
  double _fontSize = 1.0;
  String _language = 'Deutsch';
  String _currency = 'USD';
  bool _biometricAuth = false;
  bool _twoFactorAuth = false;
  bool _autoTrade = false;
  double _riskLevel = 0.5;
  bool _darkCharts = true;

  QuantumTheme get currentTheme => _currentTheme;
  QuantumPalette get palette => AppThemes.getPalette(_currentTheme);
  ThemeData get themeData => AppThemes.buildTheme(_currentTheme);
  bool get soundEnabled => _soundEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get liveDataEnabled => _liveDataEnabled;
  bool get godModeEnabled => _godModeEnabled;
  bool get quantumAnimations => _quantumAnimations;
  double get fontSize => _fontSize;
  String get language => _language;
  String get currency => _currency;
  bool get biometricAuth => _biometricAuth;
  bool get twoFactorAuth => _twoFactorAuth;
  bool get autoTrade => _autoTrade;
  double get riskLevel => _riskLevel;
  bool get darkCharts => _darkCharts;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('quantum_theme') ?? 0;
    _currentTheme = QuantumTheme.values[themeIndex];
    _soundEnabled = prefs.getBool('sound') ?? true;
    _notificationsEnabled = prefs.getBool('notifications') ?? true;
    _liveDataEnabled = prefs.getBool('live_data') ?? true;
    _quantumAnimations = prefs.getBool('quantum_animations') ?? true;
    _fontSize = prefs.getDouble('font_size') ?? 1.0;
    _language = prefs.getString('language') ?? 'Deutsch';
    _currency = prefs.getString('currency') ?? 'USD';
    _biometricAuth = prefs.getBool('biometric') ?? false;
    _twoFactorAuth = prefs.getBool('two_factor') ?? false;
    _autoTrade = prefs.getBool('auto_trade') ?? false;
    _riskLevel = prefs.getDouble('risk_level') ?? 0.5;
    _darkCharts = prefs.getBool('dark_charts') ?? true;
    notifyListeners();
  }

  Future<void> setTheme(QuantumTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quantum_theme', theme.index);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool v) async {
    _soundEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound', v);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool v) async {
    _notificationsEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', v);
    notifyListeners();
  }

  Future<void> setLiveDataEnabled(bool v) async {
    _liveDataEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('live_data', v);
    notifyListeners();
  }

  Future<void> setGodMode(bool v) async {
    _godModeEnabled = v;
    notifyListeners();
  }

  Future<void> setQuantumAnimations(bool v) async {
    _quantumAnimations = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quantum_animations', v);
    notifyListeners();
  }

  Future<void> setFontSize(double v) async {
    _fontSize = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', v);
    notifyListeners();
  }

  Future<void> setLanguage(String v) async {
    _language = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', v);
    notifyListeners();
  }

  Future<void> setCurrency(String v) async {
    _currency = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', v);
    notifyListeners();
  }

  Future<void> setBiometricAuth(bool v) async {
    _biometricAuth = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric', v);
    notifyListeners();
  }

  Future<void> setTwoFactorAuth(bool v) async {
    _twoFactorAuth = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('two_factor', v);
    notifyListeners();
  }

  Future<void> setAutoTrade(bool v) async {
    _autoTrade = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_trade', v);
    notifyListeners();
  }

  Future<void> setRiskLevel(double v) async {
    _riskLevel = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('risk_level', v);
    notifyListeners();
  }

  Future<void> setDarkCharts(bool v) async {
    _darkCharts = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_charts', v);
    notifyListeners();
  }
}
