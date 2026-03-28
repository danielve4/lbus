import SwiftUI

struct TransitNavigationDestinations: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: BusNavigation.self) { destination in
                switch destination {
                case .directions(let route):
                    Text("Directions for \(route.name)")
                case .stops(let route, let direction):
                    Text("Stops for \(route.name) - \(direction)")
                case .arrivals(let stopId, let stopName, _, _):
                    Text("Arrivals for \(stopName) (\(stopId))")
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
