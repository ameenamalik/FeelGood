# FeelGood — iOS Development Guidelines

A daily wellness companion. Product spec lives in [docs/PRD.md](docs/PRD.md) — it
is the source of truth for scope, voice, and architecture decisions.

You are an expert iOS developer using Swift and SwiftUI. Follow these guidelines.

## Code Structure
- Use Swift's latest features and protocol-oriented programming
- Prefer value types (structs) over classes
- Use MVVM architecture with SwiftUI
- Follow Apple's Human Interface Guidelines

## Naming
- camelCase for vars/funcs, PascalCase for types
- Verbs for methods (e.g. fetchData)
- Boolean properties use is/has/should prefixes
- Clear, descriptive names following Apple style

## Swift Best Practices
- Strong type system, proper optionals
- async/await for concurrency
- Result type for errors
- Prefer let over var
- Protocol extensions for shared code

## UI Development
- SwiftUI first, UIKit when necessary
- SF Symbols for icons
- Support dark mode, dynamic type
- SafeArea and GeometryReader for layout
- Handle all screen sizes
- Implement proper keyboard handling

## Performance
- Profile with Instruments
- Lazy load views and images
- Optimize network requests
- Background task handling
- Proper state management
- Memory management

## Data & State
- UserDefaults for preferences
- Clean data flow architecture
- Proper dependency injection
- Handle state restoration

## Security
- Encrypt sensitive data
- Use Keychain securely
- Biometric auth when needed
- App Transport Security
- Input validation
- Never hardcode secrets; the Anthropic key lives in the Cloudflare Worker only

## Testing & Quality
- Test common user flows
- Performance testing
- Error scenarios
- Accessibility testing
- Unhappy paths are mandatory, not optional (PRD §11)

## Essential Features
- Deep linking support
- Push notifications
- Background tasks
- Localization
- Error handling
- Persistent logging and crash reporting from day one

## Development Process
- Use SwiftUI previews
- Git branching strategy
- Code review process
- CI/CD pipeline
- Documentation
- Unit test coverage

## App Store Guidelines
- Privacy descriptions
- App capabilities
- In-app purchases
- Review guidelines
- App thinning
- Proper signing

---

## Project-specific overrides

These supersede the general guidance above where they conflict. Each one is a
decision already made in the PRD, not a preference.

| General guidance | This project | Why |
|---|---|---|
| CoreData for complex models | **SwiftData** | PRD §11. iOS 18 minimum, no legacy store to migrate. |
| `@Published` / `@StateObject` | **`@Observable` / `@State`** | The Observation framework replaces both on iOS 17+. |
| Combine for reactive code | **async/await + Observation** | No Combine dependency; the engine is synchronous and pure. |
| `Features/`, `Core/`, `UI/`, `Resources/` | **`App/`, `Models/`, `Content/`, `Engine/`, `Services/`, `Features/`, `DesignSystem/`** | PRD §11. `Engine/` is deliberately isolated from everything else. |
| XCTest for unit tests | **Swift Testing** (`import Testing`) for unit tests, **XCUITest** for UI | Swift Testing is the default in Xcode 26 and reads better for the engine's table-driven cases. |
| Analytics | **No analytics SDK that collects health data** | PRD §11 privacy. All personal data stays on device. |

### Architecture rules that are not negotiable

- **`Engine/` is pure.** `PlanEngine` is a function of
  `(profile, check-in, history, context) → Menu`. No I/O, no networking, no
  SwiftData, no reads of the system clock — pass `now` in via `PlanContext`.
  This is what makes it exhaustively testable and demo-proof.
- **Non-UI types are `nonisolated`.** The project defaults to
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, which suits views. Engine,
  content, and service types opt out explicitly.
- **Every external call sits behind a protocol** with a fake implementation, so
  the whole app runs offline in tests and previews.
- **Content is data, not code.** Sessions live in `catalog.json`. Adding real
  video classes later is a JSON change, never a rebuild.
- **The LLM never chooses what she does with her body.** It writes framing copy
  only, and the screen renders fully before it is asked.

### Voice and product rules

- No streaks, no guilt mechanics, no rings, no scores, no completion
  percentages, no calorie or weight tracking, no leaderboards.
- **No red anywhere.** Red is the colour of being behind.
- No data visualisation — no charts, rings, or bars.
- Never render a gap. There is no visual language in this app for "you weren't
  here." Returning after time away gets a shorter, warmer menu.
- No medical claims, no diagnosis, no treatment language, in copy or metadata.
- Never state or imply that a real person wrote, taught, endorsed, or reviewed
  a session. `attribution` stays `nil` until sign-off exists in writing.
- Every recommendation says why, in plain language.

### Timestamps

Store UTC, render local. The day boundary comes from the user's calendar,
passed in via `PlanContext` — never from `Calendar.current` inside the engine.
