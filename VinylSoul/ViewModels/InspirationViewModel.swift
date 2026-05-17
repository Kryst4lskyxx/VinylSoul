import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class InspirationViewModel {
    var mood: Mood = .romantic
    var keywords: String = ""
    var selectedStyle: StyleTag = .slowJam
    var isLoading = false
    var errorMessage: String?

    var canGenerate: Bool { !keywords.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading }

    func generate(appStore: AppStore, modelContext: ModelContext) {
        guard let apiKey = appStore.apiKey else {
            errorMessage = "请先在设置中输入 DeepSeek API Key"
            return
        }

        isLoading = true
        errorMessage = nil

        let service = DeepSeekService(apiKey: apiKey)
        let capturedMood = mood
        let capturedStyle = selectedStyle

        Task { @MainActor in
            defer { isLoading = false }

            do {
                let result = try await service.generate(
                    mood: capturedMood,
                    keywords: keywords,
                    style: capturedStyle
                )
                appStore.generateResult(result)
                let record = InspirationRecord(result: result, mood: capturedMood, style: capturedStyle)
                modelContext.insert(record)
            } catch let error as DeepSeekError {
                switch error {
                case .missingAPIKey:
                    errorMessage = "请先在设置中输入 DeepSeek API Key"
                case .httpError(let code) where code == 401:
                    errorMessage = "API Key 无效，请重新设置"
                case .httpError(let code):
                    errorMessage = "请求失败 (HTTP \(code))"
                case .parseError:
                    errorMessage = "响应解析失败，请重试"
                case .networkError:
                    errorMessage = "网络连接失败，请检查网络后重试"
                }
            } catch {
                errorMessage = "未知错误：\(error.localizedDescription)"
            }
        }
    }
}
