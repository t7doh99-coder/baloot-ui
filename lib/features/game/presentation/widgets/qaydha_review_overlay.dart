import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../game_provider.dart';
import '../../domain/models/qaydha_models.dart';
import 'qaydha_types.dart' show QaydhaActionType;
import 'playing_card.dart';
import '../../../../data/models/card_model.dart';
import '../../../../data/models/round_state_model.dart';

// Unused enum kept to avoid breaking any existing references
enum QaydhaReviewPhase { selectTrick, selectProof }

class QaydhaReviewOverlay extends StatefulWidget {
  const QaydhaReviewOverlay({super.key});

  @override
  State<QaydhaReviewOverlay> createState() => _QaydhaReviewOverlayState();
}

class _QaydhaReviewOverlayState extends State<QaydhaReviewOverlay> {
  // Kept for compatibility — no longer used as a phase controller
  QaydhaReviewPhase _currentPhase = QaydhaReviewPhase.selectTrick;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isAr = context.watch<LocaleProvider>().isArabic;
    final font = isAr ? GoogleFonts.tajawal : GoogleFonts.readexPro;

    // Show result screen if challenge was submitted and result is available
    final challengeResult = game.qaydhaChallengeResult;
    final isResultMode = challengeResult != null;

    if (!game.isQaydhaReviewVisible && !isResultMode) {
      return const SizedBox.shrink();
    }

    final action = game.currentQaydhaAction;
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
                        if (game.selectedQaydhaTrickIndex != null && !isResultMode)
                          _buildPlayersCardsSection(context, game, font, isAr),
                        const SizedBox(height: 20),
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

    // Instruction text (left pill) — mirrors Kammelna
    final String instructionText = hasAccusedCard && selectedViolation != null
        ? (isAr ? 'جاهز — اضغط قيدها' : 'Ready — Press Challenge')
        : hasAccusedCard
            ? (isAr ? 'أختر نوع القيد' : 'Choose violation type')
            : (isAr ? 'أختر الورقة التي تم الغش بها' : 'Choose the card that was cheated with');
    final Color instructionHighlight = (hasAccusedCard && selectedViolation != null)
        ? const Color(0xFF66BB6A) // GREEN — ready to submit
        : const Color(0xFFE53935); // RED — still selecting

    final mode = game.roundState.activeMode;
    final isHakam = mode == GameMode.hakam;
    final isClosedDouble =
        isHakam && game.doubleStatus != DoubleStatus.none && !game.isOpenPlay;

    // Build violation type options list (matches Kammelna: قاطع | ربع في الدبل | ما كبر بحكم | ما دق بحكم)
    final List<({int index, String label})> violationOptions = isHakam
        ? [
            (index: 0, label: isAr ? 'قاطع' : 'Cut'),
            if (isClosedDouble)
              (index: 1, label: isAr ? 'ربع في الدبل' : 'Four in Double'),
            (index: 2, label: isAr ? 'ما كبر بحكم' : "Didn't Over-Trump"),
            (index: 3, label: isAr ? 'ما دق بحكم' : "Didn't Trump"),
          ]
        : [
            (index: 0, label: isAr ? 'قاطع' : 'Cut'),
          ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1808),
        border: Border(bottom: BorderSide(color: Color(0x60C49028))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row 1: Instruction pill + "نوع القيد" label ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                // Left: Instruction pill
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2210),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: instructionHighlight.withValues(alpha: 0.6), width: 1),
                    ),
                    child: Text(
                      instructionText,
                      textAlign: TextAlign.center,
                      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                      style: font(
                          color: instructionHighlight,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Right: Static "نوع القيد" label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2210),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x60C49028), width: 1),
                  ),
                  child: Text(
                    isAr ? 'نوع القيد' : 'Violation Type',
                    style: font(
                        color: const Color(0xFFC49028),
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // ── Row 2: Horizontal violation type buttons (Kammelna style) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: violationOptions.map((opt) {
                  final isSelected = selectedViolation == opt.index;
                  return GestureDetector(
                    onTap: () => game.setQaydhaViolationIndex(opt.index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFFFFD54F), Color(0xFFC49028)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF392C14), Color(0xFF2C2210)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFE082)
                              : const Color(0x60C49028),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFC49028).withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        opt.label,
                        style: font(
                          color: isSelected
                              ? const Color(0xFF1E1808)
                              : const Color(0xFFF8EDD8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
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

    // Use a premium gradient for the result
    final resultGradient = isSuccess
        ? const LinearGradient(
            colors: [
              Color(0xFF66BB6A),
              Color(0xFF2E7D32)
            ], // Vibrant Royal Green
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFEF5350), Color(0xFFC62828)], // Vibrant Royal Red
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    // Get the violation type label that was selected
    final violationLabels = isAr
        ? ['قاطع', 'ربع في الدبل', 'ما كبر بحكم', 'ما دق بحكم', 'إكة خاطئة']
        : [
            'Cut',
            'Four in Double',
            'Did Not Over-Trump',
            'Did Not Trump',
            'False Ekka'
          ];
    final violationIdx = game.selectedQaydhaViolationIndex ?? 0;
    final violationLabel = violationLabels[violationIdx.clamp(0, 4)];

    final resultText = isSuccess
        ? (isAr
            ? 'نتيجة القيد: "$violationLabel" صحيح'
            : 'Qaid Result: "$violationLabel" Correct')
        : (isAr
            ? 'نتيجة القيد: "$violationLabel" خطأ'
            : 'Qaid Result: "$violationLabel" Wrong');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1808), // Sandstone dark canvas
        border: Border(bottom: BorderSide(color: Color(0x60C49028))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Centered perfectly
        children: [
          // Result banner pill
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                gradient: resultGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: isSuccess
                        ? const Color(0xFFA5D6A7)
                        : const Color(0xFFEF9A9A),
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: (isSuccess
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC62828))
                        .withValues(alpha: 0.4),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                  )
                ],
              ),
              child: Text(
                resultText,
                textAlign: TextAlign.center,
                style: font(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VIOLATION TYPE BUTTON
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildViolationBtn(
      BuildContext context,
      GameProvider game,
      TextStyle Function(
              {Color? color, double? fontSize, FontWeight? fontWeight})
          font,
      int index,
      String label) {
    final isSelected = game.selectedQaydhaViolationIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => game.setQaydhaViolationIndex(index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFF5F5F5), Color(0xFFD0D0D0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFC0C0C0), Color(0xFF909090)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.white : const Color(0xFF606060),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                offset: const Offset(0, 2),
                blurRadius: 3,
              )
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: font(
                  color: const Color(0xFF111111),
                  fontSize: 10,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ),
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
                final isAccusedCard = game.selectedQaydhaTrickIndex ==
                        trickIndex &&
                    game.selectedQaydhaCardSeatIndex == cardPlay.playerIndex;

                Color highlightColor = Colors.transparent;
                if (isAccusedCard) {
                  highlightColor = const Color(
                      0xFFFF858A); // Light Pink tint for accused card
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
                      onTap: (isResultMode ||
                              game.currentQaydhaAction ==
                                  QaydhaActionType.revealCards)
                          ? null
                          : () => game.selectQaydhaCard(
                              trickIndex, cardPlay.playerIndex),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Card shadow for accused card
                          if (isAccusedCard)
                            Container(
                              height: 90,
                              width: 65,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        highlightColor.withValues(alpha: 0.9),
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
                          if (isAccusedCard)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: highlightColor.withValues(
                                      alpha:
                                          0.65), // Stronger tint to match screenshot
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color:
                                          highlightColor.withValues(alpha: 1.0),
                                      width: 2.0),
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
  // PLAYER HANDS SECTION (Proof Card Selection)
  // Shows the opponents' hands at the start of the selected trick.
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPlayersCardsSection(
      BuildContext context,
      GameProvider game,
      TextStyle Function(
              {Color? color, double? fontSize, FontWeight? fontWeight})
          font,
      bool isAr) {
    final trickIndex = game.selectedQaydhaTrickIndex;
    if (trickIndex == null || trickIndex >= game.trickHistoryThisRound.length) {
      return const SizedBox.shrink();
    }
    final trick = game.trickHistoryThisRound[trickIndex];
    final handSnapshots = trick.handsAtStartOfTrick;
    if (handSnapshots == null) {
      return const SizedBox.shrink();
    }

    // Opponent seats are 1 and 3 (relative to player 0)
    final opponentSeats = [1, 3];

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        children: opponentSeats.map((seatIndex) {
          final hand = handSnapshots[seatIndex] ?? [];
          if (hand.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1808),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x40C49028), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Player Name Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C2210),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                    border: Border(bottom: BorderSide(color: Color(0x40C49028), width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        game.playerName(seatIndex),
                        style: font(
                            color: const Color(0xFFF8EDD8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      // Small indicator showing it's an opponent
                      Icon(Icons.person, color: const Color(0xFFC49028), size: 14),
                    ],
                  ),
                ),
                // Cards Grid
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: -25, // Fan overlap
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(hand.length, (cardIndex) {
                      final card = hand[cardIndex];
                      final isSelectedProof =
                          game.selectedQaydhaProofSeatIndex == seatIndex &&
                          game.selectedQaydhaProofCardIndex == cardIndex;

                      return GestureDetector(
                        onTap: () => game.selectQaydhaProofCard(seatIndex, cardIndex),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          transform: Matrix4.translationValues(0, isSelectedProof ? -8 : 0, 0),
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 75,
                                width: 52,
                                child: PlayingCard(
                                  card: card,
                                  faceUp: true,
                                ),
                              ),
                              if (isSelectedProof)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE91E63).withValues(alpha: 0.4), // Pink tint
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                          color: const Color(0xFFE91E63), width: 2), // Pink border
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
        }).toList(),
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
    final action = game.currentQaydhaAction;
    final isFalseEkka = action == QaydhaActionType.wrongTrick;
    final selectedViolation = game.selectedQaydhaViolationIndex;
    
    // Determine if proof card is required
    // 0: qate, 1: rubFiAlDubl, 2: maKabbarBiHakam, 3: maDaqBiHakam, 4: falseEkka
    bool requiresProof = false;
    if (selectedViolation != null && (selectedViolation == 0 || selectedViolation == 2 || selectedViolation == 3)) {
      requiresProof = true;
    }

    // An accused card MUST be selected from a trick
    bool canSubmit = game.selectedQaydhaTrickIndex != null && selectedViolation != null;
    if (requiresProof) {
      canSubmit = canSubmit && game.selectedQaydhaProofCardIndex != null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1808), // Sandstone dark canvas
        border: Border(top: BorderSide(color: Color(0x60C49028))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Left: action button ──
          Builder(builder: (context) {
            final showCloseButton = isResultMode || (action == QaydhaActionType.reviewTricks && !canSubmit);
            if (showCloseButton) {
              return GestureDetector(
                onTap: () {
                  if (!isResultMode) {
                    game.cancelQaydha();
                  } else {
                    game.closeQaydhaResult();
                  }
                },
                child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF8EDD8),
                      Color(0xFFD7C7A8)
                    ], // Warm ivory gradient
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFC49028), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      offset: const Offset(0, 3),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: Text(
                  isAr ? 'إغلاق' : 'Close',
                  style: font(
                      color: const Color(0xFF1E1808),
                      fontSize: 15,
                      fontWeight: FontWeight.w900),
                ),
              ),
            );
            } else {
              // قيدها (Challenge) button in selection mode
              return GestureDetector(
                onTap: canSubmit ? () => game.submitQaydhaChallenge() : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: canSubmit
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFFFD54F),
                              Color(0xFFC49028)
                            ], // Royal Gold gradient
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF392C14), Color(0xFF2C2210)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: canSubmit
                          ? const Color(0xFFFFE082)
                          : const Color(0x40C49028),
                      width: canSubmit ? 1.5 : 1.0,
                    ),
                    boxShadow: canSubmit
                        ? [
                            BoxShadow(
                              color:
                                  const Color(0xFFC49028).withValues(alpha: 0.4),
                              offset: const Offset(0, 3),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    isAr ? 'قيدها' : 'Challenge',
                    style: font(
                      color: canSubmit
                          ? const Color(0xFF1E1808)
                          : const Color(0x80F8EDD8),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            }
          }),

          // ── Right: Challenger name + timer ──
          Container(
            padding:
                const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2210), // Sandstone dark pill
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x60C49028), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAr ? 'المقيد: ' : 'Challenger: ',
                  style: font(
                      color: const Color(0xFFC49028),
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  game.playerName(0),
                  style: font(
                      color: const Color(0xFFF8EDD8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                // Countdown timer circle
                SizedBox(
                  width: 28,
                  height: 28,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(
                        isResultMode), // Reset animation when mode changes
                    tween: Tween(begin: 1.0, end: 0.0),
                    duration: Duration(seconds: isResultMode ? 8 : 60),
                    onEnd: () {
                      if (isResultMode ||
                          action == QaydhaActionType.revealCards) {
                        if (action == QaydhaActionType.revealCards) {
                          game.cancelQaydha();
                        } else {
                          game.closeQaydhaResult();
                        }
                      } else {
                        if (canSubmit) {
                          game.submitQaydhaChallenge();
                        } else {
                          game.cancelQaydha();
                        }
                      }
                    },
                    builder: (context, value, child) {
                      final secondsLeft =
                          (value * (isResultMode ? 8 : 60)).ceil();
                      final timerColor = value > 0.25
                          ? const Color(0xFFC49028) // Gold
                          : const Color(0xFFE53935); // Red when low
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: timerColor, width: 2),
                          color: const Color(0xFF1E1808),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$secondsLeft',
                          style: font(
                              color: timerColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
