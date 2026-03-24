import SwiftUI

struct ConfirmationCard: View {
    @Environment(ThemeManager.self) private var theme
    let action: PendingAction
    let onApply: () -> Void
    let onCancel: () -> Void

    private var changeLines: [ChangeItem] {
        action.toolCalls.map { toolCall in
            let name = toolCall.function.name
            let args = parseArgs(toolCall.function.arguments)

            switch name {
            case "add_event":
                let title = args["title"] as? String ?? "Event"
                return ChangeItem(icon: "plus.circle.fill", color: .green, text: title)
            case "delete_event":
                return ChangeItem(icon: "minus.circle.fill", color: .red, text: "Remove event")
            case "update_event":
                let title = args["title"] as? String
                return ChangeItem(icon: "pencil.circle.fill", color: .orange, text: title ?? "Update event")
            case "swap_events":
                return ChangeItem(icon: "arrow.up.arrow.down.circle.fill", color: .blue, text: "Swap events")
            case "create_task":
                let title = args["title"] as? String ?? "Task"
                return ChangeItem(icon: "checkmark.circle.fill", color: theme.effectiveAccentColor, text: title)
            default:
                return ChangeItem(icon: "circle.fill", color: AxiomColors.textSecondary, text: name)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AxiomSpacing.sm) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(theme.effectiveAccentColor)
                Text("\(action.toolCalls.count) change\(action.toolCalls.count == 1 ? "" : "s")")
                    .font(AxiomTypography.headline)
                    .foregroundStyle(AxiomColors.textPrimary)
            }

            // Clean list of changes
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(changeLines.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(item.color)
                            .frame(width: 20)

                        Text(item.text)
                            .font(.system(size: 14))
                            .foregroundStyle(AxiomColors.textPrimary)
                            .lineLimit(1)
                    }
                }
            }

            HStack(spacing: AxiomSpacing.md) {
                Button("Cancel") {
                    onCancel()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(AxiomColors.surface)
                .foregroundStyle(AxiomColors.textPrimary)
                .font(AxiomTypography.headline)
                .cornerRadius(10)

                Button("Apply") {
                    onApply()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(theme.effectiveAccentColor)
                .foregroundStyle(.white)
                .font(AxiomTypography.headline)
                .cornerRadius(10)
            }
        }
        .padding(AxiomSpacing.md)
        .background(AxiomColors.surface)
        .cornerRadius(16)
        .padding(.horizontal, AxiomSpacing.md)
    }

    private func parseArgs(_ json: String) -> [String: Any] {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}

private struct ChangeItem {
    let icon: String
    let color: Color
    let text: String
}
