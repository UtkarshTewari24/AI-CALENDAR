import SwiftUI

struct WeekGridView: View {
    let events: [CalendarEvent]
    let selectedDate: Date
    let hourHeight: CGFloat
    let onDateSelect: (Date) -> Void
    let onEventTap: (CalendarEvent) -> Void

    private var weekDays: [Date] {
        selectedDate.daysOfWeek()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Week header - fixed to intrinsic height
            WeekHeaderView(
                weekDays: weekDays,
                selectedDate: selectedDate,
                onDateSelect: onDateSelect
            )
            .fixedSize(horizontal: false, vertical: true)

            ScrollView(.vertical, showsIndicators: true) {
                HStack(alignment: .top, spacing: 0) {
                    // Hour labels column
                    VStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(hourLabel(for: hour))
                                .font(.system(size: 9, weight: .regular, design: .monospaced))
                                .foregroundStyle(AxiomColors.textSecondary)
                                .frame(width: 32, height: hourHeight, alignment: .topTrailing)
                                .padding(.trailing, 2)
                                .offset(y: -6)
                        }
                    }

                    // Day columns
                    ForEach(weekDays, id: \.self) { day in
                        WeekDayColumnView(
                            day: day,
                            events: events.filter { $0.startDate.isSameDay(as: day) },
                            hourHeight: hourHeight,
                            isToday: day.isToday,
                            onEventTap: onEventTap
                        )
                    }
                }
                .frame(height: hourHeight * 24)
            }
        }
    }

    private func hourLabel(for hour: Int) -> String {
        if hour == 0 { return "12a" }
        if hour < 12 { return "\(hour)a" }
        if hour == 12 { return "12p" }
        return "\(hour - 12)p"
    }
}
