import Foundation

nonisolated struct TrainLine: Hashable, Sendable, Identifiable, Codable {
    let id: String
    let name: String
    let colorHex: String
    let textColorHex: String

    init(id: String, name: String, colorHex: String, textColorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.textColorHex = textColorHex
    }

    init(from dto: TrainLineDTO) {
        self.init(id: dto.routeId, name: dto.name, colorHex: dto.color, textColorHex: dto.textColor)
    }
}
