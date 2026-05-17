# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

This is an Xcode project. All commands run from the `.xcodeproj` directory.

```bash
# Regenerate project after adding/removing files (REQUIRED, then re-add UIBackgroundModes)
xcodegen generate

# Build (use a concrete simulator, not 'Any iOS Simulator Device')
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run all tests (unit + UI)
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 17' test

# Run a single test
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -only-testing:VinylSoulTests/GenerationResultTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

**Important:** `xcodegen generate` wipes `UIBackgroundModes` from `Info.plist`. After every generation, re-add it:
```xml
<key>UIBackgroundModes</key>
<array><string>audio</string></array>
```

No linter is configured. Swift compiler warnings serve as the lint baseline.

## Architecture

**Pattern:** MVVM with `@Observable` (iOS 18+). No Combine, no RxSwift.

**Three layers:**

| Layer | Convention | Example |
|-------|-----------|---------|
| Models | Pure value types, `Codable` structs/enums | `GenerationResult`, `Mood`, `StyleTag`, `SongRecommendation` |
| Services | `actor` for network, `@MainActor @Observable` for UI-bound state, plain struct for stateless | `DeepSeekService`, `AudioManager`, `MusicService`, `KeychainManager`, `NotificationManager` |
| ViewModels | `@Observable` class, one per major screen | `InspirationViewModel`, `PlaybackViewModel`, `HistoryViewModel` |

**Cross-cutting state** lives in `AppStore` (`@Observable`), injected via `.environment()`. It holds `currentResult`, `selectedTab`, and the API key. When a generation completes, `AppStore.generateResult(_:)` sets the result and programmatically switches to tab 1 (Playback).

**SwiftData** is used only for persistence. `InspirationRecord` is the sole `@Model`. In-memory types (`GenerationResult`) are never stored directly — they map to `InspirationRecord` at persist time. The `ModelContainer` is configured in `VinylSoulApp`.

**TabView** in `ContentView` uses `Bindable(appStore).selectedTab` for programmatic tab switching after generation.

## Key Conventions

- **Dark mode only** — `.preferredColorScheme(.dark)` is forced in `AppRoot`. No light mode support.
- **UI strings are Chinese** — all user-facing text is in Chinese. The system prompt sent to DeepSeek is also in Chinese.
- **API key via Keychain** — `KeychainManager` wraps the Security framework. Never store API keys in UserDefaults or plists.
- **Haptics at interaction points** — `.heavy` on generate, `.light` on style tag select, `.rigid` on mood change. Use `UIImpactFeedbackGenerator` directly, no abstraction.
- **Lo-fi audio** is optional — `AudioManager.playLoFi()` silently logs if `lofi-beat.mp3` is not in the bundle. The app works without it.
- **DeepSeek response parsing** handles markdown-wrapped JSON (```json fences) since the model sometimes wraps its output.
- **Swift 6 strict concurrency** — all `@Observable` services bound to the UI must be `@MainActor`. Network actors remain non-isolated where possible (e.g., `nonisolated` parsing helpers).

## Daily Notification

`NotificationManager` is a plain struct with no state. Flow:

- `requestAuthorization()` — called once on first `.onAppear`
- `scheduleDailyInspiration()` — sets a repeating 8PM `UNCalendarNotificationTrigger`, guarded by `wasOpenedToday()` to skip if user already engaged
- `markAppOpened()` — saves today's date to UserDefaults, cancels any pending notification
- `AppRoot` calls `markAppOpened()` on `.active` and `scheduleDailyInspiration()` on `.background`

## Share Card

`ShareCardView` is a static 400×400 SwiftUI view designed for `ImageRenderer` capture. It composites:
- Dark `#0d0d0d` background with translucent amber vinyl circles
- Album title (amber serif bold), lyrics excerpt (first 6 lines, white serif)
- Optional mood/style capsule chips (from `InspirationRecord`)
- "VinylSoul" branding watermark

`ShareCardRenderer.render()` is a `@MainActor` static helper that creates a `ShareCardView`, feeds it to `ImageRenderer` at 3× scale, and returns a `UIImage`. Present via `ShareSheet` (`UIActivityViewController` wrapper).

Share button appears in both `PlaybackView` (current result, no mood/style) and `PastPlaybackView` (history detail, includes mood/style from record).

## MusicKit Integration

`MusicService` is `@MainActor @Observable` — Apple Music catalog search + preview playback:

- `searchSong(title:artist:)` — `MusicCatalogSearchRequest` against Apple Music catalog, returns `MusicKit.Song?`
- `togglePreview(for:)` — plays/stop 30s preview via `ApplicationMusicPlayer.shared`
- `playingSongID` / `isPlaying` — tracks which preview is active

`RecommendationRow` is a view component that displays one `SongRecommendation`:
- On `.task {}`, searches Apple Music catalog for the song
- Shows `AsyncImage` album art thumbnail (44×44, rounded 6pt) if found, or a music note placeholder
- Amber play/stop button toggles preview playback
- Falls back gracefully to text-only when song not found in catalog

No `MusicAuthorization` required for catalog search or preview playback. Only library access needs it.

PlaybackView recommendations (previously missing) now appear in a section below the control buttons. PastPlaybackView recommendations upgraded from plain text to rich rows.

## DeepSeek API

- Endpoint: `POST https://api.deepseek.com/chat/completions`
- Model: `deepseek-chat`
- `DeepSeekService` is an `actor` — all calls are `async throws`
- Response flows through `parseResponseContent()` which strips markdown fences, then `JSONDecoder` with `.convertFromSnakeCase`
- Raw response is never surfaced to the user — only parsed `GenerationResult` or a mapped error message
