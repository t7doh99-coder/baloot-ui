import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../game_provider.dart';
import '../../../../data/models/card_model.dart' show GameMode;
import '../../../../data/models/round_state_model.dart' show DoubleStatus;
import '../../domain/models/qaydha_models.dart';
import 'playing_card.dart';
import 'qaydha_types.dart' show QaydhaActionType;
import 'seat_orientation_indicator.dart';

class QaydhaReviewOverlay extends StatefulWidget {
  const QaydhaReviewOverlay({super.key});

  @override
  State<QaydhaReviewOverlay> createState() => _QaydhaReviewOverlayState();
}

class _QaydhaReviewOverlayState extends State<QaydhaReviewOverlay> {
  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isAr = context.watch<LocaleProvider>().isArabic;
    final font = GoogleFonts.readexPro;

    // Show result screen if challenge was submitted and result is available
    final challengeResult = game.qaydhaChallengeResult;
    final isResultMode = challengeResult != null;

    if (!game.isQaydhaReviewVisible && !isResultMode) {
      return const SizedBox.shrink();
    }

    final List<dynamic> tricks = game.trickHistoryThisRound;

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          color: Colors.black.withValues(alpha: 0.88),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // ── Top Panel ──────────────────────────────────────
                  if (challengeResult != null)
                    _buildResultTopPanel(
                        context, game, font, isAr, challengeResult)
                  else
                    _buildSelectionTopPanel(context, game, font, isAr),

                  // ── Scrollable Body ──────────────────────────
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        ...List.generate(tricks.length, (index) {
                          return _buildTrickRow(
                              context, game, index, tricks[index], font, isAr,
                              isResultMode: isResultMode);
                        }),
                        const SizedBox(height: 16),
                        _buildPlayersCardsSection(context, game, font, isAr,
                            isResultMode: isResultMode),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // ── Bottom Bar ──────────────────────────────────────
                  _buildBottomBar(context, game, font, isAr,
                      isResultMode: isResultMode),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViolationIcon(String type, Color color) {
    switch (type) {
      case 'cut':
        return Icon(Icons.content_cut, color: color, size: 22);
      case 'diamond':
        return CustomPaint(size: const Size(20, 20), painter: _SuitDiamondPainter(color));
      case 'spade':
        return CustomPaint(size: const Size(20, 20), painter: _SuitSpadePainter(color));
      case 'club':
        return CustomPaint(size: const Size(20, 20), painter: _SuitClubPainter(color));
      case 'star':
        return Icon(Icons.workspace_premium, color: color, size: 20);
      default:
        return const SizedBox(width: 20, height: 20);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOP PANEL — SELECTION MODE  (matches Kammelna layout exactly)
  // Row 1: Left pill (instruction text) | Right label "نوع القيد"
  // Row 2: Horizontal row of violation type buttons
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSelectionTopPanel(
      BuildContext context,
      GameProvider game,
      TextStyle Function(
              {Color? color, double? fontSize, FontWeight? fontWeight})
          font,
      bool isAr) {
    final hasAccusedCard = game.selectedQaydhaTrickIndex != null;
    final selectedViolation = game.selectedQaydhaViolationIndex;

    // Check if proof card is required:
    // 0: Cut (qate), 2: Didn't Over-Trump (maKabbarBiHakam), 3: Didn't Trump (maDaqBiHakam)
    final bool requiresProof = selectedViolation != null &&
        (selectedViolation == 0 || selectedViolation == 2 || selectedViolation == 3);
    final hasProofCard = game.selectedQaydhaProofCardIndex != null ||
        game.selectedQaydhaProofTrickIndex != null;

    final bool isReady = hasAccusedCard &&
        selectedViolation != null &&
        (!requiresProof || hasProofCard);

    final bool isWaitingForProof = hasAccusedCard && selectedViolation != null && requiresProof && !hasProofCard;
    final bool isWaitingForViolation = hasAccusedCard && selectedViolation == null;

    final String instructionText = isReady
        ? (isAr ? 'جاهز — اضغط قيدها' : 'Ready — Press Challenge to submit')
        : isWaitingForProof
            ? (isAr ? 'أختر الورقة التي كشفت الغش' : 'Choose the card that revealed the cheating')
            : isWaitingForViolation
                ? (isAr ? 'الآن أختر نوع القيد أعلاه' : 'Now choose the violation type above')
                : (isAr ? 'أختر الورقة التي تم الغش بها' : 'Choose the card that was cheated with');

    final Color infoBoxBorderColor = isReady
        ? const Color(0x884ADE80)
        : isWaitingForProof
            ? const Color(0x88D4A843)
            : const Color(0x66E03535);

    final List<Color> infoBoxGradient = isReady
        ? const [Color(0xFF0A2E16), Color(0xFF0D2519)]
        : isWaitingForProof
            ? const [Color(0xFF2E200A), Color(0xFF1E1405)]
            : const [Color(0xFF2A0D0D), Color(0xFF1E0A0A)];

    final Color infoBoxTextColor = isReady
        ? const Color(0xFFA7F3C0)
        : isWaitingForProof
            ? const Color(0xFFF0CA60)
            : const Color(0xFFF5A0A0);

    final List<Map<String, dynamic>> violations = [
      {'id': 0, 'label': isAr ? 'قاطع' : 'Cut', 'type': 'cut'},
      {'id': 1, 'label': isAr ? 'ربع في الدبل' : 'Four in Double', 'type': 'diamond'},
      {'id': 2, 'label': isAr ? 'ما كبر بحكم' : "Didn't Over-Trump", 'type': 'spade'},
      {'id': 3, 'label': isAr ? 'ما دق بحكم' : "Didn't Trump", 'type': 'club'},
      {'id': 4, 'label': isAr ? 'أكة خاطئة' : 'False Akka', 'type': 'star'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF221509), Color(0xFF160E05)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF3D2410), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x77000000),
            blurRadius: 32,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          // Centered "Select" and "Violation Type" heading
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0xFFD4A843)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isAr ? 'أختر' : 'SELECT',
                style: font(color: const Color(0x99D4A843), fontSize: 12, fontWeight: FontWeight.bold).copyWith(letterSpacing: 2),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD4A843), Colors.transparent],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isAr ? 'نوع القيد' : 'Violation Type',
            style: font(
              color: const Color(0xFFD4A843),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ).copyWith(
              letterSpacing: 1,
              shadows: [
                const Shadow(color: Color(0x66D4A843), blurRadius: 20),
                const Shadow(color: Color(0x99000000), blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4 Violation boxes — Equal height with IntrinsicHeight & stretch
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: violations.map((v) {
                final int vId = v['id'] as int;
                final mode = game.roundState.activeMode;
                final isSun = mode == GameMode.sun;
                final isClosedDouble = game.doubleStatus != DoubleStatus.none && !game.isOpenPlay;

                bool isAvailable = true;
                if (vId == 1) {
                  // Four in double is ONLY valid in Hakam Closed Double
                  isAvailable = !isSun && isClosedDouble;
                } else if (vId == 2 || vId == 3) {
                  // Over-trump and Trump violations are ONLY valid in Hakam
                  isAvailable = !isSun;
                } else if (vId == 4) {
                  // False Ekka is valid in Hakam
                  isAvailable = !isSun;
                }

                final isSelected = isAvailable && selectedViolation == vId;
                final iconColor = !isAvailable
                    ? const Color(0xFF4A3520)
                    : (isSelected ? const Color(0xFFF0CA60) : const Color(0xFF6B4A2A));
                return Expanded(
                  child: Opacity(
                    opacity: isAvailable ? 1.0 : 0.38,
                    child: GestureDetector(
                      onTap: isAvailable ? () => game.setQaydhaViolationIndex(vId) : null,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isSelected
                                ? [const Color(0xFF3D2800), const Color(0xFF2A1C00), const Color(0xFF1E1400)]
                                : [const Color(0xFF2A1A08), const Color(0xFF1E1108)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFD4A843) : const Color(0xFF3D2410),
                            width: isSelected ? 2 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  const BoxShadow(color: Color(0x44D4A843), blurRadius: 16, spreadRadius: 3),
                                  const BoxShadow(color: Color(0x55000000), blurRadius: 12, offset: Offset(0, 4)),
                                ]
                              : [
                                  const BoxShadow(color: Color(0x44000000), blurRadius: 8, offset: Offset(0, 2)),
                                  const BoxShadow(color: Color(0x08FFFFFF), blurRadius: 0, spreadRadius: 1, offset: Offset(0, 1)),
                                ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildViolationIcon(v['type'] as String, iconColor),
                            const SizedBox(height: 6),
                            Text(
                              v['label'] as String,
                              textAlign: TextAlign.center,
                              style: font(
                                color: !isAvailable
                                    ? const Color(0xFF5A4430)
                                    : (isSelected ? const Color(0xFFF0CA60) : const Color(0xFFA07850)),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ).copyWith(height: 1.15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Information box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: infoBoxGradient,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: infoBoxBorderColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: infoBoxBorderColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Center(
              child: Text(
                instructionText,
                textAlign: TextAlign.center,
                style: font(
                  color: infoBoxTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOP PANEL — RESULT MODE
  // Left box: GREEN "نتيجة القيد: صحيح" or RED "نتيجة القيد: خطأ"
  // Right box: "نوع القيد : قاطع" (the violation type that was confirmed)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildResultTopPanel(
      BuildContext context,
      GameProvider game,
      TextStyle Function(
              {Color? color, double? fontSize, FontWeight? fontWeight})
          font,
      bool isAr,
      QaydhaResult result) {
    final isSuccess = result.isCorrect;

    final String violationLabel;
    if (game.currentQaydhaAction == QaydhaActionType.wrongSawa) {
      violationLabel = isAr ? 'سوا خطأ' : 'False Sawa';
    } else {
      switch (result.violationType) {
        case QaydhaViolationType.qate:
          violationLabel = isAr ? 'قاطع' : 'Cut';
          break;
        case QaydhaViolationType.rubFiAlDubl:
          violationLabel = isAr ? 'ربع في الدبل' : 'Four in Double';
          break;
        case QaydhaViolationType.maKabbarBiHakam:
          violationLabel = isAr ? 'ما كبر بحكم' : 'Did Not Over-Trump';
          break;
        case QaydhaViolationType.maDaqBiHakam:
          violationLabel = isAr ? 'ما دق بحكم' : 'Did Not Trump';
          break;
        case QaydhaViolationType.falseEkka:
          violationLabel = isAr ? 'أكة خاطئة' : 'False Akka';
          break;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF221509), Color(0xFF160E05)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF3D2410), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x77000000),
            blurRadius: 32,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          // Left Pill: Result Banner (Green if correct, Red if wrong)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isSuccess
                      ? const [Color(0xFF7CB342), Color(0xFF558B2F)] // Vibrant Grass/Lime Green like 7.png
                      : const [Color(0xFFE53935), Color(0xFFB71C1C)], // Crimson Red
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSuccess ? const Color(0xFFAED581) : const Color(0xFFEF9A9A),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSuccess ? const Color(0xFF558B2F) : const Color(0xFFB71C1C))
                        .withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isSuccess
                      ? (isAr ? 'نتيجة القيد: صحيح' : 'Result: Correct')
                      : (isAr ? 'نتيجة القيد: خطأ' : 'Result: Wrong'),
                  textAlign: TextAlign.center,
                  style: font(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Right Pill: Violation Type
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2C2210), Color(0xFF1E1608)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3D2410),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isAr ? 'نوع القيد : $violationLabel' : 'Violation : $violationLabel',
                  textAlign: TextAlign.center,
                  style: font(
                    color: const Color(0xFFF5E6C8),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────────────────
  // TRICK ROW
  // Cards in tricks:
  //   • PINK/RED highlight = the card accused of cheating (selectedQaydhaTrickIndex + selectedQaydhaCardSeatIndex)
  //   • No highlight for other cards
  // In result mode, the same highlights stay visible as evidence
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTrickRow(
      BuildContext context,
      GameProvider game,
      int trickIndex,
      dynamic trickResult,
      TextStyle Function(
              {Color? color, double? fontSize, FontWeight? fontWeight})
          font,
      bool isAr,
      {bool isResultMode = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: const Color(0xFF1E1808), // Sandstone dark canvas
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0x60C49028), width: 1.2), // Gold border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0, 3),
              blurRadius: 5,
            )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF392C14),
                  Color(0xFF2C2210)
                ], // Warm dark gradient
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Text(
              isAr ? 'الأكلة ${trickIndex + 1}' : 'Trick ${trickIndex + 1}',
              textAlign: isAr ? TextAlign.right : TextAlign.left,
              style: font(
                  color: const Color(0xFFF8EDD8), // Warm Ivory text
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ),
          // Cards fan
          Container(
            height: 130,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(4, (i) {
                if (i >= trickResult.cards.length) {
                  return const SizedBox.shrink();
                }
                final cardPlay = trickResult.cards[i];
                final isAccusedCard = game.selectedQaydhaTrickIndex == trickIndex &&
                    game.selectedQaydhaCardSeatIndex == cardPlay.playerIndex;
                final isProofCard = game.selectedQaydhaProofTrickIndex == trickIndex &&
                    (game.selectedQaydhaProofSeatIndex == cardPlay.playerIndex ||
                        game.selectedQaydhaProofCardIndex == i);

                Color highlightColor = Colors.transparent;
                if (isAccusedCard) {
                  highlightColor = const Color(0xFFFF4D4F); // Vibrant Red for accused cheating card
                } else if (isProofCard) {
                  highlightColor = const Color(0xFF4ADE80); // Vibrant Green for proof card
                }

                final factor = i - 1.5;
                final dx = factor * 58.0;
                final dy = factor.abs() * 3.5;
                final rot = factor * 0.055;

                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.rotate(
                    angle: rot,
                    child: GestureDetector(
                      onTap: isResultMode
                          ? null
                          : () => game.selectQaydhaCard(
                              trickIndex, cardPlay.playerIndex,
                              cardIndexInTrick: i),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Card shadow for accused (RED) or proof (GREEN) card
                          if (isAccusedCard || isProofCard)
                            Container(
                              height: 90,
                              width: 65,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: highlightColor.withValues(alpha: 0.9),
                                    blurRadius: 16,
                                    spreadRadius: 4,
                                  )
                                ],
                              ),
                            ),
                          SizedBox(
                            height: 90,
                            width: 65,
                            child: PlayingCard(
                              card: cardPlay.card,
                              faceUp: true,
                            ),
                          ),
                          // Highlight overlay for accused or proof card
                          if (isAccusedCard || isProofCard)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isAccusedCard
                                      ? const Color(0xFFFF4D4F).withValues(alpha: 0.60)
                                      : const Color(0xFF22C55E).withValues(alpha: 0.50),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: isAccusedCard
                                          ? const Color(0xFFFF4D4F)
                                          : const Color(0xFF4ADE80),
                                      width: 2.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PLAYER HANDS SECTION (4 Players Grid matching Kammelna 5.png)
  // Shows all 4 players' unplayed hands.
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPlayersCardsSection(
      BuildContext context,
      GameProvider game,
      TextStyle Function(
              {Color? color, double? fontSize, FontWeight? fontWeight})
          font,
      bool isAr,
      {bool isResultMode = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        children: [
          // Row 1: Seat 1 and Seat 2 (matching Kammelna 5.png top row)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildPlayerHandBox(context, game, 1, font, isAr,
                    isResultMode: isResultMode),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPlayerHandBox(context, game, 2, font, isAr,
                    isResultMode: isResultMode),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Seat 0 and Seat 3 (matching Kammelna 5.png bottom row)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildPlayerHandBox(context, game, 0, font, isAr,
                    isResultMode: isResultMode),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPlayerHandBox(context, game, 3, font, isAr,
                    isResultMode: isResultMode),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHandBox(
      BuildContext context,
      GameProvider game,
      int seatIndex,
      TextStyle Function(
              {Color? color, double? fontSize, FontWeight? fontWeight})
          font,
      bool isAr,
      {bool isResultMode = false}) {
    final hand = game.getHand(seatIndex);
    final playerName = game.playerName(seatIndex);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1808),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x40C49028), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF2C2210),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(
                  bottom: BorderSide(color: Color(0x40C49028), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    playerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: font(
                      color: const Color(0xFFF8EDD8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SeatOrientationIndicator(seatIndex: seatIndex),
              ],
            ),
          ),
          // Cards Area
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: hand.isEmpty
                ? SizedBox(
                    height: 50,
                    child: Center(
                      child: Text(
                        isAr ? 'لا توجد أوراق' : 'No cards',
                        style:
                            font(color: const Color(0xFF7A6850), fontSize: 10),
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 4,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: List.generate(hand.length, (cardIndex) {
                      final card = hand[cardIndex];
                      final isSelectedProof =
                          game.selectedQaydhaProofTrickIndex == null &&
                              game.selectedQaydhaProofSeatIndex == seatIndex &&
                              game.selectedQaydhaProofCardIndex == cardIndex;

                      return GestureDetector(
                        onTap: isResultMode
                            ? null
                            : () => game.selectQaydhaProofCard(
                                seatIndex, cardIndex),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          transform: Matrix4.translationValues(
                              0, isSelectedProof ? -6 : 0, 0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isSelectedProof)
                                Container(
                                  height: 64,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x9922C55E),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              SizedBox(
                                height: 64,
                                width: 44,
                                child: PlayingCard(
                                  card: card,
                                  faceUp: true,
                                ),
                              ),
                              if (isSelectedProof)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E)
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: const Color(0xFF4ADE80),
                                          width: 2.0),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOTTOM BAR
  // Selection mode: "قيدها" button (Royal Gold gradient)
  // Result mode: "إغلاق" (Close) button
  // Both modes: Challenger name + countdown timer on the right
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomBar(
      BuildContext context,
      GameProvider game,
      TextStyle Function(
              {Color? color, double? fontSize, FontWeight? fontWeight})
          font,
      bool isAr,
      {bool isResultMode = false}) {
    final selectedViolation = game.selectedQaydhaViolationIndex;
    
    // Determine if proof card is required
    // 0: qate, 1: rubFiAlDubl, 2: maKabbarBiHakam, 3: maDaqBiHakam, 4: falseEkka
    bool requiresProof = false;
    if (selectedViolation != null && (selectedViolation == 0 || selectedViolation == 2 || selectedViolation == 3)) {
      requiresProof = true;
    }

    // An accused card MUST be selected from a trick
    final hasProofCard = game.selectedQaydhaProofCardIndex != null ||
        game.selectedQaydhaProofTrickIndex != null;
    bool canSubmit = game.selectedQaydhaTrickIndex != null && selectedViolation != null;
    if (requiresProof) {
      canSubmit = canSubmit && hasProofCard;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFF221509), Color(0xFF160E05)],
        ),
        border: Border(top: BorderSide(color: Color(0xFF3D2410), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x77000000),
            blurRadius: 32,
            offset: Offset(0, -6),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Action Button (Left)
          Builder(builder: (context) {
            if (isResultMode) {
              return GestureDetector(
                onTap: () {
                  game.closeQaydhaResult();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE8D5B0), Color(0xFFCDB88A)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC9A870), width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x44000000), blurRadius: 10, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    isAr ? 'إغلاق' : 'Close',
                    style: font(color: const Color(0xFF3D2200), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            } else if (canSubmit) {
              return GestureDetector(
                onTap: () => game.submitQaydhaChallenge(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFC9860A), Color(0xFFA86C04)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF0CA60), width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x66C9860A), blurRadius: 16),
                    ],
                  ),
                  child: Text(
                    isAr ? 'قيدها' : 'Challenge',
                    style: font(color: const Color(0xFF1A0F03), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            } else {
              // Disabled "قيدها" button during selection (matching Kammelna 2.png)
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2210),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x40C49028), width: 1.5),
                ),
                child: Text(
                  isAr ? 'قيدها' : 'Challenge',
                  style: font(color: const Color(0xFF6E5630), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              );
            }
          }),

          // Challenger info pill (Center) — displayed in both Selection and Result mode
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A1A08), Color(0xFF1E1108)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF3D2410), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0x44000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAr ? 'المقيد:' : 'Challenger:',
                  style: font(color: const Color(0xFFA07850), fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                Text(
                  game.playerName(0),
                  style: font(color: const Color(0xFFF5E6C8), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Timer (Right) — active in both Selection (60s) and Result mode (6s auto-close)
          TweenAnimationBuilder<double>(
            key: ValueKey(isResultMode),
            tween: Tween(begin: 1.0, end: 0.0),
            duration: Duration(seconds: isResultMode ? 6 : 60),
            onEnd: () {
              if (isResultMode) {
                if (game.qaydhaChallengeResult != null) {
                  game.closeQaydhaResult();
                }
              } else if (game.isQaydhaReviewVisible) {
                if (canSubmit) {
                  game.submitQaydhaChallenge();
                } else {
                  // Time ran out without valid proof -> challenger automatically loses round
                  game.submitFailedQaydhaOnTimeout();
                }
              }
            },
            builder: (context, value, child) {
              final secondsTotal = isResultMode ? 6 : 60;
              final secondsLeft = (value * secondsTotal).ceil();
              final color = isResultMode
                  ? const Color(0xFFD4A843)
                  : (secondsLeft > 30
                      ? const Color(0xFFD4A843)
                      : secondsLeft > 10
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444));
              return SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 3.5,
                      backgroundColor: const Color(0xFF2A1A08),
                      color: color,
                    ),
                    Text(
                      '$secondsLeft',
                      style: font(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SuitDiamondPainter extends CustomPainter {
  final Color color;
  const _SuitDiamondPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.95, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(size.width * 0.05, size.height * 0.5)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SuitDiamondPainter oldDelegate) => oldDelegate.color != color;
}

class _SuitSpadePainter extends CustomPainter {
  final Color color;
  const _SuitSpadePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.5, 0);
    path.cubicTo(w * 0.35, h * 0.22, 0, h * 0.42, 0, h * 0.65);
    path.cubicTo(0, h * 0.82, w * 0.22, h * 0.84, w * 0.44, h * 0.72);
    path.lineTo(w * 0.42, h);
    path.lineTo(w * 0.58, h);
    path.lineTo(w * 0.56, h * 0.72);
    path.cubicTo(w * 0.78, h * 0.84, w, h * 0.82, w, h * 0.65);
    path.cubicTo(w, h * 0.42, w * 0.65, h * 0.22, w * 0.5, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SuitSpadePainter oldDelegate) => oldDelegate.color != color;
}

class _SuitClubPainter extends CustomPainter {
  final Color color;
  const _SuitClubPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    // Top circle
    canvas.drawCircle(Offset(w * 0.5, h * 0.30), w * 0.24, paint);
    // Left circle
    canvas.drawCircle(Offset(w * 0.26, h * 0.60), w * 0.24, paint);
    // Right circle
    canvas.drawCircle(Offset(w * 0.74, h * 0.60), w * 0.24, paint);
    // Center connector
    canvas.drawCircle(Offset(w * 0.5, h * 0.54), w * 0.18, paint);
    // Stem
    final stem = Path()
      ..moveTo(w * 0.46, h * 0.55)
      ..lineTo(w * 0.36, h)
      ..lineTo(w * 0.64, h)
      ..lineTo(w * 0.54, h * 0.55)
      ..close();
    canvas.drawPath(stem, paint);
  }

  @override
  bool shouldRepaint(_SuitClubPainter oldDelegate) => oldDelegate.color != color;
}
