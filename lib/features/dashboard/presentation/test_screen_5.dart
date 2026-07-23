import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../game/presentation/game_provider.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/game_l10n.dart';
import '../../../core/services/player_stats_service.dart';
import '../../../core/services/points_calculator.dart';
import '../../../data/models/rank_tier.dart';
import '../../../core/services/rank_calculator.dart';
import '../../game/presentation/widgets/rank_badge_widget.dart';

class TestScreen5 extends StatefulWidget {
  final bool isArabic;

  const TestScreen5({
    super.key,
    required this.isArabic,
  });

  @override
  State<TestScreen5> createState() => _TestScreen5State();
}

class _TestScreen5State extends State<TestScreen5> {
  // Toggle between Lose Mockup (from screenshots) and Win Mockup
  bool _showWinScreen = false;

  MatchOutcome get _mockOutcome {
    if (_showWinScreen) {
      return const MatchOutcome(
        result: PointResult(
          basePoints: 100,
          rankGapBonus: 20,
          streakBonus: 15,
          blueStarsChange: 135,
          medalsChange: 15,
          explanation: 'Victory',
        ),
        oldRank: RankTier(mainRank: MainRank.beginner, subLevel: 1),
        newRank: RankTier(mainRank: MainRank.beginner, subLevel: 2),
        rankedUp: true,
        oldStars: 100,
        newStars: 235,
        oldMedals: 90,
        newMedals: 105,
      );
    } else {
      return const MatchOutcome(
        result: PointResult(
          basePoints: 60,
          rankGapBonus: 0,
          streakBonus: 0,
          blueStarsChange: -60,
          medalsChange: 0,
          explanation: 'Loss',
        ),
        oldRank: RankTier(mainRank: MainRank.beginner, subLevel: 1),
        newRank: RankTier(mainRank: MainRank.beginner, subLevel: 1),
        rankedUp: false,
        oldStars: 160,
        newStars: 100,
        oldMedals: 10,
        newMedals: 10,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    context.watch<LocaleProvider>();
    final loc = GameL10n.of(context);

    // If game has live outcome & score, use them; otherwise use our screenshot mockup values
    final liveOutcome = game.lastMatchOutcome;
    final outcome = liveOutcome ?? _mockOutcome;
    final teamA = liveOutcome != null ? game.gameScore.teamA : (_showWinScreen ? 152 : 82);
    final teamB = liveOutcome != null ? game.gameScore.teamB : (_showWinScreen ? 104 : 155);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isArabic
              ? 'اختبار ٥: شاشة نهاية المباراة (GameOverOverlay)'
              : 'Test 5: Match End Overlay Mockup',
          style: const TextStyle(
            color: AppColors.goldAccent,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showWinScreen = !_showWinScreen;
              });
            },
            icon: Icon(
              _showWinScreen ? Icons.emoji_events : Icons.sentiment_neutral,
              color: _showWinScreen ? AppColors.goldAccent : Colors.white70,
              size: 18,
            ),
            label: Text(
              _showWinScreen ? (widget.isArabic ? 'فوز' : 'Win') : (widget.isArabic ? 'خسارة' : 'Lose'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPointsBreakdown(context, outcome, loc),
                  const SizedBox(height: 20),

                  _buildRankProgress(context, outcome, loc),
                  const SizedBox(height: 22),

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0B09),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.goldAccent.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Top gradient shimmer line
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2.5,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFFFF3D3D),
                                    Color(0xFFC9A84C),
                                    Color(0xFF00E87A),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 16),
                            child: Column(
                              children: [
                                Text(
                                  loc.finalScore.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // THEM / Team B (Red)
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            widget.isArabic
                                                ? 'الخصوم'
                                                : 'THEM',
                                            style: const TextStyle(
                                              color: Color(0xFFFF3D3D),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 3,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '$teamB',
                                            style: TextStyle(
                                              fontFamily: 'Georgia',
                                              fontSize: 56,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFFFF3D3D),
                                              height: 1.0,
                                              shadows: [
                                                Shadow(
                                                  color: const Color(0xFFFF3D3D)
                                                      .withValues(alpha: 0.75),
                                                  blurRadius: 25,
                                                ),
                                                Shadow(
                                                  color: const Color(0xFFFF3D3D)
                                                      .withValues(alpha: 0.35),
                                                  blurRadius: 50,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            widget.isArabic
                                                ? 'نقاط'
                                                : 'POINTS',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: const Color(0xFFFF3D3D)
                                                  .withValues(alpha: 0.5),
                                              letterSpacing: 1.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Small separation line like before (NO vs icon)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text(
                                        '\u2014',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.35),
                                          fontSize: 32,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ),
                                    // US / Team A (Green)
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            widget.isArabic ? 'فريقنا' : 'US',
                                            style: const TextStyle(
                                              color: Color(0xFF00E87A),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 3,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '$teamA',
                                            style: TextStyle(
                                              fontFamily: 'Georgia',
                                              fontSize: 56,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFF00E87A),
                                              height: 1.0,
                                              shadows: [
                                                Shadow(
                                                  color: const Color(0xFF00E87A)
                                                      .withValues(alpha: 0.75),
                                                  blurRadius: 25,
                                                ),
                                                Shadow(
                                                  color: const Color(0xFF00E87A)
                                                      .withValues(alpha: 0.35),
                                                  blurRadius: 50,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            widget.isArabic
                                                ? 'نقاط'
                                                : 'POINTS',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: const Color(0xFF00E87A)
                                                  .withValues(alpha: 0.5),
                                              letterSpacing: 1.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  loc.lastRoundPts(0, 25),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(loc.exitGame),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  widget.isArabic ? 'بدء اللعب مرة أخرى...' : 'Playing again...',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: AppColors.goldAccent,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldAccent,
                            foregroundColor: const Color(0xFF1E1810),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            loc.playAgain,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointsBreakdown(BuildContext context, MatchOutcome outcome, GameL10n loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1810),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildBreakdownRow(loc.pointsBase, '+${outcome.result.basePoints}'),
          if (outcome.result.rankGapBonus != 0)
            _buildBreakdownRow(loc.pointsRankGap, '${outcome.result.rankGapBonus > 0 ? '+' : ''}${outcome.result.rankGapBonus}'),
          if (outcome.result.streakBonus > 0)
            _buildBreakdownRow(loc.pointsStreakBonus, '+${outcome.result.streakBonus}'),
          if (outcome.result.wasCapped)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(loc.botCapApplied, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
            ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(loc.totalStars, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${outcome.result.blueStarsChange > 0 ? '+' : ''}${outcome.result.blueStarsChange}',
                        style: TextStyle(
                          color: outcome.result.blueStarsChange > 0 ? AppColors.goldAccent : Colors.redAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: AppColors.goldAccent, size: 20),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  Text(loc.totalMedals, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '+${outcome.result.medalsChange}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.emoji_events, color: Colors.orangeAccent, size: 20),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRankProgress(BuildContext context, MatchOutcome outcome, GameL10n loc) {
    final progress = RankCalculator.progressToNextSubLevel(outcome.newMedals);
    final medalsNeeded = RankCalculator.medalsToNextSubLevel(outcome.newMedals);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1810),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.rankProgress, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              if (outcome.rankedUp)
                Text(loc.rankUp, style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              RankBadgeWidget(rank: outcome.newRank, compact: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(outcome.newRank.badgeColor),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      medalsNeeded == 0 ? 'Max Rank' : loc.medalsToNext(medalsNeeded),
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
