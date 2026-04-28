import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/game_l10n.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../data/models/card_model.dart' show GameMode, Suit;
import '../../../../data/models/round_state_model.dart' show DoubleStatus;
import '../game_provider.dart';

// ══════════════════════════════════════════════════════════════════
//  ROUND SCORE OVERLAY — Kammelna-style breakdown + Majlis charcoal theme
//
//  • Charcoal panel (matches table HUD), gold accent border
//  • Rows: Tricks, Ground, Projects, Points (Abnat), Result — AR when locale ar
//  • Exit / Play again below the card (not inside the border)
// ══════════════════════════════════════════════════════════════════

/// Localized strings aligned with Kammelna column labels (لنا / لهم / الأبناط…).
class _RoundScoreStrings {
  _RoundScoreStrings({required this.ar});

  final bool ar;

  String get title => ar ? 'لوحة النقاط' : 'Scoreboard';
  String get game => ar ? 'اللعبة' : 'Game';
  String get buyer => ar ? 'المشتري' : 'Buyer';
  String get stakes => ar ? 'الدبل' : 'Stakes';
  String get tricks => ar ? 'الأكلات' : 'Tricks';
  String get ground => ar ? 'الأرض' : 'Ground';
  String get projects => ar ? 'المشاريع' : 'Projects';
  /// Trick card points only (threshold 65/81); excludes project lines.
  String get trickPoints => ar ? 'أبناط الورق (الأكل)' : 'Trick pts (cards)';
  String get points => ar ? 'الأبناط' : 'Points';
  String get khamsProjectsNote =>
      ar ? 'مشاريع المشتري إلى المدافعين' : 'Buyer projects to defenders';
  String get result => ar ? 'النتيجة' : 'Result';
  String get them => ar ? 'لهم' : 'Them';
  String get us => ar ? 'لنا' : 'Us';
  String get ourTeam => ar ? 'فريقنا' : 'Our team';
  String get theirTeam => ar ? 'فريقهم' : 'Their team';

  String get exitGame => ar ? 'خروج' : 'Exit game';
  String get playAgain => ar ? 'العب مرة أخرى' : 'Play again';

  String get labelKhams =>
      ar ? 'نتيجة الشراء: خسرانة (كهمس)' : 'Purchase result: Lost (Khams)';
  String get labelWon => ar ? 'نتيجة الشراء: فائزة' : 'Purchase result: Won';
  String get labelViolationPenalty => ar ? 'غرامة قيد — خسارة دور' : 'Qaid violation — round lost';

  /// When buyer’s side took all tricks (successful purchase sweep).
  String get labelWonKabout =>
      ar ? 'نتيجة الشراء: فائزة (كبوت)' : 'Purchase result: Won (Kabout sweep)';

  /// When defenders took all tricks (Khams-equivalent headline; counted as Kabout in scoring).
  String get labelLostOppKabout =>
      ar ? 'نتيجة الشراء: خسرانة (كبوت للمدافعين)' :
      'Purchase result: Lost (defenders took Kabout)';

  /// One line: threshold is trick Abnat only (no projects in the comparison).
  String khamsThresholdShort(bool sunMode) => sunMode
      ? (ar ? 'أبناط الورق فقط: الصن يحتاج فوق 65' : 'Cards only: Sun needs above 65')
      : (ar ? 'أبناط الورق فقط: الحكم يحتاج فوق 81' : 'Cards only: Hakam needs above 81');

  TextStyle footnoteStyle(
    TextStyle Function({double size, FontWeight w, Color? color}) taj,
  ) =>
      taj(size: 10, w: FontWeight.w500, color: Colors.white.withValues(alpha: 0.5));

  /// In-play Sawa — one short line (claimant gets remaining card points + ground).
  String playSawaShortLine(int claimSeat, String buyerTeam) {
    final claimTeam = claimSeat.isEven ? 'A' : 'B';
    if (claimTeam == buyerTeam) {
      return ar ? 'سوَا يد: الباقي لفريق المشتري' : 'Sawa: remainder to buyer';
    }
    return ar ? 'سوَا يد: الباقي للمدافعين' : 'Sawa: remainder to defenders';
  }

  String matchCaption(int teamA, int teamB) => ar
      ? 'المباراة: لنا $teamA، لهم $teamB'
      : 'Match: Us $teamA, Them $teamB';
}

class RoundScoreOverlay extends StatelessWidget {
  const RoundScoreOverlay({super.key});

  /// Majlis / game-table charcoal (same family as [HumanPlayerMajlisBar]).
  static const _panelBg = Color(0xFF2C2C2C);
  static const _innerBg = Color(0xFF232323);
  static const _innerBorder = Color(0x1AFFFFFF);
  static const _themColor = Color(0xFFE63946);
  static const _usColor = Color(0xFF28802E);
  static const _lossRed = Color(0xFFFF5252);
  static const _titleGold = Color(0xFFC9A227);

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isAr = context.watch<LocaleProvider>().isArabic;
    final s = _RoundScoreStrings(ar: isAr);
    final r = game.lastRoundResult;
    final total = game.gameScore;
    if (r == null) return const SizedBox.shrink();

    final buyerSide = r.buyerTeam == 'A' ? s.ourTeam : s.theirTeam;

    // Headlines follow engine semantics (Khams/Kabout/normal).
    // Khams thresholds use trick Abnat only; projects are scored separately on the board.
    final (contractText, contractColor) = () {
      if (r.reason == 'qaid_penalty') {
        return (s.labelViolationPenalty, _lossRed);
      }
      if (r.isKhams) {
        return (s.labelKhams, _lossRed);
      }
      if (r.isKabout) {
        final buyerSwept = r.winningTeam == r.buyerTeam;
        if (buyerSwept) {
          return (s.labelWonKabout, const Color(0xFF69F0AE));
        }
        return (s.labelLostOppKabout, _lossRed);
      }
      return (s.labelWon, const Color(0xFF69F0AE));
    }();

    final groundA = r.lastTrickBonusTeam == 'A' ? 10 : 0;
    final groundB = r.lastTrickBonusTeam == 'B' ? 10 : 0;
    final trickA = r.teamATrickAbnat - groundA;
    final trickB = r.teamBTrickAbnat - groundB;

    final stakesEn = _stakesLabel(r.doubleStatus);
    final stakes = _stakesLabelLocalized(stakesEn, isAr);
    final g10n = GameL10n.of(context);
    final trumpSym = switch (r.trumpSuit) {
      Suit.hearts => '♥',
      Suit.diamonds => '♦',
      Suit.spades => '♠',
      Suit.clubs => '♣',
      null => '',
    };
    final gameLine = g10n.scoreboardGameLine(r.mode, trumpSym.isEmpty ? null : trumpSym);

    TextStyle taj({
      double size = 13,
      FontWeight w = FontWeight.w500,
      Color? color,
    }) =>
        GoogleFonts.readexPro(
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 368),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: _panelBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _titleGold.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              s.title,
                              style: GoogleFonts.readexPro(
                                color: _titleGold,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 0.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (r.playSawaClaimSeat != null) ...[
                              Text(
                                s.playSawaShortLine(
                                  r.playSawaClaimSeat!,
                                  r.buyerTeam,
                                ),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.readexPro(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _titleGold.withValues(alpha: 0.85),
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Container(
                              height: 1,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _titleGold.withValues(alpha: 0.0),
                                    _titleGold.withValues(alpha: 0.65),
                                    _titleGold.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
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
                                  _statusRow(s.game, gameLine, taj: taj),
                                  const SizedBox(height: 6),
                                  _statusRow(s.buyer, buyerSide, taj: taj),
                                  if (stakes != null) ...[
                                    const SizedBox(height: 6),
                                    _statusRow(s.stakes, stakes, taj: taj),
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
                                  if (r.isKhams) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      s.khamsThresholdShort(r.mode == GameMode.sun),
                                      style: s.footnoteStyle(taj),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
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
                                  _ScoreTableRow.header(
                                    taj,
                                    themLabel: s.them,
                                    usLabel: s.us,
                                  ),
                                  _thinRule(),
                                  _ScoreTableRow.data(
                                    s.tricks,
                                    trickB,
                                    trickA,
                                    taj,
                                  ),
                                  _ScoreTableRow.dataOptional(
                                    s.ground,
                                    groundB,
                                    groundA,
                                    taj,
                                  ),
                                  _ScoreTableRow.dataOptional(
                                    s.projects,
                                    r.teamBProjectAbnat,
                                    r.teamAProjectAbnat,
                                    taj,
                                  ),
                                  if (r.isKhams) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      s.khamsProjectsNote,
                                      textAlign: TextAlign.center,
                                      style: taj(
                                        size: 10,
                                        w: FontWeight.w500,
                                        color:
                                            Colors.white.withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ],
                                  _thinRule(),
                                  _ScoreTableRow.data(
                                    s.trickPoints,
                                    r.teamBTrickAbnat,
                                    r.teamATrickAbnat,
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
                                      color:
                                          Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _titleGold
                                            .withValues(alpha: 0.22),
                                      ),
                                    ),
                                    child: _ScoreTableRow.data(
                                      s.result,
                                      r.teamBPoints,
                                      r.teamAPoints,
                                      taj,
                                      isFinal: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.matchCaption(total.teamA, total.teamB),
                              style: taj(
                                size: 11,
                                w: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.42),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String? _stakesLabelLocalized(String? en, bool ar) {
    if (en == null) return null;
    if (!ar) return en;
    return switch (en) {
      'Double' => 'دبل',
      'Triple' => 'تربل',
      'Four' => 'أربعة',
      'Gahwa' => 'قهوة',
      _ => en,
    };
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
    }) taj, {
    required String themLabel,
    required String usLabel,
  }) {
    return _ScoreTableRow._(
      label: '',
      themText: themLabel,
      usText: usLabel,
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

// ══════════════════════════════════════════════════════════════════
//  GAME OVER OVERLAY — full screen when [GamePhase.gameOver]
// ══════════════════════════════════════════════════════════════════

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    context.watch<LocaleProvider>();
    final loc = GameL10n.of(context);
    final total = game.gameScore;
    final lastRound = game.lastRoundResult;
    final winner = game.gameWinner;

    final humanWon = game.didHumanWinGame;
    final gahwa = game.roundState.doubleStatus == DoubleStatus.gahwa;
    final title = gahwa
        ? loc.gahwaTitle
        : humanWon
            ? loc.youWin
            : loc.youLose;

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
                      letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 0.5,
                    ),
                  ),
                  if (winner != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        loc.teamReachedTarget(winner == 'A', context.read<GameProvider>().targetScore),
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
                        Text(loc.finalScore,
                            style: const TextStyle(
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
                            loc.lastRoundPts(
                              lastRound.teamAPoints,
                              lastRound.teamBPoints,
                            ),
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
                          onPressed: () {
                            context.read<GameProvider>().leaveTable();
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
                            context.read<GameProvider>().restartGame();
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
