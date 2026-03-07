import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

class AIForgeScreen extends StatefulWidget {
  const AIForgeScreen({super.key});
  @override
  State<AIForgeScreen> createState() => _AIForgeScreenState();
}

class _AIForgeScreenState extends State<AIForgeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _trainCtrl;
  bool _isTraining = false;
  double _trainProgress = 0.0;
  int _trainEpoch = 0;
  int _activeTab = 0; // 0=Agenten, 1=Modell, 2=Training, 3=Logs
  final Random _rng = Random(77);

  // Agent weights (0.0 – 1.0)
  final List<_Agent> _agents = [
    _Agent('META-ORCHESTRATOR', 'Koordiniert alle Sub-Agenten', Icons.hub, 0.95, 0.92, 'AKTIV'),
    _Agent('TREND-SENSOR', 'Erkennt Markttrends per Wellenanalyse', Icons.trending_up, 0.87, 0.85, 'AKTIV'),
    _Agent('SENTIMENT-AGENT', 'Analysiert Marktsentiment & News', Icons.psychology, 0.74, 0.80, 'AKTIV'),
    _Agent('RISK-SENTINEL', 'Überwacht Portfolio-Risiken', Icons.shield_outlined, 0.91, 0.88, 'AKTIV'),
    _Agent('QUANTUM-RESONATOR', 'Berechnet Quantenresonanz-Signale', Icons.waves, 0.83, 0.79, 'AKTIV'),
    _Agent('EMMA-CORE', 'Zentrale Entscheidungslogik', Icons.memory, 0.98, 0.96, 'AKTIV'),
  ];

  // Model parameters
  double _learningRate = 0.001;
  double _momentum = 0.9;
  double _dropoutRate = 0.2;
  int _batchSize = 32;
  int _epochs = 50;
  String _optimizer = 'Adam';
  String _modelVersion = '2.4.1';
  final List<String> _trainingLog = [];
  double _bestAccuracy = 0.9445;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _trainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _trainCtrl.dispose();
    super.dispose();
  }

  void _startTraining() {
    if (_isTraining) return;
    setState(() {
      _isTraining = true;
      _trainProgress = 0.0;
      _trainEpoch = 0;
      _trainingLog.clear();
      _trainingLog.add('[${_ts()}] Training gestartet — Modell v$_modelVersion');
      _trainingLog.add('[${_ts()}] Optimizer: $_optimizer, LR: ${_learningRate.toStringAsFixed(4)}');
      _trainingLog.add('[${_ts()}] Batch-Size: $_batchSize, Dropout: ${(_dropoutRate * 100).toStringAsFixed(0)}%');
    });

    _runEpoch();
  }

  void _runEpoch() {
    if (_trainEpoch >= _epochs) {
      setState(() {
        _isTraining = false;
        _trainProgress = 1.0;
        _bestAccuracy = (_bestAccuracy + _rng.nextDouble() * 0.005).clamp(0.0, 0.999);
        _modelVersion = '${_modelVersion.split('.')[0]}.${_modelVersion.split('.')[1]}.${int.parse(_modelVersion.split('.')[2]) + 1}';
        _trainingLog.add('[${_ts()}] ✅ Training abgeschlossen!');
        _trainingLog.add('[${_ts()}] Genauigkeit: ${(_bestAccuracy * 100).toStringAsFixed(2)}%');
        _trainingLog.add('[${_ts()}] Modell gespeichert als v$_modelVersion');
      });
      return;
    }

    Future.delayed(Duration(milliseconds: (200 + _rng.nextInt(300))), () {
      if (!mounted) return;
      setState(() {
        _trainEpoch++;
        _trainProgress = _trainEpoch / _epochs;
        final loss = (0.45 * pow(0.97, _trainEpoch) + _rng.nextDouble() * 0.02).toDouble();
        final acc = (1.0 - loss * 0.8).clamp(0.0, 1.0);
        if (_trainEpoch % 5 == 0 || _trainEpoch == 1) {
          _trainingLog.add('[${_ts()}] Epoche $_trainEpoch/$_epochs — Loss: ${loss.toStringAsFixed(4)}, Acc: ${(acc * 100).toStringAsFixed(1)}%');
        }
        if (_trainEpoch % 10 == 0) {
          _trainingLog.add('[${_ts()}] → Agent-Sync: ${_agents.where((a) => a.status == 'AKTIV').length}/6 synced');
        }
      });
      _runEpoch();
    });
  }

  void _stopTraining() {
    setState(() {
      _isTraining = false;
      _trainingLog.add('[${_ts()}] ⏹ Training gestoppt bei Epoche $_trainEpoch/$_epochs');
    });
  }

  String _ts() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(54),
        child: Container(
          color: p.background,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 54,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Icon(
                        Icons.auto_awesome,
                        color: p.primary.withValues(alpha: 0.7 + _pulseCtrl.value * 0.3),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('AI FORGE', style: GoogleFonts.spaceMono(
                      color: p.textPrimary, fontSize: 14,
                      fontWeight: FontWeight.bold, letterSpacing: 2,
                    )),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text('v$_modelVersion', style: GoogleFonts.spaceMono(
                        color: p.primary, fontSize: 8,
                      )),
                    ),
                    const Spacer(),
                    // Accuracy badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.positive.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: p.positive.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, color: p.positive, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${(_bestAccuracy * 100).toStringAsFixed(1)}%',
                            style: GoogleFonts.rajdhani(
                              color: p.positive, fontSize: 12, fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(p),
          Expanded(
            child: IndexedStack(
              index: _activeTab,
              children: [
                _buildAgentTab(p),
                _buildModelTab(p),
                _buildTrainingTab(p),
                _buildLogsTab(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(dynamic p) {
    final tabs = ['AGENTEN', 'MODELL', 'TRAINING', 'LOGS'];
    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _activeTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: active ? p.primary.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: active ? Border.all(color: p.primary.withValues(alpha: 0.3)) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[i],
                  style: GoogleFonts.spaceMono(
                    color: active ? p.primary : p.textSecondary,
                    fontSize: 9,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── TAB 0: Agenten ────────────────────────────────
  Widget _buildAgentTab(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sectionHeader('META-AGENTEN KONFIGURATION', p),
        const SizedBox(height: 8),
        ..._agents.map((agent) => _AgentCard(
          agent: agent,
          palette: p,
          onWeightChanged: (v) => setState(() => agent.weight = v),
          onConfidenceChanged: (v) => setState(() => agent.confidence = v),
        )),
        const SizedBox(height: 12),
        // Overall confidence
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(children: [
                Icon(Icons.insights, color: p.primary, size: 16),
                const SizedBox(width: 8),
                Text('GESAMT-KONFIDENZ', style: GoogleFonts.spaceMono(
                  color: p.textSecondary, fontSize: 9, letterSpacing: 1,
                )),
                const Spacer(),
                Text(
                  '${(_agents.fold<double>(0, (s, a) => s + a.confidence) / _agents.length * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.rajdhani(
                    color: p.primary, fontSize: 18, fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _agents.fold<double>(0, (s, a) => s + a.confidence) / _agents.length,
                  backgroundColor: p.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(p.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── TAB 1: Modell ─────────────────────────────────
  Widget _buildModelTab(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sectionHeader('MODELL-PARAMETER', p),
        const SizedBox(height: 8),
        _ParamSlider(
          label: 'LERNRATE',
          value: _learningRate,
          min: 0.0001,
          max: 0.01,
          divisions: 99,
          displayValue: _learningRate.toStringAsFixed(4),
          palette: p,
          onChanged: (v) => setState(() => _learningRate = v),
        ),
        _ParamSlider(
          label: 'MOMENTUM',
          value: _momentum,
          min: 0.5,
          max: 0.99,
          divisions: 49,
          displayValue: _momentum.toStringAsFixed(2),
          palette: p,
          onChanged: (v) => setState(() => _momentum = v),
        ),
        _ParamSlider(
          label: 'DROPOUT-RATE',
          value: _dropoutRate,
          min: 0.0,
          max: 0.5,
          divisions: 50,
          displayValue: '${(_dropoutRate * 100).toStringAsFixed(0)}%',
          palette: p,
          onChanged: (v) => setState(() => _dropoutRate = v),
        ),
        const SizedBox(height: 8),
        // Batch size + epochs
        Row(children: [
          Expanded(child: _IntPicker(
            label: 'BATCH-SIZE',
            value: _batchSize,
            options: const [8, 16, 32, 64, 128],
            palette: p,
            onChanged: (v) => setState(() => _batchSize = v),
          )),
          const SizedBox(width: 8),
          Expanded(child: _IntPicker(
            label: 'EPOCHEN',
            value: _epochs,
            options: const [10, 25, 50, 100, 200],
            palette: p,
            onChanged: (v) => setState(() => _epochs = v),
          )),
        ]),
        const SizedBox(height: 8),
        // Optimizer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OPTIMIZER', style: GoogleFonts.spaceMono(
                color: p.textSecondary, fontSize: 9, letterSpacing: 1,
              )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ['Adam', 'SGD', 'RMSProp', 'AdaGrad', 'Nadam'].map((o) {
                  final active = _optimizer == o;
                  return GestureDetector(
                    onTap: () => setState(() => _optimizer = o),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? p.primary.withValues(alpha: 0.15) : p.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: active ? p.primary.withValues(alpha: 0.5) : p.primary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(o, style: GoogleFonts.spaceMono(
                        color: active ? p.primary : p.textSecondary,
                        fontSize: 10, fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      )),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Network architecture viz
        _buildArchViz(p),
      ],
    );
  }

  Widget _buildArchViz(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NETZWERK-ARCHITEKTUR', style: GoogleFonts.spaceMono(
            color: p.textSecondary, fontSize: 9, letterSpacing: 1,
          )),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LayerNode('INPUT\n128', p.primary, p),
              _arrow(p),
              _LayerNode('HIDDEN\n256', p.accent, p),
              _arrow(p),
              _LayerNode('HIDDEN\n128', p.accent, p),
              _arrow(p),
              _LayerNode('HIDDEN\n64', p.accent, p),
              _arrow(p),
              _LayerNode('OUT\n6', p.positive, p),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Aktivierung: GELU  •  ', style: TextStyle(color: p.textSecondary, fontSize: 10)),
              Text('Batch-Norm: AN  •  ', style: TextStyle(color: p.textSecondary, fontSize: 10)),
              Text('Skip-Connections: JA', style: TextStyle(color: p.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _arrow(dynamic p) => Icon(Icons.arrow_forward_ios, color: p.primary.withValues(alpha: 0.4), size: 12);

  // ── TAB 2: Training ───────────────────────────────
  Widget _buildTrainingTab(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sectionHeader('TRAINING STARTEN', p),
        const SizedBox(height: 12),
        // Status card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isTraining
                  ? p.primary.withValues(alpha: 0.4)
                  : p.primary.withValues(alpha: 0.15),
            ),
            boxShadow: _isTraining ? [
              BoxShadow(color: p.primary.withValues(alpha: 0.1), blurRadius: 16, spreadRadius: 2),
            ] : null,
          ),
          child: Column(
            children: [
              Row(children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isTraining
                          ? p.primary.withValues(alpha: 0.5 + _pulseCtrl.value * 0.5)
                          : p.textSecondary,
                      boxShadow: _isTraining ? [
                        BoxShadow(
                          color: p.primary.withValues(alpha: 0.5),
                          blurRadius: 8 + _pulseCtrl.value * 6,
                        ),
                      ] : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _isTraining
                      ? 'TRAINING LÄUFT — Epoche $_trainEpoch/$_epochs'
                      : _trainProgress == 1.0
                      ? 'TRAINING ABGESCHLOSSEN'
                      : 'BEREIT ZUM TRAINING',
                  style: GoogleFonts.spaceMono(
                    color: _isTraining ? p.primary : p.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
              if (_isTraining || _trainProgress > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _trainProgress,
                    backgroundColor: p.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _trainProgress == 1.0 ? p.positive : p.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(_trainProgress * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.rajdhani(color: p.primary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Epoche $_trainEpoch / $_epochs',
                      style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              // Config summary
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _ConfigChip('LR: ${_learningRate.toStringAsFixed(4)}', p),
                  _ConfigChip('Opt: $_optimizer', p),
                  _ConfigChip('Batch: $_batchSize', p),
                  _ConfigChip('Epochen: $_epochs', p),
                  _ConfigChip('Dropout: ${(_dropoutRate * 100).toStringAsFixed(0)}%', p),
                ],
              ),
              const SizedBox(height: 14),
              // Buttons
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTraining ? null : _startTraining,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text('TRAINING STARTEN', style: GoogleFonts.spaceMono(
                      fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5,
                    )),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.primary,
                      foregroundColor: p.background,
                      disabledBackgroundColor: p.primary.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                if (_isTraining) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _stopTraining,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.negative.withValues(alpha: 0.15),
                      foregroundColor: p.negative,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: p.negative.withValues(alpha: 0.5)),
                      ),
                    ),
                    child: const Icon(Icons.stop, size: 18),
                  ),
                ],
              ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Stats
        _buildTrainingStats(p),
      ],
    );
  }

  Widget _buildTrainingStats(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MODELL-STATISTIKEN', style: GoogleFonts.spaceMono(
            color: p.textSecondary, fontSize: 9, letterSpacing: 1,
          )),
          const SizedBox(height: 12),
          Row(children: [
            _StatTile('GENAUIGKEIT', '${(_bestAccuracy * 100).toStringAsFixed(2)}%', p.positive, p),
            _StatTile('VERSION', 'v$_modelVersion', p.primary, p),
            _StatTile('AGENTEN', '${_agents.length}/6', p.accent, p),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _StatTile('PARAMETER', '2.4M', p.textPrimary, p),
            _StatTile('TRAININGS-DATEN', '182K', p.textPrimary, p),
            _StatTile('LAST TRAINED', 'Heute', p.textPrimary, p),
          ]),
        ],
      ),
    );
  }

  // ── TAB 3: Logs ───────────────────────────────────
  Widget _buildLogsTab(dynamic p) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text('TRAINING LOGS', style: GoogleFonts.spaceMono(
                color: p.textSecondary, fontSize: 9, letterSpacing: 1.5,
              )),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _trainingLog.clear()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.negative.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: p.negative.withValues(alpha: 0.3)),
                  ),
                  child: Text('LEEREN', style: GoogleFonts.spaceMono(
                    color: p.negative, fontSize: 8,
                  )),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0F1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.primary.withValues(alpha: 0.15)),
            ),
            child: _trainingLog.isEmpty
                ? Center(
              child: Text(
                'Kein Training gestartet.\nGehe zu "TRAINING" um das Modell zu trainieren.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 11),
              ),
            )
                : ListView.builder(
              itemCount: _trainingLog.length,
              itemBuilder: (_, i) {
                final log = _trainingLog[_trainingLog.length - 1 - i];
                final isSuccess = log.contains('✅');
                final isStop = log.contains('⏹');
                final isEpoch = log.contains('Epoche');
                Color color = const Color(0xFF8892A4);
                if (isSuccess) color = const Color(0xFF22C55E);
                if (isStop) color = const Color(0xFFEF4444);
                if (isEpoch) color = const Color(0xFF60A5FA);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    log,
                    style: GoogleFonts.spaceMono(color: color, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String text, dynamic p) {
    return Text(text, style: GoogleFonts.spaceMono(
      color: p.textSecondary, fontSize: 9, letterSpacing: 1.5,
      fontWeight: FontWeight.bold,
    ));
  }
}

// ── Agent Card ─────────────────────────────────────────
class _AgentCard extends StatelessWidget {
  final _Agent agent;
  final dynamic palette;
  final void Function(double) onWeightChanged;
  final void Function(double) onConfidenceChanged;
  const _AgentCard({
    required this.agent,
    required this.palette,
    required this.onWeightChanged,
    required this.onConfidenceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.primary.withValues(alpha: 0.3)),
              ),
              child: Icon(agent.icon, color: p.primary, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(agent.name, style: GoogleFonts.spaceMono(
                    color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold,
                  )),
                  Text(agent.description, style: GoogleFonts.inter(
                    color: p.textSecondary, fontSize: 10,
                  )),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: p.positive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: p.positive.withValues(alpha: 0.3)),
              ),
              child: Text(agent.status, style: GoogleFonts.spaceMono(
                color: p.positive, fontSize: 7, fontWeight: FontWeight.bold,
              )),
            ),
          ]),
          const SizedBox(height: 10),
          // Weight slider
          _SliderRow(
            label: 'GEWICHT',
            value: agent.weight,
            color: p.primary,
            palette: p,
            onChanged: onWeightChanged,
          ),
          const SizedBox(height: 6),
          // Confidence slider
          _SliderRow(
            label: 'KONFIDENZ',
            value: agent.confidence,
            color: p.accent,
            palette: p,
            onChanged: onConfidenceChanged,
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final dynamic palette;
  final void Function(double) onChanged;
  const _SliderRow({
    required this.label,
    required this.value,
    required this.color,
    required this.palette,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(label, style: GoogleFonts.spaceMono(
            color: palette.textSecondary, fontSize: 8, letterSpacing: 0.5,
          )),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: color,
              inactiveTrackColor: palette.surfaceVariant,
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.15),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            '${(value * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: GoogleFonts.rajdhani(
              color: color, fontSize: 12, fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Param Slider ───────────────────────────────────────
class _ParamSlider extends StatelessWidget {
  final String label;
  final double value, min, max;
  final int divisions;
  final String displayValue;
  final dynamic palette;
  final void Function(double) onChanged;
  const _ParamSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.palette,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: GoogleFonts.spaceMono(
              color: p.textSecondary, fontSize: 9, letterSpacing: 0.5,
            )),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                activeTrackColor: p.primary,
                inactiveTrackColor: p.surfaceVariant,
                thumbColor: p.primary,
                overlayColor: p.primary.withValues(alpha: 0.15),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: GoogleFonts.rajdhani(
                color: p.primary, fontSize: 13, fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Int Picker ─────────────────────────────────────────
class _IntPicker extends StatelessWidget {
  final String label;
  final int value;
  final List<int> options;
  final dynamic palette;
  final void Function(int) onChanged;
  const _IntPicker({
    required this.label,
    required this.value,
    required this.options,
    required this.palette,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.spaceMono(
            color: p.textSecondary, fontSize: 9, letterSpacing: 0.5,
          )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: options.map((o) {
              final active = value == o;
              return GestureDetector(
                onTap: () => onChanged(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: active ? p.primary.withValues(alpha: 0.15) : p.surfaceVariant,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: active ? p.primary.withValues(alpha: 0.5) : Colors.transparent,
                    ),
                  ),
                  child: Text('$o', style: GoogleFonts.rajdhani(
                    color: active ? p.primary : p.textSecondary,
                    fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Config Chip ────────────────────────────────────────
class _ConfigChip extends StatelessWidget {
  final String text;
  final dynamic palette;
  const _ConfigChip(this.text, this.palette);

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: p.surfaceVariant,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Text(text, style: GoogleFonts.spaceMono(
        color: p.textSecondary, fontSize: 9,
      )),
    );
  }
}

// ── Layer Node ─────────────────────────────────────────
class _LayerNode extends StatelessWidget {
  final String label;
  final Color color;
  final dynamic palette;
  const _LayerNode(this.label, this.color, this.palette);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(label, textAlign: TextAlign.center,
        style: GoogleFonts.spaceMono(color: color, fontSize: 7.5, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── Stat Tile ──────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final dynamic palette;
  const _StatTile(this.label, this.value, this.color, this.palette);

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.rajdhani(
            color: color, fontSize: 15, fontWeight: FontWeight.bold,
          )),
          Text(label, style: GoogleFonts.spaceMono(
            color: p.textSecondary, fontSize: 7.5, letterSpacing: 0.3,
          )),
        ],
      ),
    );
  }
}

// ── Data Classes ───────────────────────────────────────
class _Agent {
  final String name, description, status;
  final IconData icon;
  double weight, confidence;
  _Agent(this.name, this.description, this.icon, this.weight, this.confidence, this.status);
}
