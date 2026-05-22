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
