import Foundation
import Testing
@testable import LBus

// MARK: - Test Helpers

private func makeArrival(
    predictedArrival: Date = Date(),
    distanceToStop: Int = 0,
    countdown: ArrivalCountdown = .minutes(5),
    isDelayed: Bool = false
) -> BusArrival {
    BusArrival(
        timestamp: Date(),
        stopId: "456",
        stopName: "Madison & Jefferson",
        vehicleId: "8184",
        distanceToStop: distanceToStop,
        route: "20",
        routeDirection: "Westbound",
        destination: "Austin",
        predictedArrival: predictedArrival,
        isDelayed: isDelayed,
        countdown: countdown
    )
}

private func chicagoCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/Chicago")!
    return cal
}

// MARK: - Tests

@Suite struct ArrivalFormattingTests {

    // MARK: - countdownText

    @Test func countdownTextDue() {
        let arrival = makeArrival(countdown: .due)
        #expect(arrival.countdownText == "Due")
    }

    @Test func countdownTextMinutes() {
        let arrival = makeArrival(countdown: .minutes(5))
        #expect(arrival.countdownText == "5 min")
    }

    @Test func countdownTextOneMinute() {
        let arrival = makeArrival(countdown: .minutes(1))
        #expect(arrival.countdownText == "1 min")
    }

    // MARK: - distanceText

    @Test func distanceTextNilWhenZero() {
        let arrival = makeArrival(distanceToStop: 0)
        #expect(arrival.distanceText == nil)
    }

    @Test func distanceTextFeetUnder1000() {
        let arrival = makeArrival(distanceToStop: 686)
        #expect(arrival.distanceText == "686 ft")
    }

    @Test func distanceTextMilesOver1000() {
        let arrival = makeArrival(distanceToStop: 7000)
        #expect(arrival.distanceText == "1.3 mi")
    }

    @Test func distanceTextExactly1000UsesMiles() {
        let arrival = makeArrival(distanceToStop: 1000)
        #expect(arrival.distanceText == "0.2 mi")
    }

    // MARK: - clockTimeText

    @Test func clockTimeTextFormats12Hour() {
        var cal = chicagoCalendar()
        let components = DateComponents(year: 2026, month: 3, day: 30, hour: 16, minute: 6)
        let date = cal.date(from: components)!
        let arrival = makeArrival(predictedArrival: date)
        #expect(arrival.clockTimeText == "4:06 PM")
    }

    @Test func clockTimeTextFormatsMorning() {
        let cal = chicagoCalendar()
        let components = DateComponents(year: 2026, month: 3, day: 30, hour: 9, minute: 30)
        let date = cal.date(from: components)!
        let arrival = makeArrival(predictedArrival: date)
        #expect(arrival.clockTimeText == "9:30 AM")
    }

    // MARK: - dayContextText

    @Test func dayContextTextToday() {
        let cal = chicagoCalendar()
        let now = cal.date(from: DateComponents(year: 2026, month: 3, day: 30, hour: 12))!
        let arrival = makeArrival(predictedArrival: cal.date(from: DateComponents(year: 2026, month: 3, day: 30, hour: 16))!)
        #expect(arrival.dayContextText(relativeTo: now, calendar: cal) == "Today")
    }

    @Test func dayContextTextTomorrow() {
        let cal = chicagoCalendar()
        let now = cal.date(from: DateComponents(year: 2026, month: 3, day: 30, hour: 23))!
        let arrival = makeArrival(predictedArrival: cal.date(from: DateComponents(year: 2026, month: 3, day: 31, hour: 0, minute: 15))!)
        #expect(arrival.dayContextText(relativeTo: now, calendar: cal) == "Tomorrow")
    }

    @Test func dayContextTextFutureDate() {
        let cal = chicagoCalendar()
        let now = cal.date(from: DateComponents(year: 2026, month: 3, day: 30, hour: 12))!
        let arrival = makeArrival(predictedArrival: cal.date(from: DateComponents(year: 2026, month: 4, day: 2, hour: 10))!)
        #expect(arrival.dayContextText(relativeTo: now, calendar: cal) == "Apr 2")
    }
}
