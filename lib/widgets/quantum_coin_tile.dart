// HQMLL Quantum Trader – Quantum Coin Tile Widget System v39.0
// Animated Premium Coin Tiles · SVG-like Custom Paint Logos
// Unique Branding · Live Price Overlays · Glow Effects
// Grigori Saks · 2025
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'crypto_icon.dart';

// ═══════════════════════════════════════════════════════════════
// COIN BRAND COLORS — Master palette for all 25 coins
// ═══════════════════════════════════════════════════════════════
class CoinBrand {
  final Color primary;
  final Color secondary;
  final Color glow;
  final String symbol;
  final String name;
  final IconData icon;

  const CoinBrand({
    required this.primary,
    required this.secondary,
    required this.glow,
    required this.symbol,
    required this.name,
    required this.icon,
  });
}

const Map<String, CoinBrand> _brands = {
  'BTC':  CoinBrand(primary: Color(0xFFF7931A), secondary: Color(0xFF4D2F00), glow: Color(0xFFF7931A), symbol: 'BTC',  name: 'Bitcoin',    icon: Icons.currency_bitcoin),
  'ETH':  CoinBrand(primary: Color(0xFF627EEA), secondary: Color(0xFF1A1A4D), glow: Color(0xFF627EEA), symbol: 'ETH',  name: 'Ethereum',   icon: Icons.diamond_outlined),
  'SOL':  CoinBrand(primary: Color(0xFF9945FF), secondary: Color(0xFF1A003D), glow: Color(0xFF9945FF), symbol: 'SOL',  name: 'Solana',     icon: Icons.speed),
  'BNB':  CoinBrand(primary: Color(0xFFF3BA2F), secondary: Color(0xFF3D2F00), glow: Color(0xFFF3BA2F), symbol: 'BNB',  name: 'BNB',        icon: Icons.star),
  'XRP':  CoinBrand(primary: Color(0xFF00AAE4), secondary: Color(0xFF003040), glow: Color(0xFF00AAE4), symbol: 'XRP',  name: 'Ripple',     icon: Icons.waves),
  'ADA':  CoinBrand(primary: Color(0xFF0033AD), secondary: Color(0xFF001040), glow: Color(0xFF0033AD), symbol: 'ADA',  name: 'Cardano',    icon: Icons.hexagon_outlined),
  'AVAX': CoinBrand(primary: Color(0xFFE84142), secondary: Color(0xFF3D0000), glow: Color(0xFFE84142), symbol: 'AVAX', name: 'Avalanche',  icon: Icons.ac_unit),
  'DOGE': CoinBrand(primary: Color(0xFFC2A633), secondary: Color(0xFF2D2000), glow: Color(0xFFC2A633), symbol: 'DOGE', name: 'Dogecoin',   icon: Icons.pets),
  'DOT':  CoinBrand(primary: Color(0xFFE6007A), secondary: Color(0xFF3D001A), glow: Color(0xFFE6007A), symbol: 'DOT',  name: 'Polkadot',   icon: Icons.circle_outlined),
  'LINK': CoinBrand(primary: Color(0xFF2A5ADA), secondary: Color(0xFF001040), glow: Color(0xFF2A5ADA), symbol: 'LINK', name: 'Chainlink',  icon: Icons.link),
  'LTC':  CoinBrand(primary: Color(0xFFBFBFBF), secondary: Color(0xFF1A1A1A), glow: Color(0xFFBFBFBF), symbol: 'LTC',  name: 'Litecoin',   icon: Icons.bolt),
  'UNI':  CoinBrand(primary: Color(0xFFFF007A), secondary: Color(0xFF3D001A), glow: Color(0xFFFF007A), symbol: 'UNI',  name: 'Uniswap',    icon: Icons.swap_horiz),
  'MATIC':CoinBrand(primary: Color(0xFF8247E5), secondary: Color(0xFF1A003D), glow: Color(0xFF8247E5), symbol: 'MATIC',name: 'Polygon',    icon: Icons.pentagon_outlined),
  'ATOM': CoinBrand(primary: Color(0xFF2E3148), secondary: Color(0xFF0A0A1A), glow: Color(0xFF6F7390), symbol: 'ATOM', name: 'Cosmos',     icon: Icons.blur_circular),
  'NEAR': CoinBrand(primary: Color(0xFF00EC97), secondary: Color(0xFF003D28), glow: Color(0xFF00EC97), symbol: 'NEAR', name: 'NEAR',       icon: Icons.near_me),
  'APT':  CoinBrand(primary: Color(0xFF00BCD4), secondary: Color(0xFF003040), glow: Color(0xFF00BCD4), symbol: 'APT',  name: 'Aptos',      icon: Icons.apps),
  'OP':   CoinBrand(primary: Color(0xFFFF0420), secondary: Color(0xFF3D0000), glow: Color(0xFFFF0420), symbol: 'OP',   name: 'Optimism',   icon: Icons.brightness_7),
  'ARB':  CoinBrand(primary: Color(0xFF28A0F0), secondary: Color(0xFF001A3D), glow: Color(0xFF28A0F0), symbol: 'ARB',  name: 'Arbitrum',   icon: Icons.alt_route),
  'SUI':  CoinBrand(primary: Color(0xFF6FBCF0), secondary: Color(0xFF0A1A2D), glow: Color(0xFF6FBCF0), symbol: 'SUI',  name: 'Sui',        icon: Icons.water_drop),
  'PEPE': CoinBrand(primary: Color(0xFF4CAF50), secondary: Color(0xFF0A1A0A), glow: Color(0xFF4CAF50), symbol: 'PEPE', name: 'Pepe',       icon: Icons.eco),
  'WIF':  CoinBrand(primary: Color(0xFF9C6644), secondary: Color(0xFF1A0A00), glow: Color(0xFF9C6644), symbol: 'WIF',  name: 'WIF',        icon: Icons.face),
  'INJ':  CoinBrand(primary: Color(0xFF00BCD4), secondary: Color(0xFF001A20), glow: Color(0xFF00BCD4), symbol: 'INJ',  name: 'Injective',  icon: Icons.settings_input_component),
  'TIA':  CoinBrand(primary: Color(0xFF7B2FFF), secondary: Color(0xFF1A003D), glow: Color(0xFF7B2FFF), symbol: 'TIA',  name: 'Celestia',   icon: Icons.star_border),
  'QEMMA':CoinBrand(primary: Color(0xFF00FF88), secondary: Color(0xFF001A0A), glow: Color(0xFF00FF88), symbol: 'QEMMA',name: 'QEMMA AI',  icon: Icons.auto_awesome),
  'USDT': CoinBrand(primary: Color(0xFF26A17B), secondary: Color(0xFF002A1A), glow: Color(0xFF26A17B), symbol: 'USDT', name: 'Tether',     icon: Icons.attach_money),
};

CoinBrand _brandOf(String symbol) => _brands[symbol] ??
    CoinBrand(primary: const Color(0xFF00AAFF), secondary: const Color(0xFF001A3D),
              glow: const Color(0xFF00AAFF), symbol: symbol, name: symbol, icon: Icons.toll);

// ═══════════════════════════════════════════════════════════════
// QUANTUM COIN TILE — Animated premium kachel
// ═══════════════════════════════════════════════════════════════
class QuantumCoinTile extends StatefulWidget {
  final String symbol;
  final double price;
  final double change24h;
  final double? volume;
  final bool isLive;
  final bool selected;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const QuantumCoinTile({
    super.key,
    required this.symbol,
    required this.price,
    required this.change24h,
    this.volume,
    this.isLive = false,
    this.selected = false,
    this.onTap,
    this.width = 140,
    this.height = 160,
  });

  @override
  State<QuantumCoinTile> createState() => _QuantumCoinTileState();
}

class _QuantumCoinTileState extends State<QuantumCoinTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _glow = Tween<double>(begin: 0.3, end: 0.8).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = _brandOf(widget.symbol);
    final isUp = widget.change24h >= 0;
    final changeColor = isUp ? const Color(0xFF00C896) : const Color(0xFFFF3355);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                brand.secondary.withValues(alpha: 0.9),
                brand.primary.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: widget.selected
                  ? brand.primary
                  : brand.primary.withValues(alpha: widget.isLive ? _glow.value * 0.6 : 0.25),
              width: widget.selected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: brand.glow.withValues(alpha:
                    widget.selected ? 0.4 : (widget.isLive ? _glow.value * 0.25 : 0.08)),
                blurRadius: widget.selected ? 20 : 12,
                spreadRadius: widget.selected ? 2 : 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background pattern — subtle hex grid
              Positioned.fill(
                child: CustomPaint(
                  painter: _HexGridPainter(brand.primary.withValues(alpha: 0.04)),
                ),
              ),
              // Glow circle behind icon
              Positioned(
                top: 16, left: 0, right: 0,
                child: Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: brand.primary.withValues(alpha: 0.1 * _pulse.value),
                      boxShadow: [
                        BoxShadow(
                          color: brand.glow.withValues(alpha: _glow.value * 0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Coin icon
              Positioned(
                top: 18, left: 0, right: 0,
                child: Center(
                  child: CryptoIcon(widget.symbol, size: 48, showShadow: false),
                ),
              ),
              // Live indicator dot
              if (widget.isLive)
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00FF88),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFF00FF88).withValues(alpha: _glow.value),
                        blurRadius: 6,
                      )],
                    ),
                  ),
                ),
              // Content
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        brand.secondary.withValues(alpha: 0.0),
                        brand.secondary.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Symbol
                      Text(
                        widget.symbol,
                        style: GoogleFonts.spaceMono(
                          color: brand.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Price
                      Text(
                        widget.price > 0
                            ? (widget.price >= 1000
                                ? '\$${(widget.price / 1000).toStringAsFixed(1)}K'
                                : '\$${widget.price.toStringAsFixed(widget.price < 1 ? 4 : 2)}')
                            : '—',
                        style: GoogleFonts.spaceMono(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Change badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: changeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: changeColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                              color: changeColor, size: 12,
                            ),
                            Text(
                              '${widget.change24h.abs().toStringAsFixed(2)}%',
                              style: GoogleFonts.spaceMono(
                                color: changeColor, fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// QUANTUM COIN GRID — 3-column animated tile grid
// ═══════════════════════════════════════════════════════════════
class QuantumCoinGrid extends StatelessWidget {
  final List<String> symbols;
  final Map<String, double> prices;
  final Map<String, double> changes;
  final Map<String, bool> liveFlags;
  final String? selected;
  final ValueChanged<String>? onTap;

  const QuantumCoinGrid({
    super.key,
    required this.symbols,
    required this.prices,
    this.changes = const {},
    this.liveFlags = const {},
    this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: symbols.length,
      itemBuilder: (_, i) {
        final sym = symbols[i];
        return QuantumCoinTile(
          symbol: sym,
          price: prices[sym] ?? 0,
          change24h: changes[sym] ?? 0,
          isLive: liveFlags[sym] ?? false,
          selected: selected == sym,
          onTap: () => onTap?.call(sym),
          width: double.infinity,
          height: double.infinity,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// COIN BRAND STRIP — Horizontal scrollable animated coin strip
// ═══════════════════════════════════════════════════════════════
class CoinBrandStrip extends StatelessWidget {
  final List<String> symbols;
  /// Static price map (optional — use instead of getPriceAndChange)
  final Map<String, double> prices;
  final Map<String, double> changes;
  final Map<String, bool> liveFlags;
  final String? selected;
  final ValueChanged<String>? onTap;
  final double height;
  /// Dynamic callback: (symbol) → (price, change24h)
  /// Takes priority over prices/changes maps when provided.
  final (double, double) Function(String symbol)? getPriceAndChange;

  const CoinBrandStrip({
    super.key,
    required this.symbols,
    this.prices = const {},
    this.changes = const {},
    this.liveFlags = const {},
    this.selected,
    this.onTap,
    this.height = 170,
    this.getPriceAndChange,
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
          double price;
          double change;
          if (getPriceAndChange != null) {
            (price, change) = getPriceAndChange!(sym);
          } else {
            price = prices[sym] ?? 0;
            change = changes[sym] ?? 0;
          }
          final isLive = liveFlags[sym] ?? (price > 0);
          return QuantumCoinTile(
            symbol: sym,
            price: price,
            change24h: change,
            isLive: isLive,
            selected: selected == sym,
            onTap: () => onTap?.call(sym),
            width: 130,
            height: height,
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// COIN BRAND LOGO BADGE — Unique SVG-like Custom Paint logo
// ═══════════════════════════════════════════════════════════════
class CoinBrandBadge extends StatefulWidget {
  final String symbol;
  final double size;
  final bool animated;
  final bool showLabel;

  const CoinBrandBadge({
    super.key,
    required this.symbol,
    this.size = 56,
    this.animated = true,
    this.showLabel = false,
  });

  @override
  State<CoinBrandBadge> createState() => _CoinBrandBadgeState();
}

class _CoinBrandBadgeState extends State<CoinBrandBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.animated) _ctrl.repeat();
    _rotAnim = Tween<double>(begin: 0, end: 2 * pi).animate(_ctrl);
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = _brandOf(widget.symbol);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: widget.animated ? _scaleAnim.value : 1.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  brand.primary.withValues(alpha: 0.2),
                  brand.secondary,
                ]),
                border: Border.all(
                  color: brand.primary.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: brand.glow.withValues(alpha: 0.35),
                    blurRadius: widget.size * 0.4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Rotating outer ring
                  if (widget.animated)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RotatingRingPainter(
                          color: brand.primary.withValues(alpha: 0.3),
                          angle: _rotAnim.value,
                        ),
                      ),
                    ),
                  // Coin icon center
                  Center(
                    child: CryptoIcon(
                      widget.symbol,
                      size: widget.size * 0.65,
                      showBorder: false,
                      showShadow: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.showLabel) ...[
          const SizedBox(height: 4),
          Text(
            widget.symbol,
            style: GoogleFonts.spaceMono(
              color: brand.primary,
              fontSize: widget.size * 0.18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LIVE PRICE BADGE — Compact animated price display
// ═══════════════════════════════════════════════════════════════
class LivePriceBadge extends StatefulWidget {
  final String symbol;
  final double price;
  final double change24h;
  final bool isLive;
  final bool compact;

  const LivePriceBadge({
    super.key,
    required this.symbol,
    required this.price,
    required this.change24h,
    this.isLive = false,
    this.compact = false,
  });

  @override
  State<LivePriceBadge> createState() => _LivePriceBadgeState();
}

class _LivePriceBadgeState extends State<LivePriceBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = _brandOf(widget.symbol);
    final isUp = widget.change24h >= 0;
    final changeColor = isUp ? const Color(0xFF00C896) : const Color(0xFFFF3355);
    final priceStr = widget.price >= 1000
        ? '\$${(widget.price / 1000).toStringAsFixed(1)}K'
        : '\$${widget.price.toStringAsFixed(widget.price < 1 ? 4 : 2)}';

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 8 : 10,
            vertical: widget.compact ? 4 : 6),
        decoration: BoxDecoration(
          color: brand.secondary.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isLive
                ? brand.primary.withValues(alpha: _pulseAnim.value * 0.7)
                : brand.primary.withValues(alpha: 0.3),
          ),
          boxShadow: widget.isLive ? [
            BoxShadow(
              color: brand.glow.withValues(alpha: _pulseAnim.value * 0.2),
              blurRadius: 8,
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live dot
            if (widget.isLive) ...[
              Container(
                width: 5, height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00FF88).withValues(alpha: _pulseAnim.value),
                ),
              ),
              const SizedBox(width: 5),
            ],
            // Symbol
            Text(
              widget.symbol,
              style: GoogleFonts.spaceMono(
                color: brand.primary,
                fontSize: widget.compact ? 9 : 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            // Price
            Text(
              widget.price > 0 ? priceStr : '—',
              style: GoogleFonts.spaceMono(
                color: Colors.white,
                fontSize: widget.compact ? 9 : 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 5),
            // Change
            Text(
              '${isUp ? '+' : ''}${widget.change24h.toStringAsFixed(2)}%',
              style: GoogleFonts.spaceMono(
                color: changeColor,
                fontSize: widget.compact ? 8 : 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════

class _HexGridPainter extends CustomPainter {
  final Color color;
  _HexGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    const r = 16.0;
    final h = r * sqrt(3);
    int col = 0;
    for (double x = 0; x < size.width + r; x += r * 1.5) {
      final offsetY = col % 2 == 0 ? 0.0 : h / 2;
      for (double y = offsetY; y < size.height + h; y += h) {
        _drawHex(canvas, paint, Offset(x, y), r);
      }
      col++;
    }
  }

  void _drawHex(Canvas canvas, Paint paint, Offset center, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = pi / 180 * (60 * i - 30);
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HexGridPainter old) => old.color != color;
}

class _RotatingRingPainter extends CustomPainter {
  final Color color;
  final double angle;
  _RotatingRingPainter({required this.color, required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Dashed arc segments
    const dashCount = 8;
    const dashLength = pi / 12;
    const gapLength = (2 * pi - dashCount * dashLength) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = angle + i * (dashLength + gapLength);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, dashLength, false, paint,
      );
    }

    // Dot markers at cardinal positions
    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
    for (int i = 0; i < 4; i++) {
      final a = angle + i * pi / 2;
      final p = Offset(center.dx + radius * cos(a), center.dy + radius * sin(a));
      canvas.drawCircle(p, 2.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_RotatingRingPainter old) => old.angle != angle;
}
