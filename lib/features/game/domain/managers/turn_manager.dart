import '../../../../data/models/card_model.dart';
import '../../../../data/models/card_play_model.dart';

/// Result of evaluating a completed 4-card trick.
class TrickResult {
  final int winnerIndex; // Seat 0-3
  final List<CardPlayModel> cards;
  final int abnat; // Points from this trick's cards
  final bool isLastTrick;
  final int lastTrickBonus; // +10 if last trick

  const TrickResult({
    required this.winnerIndex,
    required this.cards,
    required this.abnat,
    required this.isLastTrick,
    required this.lastTrickBonus,
  });

  int get totalAbnat => abnat + lastTrickBonus;
}

/// Manages trick flow: collecting 4 cards, evaluating winner,
/// advancing turns, tracking team trick wins.
///
/// Per BALOOT_RULES.md Section 5.3:
/// - Sun: highest card of leading suit wins
/// - Hakam: highest trump wins if any played, else highest of leading suit
/// - Last trick (8): +10 Abnat bonus
class TurnManager {
  final GameMode mode;
  final Suit? trumpSuit;

  int _trickNumber = 1;
  int _currentPlayerIndex;
  final List<CardPlayModel> _currentTrick = [];

  // Track tricks won and Abnat per team
  final List<int> teamATricksWon = [];
  final List<int> teamBTricksWon = [];
  int teamAAbnat = 0;
  int teamBAbnat = 0;

  // History of all tricks
  final List<TrickResult> trickHistory = [];

  TurnManager({
    required this.mode,
    this.trumpSuit,
    required int firstPlayerIndex,
  }) : _currentPlayerIndex = firstPlayerIndex;

  int get trickNumber => _trickNumber;
  int get currentPlayerIndex => _currentPlayerIndex;
  List<CardPlayModel> get currentTrick => List.unmodifiable(_currentTrick);
  bool get isRoundComplete => _trickNumber > 8;

  /// Whether one team won all 8 tricks.
  bool get isKabout =>
      isRoundComplete && (teamATricksWon.length == 8 || teamBTricksWon.length == 8);

  /// Which team achieved Kabout (null if none).
  String? get kaboutTeam {
    if (!isKabout) return null;
    return teamATricksWon.length == 8 ? 'A' : 'B';
  }

  /// Play a card into the current trick.
  /// Returns a [TrickResult] when the trick is complete (4 cards), null otherwise.
  TrickResult? playCard(int seatIndex, CardModel card) {
    _currentTrick.add(CardPlayModel(card: card, playerIndex: seatIndex));

    if (_currentTrick.length < 4) {
      // Advance to next player (clockwise on screen = CCW at table = to the right)
      _currentPlayerIndex = (_currentPlayerIndex + 1) % 4;
      return null;
    }

    // Trick complete — evaluate winner
    final result = _evaluateTrick();
    _applyTrickResult(result);

    // Advance to next trick
    _trickNumber++;
    _currentTrick.clear();
    _currentPlayerIndex = result.winnerIndex;

    return result;
  }

  /// Evaluate which of the 4 played cards wins the trick.
  TrickResult _evaluateTrick() {
    final leadingSuit = _currentTrick.first.card.suit;
    final isLastTrick = _trickNumber == 8;

    CardPlayModel winner = _currentTrick.first;

    if (mode == GameMode.hakam && trumpSuit != null) {
      // Hakam: check if any trump was played
      final trumpPlays = _currentTrick.where((p) => p.card.suit == trumpSuit);

      if (trumpPlays.isNotEmpty) {
        // Highest trump wins
        winner = trumpPlays.reduce((a, b) {
          final aStr = a.card.getStrength(mode: GameMode.hakam, trumpSuit: trumpSuit);
          final bStr = b.card.getStrength(mode: GameMode.hakam, trumpSuit: trumpSuit);
          return aStr >= bStr ? a : b;
        });
      } else {
        // No trump — highest of leading suit wins
        winner = _highestOfSuit(leadingSuit);
      }
    } else {
      // Sun: highest of leading suit wins
      winner = _highestOfSuit(leadingSuit);
    }

    // Calculate Abnat from all 4 cards
    int abnat = 0;
    for (final play in _currentTrick) {
      abnat += play.card.getPointValue(mode: mode, trumpSuit: trumpSuit);
    }

    return TrickResult(
      winnerIndex: winner.playerIndex,
      cards: List.from(_currentTrick),
      abnat: abnat,
      isLastTrick: isLastTrick,
      lastTrickBonus: isLastTrick ? 10 : 0,
    );
  }

  /// Find the highest card of a specific suit in the current trick.
  CardPlayModel _highestOfSuit(Suit suit) {
    final suitPlays = _currentTrick.where((p) => p.card.suit == suit);
    return suitPlays.reduce((a, b) {
      final aStr = a.card.getStrength(mode: mode, trumpSuit: trumpSuit);
      final bStr = b.card.getStrength(mode: mode, trumpSuit: trumpSuit);
      return aStr >= bStr ? a : b;
    });
  }

  /// Record the trick result to the appropriate team.
  void _applyTrickResult(TrickResult result) {
    trickHistory.add(result);
    final isTeamA = result.winnerIndex % 2 == 0; // seats 0,2 = Team A

    if (isTeamA) {
      teamATricksWon.add(_trickNumber);
      teamAAbnat += result.totalAbnat;
    } else {
      teamBTricksWon.add(_trickNumber);
      teamBAbnat += result.totalAbnat;
    }
  }
}
