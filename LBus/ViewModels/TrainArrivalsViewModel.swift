import Foundation

@MainActor
@Observable
final class TrainArrivalsViewModel {

    enum ScreenState {
        case loading
        case error(String)
        case loaded
    }

    struct ArrivalGroupKey: Hashable {
        let line: String
        let direction: String
    }

    struct ArrivalGroup: Identifiable {
        let key: ArrivalGroupKey
        var id: ArrivalGroupKey { key }
        var arrivals: [TrainArrival]

        var destinations: [String] {
            Array(Set(arrivals.map(\.destinationName))).sorted()
        }
    }

    private(set) var arrivals: [TrainArrival] = []
    private(set) var trainLines: [TrainLine] = []
    private(set) var servingLineIds: [String] = []
    private(set) var isLoading = true
    private(set) var error: String? = nil
    private(set) var isFavorite: Bool = false
    private(set) var selectedLine: String?

    let stationId: String
    let stationName: String
    let line: TrainLine?

    private let trainRepository: TrainRepositoryProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    private(set) var refreshManager: AutoRefreshManagerProtocol
    private var isFetching = false
    private var lastFetchError: Error?
    private var hasCompletedInitialLoad = false

    init(
        stationId: String,
        stationName: String,
        line: TrainLine?,
        trainRepository: TrainRepositoryProtocol,
        favoritesRepository: FavoritesRepositoryProtocol,
        refreshManager: AutoRefreshManagerProtocol? = nil
    ) {
        self.stationId = stationId
        self.stationName = stationName
        self.line = line
        self.selectedLine = line?.id
        self.trainRepository = trainRepository
        self.favoritesRepository = favoritesRepository

        self.refreshManager = refreshManager ?? AutoRefreshManager(action: { })

        if refreshManager == nil {
            self.refreshManager = AutoRefreshManager { [weak self] in
                try await self?.fetchArrivals() ?? ()
            }
        }
    }

    // MARK: - Computed State

    var screenState: ScreenState {
        if isLoading && arrivals.isEmpty && !hasCompletedInitialLoad { return .loading }
        if let error, arrivals.isEmpty { return .error(error) }
        return .loaded
    }

    var lastUpdated: Date? { refreshManager.lastUpdated }
    var isRefreshing: Bool { refreshManager.isRefreshing }

    var linesById: [String: TrainLine] {
        Dictionary(uniqueKeysWithValues: trainLines.map { ($0.id, $0) })
    }

    func trainLine(for routeId: String) -> TrainLine? {
        linesById[routeId]
    }

    func lineDisplayName(for routeId: String) -> String {
        trainLine(for: routeId)?.name ?? routeId
    }

    // MARK: - Line Filtering

    var availableLineIds: [String] {
        var ids = Set(servingLineIds)
        ids.formUnion(arrivals.map(\.line))
        if let incomingId = line?.id {
            ids.insert(incomingId)
        }
        return ids.sorted { lineDisplayName(for: $0) < lineDisplayName(for: $1) }
    }

    var hasMultipleLines: Bool {
        availableLineIds.count > 1
    }

    var effectiveSelectedLine: String? {
        guard let selectedLine, availableLineIds.contains(selectedLine) else { return nil }
        return selectedLine
    }

    var filteredArrivals: [TrainArrival] {
        guard let effective = effectiveSelectedLine else { return arrivals }
        return arrivals.filter { $0.line == effective }
    }

    func selectLine(_ line: String?) {
        selectedLine = line
    }

    // MARK: - Grouping

    var groupedArrivals: [ArrivalGroup] {
        let grouped = Dictionary(grouping: filteredArrivals) {
            ArrivalGroupKey(line: $0.line, direction: $0.direction)
        }
        return grouped
            .sorted { lhs, rhs in
                let lhsLine = lineDisplayName(for: lhs.key.line)
                let rhsLine = lineDisplayName(for: rhs.key.line)
                if lhsLine != rhsLine { return lhsLine < rhsLine }
                let lhsDest = Set(lhs.value.map(\.destinationName)).sorted().joined(separator: " / ")
                let rhsDest = Set(rhs.value.map(\.destinationName)).sorted().joined(separator: " / ")
                return lhsDest < rhsDest
            }
            .map { ArrivalGroup(key: $0.key, arrivals: $0.value.sorted {
                if $0.arrivalTime != $1.arrivalTime { return $0.arrivalTime < $1.arrivalTime }
                return $0.runNumber < $1.runNumber
            })}
    }

    func destinationTitle(for group: ArrivalGroup) -> String {
        group.destinations.joined(separator: " / ")
    }

    func groupTitle(for group: ArrivalGroup) -> String {
        let dest = destinationTitle(for: group)
        if effectiveSelectedLine != nil {
            return dest
        }
        return "\(lineDisplayName(for: group.key.line)) to \(dest)"
    }

    // MARK: - Lifecycle

    func initialLoad() async {
        async let metadataTask: () = loadMetadata()
        async let arrivalsTask: () = loadArrivals()
        _ = await (metadataTask, arrivalsTask)
        loadFavoriteState()
    }

    func startAutoRefresh() {
        refreshManager.start()
    }

    func stopAutoRefresh() {
        refreshManager.stop()
    }

    func manualRefresh() async {
        await loadArrivals()
    }

    // MARK: - Data Loading

    func loadArrivals() async {
        guard !isFetching else { return }
        isFetching = true
        isLoading = true
        error = nil
        lastFetchError = nil

        await refreshManager.refreshNow()

        if lastFetchError != nil {
            self.error = "Unable to load arrivals. Check your connection and try again."
        }

        isLoading = false
        isFetching = false
        if lastFetchError == nil {
            hasCompletedInitialLoad = true
        }
    }

    private func fetchArrivals() async throws {
        do {
            arrivals = try await trainRepository.getArrivals(stopId: stationId)
        } catch {
            lastFetchError = error
            throw error
        }
    }

    private func loadMetadata() async {
        do {
            let data = try await trainRepository.getTrainData()
            let normalizedData = TrainStationsViewModel.normalizeStopSequences(data)
            trainLines = normalizedData.lines
            let lineIdsByStation = TrainStationsViewModel.buildLineIdsByStation(from: normalizedData.stopSequences)
            servingLineIds = Array(lineIdsByStation[stationId] ?? []).sorted()
        } catch {
            // Non-fatal: colors/serving lines degrade gracefully
        }
    }

    // MARK: - Favorites

    private var favorite: Favorite {
        .train(TrainFavorite(
            line: line?.id ?? "",
            stopId: stationId,
            stopName: stationName,
            direction: ""
        ))
    }

    func loadFavoriteState() {
        isFavorite = favoritesRepository.contains(favorite)
    }

    func toggleFavorite() {
        do {
            if isFavorite {
                try favoritesRepository.remove(favorite)
            } else {
                try favoritesRepository.add(favorite)
            }
            isFavorite.toggle()
        } catch {
            // Silently fail — state reverts on next loadFavoriteState()
        }
    }
}
