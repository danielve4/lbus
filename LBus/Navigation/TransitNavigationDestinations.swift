import SwiftUI

struct TransitNavigationDestinations: ViewModifier {
    let busRepository: BusRepositoryProtocol
    let trainRepository: TrainRepositoryProtocol
    let favoritesRepository: FavoritesRepositoryProtocol

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: BusNavigation.self) { destination in
                switch destination {
                case .directions, .stops:
                    // Handled within the modal sheet's own NavigationStack (see RoutesView)
                    EmptyView()
                case .arrivals(let stopId, let stopName, let route, let direction):
                    BusArrivalsView(stopId: stopId, stopName: stopName, route: route, direction: direction, busRepository: busRepository, favoritesRepository: favoritesRepository)
                case .follow(let vehicleId, let stopId):
                    BusFollowView(vehicleId: vehicleId, stopId: stopId, busRepository: busRepository)
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
