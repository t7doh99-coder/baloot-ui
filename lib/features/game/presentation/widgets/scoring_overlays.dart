import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/card_model.dart' show GameMode, Suit;
import '../../../../data/models/round_state_model.dart' show DoubleStatus;
import '../game_provider.dart';

// ══════════════════════════════════════════════════════════════════
//  ROUND SCORE OVERLAY — Majlis / designer-style scoreboard (English)
//
//  • Title + gold rule
//  • Contract summary (game mode, buyer, stakes, outcome)
//  • Table: Them | Us — Tricks, Ground, Projects, Points, Round result
//  • Gold “Back” → [dismissRoundScoreOverlay]
// ══════════════════════════════════════════════════════════════════

class RoundScoreOverlay extends StatelessWidget {
  const RoundScoreOverlay({super.key});

  static const _panelBg = Color(0xFF1E1810);
  static const _innerBg = Color(0xFF2A1E16);
  static const _innerBorder = Color(0x33FFFFFF);
  static const _themColor = Color(0xFFE63946);
  static const _usColor = Color(0xFF28802E);
  static const _lossRed = Color(0xFFFF5252);

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final r = game.lastRoundResult;
    final total = game.gameScore;
    if (r == null) return const SizedBox.shrink();

    final buyerWon = r.winningTeam == r.buyerTeam;
    final buyerSide = r.buyerTeam == 'A' ? 'Our team' : 'Their team';

    final (contractText, contractColor) = switch ((r.isKabout, r.isKhams, buyerWon)) {
      (true, _, _) => ('Outcome: Kabout', AppColors.goldAccent),
      (_, true, _) => ('Purchase result: Lost · Khams', _lossRed),
      (_, _, true) => ('Purchase result: Won', const Color(0xFF69F0AE)),
      _ => ('Purchase result: Lost', _lossRed),
    };

    final groundA = r.lastTrickBonusTeam == 'A' ? 10 : 0;
    final groundB = r.lastTrickBonusTeam == 'B' ? 10 : 0;
    final trickA = r.teamATrickAbnat - groundA;
    final trickB = r.teamBTrickAbnat - groundB;

    final stakes = _stakesLabel(r.doubleStatus);
    final gameLine = _gameLine(r);

    TextStyle taj({
      double size = 13,
      FontWeight w = FontWeight.w500,
      Color? color,
    }) =>
        GoogleFonts.tajawal(
          fontSize: size,
          fontWeight: w,
          color: color ?? Colors.white.withValues(alpha: 0.88),
          height: 1.25,
        );

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.62),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.94, end: 1.0),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            builder: (ctx, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 368),
                decoration: BoxDecoration(
                  color: _panelBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.55),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Scoreboard',
                        style: GoogleFonts.tajawal(
                          color: AppColors.goldAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.goldAccent.withValues(alpha: 0.0),
                              AppColors.goldAccent.withValues(alpha: 0.75),
                              AppColors.goldAccent.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Contract / status block ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _innerBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _innerBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _statusRow('Game', gameLine, taj: taj),
                            const SizedBox(height: 6),
                            _statusRow(
                              'Buyer',
                              buyerSide,
                              taj: taj,
                            ),
                            if (stakes != null) ...[
                              const SizedBox(height: 6),
                              _statusRow('Stakes', stakes, taj: taj),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              contractText,
                              style: taj(
                                size: 14,
                                w: FontWeight.w800,
                                color: contractColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Breakdown table ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _innerBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _innerBorder),
                        ),
                        child: Column(
                          children: [
                            _ScoreTableRow.header(taj),
                            _thinRule(),
                            _ScoreTableRow.data(
                              'Tricks',
                              trickB,
                              trickA,
                              taj,
                            ),
                            _ScoreTableRow.dataOptional(
                              'Ground',
                              groundB,
                              groundA,
                              taj,
                            ),
                            _ScoreTableRow.dataOptional(
                              'Projects',
                              r.teamBProjectAbnat,
                              r.teamAProjectAbnat,
                              taj,
                            ),
                            _thinRule(),
                            _ScoreTableRow.data(
                              'Points',
                              r.teamBAbnat,
                              r.teamAAbnat,
                              taj,
                              emphasize: true,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      AppColors.goldAccent.withValues(alpha: 0.2),
                                ),
                              ),
                              child: _ScoreTableRow.data(
                                'Result',
                                r.teamBPoints,
                                r.teamAPoints,
                                taj,
                                isFinal: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        'Match: Us ${total.teamA}   ·   Them ${total.teamB}',
                        style: taj(
                          size: 11,
                          w: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.38),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      _GoldBackButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.read<GameProvider>().dismissRoundScoreOverlay();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _gameLine(LastRoundResult r) {
    if (r.mode == GameMode.sun) return 'Sun';
    final s = r.trumpSuit;
    final sym = switch (s) {
      Suit.hearts => '♥',
      Suit.diamonds => '♦',
      Suit.spades => '♠',
      Suit.clubs => '♣',
      null => '',
    };
    return 'Hakam $sym'.trim();
  }

  static String? _stakesLabel(DoubleStatus d) {
    return switch (d) {
      DoubleStatus.none => null,
      DoubleStatus.doubled => 'Double',
      DoubleStatus.tripled => 'Triple',
      DoubleStatus.four => 'Four',
      DoubleStatus.gahwa => 'Gahwa',
    };
  }
}

Widget _statusRow(
  String label,
  String value, {
  required TextStyle Function({
    double size,
    FontWeight w,
    Color? color,
  }) taj,
}) {
  return RichText(
    text: TextSpan(
      style: taj(size: 13, w: FontWeight.w500),
      children: [
        TextSpan(
          text: '$label: ',
          style: taj(
            size: 13,
            w: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        TextSpan(
          text: value,
          style: taj(size: 13, w: FontWeight.w700),
        ),
      ],
    ),
  );
}

Widget _thinRule() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: Colors.white.withValues(alpha: 0.08),
      ),
    );

class _ScoreTableRow extends StatelessWidget {
  const _ScoreTableRow._({
    required this.label,
    required this.themText,
    required this.usText,
    required this.taj,
    this.header = false,
    this.emphasize = false,
    this.isFinal = false,
  });

  final String label;
  final String themText;
  final String usText;
  final TextStyle Function({
    double size,
    FontWeight w,
    Color? color,
  }) taj;
  final bool header;
  final bool emphasize;
  final bool isFinal;

  factory _ScoreTableRow.header(
    TextStyle Function({
      double size,
      FontWeight w,
      Color? color,
    }) taj,
  ) {
    return _ScoreTableRow._(
      label: '',
      themText: 'Them',
      usText: 'Us',
      taj: taj,
      header: true,
    );
  }

  factory _ScoreTableRow.data(
    String label,
    int them,
    int us,
    TextStyle Function({
      double size,
      FontWeight w,
      Color? color,
    }) taj, {
    bool emphasize = false,
    bool isFinal = false,
  }) {
    return _ScoreTableRow._(
      label: label,
      themText: '$them',
      usText: '$us',
      taj: taj,
      emphasize: emphasize,
      isFinal: isFinal,
    );
  }

  factory _ScoreTableRow.dataOptional(
    String label,
    int them,
    int us,
    TextStyle Function({
      double size,
      FontWeight w,
      Color? color,
    }) taj,
  ) {
    return _ScoreTableRow._(
      label: label,
      themText: them > 0 ? '$them' : '—',
      usText: us > 0 ? '$us' : '—',
      taj: taj,
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = taj(
      size: header ? 11 : 12.5,
      w: header ? FontWeight.w700 : FontWeight.w600,
      color: header
          ? Colors.white.withValues(alpha: 0.5)
          : Colors.white.withValues(alpha: 0.72),
    );
    final valSize = isFinal ? 17.0 : emphasize ? 14.0 : 13.0;
    final valWeight =
        emphasize || isFinal ? FontWeight.w800 : FontWeight.w600;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: header ? 2 : 5),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: labelStyle,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              themText,
              textAlign: TextAlign.center,
              style: taj(
                size: valSize,
                w: valWeight,
                color: header
                    ? RoundScoreOverlay._themColor.withValues(alpha: 0.9)
                    : RoundScoreOverlay._themColor.withValues(alpha: 0.95),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              usText,
              textAlign: TextAlign.center,
              style: taj(
                size: valSize,
                w: valWeight,
                color: header
                    ? RoundScoreOverlay._usColor.withValues(alpha: 0.9)
                    : RoundScoreOverlay._usColor.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldBackButton extends StatelessWidget {
  const _GoldBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE8C547),
                Color(0xFFD4AF37),
                Color(0xFFC9A227),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldAccent.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Back',
              style: GoogleFonts.tajawal(
                color: const Color(0xFF1A1208),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
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
    final lastRound = game.lastRoundResult;
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
                    style: const TextStyle(
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
                        winner == 'A'
                            ? 'Team Us reached 152'
                            : 'Team Them reached 152',
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
                              child: Text('\u2014',
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.3),
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
                        if (lastRound != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Last round +${lastRound.teamAPoints} / +${lastRound.teamBPoints}',
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
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
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
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
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
