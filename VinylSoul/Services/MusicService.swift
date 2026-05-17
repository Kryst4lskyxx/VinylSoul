import Foundation
import MusicKit

@MainActor
@Observable
final class MusicService {
    var isPlaying = false
    var playingSongID: String?

    func searchSong(title: String, artist: String) async -> Song? {
        let term = "\(title) \(artist)"
        let request = MusicCatalogSearchRequest(term: term, types: [Song.self])
        guard let response = try? await request.response() else { return nil }
        return response.songs.first
    }

    func togglePreview(for song: Song) async {
        if isPlaying, playingSongID == song.id.rawValue {
            stopPreview()
        } else {
            ApplicationMusicPlayer.shared.queue = ApplicationMusicPlayer.Queue(for: [song])
            try? await ApplicationMusicPlayer.shared.play()
            isPlaying = true
            playingSongID = song.id.rawValue
        }
    }

    func stopPreview() {
        ApplicationMusicPlayer.shared.stop()
        isPlaying = false
        playingSongID = nil
    }
}
