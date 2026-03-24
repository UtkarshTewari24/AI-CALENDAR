import SwiftUI

struct WeekGridView: View {
    let events: [CalendarEvent]
    let selectedDate: Date
    let hourHeight: CGFloat
    let onDateSelect: (Date) -> Void
    let onEventTap: (CalendarEvent) -> Void

    @Environment(ThemeManager.self) private var theme

    private let wakeHour = 6
    private let sleepHour = 22

    private var weekDays: [Date] {
        selectedDate.daysOfWeek()
    }

    var body: some View {
        GeometryReader { geo in
            let columnWidth = (geo.size.width - 24) / 7
            let barWidth = min(columnWidth - 10, 36)

            HStack(alignment: .top, spacing: 0) {
                // Subtle hour labels
                hourLabels(height: geo.size.height)
                    .frame(width: 0) // overlay style, no width taken
                    .zIndex(1)

                ForEach(weekDays, id: \.self) { day in
                    WeekDayPillColumn(
                        day: day,
                        events: eventsForDay(day),
                        barWidth: barWidth,
                        availableHeight: geo.size.height - 16,
                        wakeHour: wakeHour,
                        sleepHour: sleepHour,
                        isSelected: day.isSameDay(as: selectedDate),
                        onDateSelect: { onDateSelect(day) },
                        onEventTap: onEventTap
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private func eventsForDay(_ day: Date) -> [CalendarEvent] {
        events
            .filter { $0.startDate.isSameDay(as: day) && $0.type != .sleep }
            .sorted { $0.startDate < $1.startDate }
    }

    private func hourLabels(height: CGFloat) -> some View {
        let totalMinutes = CGFloat(sleepHour - wakeHour) * 60
        let usableHeight = height - 16 // match top/bottom padding
        let ppm = usableHeight / totalMinutes

        return ZStack(alignment: .topLeading) {
            ForEach([9, 12, 15, 18, 21], id: \.self) { hour in
                let minutesFromWake = CGFloat(hour - wakeHour) * 60
                // Approximate y including top circle offset
                let topCircleSpace: CGFloat = 28 // approximate space for top circle
                let y = topCircleSpace + minutesFromWake * ppm * 0.85

                Text(shortHour(hour))
                    .font(.system(size: 7, weight: .regular, design: .monospaced))
                    .foregroundStyle(AxiomColors.textSecondary.opacity(0.25))
                    .offset(x: 2, y: y)
            }
        }
    }

    private func shortHour(_ hour: Int) -> String {
        if hour < 12 { return "\(hour)a" }
        if hour == 12 { return "12p" }
        return "\(hour - 12)p"
    }
}

// MARK: - Single Day Column

private struct WeekDayPillColumn: View {
    let day: Date
    let events: [CalendarEvent]
    let barWidth: CGFloat
    let availableHeight: CGFloat
    let wakeHour: Int
    let sleepHour: Int
    let isSelected: Bool
    let onDateSelect: () -> Void
    let onEventTap: (CalendarEvent) -> Void

    @Environment(ThemeManager.self) private var theme

    private var totalMinutes: CGFloat { CGFloat(sleepHour - wakeHour) * 60 }
    private var wakeMin: CGFloat { CGFloat(wakeHour) * 60 }
    private var sleepMin: CGFloat { CGFloat(sleepHour) * 60 }
    private var now: Date { Date() }

    private var nowMin: CGFloat {
        let c = Calendar.current.dateComponents([.hour, .minute], from: now)
        return CGFloat(c.hour ?? 0) * 60 + CGFloat(c.minute ?? 0)
    }

    private func isPast(_ minute: CGFloat) -> Bool {
        if day.startOfDay < Date().startOfDay { return true }  // past day
        if day.startOfDay > Date().startOfDay { return false } // future day
        return nowMin >= minute // today
    }

    private var segments: [WeekSegment] {
        var result: [WeekSegment] = []
        var cursor = wakeMin

        for event in events {
            let eStart = minuteOfDay(event.startDate)
            let eEnd = minuteOfDay(event.endDate)

            if eStart > cursor {
                result.append(.gap(startMin: cursor, endMin: eStart))
            }
            result.append(.event(event: event, startMin: max(eStart, cursor), endMin: eEnd))
            cursor = max(cursor, eEnd)
        }

        if cursor < sleepMin {
            result.append(.gap(startMin: cursor, endMin: sleepMin))
        }

        return result
    }

    var body: some View {
        let circleSize = barWidth * 0.75
        // Space for top circle + segments + bottom circle
        let topBottomSpace = circleSize * 2 + 8
        let segmentHeight = availableHeight - topBottomSpace
        let ppm = segmentHeight / totalMinutes

        VStack(spacing: 0) {
            // Top circle
            Circle()
                .fill(isPast(wakeMin) ? theme.effectiveAccentColor : AxiomColors.surface)
                .frame(width: circleSize, height: circleSize)
                .overlay {
                    if let firstEvent = events.first {
                        Image(systemName: firstEvent.resolvedIcon)
                            .font(.system(size: circleSize * 0.4, weight: .semibold))
                            .foregroundStyle(isPast(wakeMin) ? .white.opacity(0.85) : AxiomColors.textSecondary)
                    } else {
                        Image(systemName: "sun.horizon.fill")
                            .font(.system(size: circleSize * 0.4, weight: .semibold))
                            .foregroundStyle(isPast(wakeMin) ? .white.opacity(0.85) : AxiomColors.textSecondary)
                    }
                }

            // Segments
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .gap(let startMin, let endMin):
                    let height = (endMin - startMin) * ppm
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isPast(endMin) ? theme.effectiveAccentColor.opacity(0.7) : AxiomColors.surface.opacity(0.5))
                        .frame(width: 4, height: max(height, 2))

                case .event(let event, let startMin, let endMin):
                    let height = max((endMin - startMin) * ppm, barWidth * 0.8)
                    let past = isPast(endMin)

                    Button {
                        onEventTap(event)
                    } label: {
                        RoundedRectangle(cornerRadius: barWidth / 2)
                            .fill(past ? theme.effectiveAccentColor : AxiomColors.surface)
                            .frame(width: barWidth, height: height)
                            .overlay {
                                Image(systemName: event.resolvedIcon)
                                    .font(.system(size: barWidth * 0.35, weight: .semibold))
                                    .foregroundStyle(past ? .white.opacity(0.85) : AxiomColors.textSecondary)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            // Bottom circle
            Circle()
                .fill(isPast(sleepMin) ? theme.effectiveAccentColor : AxiomColors.surface)
                .frame(width: circleSize, height: circleSize)
                .overlay {
                    if let lastEvent = events.last {
                        Image(systemName: lastEvent.resolvedIcon)
                            .font(.system(size: circleSize * 0.4, weight: .semibold))
                            .foregroundStyle(isPast(sleepMin) ? .white.opacity(0.85) : AxiomColors.textSecondary)
                    } else {
                        Image(systemName: "moon.fill")
                            .font(.system(size: circleSize * 0.4, weight: .semibold))
                            .foregroundStyle(isPast(sleepMin) ? .white.opacity(0.85) : AxiomColors.textSecondary)
                    }
                }
        }
        .contentShape(Rectangle())
        .onTapGesture { onDateSelect() }
    }

    private func minuteOfDay(_ date: Date) -> CGFloat {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return CGFloat(c.hour ?? 0) * 60 + CGFloat(c.minute ?? 0)
    }
}

private enum WeekSegment {
    case gap(startMin: CGFloat, endMin: CGFloat)
    case event(event: CalendarEvent, startMin: CGFloat, endMin: CGFloat)
}
