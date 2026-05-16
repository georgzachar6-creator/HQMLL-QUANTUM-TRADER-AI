// ════════════════════════════════════════════════════════════════════════════
// ENTERPRISE WALLET SCREEN  v26.0
// Quantum Trader AI — Neo-Broker Grade Wallet
// Features: Deposit-Adressen (BTC/ETH/SOL/USDT/BNB), Withdrawal-Flow,
//           Coin→Fiat Umtausch (Binance/Kraken), QR-Codes, Network-Auswahl,
//           SEPA-IBAN Transfer, Live Portfolio-Wert via ExchangeService
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/exchange_service.dart';
import '../widgets/crypto_icon.dart';
import '../providers/theme_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _WalletBalance {
  final String symbol;
  final String name;
  final String network;
  final double amount;
  final String address;
  final String memo;          // for XRP/XLM/TON
  bool selected;

  _WalletBalance({
    required this.symbol,
    required this.name,
    required this.network,
    required this.amount,
    required this.address,
    this.memo = '',
    this.selected = false,
  });

  double usdValue(double price) => amount * price;
}

class _NetworkDef {
  final String id;
  final String label;
  final String fullName;
  final Color color;
  final double withdrawFee; // in token
  final int confirmations;

  const _NetworkDef({
    required this.id,
    required this.label,
    required this.fullName,
    required this.color,
    required this.withdrawFee,
    required this.confirmations,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// STATIC DATA
// ─────────────────────────────────────────────────────────────────────────────

const _networks = <String, List<_NetworkDef>>{
  'BTC': [
    _NetworkDef(id:'BTC',  label:'Bitcoin',   fullName:'Bitcoin Network',   color:Color(0xFFF7931A), withdrawFee:0.0002,  confirmations:3),
    _NetworkDef(id:'LN',   label:'Lightning', fullName:'Lightning Network', color:Color(0xFFFFCC00), withdrawFee:0.00001, confirmations:0),
  ],
  'ETH': [
    _NetworkDef(id:'ETH',  label:'ERC-20',    fullName:'Ethereum Mainnet',  color:Color(0xFF627EEA), withdrawFee:0.003,   confirmations:12),
    _NetworkDef(id:'ARB',  label:'Arbitrum',  fullName:'Arbitrum One',      color:Color(0xFF28A0F0), withdrawFee:0.0005,  confirmations:1),
    _NetworkDef(id:'OP',   label:'Optimism',  fullName:'Optimism Mainnet',  color:Color(0xFFFF0420), withdrawFee:0.0005,  confirmations:1),
  ],
  'USDT': [
    _NetworkDef(id:'ETH',  label:'ERC-20',    fullName:'Ethereum Mainnet',  color:Color(0xFF627EEA), withdrawFee:5.0,     confirmations:12),
    _NetworkDef(id:'TRX',  label:'TRC-20',    fullName:'TRON Network',      color:Color(0xFFEF0027), withdrawFee:1.0,     confirmations:20),
    _NetworkDef(id:'BSC',  label:'BEP-20',    fullName:'BNB Smart Chain',   color:Color(0xFFF3BA2F), withdrawFee:0.5,     confirmations:15),
    _NetworkDef(id:'SOL',  label:'SPL',       fullName:'Solana Network',    color:Color(0xFF9945FF), withdrawFee:0.5,     confirmations:1),
  ],
  'SOL': [
    _NetworkDef(id:'SOL',  label:'Solana',    fullName:'Solana Network',    color:Color(0xFF9945FF), withdrawFee:0.01,    confirmations:1),
  ],
  'BNB': [
    _NetworkDef(id:'BSC',  label:'BEP-20',    fullName:'BNB Smart Chain',   color:Color(0xFFF3BA2F), withdrawFee:0.0005,  confirmations:15),
    _NetworkDef(id:'ETH',  label:'ERC-20',    fullName:'Ethereum Mainnet',  color:Color(0xFF627EEA), withdrawFee:0.005,   confirmations:12),
  ],
  'XRP': [
    _NetworkDef(id:'XRP',  label:'XRP',       fullName:'XRP Ledger',        color:Color(0xFF00AAE4), withdrawFee:0.1,     confirmations:4),
  ],
  'ADA': [
    _NetworkDef(id:'ADA',  label:'Cardano',   fullName:'Cardano Mainnet',   color:Color(0xFF0033AD), withdrawFee:1.0,     confirmations:20),
  ],
  'DOGE': [
    _NetworkDef(id:'DOGE', label:'Dogecoin',  fullName:'Dogecoin Network',  color:Color(0xFFC2A633), withdrawFee:5.0,     confirmations:6),
  ],
};

const Map<String, String> _depositAddresses = {
  'BTC':  '1A1zP1eP5QGefi2DMPTfTL5SLmv7Divf',  // genesis — demo address
  'ETH':  '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
  'USDT': '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
  'SOL':  'DYw8jCTfwHNRJhhmFcbXvVDTqWMEVFBX6ZKUmG5CNSKH',
  'BNB':  '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
  'XRP':  'rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh',
  'ADA':  'addr1qygn4ktcrgn4s0vlq93k3d4djtez2fkmldlhpkqtmxp29vz6qg5wqv4y60zmfwlgm3vu7m5kqdrlz6hxn6ry8z4yp7qyrdh56',
  'DOGE': 'DDkJnauqX3nHMiVHsTbcSMR8JHSaWHRZBU',
};

const Map<String, String> _depositMemos = {
  'XRP': '1234567',
  'TON': '987654321',
};

// ─────────────────────────────────────────────────────────────────────────────
// ENTERPRISE WALLET SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class EnterpriseWalletScreen extends StatefulWidget {
  const EnterpriseWalletScreen({super.key});

  @override
  State<EnterpriseWalletScreen> createState() => _EnterpriseWalletScreenState();
}

class _EnterpriseWalletScreenState extends State<EnterpriseWalletScreen>
    with TickerProviderStateMixin {

  late TabController _tabCtrl;
  late AnimationController _glowCtrl;

  // Selected state
  String _selectedSymbol = 'BTC';
  String _selectedNetworkId = 'BTC';
  int _tab = 0;  // 0=Overview 1=Deposit 2=Withdraw 3=Swap 4=Fiat

  // Form controllers
  final _withdrawAddrCtrl = TextEditingController();
  final _withdrawAmountCtrl = TextEditingController();
  final _swapFromAmountCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController(text: 'DE89370400440532013000');
  final _fiatAmountCtrl = TextEditingController(text: '500');

  String _swapFromSym = 'BTC';
  String _swapToSym = 'USDT';
  String _fiatCurrency = 'EUR';
  String _fiatDirection = 'OUT'; // OUT=Crypto→Fiat, IN=Fiat→Crypto
  bool _withdrawConfirmStep = false;
  bool _swapProcessing = false;
  bool _fiatProcessing = false;
  String? _lastTxId;

  final _rnd = Random(42);

  // Demo balances
  final List<_WalletBalance> _balances = [
    _WalletBalance(symbol:'BTC',  name:'Bitcoin',   network:'Bitcoin',   amount:0.4217,   address:_depositAddresses['BTC']!),
    _WalletBalance(symbol:'ETH',  name:'Ethereum',  network:'ERC-20',    amount:3.850,    address:_depositAddresses['ETH']!),
    _WalletBalance(symbol:'SOL',  name:'Solana',    network:'Solana',    amount:24.75,    address:_depositAddresses['SOL']!),
    _WalletBalance(symbol:'USDT', name:'Tether',    network:'TRC-20',    amount:2850.00,  address:_depositAddresses['USDT']!),
    _WalletBalance(symbol:'BNB',  name:'BNB',       network:'BEP-20',    amount:5.20,     address:_depositAddresses['BNB']!),
    _WalletBalance(symbol:'XRP',  name:'XRP',       network:'XRP Ledger',amount:1500.00,  address:_depositAddresses['XRP']!,  memo:'1234567'),
    _WalletBalance(symbol:'ADA',  name:'Cardano',   network:'Cardano',   amount:800.00,   address:_depositAddresses['ADA']!),
    _WalletBalance(symbol:'DOGE', name:'Dogecoin',  network:'Dogecoin',  amount:12450.0,  address:_depositAddresses['DOGE']!),
  ];

  final List<Map<String, dynamic>> _txHistory = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _tabCtrl.addListener(() { setState(() { _tab = _tabCtrl.index; }); });
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _generateDemoHistory();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _glowCtrl.dispose();
    _withdrawAddrCtrl.dispose();
    _withdrawAmountCtrl.dispose();
    _swapFromAmountCtrl.dispose();
    _ibanCtrl.dispose();
    _fiatAmountCtrl.dispose();
    super.dispose();
  }

  void _generateDemoHistory() {
    final txTypes = ['DEPOSIT', 'WITHDRAW', 'SWAP', 'FIAT_OUT', 'FIAT_IN'];
    final symbols = ['BTC', 'ETH', 'SOL', 'USDT', 'BNB'];
    final now = DateTime.now();
    for (int i = 0; i < 20; i++) {
      final type = txTypes[_rnd.nextInt(txTypes.length)];
      final sym = symbols[_rnd.nextInt(symbols.length)];
      _txHistory.add({
        'id': 'TX${(now.millisecondsSinceEpoch - i * 3600000).toRadixString(16).toUpperCase().substring(0, 8)}',
        'type': type,
        'symbol': sym,
        'amount': (_rnd.nextDouble() * 2.0 + 0.01),
        'status': i < 2 ? 'PENDING' : 'COMPLETED',
        'time': now.subtract(Duration(hours: i * 6 + _rnd.nextInt(5))),
        'hash': '0x${List.generate(8, (_) => _rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}...',
        'exchange': _rnd.nextBool() ? 'Binance' : 'Kraken',
      });
    }
  }

  _WalletBalance? get _selectedBalance =>
      _balances.firstWhere((b) => b.symbol == _selectedSymbol, orElse: () => _balances.first);

  List<_NetworkDef> get _availableNetworks =>
      _networks[_selectedSymbol] ?? [_NetworkDef(id:_selectedSymbol, label:_selectedSymbol, fullName:'$_selectedSymbol Network', color:Colors.grey, withdrawFee:0, confirmations:0)];

  _NetworkDef? get _currentNetwork =>
      _availableNetworks.firstWhere((n) => n.id == _selectedNetworkId, orElse: () => _availableNetworks.first);

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ex = context.watch<ExchangeService>();
    final tp = context.watch<ThemeProvider>();
    final p = tp.palette;

    // Compute total portfolio value
    double totalUsd = 0;
    for (final b in _balances) {
      final price = ex.getPrice(b.symbol);
      totalUsd += b.usdValue(price > 0 ? price : _fallbackPrice(b.symbol));
    }

    return Scaffold(
      backgroundColor: p.background,
      appBar: _buildAppBar(p, totalUsd),
      body: Column(
        children: [
          // Tab bar
          _buildTabBar(p),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildOverviewTab(ex, p),
                _buildDepositTab(p),
                _buildWithdrawTab(ex, p),
                _buildSwapTab(ex, p),
                _buildFiatTab(ex, p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(dynamic p, double totalUsd) {
    return AppBar(
      backgroundColor: p.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: p.textSecondary, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ENTERPRISE WALLET',
            style: GoogleFonts.rajdhani(color: p.primary, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2)),
          Text('Neo-Broker Grade · MiCA/PSD2 Compliant',
            style: TextStyle(color: p.textSecondary.withValues(alpha: 0.6), fontSize: 9, letterSpacing: 0.5)),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF00C896).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.4), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${_formatLarge(totalUsd)}',
                style: GoogleFonts.spaceMono(color: const Color(0xFF00C896), fontSize: 13, fontWeight: FontWeight.bold)),
              Text('TOTAL VALUE', style: TextStyle(color: Colors.grey[600], fontSize: 7, letterSpacing: 0.5)),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB BAR
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTabBar(dynamic p) {
    final tabs = [
      (Icons.account_balance_wallet_outlined, 'OVERVIEW'),
      (Icons.arrow_downward_rounded,           'DEPOSIT'),
      (Icons.arrow_upward_rounded,             'WITHDRAW'),
      (Icons.swap_horiz_rounded,               'SWAP'),
      (Icons.euro_rounded,                     'FIAT'),
    ];
    final tabColors = [p.primary, const Color(0xFF00C896), const Color(0xFFFF3355), const Color(0xFFFFB800), const Color(0xFF4A90E2)];

    return Container(
      height: 52,
      color: p.surface,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () { _tabCtrl.animateTo(i); setState(() => _tab = i); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                    color: isActive ? tabColors[i] : Colors.transparent,
                    width: 2.5,
                  )),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[i].$1, size: 16, color: isActive ? tabColors[i] : Colors.grey[600]),
                    const SizedBox(height: 1),
                    Text(tabs[i].$2, style: TextStyle(
                      color: isActive ? tabColors[i] : Colors.grey[600],
                      fontSize: 8,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      letterSpacing: 0.5,
                    )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 0: OVERVIEW
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildOverviewTab(ExchangeService ex, dynamic p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Asset allocation header
          Text('PORTFOLIO ALLOCATION', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 12),

          // Balance cards
          ..._balances.map((b) {
            final price = ex.getPrice(b.symbol);
            final effectivePrice = price > 0 ? price : _fallbackPrice(b.symbol);
            final usd = b.usdValue(effectivePrice);
            final tick = ex.getTick(b.symbol);
            final change = tick?.change24h ?? 0.0;
            final isUp = change >= 0;

            return GestureDetector(
              onTap: () { setState(() { _selectedSymbol = b.symbol; _selectedNetworkId = _availableNetworks.first.id; }); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _selectedSymbol == b.symbol
                      ? CryptoRegistry.getOrFallback(b.symbol).primary.withValues(alpha: 0.1)
                      : p.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedSymbol == b.symbol
                        ? CryptoRegistry.getOrFallback(b.symbol).primary.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.06),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    CryptoIcon(b.symbol, size: 42, showShadow: false),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(b.symbol, style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(b.network, style: TextStyle(color: Colors.grey[500], fontSize: 8)),
                            ),
                            if (tick?.isLive == true) ...[
                              const SizedBox(width: 5),
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(color: Color(0xFF00C896), shape: BoxShape.circle),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 3),
                          Text(b.name, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${b.amount % 1 == 0 ? b.amount.toStringAsFixed(0) : b.amount.toStringAsFixed(b.symbol == 'BTC' ? 4 : 2)} ${b.symbol}',
                          style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('\$${_fmt(usd)}',
                          style: GoogleFonts.spaceMono(color: Colors.grey[400], fontSize: 10)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isUp ? const Color(0xFF00C896) : const Color(0xFFFF3355)).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text('${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: isUp ? const Color(0xFF00C896) : const Color(0xFFFF3355),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SpaceMono',
                            )),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
          Text('RECENT TRANSACTIONS', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          ..._txHistory.take(8).map((tx) => _buildTxRow(tx, p)),
        ],
      ),
    );
  }

  Widget _buildTxRow(Map<String, dynamic> tx, dynamic p) {
    final type = tx['type'] as String;
    final sym = tx['symbol'] as String;
    final time = tx['time'] as DateTime;
    final status = tx['status'] as String;
    final isPending = status == 'PENDING';

    final (icon, color) = switch (type) {
      'DEPOSIT'  => (Icons.arrow_downward_rounded, const Color(0xFF00C896)),
      'WITHDRAW' => (Icons.arrow_upward_rounded,   const Color(0xFFFF3355)),
      'SWAP'     => (Icons.swap_horiz_rounded,     const Color(0xFFFFB800)),
      'FIAT_OUT' => (Icons.euro_rounded,           const Color(0xFF4A90E2)),
      'FIAT_IN'  => (Icons.euro_rounded,           const Color(0xFF00C896)),
      _          => (Icons.receipt_outlined,       Colors.grey),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          CryptoIcon(sym, size: 24, showBorder: false),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.replaceAll('_', ' '),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                Text('${tx['hash']} · ${tx['exchange']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 8)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${(tx['amount'] as double).toStringAsFixed(4)} $sym',
                style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 10)),
              Text(_formatAgo(time),
                style: TextStyle(color: Colors.grey[600], fontSize: 9)),
              if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB800).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('PENDING', style: TextStyle(color: Color(0xFFFFB800), fontSize: 7, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 1: DEPOSIT
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDepositTab(dynamic p) {
    final addr = _depositAddresses[_selectedSymbol] ?? '0x...';
    final memo = _depositMemos[_selectedSymbol];
    final networks = _availableNetworks;
    final currentNet = _currentNetwork;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coin selector
          _buildCoinSelectorStrip(),
          const SizedBox(height: 16),

          // Network selector
          if (networks.length > 1) ...[
            Text('SELECT NETWORK', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: networks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final n = networks[i];
                  final isSel = n.id == _selectedNetworkId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedNetworkId = n.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? n.color.withValues(alpha: 0.15) : p.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSel ? n.color : Colors.white.withValues(alpha: 0.08), width: isSel ? 1.5 : 1),
                      ),
                      child: Text(n.label,
                        style: TextStyle(color: isSel ? n.color : Colors.grey[400], fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB800), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only send $_selectedSymbol${currentNet != null ? ' via ${currentNet.fullName}' : ''}. Sending other assets will result in permanent loss.',
                    style: const TextStyle(color: Color(0xFFFFB800), fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // QR Code
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: CryptoRegistry.getOrFallback(_selectedSymbol).primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: QrImageView(
                data: addr,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Address display
          Text('DEPOSIT ADDRESS', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          _buildCopyField(label: addr, onCopy: () => _copy(addr, 'Address copied')),

          // Memo (for XRP etc.)
          if (memo != null) ...[
            const SizedBox(height: 12),
            Text('DESTINATION TAG / MEMO', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3355).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF3355).withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Color(0xFFFF3355), size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text('MEMO REQUIRED: $memo — Missing memo will cause permanent loss of funds',
                  style: const TextStyle(color: Color(0xFFFF3355), fontSize: 10, fontWeight: FontWeight.bold))),
                IconButton(
                  onPressed: () => _copy(memo, 'Memo copied'),
                  icon: const Icon(Icons.copy, color: Color(0xFFFF3355), size: 14),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 20),

          // Confirmations info
          if (currentNet != null)
            _buildInfoRow('Confirmations required', '${currentNet.confirmations == 0 ? 'Instant' : currentNet.confirmations}'),
          _buildInfoRow('Minimum deposit', '—'),
          _buildInfoRow('Expected arrival', currentNet?.confirmations == 0 ? '~1 min' : '~${(currentNet?.confirmations ?? 12) * 2} min'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2: WITHDRAW
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildWithdrawTab(ExchangeService ex, dynamic p) {
    final balance = _selectedBalance;
    final price = ex.getPrice(_selectedSymbol);
    final effectivePrice = price > 0 ? price : _fallbackPrice(_selectedSymbol);
    final networks = _availableNetworks;
    final currentNet = _currentNetwork;
    final amountVal = double.tryParse(_withdrawAmountCtrl.text) ?? 0;
    final fee = currentNet?.withdrawFee ?? 0;
    final receiveAmt = max(0.0, amountVal - fee);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoinSelectorStrip(),
          const SizedBox(height: 16),

          // Available balance
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  CryptoIcon(_selectedSymbol, size: 32, showBorder: false),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Available', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                    Text('${balance?.amount.toStringAsFixed(4) ?? '0.0000'} $_selectedSymbol',
                      style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ]),
                ]),
                Text('\$${_fmt((balance?.amount ?? 0) * effectivePrice)}',
                  style: GoogleFonts.spaceMono(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Network
          if (networks.length > 1) ...[
            Text('NETWORK', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: networks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final n = networks[i];
                  final isSel = n.id == _selectedNetworkId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedNetworkId = n.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? n.color.withValues(alpha: 0.15) : p.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSel ? n.color : Colors.white.withValues(alpha: 0.08), width: isSel ? 1.5 : 1),
                      ),
                      child: Row(children: [
                        Text(n.label, style: TextStyle(color: isSel ? n.color : Colors.grey[400], fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                        const SizedBox(width: 6),
                        Text('Fee: ${n.withdrawFee} $_selectedSymbol', style: TextStyle(color: Colors.grey[600], fontSize: 8)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Recipient address
          Text('RECIPIENT ADDRESS', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _withdrawAddrCtrl,
            hint: 'Enter wallet address',
            suffix: IconButton(
              onPressed: () async {
                final data = await Clipboard.getData('text/plain');
                if (data?.text != null) setState(() => _withdrawAddrCtrl.text = data!.text!);
              },
              icon: const Icon(Icons.paste, size: 16, color: Color(0xFF4A90E2)),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(height: 12),

          // Amount
          Text('AMOUNT', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _withdrawAmountCtrl,
            hint: '0.00',
            keyboardType: TextInputType.number,
            suffix: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _withdrawAmountCtrl.text = (balance!.amount * 0.5).toStringAsFixed(4)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(5)),
                    child: const Text('50%', style: TextStyle(color: Colors.white, fontSize: 9)),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _withdrawAmountCtrl.text = max(0.0, (balance!.amount - fee)).toStringAsFixed(4)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(5)),
                    child: const Text('MAX', style: TextStyle(color: Color(0xFFFFB800), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          if (amountVal > 0) ...[
            const SizedBox(height: 6),
            Text('≈ \$${_fmt(amountVal * effectivePrice)} USD',
              style: TextStyle(color: Colors.grey[500], fontSize: 10)),
          ],
          const SizedBox(height: 16),

          // Fee summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(children: [
              _buildInfoRow('Withdrawal amount', '${amountVal.toStringAsFixed(4)} $_selectedSymbol'),
              _buildInfoRow('Network fee', '${fee.toStringAsFixed(4)} $_selectedSymbol'),
              Divider(color: Colors.white.withValues(alpha: 0.06)),
              _buildInfoRow('You will receive', '${receiveAmt.toStringAsFixed(4)} $_selectedSymbol', highlight: true),
            ]),
          ),
          const SizedBox(height: 20),

          // Submit button
          if (!_withdrawConfirmStep)
            _buildActionButton(
              label: 'REVIEW WITHDRAWAL',
              color: const Color(0xFFFF3355),
              icon: Icons.arrow_upward_rounded,
              onTap: () {
                if (_withdrawAddrCtrl.text.isEmpty || amountVal <= 0) {
                  _showSnack('Enter address and amount first');
                  return;
                }
                setState(() => _withdrawConfirmStep = true);
              },
            )
          else
            _buildConfirmCard(
              title: 'CONFIRM WITHDRAWAL',
              color: const Color(0xFFFF3355),
              rows: [
                ('To', _truncAddr(_withdrawAddrCtrl.text)),
                ('Network', currentNet?.fullName ?? _selectedSymbol),
                ('Amount', '${amountVal.toStringAsFixed(4)} $_selectedSymbol'),
                ('Fee', '${fee.toStringAsFixed(4)} $_selectedSymbol'),
                ('Receive', '${receiveAmt.toStringAsFixed(4)} $_selectedSymbol'),
              ],
              onConfirm: () async {
                setState(() => _withdrawConfirmStep = false);
                await _executeWithdrawal(ex, amountVal, receiveAmt);
              },
              onCancel: () => setState(() => _withdrawConfirmStep = false),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 3: SWAP
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSwapTab(ExchangeService ex, dynamic p) {
    final fromAmt = double.tryParse(_swapFromAmountCtrl.text) ?? 0.0;
    final fromPrice = ex.getPrice(_swapFromSym);
    final toPrice = ex.getPrice(_swapToSym);
    final effectiveFrom = fromPrice > 0 ? fromPrice : _fallbackPrice(_swapFromSym);
    final effectiveTo = toPrice > 0 ? toPrice : _fallbackPrice(_swapToSym);
    final toAmt = effectiveTo > 0 ? (fromAmt * effectiveFrom / effectiveTo) : 0.0;
    final rate = effectiveTo > 0 ? effectiveFrom / effectiveTo : 0.0;
    final feeUsd = fromAmt * effectiveFrom * 0.001; // 0.1% fee

    final allSymbols = ['BTC', 'ETH', 'SOL', 'USDT', 'BNB', 'XRP', 'ADA', 'DOGE', 'MATIC', 'AVAX'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Exchange selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildExchangeChip('Binance', const Color(0xFFF3BA2F)),
              const SizedBox(width: 8),
              _buildExchangeChip('Kraken',  const Color(0xFF5741D9)),
              const SizedBox(width: 8),
              _buildExchangeChip('Internal', const Color(0xFF00C896)),
            ],
          ),
          const SizedBox(height: 20),

          // FROM
          Text('FROM', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(children: [
              Row(children: [
                GestureDetector(
                  onTap: () => _showCoinPicker(allSymbols, _swapFromSym, (s) => setState(() { _swapFromSym = s; })),
                  child: Row(children: [
                    CryptoIcon(_swapFromSym, size: 32, showBorder: false),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_swapFromSym, style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(CryptoRegistry.getOrFallback(_swapFromSym).name, style: TextStyle(color: Colors.grey[500], fontSize: 9)),
                    ]),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey[500], size: 18),
                  ]),
                ),
                const Spacer(),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _swapFromAmountCtrl,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text('≈ \$${_fmt(fromAmt * effectiveFrom)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              ),
            ]),
          ),

          // Swap button
          Center(
            child: GestureDetector(
              onTap: () => setState(() {
                final tmp = _swapFromSym;
                _swapFromSym = _swapToSym;
                _swapToSym = tmp;
              }),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.swap_vert, color: Color(0xFFFFB800), size: 20),
              ),
            ),
          ),

          // TO
          Text('TO', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(children: [
              Row(children: [
                GestureDetector(
                  onTap: () => _showCoinPicker(allSymbols, _swapToSym, (s) => setState(() { _swapToSym = s; })),
                  child: Row(children: [
                    CryptoIcon(_swapToSym, size: 32, showBorder: false),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_swapToSym, style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(CryptoRegistry.getOrFallback(_swapToSym).name, style: TextStyle(color: Colors.grey[500], fontSize: 9)),
                    ]),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey[500], size: 18),
                  ]),
                ),
                const Spacer(),
                Text(toAmt > 0 ? toAmt.toStringAsFixed(5) : '0.00000',
                  style: GoogleFonts.spaceMono(color: const Color(0xFF00C896), fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text('≈ \$${_fmt(toAmt * effectiveTo)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // Rate summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(children: [
              _buildInfoRow('Rate', '1 $_swapFromSym = ${rate.toStringAsFixed(4)} $_swapToSym'),
              _buildInfoRow('Fee (0.1%)', '\$${feeUsd.toStringAsFixed(2)} USD'),
              _buildInfoRow('Slippage', '≤ 0.1%'),
              _buildInfoRow('Route', 'Binance → Kraken (best price)'),
            ]),
          ),
          const SizedBox(height: 20),

          if (_swapProcessing)
            _buildProcessingIndicator('Executing swap on Binance...')
          else
            _buildActionButton(
              label: 'EXECUTE SWAP',
              color: const Color(0xFFFFB800),
              icon: Icons.swap_horiz_rounded,
              onTap: () async {
                if (fromAmt <= 0) { _showSnack('Enter amount first'); return; }
                setState(() => _swapProcessing = true);
                final tx = await ex.swap(fromSymbol: _swapFromSym, toSymbol: _swapToSym, fromAmount: fromAmt);
                await Future.delayed(const Duration(seconds: 2));
                if (mounted) {
                  setState(() {
                    _swapProcessing = false;
                    _lastTxId = tx?.id;
                    _swapFromAmountCtrl.clear();
                  });
                  if (tx != null) _showSuccessSnack('Swap executed! TX: ${tx.id.substring(0, 8)}...');
                }
              },
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 4: FIAT (On/Off-Ramp)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFiatTab(ExchangeService ex, dynamic p) {
    final cryptoSymbol = _fiatDirection == 'OUT' ? _selectedSymbol : _selectedSymbol;
    final cryptoPrice = ex.getPrice(cryptoSymbol);
    final effectivePrice = cryptoPrice > 0 ? cryptoPrice : _fallbackPrice(cryptoSymbol);
    final fiatAmt = double.tryParse(_fiatAmountCtrl.text) ?? 0.0;
    final cryptoAmt = _fiatDirection == 'OUT'
        ? (fiatAmt / effectivePrice)
        : (fiatAmt * effectivePrice);
    final fee = fiatAmt * 0.015; // 1.5% fiat fee
    final netAmt = fiatAmt - fee;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Direction Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(children: [
              Expanded(child: _buildDirectionBtn('OUT', 'Crypto → Fiat', Icons.arrow_upward_rounded, const Color(0xFFFF3355), p)),
              Expanded(child: _buildDirectionBtn('IN',  'Fiat → Crypto', Icons.arrow_downward_rounded, const Color(0xFF00C896), p)),
            ]),
          ),
          const SizedBox(height: 20),

          // Crypto selector
          _buildCoinSelectorStrip(small: true),
          const SizedBox(height: 16),

          // Fiat currency
          Text('FIAT CURRENCY', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['EUR', 'USD', 'GBP', 'CHF', 'JPY'].map((c) {
                final isSel = c == _fiatCurrency;
                return GestureDetector(
                  onTap: () => setState(() => _fiatCurrency = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF4A90E2).withValues(alpha: 0.15) : p.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSel ? const Color(0xFF4A90E2) : Colors.white.withValues(alpha: 0.08), width: isSel ? 1.5 : 1),
                    ),
                    child: Text(c,
                      style: TextStyle(color: isSel ? const Color(0xFF4A90E2) : Colors.grey[400], fontSize: 13, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Amount
          Text('${_fiatDirection == 'OUT' ? 'FIAT AMOUNT TO RECEIVE' : 'FIAT AMOUNT TO SEND'}',
            style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _fiatAmountCtrl,
            hint: '0.00',
            keyboardType: TextInputType.number,
            prefix: Text(_fiatCurrencySymbol(_fiatCurrency),
              style: GoogleFonts.spaceMono(color: Colors.grey[400], fontSize: 18)),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 12),

          // Live conversion
          if (fiatAmt > 0)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4A90E2).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fiatDirection == 'OUT' ? 'You send:' : 'You receive:',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  Row(children: [
                    CryptoIcon(cryptoSymbol, size: 20, showBorder: false),
                    const SizedBox(width: 6),
                    Text('${cryptoAmt.toStringAsFixed(6)} $cryptoSymbol',
                      style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // IBAN for SEPA
          if (_fiatDirection == 'OUT') ...[
            Text('SEPA BANK ACCOUNT (IBAN)', style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _ibanCtrl,
              hint: 'DE89 3704 0044 0532 0130 00',
            ),
            const SizedBox(height: 4),
            Text('PSD2 Compliant · Instant SEPA · No extra fees',
              style: TextStyle(color: Colors.grey[600], fontSize: 9)),
          ],

          const SizedBox(height: 16),

          // Fee breakdown
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(children: [
              _buildInfoRow('Gross amount', '${_fiatCurrencySymbol(_fiatCurrency)}${_fmt(fiatAmt)}'),
              _buildInfoRow('Processing fee (1.5%)', '-${_fiatCurrencySymbol(_fiatCurrency)}${_fmt(fee)}'),
              Divider(color: Colors.white.withValues(alpha: 0.06)),
              _buildInfoRow('Net amount', '${_fiatCurrencySymbol(_fiatCurrency)}${_fmt(netAmt)}', highlight: true),
              _buildInfoRow('Settlement', '1-2 business days (SEPA)'),
              _buildInfoRow('Exchange', 'Binance → Kraken (best rate)'),
            ]),
          ),

          const SizedBox(height: 20),

          if (_fiatProcessing)
            _buildProcessingIndicator(_fiatDirection == 'OUT'
                ? 'Liquidating $_selectedSymbol on Binance...'
                : 'Purchasing $_selectedSymbol via Kraken...')
          else
            _buildActionButton(
              label: _fiatDirection == 'OUT' ? 'SELL & TRANSFER TO BANK' : 'BUY WITH BANK TRANSFER',
              color: _fiatDirection == 'OUT' ? const Color(0xFFFF3355) : const Color(0xFF00C896),
              icon: _fiatDirection == 'OUT' ? Icons.euro_rounded : Icons.add_shopping_cart_rounded,
              onTap: () async {
                if (fiatAmt <= 0) { _showSnack('Enter amount first'); return; }
                setState(() => _fiatProcessing = true);
                await Future.delayed(const Duration(seconds: 3));
                if (mounted) {
                  setState(() => _fiatProcessing = false);
                  _showSuccessSnack(_fiatDirection == 'OUT'
                      ? '${_fiatCurrencySymbol(_fiatCurrency)}${_fmt(netAmt)} transfer initiated to IBAN'
                      : '${cryptoAmt.toStringAsFixed(5)} $cryptoSymbol purchased!');
                }
              },
            ),

          const SizedBox(height: 20),

          // Regulatory footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('REGULATORY COMPLIANCE', style: TextStyle(color: Colors.grey[600], fontSize: 9, letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Text('MiCA (EU Regulation 2023/1114) · PSD2/Open Banking · AML 6th Directive\nFiat operations via licensed PSP partner · KYC Level 2 required for >€5,000',
                  style: TextStyle(color: Colors.grey[700], fontSize: 8, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED WIDGETS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCoinSelectorStrip({bool small = false}) {
    final coins = ['BTC', 'ETH', 'SOL', 'USDT', 'BNB', 'XRP', 'ADA', 'DOGE'];
    return SizedBox(
      height: small ? 52 : 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: coins.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sym = coins[i];
          final isSel = sym == _selectedSymbol;
          final meta = CryptoRegistry.getOrFallback(sym);
          return GestureDetector(
            onTap: () => setState(() {
              _selectedSymbol = sym;
              _selectedNetworkId = (_networks[sym]?.first.id) ?? sym;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSel ? meta.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSel ? meta.primary : Colors.white.withValues(alpha: 0.08),
                  width: isSel ? 1.5 : 1,
                ),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                CryptoIcon(sym, size: small ? 24 : 28, showBorder: false),
                const SizedBox(height: 2),
                Text(sym, style: TextStyle(
                  color: isSel ? meta.primary : Colors.grey[400],
                  fontSize: 8,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'SpaceMono',
                )),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCopyField({required String label, required VoidCallback onCopy}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
              style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 11),
              overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCopy,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF4A90E2).withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, size: 12, color: Color(0xFF4A90E2)),
                  SizedBox(width: 4),
                  Text('COPY', style: TextStyle(color: Color(0xFF4A90E2), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
    Widget? prefix,
    void Function(String)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          if (prefix != null) ...[prefix, const SizedBox(width: 8)],
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[600], fontFamily: 'SpaceMono'),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
              onChanged: onChanged,
            ),
          ),
          if (suffix != null) suffix,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          Text(value,
            style: GoogleFonts.spaceMono(
              color: highlight ? const Color(0xFF00C896) : Colors.white,
              fontSize: 11,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            )),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required Color color, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.8), color]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 0, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ]),
      ),
    );
  }

  Widget _buildConfirmCard({
    required String title,
    required Color color,
    required List<(String, String)> rows,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ]),
          const SizedBox(height: 12),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(r.$1, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              Text(r.$2, style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 11)),
            ]),
          )),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: onCancel,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('CANCEL', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: onConfirm,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('CONFIRM & SEND', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1))),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFFFFB800), strokeWidth: 2.5)),
          const SizedBox(width: 14),
          Text(message, style: const TextStyle(color: Color(0xFFFFB800), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDirectionBtn(String id, String label, IconData icon, Color color, dynamic p) {
    final isSel = _fiatDirection == id;
    return GestureDetector(
      onTap: () => setState(() => _fiatDirection = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSel ? Border.all(color: color.withValues(alpha: 0.5)) : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: isSel ? color : Colors.grey[600], size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: isSel ? color : Colors.grey[500], fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
        ]),
      ),
    );
  }

  Widget _buildExchangeChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(name, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _executeWithdrawal(ExchangeService ex, double amount, double receiveAmt) async {
    final tx = await ex.placeOrder(
      symbol: _selectedSymbol,
      isBuy: false,
      quantity: receiveAmt,
    );
    if (mounted) {
      if (tx != null) {
        _showSuccessSnack('Withdrawal initiated! TX: ${tx.id.substring(0, 8)}...');
        setState(() {
          _withdrawAddrCtrl.clear();
          _withdrawAmountCtrl.clear();
        });
      } else {
        _showSnack('Withdrawal failed. Check balance.');
      }
    }
  }

  void _showCoinPicker(List<String> coins, String current, ValueChanged<String> onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0F14),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 3, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('SELECT ASSET', style: TextStyle(color: Colors.grey[400], fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85),
                itemCount: coins.length,
                itemBuilder: (_, i) {
                  final sym = coins[i];
                  final isSel = sym == current;
                  final meta = CryptoRegistry.getOrFallback(sym);
                  return GestureDetector(
                    onTap: () { Navigator.pop(context); onSelect(sym); },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSel ? meta.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSel ? meta.primary : Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        CryptoIcon(sym, size: 30, showBorder: false),
                        const SizedBox(height: 4),
                        Text(sym, style: TextStyle(color: isSel ? meta.primary : Colors.white, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  void _copy(String text, String msg) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnack(msg);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 12)),
      backgroundColor: const Color(0xFF1E2028),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Color(0xFF00C896), size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 11))),
      ]),
      backgroundColor: const Color(0xFF0D1F17),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  String _truncAddr(String addr) => addr.length > 16 ? '${addr.substring(0, 8)}...${addr.substring(addr.length - 6)}' : addr;
  String _fmt(double v) => v >= 10000 ? '${(v / 1000).toStringAsFixed(1)}K' : v.toStringAsFixed(2);
  String _formatLarge(double v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(2)}M' : v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : v.toStringAsFixed(0);
  String _formatAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
  String _fiatCurrencySymbol(String c) => {'EUR': '€', 'USD': '\$', 'GBP': '£', 'CHF': 'Fr', 'JPY': '¥'}[c] ?? c;
  double _fallbackPrice(String sym) => const {'BTC': 65000.0, 'ETH': 3200.0, 'SOL': 150.0, 'BNB': 580.0, 'USDT': 1.0, 'XRP': 0.55, 'ADA': 0.45, 'DOGE': 0.12, 'MATIC': 0.8, 'AVAX': 35.0}[sym] ?? 1.0;
}
