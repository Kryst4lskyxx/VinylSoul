import Foundation

struct GenerationResult: Codable {
    let lyrics: String
    let albumTitle: String
    let djScript: String
    let recommendations: [SongRecommendation]
}
