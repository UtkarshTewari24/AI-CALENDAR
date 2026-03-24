import SwiftUI

struct WeekHeaderView: View {
    let weekDays: [Date]
    let selectedDate: Date
    let onDateSelect: (Date) -> Void

    @Environment(ThemeManager.self) private var theme

    var body: some View {
        HStack(spacing: 0) {
            // Spacer for hour label column
            Color.clear.frame(width: 32)

            ForEach(weekDays, id: \.self) { day in
                VStack(spacing: 2) {
                    Text(day.dayOfWeekShort)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(day.isToday ? theme.effectiveAccentColor : AxiomColors.textSecondary)

                    ZStack {
                        if day.isToday {
                            Circle()
                                .fill(theme.effectiveAccentColor)
                                .frame(width: 22, height: 22)
                        }

                        Text(day.dayNumber)
                            .font(.system(size: 12, weight: day.isToday ? .bold : .regular))
                            .foregroundStyle(day.isToday ? .white : AxiomColors.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    onDateSelect(day)
                }
            }
        }
        .padding(.vertical, 6)
        .background(AxiomColors.backgroundSecondary.opacity(0.9))
    }
}
