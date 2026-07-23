import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:baloot_game/core/painters/diamond_painter.dart';
import 'package:provider/provider.dart';

import '../../../data/models/rank_tier.dart';
import '../../game/presentation/game_provider.dart';

// ══════════════════════════════════════════════════════════════════
//  PLAYER PROFILE SCREEN — Premium Sandstone UI (Option H)
//  Features: Animated avatar ring, enhanced stat chips, segmented
//            tab bars, richer empty states, and polished layouts.
// ══════════════════════════════════════════════════════════════════

// ── Sandstone colour tokens ──────────────────────────────────────
const _kBgCanvas   = Color(0xFF1E1808);
const _kBgCard     = Color(0xFF2C2210);
const _kBgElevated = Color(0xFF392C14);
const _kSandGold   = Color(0xFFC49028);
const _kSandLight  = Color(0xFFDFAE45);
const _kHoney      = Color(0xFFB87818);
const _kCrimson    = Color(0xFF8B2020);
const _kTextPrim   = Color(0xFFF8EDD8);
const _kTextSec    = Color(0xFFC8A868);
const _kTextMuted  = Color(0xFF806840);
const _kSandBorder = Color(0x42C49028); // rgba(196,144,40,0.26)

class PlayerProfileScreen extends StatefulWidget {
  final bool isArabic;
  const PlayerProfileScreen({super.key, this.isArabic = false});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen>
    with TickerProviderStateMixin {
  int _currentMainTab = 3; // 0: Awards, 1: Ranking, 2: Challenges, 3: About
  int _currentAwardsTab = 2; // 0: Titles, 1: Achievements, 2: Trophies
  int _currentRankingTab = 1; // 0: Performance, 1: Ranking
  int _rankingFilter = 2; // 0: Yearly, 1: Monthly, 2: Weekly

  late final AnimationController _avatarCtrl;

  @override
  void initState() {
    super.initState();
    _avatarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _avatarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1808),
      body: Stack(
        children: [
          // ── Diamond background — matches home screen game feel ──
          Positioned.fill(
            child: CustomPaint(painter: DiamondOnlyPainter()),
          ),
          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                // ── Header Bar ──
                _buildHeader(),
                
                // ── Scrollable Content ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    child: Column(
                      children: [
                        // Profile Header Card
                        _buildProfileCard(context),
                        const SizedBox(height: 16),
                        // Main Tab Navigation
                        _buildMainTabBar(),
                        const SizedBox(height: 16),
                        // Tab Content
                        _buildTabContent(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  HEADER BAR
  // ════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x1AC49028))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Back Button ──
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: SizedBox(
              width: 64,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0xFF141008), offset: Offset(0, 2)), // 3D depth
                      BoxShadow(color: Color(0x60000000), blurRadius: 8, offset: Offset(0, 4)), // Drop shadow
                    ],
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFC49028), Color(0xFF886018)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          border: Border.all(color: const Color(0xFFDFAE45), width: 1.2),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0x77FFFFFF), Color(0x00FFFFFF), Color(0x00FFFFFF)],
                            stops: [0.0, 0.45, 1.0],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Center(
                        child: CustomPaint(
                          size: const Size(11, 20),
                          painter: _BackChevronPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── Title ──
          Text(
            widget.isArabic ? 'الملف الشخصي' : 'Profile',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [_kSandGold, _kSandLight, Color(0xFFF5E6C0), _kSandLight, _kSandGold],
                ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
            ),
          ),
          // ── Options button ──
          const SizedBox(width: 64),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PROFILE HEADER CARD
  // ════════════════════════════════════════════════════════════════
  Widget _buildProfileCard(BuildContext context) {
    final game = context.watch<GameProvider>();
    final stats = game.playerStats;
    final rank = game.playerRank;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kBgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kSandBorder),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: Showcase Slot ──
              const SizedBox(width: 64),

              // ── Center: Avatar & Username ──
              Column(
                children: [
                  _buildAnimatedAvatar(),
                  const SizedBox(height: 12),
                  // Username Pill
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          final ctrl = TextEditingController(text: stats.playerName);
                          return AlertDialog(
                            backgroundColor: _kBgCard,
                            title: Text(widget.isArabic ? 'تغيير الاسم' : 'Change Name', style: GoogleFonts.cairo(color: _kSandLight)),
                              content: TextField(
                                controller: ctrl,
                                style: const TextStyle(color: _kTextPrim),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(11),
                                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s_\.\u0600-\u06FF]')),
                                ],
                              decoration: InputDecoration(
                                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: _kSandBorder)),
                                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _kSandGold)),
                                hintText: widget.isArabic ? 'أدخل اسمك الجديد' : 'Enter your new name',
                                hintStyle: const TextStyle(color: _kTextMuted),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(widget.isArabic ? 'إلغاء' : 'Cancel', style: const TextStyle(color: _kTextSec)),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (ctrl.text.trim().isNotEmpty) {
                                    game.updatePlayerName(ctrl.text.trim());
                                  }
                                  Navigator.pop(ctx);
                                },
                                child: Text(widget.isArabic ? 'حفظ' : 'Save', style: const TextStyle(color: _kSandGold, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _kBgElevated,
                        border: Border.all(color: _kSandBorder),
                        boxShadow: const [BoxShadow(color: Color(0x11C49028), blurRadius: 8)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            stats.playerName,
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _kTextPrim,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit_rounded, size: 14, color: _kTextSec),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Right: Rank Badge ──
              _buildRankBadge(rank),
            ],
          ),

          const SizedBox(height: 24),
          // ── Bottom Row: Stat Chips ──
          Row(
            children: [
              Expanded(child: _buildEnhancedStatChip(iconWidget: Image.asset('assets/icons/medal.png', width: 14, height: 14), value: '${stats.medals}', label: widget.isArabic ? 'ميداليات' : 'Medals', color: _kSandLight)),
              const SizedBox(width: 8),
              Expanded(child: _buildEnhancedStatChip(iconWidget: Image.asset('assets/icons/heart.png', width: 14, height: 14), value: '0', label: widget.isArabic ? 'قلوب' : 'Hearts', color: _kCrimson)),
              const SizedBox(width: 8),
              Expanded(child: _buildEnhancedStatChip(iconWidget: Image.asset('assets/icons/gold_star.png', width: 14, height: 14), value: '${stats.blueStars}', label: widget.isArabic ? 'نجوم ذهبية' : 'Gold Stars', color: const Color(0xFF4285F4))),
              const SizedBox(width: 8),
              Expanded(child: _buildEnhancedStatChip(iconWidget: Image.asset('assets/icons/silver_star.png', width: 14, height: 14), value: '0', label: widget.isArabic ? 'نجوم فضية' : 'Silver Stars', color: _kSandGold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShowcaseSlot() {
    return CustomPaint(
      painter: _DashedBorderPainter(color: _kSandGold.withValues(alpha: 0.4)),
      child: Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _kBgElevated.withValues(alpha: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 24, color: _kTextSec),
            Text(
              'Add Trophy',
              style: GoogleFonts.readexPro(fontSize: 8, color: _kTextSec, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedAvatar() {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Animated sweeping border ring
        AnimatedBuilder(
          animation: _avatarCtrl,
          builder: (context, child) {
            return Transform.rotate(
              angle: _avatarCtrl.value * 2 * math.pi,
              child: Container(
                width: 86, height: 86,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [_kBgCard, _kSandGold, _kSandLight, _kBgCard],
                    stops: [0.0, 0.4, 0.5, 1.0],
                  ),
                ),
              ),
            );
          },
        ),
        // Avatar Inner Circle
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(colors: [_kBgElevated, _kBgCard]),
            border: Border.all(color: _kBgCard, width: 2),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10)],
          ),
          child: const Icon(Icons.person, size: 46, color: Color(0x80C8A868)),
        ),
      ],
    );
  }

  Widget _buildRankBadge(RankTier rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [_kBgElevated, _kBgCard],
        ),
        border: Border.all(color: _kSandBorder),
        boxShadow: const [BoxShadow(color: Color(0x22C49028), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text(
            widget.isArabic ? rank.arabicName : rank.englishName,
            style: GoogleFonts.readexPro(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kSandLight,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(rank.suitIconCount, (index) {
              const suits = ['♠', '♥', '♣', '♦'];
              return _suitIcon(suits[index % suits.length]);
            }),
          )
        ],
      ),
    );
  }

  Widget _suitIcon(String suit) {
    final isRed = suit == '♥' || suit == '♦';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        suit,
        style: TextStyle(fontSize: 12, color: isRed ? _kCrimson : _kTextSec),
      ),
    );
  }

  Widget _buildEnhancedStatChip({required Widget iconWidget, required String value, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _kBgElevated.withValues(alpha: 0.5),
        border: Border.all(color: _kSandBorder),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: _kTextPrim)),
              const SizedBox(width: 4),
              iconWidget,
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.readexPro(fontSize: 9, color: _kTextMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            width: 20, height: 2,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  MAIN TAB BAR
  // ════════════════════════════════════════════════════════════════
  Widget _buildMainTabBar() {
    final tabs = ['Awards', 'Ranking', 'Challenges', 'About'];
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kBgCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kSandBorder),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _currentMainTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentMainTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: isSelected ? _kSandGold : Colors.transparent,
                  boxShadow: isSelected ? const [BoxShadow(color: Color(0x44C49028), blurRadius: 6)] : null,
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? _kBgCanvas : _kTextMuted,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  TAB CONTENT ROUTER
  // ════════════════════════════════════════════════════════════════
  Widget _buildTabContent() {
    switch (_currentMainTab) {
      case 0: return _buildAwardsTab();
      case 1: return _buildRankingTab();
      case 2: return _buildChallengesTab();
      case 3: default: return _buildAboutTab();
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  ABOUT TAB
  // ════════════════════════════════════════════════════════════════
  Widget _buildAboutTab() {
    return Column(
      children: [
        // Bio Text Area
        Container(
          width: double.infinity,
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: _kBgCard,
            border: Border.all(color: _kSandBorder),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'Tap here to add a summary...',
                  style: GoogleFonts.readexPro(color: _kTextMuted, fontSize: 13),
                ),
              ),
              const Align(
                alignment: Alignment.topRight,
                child: Icon(Icons.edit_rounded, color: _kSandGold, size: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Player Impressions
        _GlassPanel(
          label: 'Player Impressions',
          child: Column(
            children: [
              const SizedBox(height: 10),

              Text(
                'No player impressions yet',
                style: GoogleFonts.cairo(
                  color: _kHoney,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

      ],
    );
  }

  Widget _buildImpressionEmoji(String emoji) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kBgElevated,
        border: Border.all(color: _kSandBorder),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 20)),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  AWARDS TAB
  // ════════════════════════════════════════════════════════════════
  Widget _buildAwardsTab() {
    return Column(
      children: [
        // 3 Trophy Shelves
        _buildTrophyShelf(), const SizedBox(height: 16),
        _buildTrophyShelf(), const SizedBox(height: 16),
        _buildTrophyShelf(), const SizedBox(height: 24),

        // Segmented Sub-tabs
        Container(
          height: 40,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _kBgCard,
            border: Border.all(color: _kSandBorder),
          ),
          child: Row(
            children: [
              _buildSubTab(0, 'Titles', _currentAwardsTab, (v) => setState(() => _currentAwardsTab = v)),
              _buildSubTab(1, 'Achievements', _currentAwardsTab, (v) => setState(() => _currentAwardsTab = v)),
              _buildSubTab(2, 'Trophies', _currentAwardsTab, (v) => setState(() => _currentAwardsTab = v)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrophyShelf() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [_kBgElevated, _kBgCanvas],
        ),
        border: Border.all(color: _kSandBorder),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SpotlightPainter())),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) => _buildEmptyTrophySlot()),
          ),
          Center(
            child: Text(
              'No trophies yet',
              style: GoogleFonts.cairo(
                color: _kTextSec.withValues(alpha: 0.5),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTrophySlot() {
    return Container(
      width: 80, height: 100,
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        border: Border.all(color: _kSandBorder, width: 1.5, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
        color: _kBgCard.withValues(alpha: 0.4),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  RANKING TAB
  // ════════════════════════════════════════════════════════════════
  Widget _buildRankingTab() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kBgCard,
              border: Border.all(color: _kSandBorder),
            ),
            child: const Icon(Icons.info_outline_rounded, color: _kTextSec, size: 20),
          ),
        ),
        const SizedBox(height: 10),

        if (_currentRankingTab == 1) ...[
          // Ranking Pyramid View removed
          const SizedBox(height: 200),
          const SizedBox(height: 40),
          // Time Filter
          _buildTimeFilters([
            (0, 'Yearly'), (1, 'Monthly'), (2, 'Weekly')
          ]),
        ] else ...[
          // Performance Gauge View removed
          const SizedBox(height: 220),
          const SizedBox(height: 40),
          _buildTimeFilters([(1, 'Monthly'), (2, 'Weekly')]),
        ],

        const SizedBox(height: 24),
        // Bottom sub-tabs
        Container(
          height: 40, padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: _kBgCard, border: Border.all(color: _kSandBorder)),
          child: Row(
            children: [
              _buildSubTab(0, 'Performance', _currentRankingTab, (v) => setState(() => _currentRankingTab = v)),
              _buildSubTab(1, 'Ranking', _currentRankingTab, (v) => setState(() => _currentRankingTab = v)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFilters(List<(int, String)> filters) {
    return Container(
      height: 40, padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: _kBgCard, border: Border.all(color: _kSandBorder)),
      child: Row(
        children: filters.map((f) => _buildSubTab(f.$1, f.$2, _rankingFilter, (v) => setState(() => _rankingFilter = v))).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  CHALLENGES TAB
  // ════════════════════════════════════════════════════════════════
  Widget _buildChallengesTab() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _kBgCard,
        border: Border.all(color: _kSandBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(colors: [_kBgElevated, Colors.transparent]),
              boxShadow: const [BoxShadow(color: Color(0x33C49028), blurRadius: 30, spreadRadius: 10)],
            ),
            child: const Center(child: Icon(Icons.shield_rounded, size: 60, color: _kSandGold)),
          ),
          const SizedBox(height: 20),
          Text('No Challenges', style: GoogleFonts.cairo(color: _kHoney, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Complete games to unlock challenges.', style: GoogleFonts.cairo(color: _kTextMuted, fontSize: 13)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════════════
  Widget _buildSubTab(int index, String label, int currentTab, ValueChanged<int> onSelect) {
    final isSelected = currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected ? _kSandGold : Colors.transparent,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? _kBgCanvas : _kTextMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  COMPONENTS
// ══════════════════════════════════════════════════════════════════
class _GlassPanel extends StatelessWidget {
  final String label;
  final Widget child;
  const _GlassPanel({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: _kBgCard,
            border: Border.all(color: _kSandBorder),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 8))],
          ),
          child: child,
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [_kBgElevated, _kBgCard]),
                border: Border.all(color: _kSandBorder),
                boxShadow: const [BoxShadow(color: Color(0x33C49028), blurRadius: 12)],
              ),
              child: Text(
                label,
                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w800, color: _kSandLight, letterSpacing: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Dashed Border Painter for Showcase Slot ──
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16));
    Path path = Path()..addRRect(rrect);
    
    // Create dashed effect
    final dashedPath = Path();
    for (PathMetric measurePath in path.computeMetrics()) {
      double distance = 0;
      while (distance < measurePath.length) {
        dashedPath.addPath(measurePath.extractPath(distance, distance + 6), Offset.zero);
        distance += 12; // 6px line, 6px gap
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Existing Painters (Spotlight, Pyramid, Gauge) ──
class _SpotlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFFC49028).withValues(alpha: 0.15), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (int i = 0; i < 3; i++) {
      final xOffset = (size.width / 4) * (i + 1);
      final path = Path()
        ..moveTo(xOffset - 20, 0)..lineTo(xOffset + 20, 0)
        ..lineTo(xOffset + 60, size.height)..lineTo(xOffset - 60, size.height)..close();
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PyramidPainter extends CustomPainter {
  final double percent;
  _PyramidPainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()..color = Colors.white.withValues(alpha: 0.05)..style = PaintingStyle.fill;
    final fillPaint = Paint()..color = const Color(0x99C49028)..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = const Color(0xFFC49028)..strokeWidth = 2..style = PaintingStyle.stroke;

    final path = Path()..moveTo(size.width / 2, 0)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();

    canvas.drawPath(path, basePaint);
    canvas.drawPath(path, borderPaint);

    final yCut = size.height * (1.0 - percent);
    final widthAtCut = size.width * percent;
    final xStart = (size.width - widthAtCut) / 2;

    final fillPath = Path()..moveTo(xStart, yCut)..lineTo(size.width - xStart, yCut)
      ..lineTo(size.width, size.height)..lineTo(0, size.height)..close();

    canvas.drawPath(fillPath, fillPaint);

    canvas.drawCircle(Offset(size.width / 2, yCut), 12, Paint()..color = const Color(0xFFF8EDD8));
    
    final textPainter = TextPainter(
      text: TextSpan(text: '${(percent * 100).toInt()}%', style: GoogleFonts.cairo(color: const Color(0xFF1E1808), fontSize: 10, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, yCut - textPainter.height / 2));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GaugePainter extends CustomPainter {
  final int points;
  _GaugePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height / 2;

    final trackPaint = Paint()..color = Colors.white.withValues(alpha: 0.05)..style = PaintingStyle.stroke..strokeWidth = 20..strokeCap = StrokeCap.round;
    final fillPaint = Paint()..color = const Color(0xFF8B2020)..style = PaintingStyle.stroke..strokeWidth = 20..strokeCap = StrokeCap.round;

    const startAngle = 3.14159 * 0.75;
    const sweepAngle = 3.14159 * 1.5;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, trackPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * 0.1, false, fillPaint);

    canvas.drawCircle(Offset(center.dx, center.dy - radius), 16, Paint()..color = const Color(0xFFC49028));
    
    final starTextPainter = TextPainter(
      text: const TextSpan(text: '⭐', style: TextStyle(fontSize: 16)),
      textDirection: TextDirection.ltr,
    );
    starTextPainter.layout();
    starTextPainter.paint(canvas, Offset(center.dx - starTextPainter.width / 2, center.dy - radius - starTextPainter.height / 2 + 1));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BackChevronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.8, 0)
      ..lineTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.8, size.height);
    canvas.drawPath(path, Paint()..color = const Color(0xFF141008)..style = PaintingStyle.stroke
        ..strokeWidth = 5.0..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    canvas.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.stroke
        ..strokeWidth = 2.5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}



