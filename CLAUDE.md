# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

This is an Xcode project. All commands run from the `.xcodeproj` directory.

```bash
# Build
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul build

# Run all tests (unit + UI)
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul test

# Run a single test
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -only-testing:VinylSoulTests/GenerationResultTests test

# Run tests on a specific device
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

No linter is configured. Swift compiler warnings serve as the lint baseline.

## Architecture

**Pattern:** MVVM with `@Observable` (iOS 18+). No Combine, no RxSwift.

**Three layers:**

| Layer | Convention | Example |
|-------|-----------|---------|
| Models | Pure value types, `Codable` structs/enums | `GenerationResult`, `Mood`, `StyleTag` |
| Services | `actor` for network, `@Observable` for audio, plain struct for notifications | `DeepSeekService`, `AudioManager`, `KeychainManager` |
| ViewModels | `@Observable` class, one per major screen | `InspirationViewModel`, `PlaybackViewModel` |

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

## DeepSeek API

- Endpoint: `POST https://api.deepseek.com/chat/completions`
- Model: `deepseek-chat`
- `DeepSeekService` is an `actor` — all calls are `async throws`
- Response flows through `parseResponseContent()` which strips markdown fences, then `JSONDecoder` with `.convertFromSnakeCase`
- Raw response is never surfaced to the user — only parsed `GenerationResult` or a mapped error message
