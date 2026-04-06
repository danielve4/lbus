import SwiftUI

struct FavoritesView: View {
    let favoritesRepository: FavoritesRepositoryProtocol
    let onExploreRoutes: () -> Void

    @State private var favorites: [Favorite] = []

    var body: some View {
        Group {
            if favorites.isEmpty {
                ContentUnavailableView {
                    Label("Welcome to LBus", systemImage: "bus.fill")
                } description: {
                    Text("Track real-time CTA bus and train arrivals. Start by exploring routes to find your stops and add them to your favorites.")
                } actions: {
                    Button("Explore Routes") {
                        onExploreRoutes()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List(favorites) { favorite in
                    Group {
                        if case .bus(let bus) = favorite {
                            NavigationLink(value: BusNavigation.arrivals(
                                stopId: bus.stopId,
                                stopName: bus.stopName,
                                route: bus.route,
                                direction: bus.direction
                            )) {
                                favoriteRow(favorite)
                            }
                        } else {
                            favoriteRow(favorite)
                        }
                    }
                }
            }
        }
        .navigationTitle("Favorites")
        .onAppear {
            favorites = favoritesRepository.getAll()
        }
    }

    private func favoriteRow(_ favorite: Favorite) -> some View {
        HStack(spacing: 12) {
            Image(systemName: favorite.transitType == .bus ? "bus.fill" : "tram.fill")
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(favorite.name)
                Text("\(favorite.routeOrLine) · \(favorite.direction)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
