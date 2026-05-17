import Foundation

enum DeepSeekError: Error, Equatable {
    case missingAPIKey
    case parseError
    case httpError(statusCode: Int)
    case networkError(Error)

    static func == (lhs: DeepSeekError, rhs: DeepSeekError) -> Bool {
        switch (lhs, rhs) {
        case (.missingAPIKey, .missingAPIKey): return true
        case (.parseError, .parseError): return true
        case (.httpError(let a), .httpError(let b)): return a == b
        case (.networkError, .networkError): return false
        default: return false
        }
    }
}

actor DeepSeekService {
    private let apiKey: String
    private let baseURL = "https://api.deepseek.com/chat/completions"
    private let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    private let systemPrompt = """
    你是一位精通R&B文化的作词人和音乐推荐专家。用户会提供心情、关键词和风格。\
    请生成一首R&B歌词（含主歌、副歌），并为它虚构一张专辑名称。\
    同时推荐3首真实存在的、与该情绪匹配的R&B经典歌曲。\
    最后用深夜电台DJ的口吻写一段感性独白，像是在播放这首歌前说的话。\
    所有内容以JSON格式返回，字段：lyrics, album_title, dj_script, \
    recommendations（数组，每项含title和artist）。只输出JSON，不要其他解释。
    """

    func generate(mood: Mood, keywords: String, style: StyleTag) async throws -> GenerationResult {
        let userMessage = buildUserMessage(mood: mood, keywords: keywords, style: style)

        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ]
        ]

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw DeepSeekError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeepSeekError.httpError(statusCode: -1)
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw DeepSeekError.httpError(statusCode: 401)
        default:
            throw DeepSeekError.httpError(statusCode: httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw DeepSeekError.parseError
        }

        return try parseResponseContent(content)
    }

    nonisolated func buildUserMessage(mood: Mood, keywords: String, style: StyleTag) -> String {
        "心情：\(mood.rawValue)。关键词：\(keywords)。风格：\(style.rawValue)。"
    }

    nonisolated func parseResponseContent(_ content: String) throws -> GenerationResult {
        var jsonString = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if jsonString.hasPrefix("```json") {
            jsonString = String(jsonString.dropFirst(7))
        }
        if jsonString.hasPrefix("```") {
            jsonString = String(jsonString.dropFirst(3))
        }
        if jsonString.hasSuffix("```") {
            jsonString = String(jsonString.dropLast(3))
        }
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = jsonString.data(using: .utf8) else {
            throw DeepSeekError.parseError
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            return try decoder.decode(GenerationResult.self, from: data)
        } catch {
            throw DeepSeekError.parseError
        }
    }
}
