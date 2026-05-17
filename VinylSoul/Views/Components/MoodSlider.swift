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
