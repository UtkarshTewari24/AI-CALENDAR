import SwiftUI
import SwiftData

@Observable
final class TimelineViewModel {
    var selectedDate: Date = Date()
    var displayMode: TimelineDisplayMode

    var showingAddSheet = false
    var selectedEvent: CalendarEvent?

    init() {
        self.displayMode = UserDefaultsService.timelineDisplayMode
    }

    func toggleDisplayMode() {
        withAnimation(.easeInOut(duration: 0.25)) {
            displayMode = displayMode == .day ? .week : .day
            UserDefaultsService.timelineDisplayMode = displayMode
        }
    }

    func selectDate(_ date: Date) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            selectedDate = date
            displayMode = .day
            UserDefaultsService.timelineDisplayMode = .day
        }
    }

    func navigateDay(by offset: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            selectedDate = newDate
        }
    }

    func navigateWeek(by offset: Int) {
        guard let newDate = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: selectedDate) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            selectedDate = newDate
        }
    }

    func eventsForDate(_ date: Date, from allEvents: [CalendarEvent]) -> [CalendarEvent] {
        allEvents.filter { $0.startDate.isSameDay(as: date) }
            .sorted { $0.startDate < $1.startDate }
    }

    func eventsForWeek(from allEvents: [CalendarEvent]) -> [CalendarEvent] {
        let weekStart = selectedDate.startOfWeek
        let weekEnd = weekStart.endOfWeek
        return allEvents.filter { $0.startDate >= weekStart.startOfDay && $0.startDate <= weekEnd.endOfDay }
    }

    func rescheduleEvent(_ event: CalendarEvent, toStartMinutes: CGFloat, hourHeight: CGFloat) {
        let totalMinutes = Int(toStartMinutes)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        let calendar = Calendar.current
        let duration = event.endDate.timeIntervalSince(event.startDate)

        var components = calendar.dateComponents([.year, .month, .day], from: event.startDate)
        components.hour = hours
        components.minute = minutes

        if let newStart = calendar.date(from: components) {
            event.startDate = newStart
            event.endDate = newStart.addingTimeInterval(duration)
        }
    }
}
