# VinylSoul v2 功能增强设计

## 概述

在 v1 基础上增加三大领域共 8 个功能：历史与数据（搜索、收藏、统计）、生态集成（Widget、Siri/Shortcuts、Quick Actions）、分享与社交（多模板卡片、平台适配）。

## 数据模型变更

### InspirationRecord 新增字段

```
isFavorite: Bool          // 收藏标记，默认 false
```

`createdAt` 已有，确保用于统计和 Widget 数据读取。

### 新增类型

```swift
enum ShareCardTemplate: String, CaseIterable {
    case classicVinyl   // 经典黑胶（现有样式）
    case minimalText    // 极简文字
    case retroWarm      // 复古暖调
}

struct ShareCardConfig {
    var template: ShareCardTemplate = .classicVinyl
    var showAlbumTitle: Bool = true
    var showLyrics: Bool = true
    var accentColor: AccentColor = .amber
}

enum AccentColor: String, CaseIterable {
    case amber  // #E8A850
    case white  // #FFFFFF
    case warm   // #E89040
}

enum SharePlatform: String, CaseIterable {
    case generic        // 1:1, 系统分享
    case wechatMoment   // 1:1 1080×1080
    case instagramStory // 9:16 1080×1920
}

struct StatsOverview {
    let totalGenerations: Int
    let monthlyGenerations: Int
    let topStyle: StyleTag?
    let topMood: Mood?
    let styleDistribution: [StyleTag: Int]
    let moodDistribution: [Mood: Int]
    let recentTimeline: [(Date, Int)]  // 本月每天生成数
}
```

### App Group 共享

Widget 需要读取 SwiftData 记录。`ModelConfiguration` 配置 App Group 共享 container URL：

```swift
let appGroupID = "group.com.vinylsoul"
let containerURL = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
let modelConfiguration = ModelConfiguration(
    url: containerURL.appendingPathComponent("VinylSoul.sqlite")
)
```

Widget Extension 使用相同的 `ModelConfiguration` 读取数据。

---

## 视图层设计

### 1. 搜索 + 标签筛选

**位置：** `HistoryView` 顶部

- **搜索框：** `TextField` + `magnifyingglass` 图标，实时本地过滤（不发起网络请求），匹配 `albumTitle` + `lyrics`
- **标签筛选栏：** 横向 `ScrollView`，包含所有 `Mood`（忧伤/浪漫/洒脱）和所有 `StyleTag`（8 种）chip
  - 多选模式，选中态琥珀色高亮
  - 同时选中的标签为 AND 关系（如忧伤 AND Neo-Soul）
- **空白状态：** 无结果时显示"没有找到匹配的唱片"
- 搜索文字和标签筛选可组合使用

**ViewModel 变更：** `HistoryViewModel` 新增：

```swift
var searchText: String = ""
var selectedMoodFilters: Set<Mood> = []
var selectedStyleFilters: Set<StyleTag> = []
var filteredRecords: [InspirationRecord] { ... }  // 计算属性
```

### 2. 收藏功能

- **收藏按钮：** `HistoryCard` 右上角叠放心形图标（`heart` / `heart.fill`），红色 `#E04040`，点击 toggle `isFavorite`
- **筛选 SegmentedControl：** 搜索栏下方 `Picker`（`.segmented`），三项：「全部」/「收藏」/「最近」
  - 全部：所有记录
  - 收藏：`isFavorite == true`
  - 最近：按 `createdAt` 倒序，所有记录

### 3. 统计仪表盘

**新页面 `StatsView`**，从 `HistoryView` toolbar 按钮进入。

- **概览卡片：** 总生成数 + 本月生成数，大号数字 `.title` 字体
- **风格分布：** 使用 `Chart` framework（iOS 18 原生支持 Swift Charts），横向柱状图，每个 `StyleTag` 一条，琥珀色渐变
- **心情分布：** 同上，按 `Mood` 分布
- **最近时间线：** 本月每日生成数量列表

**数据来源：** `HistoryViewModel` 新增统计方法，遍历所有 `records` 聚合计算。

---

## 生态集成

### 4. Widget（小号 + 中号）

**新建 Widget Extension target：** `VinylSoulWidget`

**小号（systemSmall）：**
- 暗色背景 `#0d0d0d`，琥珀色音符图标 + 「今日 R&B 心情？」文字
- `widgetURL` deep link → 打开 App 到灵感页

**中号（systemMedium）：**
- 左侧：最近一张唱片专辑名 + 歌词前两行
- 右侧：静态黑胶图标（非动画）
- 无记录时显示占位文案：「去生成你的第一张灵感唱片」
- `widgetURL` deep link → 打开到对应历史详情

**TimelineProvider：** 每 15 分钟刷新，使用 App Group 共享 container 读取 SwiftData。

### 5. Siri / Shortcuts

使用 `AppIntents` framework（iOS 18 原生），新建 `VinylSoulIntents` 文件：

- **GenerateInspirationIntent：** 参数 mood(可选) / keywords(可选) / style(可选)，执行生成后打开 App 到 playback 页
- **PlayLatestIntent：** 打开最近一张唱片详情页
- **ViewStatsIntent：** 打开统计页

通过 `AppShortcutsProvider` 注册，自动出现在 Shortcuts App。Siri 通过 Intent 短语触发。

### 6. Home Screen Quick Actions

`UIApplicationShortcutItems` 配置三项：

| 标题 | type | 图标 |
|------|------|------|
| 生成灵感 | `generateInspiration` | `UIApplicationShortcutIcon(systemImageName: "music.note")` |
| 我的收藏 | `viewFavorites` | `UIApplicationShortcutIcon(systemImageName: "heart.fill")` |
| 唱片架 | `viewHistory` | `UIApplicationShortcutIcon(systemImageName: "square.stack")` |

在 `VinylSoulApp` / `SceneDelegate` 中处理 shortcut item，`appStore.selectedTab` 跳转。

---

## 分享与社交

### 7. 分享卡片模板

**三种模板：**

| 模板 | 背景 | 字体 | 风格参考 |
|------|------|------|----------|
| `.classicVinyl` | `#0d0d0d` + 琥珀唱片圈 | 衬线 bold | 现有样式 |
| `.minimalText` | `#000000` 纯黑 | 细体 mono | 文艺极简 |
| `.retroWarm` | `#1a0e0a` 深棕 | 粗衬线 | 70s R&B 唱片 |

**用户可调选项（bottom sheet）：**
- 显示专辑名 toggle
- 显示歌词 toggle
- 强调色：琥珀 / 白 / 暖橙
- 分享到：通用 / 微信朋友圈 / Instagram Story / 保存图片

**实现变更：**
- `ShareCardView` 新增 `template` 和 `config` 参数
- `ShareCardRenderer.render()` 接受新参数
- `PlaybackView` 和 `PastPlaybackView` 分享按钮 → 弹出配置 sheet → 确认后 render

### 8. 平台适配

`ShareCardRenderer` 新增平台感知的 render 方法：

```swift
static func render(
    albumTitle: String,
    lyrics: String,
    mood: String?,
    style: String?,
    config: ShareCardConfig,
    platform: SharePlatform
) -> UIImage
```

| 平台 | 尺寸 | 布局 |
|------|------|------|
| generic | 1:1 1200×1200 @3x | 现有布局 |
| wechatMoment | 1:1 1080×1080 | 同通用，分辨率适配 |
| instagramStory | 9:16 1080×1920 | 卡片在上半部分，下半 VinylSoul 水印 |

---

## 导航变更

- `HistoryView`：顶部新增搜索栏 + 筛选 segmented control + toolbar 统计入口
- `StatsView`：新建独立统计页
- `SettingsView`：可扩展分享偏好等设置项
- `VinylSoulWidget`：新建 Widget Extension target
- `VinylSoulIntents`：新建 AppIntents 文件

---

## 文件变更清单

| 操作 | 文件 |
|------|------|
| 修改 | `Models/GenerationResult.swift` — 新增 `ShareCardTemplate`, `ShareCardConfig`, `AccentColor`, `SharePlatform`, `StatsOverview` |
| 修改 | `Persistence/InspirationRecord.swift` — 新增 `isFavorite` |
| 修改 | `ViewModels/HistoryViewModel.swift` — 搜索/筛选/统计逻辑 |
| 修改 | `Views/HistoryView.swift` — 搜索栏 + 筛选 tab + 统计入口 |
| 修改 | `Views/Components/HistoryCard.swift` — 收藏按钮 |
| 修改 | `Views/Components/ShareCardView.swift` — 模板 + config 参数 |
| 修改 | `Views/PlaybackView.swift` — 分享配置 sheet |
| 修改 | `Views/SettingsView.swift` — 扩展设置项 |
| 修改 | `VinylSoulApp.swift` — Quick Actions + deep link 处理 |
| 新建 | `Views/StatsView.swift` |
| 新建 | `VinylSoulWidget/` — Widget Extension target |
| 新建 | `VinylSoulIntents.swift` — AppIntents |
| 修改 | `project.yml` — 新增 Widget target |
