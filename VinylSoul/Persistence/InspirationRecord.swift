import Foundation
import SwiftData

@Model
final class InspirationRecord {
    var timestamp: Date
    var lyrics: String
    var albumTitle: String
    var djScript: String
    var recommendationsJSON: String
    var moodRaw: String
    var styleTagRaw: String
    var isFavorite: Bool = false

    init(result: GenerationResult, mood: Mood, style: StyleTag) {
        self.timestamp = .now
        self.lyrics = result.lyrics
        self.albumTitle = result.albumTitle
        self.djScript = result.djScript
        self.recommendationsJSON = (try? JSONEncoder().encode(result.recommendations))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.moodRaw = mood.rawValue
        self.styleTagRaw = style.rawValue
        self.isFavorite = false
    }
}
