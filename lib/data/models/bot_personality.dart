import 'dart:math';
import 'bot_difficulty.dart';

// ══════════════════════════════════════════════════════════════════
//  BOT PERSONALITY & IDENTITY
//
//  Each game session assigns a random personality to Medium/Hard
//  bots that subtly alters their bidding thresholds and play style.
//  Easy bots have no personality — they play uniformly.
//
//  BotIdentity bundles name, rank badge, and personality for one
//  game session. A new identity is rolled every time startGame() is
//  called.
// ══════════════════════════════════════════════════════════════════

/// Medium bot personalities (3 archetypes).
enum MediumPersonality { cautious, balanced, bold }

/// Hard bot personalities (5 archetypes).
enum HardPersonality { crusher, calculator, patient, deceiver, adaptive }

/// Unified personality wrapper — one per bot per game session.
class BotPersonality {
  final MediumPersonality? medium;   // non-null for Medium bots
  final HardPersonality? hard;       // non-null for Hard bots

  const BotPersonality.none() : medium = null, hard = null;
  const BotPersonality.forMedium(MediumPersonality p) : medium = p, hard = null;
  const BotPersonality.forHard(HardPersonality p) : medium = null, hard = p;

  bool get isNone => medium == null && hard == null;

  @override
  String toString() {
    if (medium != null) return 'Medium:${medium!.name}';
    if (hard != null) return 'Hard:${hard!.name}';
    return 'None';
  }
}

/// Complete bot identity for one game session.
class BotIdentity {
  final String name;
  final String rankBadge;
  final BotPersonality personality;

  /// Hard-bot "human moment" — exactly ONE intentional mistake per game.
  bool humanMomentUsed = false;

  BotIdentity({
    required this.name,
    required this.rankBadge,
    required this.personality,
  });

  /// Roll a random identity for [difficulty] at seat [seatIndex].
  factory BotIdentity.random(BotDifficulty difficulty, int seatIndex, Random rng) {
    // ── Name pool (Gulf Arabic names) ──
    const maleNames = ['خالد', 'سعد', 'فيصل', 'عبدالله', 'ماجد', 'تركي', 'يوسف', 'راشد'];
    const femaleNames = ['نورة', 'سارة', 'ريم', 'منى', 'ليلى', 'هيا', 'دانة', 'رنا'];
    final allNames = [...maleNames, ...femaleNames];
    final name = allNames[rng.nextInt(allNames.length)];

    // ── Rank badge ──
    final String badge;
    final BotPersonality personality;

    switch (difficulty) {
      case BotDifficulty.easy:
        badge = ['Beginner', 'Amateur'][rng.nextInt(2)];
        personality = const BotPersonality.none();
      case BotDifficulty.medium:
        badge = ['Good', 'Advanced'][rng.nextInt(2)];
        final mp = MediumPersonality.values[rng.nextInt(MediumPersonality.values.length)];
        personality = BotPersonality.forMedium(mp);
      case BotDifficulty.hard:
        badge = ['Expert', 'Professional'][rng.nextInt(2)];
        final hp = HardPersonality.values[rng.nextInt(HardPersonality.values.length)];
        personality = BotPersonality.forHard(hp);
    }

    return BotIdentity(name: name, rankBadge: badge, personality: personality);
  }
}
