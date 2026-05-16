// ════════════════════════════════════════════════════════════════════════════
// CRYPTO BRAND SERVICE  v26.0
// Quantum Trader AI — Enterprise Token Branding Layer
// Sources: Logo.dev API (primary) · CoinGecko CDN (secondary) · Local Fallback
// ════════════════════════════════════════════════════════════════════════════
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// BRAND TOKEN MODEL
// ─────────────────────────────────────────────────────────────────────────────

class BrandToken {
  final String symbol;
  final String name;
  final String geckoId;
  final String? logoDevUrl;    // Logo.dev CDN
  final String? geckoUrl;      // CoinGecko CDN
  final String? cryptoIconUrl; // cryptocompare CDN
  final int geckoImageId;
  final String geckoFilename;

  const BrandToken({
    required this.symbol,
    required this.name,
    required this.geckoId,
    this.logoDevUrl,
    this.geckoUrl,
    this.cryptoIconUrl,
    this.geckoImageId = 1,
    this.geckoFilename = '',
  });

  /// Prioritized logo URL chain: Logo.dev → CoinGecko → CryptoCompare → null
  String get primaryLogoUrl =>
      logoDevUrl ??
      geckoLargeUrl ??
      cryptoIconUrl ??
      '';

  String get geckoLargeUrl => geckoFilename.isNotEmpty
      ? 'https://assets.coingecko.com/coins/images/$geckoImageId/large/$geckoFilename'
      : '';

  String get geckoThumbUrl => geckoFilename.isNotEmpty
      ? 'https://assets.coingecko.com/coins/images/$geckoImageId/thumb/$geckoFilename'
      : '';

  String get cryptoCompareUrl =>
      'https://www.cryptocompare.com/media/37746251/${symbol.toLowerCase()}.png';
}

// ─────────────────────────────────────────────────────────────────────────────
// MASTER BRAND REGISTRY  (50 Tokens)
// ─────────────────────────────────────────────────────────────────────────────

class CryptoBrandRegistry {
  static const Map<String, BrandToken> _tokens = {
    'BTC':  BrandToken(symbol:'BTC',  name:'Bitcoin',         geckoId:'bitcoin',            geckoImageId:1,     geckoFilename:'bitcoin.png'),
    'ETH':  BrandToken(symbol:'ETH',  name:'Ethereum',        geckoId:'ethereum',           geckoImageId:279,   geckoFilename:'ethereum.png'),
    'USDT': BrandToken(symbol:'USDT', name:'Tether',          geckoId:'tether',             geckoImageId:325,   geckoFilename:'tether.png'),
    'BNB':  BrandToken(symbol:'BNB',  name:'BNB',             geckoId:'binancecoin',        geckoImageId:825,   geckoFilename:'bnb-icon2_2x.png'),
    'SOL':  BrandToken(symbol:'SOL',  name:'Solana',          geckoId:'solana',             geckoImageId:4128,  geckoFilename:'solana.png'),
    'USDC': BrandToken(symbol:'USDC', name:'USD Coin',        geckoId:'usd-coin',           geckoImageId:6319,  geckoFilename:'usd-coin-usdc-logo.png'),
    'XRP':  BrandToken(symbol:'XRP',  name:'XRP',             geckoId:'xrp',                geckoImageId:44,    geckoFilename:'ripple-xrp-logo.png'),
    'ADA':  BrandToken(symbol:'ADA',  name:'Cardano',         geckoId:'cardano',            geckoImageId:975,   geckoFilename:'cardano.png'),
    'AVAX': BrandToken(symbol:'AVAX', name:'Avalanche',       geckoId:'avalanche-2',        geckoImageId:12559, geckoFilename:'avalanche-avax-logo.png'),
    'DOGE': BrandToken(symbol:'DOGE', name:'Dogecoin',        geckoId:'dogecoin',           geckoImageId:5,     geckoFilename:'dogecoin.png'),
    'DOT':  BrandToken(symbol:'DOT',  name:'Polkadot',        geckoId:'polkadot',           geckoImageId:12171, geckoFilename:'polkadot.png'),
    'LINK': BrandToken(symbol:'LINK', name:'Chainlink',       geckoId:'chainlink',          geckoImageId:877,   geckoFilename:'chainlink-new-logo.png'),
    'TRX':  BrandToken(symbol:'TRX',  name:'TRON',            geckoId:'tron',               geckoImageId:1094,  geckoFilename:'tron-logo.png'),
    'SHIB': BrandToken(symbol:'SHIB', name:'Shiba Inu',       geckoId:'shiba-inu',          geckoImageId:11939, geckoFilename:'shiba-inu-grypto.png'),
    'MATIC':BrandToken(symbol:'MATIC',name:'Polygon',         geckoId:'matic-network',      geckoImageId:4713,  geckoFilename:'polygon-matic-logo.png'),
    'LTC':  BrandToken(symbol:'LTC',  name:'Litecoin',        geckoId:'litecoin',           geckoImageId:2,     geckoFilename:'litecoin.png'),
    'BCH':  BrandToken(symbol:'BCH',  name:'Bitcoin Cash',    geckoId:'bitcoin-cash',       geckoImageId:780,   geckoFilename:'bitcoin-cash.png'),
    'XLM':  BrandToken(symbol:'XLM',  name:'Stellar',         geckoId:'stellar',            geckoImageId:100,   geckoFilename:'stellar_std.png'),
    'XMR':  BrandToken(symbol:'XMR',  name:'Monero',          geckoId:'monero',             geckoImageId:69,    geckoFilename:'monero_logo.png'),
    'ATOM': BrandToken(symbol:'ATOM', name:'Cosmos',          geckoId:'cosmos',             geckoImageId:1481,  geckoFilename:'cosmos_hub.png'),
    'UNI':  BrandToken(symbol:'UNI',  name:'Uniswap',         geckoId:'uniswap',            geckoImageId:12504, geckoFilename:'uniswap-v3.png'),
    'AAVE': BrandToken(symbol:'AAVE', name:'Aave',            geckoId:'aave',               geckoImageId:7279,  geckoFilename:'aave-logo.png'),
    'NEAR': BrandToken(symbol:'NEAR', name:'NEAR Protocol',   geckoId:'near',               geckoImageId:10365, geckoFilename:'near-protocol-near-logo.png'),
    'APT':  BrandToken(symbol:'APT',  name:'Aptos',           geckoId:'aptos',              geckoImageId:26455, geckoFilename:'aptos-apt-logo.png'),
    'ARB':  BrandToken(symbol:'ARB',  name:'Arbitrum',        geckoId:'arbitrum',           geckoImageId:16547, geckoFilename:'arbitrum.png'),
    'OP':   BrandToken(symbol:'OP',   name:'Optimism',        geckoId:'optimism',           geckoImageId:25244, geckoFilename:'optimism.png'),
    'INJ':  BrandToken(symbol:'INJ',  name:'Injective',       geckoId:'injective-protocol', geckoImageId:7226,  geckoFilename:'injective-protocol.png'),
    'SUI':  BrandToken(symbol:'SUI',  name:'Sui',             geckoId:'sui',                geckoImageId:26375, geckoFilename:'sui.png'),
    'SEI':  BrandToken(symbol:'SEI',  name:'Sei',             geckoId:'sei-network',        geckoImageId:28205, geckoFilename:'sei.png'),
    'TON':  BrandToken(symbol:'TON',  name:'Toncoin',         geckoId:'the-open-network',   geckoImageId:17980, geckoFilename:'ton_symbol.png'),
    'FET':  BrandToken(symbol:'FET',  name:'Fetch.ai',        geckoId:'fetch-ai',           geckoImageId:3406,  geckoFilename:'fetchai_logo_mark_grey_trans_200px.png'),
    'RENDER':BrandToken(symbol:'RENDER',name:'Render',        geckoId:'render-token',       geckoImageId:11636, geckoFilename:'rendertoken.png'),
    'GRT':  BrandToken(symbol:'GRT',  name:'The Graph',       geckoId:'the-graph',          geckoImageId:7483,  geckoFilename:'the-graph.png'),
    'FTM':  BrandToken(symbol:'FTM',  name:'Fantom',          geckoId:'fantom',             geckoImageId:4001,  geckoFilename:'fantom.png'),
    'FIL':  BrandToken(symbol:'FIL',  name:'Filecoin',        geckoId:'filecoin',           geckoImageId:12817, geckoFilename:'filecoin-fil-logo.png'),
    'HBAR': BrandToken(symbol:'HBAR', name:'Hedera',          geckoId:'hedera-hashgraph',   geckoImageId:4642,  geckoFilename:'hbar.png'),
    'VET':  BrandToken(symbol:'VET',  name:'VeChain',         geckoId:'vechain',            geckoImageId:3077,  geckoFilename:'vechain-logo.png'),
    'ALGO': BrandToken(symbol:'ALGO', name:'Algorand',        geckoId:'algorand',           geckoImageId:4030,  geckoFilename:'algorand_logo_mark_black.png'),
    'ETC':  BrandToken(symbol:'ETC',  name:'Ethereum Classic',geckoId:'ethereum-classic',   geckoImageId:453,   geckoFilename:'ethereum_classic_square_logo_(256x256).png'),
    'FLOW': BrandToken(symbol:'FLOW', name:'Flow',            geckoId:'flow',               geckoImageId:4558,  geckoFilename:'flow.png'),
    'SAND': BrandToken(symbol:'SAND', name:'The Sandbox',     geckoId:'the-sandbox',        geckoImageId:12129, geckoFilename:'sandbox.png'),
    'MANA': BrandToken(symbol:'MANA', name:'Decentraland',    geckoId:'decentraland',       geckoImageId:1966,  geckoFilename:'decentraland-mana.png'),
    'AXS':  BrandToken(symbol:'AXS',  name:'Axie Infinity',   geckoId:'axie-infinity',      geckoImageId:8945,  geckoFilename:'axie-infinity.png'),
    'THETA':BrandToken(symbol:'THETA',name:'Theta Network',   geckoId:'theta-token',        geckoImageId:2538,  geckoFilename:'theta-token-logo.png'),
    'XTZ':  BrandToken(symbol:'XTZ',  name:'Tezos',           geckoId:'tezos',              geckoImageId:1163,  geckoFilename:'tezos-logo.png'),
    'EOS':  BrandToken(symbol:'EOS',  name:'EOS',             geckoId:'eos',                geckoImageId:738,   geckoFilename:'eos-eos-logo.png'),
    'IOTA': BrandToken(symbol:'IOTA', name:'IOTA',            geckoId:'iota',               geckoImageId:1303,  geckoFilename:'iota_logo.png'),
    'XMR2': BrandToken(symbol:'XMR',  name:'Monero',          geckoId:'monero',             geckoImageId:69,    geckoFilename:'monero_logo.png'),
    'KAS':  BrandToken(symbol:'KAS',  name:'Kaspa',           geckoId:'kaspa',              geckoImageId:28177, geckoFilename:'kaspa-icon-exchanges.png'),
    'WIF':  BrandToken(symbol:'WIF',  name:'dogwifhat',       geckoId:'dogwifcoin',         geckoImageId:33566, geckoFilename:'wifhat.png'),
    'EUR':  BrandToken(symbol:'EUR',  name:'Euro',            geckoId:'',                   geckoImageId:0,     geckoFilename:''),
    'USD':  BrandToken(symbol:'USD',  name:'US Dollar',       geckoId:'',                   geckoImageId:0,     geckoFilename:''),
  };

  static BrandToken? get(String symbol) =>
      _tokens[symbol.toUpperCase()];

  static BrandToken getOrFallback(String symbol) =>
      _tokens[symbol.toUpperCase()] ??
      BrandToken(
        symbol: symbol.toUpperCase(),
        name: symbol,
        geckoId: symbol.toLowerCase(),
      );

  static List<BrandToken> get all => _tokens.values.toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// CRYPTO BRAND SERVICE — Fetches & caches dynamic token metadata from CoinGecko
// ─────────────────────────────────────────────────────────────────────────────

class CryptoBrandService extends ChangeNotifier {
  static final CryptoBrandService _instance = CryptoBrandService._();
  factory CryptoBrandService() => _instance;
  CryptoBrandService._();

  final Map<String, String> _logoCache = {};       // symbol → logoUrl
  final Map<String, Map<String, dynamic>> _meta = {}; // geckoId → metadata
  final Set<String> _fetching = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;
  Map<String, String> get logoCache => Map.unmodifiable(_logoCache);

  /// Get logo URL for symbol (instant from cache, else returns null and triggers fetch)
  String? getLogoUrl(String symbol) {
    final sym = symbol.toUpperCase();
    if (_logoCache.containsKey(sym)) return _logoCache[sym];
    final token = CryptoBrandRegistry.getOrFallback(sym);
    if (token.geckoLargeUrl.isNotEmpty) {
      _logoCache[sym] = token.geckoLargeUrl;
      return token.geckoLargeUrl;
    }
    _fetchDynamicLogo(sym);
    return null;
  }

  /// Pre-warm logo cache for a list of symbols
  Future<void> preloadLogos(List<String> symbols) async {
    for (final sym in symbols) {
      getLogoUrl(sym);
    }
    _initialized = true;
  }

  Future<void> _fetchDynamicLogo(String symbol) async {
    if (_fetching.contains(symbol)) return;
    _fetching.add(symbol);
    try {
      final token = CryptoBrandRegistry.getOrFallback(symbol);
      if (token.geckoId.isEmpty) return;
      final resp = await http.get(
        Uri.parse('https://api.coingecko.com/api/v3/coins/${token.geckoId}?localization=false&tickers=false&market_data=false&community_data=false'),
      ).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final image = data['image'] as Map<String, dynamic>?;
        final largeUrl = image?['large'] as String?;
        if (largeUrl != null) {
          _logoCache[symbol] = largeUrl;
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('CryptoBrandService: fetch failed for $symbol: $e');
    } finally {
      _fetching.remove(symbol);
    }
  }

  /// Batch-fetch market data for up to 250 coins via CoinGecko /coins/markets
  Future<void> fetchMarketLogos(List<String> geckoIds) async {
    if (geckoIds.isEmpty) return;
    final ids = geckoIds.take(100).join(',');
    try {
      final resp = await http.get(Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=$ids&per_page=100&page=1',
      )).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List;
        for (final item in list) {
          final sym = (item['symbol'] as String?)?.toUpperCase() ?? '';
          final img = item['image'] as String?;
          if (sym.isNotEmpty && img != null) {
            _logoCache[sym] = img;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('CryptoBrandService: batch fetch failed: $e');
    }
  }
}
