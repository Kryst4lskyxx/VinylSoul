import SwiftUI

struct ShareCardView: View {
    let albumTitle: String
    let lyrics: String
    let mood: String?
    let style: String?

    private var lyricsExcerpt: String {
        let lines = lyrics.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return lines.prefix(6).joined(separator: "\n")
    }

    var body: some View {
        ZStack {
            Color(hex: "#0d0d0d")

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

            VStack(spacing: 0) {
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

                Text(albumTitle)
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(Color(hex: "#E8A850"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 28)

                Rectangle()
                    .fill(Color(hex: "#E8A850").opacity(0.25))
                    .frame(width: 50, height: 1)
                    .padding(.top, 16)

                Text(lyricsExcerpt)
                    .font(.system(size: 17, design: .serif))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 44)
                    .padding(.top, 24)

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
                        .fill(Color(hex: "#E8A850"))
                        .frame(width: 6, height: 6)
                    Text("VinylSoul")
                        .font(.system(size: 13, weight: .medium, design: .serif))
                }
                .foregroundStyle(Color(hex: "#E8A850").opacity(0.5))
                .padding(.bottom, 36)
            }
        }
        .frame(width: 400, height: 400)
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
        style: String? = nil
    ) -> UIImage? {
        let card = ShareCardView(
            albumTitle: albumTitle,
            lyrics: lyrics,
            mood: mood,
            style: style
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        return renderer.uiImage
    }
}
