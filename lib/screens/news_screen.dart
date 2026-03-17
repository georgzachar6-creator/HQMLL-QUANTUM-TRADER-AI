import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});
  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  Timer? _refreshTimer;
  String _selectedCategory = 'Alle';
  bool _isRefreshing = false;
  int _sentimentIndex = 68;

  final List<String> _categories = [
    'Alle', 'Bitcoin', 'Ethereum', 'QEMMA', 'DeFi', 'Regulierung', 'Technik',
  ];

  final List<_NewsItem> _allNews = [
    const _NewsItem(
      id: 'n1',
      title: 'BlackRock Bitcoin ETF verzeichnet Rekord-Zuflüsse von \$1.4 Mrd an einem Tag',
      summary: 'Der iShares Bitcoin Trust ETF (IBIT) von BlackRock hat mit \$1,4 Milliarden Nettozuflüssen an einem einzigen Handelstag einen neuen Rekord aufgestellt. Analysten sehen dies als starkes Signal für institutionelle Akzeptanz.',
      source: 'CoinTelegraph',
      category: 'Bitcoin',
      sentiment: SentimentType.veryBullish,
      timeAgo: '14 Min',
      readTime: '2 Min',
      imageColor: 0xFFF7931A,
      tags: ['BTC', 'ETF', 'Institutional'],
      impact: 'HOCH',
    ),
    const _NewsItem(
      id: 'n2',
      title: 'Ethereum Layer-2 Volumen überschreitet erstmals \$50 Mrd – Neue Ära beginnt',
      summary: 'Das kombinierte Transaktionsvolumen aller Ethereum Layer-2-Netzwerke (Arbitrum, Optimism, Base) hat die \$50-Milliarden-Marke überschritten. Experten sehen dies als Beweis für die Skalierbarkeit des Ethereum-Ökosystems.',
      source: 'The Block',
      category: 'Ethereum',
      sentiment: SentimentType.bullish,
      timeAgo: '28 Min',
      readTime: '3 Min',
      imageColor: 0xFF627EEA,
      tags: ['ETH', 'Layer2', 'DeFi'],
      impact: 'MITTEL',
    ),
    const _NewsItem(
      id: 'n3',
      title: 'QEMMA Token: Proof-of-Intelligence Mining erreicht 10.000 aktive Nodes',
      summary: 'Das HQMLL-Netzwerk meldet einen Meilenstein: 10.000 aktive Mining-Nodes nehmen am Proof-of-Intelligence-Konsensus teil. Die Mining-Schwierigkeit wird automatisch angepasst um die Qualität der KI-Beiträge zu maximieren.',
      source: 'HQMLL Research',
      category: 'QEMMA',
      sentiment: SentimentType.veryBullish,
      timeAgo: '45 Min',
      readTime: '4 Min',
      imageColor: 0xFF00FFB2,
      tags: ['QEMMA', 'Mining', 'AI'],
      impact: 'HOCH',
      isHighlighted: true,
    ),
    const _NewsItem(
      id: 'n4',
      title: 'EU reguliert DeFi-Protokolle: MiCA-Framework tritt in zweite Phase',
      summary: 'Die Europäische Union hat Phase 2 des MiCA-Rahmenwerks gestartet, das nun auch dezentralisierte Finanzprotokolle umfasst. DEX-Betreiber müssen bis Q3 2026 Compliance-Anforderungen erfüllen.',
      source: 'Reuters Crypto',
      category: 'Regulierung',
      sentiment: SentimentType.bearish,
      timeAgo: '1 Std',
      readTime: '5 Min',
      imageColor: 0xFF4A90E2,
      tags: ['DeFi', 'EU', 'MiCA', 'Regulierung'],
      impact: 'HOCH',
    ),
    const _NewsItem(
      id: 'n5',
      title: 'Solana Firedancer Client geht in Mainnet-Beta – 1 Mio TPS rückt näher',
      summary: 'Jump Crypto hat den Firedancer-Validator-Client auf Solanas Mainnet-Beta gestartet. Erste Benchmarks zeigen Durchsatz von über 200.000 TPS, mit Potenzial für 1 Million TPS bei vollständiger Implementierung.',
      source: 'Decrypt',
      category: 'Technik',
      sentiment: SentimentType.bullish,
      timeAgo: '2 Std',
      readTime: '3 Min',
      imageColor: 0xFF9945FF,
      tags: ['SOL', 'Technik', 'Performance'],
      impact: 'MITTEL',
    ),
    const _NewsItem(
      id: 'n6',
      title: 'Federal Reserve: Krypto-freundliche Regulierung könnte Dollar-Dominanz stärken',
      summary: 'Ein Fed-Papier argumentiert, dass eine klare Krypto-Regulierung die Dollar-Dominanz im globalen digitalen Zahlungsverkehr stärken könnte, anstatt sie zu gefährden. Stablecoins könnten als Dollarisierungs-Tool wirken.',
      source: 'Bloomberg Crypto',
      category: 'Regulierung',
      sentiment: SentimentType.neutral,
      timeAgo: '3 Std',
      readTime: '6 Min',
      imageColor: 0xFF2ECC71,
      tags: ['USD', 'Stablecoin', 'Fed'],
      impact: 'MITTEL',
    ),
    const _NewsItem(
      id: 'n7',
      title: 'Uniswap v4 Live: Hook-System ermöglicht 99% Gasgebühren-Reduktion',
      summary: 'Uniswap v4 ist auf Ethereum Mainnet gestartet. Das neue Hook-System erlaubt benutzerdefinierte Logik in Liquiditätspools und hat in ersten Tests die Gasgebühren um bis zu 99% im Vergleich zu v3 reduziert.',
      source: 'DeFi Pulse',
      category: 'DeFi',
      sentiment: SentimentType.veryBullish,
      timeAgo: '4 Std',
      readTime: '4 Min',
      imageColor: 0xFFFF007A,
      tags: ['UNI', 'DeFi', 'DEX'],
      impact: 'HOCH',
    ),
    const _NewsItem(
      id: 'n8',
      title: 'MicroStrategy kauft weitere 5.000 BTC – Gesamtbestand nun über 210.000 BTC',
      summary: 'MicroStrategy hat bekannt gegeben, weitere 5.000 Bitcoin für ca. 340 Millionen Dollar erworben zu haben. Der Gesamtbestand beläuft sich nun auf über 210.000 BTC, was das Unternehmen zum größten öffentlichen Bitcoin-Halter macht.',
      source: 'CoinDesk',
      category: 'Bitcoin',
      sentiment: SentimentType.veryBullish,
      timeAgo: '5 Std',
      readTime: '2 Min',
      imageColor: 0xFFF7931A,
      tags: ['BTC', 'Institutional', 'MicroStrategy'],
      impact: 'HOCH',
    ),
    const _NewsItem(
      id: 'n9',
      title: 'Binance CZ kehrt zurück: Neue Beraterrolle bei nationaler Blockchain-Initiative',
      summary: 'Changpeng Zhao (CZ), ehemaliger Binance-CEO, hat seine erste offizielle Rolle nach seiner Haftstrafe bekannt gegeben: Er wird Berater für die nationale Blockchain-Infrastruktur eines südostasiatischen Landes.',
      source: 'CoinTelegraph',
      category: 'Alle',
      sentiment: SentimentType.neutral,
      timeAgo: '7 Std',
      readTime: '3 Min',
      imageColor: 0xFFF3BA2F,
      tags: ['Binance', 'CZ', 'Regulierung'],
      impact: 'NIEDRIG',
    ),
    const _NewsItem(
      id: 'n10',
      title: 'Quantum Computing Bedrohung für Krypto: NIST veröffentlicht Post-Quantum Standards',
      summary: 'Das NIST hat finale Post-Quantum-Kryptografie-Standards veröffentlicht. HQMLL war unter den ersten Projekten, die Quantum-resistente Algorithmen (Lattice-based) in ihr Protokoll integriert haben.',
      source: 'HQMLL Research',
      category: 'Technik',
      sentiment: SentimentType.neutral,
      timeAgo: '9 Std',
      readTime: '7 Min',
      imageColor: 0xFF00FFB2,
      tags: ['Quantum', 'Security', 'HQMLL'],
      impact: 'HOCH',
      isHighlighted: true,
    ),
  ];

  List<_NewsItem> get _filteredNews {
    if (_selectedCategory == 'Alle') return _allNews;
    return _allNews.where((n) => n.category == _selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _slideCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    )..forward();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _sentimentIndex = 60 + Random().nextInt(20));
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
      _isRefreshing = false;
      _sentimentIndex = 60 + Random().nextInt(25);
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(p),
            _buildSentimentBar(p),
            _buildCategoryChips(p),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: p.primary,
                backgroundColor: p.surface,
                child: _filteredNews.isEmpty
                    ? _buildEmpty(p)
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: _filteredNews.length + 1,
                        itemBuilder: (ctx, i) {
                          if (i == 0) return _buildBreakingBanner(p);
                          final news = _filteredNews[i - 1];
                          return _buildNewsCard(news, p, i - 1);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────
  Widget _buildHeader(dynamic p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.primary.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [p.primary, p.secondary]),
              boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.3), blurRadius: 8)],
            ),
            child: const Icon(Icons.newspaper_rounded, color: Colors.black, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QUANTUM NEWS', style: GoogleFonts.rajdhani(
                    color: p.primary, fontSize: 16,
                    fontWeight: FontWeight.bold, letterSpacing: 2)),
                Text('Live Crypto Intelligence Feed', style: GoogleFonts.spaceMono(
                    color: p.textSecondary, fontSize: 9)),
              ],
            ),
          ),
          // Live-Dot + Refresh
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08 + _pulseCtrl.value * 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(
                    alpha: 0.3 + _pulseCtrl.value * 0.2)),
              ),
              child: Row(children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                      boxShadow: [BoxShadow(
                          color: Colors.green.withValues(alpha: 0.5),
                          blurRadius: 6 * _pulseCtrl.value)],
                    )),
                const SizedBox(width: 5),
                Text('LIVE', style: GoogleFonts.spaceMono(
                    color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _refresh,
            child: _isRefreshing
                ? SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: p.primary))
                : Icon(Icons.refresh, color: p.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Sentiment Bar ──────────────────────────────
  Widget _buildSentimentBar(dynamic p) {
    final fearLabel = _sentimentIndex < 25 ? 'EXTREME ANGST'
        : _sentimentIndex < 45 ? 'ANGST'
        : _sentimentIndex < 55 ? 'NEUTRAL'
        : _sentimentIndex < 75 ? 'GIER'
        : 'EXTREME GIER';
    final sentColor = _sentimentIndex < 45 ? p.negative
        : _sentimentIndex < 55 ? p.textSecondary
        : p.positive;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.primary.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('FEAR & GREED INDEX', style: GoogleFonts.spaceMono(
                  color: p.textSecondary, fontSize: 9, letterSpacing: 1)),
              Row(children: [
                Text(fearLabel, style: GoogleFonts.rajdhani(
                    color: sentColor, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('$_sentimentIndex', style: GoogleFonts.rajdhani(
                    color: sentColor, fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          // Gradient-Balken
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      p.negative, Colors.orange, p.accent, p.positive,
                    ]),
                  ),
                ),
                Positioned(
                  left: (_sentimentIndex / 100) *
                      (MediaQuery.of(context).size.width - 80) - 4,
                  child: Container(
                    width: 12, height: 12,
                    margin: const EdgeInsets.only(top: -2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.white,
                      border: Border.all(color: sentColor, width: 2),
                      boxShadow: [BoxShadow(color: sentColor.withValues(alpha: 0.5), blurRadius: 6)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Extreme Angst (0)', style: GoogleFonts.spaceMono(
                  color: p.textSecondary, fontSize: 8)),
              Text('Extreme Gier (100)', style: GoogleFonts.spaceMono(
                  color: p.textSecondary, fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Category Chips ──────────────────────────────
  Widget _buildCategoryChips(dynamic p) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? p.primary.withValues(alpha: 0.15)
                    : p.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? p.primary : p.primary.withValues(alpha: 0.15),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Text(cat, style: GoogleFonts.rajdhani(
                  color: selected ? p.primary : p.textSecondary,
                  fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        },
      ),
    );
  }

  // ── Breaking Banner ─────────────────────────────
  Widget _buildBreakingBanner(dynamic p) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            p.negative.withValues(alpha: 0.15),
            p.primary.withValues(alpha: 0.08),
          ]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: p.negative.withValues(alpha: 0.3 + _pulseCtrl.value * 0.2),
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: p.negative,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('BREAKING', style: GoogleFonts.spaceMono(
                color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold,
                letterSpacing: 1)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'SEC genehmigt Spot-Ethereum-ETF-Optionen · BTC testet \$70K Widerstand',
              style: GoogleFonts.exo(color: p.textPrimary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: p.textSecondary, size: 12),
        ]),
      ),
    );
  }

  // ── News Card ────────────────────────────────────
  Widget _buildNewsCard(_NewsItem news, dynamic p, int index) {
    final sentColor = news.sentiment == SentimentType.veryBullish ? p.positive
        : news.sentiment == SentimentType.bullish ? p.positive.withValues(alpha: 0.7)
        : news.sentiment == SentimentType.bearish ? p.negative.withValues(alpha: 0.7)
        : news.sentiment == SentimentType.veryBearish ? p.negative
        : p.textSecondary;
    final sentIcon = news.sentiment == SentimentType.veryBullish ? Icons.rocket_launch
        : news.sentiment == SentimentType.bullish ? Icons.trending_up
        : news.sentiment == SentimentType.bearish ? Icons.trending_down
        : news.sentiment == SentimentType.veryBearish ? Icons.trending_down
        : Icons.remove;
    final sentLabel = news.sentiment == SentimentType.veryBullish ? 'SEHR BULLISCH'
        : news.sentiment == SentimentType.bullish ? 'BULLISCH'
        : news.sentiment == SentimentType.bearish ? 'BEARISCH'
        : news.sentiment == SentimentType.veryBearish ? 'SEHR BEARISCH'
        : 'NEUTRAL';

    return GestureDetector(
      onTap: () => _showNewsDetail(news, p),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: news.isHighlighted
                ? p.primary.withValues(alpha: 0.4)
                : p.primary.withValues(alpha: 0.1),
            width: news.isHighlighted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: news.isHighlighted
                  ? p.primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Color(news.imageColor).withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(
                  bottom: BorderSide(color: Color(news.imageColor).withValues(alpha: 0.15)),
                ),
              ),
              child: Row(
                children: [
                  // Kategorie-Farbe
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(news.imageColor).withValues(alpha: 0.15),
                      border: Border.all(color: Color(news.imageColor).withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Text(
                        news.category == 'QEMMA' ? 'Q'
                            : news.category == 'Bitcoin' ? '₿'
                            : news.category == 'Ethereum' ? 'Ξ'
                            : news.category.substring(0, 1),
                        style: GoogleFonts.rajdhani(
                            color: Color(news.imageColor), fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(news.source, style: GoogleFonts.spaceMono(
                              color: p.textSecondary, fontSize: 9)),
                          const Spacer(),
                          Text(news.timeAgo, style: GoogleFonts.spaceMono(
                              color: p.textSecondary, fontSize: 9)),
                        ]),
                        const SizedBox(height: 2),
                        Row(children: [
                          Text(news.category, style: GoogleFonts.rajdhani(
                              color: Color(news.imageColor), fontSize: 11,
                              fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          // Impact Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: _impactColor(news.impact, p).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: _impactColor(news.impact, p).withValues(alpha: 0.4)),
                            ),
                            child: Text('Impact: ${news.impact}',
                                style: GoogleFonts.spaceMono(
                                    color: _impactColor(news.impact, p),
                                    fontSize: 7, fontWeight: FontWeight.bold)),
                          ),
                          if (news.isHighlighted) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: p.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('HQMLL', style: GoogleFonts.spaceMono(
                                  color: p.primary, fontSize: 7, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(news.title,
                      style: GoogleFonts.rajdhani(
                          color: p.textPrimary, fontSize: 15,
                          fontWeight: FontWeight.bold, height: 1.3),
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(news.summary,
                      style: GoogleFonts.exo(
                          color: p.textSecondary, fontSize: 12, height: 1.5),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  // Tags + Sentiment
                  Row(
                    children: [
                      // Tags
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          children: news.tags.take(3).map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('#$tag', style: GoogleFonts.spaceMono(
                                color: p.textSecondary, fontSize: 8)),
                          )).toList(),
                        ),
                      ),
                      // Sentiment
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: sentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: sentColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          Icon(sentIcon, color: sentColor, size: 12),
                          const SizedBox(width: 4),
                          Text(sentLabel, style: GoogleFonts.spaceMono(
                              color: sentColor, fontSize: 7, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Read Time
                  Row(children: [
                    Icon(Icons.access_time, color: p.textSecondary, size: 11),
                    const SizedBox(width: 4),
                    Text('Lesezeit: ${news.readTime}',
                        style: GoogleFonts.spaceMono(color: p.textSecondary, fontSize: 9)),
                    const Spacer(),
                    Text('Vollständig lesen →',
                        style: GoogleFonts.rajdhani(
                            color: p.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ─────────────────────────────────
  Widget _buildEmpty(dynamic p) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.newspaper_rounded, color: p.textSecondary, size: 48),
          const SizedBox(height: 16),
          Text('Keine News in dieser Kategorie',
              style: GoogleFonts.rajdhani(color: p.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Color _impactColor(String impact, dynamic p) {
    switch (impact) {
      case 'HOCH': return p.negative;
      case 'MITTEL': return Colors.orange;
      default: return p.textSecondary;
    }
  }

  // ── News Detail Sheet ────────────────────────────
  void _showNewsDetail(_NewsItem news, dynamic p) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewsDetailSheet(news: news, palette: p),
    );
  }
}

// ── News Detail Bottom Sheet ─────────────────────
class _NewsDetailSheet extends StatelessWidget {
  final _NewsItem news;
  final dynamic palette;
  const _NewsDetailSheet({required this.news, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final sentColor = news.sentiment == SentimentType.veryBullish ||
            news.sentiment == SentimentType.bullish
        ? p.positive
        : news.sentiment == SentimentType.bearish ||
                news.sentiment == SentimentType.veryBearish
            ? p.negative
            : p.textSecondary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Color(news.imageColor).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: p.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color(news.imageColor).withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(color: Color(news.imageColor).withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(news.imageColor).withValues(alpha: 0.15),
                    border: Border.all(color: Color(news.imageColor).withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Text(
                      news.category == 'QEMMA' ? 'Q'
                          : news.category == 'Bitcoin' ? '₿'
                          : news.category == 'Ethereum' ? 'Ξ'
                          : news.category.substring(0, 1),
                      style: GoogleFonts.rajdhani(
                          color: Color(news.imageColor), fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(news.source, style: GoogleFonts.spaceMono(
                          color: p.textSecondary, fontSize: 10)),
                      Text('${news.category} · ${news.timeAgo} · ${news.readTime}',
                          style: GoogleFonts.spaceMono(
                              color: Color(news.imageColor), fontSize: 10)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: p.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(news.title, style: GoogleFonts.rajdhani(
                      color: p.textPrimary, fontSize: 20,
                      fontWeight: FontWeight.bold, height: 1.3)),
                  const SizedBox(height: 16),
                  // Sentiment + Impact
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: sentColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          Icon(
                            news.sentiment == SentimentType.veryBullish ||
                                    news.sentiment == SentimentType.bullish
                                ? Icons.trending_up
                                : news.sentiment == SentimentType.bearish ||
                                        news.sentiment == SentimentType.veryBearish
                                    ? Icons.trending_down
                                    : Icons.remove,
                            color: sentColor, size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(_sentimentLabel(news.sentiment),
                              style: GoogleFonts.spaceMono(
                                  color: sentColor, fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: p.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: p.primary.withValues(alpha: 0.15)),
                        ),
                        child: Text('Impact: ${news.impact}',
                            style: GoogleFonts.spaceMono(
                                color: p.textSecondary, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Full summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.primary.withValues(alpha: 0.1)),
                    ),
                    child: Text(news.summary, style: GoogleFonts.exo(
                        color: p.textPrimary, fontSize: 14, height: 1.6)),
                  ),
                  const SizedBox(height: 20),
                  // Emma's Analysis
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: p.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.primary.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [p.primary, p.secondary]),
                            ),
                            child: ClipOval(
                              child: Image.asset('assets/icons/app_icon.png', fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Emma AI Analysis', style: GoogleFonts.rajdhani(
                              color: p.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('AUTOMATISCH', style: GoogleFonts.spaceMono(
                                color: p.primary, fontSize: 7)),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Text(_generateEmmaAnalysis(news), style: GoogleFonts.exo(
                            color: p.textPrimary, fontSize: 13, height: 1.6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Tags
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: news.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: p.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: p.primary.withValues(alpha: 0.2)),
                      ),
                      child: Text('#$tag', style: GoogleFonts.spaceMono(
                          color: p.textSecondary, fontSize: 10)),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Share Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.primary.withValues(alpha: 0.15),
                        foregroundColor: p.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: p.primary.withValues(alpha: 0.3))),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: Text('News teilen', style: GoogleFonts.rajdhani(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sentimentLabel(SentimentType s) {
    switch (s) {
      case SentimentType.veryBullish: return 'SEHR BULLISCH';
      case SentimentType.bullish: return 'BULLISCH';
      case SentimentType.bearish: return 'BEARISCH';
      case SentimentType.veryBearish: return 'SEHR BEARISCH';
      case SentimentType.neutral: return 'NEUTRAL';
    }
  }

  String _generateEmmaAnalysis(_NewsItem news) {
    if (news.isHighlighted) {
      return '⚡ HQMLL-relevante Meldung erkannt.\n\n'
          'Diese Nachricht hat direkte Auswirkungen auf das QEMMA-Ökosystem. '
          'Quantum-Resonanz-Score dieser Meldung: +0.91 (stark konstruktiv).\n\n'
          '💡 Empfehlung: Meldung im Portfolio-Kontext beobachten. '
          'QEMMA-Positionen können von diesem Momentum profitieren.';
    }
    switch (news.sentiment) {
      case SentimentType.veryBullish:
        return '🚀 Sehr positives Signal für den Markt erkannt.\n\n'
            'Die Quantum-Resonanz dieser Nachricht liegt bei +0.87 '
            '(stark bullisch). Historische Parallelen zeigen, dass ähnliche '
            'Meldungen zu 73% mit Preisanstiegen von >5% in den folgenden '
            '48 Stunden korrelierten.\n\n'
            '💡 Einfluss auf Portfolio: Positiv. Keine Handlungsempfehlung notwendig.';
      case SentimentType.bullish:
        return '📈 Positive Marktentwicklung identifiziert.\n\n'
            'Resonanz-Score: +0.62 (moderat bullisch). '
            'Diese Nachricht stärkt das allgemeine Marktvertrauen, '
            'jedoch ohne unmittelbaren Handlungsdruck.\n\n'
            '💡 Beobachten Sie die Preisentwicklung der betroffenen Assets.';
      case SentimentType.bearish:
      case SentimentType.veryBearish:
        return '⚠️ Potenziell marktbewegende Risikonachricht.\n\n'
            'Resonanz-Score: -0.54 (moderat bearisch). '
            'Regulatorische Entwicklungen dieser Art zeigten historisch '
            'kurzfristige Korrekturen von 3-8%, gefolgt von Erholung.\n\n'
            '💡 Ihr Portfolio ist durch HQMLL Risk-Sentinel überwacht. '
            'Stop-Loss-Level wurden automatisch überprüft.';
      default:
        return '🔍 Neutrale Marktinformation analysiert.\n\n'
            'Resonanz-Score: ±0.12 (neutral). '
            'Diese Nachricht hat keine unmittelbaren Auswirkungen '
            'auf bestehende Positionen.\n\n'
            '💡 Weiterhin beobachten für langfristige Trends.';
    }
  }
}

// ── Data Classes ──────────────────────────────────
enum SentimentType { veryBullish, bullish, neutral, bearish, veryBearish }

class _NewsItem {
  final String id;
  final String title;
  final String summary;
  final String source;
  final String category;
  final SentimentType sentiment;
  final String timeAgo;
  final String readTime;
  final int imageColor;
  final List<String> tags;
  final String impact;
  final bool isHighlighted;

  const _NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.category,
    required this.sentiment,
    required this.timeAgo,
    required this.readTime,
    required this.imageColor,
    required this.tags,
    required this.impact,
    this.isHighlighted = false,
  });
}
