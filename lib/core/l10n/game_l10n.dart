import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/models/card_model.dart' show GameMode;
import '../../data/models/round_state_model.dart' show ProjectType;
import 'locale_provider.dart';

/// In-game UI strings (table, HUD, overlays). Toggle via [LocaleProvider] on home/settings.
class GameL10n {
  GameL10n._(this._ar);

  final bool _ar;

  bool get isArabic => _ar;

  static GameL10n of(BuildContext context) {
    return GameL10n._(context.watch<LocaleProvider>().isArabic);
  }

  static GameL10n read(BuildContext context) {
    return GameL10n._(context.read<LocaleProvider>().isArabic);
  }

  // ── Action bar ──
  /// Round 1 pass — apps often use بس (Kammelna-style).
  String get pass => _ar ? 'بس' : 'Pass';
  /// Round 2 only — Jawaker/Kammelna often use ولا instead of باس.
  String get passRound2 => _ar ? 'ولا' : 'Pass';
  String get hakam => _ar ? 'حكم' : 'Hakam';
  /// Round 2: choose a new trump (not buyer-card suit). Same action as suit-picker Hakam.
  String get secondHakam => _ar ? 'حكم ثاني' : 'Second Hakam';
  String get sun => _ar ? 'صن' : 'Sun';
  String get sawa => _ar ? 'سوى' : 'Sawa';
  String get ashkal => _ar ? 'أشكال' : 'Ashkal';
  String get confirmHakam => _ar ? 'تأكيد الحكم' : 'Confirm Hakam';
  String get switchToSun => _ar ? 'تحويل لصن' : 'Switch to Sun';
  String get projects => _ar ? 'مشاريع' : 'Projects';
  String get cancel => _ar ? 'إلغاء' : 'Cancel';
  String get closed => _ar ? 'سِرّ' : 'Closed';
  String get open => _ar ? 'علني' : 'Open';
  String get doubleWord => _ar ? 'دبل' : 'Double';
  String get triple => _ar ? 'تربل' : 'Triple';
  String get four => _ar ? 'أربعة' : 'Four';
  String get gahwa => _ar ? 'قهوة' : 'Gahwa';
  String get startGame => _ar ? 'ابدأ اللعب' : 'Start Game';

  // ── Top HUD menu ──
  String get them => _ar ? 'لهم' : 'Them';
  String get us => _ar ? 'لنا' : 'Us';
  String get leave => _ar ? 'مغادرة' : 'Leave';
  String get wallpaper => _ar ? 'الخلفية' : 'Wallpaper';
  String get testMode => _ar ? 'وضع تجريبي' : 'Test Mode';
  String get testProjectUi => _ar ? 'اختبار المشاريع' : 'Test Project UI';
  String get sound => _ar ? 'صوت' : 'Sound';
  String get emotes => _ar ? 'إيموشن' : 'Emotes';

  // ── Majlis player bar ──
  String get dealer => _ar ? 'موزع' : 'Dealer';
  String get buyer => _ar ? 'مشتري' : 'Buyer';

  String modeLabel(String engineLabel) {
    if (!_ar) return engineLabel;
    return switch (engineLabel) {
      'Sun' => 'صن',
      'Hakam' => 'حكم',
      '—' => '—',
      _ => engineLabel,
    };
  }

  // ── Deal overlay ──
  String get dealing => _ar ? 'جاري التوزيع...' : 'Dealing...';
  String get dealingShort => _ar ? 'توزيع' : 'Dealing';
  String get confirmShort => _ar ? 'حكم؟' : 'Hakam?';
  String get bidRound1Short => _ar ? 'مزاد ١' : 'Bid · R1';
  String get bidRound2Short => _ar ? 'مزاد ٢' : 'Bid · R2';
  String get doubleShort => _ar ? 'دبل' : 'Double';
  String get gameOverShort => _ar ? 'انتهت اللعبة' : 'Game over';
  String get bidding => _ar ? 'المزاد' : 'Bidding';
  String buyerLine(String name) => _ar ? 'المشتري: $name' : 'Buyer: $name';
  String get bidRound1 => _ar ? 'المزاد — الجولة ١' : 'Bid Round 1';
  String get bidRound2 => _ar ? 'المزاد — الجولة ٢' : 'Bid Round 2';
  String get confirmOrSwitch => _ar ? 'تأكيد الحكم أو صن؟' : 'Confirm or Switch?';
  String get doubleWindow => _ar ? 'نافذة الدبل' : 'Double Window';

  // ── Game over ──
  String get gahwaTitle => _ar ? 'قهوة' : 'Gahwa';
  String get youWin => _ar ? 'فزت!' : 'You win!';
  String get youLose => _ar ? 'خسرت' : 'You lose';
  String teamReached152(bool teamIsUs) {
    if (_ar) {
      return teamIsUs ? 'فريقنا وصل ١٥٢' : 'فريقهم وصل ١٥٢';
    }
    return teamIsUs ? 'Team Us reached 152' : 'Team Them reached 152';
  }

  String get finalScore => _ar ? 'النتيجة النهائية' : 'Final score';
  String lastRoundPts(int a, int b) =>
      _ar ? 'آخر جولة +$a / +$b' : 'Last round +$a / +$b';
  String get exitGame => _ar ? 'خروج' : 'Exit game';
  String get playAgain => _ar ? 'العب مرة أخرى' : 'Play again';

  // ── Projects (picker) ──
  String projectType(ProjectType t) {
    if (!_ar) {
      return switch (t) {
        ProjectType.sera => 'Sera',
        ProjectType.fifty => '50',
        ProjectType.hundred => '100',
        ProjectType.fourHundred => '400',
        ProjectType.baloot => 'Baloot',
      };
    }
    return switch (t) {
      ProjectType.sera => 'صيرة',
      ProjectType.fifty => '٥٠',
      ProjectType.hundred => '١٠٠',
      ProjectType.fourHundred => '٤٠٠',
      ProjectType.baloot => 'بلوت',
    };
  }

  // ── Scoreboard header line (mode + trump) ──
  String scoreboardGameLine(GameMode mode, String? trumpSymbol) {
    if (mode == GameMode.sun) return _ar ? 'صن' : 'Sun';
    final sym = trumpSymbol ?? '';
    return _ar ? 'حكم $sym'.trim() : 'Hakam $sym'.trim();
  }

  /// Localize speech-bubble text produced by [GameProvider] (English tokens).
  String localizeBubble(String en) {
    if (!_ar) return en;
    if (en.startsWith('Hakam ') && en.length > 6) {
      return 'حكم ${en.substring(6)}';
    }
    return switch (en) {
      'Pass' => 'بس',
      'Hakam' => 'حكم',
      'Sun' => 'صن',
      'Sawa' => 'سوى',
      'Ashkal' => 'أشكال',
      'Double' => 'دبل',
      'Triple' => 'تربل',
      'Four' => 'أربعة',
      'Gahwa' => 'قهوة',
      _ => en,
    };
  }
}
