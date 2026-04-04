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
        }
        .navigationTitle("Favorites")
        .onAppear {
            favorites = favoritesRepository.getAll()
        }
    }
}
