// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/live_market_service.dart';

// ═══════════════════════════════════════════════════════════════
//  HQMLL BRANDING ASSETS WIDGET — v15.0
//  Premium Icons, Coin Images, Navigation Brand Icons
// ═══════════════════════════════════════════════════════════════

class HQLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const HQLogo({super.key, this.size = 40, this.showText = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/icon/app_icon.png',
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _fallbackLogo(size),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HQMLL',
                style: TextStyle(
                  color: const Color(0xFF00FF88),
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'QUANTUM TRADER',
                style: TextStyle(
                  color: const Color(0xFF7AAFC8),
                  fontSize: size * 0.2,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _fallbackLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0xFF00FF88), Color(0xFF001020)],
        ),
      ),
      child: Center(
        child: Text(
          'QT',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── Coin Icon Widget ──────────────────────────────────────────
class CoinIconWidget extends StatelessWidget {
  final String symbol;
  final double size;
  final bool showBorder;

  const CoinIconWidget({
    super.key,
    required this.symbol,
    this.size = 36,
    this.showBorder = true,
  });

  static const Map<String, Color> _coinColors = {
    'BTC': Color(0xFFF7931A),
    'ETH': Color(0xFF627EEA),
    'BNB': Color(0xFFF3BA2F),
    'SOL': Color(0xFF9945FF),
    'ADA': Color(0xFF0033AD),
    'DOGE': Color(0xFFC2A633),
    'AVAX': Color(0xFFE84142),
    'DOT': Color(0xFFE6007A),
    'MATIC': Color(0xFF8247E5),
    'LINK': Color(0xFF2A5ADA),
    'XRP': Color(0xFF346AA9),
    'LTC': Color(0xFFBFBFBF),
    'KAS': Color(0xFF49EACB),
    'XMR': Color(0xFFFF6600),
    'ATOM': Color(0xFF2E3148),
    'UNI': Color(0xFFFF007A),
    'NEAR': Color(0xFF00C08B),
    'ARB': Color(0xFF1B4ADD),
    'OP': Color(0xFFFF0420),
    'SUI': Color(0xFF4DA2FF),
    'INJ': Color(0xFF00A3FF),
    'TON': Color(0xFF0098EA),
    'TRX': Color(0xFFFF060A),
    'APT': Color(0xFF2DD8E8),
    'FET': Color(0xFF1DB2E8),
    'QEMMA': Color(0xFF00FF88),
    'AAPL': Color(0xFF555555),
    'TSLA': Color(0xFFCC0000),
    'GOOGL': Color(0xFF4285F4),
    'AMZN': Color(0xFFFF9900),
    'MSFT': Color(0xFF00A4EF),
    'NVDA': Color(0xFF76B900),
    'META': Color(0xFF0866FF),
    'XAU': Color(0xFFFFD700),
    'XAG': Color(0xFFC0C0C0),
    'OIL': Color(0xFF8B4513),
  };

  @override
  Widget build(BuildContext context) {
    final color = _coinColors[symbol] ?? const Color(0xFF7AAFC8);
    final iconUrl = LiveMarketService.coinIconUrls[symbol] ?? '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: showBorder
            ? Border.all(color: color.withValues(alpha: 0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipOval(
        child: iconUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: iconUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _fallbackIcon(symbol, color, size),
                placeholder: (_, __) => _shimmerIcon(color, size),
              )
            : _fallbackIcon(symbol, color, size),
      ),
    );
  }

  Widget _fallbackIcon(String sym, Color color, double size) {
    // Special local assets
    if (sym == 'QEMMA') {
      return Image.asset(
        'assets/icons/qemma_token.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _textIcon(sym, color, size),
      );
    }
    return _textIcon(sym, color, size);
  }

  Widget _textIcon(String sym, Color color, double size) {
    return Container(
      width: size,
      height: size,
      color: color.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          sym.length > 3 ? sym.substring(0, 3) : sym,
          style: TextStyle(
            color: color,
            fontSize: size * 0.28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _shimmerIcon(Color color, double size) {
    return Container(
      width: size,
      height: size,
      color: color.withValues(alpha: 0.1),
    );
  }
}

// ── Nav Brand Icon ─────────────────────────────────────────────
class NavBrandIcon extends StatelessWidget {
  final String label;
  final bool isActive;
  final double size;

  const NavBrandIcon({
    super.key,
    required this.label,
    this.isActive = false,
    this.size = 24,
  });

  static const Map<String, IconData> _navIcons = {
    'DASHBOARD': Icons.dashboard_rounded,
    'ORACLE': Icons.remove_red_eye_rounded,
    'TRADING': Icons.candlestick_chart_rounded,
    'MARKT': Icons.bar_chart_rounded,
    'PORTFOLIO': Icons.pie_chart_rounded,
    'WALLET': Icons.account_balance_wallet_rounded,
    'QEMMA': Icons.token_rounded,
    'AI FORGE': Icons.auto_awesome_rounded,
    'ALARMS': Icons.notifications_rounded,
    'SETTINGS': Icons.settings_rounded,
    'DOWNLOAD': Icons.download_rounded,
    'ENTERPRISE': Icons.verified_rounded,
    'VAULT': Icons.enhanced_encryption,
    'AI GENIUS': Icons.psychology_rounded,
    'MINING': Icons.hardware_rounded,
    'DEPLOY': Icons.rocket_launch_rounded,
    'CMD': Icons.terminal_rounded,
    'FIAT': Icons.euro_rounded,
    'BOT': Icons.smart_toy_rounded,
    'SOCIAL': Icons.groups_rounded,
    'ANALYTICS': Icons.analytics_rounded,
    'DeFi': Icons.account_balance_rounded,
    'INTEL': Icons.shield_rounded,
    'NEWS': Icons.newspaper_rounded,
    'WRITER': Icons.edit_note_rounded,
  };

  static const Map<String, Color> _navColors = {
    'DASHBOARD': Color(0xFF00FF88),
    'ORACLE': Color(0xFF00AAFF),
    'TRADING': Color(0xFFFFAA00),
    'MARKT': Color(0xFF00FFCC),
    'PORTFOLIO': Color(0xFFAA44FF),
    'WALLET': Color(0xFF00FF88),
    'QEMMA': Color(0xFFFFD700),
    'AI FORGE': Color(0xFF00AAFF),
    'ALARMS': Color(0xFFFF4466),
    'SETTINGS': Color(0xFF7AAFC8),
    'DOWNLOAD': Color(0xFF00FF88),
    'ENTERPRISE': Color(0xFFFFAA00),
    'VAULT': Color(0xFFFF4466),
    'AI GENIUS': Color(0xFFAA44FF),
    'MINING': Color(0xFFFF8800),
    'DEPLOY': Color(0xFF00AAFF),
    'CMD': Color(0xFF00FF88),
    'FIAT': Color(0xFF00FFAA),
    'BOT': Color(0xFF00AAFF),
    'SOCIAL': Color(0xFFFF66AA),
    'ANALYTICS': Color(0xFF44AAFF),
    'DeFi': Color(0xFF8844FF),
    'INTEL': Color(0xFF00FF88),
    'NEWS': Color(0xFF00AAFF),
    'WRITER': Color(0xFFAA44FF),
  };

  @override
  Widget build(BuildContext context) {
    final icon = _navIcons[label] ?? Icons.circle;
    final color = _navColors[label] ?? const Color(0xFF7AAFC8);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size + 8,
      height: size + 8,
      decoration: isActive
          ? BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            )
          : null,
      child: Icon(
        icon,
        size: size,
        color: isActive ? color : const Color(0xFF4A7A9B),
      ),
    );
  }
}
