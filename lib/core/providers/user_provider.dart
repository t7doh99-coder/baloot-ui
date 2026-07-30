import 'package:flutter/material.dart';
import '../constants/app_assets.dart';
import '../../../data/models/user_model.dart';

/// Provides the current user profile data to the widget tree.
/// LOGIC_PLUG_IN: Replace mock data with real auth/backend user data.
///
/// Usage:
/// ```dart
/// // In main.dart:
/// ChangeNotifierProvider(create: (_) => UserProvider())
///
/// // In widgets:
/// final user = context.watch<UserProvider>().user;
/// ```
class UserProvider extends ChangeNotifier {
  // ── MOCK DATA — Replace with real backend fetch ──
  UserModel _user = UserModel(
    id: 'mock-001',
    username: 'Stanley',
    avatarUrl: AppAssets.playerAvatarPath(0),
    coins: 1139194,
    gems: 662,
    level: 'Expert',
    isVip: true,
    activeGames: 1,
  );

  UserModel get user => _user;

  /// Update user profile. Called after backend fetch.
  void updateUser(UserModel newUser) {
    _user = newUser;
    notifyListeners();
  }

  /// Update coin balance only.
  void updateCoins(int coins) {
    _user = _user.copyWith(coins: coins);
    notifyListeners();
  }

  /// Update gem balance only.
  void updateGems(int gems) {
    _user = _user.copyWith(gems: gems);
    notifyListeners();
  }
}
