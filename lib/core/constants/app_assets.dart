import '../../data/models/card_model.dart';

/// Asset path strings — single source of truth
class AppAssets {
  AppAssets._();

  // Images
  static const String logoImage = 'assets/images/logo.png';
  static const String majlisTableReference = 'assets/images/majlis_table_reference.png';
  static const String majlisTableMap = 'assets/images/majlis_table_map.svg';
  static const String majlisTableMap2 = 'assets/images/map2.svg';

  /// Portrait per seat index 0–3 (same mapping as [PlayerAvatarRing]).
  static const List<String> playerSeatAvatars = [
    'assets/images/avatars/Screenshot 2026-04-16 194030.png',
    'assets/images/avatars/Screenshot 2026-04-16 194232.png',
    'assets/images/avatars/Screenshot 2026-04-16 194821.png',
    'assets/images/avatars/bc9fd4bd-de9b-4555-976c-8360576c6708.jpg',
  ];

  static String playerAvatarPath(int seatIndex) =>
      playerSeatAvatars[seatIndex % playerSeatAvatars.length];

  // SVG Icons (cards)
  static const String suitHeartsIcon = 'assets/icons/suit_hearts.svg';
  static const String suitDiamondsIcon = 'assets/icons/suit_diamonds.svg';
  static const String suitSpadesIcon = 'assets/icons/suit_spades.svg';
  static const String suitClubsIcon = 'assets/icons/suit_clubs.svg';

  // Lottie animations
  static const String splashLottie = 'assets/lottie/splash_glow.json';
  static const String cardFlipLottie = 'assets/lottie/card_flip.json';

  // Card images — filenames match Figma export format "Suit=X, Number=Y.png"
  static const String cardBackRed  = 'assets/images/cards/Suit=Other, Number=Back Red.png';
  static const String cardBackBlue = 'assets/images/cards/Suit=Other, Number=Back Blue.png';

  static const _suitNames = {
    Suit.hearts:   'Hearts',
    Suit.diamonds: 'Diamonds',
    Suit.spades:   'Spades',
    Suit.clubs:    'Clubs',
  };

  static const _rankNames = {
    Rank.seven:  '7',
    Rank.eight:  '8',
    Rank.nine:   '9',
    Rank.ten:    '10',
    Rank.jack:   'Jack',
    Rank.queen:  'Queen',
    Rank.king:   'King',
    Rank.ace:    'Ace',
  };

  /// Returns the asset path for a given [CardModel].
  /// e.g. CardModel(Suit.hearts, Rank.ace) → "assets/images/cards/Suit=Hearts, Number=Ace.png"
  static String cardImage(CardModel card) {
    final suit = _suitNames[card.suit]!;
    final rank = _rankNames[card.rank]!;
    return 'assets/images/cards/Suit=$suit, Number=$rank.png';
  }
}
