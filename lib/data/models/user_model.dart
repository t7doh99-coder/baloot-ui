import 'package:flutter/foundation.dart';

/// User profile data model — fed from backend/auth
/// No hardcoded values in UI; everything flows from this model.
class UserModel {
  final String id;
  final String username;
  final String? avatarUrl;
  final int coins;
  final int gems;
  final String level; // e.g. 'Expert', 'Beginner'
  final bool isVip;
  final int activeGames;

  const UserModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.coins = 0,
    this.gems = 0,
    this.level = 'Beginner',
    this.isVip = false,
    this.activeGames = 0,
  });

  /// Formatted coin string for display
  String get coinsFormatted {
    if (coins >= 1000000) {
      return '${(coins / 1000000).toStringAsFixed(1)}M';
    } else if (coins >= 1000) {
      return '${(coins / 1000).toStringAsFixed(0)},${(coins % 1000).toString().padLeft(3, '0')}';
    }
    return coins.toString();
  }

  String get gemsFormatted => gems.toString();

  UserModel copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    int? coins,
    int? gems,
    String? level,
    bool? isVip,
    int? activeGames,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      level: level ?? this.level,
      isVip: isVip ?? this.isVip,
      activeGames: activeGames ?? this.activeGames,
    );
  }

  @override
  String toString() => 'User($username, coins: $coins, vip: $isVip)';
}
