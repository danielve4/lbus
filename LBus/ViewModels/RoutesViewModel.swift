import Foundation

@MainActor
@Observable
final class RoutesViewModel {

    enum ScreenState {
        case loading
        case error(String)
        case loaded
    }

    private(set) var busRoutes: [BusRoute] = []
    private(set) var trainLines: [TrainLine] = []
    private(set) var isLoading = true
    private(set) var error: String? = nil

    private let busRepository: BusRepositoryProtocol
    private let trainRepository: TrainRepositoryProtocol

    init(busRepository: BusRepositoryProtocol, trainRepository: TrainRepositoryProtocol) {
        self.busRepository = busRepository
        self.trainRepository = trainRepository
    }

    var screenState: ScreenState {
        if isLoading && busRoutes.isEmpty && trainLines.isEmpty { return .loading }
        if let error, busRoutes.isEmpty && trainLines.isEmpty { return .error(error) }
        return .loaded
    }

    func loadData() async {
        isLoading = true
        error = nil

        async let bus = fetchBusRoutes()
        async let train = fetchTrainLines()
        let (busResult, trainResult) = await (bus, train)

        if let routes = busResult { busRoutes = routes }
        if let lines = trainResult { trainLines = lines }

        if busRoutes.isEmpty && trainLines.isEmpty && (busResult == nil || trainResult == nil) {
            error = "Unable to load routes. Check your connection and try again."
        }

        isLoading = false
    }

    func filteredBusRoutes(searchText: String) -> [BusRoute] {
        guard !searchText.isEmpty else { return busRoutes }
        let query = searchText.lowercased()
        return busRoutes.filter {
            $0.id.lowercased().contains(query) || $0.name.lowercased().contains(query)
        }
    }

    func filteredTrainLines(searchText: String) -> [TrainLine] {
        guard !searchText.isEmpty else { return trainLines }
        let query = searchText.lowercased()
        return trainLines.filter {
            $0.id.lowercased().contains(query) || $0.name.lowercased().contains(query)
        }
    }

    // MARK: - Private

    private func fetchBusRoutes() async -> [BusRoute]? {
        try? await busRepository.getRoutes()
    }

    private func fetchTrainLines() async -> [TrainLine]? {
        (try? await trainRepository.getTrainData())?.lines
    }
}
