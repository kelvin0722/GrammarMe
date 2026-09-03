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
    private let useCase: FormatSelectedText
    private let clipboard: any ClipboardManaging

    init() {
        self.useCase = FormatSelectedText(
            formatter: OpenAITextFormatter(),
            apiKey: { UserDefaults.standard.string(forKey: AppSettings.apiKey) ?? "" }
        )
        self.clipboard = SystemClipboard()
    }

    init(useCase: FormatSelectedText, clipboard: any ClipboardManaging) {
        self.useCase = useCase
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

    func showAPIKeySaved() { phase = .success("API key saved.") }

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
