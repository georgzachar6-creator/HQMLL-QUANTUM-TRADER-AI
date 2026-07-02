// HQMLL Quantum Trader – Live Market Service
// CoinGecko REST API + Binance WebSocket + Alpha Vantage Stocks
// Grigori Saks · 2025
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

// ── Asset Model ────────────────────────────────────────
class AssetQuote {
  final String symbol;
  final String name;
  final String category; // crypto | stock | commodity | fiat
  final double price;
  final double change24h;  // percentage
  final double volume24h;
  final double marketCap;
  final double high24h;
  final double low24h;
  final String iconUrl;
  final DateTime updatedAt;
  final bool isLive;

  const AssetQuote({
    required this.symbol,
    required this.name,
    required this.category,
    required this.price,
    required this.change24h,
    required this.volume24h,
    required this.marketCap,
    required this.high24h,
    required this.low24h,
    required this.iconUrl,
    required this.updatedAt,
    required this.isLive,
  });

  AssetQuote copyWith({double? price, double? change24h, bool? isLive}) => AssetQuote(
    symbol: symbol, name: name, category: category,
    price: price ?? this.price,
    change24h: change24h ?? this.change24h,
    volume24h: volume24h, marketCap: marketCap,
    high24h: high24h, low24h: low24h,
    iconUrl: iconUrl,
    updatedAt: DateTime.now(),
    isLive: isLive ?? this.isLive,
  );

  bool get isPositive => change24h >= 0;
  String get formattedPrice {
    if (price >= 1000) return '\$${price.toStringAsFixed(0)}';
    if (price >= 1) return '\$${price.toStringAsFixed(2)}';
    return '\$${price.toStringAsFixed(4)}';
  }
  String get formattedChange => '${isPositive ? '+' : ''}${change24h.toStringAsFixed(2)}%';
}

// ── Candlestick Model ──────────────────────────────────
class Candle {
  final DateTime time;
  final double open, high, low, close, volume;
  const Candle(this.time, this.open, this.high, this.low, this.close, this.volume);
}

// ── Broker Order Model ────────────────────────────────
class BrokerOrder {
  final String id;
  final String symbol;
  final String side; // BUY | SELL
  final double quantity;
  final double price;
  final String status; // PENDING | FILLED | CANCELLED
  final DateTime createdAt;
  BrokerOrder({
    required this.id, required this.symbol, required this.side,
    required this.quantity, required this.price,
    required this.status, required this.createdAt,
  });
}

// ══════════════════════════════════════════════════════
// LIVE MARKET SERVICE
// ══════════════════════════════════════════════════════
class LiveMarketService extends ChangeNotifier {
  static final LiveMarketService _instance = LiveMarketService._internal();
  factory LiveMarketService() => _instance;
  LiveMarketService._internal() {
    _initData();
    _startSimulatedLiveFeed();
  }

  // ── CoinGecko IDs ──────────────────────────────────
  static const Map<String, String> _geckoIds = {
    // Top Tier
    'BTC': 'bitcoin', 'ETH': 'ethereum', 'BNB': 'binancecoin',
    'SOL': 'solana', 'ADA': 'cardano', 'DOGE': 'dogecoin',
    'AVAX': 'avalanche-2', 'DOT': 'polkadot', 'MATIC': 'matic-network',
    'LINK': 'chainlink', 'XRP': 'ripple', 'LTC': 'litecoin',
    'KAS': 'kaspa', 'XMR': 'monero', 'ATOM': 'cosmos',
    'UNI': 'uniswap', 'ALGO': 'algorand', 'VET': 'vechain',
    'NEAR': 'near', 'ICP': 'internet-computer', 'FIL': 'filecoin',
    'HBAR': 'hedera-hashgraph',
    'AAVE': 'aave', 'GRT': 'the-graph', 'SAND': 'the-sandbox',
    'MANA': 'decentraland', 'FTM': 'fantom', 'CRO': 'crypto-com-chain',
    'USDT': 'tether', 'USDC': 'usd-coin',
    // Extended Coins
    'TRX': 'tron', 'TON': 'the-open-network', 'SUI': 'sui',
    'OP': 'optimism', 'ARB': 'arbitrum', 'APT': 'aptos',
    'INJ': 'injective-protocol', 'SEI': 'sei-network', 'TIA': 'celestia',
    'RUNE': 'thorchain', 'FET': 'fetch-ai', 'RENDER': 'render-token',
    'IMX': 'immutable-x', 'BLUR': 'blur', 'WLD': 'worldcoin-wld',
    'STX': 'stacks', 'CFX': 'conflux-token', 'KAVA': 'kava',
    'ZEC': 'zcash', 'DASH': 'dash', 'EOS': 'eos',
    'XLM': 'stellar', 'EGLD': 'elrond-erd-2', 'ZIL': 'zilliqa',
    'OCEAN': 'ocean-protocol', 'AGIX': 'singularitynet',
    'ROSE': 'oasis-network', 'ONE': 'harmony', 'BAT': 'basic-attention-token',
    'ENJ': 'enjincoin', 'CHZ': 'chiliz', 'HOT': 'holotoken',
    'LUNC': 'terra-luna', 'LUNA': 'terra-luna-2',
  };

  // ── CoinGecko Icon URLs ────────────────────────────
  static const Map<String, String> coinIconUrls = {
    'BTC':  'https://assets.coingecko.com/coins/images/1/small/bitcoin.png',
    'ETH':  'https://assets.coingecko.com/coins/images/279/small/ethereum.png',
    'BNB':  'https://assets.coingecko.com/coins/images/825/small/bnb-icon2_2x.png',
    'SOL':  'https://assets.coingecko.com/coins/images/4128/small/solana.png',
    'ADA':  'https://assets.coingecko.com/coins/images/975/small/cardano.png',
    'DOGE': 'https://assets.coingecko.com/coins/images/5/small/dogecoin.png',
    'AVAX': 'https://assets.coingecko.com/coins/images/12559/small/Avalanche_Circle_RedWhite_Trans.png',
    'DOT':  'https://assets.coingecko.com/coins/images/12171/small/polkadot.png',
    'MATIC':'https://assets.coingecko.com/coins/images/4713/small/matic-token-icon.png',
    'LINK': 'https://assets.coingecko.com/coins/images/877/small/chainlink-new-logo.png',
    'XRP':  'https://assets.coingecko.com/coins/images/44/small/xrp-symbol-white-128.png',
    'LTC':  'https://assets.coingecko.com/coins/images/2/small/litecoin.png',
    'KAS':  'https://assets.coingecko.com/coins/images/25751/small/kaspa-icon-exchanges.png',
    'XMR':  'https://assets.coingecko.com/coins/images/69/small/monero_logo.png',
    'ATOM': 'https://assets.coingecko.com/coins/images/1481/small/cosmos_hub.png',
    'UNI':  'https://assets.coingecko.com/coins/images/12504/small/uniswap-uni.png',
    'ALGO': 'https://assets.coingecko.com/coins/images/4380/small/download.png',
    'VET':  'https://assets.coingecko.com/coins/images/1167/small/VET_Token_Icon.png',
    'NEAR': 'https://assets.coingecko.com/coins/images/10365/small/near_icon.png',
    'ICP':  'https://assets.coingecko.com/coins/images/14495/small/Internet_Computer_logo.png',
    'FIL':  'https://assets.coingecko.com/coins/images/12817/small/filecoin.png',
    'HBAR': 'https://assets.coingecko.com/coins/images/3688/small/hbar.png',
    'AAVE': 'https://assets.coingecko.com/coins/images/12645/small/AAVE.png',
    'GRT':  'https://assets.coingecko.com/coins/images/13397/small/Graph_Token.png',
    'USDT': 'https://assets.coingecko.com/coins/images/325/small/Tether.png',
    'USDC': 'https://assets.coingecko.com/coins/images/6319/small/USD_Coin_icon.png',
    'TRX':  'https://assets.coingecko.com/coins/images/1094/small/tron-logo.png',
    'TON':  'https://assets.coingecko.com/coins/images/17980/small/ton_symbol.png',
    'SUI':  'https://assets.coingecko.com/coins/images/26375/small/sui_asset.jpeg',
    'OP':   'https://assets.coingecko.com/coins/images/25244/small/Optimism.png',
    'ARB':  'https://assets.coingecko.com/coins/images/16547/small/photo_2023-03-29_21.47.00.jpeg',
    'APT':  'https://assets.coingecko.com/coins/images/26455/small/aptos_round.png',
    'INJ':  'https://assets.coingecko.com/coins/images/12882/small/Secondary_Symbol.png',
    'SEI':  'https://assets.coingecko.com/coins/images/28205/small/Sei_Logo_-_Transparent.png',
    'RUNE': 'https://assets.coingecko.com/coins/images/13677/small/IMG_20210123_132049_458.png',
    'FET':  'https://assets.coingecko.com/coins/images/5681/small/Fetch.jpg',
    'IMX':  'https://assets.coingecko.com/coins/images/17233/small/immutableX-symbol-BLK-RGB.png',
    'WLD':  'https://assets.coingecko.com/coins/images/31069/small/worldcoin.jpeg',
    'STX':  'https://assets.coingecko.com/coins/images/2069/small/Stacks_logo_full.png',
    'XLM':  'https://assets.coingecko.com/coins/images/100/small/Stellar_symbol_black_RGB.png',
    'ZEC':  'https://assets.coingecko.com/coins/images/486/small/circle-zcash-color.png',
    'DASH': 'https://assets.coingecko.com/coins/images/19/small/dash-logo.png',
    'EOS':  'https://assets.coingecko.com/coins/images/738/small/eos-eos-logo.png',
    'BAT':  'https://assets.coingecko.com/coins/images/677/small/basic-attention-token.png',
    'CHZ':  'https://assets.coingecko.com/coins/images/8834/small/CHZ_Token_updated.png',
    'ENJ':  'https://assets.coingecko.com/coins/images/1102/small/enjin-coin-logo.png',
    'OCEAN':'https://assets.coingecko.com/coins/images/3687/small/ocean-protocol-logo.jpg',
    'AGIX': 'https://assets.coingecko.com/coins/images/2138/small/singularitynet.png',
    'QEMMA':'', // Local asset
    // Stocks use local assets
    'AAPL': '', 'TSLA': '', 'GOOGL': '', 'AMZN': '', 'MSFT': '',
    'NVDA': '', 'META': '', 'NFLX': '', 'AMD': '', 'INTC': '',
    'XAU':  '', 'XAG':  '', 'OIL':   '', 'GAS': '', 'COPPER': '',
  };

  // ── State ──────────────────────────────────────────
  final Map<String, AssetQuote> _quotes = {};
  final Map<String, List<Candle>> _candles = {};
  final List<BrokerOrder> _orders = [];
  bool _isConnected = false;
  bool _geckoFetched = false;
  Timer? _refreshTimer;
  Timer? _liveTickTimer;
  WebSocketChannel? _binanceWs;
  final Random _rng = Random(42);
  String? _lastError;

  // ── Getters ────────────────────────────────────────
  Map<String, AssetQuote> get quotes => Map.unmodifiable(_quotes);
  List<AssetQuote> get cryptoAssets => _quotes.values.where((q) => q.category == 'crypto').toList();
  List<AssetQuote> get stockAssets => _quotes.values.where((q) => q.category == 'stock').toList();
  List<AssetQuote> get commodityAssets => _quotes.values.where((q) => q.category == 'commodity').toList();
  List<BrokerOrder> get orders => List.unmodifiable(_orders);
  bool get isConnected => _isConnected;
  bool get isLive => _geckoFetched;
  String? get lastError => _lastError;
  List<AssetQuote> get topGainers => [..._quotes.values]..sort((a,b) => b.change24h.compareTo(a.change24h));
  List<AssetQuote> get topLosers => [..._quotes.values]..sort((a,b) => a.change24h.compareTo(b.change24h));

  AssetQuote? quote(String symbol) => _quotes[symbol];
  List<Candle> candles(String symbol) => _candles[symbol] ?? [];

  // ── Init with realistic seed data ─────────────────
  void _initData() {
    final seedAssets = [
      // ─ Crypto ─
      _seed('BTC',   'Bitcoin',          'crypto',    67842.50,  2.34, 32.1e9, 1284e9,    68500, 66100),
      _seed('ETH',   'Ethereum',         'crypto',     3548.20,  1.87, 18.4e9,  426e9,     3610,  3480),
      _seed('BNB',   'BNB Chain',        'crypto',      598.30,  0.94,  1.8e9,   88e9,      605,   590),
      _seed('SOL',   'Solana',           'crypto',      182.40, -0.52,  3.2e9,   80e9,      190,   178),
      _seed('QEMMA', 'QEMMA Token',      'crypto',        0.0847, 12.45, 4.2e6, 156e6,    0.089,  0.075),
      _seed('ADA',   'Cardano',          'crypto',        0.452, -1.23,  420e6,  15.8e9,  0.465,  0.442),
      _seed('DOGE',  'Dogecoin',         'crypto',        0.0892, -3.44,  850e6, 12.7e9,  0.094,  0.086),
      _seed('AVAX',  'Avalanche',        'crypto',       36.80,  4.56,  580e6,  14.9e9,   37.8,   35.2),
      _seed('DOT',   'Polkadot',         'crypto',        7.24, -0.88,  240e6,   9.8e9,    7.45,   7.10),
      _seed('MATIC', 'Polygon',          'crypto',        0.712,  2.11,  380e6,   7.1e9,  0.728,  0.694),
      _seed('LINK',  'Chainlink',        'crypto',       14.32,  3.45,  420e6,   8.2e9,  14.78,  13.85),
      _seed('XRP',   'Ripple XRP',       'crypto',        0.524,  0.78,  1.1e9,  28.4e9,  0.534,  0.512),
      _seed('LTC',   'Litecoin',         'crypto',       82.40,  1.22,  380e6,   6.1e9,   83.8,   81.0),
      _seed('KAS',   'Kaspa',            'crypto',        0.134,  8.21,  280e6,   3.2e9,  0.142,  0.122),
      _seed('XMR',   'Monero',           'crypto',      158.40, -0.44,  180e6,   2.9e9,  161.2,  155.8),
      _seed('ATOM',  'Cosmos',           'crypto',        9.84,  2.34,  240e6,   3.8e9,  10.12,   9.54),
      _seed('UNI',   'Uniswap',          'crypto',       10.42,  1.88,  180e6,   6.2e9,  10.78,  10.12),
      _seed('ALGO',  'Algorand',         'crypto',        0.182, -0.92,  120e6,   1.5e9,  0.188,  0.175),
      _seed('VET',   'VeChain',          'crypto',        0.0382, 3.12,  98e6,   2.8e9,  0.0395, 0.0368),
      _seed('NEAR',  'NEAR Protocol',    'crypto',        7.84,  4.21,  380e6,   8.2e9,   8.12,   7.48),
      _seed('ICP',   'Internet Computer','crypto',       12.84,  1.45,  120e6,   6.0e9,  13.24,  12.42),
      _seed('AAVE',  'Aave',             'crypto',      142.30,  2.88,  180e6,   2.1e9,  146.8,  138.4),
      _seed('GRT',   'The Graph',        'crypto',        0.254,  5.12,  280e6,   2.4e9,  0.264,  0.241),
      _seed('USDT',  'Tether USD',       'crypto',        1.000,  0.01,  52.1e9, 113e9,  1.001,  0.999),
      _seed('USDC',  'USD Coin',         'crypto',        1.000,  0.00,  8.4e9,  36.8e9, 1.000,  1.000),
      // ─ Extended Crypto ─
      _seed('TRX',   'TRON',             'crypto',        0.1248,  1.42,  890e6,  10.9e9,  0.128, 0.121),
      _seed('TON',   'Toncoin',          'crypto',        5.840,   3.22,  480e6,  20.2e9,   6.01,  5.62),
      _seed('SUI',   'Sui',              'crypto',        1.842,   6.44,  580e6,   4.8e9,   1.92,  1.71),
      _seed('OP',    'Optimism',         'crypto',        2.480,   4.12,  320e6,   3.2e9,   2.56,  2.34),
      _seed('ARB',   'Arbitrum',         'crypto',        1.124,   2.88,  480e6,   4.5e9,   1.16,  1.08),
      _seed('APT',   'Aptos',            'crypto',       10.840,   5.34,  380e6,   4.7e9,  11.24,  10.21),
      _seed('INJ',   'Injective',        'crypto',       28.420,   7.82,  280e6,   2.7e9,  29.45,  26.18),
      _seed('SEI',   'Sei Network',      'crypto',        0.542,   4.21,  180e6,   1.2e9,  0.562,  0.512),
      _seed('RUNE',  'THORChain',        'crypto',        5.840,   3.44,  180e6,   2.0e9,   6.02,  5.61),
      _seed('FET',   'Fetch.ai',         'crypto',        2.142,   8.12,  280e6,   1.8e9,   2.24,  1.96),
      _seed('IMX',   'ImmutableX',       'crypto',        2.284,   3.88,  180e6,   3.4e9,   2.36,  2.18),
      _seed('WLD',   'Worldcoin',        'crypto',        4.820,   5.22,  180e6,   5.8e9,   5.04,  4.54),
      _seed('STX',   'Stacks',           'crypto',        2.148,   2.44,  140e6,   3.1e9,   2.22,  2.06),
      _seed('XLM',   'Stellar',          'crypto',        0.1124,  1.88,  280e6,   3.2e9,  0.118,  0.107),
      _seed('ZEC',   'Zcash',            'crypto',       28.420,  -0.82,  42e6,   0.42e9,  29.12,  27.84),
      _seed('DASH',  'Dash',             'crypto',       31.840,  -1.22,  68e6,   0.38e9,  32.80,  31.02),
      _seed('EOS',   'EOS',              'crypto',        0.884,   0.44,  180e6,   1.3e9,  0.912,  0.858),
      _seed('BAT',   'Basic Attention',  'crypto',        0.2480,  2.12,  84e6,   0.42e9, 0.256,  0.238),
      _seed('CHZ',   'Chiliz',           'crypto',        0.1084,  3.22,  84e6,   0.98e9, 0.114,  0.103),
      _seed('ENJ',   'Enjin Coin',       'crypto',        0.3240,  1.84,  42e6,   0.54e9, 0.334,  0.312),
      _seed('OCEAN', 'Ocean Protocol',   'crypto',        0.8840,  4.88,  42e6,   0.52e9, 0.924,  0.842),
      _seed('AGIX',  'SingularityNET',   'crypto',        0.9840,  6.12,  84e6,   0.64e9, 1.024,  0.924),
      // ─ Stocks ─
      _seed('AAPL',  'Apple Inc.',       'stock',       189.30, -0.42,  4.8e9,  2930e9,  191.2,  187.8),
      _seed('TSLA',  'Tesla Inc.',       'stock',       245.80,  2.18,  6.2e9,   783e9,  249.4,  241.2),
      _seed('GOOGL', 'Alphabet Inc.',    'stock',       165.42,  0.84,  2.1e9,  2060e9,  166.8,  163.9),
      _seed('AMZN',  'Amazon.com',       'stock',       198.75,  1.34,  3.4e9,  2080e9,  200.5,  196.3),
      _seed('MSFT',  'Microsoft Corp.',  'stock',       415.20,  0.56,  2.8e9,  3090e9,  417.8,  413.1),
      _seed('NVDA',  'NVIDIA Corp.',     'stock',       875.40,  3.21,  8.9e9,  2160e9,  884.2,  856.7),
      _seed('META',  'Meta Platforms',   'stock',       478.90,  1.78,  1.9e9,  1220e9,  482.4,  472.1),
      _seed('NFLX',  'Netflix Inc.',     'stock',       628.40,  1.12,  1.2e9,   274e9,  635.8,  621.3),
      _seed('AMD',   'Advanced Micro',   'stock',       162.30, -0.65,  3.1e9,   263e9,  164.8,  159.7),
      _seed('INTC',  'Intel Corp.',      'stock',        31.20, -1.22,  2.4e9,   132e9,   32.1,   30.5),
      // ─ Commodities ─
      _seed('XAU',   'Gold (XAU/USD)',   'commodity',  2320.50,  0.34,  42e9,     0,    2338.4, 2305.2),
      _seed('XAG',   'Silver (XAG/USD)', 'commodity',    27.84,  0.71,   8e9,     0,    28.12,  27.51),
      _seed('OIL',   'Crude Oil WTI',    'commodity',    82.45, -0.89,  18e9,     0,    83.20,  81.60),
      _seed('GAS',   'Natural Gas',      'commodity',     2.14, -1.45,   4e9,     0,     2.21,   2.08),
      _seed('COPPER','Copper',           'commodity',     4.52,  0.42,   6e9,     0,     4.58,   4.47),
    ];

    for (final a in seedAssets) {
      _quotes[a.symbol] = a;
      _candles[a.symbol] = _generateCandles(a.price, 100);
    }
    _isConnected = true;
    notifyListeners();
  }

  AssetQuote _seed(String sym, String name, String cat, double price,
      double chg, double vol, double mcap, double h, double l) {
    return AssetQuote(
      symbol: sym, name: name, category: cat,
      price: price, change24h: chg, volume24h: vol,
      marketCap: mcap, high24h: h, low24h: l,
      iconUrl: coinIconUrls[sym] ?? '',
      updatedAt: DateTime.now(), isLive: false,
    );
  }

  // ── Generate synthetic candle data ────────────────
  List<Candle> _generateCandles(double basePrice, int count) {
    final List<Candle> candles = [];
    double price = basePrice;
    final now = DateTime.now();
    for (int i = count; i >= 0; i--) {
      final t = now.subtract(Duration(hours: i));
      final open = price;
      final change = ((_rng.nextDouble() - 0.48) * basePrice * 0.02);
      final close = (open + change).clamp(basePrice * 0.7, basePrice * 1.3);
      final high = [open, close].reduce(max) + _rng.nextDouble() * basePrice * 0.005;
      final low  = [open, close].reduce(min) - _rng.nextDouble() * basePrice * 0.005;
      final vol  = basePrice * 1000 * (0.5 + _rng.nextDouble());
      candles.add(Candle(t, open, high, low.clamp(0.0001, low), close, vol));
      price = close;
    }
    return candles;
  }

  // ── Simulated Live Tick (always active) ───────────
  void _startSimulatedLiveFeed() {
    _liveTickTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      bool changed = false;
      for (final sym in _quotes.keys) {
        final q = _quotes[sym]!;
        final noise = (_rng.nextDouble() - 0.499) * q.price * 0.0008;
        final newPrice = (q.price + noise).clamp(q.price * 0.95, q.price * 1.05);
        final chgNoise = (_rng.nextDouble() - 0.499) * 0.05;
        _quotes[sym] = q.copyWith(
          price: newPrice,
          change24h: q.change24h + chgNoise,
        );
        // Append candle tick
        if (_candles.containsKey(sym) && (_candles[sym]?.isNotEmpty ?? false)) {
          final last = _candles[sym]?.last; if (last == null) return;
          final updatedLast = Candle(
            last.time,
            last.open,
            max(last.high, newPrice),
            min(last.low, newPrice),
            newPrice,
            last.volume + q.volume24h * 0.0001,
          );
          if (_candles[sym]?.isNotEmpty ?? false) { _candles[sym]!.last = updatedLast; }
        }
        changed = true;
      }
      if (changed) notifyListeners();
    });
  }

  // ── CoinGecko Live Fetch ───────────────────────────
  Future<void> fetchCoinGeckoData() async {
    const ids = 'bitcoin,ethereum,binancecoin,solana,cardano,dogecoin,avalanche-2,polkadot,matic-network,chainlink,ripple,litecoin';
    const url = 'https://api.coingecko.com/api/v3/simple/price?ids=$ids&vs_currencies=usd&include_24hr_change=true&include_24hr_vol=true&include_market_cap=true&include_high_24h=true&include_low_24h=true';

    try {
      final resp = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final idToSym = Map.fromEntries(_geckoIds.entries.map((e) => MapEntry(e.value, e.key)));
        data.forEach((geckoId, vals) {
          final sym = idToSym[geckoId];
          if (sym != null && vals is Map) {
            final existing = _quotes[sym];
            if (existing != null) {
              _quotes[sym] = AssetQuote(
                symbol: sym, name: existing.name, category: existing.category,
                price: (vals['usd'] as num?)?.toDouble() ?? existing.price,
                change24h: (vals['usd_24h_change'] as num?)?.toDouble() ?? existing.change24h,
                volume24h: (vals['usd_24h_vol'] as num?)?.toDouble() ?? existing.volume24h,
                marketCap: (vals['usd_market_cap'] as num?)?.toDouble() ?? existing.marketCap,
                high24h: (vals['usd_24h_high'] as num?)?.toDouble() ?? existing.high24h,
                low24h: (vals['usd_24h_low'] as num?)?.toDouble() ?? existing.low24h,
                iconUrl: existing.iconUrl,
                updatedAt: DateTime.now(),
                isLive: true,
              );
            }
          }
        });
        _geckoFetched = true;
        _lastError = null;
        notifyListeners();
      }
    } catch (e) {
      _lastError = 'CoinGecko: ${e.toString().substring(0, min(50, e.toString().length))}';
      if (kDebugMode) debugPrint('CoinGecko error: $e');
    }
  }

  // ── Binance WebSocket (BTC/ETH Ticker) ───────────
  void connectBinanceWebSocket() {
    try {
      _binanceWs?.sink.close();
      const streams = 'btcusdt@ticker/ethusdt@ticker/solusdt@ticker/bnbusdt@ticker';
      _binanceWs = WebSocketChannel.connect(
        Uri.parse('wss://stream.binance.com:9443/stream?streams=$streams'),
      );
      _binanceWs!.stream.listen(
        (data) {
          try {
            final json_ = json.decode(data as String);
            final d = json_['data'] as Map<String, dynamic>?;
            if (d == null) return;
            final rawSym = (d['s'] as String?)?.replaceAll('USDT', '') ?? '';
            final q = _quotes[rawSym];
            if (q != null) {
              _quotes[rawSym] = AssetQuote(
                symbol: q.symbol, name: q.name, category: q.category,
                price: double.tryParse(d['c']?.toString() ?? '') ?? q.price,
                change24h: double.tryParse(d['P']?.toString() ?? '') ?? q.change24h,
                volume24h: double.tryParse(d['v']?.toString() ?? '') ?? q.volume24h,
                marketCap: q.marketCap, high24h: q.high24h, low24h: q.low24h,
                iconUrl: q.iconUrl, updatedAt: DateTime.now(), isLive: true,
              );
              notifyListeners();
            }
          } catch (_) {}
        },
        onError: (e) {
          _lastError = 'Binance WS: $e';
          if (kDebugMode) debugPrint('Binance WS error: $e');
        },
      );
      _isConnected = true;
    } catch (e) {
      if (kDebugMode) debugPrint('Binance connect error: $e');
    }
  }

  // ── Auto-refresh timer ────────────────────────────
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    fetchCoinGeckoData(); // immediate
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchCoinGeckoData();
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _binanceWs?.sink.close();
  }

  // ── Broker: Place Order ───────────────────────────
  Future<BrokerOrder> placeOrder({
    required String symbol,
    required String side,
    required double quantity,
    String orderType = 'MARKET',
  }) async {
    await Future.delayed(const Duration(milliseconds: 800)); // simulate latency
    final q = _quotes[symbol];
    final price = q?.price ?? 0;
    final order = BrokerOrder(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      symbol: symbol, side: side,
      quantity: quantity, price: price,
      status: 'FILLED',
      createdAt: DateTime.now(),
    );
    _orders.insert(0, order);
    notifyListeners();
    return order;
  }

  // ── FIAT Conversion ───────────────────────────────
  double toEur(double usdAmount) => usdAmount * 0.923;
  double toUsd(double eurAmount) => eurAmount / 0.923;
  String formatFiat(double amount, String currency) {
    if (currency == 'EUR') return '€${toEur(amount).toStringAsFixed(2)}';
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  void dispose() {
    _liveTickTimer?.cancel();
    _refreshTimer?.cancel();
    _binanceWs?.sink.close();
    super.dispose();
  }
}
