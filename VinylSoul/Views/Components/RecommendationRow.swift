import SwiftUI
import MusicKit

struct RecommendationRow: View {
    let recommendation: SongRecommendation
    @Environment(MusicService.self) private var musicService

    @State private var catalogSong: Song?
    @State private var searchDone = false

    var body: some View {
        HStack(spacing: 12) {
            if let song = catalogSong, let artwork = song.artwork {
                AsyncImage(url: artwork.url(width: 120, height: 120)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        fallbackArt
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                fallbackArt
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.title)
                    .font(.subheadline.weight(.medium))
                Text(recommendation.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let song = catalogSong {
                Button {
                    Task { await musicService.togglePreview(for: song) }
                } label: {
                    Image(systemName: musicService.isPlaying
                        && musicService.playingSongID == song.id.rawValue
                        ? "stop.fill"
                        : "play.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color(hex: "#E8A850"))
                }

                let songID = song.id.rawValue
                if musicService.isAddedToLibrary(songID) {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        Task { await musicService.addToLibrary(song) }
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(4)
                    }
                }
            }
        }
        .task {
            catalogSong = await musicService.searchSong(
                title: recommendation.title,
                artist: recommendation.artist
            )
            searchDone = true
        }
    }

    private var fallbackArt: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(.systemGray6).opacity(0.3))
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "music.note")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            )
    }
}
