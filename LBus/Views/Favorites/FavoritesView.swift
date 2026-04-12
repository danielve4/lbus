import SwiftUI

struct FavoritesView: View {
    let favoritesRepository: FavoritesRepositoryProtocol
    let onExploreRoutes: () -> Void

    @State private var favorites: [Favorite] = []
    @State private var showClearAllConfirmation = false
    @State private var editMode: EditMode = .inactive

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
                List {
                    ForEach(favorites) { favorite in
                        Group {
                            switch favorite {
                            case .bus(let bus):
                                NavigationLink(value: BusNavigation.arrivals(
                                    stopId: bus.stopId,
                                    stopName: bus.stopName,
                                    route: bus.route,
                                    direction: bus.direction
                                )) {
                                    favoriteRow(favorite)
                                }
                            case .train(let train):
                                NavigationLink(value: TrainNavigation.arrivals(
                                    stationId: train.stopId,
                                    stationName: train.stopName,
                                    line: TrainLine.fromId(train.line)
                                )) {
                                    favoriteRow(favorite)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteFavorites)
                    .onMove(perform: moveFavorites)
                }
                .environment(\.editMode, $editMode)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(editMode == .active ? "Done" : "Edit") {
                            withAnimation {
                                editMode = editMode == .active ? .inactive : .active
                            }
                        }
                    }
                    if editMode == .active {
                        ToolbarItem(placement: .bottomBar) {
                            Button("Clear All", role: .destructive) {
                                showClearAllConfirmation = true
                            }
                        }
                    }
                }
                .confirmationDialog(
                    "Remove All Favorites",
                    isPresented: $showClearAllConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Remove All", role: .destructive) {
                        clearAllFavorites()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will remove all your saved favorites. This action cannot be undone.")
                }
            }
        }
        .navigationTitle("Favorites")
        .onAppear {
            reloadFavorites()
        }
    }

    // MARK: - Row

    private func favoriteRow(_ favorite: Favorite) -> some View {
        HStack(spacing: 12) {
            Image(systemName: favorite.transitType == .bus ? "bus.fill" : "tram.fill")
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(favorite.name)
                if let subtitle = subtitle(for: favorite) {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func subtitle(for favorite: Favorite) -> String? {
        switch favorite {
        case .bus(let bus):
            return "\(bus.route) · \(bus.direction)"
        case .train(let train):
            let lineName = TrainLine.fromId(train.line)?.name ?? train.line
            return lineName.isEmpty ? nil : lineName
        }
    }

    // MARK: - Actions

    private func deleteFavorites(at offsets: IndexSet) {
        for index in offsets {
            let favorite = favorites[index]
            try? favoritesRepository.remove(favorite)
        }
        reloadFavorites()
        if favorites.isEmpty {
            editMode = .inactive
        }
    }

    private func moveFavorites(from source: IndexSet, to destination: Int) {
        try? favoritesRepository.move(fromOffsets: source, toOffset: destination)
        reloadFavorites()
    }

    private func clearAllFavorites() {
        try? favoritesRepository.removeAll()
        reloadFavorites()
        editMode = .inactive
    }

    private func reloadFavorites() {
        favorites = favoritesRepository.getAll()
    }
}
