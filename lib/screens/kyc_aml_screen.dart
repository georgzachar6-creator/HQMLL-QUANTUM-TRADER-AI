// HQMLL Quantum Trader — KYC/AML Screen v51.0
// AMLR · MiCA · MiFID II konforme KYC/AML Ansicht
// Grigori Saks · 2025
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/kyc_aml_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
class KycAmlScreen extends StatefulWidget {
  const KycAmlScreen({super.key});
  @override
  State<KycAmlScreen> createState() => _KycAmlScreenState();
}

class _KycAmlScreenState extends State<KycAmlScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _onboarding = false; // ignore: unused_field

  // Onboarding Form
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController(text: 'Max');
  final _lastNameCtrl  = TextEditingController(text: 'Mustermann');
  final _emailCtrl     = TextEditingController(text: 'max@example.com');
  final _dobCtrl       = TextEditingController(text: '1985-03-15');
  final _nationalityCtrl = TextEditingController(text: 'DE');
  final _countryCtrl   = TextEditingController(text: 'DE');
  final _addressCtrl   = TextEditingController(text: 'Musterstraße 1, 10115 Berlin');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose();
    _emailCtrl.dispose(); _dobCtrl.dispose();
    _nationalityCtrl.dispose(); _countryCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp  = context.watch<ThemeProvider>();
    final p   = tp.palette;
    final kyc = context.watch<KycAmlService>();

    return Scaffold(
      backgroundColor: p.background,
      body: Column(
        children: [
          _buildHeader(p, kyc),
          _buildTabBar(p),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _ProfileTab(kyc: kyc, p: p, onStartOnboarding: _startOnboarding),
                _TransactionsTab(kyc: kyc, p: p),
                _SarTab(kyc: kyc, p: p),
                _ComplianceTab(kyc: kyc, p: p),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: kyc.currentProfile == null
          ? FloatingActionButton.extended(
              onPressed: _startOnboarding,
              backgroundColor: const Color(0xFF00E5FF),
              icon: const Icon(Icons.person_add, color: Colors.black),
              label: const Text('KYC starten',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(dynamic p, KycAmlService kyc) {
    final status = kyc.kycStatus;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.primary.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statusIcon(status), color: _statusColor(status), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KYC / AML Compliance',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('AMLR · MiCA · MiFID II Art.17',
                    style: TextStyle(color: p.primary, fontSize: 11)),
              ],
            ),
          ),
          _StatusBadge(status: status),
        ],
      ),
    );
  }

  Widget _buildTabBar(dynamic p) {
    return Container(
      color: p.surface,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: p.primary,
        labelColor: p.primary,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(icon: Icon(Icons.person, size: 18), text: 'PROFIL'),
          Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'TRANSAKT.'),
          Tab(icon: Icon(Icons.flag, size: 18), text: 'SAR'),
          Tab(icon: Icon(Icons.gavel, size: 18), text: 'COMPLIANCE'),
        ],
      ),
    );
  }

  void _startOnboarding() async {
    final kyc = context.read<KycAmlService>();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _onboarding = true);
    try {
      await kyc.startKycOnboarding(
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        firstName: _firstNameCtrl.text,
        lastName: _lastNameCtrl.text,
        email: _emailCtrl.text,
        dateOfBirth: DateTime.tryParse(_dobCtrl.text) ?? DateTime(1985, 3, 15),
        nationality: _nationalityCtrl.text,
        country: _countryCtrl.text,
        address: _addressCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ KYC Onboarding gestartet'),
              backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _onboarding = false);
    }
  }

  Color _statusColor(KycStatus s) => switch (s) {
    KycStatus.approved   => Colors.green,
    KycStatus.rejected   => Colors.red,
    KycStatus.pending    => Colors.orange,
    KycStatus.inProgress => const Color(0xFF00E5FF),
    KycStatus.expired    => Colors.grey,
    _                    => Colors.grey,
  };

  IconData _statusIcon(KycStatus s) => switch (s) {
    KycStatus.approved   => Icons.verified,
    KycStatus.rejected   => Icons.cancel,
    KycStatus.pending    => Icons.hourglass_empty,
    KycStatus.inProgress => Icons.pending_actions,
    KycStatus.expired    => Icons.timer_off,
    _                    => Icons.person_outline,
  };
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — PROFIL
// ══════════════════════════════════════════════════════════════════════════════
class _ProfileTab extends StatelessWidget {
  final KycAmlService kyc;
  final dynamic p;
  final VoidCallback onStartOnboarding;

  const _ProfileTab({required this.kyc, required this.p,
    required this.onStartOnboarding});

  @override
  Widget build(BuildContext context) {
    final profile = kyc.currentProfile;
    if (profile == null) return _EmptyState(p: p, onStart: onStartOnboarding);

    final tier = profile.tier;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tier Card
        _TierCard(tier: tier, p: p),
        const SizedBox(height: 16),
        // Persönliche Daten
        _SectionCard(
          title: 'Persönliche Daten',
          icon: Icons.person,
          p: p,
          children: [
            _InfoRow('Name', '${profile.firstName} ${profile.lastName}', p),
            _InfoRow('E-Mail', profile.email, p),
            _InfoRow('Geburtsdatum', profile.dateOfBirth.toLocal().toString().substring(0, 10), p),
            _InfoRow('Nationalität', profile.nationality, p),
            _InfoRow('Wohnsitz', profile.country, p),
            _InfoRow('Adresse', profile.address, p),
          ],
        ),
        const SizedBox(height: 12),
        // AML Risiko
        _SectionCard(
          title: 'AML Risiko-Profil',
          icon: Icons.shield_outlined,
          p: p,
          children: [
            _InfoRow('Risikoklasse', kyc.userRiskRating.label, p,
                valueColor: _riskColor(kyc.userRiskRating)),
            _InfoRow('PEP Status', profile.pepStatus ? 'JA ⚠️' : 'Nein ✅', p,
                valueColor: profile.pepStatus ? Colors.orange : Colors.green),
            _InfoRow('Hochrisiko-Land', profile.sanctionsHit ? 'JA ⚠️' : 'Nein ✅', p,
                valueColor: profile.sanctionsHit ? Colors.orange : Colors.green),
            _InfoRow('Verifiziert am',
                profile.approvedAt?.toLocal().toString().substring(0, 10) ?? '—', p),
            _InfoRow('Gültig bis',
                profile.expiresAt?.toLocal().toString().substring(0, 10) ?? '—', p),
          ],
        ),
        const SizedBox(height: 12),
        // Dokumenten-Status
        _SectionCard(
          title: 'Dokumente (${profile.documents.length})',
          icon: Icons.folder_copy_outlined,
          p: p,
          children: profile.documents.isEmpty
              ? [_InfoRow('Status', 'Keine Dokumente eingereicht', p)]
              : profile.documents.map((d) => _DocRow(doc: d, p: p)).toList(),
        ),
        const SizedBox(height: 12),
        // Limit-Übersicht
        _SectionCard(
          title: 'Handelslimits',
          icon: Icons.speed,
          p: p,
          children: [
            _InfoRow('Tageslimit', '€ ${tier.dailyLimitEur.toStringAsFixed(0)}', p,
                valueColor: Colors.green),
            _InfoRow('Transaktionslimit', '€ ${tier.transactionLimitEur.toStringAsFixed(0)}', p,
                valueColor: Colors.green),
            _InfoRow('Monatliches Volumen', '€ ${kyc.totalVolumeEur30d.toStringAsFixed(2)}', p),
          ],
        ),
        const SizedBox(height: 20),
        // Approve-Button (Demo)
        if (profile.status == KycStatus.pending || profile.status == KycStatus.inProgress)
          ElevatedButton.icon(
            onPressed: () async {
              await kyc.approveKyc(tier: KycTier.standard);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ KYC Standard genehmigt'),
                      backgroundColor: Colors.green));
              }
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('KYC Genehmigen (Standard)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Color _riskColor(AmlRiskRating r) => switch (r) {
    AmlRiskRating.low      => Colors.green,
    AmlRiskRating.medium   => Colors.orange,
    AmlRiskRating.high     => Colors.deepOrange,
    AmlRiskRating.veryHigh => Colors.red,
    AmlRiskRating.prohibited => Colors.red.shade900,
  };
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — TRANSAKTIONEN
// ══════════════════════════════════════════════════════════════════════════════
class _TransactionsTab extends StatelessWidget {
  final KycAmlService kyc;
  final dynamic p;

  const _TransactionsTab({required this.kyc, required this.p});

  @override
  Widget build(BuildContext context) {
    final txs = kyc.transactions;
    if (txs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, color: Colors.grey, size: 56),
            const SizedBox(height: 12),
            const Text('Keine Transaktionen', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            // Demo-Screening Button
            ElevatedButton.icon(
              onPressed: () => _demoScreen(context),
              icon: const Icon(Icons.search),
              label: const Text('Demo-Transaktion screenen'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: txs.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () => _demoScreen(context),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Neue Transaktion screenen'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black),
            ),
          );
        }
        final tx = txs[i - 1];
        return _TxCard(tx: tx, p: p);
      },
    );
  }

  void _demoScreen(BuildContext context) async {
    final kyc = context.read<KycAmlService>();
    if (kyc.currentProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte zuerst KYC starten'),
            backgroundColor: Colors.orange));
      return;
    }
    try {
      final result = await kyc.screenTransaction(
        userId: kyc.currentProfile!.userId,
        symbol: 'BTC',
        amountEur: 15000.0,
        direction: 'TRADE',
        counterpartyAddress: '1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('AML: ${result.flagLabel} — Score: ${result.riskScore.toStringAsFixed(0)}'),
          backgroundColor: result.riskFlag == TransactionRiskFlag.clean
              ? Colors.green : Colors.orange,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3 — SAR (Suspicious Activity Reports)
// ══════════════════════════════════════════════════════════════════════════════
class _SarTab extends StatelessWidget {
  final KycAmlService kyc;
  final dynamic p;

  const _SarTab({required this.kyc, required this.p});

  @override
  Widget build(BuildContext context) {
    final sars = kyc.sars;
    if (sars.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
            SizedBox(height: 12),
            Text('Keine verdächtigen Aktivitäten',
                style: TextStyle(color: Colors.green, fontSize: 16)),
            SizedBox(height: 8),
            Text('System ist compliant',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sars.length,
      itemBuilder: (ctx, i) => _SarCard(sar: sars[i], p: p),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 4 — COMPLIANCE
// ══════════════════════════════════════════════════════════════════════════════
class _ComplianceTab extends StatelessWidget {
  final KycAmlService kyc;
  final dynamic p;

  const _ComplianceTab({required this.kyc, required this.p});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ComplianceCard(
          title: 'AMLR (Anti-Money Laundering Regulation)',
          icon: Icons.account_balance,
          color: const Color(0xFF00E5FF),
          items: const [
            'Betragsgrenze: €10.000 Meldepflicht',
            'Travel Rule: €1.000 für Krypto-Transfers',
            'Verdächtige Aktivitäten → SAR innerhalb 24h',
            '5-Jahres Datenaufbewahrungspflicht',
            'PEP/Sanctions Screening bei Onboarding',
          ],
          p: p,
        ),
        const SizedBox(height: 12),
        _ComplianceCard(
          title: 'MiCA (Markets in Crypto-Assets)',
          icon: Icons.currency_bitcoin,
          color: Colors.orange,
          items: const [
            'KYC vor Krypto-Transaktionen erforderlich',
            'Custodial Wallet: volle KYC-Pflicht',
            'Stablecoin-Emittenten: Erweiterte Anforderungen',
            'CASP-Lizenz Voraussetzung',
            'Consumer Protection Standards',
          ],
          p: p,
        ),
        const SizedBox(height: 12),
        _ComplianceCard(
          title: 'MiFID II (Markets in Financial Instruments)',
          icon: Icons.gavel,
          color: Colors.purple,
          items: const [
            'Suitability Assessment für Anlagen',
            'Best Execution Nachweispflicht',
            'Transaktionsmeldepflicht Art. 26',
            'Circuit Breaker Art. 17 (Risk Management)',
            'Pre/Post-Trade Transparenz',
          ],
          p: p,
        ),
        const SizedBox(height: 12),
        _ComplianceCard(
          title: 'Tier-System & Limits',
          icon: Icons.layers,
          color: Colors.green,
          items: KycTier.values.map((t) =>
              '${t.label}: Täglich €${t.dailyLimitEur.toStringAsFixed(0)} / TX €${t.transactionLimitEur.toStringAsFixed(0)}'
          ).toList(),
          p: p,
        ),
        const SizedBox(height: 12),
        _ComplianceCard(
          title: 'Hochrisiko-Länder',
          icon: Icons.public_off,
          color: Colors.red,
          items: const [
            'FATF Blacklist: Iran, Nordkorea, Myanmar',
            'FATF Greylist: Dynamisch aktualisiert',
            'EU-Sanktionsliste: Russland, Belarus, weitere',
            'UN-Sanktionen: Automatisches Screening',
          ],
          p: p,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final dynamic p;
  final VoidCallback onStart;
  const _EmptyState({required this.p, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, color: p.primary, size: 80),
            const SizedBox(height: 16),
            const Text('KYC noch nicht gestartet',
                style: TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Starten Sie die Identitätsprüfung um den vollen\nFunktionsumfang freizuschalten.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.person_add),
              label: const Text('KYC Onboarding starten'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final KycStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      KycStatus.approved   => Colors.green,
      KycStatus.rejected   => Colors.red,
      KycStatus.pending    => Colors.orange,
      KycStatus.inProgress => const Color(0xFF00E5FF),
      KycStatus.expired    => Colors.grey,
      _                    => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(status.label,
          style: TextStyle(color: color, fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _TierCard extends StatelessWidget {
  final KycTier tier;
  final dynamic p;
  const _TierCard({required this.tier, required this.p});

  @override
  Widget build(BuildContext context) {
    final color = switch (tier) {
      KycTier.basic          => Colors.grey,
      KycTier.standard       => const Color(0xFF00E5FF),
      KycTier.advanced       => Colors.orange,
      KycTier.institutional  => Colors.purple,
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KYC-Tier: ${tier.label}',
                    style: TextStyle(color: color, fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('Täglich: €${tier.dailyLimitEur.toStringAsFixed(0)} · TX: €${tier.transactionLimitEur.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.verified, color: color),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final dynamic p;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon,
    required this.p, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(icon, color: p.primary, size: 16),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: p.primary,
                    fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final dynamic p;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, this.p, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          Flexible(child: Text(value,
              style: TextStyle(color: valueColor ?? Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final KycDocument doc;
  final dynamic p;
  const _DocRow({required this.doc, required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: p.primary, size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text('${doc.typeLabel} — ${doc.documentNumber}',
              style: const TextStyle(color: Colors.white, fontSize: 12))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (doc.isValid ? Colors.green : Colors.red).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(doc.isValid ? 'Gültig' : 'Abgelaufen',
                style: TextStyle(
                    color: doc.isValid ? Colors.green : Colors.red,
                    fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final AmlTransaction tx;
  final dynamic p;
  const _TxCard({required this.tx, required this.p});

  @override
  Widget build(BuildContext context) {
    final flagColor = switch (tx.riskFlag) {
      TransactionRiskFlag.clean       => Colors.green,
      TransactionRiskFlag.suspicious  => Colors.orange,
      TransactionRiskFlag.reported    => Colors.red,
      TransactionRiskFlag.blocked     => Colors.red.shade900,
      _                               => Colors.grey,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: flagColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${tx.direction.toUpperCase()} ${tx.symbol}',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: flagColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tx.flagLabel,
                    style: TextStyle(color: flagColor, fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('€ ${tx.amountEur.toStringAsFixed(2)}',
                  style: TextStyle(color: flagColor, fontSize: 13,
                      fontWeight: FontWeight.bold)),
              Text('Score: ${tx.riskScore.toStringAsFixed(0)}/100',
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          if (tx.flagReasons.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: tx.flagReasons.map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(f, style: const TextStyle(color: Colors.orange, fontSize: 9)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 4),
          Text(tx.executedAt.toLocal().toString().substring(0, 19),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
        ],
      ),
    );
  }
}

class _SarCard extends StatelessWidget {
  final SuspiciousActivityReport sar;
  final dynamic p;
  const _SarCard({required this.sar, required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Text('SAR-${sar.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(color: Colors.red,
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ((sar.status == SarStatus.reported) ? Colors.green : Colors.orange)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(sar.statusLabel,
                    style: TextStyle(
                        color: (sar.status == SarStatus.reported) ? Colors.green : Colors.orange,
                        fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(sar.description, style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Erkannt: ${sar.detectedAt.toLocal().toString().substring(0, 19)}  Gemeldet: ${sar.reportedAt?.toLocal().toString().substring(0, 10) ?? '—'}',  
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ComplianceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  final dynamic p;
  const _ComplianceCard({required this.title, required this.icon,
    required this.color, required this.items, required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(title,
                    style: TextStyle(color: color, fontSize: 12,
                        fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: color)),
                Expanded(child: Text(item,
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 12))),
              ],
            ),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
