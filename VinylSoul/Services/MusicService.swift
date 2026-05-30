import Foundation
import MusicKit

@MainActor
@Observable
final class MusicService {
    var isPlaying = false
    var playingSongID: String?
    var libraryAddStatus: [String: Bool] = [:]

    private(set) var catalogAvailable: Bool? = nil
    private var checkingCatalog = false

    func searchSong(title: String, artist: String) async -> Song? {
        if catalogAvailable == false { return nil }
        if checkingCatalog { return nil }

        checkingCatalog = true
        defer { checkingCatalog = false }

        let term = "\(title) \(artist)"
        let request = MusicCatalogSearchRequest(term: term, types: [Song.self])
        if let response = try? await request.response() {
            catalogAvailable = true
            return response.songs.first
        } else {
            catalogAvailable = false
            return nil
        }
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

    func addToLibrary(_ song: Song) async -> Bool {
        let status = await MusicAuthorization.request()
        guard status == .authorized else { return false }

        let songID = song.id.rawValue
        do {
            try await MusicLibrary.shared.add(song)
            libraryAddStatus[songID] = true
            return true
        } catch {
            libraryAddStatus[songID] = false
            return false
        }
    }

    func isAddedToLibrary(_ songID: String) -> Bool {
        libraryAddStatus[songID] == true
    }
}
