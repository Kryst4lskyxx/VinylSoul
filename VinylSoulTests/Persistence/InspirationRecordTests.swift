import Testing
import Foundation
@testable import VinylSoul

struct InspirationRecordTests {

    @Test func mapFromGenerationResult() throws {
        let result = GenerationResult(
            lyrics: "Test lyrics",
            albumTitle: "Test Album",
            djScript: "Test DJ",
            recommendations: [
                SongRecommendation(title: "Song 1", artist: "Artist 1")
            ]
        )

        let record = InspirationRecord(result: result, mood: .romantic, style: .slowJam)

        #expect(record.lyrics == "Test lyrics")
        #expect(record.albumTitle == "Test Album")
        #expect(record.moodRaw == "浪漫")
        #expect(record.styleTagRaw == "90's Slow Jam")

        let decoded = try JSONDecoder().decode(
            [SongRecommendation].self,
            from: record.recommendationsJSON.data(using: .utf8)!
        )
        #expect(decoded.count == 1)
        #expect(decoded[0].title == "Song 1")
    }
}
