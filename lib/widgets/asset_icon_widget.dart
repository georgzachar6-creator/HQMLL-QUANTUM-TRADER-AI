/// Asset Icon Widget – Originale Coin/Stock/Commodity Icons
/// CoinGecko CDN für Crypto, Custom SVG für Stocks/Rohstoffe
/// Grigori Saks · 2025
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_themes.dart';
import '../services/live_market_service.dart';

// ═══════════════════════════════════════════════════════
// ASSET ICON WIDGET
// ═══════════════════════════════════════════════════════
class AssetIconWidget extends StatelessWidget {
  final String symbol;
  final double size;
  final QuantumPalette palette;
  final bool showBorder;
  final double borderWidth;
  final bool showGlow;

  const AssetIconWidget({
    super.key,
    required this.symbol,
    required this.palette,
    this.size = 40,
    this.showBorder = true,
    this.borderWidth = 1.5,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconUrl = LiveMarketService.coinIconUrls[symbol] ?? '';
    final fallbackColor = symbolColor(symbol);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fallbackColor.withValues(alpha: 0.12),
        border: showBorder
            ? Border.all(color: fallbackColor.withValues(alpha: 0.4), width: borderWidth)
            : null,
        boxShadow: showGlow
            ? [BoxShadow(color: fallbackColor.withValues(alpha: 0.3), blurRadius: size * 0.5, spreadRadius: 1)]
            : [BoxShadow(color: fallbackColor.withValues(alpha: 0.12), blurRadius: size * 0.25)],
      ),
      child: ClipOval(
        child: iconUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: iconUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => _symbolFallback(fallbackColor),
                errorWidget: (_, __, ___) => _symbolFallback(fallbackColor),
              )
            : _localIcon(symbol, fallbackColor),
      ),
    );
  }

  Widget _symbolFallback(Color color) {
    return Container(
      color: color.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          symbol.length > 3 ? symbol.substring(0, 3) : symbol,
          style: TextStyle(
            color: color,
            fontSize: size * 0.28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _localIcon(String sym, Color color) {
    final data = _localIconData[sym];
    if (data != null) {
      return Container(
        color: data.bg,
        child: Center(child: _buildLocalSymbol(sym, data, color)),
      );
    }
    return _symbolFallback(color);
  }

  Widget _buildLocalSymbol(String sym, _IconData data, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background gradient circle
        Container(
          width: size * 0.85,
          height: size * 0.85,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [data.accent.withValues(alpha: 0.3), Colors.transparent],
            ),
          ),
        ),
        // Symbol text or icon
        Text(
          data.symbol,
          style: TextStyle(
            color: data.accent,
            fontSize: size * 0.32,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  static Color symbolColor(String symbol) {
    const colors = {
      'BTC':   Color(0xFFF7931A),
      'ETH':   Color(0xFF627EEA),
      'BNB':   Color(0xFFF3BA2F),
      'SOL':   Color(0xFF9945FF),
      'QEMMA': Color(0xFF00D4FF),
      'ADA':   Color(0xFF0033AD),
      'DOGE':  Color(0xFFCBA132),
      'AVAX':  Color(0xFFE84142),
      'DOT':   Color(0xFFE6007A),
      'MATIC': Color(0xFF8247E5),
      'LINK':  Color(0xFF375BD2),
      'XRP':   Color(0xFF00AAE4),
      'LTC':   Color(0xFF345D9D),
      'USDT':  Color(0xFF26A17B),
      'USDC':  Color(0xFF2775CA),
      // Stocks
      'AAPL':  Color(0xFF555555),
      'TSLA':  Color(0xFFCC0000),
      'GOOGL': Color(0xFF4285F4),
      'AMZN':  Color(0xFFFF9900),
      'MSFT':  Color(0xFF00A4EF),
      'NVDA':  Color(0xFF76B900),
      'META':  Color(0xFF1877F2),
      // Commodities
      'XAU':   Color(0xFFFFD700),
      'XAG':   Color(0xFFAAAAAA),
      'OIL':   Color(0xFF333333),
      // FIAT
      'EUR':   Color(0xFF003399),
      'USD':   Color(0xFF006400),
    };
    return colors[symbol] ?? const Color(0xFF00D4FF);
  }

  static const Map<String, _IconData> _localIconData = {
    'QEMMA': _IconData(Color(0xFF0A1628), Color(0xFF00D4FF), '⬡'),
    'AAPL':  _IconData(Color(0xFF1C1C1E), Color(0xFFE0E0E0), ''),
    'TSLA':  _IconData(Color(0xFF0C0C0C), Color(0xFFCC0000), 'T'),
    'GOOGL': _IconData(Color(0xFF0B1A5C), Color(0xFF4285F4), 'G'),
    'AMZN':  _IconData(Color(0xFF0F1111), Color(0xFFFF9900), 'a'),
    'MSFT':  _IconData(Color(0xFF00334D), Color(0xFF00A4EF), '⊞'),
    'NVDA':  _IconData(Color(0xFF0A2600), Color(0xFF76B900), 'N'),
    'META':  _IconData(Color(0xFF001B44), Color(0xFF1877F2), '∞'),
    'XAU':   _IconData(Color(0xFF2A1F00), Color(0xFFFFD700), 'Au'),
    'XAG':   _IconData(Color(0xFF1A1A1A), Color(0xFFCCCCCC), 'Ag'),
    'OIL':   _IconData(Color(0xFF0D0D0D), Color(0xFF555555), '⛽'),
    'EUR':   _IconData(Color(0xFF00204D), Color(0xFFFFCC00), '€'),
    'USD':   _IconData(Color(0xFF003300), Color(0xFF85BB65), '\$'),
  };
}

class _IconData {
  final Color bg;
  final Color accent;
  final String symbol;
  const _IconData(this.bg, this.accent, this.symbol);
}

// ═══════════════════════════════════════════════════════
// ANIMATED ASSET ICON (mit Pulse-Effekt)
// ═══════════════════════════════════════════════════════
class AnimatedAssetIcon extends StatefulWidget {
  final String symbol;
  final double size;
  final QuantumPalette palette;
  final bool pulsing;

  const AnimatedAssetIcon({
    super.key,
    required this.symbol,
    required this.palette,
    this.size = 44,
    this.pulsing = false,
  });

  @override
  State<AnimatedAssetIcon> createState() => _AnimatedAssetIconState();
}

class _AnimatedAssetIconState extends State<AnimatedAssetIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulsing) {
      return AssetIconWidget(
        symbol: widget.symbol, palette: widget.palette, size: widget.size, showGlow: false,
      );
    }
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, child) {
        final color = AssetIconWidget.symbolColor(widget.symbol);
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2 + _glowAnim.value * 0.3),
                blurRadius: widget.size * (0.3 + _glowAnim.value * 0.4),
                spreadRadius: _glowAnim.value * 3,
              ),
            ],
          ),
          child: child,
        );
      },
      child: AssetIconWidget(
        symbol: widget.symbol, palette: widget.palette,
        size: widget.size, showGlow: true,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ASSET ICON ROW (Symbol + Name + Preis)
// ═══════════════════════════════════════════════════════
class AssetIconRow extends StatelessWidget {
  final String symbol;
  final String name;
  final String? subtitle;
  final double iconSize;
  final QuantumPalette palette;

  const AssetIconRow({
    super.key,
    required this.symbol,
    required this.name,
    required this.palette,
    this.subtitle,
    this.iconSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AssetIconWidget(symbol: symbol, palette: palette, size: iconSize),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(symbol,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: iconSize * 0.38,
                  letterSpacing: 0.5,
                )),
              if (subtitle != null)
                Text(subtitle!,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: iconSize * 0.28,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
