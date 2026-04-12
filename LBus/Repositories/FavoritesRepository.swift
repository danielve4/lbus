import Foundation
import SwiftData

@MainActor
protocol FavoritesRepositoryProtocol {
    func getAll() -> [Favorite]
    func add(_ favorite: Favorite) throws
    func remove(_ favorite: Favorite) throws
    func removeAll() throws
    func move(fromOffsets source: IndexSet, toOffset destination: Int) throws
    func contains(_ favorite: Favorite) -> Bool
    func pushToRemote() async throws
    func pullFromRemote() async throws
}

@MainActor
final class FavoritesRepository: FavoritesRepositoryProtocol {
    private let modelContext: ModelContext
    private let apiClient: APIClientProtocol
    private let deviceIdentifier: DeviceIdentifierProtocol

    init(modelContext: ModelContext, apiClient: APIClientProtocol, deviceIdentifier: DeviceIdentifierProtocol) {
        self.modelContext = modelContext
        self.apiClient = apiClient
        self.deviceIdentifier = deviceIdentifier
    }

    func getAll() -> [Favorite] {
        let descriptor = FetchDescriptor<FavoritePersisted>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let persisted = (try? modelContext.fetch(descriptor)) ?? []
        return persisted.map { $0.toFavorite() }
    }

    func add(_ favorite: Favorite) throws {
        let targetId = favorite.id
        var descriptor = FetchDescriptor<FavoritePersisted>(
            predicate: #Predicate { $0.favoriteId == targetId }
        )
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else { return }

        var maxDescriptor = FetchDescriptor<FavoritePersisted>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        maxDescriptor.fetchLimit = 1
        let maxOrder = (try? modelContext.fetch(maxDescriptor).first?.sortOrder) ?? -1

        let persisted = FavoritePersisted(from: favorite, sortOrder: maxOrder + 1)
        modelContext.insert(persisted)
        try modelContext.save()
    }

    func remove(_ favorite: Favorite) throws {
        let targetId = favorite.id
        let descriptor = FetchDescriptor<FavoritePersisted>(
            predicate: #Predicate { $0.favoriteId == targetId }
        )
        let matches = try modelContext.fetch(descriptor)
        for match in matches {
            modelContext.delete(match)
        }
        try modelContext.save()
    }

    func removeAll() throws {
        try modelContext.delete(model: FavoritePersisted.self)
        try modelContext.save()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) throws {
        var favorites = getAll()
        try favorites.moveElements(fromOffsets: source, toOffset: destination)

        let descriptor = FetchDescriptor<FavoritePersisted>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let persisted = try modelContext.fetch(descriptor)
        var persistedById: [String: FavoritePersisted] = [:]
        for item in persisted {
            persistedById[item.favoriteId] = item
        }

        for (index, favorite) in favorites.enumerated() {
            if let record = persistedById[favorite.id] {
                record.sortOrder = index
            }
        }

        try modelContext.save()
    }

    func contains(_ favorite: Favorite) -> Bool {
        let targetId = favorite.id
        var descriptor = FetchDescriptor<FavoritePersisted>(
            predicate: #Predicate { $0.favoriteId == targetId }
        )
        descriptor.fetchLimit = 1
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    func pushToRemote() async throws {
        let deviceId = deviceIdentifier.id
        let dtos = getAll().map { $0.toDTO() }
        try await FavoritesAPI.push(apiClient: apiClient, deviceId: deviceId, favorites: dtos)
    }

    func pullFromRemote() async throws {
        let deviceId = deviceIdentifier.id
        let response = try await FavoritesAPI.pull(apiClient: apiClient, deviceId: deviceId)

        try modelContext.delete(model: FavoritePersisted.self)
        for (index, dto) in response.favorites.enumerated() {
            let favorite = Favorite(from: dto)
            let persisted = FavoritePersisted(from: favorite, sortOrder: index)
            modelContext.insert(persisted)
        }
        try modelContext.save()
    }
}
