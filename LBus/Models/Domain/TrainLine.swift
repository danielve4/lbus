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

    /// Local fallback mapping from line IDs to TrainLine values with official CTA colors.
    /// Used when constructing a TrainLine from persisted favorite data without an API call.
    static let fallbackLinesById: [String: TrainLine] = [
        "Red": TrainLine(id: "Red", name: "Red Line", colorHex: "C60C30", textColorHex: "FFFFFF"),
        "Blue": TrainLine(id: "Blue", name: "Blue Line", colorHex: "00A1DE", textColorHex: "FFFFFF"),
        "Brn": TrainLine(id: "Brn", name: "Brown Line", colorHex: "62361B", textColorHex: "FFFFFF"),
        "G": TrainLine(id: "G", name: "Green Line", colorHex: "009B3A", textColorHex: "FFFFFF"),
        "Org": TrainLine(id: "Org", name: "Orange Line", colorHex: "F9461C", textColorHex: "FFFFFF"),
        "P": TrainLine(id: "P", name: "Purple Line", colorHex: "522398", textColorHex: "FFFFFF"),
        "Pink": TrainLine(id: "Pink", name: "Pink Line", colorHex: "E27EA6", textColorHex: "FFFFFF"),
        "Y": TrainLine(id: "Y", name: "Yellow Line", colorHex: "F9E300", textColorHex: "000000"),
    ]

    static func fromId(_ id: String) -> TrainLine? {
        fallbackLinesById[id]
    }
}
