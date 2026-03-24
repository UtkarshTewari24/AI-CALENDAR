import Foundation

enum DayTimelineLayout {

    static func layout(
        events: [CalendarEvent],
        hourHeight: CGFloat,
        availableWidth: CGFloat
    ) -> [PositionedEvent] {
        guard !events.isEmpty else { return [] }

        let sorted = events.sorted { $0.startDate < $1.startDate }

        // Group overlapping events into columns
        var columns: [[CalendarEvent]] = []

        for event in sorted {
            let eventStart = event.startDate.minutesSinceStartOfDay()
            var placed = false

            for i in 0..<columns.count {
                let lastInColumn = columns[i].last!
                let lastEnd = lastInColumn.endDate.minutesSinceStartOfDay()
                if eventStart >= lastEnd {
                    columns[i].append(event)
                    placed = true
                    break
                }
            }

            if !placed {
                columns.append([event])
            }
        }

        let columnCount = max(columns.count, 1)
        let columnWidth = availableWidth / CGFloat(columnCount)
        let leftOffset = TimelineConstants.hourLabelWidth

        var result: [PositionedEvent] = []

        for (columnIndex, column) in columns.enumerated() {
            for event in column {
                let startMinutes = event.startDate.minutesSinceStartOfDay()
                let endMinutes = event.endDate.minutesSinceStartOfDay()
                let durationMinutes = max(endMinutes - startMinutes, 15) // Minimum 15 min display

                let y = startMinutes / 60 * hourHeight
                let height = durationMinutes / 60 * hourHeight
                let x = leftOffset + CGFloat(columnIndex) * columnWidth

                result.append(PositionedEvent(
                    event: event,
                    x: x,
                    y: y,
                    width: columnWidth - 2,
                    height: height
                ))
            }
        }

        return result
    }

    // MARK: - Free Time Gap Detection

    struct TimeGap: Identifiable {
        let id = UUID()
        let startMinutes: CGFloat
        let durationMinutes: CGFloat
        let y: CGFloat
        let height: CGFloat
        let startTime: Date
    }

    static func findGaps(
        events: [CalendarEvent],
        hourHeight: CGFloat,
        referenceDate: Date,
        minimumGapMinutes: CGFloat = 15
    ) -> [TimeGap] {
        let sorted = events.sorted { $0.startDate < $1.startDate }
        var gaps: [TimeGap] = []

        // Only show gaps during waking hours (7 AM to 10 PM)
        var currentMinute: CGFloat = 7 * 60
        let dayEnd: CGFloat = 22 * 60

        for event in sorted {
            let eventStart = event.startDate.minutesSinceStartOfDay()
            let eventEnd = event.endDate.minutesSinceStartOfDay()

            // Skip events outside waking hours
            guard eventEnd > 7 * 60 && eventStart < 22 * 60 else { continue }

            let clampedStart = max(eventStart, 7 * 60)

            if clampedStart > currentMinute && (clampedStart - currentMinute) >= minimumGapMinutes {
                let duration = clampedStart - currentMinute
                gaps.append(TimeGap(
                    startMinutes: currentMinute,
                    durationMinutes: duration,
                    y: currentMinute / 60 * hourHeight,
                    height: duration / 60 * hourHeight,
                    startTime: Date.timeFromComponents(
                        hour: Int(currentMinute) / 60,
                        minute: Int(currentMinute) % 60,
                        relativeTo: referenceDate
                    )
                ))
            }
            let clampedEnd = min(eventEnd, 22 * 60)
            if clampedEnd > currentMinute {
                currentMinute = clampedEnd
            }
        }

        // Gap after last event until end of day
        if currentMinute < dayEnd && (dayEnd - currentMinute) >= minimumGapMinutes {
            let duration = dayEnd - currentMinute
            gaps.append(TimeGap(
                startMinutes: currentMinute,
                durationMinutes: duration,
                y: currentMinute / 60 * hourHeight,
                height: duration / 60 * hourHeight,
                startTime: Date.timeFromComponents(
                    hour: Int(currentMinute) / 60,
                    minute: Int(currentMinute) % 60,
                    relativeTo: referenceDate
                )
            ))
        }

        return gaps
    }
}
