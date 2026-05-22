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
        nonisolated(unsafe) let safeCompletion = completion
        Task { @MainActor in
            let entry = loadLatestEntry()
            let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(refresh))
            safeCompletion(timeline)
        }
    }

    @MainActor
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
