# Royal Baloot 🃏 — VIP Card Game

**App Name:** Royal Baloot  
**Client:** Visca ME  
**Lead UI Developer:** Abdul Sami  
**Phase:** 1 — UI Foundation & Architecture (Logic-Ready)

---

## 1. Executive Summary

Royal Baloot is a premium VIP card game app built with Flutter, targeting the Middle Eastern market. The UI delivers a **"Luxury Minimalist"** dark-themed experience inspired by mobile games like Clash Royale, with full Arabic/English bilingual support.

Phase 1 delivers a **fully polished, logic-ready UI shell** — all screens, animations, and navigation are complete. A backend/logic developer can integrate the game engine by implementing the provided abstract interfaces without touching the UI layer.

---

## 2. Technical Stack

| Technology | Details |
|---|---|
| **Framework** | Flutter 3.x (Stable) |
| **Language** | Dart |
| **Architecture** | Feature-First Clean Architecture |
| **State Management** | Provider (ChangeNotifier) |
| **Design System** | VIP Dark & Gold (Charcoal + Royal Gold `#D4AF37`) |
| **Localization** | Dual-language (Arabic / English) via `LocaleProvider` |
| **Typography** | Google Fonts — `Montserrat` (EN), `Tajawal` / `Cairo` (AR) |
| **Platforms** | Android & iOS |

---

## 3. Project Structure

```plaintext
lib/
├── core/
│   ├── constants/
│   │   └── app_colors.dart          # Design tokens (royalGold, antigravityBlack)
│   ├── theme/
│   │   └── app_theme.dart           # Global dark theme + localized text themes
│   ├── widgets/
│   │   ├── glass_container.dart     # Glassmorphic card widget
│   │   ├── gold_button.dart         # Reusable gold gradient button
│   │   └── vip_background_shell.dart# Static suit pattern background (cached)
│   ├── interfaces/
│   │   └── i_baloot_controller.dart # Abstract game logic contract
│   ├── l10n/
│   │   ├── locale_provider.dart     # Language toggle (AR ↔ EN)
│   │   └── app_localizations.dart   # Localization delegate
│   └── providers/
│       └── user_provider.dart       # Mock user data (coins, gems, username)
│
├── data/
│   └── models/
│       └── user_model.dart          # User data schema
│
├── features/
│   ├── splash/
│   │   └── presentation/
│   │       └── splash_screen.dart   # Animated splash with card fan + golden arcs
│   ├── dashboard/
│   │   └── presentation/
│   │       └── navigation_shell.dart# Main game hub (TopBar, GameHub, BottomNav)
│   ├── game/
│   │   └── presentation/
│   │       └── finding_game_popup.dart # Matchmaking popup with sine-wave animation
│   ├── session/
│   │   └── presentation/
│   │       └── create_session_screen.dart # Session creation form
│   └── settings/
│       └── presentation/
│           └── settings_screen.dart  # Settings modal panel
│
└── main.dart                         # App entry point, providers, theme injection
```

---

## 4. Screens & Features

### 4.1 Splash Screen
- **4 animated playing cards** fan out from center with arcade-style physics
- **Golden rotating arc** circles behind the logo
- **Logo images** (`logo-text1.png`, `logo-text2.png`) fade in with scale animation
- **Subtitle** translates: "THE ROYAL CARD GAME" / "لعبة الورق الملكية"
- Auto-navigates to Home after animation completes

### 4.2 Home Screen (Navigation Shell)
The main hub with three distinct zones:

#### Top Bar
- **Player avatar chip** — 52px circle with username and rank badge
- **Currency bars** (Clash Royale style):
  - 💰 Coins: Gold gradient `+` button
  - 💎 Gems: Green gradient `+` button
- **Quick Menu button** (☰) — opens a dropdown with:
  - Language toggle (EN ↔ عربي)
  - Alerts
  - Settings

#### Game Hub (Center)
- **Play Medallion** — 170px pulsing glow circle with `♠` icon
  - Glow animation separated into its own layer via `RepaintBoundary` for performance
  - Tap scales up with spring-back animation
- **3 Satellite Actions:**
  - Create Session
  - Join Sessions  
  - VIP Store

#### Bottom Navigation (5 tabs)
| Index | Tab | Icon | Status |
|---|---|---|---|
| 0 | Shop | `storefront` | Coming Soon |
| 1 | Community | `people` | Coming Soon |
| 2 | **Home** | `home` | ✅ Active |
| 3 | Chat | `chat` | Coming Soon |
| 4 | Leagues | `emoji_events` | Coming Soon |

- Active tab: enlarged gold icon + label
- Inactive tabs: smaller muted icon, no label
- Non-Home tabs show a **"Coming Soon"** placeholder with lock icon

### 4.3 Create Session Screen
- Session name text input
- Game type selector (Restricted / Free Play)
- Game speed selector (30s / 10s / 5s)
- Minimum play level selector (Beginner / Intermediate / Expert)
- All labels fully translated to Arabic
- Scrollable form with back chevron

### 4.4 Finding Game Popup
- Modal overlay triggered by "Play" button
- **Sine-wave animated suit icons** (♠♥♣♦) — smooth opacity/scale pulse
- "Finding Game" / "البحث عن لعبة" + "Searching for players..." / "جاري البحث عن لاعبين..."
- Close chevron in top-right corner

### 4.5 Settings Panel
- Modal overlay with blurred backdrop
- Toggle switches for Audio, Language
- Action items: Change Name, Notifications
- Links: Help & Support, Privacy, Terms of Service, Credits
- Player ID display
- All text fully translated

---

## 5. Design System

### Color Palette

| Token | Hex | Usage |
|---|---|---|
| **Antigravity Black** | `#0D0F14` | Primary background |
| **Surface** | `#1C1F26` | Cards, overlays |
| **Royal Gold** | `#D4AF37` | Borders, accents, primary actions |
| **Soft Ivory** | `#F4E4B7` | Text on dark surfaces |
| **Gem Green** | `#4CAF50` → `#2E7D32` | Gem currency button gradient |

### Typography

| Context | Font | Weight | Size |
|---|---|---|---|
| **Headings (EN)** | Montserrat | 600-800 | 15-20px |
| **Body (EN)** | Montserrat | 400-500 | 9-13px |
| **Arabic text** | Tajawal / Cairo | 500-700 | Matches EN sizes |

---

## 6. Localization (Arabic / English)

### Strategy
- **Layout is always LTR** — forced via `Directionality(textDirection: TextDirection.ltr)` in the `MaterialApp` builder. This follows the game industry standard (Clash Royale, PUBG, etc.) where UI positions stay fixed regardless of language.
- **Text content translates** — all user-facing strings switch between Arabic and English via `LocaleProvider.isArabic`.
- **Arabic text renders correctly** — Arabic glyphs naturally render right-to-left within their `Text` widget, no special handling needed.

### Translation Coverage

| Screen | Status |
|---|---|
| Splash subtitle | ✅ Translated |
| Home — Play button | ✅ Translated |
| Home — Satellite labels | ✅ Translated |
| Home — Bottom nav labels | ✅ Translated |
| Home — Quick menu items | ✅ Translated |
| Home — Coming Soon pages | ✅ Translated |
| Create Session — all labels | ✅ Translated |
| Finding Game — title & subtitle | ✅ Translated |
| Settings — all items | ✅ Translated |

---

## 7. Performance Optimizations

| Optimization | Implementation |
|---|---|
| **Background caching** | `VipStaticBackground` uses `RepaintBoundary` + `shouldRepaint: false` — painted once, never redraws |
| **Medallion glow separation** | Animated glow shadow is in its own layer; static medallion content wrapped in `RepaintBoundary` |
| **Lazy-loaded popups** | Settings, Finding Game, and Quick Menu are only built when opened |
| **Minimal rebuilds** | `Provider` with `context.watch` / `context.read` for targeted rebuilds |
| **Font pre-caching** | Google Fonts loaded in `main()` before app renders |

---

## 8. Responsiveness

| Device Class | Width | Status |
|---|---|---|
| **Small phones** (iPhone SE, Galaxy A series) | 320-360px | ✅ Supported |
| **Standard phones** (iPhone 14, Pixel 7) | 375-412px | ✅ Primary target |
| **Large phones** (iPhone Pro Max, Galaxy Ultra) | 428-480px | ✅ Supported |
| **Tablets** | 600px+ | ⚠️ Functional but not optimized |

### Responsive Techniques Used
- `MediaQuery.of(context).size` for popup widths (85-88% of screen)
- `Expanded` + `Spacer` for flexible row layouts
- `SafeArea` for notch/status bar handling
- `SingleChildScrollView` for scrollable forms
- `MainAxisSize.min` to prevent unnecessary stretching

---

## 9. Developer Handoff — Logic Integration

All game interactions are behind `debugPrint` stubs marked with `LOGIC_PLUG_IN` comments. A backend developer can replace them without modifying any widget code.

### Key Integration Points

| Action | Current Stub | File |
|---|---|---|
| Play Now | `FindingGamePopup.show()` | `navigation_shell.dart` |
| Create Session | `debugPrint('[CreateSession]...')` | `create_session_screen.dart` |
| Join Sessions | `debugPrint('[LobbyAction]...')` | `navigation_shell.dart` |
| VIP Store | Shows "Coming Soon" snackbar | `navigation_shell.dart` |
| Change Name | `debugPrint('[Settings]...')` | `settings_screen.dart` |
| Notifications | `debugPrint('[Settings]...')` | `settings_screen.dart` |

### Abstract Interfaces
- `IBalootController` — Game engine contract (in `lib/core/interfaces/`)
- `UserProvider` — Mock user data (replace with real API)
- `LocaleProvider` — Language state management

---

## 10. Assets

```plaintext
assets/
├── images/
│   ├── icon.png           # App launcher icon (Royal Baloot logo)
│   ├── logo-text1.png     # Bottom splash logo text
│   ├── logo-text2.png     # Top splash logo text
│   ├── dollar.png         # Coin currency icon
│   ├── gem.png            # Gem currency icon
│   └── chevron-left.png   # Custom back button icon
├── icons/                 # Reserved for future SVG icons
└── lottie/                # Reserved for future Lottie animations
```

---

## 11. Setup & Run

### Prerequisites
- Flutter SDK >= 3.0.0
- Android Studio / Xcode for platform builds
- A physical device or emulator

### Commands
```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Run in release mode (for performance testing)
flutter run --release

# Analyze code
flutter analyze

# Regenerate app launcher icons
dart run flutter_launcher_icons
```

---

## 12. Known Issues & TODOs

### Known Issues
- `create_session_screen.dart` has dead code warnings from hardcoded `isArabic = false` — will be resolved when `LocaleProvider` is fully integrated
- iOS launcher icon has alpha channel warning — set `remove_alpha_ios: true` in pubspec if submitting to App Store

### Phase 2 TODOs
- [ ] Connect `IBalootController` to real game engine
- [ ] Replace mock `UserProvider` with API-backed data
- [ ] Build Game Table UI (`features/game/`)
- [ ] Implement Shop screen with in-app purchases
- [ ] Implement Chat screen with real-time messaging
- [ ] Implement Leagues/Tournaments screen
- [ ] Add push notification support
- [ ] Tablet-optimized layouts

---

**Built with ♠ by Antigravitty**
