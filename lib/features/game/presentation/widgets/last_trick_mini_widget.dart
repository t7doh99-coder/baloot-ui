import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/card_model.dart';
import '../game_provider.dart';
import 'playing_card.dart' show CardSize, PlayingCard, cardBackForSeat;

/// Top-right mini panel: last completed trick in a + layout on the table
/// background (no dark container). Generous insets so the four glyphs are not
/// cramped.
///
/// • Before any trick in the session: four **red** card backs (first-round look).
/// • After each trick: the four real cards by seat (2=top, 1=right, 0=bottom, 3=left).
///
/// Face-up cards use a **minimal rank + suit glyph** (high contrast, readable at
/// small size) instead of full Figma artwork.
class LastTrickMiniWidget extends StatelessWidget {
  const LastTrickMiniWidget({super.key});

  /// Cross layout size (no outer “behind” box — cards sit on table background).
  /// Sized to fit [_cardH] × 2 + insets + gap without Stack overflow.
  static const _crossSize = 128.0;
  static const _cardW = 30.0;
  /// Room for padding + rank/suit + font ascent/descent (avoids 1–2px RenderFlex overflow).
  static const _cardH = 48.0;
  /// Inset from edges — more space between the four mini cards.
  static const _armInset = 12.0;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final cards = game.lastTrickMiniBySeat;

    Widget cardForSeat(int seat) {
      final snap = cards;
      if (snap == null) {
        return SizedBox(
          width: _cardW,
          height: _cardH,
          child: FittedBox(
            fit: BoxFit.contain,
            child: PlayingCard(
              faceUp: false,
              back: cardBackForSeat(seat),
              size: CardSize.small,
            ),
          ),
        );
      }
      return SizedBox(
        width: _cardW,
        height: _cardH,
        child: _MiniGlyphCard(card: snap[seat]),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
      child: SizedBox(
        width: _crossSize,
        height: _crossSize,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Top — seat 2 (partner)
            Positioned(
              top: _armInset,
              left: 0,
              right: 0,
              child: Center(child: cardForSeat(2)),
            ),
            // Bottom — seat 0 (you)
            Positioned(
              bottom: _armInset,
              left: 0,
              right: 0,
              child: Center(child: cardForSeat(0)),
            ),
            // Left — seat 3
            Positioned(
              left: _armInset,
              top: 0,
              bottom: 0,
              child: Center(child: cardForSeat(3)),
            ),
            // Right — seat 1
            Positioned(
              right: _armInset,
              top: 0,
              bottom: 0,
              child: Center(child: cardForSeat(1)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── High-contrast rank + suit only (no Figma assets) ─────────────────

class _MiniGlyphCard extends StatelessWidget {
  const _MiniGlyphCard({required this.card});

  final CardModel card;

  static String _rankLabel(Rank r) {
    switch (r) {
      case Rank.seven:
        return '7';
      case Rank.eight:
        return '8';
      case Rank.nine:
        return '9';
      case Rank.ten:
        return '10';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'K';
      case Rank.ace:
        return 'A';
    }
  }

  static String _suitSymbol(Suit s) {
    switch (s) {
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.spades:
        return '♠';
      case Suit.clubs:
        return '♣';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rank = _rankLabel(card.rank);
    final suit = _suitSymbol(card.suit);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1A1A1A).withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rank,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              style: const TextStyle(
                color: Color(0xFF0D0D0D),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              suit,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              style: const TextStyle(
                color: Color(0xFF0D0D0D),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
