import Foundation

struct BusStop: Equatable, Sendable, Identifiable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double

    init(from dto: BusStopDTO) {
        self.id = dto.stpid
        self.name = dto.stpnm
        self.latitude = dto.lat
        self.longitude = dto.lon
    }
}
