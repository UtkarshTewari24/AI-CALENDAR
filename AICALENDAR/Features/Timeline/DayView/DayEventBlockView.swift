import SwiftUI

struct DayEventBlockView: View {
    let event: CalendarEvent
    var isDragging: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // Colored left border
            RoundedRectangle(cornerRadius: 2)
                .fill(AxiomColors.color(for: event.type))
                .frame(width: TimelineConstants.eventBlockBorderWidth)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(AxiomTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(AxiomColors.textPrimary)
                    .lineLimit(2)

                Text(event.startDate.formattedShortTime)
                    .font(AxiomTypography.micro)
                    .foregroundStyle(AxiomColors.textSecondary)
            }
            .padding(.horizontal, AxiomSpacing.sm)
            .padding(.vertical, AxiomSpacing.xs)

            Spacer(minLength: 0)

            if event.linkedTaskId != nil {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(AxiomColors.accent)
                    .padding(.trailing, AxiomSpacing.sm)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: TimelineConstants.eventBlockCornerRadius)
                .fill(AxiomColors.color(for: event.type).opacity(0.15))
        )
        .clipShape(RoundedRectangle(cornerRadius: TimelineConstants.eventBlockCornerRadius))
        .shadow(color: isDragging ? .black.opacity(0.3) : .clear, radius: isDragging ? 8 : 0)
        .scaleEffect(isDragging ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isDragging)
    }
}
