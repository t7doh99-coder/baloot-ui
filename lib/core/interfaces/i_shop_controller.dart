/// Abstract contract for the Shop & Economy system.
/// Backend developer: implement this to connect purchases to your payment system.
abstract class IShopController {
  /// Called when user taps "Buy" on a coin pack
  Future<bool> onPurchaseCoins({
    required String packId,
    required int amount,
    required String price,
  });

  /// Called when user taps "Subscribe" on a VIP plan
  Future<bool> onSubscribeVIP({
    required String planId,
    required String duration,
  });

  /// Get user's current coin balance
  int getCoinBalance();

  /// Check if user has active VIP subscription
  bool isVIPActive();

  /// Refresh coin balance from server
  Future<int> refreshBalance();
}
