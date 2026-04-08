# Royal Baloot (أربعة مربعة) - VIP Edition

**Client:** Visca ME  
**Lead UI Developer:** Abdul Sami  
**Phase:** 1 - Technical Foundation & Architecture

## 1. Executive Summary
This repository contains the "Logic-Ready" foundation for the premium *Royal Baloot* card game. The architectural goal of Phase 1 is to create a high-performance, minimalist VIP UI shell that is strictly decoupled from the core game engine. This clean decoupling allows for seamless logic integration and backend hookups in subsequent phases without altering the presentation layer.

## 2. Technical Stack & Standards
*   **Framework:** Flutter 3.x (Stable)
*   **Architecture:** Feature-First Clean Architecture
*   **State Management:** Provider (via abstract Interface Controllers)
*   **Design Paradigm:** VIP Dark & Gold (Minimalist Glassmorphism)
*   **Localization:** Dual-language optimization (Arabic RTL / English LTR)

## 3. Architecture & Project Structure
To prevent code spaghettification and parallelize UI/Engine development, the codebase is entirely modularized.

```plaintext
lib/
├── core/
│   ├── theme/           # Global VIP Dark/Gold styles, shadows, and TextThemes
│   ├── constants/       # Reusable dimensions, colors, and asset references
│   ├── widgets/         # UI Atoms (GlassContainer, GoldButton)
│   ├── interfaces/      # ABSTRACT CLASSES (The contract for the Game Logic)
│   └── l10n/            # Localization Engine (AppLocalizations, LocaleProvider)
├── data/
│   └── models/          # Data schemas (CardModel, PlayerModel, TableModel)
├── features/
│   ├── splash/          # Animated entrance utilizing the circular logo
│   ├── dashboard/       # Lobby, Profile, & Navigation Shell
│   ├── game/            # Table UI & Card Physics (Phase 2 Focus)
│   └── shop/            # Economy & Subscription UI
└── main.dart            # Initialization, Theme injection, Route management
```

## 4. VIP Design Identity
The branding is built around a High-Contrast Dark Theme, delivering a "Premium Club" feel while significantly reducing eye strain during long gameplay sessions.

| Element | Hex Code | Visual Application |
| :--- | :--- | :--- |
| **Primary Background** | `#0D0F14` | Deep Scaffolds & Main Canvas |
| **Surface/Glass** | `#1C1F2B` | Menu Cards, Glassmorphic Overlays |
| **VIP Gold** | `#D4AF37` | Borders, Primary Actions, Accents |
| **Soft Silver** | `#C0C0C0` | Secondary Text, Muted Dividers |

**Typography:**
*   **Arabic (RTL):** `Tajawal` - Modern, bold, highly legible for Right-to-Left interfaces.
*   **English (LTR):** `Montserrat` - Geometric, premium, and clean.

## 5. Bilingual & RTL Logic
The foundation is fully optimized for the Middle Eastern market:
*   **Localization Setup:** Dynamic switching between AR and EN via `LocaleProvider`.
*   **Directionality:** The UI relies on intrinsic `Start/End` directional logic rather than explicit `Left/Right`, guaranteeing flawless mirroring when toggling languages.

## 6. Developer Handoff Readiness (Logic Integration)
All game-related interactions and state updates are hidden behind clean interfaces.
**Note to Backend / Engine Developers:** 
To wire up the game logic, simply implement `IBalootController` (in `lib/core/interfaces/`) and inject it into the application state. The UI components will automatically react to your state updates. No modifications to the presentation (UI) layer are necessary. Every play, bid, and pass animation is triggerable via these interface functions.

## 7. Setup & Run
1. Ensure you have the Flutter SDK (>= 3.0.0) installed.
2. Clone the repository and run `flutter pub get`.
3. To view the UI skeleton, simply run `flutter run`.
