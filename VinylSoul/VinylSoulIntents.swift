import AppIntents
import SwiftUI

struct GenerateInspirationIntent: AppIntent {
    static let title: LocalizedStringResource = "生成灵感"
    static let description = IntentDescription("用 VinylSoul 生成一首 R&B 灵感歌曲")

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
    static let title: LocalizedStringResource = "播放最近唱片"
    static let description = IntentDescription("打开最近一张灵感唱片")

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        let url = URL(string: "vinylsoul://latest")!
        await UIApplication.shared.open(url)
        return .result(opensIntent: OpenURLIntent(url))
    }
}

struct ViewStatsIntent: AppIntent {
    static let title: LocalizedStringResource = "查看统计"
    static let description = IntentDescription("打开 VinylSoul 统计数据")

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
                "用${applicationName}生成灵感",
                "用${applicationName}生成一首歌",
                "${applicationName}生成 R&B 灵感"
            ],
            shortTitle: "生成灵感",
            systemImageName: "music.note"
        )
        AppShortcut(
            intent: PlayLatestIntent(),
            phrases: [
                "播放${applicationName}最近唱片",
                "用${applicationName}播放最近的灵感唱片"
            ],
            shortTitle: "播放最近",
            systemImageName: "record.circle"
        )
        AppShortcut(
            intent: ViewStatsIntent(),
            phrases: [
                "查看${applicationName}统计",
                "用${applicationName}查看我的灵感统计"
            ],
            shortTitle: "查看统计",
            systemImageName: "chart.bar"
        )
    }
}
