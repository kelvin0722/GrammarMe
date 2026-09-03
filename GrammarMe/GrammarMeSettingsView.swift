import SwiftUI

struct GrammarMeSettingsView: View {
    @Binding var apiKey: String
    let save: () -> Void

    var body: some View {
        Group {
            Text("OpenAI API key").font(.subheadline.bold())
            SecureField("sk-…", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("OpenAI API key")
            Text("Text is sent to OpenAI only when formatting is invoked.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Save", action: save)
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
