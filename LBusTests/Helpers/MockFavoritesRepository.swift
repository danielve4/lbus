import Foundation
@testable import LBus

@MainActor
final class MockFavoritesRepository: FavoritesRepositoryProtocol {
    private var favorites: [Favorite] = []

    func getAll() -> [Favorite] {
        favorites
    }

    func add(_ favorite: Favorite) throws {
        guard !favorites.contains(where: { $0.id == favorite.id }) else { return }
        favorites.append(favorite)
    }

    func remove(_ favorite: Favorite) throws {
        favorites.removeAll { $0.id == favorite.id }
    }

    func removeAll() throws {
        favorites.removeAll()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) throws {
        try favorites.moveElements(fromOffsets: source, toOffset: destination)
    }

    func contains(_ favorite: Favorite) -> Bool {
        favorites.contains { $0.id == favorite.id }
    }

    func pushToRemote() async throws {}
    func pullFromRemote() async throws {}
}
