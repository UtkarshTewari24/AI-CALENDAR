import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void

    @Environment(ThemeManager.self) private var theme
    @State private var speechService = SpeechRecognitionService()

    var body: some View {
        HStack(spacing: AxiomSpacing.sm) {
            // Microphone button
            Button {
                if speechService.isRecording {
                    speechService.stopRecording()
                    if !speechService.transcribedText.isEmpty {
                        text = speechService.transcribedText
                    }
                } else {
                    speechService.transcribedText = ""
                    try? speechService.startRecording()
                }
            } label: {
                Image(systemName: speechService.isRecording ? "mic.fill" : "mic")
                    .font(.system(size: 20))
                    .foregroundStyle(speechService.isRecording ? .red : theme.effectiveAccentColor)
                    .frame(width: 36, height: 36)
            }

            TextField("Ask Axiom anything...", text: $text, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, AxiomSpacing.md)
                .padding(.vertical, AxiomSpacing.sm)
                .background(AxiomColors.surface)
                .cornerRadius(20)
                .foregroundStyle(AxiomColors.textPrimary)

            Button {
                onSend()
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(theme.effectiveAccentColor)
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            text.trimmingCharacters(in: .whitespaces).isEmpty
                                ? AxiomColors.textSecondary.opacity(0.5)
                                : theme.effectiveAccentColor
                        )
                }
            }
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
        }
        .padding(.horizontal, AxiomSpacing.md)
        .padding(.vertical, AxiomSpacing.sm)
        .background(AxiomColors.backgroundSecondary)
    }
}
