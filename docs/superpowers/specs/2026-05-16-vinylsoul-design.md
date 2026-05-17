# VinylSoul — Design Spec

## Overview

VinylSoul is an iOS R&B inspiration app. Users input their mood, keywords, and a style tag; DeepSeek API generates lyrics, a virtual album title, a DJ radio monologue, and song recommendations. Results display with a spinning vinyl visual, typewriter lyrics reveal, and lo-fi background music. Generated content persists via SwiftData for browsing history.

**Target:** iOS 18+  
**Language:** Swift  
**Frameworks:** SwiftUI, SwiftData, AVFoundation, UserNotifications  
**Pattern:** MVVM with @Observable

---

## Feature Scope

### v1 (This Spec)
1. Mood slider + keyword input + style tag selection → generate via DeepSeek API
2. Playback page: spinning vinyl, typewriter lyrics, lo-fi beat, DJ TTS
3. History shelf: SwiftData-backed list, view past results, delete
4. API key management via Keychain + settings sheet
5. Haptic feedback on generate + tag/slider interactions
6. Daily inspiration local notification (8PM)

### Future
- Share card (lyrics + album cover image compositing)
- MusicKit integration (Apple Music preview/add)
- Dark-only theme (preferredColorScheme(.dark))

---

## Architecture

### File Structure

```
VinylSoul/
├── App/
│   ├── VinylSoulApp.swift          // @main, TabView, environment
│   └── AppStore.swift              // shared @Observable: currentResult, selectedTab
├── Models/
│   ├── GenerationResult.swift      // Codable: lyrics, albumTitle, djScript, recommendations
│   ├── SongRecommendation.swift    // Codable: title, artist
│   ├── Mood.swift                  // enum: sad, romantic, free
│   └── StyleTag.swift              // enum: slowJam, neoSoul, altRnB
├── Services/
│   ├── DeepSeekService.swift       // actor: URLSession, prompt builder
│   ├── KeychainManager.swift       // API key CRUD
│   ├── AudioManager.swift          // @Observable: lo-fi playback + TTS
│   └── NotificationManager.swift   // Daily trigger scheduling
├── ViewModels/
│   ├── InspirationViewModel.swift  // @Observable: input state, generate action
│   ├── PlaybackViewModel.swift     // @Observable: typewriter state, DJ trigger
│   └── HistoryViewModel.swift      // @Observable: SwiftData query, delete
├── Views/
│   ├── InspirationView.swift       // Tab 1
│   ├── PlaybackView.swift          // Tab 2
│   ├── HistoryView.swift           // Tab 3
│   ├── SettingsView.swift          // Sheet: API key input
│   └── Components/
│       ├── MoodSlider.swift
│       ├── StyleTagChip.swift
│       ├── SpinningVinyl.swift
│       ├── TypewriterText.swift
│       └── HistoryCard.swift
├── Persistence/
│   └── InspirationRecord.swift     // @Model
└── Assets/
    ├── vinyl.png
    └── lofi-beat.mp3
```

### Layer Responsibilities

| Layer | Role | Depends On |
|---|---|---|
| Views | Render UI, delegate actions to VM | ViewModels, AppStore (env) |
| ViewModels | Business logic, state, call services | Services, Models |
| Services | I/O: network, audio, keychain, notifications | System frameworks |
| Models | Pure value types (Codable enums/structs) | Nothing |
| Persistence | SwiftData @Model class | Models (for mapping) |

**Rules:**
- Views own their ViewModel via `@State var viewModel = ...`
- AppStore flows via `.environment(appStore)` — read by tabs, written by InspirationVM
- DeepSeekService is an `actor` for thread safety
- Models are pure Swift types with no framework dependencies
- SwiftData @Model maps from Codable structs at persistence time

---

## Data Flow

```
User Input → InspirationVM.generate()
     │
     ▼
InspirationVM builds prompt(mood, keywords, styleTag)
     │
     ▼
DeepSeekService.send(...) async throws → GenerationResult
     │
     ▼
InspirationVM writes to AppStore ─┬→ selectedTab = 1 (Playback)
                                   └→ inserts InspirationRecord into ModelContext
     │
     ▼
PlaybackView reads AppStore.currentResult
     ├── PlaybackVM starts typewriter Timer
     ├── AudioManager starts lo-fi loop
     └── User taps "电台" → AVSpeechSynthesizer speaks djScript
```

### State Ownership

| State | Owner | Lifetime |
|---|---|---|
| Mood, keywords, style tag | InspirationVM | While on input tab |
| API loading/error | InspirationVM | During request |
| Current result | AppStore | Until next generation |
| Audio playback | AudioManager | While on playback tab |
| Typewriter progress | PlaybackVM | While on playback tab |
| History list | HistoryVM (SwiftData query) | Persistent |
| API key | KeychainManager | Persistent |

---

## Data Models

### GenerationResult (Codable, in-memory)

```swift
struct GenerationResult: Codable {
    let lyrics: String
    let albumTitle: String
    let djScript: String
    let recommendations: [SongRecommendation]
}

struct SongRecommendation: Codable, Identifiable {
    var id: String { "\(title)-\(artist)" }
    let title: String
    let artist: String
}
```

### Mood & StyleTag (enums)

```swift
enum Mood: String, CaseIterable {
    case sad = "忧伤"
    case romantic = "浪漫"
    case free = "洒脱"
}

enum StyleTag: String, CaseIterable {
    case slowJam = "90's Slow Jam"
    case neoSoul = "Neo-Soul"
    case altRnB = "Alternative R&B"
}
```

### InspirationRecord (@Model, persistent)

```swift
@Model
final class InspirationRecord {
    var timestamp: Date
    var lyrics: String
    var albumTitle: String
    var djScript: String
    var recommendationsJSON: String // JSON-encoded [SongRecommendation]
    var moodRaw: String
    var styleTagRaw: String

    init(result: GenerationResult, mood: Mood, style: StyleTag) {
        self.timestamp = .now
        self.lyrics = result.lyrics
        self.albumTitle = result.albumTitle
        self.djScript = result.djScript
        self.recommendationsJSON = (try? JSONEncoder().encode(result.recommendations))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.moodRaw = mood.rawValue
        self.styleTagRaw = style.rawValue
    }
}
```

---

## DeepSeek API Integration

### Endpoint

```
POST https://api.deepseek.com/chat/completions
Authorization: Bearer <key>
Content-Type: application/json
```

### Request Body

```json
{
  "model": "deepseek-chat",
  "messages": [
    {
      "role": "system",
      "content": "你是一位精通R&B文化的作词人和音乐推荐专家。用户会提供心情、关键词和风格。请生成一首R&B歌词（含主歌、副歌），并为它虚构一张专辑名称。同时推荐3首真实存在的、与该情绪匹配的R&B经典歌曲。最后用深夜电台DJ的口吻写一段感性独白，像是在播放这首歌前说的话。所有内容以JSON格式返回，字段：lyrics, album_title, dj_script, recommendations（数组，每项含title和artist）。只输出JSON，不要其他解释。"
    },
    {
      "role": "user",
      "content": "心情：{mood}。关键词：{keywords}。风格：{style}。"
    }
  ]
}
```

### Response Parsing

- Extract `choices[0].message.content` as String
- Strip markdown code fences (` ```json` / ` ``` `) if present
- `JSONDecoder().decode(GenerationResult.self, from: content)`
- Map snake_case to camelCase via `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase`
- On parsing failure: throw `DeepSeekError.parseError`, surface raw content to user as fallback

### Error Handling

| Condition | Behavior |
|---|---|
| No API key set | Show alert: "请先在设置中输入 DeepSeek API Key" |
| HTTP 401 | Show alert: "API Key 无效，请重新设置" |
| Network timeout (30s) | Show alert with retry button |
| JSON parse failure | Show raw text in lyrics area, log error |
| Other HTTP errors | Show alert with status code |

---

## Views & UI

### Theme
- Dark mode forced (`.preferredColorScheme(.dark)`)
- Accent color: warm amber/orange (`Color(hex: "#E8A850")`)
- Lyrics font: serif system font (`.serif` design)
- Overall aesthetic: late-night record store

### Tab 1 — InspirationView (创作)

- **MoodSlider:** Discrete 3-stop slider (not continuous range). Stops labeled "忧伤 🥀" / "浪漫 💜" / "洒脱 🕊️". Maps to `Mood` enum values. Haptic `.rigid` on detent snap.
- **TextField:** Keywords input, placeholder "输入关键词，如：雨夜、末班车...". Single line, return dismisses keyboard.
- **StyleTagChips:** 3 selectable pills in HStack. Haptic `.light` on selection.
- **Generate Button:** Full-width, "生成灵感". Haptic `.heavy` on press. Shows ProgressView + "正在创作中..." while loading. Disabled when loading or no keywords.
- **Settings gear:** Top-right, presents SettingsView sheet.

### Tab 2 — PlaybackView (正在播放)

- **SpinningVinyl:** Record image centered, `rotationEffect(.degrees(isSpinning ? 360 : 0))` with `linear(duration: 8).repeatForever`. Animation starts on appear.
- **TypewriterText:** Lyrics revealed char-by-char via Timer (~50ms/ch). Full text scrollable.
- **Album Title:** Displayed above lyrics, semi-transparent.
- **DJ Button:** "电台" with mic icon. Taps trigger `AVSpeechSynthesizer.speak(djScript)` at rate 0.45, zh-CN voice.
- **Mute Toggle:** Speaker icon toggles lo-fi beat.
- **Empty state:** When `AppStore.currentResult == nil` (e.g., fresh launch before any generation), show a placeholder: "还没有灵感，去创作页生成一首吧 🎧"
- **Lo-fi auto-play:** Starts when view appears, stops on disappear.

### Tab 3 — HistoryView (唱片架)

- **List:** Sorted by timestamp descending.
- **HistoryCard rows:** Album title, date, mood emoji, first 2 lines of lyrics.
- **Tap:** Push to read-only PlaybackView (pre-filled from SwiftData).
- **Long press delete:** Confirmation alert, remove from ModelContext.
- **Empty state:** "还没有灵感唱片，去创作一张吧 🎵"

### SettingsView (Sheet)

- **SecureField:** API key input, masked.
- **Save button:** Writes to Keychain via KeychainManager.
- **Link:** "获取 API Key" → DeepSeek platform URL.
- **Dismiss:** Tap outside or close button.

---

## Audio & Haptics

### AudioManager (@Observable, singleton)

- `playLoFi()` — `AVAudioPlayer` with `lofi-beat.mp3`, `numberOfLoops = -1`, volume 0.3
- `stopLoFi()` — Called on Tab 2 disappear
- `isMuted: Bool` — Toggles volume between 0.0 and 0.3
- `speakDJ(_ script: String)` — `AVSpeechSynthesizer` with `AVSpeechSynthesisVoice(language: "zh-CN")`, rate 0.45, pitch 0.9
- Audio session: `.playback` category, mix with others = false

### Haptics

| Trigger | Style |
|---|---|
| Generate button | `.heavy` |
| Style tag select | `.light` |
| Slider detent snap | `.rigid` |

---

## Notifications

- Request `.alert` authorization on first launch (fail gracefully)
- Schedule daily trigger at 20:00 local: "今天的R&B心情是什么？🎵 打开 VinylSoul，让灵感流淌。"
- Re-schedule when app becomes active (covers settings changes)
- Only deliver if app hasn't been opened that day (check last open date in UserDefaults)

---

## Permissions

| Permission | When | Purpose |
|---|---|---|
| Notifications | First launch | Daily inspiration |
| (No mic, camera, or location) | | |

---

## Testing Strategy

### Unit Tests
- `DeepSeekService`: Mock URLSession, verify request body, verify response parsing (valid JSON, missing fields, markdown-wrapped)
- `InspirationViewModel`: Verify prompt assembly, state transitions (idle → loading → success/error), AppStore write
- `PlaybackViewModel`: Verify typewriter timer produces correct substring at each tick
- `KeychainManager`: Write/read/delete cycle
- Model mapping: `GenerationResult` → `InspirationRecord` round-trip

### Widget Tests
- `InspirationView`: Slider interaction, keyword input, generate button enabled/disabled states
- `StyleTagChip`: Selection/deselection behavior
- `HistoryView`: Empty state, populated list, delete gesture
- `PlaybackView`: Vinyl renders, typewriter text appears, DJ button triggers TTS

### Integration Test
- End-to-end: Input → mock API response → verify result appears in playback view → verify record appears in history

### Excluded
- Live DeepSeek API tests (use mocks)
- Snapshot tests (asset-dependent, low ROI for v1)
