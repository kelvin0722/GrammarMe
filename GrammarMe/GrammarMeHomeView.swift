import SwiftUI

struct GrammarMeHomeView: View {
    let hasAPIKey: Bool
    let isFormatting: Bool
    let statusMessage: String?
    let formatClipboard: () -> Void

    var body: some View {
        Group {
            Text(hasAPIKey ? "Ready to format selected text." : "Add an API key to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("For in-place editing, select text and choose Services → Format with GrammarMe.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: formatClipboard) {
                if isFormatting { ProgressView().controlSize(.small) }
                else { Label("Format Clipboard", systemImage: "doc.on.clipboard") }
            }
            .buttonStyle(.bordered)
            .disabled(!hasAPIKey || isFormatting)
            Text("Fallback for apps that don’t support macOS Services.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            if let statusMessage {
                Text(statusMessage).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
