import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../services/exchange_service.dart';

class QuantumMonitorScreen extends StatefulWidget {
  const QuantumMonitorScreen({super.key});
  @override
  State<QuantumMonitorScreen> createState() => _QuantumMonitorScreenState();
}

class _QuantumMonitorScreenState extends State<QuantumMonitorScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _spectrumCtrl;
  late AnimationController _darkEnergyCtrl;

  int _selectedBroker = 0;
  int _selectedTab = 0;
  // ignore: unused_field
  final bool _drawerOpen = false;

  final List<_BrokerApiEntry> _brokers = [
    const _BrokerApiEntry('Binance', true, '12ms', '\$847.293', Icons.bolt),
    const _BrokerApiEntry('Kraken', false, '—', '—', Icons.water_drop),
    const _BrokerApiEntry('Bybit', false, '—', '—', Icons.trending_up),
    const _BrokerApiEntry('OKX', false, '—', '—', Icons.hub),
    const _BrokerApiEntry('Coinbase', false, '—', '—', Icons.currency_bitcoin),
  ];

  final List<_ResonancePeak> _peaks = [
    _ResonancePeak('17-Tage', 0.78, 0.72, true),
    _ResonancePeak('89-Tage', 0.62, 0.58, true),
    _ResonancePeak('34-Tage', 0.45, 0.40, false),
    _ResonancePeak('5-Tage', 0.88, 0.82, true),
    _ResonancePeak('233-Tage', 0.35, 0.30, false),
    _ResonancePeak('55-Tage', 0.52, 0.48, true),
  ];

  final List<_InterferenceNote> _notes = [
    _InterferenceNote('Konstruktiv', '17T × 89T', 'BTC Aufwärtsdruck', true),
    _InterferenceNote('Destruktiv', '34T × 5T', 'ETH Korrekturdruck', false),
    _InterferenceNote('Neutral', '55T × 89T', 'SOL Konsolidierung', null),
  ];

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _spectrumCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3500))
      ..repeat();
    _darkEnergyCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _pulseCtrl.dispose();
    _spectrumCtrl.dispose();
    _darkEnergyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;
    final ex = context.watch<ExchangeService>();

    return Scaffold(
      backgroundColor: p.background,
      drawer: _buildBrokerDrawer(context, p),
      appBar: AppBar(
        backgroundColor: p.surface,
        title: Row(children: [
          AnimatedBuilder(
            animation: _darkEnergyCtrl,
            builder: (_, __) => Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  p.primary.withValues(alpha: 0.8 + _darkEnergyCtrl.value * 0.2),
                  p.secondary.withValues(alpha: 0.3),
                  Colors.transparent,
                ]),
                boxShadow: [BoxShadow(color: p.primary.withValues(alpha: _darkEnergyCtrl.value * 0.6), blurRadius: 12)],
              ),
              child: Icon(Icons.waves, color: p.primary, size: 13),
            ),
          ),
          const SizedBox(width: 8),
          Text('QUANTUM MONITOR', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
          Builder(builder: (_) {
            final btc = ex.getPrice('BTC');
            if (btc <= 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('BTC \$${btc.toStringAsFixed(0)}',
                  style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
            );
          }),
        ]),
        leading: IconButton(
          icon: Icon(Icons.menu, color: p.primary, size: 22),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Broker API Auswahl',
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: p.textSecondary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: p.positive.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: p.positive.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.positive,
                    boxShadow: [BoxShadow(color: p.positive.withValues(alpha: _pulseCtrl.value * 0.8), blurRadius: 6)],
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(_brokers[_selectedBroker].name.toUpperCase(), style: GoogleFonts.rajdhani(color: p.positive, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ]),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab-Leiste
          Container(
            color: p.surface,
            child: Row(
              children: [
                _QTabBtn('SPEKTRUM', 0, _selectedTab, p, () => setState(() => _selectedTab = 0)),
                _QTabBtn('BROKER', 1, _selectedTab, p, () => setState(() => _selectedTab = 1)),
                _QTabBtn('META-LOOP', 2, _selectedTab, p, () => setState(() => _selectedTab = 2)),
                _QTabBtn('FREQUENZ', 3, _selectedTab, p, () => setState(() => _selectedTab = 3)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (_selectedTab == 0) ...[
                    _buildDarkEnergyHeader(p),
                    const SizedBox(height: 12),
                    _buildSpectrumVisualizer(p),
                    const SizedBox(height: 12),
                    _buildWaveInterference(p),
                    const SizedBox(height: 12),
                    _buildResonancePeaks(p),
                    const SizedBox(height: 12),
                    _buildInterferenceNotes(p),
                    const SizedBox(height: 12),
                    _buildAgentStatus(p),
                  ],
                  if (_selectedTab == 1) ...[
                    _buildBrokerOverview(p),
                    const SizedBox(height: 12),
                    _buildLiveMarketFeed(p),
                  ],
                  if (_selectedTab == 2) ...[
                    _buildMetaLoopMonitor(p),
                  ],
                  if (_selectedTab == 3) ...[
                    _buildFrequencySpectrum(p),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quantum Spektrum Visualizer ──────────────────
  Widget _buildSpectrumVisualizer(dynamic p) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Grid lines
            CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _GridPainter(p),
            ),
            // Live Spectrum
            AnimatedBuilder(
              animation: _spectrumCtrl,
              builder: (_, __) => CustomPaint(
                size: const Size(double.infinity, 200),
                painter: _SpectrumPainter(_spectrumCtrl.value, p),
              ),
            ),
            // Labels
            Positioned(
              top: 10,
              left: 14,
              child: Text(
                'QUANTUM RESONANZ-SPEKTRUM',
                style: GoogleFonts.rajdhani(
                    color: p.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 14,
              child: Text(
                'Frequenz (Tage)',
                style: TextStyle(color: p.textSecondary, fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Wellen-Interferenz-Anzeige ───────────────────
  Widget _buildWaveInterference(dynamic p) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, __) => CustomPaint(
                size: const Size(double.infinity, 140),
                painter: _WaveInterferencePainter(_waveCtrl.value, p),
              ),
            ),
            Positioned(
              top: 10,
              left: 14,
              child: Text(
                'INTERFERENZ-MUSTER',
                style: GoogleFonts.rajdhani(
                    color: p.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 14,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.primary
                        .withValues(alpha: 0.1 + _pulseCtrl.value * 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: p.primary
                            .withValues(alpha: 0.3 + _pulseCtrl.value * 0.2)),
                  ),
                  child: Text(
                    'Konstruktiv: +0.78',
                    style: TextStyle(
                        color: p.positive,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Resonanz-Peaks Tabelle ────────────────────────
  Widget _buildResonancePeaks(dynamic p) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(Icons.graphic_eq, color: p.primary, size: 16),
                const SizedBox(width: 8),
                Text('RESONANZ-PEAKS',
                    style: GoogleFonts.rajdhani(
                        color: p.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5)),
                const Spacer(),
                Text('BTC/USDT · ${_timeStr()}',
                    style: TextStyle(color: p.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                    child: Text('Zyklus',
                        style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text('Amplitude',
                        style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text('Konfidenz',
                        style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold))),
                Text('Trend',
                    style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Divider(color: p.primary.withValues(alpha: 0.1), height: 1),
          ..._peaks.map((peak) => _buildPeakRow(p, peak)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPeakRow(dynamic p, _ResonancePeak peak) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(peak.cycle,
                style: GoogleFonts.rajdhani(
                    color: p.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                final liveAmp =
                    peak.amplitude + _pulseCtrl.value * 0.02 * (peak.bullish ? 1 : -1);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(liveAmp.toStringAsFixed(2),
                        style: TextStyle(
                            color: peak.bullish ? p.positive : p.negative,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: liveAmp,
                        backgroundColor: p.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            peak.bullish ? p.positive : p.negative),
                        minHeight: 3,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: Text(
              '${(peak.confidence * 100).toInt()}%',
              style: TextStyle(color: p.primary, fontSize: 12),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: (peak.bullish ? p.positive : p.negative)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  peak.bullish ? Icons.arrow_upward : Icons.arrow_downward,
                  color: peak.bullish ? p.positive : p.negative,
                  size: 11,
                ),
                Text(
                  peak.bullish ? 'Bull' : 'Bear',
                  style: TextStyle(
                      color: peak.bullish ? p.positive : p.negative,
                      fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Interferenz-Notizen ───────────────────────────
  Widget _buildInterferenceNotes(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.auto_awesome, color: p.secondary, size: 16),
            const SizedBox(width: 8),
            Text('EMMA ORACLE INTERFERENZ-ANALYSE',
                style: GoogleFonts.rajdhani(
                    color: p.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
          ]),
          const SizedBox(height: 12),
          ..._notes.map((note) {
            final color = note.isConstructive == null
                ? p.textSecondary
                : (note.isConstructive! ? p.positive : p.negative);
            final icon = note.isConstructive == null
                ? Icons.remove
                : (note.isConstructive! ? Icons.add_circle_outline : Icons.remove_circle_outline);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(note.type,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: p.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(note.cycles,
                                style: TextStyle(
                                    color: p.textSecondary, fontSize: 9)),
                          ),
                        ]),
                        Text(note.description,
                            style: TextStyle(
                                color: p.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          Divider(color: p.primary.withValues(alpha: 0.1)),
          const SizedBox(height: 6),
          Text(
            '🔮 Emma: „Die 17-Tage-Resonanz interferiert KONSTRUKTIV mit der 89-Tage-Welle. Aufwärtsbewegung in den nächsten 6–12h hochwahrscheinlich. Konfidenz: 82%."',
            style: GoogleFonts.exo(
                color: p.textPrimary,
                fontSize: 12,
                height: 1.5,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ── Agenten-Status ────────────────────────────────
  Widget _buildAgentStatus(dynamic p) {
    final agents = [
      ('Deep Research', 0.18, Icons.manage_search, true),
      ('Pattern Genesis', 0.22, Icons.auto_graph, true),
      ('Sentient Market', 0.20, Icons.psychology, true),
      ('Paradigm Shift', 0.14, Icons.swap_vert, true),
      ('Error & Anomaly', 0.12, Icons.bug_report_outlined, true),
      ('Strategic Synthesis', 0.14, Icons.account_tree_outlined, true),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.hub, color: p.primary, size: 16),
            const SizedBox(width: 8),
            Text('HQMLL META-AGENTEN STATUS',
                style: GoogleFonts.rajdhani(
                    color: p.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            const Spacer(),
            Text('6/6 ONLINE',
                style: TextStyle(
                    color: p.positive,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          ...agents.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(a.$3, color: p.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(a.$1,
                          style: TextStyle(
                              color: p.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text('${(a.$2 * 100).toInt()}%',
                          style: TextStyle(color: p.primary, fontSize: 11)),
                    ]),
                    const SizedBox(height: 3),
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: a.$2 + _pulseCtrl.value * 0.01,
                          backgroundColor: p.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(p.primary),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.positive,
                  boxShadow: [BoxShadow(color: p.positive.withValues(alpha: 0.7), blurRadius: 5)],
                ),
              ),
            ]),
          )),
        ],
      ),
    );
  }

  String _timeStr() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // ── BROKER DRAWER ──────────────────────────────
  Widget _buildBrokerDrawer(BuildContext context, dynamic p) {
    return Drawer(
      backgroundColor: p.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [p.primary.withValues(alpha: 0.2), Colors.transparent]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('BROKER API', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                Text('Seitenleiste · Live-Auswahl', style: TextStyle(color: p.textSecondary, fontSize: 11)),
              ]),
            ),
            Divider(color: p.primary.withValues(alpha: 0.15), height: 1),
            ..._brokers.asMap().entries.map((e) => GestureDetector(
              onTap: () {
                setState(() => _selectedBroker = e.key);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: e.key == _selectedBroker ? p.primary.withValues(alpha: 0.1) : Colors.transparent,
                  border: Border(left: BorderSide(color: e.key == _selectedBroker ? p.primary : Colors.transparent, width: 3)),
                ),
                child: Row(children: [
                  Icon(e.value.icon, color: e.key == _selectedBroker ? p.primary : p.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.value.name, style: TextStyle(color: e.key == _selectedBroker ? p.textPrimary : p.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(e.value.connected ? 'Latenz: ${e.value.latency}' : 'Nicht verbunden', style: TextStyle(color: p.textSecondary, fontSize: 10)),
                  ])),
                  if (e.value.connected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: p.positive.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(5), border: Border.all(color: p.positive.withValues(alpha: 0.4))),
                      child: Text('LIVE', style: GoogleFonts.spaceMono(color: p.positive, fontSize: 8)),
                    ),
                ]),
              ),
            )),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AKTIVER BROKER', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
                  const SizedBox(height: 4),
                  Text(_brokers[_selectedBroker].name, style: GoogleFonts.rajdhani(color: p.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Portfolio: ${_brokers[_selectedBroker].portfolio}', style: TextStyle(color: p.textSecondary, fontSize: 11)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DARK ENERGY HEADER ─────────────────────────
  Widget _buildDarkEnergyHeader(dynamic p) {
    return AnimatedBuilder(
      animation: _darkEnergyCtrl,
      builder: (_, __) {
        final pulse = (sin(_darkEnergyCtrl.value * 2 * pi) + 1) / 2;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Color.lerp(const Color(0xFF0A0015), const Color(0xFF150025), pulse)!,
                Color.lerp(const Color(0xFF000820), const Color(0xFF001030), pulse)!,
              ],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            border: Border.all(color: p.primary.withValues(alpha: 0.2 + pulse * 0.3)),
            boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.1 + pulse * 0.15), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Row(children: [
            // Quantum Auge Markenzeichen
            SizedBox(
              width: 60, height: 60,
              child: CustomPaint(painter: _DarkEyePainter(progress: _darkEnergyCtrl.value, color: p.primary, secondary: p.secondary)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('QUANTUM RESONANZ-MONITOR', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text('Dark Energy · Frequenz · Spektrum', style: TextStyle(color: p.textSecondary, fontSize: 10)),
              const SizedBox(height: 6),
              Row(children: [
                _QMetric('RESONANZ', (0.78 + pulse * 0.05).toStringAsFixed(2), p.primary, p),
                const SizedBox(width: 8),
                _QMetric('ENERGIE', '${(847 + (pulse * 50).toInt())} THz', p.secondary, p),
                const SizedBox(width: 8),
                _QMetric('KOHÄRENZ', '${(94 + (pulse * 3).toInt())}%', p.positive, p),
              ]),
            ])),
          ]),
        );
      },
    );
  }

  // ── BROKER OVERVIEW TAB ────────────────────────
  Widget _buildBrokerOverview(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('AKTIVE BROKER-VERBINDUNGEN', style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._brokers.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Icon(e.value.icon, color: e.value.connected ? p.positive : p.textSecondary, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.value.name, style: TextStyle(color: p.textPrimary, fontSize: 13)),
              LinearProgressIndicator(
                value: e.value.connected ? 0.85 + (e.key * 0.03) : 0.0,
                minHeight: 3, backgroundColor: p.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(e.value.connected ? p.positive : p.surfaceVariant),
              ),
            ])),
            const SizedBox(width: 8),
            Text(e.value.connected ? e.value.latency : '—', style: GoogleFonts.spaceMono(color: e.value.connected ? p.positive : p.textSecondary, fontSize: 10)),
          ]),
        )),
      ]),
    );
  }

  Widget _buildLiveMarketFeed(dynamic p) {
    // v30.0: Use ExchangeService for live prices
    final ex = context.read<ExchangeService>();
    String fmt(String sym, String fallback) {
      final pr = ex.getPrice(sym);
      if (pr <= 0) return fallback;
      return pr >= 1000 ? (pr / 1000).toStringAsFixed(3) + 'K' : pr.toStringAsFixed(pr >= 1 ? 2 : 4);
    }
    String chg(String sym, String fallback) {
      final tick = ex.getTick(sym);
      if (tick == null) return fallback;
      final c = tick.change24h;
      return '${c >= 0 ? '+' : ''}${c.toStringAsFixed(2)}%';
    }
    bool pos(String sym, bool fallback) {
      final tick = ex.getTick(sym);
      return tick != null ? tick.change24h >= 0 : fallback;
    }
    final assets = [
      ('BTC/USDT',   fmt('BTC', '67.842'),  chg('BTC', '+2.14%'), pos('BTC', true)),
      ('ETH/USDT',   fmt('ETH', '3.548'),   chg('ETH', '+1.87%'), pos('ETH', true)),
      ('SOL/USDT',   fmt('SOL', '182.40'),  chg('SOL', '-0.43%'), pos('SOL', false)),
      ('BNB/USDT',   fmt('BNB', '598.30'),  chg('BNB', '+0.91%'), pos('BNB', true)),
      ('QEMMA/USDT', '0.0847', '+12.45%', true), // no exchange data for QEMMA
      ('ADA/USDT',   fmt('ADA', '0.624'),   chg('ADA', '-1.23%'), pos('ADA', false)),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('LIVE MARKET FEED', style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(_brokers[_selectedBroker].name, style: GoogleFonts.spaceMono(color: p.primary, fontSize: 10)),
        ]),
        const SizedBox(height: 12),
        ...assets.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(child: Text(a.$1, style: TextStyle(color: p.textPrimary, fontSize: 12))),
            Text('\$${a.$2}', style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 12)),
            const SizedBox(width: 12),
            Text(a.$3, style: GoogleFonts.spaceMono(color: a.$4 ? p.positive : p.negative, fontSize: 12)),
          ]),
        )),
      ]),
    );
  }

  // ── META-LOOP MONITOR ─────────────────────────
  Widget _buildMetaLoopMonitor(dynamic p) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color(0xFF0D0020), p.surfaceVariant]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.secondary.withValues(alpha: 0.4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TR2 RECURSIVE META-LOOP MONITOR', style: GoogleFonts.rajdhani(color: p.secondary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          ...List.generate(7, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AnimatedBuilder(
              animation: _spectrumCtrl,
              builder: (_, __) {
                final offset = i * 0.14;
                final val = 0.5 + sin((_spectrumCtrl.value + offset) * 2 * pi) * 0.4;
                return Row(children: [
                  SizedBox(width: 16, child: Text('L${i + 1}', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9))),
                  const SizedBox(width: 6),
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: val.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: p.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(Color.lerp(p.primary, p.secondary, i / 7)!),
                    ),
                  )),
                  const SizedBox(width: 6),
                  Text('${(val * 100).toInt()}%', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
                ]);
              },
            ),
          )),
          const SizedBox(height: 8),
          Row(children: [
            _QMetric('ITERATIONEN', '14.847', p.primary, p),
            const SizedBox(width: 8),
            _QMetric('KONFIDENZ', '94.7%', p.positive, p),
            const SizedBox(width: 8),
            _QMetric('META-EBENE', 'MAX L7', p.secondary, p),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('KREALOGIK HANDLUNGS-PROTOKOLL', style: GoogleFonts.rajdhani(color: const Color(0xFFCE93D8), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...[
            ('14:35:22', 'BTC ANALYSE', 'Aufwärtstrend erkannt +2.14%', true),
            ('14:34:58', 'MUSTER', 'Fibonacci 0.618 bestätigt', true),
            ('14:34:15', 'ENTSCHEIDUNG', 'ETH Long-Signal generiert', true),
            ('14:33:42', 'OPTIMIERUNG', 'Portfolio-Rebalancing empfohlen', null),
            ('14:33:01', 'FEEDBACK', 'SOL Prognose-Abweichung -0.4%', false),
          ].map((l) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Text(l.$1, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 8)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF9C27B0).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(l.$2, style: GoogleFonts.spaceMono(color: const Color(0xFFCE93D8), fontSize: 8)),
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(l.$3, style: TextStyle(color: p.textSecondary, fontSize: 10))),
              Icon(l.$4 == null ? Icons.remove : (l.$4! ? Icons.check : Icons.close), color: l.$4 == null ? p.textSecondary : (l.$4! ? p.positive : p.negative), size: 12),
            ]),
          )),
        ]),
      ),
    ]);
  }

  // ── FREQUENZ SPEKTRUM ─────────────────────────
  Widget _buildFrequencySpectrum(dynamic p) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.primary.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('QUANTUM FREQUENZ-SPEKTRUM', style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: AnimatedBuilder(
              animation: _spectrumCtrl,
              builder: (_, __) => CustomPaint(
                painter: _FrequencyPainter(progress: _spectrumCtrl.value, color: p.primary, secondary: p.secondary),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _QMetric('ALPHA', '7-13 Hz', p.primary, p),
            const SizedBox(width: 8),
            _QMetric('BETA', '13-30 Hz', p.secondary, p),
            const SizedBox(width: 8),
            _QMetric('GAMMA', '30-100 Hz', p.positive, p),
            const SizedBox(width: 8),
            _QMetric('DELTA', '0.5-4 Hz', const Color(0xFF9C27B0), p),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.secondary.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('QUANTENFELD-INTERFERENZ', style: GoogleFonts.rajdhani(color: p.secondary, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, __) => CustomPaint(
                painter: _QuantumFieldPainter(progress: _waveCtrl.value, primary: p.primary, secondary: p.secondary),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ── Data Classes ──────────────────────────────────
class _ResonancePeak {
  final String cycle;
  final double amplitude;
  final double confidence;
  final bool bullish;
  _ResonancePeak(this.cycle, this.amplitude, this.confidence, this.bullish);
}

class _InterferenceNote {
  final String type, cycles, description;
  final bool? isConstructive;
  _InterferenceNote(this.type, this.cycles, this.description, this.isConstructive);
}

// ── Custom Painters ───────────────────────────────
class _GridPainter extends CustomPainter {
  final dynamic p;
  _GridPainter(this.p);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = p.primary.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (int i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  @override
  bool shouldRepaint(_GridPainter old) => false;
}

class _SpectrumPainter extends CustomPainter {
  final double t;
  final dynamic p;
  final Random _rnd = Random(42);

  _SpectrumPainter(this.t, this.p);

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 32;
    final barW = size.width / barCount;
    final baseHeights = List.generate(barCount, (i) {
      final base = sin(i * 0.4) * 0.3 + sin(i * 0.15) * 0.4 + 0.2;
      return (base + _rnd.nextDouble() * 0.1).clamp(0.05, 0.9);
    });

    for (int i = 0; i < barCount; i++) {
      final phase = t * 2 * pi + i * 0.3;
      final h = baseHeights[i] + sin(phase) * 0.08;
      final barH = h.clamp(0.05, 0.95) * (size.height - 30);
      final x = i * barW;
      final y = size.height - barH - 10;

      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          p.primary.withValues(alpha: 0.9),
          p.accent.withValues(alpha: 0.4),
        ],
      );

      canvas.drawRect(
        Rect.fromLTWH(x + 1, y, barW - 2, barH),
        Paint()
          ..shader = gradient
              .createShader(Rect.fromLTWH(x, y, barW, barH)),
      );

      // Peak dot
      canvas.drawCircle(
        Offset(x + barW / 2, y),
        2,
        Paint()..color = p.primary,
      );
    }

    // Overlay wave line
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = p.secondary.withValues(alpha: 0.6);
    final wavePath = Path();
    for (double x = 0; x <= size.width; x += 2) {
      final i = (x / size.width * barCount).clamp(0, barCount - 1).toInt();
      final h = (baseHeights[i] + sin(t * 2 * pi + i * 0.3) * 0.08)
          .clamp(0.05, 0.95);
      final y = size.height - h * (size.height - 30) - 10;
      if (x == 0) {
        wavePath.moveTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }
    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(_SpectrumPainter old) => old.t != t;
}

class _WaveInterferencePainter extends CustomPainter {
  final double t;
  final dynamic p;
  _WaveInterferencePainter(this.t, this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;

    // Wave 1: 17-day cycle
    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = p.primary.withValues(alpha: 0.7);
    final path1 = Path();
    for (double x = 0; x <= size.width; x++) {
      final y = cy + sin((x / size.width * 4 * pi) + t * 2 * pi) * (cy * 0.5);
      if (x == 0) {
        path1.moveTo(x, y);
      } else {
        path1.lineTo(x, y);
      }
    }
    canvas.drawPath(path1, paint1);

    // Wave 2: 89-day cycle
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = p.secondary.withValues(alpha: 0.6);
    final path2 = Path();
    for (double x = 0; x <= size.width; x++) {
      final y = cy + sin((x / size.width * 1.5 * pi) + t * 2 * pi * 0.3) * (cy * 0.4);
      if (x == 0) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }
    canvas.drawPath(path2, paint2);

    // Interference = sum of waves
    final paintI = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = p.accent.withValues(alpha: 0.9);
    final pathI = Path();
    for (double x = 0; x <= size.width; x++) {
      final w1 = sin((x / size.width * 4 * pi) + t * 2 * pi) * (cy * 0.5);
      final w2 = sin((x / size.width * 1.5 * pi) + t * 2 * pi * 0.3) * (cy * 0.4);
      final y = cy + (w1 + w2) * 0.6;
      if (x == 0) {
        pathI.moveTo(x, y);
      } else {
        pathI.lineTo(x, y);
      }
    }
    canvas.drawPath(pathI, paintI);

    // Center line
    canvas.drawLine(
      Offset(0, cy),
      Offset(size.width, cy),
      Paint()..color = p.textSecondary.withValues(alpha: 0.15)..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_WaveInterferencePainter old) => old.t != t;
}

// ═══════════════════════════════════════════════════
// QUANTUM MONITOR HELPER CLASSES
// ═══════════════════════════════════════════════════

class _BrokerApiEntry {
  final String name, latency, portfolio;
  final bool connected;
  final IconData icon;
  const _BrokerApiEntry(this.name, this.connected, this.latency, this.portfolio, this.icon);
}

class _QTabBtn extends StatelessWidget {
  final String label;
  final int index, selected;
  final dynamic p;
  final VoidCallback onTap;
  const _QTabBtn(this.label, this.index, this.selected, this.p, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? p.primary : Colors.transparent, width: 2)),
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              color: isSelected ? p.primary : p.textSecondary,
              fontSize: 8, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _QMetric extends StatelessWidget {
  final String label, value;
  final Color color;
  final dynamic p;
  const _QMetric(this.label, this.value, this.color, this.p);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(value, style: GoogleFonts.rajdhani(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: p.textSecondary, fontSize: 7), textAlign: TextAlign.center),
    ]));
  }
}

class _DarkEyePainter extends CustomPainter {
  final double progress;
  final Color color, secondary;
  const _DarkEyePainter({required this.progress, required this.color, required this.secondary});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width / 2;
    final pulse = (sin(progress * 2 * pi) + 1) / 2;

    // Äußerer Halo
    for (int ring = 3; ring >= 1; ring--) {
      final paint = Paint()
        ..color = Color.lerp(color, secondary, ring / 3)!.withValues(alpha: 0.05 + pulse * 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), r * (0.7 + ring * 0.15), paint);
    }

    // Quantum-Auge Hintergrund
    final bgPaint = Paint()
      ..shader = RadialGradient(colors: [
        color.withValues(alpha: 0.3 + pulse * 0.2),
        secondary.withValues(alpha: 0.1),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.7));
    canvas.drawCircle(Offset(cx, cy), r * 0.7, bgPaint);

    // Rotierende Frequenz-Ringe
    for (int i = 0; i < 3; i++) {
      final angle = progress * 2 * pi * (i % 2 == 0 ? 1 : -1) + (i * pi / 3);
      final paint = Paint()
        ..color = Color.lerp(color, secondary, i / 3)!.withValues(alpha: 0.6)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: r * (0.4 + i * 0.1));
      canvas.drawArc(arcRect, angle, pi * 1.5, false, paint);
    }

    // Zentrales Auge
    final eyePaint = Paint()
      ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.9), color, secondary.withValues(alpha: 0.5)])
          .createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.25));
    canvas.drawCircle(Offset(cx, cy), r * 0.25 + pulse * 3, eyePaint);

    // Pulsierender Kern
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8 + pulse * 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.08 + pulse * 2, corePaint);
  }

  @override
  bool shouldRepaint(covariant _DarkEyePainter old) => old.progress != progress;
}

class _FrequencyPainter extends CustomPainter {
  final double progress;
  final Color color, secondary;
  const _FrequencyPainter({required this.progress, required this.color, required this.secondary});

  @override
  void paint(Canvas canvas, Size size) {
    const bands = 5;
    final w = size.width / bands;
    for (int i = 0; i < bands; i++) {
      final freqProgress = (progress + i * 0.2) % 1.0;
      final h = size.height * (0.2 + sin(freqProgress * 2 * pi) * 0.4 + 0.4);
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [Color.lerp(color, secondary, i / bands)!, Colors.transparent],
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(i * w, size.height - h, w * 0.7, h))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(i * w + 2, size.height - h, w - 4, h), const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FrequencyPainter old) => old.progress != progress;
}

class _QuantumFieldPainter extends CustomPainter {
  final double progress;
  final Color primary, secondary;
  const _QuantumFieldPainter({required this.progress, required this.primary, required this.secondary});

  @override
  void paint(Canvas canvas, Size size) {
    final path1 = Path(), path2 = Path();
    for (double x = 0; x <= size.width; x += 2) {
      final t = x / size.width;
      final y1 = size.height * 0.5 + sin((t * 6 + progress * 2) * pi) * 20;
      final y2 = size.height * 0.5 + sin((t * 4 + progress * 2 + 1) * pi) * 15;
      if (x == 0) { path1.moveTo(x, y1); path2.moveTo(x, y2); }
      else { path1.lineTo(x, y1); path2.lineTo(x, y2); }
    }
    canvas.drawPath(path1, Paint()..color = primary.withValues(alpha: 0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    canvas.drawPath(path2, Paint()..color = secondary.withValues(alpha: 0.5)..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _QuantumFieldPainter old) => old.progress != progress;
}
