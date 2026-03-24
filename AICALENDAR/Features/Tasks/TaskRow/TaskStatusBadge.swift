import SwiftUI

struct TaskStatusBadge: View {
    let task: AxiomTask
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        Text(badgeText)
            .font(AxiomTypography.micro)
            .padding(.horizontal, AxiomSpacing.sm)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.2))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeText: String {
        if task.status == .completed { return "Completed" }
        if task.status == .failed { return "Failed" }
        return task.deadline.deadlineDescription
    }

    private var badgeColor: Color {
        if task.status == .completed { return AxiomColors.success }
        if task.status == .failed { return AxiomColors.destructive }
        if task.isOverdue { return AxiomColors.destructive }
        if task.deadline.isToday { return theme.effectiveAccentColor }
        return AxiomColors.textSecondary
    }
}
