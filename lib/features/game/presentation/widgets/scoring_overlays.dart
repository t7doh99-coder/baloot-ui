import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/round_state_model.dart' show DoubleStatus;
import '../../domain/engines/scoring_engine.dart';
import '../game_provider.dart';

// ══════════════════════════════════════════════════════════════════
//  ROUND SCORE OVERLAY — shown during [GamePhase.scoring]
// ══════════════════════════════════════════════════════════════════

class RoundScoreOverlay extends StatelessWidget {
  const RoundScoreOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final detail = game.lastRoundScoreResult;
    final total = game.gameScore;
    if (detail == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1.0),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            builder: (ctx, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1810),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Round complete',
                    style: TextStyle(
                      color: AppColors.goldAccent,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _RoundTags(detail: detail),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _TeamRoundColumn(
                          label: 'Us',
                          color: const Color(0xFF28802E),
                          roundPts: detail.teamAPoints,
                          abnat: detail.teamARawAbnat,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 56,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      Expanded(
                        child: _TeamRoundColumn(
                          label: 'Them',
                          color: const Color(0xFFE63946),
                          roundPts: detail.teamBPoints,
                          abnat: detail.teamBRawAbnat,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: Colors.white.withValues(alpha: 0.12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Game total',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12,
                          )),
                      Text(
                        '${total.teamA} — ${total.teamB}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Next round…',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundTags extends StatelessWidget {
  final RoundScoreResult detail;
  const _RoundTags({required this.detail});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (detail.isKhams) {
      chips.add(_chip('Khams', const Color(0xFFE63946)));
    }
    if (detail.isKabout) {
      chips.add(_chip('Kabout', const Color(0xFFD4AF37)));
    }
    if (chips.isEmpty) {
      chips.add(_chip('Normal', Colors.white24));
    }
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: chips,
    );
  }

  Widget _chip(String text, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TeamRoundColumn extends StatelessWidget {
  final String label;
  final Color color;
  final int roundPts;
  final int abnat;

  const _TeamRoundColumn({
    required this.label,
    required this.color,
    required this.roundPts,
    required this.abnat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 4),
        Text(
          '+$roundPts',
          style: TextStyle(
            color: color,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          '$abnat Abnat',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  GAME OVER OVERLAY — full screen when [GamePhase.gameOver]
// ══════════════════════════════════════════════════════════════════

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final total = game.gameScore;
    final detail = game.lastRoundScoreResult;
    final winner = game.gameWinner;

    final humanWon = game.didHumanWinGame;
    final gahwa = game.roundState.doubleStatus == DoubleStatus.gahwa;
    final title = gahwa
        ? 'Gahwa'
        : humanWon
            ? 'You win!'
            : 'You lose';

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    humanWon ? Icons.emoji_events : Icons.sentiment_neutral,
                    size: 56,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.goldAccent,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (winner != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        winner == 'A' ? 'Team Us reached 152' : 'Team Them reached 152',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _StarRow(won: humanWon || gahwa),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1810),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.goldAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text('Final score',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            )),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${total.teamA}',
                                style: const TextStyle(
                                  color: Color(0xFF28802E),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                )),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('—',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 24,
                                  )),
                            ),
                            Text('${total.teamB}',
                                style: const TextStyle(
                                  color: Color(0xFFE63946),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                )),
                          ],
                        ),
                        if (detail != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Last round +${detail.teamAPoints} / +${detail.teamBPoints}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Exit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<GameProvider>().restartGame();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldAccent,
                            foregroundColor: const Color(0xFF1E1810),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Play again',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final bool won;
  const _StarRow({required this.won});

  @override
  Widget build(BuildContext context) {
    final n = won ? 5 : 2;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < n;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(
            filled ? Icons.star : Icons.star_border,
            color: filled
                ? AppColors.goldAccent
                : Colors.white.withValues(alpha: 0.2),
            size: 28,
          ),
        );
      }),
    );
  }
}
