import Testing
import Foundation
@testable import VinylSoul

struct GenerationResultTests {

    @Test func decodeValidJSON() throws {
        let json = """
        {
            "lyrics": "Verse one\\nChorus here",
            "album_title": "Midnight Vinyl",
            "dj_script": "Welcome to the show",
            "recommendations": [
                {"title": "Adorn", "artist": "Miguel"},
                {"title": "Untitled", "artist": "D'Angelo"}
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(GenerationResult.self, from: json)

        #expect(result.lyrics == "Verse one\nChorus here")
        #expect(result.albumTitle == "Midnight Vinyl")
        #expect(result.recommendations.count == 2)
        #expect(result.recommendations[0].title == "Adorn")
    }

    @Test func songRecommendationID() {
        let song = SongRecommendation(title: "Blame", artist: "Bryson Tiller")
        #expect(song.id == "Blame-Bryson Tiller")
    }
}
