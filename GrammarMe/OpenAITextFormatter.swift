import Foundation

nonisolated enum OpenAIFormattingError: LocalizedError {
    case invalidKey
    case invalidResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .invalidKey: "Your OpenAI API key appears to be invalid."
        case .invalidResponse: "GrammarMe could not read the formatting response."
        case .api(let message): message
        }
    }
}

nonisolated struct OpenAITextFormatter: TextFormatting {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    nonisolated func format(_ text: String, apiKey: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        let schema: [String: Any] = [
            "type": "object",
            "properties": ["formattedText": ["type": "string"]],
            "required": ["formattedText"],
            "additionalProperties": false
        ]
        let body: [String: Any] = [
            "model": "gpt-5.6-luna",
            "store": false,
            "reasoning": ["effort": "none"],
            "instructions": "Correct grammar, spelling, punctuation, and clarity while preserving meaning, voice, and paragraph breaks. Do not introduce dashes. Return only the revised text.",
            "input": text,
            "text": [
                "verbosity": "low",
                "format": ["type": "json_schema", "name": "formatted_text", "strict": true, "schema": schema]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw OpenAIFormattingError.invalidResponse }
        if http.statusCode == 401 { throw OpenAIFormattingError.invalidKey }
        guard (200...299).contains(http.statusCode) else {
            let apiError = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data)
            throw OpenAIFormattingError.api(apiError?.error.message ?? "Formatting failed. Please try again.")
        }
        let responseEnvelope = try JSONDecoder().decode(ResponseEnvelope.self, from: data)
        guard let json = responseEnvelope.output.flatMap(\.content).first(where: { $0.type == "output_text" })?.text,
              let jsonData = json.data(using: .utf8) else { throw OpenAIFormattingError.invalidResponse }
        return try JSONDecoder().decode(FormattedPayload.self, from: jsonData).formattedText
    }
}

private nonisolated struct FormattedPayload: Decodable { let formattedText: String }
private nonisolated struct ResponseEnvelope: Decodable {
    struct Output: Decodable { let content: [Content] }
    struct Content: Decodable { let type: String; let text: String? }
    let output: [Output]
}
private nonisolated struct APIErrorEnvelope: Decodable {
    struct APIError: Decodable { let message: String }
    let error: APIError
}
