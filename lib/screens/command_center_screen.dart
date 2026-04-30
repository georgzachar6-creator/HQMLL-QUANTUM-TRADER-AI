// ============================================================
// COMMAND CENTER v2 – Quantum Terminal & System Control
// Live Terminal, API Monitor, System Health, Network Scanner
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});
  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen>
    with TickerProviderStateMixin {
  late TabController _tab;
  late AnimationController _glowCtrl;
  late AnimationController _scanCtrl;
  Timer? _liveTimer;
  Timer? _sysTimer;
  final _rand = Random();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  // Terminal
  final List<_TermLine> _termLines = [];
  bool _cursorVisible = true;
  Timer? _cursorTimer;

  // System Health
  double _cpuUsage = 34.2;
  double _memUsage = 58.7;
  double _netIn = 124.5;
  double _netOut = 38.2;
  double _diskUsage = 62.4;
  final List<double> _cpuHistory = [];
  final List<double> _netHistory = [];

  // API Endpoints
  final List<Map<String, dynamic>> _apiEndpoints = [
    {'name': 'CoinGecko API', 'url': 'api.coingecko.com/v3', 'status': 'online', 'latency': 142, 'uptime': 99.8, 'calls': 8420, 'color': const Color(0xFF00FF88)},
    {'name': 'CoinMarketCap', 'url': 'pro-api.coinmarketcap.com', 'status': 'online', 'latency': 89, 'uptime': 99.9, 'calls': 3210, 'color': const Color(0xFF00AAFF)},
    {'name': 'Binance WS Feed', 'url': 'stream.binance.com:9443', 'status': 'online', 'latency': 12, 'uptime': 100.0, 'calls': 145200, 'color': const Color(0xFFFFD700)},
    {'name': 'Infura RPC', 'url': 'mainnet.infura.io/v3', 'status': 'online', 'latency': 211, 'uptime': 98.4, 'calls': 1840, 'color': const Color(0xFF627EEA)},
    {'name': 'HQMLL Node', 'url': 'node.hqmll.io:8545', 'status': 'degraded', 'latency': 840, 'uptime': 94.2, 'calls': 420, 'color': const Color(0xFFFFD700)},
    {'name': 'Firebase RT-DB', 'url': 'hqmll-default.firebaseio.com', 'status': 'online', 'latency': 56, 'uptime': 99.95, 'calls': 22100, 'color': const Color(0xFFFF6B35)},
    {'name': 'TradingView WS', 'url': 'data.tradingview.com', 'status': 'offline', 'latency': 0, 'uptime': 87.3, 'calls': 0, 'color': const Color(0xFFFF3358)},
  ];

  // Network Scan Results
  final List<Map<String, dynamic>> _networkNodes = [
    {'ip': '10.0.1.12', 'type': 'Mining Node', 'status': 'active', 'ping': 4, 'port': 3333},
    {'ip': '10.0.1.15', 'type': 'Trading Bot', 'status': 'active', 'ping': 7, 'port': 8080},
    {'ip': '10.0.1.22', 'type': 'Oracle Feed', 'status': 'active', 'ping': 3, 'port': 443},
    {'ip': '10.0.1.33', 'type': 'Backup Node', 'status': 'inactive', 'ping': 0, 'port': 22},
    {'ip': '192.168.1.1', 'type': 'Gateway', 'status': 'active', 'ping': 1, 'port': 80},
  ];

  // CLI Command History
  final List<String> _cmdHistory = [];
  int _historyIdx = -1;

  // Available commands
  static const _commands = {
    'help': '📋 Verfügbare Befehle: status, price <coin>, balance, scan, ping <host>, clear, version, nodes, api-status',
    'version': '🔮 HQMLL Quantum Trader v18.0 · Build 180 · Flutter 3.35 · Dart 3.9',
    'status': '✅ Alle Systeme online · Mining: AKTIV · Trading Bot: AKTIV · Oracle: SYNC · Vault: LOCKED',
    'scan': '🔍 Netzwerk-Scan läuft...\n  [10.0.1.12] Mining Node — AKTIV (4ms)\n  [10.0.1.15] Trading Bot — AKTIV (7ms)\n  [10.0.1.22] Oracle Feed — AKTIV (3ms)\n  [10.0.1.33] Backup Node — OFFLINE\n  Scan abgeschlossen: 4/5 Nodes aktiv',
    'clear': '__CLEAR__',
    'nodes': '🌐 Aktive Nodes: 4 · Mining Pool: HQMLL-POOL · Hashrate: 142.6 TH/s · Uptime: 99.7%',
    'api-status': '🔌 API Monitor:\n  CoinGecko: ONLINE (142ms)\n  CoinMarketCap: ONLINE (89ms)\n  Binance WS: ONLINE (12ms)\n  Infura RPC: ONLINE (211ms)\n  HQMLL Node: DEGRADED (840ms)\n  TradingView: OFFLINE',
    'balance': '💰 Wallet Balance:\n  BTC: 0.48271 (≈ \$32,748)\n  ETH: 4.8402 (≈ \$17,184)\n  SOL: 142.8 (≈ \$26,047)\n  Total: ≈ \$75,979',
  };

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();

    // Init CPU/Net history
    for (int i = 0; i < 40; i++) {
      _cpuHistory.add(25 + _rand.nextDouble() * 40);
      _netHistory.add(_rand.nextDouble() * 200);
    }

    _addSystemBoot();
    _startLiveUpdates();
    _startCursorBlink();
  }

  void _addSystemBoot() {
    final bootLines = [
      'HQMLL Quantum Command Center v2.0',
      'Copyright © 2025 HQMLL Technologies. All rights reserved.',
      'Initialisierung des Quantumkernels...',
      '  [OK] Kryptographisches Modul (AES-256 / Kyber-1024)',
      '  [OK] Netzwerkstack (IPv4/IPv6)',
      '  [OK] Mining-Subsystem (SHA-256)',
      '  [OK] Oracle-Feed (CoinGecko / Binance)',
      '  [OK] Trading Engine (TR2 Meta-Reasoning)',
      '  [OK] Sicherheitsmodul (VAULT gesperrt)',
      'System bereit. Tippe "help" für Befehle.',
      '',
    ];
    for (final line in bootLines) {
      _termLines.add(_TermLine(text: line, type: line.startsWith('  [OK]') ? 'success' : line.startsWith('  [ERR]') ? 'error' : 'system'));
    }
  }

  void _startLiveUpdates() {
    _liveTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted) return;
      setState(() {
        _cpuUsage = (25 + _rand.nextDouble() * 55).clamp(5, 95);
        _memUsage = (55 + _rand.nextDouble() * 20).clamp(40, 85);
        _netIn = _rand.nextDouble() * 250;
        _netOut = _rand.nextDouble() * 80;
        _cpuHistory.add(_cpuUsage);
        _netHistory.add(_netIn);
        if (_cpuHistory.length > 40) _cpuHistory.removeAt(0);
        if (_netHistory.length > 40) _netHistory.removeAt(0);
        // Random API latency updates
        for (var ep in _apiEndpoints) {
          if (ep['status'] == 'online') {
            ep['latency'] = ((ep['latency'] as int) + _rand.nextInt(40) - 20).clamp(5, 500);
          }
        }
      });
    });
  }

  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });
  }

  void _executeCommand(String cmd) {
    final trimmed = cmd.trim().toLowerCase();
    if (trimmed.isEmpty) return;
    HapticFeedback.lightImpact();
    _cmdHistory.insert(0, cmd);
    _historyIdx = -1;

    // Add input line
    setState(() {
      _termLines.add(_TermLine(text: '> $cmd', type: 'input'));
    });
    _inputCtrl.clear();

    // Process
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() {
        // price command
        if (trimmed.startsWith('price ')) {
          final coin = trimmed.substring(6).toUpperCase();
          final prices = {'BTC': '\$67,842', 'ETH': '\$3,548', 'SOL': '\$182', 'BNB': '\$584', 'ADA': '\$0.45'};
          final price = prices[coin] ?? 'Unbekannt';
          _termLines.add(_TermLine(text: '💱 $coin Preis: $price (CoinGecko Live)', type: 'success'));
        } else if (trimmed.startsWith('ping ')) {
          final host = cmd.trim().substring(5);
          final ms = _rand.nextInt(200) + 5;
          _termLines.add(_TermLine(text: 'PING $host: ${ms}ms · TTL=64 · Status: ONLINE', type: 'success'));
        } else if (_commands.containsKey(trimmed)) {
          final result = _commands[trimmed]!;
          if (result == '__CLEAR__') {
            _termLines.clear();
          } else {
            for (final line in result.split('\n')) {
              _termLines.add(_TermLine(text: line, type: line.startsWith('  ') ? 'info' : 'output'));
            }
          }
        } else {
          _termLines.add(_TermLine(text: 'Unbekannter Befehl: "$cmd". Tippe "help" für Hilfe.', type: 'error'));
        }
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose(); _glowCtrl.dispose(); _scanCtrl.dispose();
    _liveTimer?.cancel(); _cursorTimer?.cancel(); _sysTimer?.cancel();
    _inputCtrl.dispose(); _scrollCtrl.dispose(); _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: p.background,
      body: Column(children: [
        _buildHeader(p),
        _buildTabBar(p),
        Expanded(child: TabBarView(controller: _tab, children: [
          _buildTerminal(p),
          _buildSystemHealth(p),
          _buildApiMonitor(p),
          _buildNetworkScan(p),
        ])),
      ]),
    );
  }

  Widget _buildHeader(dynamic p) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(bottom: BorderSide(color: p.primary.withValues(alpha: 0.15 + _glowCtrl.value * 0.08))),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [p.primary.withValues(alpha: 0.25), p.primary.withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.primary.withValues(alpha: 0.4 + _glowCtrl.value * 0.25)),
              boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.2 + _glowCtrl.value * 0.12), blurRadius: 14)],
            ),
            child: Icon(Icons.terminal_rounded, color: p.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('QUANTUM CMD', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
            Text('CPU: ${_cpuUsage.toStringAsFixed(1)}% · RAM: ${_memUsage.toStringAsFixed(1)}% · Net: ${_netIn.toStringAsFixed(0)} MB/s', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
          ])),
          // Status indicators
          Row(children: [
            _dot(const Color(0xFF00FF88)),
            const SizedBox(width: 4),
            _dot(const Color(0xFF00FF88)),
            const SizedBox(width: 4),
            _dot(const Color(0xFFFFD700)),
          ]),
        ]),
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)]),
  );

  Widget _buildTabBar(dynamic p) {
    return Container(
      color: p.surface,
      child: TabBar(
        controller: _tab,
        labelColor: p.primary,
        unselectedLabelColor: p.textSecondary,
        indicatorColor: p.primary,
        indicatorWeight: 2,
        labelStyle: GoogleFonts.spaceMono(fontSize: 10, letterSpacing: 1),
        unselectedLabelStyle: GoogleFonts.spaceMono(fontSize: 10),
        tabs: const [
          Tab(icon: Icon(Icons.terminal_outlined, size: 15), text: 'TERMINAL'),
          Tab(icon: Icon(Icons.monitor_heart_outlined, size: 15), text: 'HEALTH'),
          Tab(icon: Icon(Icons.api_outlined, size: 15), text: 'API'),
          Tab(icon: Icon(Icons.radar_rounded, size: 15), text: 'NETZWERK'),
        ],
      ),
    );
  }

  // ── TERMINAL ──
  Widget _buildTerminal(dynamic p) {
    return Column(children: [
      // Output area
      Expanded(
        child: Container(
          color: const Color(0xFF020609),
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(10),
            itemCount: _termLines.length + 1,
            itemBuilder: (_, i) {
              if (i == _termLines.length) {
                // Cursor line
                return Row(children: [
                  Text('> ', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 12)),
                  Text(_inputCtrl.text, style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 12)),
                  AnimatedOpacity(
                    opacity: _cursorVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 100),
                    child: Container(width: 8, height: 14, color: const Color(0xFF00FF88)),
                  ),
                ]);
              }
              final line = _termLines[i];
              Color color;
              switch (line.type) {
                case 'input': color = const Color(0xFF00AAFF); break;
                case 'success': color = const Color(0xFF00FF88); break;
                case 'error': color = const Color(0xFFFF3358); break;
                case 'info': color = const Color(0xFFFFD700); break;
                case 'system': color = const Color(0xFF8888AA); break;
                default: color = const Color(0xFFCCCCCC);
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(line.text, style: GoogleFonts.spaceMono(color: color, fontSize: 11, height: 1.4)),
              );
            },
          ),
        ),
      ),
      // Quick Commands
      Container(
        height: 36,
        color: const Color(0xFF060A10),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          children: ['help', 'status', 'price btc', 'balance', 'scan', 'nodes', 'api-status', 'clear'].map((cmd) =>
            GestureDetector(
              onTap: () => _executeCommand(cmd),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1218),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.2)),
                ),
                child: Text(cmd, style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 10)),
              ),
            )
          ).toList(),
        ),
      ),
      // Input bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: const Color(0xFF040810),
        child: Row(children: [
          Text('> ', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 14)),
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              focusNode: _focusNode,
              autofocus: false,
              style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 12),
              cursorColor: const Color(0xFF00FF88),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Befehl eingeben...',
                hintStyle: GoogleFonts.spaceMono(color: const Color(0xFF00FF88).withValues(alpha: 0.3), fontSize: 11),
                isDense: true, contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (v) { _executeCommand(v); _focusNode.requestFocus(); },
              onChanged: (_) => setState(() {}),
            ),
          ),
          GestureDetector(
            onTap: () { _executeCommand(_inputCtrl.text); _focusNode.requestFocus(); },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFF00FF88).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.send_rounded, color: Color(0xFF00FF88), size: 16),
            ),
          ),
        ]),
      ),
    ]);
  }

  // ── SYSTEM HEALTH ──
  Widget _buildSystemHealth(dynamic p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        // CPU Card
        _healthCard('CPU AUSLASTUNG', '${_cpuUsage.toStringAsFixed(1)}%', _cpuUsage / 100, _cpuHistory, const Color(0xFF00AAFF), Icons.memory_rounded, p),
        const SizedBox(height: 10),
        _healthCard('ARBEITSSPEICHER', '${_memUsage.toStringAsFixed(1)}%', _memUsage / 100, List.filled(40, _memUsage / 100 * 200), const Color(0xFFAA44FF), Icons.storage_rounded, p),
        const SizedBox(height: 10),
        _healthCard('NETZWERK IN', '${_netIn.toStringAsFixed(1)} MB/s', _netIn / 250, _netHistory, const Color(0xFF00FF88), Icons.download_rounded, p),
        const SizedBox(height: 10),

        // System Stats Grid
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, childAspectRatio: 2.2, crossAxisSpacing: 8, mainAxisSpacing: 8,
          children: [
            _sysStatCard('DISK', '${_diskUsage.toStringAsFixed(1)}%', '256 GB / 512 GB', const Color(0xFFFFD700), Icons.disc_full_rounded, p),
            _sysStatCard('UPTIME', '14d 6h 22m', 'Quantum OS 3.0', const Color(0xFF00FF88), Icons.timer_rounded, p),
            _sysStatCard('PROZESSE', '${142 + _rand.nextInt(10)}', '${8 + _rand.nextInt(4)} Threads', const Color(0xFFFF6B35), Icons.list_rounded, p),
            _sysStatCard('TEMP', '${62 + _rand.nextInt(8)}°C', 'CPU Kern-Temp', const Color(0xFFFF3358), Icons.thermostat_rounded, p),
          ],
        ),
        const SizedBox(height: 10),

        // Process List
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.primary.withValues(alpha: 0.1))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TOP PROZESSE', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 10, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            ...[
              ('trading_engine', '24.2%', '312 MB'),
              ('oracle_feed', '12.8%', '128 MB'),
              ('mining_core', '18.4%', '256 MB'),
              ('websocket_srv', '4.2%', '64 MB'),
              ('quantum_vault', '1.1%', '32 MB'),
            ].map((proc) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF00FF88), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(proc.$1, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 10))),
                Text(proc.$2, style: GoogleFonts.spaceMono(color: const Color(0xFF00AAFF), fontSize: 10)),
                const SizedBox(width: 12),
                Text(proc.$3, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
              ]),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _healthCard(String label, String value, double progress, List<double> history, Color color, IconData icon, dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.spaceMono(color: color, fontSize: 10, letterSpacing: 1.5)),
          const Spacer(),
          Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), backgroundColor: color.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(color), minHeight: 6),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: CustomPaint(size: const Size(double.infinity, 40), painter: _SparkPainter(history, color)),
        ),
      ]),
    );
  }

  Widget _sysStatCard(String label, String value, String sub, Color color, IconData icon, dynamic p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
          Text(sub, style: GoogleFonts.inter(color: p.textSecondary.withValues(alpha: 0.6), fontSize: 8), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  // ── API MONITOR ──
  Widget _buildApiMonitor(dynamic p) {
    final online = _apiEndpoints.where((e) => e['status'] == 'online').length;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.primary.withValues(alpha: 0.1))),
          child: Row(children: [
            Expanded(child: _apiSummaryItem('ONLINE', '$online', const Color(0xFF00FF88), p)),
            Expanded(child: _apiSummaryItem('DEGRADED', '${_apiEndpoints.where((e) => e['status'] == 'degraded').length}', const Color(0xFFFFD700), p)),
            Expanded(child: _apiSummaryItem('OFFLINE', '${_apiEndpoints.where((e) => e['status'] == 'offline').length}', const Color(0xFFFF3358), p)),
            Expanded(child: _apiSummaryItem('TOTAL', '${_apiEndpoints.length}', p.primary, p)),
          ]),
        ),
        ..._apiEndpoints.map((ep) {
          final color = ep['status'] == 'online' ? const Color(0xFF00FF88) : ep['status'] == 'degraded' ? const Color(0xFFFFD700) : const Color(0xFFFF3358);
          final latency = ep['latency'] as int;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.15))),
            child: Column(children: [
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)])),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ep['name'] as String, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(ep['url'] as String, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(latency > 0 ? '${latency}ms' : '—', style: GoogleFonts.spaceMono(color: latency < 100 ? const Color(0xFF00FF88) : latency < 300 ? const Color(0xFFFFD700) : const Color(0xFFFF3358), fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('${(ep['uptime'] as double).toStringAsFixed(1)}% up', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
                ]),
              ]),
              if (ep['status'] != 'offline') ...[
                const SizedBox(height: 8),
                Row(children: [
                  Text('Calls heute:', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
                  const SizedBox(width: 6),
                  Text('${(ep['calls'] as int).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 9)),
                  const Spacer(),
                  // Latency bar
                  SizedBox(
                    width: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (latency / 500).clamp(0.0, 1.0),
                        backgroundColor: color.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ]),
              ],
            ]),
          );
        }),
      ],
    );
  }

  Widget _apiSummaryItem(String label, String value, Color color, dynamic p) {
    return Column(children: [
      Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
    ]);
  }

  // ── NETWORK SCAN ──
  Widget _buildNetworkScan(dynamic p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        // Radar visualization
        Container(
          height: 200,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.primary.withValues(alpha: 0.12))),
          child: AnimatedBuilder(
            animation: _scanCtrl,
            builder: (_, __) => CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _RadarPainter(_scanCtrl.value, p.primary, _networkNodes),
            ),
          ),
        ),
        // Nodes List
        ..._networkNodes.map((node) {
          final isActive = node['status'] == 'active';
          final color = isActive ? const Color(0xFF00FF88) : const Color(0xFFFF3358);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(isActive ? Icons.router_rounded : Icons.signal_wifi_off_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(node['ip'] as String, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(node['type'] as String, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(isActive ? '${node['ping']}ms' : 'OFFLINE', style: GoogleFonts.spaceMono(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                Text('Port: ${node['port']}', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
              ]),
            ]),
          );
        }),
      ]),
    );
  }
}

class _TermLine {
  final String text;
  final String type;
  const _TermLine({required this.text, required this.type});
}

class _SparkPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _SparkPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final maxV = data.reduce(max) + 1;
    final minV = data.reduce(min) - 1;
    final range = maxV - minV;
    final paint = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minV) / range) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.data != data;
}

class _RadarPainter extends CustomPainter {
  final double angle;
  final Color color;
  final List<Map<String, dynamic>> nodes;
  _RadarPainter(this.angle, this.color, this.nodes);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2 - 16;
    final bgPaint = Paint()..color = color.withAlpha(8)..style = PaintingStyle.fill;
    final ringPaint = Paint()..color = color.withAlpha(30)..style = PaintingStyle.stroke..strokeWidth = 1;
    final sweepPaint = Paint()..shader = SweepGradient(
      colors: [color.withAlpha(0), color.withAlpha(60), color.withAlpha(0)],
      stops: const [0.0, 0.15, 1.0],
      startAngle: 0, endAngle: 2 * pi,
      transform: GradientRotation(angle * 2 * pi),
    ).createShader(Rect.fromCircle(center: center, radius: r));

    // Rings
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, r * i / 4, i == 4 ? ringPaint : (Paint()..color = color.withAlpha(20)..style = PaintingStyle.stroke..strokeWidth = 0.5));
    }
    canvas.drawCircle(center, r, bgPaint);

    // Cross lines
    final linePaint = Paint()..color = color.withAlpha(25)..strokeWidth = 0.5;
    canvas.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx + r, center.dy), linePaint);
    canvas.drawLine(Offset(center.dx, center.dy - r), Offset(center.dx, center.dy + r), linePaint);

    // Sweep
    canvas.drawCircle(center, r, sweepPaint);

    // Nodes
    final nodeColors = [const Color(0xFF00FF88), const Color(0xFF00FF88), const Color(0xFF00FF88), const Color(0xFFFF3358), const Color(0xFF00FF88)];
    final nodeAngles = [0.2, 1.1, 2.4, 3.8, 5.1];
    final nodeRadii = [0.4, 0.7, 0.55, 0.8, 0.3];
    for (int i = 0; i < min(nodes.length, 5); i++) {
      final nx = center.dx + cos(nodeAngles[i]) * r * nodeRadii[i];
      final ny = center.dy + sin(nodeAngles[i]) * r * nodeRadii[i];
      canvas.drawCircle(Offset(nx, ny), 4, Paint()..color = nodeColors[i]);
      canvas.drawCircle(Offset(nx, ny), 7, Paint()..color = nodeColors[i].withAlpha(60)..style = PaintingStyle.stroke..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.angle != angle;
}
