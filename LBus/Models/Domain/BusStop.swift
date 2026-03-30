import Foundation

nonisolated struct BusStop: Equatable, Sendable, Identifiable, Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double

    init(id: String, name: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }

    init(from dto: BusStopDTO) {
        self.init(id: dto.stpid, name: dto.stpnm, latitude: dto.lat, longitude: dto.lon)
    }
}
