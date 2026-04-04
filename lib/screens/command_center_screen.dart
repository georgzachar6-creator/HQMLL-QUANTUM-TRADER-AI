/// HQMLL – Quantum Command Center
/// Live Monitoring · Device Control · Deep Meta-Thinking Loops
/// © 2025 Grigori Saks · HQMLL · Patent-Pending · CONFIDENTIAL
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});
  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _scanCtrl;

  Timer? _sysTimer;
  final Random _rng = Random();
  final _cmdCtrl = TextEditingController();
  final ScrollController _logScroll = ScrollController();

  // ─ System Metrics ─
  double _cpuLoad = 0.42;
  double _memLoad = 0.67;
  double _netIn   = 0.0;
  double _netOut  = 0.0;
  double _gpuLoad = 0.38;
  int _uptime = 0;
  int _tab = 0;

  // ─ Live Metrics History ─
  final List<double> _cpuHistory  = List.filled(30, 0.3);
  final List<double> _memHistory  = List.filled(30, 0.6);
  final List<double> _netHistory  = List.filled(30, 0.1);

  // ─ Command Logs ─
  final List<_CmdLog> _cmdLogs = [
    _CmdLog('SYSTEM', 'HQMLL Command Center v11.0 – ONLINE', _CmdType.system, true),
    _CmdLog('INIT',   'Quantum-Agents geladen – 6/6 aktiv', _CmdType.info, true),
    _CmdLog('NET',    'Live-Feed verbunden: CoinGecko · Binance · CMC', _CmdType.network, true),
    _CmdLog('VAULT',  'SecureVault initialisiert – AES-256 bereit', _CmdType.security, true),
    _CmdLog('TR2',    'Meta-Reasoning Engine – Standby', _CmdType.ai, true),
  ];

  // ─ Device Tasks ─
  final List<_Task> _tasks = [
    _Task('BTC Marktanalyse', 'TR2-CORE', true, 0.87, 'LÄUFT'),
    _Task('Portfolio Rebalancing', 'META-ANALYST', true, 0.54, 'LÄUFT'),
    _Task('QEMMA Mining', 'MINING-SYS', true, 1.0, 'AKTIV'),
    _Task('Vault Backup', 'SECURE-VAULT', false, 0.0, 'WARTEN'),
    _Task('Deploy Vercel', 'DEPLOY-HUB', false, 0.0, 'BEREIT'),
    _Task('Alarm Scanning', 'ORACLE', true, 0.32, 'LÄUFT'),
  ];

  final List<String> _suggestions = [
    'status', 'analyze btc', 'think', 'mine start',
    'vault lock', 'deploy github', 'monitor all',
    'agent list', 'task run', 'clear', 'help',
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _rotateCtrl= AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _scanCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _startMonitoring();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _scanCtrl.dispose();
    _sysTimer?.cancel();
    _cmdCtrl.dispose();
    _logScroll.dispose();
    super.dispose();
  }

  void _startMonitoring() {
    _sysTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted) return;
      setState(() {
        _cpuLoad = (_cpuLoad + (_rng.nextDouble() - 0.5) * 0.15).clamp(0.1, 0.98);
        _memLoad = (_memLoad + (_rng.nextDouble() - 0.5) * 0.05).clamp(0.3, 0.95);
        _gpuLoad = (_gpuLoad + (_rng.nextDouble() - 0.5) * 0.12).clamp(0.05, 0.92);
        _netIn   = _rng.nextDouble() * 5.0;
        _netOut  = _rng.nextDouble() * 2.0;
        _uptime++;

        _cpuHistory.removeAt(0); _cpuHistory.add(_cpuLoad);
        _memHistory.removeAt(0); _memHistory.add(_memLoad);
        _netHistory.removeAt(0); _netHistory.add(_netIn / 5.0);

        // Update running tasks
        for (final task in _tasks.where((t) => t.running)) {
          task.progress = (task.progress + _rng.nextDouble() * 0.01).clamp(0.0, 1.0);
          if (task.progress >= 1.0) task.progress = 0.1;
        }
      });
    });
  }

  void _runCommand(String cmd) {
    if (cmd.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    _cmdCtrl.clear();

    final responses = _buildResponse(cmd.toLowerCase().trim());
    for (final r in responses) {
      _cmdLogs.insert(0, r);
    }
    if (mounted) setState(() {});
  }

  List<_CmdLog> _buildResponse(String cmd) {
    if (cmd == 'help') {
      return [
        _CmdLog('HELP', 'Befehle: status · analyze [coin] · think · mine · vault · deploy · monitor · agent list · task run · clear', _CmdType.info, true),
      ];
    }
    if (cmd == 'clear') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _cmdLogs.clear());
      });
      return [];
    }
    if (cmd == 'status') {
      return [
        _CmdLog('STATUS', 'CPU: ${(_cpuLoad*100).toStringAsFixed(0)}% · RAM: ${(_memLoad*100).toStringAsFixed(0)}% · GPU: ${(_gpuLoad*100).toStringAsFixed(0)}%', _CmdType.system, true),
        _CmdLog('STATUS', 'Uptime: ${_uptime}s · Tasks aktiv: ${_tasks.where((t) => t.running).length}/${_tasks.length}', _CmdType.info, true),
      ];
    }
    if (cmd.startsWith('analyze')) {
      final coin = cmd.replaceFirst('analyze', '').trim().toUpperCase();
      return [
        _CmdLog('ANALYZE', '${coin.isEmpty ? "MARKT" : coin} → TR2-Analyse gestartet...', _CmdType.ai, true),
        _CmdLog('TR2', 'Tiefe 7 angesteuert · Mustererkennung aktiv', _CmdType.ai, true),
      ];
    }
    if (cmd == 'think' || cmd == 'tr2') {
      return [
        _CmdLog('TR2', 'Meta-Reasoning Loop initiiert – Tiefe 7/7', _CmdType.ai, true),
        _CmdLog('GENIUS', 'Emergenz erkannt – Neue Hypothese generiert', _CmdType.ai, true),
      ];
    }
    if (cmd.startsWith('mine')) {
      return [
        _CmdLog('MINING', 'Mining-System ${cmd.contains('stop') ? 'gestoppt' : 'gestartet'}', _CmdType.system, true),
      ];
    }
    if (cmd.startsWith('vault')) {
      return [
        _CmdLog('VAULT', 'SecureVault ${cmd.contains('lock') ? 'gesperrt' : 'entsperrt'}', _CmdType.security, true),
      ];
    }
    if (cmd.startsWith('deploy')) {
      final target = cmd.replaceFirst('deploy', '').trim();
      return [
        _CmdLog('DEPLOY', '${target.isEmpty ? 'alle Plattformen' : target} → Deploy initiiert', _CmdType.network, true),
        _CmdLog('GIT', 'git push origin main → ausstehend', _CmdType.network, true),
      ];
    }
    if (cmd == 'agent list') {
      return [
        _CmdLog('AGENTS', '6/6 aktiv: META-ANALYST · ORACLE · TR2-CORE · MEMORY · REASONING · GENIUS', _CmdType.ai, true),
      ];
    }
    return [
      _CmdLog('CMD', '> $cmd', _CmdType.command, true),
      _CmdLog('SYS', 'Befehl verarbeitet – OK', _CmdType.system, true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    const cmdColor = Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: p.background,
      body: Column(
        children: [
          _buildHeader(p, cmdColor),
          _buildMetricsBar(p, cmdColor),
          _buildTabBar(p, cmdColor),
          Expanded(child: _buildTabContent(p, cmdColor)),
          _buildTerminal(p, cmdColor),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic p, Color c) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c.withValues(alpha: 0.1 + _glowCtrl.value * 0.05), p.background]),
          border: Border(bottom: BorderSide(color: c.withValues(alpha: 0.2))),
        ),
        child: Row(children: [
          AnimatedBuilder(
            animation: _rotateCtrl,
            builder: (_, __) => Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.withValues(alpha: 0.5), width: 2),
                boxShadow: [BoxShadow(color: c.withValues(alpha: 0.3 + _glowCtrl.value * 0.15), blurRadius: 14)],
              ),
              child: Icon(Icons.terminal, color: c, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('COMMAND CENTER',
              style: GoogleFonts.spaceMono(color: c, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
            Text('Live Monitoring · Task Control · Deep AI Loops',
              style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
          ])),
          // Uptime badge
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.08 + _pulseCtrl.value * 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
              ),
              child: Column(children: [
                Text('ONLINE', style: GoogleFonts.spaceMono(color: const Color(0xFF00E676), fontSize: 8, fontWeight: FontWeight.bold)),
                Text('${_uptime}s', style: GoogleFonts.rajdhani(color: const Color(0xFF00E676), fontSize: 10)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildMetricsBar(dynamic p, Color c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.12)),
      ),
      child: Row(children: [
        _metricGauge('CPU', _cpuLoad, const Color(0xFF00E5FF), p),
        _vDivider(),
        _metricGauge('RAM', _memLoad, const Color(0xFF7B00D4), p),
        _vDivider(),
        _metricGauge('GPU', _gpuLoad, const Color(0xFFFF9100), p),
        _vDivider(),
        Expanded(child: Column(children: [
          Text('↓ ${_netIn.toStringAsFixed(1)}', style: GoogleFonts.rajdhani(color: const Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.bold)),
          Text('↑ ${_netOut.toStringAsFixed(1)} MB/s', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7)),
          Text('NETZ', style: GoogleFonts.spaceMono(color: p.textSecondary.withValues(alpha: 0.5), fontSize: 6)),
        ])),
      ]),
    );
  }

  Widget _metricGauge(String label, double val, Color color, dynamic p) {
    return Expanded(
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 44, height: 44,
            child: CircularProgressIndicator(
              value: val, strokeWidth: 4,
              backgroundColor: p.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text('${(val*100).toStringAsFixed(0)}%',
            style: GoogleFonts.rajdhani(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 3),
        Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 7)),
      ]),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 44, color: Colors.white.withValues(alpha: 0.05), margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _buildTabBar(dynamic p, Color c) {
    final tabs = ['MONITOR', 'TASKS', 'PROTOKOLL', 'TIEFE'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 34,
      decoration: BoxDecoration(
        color: p.surface, borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final sel = _tab == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: sel ? c : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(child: Text(e.value,
                  style: GoogleFonts.spaceMono(
                    color: sel ? Colors.black : p.textSecondary,
                    fontSize: 7, fontWeight: FontWeight.bold))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(dynamic p, Color c) {
    switch (_tab) {
      case 0: return _buildMonitorTab(p, c);
      case 1: return _buildTasksTab(p, c);
      case 2: return _buildLogsTab(p, c);
      case 3: return _buildDeepThinkTab(p, c);
      default: return const SizedBox();
    }
  }

  Widget _buildMonitorTab(dynamic p, Color c) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: [
        _buildSparkCard('CPU Verlauf', _cpuHistory, const Color(0xFF00E5FF), p),
        _buildSparkCard('RAM Verlauf', _memHistory, const Color(0xFF7B00D4), p),
        _buildSparkCard('Netz I/O', _netHistory, const Color(0xFF00E676), p),
        const SizedBox(height: 8),
        // System info grid
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: [
            _infoCard('App Version', 'v11.0.0', c, p),
            _infoCard('Plattform', 'Android/Web', const Color(0xFF00E676), p),
            _infoCard('Dart VM', '3.9.2', const Color(0xFF7B00D4), p),
            _infoCard('Flutter', '3.35.4', const Color(0xFFFF9100), p),
            _infoCard('Screens', '18', c, p),
            _infoCard('Services', '3', const Color(0xFF00E676), p),
          ],
        ),
      ],
    );
  }

  Widget _buildSparkCard(String title, List<double> data, Color color, dynamic p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
          Text('${(data.last * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.rajdhani(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: CustomPaint(
            painter: _SparklinePainter(data, color),
            size: const Size(double.infinity, 32),
          ),
        ),
      ]),
    );
  }

  Widget _infoCard(String l, String v, Color c, dynamic p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.12)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
          Text(v, style: GoogleFonts.rajdhani(color: c, fontSize: 14, fontWeight: FontWeight.bold)),
        ])),
      ]),
    );
  }

  Widget _buildTasksTab(dynamic p, Color c) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: _tasks.map((task) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface, borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.running
                ? const Color(0xFF00E676).withValues(alpha: 0.25)
                : p.primary.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.running
                  ? const Color(0xFF00E676).withValues(alpha: 0.1)
                  : p.surfaceVariant,
              border: Border.all(
                color: task.running
                    ? const Color(0xFF00E676).withValues(alpha: 0.4)
                    : p.primary.withValues(alpha: 0.1)),
            ),
            child: Icon(
              task.running ? Icons.play_arrow : Icons.pause,
              color: task.running ? const Color(0xFF00E676) : p.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.name,
              style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Agent: ${task.agent}',
              style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
            if (task.running) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: task.progress, minHeight: 3,
                  backgroundColor: p.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                ),
              ),
            ],
          ])),
          const SizedBox(width: 8),
          Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: task.running
                    ? const Color(0xFF00E676).withValues(alpha: 0.1)
                    : p.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(task.status,
                style: GoogleFonts.spaceMono(
                  color: task.running ? const Color(0xFF00E676) : p.textSecondary,
                  fontSize: 7, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  task.running = !task.running;
                  if (task.running) task.progress = 0.0;
                });
                _cmdLogs.insert(0, _CmdLog(
                  'TASK',
                  '${task.name}: ${task.running ? "gestartet" : "gestoppt"}',
                  _CmdType.system, true,
                ));
              },
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: p.surfaceVariant, borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: p.primary.withValues(alpha: 0.1)),
                ),
                child: Icon(task.running ? Icons.stop : Icons.play_arrow, color: p.textSecondary, size: 13),
              ),
            ),
          ]),
        ]),
      )).toList(),
    );
  }

  Widget _buildLogsTab(dynamic p, Color c) {
    final typeColors = {
      _CmdType.system: p.primary,
      _CmdType.info: const Color(0xFF2979FF),
      _CmdType.ai: const Color(0xFF00E5FF),
      _CmdType.network: const Color(0xFF00E676),
      _CmdType.security: const Color(0xFF7B00D4),
      _CmdType.command: const Color(0xFFFF9100),
      _CmdType.error: const Color(0xFFFF1744),
    };
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _cmdLogs.length,
      itemBuilder: (_, i) {
        final log = _cmdLogs[i];
        final color = typeColors[log.type] ?? p.primary;
        return Container(
          margin: const EdgeInsets.only(bottom: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: p.surface, borderRadius: BorderRadius.circular(6),
            border: Border(left: BorderSide(color: color, width: 2)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3)),
              child: Text(log.tag,
                style: GoogleFonts.spaceMono(color: color, fontSize: 7, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(log.message,
              style: GoogleFonts.robotoMono(color: p.textSecondary, fontSize: 9))),
          ]),
        );
      },
    );
  }

  Widget _buildDeepThinkTab(dynamic p, Color c) {
    final loops = [
      ('LOOP-1', 'Dateneingabe', 'Marktdaten · Wallet · Portfolio', const Color(0xFF2979FF), 1.0),
      ('LOOP-2', 'Mustererkennung', 'Fibonacci · RSI · MACD · Wellen', const Color(0xFF00E5FF), 0.87),
      ('LOOP-3', 'Meta-Analyse', 'Sentiment · Macro · On-Chain', const Color(0xFF7B00D4), 0.74),
      ('LOOP-4', 'TR2 Reasoning', 'Hypothesen · Konfidenz · Tiefe', const Color(0xFF00E676), 0.62),
      ('LOOP-5', 'Genius-Synthese', 'Emergenz · Neue Erkenntnis', const Color(0xFFFF9100), 0.45),
      ('LOOP-6', 'Entscheidung', 'Signal · Order · Warnung', const Color(0xFFFF1744), 0.31),
      ('LOOP-7', 'Feedback', 'Selbst-Optimierung · Lernen', c, 0.18),
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TR2 DEEP META-THINKING LOOPS',
                style: GoogleFonts.spaceMono(color: c, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text('Rekursive Tiefe: 7/7 · HQMLL Quantum Algorithm',
                style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
              const SizedBox(height: 12),
              ...loops.map((loop) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                    width: 52, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    decoration: BoxDecoration(
                      color: loop.$4.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: loop.$4.withValues(alpha: 0.3)),
                    ),
                    child: Text(loop.$1, style: GoogleFonts.spaceMono(color: loop.$4, fontSize: 7, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(loop.$2, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 9, fontWeight: FontWeight.bold)),
                      Text('${(loop.$5 * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.rajdhani(color: loop.$4, fontSize: 11, fontWeight: FontWeight.bold)),
                    ]),
                    Text(loop.$3, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 8)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: loop.$5, minHeight: 3,
                        backgroundColor: p.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(loop.$4),
                      ),
                    ),
                  ])),
                ]),
              )),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTerminal(dynamic p, Color c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: c.withValues(alpha: 0.2))),
      ),
      child: Column(
        children: [
          // Suggestions
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _suggestions.map((s) => GestureDetector(
                onTap: () => _runCommand(s),
                child: Container(
                  margin: const EdgeInsets.only(right: 6, bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.withValues(alpha: 0.2)),
                  ),
                  child: Text(s, style: GoogleFonts.robotoMono(color: c, fontSize: 9)),
                ),
              )).toList(),
            ),
          ),
          // Input row
          Row(children: [
            Text('❯ ', style: GoogleFonts.spaceMono(color: const Color(0xFF00E676), fontSize: 14, fontWeight: FontWeight.bold)),
            Expanded(
              child: TextField(
                controller: _cmdCtrl,
                style: GoogleFonts.robotoMono(color: const Color(0xFF00E676), fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Befehl eingeben...',
                  hintStyle: GoogleFonts.robotoMono(color: p.textSecondary.withValues(alpha: 0.3), fontSize: 10),
                  border: InputBorder.none, contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: _runCommand,
              ),
            ),
            GestureDetector(
              onTap: () => _runCommand(_cmdCtrl.text),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.send, color: c, size: 15),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Sparkline Painter ─────────────────────────────────
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - data[i] * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    // Fill
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, paint..style = PaintingStyle.fill..color = color.withValues(alpha: 0.08));
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.data != data;
}

// ── Data Models ───────────────────────────────────────
enum _CmdType { system, info, ai, network, security, command, error }

class _CmdLog {
  final String tag, message;
  final _CmdType type;
  final bool success;
  _CmdLog(this.tag, this.message, this.type, this.success);
}

class _Task {
  final String name, agent;
  bool running;
  double progress;
  final String status;
  _Task(this.name, this.agent, this.running, this.progress, this.status);
}
