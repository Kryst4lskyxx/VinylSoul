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
        VStack(spacing: 10) {
            Text("今天的心情")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                ForEach(moods, id: \.self) { m in
                    Button {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        mood = m
                    } label: {
                        VStack(spacing: 6) {
                            Text(emojis[m] ?? "")
                                .font(.largeTitle)
                                .opacity(mood == m ? 1 : 0.3)
                                .scaleEffect(mood == m ? 1.2 : 1.0)

                            Text(m.rawValue)
                                .font(.caption)
                                .foregroundStyle(mood == m ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.3), value: mood)
                }
            }
            .padding(.horizontal)
        }
    }
}
