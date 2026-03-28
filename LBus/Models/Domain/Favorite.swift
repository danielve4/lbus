import Foundation

enum TransitType: String, Equatable, Sendable {
    case bus
    case train
}

struct BusFavorite: Equatable, Sendable {
    let route: String
    let stopId: String
    let stopName: String
    let direction: String
}

struct TrainFavorite: Equatable, Sendable {
    let line: String
    let stopId: String
    let stopName: String
    let direction: String
}

enum Favorite: Equatable, Sendable, Identifiable {
    case bus(BusFavorite)
    case train(TrainFavorite)

    var id: String {
        switch self {
        case .bus(let f): return "bus-\(f.route)-\(f.stopId)"
        case .train(let f): return "train-\(f.line)-\(f.stopId)"
        }
    }

    var name: String {
        switch self {
        case .bus(let f): return f.stopName
        case .train(let f): return f.stopName
        }
    }

    var transitType: TransitType {
        switch self {
        case .bus: return .bus
        case .train: return .train
        }
    }

    var stopId: String {
        switch self {
        case .bus(let f): return f.stopId
        case .train(let f): return f.stopId
        }
    }

    var routeOrLine: String {
        switch self {
        case .bus(let f): return f.route
        case .train(let f): return f.line
        }
    }

    var direction: String {
        switch self {
        case .bus(let f): return f.direction
        case .train(let f): return f.direction
        }
    }

    init(from dto: FavoriteDTO) {
        let type = dto.type ?? "bus"
        switch type {
        case "train":
            self = .train(TrainFavorite(
                line: dto.route,
                stopId: dto.stopId,
                stopName: dto.stopName,
                direction: dto.direction
            ))
        default:
            self = .bus(BusFavorite(
                route: dto.route,
                stopId: dto.stopId,
                stopName: dto.stopName,
                direction: dto.direction
            ))
        }
    }

    func toDTO() -> FavoriteDTO {
        switch self {
        case .bus(let f):
            return FavoriteDTO(
                route: f.route,
                stopId: f.stopId,
                stopName: f.stopName,
                direction: f.direction,
                type: "bus"
            )
        case .train(let f):
            return FavoriteDTO(
                route: f.line,
                stopId: f.stopId,
                stopName: f.stopName,
                direction: f.direction,
                type: "train"
            )
        }
    }
}
