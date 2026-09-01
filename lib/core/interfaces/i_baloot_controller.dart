import '../../data/models/card_model.dart';
import '../../data/models/round_state_model.dart';
import '../../features/game/domain/managers/bidding_manager.dart';
import '../../features/game/domain/models/qaydha_models.dart';

/// Abstract contract for the Baloot Game Engine.
///
/// The UI layer talks to this interface only. The implementation
/// lives in [BalootGameController]. In Phase 3, the same interface
/// will be mirrored on the Node.js server as the authoritative referee.
abstract class IBalootController {
  // ── Game Lifecycle ──

  /// Start a brand new game (resets scores, picks first dealer).
  void startNewGame(List<String> playerNames);

  /// Get the names of players at seats 0..3 (updated after identities assigned).
  List<String> get playerNames;

  /// Start a new round within the current game.
  void startNewRound();

  // ── Bidding Phase ──

  /// Place a bid during the Mzad phase.
  void placeBid(int seatIndex, BidAction action, {Suit? secondHakamSuit});

  // ── Double Phase ──

  /// Call double/triple/four/gahwa (before first card is played).
  /// [isOpenPlay]: true = Open (can lead with trump), false = Closed (cannot).
  void callDouble(int seatIndex, DoubleStatus level, {bool isOpenPlay = true});

  // ── Play Phase ──

  /// Play a card from a player's hand.
  void playCard(int seatIndex, CardModel card);


  // ── Projects & Ekka ──

  /// Declare a project during trick 1.
  void declareProject(int seatIndex, int projectIndex);

  /// Check if a player can claim Ekka (must be their turn to lead).
  bool canEkka(int seatIndex);

  /// Claim Ekka for the current trick.
  void claimEkka(int seatIndex);

  // ── State Queries ──

  /// Apply Qaydha challenge outcome (penalize the accused team)
  void applyQaydhaResult(QaydhaResult result);

  /// Get the current round state (for UI rendering and reconnection).
  RoundStateModel get roundState;

  /// Which seat claimed Ekka in the current trick (if any)
  int? get ekkaClaimSeat;

  /// Get a player's current hand.
  List<CardModel> getHand(int seatIndex);

  /// Get overall game scores.
  ({int teamA, int teamB}) get gameScore;

  /// Check if the game is over.
  bool get isGameOver;

  /// Get the winning team ('A' or 'B'), or null if not over.
  String? get gameWinner;

  /// Get the team ('A' or 'B') that won the project priority this round, or null.
  String? get projectWinningTeam;

  /// Full state snapshot for reconnection.
  Map<String, dynamic> getGameState();
}
