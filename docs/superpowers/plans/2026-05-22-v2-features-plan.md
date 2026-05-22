# VinylSoul v2 功能增强 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add search, favorites, stats dashboard, Widget, Siri/Shortcuts, Quick Actions, multi-template share cards, and platform-adapted sharing to VinylSoul.

**Architecture:** Extend existing MVVM + `@Observable` pattern. New `HistoryViewModel` computed properties for search/filter/stats. New `StatsView`, Widget Extension target, `AppIntents` file for Siri/Shortcuts. Share card gains template/config parameters. App Group enables Widget to read SwiftData.

**Tech Stack:** SwiftUI, SwiftData, WidgetKit, AppIntents, Swift Charts, UIKit interop (ImageRenderer, AppDelegate adaptor)

---

### Phase 1: Data Model Foundation

### Task 1: Add `isFavorite` to `InspirationRecord`

**Files:**
- Modify: `VinylSoul/Persistence/InspirationRecord.swift`

- [ ] **Step 1: Add `isFavorite` property with default**

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
    var isFavorite: Bool = false

    init(result: GenerationResult, mood: Mood, style: StyleTag) {
        self.timestamp = .now
        self.lyrics = result.lyrics
        self.albumTitle = result.albumTitle
        self.djScript = result.djScript
        self.recommendationsJSON = (try? JSONEncoder().encode(result.recommendations))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.moodRaw = mood.rawValue
        self.styleTagRaw = style.rawValue
        self.isFavorite = false
    }
}
```

- [ ] **Step 2: Build to verify no compilation errors**

```bash
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add VinylSoul/Persistence/InspirationRecord.swift
git commit -m "feat: add isFavorite property to InspirationRecord"
```

---

### Task 2: Add share and stats model types

**Files:**
- Create: `VinylSoul/Models/ShareTypes.swift`
- Create: `VinylSoul/Models/StatsOverview.swift`

- [ ] **Step 1: Create `ShareTypes.swift`**

```swift
import Foundation

enum ShareCardTemplate: String, CaseIterable {
    case classicVinyl
    case minimalText
    case retroWarm

    var displayName: String {
        switch self {
        case .classicVinyl: return "经典黑胶"
        case .minimalText: return "极简文字"
        case .retroWarm: return "复古暖调"
        }
    }
}

enum AccentColor: String, CaseIterable {
    case amber
    case white
    case warm

    var hex: String {
        switch self {
        case .amber: return "#E8A850"
        case .white: return "#FFFFFF"
        case .warm:  return "#E89040"
        }
    }
}

struct ShareCardConfig {
    var template: ShareCardTemplate = .classicVinyl
    var showAlbumTitle: Bool = true
    var showLyrics: Bool = true
    var accentColor: AccentColor = .amber
}

enum SharePlatform: String, CaseIterable {
    case generic
    case wechatMoment
    case instagramStory

    var displayName: String {
        switch self {
        case .generic:        return "通用"
        case .wechatMoment:   return "微信朋友圈"
        case .instagramStory: return "Instagram Story"
        }
    }
}
```

- [ ] **Step 2: Create `StatsOverview.swift`**

```swift
import Foundation

struct StatsOverview {
    let totalGenerations: Int
    let monthlyGenerations: Int
    let topStyle: StyleTag?
    let topMood: Mood?
    let styleDistribution: [StyleTag: Int]
    let moodDistribution: [Mood: Int]
    let recentTimeline: [(date: Date, count: Int)]

    static func from(_ records: [InspirationRecord]) -> StatsOverview {
        let total = records.count
        let calendar = Calendar.current
        let thisMonth = calendar.component(.month, from: Date())
        let thisYear = calendar.component(.year, from: Date())

        let monthly = records.filter {
            let m = calendar.component(.month, from: $0.timestamp)
            let y = calendar.component(.year, from: $0.timestamp)
            return m == thisMonth && y == thisYear
        }

        var styleDist: [StyleTag: Int] = [:]
        var moodDist: [Mood: Int] = [:]
        for r in records {
            if let style = StyleTag(rawValue: r.styleTagRaw) {
                styleDist[style, default: 0] += 1
            }
            if let mood = Mood(rawValue: r.moodRaw) {
                moodDist[mood, default: 0] += 1
            }
        }

        let topStyle = styleDist.max(by: { $0.value < $1.value })?.key
        let topMood = moodDist.max(by: { $0.value < $1.value })?.key

        var timeline: [(Date, Int)] = []
        if let range = calendar.range(of: .day, in: .month, for: Date()) {
            for day in range {
                var comps = calendar.dateComponents([.year, .month], from: Date())
                comps.day = day
                if let date = calendar.date(from: comps) {
                    let count = monthly.filter {
                        calendar.isDate($0.timestamp, inSameDayAs: date)
                    }.count
                    timeline.append((date, count))
                }
            }
        }

        return StatsOverview(
            totalGenerations: total,
            monthlyGenerations: monthly.count,
            topStyle: topStyle,
            topMood: topMood,
            styleDistribution: styleDist,
            moodDistribution: moodDist,
            recentTimeline: timeline
        )
    }
}
```

- [ ] **Step 3: Build to verify**

```bash
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add VinylSoul/Models/ShareTypes.swift VinylSoul/Models/StatsOverview.swift
git commit -m "feat: add ShareCardTemplate, ShareCardConfig, StatsOverview model types"
```

---

### Phase 2: History & Data Features

### Task 3: Add search, filter, favorite, and stats logic to HistoryViewModel

**Files:**
- Modify: `VinylSoul/ViewModels/HistoryViewModel.swift`

- [ ] **Step 1: Replace HistoryViewModel with full implementation**

```swift
import Foundation
import SwiftUI
import SwiftData

@Observable
final class HistoryViewModel {
    var records: [InspirationRecord] = []
    var searchText: String = ""
    var selectedMoodFilters: Set<String> = []
    var selectedStyleFilters: Set<String> = []
    var filterMode: FilterMode = .all

    enum FilterMode: String, CaseIterable {
        case all = "全部"
        case favorites = "收藏"
        case recent = "最近"
    }

    var filteredRecords: [InspirationRecord] {
        var result = records

        if filterMode == .favorites {
            result = result.filter { $0.isFavorite }
        }

        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.albumTitle.lowercased().contains(query)
                || $0.lyrics.lowercased().contains(query)
            }
        }

        if !selectedMoodFilters.isEmpty {
            result = result.filter { selectedMoodFilters.contains($0.moodRaw) }
        }

        if !selectedStyleFilters.isEmpty {
            result = result.filter { selectedStyleFilters.contains($0.styleTagRaw) }
        }

        if filterMode == .recent {
            result.sort { $0.timestamp > $1.timestamp }
        }

        return result
    }

    var moodFilterOptions: [String] { Mood.allCases.map(\.rawValue) }
    var styleFilterOptions: [String] { StyleTag.allCases.map(\.rawValue) }

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

    func toggleFavorite(_ record: InspirationRecord, modelContext: ModelContext) {
        record.isFavorite.toggle()
        try? modelContext.save()
    }

    func hasActiveFilters: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
        || !selectedMoodFilters.isEmpty
        || !selectedStyleFilters.isEmpty
        || filterMode != .all
    }

    func clearAllFilters() {
        searchText = ""
        selectedMoodFilters = []
        selectedStyleFilters = []
        filterMode = .all
    }

    func statsOverview() -> StatsOverview {
        StatsOverview.from(records)
    }

    func toggleMoodFilter(_ rawValue: String) {
        if selectedMoodFilters.contains(rawValue) {
            selectedMoodFilters.remove(rawValue)
        } else {
            selectedMoodFilters.insert(rawValue)
        }
    }

    func toggleStyleFilter(_ rawValue: String) {
        if selectedStyleFilters.contains(rawValue) {
            selectedStyleFilters.remove(rawValue)
        } else {
            selectedStyleFilters.insert(rawValue)
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add VinylSoul/ViewModels/HistoryViewModel.swift
git commit -m "feat: add search, filter, favorite toggle, and stats logic to HistoryViewModel"
```

---

### Task 4: Update HistoryView with search bar, filter chips, and segmented control

**Files:**
- Modify: `VinylSoul/Views/HistoryView.swift`

- [ ] **Step 1: Replace HistoryView with full implementation**

```swift
import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppStore.self) private var appStore
    @State private var viewModel = HistoryViewModel()
    @State private var showStats = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchAndFilterBar
                recordList
            }
            .navigationTitle("唱片架")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showStats = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .foregroundStyle(Color(hex: "#E8A850"))
                    }
                }
            }
            .onAppear {
                viewModel.fetch(modelContext: modelContext)
                if appStore.showStats {
                    showStats = true
                    appStore.showStats = false
                }
            }
            .sheet(isPresented: $showStats) {
                StatsView(viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private var searchAndFilterBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索专辑或歌词...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color(.systemGray6).opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

            Picker("筛选", selection: $viewModel.filterMode) {
                ForEach(HistoryViewModel.FilterMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(viewModel.moodFilterOptions, id: \.self) { mood in
                        FilterChip(
                            label: mood,
                            isSelected: viewModel.selectedMoodFilters.contains(mood),
                            color: .purple
                        ) {
                            viewModel.toggleMoodFilter(mood)
                        }
                    }
                    ForEach(viewModel.styleFilterOptions, id: \.self) { style in
                        FilterChip(
                            label: style,
                            isSelected: viewModel.selectedStyleFilters.contains(style),
                            color: .orange
                        ) {
                            viewModel.toggleStyleFilter(style)
                        }
                    }
                }
                .padding(.horizontal)
            }

            if viewModel.hasActiveFilters {
                Button {
                    viewModel.clearAllFilters()
                } label: {
                    Text("清除筛选")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#E8A850"))
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var recordList: some View {
        if viewModel.filteredRecords.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: viewModel.hasActiveFilters
                      ? "magnifyingglass" : "square.stack")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text(viewModel.hasActiveFilters
                     ? "没有找到匹配的唱片" : "还没有灵感唱片，去创作一张吧 🎵")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxHeight: .infinity)
        } else if horizontalSizeClass == .regular {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.filteredRecords) { record in
                        NavigationLink {
                            PastPlaybackView(record: record)
                        } label: {
                            HistoryCard(record: record) {
                                viewModel.toggleFavorite(record, modelContext: modelContext)
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.delete(record, modelContext: modelContext)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
        } else {
            List {
                ForEach(viewModel.filteredRecords) { record in
                    NavigationLink {
                        PastPlaybackView(record: record)
                    } label: {
                        HistoryCard(record: record) {
                            viewModel.toggleFavorite(record, modelContext: modelContext)
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
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
                        viewModel.delete(viewModel.filteredRecords[index], modelContext: modelContext)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? color.opacity(0.3) : Color(.systemGray6).opacity(0.4))
                .foregroundStyle(isSelected ? color : .secondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? color : Color.clear, lineWidth: 0.5)
                )
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add VinylSoul/Views/HistoryView.swift
git commit -m "feat: add search bar, filter chips, and segmented control to HistoryView"
```

---

### Task 5: Add favorite button to HistoryCard

**Files:**
- Modify: `VinylSoul/Views/Components/HistoryCard.swift`

- [ ] **Step 1: Add favorite action closure and heart overlay**

```swift
import SwiftUI

struct HistoryCard: View {
    let record: InspirationRecord
    var onToggleFavorite: (() -> Void)?

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
                if onToggleFavorite != nil {
                    Button(action: { onToggleFavorite?() }) {
                        Image(systemName: record.isFavorite ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundStyle(record.isFavorite ? Color(hex: "#E04040") : .secondary)
                    }
                }
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

- [ ] **Step 2: Build to verify**

```bash
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add VinylSoul/Views/Components/HistoryCard.swift
git commit -m "feat: add favorite toggle button to HistoryCard"
```

---

### Task 6: Create StatsView

**Files:**
- Create: `VinylSoul/Views/StatsView.swift`

- [ ] **Step 1: Create StatsView with Swift Charts**

```swift
import SwiftUI
import Charts

struct StatsView: View {
    let viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss

    private var stats: StatsOverview {
        viewModel.statsOverview()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    overviewCards
                    styleChart
                    moodChart
                    timelineSection
                }
                .padding()
            }
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var overviewCards: some View {
        HStack(spacing: 12) {
            StatCard(title: "总生成", value: "\(stats.totalGenerations)")
            StatCard(title: "本月生成", value: "\(stats.monthlyGenerations)")
        }
    }

    @ViewBuilder
    private var styleChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("风格分布")
                .font(.headline)
                .foregroundStyle(.secondary)

            if stats.styleDistribution.isEmpty {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                Chart {
                    ForEach(
                        Array(stats.styleDistribution),
                        id: \.key
                    ) { style, count in
                        BarMark(
                            x: .value("次数", count),
                            y: .value("风格", style.rawValue)
                        )
                        .foregroundStyle(Color(hex: "#E8A850").gradient)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisValueLabel()
                    }
                }
                .frame(height: CGFloat(stats.styleDistribution.count * 40 + 20))
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var moodChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("心情分布")
                .font(.headline)
                .foregroundStyle(.secondary)

            if stats.moodDistribution.isEmpty {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                Chart {
                    ForEach(
                        Array(stats.moodDistribution),
                        id: \.key
                    ) { mood, count in
                        BarMark(
                            x: .value("次数", count),
                            y: .value("心情", mood.rawValue)
                        )
                        .foregroundStyle(Color.purple.opacity(0.6).gradient)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisValueLabel()
                    }
                }
                .frame(height: CGFloat(stats.moodDistribution.count * 40 + 20))
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本月时间线")
                .font(.headline)
                .foregroundStyle(.secondary)

            if stats.recentTimeline.allSatisfy({ $0.count == 0 }) {
                Text("本月暂无记录")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(stats.recentTimeline, id: \.date) { item in
                    HStack {
                        Text(item.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if item.count > 0 {
                            HStack(spacing: 4) {
                                ForEach(0..<min(item.count, 10), id: \.self) { _ in
                                    Circle()
                                        .fill(Color(hex: "#E8A850"))
                                        .frame(width: 8, height: 8)
                                }
                                Text("\(item.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("-")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color(hex: "#E8A850"))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemGray6).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add VinylSoul/Views/StatsView.swift
git commit -m "feat: add StatsView with Charts-based dashboard"
```

---

### Phase 3: Sharing Enhancement

### Task 7: Update ShareCardView with template and config support

**Files:**
- Modify: `VinylSoul/Views/Components/ShareCardView.swift`

- [ ] **Step 1: Replace ShareCardView with template-aware version**

```swift
import SwiftUI

struct ShareCardView: View {
    let albumTitle: String
    let lyrics: String
    let mood: String?
    let style: String?
    let config: ShareCardConfig

    init(
        albumTitle: String,
        lyrics: String,
        mood: String? = nil,
        style: String? = nil,
        config: ShareCardConfig = ShareCardConfig()
    ) {
        self.albumTitle = albumTitle
        self.lyrics = lyrics
        self.mood = mood
        self.style = style
        self.config = config
    }

    private var lyricsExcerpt: String {
        let lines = lyrics.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return lines.prefix(6).joined(separator: "\n")
    }

    private var backgroundColor: Color {
        switch config.template {
        case .classicVinyl: return Color(hex: "#0d0d0d")
        case .minimalText:  return .black
        case .retroWarm:    return Color(hex: "#1a0e0a")
        }
    }

    private var titleFont: Font {
        switch config.template {
        case .classicVinyl: return .system(size: 30, weight: .bold, design: .serif)
        case .minimalText:  return .system(size: 28, weight: .light, design: .monospaced)
        case .retroWarm:    return .system(size: 32, weight: .bold, design: .serif)
        }
    }

    private var bodyFont: Font {
        switch config.template {
        case .classicVinyl: return .system(size: 17, design: .serif)
        case .minimalText:  return .system(size: 15, weight: .light, design: .monospaced)
        case .retroWarm:    return .system(size: 16, design: .serif)
        }
    }

    var body: some View {
        ZStack {
            backgroundColor

            if config.template == .classicVinyl {
                vinylCircles
            }

            VStack(spacing: 0) {
                if config.template == .classicVinyl {
                    vinylCenterIcon
                }

                if config.showAlbumTitle {
                    Text(albumTitle)
                        .font(titleFont)
                        .foregroundStyle(Color(hex: config.accentColor.hex))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, config.template == .classicVinyl ? 28 : 48)
                }

                if config.template != .minimalText {
                    Rectangle()
                        .fill(Color(hex: config.accentColor.hex).opacity(0.25))
                        .frame(width: 50, height: 1)
                        .padding(.top, 16)
                }

                if config.showLyrics {
                    Text(lyricsExcerpt)
                        .font(bodyFont)
                        .foregroundStyle(
                            config.template == .minimalText
                            ? .white : Color(hex: config.accentColor.hex).opacity(0.9)
                        )
                        .multilineTextAlignment(.leading)
                        .lineSpacing(config.template == .minimalText ? 10 : 7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 44)
                        .padding(.top, 24)
                }

                Spacer()

                if let mood, let style {
                    HStack(spacing: 10) {
                        TagChip(text: mood)
                        TagChip(text: style)
                    }
                    .padding(.bottom, 20)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: config.accentColor.hex))
                        .frame(width: 6, height: 6)
                    Text("VinylSoul")
                        .font(.system(size: 13, weight: .medium, design: .serif))
                }
                .foregroundStyle(Color(hex: config.accentColor.hex).opacity(0.5))
                .padding(.bottom, 36)
            }
        }
        .frame(width: 400, height: 400)
    }

    private var vinylCircles: some View {
        Group {
            Circle()
                .stroke(Color(hex: "#E8A850").opacity(0.06), lineWidth: 1.5)
                .frame(width: 360, height: 360)
                .offset(x: 100, y: -180)
            Circle()
                .stroke(Color(hex: "#E8A850").opacity(0.04), lineWidth: 1)
                .frame(width: 220, height: 220)
                .offset(x: -120, y: 200)
            Circle()
                .stroke(Color(hex: "#E8A850").opacity(0.05), lineWidth: 1)
                .frame(width: 140, height: 140)
                .offset(x: -120, y: 200)
        }
    }

    private var vinylCenterIcon: some View {
        ZStack {
            Circle()
                .fill(.black)
                .frame(width: 80, height: 80)
                .shadow(color: .black.opacity(0.8), radius: 10)
            ForEach(0..<4) { i in
                Circle()
                    .stroke(Color(.systemGray5).opacity(0.2), lineWidth: 0.5)
                    .frame(width: CGFloat(70 - i * 17), height: CGFloat(70 - i * 17))
            }
            Circle()
                .fill(Color(hex: "#E8A850"))
                .frame(width: 22, height: 22)
            Circle()
                .fill(Color(hex: "#0d0d0d"))
                .frame(width: 4, height: 4)
        }
        .padding(.top, 44)
    }
}

private struct TagChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(.white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
    }
}

@MainActor
enum ShareCardRenderer {
    static func render(
        albumTitle: String,
        lyrics: String,
        mood: String? = nil,
        style: String? = nil,
        config: ShareCardConfig = ShareCardConfig(),
        platform: SharePlatform = .generic
    ) -> UIImage? {
        let card = ShareCardView(
            albumTitle: albumTitle,
            lyrics: lyrics,
            mood: mood,
            style: style,
            config: config
        )

        let size = platform.canvasSize
        let renderer = ImageRenderer(content: card.frame(width: size.width, height: size.height))
        renderer.scale = platform.renderScale
        return renderer.uiImage
    }
}

private extension SharePlatform {
    var canvasSize: CGSize {
        switch self {
        case .generic:        return CGSize(width: 400, height: 400)
        case .wechatMoment:   return CGSize(width: 360, height: 360)
        case .instagramStory: return CGSize(width: 360, height: 640)
        }
    }

    var renderScale: CGFloat {
        switch self {
        case .generic:        return 3.0
        case .wechatMoment:   return 3.0
        case .instagramStory: return 3.0
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add VinylSoul/Views/Components/ShareCardView.swift
git commit -m "feat: add multi-template and platform-adapted rendering to ShareCard"
```

---

### Task 8: Create ShareConfigSheet component

**Files:**
- Create: `VinylSoul/Views/Components/ShareConfigSheet.swift`

- [ ] **Step 1: Create ShareConfigSheet**

```swift
import SwiftUI

struct ShareConfigSheet: View {
    @Binding var config: ShareCardConfig
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("模板") {
                    Picker("模板", selection: $config.template) {
                        ForEach(ShareCardTemplate.allCases, id: \.self) { tpl in
                            Text(tpl.displayName).tag(tpl)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("内容") {
                    Toggle("显示专辑名", isOn: $config.showAlbumTitle)
                    Toggle("显示歌词", isOn: $config.showLyrics)
                }

                Section("强调色") {
                    Picker("强调色", selection: $config.accentColor) {
                        ForEach(AccentColor.allCases, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(Color(hex: color.hex))
                                    .frame(width: 16, height: 16)
                                Text(colorLabel(color))
                            }
                            .tag(color)
                        }
                    }
                }
            }
            .navigationTitle("分享设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("生成") {
                        onConfirm()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: "#E8A850"))
                }
            }
        }
    }

    private func colorLabel(_ color: AccentColor) -> String {
        switch color {
        case .amber: return "琥珀"
        case .white: return "白色"
        case .warm:  return "暖橙"
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add VinylSoul/Views/Components/ShareConfigSheet.swift
git commit -m "feat: add ShareConfigSheet for share template/config selection"
```

---

### Task 9: Wire up ShareConfigSheet in PlaybackView and PastPlaybackView

**Files:**
- Modify: `VinylSoul/Views/PlaybackView.swift`
- Modify: `VinylSoul/Views/HistoryView.swift` (PastPlaybackView is in this file)

- [ ] **Step 1: Update PlaybackView share state and button**

In `PlaybackView.swift`, replace share state properties (currently `@State private var shareImage: UIImage?` and `@State private var showShareSheet = false`) with:

```swift
@State private var shareConfig = ShareCardConfig()
@State private var showShareConfig = false
@State private var shareImage: UIImage?
@State private var showShareSheet = false
```

Replace the `shareButton` method:

```swift
private func shareButton(albumTitle: String) -> some View {
    Button(action: { showShareConfig = true }) {
        VStack(spacing: 4) {
            Image(systemName: "square.and.arrow.up").font(.title2)
            Text("分享").font(.caption)
        }
        .foregroundStyle(Color(hex: "#E8A850"))
    }
    .sheet(isPresented: $showShareConfig) {
        ShareConfigSheet(
            config: $shareConfig,
            onConfirm: {
                shareImage = ShareCardRenderer.render(
                    albumTitle: albumTitle,
                    lyrics: viewModel.displayedText,
                    config: shareConfig,
                    platform: .generic
                )
                showShareSheet = true
            }
        )
    }
}
```

Keep the existing `.sheet(isPresented: $showShareSheet)` on the Group — it still serves the final ShareSheet after config closes.

- [ ] **Step 2: Update PastPlaybackView share toolbar**

In `PastPlaybackView`, add these state properties alongside existing `shareImage`/`showShareSheet`:

```swift
@State private var shareConfig = ShareCardConfig()
@State private var showShareConfig = false
```

Replace the `shareToolbarItem`:

```swift
private var shareToolbarItem: some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button {
            showShareConfig = true
        } label: {
            Image(systemName: "square.and.arrow.up")
                .foregroundStyle(Color(hex: "#E8A850"))
        }
        .sheet(isPresented: $showShareConfig) {
            ShareConfigSheet(
                config: $shareConfig,
                onConfirm: {
                    shareImage = ShareCardRenderer.render(
                        albumTitle: record.albumTitle,
                        lyrics: record.lyrics,
                        mood: record.moodRaw,
                        style: record.styleTagRaw,
                        config: shareConfig,
                        platform: .generic
                    )
                    showShareSheet = true
                }
            )
        }
    }
}
```

- [ ] **Step 3: Build to verify**

```bash
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add VinylSoul/Views/PlaybackView.swift VinylSoul/Views/HistoryView.swift
git commit -m "feat: wire up ShareConfigSheet in Playback and PastPlayback views"
```

---

### Phase 4: Ecosystem Integration

### Task 10: Configure App Group for SwiftData sharing

**Files:**
- Modify: `VinylSoul/VinylSoulApp.swift`
- Create: `VinylSoul/VinylSoul.entitlements`

- [ ] **Step 1: Create shared entitlements file**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.vinylsoul.app</string>
    </array>
</dict>
</plist>
```

Save to `VinylSoul/VinylSoul.entitlements`.

- [ ] **Step 2: Update VinylSoulApp to use shared container**

In `VinylSoulApp.swift`, replace the `.modelContainer(for: InspirationRecord.self)` modifier on `WindowGroup` with a computed `sharedModelContainer`. Only the `VinylSoulApp` struct changes — `AppRoot` stays unchanged.

Add `private let appGroupID` and `sharedModelContainer` to `VinylSoulApp`:

```swift
@main
struct VinylSoulApp: App {
    @State private var appStore = AppStore()
    @State private var audioManager = AudioManager()
    @State private var musicService = MusicService()

    private let appGroupID = "group.com.vinylsoul.app"

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environment(appStore)
                .environment(audioManager)
                .environment(musicService)
        }
        .modelContainer(sharedModelContainer)
    }

    private var sharedModelContainer: ModelContainer {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        else {
            fatalError("App Group container URL not found. Check provisioning profile.")
        }
        let storeURL = containerURL.appendingPathComponent("VinylSoul.sqlite")
        let configuration = ModelConfiguration(url: storeURL)
        do {
            return try ModelContainer(for: InspirationRecord.self, configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
```

`AppRoot` struct stays exactly as-is from the original file — no changes.

- [ ] **Step 3: Commit**

```bash
git add VinylSoul/VinylSoulApp.swift VinylSoul/VinylSoul.entitlements
git commit -m "feat: configure App Group shared SwiftData container"
```

---

### Task 11: Create Widget Extension

**Files:**
- Create: `VinylSoulWidget/VinylSoulWidget.swift`
- Create: `VinylSoulWidget/Info.plist`

- [ ] **Step 1: Create Widget directory and main widget file**

```bash
mkdir -p VinylSoulWidget
```

```swift
import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), albumTitle: "午夜蓝调", lyricsExcerpt: "在城市的霓虹灯下，思念如潮水般涌来...")
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        let entry = WidgetEntry(date: Date(), albumTitle: "午夜蓝调", lyricsExcerpt: "在城市的霓虹灯下，思念如潮水般涌来...")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entry = loadLatestEntry()
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(refresh))
        completion(timeline)
    }

    private func loadLatestEntry() -> WidgetEntry {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.vinylsoul.app")
        else {
            return WidgetEntry(date: Date(), albumTitle: nil, lyricsExcerpt: nil)
        }

        let storeURL = containerURL.appendingPathComponent("VinylSoul.sqlite")
        let configuration = ModelConfiguration(url: storeURL)

        guard let container = try? ModelContainer(
            for: InspirationRecord.self,
            configurations: configuration
        ) else {
            return WidgetEntry(date: Date(), albumTitle: nil, lyricsExcerpt: nil)
        }

        let descriptor = FetchDescriptor<InspirationRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let records = (try? container.mainContext.fetch(descriptor)) ?? []

        guard let latest = records.first else {
            return WidgetEntry(date: Date(), albumTitle: nil, lyricsExcerpt: nil)
        }

        let excerpt = latest.lyrics
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .prefix(2)
            .joined(separator: "\n")

        return WidgetEntry(date: latest.timestamp, albumTitle: latest.albumTitle, lyricsExcerpt: excerpt)
    }
}

struct WidgetEntry: TimelineEntry {
    let date: Date
    let albumTitle: String?
    let lyricsExcerpt: String?
}

struct VinylSoulWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: WidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            mediumWidget
        }
    }

    private var smallWidget: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note")
                .font(.title)
                .foregroundStyle(Color(hex: "#E8A850"))
            Text("今日 R&B 心情？")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color(hex: "#E8A850"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#0d0d0d"))
        .widgetURL(URL(string: "vinylsoul://generate"))
    }

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                if let title = entry.albumTitle {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color(hex: "#E8A850"))
                        .lineLimit(1)
                    if let excerpt = entry.lyricsExcerpt {
                        Text(excerpt)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                } else {
                    Text("去生成你的第一张灵感唱片")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: "#E8A850"))
                        .frame(width: 4, height: 4)
                    Text("VinylSoul")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: "#E8A850").opacity(0.5))
                }
            }
            Spacer()
            Image(systemName: "record.circle")
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: "#E8A850").opacity(0.3))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#0d0d0d"))
        .widgetURL(URL(string: "vinylsoul://latest"))
    }
}

struct VinylSoulWidget: Widget {
    let kind: String = "VinylSoulWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VinylSoulWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("VinylSoul")
        .description("每日 R&B 灵感提醒")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

- [ ] **Step 2: Create Widget Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>VinylSoul</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
```

Save to `VinylSoulWidget/Info.plist`.

- [ ] **Step 3: Commit**

```bash
git add VinylSoulWidget/
git commit -m "feat: add Widget Extension for small and medium widgets"
```

---

### Task 12: Update project.yml for Widget target and App Group

**Files:**
- Modify: `project.yml`

- [ ] **Step 1: Add Widget target and entitlements to project.yml**

Replace the entire `project.yml` with:

```yaml
name: VinylSoul
options:
  bundleIdPrefix: com.vinylsoul
  deploymentTarget:
    iOS: "18.0"
  xcodeVersion: "16.0"
  generateEmptyDirectories: false

settings:
  base:
    SWIFT_VERSION: "6.0"

targets:
  VinylSoul:
    type: application
    platform: iOS
    sources:
      - path: VinylSoul
    info:
      path: VinylSoul/Info.plist
    entitlements:
      path: VinylSoul/VinylSoul.entitlements
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.vinylsoul.app
        UIBackgroundModes: ["audio"]

  VinylSoulWidget:
    type: app-extension
    platform: iOS
    sources:
      - path: VinylSoulWidget
      - path: VinylSoul/Models
      - path: VinylSoul/Persistence
    info:
      path: VinylSoulWidget/Info.plist
    entitlements:
      path: VinylSoul/VinylSoul.entitlements
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.vinylsoul.app.widget

  VinylSoulTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: VinylSoulTests
    dependencies:
      - target: VinylSoul
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.vinylsoul.tests
        GENERATE_INFOPLIST_FILE: "YES"

  VinylSoulUITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - path: VinylSoulUITests
    dependencies:
      - target: VinylSoul
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.vinylsoul.uitests
        GENERATE_INFOPLIST_FILE: "YES"
```

- [ ] **Step 2: Regenerate project and verify build**

```bash
cd /Users/pig/Desktop/private_workspace/VinylSoul
xcodegen generate
```

Then re-add `UIBackgroundModes` to `VinylSoul/Info.plist` if xcodegen wiped it:
```xml
<key>UIBackgroundModes</key>
<array><string>audio</string></array>
```

```bash
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Also build the Widget target**

```bash
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoulWidget \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add project.yml
git commit -m "feat: add Widget target and App Group entitlements to project config"
```

---

### Task 13: Create AppIntents for Siri/Shortcuts

**Files:**
- Create: `VinylSoul/VinylSoulIntents.swift`

- [ ] **Step 1: Create AppIntents file**

```swift
import AppIntents
import SwiftUI

struct GenerateInspirationIntent: AppIntent {
    static var title: LocalizedStringResource = "生成灵感"
    static var description = IntentDescription("用 VinylSoul 生成一首 R&B 灵感歌曲")

    @Parameter(title: "心情")
    var mood: String?

    @Parameter(title: "关键词")
    var keywords: String?

    @Parameter(title: "风格")
    var style: String?

    static var parameterSummary: some ParameterSummary {
        Summary("用\(\.$mood)心情和\(\.$style)风格生成灵感，关键词：\(\.$keywords)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        var components = URLComponents(string: "vinylsoul://generate")!
        var queryItems: [URLQueryItem] = []
        if let mood { queryItems.append(URLQueryItem(name: "mood", value: mood)) }
        if let keywords { queryItems.append(URLQueryItem(name: "keywords", value: keywords)) }
        if let style { queryItems.append(URLQueryItem(name: "style", value: style)) }
        if !queryItems.isEmpty { components.queryItems = queryItems }

        await UIApplication.shared.open(components.url!)
        return .result(opensIntent: OpenURLIntent(components.url!))
    }
}

struct PlayLatestIntent: AppIntent {
    static var title: LocalizedStringResource = "播放最近唱片"
    static var description = IntentDescription("打开最近一张灵感唱片")

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        let url = URL(string: "vinylsoul://latest")!
        await UIApplication.shared.open(url)
        return .result(opensIntent: OpenURLIntent(url))
    }
}

struct ViewStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "查看统计"
    static var description = IntentDescription("打开 VinylSoul 统计数据")

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        let url = URL(string: "vinylsoul://stats")!
        await UIApplication.shared.open(url)
        return .result(opensIntent: OpenURLIntent(url))
    }
}

struct VinylSoulShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GenerateInspirationIntent(),
            phrases: [
                "用 VinylSoul 生成灵感",
                "用 VinylSoul 生成一首歌",
                "生成 R&B 灵感"
            ],
            shortTitle: "生成灵感",
            systemImageName: "music.note"
        )
        AppShortcut(
            intent: PlayLatestIntent(),
            phrases: [
                "播放 VinylSoul 最近唱片",
                "播放最近的灵感唱片"
            ],
            shortTitle: "播放最近",
            systemImageName: "record.circle"
        )
        AppShortcut(
            intent: ViewStatsIntent(),
            phrases: [
                "查看 VinylSoul 统计",
                "查看我的灵感统计"
            ],
            shortTitle: "查看统计",
            systemImageName: "chart.bar"
        )
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add VinylSoul/VinylSoulIntents.swift
git commit -m "feat: add Siri/Shortcuts AppIntents for generate, play latest, and stats"
```

---

### Task 14: Add Quick Actions and deep link handling

**Files:**
- Modify: `VinylSoul/Info.plist`
- Modify: `VinylSoul/VinylSoulApp.swift`

- [ ] **Step 1: Add `showStats` to AppStore and Quick Actions to Info.plist**

Add `var showStats = false` to `AppStore` (in `App/AppStore.swift`):

```swift
final class AppStore {
    var currentResult: GenerationResult?
    var selectedTab: Int = 0
    var apiKey: String?
    var showStats: Bool = false
    var hasAPIKey: Bool { apiKey != nil }
    // ... rest unchanged
}
```

Add `UIApplicationShortcutItems` to `VinylSoul/Info.plist` (inside the top-level `<dict>`):

```xml
<key>UIApplicationShortcutItems</key>
<array>
    <dict>
        <key>UIApplicationShortcutItemType</key>
        <string>generateInspiration</string>
        <key>UIApplicationShortcutItemTitle</key>
        <string>生成灵感</string>
        <key>UIApplicationShortcutItemIconSymbolName</key>
        <string>music.note</string>
    </dict>
    <dict>
        <key>UIApplicationShortcutItemType</key>
        <string>viewFavorites</string>
        <key>UIApplicationShortcutItemTitle</key>
        <string>我的收藏</string>
        <key>UIApplicationShortcutItemIconSymbolName</key>
        <string>heart.fill</string>
    </dict>
    <dict>
        <key>UIApplicationShortcutItemType</key>
        <string>viewHistory</string>
        <key>UIApplicationShortcutItemTitle</key>
        <string>唱片架</string>
        <key>UIApplicationShortcutItemIconSymbolName</key>
        <string>square.stack</string>
    </dict>
</array>
```

- [ ] **Step 2: Add deep link + Quick Action handling to VinylSoulApp**

Add an `AppDelegate` adaptor class at the top of `VinylSoulApp.swift` (before `@main`):

```swift
import SwiftUI
import SwiftData

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            QuickActionHandler.shared.pendingAction = shortcutItem.type
        }
        return UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        QuickActionHandler.shared.pendingAction = shortcutItem.type
        completionHandler(true)
    }
}

@Observable
final class QuickActionHandler {
    static let shared = QuickActionHandler()
    var pendingAction: String?
}
```

Add the delegate adaptor to `VinylSoulApp` struct:

```swift
@main
struct VinylSoulApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appStore = AppStore()
    @State private var audioManager = AudioManager()
    @State private var musicService = MusicService()
    // ... rest unchanged
```

Add deep link handling in `AppRoot`. Add `@Environment(AppStore.self)` and an `onOpenURL` modifier to `ContentView()` in `AppRoot.body`:

```swift
struct AppRoot: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppStore.self) private var appStore
    private let notificationManager = NotificationManager()

    var body: some View {
        ContentView()
            .preferredColorScheme(.dark)
            .onAppear {
                notificationManager.requestAuthorization()
                notificationManager.scheduleDailyInspiration()
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    notificationManager.markAppOpened()
                    handlePendingAction()
                case .background:
                    notificationManager.scheduleDailyInspiration()
                default:
                    break
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
    }

    private func handlePendingAction() {
        guard let action = QuickActionHandler.shared.pendingAction else { return }
        QuickActionHandler.shared.pendingAction = nil
        switch action {
        case "generateInspiration": appStore.selectedTab = 0
        case "viewFavorites", "viewHistory": appStore.selectedTab = 2
        default: break
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let host = url.host else { return }
        switch host {
        case "generate": appStore.selectedTab = 0
        case "latest", "history":  appStore.selectedTab = 2
        case "stats":
            appStore.selectedTab = 2
            appStore.showStats = true
        default: break
        }
    }
}
```

- [ ] **Step 3: Build to verify**

```bash
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add VinylSoul/App/AppStore.swift VinylSoul/Info.plist VinylSoul/VinylSoulApp.swift
git commit -m "feat: add Quick Actions, deep link handling, and AppDelegate adapter"
```

---

### Task 15: Add URL scheme to Info.plist

**Files:**
- Modify: `VinylSoul/Info.plist`

- [ ] **Step 1: Add URL types for custom scheme**

Add `CFBundleURLTypes` to `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>vinylsoul</string>
        </array>
    </dict>
</array>
```

- [ ] **Step 2: Commit**

```bash
git add VinylSoul/Info.plist
git commit -m "feat: add vinylsoul:// URL scheme for deep linking"
```

---

### Phase 5: Final Integration & Verification

### Task 16: Regenerate project, check Info.plist, and build all targets

- [ ] **Step 1: Regenerate Xcode project**

```bash
cd /Users/pig/Desktop/private_workspace/VinylSoul
xcodegen generate
```

- [ ] **Step 2: Verify UIBackgroundModes is present in Info.plist**

```bash
grep -A3 "UIBackgroundModes" VinylSoul/Info.plist
```

If missing, re-add:
```xml
<key>UIBackgroundModes</key>
<array><string>audio</string></array>
```

- [ ] **Step 3: Build main app target**

```bash
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Build Widget target**

```bash
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoulWidget \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Run existing tests to verify no regressions**

```bash
xcodebuild -project VinylSoul.xcodeproj -scheme VinylSoul \
  -destination 'platform=iOS Simulator,name=iPhone 17' test 2>&1 | tail -20
```

Expected: All tests pass (or no regression from pre-existing test state).

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: regenerate project with all v2 targets and verify build"
```

---

## Completion Checklist

After all tasks are implemented, verify:

- [ ] Search: typing in search bar filters records by album title and lyrics
- [ ] Filter: mood/style chips filter records, segmented control toggles all/favorites/recent
- [ ] Favorites: heart button toggles on HistoryCard, persists across app restarts
- [ ] Stats: StatsView shows total/monthly counts, bar charts, timeline
- [ ] Widget: Widgets appear in widget gallery, small shows prompt, medium shows latest
- [ ] Siri/Shortcuts: Intents appear in Shortcuts app, can trigger from Siri
- [ ] Quick Actions: Long-press app icon shows 3 shortcut items, each navigates correctly
- [ ] Share templates: Share button shows config sheet, 3 templates render differently
- [ ] Platform sizes: Instagram Story renders 9:16, WeChat renders 1:1
- [ ] Deep links: `vinylsoul://generate`, `vinylsoul://latest`, `vinylsoul://stats` all work
- [ ] No regressions: Existing generate → playback → history flow still works
