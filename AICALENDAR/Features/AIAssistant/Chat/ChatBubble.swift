import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(AxiomTypography.body)
                    .foregroundStyle(textColor)
                    .padding(.horizontal, AxiomSpacing.md)
                    .padding(.vertical, AxiomSpacing.sm)
                    .background(backgroundColor)
                    .cornerRadius(16)

                Text(message.timestamp.formattedShortTime)
                    .font(.system(size: 10))
                    .foregroundStyle(AxiomColors.textSecondary.opacity(0.6))
            }

            if message.role != .user { Spacer(minLength: 60) }
        }
    }

    private var backgroundColor: Color {
        switch message.role {
        case .user: return AxiomColors.accent
        case .assistant: return AxiomColors.surface
        case .system: return AxiomColors.destructive.opacity(0.15)
        }
    }

    private var textColor: Color {
        switch message.role {
        case .user: return .white
        case .assistant, .system: return AxiomColors.textPrimary
        }
    }
}
