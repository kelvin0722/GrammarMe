import Foundation

nonisolated protocol TextFormatting: Sendable {
    nonisolated func format(_ text: String, apiKey: String) async throws -> String
}

nonisolated enum FormattingJourneyError: LocalizedError, Equatable {
    case noSelectedText
    case missingAPIKey
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .noSelectedText: "Select some text before choosing Format with GrammarMe."
        case .missingAPIKey: "Add your OpenAI API key from the GrammarMe menu-bar icon."
        case .emptyResponse: "GrammarMe did not receive formatted text. Please try again."
        }
    }
}

nonisolated struct FormatSelectedText: Sendable {
    let formatter: any TextFormatting
    let apiKey: @Sendable () throws -> String

    nonisolated func run(_ selectedText: String) async throws -> String {
        guard !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FormattingJourneyError.noSelectedText
        }
        let key = try apiKey().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw FormattingJourneyError.missingAPIKey }
        let formatted = try await formatter.format(selectedText, apiKey: key)
        guard !formatted.isEmpty else { throw FormattingJourneyError.emptyResponse }

        // The product promise explicitly avoids adding stylistic em dashes.
        if !selectedText.contains("—") {
            return formatted.replacingOccurrences(of: " — ", with: " ")
        }
        return formatted
    }
}
