import SwiftUI

struct AxiomTaskRow: View {
    let task: AxiomTask

    var body: some View {
        HStack(spacing: AxiomSpacing.md) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(AxiomTypography.body)
                    .foregroundStyle(AxiomColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: AxiomSpacing.sm) {
                    TaskStatusBadge(task: task)

                    if task.totalTimeLogged > 0 {
                        Label("\(task.totalTimeLogged)m", systemImage: "timer")
                            .font(AxiomTypography.micro)
                            .foregroundStyle(AxiomColors.textSecondary)
                    }

                    if task.isStrictMode {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AxiomColors.destructive)
                    }
                }
            }

            Spacer()

            // Verification method icon
            Image(systemName: verificationIcon)
                .font(.system(size: 14))
                .foregroundStyle(AxiomColors.textSecondary)
        }
        .padding(AxiomSpacing.md)
        .background(AxiomColors.surface)
        .cornerRadius(12)
    }

    private var statusColor: Color {
        switch task.status {
        case .pending: return task.isOverdue ? AxiomColors.destructive : AxiomColors.accent
        case .completed: return AxiomColors.success
        case .failed: return AxiomColors.destructive
        }
    }

    private var verificationIcon: String {
        switch task.verificationMethod {
        case .photo: return "camera"
        case .text: return "text.bubble"
        case .both: return "camera.badge.ellipsis"
        }
    }
}
