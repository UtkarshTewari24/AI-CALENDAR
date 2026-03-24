import SwiftUI

struct ChatBubble: View {
    @Environment(ThemeManager.self) private var theme
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(cleanedContent)
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

    /// Strip markdown formatting for clean display
    private var cleanedContent: String {
        var text = message.content
        // Remove bold markers
        text = text.replacingOccurrences(of: "**", with: "")
        text = text.replacingOccurrences(of: "__", with: "")
        // Remove italic markers (single * or _ around words)
        // Be careful not to remove * in bullet points
        text = text.replacingOccurrences(of: "\\*([^*\\n]+)\\*", with: "$1", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\_([^_\\n]+)\\_", with: "$1", options: .regularExpression)
        // Remove code backticks
        text = text.replacingOccurrences(of: "`", with: "")
        // Remove heading markers
        text = text.replacingOccurrences(of: "^#{1,6}\\s*", with: "", options: .regularExpression)
        // Clean up extra whitespace
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return text
    }

    private var backgroundColor: Color {
        switch message.role {
        case .user: return theme.effectiveAccentColor
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
