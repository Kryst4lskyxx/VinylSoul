# VinylSoul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an iOS R&B inspiration app with mood input, DeepSeek API generation, animated playback view, and SwiftData history.

**Architecture:** MVVM with @Observable (iOS 18+). 3 tabs (input, playback, history). Shared AppStore for cross-tab state. Actor-based DeepSeekService. SwiftData for persistence.

**Tech Stack:** SwiftUI, SwiftData, AVFoundation, UserNotifications, Keychain (Security framework)

---

### Task 1: Create Xcode Project

**Files:** Create via Xcode New Project wizard

- [ ] **Step 1: Create Xcode project**

In Xcode: File → New → Project → iOS → App
- Name: `VinylSoul`
- Interface: SwiftUI
- Language: Swift
- Check "Use SwiftData"
- Deployment target: iOS 18.0
- Save to `/Users/pig/Desktop/private_workspace/VinylSoul`

- [ ] **Step 2: Configure Info.plist for background audio**

In the project's Info tab, add:
- Key: `Required background modes` → `App plays audio or streams audio/video using AirPlay`

- [ ] **Step 3: Create directory structure**

```bash
cd /Users/pig/Desktop/private_workspace/VinylSoul/VinylSoul
mkdir -p App Models Services ViewModels Views/Components Persistence Assets
```

- [ ] **Step 4: Configure dark mode in VinylSoulApp.swift**

Open the generated `VinylSoulApp.swift` and change to:

```swift
import SwiftUI
import SwiftData

@main
struct VinylSoulApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: InspirationRecord.self)
    }
}
```

- [ ] **Step 5: Commit**

```bash
cd /Users/pig/Desktop/private_workspace/VinylSoul
git init
git add .
git commit -m "chore: scaffold Xcode project with SwiftData and dark mode"
```

---

### Task 2: Model Types

**Files:**
- Create: `VinylSoul/Models/Mood.swift`
- Create: `VinylSoul/Models/StyleTag.swift`
- Create: `VinylSoul/Models/SongRecommendation.swift`
- Create: `VinylSoul/Models/GenerationResult.swift`

- [ ] **Step 1: Write failing test for model encoding/decoding**

Create `VinylSoulTests/Models/GenerationResultTests.swift`:

```swift
import Testing
import Foundation
@testable import VinylSoul

struct GenerationResultTests {

    @Test func decodeValidJSON() throws {
        let json = """
        {
            "lyrics": "Verse one\\nChorus here",
            "album_title": "Midnight Vinyl",
            "dj_script": "Welcome to the show",
            "recommendations": [
                {"title": "Adorn", "artist": "Miguel"},
                {"title": "Untitled", "artist": "D'Angelo"}
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(GenerationResult.self, from: json)

        #expect(result.lyrics == "Verse one\nChorus here")
        #expect(result.albumTitle == "Midnight Vinyl")
        #expect(result.recommendations.count == 2)
        #expect(result.recommendations[0].title == "Adorn")
    }

    @Test func songRecommendationID() {
        let song = SongRecommendation(title: "Blame", artist: "Bryson Tiller")
        #expect(song.id == "Blame-Bryson Tiller")
    }
}
```

In Xcode: File → New → Target → Unit Testing Bundle → name: `VinylSoulTests`. Then add this file. Or if using Swift Testing (Xcode 16+), add to existing test target.

- [ ] **Step 2: Run test to verify failure**

Run: Cmd+U in Xcode
Expected: Build failure — types not defined

- [ ] **Step 3: Create model files**

`VinylSoul/Models/SongRecommendation.swift`:

```swift
import Foundation

struct SongRecommendation: Codable, Identifiable {
    var id: String { "\(title)-\(artist)" }
    let title: String
    let artist: String
}
```

`VinylSoul/Models/Mood.swift`:

```swift
import Foundation

enum Mood: String, CaseIterable {
    case sad = "忧伤"
    case romantic = "浪漫"
    case free = "洒脱"
}
```

`VinylSoul/Models/StyleTag.swift`:

```swift
import Foundation

enum StyleTag: String, CaseIterable {
    case slowJam = "90's Slow Jam"
    case neoSoul = "Neo-Soul"
    case altRnB = "Alternative R&B"
}
```

`VinylSoul/Models/GenerationResult.swift`:

```swift
import Foundation

struct GenerationResult: Codable {
    let lyrics: String
    let albumTitle: String
    let djScript: String
    let recommendations: [SongRecommendation]
}
```

Add all 4 files to the Xcode project target `VinylSoul`.

- [ ] **Step 4: Run test to verify pass**

Run: Cmd+U in Xcode
Expected: All `GenerationResultTests` pass

- [ ] **Step 5: Commit**

```bash
cd /Users/pig/Desktop/private_workspace/VinylSoul
git add VinylSoul/Models/ VinylSoulTests/
git commit -m "feat: add model types — Mood, StyleTag, GenerationResult, SongRecommendation"
```

---

### Task 3: SwiftData Persistence Model

**Files:**
- Create: `VinylSoul/Persistence/InspirationRecord.swift`
- Test: `VinylSoulTests/Persistence/InspirationRecordTests.swift`

- [ ] **Step 1: Write failing test**

`VinylSoulTests/Persistence/InspirationRecordTests.swift`:

```swift
import Testing
import Foundation
@testable import VinylSoul

struct InspirationRecordTests {

    @Test func mapFromGenerationResult() throws {
        let result = GenerationResult(
            lyrics: "Test lyrics",
            albumTitle: "Test Album",
            djScript: "Test DJ",
            recommendations: [
                SongRecommendation(title: "Song 1", artist: "Artist 1")
            ]
        )

        let record = InspirationRecord(result: result, mood: .romantic, style: .slowJam)

        #expect(record.lyrics == "Test lyrics")
        #expect(record.albumTitle == "Test Album")
        #expect(record.moodRaw == "浪漫")
        #expect(record.styleTagRaw == "90's Slow Jam")

        let decoded = try JSONDecoder().decode(
            [SongRecommendation].self,
            from: record.recommendationsJSON.data(using: .utf8)!
        )
        #expect(decoded.count == 1)
        #expect(decoded[0].title == "Song 1")
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run: Cmd+U
Expected: Build failure — `InspirationRecord` not defined

- [ ] **Step 3: Create InspirationRecord**

`VinylSoul/Persistence/InspirationRecord.swift`:

```swift
import Foundation
import SwiftData

@Model
final class InspirationRecord {
    var timestamp: Date
    var lyrics: String
    var albumTitle: String
    var djScript: String
    var recommendationsJSON: String
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

Add file to Xcode target `VinylSoul`.

- [ ] **Step 4: Run test to verify pass**

Run: Cmd+U
Expected: `InspirationRecordTests` pass

- [ ] **Step 5: Commit**

```bash
git add VinylSoul/Persistence/ VinylSoulTests/Persistence/
git commit -m "feat: add SwiftData InspirationRecord with mapping from GenerationResult"
```

---

### Task 4: KeychainManager

**Files:**
- Create: `VinylSoul/Services/KeychainManager.swift`
- Test: `VinylSoulTests/Services/KeychainManagerTests.swift`

- [ ] **Step 1: Write failing test**

`VinylSoulTests/Services/KeychainManagerTests.swift`:

```swift
import Testing
import Foundation
@testable import VinylSoul

struct KeychainManagerTests {
    private let service = "com.vinylsoul.test"
    private let account = "deepseek_api_key"

    @Test func writeReadDeleteCycle() throws {
        let manager = KeychainManager(service: service)

        // Write
        try manager.save(key: "sk-test-12345", account: account)

        // Read
        let key = try manager.read(account: account)
        #expect(key == "sk-test-12345")

        // Delete
        try manager.delete(account: account)

        // Verify deleted
        do {
            _ = try manager.read(account: account)
            Issue.record("Expected error after delete")
        } catch {
            // Expected
        }
    }
}
```

Note: `KeychainManager` uses a `service` parameter for test isolation. The production instance uses a fixed service name.

- [ ] **Step 2: Run test to verify failure**

Run: Cmd+U
Expected: Build failure

- [ ] **Step 3: Create KeychainManager**

`VinylSoul/Services/KeychainManager.swift`:

```swift
import Foundation
import Security

struct KeychainManager {
    let service: String

    init(service: String = "com.vinylsoul") {
        self.service = service
    }

    func save(key: String, account: String) throws {
        guard let data = key.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        // Delete existing item first
        try? delete(account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    func read(account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.unhandledError(status: status)
        }

        return key
    }

    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}

enum KeychainError: Error {
    case encodingFailed
    case unhandledError(status: OSStatus)
}
```

Add to Xcode target `VinylSoul`.

- [ ] **Step 4: Run test to verify pass**

Run: Cmd+U
Expected: `KeychainManagerTests` pass

- [ ] **Step 5: Commit**

```bash
git add VinylSoul/Services/KeychainManager.swift VinylSoulTests/Services/
git commit -m "feat: add KeychainManager for secure API key storage"
```

---

### Task 5: DeepSeekService

**Files:**
- Create: `VinylSoul/Services/DeepSeekService.swift`
- Test: `VinylSoulTests/Services/DeepSeekServiceTests.swift`

- [ ] **Step 1: Write failing test**

`VinylSoulTests/Services/DeepSeekServiceTests.swift`:

```swift
import Testing
import Foundation
@testable import VinylSoul

struct DeepSeekServiceTests {

    @Test func buildsCorrectPrompt() {
        let service = DeepSeekService(apiKey: "test-key")
        let prompt = service.buildUserMessage(
            mood: .romantic,
            keywords: "雨夜, 末班车",
            style: .slowJam
        )
        #expect(prompt.contains("浪漫"))
        #expect(prompt.contains("雨夜, 末班车"))
        #expect(prompt.contains("90's Slow Jam"))
    }

    @Test func parsesValidJSONResponse() throws {
        let service = DeepSeekService(apiKey: "test-key")
        let json = """
        {
            "lyrics": "Verse\\nChorus",
            "album_title": "Test Album",
            "dj_script": "DJ talks",
            "recommendations": [{"title": "Song", "artist": "Artist"}]
        }
        """
        let result = try service.parseResponseContent(json)
        #expect(result.lyrics == "Verse\nChorus")
        #expect(result.albumTitle == "Test Album")
        #expect(result.recommendations.count == 1)
    }

    @Test func parsesMarkdownWrappedJSON() throws {
        let service = DeepSeekService(apiKey: "test-key")
        let markdown = """
        ```json
        {
            "lyrics": "Verse",
            "album_title": "Album",
            "dj_script": "DJ",
            "recommendations": []
        }
        ```
        """
        let result = try service.parseResponseContent(markdown)
        #expect(result.lyrics == "Verse")
    }

    @Test func throwsParseErrorOnInvalidJSON() {
        let service = DeepSeekService(apiKey: "test-key")
        do {
            _ = try service.parseResponseContent("not json at all {")
            Issue.record("Expected parseError")
        } catch let error as DeepSeekError {
            #expect(error == .parseError)
        } catch {
            Issue.record("Unexpected error type")
        }
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run: Cmd+U
Expected: Build failure

- [ ] **Step 3: Create DeepSeekService**

`VinylSoul/Services/DeepSeekService.swift`:

```swift
import Foundation

enum DeepSeekError: Error, Equatable {
    case missingAPIKey
    case parseError
    case httpError(statusCode: Int)
    case networkError(Error)

    static func == (lhs: DeepSeekError, rhs: DeepSeekError) -> Bool {
        switch (lhs, rhs) {
        case (.missingAPIKey, .missingAPIKey): return true
        case (.parseError, .parseError): return true
        case (.httpError(let a), .httpError(let b)): return a == b
        case (.networkError): return false
        default: return false
        }
    }
}

actor DeepSeekService {
    private let apiKey: String
    private let baseURL = "https://api.deepseek.com/chat/completions"
    private let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    private let systemPrompt = """
    你是一位精通R&B文化的作词人和音乐推荐专家。用户会提供心情、关键词和风格。\
    请生成一首R&B歌词（含主歌、副歌），并为它虚构一张专辑名称。\
    同时推荐3首真实存在的、与该情绪匹配的R&B经典歌曲。\
    最后用深夜电台DJ的口吻写一段感性独白，像是在播放这首歌前说的话。\
    所有内容以JSON格式返回，字段：lyrics, album_title, dj_script, \
    recommendations（数组，每项含title和artist）。只输出JSON，不要其他解释。
    """

    func generate(mood: Mood, keywords: String, style: StyleTag) async throws -> GenerationResult {
        let userMessage = buildUserMessage(mood: mood, keywords: keywords, style: style)

        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ]
        ]

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw DeepSeekError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeepSeekError.httpError(statusCode: -1)
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw DeepSeekError.httpError(statusCode: 401)
        default:
            throw DeepSeekError.httpError(statusCode: httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw DeepSeekError.parseError
        }

        return try parseResponseContent(content)
    }

    func buildUserMessage(mood: Mood, keywords: String, style: StyleTag) -> String {
        "心情：\(mood.rawValue)。关键词：\(keywords)。风格：\(style.rawValue)。"
    }

    func parseResponseContent(_ content: String) throws -> GenerationResult {
        var jsonString = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if jsonString.hasPrefix("```json") {
            jsonString = String(jsonString.dropFirst(7))
        }
        if jsonString.hasPrefix("```") {
            jsonString = String(jsonString.dropFirst(3))
        }
        if jsonString.hasSuffix("```") {
            jsonString = String(jsonString.dropLast(3))
        }
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = jsonString.data(using: .utf8) else {
            throw DeepSeekError.parseError
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            return try decoder.decode(GenerationResult.self, from: data)
        } catch {
            throw DeepSeekError.parseError
        }
    }
}
```

Add to Xcode target `VinylSoul`.

- [ ] **Step 4: Run test to verify pass**

Run: Cmd+U
Expected: `DeepSeekServiceTests` pass

- [ ] **Step 5: Commit**

```bash
git add VinylSoul/Services/DeepSeekService.swift VinylSoulTests/Services/
git commit -m "feat: add DeepSeekService actor with prompt builder and response parser"
```

---

### Task 6: AudioManager + NotificationManager

**Files:**
- Create: `VinylSoul/Services/AudioManager.swift`
- Create: `VinylSoul/Services/NotificationManager.swift`

- [ ] **Step 1: Create AudioManager**

`VinylSoul/Services/AudioManager.swift`:

```swift
import Foundation
import AVFoundation

@Observable
final class AudioManager {
    private var loFiPlayer: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()
    var isMuted = false

    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    func playLoFi() {
        guard let url = Bundle.main.url(forResource: "lofi-beat", withExtension: "mp3") else {
            print("lofi-beat.mp3 not found in bundle")
            return
        }
        do {
            loFiPlayer = try AVAudioPlayer(contentsOf: url)
            loFiPlayer?.numberOfLoops = -1
            loFiPlayer?.volume = isMuted ? 0 : 0.3
            loFiPlayer?.play()
        } catch {
            print("Lo-fi playback failed: \(error)")
        }
    }

    func stopLoFi() {
        loFiPlayer?.stop()
    }

    func toggleMute() {
        isMuted.toggle()
        loFiPlayer?.volume = isMuted ? 0 : 0.3
    }

    func speakDJ(_ script: String) {
        let utterance = AVSpeechUtterance(string: script)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.45
        utterance.pitchMultiplier = 0.9
        synthesizer.speak(utterance)
    }
}
```

- [ ] **Step 2: Create NotificationManager**

`VinylSoul/Services/NotificationManager.swift`:

```swift
import Foundation
import UserNotifications

struct NotificationManager {
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                print("Notification auth failed: \(error)")
            }
        }
    }

    func scheduleDailyInspiration() {
        let content = UNMutableNotificationContent()
        content.title = "VinylSoul"
        content.body = "今天的R&B心情是什么？🎵 打开 VinylSoul，让灵感流淌。"
        content.sound = .default

        var components = DateComponents()
        components.hour = 20
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-inspiration",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Schedule failed: \(error)")
            }
        }
    }
}
```

- [ ] **Step 3: Add both files to Xcode target `VinylSoul`**

- [ ] **Step 4: Commit**

```bash
git add VinylSoul/Services/AudioManager.swift VinylSoul/Services/NotificationManager.swift
git commit -m "feat: add AudioManager (lo-fi + TTS) and NotificationManager (daily reminder)"
```

---

### Task 7: AppStore + VinylSoulApp Entry Point

**Files:**
- Create: `VinylSoul/App/AppStore.swift`
- Modify: `VinylSoul/VinylSoulApp.swift`
- Modify: `VinylSoul/ContentView.swift`

- [ ] **Step 1: Create AppStore**

`VinylSoul/App/AppStore.swift`:

```swift
import Foundation
import SwiftUI

@Observable
final class AppStore {
    var currentResult: GenerationResult?
    var selectedTab: Int = 0
    var apiKey: String?
    var hasAPIKey: Bool { apiKey != nil }

    private let keychain = KeychainManager()

    init() {
        self.apiKey = try? keychain.read(account: "deepseek_api_key")
    }

    func saveAPIKey(_ key: String) {
        try? keychain.save(key: key, account: "deepseek_api_key")
        apiKey = key
    }

    func generateResult(_ result: GenerationResult) {
        currentResult = result
        selectedTab = 1
    }
}
```

- [ ] **Step 2: Update VinylSoulApp.swift**

```swift
import SwiftUI
import SwiftData

@main
struct VinylSoulApp: App {
    @State private var appStore = AppStore()
    @State private var audioManager = AudioManager()
    private let notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(appStore)
                .environment(audioManager)
                .onAppear {
                    notificationManager.requestAuthorization()
                    notificationManager.scheduleDailyInspiration()
                }
        }
        .modelContainer(for: InspirationRecord.self)
    }
}
```

- [ ] **Step 3: Replace ContentView with tab structure**

`VinylSoul/ContentView.swift` (replace generated content):

```swift
import SwiftUI

struct ContentView: View {
    @Environment(AppStore.self) private var appStore

    var body: some View {
        TabView(selection: Bindable(appStore).selectedTab) {
            InspirationView()
                .tabItem {
                    Label("创作", systemImage: "pencil.and.outline")
                }
                .tag(0)

            PlaybackView()
                .tabItem {
                    Label("正在播放", systemImage: "record.circle")
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    Label("唱片架", systemImage: "square.stack")
                }
                .tag(2)
        }
        .tint(Color(hex: "#E8A850"))
    }
}
```

Note: `Color(hex:)` extension is defined in Task 10. Add a temporary `Color.accentColor` or define the hex initializer now:

Create `VinylSoul/App/Color+Hex.swift`:

```swift
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
```

If `InspirationView`, `PlaybackView`, `HistoryView` don't exist yet, use placeholder stubs:

```swift
struct InspirationView: View { var body: some View { Text("创作") } }
struct PlaybackView: View { var body: some View { Text("正在播放") } }
struct HistoryView: View { var body: some View { Text("唱片架") } }
```

Replace with real views in their respective tasks.

- [ ] **Step 4: Build and verify tabs render**

Run: Cmd+R in Xcode
Expected: App launches with 3 empty tabs in dark mode

- [ ] **Step 5: Commit**

```bash
git add VinylSoul/App/ VinylSoul/ContentView.swift
git commit -m "feat: add AppStore, tab structure, dark theme"
```

---

### Task 8: InspirationViewModel + PlaybackViewModel + HistoryViewModel

**Files:**
- Create: `VinylSoul/ViewModels/InspirationViewModel.swift`
- Create: `VinylSoul/ViewModels/PlaybackViewModel.swift`
- Create: `VinylSoul/ViewModels/HistoryViewModel.swift`

- [ ] **Step 1: Create InspirationViewModel**

`VinylSoul/ViewModels/InspirationViewModel.swift`:

```swift
import Foundation
import SwiftUI
import SwiftData

@Observable
final class InspirationViewModel {
    var mood: Mood = .romantic
    var keywords: String = ""
    var selectedStyle: StyleTag = .slowJam
    var isLoading = false
    var errorMessage: String?

    var canGenerate: Bool { !keywords.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading }

    func generate(appStore: AppStore, modelContext: ModelContext) {
        guard let apiKey = appStore.apiKey else {
            errorMessage = "请先在设置中输入 DeepSeek API Key"
            return
        }

        isLoading = true
        errorMessage = nil

        let service = DeepSeekService(apiKey: apiKey)
        let capturedMood = mood
        let capturedStyle = selectedStyle

        Task { @MainActor in
            defer { isLoading = false }

            do {
                let result = try await service.generate(
                    mood: capturedMood,
                    keywords: keywords,
                    style: capturedStyle
                )
                appStore.generateResult(result)
                let record = InspirationRecord(result: result, mood: capturedMood, style: capturedStyle)
                modelContext.insert(record)
            } catch let error as DeepSeekError {
                switch error {
                case .missingAPIKey:
                    errorMessage = "请先在设置中输入 DeepSeek API Key"
                case .httpError(let code) where code == 401:
                    errorMessage = "API Key 无效，请重新设置"
                case .httpError(let code):
                    errorMessage = "请求失败 (HTTP \(code))"
                case .parseError:
                    errorMessage = "响应解析失败，请重试"
                case .networkError:
                    errorMessage = "网络连接失败，请检查网络后重试"
                }
            } catch {
                errorMessage = "未知错误：\(error.localizedDescription)"
            }
        }
    }
}
```

- [ ] **Step 2: Create PlaybackViewModel**

`VinylSoul/ViewModels/PlaybackViewModel.swift`:

```swift
import Foundation
import SwiftUI

@Observable
final class PlaybackViewModel {
    var displayedText: String = ""
    var isComplete = false

    private var timer: Timer?
    private var fullText: String = ""
    private var currentIndex: Int = 0

    func startTypewriter(text: String, interval: TimeInterval = 0.05) {
        reset()
        fullText = text
        currentIndex = 0

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self else { return }
            guard self.currentIndex < self.fullText.count else {
                timer.invalidate()
                self.timer = nil
                self.isComplete = true
                return
            }
            let idx = self.fullText.index(self.fullText.startIndex, offsetBy: self.currentIndex)
            self.displayedText = String(self.fullText[..<self.fullText.index(after: idx)])
            self.currentIndex += 1
        }
    }

    func skipToEnd() {
        timer?.invalidate()
        timer = nil
        displayedText = fullText
        isComplete = true
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        displayedText = ""
        isComplete = false
        currentIndex = 0
    }
}
```

- [ ] **Step 3: Create HistoryViewModel**

`VinylSoul/ViewModels/HistoryViewModel.swift`:

```swift
import Foundation
import SwiftUI
import SwiftData

@Observable
final class HistoryViewModel {
    var records: [InspirationRecord] = []

    func fetch(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<InspirationRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        do {
            records = try modelContext.fetch(descriptor)
        } catch {
            print("Fetch failed: \(error)")
        }
    }

    func delete(_ record: InspirationRecord, modelContext: ModelContext) {
        modelContext.delete(record)
        fetch(modelContext: modelContext)
    }
}
```

Add all 3 files to Xcode target `VinylSoul`.

- [ ] **Step 4: Commit**

```bash
git add VinylSoul/ViewModels/
git commit -m "feat: add InspirationVM, PlaybackVM, HistoryVM"
```

---

### Task 9: Component Views

**Files:**
- Create: `VinylSoul/Views/Components/MoodSlider.swift`
- Create: `VinylSoul/Views/Components/StyleTagChip.swift`
- Create: `VinylSoul/Views/Components/SpinningVinyl.swift`
- Create: `VinylSoul/Views/Components/TypewriterText.swift`
- Create: `VinylSoul/Views/Components/HistoryCard.swift`

- [ ] **Step 1: Create MoodSlider**

`VinylSoul/Views/Components/MoodSlider.swift`:

```swift
import SwiftUI

struct MoodSlider: View {
    @Binding var mood: Mood

    private let moods = Mood.allCases
    private let emojis: [Mood: String] = [
        .sad: "🥀",
        .romantic: "💜",
        .free: "🕊️"
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("今天的心情")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                ForEach(moods, id: \.self) { m in
                    VStack(spacing: 8) {
                        Text(emojis[m] ?? "")
                            .font(.largeTitle)
                            .opacity(mood == m ? 1 : 0.3)
                            .scaleEffect(mood == m ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: mood)

                        Text(m.rawValue)
                            .font(.caption)
                            .foregroundStyle(mood == m ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        mood = m
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
```

- [ ] **Step 2: Create StyleTagChip**

`VinylSoul/Views/Components/StyleTagChip.swift`:

```swift
import SwiftUI

struct StyleTagChip: View {
    let style: StyleTag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(style.rawValue)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: "#E8A850") : Color(.systemGray6))
                .foregroundStyle(isSelected ? .black : .primary)
                .clipShape(Capsule())
        }
    }
}
```

- [ ] **Step 3: Create SpinningVinyl**

`VinylSoul/Views/Components/SpinningVinyl.swift`:

```swift
import SwiftUI

struct SpinningVinyl: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(.black)
                .frame(width: 220, height: 220)
                .shadow(color: .black.opacity(0.5), radius: 20)

            Circle()
                .stroke(Color(.systemGray5), lineWidth: 1)
                .frame(width: 200, height: 200)

            ForEach(0..<8) { i in
                Circle()
                    .stroke(Color(.systemGray6).opacity(0.3), lineWidth: 0.5)
                    .frame(width: CGFloat(200 - i * 25), height: CGFloat(200 - i * 25))
            }

            Circle()
                .fill(Color(hex: "#E8A850"))
                .frame(width: 50, height: 50)

            Circle()
                .fill(.black)
                .frame(width: 8, height: 8)
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
```

- [ ] **Step 4: Create TypewriterText**

`VinylSoul/Views/Components/TypewriterText.swift`:

```swift
import SwiftUI

struct TypewriterText: View {
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .font(.system(.body, design: .serif))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}
```

- [ ] **Step 5: Create HistoryCard**

`VinylSoul/Views/Components/HistoryCard.swift`:

```swift
import SwiftUI

struct HistoryCard: View {
    let record: InspirationRecord

    private var moodEmoji: String {
        switch record.moodRaw {
        case "忧伤": return "🥀"
        case "浪漫": return "💜"
        case "洒脱": return "🕊️"
        default: return "🎵"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.albumTitle)
                    .font(.headline)
                    .foregroundStyle(Color(hex: "#E8A850"))
                Spacer()
                Text(moodEmoji)
                    .font(.title3)
            }

            Text(record.styleTagRaw)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(record.lyrics)
                .font(.system(.caption, design: .serif))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(record.timestamp, style: .date)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

Add all 5 files to Xcode target `VinylSoul`.

- [ ] **Step 6: Commit**

```bash
git add VinylSoul/Views/Components/
git commit -m "feat: add component views — MoodSlider, StyleTagChip, SpinningVinyl, TypewriterText, HistoryCard"
```

---

### Task 10: InspirationView

**Files:**
- Create: `VinylSoul/Views/InspirationView.swift`

- [ ] **Step 1: Create InspirationView**

`VinylSoul/Views/InspirationView.swift`:

```swift
import SwiftUI

struct InspirationView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = InspirationViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                MoodSlider(mood: $viewModel.mood)

                VStack(alignment: .leading, spacing: 8) {
                    Text("关键词")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    TextField("输入关键词，如：雨夜、末班车...",
                              text: $viewModel.keywords)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemGray6).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("风格")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        ForEach(StyleTag.allCases, id: \.self) { style in
                            StyleTagChip(
                                style: style,
                                isSelected: viewModel.selectedStyle == style
                            ) {
                                viewModel.selectedStyle = style
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    viewModel.generate(appStore: appStore, modelContext: modelContext)
                }) {
                    HStack(spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.black)
                        }
                        Text(viewModel.isLoading ? "正在创作中..." : "生成灵感")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.canGenerate
                        ? Color(hex: "#E8A850")
                        : Color(.systemGray4))
                    .foregroundStyle(viewModel.canGenerate ? .black : .gray)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!viewModel.canGenerate)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("VinylSoul")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color(hex: "#E8A850"))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("提示", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("确定") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
```

Replace the placeholder `InspirationView` stub in `ContentView.swift` or wherever it was defined. If the placeholder is in `ContentView.swift`, remove it — the struct above in its own file will be picked up.

Add file to Xcode target `VinylSoul`.

- [ ] **Step 2: Build and verify compilation**

Run: Cmd+B
Expected: Build succeeds (PlaybackView and HistoryView still stubs from Task 7)

- [ ] **Step 3: Commit**

```bash
git add VinylSoul/Views/InspirationView.swift
git commit -m "feat: implement InspirationView with mood slider, keywords, style tags, and generate"
```

---

### Task 11: SettingsView

**Files:**
- Create: `VinylSoul/Views/SettingsView.swift`

- [ ] **Step 1: Create SettingsView**

`VinylSoul/Views/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var appStore
    @State private var apiKeyInput: String = ""
    @State private var showSaved = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("请输入 API Key", text: $apiKeyInput)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("DeepSeek API Key")
                } footer: {
                    Text("API Key 将安全存储在系统钥匙串中")
                }

                Section {
                    Button("保存") {
                        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        appStore.saveAPIKey(trimmed)
                        showSaved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
                }

                Section {
                    Link("获取 API Key →",
                         destination: URL(string: "https://platform.deepseek.com/api_keys")!)
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .alert("已保存", isPresented: $showSaved) {
                Button("好") { }
            } message: {
                Text("API Key 已安全存储")
            }
            .onAppear {
                apiKeyInput = appStore.apiKey ?? ""
            }
        }
    }
}
```

Add to Xcode target `VinylSoul`.

- [ ] **Step 2: Build and verify**

Run: Cmd+B
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add VinylSoul/Views/SettingsView.swift
git commit -m "feat: add SettingsView with Keychain-backed API key input"
```

---

### Task 12: PlaybackView

**Files:**
- Create: `VinylSoul/Views/PlaybackView.swift`

- [ ] **Step 1: Create PlaybackView**

`VinylSoul/Views/PlaybackView.swift`:

```swift
import SwiftUI

struct PlaybackView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(AudioManager.self) private var audioManager
    @State private var viewModel = PlaybackViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if let result = appStore.currentResult {
                    VStack(spacing: 24) {
                        SpinningVinyl()
                            .padding(.top, 40)

                        Text(result.albumTitle)
                            .font(.title2.weight(.medium))
                            .foregroundStyle(Color(hex: "#E8A850"))

                        TypewriterText(text: viewModel.displayedText)
                            .frame(maxHeight: 300)
                            .onAppear {
                                viewModel.startTypewriter(text: result.lyrics)
                            }
                            .onDisappear {
                                viewModel.reset()
                            }
                            .onTapGesture {
                                viewModel.skipToEnd()
                            }

                        HStack(spacing: 40) {
                            Button(action: {
                                audioManager.speakDJ(result.djScript)
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "radio")
                                        .font(.title2)
                                    Text("电台")
                                        .font(.caption)
                                }
                                .foregroundStyle(Color(hex: "#E8A850"))
                            }

                            Button(action: {
                                audioManager.toggleMute()
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: audioManager.isMuted
                                        ? "speaker.slash"
                                        : "speaker.wave.2")
                                        .font(.title2)
                                    Text(audioManager.isMuted ? "静音" : "音乐")
                                        .font(.caption)
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("还没有灵感，去创作页生成一首吧 🎧")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("正在播放")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            audioManager.playLoFi()
        }
        .onDisappear {
            audioManager.stopLoFi()
        }
    }
}
```

Replace the placeholder `PlaybackView` in the project with this file. Add to Xcode target `VinylSoul`.

- [ ] **Step 2: Build and verify**

Run: Cmd+B
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add VinylSoul/Views/PlaybackView.swift
git commit -m "feat: implement PlaybackView with spinning vinyl, typewriter lyrics, DJ TTS, and lo-fi"
```

---

### Task 13: HistoryView

**Files:**
- Create: `VinylSoul/Views/HistoryView.swift`

- [ ] **Step 1: Create HistoryView**

`VinylSoul/Views/HistoryView.swift`:

```swift
import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.records.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "square.stack")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("还没有灵感唱片，去创作一张吧 🎵")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        ForEach(viewModel.records) { record in
                            NavigationLink {
                                PastPlaybackView(record: record)
                            } label: {
                                HistoryCard(record: record)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.delete(record, modelContext: modelContext)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.delete(viewModel.records[index], modelContext: modelContext)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("唱片架")
            .onAppear {
                viewModel.fetch(modelContext: modelContext)
            }
        }
    }
}

struct PastPlaybackView: View {
    let record: InspirationRecord
    @Environment(AudioManager.self) private var audioManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SpinningVinyl()
                    .padding(.top, 40)

                Text(record.albumTitle)
                    .font(.title2.weight(.medium))
                    .foregroundStyle(Color(hex: "#E8A850"))

                Text(record.lyrics)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                Button(action: {
                    audioManager.speakDJ(record.djScript)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "radio")
                            .font(.title2)
                        Text("电台")
                            .font(.caption)
                    }
                    .foregroundStyle(Color(hex: "#E8A850"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("推荐歌曲")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    if let data = record.recommendationsJSON.data(using: .utf8),
                       let songs = try? JSONDecoder().decode([SongRecommendation].self, from: data) {
                        ForEach(songs) { song in
                            HStack {
                                Text(song.title)
                                    .fontWeight(.medium)
                                Text(song.artist)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(record.albumTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            audioManager.playLoFi()
        }
        .onDisappear {
            audioManager.stopLoFi()
        }
    }
}
```

Replace the placeholder `HistoryView` with this file. Add to Xcode target `VinylSoul`.

- [ ] **Step 2: Build and verify**

Run: Cmd+B
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add VinylSoul/Views/HistoryView.swift
git commit -m "feat: implement HistoryView with SwiftData list, empty state, and past playback"
```

---

### Task 14: Add Assets + Final Wiring

**Files:**
- Create/Add: `VinylSoul/Assets/vinyl.png` (placeholder)
- Create/Add: `VinylSoul/Assets/lofi-beat.mp3` (placeholder)
- Modify: `VinylSoul/App/VinylSoulApp.swift` (notification on become active)
- Modify: `VinylSoul/ContentView.swift` (verify all stubs replaced)

- [ ] **Step 1: Add placeholder vinyl image**

The `SpinningVinyl` component renders programmatically with SwiftUI shapes, so we don't strictly need a `vinyl.png`. If you have a vinyl record image, add it to `Assets.xcassets` via Xcode. For now, the programmatic rendering in SpinningVinyl suffices.

- [ ] **Step 2: Add lo-fi beat audio file**

Find a royalty-free lo-fi R&B loop from a source like Pixabay (pixabay.com/music) and add it to the Xcode project:
- File name: `lofi-beat.mp3`
- Add to target: `VinylSoul`
- Place in `VinylSoul/Assets/`

Until the real file is added, AudioManager will log "lofi-beat.mp3 not found" but won't crash.

- [ ] **Step 3: Add notification re-schedule on app become active**

Update `VinylSoul/VinylSoulApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct VinylSoulApp: App {
    @State private var appStore = AppStore()
    @State private var audioManager = AudioManager()

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environment(appStore)
                .environment(audioManager)
        }
        .modelContainer(for: InspirationRecord.self)
    }
}

struct AppRoot: View {
    @Environment(\.scenePhase) private var scenePhase
    private let notificationManager = NotificationManager()

    var body: some View {
        ContentView()
            .preferredColorScheme(.dark)
            .onAppear {
                notificationManager.requestAuthorization()
                notificationManager.scheduleDailyInspiration()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    notificationManager.scheduleDailyInspiration()
                }
            }
    }
}
```

- [ ] **Step 4: Remove all placeholder view stubs**

Ensure no placeholder stubs (empty `Text("创作")` etc.) remain in `ContentView.swift`. The standalone files are the canonical views.

- [ ] **Step 5: Build and run full app**

Run: Cmd+R
Expected: App launches with all 3 tabs, dark theme, amber accents

- [ ] **Step 6: Commit**

```bash
git add VinylSoul/Assets/ VinylSoul/App/VinylSoulApp.swift
git commit -m "feat: add assets, notification re-schedule, wire up full app"
```

---

### Task 15: Write Widget Tests (UI Tests)

**Files:**
- Create: `VinylSoulUITests/VinylSoulUITests.swift`
- Create: `VinylSoulUITests/InspirationViewTests.swift`

Note: Requires a `VinylSoulUITests` target in Xcode (File → New → Target → UI Testing Bundle).

- [ ] **Step 1: Create UI test target if not present**

In Xcode: File → New → Target → iOS → UI Testing Bundle → name: `VinylSoulUITests`

- [ ] **Step 2: Create base UI test**

`VinylSoulUITests/InspirationViewTests.swift`:

```swift
import XCTest

final class InspirationViewTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testMoodSelection() throws {
        let romanticButton = app.staticTexts["浪漫"]
        XCTAssertTrue(romanticButton.exists)
        romanticButton.tap()
    }

    func testKeywordInput() throws {
        let textField = app.textFields["输入关键词，如：雨夜、末班车..."]
        XCTAssertTrue(textField.exists)
        textField.tap()
        textField.typeText("雨夜, 末班车")
    }

    func testGenerateButtonDisabledWhenEmpty() throws {
        let button = app.buttons["生成灵感"]
        XCTAssertTrue(button.exists)
        // Button should be disabled with empty keywords
        XCTAssertFalse(button.isEnabled)
    }

    func testTabNavigation() throws {
        app.tabBars.buttons["唱片架"].tap()
        XCTAssertTrue(app.staticTexts["唱片架"].exists)

        app.tabBars.buttons["创作"].tap()
        XCTAssertTrue(app.staticTexts["VinylSoul"].exists)

        app.tabBars.buttons["正在播放"].tap()
        XCTAssertTrue(app.staticTexts["还没有灵感"].exists)
    }
}
```

- [ ] **Step 3: Run UI tests**

Run: Cmd+U (or select the UI test scheme)
Expected: Tests that don't require API key pass (navigation, input)

- [ ] **Step 4: Commit**

```bash
git add VinylSoulUITests/
git commit -m "test: add UI tests for InspirationView and tab navigation"
```

---

## Verification Checklist

Before marking the implementation complete, verify:

- [ ] App launches in dark mode with amber accent
- [ ] Tab 1: mood selector, keyword input, style chips all interactive
- [ ] Generate button disabled with empty keywords, enabled with text
- [ ] Settings sheet opens, API key saves to Keychain, persists across launches
- [ ] Generate calls DeepSeek API, switches to Tab 2 on success
- [ ] Tab 2 shows spinning vinyl, typewriter lyrics, album title
- [ ] DJ button speaks text, mute toggles lo-fi
- [ ] Empty state shows when no result in Tab 2
- [ ] Tab 3 lists generated records, tap to re-view, long press to delete
- [ ] Empty state shows when no records in Tab 3
- [ ] Haptic fires on generate (.heavy), tag select (.light), mood change (.rigid)
- [ ] Daily notification scheduled at 8PM
- [ ] All tests pass (Cmd+U)
