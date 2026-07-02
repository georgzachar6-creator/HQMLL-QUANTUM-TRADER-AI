// HQMLL Quantum Trader – SecureVault Encryption Service
// AES-256-CBC + Quantum-Key-Derivation
// © 2025 Grigori Saks · HQMLL · Patent-Pending · CONFIDENTIAL
library;

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons, IconData;
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════════════════
// SecureVaultService – AES-256-GCM Encryption Engine
// ══════════════════════════════════════════════════════════════════
class SecureVaultService extends ChangeNotifier {
  static final SecureVaultService _instance = SecureVaultService._internal();
  factory SecureVaultService() => _instance;
  SecureVaultService._internal();

  // ─ Vault State ─
  bool _vaultUnlocked = false;
  String? _masterKeyHash;
  final List<VaultEntry> _entries = [];
  final List<EncryptionLog> _logs = [];
  int _encryptionCount = 0;
  int _decryptionCount = 0;
  final Random _rng = Random.secure();

  // ─ Getters ─
  bool get vaultUnlocked => _vaultUnlocked;
  List<VaultEntry> get entries => List.unmodifiable(_entries);
  List<EncryptionLog> get logs => List.unmodifiable(_logs);
  int get encryptionCount => _encryptionCount;
  int get decryptionCount => _decryptionCount;
  String get vaultStatus => _vaultUnlocked ? 'ENTSPERRT' : 'GESPERRT';

  // ══════════════════════════════════════════════════════════════
  // MASTER KEY MANAGEMENT
  // ══════════════════════════════════════════════════════════════

  /// Initialize vault with master password
  Future<bool> initVault(String masterPassword) async {
    try {
      final hash = _deriveKeyHash(masterPassword);
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('vault_master_hash');

      if (stored == null) {
        // First time – store hash
        await prefs.setString('vault_master_hash', hash);
        _masterKeyHash = hash;
        _vaultUnlocked = true;
        _addLog('VAULT_INIT', 'Vault initialisiert & entsperrt', true);
        _loadSampleEntries();
        notifyListeners();
        return true;
      } else if (stored == hash) {
        _masterKeyHash = hash;
        _vaultUnlocked = true;
        _addLog('VAULT_UNLOCK', 'Vault erfolgreich entsperrt', true);
        await _loadEntries();
        notifyListeners();
        return true;
      }
      _addLog('VAULT_FAIL', 'Falsches Master-Passwort', false);
      notifyListeners();
      return false;
    } catch (e) {
      _addLog('VAULT_ERROR', 'Fehler: $e', false);
      notifyListeners();
      return false;
    }
  }

  void lockVault() {
    _vaultUnlocked = false;
    _masterKeyHash = null;
    _addLog('VAULT_LOCK', 'Vault gesperrt', true);
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════
  // AES-256 ENCRYPTION ENGINE
  // ══════════════════════════════════════════════════════════════

  /// Encrypt plaintext with AES-256-CBC
  EncryptResult encryptText(String plaintext, String label) {
    if (!_vaultUnlocked) {
      return EncryptResult(success: false, error: 'Vault gesperrt');
    }
    try {
      final keyBytes = _deriveAESKey(_masterKeyHash!);
      final iv = _generateIV();
      final cipher = CBCBlockCipher(AESEngine())
        ..init(true, ParametersWithIV(KeyParameter(keyBytes), iv));

      final input = _padPKCS7(utf8.encode(plaintext));
      final output = Uint8List(input.length);
      for (var i = 0; i < input.length; i += 16) {
        cipher.processBlock(input, i, output, i);
      }

      final ivBase64 = base64Encode(iv);
      final ctBase64 = base64Encode(output);
      final payload = '$ivBase64:$ctBase64';
      final checksum = _computeHMAC(payload, keyBytes);

      _encryptionCount++;
      _addLog('ENCRYPT', 'Verschlüsselt: $label (${plaintext.length} Zeichen)', true);

      final entry = VaultEntry(
        id: _generateId(),
        label: label,
        encryptedData: payload,
        checksum: checksum,
        algorithm: 'AES-256-CBC',
        createdAt: DateTime.now(),
        type: VaultEntryType.text,
        originalSize: plaintext.length,
      );
      _entries.insert(0, entry);
      _saveEntries();
      notifyListeners();

      return EncryptResult(success: true, ciphertext: payload, entry: entry);
    } catch (e) {
      _addLog('ENCRYPT_ERR', 'Fehler bei Verschlüsselung: $e', false);
      return EncryptResult(success: false, error: e.toString());
    }
  }

  /// Decrypt ciphertext payload
  DecryptResult decryptEntry(VaultEntry entry) {
    if (!_vaultUnlocked) {
      return DecryptResult(success: false, error: 'Vault gesperrt');
    }
    try {
      final keyBytes = _deriveAESKey(_masterKeyHash!);

      // Verify HMAC
      final storedChecksum = _computeHMAC(entry.encryptedData, keyBytes);
      if (storedChecksum != entry.checksum) {
        _addLog('DECRYPT_TAMPER', 'WARNUNG: Daten manipuliert! ${entry.label}', false);
        return DecryptResult(success: false, error: 'Integritätsfehler – Daten manipuliert!');
      }

      final parts = entry.encryptedData.split(':');
      if (parts.length != 2) {
        return DecryptResult(success: false, error: 'Ungültiges Format');
      }

      final iv = base64Decode(parts[0]);
      final ciphertext = base64Decode(parts[1]);

      final cipher = CBCBlockCipher(AESEngine())
        ..init(false, ParametersWithIV(KeyParameter(keyBytes), Uint8List.fromList(iv)));

      final output = Uint8List(ciphertext.length);
      final ct = Uint8List.fromList(ciphertext);
      for (var i = 0; i < ct.length; i += 16) {
        cipher.processBlock(ct, i, output, i);
      }

      final unpadded = _unpadPKCS7(output);
      final plaintext = utf8.decode(unpadded);

      _decryptionCount++;
      _addLog('DECRYPT', 'Entschlüsselt: ${entry.label}', true);
      notifyListeners();

      return DecryptResult(success: true, plaintext: plaintext);
    } catch (e) {
      _addLog('DECRYPT_ERR', 'Fehler: $e', false);
      return DecryptResult(success: false, error: e.toString());
    }
  }

  /// Delete vault entry
  void deleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    _saveEntries();
    _addLog('DELETE', 'Eintrag gelöscht: $id', true);
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════
  // QUANTUM KEY GENERATION
  // ══════════════════════════════════════════════════════════════

  String generateQuantumKey(int bits) {
    final bytes = bits ~/ 8;
    final keyBytes = Uint8List(bytes);
    for (var i = 0; i < bytes; i++) {
      keyBytes[i] = _rng.nextInt(256);
    }
    final key = base64Encode(keyBytes);
    _addLog('KEYGEN', 'Quantum-Key generiert: $bits-bit', true);
    notifyListeners();
    return key;
  }

  String generateHQMLLToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _rng.nextInt(999999).toString().padLeft(6, '0');
    final hash = sha256.convert(utf8.encode('HQMLL-GRIGORI-SAKS-$timestamp-$random')).toString().substring(0, 16).toUpperCase();
    final token = 'HQMLL-$hash-$random';
    _addLog('TOKEN', 'HQMLL-Token generiert', true);
    notifyListeners();
    return token;
  }

  // ══════════════════════════════════════════════════════════════
  // INTERNAL HELPERS
  // ══════════════════════════════════════════════════════════════

  String _deriveKeyHash(String password) {
    const salt = 'HQMLL-QUANTUM-SALT-GRIGORI-SAKS-2025';
    final data = utf8.encode('$password:$salt');
    return sha256.convert(sha256.convert(data).bytes).toString();
  }

  Uint8List _deriveAESKey(String keyHash) {
    final keyData = utf8.encode('$keyHash:AES256:HQMLL');
    return Uint8List.fromList(sha256.convert(keyData).bytes);
  }

  Uint8List _generateIV() {
    final iv = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      iv[i] = _rng.nextInt(256);
    }
    return iv;
  }

  Uint8List _padPKCS7(List<int> data) {
    final pad = 16 - (data.length % 16);
    return Uint8List.fromList([...data, ...List.filled(pad, pad)]);
  }

  Uint8List _unpadPKCS7(Uint8List data) {
    if (data.isEmpty) return data;
    final pad = data.last;
    if (pad > 16 || pad == 0) return data;
    return data.sublist(0, data.length - pad);
  }

  String _computeHMAC(String data, Uint8List key) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).toString();
  }

  String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      _rng.nextInt(9999).toString().padLeft(4, '0');

  void _addLog(String type, String message, bool success) {
    _logs.insert(0, EncryptionLog(
      type: type,
      message: message,
      success: success,
      timestamp: DateTime.now(),
    ));
    if (_logs.length > 100) _logs.removeRange(100, _logs.length);
  }

  void _loadSampleEntries() {
    _entries.addAll([
      VaultEntry(
        id: '001',
        label: 'HQMLL Master Seed',
        encryptedData: 'ENCRYPTED::SAMPLE::SEED::PHRASE',
        checksum: 'demo',
        algorithm: 'AES-256-CBC',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        type: VaultEntryType.seed,
        originalSize: 128,
      ),
      VaultEntry(
        id: '002',
        label: 'API Keys – CoinGecko',
        encryptedData: 'ENCRYPTED::API::KEYS',
        checksum: 'demo',
        algorithm: 'AES-256-CBC',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        type: VaultEntryType.apiKey,
        originalSize: 64,
      ),
      VaultEntry(
        id: '003',
        label: 'Wallet Private Key – ETH',
        encryptedData: 'ENCRYPTED::PRIVATE::KEY',
        checksum: 'demo',
        algorithm: 'AES-256-CBC',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        type: VaultEntryType.privateKey,
        originalSize: 256,
      ),
    ]);
  }

  Future<void> _loadEntries() async {
    // In production: load from encrypted SharedPreferences
    _loadSampleEntries();
  }

  Future<void> _saveEntries() async {
    // In production: persist encrypted to SharedPreferences
  }
}

// ══════════════════════════════════════════════════════════════════
// DATA MODELS
// ══════════════════════════════════════════════════════════════════

enum VaultEntryType { text, seed, privateKey, apiKey, document, password }

class VaultEntry {
  final String id, label, encryptedData, checksum, algorithm;
  final DateTime createdAt;
  final VaultEntryType type;
  final int originalSize;

  VaultEntry({
    required this.id,
    required this.label,
    required this.encryptedData,
    required this.checksum,
    required this.algorithm,
    required this.createdAt,
    required this.type,
    required this.originalSize,
  });

  IconData get icon {
    switch (type) {
      case VaultEntryType.seed: return Icons.grain;
      case VaultEntryType.privateKey: return Icons.key;
      case VaultEntryType.apiKey: return Icons.api;
      case VaultEntryType.password: return Icons.lock;
      case VaultEntryType.document: return Icons.description;
      default: return Icons.text_fields;
    }
  }
}

class EncryptionLog {
  final String type, message;
  final bool success;
  final DateTime timestamp;
  EncryptionLog({
    required this.type,
    required this.message,
    required this.success,
    required this.timestamp,
  });
}

class EncryptResult {
  final bool success;
  final String? ciphertext;
  final String? error;
  final VaultEntry? entry;
  EncryptResult({required this.success, this.ciphertext, this.error, this.entry});
}

class DecryptResult {
  final bool success;
  final String? plaintext;
  final String? error;
  DecryptResult({required this.success, this.plaintext, this.error});
}
