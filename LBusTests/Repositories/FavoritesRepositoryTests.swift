import Foundation
import SwiftData
import Testing
@testable import LBus

// MARK: - Test Helpers

private struct MockDeviceIdentifier: DeviceIdentifierProtocol {
    let id: String = "test-device-id"
}

private let busFavorite = Favorite.bus(BusFavorite(
    route: "20",
    stopId: "456",
    stopName: "State & Lake",
    direction: "Eastbound"
))

private let trainFavorite = Favorite.train(TrainFavorite(
    line: "Red",
    stopId: "30089",
    stopName: "Howard",
    direction: "Service toward 95th/Dan Ryan"
))

private let busFavorite2 = Favorite.bus(BusFavorite(
    route: "66",
    stopId: "789",
    stopName: "Clark & Lake",
    direction: "Westbound"
))

// MARK: - Tests

@Suite(.serialized) @MainActor struct FavoritesRepositoryTests {

    private func makeRepo(mock: MockAPIClient = MockAPIClient()) throws -> (FavoritesRepository, MockAPIClient, ModelContainer) {
        let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).store")
        let config = ModelConfiguration(url: url)
        let container = try ModelContainer(for: FavoritePersisted.self, configurations: config)
        let repo = FavoritesRepository(
            modelContext: container.mainContext,
            apiClient: mock,
            deviceIdentifier: MockDeviceIdentifier()
        )
        return (repo, mock, container)
    }

    // MARK: - CRUD

    @Test func getAllReturnsEmptyInitially() throws {
        let (repo, _, container) = try makeRepo()
        _ = container
        #expect(repo.getAll().isEmpty)
    }

    @Test func addAndGetAll() throws {
        let (repo, _, container) = try makeRepo()
        _ = container

        try repo.add(busFavorite)
        let all = repo.getAll()

        #expect(all.count == 1)
        #expect(all[0] == busFavorite)
    }

    @Test func addSameFavoriteTwiceIsIdempotent() throws {
        let (repo, _, container) = try makeRepo()
        _ = container

        try repo.add(busFavorite)
        try repo.add(busFavorite)

        #expect(repo.getAll().count == 1)
    }

    @Test func removeDeletesSpecificFavorite() throws {
        let (repo, _, container) = try makeRepo()
        _ = container

        try repo.add(busFavorite)
        try repo.add(trainFavorite)
        try repo.remove(busFavorite)
        let all = repo.getAll()

        #expect(all.count == 1)
        #expect(all[0] == trainFavorite)
    }

    @Test func removeAllClearsEverything() throws {
        let (repo, _, container) = try makeRepo()
        _ = container

        try repo.add(busFavorite)
        try repo.add(trainFavorite)
        try repo.removeAll()

        #expect(repo.getAll().isEmpty)
    }

    @Test func containsReturnsTrueWhenPresent() throws {
        let (repo, _, container) = try makeRepo()
        _ = container

        try repo.add(busFavorite)

        #expect(repo.contains(busFavorite) == true)
        #expect(repo.contains(trainFavorite) == false)
    }

    @Test func mixedBusAndTrainFavoritesCoexist() throws {
        let (repo, _, container) = try makeRepo()
        _ = container

        try repo.add(busFavorite)
        try repo.add(trainFavorite)
        let all = repo.getAll()

        #expect(all.count == 2)
        #expect(all.contains(busFavorite))
        #expect(all.contains(trainFavorite))
    }

    @Test func orderingBySortOrder() throws {
        let (repo, _, container) = try makeRepo()
        _ = container

        try repo.add(busFavorite)
        try repo.add(trainFavorite)
        let all = repo.getAll()

        #expect(all[0] == busFavorite)
        #expect(all[1] == trainFavorite)
    }

    // MARK: - Move

    @Test func moveReordersFromFirstToLast() throws {
        let (repo, _, container) = try makeRepo()
        _ = container

        try repo.add(busFavorite)
        try repo.add(trainFavorite)
        try repo.add(busFavorite2)

        // Move first item to end: [bus, train, bus2] -> [train, bus2, bus]
        try repo.move(fromOffsets: IndexSet(integer: 0), toOffset: 3)

        let all = repo.getAll()
        #expect(all.count == 3)
        #expect(all[0] == trainFavorite)
        #expect(all[1] == busFavorite2)
        #expect(all[2] == busFavorite)
    }

    @Test func moveReordersFromLastToFirst() throws {
        let (repo, _, container) = try makeRepo()
        _ = container

        try repo.add(busFavorite)
        try repo.add(trainFavorite)
        try repo.add(busFavorite2)

        // Move last item to beginning: [bus, train, bus2] -> [bus2, bus, train]
        try repo.move(fromOffsets: IndexSet(integer: 2), toOffset: 0)

        let all = repo.getAll()
        #expect(all.count == 3)
        #expect(all[0] == busFavorite2)
        #expect(all[1] == busFavorite)
        #expect(all[2] == trainFavorite)
    }

    @Test func movePreservesOrderAfterMultipleMoves() throws {
        let (repo, _, container) = try makeRepo()
        _ = container

        try repo.add(busFavorite)
        try repo.add(trainFavorite)
        try repo.add(busFavorite2)

        // Move index 0 to end: [bus, train, bus2] -> [train, bus2, bus]
        try repo.move(fromOffsets: IndexSet(integer: 0), toOffset: 3)
        // Move index 0 past index 1: [train, bus2, bus] -> [bus2, train, bus]
        try repo.move(fromOffsets: IndexSet(integer: 0), toOffset: 2)

        let all = repo.getAll()
        #expect(all.count == 3)
        #expect(all[0] == busFavorite2)
        #expect(all[1] == trainFavorite)
        #expect(all[2] == busFavorite)
    }

    @Test func moveSamePositionIsNoOp() throws {
        let (repo, _, container) = try makeRepo()
        _ = container

        try repo.add(busFavorite)
        try repo.add(trainFavorite)

        // Move item 0 to position 0 (no change)
        try repo.move(fromOffsets: IndexSet(integer: 0), toOffset: 0)

        let all = repo.getAll()
        #expect(all[0] == busFavorite)
        #expect(all[1] == trainFavorite)
    }

    @Test func moveAdjacentOffsetIsNoOp() throws {
        let (repo, _, container) = try makeRepo()
        _ = container

        try repo.add(busFavorite)
        try repo.add(trainFavorite)
        try repo.add(busFavorite2)

        // Move item 0 to offset 1 — after adjustment this is a no-op
        // (item is removed from index 0, insertion point becomes 1 - 1 = 0)
        try repo.move(fromOffsets: IndexSet(integer: 0), toOffset: 1)

        let all = repo.getAll()
        #expect(all[0] == busFavorite)
        #expect(all[1] == trainFavorite)
        #expect(all[2] == busFavorite2)
    }

    // MARK: - Sync

    @Test func pushSendsCorrectPathAndBody() async throws {
        let mock = MockAPIClient()
        await mock.setPostResult(SaveFavoritesResponse(id: "test-device-id", favorites: []))
        let (repo, _, container) = try makeRepo(mock: mock)
        _ = container

        try repo.add(busFavorite)
        try await repo.pushToRemote()

        #expect(await mock.lastPostPath == "savefavorites")
        let body = await mock.lastPostBody as? SaveFavoritesRequestBody
        #expect(body?.id == "test-device-id")
        #expect(body?.favorites.count == 1)
        #expect(body?.favorites[0].route == "20")
        #expect(body?.favorites[0].type == "bus")
    }

    @Test func pushWithEmptyStoreSendsEmptyArray() async throws {
        let mock = MockAPIClient()
        await mock.setPostResult(SaveFavoritesResponse(id: "test-device-id", favorites: []))
        let (repo, _, container) = try makeRepo(mock: mock)
        _ = container

        try await repo.pushToRemote()

        let body = await mock.lastPostBody as? SaveFavoritesRequestBody
        #expect(body?.favorites.isEmpty == true)
    }

    @Test func pushPropagatesErrors() async throws {
        let mock = MockAPIClient()
        await mock.setPostError(APIError.networkError(URLError(.notConnectedToInternet)))
        let (repo, _, container) = try makeRepo(mock: mock)
        _ = container

        do {
            try await repo.pushToRemote()
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            guard case .networkError = error else {
                Issue.record("Expected networkError, got \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func pullReplacesLocalStoreWithRemoteData() async throws {
        let mock = MockAPIClient()
        let (repo, _, container) = try makeRepo(mock: mock)
        _ = container

        try repo.add(busFavorite)

        let remoteFavorites = [
            FavoriteDTO(route: "Red", stopId: "30089", stopName: "Howard", direction: "Service toward 95th/Dan Ryan", type: "train"),
            FavoriteDTO(route: "66", stopId: "789", stopName: "Clark & Lake", direction: "Westbound", type: "bus"),
        ]
        await mock.setPostResult(GetFavoritesResponse(id: "test-device-id", favorites: remoteFavorites))

        try await repo.pullFromRemote()

        let all = repo.getAll()
        #expect(all.count == 2)
        #expect(await mock.lastPostPath == "myfavorites")
        let body = await mock.lastPostBody as? GetFavoritesRequestBody
        #expect(body?.id == "test-device-id")
    }

    @Test func pullWithEmptyResponseClearsLocal() async throws {
        let mock = MockAPIClient()
        let (repo, _, container) = try makeRepo(mock: mock)
        _ = container

        try repo.add(busFavorite)
        await mock.setPostResult(GetFavoritesResponse(id: "test-device-id", favorites: []))

        try await repo.pullFromRemote()

        #expect(repo.getAll().isEmpty)
    }

    @Test func pullPreservesRemoteOrdering() async throws {
        let mock = MockAPIClient()
        let (repo, _, container) = try makeRepo(mock: mock)
        _ = container

        let remoteFavorites = [
            FavoriteDTO(route: "66", stopId: "789", stopName: "Clark & Lake", direction: "Westbound", type: "bus"),
            FavoriteDTO(route: "Red", stopId: "30089", stopName: "Howard", direction: "Service toward 95th/Dan Ryan", type: "train"),
            FavoriteDTO(route: "20", stopId: "456", stopName: "State & Lake", direction: "Eastbound", type: "bus"),
        ]
        await mock.setPostResult(GetFavoritesResponse(id: "test-device-id", favorites: remoteFavorites))

        try await repo.pullFromRemote()

        let all = repo.getAll()
        #expect(all.count == 3)
        #expect(all[0].routeOrLine == "66")
        #expect(all[1].routeOrLine == "Red")
        #expect(all[2].routeOrLine == "20")
    }

    @Test func pullPropagatesErrors() async throws {
        let mock = MockAPIClient()
        await mock.setPostError(APIError.networkError(URLError(.timedOut)))
        let (repo, _, container) = try makeRepo(mock: mock)
        _ = container

        try repo.add(busFavorite)

        do {
            try await repo.pullFromRemote()
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            guard case .networkError = error else {
                Issue.record("Expected networkError, got \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(repo.getAll().count == 1)
    }
}
