import AppKit
import SwiftUI

struct GrammarMeMenuView: View {
    private enum Page { case home, settings }

    @AppStorage(AppSettings.lastServiceStatus) private var lastServiceStatus = ""
    @State private var model = GrammarMeModel()
    @State private var page: Page = .home
    @State private var draftKey = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            if page == .home {
                GrammarMeHomeView(
                    hasAPIKey: model.hasAPIKey,
                    isFormatting: model.isFormatting,
                    statusMessage: model.statusMessage ?? nonEmpty(lastServiceStatus),
                    formatClipboard: { Task { await model.formatClipboard() } }
                )
            } else {
                GrammarMeSettingsView(apiKey: $draftKey, save: saveAPIKey)
            }
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 330)
    }

    private var header: some View {
        HStack {
            if page == .settings {
                Button { page = .home } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
            }
            Label(page == .home ? "GrammarMe" : "Settings", systemImage: page == .home ? "text.badge.checkmark" : "gearshape")
                .font(.headline)
            Spacer()
        }
    }

    private var footer: some View {
        HStack {
            if page == .home {
                Button { draftKey = model.savedAPIKey(); page = .settings } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
    }

    private func saveAPIKey() {
        if model.saveAPIKey(draftKey) { page = .home }
    }

    private func nonEmpty(_ value: String) -> String? { value.isEmpty ? nil : value }
}
