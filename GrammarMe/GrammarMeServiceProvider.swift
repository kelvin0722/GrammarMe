import AppKit
import UserNotifications

final class GrammarMeServiceProvider: NSObject {
    private let useCase: FormatSelectedText
    private let progressPanel = FormattingProgressPanel()

    override init() {
        useCase = FormatSelectedText(
            formatter: OpenAITextFormatter(),
            apiKey: { UserDefaults.standard.string(forKey: AppSettings.apiKey) ?? "" }
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

        publishStatus("Formatting selected text…")
        progressPanel.show()
        let resultBox = LockedBox<Result<String, Error>>()
        let useCase = self.useCase
        Task.detached {
            do { resultBox.set(.success(try await useCase.run(selectedText))) }
            catch { resultBox.set(.failure(error)) }
        }

        let deadline = Date().addingTimeInterval(55)
        while resultBox.value == nil && Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.03))
        }
        progressPanel.hide()

        guard let outcome = resultBox.value else {
            errorPointer.pointee = "GrammarMe timed out. Please try again." as NSString
            publishStatus("Formatting timed out. Please try again.")
            return
        }
        switch outcome {
        case .success(let formattedText):
            pasteboard.clearContents()
            pasteboard.setString(formattedText, forType: .string)
            publishStatus("Formatting complete.")
            notify(title: "Formatting complete", body: "The selected text was updated.")
        case .failure(let error):
            errorPointer.pointee = error.localizedDescription as NSString
            publishStatus(error.localizedDescription)
            notify(title: "GrammarMe couldn't format that", body: error.localizedDescription)
        }
    }

    private func publishStatus(_ message: String) {
        UserDefaults.standard.set(message, forKey: AppSettings.lastServiceStatus)
    }

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}

private final class FormattingProgressPanel {
    private let panel: NSPanel
    private let spinner = NSProgressIndicator()

    init() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 104),
            styleMask: [.titled, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false

        let title = NSTextField(labelWithString: "Formatting with GrammarMe…")
        title.font = .systemFont(ofSize: 14, weight: .semibold)
        let detail = NSTextField(labelWithString: "Your selected text will be replaced when it’s ready.")
        detail.font = .systemFont(ofSize: 11)
        detail.textColor = .secondaryLabelColor
        spinner.style = .spinning
        spinner.controlSize = .small

        let textStack = NSStackView(views: [title, detail])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4
        let stack = NSStackView(views: [spinner, textStack])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor)
        ])
        panel.contentView = content
    }

    func show() {
        spinner.startAnimation(nil)
        panel.center()
        panel.orderFrontRegardless()
        panel.displayIfNeeded()
    }

    func hide() {
        spinner.stopAnimation(nil)
        panel.orderOut(nil)
    }
}

private nonisolated final class LockedBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValue: Value?
    var value: Value? { lock.withLock { storedValue } }
    func set(_ value: Value) { lock.withLock { storedValue = value } }
}
