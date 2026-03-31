import SwiftUI

struct TransitNavigationDestinations: ViewModifier {
    let busRepository: BusRepositoryProtocol
    let trainRepository: TrainRepositoryProtocol
    let favoritesRepository: FavoritesRepositoryProtocol

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: BusNavigation.self) { destination in
                switch destination {
                case .directions(let route):
                    BusDirectionsView(route: route, busRepository: busRepository)
                case .stops(let route, let direction):
                    BusStopsView(route: route, direction: direction, busRepository: busRepository)
                case .arrivals(let stopId, let stopName, let route, let direction):
                    BusArrivalsView(stopId: stopId, stopName: stopName, route: route, direction: direction, busRepository: busRepository, favoritesRepository: favoritesRepository)
                case .follow(let vehicleId, _):
                    Text("Following bus \(vehicleId)")
                }
            }
            .navigationDestination(for: TrainNavigation.self) { destination in
                switch destination {
                case .stations(let line):
                    Text("Stations for \(line.name)")
                case .arrivals(let stopId, let stationName, _):
                    Text("Arrivals for \(stationName) (\(stopId))")
                case .follow(let runNumber, _):
                    Text("Following train \(runNumber)")
                }
            }
    }
}
