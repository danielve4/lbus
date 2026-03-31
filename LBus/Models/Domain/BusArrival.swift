import Foundation

enum ArrivalCountdown: Equatable, Sendable {
    case due
    case minutes(Int)
}

struct BusArrival: Equatable, Sendable, Identifiable {
    var id: String { vehicleId + "-" + stopId + "-" + route + "-" + String(predictedArrival.timeIntervalSince1970) }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd HH:mm"
        f.timeZone = TimeZone(identifier: "America/Chicago")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    let timestamp: Date
    let stopId: String
    let stopName: String
    let vehicleId: String
    let distanceToStop: Int
    let route: String
    let routeDirection: String
    let destination: String
    let predictedArrival: Date
    let isDelayed: Bool
    let countdown: ArrivalCountdown

    init(
        timestamp: Date,
        stopId: String,
        stopName: String,
        vehicleId: String,
        distanceToStop: Int,
        route: String,
        routeDirection: String,
        destination: String,
        predictedArrival: Date,
        isDelayed: Bool,
        countdown: ArrivalCountdown
    ) {
        self.timestamp = timestamp
        self.stopId = stopId
        self.stopName = stopName
        self.vehicleId = vehicleId
        self.distanceToStop = distanceToStop
        self.route = route
        self.routeDirection = routeDirection
        self.destination = destination
        self.predictedArrival = predictedArrival
        self.isDelayed = isDelayed
        self.countdown = countdown
    }

    init(from dto: BusPredictionDTO) {
        // Falls back to Date() if parsing fails — silent, keeps UI from crashing
        // but countdown values will be wrong. Check timestamps if debugging odd countdowns.
        let timestamp = Self.dateFormatter.date(from: dto.tmstmp) ?? Date()
        let predictedArrival = Self.dateFormatter.date(from: dto.prdtm) ?? Date()

        let countdown: ArrivalCountdown
        if let prdctdn = dto.prdctdn {
            if prdctdn.uppercased() == "DUE" {
                countdown = .due
            } else if let minutes = Int(prdctdn) {
                countdown = .minutes(minutes)
            } else {
                countdown = .due
            }
        } else {
            let diff = Int(predictedArrival.timeIntervalSince(timestamp) / 60)
            countdown = diff <= 0 ? .due : .minutes(diff)
        }

        self.init(
            timestamp: timestamp,
            stopId: dto.stpid,
            stopName: dto.stpnm,
            vehicleId: dto.vid,
            distanceToStop: dto.dstp,
            route: dto.rt,
            routeDirection: dto.rtdir,
            destination: dto.des,
            predictedArrival: predictedArrival,
            isDelayed: dto.dly,
            countdown: countdown
        )
    }
}
