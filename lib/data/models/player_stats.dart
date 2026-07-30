class PlayerStats {
  int blueStars;
  int medals;
  int currentWinStreak;
  int totalGamesPlayed;
  int totalWins;
  String playerName;
  String? customAvatarPath;

  PlayerStats({
    this.blueStars = 0,
    this.medals = 0,
    this.currentWinStreak = 0,
    this.totalGamesPlayed = 0,
    this.totalWins = 0,
    this.playerName = 'Player',
    this.customAvatarPath,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      blueStars: json['blueStars'] as int? ?? 0,
      medals: json['medals'] as int? ?? 0,
      currentWinStreak: json['currentWinStreak'] as int? ?? 0,
      totalGamesPlayed: json['totalGamesPlayed'] as int? ?? 0,
      totalWins: json['totalWins'] as int? ?? 0,
      playerName: json['playerName'] as String? ?? 'Player',
      customAvatarPath: json['customAvatarPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blueStars': blueStars,
      'medals': medals,
      'currentWinStreak': currentWinStreak,
      'totalGamesPlayed': totalGamesPlayed,
      'totalWins': totalWins,
      'playerName': playerName,
      'customAvatarPath': customAvatarPath,
    };
  }

  PlayerStats copyWith({
    int? blueStars,
    int? medals,
    int? currentWinStreak,
    int? totalGamesPlayed,
    int? totalWins,
    String? playerName,
    String? customAvatarPath,
  }) {
    return PlayerStats(
      blueStars: blueStars ?? this.blueStars,
      medals: medals ?? this.medals,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalWins: totalWins ?? this.totalWins,
      playerName: playerName ?? this.playerName,
      customAvatarPath: customAvatarPath ?? this.customAvatarPath,
    );
  }
}

