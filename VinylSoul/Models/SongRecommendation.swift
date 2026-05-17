import Foundation

struct SongRecommendation: Codable, Identifiable {
    var id: String { "\(title)-\(artist)" }
    let title: String
    let artist: String
}
