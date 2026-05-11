// ════════════════════════════════════════════════════════════════════════════
// CRYPTO ICON WIDGET SYSTEM  v23.0
// Quantum Trader AI — Professional coin/token logo integration
// Sources: CoinGecko CDN (primary) + Fallback gradient avatars
// ════════════════════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COIN METADATA DATABASE
// ─────────────────────────────────────────────────────────────────────────────

class CoinMeta {
  final String id;          // CoinGecko ID
  final String symbol;      // Ticker symbol
  final String name;        // Full name
  final Color primary;      // Brand color
  final Color secondary;    // Secondary brand color
  final String? customUrl;  // Override URL if needed

  const CoinMeta({
    required this.id,
    required this.symbol,
    required this.name,
    required this.primary,
    required this.secondary,
    this.customUrl,
  });

  /// CoinGecko large logo URL (128x128 PNG)
  String get logoUrl =>
      customUrl ?? 'https://assets.coingecko.com/coins/images/$_geckoImageId/large/$_geckoFilename';

  /// CoinGecko thumb URL (50x50)
  String get thumbUrl =>
      'https://assets.coingecko.com/coins/images/$_geckoImageId/thumb/$_geckoFilename';

  String get _geckoImageId => _geckoIds[id] ?? '1';
  String get _geckoFilename => _geckoFiles[id] ?? '$id.png';

  // CoinGecko image IDs & filenames (verified correct)
  static const Map<String, String> _geckoIds = {
    'bitcoin':          '1',
    'ethereum':         '279',
    'tether':           '325',
    'binancecoin':      '825',
    'solana':           '4128',
    'usd-coin':         '6319',
    'xrp':              '44',
    'staked-ether':     '13442',
    'cardano':          '975',
    'avalanche-2':      '12559',
    'dogecoin':         '5',
    'polkadot':         '12171',
    'chainlink':        '877',
    'tron':             '1094',
    'shiba-inu':        '11939',
    'polygon':          '4713',
    'litecoin':         '2',
    'bitcoin-cash':     '780',
    'stellar':          '100',
    'monero':           '69',
    'ethereum-classic': '453',
    'cosmos':           '1481',
    'uniswap':          '12504',
    'aave':             '7279',
    'maker':            '1364',
    'compound-ether':   '629',
    'filecoin':         '12817',
    'internet-computer':'8916',
    'near':             '10365',
    'algorand':         '4030',
    'vechain':          '3077',
    'aptos':            '26455',
    'arbitrum':         '16547',
    'optimism':         '25244',
    'the-sandbox':      '12129',
    'decentraland':     '1966',
    'axie-infinity':    '8945',
    'the-graph':        '7483',
    'fantom':           '4001',
    'injective-protocol':'7226',
    'render-token':     '11636',
    'fetch-ai':         '3406',
    'ocean-protocol':   '3687',
    'hedera':           '4642',
    'flow':             '4558',
    'eos':              '738',
    'tezos':            '1163',
    'theta-token':      '2538',
    'elrond-erd-2':     '6892',
    'iota':             '1303',
  };

  static const Map<String, String> _geckoFiles = {
    'bitcoin':          'bitcoin.png',
    'ethereum':         'ethereum.png',
    'tether':           'tether.png',
    'binancecoin':      'bnb-icon2_2x.png',
    'solana':           'solana.png',
    'usd-coin':         'usd-coin-usdc-logo.png',
    'xrp':              'ripple-xrp-logo.png',
    'staked-ether':     'lido-staked-ether.png',
    'cardano':          'cardano.png',
    'avalanche-2':      'avalanche-avax-logo.png',
    'dogecoin':         'dogecoin.png',
    'polkadot':         'polkadot.png',
    'chainlink':        'chainlink-new-logo.png',
    'tron':             'tron-logo.png',
    'shiba-inu':        'shiba-inu-grypto.png',
    'polygon':          'polygon-matic-logo.png',
    'litecoin':         'litecoin.png',
    'bitcoin-cash':     'bitcoin-cash.png',
    'stellar':          'stellar_std.png',
    'monero':           'monero_logo.png',
    'ethereum-classic': 'ethereum_classic_square_logo_(256x256).png',
    'cosmos':           'cosmos_hub.png',
    'uniswap':          'uniswap-v3.png',
    'aave':             'aave-logo.png',
    'maker':            'dai.png',
    'filecoin':         'filecoin-fil-logo.png',
    'near':             'near-protocol-near-logo.png',
    'algorand':         'algorand_logo_mark_black.png',
    'vechain':          'vechain-logo.png',
    'aptos':            'aptos-apt-logo.png',
    'arbitrum':         'arbitrum.png',
    'optimism':         'optimism.png',
    'the-sandbox':      'sandbox.png',
    'decentraland':     'decentraland-mana.png',
    'axie-infinity':    'axie-infinity.png',
    'the-graph':        'the-graph.png',
    'fantom':           'fantom.png',
    'injective-protocol':'injective-protocol.png',
    'hedera':           'hbar.png',
    'flow':             'flow.png',
    'eos':              'eos-eos-logo.png',
    'tezos':            'tezos-logo.png',
    'theta-token':      'theta-token-logo.png',
    'iota':             'iota_logo.png',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// MASTER COIN REGISTRY
// ─────────────────────────────────────────────────────────────────────────────

class CryptoRegistry {
  static const Map<String, CoinMeta> _coins = {
    'BTC': CoinMeta(id: 'bitcoin',           symbol: 'BTC',   name: 'Bitcoin',          primary: Color(0xFFF7931A), secondary: Color(0xFFFFB84D)),
    'ETH': CoinMeta(id: 'ethereum',          symbol: 'ETH',   name: 'Ethereum',         primary: Color(0xFF627EEA), secondary: Color(0xFF8FA8FF)),
    'USDT':CoinMeta(id: 'tether',            symbol: 'USDT',  name: 'Tether',           primary: Color(0xFF26A17B), secondary: Color(0xFF4ECFA6)),
    'BNB': CoinMeta(id: 'binancecoin',       symbol: 'BNB',   name: 'BNB',              primary: Color(0xFFF3BA2F), secondary: Color(0xFFFFD84D)),
    'SOL': CoinMeta(id: 'solana',            symbol: 'SOL',   name: 'Solana',           primary: Color(0xFF9945FF), secondary: Color(0xFF14F195)),
    'USDC':CoinMeta(id: 'usd-coin',          symbol: 'USDC',  name: 'USD Coin',         primary: Color(0xFF2775CA), secondary: Color(0xFF4A9DE8)),
    'XRP': CoinMeta(id: 'xrp',              symbol: 'XRP',   name: 'XRP',              primary: Color(0xFF00AAE4), secondary: Color(0xFF4DC8F4)),
    'ADA': CoinMeta(id: 'cardano',           symbol: 'ADA',   name: 'Cardano',          primary: Color(0xFF0033AD), secondary: Color(0xFF4A7EFF)),
    'AVAX':CoinMeta(id: 'avalanche-2',       symbol: 'AVAX',  name: 'Avalanche',        primary: Color(0xFFE84142), secondary: Color(0xFFFF7172)),
    'DOGE':CoinMeta(id: 'dogecoin',          symbol: 'DOGE',  name: 'Dogecoin',         primary: Color(0xFFC2A633), secondary: Color(0xFFE8CC5A)),
    'DOT': CoinMeta(id: 'polkadot',          symbol: 'DOT',   name: 'Polkadot',         primary: Color(0xFFE6007A), secondary: Color(0xFFFF4AB5)),
    'LINK':CoinMeta(id: 'chainlink',         symbol: 'LINK',  name: 'Chainlink',        primary: Color(0xFF2A5ADA), secondary: Color(0xFF5080FF)),
    'TRX': CoinMeta(id: 'tron',              symbol: 'TRX',   name: 'TRON',             primary: Color(0xFFEF0027), secondary: Color(0xFFFF3355)),
    'SHIB':CoinMeta(id: 'shiba-inu',         symbol: 'SHIB',  name: 'Shiba Inu',        primary: Color(0xFFFF6300), secondary: Color(0xFFFF9040)),
    'MATIC':CoinMeta(id: 'polygon',          symbol: 'MATIC', name: 'Polygon',          primary: Color(0xFF8247E5), secondary: Color(0xFFAA78FF)),
    'LTC': CoinMeta(id: 'litecoin',          symbol: 'LTC',   name: 'Litecoin',         primary: Color(0xFF345D9D), secondary: Color(0xFF5B89D4)),
    'BCH': CoinMeta(id: 'bitcoin-cash',      symbol: 'BCH',   name: 'Bitcoin Cash',     primary: Color(0xFF8DC351), secondary: Color(0xFFB4E878)),
    'XLM': CoinMeta(id: 'stellar',           symbol: 'XLM',   name: 'Stellar',          primary: Color(0xFF14B6E7), secondary: Color(0xFF3DD4FF)),
    'XMR': CoinMeta(id: 'monero',            symbol: 'XMR',   name: 'Monero',           primary: Color(0xFFFF6600), secondary: Color(0xFFFF9940)),
    'ETC': CoinMeta(id: 'ethereum-classic',  symbol: 'ETC',   name: 'Ethereum Classic', primary: Color(0xFF3DB34A), secondary: Color(0xFF5EE06C)),
    'ATOM':CoinMeta(id: 'cosmos',            symbol: 'ATOM',  name: 'Cosmos',           primary: Color(0xFF2E3148), secondary: Color(0xFF6F74A8)),
    'UNI': CoinMeta(id: 'uniswap',           symbol: 'UNI',   name: 'Uniswap',          primary: Color(0xFFFF007A), secondary: Color(0xFFFF5CA8)),
    'AAVE':CoinMeta(id: 'aave',              symbol: 'AAVE',  name: 'Aave',             primary: Color(0xFF2EBAC6), secondary: Color(0xFF50E0EC)),
    'FIL': CoinMeta(id: 'filecoin',          symbol: 'FIL',   name: 'Filecoin',         primary: Color(0xFF0090FF), secondary: Color(0xFF40B8FF)),
    'NEAR':CoinMeta(id: 'near',              symbol: 'NEAR',  name: 'NEAR Protocol',    primary: Color(0xFF000000), secondary: Color(0xFF404040)),
    'ALGO':CoinMeta(id: 'algorand',          symbol: 'ALGO',  name: 'Algorand',         primary: Color(0xFF000000), secondary: Color(0xFF555555)),
    'VET': CoinMeta(id: 'vechain',           symbol: 'VET',   name: 'VeChain',          primary: Color(0xFF15BDFF), secondary: Color(0xFF4BCFFF)),
    'APT': CoinMeta(id: 'aptos',             symbol: 'APT',   name: 'Aptos',            primary: Color(0xFF33B8B8), secondary: Color(0xFF5CEDED)),
    'ARB': CoinMeta(id: 'arbitrum',          symbol: 'ARB',   name: 'Arbitrum',         primary: Color(0xFF28A0F0), secondary: Color(0xFF60C8FF)),
    'OP':  CoinMeta(id: 'optimism',          symbol: 'OP',    name: 'Optimism',         primary: Color(0xFFFF0420), secondary: Color(0xFFFF4455)),
    'SAND':CoinMeta(id: 'the-sandbox',       symbol: 'SAND',  name: 'The Sandbox',      primary: Color(0xFF04ADEF), secondary: Color(0xFF3DCDFF)),
    'MANA':CoinMeta(id: 'decentraland',      symbol: 'MANA',  name: 'Decentraland',     primary: Color(0xFFFF2D55), secondary: Color(0xFFFF6882)),
    'AXS': CoinMeta(id: 'axie-infinity',     symbol: 'AXS',   name: 'Axie Infinity',    primary: Color(0xFF0055D5), secondary: Color(0xFF3380FF)),
    'GRT': CoinMeta(id: 'the-graph',         symbol: 'GRT',   name: 'The Graph',        primary: Color(0xFF6747ED), secondary: Color(0xFF9580FF)),
    'FTM': CoinMeta(id: 'fantom',            symbol: 'FTM',   name: 'Fantom',           primary: Color(0xFF1969FF), secondary: Color(0xFF4D8EFF)),
    'INJ': CoinMeta(id: 'injective-protocol',symbol: 'INJ',   name: 'Injective',        primary: Color(0xFF00BAFF), secondary: Color(0xFF40D4FF)),
    'HBAR':CoinMeta(id: 'hedera',            symbol: 'HBAR',  name: 'Hedera',           primary: Color(0xFF222222), secondary: Color(0xFF444444)),
    'FLOW':CoinMeta(id: 'flow',              symbol: 'FLOW',  name: 'Flow',             primary: Color(0xFF16FF99), secondary: Color(0xFF00D4A0)),
    'EOS': CoinMeta(id: 'eos',              symbol: 'EOS',   name: 'EOS',              primary: Color(0xFF000000), secondary: Color(0xFF333333)),
    'XTZ': CoinMeta(id: 'tezos',             symbol: 'XTZ',   name: 'Tezos',            primary: Color(0xFF2C7DF7), secondary: Color(0xFF5B9FFF)),
    'THETA':CoinMeta(id: 'theta-token',      symbol: 'THETA', name: 'Theta Network',    primary: Color(0xFF2AB8E6), secondary: Color(0xFF5DD4FF)),
    'IOTA':CoinMeta(id: 'iota',              symbol: 'IOTA',  name: 'IOTA',             primary: Color(0xFF131F37), secondary: Color(0xFF2B3F6B)),
    'RENDER':CoinMeta(id: 'render-token',    symbol: 'RENDER',name: 'Render',           primary: Color(0xFF3A6BE4), secondary: Color(0xFF6A9BFF)),
    'FET': CoinMeta(id: 'fetch-ai',          symbol: 'FET',   name: 'Fetch.ai',         primary: Color(0xFF1A1F71), secondary: Color(0xFF3B44A8)),
    'OCEAN':CoinMeta(id: 'ocean-protocol',   symbol: 'OCEAN', name: 'Ocean Protocol',   primary: Color(0xFF141414), secondary: Color(0xFF1B8EF0)),
  };

  static CoinMeta? get(String symbol) =>
      _coins[symbol.toUpperCase()] ?? _coins[symbol.toLowerCase()];

  static CoinMeta getOrFallback(String symbol) {
    return _coins[symbol.toUpperCase()] ??
        CoinMeta(
          id: symbol.toLowerCase(),
          symbol: symbol.toUpperCase(),
          name: symbol,
          primary: _generateColor(symbol),
          secondary: _generateColor(symbol + symbol),
        );
  }

  static Color _generateColor(String seed) {
    final hash = seed.codeUnits.fold(0, (h, c) => (h * 31 + c) & 0xFFFFFF);
    return Color(0xFF000000 | hash).withValues(alpha: 1.0);
  }

  static List<CoinMeta> get all => _coins.values.toList();
  static List<String> get allSymbols => _coins.keys.toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// CRYPTO ICON WIDGET — Primary widget to use everywhere
// ─────────────────────────────────────────────────────────────────────────────

class CryptoIcon extends StatelessWidget {
  final String symbol;
  final double size;
  final double borderWidth;
  final bool showBorder;
  final bool showShadow;
  final Color? borderColor;
  final BoxShape shape;

  const CryptoIcon(
    this.symbol, {
    super.key,
    this.size = 40,
    this.borderWidth = 1.5,
    this.showBorder = true,
    this.showShadow = false,
    this.borderColor,
    this.shape = BoxShape.circle,
  });

  @override
  Widget build(BuildContext context) {
    final meta = CryptoRegistry.getOrFallback(symbol);
    final borderC = borderColor ?? meta.primary.withValues(alpha: 0.5);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: shape,
        border: showBorder ? Border.all(color: borderC, width: borderWidth) : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: meta.primary.withValues(alpha: 0.4),
                  blurRadius: size * 0.4,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImage(meta),
    );
  }

  Widget _buildImage(CoinMeta meta) {
    return CachedNetworkImage(
      imageUrl: meta.logoUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (_, __) => _fallbackAvatar(meta, size * 0.55),
      errorWidget: (_, __, ___) => _buildFallbackDirect(meta),
    );
  }

  Widget _buildFallbackDirect(CoinMeta meta) {
    return CachedNetworkImage(
      imageUrl: meta.thumbUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (_, __) => _fallbackAvatar(meta, size * 0.55),
      errorWidget: (_, __, ___) => _fallbackAvatar(meta, size * 0.42),
    );
  }
}

Widget _fallbackAvatar(CoinMeta meta, double fontSize) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [meta.primary, meta.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(
        meta.symbol.length > 4
            ? meta.symbol.substring(0, 4)
            : meta.symbol.length > 2
                ? meta.symbol.substring(0, min(3, meta.symbol.length))
                : meta.symbol,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CRYPTO ICON WITH LABEL — Shows icon + symbol + optional name
// ─────────────────────────────────────────────────────────────────────────────

class CryptoIconLabel extends StatelessWidget {
  final String symbol;
  final double iconSize;
  final bool showName;
  final TextStyle? symbolStyle;
  final TextStyle? nameStyle;
  final double spacing;

  const CryptoIconLabel(
    this.symbol, {
    super.key,
    this.iconSize = 36,
    this.showName = true,
    this.symbolStyle,
    this.nameStyle,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    final meta = CryptoRegistry.getOrFallback(symbol);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CryptoIcon(symbol, size: iconSize),
        SizedBox(width: spacing),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              meta.symbol,
              style: symbolStyle ??
                  TextStyle(
                    color: Colors.white,
                    fontSize: iconSize * 0.35,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    fontFamily: 'SpaceMono',
                  ),
            ),
            if (showName)
              Text(
                meta.name,
                style: nameStyle ??
                    TextStyle(
                      color: Colors.grey[400],
                      fontSize: iconSize * 0.25,
                    ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CRYPTO ICON STACK — Overlapping icons (for pairs like BTC/ETH)
// ─────────────────────────────────────────────────────────────────────────────

class CryptoIconPair extends StatelessWidget {
  final String base;
  final String quote;
  final double size;

  const CryptoIconPair(this.base, this.quote, {super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.5,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: CryptoIcon(base, size: size, showShadow: false),
          ),
          Positioned(
            left: size * 0.5,
            child: CryptoIcon(quote, size: size * 0.75,
                borderColor: Colors.black, borderWidth: 2),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CRYPTO BADGE — Compact icon with glow for active/highlighted state
// ─────────────────────────────────────────────────────────────────────────────

class CryptoBadge extends StatelessWidget {
  final String symbol;
  final double size;
  final bool active;
  final VoidCallback? onTap;

  const CryptoBadge(
    this.symbol, {
    super.key,
    this.size = 48,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = CryptoRegistry.getOrFallback(symbol);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: active
                ? meta.primary
                : meta.primary.withValues(alpha: 0.25),
            width: active ? 2.5 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: meta.primary.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : null,
          color: meta.primary.withValues(alpha: active ? 0.12 : 0.05),
        ),
        child: CryptoIcon(symbol, size: size - 8, showBorder: false),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CRYPTO SELECTOR CHIP — Horizontal scrollable coin selector
// ─────────────────────────────────────────────────────────────────────────────

class CryptoSelectorStrip extends StatelessWidget {
  final List<String> symbols;
  final String selected;
  final ValueChanged<String> onSelected;
  final double height;

  const CryptoSelectorStrip({
    super.key,
    required this.symbols,
    required this.selected,
    required this.onSelected,
    this.height = 72,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: symbols.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sym = symbols[i];
          final isSelected = sym == selected;
          final meta = CryptoRegistry.getOrFallback(sym);
          return GestureDetector(
            onTap: () => onSelected(sym),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? meta.primary.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? meta.primary
                      : Colors.white.withValues(alpha: 0.08),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: meta.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          spreadRadius: 0,
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CryptoIcon(sym, size: 28, showBorder: false),
                  const SizedBox(width: 7),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.symbol,
                        style: TextStyle(
                          color: isSelected ? meta.primary : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SpaceMono',
                        ),
                      ),
                      Text(
                        meta.name.length > 10
                            ? '${meta.name.substring(0, 9)}…'
                            : meta.name,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COIN PRICE ROW — Full-width market list row with icon
// ─────────────────────────────────────────────────────────────────────────────

class CoinPriceRow extends StatelessWidget {
  final String symbol;
  final double price;
  final double change24h;
  final double? volume;
  final double? marketCap;
  final int? rank;
  final VoidCallback? onTap;
  final bool compact;

  const CoinPriceRow({
    super.key,
    required this.symbol,
    required this.price,
    required this.change24h,
    this.volume,
    this.marketCap,
    this.rank,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final meta = CryptoRegistry.getOrFallback(symbol);
    final isUp = change24h >= 0;
    final changeColor = isUp ? const Color(0xFF00C896) : const Color(0xFFFF3355);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: compact ? 8 : 12,
        ),
        child: Row(
          children: [
            // Rank
            if (rank != null) ...[
              SizedBox(
                width: 24,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Icon
            CryptoIcon(symbol, size: compact ? 34 : 42, showShadow: false),
            const SizedBox(width: 12),
            // Name & Symbol
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.symbol,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                  Text(
                    meta.name,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: compact ? 9 : 11,
                    ),
                  ),
                ],
              ),
            ),
            // Volume (optional)
            if (volume != null && !compact) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatVolume(volume!),
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  ),
                  Text('24h Vol', style: TextStyle(color: Colors.grey[600], fontSize: 8)),
                ],
              ),
              const SizedBox(width: 14),
            ],
            // Price & Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatPrice(price),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SpaceMono',
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${isUp ? '+' : ''}${change24h.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: changeColor,
                      fontSize: compact ? 9 : 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double p) {
    if (p >= 10000) return '\$${(p / 1000).toStringAsFixed(1)}K';
    if (p >= 1) return '\$${p.toStringAsFixed(2)}';
    if (p >= 0.01) return '\$${p.toStringAsFixed(4)}';
    return '\$${p.toStringAsFixed(6)}';
  }

  String _formatVolume(double v) {
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(0)}M';
    return '\$${(v / 1e3).toStringAsFixed(0)}K';
  }
}
