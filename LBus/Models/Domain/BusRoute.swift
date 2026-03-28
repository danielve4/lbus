import Foundation

struct BusRoute: Equatable, Sendable, Identifiable {
    let id: String
    let name: String
    let colorHex: String
    let shortName: String

    init(from dto: BusRouteDTO) {
        self.id = dto.rt
        self.name = dto.rtnm
        self.colorHex = dto.rtclr
        self.shortName = dto.rtdd
    }
}

struct BusDirection: Equatable, Sendable {
    let direction: String

    init(from dto: BusDirectionDTO) {
        self.direction = dto.dir
    }
}
