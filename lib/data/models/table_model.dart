import 'player_model.dart';

/// Represents a Baloot game table (4 players, 2 teams)
enum GameState { waiting, bidding, playing, scoring, finished }

class TableModel {
  final String id;
  final String name;
  final List<PlayerModel> players;
  final GameState state;
  final int teamAScore;
  final int teamBScore;
  final int currentRound;

  const TableModel({
    required this.id,
    required this.name,
    this.players = const [],
    this.state = GameState.waiting,
    this.teamAScore = 0,
    this.teamBScore = 0,
    this.currentRound = 1,
  });

  bool get isFull => players.length >= 4;

  List<PlayerModel> get teamA =>
      players.length >= 2 ? [players[0], players[2]] : [];

  List<PlayerModel> get teamB =>
      players.length >= 4 ? [players[1], players[3]] : [];

  TableModel copyWith({
    String? id,
    String? name,
    List<PlayerModel>? players,
    GameState? state,
    int? teamAScore,
    int? teamBScore,
    int? currentRound,
  }) {
    return TableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      players: players ?? this.players,
      state: state ?? this.state,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      currentRound: currentRound ?? this.currentRound,
    );
  }
}
