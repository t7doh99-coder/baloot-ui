import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/card_model.dart' show GameMode;
import '../../../../data/models/round_state_model.dart' show DoubleStatus;
import '../game_provider.dart';

// ══════════════════════════════════════════════════════════════════
//  ROUND SCORE OVERLAY — Kamelna-style detailed breakdown
//
//  ┌─────────────────────────────────────┐
//  │  Mode: Hakam   Buyer: Us   Won ✓   │
//  ├───────────┬──────────┬──────────────┤
//  │           │   Us     │   Them       │
//  │  Tricks   │   137    │    15        │
//  │  Ground   │   +10    │              │
//  │  Projects │ Sera 20  │              │
//  │           │  100     │              │
//  │  Abnat    │   267    │    15        │
//  ├───────────┴──────────┴──────────────┤
//  │  Score       27         1           │
//  │  Game total  27 — 1                 │
//  │           Next round…               │
//  └─────────────────────────────────────┘
// ══════════════════════════════════════════════════════════════════

class RoundScoreOverlay extends StatelessWidget {
  const RoundScoreOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final r = game.lastRoundResult;
    final total = game.gameScore;
    if (r == null) return const SizedBox.shrink();

    final modeLabel = r.mode == GameMode.sun ? 'Sun' : 'Hakam';
    final buyerLabel = r.buyerTeam == 'A' ? 'Us' : 'Them';
    final buyerWon = r.winningTeam == r.buyerTeam;
    final resultLabel = r.isKabout
        ? 'Kabout'
        : r.isKhams
            ? 'Khams'
            : buyerWon
                ? 'Won'
                : 'Lost';

    final resultColor = r.isKabout
        ? AppColors.goldAccent
        : r.isKhams
            ? const Color(0xFFE63946)
            : const Color(0xFF28802E);

    // Compute ground display: last trick bonus is +10
    final groundA = r.lastTrickBonusTeam == 'A' ? 10 : 0;
    final groundB = r.lastTrickBonusTeam == 'B' ? 10 : 0;

    // Trick Abnat = raw trick card points minus the ground bonus
    // (since turnManager.teamAAbnat includes the +10)
    final trickA = r.teamATrickAbnat - groundA;
    final trickB = r.teamBTrickAbnat - groundB;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.60),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1.0),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            builder: (ctx, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 22),
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1810),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.50),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header: Mode + Buyer + Result ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(17)),
                    ),
                    child: Row(
                      children: [
                        _HeaderPill(label: modeLabel),
                        const SizedBox(width: 8),
                        Text(
                          'Buyer: $buyerLabel',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: resultColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: resultColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            resultLabel,
                            style: TextStyle(
                              color: resultColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Breakdown Table ──
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Column(
                      children: [
                        // Column headers
                        _TableRow(
                          label: '',
                          valA: 'Us',
                          valB: 'Them',
                          isHeader: true,
                        ),
                        _divider(),

                        // Tricks
                        _TableRow(
                          label: 'Tricks',
                          valA: '$trickA',
                          valB: '$trickB',
                        ),

                        // Ground (+10 last trick)
                        if (r.lastTrickBonusTeam != null)
                          _TableRow(
                            label: 'Ground',
                            valA: groundA > 0 ? '+$groundA' : '',
                            valB: groundB > 0 ? '+$groundB' : '',
                            subtle: true,
                          ),

                        // Projects
                        if (r.teamAProjectAbnat > 0 ||
                            r.teamBProjectAbnat > 0)
                          _TableRow(
                            label: 'Projects',
                            valA: r.teamAProjectAbnat > 0
                                ? '${r.teamAProjectAbnat}'
                                : '',
                            valB: r.teamBProjectAbnat > 0
                                ? '${r.teamBProjectAbnat}'
                                : '',
                            highlight: true,
                          ),

                        _divider(),

                        // Total Abnat
                        _TableRow(
                          label: 'Abnat',
                          valA: '${r.teamAAbnat}',
                          valB: '${r.teamBAbnat}',
                          bold: true,
                        ),

                        _thickDivider(),

                        // Score (scoreboard points)
                        _TableRow(
                          label: 'Score',
                          valA: '${r.teamAPoints}',
                          valB: '${r.teamBPoints}',
                          bold: true,
                          scoreRow: true,
                          aColor: const Color(0xFF28802E),
                          bColor: const Color(0xFFE63946),
                        ),
                      ],
                    ),
                  ),

                  // ── Footer: Game Total + Next Round ──
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      children: [
                        Divider(
                            color: Colors.white.withValues(alpha: 0.10)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Game total',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.40),
                                fontSize: 12,
                              ),
                            ),
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
                        const SizedBox(height: 6),
                        Text(
                          'Next round\u2026',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.30),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
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

  static Widget _divider() => Divider(
        height: 1,
        thickness: 0.5,
        color: Colors.white.withValues(alpha: 0.07),
      );

  static Widget _thickDivider() => Divider(
        height: 2,
        thickness: 1,
        color: AppColors.goldAccent.withValues(alpha: 0.25),
      );
}

// ── Header pill (mode badge) ───────────────────────────────────────

class _HeaderPill extends StatelessWidget {
  final String label;
  const _HeaderPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppColors.goldAccent.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.goldAccent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Breakdown table row ────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final String label;
  final String valA;
  final String valB;
  final bool isHeader;
  final bool subtle;
  final bool bold;
  final bool highlight;
  final bool scoreRow;
  final Color? aColor;
  final Color? bColor;

  const _TableRow({
    required this.label,
    required this.valA,
    required this.valB,
    this.isHeader = false,
    this.subtle = false,
    this.bold = false,
    this.highlight = false,
    this.scoreRow = false,
    this.aColor,
    this.bColor,
  });

  @override
  Widget build(BuildContext context) {
    final baseAlpha = subtle ? 0.35 : isHeader ? 0.45 : 0.80;
    final baseColor = Colors.white.withValues(alpha: baseAlpha);
    final fontSize = scoreRow ? 18.0 : isHeader ? 10.0 : 13.0;
    final weight = bold || scoreRow
        ? FontWeight.w900
        : isHeader
            ? FontWeight.w600
            : FontWeight.w500;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: scoreRow ? 6 : 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                color: highlight
                    ? AppColors.goldAccent.withValues(alpha: 0.8)
                    : baseColor,
                fontSize: isHeader ? 10 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valA,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: aColor ?? (highlight
                    ? AppColors.goldAccent
                    : baseColor),
                fontSize: fontSize,
                fontWeight: weight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valB,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: bColor ?? (highlight
                    ? AppColors.goldAccent
                    : baseColor),
                fontSize: fontSize,
                fontWeight: weight,
              ),
            ),
          ),
        ],
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
