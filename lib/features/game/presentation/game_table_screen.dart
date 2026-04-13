import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import 'game_provider.dart';
import 'widgets/baloot_rug_painter.dart';

// ══════════════════════════════════════════════════════════════════
//  GAME TABLE SCREEN  (Step 3 — Layout Shell)
//
//  The rug is NOT a table — it is a flat floor mat displayed in
//  the centre of the screen (like the reference screenshot).
//
//  Portrait layout:
//  ┌─────────────────────────────────────┐
//  │  TOP BAR:  لنا | round+icons | لهم  │
//  ├─────────────────────────────────────┤
//  │        [Top player / opponent]      │
//  │  [L]  ┌──────────────────┐  [R]    │
//  │  [P]  │  BALOOT  RUG     │  [P]    │
//  │  [l]  │  (floor mat)     │  [l]    │
//  │  [a]  └──────────────────┘  [a]    │
//  │  [y]   [trick play area]    [y]    │
//  ├─────────────────────────────────────┤
//  │  [Bottom player — human hand]       │
//  ├─────────────────────────────────────┤
//  │  BOTTOM ACTION BAR                  │
//  └─────────────────────────────────────┘
// ══════════════════════════════════════════════════════════════════

class GameTableScreen extends StatelessWidget {
  const GameTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    return Scaffold(
      backgroundColor: AppColors.darkWood,
      body: SafeArea(
        child: Column(
          children: [
            _TopScoreBar(game: game),
            Expanded(child: _PlayArea(game: game)),
            _BottomActionBar(game: game),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TOP SCORE BAR
// ══════════════════════════════════════════════════════════════════

class _TopScoreBar extends StatelessWidget {
  final GameProvider game;
  const _TopScoreBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final score = game.gameScore;

    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Extra menu icon (المزيد)
          _BarIcon(icon: Icons.more_horiz, label: 'المزيد'),
          // Sound icon
          _BarIcon(icon: Icons.volume_up_outlined, label: 'الصوت'),

          const Spacer(),

          // لهم / لنا score box (like reference screenshot)
          _ScoreGroup(usScore: score.teamA, themScore: score.teamB),

          const Spacer(),

          // Share icon
          _BarIcon(icon: Icons.ios_share_outlined, label: 'مشاركة'),
          // Emoji icon
          _BarIcon(icon: Icons.emoji_emotions_outlined, label: 'تعابير'),

          // Back (exit)
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: Colors.white.withValues(alpha: 0.6),
              size: 18,
            ),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BarIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.65), size: 17),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 8,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreGroup extends StatelessWidget {
  final int usScore;
  final int themScore;
  const _ScoreGroup({required this.usScore, required this.themScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ScoreCell(label: 'لهم', score: themScore, color: const Color(0xFFE63946)),
          Container(width: 1, height: 26, color: AppColors.goldAccent.withValues(alpha: 0.25)),
          _ScoreCell(label: 'لنا', score: usScore, color: const Color(0xFF28802E)),
        ],
      ),
    );
  }
}

class _ScoreCell extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  const _ScoreCell({required this.label, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 9,
              fontFamily: 'Tajawal',
              height: 1,
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  MAIN PLAY AREA
// ══════════════════════════════════════════════════════════════════

class _PlayArea extends StatelessWidget {
  final GameProvider game;
  const _PlayArea({required this.game});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      // Rug is portrait-ish — similar to screenshot proportions
      // Rug fills the middle vertically, side players flank it
      final seatW = 60.0;
      final rugW = w - seatW * 2 - 16;
      // Figma rug aspect = 800/1100 ≈ 0.727 — but we reserve some
      // space for top player above and trick zone below
      final rugH = (rugW / 0.727).clamp(0.0, h * 0.68);
      final rugTop = (h - rugH) / 2;

      return Stack(
        children: [
          // ── Rug (floor mat) center ──
          Positioned(
            left: seatW + 8,
            top: rugTop,
            width: rugW,
            height: rugH,
            child: _BalootRug(width: rugW, height: rugH),
          ),

          // ── Trick area overlay in rug center ──
          Positioned(
            left: seatW + 8 + rugW * 0.25,
            top:  rugTop + rugH * 0.35,
            width:  rugW * 0.50,
            height: rugH * 0.30,
            child: const _TrickArea(),
          ),

          // ── Top player (opponent across) ──
          Positioned(
            top: rugTop - 70,
            left: 0, right: 0,
            child: Center(
              child: _PlayerSeatPlaceholder(
                label: 'خصم ٢',
                sublabel: 'لاعب 3686a1',
                color: const Color(0xFFE63946),
                horizontal: true,
              ),
            ),
          ),

          // ── Left player (partner) ──
          Positioned(
            left: 0,
            top: rugTop,
            height: rugH,
            width: seatW + 8,
            child: _PlayerSeatPlaceholder(
              label: 'شريكي',
              sublabel: 'ابوالهوايل',
              color: const Color(0xFF28802E),
              horizontal: false,
              showCards: true,
              cardCount: 8,
            ),
          ),

          // ── Right player (opponent) ──
          Positioned(
            right: 0,
            top: rugTop,
            height: rugH,
            width: seatW + 8,
            child: _PlayerSeatPlaceholder(
              label: 'خصم ١',
              sublabel: 'd2ee28b',
              color: const Color(0xFFE63946),
              horizontal: false,
              showCards: true,
              cardCount: 8,
            ),
          ),

          // ── Session number ──
          Positioned(
            bottom: 8,
            left: 0, right: 0,
            child: Center(
              child: Text(
                'جلسة 2266',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 10,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ── Rug Widget ─────────────────────────────────────────────────────

class _BalootRug extends StatelessWidget {
  final double width;
  final double height;
  const _BalootRug({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 20,
            spreadRadius: 4,
            offset: const Offset(0, 6),
          ),
          // Warm glow from rug
          BoxShadow(
            color: const Color(0xFFE63946).withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CustomPaint(
          size: Size(width, height),
          painter: const BalootRugPainter(),
        ),
      ),
    );
  }
}

// ── Trick Area (center of rug) ─────────────────────────────────────

class _TrickArea extends StatelessWidget {
  const _TrickArea();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: const Color(0xFF5C3A1E).withValues(alpha: 0.20),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          'منطقة اللعب',
          style: TextStyle(
            color: const Color(0xFF5C3A1E).withValues(alpha: 0.35),
            fontSize: 10,
            fontFamily: 'Tajawal',
          ),
        ),
      ),
    );
  }
}

// ── Player Seat Placeholder ────────────────────────────────────────

class _PlayerSeatPlaceholder extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final bool horizontal;
  final bool showCards;
  final int cardCount;

  const _PlayerSeatPlaceholder({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.horizontal,
    this.showCards = false,
    this.cardCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showCards) _FaceDownCards(count: cardCount, vertical: !horizontal),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(Icons.person, color: color.withValues(alpha: 0.8), size: 14),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Tajawal',
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                sublabel,
                style: TextStyle(
                  color: color.withValues(alpha: 0.6),
                  fontSize: 7.5,
                  fontFamily: 'Tajawal',
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FaceDownCards extends StatelessWidget {
  final int count;
  final bool vertical;
  const _FaceDownCards({required this.count, required this.vertical});

  @override
  Widget build(BuildContext context) {
    // Stacked face-down cards as a visual indicator
    const cardW = 18.0;
    const cardH = 26.0;
    const overlap = 6.0;

    return SizedBox(
      width: vertical ? cardW + 4 : (count - 1) * overlap + cardW,
      height: vertical ? (count - 1) * overlap + cardH : cardH + 4,
      child: Stack(
        children: List.generate(count, (i) {
          return Positioned(
            left: vertical ? 0 : i * overlap,
            top:  vertical ? i * overlap : 0,
            child: Container(
              width: cardW,
              height: cardH,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2878),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  BOTTOM ACTION BAR
// ══════════════════════════════════════════════════════════════════

class _BottomActionBar extends StatelessWidget {
  final GameProvider game;
  const _BottomActionBar({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionBtn(icon: Icons.lock_outline,    label: 'قيدها',      color: const Color(0xFFE63946)),
          _ActionBtn(icon: Icons.emoji_events_outlined, label: 'المشاريع', color: AppColors.goldAccent),
          _ActionBtn(icon: Icons.compare_arrows,  label: 'سوا',        color: Colors.white70),
          _ActionBtn(icon: Icons.chat_bubble_outline, label: 'دردشة', color: const Color(0xFF30C8D8), badge: 2),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int badge;
  const _ActionBtn({required this.icon, required this.label, required this.color, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color.withValues(alpha: 0.8), size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.65),
                fontSize: 9,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
        if (badge > 0)
          Positioned(
            top: -2,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFFE63946),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
