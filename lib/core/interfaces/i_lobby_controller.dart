/// Abstract contract for the Lobby / Home Hub actions.
/// Phase 2 developer: implement this to connect hub buttons to backend.
///
/// Usage in UI:
/// ```dart
/// final controller = context.read<ILobbyController>();
/// onTap: () => controller.onPlayNow()
/// ```
abstract class ILobbyController {
  /// Called when user taps the "Play Now" medallion.
  /// LOGIC_PLUG_IN: Start matchmaking / open game table.
  void onPlayNow();

  /// Called when user taps "Create Session".
  /// LOGIC_PLUG_IN: Navigate to session creation flow.
  void onCreateSession();

  /// Called when user taps "Join Sessions".
  /// LOGIC_PLUG_IN: Navigate to session browser / list.
  void onJoinSessions();

  /// Called when user taps "VIP Access".
  /// LOGIC_PLUG_IN: Navigate to VIP subscription / paywall.
  void onVipAccess();
}
