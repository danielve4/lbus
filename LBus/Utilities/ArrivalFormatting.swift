import Foundation

extension BusArrival {

    var countdownText: String {
        switch countdown {
        case .due: return "Due"
        case .minutes(let m): return "\(m) min"
        }
    }

    private static let clockFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.timeZone = TimeZone(identifier: "America/Chicago")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    var clockTimeText: String {
        Self.clockFormatter.string(from: predictedArrival)
    }

    private static let chicagoCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Chicago")!
        return cal
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        f.timeZone = TimeZone(identifier: "America/Chicago")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    var dayContextText: String {
        dayContextText(relativeTo: Date(), calendar: Self.chicagoCalendar)
    }

    func dayContextText(relativeTo now: Date, calendar: Calendar) -> String {
        if calendar.isDate(predictedArrival, inSameDayAs: now) {
            return "Today"
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(predictedArrival, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }
        return Self.dayFormatter.string(from: predictedArrival)
    }

    var distanceText: String? {
        guard distanceToStop > 0 else { return nil }
        if distanceToStop < 1000 {
            return "\(distanceToStop) ft"
        }
        let miles = Double(distanceToStop) / 5280.0
        return String(format: "%.1f mi", miles)
    }
}
