import SwiftUI

struct WeekDayColumnView: View {
    let day: Date
    let events: [CalendarEvent]
    let hourHeight: CGFloat
    let isToday: Bool
    let onEventTap: (CalendarEvent) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background highlight for today
            if isToday {
                Rectangle()
                    .fill(AxiomColors.accent.opacity(0.035))
            }

            // Hour grid lines
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { _ in
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(AxiomColors.surface.opacity(0.22))
                            .frame(height: 0.5)
                        Spacer()
                    }
                    .frame(height: hourHeight)
                }
            }

            // Event blocks
            ForEach(events, id: \.id) { event in
                let startMinutes = event.startDate.minutesSinceStartOfDay()
                let endMinutes = event.endDate.minutesSinceStartOfDay()
                let duration = max(endMinutes - startMinutes, 15)

                let yOffset = startMinutes / 60.0 * hourHeight
                let height = max(duration / 60.0 * hourHeight, 20)

                WeekEventBlock(event: event)
                    .frame(height: height)
                    .offset(y: yOffset)
                    .padding(.horizontal, 1)
                    .onTapGesture {
                        onEventTap(event)
                    }
            }

            // Now line for today
            if isToday {
                let nowMinutes = Date().minutesSinceStartOfDay()
                let yOffset = nowMinutes / 60.0 * hourHeight
                Rectangle()
                    .fill(AxiomColors.nowLine)
                    .frame(height: 1.5)
                    .offset(y: yOffset)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WeekEventBlock: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 1)
                .fill(AxiomColors.color(for: event.type))
                .frame(width: 2)

            Text(event.title)
                .font(.system(size: 9))
                .foregroundStyle(AxiomColors.textPrimary)
                .lineLimit(1)
                .padding(.leading, 2)

            Spacer(minLength: 0)
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(AxiomColors.color(for: event.type).opacity(0.15))
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
