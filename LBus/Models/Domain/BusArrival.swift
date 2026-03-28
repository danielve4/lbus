import Foundation

enum ArrivalCountdown: Equatable, Sendable {
    case due
    case minutes(Int)
}

struct BusArrival: Equatable, Sendable, Identifiable {
    var id: String { vehicleId + "-" + stopId + "-" + route }

    nonisolated(unsafe) private static let dateFormatter: DateFormatter = {
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

    init(from dto: BusPredictionDTO) {
        // Falls back to Date() if parsing fails — silent, keeps UI from crashing
        // but countdown values will be wrong. Check timestamps if debugging odd countdowns.
        self.timestamp = Self.dateFormatter.date(from: dto.tmstmp) ?? Date()
        self.stopId = dto.stpid
        self.stopName = dto.stpnm
        self.vehicleId = dto.vid
        self.distanceToStop = dto.dstp
        self.route = dto.rt
        self.routeDirection = dto.rtdir
        self.destination = dto.des
        self.predictedArrival = Self.dateFormatter.date(from: dto.prdtm) ?? Date()
        self.isDelayed = dto.dly

        if let prdctdn = dto.prdctdn {
            if prdctdn.uppercased() == "DUE" {
                self.countdown = .due
            } else if let minutes = Int(prdctdn) {
                self.countdown = .minutes(minutes)
            } else {
                self.countdown = .due
            }
        } else {
            let diff = Int(self.predictedArrival.timeIntervalSince(self.timestamp) / 60)
            self.countdown = diff <= 0 ? .due : .minutes(diff)
        }
    }
}
