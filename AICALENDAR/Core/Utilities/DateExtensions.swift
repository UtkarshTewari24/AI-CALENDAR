import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) ?? self
    }

    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    var endOfWeek: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? self
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var dayOfWeekShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: self)
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }

    var formattedShortTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }

    func minutesSinceStartOfDay() -> CGFloat {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: self)
        return CGFloat(components.hour ?? 0) * 60 + CGFloat(components.minute ?? 0)
    }

    func formatTimeRange(to endDate: Date) -> String {
        "\(formattedTime) – \(endDate.formattedTime)"
    }

    func daysUntil() -> Int {
        Calendar.current.dateComponents([.day], from: Date().startOfDay, to: startOfDay).day ?? 0
    }

    var deadlineDescription: String {
        let days = daysUntil()
        if days < 0 { return "Overdue" }
        if days == 0 { return "Due Today" }
        if days == 1 { return "Due Tomorrow" }
        return "Due in \(days) days"
    }

    static func timeFromComponents(hour: Int, minute: Int, relativeTo date: Date = Date()) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? date
    }

    func daysOfWeek() -> [Date] {
        let start = startOfWeek
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }
}
