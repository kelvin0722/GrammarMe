import AppKit
import Observation

@MainActor
protocol ClipboardManaging {
    func readText() -> String?
    func writeText(_ text: String)
}

@MainActor
struct SystemClipboard: ClipboardManaging {
    func readText() -> String? { NSPasteboard.general.string(forType: .string) }

    func writeText(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

@Observable
@MainActor
final class GrammarMeModel {
    enum Phase: Equatable {
        case idle
        case formatting
        case success(String)
        case failure(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var hasAPIKey: Bool
    private let useCase: FormatSelectedText
    private let clipboard: any ClipboardManaging
    private let apiKeyStore: any APIKeyStoring

    init() {
        let apiKeyStore = KeychainAPIKeyStore()
        self.apiKeyStore = apiKeyStore
        self.hasAPIKey = ((try? apiKeyStore.load()) ?? nil)?.isEmpty == false
        self.useCase = FormatSelectedText(
            formatter: OpenAITextFormatter(),
            apiKey: { (try? apiKeyStore.load()) ?? "" }
        )
        self.clipboard = SystemClipboard()
    }

    init(apiKeyStore: any APIKeyStoring, formatter: any TextFormatting, clipboard: any ClipboardManaging) {
        self.apiKeyStore = apiKeyStore
        self.hasAPIKey = ((try? apiKeyStore.load()) ?? nil)?.isEmpty == false
        self.useCase = FormatSelectedText(formatter: formatter, apiKey: { (try? apiKeyStore.load()) ?? "" })
        self.clipboard = clipboard
    }

    var isFormatting: Bool { phase == .formatting }

    var statusMessage: String? {
        switch phase {
        case .idle: nil
        case .formatting: "Formatting…"
        case .success(let message), .failure(let message): message
        }
    }

    func savedAPIKey() -> String { (try? apiKeyStore.load()) ?? "" }

    @discardableResult
    func saveAPIKey(_ key: String) -> Bool {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { return false }
        do {
            try apiKeyStore.save(trimmedKey)
            hasAPIKey = true
            phase = .success("API key saved.")
            return true
        } catch {
            phase = .failure(error.localizedDescription)
            return false
        }
    }

    func formatClipboard() async {
        guard let text = clipboard.readText() else {
            phase = .failure("Copy some text first.")
            return
        }
        phase = .formatting
        do {
            clipboard.writeText(try await useCase.run(text))
            phase = .success("Formatted text copied.")
        } catch {
            phase = .failure(error.localizedDescription)
        }
    }
}
