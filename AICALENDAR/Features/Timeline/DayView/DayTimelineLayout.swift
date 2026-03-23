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
}
