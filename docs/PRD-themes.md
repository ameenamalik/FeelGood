# PRD: Kiln, Moss and Indigo — a contrast rework and an unlockable theme

Status: **draft. Direction and all four themes' palettes are decided; two small items open (§10). Nothing here is implemented.**
Parent doc: [PRD.md](PRD.md). Design source: Paper file "FeelGood — Today colour explorations" (artboards A, B, C).

## 1. Summary

The Today screen's colours have a contrast problem: every course card sits at the same pastel
lightness, the mascots blend into their cards, and the terracotta hero is the weakest text on the
screen. Three explorations were drawn:

| | Name | Role in this PRD |
|---|---|---|
| A | **Kiln** | The new default light look, for everyone. |
| B | **Moss** | The new default dark look, for everyone. |
| C | **Indigo** | An optional look, unlocked by earning a Little Win. |

This is a **re-skin of the existing token layer**, not a new design system. Screens keep using
`FGColor`, `Course` and `FGAura`; only what those names resolve to changes.

## 2. Problem

From the current Today screen:
- Four cards at one pastel value: nothing separates them from each other or from the page.
- The orange and red mascots disappear into peach and pink cards.
- The tab bar is translucent, so card text shows through it.
- Hero text is white on mid-terracotta, the lowest contrast on the screen.

## 3. Goals and non-goals

**Goals**
1. Every text/background pair on Today meets 4.5:1 (7:1 for text under 16pt); every tappable boundary meets 3:1.
2. Keep the wabi-sabi, wellness, women-first feel: warm, slightly imperfect, never clinical.
3. One place to change colour. No screen hardcodes a theme.
4. Unlocking Indigo feels like a gift, not a score.

**Non-goals**
- No new type. SF Rounded / SF Pro stay exactly as they are.
- No new layout language beyond the two changes in §6.
- No user-authored colours, no theme store, no seasonal themes in v1.
- No new analytics that record which theme someone uses beyond the anonymous aggregate already allowed; nothing health-related is ever attached.

## 4. Themes (values from the artboards)

Contrast ratios below were computed from the hex values, not eyeballed. Text pairs all clear the bar.

**Kiln (light)** — mood: glazed ceramic on linen.
| Role | Value | Note |
|---|---|---|
| Page | `#F4EEE3` | linen |
| Ink | `#2A1E18` | 14.0:1 on page |
| Hero fill / text | `#4B2A3A` / `#FBF3E8` | 11.3:1 |
| Cards: appetizer, main, side, dessert | `#F0C9A8`, `#E9D392`, `#BBD0B6`, `#E3B9C4` | ink on each: 10.5, 10.9, 9.9, 9.3 |
| Plate / pill | `#FBF6EC` | cream disc behind each mascot |

**Moss (dark)** — mood: botanical evening.
| Role | Value | Note |
|---|---|---|
| Page | `#1D2922` | cream text 12.9:1 |
| Hero fill / text | `#C6DAC4` / `#2B1A1A` | 11.2:1. Blush was rejected: the peach mascot vanished on it. |
| Cards | `#5A3A32`, `#4F4A25`, `#2F4A3C`, `#5B3446` | cream text 8.9, 7.9, 8.6, 9.2 |
| Plate | `#F3EDE0` | |

**Indigo (light, unlockable)** — mood: paper and ink-dyed cloth.
| Role | Value | Note |
|---|---|---|
| Page | `#ECE8E1` | |
| Ink | `#1F2233` | 12.9:1 |
| Hero fill / text | `#2F3A5F` / `#F5F1EA` | 9.9:1 |
| Cards | `#FBF9F5` paper, colour only in chip + plate | chip text 8.0–8.5:1 |

**Indigo Dark (unlockable, night)** — mood: paper on ink. Artboard D.
| Role | Value | Note |
|---|---|---|
| Page | `#131829` | text `#EEF0F8` 15.5:1 |
| Card fill / edge | `#212948` / `#5C6694` | edge 3.2:1 on page; ink on card 12.5:1 |
| Hero fill / text | `#EFE6D2` / `#1F2233` | 12.7:1; the pale oat hero keeps the blueberry mascot visible |
| Chips (fill / text) | `#5A3520`/`#F6D3B8`, `#4F4210`/`#EFDDA0`, `#24463A`/`#CBDCC6`, `#5E2A44`/`#F0CBD3` | 7.3–7.6:1 |
| Plates | `#F6D3B8`, `#EFDDA0`, `#CBDCC6`, `#F0CBD3` | light, so mascots glow |
| Swap border | `#B4BAD6` | 7.4:1 on the card |
| Tab bar fill / edge / active | `#1F2640` / `#5C6694` / `#EFE6D2` | |

### Card edges (fixed in the artboards)
Card edges were below the project's 3:1 rule for a tappable boundary (2.2–2.7 Kiln, 2.5–3.2 Moss, 1.4 Indigo). They are now all ≥3.1:1 against the page, at 1.5pt:

| Theme | Appetizer | Main | Side | Dessert |
|---|---|---|---|---|
| Kiln | `#A47F61` | `#9C8543` | `#768C6F` | `#A97A87` |
| Moss | `#91685A` | `#7C7538` | `#517B66` | `#94647B` |
| Indigo (light) | `#858282` on all | | | |
| Indigo Dark | `#5C6694` on all | | | |

### Known gaps to fix before build
- **The red apple mascot** is red in every theme. The "no red" rule is about UI, but it is worth a deliberate call.
- Contrast numbers here are computed from hex values. They must be enforced by the tests in §9, not trusted from this table.
- The edges are checked against the page only. Confirm they read well next to the card fills on device.

## 5. How it layers over the existing system (the "not hardcoding" requirement)

What exists today (verified in code):
- `FGColor` in `DesignSystem/Palette.swift` is the semantic layer. Each token resolves light/dark via `Color(light:dark:)`, a `nonisolated` dynamic `UIColor`. About 680 call sites use `FGColor.*`.
- `Course.accentGradient`, `tagFill`, `tagText`, `accentHex` and `FGAura` hold the per-course and per-answer colours.
- About 30 `Color(light:dark:)` literals live **outside** `Palette.swift`, mostly in `ExploreView`, `FeelGoodPaywallView`, `CheckInBanner`, `ChatHistorySheet`, `ChatCheckInView`, `AuthSheetView` and `ProductIntroView`. These would ignore a theme.
- The widget receives colour as raw hex (`Course.accentHex`), so it does not follow either appearance or a theme.

Approach, in order:

1. **Migrate the ~30 literals into named tokens first.** No visual change. This is the real prerequisite; without it a theme is only partly applied.
2. **Add missing semantic roles** rather than reusing accents for new jobs: `courseFill(course)`, `courseEdge(course)`, `plate`, `heroFill`, `onHero`, `onHeroMuted`, `tabBarFill`, `tabBarEdge`, `tabActiveFill`, `onTabActive`. Today's `accentGradient` becomes one implementation of `courseFill`, not the only one.
3. **Make the theme part of resolution, not of call sites.** Keep `Color(light:dark:)` shape but have the dynamic provider also read a custom trait (`UITraitDefinition`) carrying the theme. Bridge it from SwiftUI with `UITraitBridgedEnvironmentKey` so `.environment(\.fgTheme, …)` at the app root flows into every token. Call sites do not change. This must stay `nonisolated` (see the SIGTRAP note in `CLAUDE.md`). **Spike this first**: if the bridge does not reach the resolver on iOS 18, fall back to a `FGTheme` value passed through the environment and read by the tokens that need it.
4. **Theme is data.** A `FGTheme` struct (value type, `Codable`, `Sendable`) holds per-appearance values for each role. Kiln/Moss/Indigo are three instances. Adding a fourth is a data change.
5. **Widget:** publish the resolved theme through the existing `publishWidgetAppearance()` path and replace `accentHex` with values derived from the active theme.
6. **Engine boundary:** none of this touches `Engine/` or `Content/`. Theme is a `Services/` + `DesignSystem/` concern, stored in `UserDefaults`.

## 6. Layout changes (only these two, both applied to all themes)

1. **Shorter course cards** (~116pt instead of ~320pt). Reason: the old cards were mostly empty, and the fourth course sat under the tab bar. Now the full menu is visible at once, which serves "one idea per screen".
2. **Opaque tab bar with an outline.** Reason: legibility; nothing bleeds through it.

Additional visual changes that come with the palette: mascots sit on a cream/tinted plate so they never depend on card colour; pills use the plate colour.

## 7. Unlocking Indigo

The app already has **Little Wins** (`Features/LittleWins/`): six lifetime milestones derived from completion history, with no stored counters. Indigo unlocks from one of them. Rules that follow from the parent PRD:

- **Additive only.** Once unlocked, it stays unlocked, forever. Nothing can be lost, revoked or "restored". Derive it from history like Little Wins do, so it cannot drift.
- **No gap language.** Never render "you haven't unlocked…", a progress ring, a percent, or a count-down. If locked themes are shown at all, they are shown quietly (see Q4).
- **Copy in the app's voice.** For example: "You found more than one way to move. There's a new look waiting in You." No streaks, no scores.
- **No medical or attribution claims** in any theme copy.

## 8. Experience

- **Where:** You tab → "Look" (name TBD). Shows Kiln (default) and, once earned, Indigo, each as a small live preview of the Today screen.
- **Appearance:** Moss is what "dark" means for Kiln. Follow the system setting by default. Whether Indigo has a dark form is open (Q3).
- **Moment of unlock:** reuse the Little Win completion moment; add one line and a "Try it" action. Never auto-apply.
- **Switching:** instant crossfade, honouring Reduce Motion.
- **Persistence:** `UserDefaults`, on device only.

## 9. Requirements, testing, accessibility

- Every token pair in every theme × appearance has a Swift Testing case asserting its contrast ratio (4.5:1 text, 3:1 tappable boundary). Adding a theme without passing them fails CI.
- A test that fails if any `Color(light:dark:)` or hex literal appears outside `DesignSystem/`. This is the guard that keeps "not hardcoding" true.
- Snapshot the Today, Chat, You and paywall screens in each theme at default and XXL Dynamic Type.
- Widgets follow the active theme.
- VoiceOver: theme previews have labels; unlocking is announced.
- Unhappy paths: unknown stored theme id falls back to Kiln; a theme the person has not unlocked (for example after a restore) falls back to Kiln without an error.

## 10. Decisions and open questions

**Decided**
1. Indigo unlocks with the **Variety Pack** Little Win (3 different movement types).
2. **Kiln replaces the current clay-studio look** for everyone. No fourth theme to maintain.
3. **Indigo gets a dark form.** Designed (artboard D, §4). Indigo follows the system appearance like the other themes.
4. **Locked themes are hidden** until earned. The picker shows only what is unlocked, so nothing on screen says what you have not done.
5. **Indigo is free** for everyone who unlocks it. No Pro gate.
6. **Card edges are darkened to ≥3:1** in every theme (§4).

**Still open**
7. The red apple mascot (§4).
8. On-device check of the darker Kiln glazes on Chat and You (§12).

## 11. Phasing

1. Token migration of hardcoded literals. No visual change. Ship. **Done in the working tree, uncommitted:** 15 roles added to `FGColor`, every literal in `Features/` moved, and `DesignTokenBoundaryTests` fails on any new one. The widget target keeps its own literals until phase 5.
2. Trait/bridge spike and `FGTheme` type. No visual change. **Spike answered (§13): the bridge works.** **`FGThemeID`, the trait, the bridge and `Color(light:dark:overrides:)` are built** (`DesignSystem/Theme.swift`), with 10 passing tests. Every token is unchanged until a theme overrides it. Deviation from §5 step 4: themes are per-token `overrides` on each colour, not one big `FGTheme` struct of every role, so a theme can be filled in one token at a time. **The theme is on the app root** (`.fgTheme(...)`, backed by `ThemeSettings` in `Services/`), and sheets and full-screen covers are verified in the running app (§13).
3. Kiln + Moss as the new default (replaces current colours). Ship.
4. Indigo, unlock, and the Look picker. Ship.
5. Widget follows theme.

## 12. Risks

- **The bridge spike fails** and the fallback touches more call sites. Mitigated by doing the spike first.
- **Migrating literals silently changes a screen.** Mitigated by phase 1 being pixel-identical and snapshot-tested.
- **Unlocks read as a game.** Mitigated by §7 and by asking whether locked themes show at all.
- **Kiln's glaze colours are darker than today's pastels** and may feel heavier on screens with long lists. Verify on Chat and You before locking values.

## 13. Spike result: the trait bridge (`FeelGoodTests/ThemeTraitBridgeSpikeTests.swift`)

**Answer: yes.** A theme set as a SwiftUI environment value reaches a `UIColor` dynamic provider, with no view edited. Verified on the iOS 27 simulator with prototype code kept in the test target only:

| Check | Result |
|---|---|
| Nothing set resolves the default theme | pass |
| `.environment(\.theme, x)` changes the resolved colour (rendered pixels) | pass |
| A subtree can override its parent (a theme preview inside another theme) | pass |
| `Color.resolve(in:)` sees the bridged value directly | pass |
| UIKit-side `traitOverrides` arrive in the SwiftUI environment (the fallback path) | pass |
| The provider resolves off the main thread | pass |

The shape that worked: a `UITraitDefinition` with `affectsColorAppearance = true`, a `UITraitBridgedEnvironmentKey` reading and writing it, and a `UIColor { traits in … }` provider reading the trait. All types are `nonisolated`, which the project's SIGTRAP rule requires.

**Not proven, so still risks for the real build:**
- Sheets, full-screen covers, popovers and alerts. Environment usually propagates, but a presented UIKit controller may not inherit the trait. Needs a check in the real app.
- `Color`s SwiftUI resolves itself (materials, system tints) do not read the trait and will not change.
- The window-snapshot approach drew black in the test host, so the UIKit-side path was checked through the environment rather than pixels.
- Runs on the iOS 27 simulator; the app's minimum is iOS 18. Confirm on an iOS 18 runtime before relying on it.

### Update: verified in the running app
Setting only the SwiftUI environment at the root **did not reach sheets**. The check-in sheet kept the default page colour while the screen behind it changed. Each sheet or cover is its own hosting controller and takes its trait from the UIKit hierarchy. The unit tests could not see this; a loud test colour in the real app did.

**Fix:** `View.fgTheme(_:)` also sets the trait on the window, so every presented controller inherits it. After the fix, the check-in sheet, the session detail sheet and the full-screen player all followed the theme. One pitfall found on the way: reading `window.traitOverrides.fgTheme` when it was never set is an assertion failure in UIKit; compare `window.traitCollection.fgTheme` instead.

Still unchecked: alerts and system share sheets (separate windows), iOS 18 runtime, and the widget.
