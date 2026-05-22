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
