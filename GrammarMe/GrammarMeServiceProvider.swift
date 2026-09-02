import AppKit
import UserNotifications

final class GrammarMeServiceProvider: NSObject {
    private let useCase: FormatSelectedText

    override init() {
        useCase = FormatSelectedText(
            formatter: OpenAITextFormatter(),
            apiKey: { UserDefaults.standard.string(forKey: "openAIAPIKey") ?? "" }
        )
        super.init()
    }

    init(useCase: FormatSelectedText) {
        self.useCase = useCase
        super.init()
    }

    @objc(formatText:userData:error:) func formatText(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error errorPointer: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        let selectedText = pasteboard.string(forType: .string)
            ?? pasteboard.string(forType: NSPasteboard.PasteboardType("public.plain-text"))
            ?? pasteboard.string(forType: NSPasteboard.PasteboardType("NSStringPboardType"))
        guard let selectedText else {
            errorPointer.pointee = FormattingJourneyError.noSelectedText.localizedDescription as NSString
            return
        }

        let semaphore = DispatchSemaphore(value: 0)
        let resultBox = LockedBox<Result<String, Error>>()
        let useCase = self.useCase
        Task.detached {
            do { resultBox.set(.success(try await useCase.run(selectedText))) }
            catch { resultBox.set(.failure(error)) }
            semaphore.signal()
        }

        guard semaphore.wait(timeout: .now() + 55) == .success, let outcome = resultBox.value else {
            errorPointer.pointee = "GrammarMe timed out. Please try again." as NSString
            return
        }
        switch outcome {
        case .success(let formattedText):
            pasteboard.clearContents()
            pasteboard.setString(formattedText, forType: .string)
            notify(title: "Formatting complete", body: "The selected text was updated.")
        case .failure(let error):
            errorPointer.pointee = error.localizedDescription as NSString
            notify(title: "GrammarMe couldn't format that", body: error.localizedDescription)
        }
    }

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}

private nonisolated final class LockedBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValue: Value?
    var value: Value? { lock.withLock { storedValue } }
    func set(_ value: Value) { lock.withLock { storedValue = value } }
}
