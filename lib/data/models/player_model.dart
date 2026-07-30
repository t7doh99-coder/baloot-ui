import 'card_model.dart';

/// Represents a player at the Baloot table
class PlayerModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final int score;
  final List<CardModel> hand;
  final bool isCurrentTurn;

  const PlayerModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.score = 0,
    this.hand = const [],
    this.isCurrentTurn = false,
  });

  PlayerModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    int? score,
    List<CardModel>? hand,
    bool? isCurrentTurn,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      score: score ?? this.score,
      hand: hand ?? this.hand,
      isCurrentTurn: isCurrentTurn ?? this.isCurrentTurn,
    );
  }

  @override
  String toString() => 'Player($name, score: $score, cards: ${hand.length})';
}
