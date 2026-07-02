// HQMLL Quantum Trader — KYC/AML Service v51.0
// Basiert auf: Perplexity AI Training Platform Architecture
// EU-konform: AMLR, MiCA, MiFID II — Onboarding, Monitoring, Travel Rule
// Grigori Saks · 2025
library;

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ══════════════════════════════════════════════════════════════════════════
// ENUMS
// ══════════════════════════════════════════════════════════════════════════

enum KycStatus { notStarted, inProgress, pending, approved, rejected, expired }
enum KycTier { basic, standard, advanced, institutional }
enum AmlRiskRating { low, medium, high, veryHigh, prohibited }
enum TransactionRiskFlag { clean, suspicious, underMonitoring, reported, blocked }
enum IdDocumentType { passport, nationalId, drivingLicense, residencePermit }
enum SarStatus { detected, reported, cleared }

extension KycStatusX on KycStatus {
  String get label => const {
    KycStatus.notStarted: 'Nicht begonnen',
    KycStatus.inProgress: 'In Bearbeitung',
    KycStatus.pending: 'Ausstehend',
    KycStatus.approved: 'Genehmigt',
    KycStatus.rejected: 'Abgelehnt',
    KycStatus.expired: 'Abgelaufen',
  }[this] ?? 'Unbekannt';

  String get emoji => const {
    KycStatus.notStarted: '⭕',
    KycStatus.inProgress: '🔄',
    KycStatus.pending: '⏳',
    KycStatus.approved: '✅',
    KycStatus.rejected: '❌',
    KycStatus.expired: '⏰',
  }[this] ?? '❓';

  bool get isVerified => this == KycStatus.approved;
}

extension KycTierX on KycTier {
  String get label => const {
    KycTier.basic: 'Basic (€1.000/Tag)',
    KycTier.standard: 'Standard (€10.000/Tag)',
    KycTier.advanced: 'Advanced (€50.000/Tag)',
    KycTier.institutional: 'Institutionell (Unbegrenzt)',
  }[this] ?? 'Basic';

  double get dailyLimitEur => const {
    KycTier.basic: 1000.0,
    KycTier.standard: 10000.0,
    KycTier.advanced: 50000.0,
    KycTier.institutional: double.infinity,
  }[this] ?? 1000.0;

  double get transactionLimitEur => const {
    KycTier.basic: 500.0,
    KycTier.standard: 5000.0,
    KycTier.advanced: 20000.0,
    KycTier.institutional: double.infinity,
  }[this] ?? 500.0;

  bool get cryptoEnabled => this != KycTier.basic;
  bool get derivativesEnabled =>
      this == KycTier.advanced || this == KycTier.institutional;
}

extension AmlRiskRatingX on AmlRiskRating {
  String get label => const {
    AmlRiskRating.low: 'Niedrig',
    AmlRiskRating.medium: 'Mittel',
    AmlRiskRating.high: 'Hoch',
    AmlRiskRating.veryHigh: 'Sehr Hoch',
    AmlRiskRating.prohibited: 'GESPERRT',
  }[this] ?? 'Mittel';

  String get emoji => const {
    AmlRiskRating.low: '🟢',
    AmlRiskRating.medium: '🟡',
    AmlRiskRating.high: '🟠',
    AmlRiskRating.veryHigh: '🔴',
    AmlRiskRating.prohibited: '⛔',
  }[this] ?? '🟡';

  bool get canTrade =>
      this != AmlRiskRating.prohibited && this != AmlRiskRating.veryHigh;

  bool get requiresEnhancedDueDiligence =>
      this == AmlRiskRating.high ||
      this == AmlRiskRating.veryHigh ||
      this == AmlRiskRating.prohibited;
}

// ══════════════════════════════════════════════════════════════════════════
// MODELLE
// ══════════════════════════════════════════════════════════════════════════

class KycDocument {
  final String id;
  final IdDocumentType type;
  final String documentNumber;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String issuingCountry;
  final bool verified;

  const KycDocument({
    required this.id,
    required this.type,
    required this.documentNumber,
    required this.issuedAt,
    required this.expiresAt,
    required this.issuingCountry,
    required this.verified,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => verified && !isExpired;

  String get typeLabel => const {
    IdDocumentType.passport: 'Reisepass',
    IdDocumentType.nationalId: 'Personalausweis',
    IdDocumentType.drivingLicense: 'Führerschein',
    IdDocumentType.residencePermit: 'Aufenthaltstitel',
  }[type] ?? 'Dokument';

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type.name, 'documentNumber': documentNumber,
    'issuedAt': issuedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'issuingCountry': issuingCountry, 'verified': verified,
  };

  factory KycDocument.fromJson(Map<String, dynamic> j) => KycDocument(
    id: j['id'] as String? ?? '',
    type: IdDocumentType.values.firstWhere(
      (t) => t.name == j['type'], orElse: () => IdDocumentType.passport),
    documentNumber: j['documentNumber'] as String? ?? '',
    issuedAt: DateTime.tryParse(j['issuedAt'] as String? ?? '') ?? DateTime.now(),
    expiresAt: DateTime.tryParse(j['expiresAt'] as String? ?? '') ?? DateTime.now(),
    issuingCountry: j['issuingCountry'] as String? ?? 'DE',
    verified: j['verified'] as bool? ?? false,
  );
}

// ──────────────────────────────────────────────────────────────────────────
class KycProfile {
  final String userId;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String nationality;
  final String country;
  final String address;
  final String email;
  final KycStatus status;
  final KycTier tier;
  final List<KycDocument> documents;
  final bool pepStatus; // Politically Exposed Person
  final bool sanctionsHit;
  final DateTime? approvedAt;
  final DateTime? expiresAt;
  final String? rejectionReason;

  const KycProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.nationality,
    required this.country,
    required this.address,
    required this.email,
    required this.status,
    required this.tier,
    required this.documents,
    required this.pepStatus,
    required this.sanctionsHit,
    this.approvedAt,
    this.expiresAt,
    this.rejectionReason,
  });

  String get fullName => '$firstName $lastName';
  bool get isVerified => status == KycStatus.approved;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toJson() => {
    'userId': userId, 'firstName': firstName, 'lastName': lastName,
    'dateOfBirth': dateOfBirth.toIso8601String(),
    'nationality': nationality, 'country': country,
    'address': address, 'email': email,
    'status': status.name, 'tier': tier.name,
    'documents': documents.map((d) => d.toJson()).toList(),
    'pepStatus': pepStatus, 'sanctionsHit': sanctionsHit,
    'approvedAt': approvedAt?.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'rejectionReason': rejectionReason,
  };

  factory KycProfile.fromJson(Map<String, dynamic> j) => KycProfile(
    userId: j['userId'] as String? ?? '',
    firstName: j['firstName'] as String? ?? '',
    lastName: j['lastName'] as String? ?? '',
    dateOfBirth: DateTime.tryParse(j['dateOfBirth'] as String? ?? '') ??
        DateTime(1990, 1, 1),
    nationality: j['nationality'] as String? ?? 'DE',
    country: j['country'] as String? ?? 'DE',
    address: j['address'] as String? ?? '',
    email: j['email'] as String? ?? '',
    status: KycStatus.values.firstWhere(
      (s) => s.name == j['status'], orElse: () => KycStatus.notStarted),
    tier: KycTier.values.firstWhere(
      (t) => t.name == j['tier'], orElse: () => KycTier.basic),
    documents: (j['documents'] as List<dynamic>? ?? [])
        .map((d) => KycDocument.fromJson(d as Map<String, dynamic>)).toList(),
    pepStatus: j['pepStatus'] as bool? ?? false,
    sanctionsHit: j['sanctionsHit'] as bool? ?? false,
    approvedAt: DateTime.tryParse(j['approvedAt'] as String? ?? ''),
    expiresAt: DateTime.tryParse(j['expiresAt'] as String? ?? ''),
    rejectionReason: j['rejectionReason'] as String?,
  );

  KycProfile copyWith({
    KycStatus? status, KycTier? tier,
    bool? pepStatus, bool? sanctionsHit,
    DateTime? approvedAt, DateTime? expiresAt,
    String? rejectionReason, List<KycDocument>? documents,
  }) => KycProfile(
    userId: userId, firstName: firstName, lastName: lastName,
    dateOfBirth: dateOfBirth, nationality: nationality,
    country: country, address: address, email: email,
    status: status ?? this.status, tier: tier ?? this.tier,
    documents: documents ?? this.documents,
    pepStatus: pepStatus ?? this.pepStatus,
    sanctionsHit: sanctionsHit ?? this.sanctionsHit,
    approvedAt: approvedAt ?? this.approvedAt,
    expiresAt: expiresAt ?? this.expiresAt,
    rejectionReason: rejectionReason ?? this.rejectionReason,
  );
}

// ──────────────────────────────────────────────────────────────────────────
class AmlTransaction {
  final String id;
  final String userId;
  final String symbol;
  final double amountEur;
  final String direction; // DEPOSIT / WITHDRAWAL / TRADE / SWAP
  final String? counterpartyAddress;
  final String? counterpartyName;
  final TransactionRiskFlag riskFlag;
  final double riskScore; // 0–100
  final List<String> flagReasons;
  final DateTime executedAt;

  const AmlTransaction({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.amountEur,
    required this.direction,
    this.counterpartyAddress,
    this.counterpartyName,
    required this.riskFlag,
    required this.riskScore,
    required this.flagReasons,
    required this.executedAt,
  });

  bool get isSuspicious => riskScore >= 70;
  bool get requiresTravelRule => amountEur >= 1000.0; // EU Travel Rule €1.000+

  String get flagLabel => const {
    TransactionRiskFlag.clean: 'OK',
    TransactionRiskFlag.suspicious: 'Verdächtig',
    TransactionRiskFlag.underMonitoring: 'Beobachtet',
    TransactionRiskFlag.reported: 'Gemeldet',
    TransactionRiskFlag.blocked: 'GEBLOCKT',
  }[riskFlag] ?? 'OK';

  Map<String, dynamic> toJson() => {
    'id': id, 'userId': userId, 'symbol': symbol,
    'amountEur': amountEur, 'direction': direction,
    'counterpartyAddress': counterpartyAddress,
    'counterpartyName': counterpartyName,
    'riskFlag': riskFlag.name, 'riskScore': riskScore,
    'flagReasons': flagReasons,
    'executedAt': executedAt.toIso8601String(),
  };

  factory AmlTransaction.fromJson(Map<String, dynamic> j) => AmlTransaction(
    id: j['id'] as String? ?? '',
    userId: j['userId'] as String? ?? '',
    symbol: j['symbol'] as String? ?? '',
    amountEur: (j['amountEur'] as num?)?.toDouble() ?? 0.0,
    direction: j['direction'] as String? ?? 'TRADE',
    counterpartyAddress: j['counterpartyAddress'] as String?,
    counterpartyName: j['counterpartyName'] as String?,
    riskFlag: TransactionRiskFlag.values.firstWhere(
      (f) => f.name == j['riskFlag'], orElse: () => TransactionRiskFlag.clean),
    riskScore: (j['riskScore'] as num?)?.toDouble() ?? 0.0,
    flagReasons: List<String>.from(j['flagReasons'] as List<dynamic>? ?? []),
    executedAt: DateTime.tryParse(j['executedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

// ──────────────────────────────────────────────────────────────────────────
class SuspiciousActivityReport {
  final String id;
  final String userId;
  final String transactionId;
  final String description;
  final SarStatus status;
  final DateTime detectedAt;
  final DateTime? reportedAt;

  const SuspiciousActivityReport({
    required this.id,
    required this.userId,
    required this.transactionId,
    required this.description,
    required this.status,
    required this.detectedAt,
    this.reportedAt,
  });

  String get statusLabel => const {
    SarStatus.detected: 'Erkannt',
    SarStatus.reported: 'Gemeldet (FIU)',
    SarStatus.cleared: 'Geklärt',
  }[status] ?? 'Erkannt';
}

// ══════════════════════════════════════════════════════════════════════════
// KYC/AML SERVICE
// ══════════════════════════════════════════════════════════════════════════
class KycAmlService extends ChangeNotifier {
  static const _kKycProfile = 'qt_kyc_profile_v51';
  static const _kAmlTxns    = 'qt_aml_transactions_v51';
  static const _kSars       = 'qt_sars_v51'; // ignore: unused_field

  KycProfile? _currentProfile;
  AmlRiskRating _userRiskRating = AmlRiskRating.low;
  final List<AmlTransaction> _transactions = [];
  final List<SuspiciousActivityReport> _sars = [];
  bool _isLoading = false;

  // ── Getters ──────────────────────────────────────────────────────────────
  KycProfile? get currentProfile => _currentProfile;
  AmlRiskRating get userRiskRating => _userRiskRating;
  List<AmlTransaction> get transactions => List.unmodifiable(_transactions);
  List<SuspiciousActivityReport> get sars => List.unmodifiable(_sars);
  bool get isLoading => _isLoading;

  bool get isKycVerified => _currentProfile?.isVerified ?? false;
  KycTier get currentTier =>
      _currentProfile?.tier ?? KycTier.basic;
  KycStatus get kycStatus =>
      _currentProfile?.status ?? KycStatus.notStarted;

  List<AmlTransaction> get suspiciousTransactions =>
      _transactions.where((t) => t.isSuspicious).toList();

  int get pendingSarCount =>
      _sars.where((s) => s.status == SarStatus.detected).length;

  double get totalVolumeEur30d {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _transactions
        .where((t) => t.executedAt.isAfter(cutoff))
        .fold(0.0, (s, t) => s + t.amountEur);
  }

  KycAmlService() { _load(); }

  // ══════════════════════════════════════════════════════════════════════════
  // ONBOARDING / KYC
  // ══════════════════════════════════════════════════════════════════════════
  Future<KycProfile> startKycOnboarding({
    required String userId,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String nationality,
    required String country,
    required String address,
    required String email,
  }) async {
    _isLoading = true;
    notifyListeners();

    // PEP / Sanctions Screening (simuliert)
    final isPep = _simulatePepCheck(firstName, lastName, country);
    final hasSanctions = _simulateSanctionsCheck(firstName, lastName, country);

    final profile = KycProfile(
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      nationality: nationality,
      country: country,
      address: address,
      email: email,
      status: isPep || hasSanctions
          ? KycStatus.pending
          : KycStatus.inProgress,
      tier: KycTier.basic,
      documents: [],
      pepStatus: isPep,
      sanctionsHit: hasSanctions,
    );

    _currentProfile = profile;
    _userRiskRating = _computeRiskRating(profile);

    await _saveProfile();
    _isLoading = false;
    notifyListeners();

    if (kDebugMode) debugPrint('KYC Onboarding gestartet: $userId');
    return profile;
  }

  Future<void> submitDocument(KycDocument doc) async {
    if (_currentProfile == null) return;

    final docs = [..._currentProfile!.documents, doc];
    _currentProfile = _currentProfile!.copyWith(
      documents: docs,
      status: KycStatus.pending,
    );

    await _saveProfile();
    notifyListeners();
  }

  Future<bool> approveKyc({
    required KycTier tier,
    Duration validity = const Duration(days: 365),
  }) async {
    if (_currentProfile == null) return false;
    if (_currentProfile!.sanctionsHit) return false;

    _currentProfile = _currentProfile!.copyWith(
      status: KycStatus.approved,
      tier: tier,
      approvedAt: DateTime.now(),
      expiresAt: DateTime.now().add(validity),
    );

    _userRiskRating = _computeRiskRating(_currentProfile!);
    await _saveProfile();
    notifyListeners();

    if (kDebugMode) debugPrint('KYC genehmigt: Tier ${tier.name}');
    return true;
  }

  Future<void> rejectKyc(String reason) async {
    if (_currentProfile == null) return;

    _currentProfile = _currentProfile!.copyWith(
      status: KycStatus.rejected,
      rejectionReason: reason,
    );

    await _saveProfile();
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AML TRANSACTION MONITORING
  // ══════════════════════════════════════════════════════════════════════════
  Future<AmlTransaction> screenTransaction({
    required String userId,
    required String symbol,
    required double amountEur,
    required String direction,
    String? counterpartyAddress,
    String? counterpartyName,
  }) async {
    final flagReasons = <String>[];
    double riskScore = 0.0;

    // 1. Betragsprüfung
    if (amountEur >= 10000) {
      riskScore += 30;
      flagReasons.add('Großbetrag ≥ €10.000 (AMLR-Meldepflicht)');
    } else if (amountEur >= 1000) {
      riskScore += 10;
      flagReasons.add('Travel Rule Schwellenwert ≥ €1.000');
    }

    // 2. Häufigkeitsanalyse (Structuring-Erkennung)
    final recentVolume = _getRecentVolume(userId, const Duration(hours: 24));
    if (recentVolume > 9000 && amountEur > 1000) {
      riskScore += 40;
      flagReasons.add('Verdacht auf Structuring (Stückelung)');
    }

    // 3. Nutzer-Risikoprofil
    if (_userRiskRating == AmlRiskRating.high) riskScore += 20;
    if (_userRiskRating == AmlRiskRating.veryHigh) riskScore += 40;

    // 4. PEP-Status
    if (_currentProfile?.pepStatus == true) {
      riskScore += 25;
      flagReasons.add('PEP (Politisch exponierte Person)');
    }

    // 5. Unbekannte Gegenpartei bei Krypto-Auszahlungen
    if (direction == 'WITHDRAWAL' && counterpartyAddress == null) {
      riskScore += 15;
      flagReasons.add('Unbekannte Zieladresse');
    }

    // 6. Velocity-Check: zu viele Transaktionen
    final txCountToday = _getTransactionCount(userId, const Duration(hours: 24));
    if (txCountToday > 20) {
      riskScore += 20;
      flagReasons.add('Ungewöhnlich hohe Transaktionsfrequenz');
    }

    riskScore = riskScore.clamp(0.0, 100.0);

    final flag = riskScore >= 80
        ? TransactionRiskFlag.blocked
        : riskScore >= 70
            ? TransactionRiskFlag.suspicious
            : riskScore >= 40
                ? TransactionRiskFlag.underMonitoring
                : TransactionRiskFlag.clean;

    final tx = AmlTransaction(
      id: 'AML_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      symbol: symbol,
      amountEur: amountEur,
      direction: direction,
      counterpartyAddress: counterpartyAddress,
      counterpartyName: counterpartyName,
      riskFlag: flag,
      riskScore: riskScore,
      flagReasons: flagReasons,
      executedAt: DateTime.now(),
    );

    _transactions.insert(0, tx);
    if (_transactions.length > 500) _transactions.removeLast();

    // SAR automatisch erstellen wenn blockiert
    if (flag == TransactionRiskFlag.blocked ||
        flag == TransactionRiskFlag.suspicious) {
      _createSar(tx);
    }

    await _saveTransactions();
    notifyListeners();
    return tx;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TRAVEL RULE (EU, AMLR 2027)
  // ══════════════════════════════════════════════════════════════════════════
  Map<String, dynamic> buildTravelRuleData({
    required String beneficiaryName,
    required String beneficiaryAddress,
    required String originatorName,
    required String originatorAddress,
    required double amount,
    required String asset,
  }) {
    return {
      'originator': {
        'name': originatorName,
        'address': originatorAddress,
        'account_number': 'HQMLL-${DateTime.now().millisecondsSinceEpoch}',
      },
      'beneficiary': {
        'name': beneficiaryName,
        'address': beneficiaryAddress,
      },
      'transfer': {
        'amount': amount,
        'asset': asset,
        'timestamp': DateTime.now().toIso8601String(),
      },
      'ivms_version': '1.0',
      'compliance_standard': 'FATF_Travel_Rule',
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LIMITS CHECK
  // ══════════════════════════════════════════════════════════════════════════
  bool canExecuteTransaction(double amountEur) {
    if (!isKycVerified) return amountEur <= 500; // Unverified = €500 max
    final tier = currentTier;
    final dailyVolume = _getRecentVolume('current', const Duration(hours: 24));
    return (dailyVolume + amountEur) <= tier.dailyLimitEur &&
        amountEur <= tier.transactionLimitEur;
  }

  String? getLimitViolationReason(double amountEur) {
    if (!isKycVerified && amountEur > 500) {
      return 'KYC nicht abgeschlossen. Limit €500 für unverifizierte Nutzer.';
    }
    if (amountEur > currentTier.transactionLimitEur) {
      return 'Einzeltransaktion überschreitet Tier-Limit '
          '(${currentTier.transactionLimitEur.toStringAsFixed(0)} €)';
    }
    final dailyVol = _getRecentVolume('current', const Duration(hours: 24));
    if ((dailyVol + amountEur) > currentTier.dailyLimitEur) {
      return 'Tageslimit überschritten '
          '(${currentTier.dailyLimitEur.toStringAsFixed(0)} €/Tag)';
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  AmlRiskRating _computeRiskRating(KycProfile profile) {
    if (profile.sanctionsHit) return AmlRiskRating.prohibited;
    if (profile.pepStatus) return AmlRiskRating.high;

    // Hochrisiko-Länder (vereinfacht — FATF-Liste)
    const highRiskCountries = ['KP', 'IR', 'MM', 'SY', 'YE', 'LY'];
    if (highRiskCountries.contains(profile.country)) {
      return AmlRiskRating.veryHigh;
    }

    return AmlRiskRating.low;
  }

  bool _simulatePepCheck(String first, String last, String country) {
    // Simulierte PEP-Prüfung (Zufallswahrscheinlichkeit 1%)
    return Random().nextDouble() < 0.01;
  }

  bool _simulateSanctionsCheck(String first, String last, String country) {
    const sanctionedCountries = ['KP', 'IR', 'SY'];
    return sanctionedCountries.contains(country);
  }

  double _getRecentVolume(String userId, Duration window) {
    final cutoff = DateTime.now().subtract(window);
    return _transactions
        .where((t) => t.userId == userId && t.executedAt.isAfter(cutoff))
        .fold(0.0, (s, t) => s + t.amountEur);
  }

  int _getTransactionCount(String userId, Duration window) {
    final cutoff = DateTime.now().subtract(window);
    return _transactions
        .where((t) => t.userId == userId && t.executedAt.isAfter(cutoff))
        .length;
  }

  void _createSar(AmlTransaction tx) {
    final sar = SuspiciousActivityReport(
      id: 'SAR_${DateTime.now().millisecondsSinceEpoch}',
      userId: tx.userId,
      transactionId: tx.id,
      description: 'Automatisch erkannt: ${tx.flagReasons.join(', ')}',
      status: SarStatus.detected,
      detectedAt: DateTime.now(),
    );
    _sars.insert(0, sar);
    if (_sars.length > 100) _sars.removeLast();
  }

  // ── Persistenz ─────────────────────────────────────────────────────────
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawP = prefs.getString(_kKycProfile);
      if (rawP != null) {
        _currentProfile = KycProfile.fromJson(
            jsonDecode(rawP) as Map<String, dynamic>);
        if (_currentProfile != null) {
          _userRiskRating = _computeRiskRating(_currentProfile!);
        }
      }
      final rawT = prefs.getString(_kAmlTxns);
      if (rawT != null) {
        final list = jsonDecode(rawT) as List<dynamic>;
        _transactions.clear();
        for (final j in list) {
          try {
            _transactions.add(AmlTransaction.fromJson(j as Map<String, dynamic>));
          } catch (_) {}
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('KycAmlService._load error: $e');
    }
  }

  Future<void> _saveProfile() async {
    try {
      if (_currentProfile == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKycProfile, jsonEncode(_currentProfile!.toJson()));
    } catch (e) {
      if (kDebugMode) debugPrint('KycAmlService._saveProfile: $e');
    }
  }

  Future<void> _saveTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAmlTxns,
          jsonEncode(_transactions.take(100).map((t) => t.toJson()).toList()));
    } catch (e) {
      if (kDebugMode) debugPrint('KycAmlService._saveTransactions: $e');
    }
  }
}
