import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/theme_provider.dart';
import '../widgets/quantum_eye_widget.dart';
import '../widgets/asset_icon_widget.dart';
import '../services/exchange_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  int _tabIndex = 0; // 0=Guthaben 1=Senden 2=Empfangen 3=Verlauf
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  String _selectedAsset = 'QEMMA';
  bool _sendConfirmed = false;
  final Random _rnd = Random(77);

  final List<_WalletAsset> _assets = [
    _WalletAsset('QEMMA', '\$QEMMA Token', 1284.0, 0.0847, 'SOL'),
    _WalletAsset('BTC', 'Bitcoin', 0.42, 67842.50, 'BTC'),
    _WalletAsset('ETH', 'Ethereum', 3.85, 3548.20, 'ETH'),
    _WalletAsset('SOL', 'Solana', 12.0, 182.40, 'SOL'),
    _WalletAsset('USDT', 'Tether', 1480.0, 1.0, 'ETH'),
    _WalletAsset('BNB', 'BNB Chain', 2.1, 598.30, 'BSC'),
  ];

  final List<_TxHistory> _history = [
    _TxHistory('Empfangen', 'QEMMA', 47.5, '0x8fA2...3d1C', true, DateTime.now().subtract(const Duration(hours: 2))),
    _TxHistory('Gesendet', 'BTC', 0.05, '0x4bC1...9aF3', false, DateTime.now().subtract(const Duration(hours: 5))),
    _TxHistory('Mining', 'QEMMA', 25.0, 'Proof-of-Intelligence', true, DateTime.now().subtract(const Duration(days: 1))),
    _TxHistory('Empfangen', 'ETH', 0.5, '0x2dE4...7bA8', true, DateTime.now().subtract(const Duration(days: 1, hours: 3))),
    _TxHistory('Gesendet', 'USDT', 200.0, '0x6fC9...1eD2', false, DateTime.now().subtract(const Duration(days: 2))),
    _TxHistory('Swap', 'SOL→QEMMA', 5.0, 'Raydium DEX', true, DateTime.now().subtract(const Duration(days: 3))),
    _TxHistory('Empfangen', 'BTC', 0.1, '0x9aB3...5cE7', true, DateTime.now().subtract(const Duration(days: 4))),
    _TxHistory('Mining', 'QEMMA', 30.0, 'Agenten-Quest', true, DateTime.now().subtract(const Duration(days: 5))),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _addressCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.surface,
        title: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: p.primary.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.3), blurRadius: 8)],
            ),
            child: ClipOval(
              child: Image.asset('assets/icons/app_icon.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 8),
          Text('QUANTUM WALLET',
              style: GoogleFonts.rajdhani(
                  color: p.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
        ]),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: p.textSecondary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: p.positive
                    .withValues(alpha: 0.08 + _pulseCtrl.value * 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: p.positive.withValues(alpha: 0.3 + _pulseCtrl.value * 0.2)),
              ),
              child: Row(children: [
                Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.positive,
                        boxShadow: [BoxShadow(color: p.positive.withValues(alpha: 0.8), blurRadius: 6)])),
                const SizedBox(width: 5),
                Text('SICHER',
                    style: GoogleFonts.rajdhani(
                        color: p.positive, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Balance Header
          _buildBalanceHeader(p, tp),
          // Tab Bar
          _buildTabBar(p),
          // Content
          Expanded(child: _buildContent(p)),
        ],
      ),
    );
  }

  // ── Balance Header ────────────────────────────
  // ── Balance Header mit Live-Preisen ───────────
  Widget _buildBalanceHeader(dynamic p, ThemeProvider tp) {
    final ex = context.watch<ExchangeService>();
    double total = 0;
    for (final a in _assets) {
      final lp = ex.getPrice(a.symbol);
      total += a.balance * (lp > 0 ? lp : a.price);
    }
    final totalEur = total * 0.923;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.primary.withValues(alpha: 0.08), p.surface],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: p.primary.withValues(alpha: 0.12))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            QuantumEyeWidget(palette: p, size: 42, animate: tp.quantumAnimations),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('HQMLL WALLET', style: GoogleFonts.spaceMono(
                  color: p.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              Text('Grigori Saks · Quantum Portfolio', style: GoogleFonts.exo(
                  color: p.textSecondary, fontSize: 9)),
            ]),
            const Spacer(),
            AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) => Row(children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(
                shape: BoxShape.circle, color: p.positive,
                boxShadow: [BoxShadow(color: p.positive.withValues(alpha: _pulseCtrl.value * 0.8), blurRadius: 8)],
              )),
              const SizedBox(width: 5),
              Text('LIVE', style: GoogleFonts.spaceMono(color: p.positive, fontSize: 8, fontWeight: FontWeight.bold)),
            ])),
          ]),
          const SizedBox(height: 14),
          Text('Gesamtvermögen', style: GoogleFonts.spaceMono(
              color: p.textSecondary, fontSize: 9, letterSpacing: 1)),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('\$${_fmtBig(total + _pulseCtrl.value * 8)}', style: GoogleFonts.rajdhani(
                  color: p.textPrimary, fontSize: 28, fontWeight: FontWeight.bold, height: 1)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('€${_fmtBig(totalEur)}', style: GoogleFonts.rajdhani(
                    color: p.textSecondary, fontSize: 15)),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: p.positive.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text('+\$${(total * 0.0234).toStringAsFixed(0)} (2.34%) heute',
                  style: TextStyle(color: p.positive, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
            _WalletActionBtn(icon: Icons.send_outlined, label: 'Senden', color: p.primary,
                onTap: () => setState(() => _tabIndex = 1)),
            const SizedBox(width: 6),
            _WalletActionBtn(icon: Icons.call_received_outlined, label: 'Empfangen', color: p.secondary,
                onTap: () => setState(() => _tabIndex = 2)),
            const SizedBox(width: 6),
            _WalletActionBtn(icon: Icons.swap_horiz, label: 'Swap', color: p.accent,
                onTap: () {}),
          ]),
        ],
      ),
    );
  }

  String _fmtBig(double v) {
    if (v >= 1e6) return '${(v/1e6).toStringAsFixed(2)}M';
    if (v >= 1000) {
      return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    }
    return v.toStringAsFixed(2);
  }


  // ── Tab Bar ────────────────────────────────────
  Widget _buildTabBar(dynamic p) {
    final tabs = ['Guthaben', 'Senden', 'Empfangen', 'Verlauf'];
    return Container(
      height: 42,
      color: p.surface,
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final selected = _tabIndex == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _tabIndex = e.key;
                _sendConfirmed = false;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? p.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(e.value,
                      style: GoogleFonts.rajdhani(
                        color: selected ? p.primary : p.textSecondary,
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        letterSpacing: 0.5,
                      )),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Content Router ─────────────────────────────
  Widget _buildContent(dynamic p) {
    switch (_tabIndex) {
      case 0: return _buildBalanceTab(p);
      case 1: return _buildSendTab(p);
      case 2: return _buildReceiveTab(p);
      case 3: return _buildHistoryTab(p);
      default: return _buildBalanceTab(p);
    }
  }

  // ── Balance Tab ────────────────────────────────
  Widget _buildBalanceTab(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Asset grid header
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Icon(Icons.account_balance_wallet, color: p.primary, size: 14),
            const SizedBox(width: 6),
            Text('Meine Assets', style: GoogleFonts.rajdhani(
                color: p.primary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const Spacer(),
            Text('${_assets.length} Tokens', style: TextStyle(color: p.textSecondary, fontSize: 11)),
          ]),
        ),
        ..._assets.map((a) => _buildAssetCard(p, a)),
        const SizedBox(height: 16),
        // Quick Actions
        Text('Schnell-Aktionen', style: GoogleFonts.rajdhani(
            color: p.primary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _ActionCard(icon: Icons.swap_horiz, label: 'Swap', sublabel: 'Token tauschen', color: p.primary, p: p, onTap: () => _showSwapDialog(context, p))),
          const SizedBox(width: 8),
          Expanded(child: _ActionCard(icon: Icons.currency_exchange, label: 'Bridge', sublabel: 'Cross-Chain', color: p.secondary, p: p, onTap: () => _showBridgeDialog(context, p))),
          const SizedBox(width: 8),
          Expanded(child: _ActionCard(icon: Icons.savings_outlined, label: 'Staking', sublabel: 'Yield farming', color: p.accent, p: p, onTap: () => _showStakingDialog(context, p))),
        ]),
        const SizedBox(height: 12),
        // Network info
        _buildNetworkCard(p),
      ],
    );
  }

  Widget _buildAssetCard(dynamic p, _WalletAsset a) {
    final isSelected = _selectedAsset == a.symbol;
    final ex = context.watch<ExchangeService>();
    final rawLive = ex.getPrice(a.symbol);
    final livePrice = rawLive > 0 ? rawLive : a.price;
    final isLive = rawLive > 0 && (ex.getTick(a.symbol)?.isLive ?? false);
    final liveValue = a.balance * livePrice;

    return GestureDetector(
      onTap: () => setState(() => _selectedAsset = a.symbol),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? p.primary.withValues(alpha: 0.08) : p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? p.primary.withValues(alpha: 0.5) : p.primary.withValues(alpha: 0.12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Token Icon – Original CoinGecko
            AssetIconWidget(symbol: a.symbol, palette: p, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(a.symbol, style: GoogleFonts.rajdhani(
                        color: p.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: p.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(a.network, style: TextStyle(color: p.textSecondary, fontSize: 9)),
                    ),
                  ]),
                  Text(a.name, style: TextStyle(color: p.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(children: [
                  Text('\$${liveValue.toStringAsFixed(2)}',
                      style: GoogleFonts.rajdhani(
                          color: p.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                  if (isLive) ...[
                    const SizedBox(width: 4),
                    Container(width: 5, height: 5,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        color: const Color(0xFF00FF88),
                        boxShadow: [BoxShadow(color: const Color(0xFF00FF88).withValues(alpha: 0.6), blurRadius: 4)])),
                  ],
                ]),
                Text('${a.amount.toStringAsFixed(a.symbol == 'USDT' ? 0 : 4)} ${a.symbol}'
                    '  @\$${livePrice >= 1 ? livePrice.toStringAsFixed(0) : livePrice.toStringAsFixed(4)}',
                    style: TextStyle(color: p.textSecondary, fontSize: 10)),
              ],
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAsset = a.symbol;
                  _tabIndex = 1;
                });
              },
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.send, color: p.primary, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkCard(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Netzwerk-Status', style: GoogleFonts.rajdhani(
              color: p.primary, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...[
            ('Solana', 'Online', p.positive, '~0.5s Bestätigung'),
            ('Ethereum', 'Online', p.positive, '~15s Bestätigung'),
            ('BSC', 'Online', p.positive, '~3s Bestätigung'),
            ('Bitcoin', 'Online', p.positive, '~10min Bestätigung'),
          ].map((n) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: n.$3,
                  boxShadow: [BoxShadow(color: n.$3.withValues(alpha: 0.7), blurRadius: 5)])),
              const SizedBox(width: 8),
              Expanded(child: Text(n.$1, style: TextStyle(color: p.textPrimary, fontSize: 12))),
              Text(n.$2, style: TextStyle(color: n.$3, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(n.$4, style: TextStyle(color: p.textSecondary, fontSize: 10)),
            ]),
          )),
        ],
      ),
    );
  }

  // ── Send Tab ───────────────────────────────────
  Widget _buildSendTab(dynamic p) {
    if (_sendConfirmed) return _buildSendSuccess(p);

    final selectedAssetObj = _assets.firstWhere((a) => a.symbol == _selectedAsset,
        orElse: () => _assets.first);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emma Security Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.primary.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: p.primary.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.3), blurRadius: 6)],
                ),
                child: ClipOval(
                  child: Image.asset('assets/icons/app_icon.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('Emma: Alle Transaktionen werden von HQMLL-Security überwacht. Zero-Trust aktiv.',
                  style: GoogleFonts.exo(color: p.textPrimary, fontSize: 11, height: 1.4))),
            ]),
          ),
          const SizedBox(height: 20),

          // Asset Auswahl
          Text('Asset auswählen', style: TextStyle(color: p.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: p.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.primary.withValues(alpha: 0.25)),
            ),
            child: DropdownButton<String>(
              value: _selectedAsset,
              isExpanded: true,
              dropdownColor: p.surfaceVariant,
              underline: const SizedBox(),
              icon: Icon(Icons.keyboard_arrow_down, color: p.primary),
              style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 15),
              items: _assets.map((a) => DropdownMenuItem(
                value: a.symbol,
                child: Row(children: [
                  AssetIconWidget(symbol: a.symbol, palette: p, size: 24, showBorder: false),
                  const SizedBox(width: 8),
                  Text('${a.symbol}  ·  ${a.amount.toStringAsFixed(4)}'),
                ]),
              )).toList(),
              onChanged: (v) => setState(() => _selectedAsset = v!),
            ),
          ),
          const SizedBox(height: 16),

          // Empfänger-Adresse
          Text('Empfänger-Adresse', style: TextStyle(color: p.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: _addressCtrl,
            style: GoogleFonts.robotoMono(color: p.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: '0x... oder Solana-Adresse eingeben',
              hintStyle: TextStyle(color: p.textSecondary, fontSize: 12),
              filled: true, fillColor: p.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.primary, width: 1.5)),
              suffixIcon: IconButton(
                icon: Icon(Icons.qr_code_scanner, color: p.primary, size: 20),
                onPressed: () => _showQRScanner(context, p),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Quick address buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _AddressChip('0x8fA2...3d1C', p, () => _addressCtrl.text = '0x8fA2d3b97C4e1a5f6B8dE29fA3d1C'),
              _AddressChip('0x4bC1...9aF3', p, () => _addressCtrl.text = '0x4bC1a2d3E4f5B6c7D8e9F0aB19aF3'),
              _AddressChip('Raydium DEX', p, () => _addressCtrl.text = 'raydium_dex_pool_qemma_sol'),
            ]),
          ),
          const SizedBox(height: 16),

          // Betrag
          Text('Betrag', style: TextStyle(color: p.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 18),
                  filled: true, fillColor: p.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.primary, width: 1.5)),
                  suffix: Text(_selectedAsset, style: TextStyle(color: p.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => setState(() => _amountCtrl.text = selectedAssetObj.amount.toStringAsFixed(4)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: p.primary.withValues(alpha: 0.4))),
                child: Text('MAX', style: GoogleFonts.rajdhani(color: p.primary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text('Verfügbar: ${selectedAssetObj.amount.toStringAsFixed(4)} ${selectedAssetObj.symbol}  ≈  \$${selectedAssetObj.value.toStringAsFixed(2)}',
              style: TextStyle(color: p.textSecondary, fontSize: 11)),
          const SizedBox(height: 16),

          // Fee Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              _FeeRow('Netzwerk-Gebühr', '~0.00025 SOL (\$0.05)', p),
              _FeeRow('HQMLL-Schutzgebühr', '0.00 (Eigentümer-Modus)', p),
              Divider(color: p.primary.withValues(alpha: 0.1)),
              _FeeRow('Gesamt zu senden', '${_amountCtrl.text.isEmpty ? "0.00" : _amountCtrl.text} $_selectedAsset', p, highlight: true),
            ]),
          ),
          const SizedBox(height: 20),

          // Send Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text('TRANSAKTION SENDEN',
                  style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: p.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _confirmSend(context, p),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Gesichert durch HQMLL Zero-Trust Security',
                style: TextStyle(color: p.textSecondary, fontSize: 10)),
          ),
          const SizedBox(height: 24),

          // ─ FIAT Transfer Section ─
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                const Color(0xFF003399).withValues(alpha: 0.15),
                const Color(0xFF006400).withValues(alpha: 0.10),
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF85BB65).withValues(alpha: 0.35)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.currency_exchange, color: Color(0xFF85BB65), size: 16),
                const SizedBox(width: 6),
                Text('FIAT TRANSFER', style: GoogleFonts.rajdhani(
                  color: const Color(0xFF85BB65), fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF85BB65).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('SEPA · SWIFT', style: GoogleFonts.rajdhani(color: const Color(0xFF85BB65), fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 12),
              // EUR/USD amounts row
              Row(children: [
                Expanded(child: _fiatInputBox('EUR', '€', '500,00', p, const Color(0xFF003399))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(children: [
                    const Icon(Icons.swap_horiz, color: Color(0xFF85BB65), size: 20),
                    Text('1:1.083', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9)),
                  ]),
                ),
                Expanded(child: _fiatInputBox('USD', '\$', '541,50', p, const Color(0xFF006400))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _fiatMethodBtn('SEPA Überweisung', Icons.account_balance, const Color(0xFF003399), p)),
                const SizedBox(width: 8),
                Expanded(child: _fiatMethodBtn('SWIFT Transfer', Icons.send_to_mobile, const Color(0xFF85BB65), p)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.info_outline, color: p.textSecondary, size: 12),
                const SizedBox(width: 6),
                Expanded(child: Text(
                  'SEPA: kostenlos, 1-2 Werktage · SWIFT: ab 2€, 1-3 Banktage',
                  style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10),
                )),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _fiatInputBox(String currency, String sym, String placeholder, dynamic p, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(currency, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 9, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text('$sym $placeholder', style: GoogleFonts.rajdhani(color: p.text, fontSize: 16, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _fiatMethodBtn(String label, IconData icon, Color color, dynamic p) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: color.withValues(alpha: 0.9),
          content: Text('$label wird vorbereitet...', style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.w700)),
          duration: const Duration(seconds: 2),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.rajdhani(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _buildSendSuccess(dynamic p) {
    final txHash = '0x${_rnd.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}${_rnd.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}...';
    final steps = [
      ('Transaktion signiert', true),
      ('An Netzwerk gesendet', true),
      ('Vom Node akzeptiert', true),
      ('Bestätigung ausstehend', false),
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Erfolgs-Kreis mit App Icon + Glow
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.positive.withValues(alpha: 0.1),
                border: Border.all(color: p.positive, width: 2.5),
                boxShadow: [
                  BoxShadow(color: p.positive.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 4),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset('assets/icons/app_icon.png', fit: BoxFit.cover, width: 100, height: 100),
                    Positioned(
                      bottom: 4, right: 4,
                      child: Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.positive,
                          border: Border.all(color: p.background, width: 2),
                        ),
                        child: Icon(Icons.check, color: p.background, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('TRANSAKTION GESENDET!',
                style: GoogleFonts.rajdhani(
                    color: p.positive, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 6),
            Text('Emma bestätigt: Transaktion erfolgreich übermittelt.',
                style: TextStyle(color: p.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            // TX-Hash
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.primary.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Icon(Icons.tag, color: p.primary, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(txHash,
                    style: GoogleFonts.robotoMono(color: p.primary, fontSize: 11))),
                GestureDetector(
                  onTap: () => Clipboard.setData(ClipboardData(text: txHash)),
                  child: Icon(Icons.copy, color: p.textSecondary, size: 16),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            // Bestätigungs-Schritte
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.primary.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: steps.asMap().entries.map((e) {
                  final done = e.value.$2;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? p.positive.withValues(alpha: 0.15) : p.surfaceVariant,
                          border: Border.all(color: done ? p.positive : p.textSecondary),
                        ),
                        child: Icon(
                          done ? Icons.check : Icons.hourglass_empty,
                          color: done ? p.positive : p.textSecondary,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(e.value.$1,
                          style: TextStyle(
                              color: done ? p.textPrimary : p.textSecondary,
                              fontSize: 12,
                              fontWeight: done ? FontWeight.w600 : FontWeight.normal)),
                    ]),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            // Emma Sicherheits-Badge
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.verified_user, color: p.positive, size: 14),
              const SizedBox(width: 6),
              Text('HQMLL Zero-Trust Security · Verifiziert',
                  style: TextStyle(color: p.positive, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _sendConfirmed = false;
                _amountCtrl.clear();
                _addressCtrl.clear();
              }),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: Text('Neue Transaktion',
                  style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: p.primary,
                  foregroundColor: p.background,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }

  // ── Receive Tab ────────────────────────────────
  Widget _buildReceiveTab(dynamic p) {
    const ethAddress = '0x7Gf2QmL9kXs3aBvNpR4cYhW8dFtJ5eZ';
    const solAddress = 'HQMLLqEmma85SaksGrigor1QkJ7mXzR9vBpLt3nW';
    const btcAddress = '1HQMLL9Grigori1985SaksQuantumEm2XqZkJ';

    final networks = [
      const _NetworkAddress('Ethereum', 'ERC-20 · ETH / USDT / ERC20 Tokens', ethAddress, Icons.account_balance_wallet, Color(0xFF627EEA)),
      const _NetworkAddress('Solana', 'SPL · QEMMA / SOL / SPL Tokens', solAddress, Icons.token, Color(0xFF9945FF)),
      const _NetworkAddress('Bitcoin', 'BTC · Native SegWit', btcAddress, Icons.currency_bitcoin, Color(0xFFF7931A)),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.call_received, color: p.primary, size: 18),
            const SizedBox(width: 8),
            Text('EMPFANGEN', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
          ]),
          const SizedBox(height: 4),
          Text('Senden Sie Assets an diese Wallet-Adressen', style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 12)),
          const SizedBox(height: 24),

          // Asset Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: ['QEMMA', 'BTC', 'ETH', 'SOL', 'USDT'].map((sym) {
                final sel = _selectedAsset == sym;
                return Expanded(
                  child: GestureDetector(
                    onTap: () { setState(() => _selectedAsset = sym); HapticFeedback.selectionClick(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                      decoration: BoxDecoration(
                        color: sel ? AssetIconWidget.symbolColor(sym).withValues(alpha: 0.18) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: sel ? Border.all(color: AssetIconWidget.symbolColor(sym).withValues(alpha: 0.5), width: 1) : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AssetIconWidget(symbol: sym, palette: p, size: 22, showBorder: false, showGlow: sel),
                          const SizedBox(height: 2),
                          Text(sym, style: GoogleFonts.rajdhani(
                            color: sel ? AssetIconWidget.symbolColor(sym) : p.textSecondary,
                            fontSize: 8, fontWeight: FontWeight.w700,
                          )),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // QR Code (echtes QR-Widget)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: p.primary.withValues(alpha: 0.25), blurRadius: 24, spreadRadius: 2),
                BoxShadow(color: AssetIconWidget.symbolColor(_selectedAsset).withValues(alpha: 0.2), blurRadius: 16),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                QrImageView(
                  data: _receiveAddress(_selectedAsset, ethAddress, solAddress, btcAddress),
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
                // Center Logo
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                  ),
                  child: ClipOval(child: AssetIconWidget(symbol: _selectedAsset, palette: p, size: 36, showBorder: false)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Selected Address
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AssetIconWidget.symbolColor(_selectedAsset).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  AssetIconWidget(symbol: _selectedAsset, palette: p, size: 24, showBorder: false),
                  const SizedBox(width: 8),
                  Text('$_selectedAsset Adresse', style: GoogleFonts.rajdhani(color: p.text, fontSize: 13, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      final addr = _receiveAddress(_selectedAsset, ethAddress, solAddress, btcAddress);
                      _copyAddress(context, addr, p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(Icons.copy, color: p.primary, size: 12),
                        const SizedBox(width: 4),
                        Text('KOPIEREN', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(
                  _receiveAddress(_selectedAsset, ethAddress, solAddress, btcAddress),
                  style: GoogleFonts.robotoMono(color: p.textSecondary, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Network Cards
          ...networks.map((n) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildNetworkAddressCard(n, p),
          )),
          const SizedBox(height: 12),

          // Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFAA00).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFAA00).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber, color: Color(0xFFFFAA00), size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Nur kompatible Assets an jeweilige Adresse senden. Falsche Netzwerke führen zu unwiderruflichem Verlust!',
                style: GoogleFonts.rajdhani(color: const Color(0xFFFFAA00), fontSize: 11, height: 1.4),
              )),
            ]),
          ),
        ],
      ),
    );
  }

  String _receiveAddress(String sym, String eth, String sol, String btc) {
    if (sym == 'BTC') return btc;
    if (sym == 'QEMMA' || sym == 'SOL') return sol;
    return eth;
  }

  Widget _buildNetworkAddressCard(_NetworkAddress n, dynamic p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: n.color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: n.color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(n.icon, color: n.color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(n.network, style: GoogleFonts.rajdhani(color: p.text, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(n.type, style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 10)),
          Text(
            '${n.address.substring(0, 12)}...${n.address.substring(n.address.length - 6)}',
            style: GoogleFonts.robotoMono(color: p.textSecondary, fontSize: 10),
          ),
        ])),
        GestureDetector(
          onTap: () => _copyAddress(context, n.address, p),
          child: Icon(Icons.copy_outlined, color: p.primary, size: 18),
        ),
      ]),
    );
  }

  // ── History Tab ────────────────────────────────
  Widget _buildHistoryTab(dynamic p) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _history.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(Icons.history, color: p.primary, size: 14),
              const SizedBox(width: 6),
              Text('Transaktionsverlauf', style: GoogleFonts.rajdhani(
                  color: p.primary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const Spacer(),
              Text('${_history.length} Einträge', style: TextStyle(color: p.textSecondary, fontSize: 11)),
            ]),
          );
        }
        final tx = _history[i - 1];
        return _buildTxCard(p, tx);
      },
    );
  }

  Widget _buildTxCard(dynamic p, _TxHistory tx) {
    final isSend = tx.type == 'Gesendet';
    final color = isSend ? p.negative : p.positive;
    final icon = tx.type == 'Mining' ? Icons.auto_awesome
        : tx.type == 'Swap' ? Icons.swap_horiz
        : isSend ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.type, style: TextStyle(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(tx.address, style: GoogleFonts.robotoMono(color: p.textSecondary, fontSize: 10)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${isSend ? '-' : '+'}${tx.amount.toStringAsFixed(tx.asset.contains('QEMMA') ? 1 : 4)} ${tx.asset}',
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
            Text(_formatDate(tx.date), style: TextStyle(color: p.textSecondary, fontSize: 10)),
          ]),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────
  void _confirmSend(BuildContext context, dynamic p) {
    if (_addressCtrl.text.isEmpty || _amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: p.negative,
          content: const Text('Bitte Adresse und Betrag eingeben', style: TextStyle(color: Colors.white))));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.primary.withValues(alpha: 0.4))),
        title: Row(children: [Icon(Icons.send_rounded, color: p.primary, size: 20), const SizedBox(width: 8),
          Text('Transaktion bestätigen', style: TextStyle(color: p.textPrimary, fontSize: 16))]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ConfirmRow('Asset', _selectedAsset, p),
          _ConfirmRow('Betrag', '${_amountCtrl.text} $_selectedAsset', p),
          _ConfirmRow('An', '${_addressCtrl.text.substring(0, min(20, _addressCtrl.text.length))}...', p),
          _ConfirmRow('Netzwerkgebühr', '~\$0.05', p),
          Divider(color: p.primary.withValues(alpha: 0.15)),
          Row(children: [Icon(Icons.security, color: p.positive, size: 14), const SizedBox(width: 6),
            Text('HQMLL Security: Verifiziert', style: TextStyle(color: p.positive, fontSize: 11))]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Abbrechen', style: TextStyle(color: p.textSecondary))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); setState(() => _sendConfirmed = true); },
            style: ElevatedButton.styleFrom(backgroundColor: p.primary, foregroundColor: p.background),
            child: Text('Bestätigen', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSwapDialog(BuildContext context, dynamic p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Token Swap', style: TextStyle(color: p.textPrimary)),
        content: Text('Swap über Raydium DEX (Solana) oder Uniswap (Ethereum).\n\nEmma empfiehlt: SOL → QEMMA für optimale Mining-Rate.\n\nFunktion in nächster Version voll verfügbar.', style: TextStyle(color: p.textSecondary, fontSize: 13)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: p.primary)))],
      ),
    );
  }

  void _showStakingDialog(BuildContext context, dynamic p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('\$QEMMA Staking', style: TextStyle(color: p.textPrimary)),
        content: Text('QEMMA Staking aktiviert Emma-Boosts:\n\n• 100 QEMMA: +10% Signal-Konfidenz\n• 500 QEMMA: +25% Mining-Rate\n• 1000 QEMMA: Emma Pro-Modus\n\n"Quantum Yield" APY: 12.5% (HQMLL-optimiert)', style: TextStyle(color: p.textSecondary, fontSize: 13, height: 1.5)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Schließen', style: TextStyle(color: p.primary)))],
      ),
    );
  }

  void _showQRScanner(BuildContext context, dynamic p) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: p.surface,
        content: Text('QR-Scanner: In der Android-App verfügbar', style: TextStyle(color: p.textPrimary)),
        duration: const Duration(seconds: 2)));
  }

  void _showBridgeDialog(BuildContext context, dynamic p) {
    // Vollständiger Cross-Chain Bridge Dialog
    String fromChain = 'Ethereum';
    String toChain = 'Solana';
    String selectedToken = 'USDT';
    final amtCtrl = TextEditingController();
    bool bridging = false;
    bool bridgeDone = false;

    final chains = ['Ethereum', 'Solana', 'BNB Chain', 'Polygon', 'Arbitrum', 'Optimism'];
    final tokens = ['USDT', 'USDC', 'ETH', 'BNB', 'MATIC'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: p.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: p.secondary.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 4),
                decoration: BoxDecoration(
                  color: p.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: p.secondary.withValues(alpha: 0.06),
                  border: Border(bottom: BorderSide(color: p.secondary.withValues(alpha: 0.2))),
                ),
                child: Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.secondary.withValues(alpha: 0.15),
                      border: Border.all(color: p.secondary.withValues(alpha: 0.4)),
                    ),
                    child: Icon(Icons.currency_exchange, color: p.secondary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('CROSS-CHAIN BRIDGE', style: GoogleFonts.rajdhani(
                          color: p.secondary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      Text('Powered by HQMLL Quantum Bridge', style: GoogleFonts.spaceMono(
                          color: p.textSecondary, fontSize: 9)),
                    ]),
                  ),
                  IconButton(icon: Icon(Icons.close, color: p.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(ctx)),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: bridgeDone
                      ? _buildBridgeSuccess(p, fromChain, toChain, amtCtrl.text, selectedToken)
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // Emma Security Info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: p.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: p.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(children: [
                              Container(
                                width: 28, height: 28,
                                decoration: const BoxDecoration(shape: BoxShape.circle),
                                child: ClipOval(
                                  child: Image.asset('assets/icons/app_icon.png', fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(
                                'Emma: Bridge-Transaktionen werden durch HQMLL Zero-Trust-Bridge-Protokoll v2 gesichert. Atomic Swaps aktiv.',
                                style: GoogleFonts.exo(color: p.textPrimary, fontSize: 11, height: 1.4),
                              )),
                            ]),
                          ),
                          const SizedBox(height: 20),
                          // From Chain
                          Text('Von Blockchain', style: TextStyle(color: p.textSecondary, fontSize: 12)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: p.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: p.secondary.withValues(alpha: 0.25)),
                            ),
                            child: DropdownButton<String>(
                              value: fromChain,
                              isExpanded: true,
                              dropdownColor: p.surfaceVariant,
                              underline: const SizedBox(),
                              icon: Icon(Icons.keyboard_arrow_down, color: p.secondary),
                              style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 15),
                              items: chains.map((c) => DropdownMenuItem(value: c, child: Row(children: [
                                Icon(_chainIcon(c), color: p.secondary, size: 18),
                                const SizedBox(width: 8),
                                Text(c),
                              ]))).toList(),
                              onChanged: (v) => setSt(() => fromChain = v!),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Swap Arrow
                          Center(
                            child: GestureDetector(
                              onTap: () => setSt(() {
                                final tmp = fromChain;
                                fromChain = toChain;
                                toChain = tmp;
                              }),
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: p.secondary.withValues(alpha: 0.1),
                                  border: Border.all(color: p.secondary.withValues(alpha: 0.4)),
                                ),
                                child: Icon(Icons.swap_vert, color: p.secondary, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // To Chain
                          Text('Zu Blockchain', style: TextStyle(color: p.textSecondary, fontSize: 12)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: p.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: p.secondary.withValues(alpha: 0.25)),
                            ),
                            child: DropdownButton<String>(
                              value: toChain,
                              isExpanded: true,
                              dropdownColor: p.surfaceVariant,
                              underline: const SizedBox(),
                              icon: Icon(Icons.keyboard_arrow_down, color: p.secondary),
                              style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 15),
                              items: chains.map((c) => DropdownMenuItem(value: c, child: Row(children: [
                                Icon(_chainIcon(c), color: p.secondary, size: 18),
                                const SizedBox(width: 8),
                                Text(c),
                              ]))).toList(),
                              onChanged: (v) => setSt(() => toChain = v!),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Token Auswahl
                          Text('Token', style: TextStyle(color: p.textSecondary, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            children: tokens.map((t) => GestureDetector(
                              onTap: () => setSt(() => selectedToken = t),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selectedToken == t
                                      ? p.secondary.withValues(alpha: 0.15) : p.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selectedToken == t
                                        ? p.secondary : p.primary.withValues(alpha: 0.15),
                                    width: selectedToken == t ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(t, style: GoogleFonts.rajdhani(
                                    color: selectedToken == t ? p.secondary : p.textSecondary,
                                    fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 20),
                          // Betrag
                          Text('Betrag', style: TextStyle(color: p.textSecondary, fontSize: 12)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: amtCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.rajdhani(color: p.textPrimary, fontSize: 18),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(color: p.textSecondary),
                              filled: true, fillColor: p.surfaceVariant,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: p.secondary.withValues(alpha: 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: p.secondary.withValues(alpha: 0.25)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: p.secondary, width: 1.5),
                              ),
                              suffixText: selectedToken,
                              suffixStyle: TextStyle(color: p.secondary, fontWeight: FontWeight.bold),
                            ),
                            onChanged: (_) => setSt(() {}),
                          ),
                          const SizedBox(height: 16),
                          // Fee Info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: p.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: p.primary.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              children: [
                                _BridgeInfoRow('Bridge-Gebühr', '0.1%', p),
                                const SizedBox(height: 6),
                                _BridgeInfoRow('Netzwerkgebühr', '~\$2.40', p),
                                const SizedBox(height: 6),
                                _BridgeInfoRow('Geschätzte Zeit', '~4 Minuten', p),
                                const SizedBox(height: 6),
                                _BridgeInfoRow('Sicherheit', 'Atomic Swap ✓', p),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Bridge Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: p.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              onPressed: bridging ? null : () async {
                                if (amtCtrl.text.isEmpty || double.tryParse(amtCtrl.text) == null) return;
                                setSt(() => bridging = true);
                                HapticFeedback.mediumImpact();
                                await Future.delayed(const Duration(milliseconds: 2000));
                                setSt(() { bridging = false; bridgeDone = true; });
                              },
                              child: bridging
                                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      const SizedBox(width: 18, height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: Colors.white)),
                                      const SizedBox(width: 12),
                                      Text('Bridge läuft...', style: GoogleFonts.rajdhani(
                                          fontSize: 16, fontWeight: FontWeight.bold)),
                                    ])
                                  : Text('Jetzt bridgen: $fromChain → $toChain',
                                      style: GoogleFonts.rajdhani(
                                          fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(child: Text('Gesichert durch HQMLL Zero-Trust Bridge Protocol',
                              style: TextStyle(color: p.textSecondary, fontSize: 10))),
                        ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBridgeSuccess(dynamic p, String from, String to, String amt, String token) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.secondary.withValues(alpha: 0.1),
            border: Border.all(color: p.secondary, width: 2.5),
            boxShadow: [BoxShadow(color: p.secondary.withValues(alpha: 0.3), blurRadius: 24)],
          ),
          child: Icon(Icons.swap_horizontal_circle, color: p.secondary, size: 48),
        ),
        const SizedBox(height: 20),
        Text('BRIDGE ERFOLGREICH!', style: GoogleFonts.rajdhani(
            color: p.secondary, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text('$amt $token von $from nach $to übertragen',
            style: TextStyle(color: p.textSecondary, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.secondary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _BridgeInfoRow('Status', '✅ Bestätigt', p),
              const SizedBox(height: 8),
              _BridgeInfoRow('Atomic Swap', '✅ Abgeschlossen', p),
              const SizedBox(height: 8),
              _BridgeInfoRow('Angekommen auf', to, p),
            ],
          ),
        ),
      ],
    );
  }

  IconData _chainIcon(String chain) {
    switch (chain) {
      case 'Ethereum': return Icons.diamond_outlined;
      case 'Solana': return Icons.flash_on;
      case 'BNB Chain': return Icons.circle_outlined;
      case 'Polygon': return Icons.hexagon_outlined;
      default: return Icons.link;
    }
  }

  void _copyAddress(BuildContext context, String address, dynamic p) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: p.positive.withValues(alpha: 0.9),
        content: const Text('Adresse kopiert!', style: TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 2)));
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inHours < 24) return 'vor ${diff.inHours}h';
    return 'vor ${diff.inDays}T';
  }
}

// ── Wallet Action Button (Senden/Empfangen/Swap) ──────
class _WalletActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _WalletActionBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────
// ignore: unused_element
class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final Color color;
  final dynamic p;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.sublabel, required this.color, required this.p, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(sublabel, style: TextStyle(color: p.textSecondary, fontSize: 9)),
        ]),
      ),
    );
  }
}

class _AddressChip extends StatelessWidget {
  final String label;
  final dynamic p;
  final VoidCallback onTap;
  const _AddressChip(this.label, this.p, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: p.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: p.primary.withValues(alpha: 0.25)),
        ),
        child: Text(label, style: GoogleFonts.robotoMono(color: p.primary, fontSize: 10)),
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label, value;
  final dynamic p;
  final bool highlight;
  const _FeeRow(this.label, this.value, this.p, {this.highlight = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: p.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: highlight ? p.primary : p.textPrimary, fontSize: 12, fontWeight: highlight ? FontWeight.bold : FontWeight.normal)),
      ]),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label, value;
  final dynamic p;
  const _ConfirmRow(this.label, this.value, this.p);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: p.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: p.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ignore: unused_element
class _AddressCard extends StatelessWidget {
  final String network, address;
  final IconData icon;
  final dynamic p;
  final VoidCallback onCopy;
  const _AddressCard(this.network, this.address, this.icon, this.p, {required this.onCopy});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: p.primary, size: 14),
          const SizedBox(width: 6),
          Text(network, style: TextStyle(color: p.primary, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text(address, style: GoogleFonts.robotoMono(color: p.textPrimary, fontSize: 11))),
          IconButton(
            icon: Icon(Icons.copy_outlined, color: p.textSecondary, size: 18),
            onPressed: onCopy,
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
        ]),
      ]),
    );
  }
}

// ── Data Classes ───────────────────────────────────
class _WalletAsset {
  final String symbol, name, network;
  final double balance, price;
  // Legacy compat
  double get amount => balance;
  _WalletAsset(this.symbol, this.name, this.balance, this.price, this.network);
  double get value => balance * price;
}

class _TxHistory {
  final String type, asset, address;
  final double amount;
  final bool isIn;
  final DateTime date;
  _TxHistory(this.type, this.asset, this.amount, this.address, this.isIn, this.date);
}

// QR Code Painter (simplified visual)
// ignore: unused_element
class _QRPainter extends CustomPainter {
  final dynamic p;
  _QRPainter(this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(42);
    final cellSize = size.width / 21;
    final paint = Paint()..color = Colors.black87;

    // Draw QR-like pattern
    for (int row = 0; row < 21; row++) {
      for (int col = 0; col < 21; col++) {
        // Corner markers
        final isCorner = (row < 7 && col < 7) || (row < 7 && col > 13) || (row > 13 && col < 7);
        final isInnerCorner = (row >= 2 && row <= 4 && col >= 2 && col <= 4) ||
            (row >= 2 && row <= 4 && col >= 16 && col <= 18) ||
            (row >= 16 && row <= 18 && col >= 2 && col <= 4);
        final isBorderCorner = (row == 0 || row == 6) && col <= 6 ||
            (col == 0 || col == 6) && row <= 6 ||
            (row == 0 || row == 6) && col >= 14 ||
            (col == 14 || col == 20) && row <= 6 ||
            (row == 14 || row == 20) && col <= 6 ||
            (col == 0 || col == 6) && row >= 14;

        bool fill = false;
        if (isInnerCorner || isBorderCorner) {
          fill = true;
        } else if (!isCorner) {
          fill = rnd.nextBool();
        }

        if (fill) {
          canvas.drawRect(
            Rect.fromLTWH(col * cellSize + 2, row * cellSize + 2, cellSize - 1, cellSize - 1),
            paint,
          );
        }
      }
    }

    // Center quantum eye hint
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 10,
        Paint()..color = p.primary.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_QRPainter old) => false;
}

// ── Bridge Info Row ────────────────────────────────
class _BridgeInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final dynamic palette;
  const _BridgeInfoRow(this.label, this.value, this.palette);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.spaceMono(color: palette.textSecondary, fontSize: 10)),
        Text(value, style: GoogleFonts.rajdhani(
            color: palette.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Network Address Data ───────────────────────────
class _NetworkAddress {
  final String network, type, address;
  final IconData icon;
  final Color color;
  const _NetworkAddress(this.network, this.type, this.address, this.icon, this.color);
}
