import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/card_model.dart';
import '../domain/baloot_game_controller.dart' show GamePhase;
import 'game_provider.dart';
import 'game_table_screen.dart';
import 'widgets/playing_card.dart';

/// Debug screen: verifies all 32 Baloot card images (Step 1)
/// and live game engine state (Step 2).
class CardDebugScreen extends StatefulWidget {
  const CardDebugScreen({super.key});

  @override
  State<CardDebugScreen> createState() => _CardDebugScreenState();
}

class _CardDebugScreenState extends State<CardDebugScreen> {
  CardModel? _selectedCard;
  CardSize _currentSize = CardSize.medium;

  static final _allCards = [
    for (final suit in Suit.values)
      for (final rank in Rank.values) CardModel(suit: suit, rank: rank),
  ];

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF8B7355),
      appBar: AppBar(
        title: Text(
          'Card Debug — ${_allCards.length} Cards',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF3E2723),
        foregroundColor: const Color(0xFFFFF8E7),
        actions: [
          TextButton.icon(
            onPressed: game.phase == GamePhase.notStarted
                ? () => context.read<GameProvider>().startGame()
                : null,
            icon: const Icon(Icons.play_arrow, color: Color(0xFFD4AF37)),
            label: Text(
              'Start Engine',
              style: GoogleFonts.montserrat(
                color: const Color(0xFFD4AF37),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GameTableScreen()),
            ),
            icon: const Icon(Icons.table_restaurant, color: Color(0xFF80DEEA)),
            label: Text(
              'Step 3 →',
              style: GoogleFonts.montserrat(
                color: const Color(0xFF80DEEA),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Step 2: live game state panel
          _GameStatePanel(game: game),

          // Size selector chips
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: CardSize.values.map((s) {
                final active = s == _currentSize;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(
                      s.name.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? const Color(0xFF3E2723)
                            : const Color(0xFFFFF8E7),
                      ),
                    ),
                    selected: active,
                    selectedColor: const Color(0xFFD4AF37),
                    backgroundColor: const Color(0xFF5D4E37),
                    onSelected: (_) => setState(() => _currentSize = s),
                  ),
                );
              }).toList(),
            ),
          ),

          // Card grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // All 32 cards grouped by suit
                  for (final suit in Suit.values) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 12),
                      child: Text(
                        _suitTitle(suit),
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFFF8E7),
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Rank.values.map((rank) {
                        final card = CardModel(suit: suit, rank: rank);
                        final isSelected = _selectedCard == card;
                        return PlayingCard(
                          card: card,
                          size: _currentSize,
                          selected: isSelected,
                          onTap: () => setState(() {
                            _selectedCard = isSelected ? null : card;
                          }),
                        );
                      }).toList(),
                    ),
                  ],

                  // Card backs
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 24),
                    child: Text(
                      'Card Backs',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFF8E7),
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _backSample(CardBack.red, 'Enemy (Red)'),
                      _backSample(CardBack.blue, 'Team (Blue)'),
                    ],
                  ),

                  // Dimmed cards
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 24),
                    child: Text(
                      'Dimmed (Invalid) Cards',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFF8E7),
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PlayingCard(
                        card: const CardModel(suit: Suit.spades, rank: Rank.ace),
                        size: _currentSize,
                        dimmed: true,
                      ),
                      PlayingCard(
                        card: const CardModel(suit: Suit.hearts, rank: Rank.king),
                        size: _currentSize,
                        dimmed: true,
                      ),
                      PlayingCard(
                        faceUp: false,
                        back: CardBack.red,
                        size: _currentSize,
                        dimmed: true,
                      ),
                    ],
                  ),

                  // Live hand preview (Step 2)
                  if (game.phase != GamePhase.notStarted) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 24),
                      child: Text(
                        'Your Hand (Seat 0) — ${game.playerHand.length} cards',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: game.playerHand.map((card) {
                        return PlayingCard(
                          card: card,
                          size: CardSize.medium,
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backSample(CardBack back, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: CardSize.values.map((s) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PlayingCard(faceUp: false, back: back, size: s),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: const Color(0xFFFFF8E7).withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  String _suitTitle(Suit suit) {
    switch (suit) {
      case Suit.hearts:   return '♥ Hearts';
      case Suit.diamonds: return '♦ Diamonds';
      case Suit.spades:   return '♠ Spades';
      case Suit.clubs:    return '♣ Clubs';
    }
  }
}

// ── Step 2 checkpoint: Live game state chips ──────────────────────
class _GameStatePanel extends StatelessWidget {
  final GameProvider game;
  const _GameStatePanel({required this.game});

  @override
  Widget build(BuildContext context) {
    if (game.phase == GamePhase.notStarted) {
      return Container(
        color: const Color(0xFF2C1F0E),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFD4AF37), size: 16),
            const SizedBox(width: 8),
            Text(
              'Tap "Start Engine" to test Step 2 — Game Provider',
              style: GoogleFonts.montserrat(
                color: const Color(0xFFD4AF37),
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    final rs = game.roundState;
    final score = game.gameScore;

    return Container(
      color: const Color(0xFF2C1F0E),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _chip('Phase', game.phase.name, const Color(0xFF1565C0)),
              _chip('Mode', game.gameModeLabel, const Color(0xFF2E7D32)),
              _chip('Turn', 'Seat ${rs.currentPlayerIndex}', const Color(0xFF6A1B9A)),
              if (game.phase == GamePhase.playing)
                _chip('Trick', '${game.trickNumber}/8', const Color(0xFFBF360C)),
              _chip('لنا', '${score.teamA}', const Color(0xFFC62828)),
              _chip('لهم', '${score.teamB}', const Color(0xFF1B5E20)),
              _chip('Hand', '${game.playerHand.length}', const Color(0xFF4E342E)),
              if (game.isHumanTurn)
                _chip('⏱', '${game.timerSeconds}s', const Color(0xFFE65100)),
            ],
          ),
          if (game.isGameOver)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Game Over! Winner: Team ${game.gameWinner ?? "?"}  —  Tap Restart',
                style: GoogleFonts.cairo(
                  color: const Color(0xFFD4AF37),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
