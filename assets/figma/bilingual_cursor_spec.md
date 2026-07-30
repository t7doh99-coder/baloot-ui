# Bilingual Arabic/English Implementation — Cursor Spec
# Copy and paste this entire file into Cursor as your instructions

---

## WHAT TO BUILD

Implement a complete bilingual text system for the Baloot game app.
The app must support TWO languages: Arabic (ar) and English (en).
Arabic is the default language. English is optional/switchable.

---

## PART 1 — SETUP: ADD FLUTTER LOCALIZATION

### Step 1 — pubspec.yaml dependencies

Add these to pubspec.yaml:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

flutter:
  generate: true
```

### Step 2 — Create l10n.yaml at the root of the project

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

### Step 3 — MaterialApp setup in main.dart

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: _currentLocale, // controlled by LanguageProvider
  home: HomeScreen(),
)
```

---

## PART 2 — LANGUAGE FILES

Create folder: `lib/l10n/`

Create TWO files inside it:

---

### FILE 1: lib/l10n/app_en.arb (English)

```json
{
  "@@locale": "en",

  "appName": "Baloot",

  "navHome": "Home",
  "navStore": "Store",
  "navCommunity": "Community",
  "navTournaments": "Tournaments",
  "navChat": "Chat",

  "playButton": "Play",
  "playBaloot": "Play Baloot",
  "gameModesButton": "Game Modes",
  "voiceSession": "Voice Session",
  "createSession": "Create Session",
  "friendlyGame": "Friendly Game",
  "sessionsList": "Sessions List",

  "playerProfile": "Player Profile",
  "editProfile": "Edit Profile",
  "back": "Back",
  "edit": "Edit",

  "medals": "Medals",
  "hearts": "Hearts",
  "blueStars": "Stars",
  "goldStars": "Gold Stars",
  "level": "Level",
  "xpProgress": "{current} / {target} XP",
  "@xpProgress": {
    "placeholders": {
      "current": { "type": "int" },
      "target": { "type": "int" }
    }
  },

  "rankBeginner": "Beginner",
  "rankAmateur": "Amateur",
  "rankGood": "Good",
  "rankAdvanced": "Advanced",
  "rankExpert": "Expert",
  "rankProfessional": "Professional",
  "rankMaster": "Master",
  "rankLegend": "Legend",

  "subscriptionFree": "Free Tier",
  "subscriptionVip": "VIP Member",
  "getVipNow": "Get VIP Now",
  "winButton": "Win",

  "tabBio": "Bio",
  "tabChallenges": "Challenges",
  "tabRanking": "Ranking",
  "tabPrizes": "Prizes",

  "bioPlaceholder": "Tap here to add a general bio",
  "playerImpressions": "Player Impressions",
  "noImpressions": "No impressions from players yet",
  "supporters": "Supporters",
  "joinDate": "Joined on {date}",
  "@joinDate": {
    "placeholders": {
      "date": { "type": "String" }
    }
  },

  "noChallenges": "No challenges available",

  "globalRank": "Rank: {rank}",
  "@globalRank": {
    "placeholders": {
      "rank": { "type": "int" }
    }
  },
  "subTabPerformance": "Performance",
  "subTabRanking": "Ranking",
  "subTabWeekly": "Weekly",
  "subTabMonthly": "Monthly",
  "subTabYearly": "Yearly",
  "points": "Points",

  "subTabTitles": "Titles",
  "subTabAchievements": "Achievements",
  "subTabPrizes": "Prizes",
  "noPrizes": "You don't have any prizes yet",
  "noTitles": "You don't have any titles yet",
  "achievementCount": "{count} / {total} unlocked",
  "@achievementCount": {
    "placeholders": {
      "count": { "type": "int" },
      "total": { "type": "int" }
    }
  },

  "editTabShowcase": "Showcase",
  "editTabTitles": "Titles",
  "editTabCardDesigns": "Card Designs",
  "editTabSessionBg": "Session Backgrounds",
  "editTabPatterns": "Patterns",

  "showcaseRemove": "Remove",
  "titlesEarned": "Titles earned: {count}",
  "@titlesEarned": {
    "placeholders": {
      "count": { "type": "int" }
    }
  },
  "cardDesignsOwned": "Card designs owned: {count}",
  "@cardDesignsOwned": {
    "placeholders": {
      "count": { "type": "int" }
    }
  },
  "buyButton": "Buy",
  "rentButton": "Rent",
  "activateButton": "Activate",
  "activeLabel": "Active",

  "sessionBgTitle": "Session Background Store",
  "sessionBgExplainer": "Stand out by renting session backgrounds for a set period using golden cards. This lets you create a distinguished session and control its properties.",
  "sessionBgFreeNote": "If you are not a subscriber, you can still create a session — but without free play mode.",
  "dontShowAgain": "Don't show this again",
  "doneButton": "Done",

  "createSessionTitle": "Create Session",
  "cancel": "Cancel",
  "voiceSessionLabel": "Voice Session",
  "sessionName": "Session Name",
  "sessionNameHint": "Enter session name",
  "gameType": "Game Type",
  "freePay": "Free Play",
  "limitedPlay": "Limited Play",
  "freePlayDescription": "Free play allows you to cut and restrict cards",
  "gameSpeed": "Game Speed",
  "speedUnlimited": "Unlimited",
  "speed30": "30 sec",
  "speed10": "10 sec",
  "speed5": "5 sec",
  "minimumLevel": "Minimum Level Required",
  "allowSpectators": "Allow spectators to listen",
  "sessionBackground": "Session Background",
  "createSessionButton": "Create Session",

  "settingsTitle": "Settings",
  "soundControl": "Sound Control",
  "allSounds": "All Sounds",
  "chatSound": "Chat Sound",
  "soundEffects": "Sound Effects",
  "playerVoices": "Player Voices",
  "differentVoicePerPlayer": "Different voice per player",

  "gameControl": "Game Control",
  "dimUnplayableCards": "Dim unplayable cards",
  "dimUnplayableCardsDesc": "Dims cards not available in Limited Play",
  "confirmSawa": "Confirm Sawa",
  "confirmSawaDesc": "Shows confirmation before committing a Sawa play",
  "preSelectPurchase": "Pre-select purchase",
  "preSelectPurchaseDesc": "Select your action before your turn arrives",
  "cardHeightBySuit": "Card height by suit",
  "cardHeightBySuitDesc": "Visually varies card height for different suits",
  "vibration": "Vibration",
  "vibrationDesc": "Enable haptic feedback on actions",
  "turnArrivalRaise": "Clarify your turn",
  "turnArrivalRaiseDesc": "Your cards lift when it becomes your turn",

  "accountsSection": "Accounts",
  "helpButton": "Help",
  "privacyPolicy": "Privacy Policy",
  "deleteAccount": "Delete Account",
  "logout": "Log Out",
  "socialAccounts": "Social Media Accounts",
  "linkButton": "Link",
  "unlinkButton": "Unlink",
  "appVersion": "Version: {version}",
  "@appVersion": {
    "placeholders": {
      "version": { "type": "String" }
    }
  },

  "archiveButton": "Game Archive",
  "newBadge": "New",
  "expressionOrder": "Expression Display Order",
  "subscriptionDaysLeft": "Subscription days remaining: {days}",
  "@subscriptionDaysLeft": {
    "placeholders": {
      "days": { "type": "int" }
    }
  },
  "cancelSubscriptionInstructions": "Subscription cancellation instructions",

  "balootCup": "Baloot Cup",
  "joinTournament": "Join the grand tournament now",

  "onlineCount": "{count} players online",
  "@onlineCount": {
    "placeholders": {
      "count": { "type": "int" }
    }
  },

  "alertsTitle": "Alerts",
  "alertTabAll": "All",
  "alertTabSocial": "Social",
  "alertTabRewards": "Rewards",
  "alertTabGame": "Game",
  "alertTabSystem": "System",

  "friendRequest": "{name} sent you a friend request",
  "@friendRequest": {
    "placeholders": {
      "name": { "type": "String" }
    }
  },
  "friendRequestAccepted": "{name} accepted your friend request",
  "@friendRequestAccepted": {
    "placeholders": {
      "name": { "type": "String" }
    }
  },
  "giftReceived": "{name} sent you a gift",
  "@giftReceived": {
    "placeholders": {
      "name": { "type": "String" }
    }
  },
  "dailyRewardReady": "Your daily reward is ready to claim!",
  "heartsFullNotif": "Your hearts are full! Time to play",
  "cupTicketsRefreshed": "2 new Cup tickets are ready!",
  "streakExpiring": "Don't lose your streak! Play before midnight",
  "rankUpNotif": "Congratulations! You reached {rank} rank",
  "@rankUpNotif": {
    "placeholders": {
      "rank": { "type": "String" }
    }
  },
  "acceptButton": "Accept",
  "declineButton": "Decline"
}
```

---

### FILE 2: lib/l10n/app_ar.arb (Arabic)

```json
{
  "@@locale": "ar",

  "appName": "بلوت",

  "navHome": "الرئيسية",
  "navStore": "المتجر",
  "navCommunity": "المجتمع",
  "navTournaments": "الدوريات",
  "navChat": "دردشة",

  "playButton": "العب",
  "playBaloot": "العب بلوت",
  "gameModesButton": "أوضاع اللعب",
  "voiceSession": "جلسة صوتية",
  "createSession": "إنشاء جلسة",
  "friendlyGame": "لعبة ودية",
  "sessionsList": "قائمة الجلسات",

  "playerProfile": "ملف اللاعب",
  "editProfile": "تعديل الملف الشخصي",
  "back": "عودة",
  "edit": "تعديل",

  "medals": "ميداليات",
  "hearts": "قلوب",
  "blueStars": "نجوم",
  "goldStars": "النجوم الذهبية",
  "level": "المستوى",
  "xpProgress": "{current} / {target} تجربة",

  "rankBeginner": "مبتدئ",
  "rankAmateur": "هاوي",
  "rankGood": "جيد",
  "rankAdvanced": "متقدم",
  "rankExpert": "خبير",
  "rankProfessional": "محترف",
  "rankMaster": "ماهر",
  "rankLegend": "أسطورة",

  "subscriptionFree": "مجاني",
  "subscriptionVip": "مشترك",
  "getVipNow": "اشترك الآن",
  "winButton": "اربح",

  "tabBio": "نبذة",
  "tabChallenges": "التحديات",
  "tabRanking": "التصنيف",
  "tabPrizes": "الجوائز",

  "bioPlaceholder": "اضغط هنا لاضافة نبذة عامة",
  "playerImpressions": "انطباعات اللاعبين",
  "noImpressions": "لا توجد انطباعات من اللاعبين",
  "supporters": "الداعمين",
  "joinDate": "لقد انضممت بتاريخ {date}",

  "noChallenges": "لا يوجد تحديات",

  "globalRank": "الترتيب : {rank}",
  "subTabPerformance": "الأداء",
  "subTabRanking": "الترتيب",
  "subTabWeekly": "أسبوعي",
  "subTabMonthly": "شهري",
  "subTabYearly": "العام",
  "points": "النقاط",

  "subTabTitles": "الألقاب",
  "subTabAchievements": "الإنجازات",
  "subTabPrizes": "الجوائز",
  "noPrizes": "ليس لديك أي جوائز",
  "noTitles": "ليس لديك أي ألقاب",
  "achievementCount": "{count} / {total} مفتوحة",

  "editTabShowcase": "المعرض",
  "editTabTitles": "الألقاب",
  "editTabCardDesigns": "تصاميم الورق",
  "editTabSessionBg": "خلفيات الجلسة",
  "editTabPatterns": "الأنماط",

  "showcaseRemove": "إزالة",
  "titlesEarned": "عدد الألقاب المكتسبة: {count}",
  "cardDesignsOwned": "عدد تصاميم الورق: {count}",
  "buyButton": "شراء",
  "rentButton": "تأجير",
  "activateButton": "تفعيل",
  "activeLabel": "مفعل",

  "sessionBgTitle": "متجر خلفيات الجلسة",
  "sessionBgExplainer": "تميز بتأجير خلفيات للجلسة لمدة معينة باستخدام الورق الذهبي. تمكنك من إنشاء جلسة مميزة والتحكم في خصائصها.",
  "sessionBgFreeNote": "في حال لم تكن مشترك ستتمكن من إنشاء جلسة ولكن من دون اللعب الحر.",
  "dontShowAgain": "لا تظهر هذه الرسالة مرة أخرى",
  "doneButton": "تم",

  "createSessionTitle": "إنشاء جلسة",
  "cancel": "إلغاء",
  "voiceSessionLabel": "جلسة صوتية",
  "sessionName": "اسم الجلسة",
  "sessionNameHint": "اسم الجلسة",
  "gameType": "نوع اللعب",
  "freePay": "لعب حر",
  "limitedPlay": "لعب محدود",
  "freePlayDescription": "اللعب الحر يمكنك من القطع والتقييد",
  "gameSpeed": "سرعة اللعب",
  "speedUnlimited": "لا نهائي",
  "speed30": "30 ث",
  "speed10": "10 ث",
  "speed5": "5 ثواني",
  "minimumLevel": "أدنى مستوى مسموح للعب",
  "allowSpectators": "السماح للمشاهدين بالاستماع",
  "sessionBackground": "خلفيات الجلسة",
  "createSessionButton": "إنشاء الجلسة",

  "settingsTitle": "الإعدادات",
  "soundControl": "تحكم الصوت",
  "allSounds": "كل الأصوات",
  "chatSound": "صوت الدردشة",
  "soundEffects": "المؤثرات الصوتية",
  "playerVoices": "أصوات اللاعبين",
  "differentVoicePerPlayer": "صوت مختلف لكل لاعب",

  "gameControl": "تحكم اللعب",
  "dimUnplayableCards": "تظليل الأوراق",
  "dimUnplayableCardsDesc": "تظليل الأوراق غير المتاحة في اللعب المحدود",
  "confirmSawa": "تأكيد السوا",
  "confirmSawaDesc": "إظهار قائمة للتأكيد عند لعب السوا",
  "preSelectPurchase": "تحديد شراء مسبق",
  "preSelectPurchaseDesc": "السماح بتحديد الشراء قبل دور اللاعب",
  "cardHeightBySuit": "تغيير ارتفاع الكروت",
  "cardHeightBySuitDesc": "يتغير ارتفاع الكروت ذات الزات المختلف",
  "vibration": "خاصية الاهتزاز",
  "vibrationDesc": "تفعيل خاصية الاهتزاز",
  "turnArrivalRaise": "توضيح وصول دورك للعب",
  "turnArrivalRaiseDesc": "يتغير ارتفاع الورق بوصول دورك",

  "accountsSection": "الحسابات",
  "helpButton": "مساعدة",
  "privacyPolicy": "سياسة الخصوصية",
  "deleteAccount": "حذف الحساب",
  "logout": "تسجيل خروج",
  "socialAccounts": "حسابات التواصل الاجتماعي",
  "linkButton": "ربط",
  "unlinkButton": "إلغاء ربط",
  "appVersion": "الإصدار: {version}",

  "archiveButton": "أرشيف كملنا",
  "newBadge": "جديد",
  "expressionOrder": "ترتيب ظهور التعابير",
  "subscriptionDaysLeft": "عدد الأيام المتبقية في الاشتراك: {days}",
  "cancelSubscriptionInstructions": "تعليمات إلغاء الاشتراك",

  "balootCup": "كأس البلوت",
  "joinTournament": "انضم إلى البطولة الكبرى",

  "onlineCount": "{count} لاعب متواجد",

  "alertsTitle": "مركز الإشعارات",
  "alertTabAll": "الكل",
  "alertTabSocial": "اجتماعي",
  "alertTabRewards": "المكافآت",
  "alertTabGame": "اللعب",
  "alertTabSystem": "النظام",

  "friendRequest": "{name} أرسل لك طلب صداقة",
  "friendRequestAccepted": "{name} قبل طلب صداقتك",
  "giftReceived": "{name} أرسل لك هدية",
  "dailyRewardReady": "جايزتك جاهزة للاستلام!",
  "heartsFullNotif": "قلوبك اكتملت! وقت اللعب",
  "cupTicketsRefreshed": "تذكرتان جديدتان جاهزتان!",
  "streakExpiring": "لا تفقد سلسلتك! العب قبل منتصف الليل",
  "rankUpNotif": "مبروك! وصلت إلى رتبة {rank}",
  "acceptButton": "قبول",
  "declineButton": "رفض"
}
```

---

## PART 3 — LANGUAGE PROVIDER (state management)

Create file: `lib/providers/language_provider.dart`

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar'); // Arabic is default

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_language') ?? 'ar';
    _locale = Locale(savedLang);
    notifyListeners();
  }

  Future<void> setArabic() async {
    _locale = const Locale('ar');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', 'ar');
    notifyListeners();
  }

  Future<void> setEnglish() async {
    _locale = const Locale('en');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', 'en');
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    if (isArabic) {
      await setEnglish();
    } else {
      await setArabic();
    }
  }
}
```

---

## PART 4 — HOW TO USE TEXT IN EVERY WIDGET

### Import at top of every screen file:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

### Get the text object (one line, use everywhere in the file):
```dart
final t = AppLocalizations.of(context)!;
```

### Use it everywhere instead of hardcoded strings:

```dart
// WRONG — never do this:
Text('Play')
Text('العب')

// RIGHT — always do this:
Text(t.playButton)   // shows "Play" in English, "العب" in Arabic automatically
```

### Examples for every screen:

```dart
// Home screen
Text(t.playButton)
Text(t.voiceSession)
Text(t.createSession)
Text(t.balootCup)

// Player card
Text(t.subscriptionFree)       // or t.subscriptionVip
Text(t.rankExpert)
Text(t.winButton)

// Profile screen tabs
Tab(text: t.tabBio)
Tab(text: t.tabChallenges)
Tab(text: t.tabRanking)
Tab(text: t.tabPrizes)

// Empty states
Text(t.noPrizes)
Text(t.noImpressions)
Text(t.noChallenges)

// Settings toggles
ListTile(
  title: Text(t.dimUnplayableCards),
  subtitle: Text(t.dimUnplayableCardsDesc),
  trailing: Switch(value: dimCards, onChanged: ...),
)

// With variables:
Text(t.xpProgress(1820, 2800))      // "1820 / 2800 XP"
Text(t.joinDate('2026/04/07'))       // "Joined on 2026/04/07"
Text(t.globalRank(759965))           // "Rank: 759965"
Text(t.onlineCount(1240))            // "1,240 players online"
```

---

## PART 5 — RTL LAYOUT (Arabic text direction)

Flutter handles RTL automatically when locale is Arabic.
BUT add this wrapper to your MaterialApp to make sure icons and layout also flip:

```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: languageProvider.locale,
  builder: (context, child) {
    return Directionality(
      textDirection: languageProvider.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: child!,
    );
  },
)
```

For individual widgets that should NOT flip with RTL (like card suit icons ♠♥♣♦):
```dart
Directionality(
  textDirection: TextDirection.ltr, // always left-to-right
  child: Row(
    children: [Text('♠'), Text('♥'), Text('♣'), Text('♦')],
  ),
)
```

---

## PART 6 — LANGUAGE TOGGLE IN SETTINGS

The Settings screen has a language selector. Build it like this:

```dart
// In Settings screen
Consumer<LanguageProvider>(
  builder: (context, langProvider, _) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LanguageOption(
          label: 'العربية',
          isSelected: langProvider.isArabic,
          onTap: langProvider.setArabic,
        ),
        const SizedBox(width: 12),
        _LanguageOption(
          label: 'English',
          isSelected: langProvider.isEnglish,
          onTap: langProvider.setEnglish,
        ),
      ],
    );
  },
)

// Language option pill widget:
class _LanguageOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF5C518)  // gold when selected
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF5C518)
                : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
```

---

## PART 7 — AUDIO FILE LANGUAGE SWITCHING

For game call audio (Hokum, Baloot, Kaboot etc.), the language also switches the audio files:

```dart
// In your audio service:
class AudioService {
  final LanguageProvider _langProvider;

  String _audioPath(String fileName) {
    final lang = _langProvider.isArabic ? 'ar' : 'en';
    final voice = _langProvider.selectedVoice; // e.g. 'turki', 'sarah'
    return 'assets/audio/$lang/$voice/$fileName';
  }

  void playHokum() {
    _play(_audioPath('01_hokum.mp3'));
  }

  void playBaloot() {
    // randomly pick one of 3 takes
    final take = Random().nextInt(3) + 1;
    _play(_audioPath('11_baloot_v$take.mp3'));
  }

  void playKaboot() {
    final take = Random().nextInt(3) + 1;
    _play(_audioPath('13_kaboot_v$take.mp3'));
  }
}
```

Audio folder structure:
```
assets/
  audio/
    ar/
      turki/
        01_hokum.mp3
        02_sun.mp3
        03_pass.mp3
        ... (all 16 lines)
      majeed/
        01_hokum.mp3
        ... (same 16 lines)
      ahmed/ sarah/ faisal/ anoud/ abeer/ suad/
    en/
      voice1/
        01_hokum.mp3
        ... (all 16 lines in English)
```

---

## PART 8 — QUICK REFERENCE: WHERE EACH KEY IS USED

| Screen | Keys to use |
|--------|-------------|
| Home screen bottom nav | navHome, navStore, navCommunity, navTournaments, navChat |
| Home player card | subscriptionFree/Vip, winButton, onlineCount |
| Home play area | playButton, voiceSession, createSession, friendlyGame, sessionsList |
| Home tournament banner | balootCup, joinTournament |
| Player profile header | medals, hearts, blueStars, goldStars |
| Profile rank badge | rankBeginner...rankLegend |
| Profile tabs | tabBio, tabChallenges, tabRanking, tabPrizes |
| Bio tab | bioPlaceholder, playerImpressions, noImpressions, supporters, joinDate |
| Ranking tab | globalRank, subTabPerformance, subTabRanking, subTabWeekly/Monthly/Yearly, points |
| Prizes tab | subTabTitles, subTabAchievements, subTabPrizes, noPrizes, noTitles, achievementCount |
| Edit profile tabs | editTabShowcase...editTabPatterns |
| Settings sound | soundControl, allSounds, chatSound, soundEffects, playerVoices, differentVoicePerPlayer |
| Settings game control | dimUnplayableCards...turnArrivalRaise (each has a Desc version too) |
| Settings accounts | accountsSection, helpButton, privacyPolicy, deleteAccount, logout, socialAccounts |
| Alerts screen | alertsTitle, alertTabAll/Social/Rewards/Game/System |
| Alert messages | friendRequest, friendRequestAccepted, giftReceived, dailyRewardReady, rankUpNotif |
| Create session | createSessionTitle, freePay, limitedPlay, freePlayDescription, gameSpeed, speed5/10/30/Unlimited |

---

## SUMMARY: 4 FILES TO CREATE

1. `pubspec.yaml` — add flutter_localizations + generate: true
2. `l10n.yaml` — localization config
3. `lib/l10n/app_en.arb` — English strings
4. `lib/l10n/app_ar.arb` — Arabic strings
5. `lib/providers/language_provider.dart` — language state

Then run: `flutter gen-l10n` to generate the AppLocalizations class.

After that, in every widget: `final t = AppLocalizations.of(context)!;` and use `t.anyKey` instead of any hardcoded string.
