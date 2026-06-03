/// HQMLL Quantum Trader — Coin SVG Branding Sheet v41.0
/// Professional original coin logos via CustomPainter + vector geometry
/// All 12 major coins: BTC/ETH/SOL/BNB/XRP/ADA/AVAX/MATIC/DOT/LINK/UNI/ATOM
/// Zero external dependencies — fully offline-capable
/// Grigori Saks · 2025
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
// COIN BRAND COLOR PALETTE — Official HEX colors
// ══════════════════════════════════════════════════════════════
class CoinColors {
  static const btc  = Color(0xFFF7931A);  // Bitcoin Orange
  static const btc2 = Color(0xFFFFAF3F);
  static const eth  = Color(0xFF627EEA);  // Ethereum Blue
  static const eth2 = Color(0xFF8DA4F1);
  static const sol  = Color(0xFF9945FF);  // Solana Purple
  static const sol2 = Color(0xFF14F195);  // Solana Green
  static const bnb  = Color(0xFFF3BA2F);  // BNB Yellow
  static const bnb2 = Color(0xFFFFD96A);
  static const xrp  = Color(0xFF00AAE4);  // XRP Blue
  static const xrp2 = Color(0xFF6ACFF0);
  static const ada  = Color(0xFF0033AD);  // Cardano Blue
  static const ada2 = Color(0xFF2F6FFF);
  static const avax = Color(0xFFE84142);  // Avalanche Red
  static const avax2 = Color(0xFFFF6B6B);
  static const matic = Color(0xFF8247E5); // Polygon Purple
  static const matic2 = Color(0xFFAA79F0);
  static const dot  = Color(0xFFE6007A);  // Polkadot Pink
  static const dot2 = Color(0xFFFF4DB5);
  static const link = Color(0xFF2A5ADA);  // Chainlink Blue
  static const link2 = Color(0xFF5984F0);
  static const uni  = Color(0xFFFF007A);  // Uniswap Pink
  static const uni2 = Color(0xFFFF6BAF);
  static const atom = Color(0xFF2E3148);  // Cosmos Dark
  static const atom2 = Color(0xFF6F7390);
}

// ══════════════════════════════════════════════════════════════
// MAIN COIN LOGO WIDGET — Entry point
// ══════════════════════════════════════════════════════════════
class CoinLogo extends StatelessWidget {
  final String symbol;
  final double size;
  final bool showShadow;
  final bool circular;

  const CoinLogo({
    super.key,
    required this.symbol,
    this.size = 40,
    this.showShadow = false,
    this.circular = true,
  });

  @override
  Widget build(BuildContext context) {
    final painter = _getPainter(symbol.toUpperCase());
    Widget logo = CustomPaint(
      size: Size(size, size),
      painter: painter,
    );
    if (showShadow) {
      logo = Container(
        decoration: BoxDecoration(
          shape: circular ? BoxShape.circle : BoxShape.rectangle,
          boxShadow: [
            BoxShadow(
              color: _getShadowColor(symbol).withValues(alpha: 0.4),
              blurRadius: size * 0.3,
              spreadRadius: size * 0.02,
            ),
          ],
        ),
        child: logo,
      );
    }
    return logo;
  }

  static CustomPainter _getPainter(String sym) {
    switch (sym) {
      case 'BTC':  return _BtcPainter();
      case 'ETH':  return _EthPainter();
      case 'SOL':  return _SolPainter();
      case 'BNB':  return _BnbPainter();
      case 'XRP':  return _XrpPainter();
      case 'ADA':  return _AdaPainter();
      case 'AVAX': return _AvaxPainter();
      case 'MATIC':return _MaticPainter();
      case 'DOT':  return _DotPainter();
      case 'LINK': return _LinkPainter();
      case 'UNI':  return _UniPainter();
      case 'ATOM': return _AtomPainter();
      default:     return _GenericCoinPainter(sym);
    }
  }

  static Color _getShadowColor(String sym) {
    switch (sym.toUpperCase()) {
      case 'BTC':  return CoinColors.btc;
      case 'ETH':  return CoinColors.eth;
      case 'SOL':  return CoinColors.sol;
      case 'BNB':  return CoinColors.bnb;
      case 'XRP':  return CoinColors.xrp;
      case 'ADA':  return CoinColors.ada2;
      case 'AVAX': return CoinColors.avax;
      case 'MATIC':return CoinColors.matic;
      case 'DOT':  return CoinColors.dot;
      case 'LINK': return CoinColors.link;
      case 'UNI':  return CoinColors.uni;
      case 'ATOM': return CoinColors.atom2;
      default:     return Colors.white;
    }
  }
}

// ══════════════════════════════════════════════════════════════
// COIN LOGO SHEET — Horizontal scrollable branding sheet
// ══════════════════════════════════════════════════════════════
class CoinBrandingSheet extends StatelessWidget {
  final double logoSize;
  final bool showLabels;
  final bool showShadows;
  final String? selectedSymbol;
  final void Function(String)? onCoinTap;

  static const _coins = [
    'BTC','ETH','SOL','BNB','XRP','ADA','AVAX','MATIC','DOT','LINK','UNI','ATOM'
  ];

  const CoinBrandingSheet({
    super.key,
    this.logoSize = 48,
    this.showLabels = true,
    this.showShadows = true,
    this.selectedSymbol,
    this.onCoinTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: _coins.map((sym) => _CoinChip(
          symbol: sym,
          size: logoSize,
          showLabel: showLabels,
          showShadow: showShadows,
          selected: selectedSymbol == sym,
          onTap: onCoinTap != null ? () => onCoinTap!(sym) : null,
        )).toList(),
      ),
    );
  }
}

class _CoinChip extends StatelessWidget {
  final String symbol;
  final double size;
  final bool showLabel;
  final bool showShadow;
  final bool selected;
  final VoidCallback? onTap;

  const _CoinChip({
    required this.symbol,
    required this.size,
    required this.showLabel,
    required this.showShadow,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: EdgeInsets.all(selected ? 3 : 0),
        decoration: selected ? BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
        ) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CoinLogo(symbol: symbol, size: size, showShadow: showShadow),
            if (showLabel) ...[
              const SizedBox(height: 4),
              Text(
                symbol,
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  color: selected ? Colors.white : Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// COIN LOGO GRID — 4-column grid layout for full branding sheet
// ══════════════════════════════════════════════════════════════
class CoinLogoGrid extends StatelessWidget {
  final double logoSize;
  final bool showLabels;
  final String? selectedSymbol;
  final void Function(String)? onCoinTap;

  static const _coins = [
    ('BTC','Bitcoin'),('ETH','Ethereum'),('SOL','Solana'),('BNB','BNB'),
    ('XRP','XRP'),('ADA','Cardano'),('AVAX','Avalanche'),('MATIC','Polygon'),
    ('DOT','Polkadot'),('LINK','Chainlink'),('UNI','Uniswap'),('ATOM','Cosmos'),
  ];

  const CoinLogoGrid({
    super.key,
    this.logoSize = 56,
    this.showLabels = true,
    this.selectedSymbol,
    this.onCoinTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _coins.length,
      itemBuilder: (_, i) {
        final (sym, name) = _coins[i];
        final isSelected = selectedSymbol == sym;
        return GestureDetector(
          onTap: onCoinTap != null ? () => onCoinTap!(sym) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? CoinLogo._getShadowColor(sym).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: isSelected
                    ? CoinLogo._getShadowColor(sym).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.08),
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CoinLogo(symbol: sym, size: logoSize, showShadow: isSelected),
                const SizedBox(height: 6),
                Text(sym,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
                if (showLabels)
                  Text(name,
                    style: const TextStyle(fontSize: 8, color: Colors.white38),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BTC — Bitcoin CustomPainter
// Orange circle + white ₿ symbol with serifs
// ══════════════════════════════════════════════════════════════
class _BtcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    // Background gradient circle
    final bgPaint = Paint()
      ..shader = RadialGradient(colors: [CoinColors.btc2, CoinColors.btc])
          .createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, bgPaint);

    // White ₿ symbol using text
    final tp = TextPainter(
      text: TextSpan(
        text: '₿',
        style: TextStyle(
          fontSize: size.width * 0.58,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(r - tp.width / 2, r - tp.height / 2));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════
// ETH — Ethereum CustomPainter
// Dark circle + iconic diamond/rhombus logo
// ══════════════════════════════════════════════════════════════
class _EthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    // BG
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [CoinColors.eth2, CoinColors.eth],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, bgPaint);

    // ETH diamond shape
    final scale = size.width / 40.0;
    final cx = r;
    final cy = r;

    // Top diamond (upper half)
    final topPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final topPath = Path()
      ..moveTo(cx, cy - 14 * scale)
      ..lineTo(cx - 9 * scale, cy - 1 * scale)
      ..lineTo(cx, cy + 1 * scale)
      ..lineTo(cx + 9 * scale, cy - 1 * scale)
      ..close();
    canvas.drawPath(topPath, topPaint);

    // Bottom diamond (lower half)
    final botPath = Path()
      ..moveTo(cx, cy - 14 * scale)
      ..lineTo(cx - 9 * scale, cy - 1 * scale)
      ..lineTo(cx, cy + 1 * scale)
      ..lineTo(cx + 9 * scale, cy - 1 * scale)
      ..close();
    canvas.drawPath(botPath, topPaint);

    // Lower portion
    final lowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)..style = PaintingStyle.fill;
    final lowPath = Path()
      ..moveTo(cx - 9 * scale, cy + 1 * scale)
      ..lineTo(cx, cy + 14 * scale)
      ..lineTo(cx + 9 * scale, cy + 1 * scale)
      ..lineTo(cx, cy + 3 * scale)
      ..close();
    canvas.drawPath(lowPath, lowPaint);

    // Middle separator
    final midPath = Path()
      ..moveTo(cx - 9 * scale, cy + 1 * scale)
      ..lineTo(cx, cy + 3 * scale)
      ..lineTo(cx + 9 * scale, cy + 1 * scale)
      ..lineTo(cx, cy - 1 * scale)
      ..close();
    canvas.drawPath(midPath, topPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════
// SOL — Solana CustomPainter
// Gradient circle + 3 diagonal bars (iconic SOL logo)
// ══════════════════════════════════════════════════════════════
class _SolPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    // Solana gradient background
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight, end: Alignment.bottomLeft,
        colors: [CoinColors.sol2, CoinColors.sol],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, bgPaint);

    // 3 diagonal SOL bars
    final barPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final scale = size.width / 40.0;
    for (int i = 0; i < 3; i++) {
      final yOffset = (-8 + i * 8) * scale;
      final path = Path()
        ..moveTo(c.dx - 11 * scale, c.dy + yOffset - 3 * scale)
        ..lineTo(c.dx + 5 * scale,  c.dy + yOffset - 3 * scale)
        ..lineTo(c.dx + 11 * scale, c.dy + yOffset + 3 * scale)
        ..lineTo(c.dx - 5 * scale,  c.dy + yOffset + 3 * scale)
        ..close();
      canvas.drawPath(path, barPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════
// BNB — Binance Coin CustomPainter
// Yellow circle + BNB diamond grid logo
// ══════════════════════════════════════════════════════════════
class _BnbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    // Yellow BG
    final bgPaint = Paint()
      ..shader = RadialGradient(colors: [CoinColors.bnb2, CoinColors.bnb])
          .createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, bgPaint);

    // BNB letter
    final tp = TextPainter(
      text: TextSpan(
        text: 'BNB',
        style: TextStyle(
          fontSize: size.width * 0.30,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1,
          letterSpacing: -1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(r - tp.width / 2, r - tp.height / 2));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════
// XRP — Ripple CustomPainter
// Blue circle + XRP symbol
// ══════════════════════════════════════════════════════════════
class _XrpPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [CoinColors.xrp2, CoinColors.xrp],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, bgPaint);

    // XRP text
    final tp = TextPainter(
      text: TextSpan(
        text: 'XRP',
        style: TextStyle(
          fontSize: size.width * 0.30,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(r - tp.width / 2, r - tp.height / 2));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════
// ADA — Cardano CustomPainter
// Blue gradient + ADA flower pattern (simplified)
// ══════════════════════════════════════════════════════════════
class _AdaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [CoinColors.ada2, CoinColors.ada],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, bgPaint);

    // Cardano dots pattern (Ouroboros simplified)
    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final scale = size.width / 40.0;

    // Center dot
    canvas.drawCircle(c, 3 * scale, dotPaint);

    // Ring of 8 dots
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi - math.pi / 2;
      final dx = c.dx + 10 * scale * math.cos(angle);
      final dy = c.dy + 10 * scale * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 2 * scale, dotPaint);
    }

    // Outer ring of 4 dots
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * 2 * math.pi - math.pi / 4;
      final dx = c.dx + 15 * scale * math.cos(angle);
      final dy = c.dy + 15 * scale * math.sin(angle);
      final dp = Paint()..color = Colors.white.withValues(alpha: 0.5);
      canvas.drawCircle(Offset(dx, dy), 1.5 * scale, dp);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════
// AVAX — Avalanche CustomPainter
// Red circle + A with mountain lines
// ══════════════════════════════════════════════════════════════
class _AvaxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    final bgPaint = Paint()
      ..shader = RadialGradient(colors: [CoinColors.avax2, CoinColors.avax])
          .createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, bgPaint);

    // AVAX triangle / A shape
    final scale = size.width / 40.0;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Left mountain line
    canvas.drawLine(
      Offset(c.dx - 12 * scale, c.dy + 10 * scale),
      Offset(c.dx, c.dy - 12 * scale), paint,
    );
    // Right mountain line
    canvas.drawLine(
      Offset(c.dx, c.dy - 12 * scale),
      Offset(c.dx + 12 * scale, c.dy + 10 * scale), paint,
    );
    // Horizontal bar
    canvas.drawLine(
      Offset(c.dx - 6 * scale, c.dy + 2 * scale),
      Offset(c.dx + 6 * scale, c.dy + 2 * scale), paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════
// MATIC — Polygon CustomPainter
// Purple gradient + hexagonal P symbol
// ══════════════════════════════════════════════════════════════
class _MaticPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [CoinColors.matic2, CoinColors.matic],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, bgPaint);

    // Polygon hexagon outline
    final hexPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065;
    final scale = size.width * 0.32;
    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * math.pi - math.pi / 6;
      final x = c.dx + scale * math.cos(angle);
      final y = c.dy + scale * math.sin(angle);
      if (i == 0) hexPath.moveTo(x, y); else hexPath.lineTo(x, y);
    }
    hexPath.close();
    canvas.drawPath(hexPath, hexPaint);

    // P letter inside
    final tp = TextPainter(
      text: TextSpan(
        text: 'P',
        style: TextStyle(
          fontSize: size.width * 0.38,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(r - tp.width / 2, r - tp.height / 2));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════
// DOT — Polkadot CustomPainter
// Pink background + dot matrix
// ══════════════════════════════════════════════════════════════
class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    final bgPaint = Paint()
      ..shader = RadialGradient(colors: [CoinColors.dot2, CoinColors.dot])
          .createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, bgPaint);

    // Polkadot circles pattern
    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final scale = size.width / 40.0;

    // Center large dot
    canvas.drawCircle(c, 5 * scale, dotPaint);

    // 6 surrounding dots
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * math.pi - math.pi / 2;
      final dx = c.dx + 13 * scale * math.cos(angle);
      final dy = c.dy + 13 * scale * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 3.5 * scale, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════
// LINK — Chainlink CustomPainter
// Blue hexagon + LINK chain symbol
// ══════════════════════════════════════════════════════════════
class _LinkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    // Hexagonal background
    final hexPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [CoinColors.link2, CoinColors.link],
      ).createShader(Rect.fromCircle(center: c, radius: r));

    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * math.pi - math.pi / 6;
      final x = c.dx + r * math.cos(angle);
      final y = c.dy + r * math.sin(angle);
      if (i == 0) hexPath.moveTo(x, y); else hexPath.lineTo(x, y);
    }
    hexPath.close();
    canvas.drawPath(hexPath, hexPaint);

    // LINK text
    final tp = TextPainter(
      text: TextSpan(
        text: '⬡',
        style: TextStyle(
          fontSize: size.width * 0.62,
          color: Colors.white.withValues(alpha: 0.3),
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(r - tp.width / 2, r - tp.height / 2));

    final tp2 = TextPainter(
      text: TextSpan(
        text: 'L',
        style: TextStyle(
          fontSize: size.width * 0.48,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(r - tp2.width / 2, r - tp2.height / 2));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════
// UNI — Uniswap CustomPainter
// Pink circle + Unicorn horn / U symbol
// ══════════════════════════════════════════════════════════════
class _UniPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    final bgPaint = Paint()
      ..shader = RadialGradient(colors: [CoinColors.uni2, CoinColors.uni])
          .createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, bgPaint);

    // Unicorn U shape
    final scale = size.width / 40.0;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(c.dx - 9 * scale, c.dy - 10 * scale)
      ..lineTo(c.dx - 9 * scale, c.dy + 3 * scale)
      ..arcToPoint(
        Offset(c.dx + 9 * scale, c.dy + 3 * scale),
        radius: Radius.circular(9 * scale),
        clockwise: false,
      )
      ..lineTo(c.dx + 9 * scale, c.dy - 10 * scale);
    canvas.drawPath(path, paint);

    // Horn on top
    final hornPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final hornPath = Path()
      ..moveTo(c.dx - 2 * scale, c.dy - 10 * scale)
      ..lineTo(c.dx, c.dy - 17 * scale)
      ..lineTo(c.dx + 2 * scale, c.dy - 10 * scale)
      ..close();
    canvas.drawPath(hornPath, hornPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════
// ATOM — Cosmos CustomPainter
// Dark space background + atom orbital rings
// ══════════════════════════════════════════════════════════════
class _AtomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    // Dark cosmos BG
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF4A4F6E), CoinColors.atom],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, bgPaint);

    // Atom orbital rings
    final scale = size.width / 40.0;
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;

    // 3 ellipse orbits at different angles
    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate((i / 3) * math.pi);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 28 * scale, height: 12 * scale),
        ringPaint,
      );
      canvas.restore();
    }

    // Center nucleus
    canvas.drawCircle(c, 3 * scale, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════
// GENERIC COIN PAINTER — Fallback for unknown symbols
// ══════════════════════════════════════════════════════════════
class _GenericCoinPainter extends CustomPainter {
  final String symbol;
  _GenericCoinPainter(this.symbol);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final hash = symbol.codeUnits.fold(0, (a, b) => a + b);
    final hue = (hash * 37.0) % 360;

    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          HSLColor.fromAHSL(1, hue, 0.7, 0.6).toColor(),
          HSLColor.fromAHSL(1, hue, 0.7, 0.35).toColor(),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, bgPaint);

    final disp = symbol.length > 3 ? symbol.substring(0, 3) : symbol;
    final tp = TextPainter(
      text: TextSpan(
        text: disp,
        style: TextStyle(
          fontSize: size.width * (symbol.length > 2 ? 0.28 : 0.38),
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(r - tp.width / 2, r - tp.height / 2));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════
// CONVENIENCE EXTENSIONS
// ══════════════════════════════════════════════════════════════
extension CoinLogoX on String {
  /// e.g.  'BTC'.coinLogo(size: 32)
  Widget coinLogo({double size = 32, bool shadow = false}) =>
      CoinLogo(symbol: this, size: size, showShadow: shadow);

  /// Brand color for the coin
  Color get coinColor => CoinLogo._getShadowColor(this);
}
