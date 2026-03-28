import Foundation

struct TrainLine: Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let colorHex: String
    let textColorHex: String

    init(from dto: TrainLineDTO) {
        self.id = dto.routeId
        self.name = dto.name
        self.colorHex = dto.color
        self.textColorHex = dto.textColor
    }
}
