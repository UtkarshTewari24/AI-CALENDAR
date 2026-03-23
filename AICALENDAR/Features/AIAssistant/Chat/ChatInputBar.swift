import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: AxiomSpacing.sm) {
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
                        .tint(AxiomColors.accent)
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            text.trimmingCharacters(in: .whitespaces).isEmpty
                                ? AxiomColors.textSecondary.opacity(0.5)
                                : AxiomColors.accent
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
