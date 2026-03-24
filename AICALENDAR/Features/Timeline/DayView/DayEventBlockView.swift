import SwiftUI

struct DayEventBlockView: View {
    let event: CalendarEvent
    var isDragging: Bool = false
    var isPast: Bool = false

    @Environment(ThemeManager.self) private var theme

    private var blockColor: Color {
        isPast ? AxiomColors.textSecondary.opacity(0.3) : theme.effectiveAccentColor
    }

    var body: some View {
        HStack(spacing: AxiomSpacing.sm) {
            // Category icon
            Image(systemName: event.resolvedIcon)
                .font(.system(size: 14))
                .foregroundStyle(isPast ? AxiomColors.textSecondary : theme.effectiveAccentColor)
                .frame(width: TimelineConstants.iconColumnWidth)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(AxiomTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isPast ? AxiomColors.textSecondary : AxiomColors.textPrimary)
                    .lineLimit(2)

                Text(event.startDate.formatTimeRange(to: event.endDate))
                    .font(AxiomTypography.micro)
                    .foregroundStyle(isPast ? AxiomColors.textSecondary.opacity(0.7) : AxiomColors.textSecondary)

                HStack(spacing: 4) {
                    Text("\(event.durationMinutes)m")
                        .font(AxiomTypography.micro)
                        .foregroundStyle(AxiomColors.textSecondary.opacity(0.7))

                    if event.linkedTaskId != nil {
                        Image(systemName: isPast ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 10))
                            .foregroundStyle(isPast ? AxiomColors.success : AxiomColors.textSecondary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AxiomSpacing.sm)
        .padding(.vertical, AxiomSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: TimelineConstants.eventBlockCornerRadius)
                .fill(blockColor.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: TimelineConstants.eventBlockCornerRadius)
                .stroke(blockColor.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: TimelineConstants.eventBlockCornerRadius))
        .shadow(color: isDragging ? .black.opacity(0.3) : .clear, radius: isDragging ? 8 : 0)
        .scaleEffect(isDragging ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isDragging)
    }
}
