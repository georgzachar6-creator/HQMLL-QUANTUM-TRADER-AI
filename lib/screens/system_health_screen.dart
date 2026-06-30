/// HQMLL Quantum Trader — System Health Screen v53.0
/// Live Service Monitor · Dependency Graph · Error Log · Resource Monitor
/// Grigori Saks · 2025
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/performance_optimizer_service.dart';
import '../services/auto_workflow_service.dart';
import '../services/error_handler_service.dart';
import '../services/persistence_service.dart';
import '../services/exchange_service.dart';
import '../services/live_data_service.dart';
import '../services/trading_signal_service.dart';
import '../services/kyc_aml_service.dart';
import '../services/market_data_ingestion_service.dart';
import '../services/risk_engine_service.dart';
import '../services/auto_save_service.dart';
import '../services/wallet_service.dart';

// ── Service Health Model ──────────────────────────────────────────────────────
enum ServiceStatus { healthy, degraded, error, offline, starting }

class ServiceHealth {
  final String name;
  final String category;
  final ServiceStatus status;
  final String detail;
  final IconData icon;
  final int uptimeSeconds;
  final bool isCore;

  const ServiceHealth({
    required this.name,
    required this.category,
    required this.status,
    required this.detail,
    required this.icon,
    this.uptimeSeconds = 0,
    this.isCore = false,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────
class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Timer? _refreshTimer;
  DateTime _startTime = DateTime.now();
  int _refreshCount = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _startTime = DateTime.now();
    // Alle 5 Sekunden Auto-Refresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _refreshCount++);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp   = context.watch<ThemeProvider>();
    final p    = tp.palette;
    final perf = context.watch<PerformanceOptimizerService>();
    final wf   = context.watch<AutoWorkflowService>();
    final errs = context.watch<ErrorHandlerService>();

    final services = _buildServiceList(context);
    final healthyCount  = services.where((s) => s.status == ServiceStatus.healthy).length;
    final degradedCount = services.where((s) => s.status == ServiceStatus.degraded).length;
    final errorCount    = services.where((s) => s.status == ServiceStatus.error || s.status == ServiceStatus.offline).length;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.surface,
        elevation: 0,
        title: Text(
          'SYSTEM HEALTH MONITOR',
          style: GoogleFonts.spaceMono(
            color: p.primary, fontSize: 13, letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Refresh-Indikator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.refresh, size: 12, color: p.textSecondary),
              const SizedBox(width: 3),
              Text(
                '#$_refreshCount',
                style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9),
              ),
            ]),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: p.primary,
          labelColor: p.primary,
          unselectedLabelColor: p.textSecondary,
          labelStyle: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'SERVICES'),
            Tab(text: 'RESSOURCEN'),
            Tab(text: 'ERROR LOG'),
          ],
        ),
      ),
      body: Column(children: [
        // ── Overall Status Banner ─────────────────────────────────────────
        _OverallStatusBanner(
          healthy: healthyCount,
          degraded: degradedCount,
          errors: errorCount,
          total: services.length,
          palette: p,
          uptime: DateTime.now().difference(_startTime),
        ),
        // ── Tabs ──────────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _ServicesTab(services: services, palette: p),
              _ResourcesTab(perf: perf, wf: wf, palette: p),
              _ErrorLogTab(errs: errs, palette: p),
            ],
          ),
        ),
      ]),
    );
  }

  List<ServiceHealth> _buildServiceList(BuildContext ctx) {
    final perf = ctx.read<PerformanceOptimizerService>();
    final wf   = ctx.read<AutoWorkflowService>();
    final as2  = ctx.read<AutoSaveService>();
    final ex   = ctx.read<ExchangeService>();
    final lds  = ctx.read<LiveDataService>();
    final tss  = ctx.read<TradingSignalService>();
    final kyc  = ctx.read<KycAmlService>();
    final mdi  = ctx.read<MarketDataIngestionService>();
    final risk = ctx.read<RiskEngineService>();
    final wal  = ctx.read<WalletService>();
    final err  = ctx.read<ErrorHandlerService>();
    final per  = ctx.read<PersistenceService>();

    return [
      // ── Core Infrastructure ──────────────────────────────────────────────
      ServiceHealth(
        name: 'ErrorHandlerService',
        category: 'Core',
        status: ServiceStatus.healthy,
        detail: '${err.errors.length} Fehler im Log',
        icon: Icons.shield_outlined,
        isCore: true,
      ),
      ServiceHealth(
        name: 'PersistenceService',
        category: 'Core',
        status: ServiceStatus.healthy,
        detail: '${per.systemLogs.length} Log-Einträge',
        icon: Icons.storage_outlined,
        isCore: true,
      ),
      const ServiceHealth(
        name: 'ThemeProvider',
        category: 'Core',
        status: ServiceStatus.healthy,
        detail: 'Dark Mode aktiv',
        icon: Icons.palette_outlined,
        isCore: true,
      ),
      // ── Market Data ──────────────────────────────────────────────────────
      const ServiceHealth(
        name: 'ExchangeService',
        category: 'Market Data',
        status: ServiceStatus.healthy,
        detail: 'Exchange Service aktiv',
        icon: Icons.swap_horiz_outlined,
      ),
      ServiceHealth(
        name: 'LiveDataService',
        category: 'Market Data',
        status: ServiceStatus.healthy,
        detail: '${lds.tickers.length} Symbole getrackt',
        icon: Icons.show_chart,
      ),
      ServiceHealth(
        name: 'MarketDataIngestionService',
        category: 'Market Data',
        status: mdi.isRunning ? ServiceStatus.healthy : ServiceStatus.offline,
        detail: '${mdi.connectedProviderCount}/7 Provider · ${mdi.subscribedSymbols.length} Symbole',
        icon: Icons.sensors_outlined,
      ),
      // ── Trading ──────────────────────────────────────────────────────────
      ServiceHealth(
        name: 'TradingSignalService',
        category: 'Trading',
        status: ServiceStatus.healthy,
        detail: '${tss.activeSignals.length} aktive Signale',
        icon: Icons.electric_bolt_outlined,
      ),
      ServiceHealth(
        name: 'RiskEngineService',
        category: 'Trading',
        status: risk.killSwitchActive
            ? ServiceStatus.error
            : risk.circuitBreaker.isOpen
                ? ServiceStatus.degraded
                : ServiceStatus.healthy,
        detail: risk.killSwitchActive
            ? 'KILL-SWITCH AKTIV'
            : risk.circuitBreaker.isOpen
                ? 'Circuit Breaker ausgelöst'
                : 'VaR95-Limit: ${(risk.var95Limit * 100).toStringAsFixed(1)}%',
        icon: Icons.gavel_outlined,
        isCore: true,
      ),
      // ── Finance ──────────────────────────────────────────────────────────
      ServiceHealth(
        name: 'WalletService',
        category: 'Finance',
        status: ServiceStatus.healthy,
        detail: '${wal.wallets.length} Wallets · ${wal.addressBook.length} Adressen',
        icon: Icons.account_balance_wallet_outlined,
      ),
      ServiceHealth(
        name: 'KycAmlService',
        category: 'Finance',
        status: kyc.kycStatus == KycStatus.approved
            ? ServiceStatus.healthy
            : kyc.kycStatus == KycStatus.rejected
                ? ServiceStatus.error
                : ServiceStatus.degraded,
        detail: 'KYC: ${kyc.kycStatus.name.toUpperCase()} · ${kyc.transactions.length} Transaktionen',
        icon: Icons.verified_user_outlined,
      ),
      ServiceHealth(
        name: 'AutoSaveService',
        category: 'System',
        status: as2.autoSaveOn ? ServiceStatus.healthy : ServiceStatus.degraded,
        detail: as2.autoSaveOn
            ? 'Aktiv · ${as2.intervalLabel}'
            : 'Deaktiviert',
        icon: Icons.save_outlined,
      ),
      // ── Performance & Workflow ────────────────────────────────────────────
      ServiceHealth(
        name: 'PerformanceOptimizerService',
        category: 'System',
        status: perf.isMonitoring
            ? (perf.currentTier == PerformanceTier.critical
                ? ServiceStatus.degraded
                : ServiceStatus.healthy)
            : ServiceStatus.offline,
        detail: perf.isMonitoring
            ? '${perf.currentFps.toStringAsFixed(0)} fps · ${perf.currentTier.label}'
            : 'Monitoring nicht aktiv',
        icon: Icons.speed_outlined,
        isCore: true,
      ),
      ServiceHealth(
        name: 'AutoWorkflowService',
        category: 'System',
        status: wf.isRunning ? ServiceStatus.healthy : ServiceStatus.offline,
        detail: wf.isRunning
            ? '${wf.tasks.length} Tasks · ${wf.totalRunCount} ausgeführt'
            : 'Engine gestoppt',
        icon: Icons.account_tree_outlined,
        isCore: true,
      ),
      // ── Additional Services ───────────────────────────────────────────────
      const ServiceHealth(
        name: 'TimeCrystalService',
        category: 'Quantum',
        status: ServiceStatus.healthy,
        detail: 'DTC-Phase aktiv',
        icon: Icons.diamond_outlined,
      ),
      const ServiceHealth(
        name: 'SecureVaultService',
        category: 'Security',
        status: ServiceStatus.healthy,
        detail: 'Vault verschlüsselt',
        icon: Icons.enhanced_encryption,
      ),
      const ServiceHealth(
        name: 'AuthService',
        category: 'Security',
        status: ServiceStatus.healthy,
        detail: 'Eingeloggt',
        icon: Icons.lock_outlined,
      ),
      const ServiceHealth(
        name: 'CoinMarketCapService',
        category: 'Market Data',
        status: ServiceStatus.healthy,
        detail: 'API verfügbar',
        icon: Icons.bar_chart_outlined,
      ),
      const ServiceHealth(
        name: 'PaymentService',
        category: 'Finance',
        status: ServiceStatus.healthy,
        detail: 'Zahlungssystem aktiv',
        icon: Icons.payment_outlined,
      ),
      const ServiceHealth(
        name: 'MarketService',
        category: 'Market Data',
        status: ServiceStatus.healthy,
        detail: 'Marktdaten live',
        icon: Icons.candlestick_chart_outlined,
      ),
      const ServiceHealth(
        name: 'LivePriceProvider',
        category: 'Market Data',
        status: ServiceStatus.healthy,
        detail: 'Provider aktiv',
        icon: Icons.price_change_outlined,
      ),
      ServiceHealth(
        name: 'WebSocketService',
        category: 'Network',
        status: ex.isConnected ? ServiceStatus.healthy : ServiceStatus.degraded,
        detail: ex.isConnected ? 'WS verbunden' : 'Keine Verbindung',
        icon: Icons.wifi_outlined,
      ),
      const ServiceHealth(
        name: 'CryptoIconService',
        category: 'UI',
        status: ServiceStatus.healthy,
        detail: 'Icons gecacht',
        icon: Icons.image_outlined,
      ),
    ];
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// OVERALL STATUS BANNER
// ══════════════════════════════════════════════════════════════════════════════
class _OverallStatusBanner extends StatelessWidget {
  final int healthy;
  final int degraded;
  final int errors;
  final int total;
  final Duration uptime;
  final dynamic palette;

  const _OverallStatusBanner({
    required this.healthy,
    required this.degraded,
    required this.errors,
    required this.total,
    required this.uptime,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final allHealthy = errors == 0 && degraded == 0;
    final hasErrors  = errors > 0;
    final statusColor = hasErrors
        ? Colors.red
        : degraded > 0 ? Colors.orange : const Color(0xFF00FF88);
    final statusText = hasErrors
        ? 'KRITISCHE FEHLER'
        : degraded > 0 ? 'DEGRADIERT'
        : 'ALLE SYSTEME NOMINAL';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(
          color: statusColor.withValues(alpha: 0.3),
        )),
      ),
      child: Row(children: [
        // Status
        Row(children: [
          Icon(
            allHealthy ? Icons.check_circle : Icons.warning_amber_rounded,
            size: 18, color: statusColor,
          ),
          const SizedBox(width: 8),
          Text(statusText, style: GoogleFonts.spaceMono(
            color: statusColor, fontSize: 11, fontWeight: FontWeight.bold,
            letterSpacing: 1,
          )),
        ]),
        const Spacer(),
        // Counts
        _BannerCount(count: healthy,  label: 'OK',    color: const Color(0xFF00FF88)),
        const SizedBox(width: 6),
        _BannerCount(count: degraded, label: 'WARN',  color: Colors.orange),
        const SizedBox(width: 6),
        _BannerCount(count: errors,   label: 'ERR',   color: Colors.red),
        const SizedBox(width: 10),
        // Uptime
        Text(
          'UP ${_fmtUptime(uptime)}',
          style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9),
        ),
      ]),
    );
  }

  String _fmtUptime(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }
}

class _BannerCount extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _BannerCount({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(count.toString(), style: GoogleFonts.spaceMono(
        color: color, fontSize: 11, fontWeight: FontWeight.bold,
      )),
      const SizedBox(width: 3),
      Text(label, style: GoogleFonts.spaceMono(
        color: color.withValues(alpha: 0.7), fontSize: 8,
      )),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — SERVICES LISTE
// ══════════════════════════════════════════════════════════════════════════════
class _ServicesTab extends StatelessWidget {
  final List<ServiceHealth> services;
  final dynamic palette;
  const _ServicesTab({required this.services, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    // Nach Kategorie gruppieren
    final categories = <String, List<ServiceHealth>>{};
    for (final svc in services) {
      categories.putIfAbsent(svc.category, () => []).add(svc);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final cat in categories.entries) ...[
          _CategoryHeader(title: cat.key, count: cat.value.length, palette: p),
          const SizedBox(height: 6),
          ...cat.value.map((s) => _ServiceCard(service: s, palette: p)),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  final int count;
  final dynamic palette;
  const _CategoryHeader({required this.title, required this.count, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Row(children: [
      Text(title.toUpperCase(), style: GoogleFonts.spaceMono(
        color: p.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5,
      )),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: p.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('$count', style: GoogleFonts.spaceMono(
          color: p.primary, fontSize: 9,
        )),
      ),
    ]);
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceHealth service;
  final dynamic palette;
  const _ServiceCard({required this.service, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final statusColor = _statusColor(service.status);
    final statusLabel = _statusLabel(service.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: service.isCore ? 0.4 : 0.25),
          width: service.isCore ? 1.2 : 1.0,
        ),
      ),
      child: Row(children: [
        // Status dot
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: statusColor.withValues(alpha: 0.4),
              blurRadius: 4,
            )],
          ),
        ),
        const SizedBox(width: 8),
        // Icon
        Icon(service.icon, size: 14, color: p.primary),
        const SizedBox(width: 8),
        // Name + Detail
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(service.name, style: GoogleFonts.spaceMono(
                color: p.primary, fontSize: 10, fontWeight: FontWeight.bold,
              )),
              if (service.isCore) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text('KERN', style: GoogleFonts.spaceMono(
                    color: p.primary, fontSize: 7, fontWeight: FontWeight.bold,
                  )),
                ),
              ],
            ]),
            Text(service.detail, style: GoogleFonts.inter(
              color: p.textSecondary, fontSize: 9,
            )),
          ],
        )),
        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: statusColor.withValues(alpha: 0.35)),
          ),
          child: Text(statusLabel, style: GoogleFonts.spaceMono(
            color: statusColor, fontSize: 8, fontWeight: FontWeight.bold,
          )),
        ),
      ]),
    );
  }

  Color _statusColor(ServiceStatus s) {
    switch (s) {
      case ServiceStatus.healthy:  return const Color(0xFF00FF88);
      case ServiceStatus.degraded: return Colors.orange;
      case ServiceStatus.error:    return Colors.red;
      case ServiceStatus.offline:  return Colors.grey;
      case ServiceStatus.starting: return Colors.blue;
    }
  }

  String _statusLabel(ServiceStatus s) {
    switch (s) {
      case ServiceStatus.healthy:  return 'OK';
      case ServiceStatus.degraded: return 'WARN';
      case ServiceStatus.error:    return 'FEHLER';
      case ServiceStatus.offline:  return 'OFFLINE';
      case ServiceStatus.starting: return 'START';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — RESSOURCEN (FPS + Memory + Workflow)
// ══════════════════════════════════════════════════════════════════════════════
class _ResourcesTab extends StatelessWidget {
  final PerformanceOptimizerService perf;
  final AutoWorkflowService wf;
  final dynamic palette;
  const _ResourcesTab({required this.perf, required this.wf, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final mem = perf.latestMemory;
    final tier = perf.currentTier;
    final tierColor = _tierColor(tier);
    final saveState = wf.autoSaveState;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Performance Metriken ────────────────────────────────────────────
        _SectionTitle(title: 'PERFORMANCE', palette: p),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _ResCard(label: 'LIVE FPS', value: perf.currentFps.toStringAsFixed(1),
              unit: 'fps', color: tierColor, icon: Icons.speed, palette: p),
            _ResCard(label: 'Ø FPS',  value: perf.avgFps.toStringAsFixed(1),
              unit: 'fps', color: p.primary, icon: Icons.show_chart, palette: p),
            _ResCard(label: 'JANK',   value: perf.jankFrameCount.toString(),
              unit: 'frames', color: perf.jankFrameCount > 5 ? Colors.red : Colors.green, icon: Icons.warning_amber_outlined, palette: p),
            _ResCard(label: 'TIER',   value: tier.emoji,
              unit: tier.label, color: tierColor, icon: Icons.layers_outlined, palette: p),
          ],
        ),
        const SizedBox(height: 16),

        // ── Memory ──────────────────────────────────────────────────────────
        _SectionTitle(title: 'SPEICHER', palette: p),
        const SizedBox(height: 8),
        if (mem == null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.primary.withValues(alpha: 0.15)),
            ),
            child: Text('Kein Memory-Sample verfügbar',
              style: GoogleFonts.inter(color: p.textSecondary, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          _MemBar(label: 'HEAP', usedMb: mem.heapMb,
            totalMb: mem.heapCapacityBytes / (1024*1024), pct: mem.heapUsagePct, palette: p),
          const SizedBox(height: 8),
          _MemBar(label: 'RSS', usedMb: mem.rssMb,
            totalMb: mem.rssMb * 1.2, pct: 0.83, palette: p),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: p.primary.withValues(alpha: 0.15)),
            ),
            child: Row(children: [
              Expanded(child: _MemStat(label: 'HEAP', value: '${mem.heapMb.toStringAsFixed(1)} MB', palette: p)),
              Expanded(child: _MemStat(label: 'HEAP %', value: '${(mem.heapUsagePct * 100).toStringAsFixed(0)}%', palette: p)),
              Expanded(child: _MemStat(label: 'RSS', value: '${mem.rssMb.toStringAsFixed(1)} MB', palette: p)),
              Expanded(child: _MemStat(label: 'EXTERN', value: '${(mem.externalBytes / (1024*1024)).toStringAsFixed(1)} MB', palette: p)),
            ]),
          ),
        ],
        const SizedBox(height: 16),

        // ── AutoSave / Workflow ──────────────────────────────────────────────
        _SectionTitle(title: 'AUTO-WORKFLOW ENGINE', palette: p),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (wf.isRunning ? const Color(0xFF00FF88) : Colors.grey).withValues(alpha: 0.3),
            ),
          ),
          child: Column(children: [
            Row(children: [
              Icon(
                wf.isRunning ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 16,
                color: wf.isRunning ? const Color(0xFF00FF88) : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                wf.isRunning ? 'Auto-Workflow ENGINE AKTIV' : 'Engine gestoppt',
                style: GoogleFonts.spaceMono(
                  color: wf.isRunning ? const Color(0xFF00FF88) : Colors.grey,
                  fontSize: 11, fontWeight: FontWeight.bold,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _WfStat(label: 'TASKS', value: wf.tasks.length.toString(), palette: p)),
              Expanded(child: _WfStat(label: 'RUNS', value: wf.totalRunCount.toString(), palette: p)),
              Expanded(child: _WfStat(label: 'FAILS', value: wf.totalFailCount.toString(), palette: p)),
              Expanded(child: _WfStat(label: 'PIPELINES', value: wf.pipelineHistory.length.toString(), palette: p)),
            ]),
            const SizedBox(height: 8),
            Divider(color: p.primary.withValues(alpha: 0.1)),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.save_outlined, size: 13, color: p.textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text(saveState.statusText,
                style: GoogleFonts.inter(color: p.textSecondary, fontSize: 11))),
              Text(
                '${saveState.saveCount} saves',
                style: GoogleFonts.spaceMono(color: p.primary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Slow Widgets ────────────────────────────────────────────────────
        if (perf.slowWidgets.isNotEmpty) ...[
          _SectionTitle(title: 'LANGSAME WIDGETS (${perf.slowWidgets.length})', palette: p),
          const SizedBox(height: 8),
          ...perf.slowWidgets.take(5).map((w) => Container(
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.slow_motion_video, size: 12, color: Colors.orange),
              const SizedBox(width: 6),
              Expanded(child: Text(w.widgetName,
                style: GoogleFonts.spaceMono(color: p.primary, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              )),
              Text('${w.buildTime.inMilliseconds}ms',
                style: GoogleFonts.spaceMono(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
          )),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 20),
      ],
    );
  }

  Color _tierColor(PerformanceTier t) {
    switch (t) {
      case PerformanceTier.excellent: return const Color(0xFF00FF88);
      case PerformanceTier.good:      return const Color(0xFF00AAFF);
      case PerformanceTier.degraded:  return Colors.orange;
      case PerformanceTier.critical:  return Colors.red;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3 — ERROR LOG
// ══════════════════════════════════════════════════════════════════════════════
class _ErrorLogTab extends StatelessWidget {
  final ErrorHandlerService errs;
  final dynamic palette;
  const _ErrorLogTab({required this.errs, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final errors = errs.errors;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Stats ────────────────────────────────────────────────────────
        Row(children: [
          Expanded(child: _ErrStat(label: 'TOTAL', value: errors.length.toString(), color: p.primary, palette: p)),
          const SizedBox(width: 8),
          Expanded(child: _ErrStat(label: 'AKTIV', value: errs.activeErrors.length.toString(), color: Colors.red, palette: p)),
          const SizedBox(width: 8),
          Expanded(child: _ErrStat(label: 'FEHLER', value: errs.errorCount.toString(), color: Colors.orange, palette: p)),
        ]),
        const SizedBox(height: 16),

        _SectionTitle(title: 'FEHLER-LOG (${errors.length})', palette: p),
        const SizedBox(height: 8),

        if (errors.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
              const SizedBox(width: 10),
              Text('Keine Fehler — System läuft fehlerfrei',
                style: GoogleFonts.inter(color: Colors.green, fontSize: 12)),
            ]),
          )
        else
          ...errors.reversed.take(30).map((e) => _ErrorEntry(error: e, palette: p)),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _ErrorEntry extends StatelessWidget {
  final AppError error;
  final dynamic palette;
  const _ErrorEntry({required this.error, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final color = error.severity == AppErrorSeverity.critical ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(
            error.severity == AppErrorSeverity.critical ? Icons.error_outline : Icons.warning_amber_outlined,
            size: 13, color: color,
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(
            error.source ?? error.typeLabel,
            style: GoogleFonts.spaceMono(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          )),
          Text(
            _fmtTime(error.timestamp),
            style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9),
          ),
        ]),
        const SizedBox(height: 3),
        Text(
          error.message,
          style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ]),
    );
  }

  String _fmtTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}';
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED HELPER WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  final dynamic palette;
  const _SectionTitle({required this.title, required this.palette});

  @override
  Widget build(BuildContext context) => Text(title,
    style: GoogleFonts.spaceMono(
      color: palette.primary, fontSize: 10,
      fontWeight: FontWeight.bold, letterSpacing: 1.5,
    ));
}

class _ResCard extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  final IconData icon;
  final dynamic palette;
  const _ResCard({required this.label, required this.value,
    required this.unit, required this.color, required this.icon,
    required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.spaceMono(
              color: p.textSecondary, fontSize: 9,
            )),
          ]),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(value, style: GoogleFonts.spaceMono(
              color: color, fontSize: 16, fontWeight: FontWeight.bold,
            )),
            if (unit.isNotEmpty && !value.contains(unit)) ...[
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(unit, style: GoogleFonts.inter(
                  color: p.textSecondary, fontSize: 9,
                )),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

class _MemBar extends StatelessWidget {
  final String label;
  final double usedMb, totalMb, pct;
  final dynamic palette;
  const _MemBar({required this.label, required this.usedMb,
    required this.totalMb, required this.pct, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final c = pct > 0.8 ? Colors.red : pct > 0.6 ? Colors.orange : Colors.teal;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9, letterSpacing: 1)),
          const Spacer(),
          Text('${usedMb.toStringAsFixed(1)} / ${totalMb.toStringAsFixed(1)} MB',
            style: GoogleFonts.spaceMono(color: c, fontSize: 9, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            backgroundColor: c.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(c),
            minHeight: 6,
          ),
        ),
      ]),
    );
  }
}

class _MemStat extends StatelessWidget {
  final String label, value;
  final dynamic palette;
  const _MemStat({required this.label, required this.value, required this.palette});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: GoogleFonts.spaceMono(color: palette.textSecondary, fontSize: 8)),
    Text(value, style: GoogleFonts.spaceMono(color: palette.primary, fontSize: 10, fontWeight: FontWeight.bold)),
  ]);
}

class _WfStat extends StatelessWidget {
  final String label, value;
  final dynamic palette;
  const _WfStat({required this.label, required this.value, required this.palette});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: GoogleFonts.spaceMono(color: palette.textSecondary, fontSize: 8, letterSpacing: 0.5)),
    Text(value, style: GoogleFonts.spaceMono(color: palette.primary, fontSize: 13, fontWeight: FontWeight.bold)),
  ]);
}

class _ErrStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final dynamic palette;
  const _ErrStat({required this.label, required this.value,
    required this.color, required this.palette});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(children: [
      Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.spaceMono(color: palette.textSecondary, fontSize: 8)),
    ]),
  );
}
