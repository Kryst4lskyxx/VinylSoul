import Testing
import Foundation
@testable import VinylSoul

struct DeepSeekServiceTests {

    @Test func buildsCorrectPrompt() {
        let service = DeepSeekService(apiKey: "test-key")
        let prompt = service.buildUserMessage(
            mood: .romantic,
            keywords: "雨夜, 末班车",
            style: .slowJam
        )
        #expect(prompt.contains("浪漫"))
        #expect(prompt.contains("雨夜, 末班车"))
        #expect(prompt.contains("90's Slow Jam"))
    }

    @Test func parsesValidJSONResponse() throws {
        let service = DeepSeekService(apiKey: "test-key")
        let json = """
        {
            "lyrics": "Verse\\nChorus",
            "album_title": "Test Album",
            "dj_script": "DJ talks",
            "recommendations": [{"title": "Song", "artist": "Artist"}]
        }
        """
        let result = try service.parseResponseContent(json)
        #expect(result.lyrics == "Verse\nChorus")
        #expect(result.albumTitle == "Test Album")
        #expect(result.recommendations.count == 1)
    }

    @Test func parsesMarkdownWrappedJSON() throws {
        let service = DeepSeekService(apiKey: "test-key")
        let markdown = """
        ```json
        {
            "lyrics": "Verse",
            "album_title": "Album",
            "dj_script": "DJ",
            "recommendations": []
        }
        ```
        """
        let result = try service.parseResponseContent(markdown)
        #expect(result.lyrics == "Verse")
    }

    @Test func throwsParseErrorOnInvalidJSON() {
        let service = DeepSeekService(apiKey: "test-key")
        do {
            _ = try service.parseResponseContent("not json at all {")
            Issue.record("Expected parseError")
        } catch let error as DeepSeekError {
            #expect(error == .parseError)
        } catch {
            Issue.record("Unexpected error type")
        }
    }
}
