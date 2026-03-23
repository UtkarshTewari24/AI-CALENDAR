import SwiftUI

struct WeekHeaderView: View {
    let weekDays: [Date]
    let selectedDate: Date
    let onDateSelect: (Date) -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Spacer for hour label column
            Color.clear.frame(width: 32)

            ForEach(weekDays, id: \.self) { day in
                VStack(spacing: 2) {
                    Text(day.dayOfWeekShort)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(day.isToday ? AxiomColors.accent : AxiomColors.textSecondary)

                    ZStack {
                        if day.isToday {
                            Circle()
                                .fill(AxiomColors.accent)
                                .frame(width: 28, height: 28)
                        }

                        Text(day.dayNumber)
                            .font(.system(size: 14, weight: day.isToday ? .bold : .regular))
                            .foregroundStyle(day.isToday ? .white : AxiomColors.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    onDateSelect(day)
                }
            }
        }
        .padding(.vertical, AxiomSpacing.sm)
        .background(AxiomColors.backgroundSecondary)
    }
}
