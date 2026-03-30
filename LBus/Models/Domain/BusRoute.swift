import Foundation

nonisolated struct BusRoute: Hashable, Sendable, Identifiable, Codable {
    let id: String
    let name: String
    let colorHex: String
    let shortName: String

    init(id: String, name: String, colorHex: String, shortName: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.shortName = shortName
    }

    init(from dto: BusRouteDTO) {
        self.init(id: dto.rt, name: dto.rtnm, colorHex: dto.rtclr, shortName: dto.rtdd)
    }
}

nonisolated struct BusDirection: Equatable, Sendable, Codable {
    let direction: String

    init(direction: String) {
        self.direction = direction
    }

    init(from dto: BusDirectionDTO) {
        self.init(direction: dto.dir)
    }
}
