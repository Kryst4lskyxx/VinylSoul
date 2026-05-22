import Foundation

enum ShareCardTemplate: String, CaseIterable {
    case classicVinyl
    case minimalText
    case retroWarm

    var displayName: String {
        switch self {
        case .classicVinyl: return "经典黑胶"
        case .minimalText: return "极简文字"
        case .retroWarm: return "复古暖调"
        }
    }
}

enum AccentColor: String, CaseIterable {
    case amber
    case white
    case warm

    var hex: String {
        switch self {
        case .amber: return "#E8A850"
        case .white: return "#FFFFFF"
        case .warm:  return "#E89040"
        }
    }
}

struct ShareCardConfig {
    var template: ShareCardTemplate = .classicVinyl
    var showAlbumTitle: Bool = true
    var showLyrics: Bool = true
    var accentColor: AccentColor = .amber
}

enum SharePlatform: String, CaseIterable {
    case generic
    case wechatMoment
    case instagramStory

    var displayName: String {
        switch self {
        case .generic:        return "通用"
        case .wechatMoment:   return "微信朋友圈"
        case .instagramStory: return "Instagram Story"
        }
    }
}
