// ============================================================
// DEPLOY HUB v2 – Smart Contract Deployer & DevOps Pipeline
// Networks, Gas Estimator, Live TX Monitor, Contract Library
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/exchange_service.dart';

class DeployHubScreen extends StatefulWidget {
  const DeployHubScreen({super.key});
  @override
  State<DeployHubScreen> createState() => _DeployHubScreenState();
}

class _DeployHubScreenState extends State<DeployHubScreen>
    with TickerProviderStateMixin {
  late TabController _tab;
  late AnimationController _glowCtrl;
  late AnimationController _pulseCtrl;
  Timer? _liveTimer;
  final _rand = Random();

  // State
  String _selectedNetwork = 'Ethereum Mainnet';
  String _selectedContract = 'ERC-20 Token';
  bool _isDeploying = false;
  double _deployProgress = 0;
  String _deployStatus = '';
  final List<_TxEntry> _liveTx = [];
  int _gasPrice = 24;
  int _gasLimit = 200000;
  double _ethPrice = 3548.20;

  // Networks
  final List<Map<String, dynamic>> _networks = [
    {'name': 'Ethereum Mainnet', 'chainId': 1, 'symbol': 'ETH', 'color': const Color(0xFF627EEA), 'rpc': 'mainnet.infura.io', 'explorer': 'etherscan.io', 'gas': 24},
    {'name': 'Polygon PoS', 'chainId': 137, 'symbol': 'MATIC', 'color': const Color(0xFF8247E5), 'rpc': 'polygon-rpc.com', 'explorer': 'polygonscan.com', 'gas': 180},
    {'name': 'BNB Smart Chain', 'chainId': 56, 'symbol': 'BNB', 'color': const Color(0xFFF0B90B), 'rpc': 'bsc-dataseed.binance.org', 'explorer': 'bscscan.com', 'gas': 5},
    {'name': 'Arbitrum One', 'chainId': 42161, 'symbol': 'ETH', 'color': const Color(0xFF28A0F0), 'rpc': 'arb1.arbitrum.io', 'explorer': 'arbiscan.io', 'gas': 0},
    {'name': 'Optimism', 'chainId': 10, 'symbol': 'ETH', 'color': const Color(0xFFFF0420), 'rpc': 'mainnet.optimism.io', 'explorer': 'optimistic.etherscan.io', 'gas': 0},
    {'name': 'Base', 'chainId': 8453, 'symbol': 'ETH', 'color': const Color(0xFF0052FF), 'rpc': 'mainnet.base.org', 'explorer': 'basescan.org', 'gas': 0},
    {'name': 'Avalanche C-Chain', 'chainId': 43114, 'symbol': 'AVAX', 'color': const Color(0xFFE84142), 'rpc': 'api.avax.network', 'explorer': 'snowtrace.io', 'gas': 25},
    {'name': 'Solana Mainnet', 'chainId': 0, 'symbol': 'SOL', 'color': const Color(0xFF9945FF), 'rpc': 'api.mainnet-beta.solana.com', 'explorer': 'solscan.io', 'gas': 0},
  ];

  // Contract Templates
  final List<Map<String, dynamic>> _contracts = [
    {'name': 'ERC-20 Token', 'icon': Icons.token_rounded, 'color': const Color(0xFF00FF88), 'desc': 'Standard Fungible Token', 'gas': '~250,000', 'audited': true, 'code': 'ERC20'},
    {'name': 'ERC-721 NFT', 'icon': Icons.image_rounded, 'color': const Color(0xFF00AAFF), 'desc': 'Non-Fungible Token', 'gas': '~180,000', 'audited': true, 'code': 'ERC721'},
    {'name': 'ERC-1155 Multi', 'icon': Icons.collections_rounded, 'color': const Color(0xFFAA44FF), 'desc': 'Multi-Token Standard', 'gas': '~320,000', 'audited': true, 'code': 'ERC1155'},
    {'name': 'DEX Swap Router', 'icon': Icons.swap_horiz_rounded, 'color': const Color(0xFFFF6B35), 'desc': 'Uniswap V3 Fork', 'gas': '~1,200,000', 'audited': false, 'code': 'SWAP'},
    {'name': 'Staking Contract', 'icon': Icons.savings_rounded, 'color': const Color(0xFFFFD700), 'desc': 'Yield Bearing Staking', 'gas': '~450,000', 'audited': true, 'code': 'STAKE'},
    {'name': 'Multisig Wallet', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF00CED1), 'desc': 'Gnosis Safe Fork', 'gas': '~600,000', 'audited': true, 'code': 'MSIG'},
    {'name': 'DAO Governance', 'icon': Icons.how_to_vote_rounded, 'color': const Color(0xFFFF69B4), 'desc': 'OpenZeppelin Governor', 'gas': '~800,000', 'audited': false, 'code': 'DAO'},
    {'name': 'Vesting Contract', 'icon': Icons.schedule_rounded, 'color': const Color(0xFF98FF98), 'desc': 'Token Vesting Schedule', 'gas': '~280,000', 'audited': true, 'code': 'VEST'},
  ];

  // Recent Deployments
  final List<Map<String, dynamic>> _deployments = [
    {'name': 'QEMMA Token v2', 'network': 'Ethereum', 'address': '0x7Fc...4a2f', 'status': 'success', 'time': 'vor 2h', 'gas': '\$18.42', 'block': '19841203'},
    {'name': 'HQMLL Staking', 'network': 'Polygon', 'address': '0x3aB...91c8', 'status': 'success', 'time': 'vor 1d', 'gas': '\$0.84', 'block': '54821047'},
    {'name': 'NFT Collection', 'network': 'Base', 'address': '0x9eF...3d71', 'status': 'success', 'time': 'vor 3d', 'gas': '\$2.11', 'block': '12047892'},
    {'name': 'DEX Router', 'network': 'BSC', 'address': '0x1cD...8e43', 'status': 'failed', 'time': 'vor 5d', 'gas': '\$0.32', 'block': '-'},
    {'name': 'DAO Governor', 'network': 'Arbitrum', 'address': '0x5aA...2b16', 'status': 'pending', 'time': 'vor 7d', 'gas': '\$1.05', 'block': 'pending'},
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _startLiveTxFeed();
    // v34.0: _ethPrice sofort aus ExchangeService laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ex = context.read<ExchangeService>();
      final live = ex.getPrice('ETH');
      if (live > 0) setState(() => _ethPrice = live);
    });
  }

  void _startLiveTxFeed() {
    // Seed initial TXs
    final txTypes = ['Transfer', 'Swap', 'Mint', 'Burn', 'Stake', 'Unstake', 'Approve'];
    for (int i = 0; i < 8; i++) {
      _liveTx.add(_TxEntry(
        hash: '0x${_randHex(8)}...${_randHex(4)}',
        type: txTypes[_rand.nextInt(txTypes.length)],
        value: '${(_rand.nextDouble() * 10).toStringAsFixed(4)} ETH',
        gas: '${_rand.nextInt(200) + 20} Gwei',
        status: _rand.nextDouble() > 0.1 ? 'confirmed' : 'pending',
        time: 'vor ${_rand.nextInt(60) + 1}s',
      ));
    }
    _liveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _gasPrice = 18 + _rand.nextInt(20);
        _liveTx.insert(0, _TxEntry(
          hash: '0x${_randHex(8)}...${_randHex(4)}',
          type: txTypes[_rand.nextInt(txTypes.length)],
          value: '${(_rand.nextDouble() * 5).toStringAsFixed(4)} ETH',
          gas: '$_gasPrice Gwei',
          status: _rand.nextDouble() > 0.08 ? 'confirmed' : 'pending',
          time: 'jetzt',
        ));
        if (_liveTx.length > 20) _liveTx.removeLast();
      });
    });
  }

  String _randHex(int len) {
    const chars = '0123456789abcdef';
    return List.generate(len, (_) => chars[_rand.nextInt(16)]).join();
  }

  Future<void> _startDeploy() async {
    HapticFeedback.mediumImpact();
    setState(() { _isDeploying = true; _deployProgress = 0; _deployStatus = 'Kompiliere Contract...'; });
    final steps = [
      (0.15, 'Kompiliere Solidity...'),
      (0.30, 'ABI generieren...'),
      (0.45, 'Bytecode optimieren...'),
      (0.60, 'Signiere Transaktion...'),
      (0.75, 'Sende an Netzwerk...'),
      (0.88, 'Warte auf Bestätigung...'),
      (1.0,  'Deployment erfolgreich!'),
    ];
    for (final step in steps) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() { _deployProgress = step.$1; _deployStatus = step.$2; });
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() { _isDeploying = false; });
    _showDeploySuccess();
  }

  void _showDeploySuccess() {
    final p = context.read<ThemeProvider>().palette;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.check_circle_rounded, color: const Color(0xFF00FF88), size: 24),
          const SizedBox(width: 8),
          Text('Deployment erfolgreich', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 13)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _deployInfoRow('Contract', _selectedContract, p),
          _deployInfoRow('Netzwerk', _selectedNetwork, p),
          _deployInfoRow('Adresse', '0x${_randHex(4)}...${_randHex(4)}', p),
          _deployInfoRow('Gas', '\$${(_gasPrice * _gasLimit / 1e9 * _ethPrice).toStringAsFixed(2)}', p),
          _deployInfoRow('Block', '#${8400000 + _rand.nextInt(100000)}', p),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen', style: GoogleFonts.spaceMono(color: p.primary)),
          ),
        ],
      ),
    );
  }

  Widget _deployInfoRow(String label, String value, dynamic p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 10))),
        Expanded(child: Text(value, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 10))),
      ]),
    );
  }

  @override
  void dispose() {
    _tab.dispose(); _glowCtrl.dispose(); _pulseCtrl.dispose(); _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    // v34.0: Live ETH price für Gas-Kosten-Berechnungen
    final ethLive = context.watch<ExchangeService>().getPrice('ETH');
    if (ethLive > 0) _ethPrice = ethLive;
    return Scaffold(
      backgroundColor: p.background,
      body: Column(children: [
        _buildHeader(p),
        _buildTabBar(p),
        Expanded(child: TabBarView(controller: _tab, children: [
          _buildDeployView(p),
          _buildNetworkView(p),
          _buildLiveTxView(p),
          _buildHistoryView(p),
        ])),
      ]),
    );
  }

  Widget _buildHeader(dynamic p) {
    final net = _networks.firstWhere((n) => n['name'] == _selectedNetwork, orElse: () => _networks[0]);
    final netColor = net['color'] as Color;
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(bottom: BorderSide(color: netColor.withValues(alpha: 0.15 + _glowCtrl.value * 0.08))),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [netColor.withValues(alpha: 0.25), netColor.withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: netColor.withValues(alpha: 0.45 + _glowCtrl.value * 0.25)),
              boxShadow: [BoxShadow(color: netColor.withValues(alpha: 0.2 + _glowCtrl.value * 0.12), blurRadius: 14)],
            ),
            child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DEPLOY HUB', style: GoogleFonts.spaceMono(color: netColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
            Text('${net['name']} · Chain ID: ${net['chainId']} · Gas: $_gasPrice Gwei', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
          ])),
          // Gas Badge
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.local_gas_station_rounded, color: Color(0xFFFF6B35), size: 12),
                const SizedBox(width: 4),
                Text('$_gasPrice Gwei', style: GoogleFonts.spaceMono(color: const Color(0xFFFF6B35), fontSize: 10)),
              ]),
            ),
            const SizedBox(height: 2),
            Text('≈ \$${(_gasPrice * 200000 / 1e9 * _ethPrice).toStringAsFixed(2)} deploy', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
          ]),
        ]),
      ),
    );
  }

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
          Tab(icon: Icon(Icons.rocket_launch_outlined, size: 15), text: 'DEPLOY'),
          Tab(icon: Icon(Icons.account_tree_outlined, size: 15), text: 'NETZWERKE'),
          Tab(icon: Icon(Icons.compare_arrows_rounded, size: 15), text: 'LIVE TX'),
          Tab(icon: Icon(Icons.history_rounded, size: 15), text: 'VERLAUF'),
        ],
      ),
    );
  }

  // ── DEPLOY VIEW ──
  Widget _buildDeployView(dynamic p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        // Contract Selector
        _sectionHeader('CONTRACT TEMPLATE', Icons.code_rounded, const Color(0xFF00AAFF), p),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.8, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: _contracts.length,
          itemBuilder: (_, i) {
            final c = _contracts[i];
            final isSelected = _selectedContract == c['name'];
            final color = c['color'] as Color;
            return GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedContract = c['name'] as String); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.12) : p.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? color.withValues(alpha: 0.45) : p.primary.withValues(alpha: 0.1), width: isSelected ? 1.5 : 1),
                ),
                child: Row(children: [
                  Icon(c['icon'] as IconData, color: color, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(c['name'] as String, style: GoogleFonts.spaceMono(color: isSelected ? color : p.textPrimary, fontSize: 9, fontWeight: FontWeight.bold)),
                    Text(c['desc'] as String, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 8), overflow: TextOverflow.ellipsis),
                  ])),
                  if (c['audited'] == true)
                    Icon(Icons.verified_rounded, color: const Color(0xFF00FF88), size: 12),
                ]),
              ),
            );
          },
        ),
        const SizedBox(height: 14),

        // Network Selector
        _sectionHeader('ZIEL-NETZWERK', Icons.account_tree_outlined, const Color(0xFF00FF88), p),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.primary.withValues(alpha: 0.15)),
          ),
          child: DropdownButton<String>(
            value: _selectedNetwork,
            isExpanded: true,
            dropdownColor: p.surface,
            underline: const SizedBox(),
            style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 12),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: p.primary),
            items: _networks.map((n) => DropdownMenuItem(
              value: n['name'] as String,
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: n['color'] as Color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(n['name'] as String, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11)),
                const Spacer(),
                Text('${n['symbol']}', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
              ]),
            )).toList(),
            onChanged: (v) => setState(() => _selectedNetwork = v!),
          ),
        ),
        const SizedBox(height: 14),

        // Gas Settings
        _sectionHeader('GAS EINSTELLUNGEN', Icons.local_gas_station_rounded, const Color(0xFFFF6B35), p),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.primary.withValues(alpha: 0.1))),
          child: Column(children: [
            Row(children: [
              Text('Gas Price', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 11)),
              const Spacer(),
              Text('$_gasPrice Gwei', style: GoogleFonts.spaceMono(color: const Color(0xFFFF6B35), fontSize: 12)),
            ]),
            Slider(
              value: _gasPrice.toDouble(), min: 5, max: 200,
              activeColor: const Color(0xFFFF6B35),
              inactiveColor: const Color(0xFFFF6B35).withValues(alpha: 0.15),
              onChanged: (v) => setState(() => _gasPrice = v.toInt()),
            ),
            Row(children: [
              _gasPreset('Slow', 15, const Color(0xFF00FF88), p),
              const SizedBox(width: 6),
              _gasPreset('Standard', 24, const Color(0xFFFFD700), p),
              const SizedBox(width: 6),
              _gasPreset('Fast', 45, const Color(0xFFFF6B35), p),
              const SizedBox(width: 6),
              _gasPreset('Instant', 80, const Color(0xFFFF3358), p),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.info_outline_rounded, color: p.textSecondary, size: 12),
              const SizedBox(width: 6),
              Text('Geschätzte Kosten: \$${(_gasPrice * _gasLimit / 1e9 * _ethPrice).toStringAsFixed(2)} · ~${(_gasPrice < 20 ? '3-5 min' : _gasPrice < 40 ? '30-60s' : '<15s')}', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
            ]),
          ]),
        ),
        const SizedBox(height: 14),

        // Deploy Progress
        if (_isDeploying) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.primary.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              Row(children: [
                AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) => Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: const Color(0xFF00FF88), shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF00FF88).withValues(alpha: 0.5 + _pulseCtrl.value * 0.4), blurRadius: 6)]),
                )),
                const SizedBox(width: 8),
                Text(_deployStatus, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11)),
                const Spacer(),
                Text('${(_deployProgress * 100).toInt()}%', style: GoogleFonts.spaceMono(color: p.primary, fontSize: 11)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _deployProgress,
                  backgroundColor: p.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(p.primary),
                  minHeight: 8,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
        ],

        // Deploy Button
        GestureDetector(
          onTap: _isDeploying ? null : _startDeploy,
          child: AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) => Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: _isDeploying
                    ? LinearGradient(colors: [p.surfaceVariant, p.surfaceVariant])
                    : LinearGradient(colors: [p.primary, const Color(0xFF00AAFF)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isDeploying ? [] : [BoxShadow(color: p.primary.withValues(alpha: 0.3 + _glowCtrl.value * 0.2), blurRadius: 16, spreadRadius: 1)],
              ),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_isDeploying ? Icons.hourglass_empty_rounded : Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(_isDeploying ? 'DEPLOYING...' : 'CONTRACT DEPLOYEN', style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              ])),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _gasPreset(String label, int gwei, Color color, dynamic p) {
    final isSelected = _gasPrice == gwei;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _gasPrice = gwei),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : p.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? color.withValues(alpha: 0.4) : Colors.transparent),
        ),
        child: Column(children: [
          Text(label, style: GoogleFonts.spaceMono(color: isSelected ? color : p.textSecondary, fontSize: 9)),
          Text('$gwei G', style: GoogleFonts.spaceMono(color: isSelected ? color : p.textSecondary, fontSize: 8)),
        ]),
      ),
    ));
  }

  Widget _sectionHeader(String title, IconData icon, Color color, dynamic p) {
    return Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 6),
      Text(title, style: GoogleFonts.spaceMono(color: color, fontSize: 10, letterSpacing: 1.5)),
    ]);
  }

  // ── NETWORK VIEW ──
  Widget _buildNetworkView(dynamic p) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _networks.length,
      itemBuilder: (_, i) {
        final net = _networks[i];
        final color = net['color'] as Color;
        final isSelected = _selectedNetwork == net['name'];
        return GestureDetector(
          onTap: () { setState(() => _selectedNetwork = net['name'] as String); _tab.animateTo(0); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.08) : p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? color.withValues(alpha: 0.4) : p.primary.withValues(alpha: 0.1), width: isSelected ? 1.5 : 1),
            ),
            child: Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(net['name'] as String, style: GoogleFonts.spaceMono(color: isSelected ? color : p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('ID:${net['chainId']}', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
                ]),
                const SizedBox(height: 3),
                Text('${net['rpc']}', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 10)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${net['symbol']}', style: GoogleFonts.spaceMono(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                Text('${net['gas']} Gwei', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
              ]),
            ]),
          ),
        );
      },
    );
  }

  // ── LIVE TX VIEW ──
  Widget _buildLiveTxView(dynamic p) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: p.surface,
        child: Row(children: [
          AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) => Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF00FF88), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF00FF88).withValues(alpha: 0.6 + _pulseCtrl.value * 0.3), blurRadius: 6)]))),
          const SizedBox(width: 8),
          Text('LIVE MEMPOOL', style: GoogleFonts.spaceMono(color: const Color(0xFF00FF88), fontSize: 11, letterSpacing: 1.5)),
          const Spacer(),
          Text('Gas: $_gasPrice Gwei', style: GoogleFonts.spaceMono(color: const Color(0xFFFF6B35), fontSize: 10)),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _liveTx.length,
          itemBuilder: (_, i) {
            final tx = _liveTx[i];
            final isConfirmed = tx.status == 'confirmed';
            final color = isConfirmed ? const Color(0xFF00FF88) : const Color(0xFFFFD700);
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.12)),
              ),
              child: Row(children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tx.hash, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 10)),
                  Text('${tx.type} · ${tx.value}', style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(tx.gas, style: GoogleFonts.spaceMono(color: const Color(0xFFFF6B35), fontSize: 9)),
                  Text(tx.time, style: GoogleFonts.inter(color: p.textSecondary.withValues(alpha: 0.5), fontSize: 8)),
                ]),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  // ── HISTORY VIEW ──
  Widget _buildHistoryView(dynamic p) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sectionHeader('DEPLOYMENT VERLAUF', Icons.history_rounded, p.primary, p),
        const SizedBox(height: 10),
        ..._deployments.map((d) {
          final statusColor = d['status'] == 'success' ? const Color(0xFF00FF88) : d['status'] == 'pending' ? const Color(0xFFFFD700) : const Color(0xFFFF3358);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.primary.withValues(alpha: 0.1))),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.4), blurRadius: 4)])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['name'] as String, style: GoogleFonts.spaceMono(color: p.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                Text('${d['network']} · ${d['address']} · Block: ${d['block']}', style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(d['gas'] as String, style: GoogleFonts.spaceMono(color: p.primary, fontSize: 10)),
                Text(d['time'] as String, style: GoogleFonts.inter(color: p.textSecondary, fontSize: 9)),
              ]),
            ]),
          );
        }),
      ],
    );
  }
}

class _TxEntry {
  final String hash, type, value, gas, status, time;
  const _TxEntry({required this.hash, required this.type, required this.value, required this.gas, required this.status, required this.time});
}
