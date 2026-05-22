import Foundation
import SwiftUI

@Observable
final class AppStore {
    var currentResult: GenerationResult?
    var selectedTab: Int = 0
    var apiKey: String?
    var showStats = false
    var hasAPIKey: Bool { apiKey != nil }

    private let keychain = KeychainManager()

    init() {
        self.apiKey = try? keychain.read(account: "deepseek_api_key")
    }

    func saveAPIKey(_ key: String) {
        try? keychain.save(key: key, account: "deepseek_api_key")
        apiKey = key
    }

    func generateResult(_ result: GenerationResult) {
        currentResult = result
        selectedTab = 1
    }
}
