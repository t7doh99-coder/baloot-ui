/// Thrown when a player attempts an illegal card play (Qaid violation).
///
/// Violation types per BALOOT_RULES.md Section 9:
/// - suitViolation: not following leading suit while holding one
/// - cutViolation: not playing trump when void in leading suit (Hakam)
/// - upTrumpViolation: not playing a higher trump when required (Hakam)
/// - closedPlayViolation: leading with trump while holding other suits (Double active)
class PlayViolationException implements Exception {
  final ViolationType type;
  final int playerIndex;
  final String message;

  const PlayViolationException({
    required this.type,
    required this.playerIndex,
    required this.message,
  });

  @override
  String toString() => 'PlayViolation(seat $playerIndex, $type): $message';
}

enum ViolationType {
  suitViolation,
  cutViolation,
  upTrumpViolation,
  closedPlayViolation,
}

/// Thrown when a player makes an invalid bid.
class InvalidBidException implements Exception {
  final int playerIndex;
  final String message;

  const InvalidBidException({
    required this.playerIndex,
    required this.message,
  });

  @override
  String toString() => 'InvalidBid(seat $playerIndex): $message';
}

/// General invalid move (wrong turn, game not in correct phase, etc).
class InvalidMoveException implements Exception {
  final String message;

  const InvalidMoveException(this.message);

  @override
  String toString() => 'InvalidMove: $message';
}
