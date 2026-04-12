import Foundation

// MARK: - Shared Formatters

private let chicagoClockFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "h:mm a"
    f.timeZone = TimeZone(identifier: "America/Chicago")
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

private let chicagoDayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MMM d"
    f.timeZone = TimeZone(identifier: "America/Chicago")
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

private let chicagoCalendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/Chicago")!
    return cal
}()

// MARK: - BusArrival

extension BusArrival {

    var countdownText: String {
        switch countdown {
        case .due: return "Due"
        case .minutes(let m): return "\(m) min"
        }
    }

    var clockTimeText: String {
        chicagoClockFormatter.string(from: predictedArrival)
    }

    var dayContextText: String {
        dayContextText(relativeTo: Date(), calendar: chicagoCalendar)
    }

    func dayContextText(relativeTo now: Date, calendar: Calendar) -> String {
        if calendar.isDate(predictedArrival, inSameDayAs: now) {
            return "Today"
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(predictedArrival, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }
        return chicagoDayFormatter.string(from: predictedArrival)
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

// MARK: - TrainArrival

extension TrainArrival {

    var countdownText: String {
        switch countdown {
        case .due: return "Due"
        case .minutes(let m): return "\(m) min"
        }
    }

    var clockTimeText: String {
        chicagoClockFormatter.string(from: arrivalTime)
    }

    var dayContextText: String {
        dayContextText(relativeTo: Date(), calendar: chicagoCalendar)
    }

    func dayContextText(relativeTo now: Date, calendar: Calendar) -> String {
        if calendar.isDate(arrivalTime, inSameDayAs: now) {
            return "Today"
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(arrivalTime, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }
        return chicagoDayFormatter.string(from: arrivalTime)
    }
}
