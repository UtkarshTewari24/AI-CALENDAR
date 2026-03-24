import SwiftUI
import SwiftData

struct DayTimelineView: View {
    let events: [CalendarEvent]
    let hourHeight: CGFloat
    let onEventTap: (CalendarEvent) -> Void
    let onEventReschedule: (CalendarEvent, CGFloat) -> Void

    @Environment(ThemeManager.self) private var theme
    @State private var now = Date()

    private let wakeHour = 6
    private let sleepHour = 22
    private var totalMinutes: CGFloat { CGFloat(sleepHour - wakeHour) * 60 }

    private var sortedEvents: [CalendarEvent] {
        events
            .filter { $0.type != .sleep }
            .sorted { $0.startDate < $1.startDate }
    }

    private var nowMinutes: CGFloat {
        let cal = Calendar.current
        let c = cal.dateComponents([.hour, .minute], from: now)
        return CGFloat(c.hour ?? 0) * 60 + CGFloat(c.minute ?? 0)
    }

    private var wakeMinutes: CGFloat { CGFloat(wakeHour) * 60 }
    private var sleepMinutes: CGFloat { CGFloat(sleepHour) * 60 }

    /// Build segments: alternating gaps and events from wake to sleep
    private var segments: [TimelineSegment] {
        var result: [TimelineSegment] = []
        var cursor = wakeMinutes

        for event in sortedEvents {
            let eventStart = minuteOfDay(event.startDate)
            let eventEnd = minuteOfDay(event.endDate)

            if eventStart > cursor {
                result.append(.gap(startMin: cursor, endMin: eventStart))
            }

            result.append(.event(event: event, startMin: max(eventStart, cursor), endMin: eventEnd))
            cursor = max(cursor, eventEnd)
        }

        if cursor < sleepMinutes {
            result.append(.gap(startMin: cursor, endMin: sleepMinutes))
        }

        return result
    }

    /// Fraction of a segment that is "past" (0.0 = all future, 1.0 = all past)
    private func fillFraction(startMin: CGFloat, endMin: CGFloat) -> CGFloat {
        if nowMinutes >= endMin { return 1.0 }
        if nowMinutes <= startMin { return 0.0 }
        return (nowMinutes - startMin) / (endMin - startMin)
    }

    var body: some View {
        GeometryReader { geo in
            let barWidth: CGFloat = 48
            let availableHeight = max(geo.size.height - 60, 400)
            let pixelsPerMinute = availableHeight / totalMinutes

            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // Hour labels on the left
                    hourLabels(pixelsPerMinute: pixelsPerMinute)
                        .offset(y: 30)

                    // Center column: circles + bar segments
                    VStack(spacing: 0) {
                        // Top circle (wake icon)
                        topBottomCircle(
                            icon: "sun.horizon.fill",
                            minute: wakeMinutes,
                            size: barWidth
                        )

                        // Segments
                        ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                            switch segment {
                            case .gap(let startMin, let endMin):
                                let height = max((endMin - startMin) * pixelsPerMinute, 4)
                                let fraction = fillFraction(startMin: startMin, endMin: endMin)
                                gapLine(width: 6, height: height, fillFraction: fraction)

                            case .event(let event, let startMin, let endMin):
                                let height = max((endMin - startMin) * pixelsPerMinute, 44)
                                let fraction = fillFraction(startMin: startMin, endMin: endMin)

                                Button {
                                    onEventTap(event)
                                } label: {
                                    eventBar(
                                        icon: event.resolvedIcon,
                                        width: barWidth,
                                        height: height,
                                        fillFraction: fraction
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Bottom circle (sleep icon)
                        topBottomCircle(
                            icon: "moon.fill",
                            minute: sleepMinutes,
                            size: barWidth
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .offset(x: -geo.size.width * 0.15)

                    // Event details on the right
                    eventDetails(pixelsPerMinute: pixelsPerMinute, barWidth: barWidth, geoWidth: geo.size.width)
                }
                .padding(.vertical, AxiomSpacing.md)
                .frame(minHeight: geo.size.height)
            }
        }
        .onAppear { startTimer() }
    }

    // MARK: - Partial Fill Views

    /// A gap line with partial accent fill
    private func gapLine(width: CGFloat, height: CGFloat, fillFraction: CGFloat) -> some View {
        ZStack(alignment: .top) {
            // Gray background (full height)
            RoundedRectangle(cornerRadius: width / 2)
                .fill(AxiomColors.surface.opacity(0.6))
                .frame(width: width, height: height)

            // Accent overlay (partial)
            if fillFraction > 0 {
                RoundedRectangle(cornerRadius: width / 2)
                    .fill(theme.effectiveAccentColor)
                    .frame(width: width, height: height)
                    .mask(alignment: .top) {
                        Rectangle()
                            .frame(width: width, height: height * fillFraction)
                    }
            }
        }
        .frame(width: width, height: height)
    }

    /// An event bar with partial accent fill and icon
    private func eventBar(icon: String, width: CGFloat, height: CGFloat, fillFraction: CGFloat) -> some View {
        ZStack {
            // Gray background
            RoundedRectangle(cornerRadius: width / 2)
                .fill(AxiomColors.surface)
                .frame(width: width, height: height)

            // Accent fill from top
            if fillFraction > 0 {
                RoundedRectangle(cornerRadius: width / 2)
                    .fill(theme.effectiveAccentColor)
                    .frame(width: width, height: height)
                    .mask(alignment: .top) {
                        Rectangle()
                            .frame(width: width, height: height * fillFraction)
                    }
            }

            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(fillFraction > 0.5 ? .white.opacity(0.9) : AxiomColors.textSecondary)
        }
        .frame(width: width, height: height)
    }

    /// Top/bottom circle with fill based on time
    private func topBottomCircle(icon: String, minute: CGFloat, size: CGFloat) -> some View {
        let past = nowMinutes >= minute
        return Circle()
            .fill(past ? theme.effectiveAccentColor : AxiomColors.surface)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(past ? .white.opacity(0.9) : AxiomColors.textSecondary)
            }
    }

    // MARK: - Event Details (right side)

    private func eventDetails(pixelsPerMinute: CGFloat, barWidth: CGFloat, geoWidth: CGFloat) -> some View {
        let segs = segments
        var yPositions: [(CalendarEvent, CGFloat)] = []
        var currentY: CGFloat = barWidth

        for seg in segs {
            switch seg {
            case .gap(let startMin, let endMin):
                let height = max((endMin - startMin) * pixelsPerMinute, 4)
                currentY += height
            case .event(let event, let startMin, let endMin):
                let height = max((endMin - startMin) * pixelsPerMinute, 44)
                yPositions.append((event, currentY + height / 2))
                currentY += height
            }
        }

        let centerX = geoWidth * 0.35 + barWidth / 2 + 16

        return ZStack(alignment: .topLeading) {
            ForEach(yPositions, id: \.0.id) { (event, yCenter) in
                let past = event.endDate < now

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(past ? AxiomColors.textSecondary.opacity(0.5) : AxiomColors.textPrimary)
                        .lineLimit(1)

                    Text(event.startDate.formattedShortTime + " – " + event.endDate.formattedShortTime)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(AxiomColors.textSecondary.opacity(past ? 0.4 : 0.7))

                    Text("\(event.durationMinutes) min")
                        .font(.system(size: 10))
                        .foregroundStyle(AxiomColors.textSecondary.opacity(0.4))
                }
                .offset(x: centerX, y: yCenter - 20)
            }
        }
    }

    // MARK: - Hour Labels

    private func hourLabels(pixelsPerMinute: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(stride(from: wakeHour, through: sleepHour, by: 3)), id: \.self) { hour in
                let minutesFromWake = CGFloat(hour - wakeHour) * 60
                let y = minutesFromWake * pixelsPerMinute

                Text(hourString(hour))
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(AxiomColors.textSecondary.opacity(0.4))
                    .offset(x: 8, y: y - 5)
            }
        }
    }

    // MARK: - Helpers

    private func minuteOfDay(_ date: Date) -> CGFloat {
        let cal = Calendar.current
        let c = cal.dateComponents([.hour, .minute], from: date)
        return CGFloat(c.hour ?? 0) * 60 + CGFloat(c.minute ?? 0)
    }

    private func hourString(_ hour: Int) -> String {
        if hour == 0 { return "12a" }
        if hour < 12 { return "\(hour)a" }
        if hour == 12 { return "12p" }
        return "\(hour - 12)p"
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            now = Date()
        }
    }
}

// MARK: - Segment Model

private enum TimelineSegment {
    case gap(startMin: CGFloat, endMin: CGFloat)
    case event(event: CalendarEvent, startMin: CGFloat, endMin: CGFloat)
}

struct PositionedEvent {
    let event: CalendarEvent
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
}
