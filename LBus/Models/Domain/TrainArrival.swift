import Foundation

struct TrainPosition: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
    let heading: Int

    init?(from dto: TrainPositionDTO) {
        guard let lat = Double(dto.lat),
              let lon = Double(dto.lon),
              let hdg = Int(dto.heading) else { return nil }
        self.latitude = lat
        self.longitude = lon
        self.heading = hdg
    }
}

struct TrainArrival: Equatable, Sendable, Identifiable {
    var id: String { runNumber + "-" + stationId + "-" + stopId }

    nonisolated(unsafe) private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.timeZone = TimeZone(identifier: "America/Chicago")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    let stationId: String
    let stopId: String
    let stationName: String
    let stopDescription: String
    let runNumber: String
    let line: String
    let destinationStopId: String
    let destinationName: String
    let direction: String
    let predictionTime: Date
    let arrivalTime: Date
    let isApproaching: Bool
    let isScheduled: Bool
    let isDelayed: Bool
    let hasAlert: Bool
    let countdown: ArrivalCountdown
    let latitude: Double?
    let longitude: Double?
    let heading: Int?

    init(from dto: TrainEtaPredictionDTO) {
        self.stationId = dto.staId
        self.stopId = dto.stpId
        self.stationName = dto.staNm
        self.stopDescription = dto.stpDe
        self.runNumber = dto.rn
        self.line = dto.rt
        self.destinationStopId = dto.destSt
        self.destinationName = dto.destNm
        self.direction = dto.trDr
        // Falls back to Date() if parsing fails — silent, keeps UI from crashing
        // but countdown values will be wrong. Check timestamps if debugging odd countdowns.
        self.predictionTime = Self.dateFormatter.date(from: dto.prdt) ?? Date()
        self.arrivalTime = Self.dateFormatter.date(from: dto.arrT) ?? Date()
        self.isApproaching = dto.isApp == "1"
        self.isScheduled = dto.isSch == "1"
        self.isDelayed = dto.isDly == "1"
        self.hasAlert = dto.isFlt == "1"
        self.latitude = dto.lat.flatMap(Double.init)
        self.longitude = dto.lon.flatMap(Double.init)
        self.heading = dto.heading.flatMap(Int.init)

        if self.isApproaching {
            self.countdown = .due
        } else {
            let diff = Int(self.arrivalTime.timeIntervalSince(self.predictionTime) / 60)
            self.countdown = diff <= 0 ? .due : .minutes(diff)
        }
    }
}
