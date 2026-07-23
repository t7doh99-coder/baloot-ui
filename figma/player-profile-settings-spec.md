# Player Profile & Settings — Build Specification

Reference: Kammelna (كملنا) Baloot app — full screen audit from live screenshots.
Purpose: hand this spec to Cursor / your dev team as the source of truth for building the Player Profile screen, the Edit Profile (customization) screen, and the Settings screen.

---

## 1. PLAYER PROFILE SCREEN (read-only view)

### 1.1 Header bar
- Title: "Player Profile" (centered)
- Left button: "Edit" → navigates to Edit Profile screen (Section 2)
- Right button: "Back" → returns to previous screen

### 1.2 Profile header card (persistent across all tabs)
Build this as a single reusable component — it stays fixed while tab content below it scrolls.

Fields/elements required:
- `showcaseSlot` — square slot, left side. Empty state = "+" icon (tappable, opens Edit Profile → Showcase tab). Filled state = shows the player's selected achievement/title/trophy icon.
- `avatar` — circular image, center-left of card.
  - `onlineStatusDot` — small green circle, top-right corner of avatar. Bound to `player.isOnline`.
  - `cardFrameOverlay` — small decorative playing-card graphic, bottom-right corner of avatar (cosmetic, non-functional).
- `username` — text pill directly below avatar. Max 16 characters, truncate with ellipsis if longer.
- `rankBadge` — pill, right side of card. Shows rank name (e.g. "Beginner") with all 4 suit icons (♠ ♥ ♣ ♦) displayed beneath it as a static decorative row.
- `statRow` — 4 stat chips in a horizontal row beneath the avatar/username/rank group:
  1. Medals — coin/medal icon + number (`player.medals`)
  2. Hearts — heart icon + number (`player.hearts`)
  3. Blue star — star icon (blue fill) + number (`player.blueStars`)
  4. Gold star — star icon (gold fill) + number (`player.goldStars`)

### 1.3 Tab navigation — 4 top-level tabs
Order (right to left, RTL layout): **Bio | Challenges | Ranking | Prizes**
Default selected tab on screen load: **Bio**

---

#### TAB 1 — Bio (نبذة)

Components needed:
- `bioTextField` — tap-to-edit text area. Empty state shows placeholder "Tap here to add a general bio." Editable inline or via modal — your choice, but must be reachable without leaving this tab.
- `playerImpressionsSection` — a sub-panel titled "Player Impressions."
  - Empty state: centered icon + text "No impressions from players yet."
  - Populated state: list of impression entries, each showing: reviewer avatar, reviewer name, impression text/tag, date.
  - This is a lightweight social-proof/testimonial system — other players who've played with you can leave a short tag or comment. Build the data model now even if the UI for *leaving* an impression ships later.
- `supportersButton` — full-width button, "Supporters." Opens a list of players who have supported/gifted this player (ties into the gifting system).
- `joinDateLabel` — static text at the bottom: "You joined [App Name] on [date]." Pull from `player.createdAt`.

Data fields needed on the Player model:
```
bio: string | null
impressions: Impression[]
joinDate: timestamp
```

Impression model:
```
Impression {
  id: string
  fromPlayerId: string
  fromPlayerName: string
  fromPlayerAvatar: string
  text: string
  createdAt: timestamp
}
```

---

#### TAB 2 — Challenges (التحديات)

Components needed:
- `challengeCampaignHeader` — branded artwork banner for the current active challenge campaign/season (e.g. seasonal crest, themed logo).
- `challengeList` — list of active challenges, each showing: icon, title, progress bar (`current/target`), reward preview, expiry countdown.
- Empty state: centered campaign logo + "No challenges available."

Data model:
```
Challenge {
  id: string
  title: string
  description: string
  icon: string
  progressCurrent: number
  progressTarget: number
  reward: RewardObject
  expiresAt: timestamp
  status: "active" | "completed" | "expired"
}
```

Note: this is distinct from the Daily/Weekly/Season challenges discussed in the progression-system spec — this screen appears to surface a campaign-specific challenge set, likely seasonal/limited-time, separate from the recurring daily ones. Confirm with your game design doc whether to merge these into one system or keep them separate.

---

#### TAB 3 — Ranking (التصنيف)

This tab has its own internal sub-tab bar: **Performance | Ranking** (right to left).

##### Sub-tab: Ranking (default selected)
- `globalRankNumber` — large numeric display: "Rank: [number]" (e.g. "Rank: 759965"). Lower number = better rank.
- `percentileChart` — triangle/pyramid visual. Player's position along the height of the triangle represents percentile standing (e.g. "88%" or "100%" shown near the base). Build this as an SVG or custom-drawn component — a filled triangle with a horizontal marker line + percentage label at the player's position.
- `timeFilterToggle` — 3-option segmented control: **Weekly | Monthly | Yearly**. Changes the data window for both the rank number and percentile chart.
- `infoButton` — small book/info icon, top-left of the panel. Opens an explainer modal describing how ranking is calculated.

##### Sub-tab: Performance
- `pointsGauge` — circular ring/gauge chart, centered. A star icon sits at the top of the ring as a decorative marker.
- `pointsValue` — centered inside the ring: "Points: [current]/[target]" — note this value can be **negative** (e.g. "-1332/0"), so design the UI to clearly show negative values in a distinct color (red) vs positive (default/green).
- Same `timeFilterToggle` (Weekly/Monthly) applies here too — keep filter state synced between both sub-tabs.

Data model:
```
RankingData {
  globalRank: number
  percentile: number          // 0-100
  netPoints: number            // can be negative
  pointsTarget: number
  period: "weekly" | "monthly" | "yearly"
}
```

---

#### TAB 4 — Prizes (الجوائز)

This tab has its own internal sub-tab bar at the **bottom** of the panel (not the top, unlike Ranking): **Titles | Achievements | Prizes** (right to left, with "Prizes" as the rightmost/default).

##### Sub-tab: Prizes (default)
- `trophyShelfDisplay` — 3 stacked "shelf" components with dramatic spotlight/glow lighting effect (decorative background).
- Empty state per shelf: "You don't have any prizes" centered text.
- Populated state: each shelf displays a trophy icon + name + date earned.

##### Sub-tab: Achievements
- Grid or list of achievement badges, each with: icon, name, unlock condition description, unlocked/locked state, date unlocked (if applicable).
- Suggest building an achievement count summary at the top: "47 / 120 unlocked."

##### Sub-tab: Titles
- Grid of earned title badges (e.g. "The King," "Sharp Dealer"). Same display pattern as Achievements.
- Empty state: "You don't have any titles yet."

Data models:
```
Trophy {
  id: string
  name: string
  iconUrl: string
  earnedAt: timestamp
}

Achievement {
  id: string
  name: string
  description: string
  iconUrl: string
  isUnlocked: boolean
  unlockedAt: timestamp | null
  progressCurrent: number | null
  progressTarget: number | null
}

Title {
  id: string
  name: string
  earnedAt: timestamp
}
```

---

## 2. EDIT PROFILE SCREEN (customization view)

Separate screen, reached via the "Edit" button on the Player Profile header (Section 1.1).

### 2.1 Header bar
- Title: "Edit Personal Profile"
- Right button: "Back"

### 2.2 Profile header card (same component as 1.2, with ONE difference)
- `avatar` now shows an `editPencilIcon` overlay, top-right corner — tapping it opens the avatar picker (camera roll upload OR avatar library selection).

### 2.3 Tab navigation — 5 tabs
Order: **Showcase | Titles | Card Designs | Session Backgrounds | Patterns**

---

#### TAB 1 — Showcase (المعرض)

- Purpose: player selects ONE achievement/trophy/title to display in the `showcaseSlot` on their main Profile card (see 1.2).
- `itemGrid` — grid of all earned showcase-eligible items (trophies, medals, special achievements).
- Each grid item: icon + name, tappable to select.
- Selected state: yellow/gold highlight border around the chosen item.
- Special grid item: "Remove" (circle-with-slash icon) — always present as the last option, clears the showcase slot back to empty.

```
showcaseSelection: {
  selectedItemId: string | null   // null = nothing showcased
  selectedItemType: "trophy" | "achievement" | "title" | null
}
```

---

#### TAB 2 — Titles (الألقاب)

- `titleCountLabel` — "Number of titles earned: [count]"
- `titleGrid` — grid of earned titles, tappable to select ONE as the displayed title (separate selection state from Showcase — a player can showcase a trophy AND display a title simultaneously, in different UI locations).
- Empty state: single "Empty" placeholder tile shown when count = 0.

---

#### TAB 3 — Card Designs (تصاميم الورق)

- `buyButton` — top-left, opens the card-design store (in-app purchase flow).
- `designCountLabel` — "Number of card designs owned: [count]"
- `designGrid` — grid of owned + purchasable card-back designs. Default/free design always present and pre-selected.
- Selected state: yellow highlight border.
- Locked/unowned designs: show price + "Buy" button instead of being directly selectable.

```
CardDesign {
  id: string
  name: string
  imageUrl: string
  price: number
  currency: "goldenCards" | "coins"
  isOwned: boolean
  isEquipped: boolean
}
```

---

#### TAB 4 — Session Backgrounds (خلفيات الجلسة)

This tab has its own internal sub-tab bar: **Rent | Design**

##### First-time entry: explainer modal
On first visit to this tab, show a one-time modal (dismissible permanently via checkbox):
> "Stand out by renting session backgrounds for a set period using golden cards. This lets you create a distinguished session and control its properties. If you are not a subscriber, you can still create a session — but without free play [unrestricted/cutting mode]."

Modal requirements:
- `dontShowAgainCheckbox` — persists choice to user prefs.
- `doneButton` — green, full-width, dismisses modal.

##### Design sub-tab
- `backgroundCountLabel` — "Number of session backgrounds owned: [count]"
- Default branded background shown with an `activateButton` beneath it.
- Background preview card includes the app logo watermark in the corner.

##### Rent sub-tab
- Store-style grid of rentable backgrounds, each showing: preview image, rent duration, golden-card cost, "Rent" button.

```
SessionBackground {
  id: string
  name: string
  imageUrl: string
  rentCostGoldenCards: number
  rentDurationDays: number
  isOwned: boolean
  isActive: boolean
  expiresAt: timestamp | null   // for rented items
}
```

---

#### TAB 5 — Patterns (الأنماط)

- `currencyDisplay` — top of panel, shows current balance of the specific currency used here (appears to be a distinct currency, shown with a banknote icon — confirm with backend whether this maps to Golden Cards or a separate "Patterns currency").
- `patternGrid` — grid of visual pattern designs. Each tile: pattern preview, price label ("1000" + currency icon) and "Buy" button, OR "Active" label (dark pill) if currently equipped.
- Only one pattern can be active at a time.

```
Pattern {
  id: string
  name: string
  imageUrl: string
  price: number
  isOwned: boolean
  isActive: boolean
}
```

---

## 3. SETTINGS SCREEN

### 3.1 Header bar
- Title: "Settings"
- Right button: "Back"

### 3.2 Section: Sound Control

Three independent toggles (not nested — all top-level, all default ON):
1. `allSoundsToggle` — master switch. When OFF, overrides/mutes the two below regardless of their individual state.
2. `chatSoundToggle` — chat message notification sound.
3. `soundEffectsToggle` — in-game SFX (card sounds, button taps, etc.) — separate from voice calls.

### 3.3 Section: Player Voices — IMPORTANT, BUILD THIS CAREFULLY

This is a distinct system from the toggles above — it controls which **voice actor** is heard for game-call audio (Hokum, Baloot, Kaboot, etc.), not whether audio plays at all.

Requirements:
- `voiceGrid` — 8 selectable voice options, displayed as two rows of 4:
  - Row 1 (male voices): Turki, Majeed, Ahmed, Faisal
  - Row 2 (female voices): Anoud, Sarah, Abeer, Suad
- Each voice option is a tappable pill. Selected state = filled/highlighted background.
- `differentVoicePerPlayerToggle` — when ON, each of the 4 players at a table can independently select their own announcer voice (their selection is visible/audible to the table). When OFF, presumably the host's voice selection or the player's own selection applies uniformly — confirm exact behavior with game design, but build the toggle and the per-player voice assignment data structure now.

Build implication for your audio pipeline: you previously had a single male voice (Khaled Alnajjar) for all 54 script lines. **You now need to record the full script across multiple distinct voices** — at minimum start with 2 male + 2 female voices, expand to all 8 later. Each voice needs its own full set of the 54 audio files, organized by voice ID.

```
VoiceOption {
  id: string
  name: string            // "Turki", "Sarah", etc.
  gender: "male" | "female"
  audioFileSetId: string  // maps to the recorded 54-line set for this voice
}

PlayerVoiceSettings {
  selectedVoiceId: string
  differentVoicePerPlayer: boolean
}
```

File organization recommendation:
```
/audio/{voiceId}/ar_01_hokum.mp3
/audio/{voiceId}/ar_02_sun.mp3
... (all 54 lines per voice folder)
```

### 3.4 Section: Game Control

Six toggles, all should have a primary label + a one-line description beneath each (per the reference screenshots — don't ship these as bare switches with no explanation):

1. `dimUnplayableCardsToggle` — "Dim cards not available in Limited Play." Description: dims/shades cards in hand that cannot legally be played this turn.
2. `confirmSawaToggle` — "Confirm Sawa." Description: shows a confirmation list/popup before committing a Sawa play.
3. `preSelectPurchaseToggle` — "Pre-select purchase." Description: allows the player to queue an action before their turn arrives, speeding up play.
4. `cardHeightBySuitToggle` — "Change card height by suit." Description: visually varies card height for different suits (likely an accessibility/legibility aid). Note: shown disabled/greyed in the reference — confirm if this is a planned-but-unreleased feature or conditionally available.
5. `vibrationToggle` — "Enable vibration." Description: standard haptic feedback on actions.
6. `turnArrivalCardRaiseToggle` — "Clarify your turn." Description: your cards visually raise/lift in your hand when it becomes your turn — a non-intrusive turn indicator.

```
GameControlSettings {
  dimUnplayableCards: boolean
  confirmSawa: boolean
  preSelectPurchase: boolean
  cardHeightBySuit: boolean
  vibrationEnabled: boolean
  turnArrivalCardRaise: boolean
}
```

### 3.5 Section: Accounts

- `helpButton` — opens support/FAQ.
- `privacyPolicyButton` — opens privacy policy (web view or in-app doc).
- `deleteAccountButton` — styled in red/destructive color. Must trigger a confirmation flow before executing — required by App Store / Play Store policy, must be reachable (not buried).
- `appNameLogoutRow` — shows app logo + "Log Out" (red text) in a single row.
- `socialAccountsSection` — sub-header "Social Media Accounts," lists:
  - Google — shows "Unlink" (red) if connected, "Link" (green) if not.
  - X (Twitter) — same pattern.
  - Facebook — same pattern.
- `appVersionLabel` — small text at the very bottom: "Version: [x.x.x]" — pull from build config automatically, never hardcode.

### 3.6 Section: Extras (can live in Settings OR a consolidated account view — confirm with design)

- `archiveButton` — "[App Name] Archive," tagged with a "New" badge. Likely a replay/highlight history feature — scope this as a future build item, but reserve the menu slot now.
- `expressionOrderButton` — "Expression Display Order," tagged "New." Opens a reorderable list of the player's in-game expression/emoji pack, letting them set which expressions appear first in the quick-select wheel during gameplay.
- `subscriptionStatusBlock` — shows remaining subscription days inside a "Paid" badge (or equivalent free-tier indicator), plus a link to "Subscription cancellation instructions."

```
ExpressionSettings {
  expressionOrder: string[]   // ordered list of expression IDs, player-customizable
}
```

---

## 4. BUILD PRIORITY (suggested order for Cursor)

1. Player model + stat chips (medals, hearts, blue star, gold star) — needed everywhere, build first.
2. Profile header card component (reusable across Profile view + Edit Profile view).
3. Bio tab (simplest tab, validates the tab-navigation pattern).
4. Settings: Sound Control + Game Control toggles (straightforward, no complex data).
5. Settings: Player Voices system + voice picker UI (more involved — needs the audio file structure decided first).
6. Ranking tab (Performance + Ranking sub-tabs) — needs the percentile pyramid chart component.
7. Prizes tab (Titles/Achievements/Prizes sub-tabs) + Showcase tab in Edit Profile — these are linked systems, build together.
8. Card Designs + Patterns tabs (store-style grids — similar component, can share code).
9. Session Backgrounds (Rent/Design) — most complex due to the rent-duration + explainer-modal logic.
10. Challenges tab + Archive + Expression Ordering — lowest priority, ship last.

---

## 5. OPEN QUESTIONS TO RESOLVE BEFORE BUILDING

- Does "Player Impressions" (Bio tab) need a UI for *leaving* an impression on someone else's profile, or is it currently read-only/system-generated in the reference app? Confirm before scoping.
- Is the "Patterns" currency the same as Golden Cards, or a separate currency? Affects wallet/balance display logic.
- What exactly triggers "Different voice per player" — is it host-controlled, or does each client device apply its own local player's voice selection independently? This affects whether voice selection needs to sync over the network during a match.
- Is "Limited Play" the default for ranked/competitive matches, with "Free Play" (cutting/restriction) only available in custom Created Sessions? Confirm this before gating the cutting mechanic.
