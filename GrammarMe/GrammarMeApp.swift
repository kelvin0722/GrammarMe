import AppKit
import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let serviceProvider = GrammarMeServiceProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = serviceProvider
        NSUpdateDynamicServices()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}

@main
struct GrammarMeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("GrammarMe", systemImage: "text.badge.checkmark") {
            GrammarMeMenuView()
        }
        .menuBarExtraStyle(.window)
    }
}

struct GrammarMeMenuView: View {
    private enum Page { case home, settings }

    @AppStorage("openAIAPIKey") private var apiKey = ""
    @AppStorage("lastServiceStatus") private var lastServiceStatus = ""
    @State private var page: Page = .home
    @State private var draftKey = ""
    @State private var statusMessage: String?
    @State private var isFormatting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                if page == .settings {
                    Button { page = .home } label: { Image(systemName: "chevron.left") }
                        .buttonStyle(.plain).accessibilityLabel("Back")
                }
                Label(page == .home ? "GrammarMe" : "Settings", systemImage: page == .home ? "text.badge.checkmark" : "gearshape")
                    .font(.headline)
                Spacer()
            }
            Divider()

            if page == .home { home }
            else { settings }

            Divider()
            HStack {
                if page == .home {
                    Button { draftKey = apiKey; page = .settings } label: { Label("Settings", systemImage: "gearshape") }
                }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(16).frame(width: 330)
    }

    private var home: some View {
        Group {
            Text(apiKey.isEmpty ? "Add an API key to get started." : "Ready to format selected text.")
                .font(.subheadline).foregroundStyle(.secondary)
            Text("For in-place editing, select text and choose Services → Format with GrammarMe.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Button { formatClipboard() } label: {
                if isFormatting { ProgressView().controlSize(.small) }
                else { Label("Format Clipboard", systemImage: "doc.on.clipboard") }
            }
            .buttonStyle(.bordered).disabled(apiKey.isEmpty || isFormatting)
            Text("Fallback for apps that don’t support macOS Services.")
                .font(.caption2).foregroundStyle(.tertiary)
            if let statusMessage { Text(statusMessage).font(.caption).foregroundStyle(.secondary) }
            else if !lastServiceStatus.isEmpty { Text(lastServiceStatus).font(.caption).foregroundStyle(.secondary) }
        }
    }

    private var settings: some View {
        Group {
            Text("OpenAI API key").font(.subheadline.bold())
            SecureField("sk-…", text: $draftKey)
                .textFieldStyle(.roundedBorder).accessibilityLabel("OpenAI API key")
            Text("Text is sent to OpenAI only when formatting is invoked.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Save") {
                    apiKey = draftKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    page = .home
                    statusMessage = "API key saved."
                }
                .buttonStyle(.borderedProminent)
                .disabled(draftKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func formatClipboard() {
        guard let text = NSPasteboard.general.string(forType: .string) else {
            statusMessage = "Copy some text first."
            return
        }
        isFormatting = true; statusMessage = "Formatting…"
        let savedKey = apiKey
        let useCase = FormatSelectedText(formatter: OpenAITextFormatter(), apiKey: { savedKey })
        Task {
            do {
                let result = try await useCase.run(text)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(result, forType: .string)
                statusMessage = "Formatted text copied."
            } catch { statusMessage = error.localizedDescription }
            isFormatting = false
        }
    }
}
