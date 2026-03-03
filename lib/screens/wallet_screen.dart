import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../widgets/quantum_eye_widget.dart';

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
          Icon(Icons.account_balance_wallet_outlined, color: p.primary, size: 18),
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
  Widget _buildBalanceHeader(dynamic p, ThemeProvider tp) {
    final total = _assets.fold<double>(0, (s, a) => s + a.value);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.surface, p.surfaceVariant],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: p.primary.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          QuantumEyeWidget(palette: p, size: 52, animate: tp.quantumAnimations),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gesamtvermögen',
                    style: GoogleFonts.exo(color: p.textSecondary, fontSize: 11, letterSpacing: 1)),
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Text(
                    '\$${(total + _pulseCtrl.value * 12).toStringAsFixed(2)}',
                    style: GoogleFonts.rajdhani(
                        color: p.textPrimary, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: p.positive.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('+\$108.44 (1.94%)',
                        style: TextStyle(color: p.positive, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text('24h', style: TextStyle(color: p.textSecondary, fontSize: 10)),
                ]),
              ],
            ),
          ),
          Column(
            children: [
              _QuickBtn(icon: Icons.send_outlined, label: 'Senden', color: p.primary, onTap: () => setState(() => _tabIndex = 1)),
              const SizedBox(height: 6),
              _QuickBtn(icon: Icons.call_received_outlined, label: 'Empfangen', color: p.secondary, onTap: () => setState(() => _tabIndex = 2)),
            ],
          ),
        ],
      ),
    );
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
          Expanded(child: _ActionCard(icon: Icons.currency_exchange, label: 'Bridge', sublabel: 'Cross-Chain', color: p.secondary, p: p, onTap: () => _showComingSoon(context, p))),
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
            // Token Icon
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [p.primary.withValues(alpha: 0.25), p.secondary.withValues(alpha: 0.15)],
                ),
                border: Border.all(color: p.primary.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(a.symbol.length > 3 ? a.symbol.substring(0, 1) : a.symbol[0],
                    style: GoogleFonts.rajdhani(
                        color: p.primary, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
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
                Text('\$${a.value.toStringAsFixed(2)}',
                    style: GoogleFonts.rajdhani(
                        color: p.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                Text('${a.amount.toStringAsFixed(a.symbol == 'USDT' ? 0 : 4)} ${a.symbol}',
                    style: TextStyle(color: p.textSecondary, fontSize: 11)),
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
              Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [p.primary, p.secondary])),
                  child: Icon(Icons.remove_red_eye, color: p.background, size: 16)),
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
                  Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: p.primary.withValues(alpha: 0.15)),
                      child: Center(child: Text(a.symbol[0], style: TextStyle(color: p.primary, fontSize: 11, fontWeight: FontWeight.bold)))),
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
        ],
      ),
    );
  }

  Widget _buildSendSuccess(dynamic p) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(shape: BoxShape.circle, color: p.positive.withValues(alpha: 0.1),
                border: Border.all(color: p.positive, width: 2)),
            child: Icon(Icons.check_circle_outline, color: p.positive, size: 50),
          ),
          const SizedBox(height: 20),
          Text('TRANSAKTION GESENDET!', style: GoogleFonts.rajdhani(
              color: p.positive, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text('Emma bestätigt: Transaktion erfolgreich übermittelt.',
              style: TextStyle(color: p.textSecondary, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('TX: 0x${_rnd.nextInt(999999999).toRadixString(16).padLeft(8, '0').toUpperCase()}',
              style: GoogleFonts.robotoMono(color: p.primary, fontSize: 11)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() { _sendConfirmed = false; _amountCtrl.clear(); _addressCtrl.clear(); }),
            style: ElevatedButton.styleFrom(backgroundColor: p.primary, foregroundColor: p.background, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Neue Transaktion', style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Receive Tab ────────────────────────────────
  Widget _buildReceiveTab(dynamic p) {
    const address = '0x7Gf2Q...HQMLL1985sGS';
    const solAddress = 'HQMLLqEmma1985SaksGrigori...XqZ9';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('Empfangen', style: GoogleFonts.rajdhani(color: p.primary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Senden Sie Assets an diese Adressen', style: TextStyle(color: p.textSecondary, fontSize: 12)),
          const SizedBox(height: 24),
          // QR Code Placeholder
          Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)],
            ),
            child: CustomPaint(painter: _QRPainter(p)),
          ),
          const SizedBox(height: 20),
          // Address Cards
          _AddressCard('Ethereum / ERC-20', address, Icons.account_balance_wallet, p,
              onCopy: () => _copyAddress(context, address, p)),
          const SizedBox(height: 10),
          _AddressCard('Solana / QEMMA', solAddress, Icons.token, p,
              onCopy: () => _copyAddress(context, solAddress, p)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.primary.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: p.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Senden Sie nur kompatible Assets an die jeweilige Adresse. Falsche Netzwerke führen zu Verlust.',
                  style: TextStyle(color: p.textSecondary, fontSize: 11, height: 1.4))),
            ]),
          ),
        ],
      ),
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

  void _showComingSoon(BuildContext context, dynamic p) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: p.primary.withValues(alpha: 0.9),
        content: Text('Bridge: Kommt in Version 2.0', style: TextStyle(color: p.background)),
        duration: const Duration(seconds: 2)));
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

// ── Helper Widgets ─────────────────────────────────
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
  final double amount, price;
  _WalletAsset(this.symbol, this.name, this.amount, this.price, this.network);
  double get value => amount * price;
}

class _TxHistory {
  final String type, asset, address;
  final double amount;
  final bool isIn;
  final DateTime date;
  _TxHistory(this.type, this.asset, this.amount, this.address, this.isIn, this.date);
}

// QR Code Painter (simplified visual)
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
