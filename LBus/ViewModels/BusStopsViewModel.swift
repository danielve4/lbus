import Foundation

@MainActor
@Observable
final class BusStopsViewModel {

    enum ScreenState {
        case loading
        case error(String)
        case loaded
    }

    private(set) var stops: [BusStop] = []
    private(set) var isLoading = true
    private(set) var error: String? = nil

    let route: BusRoute
    let direction: String

    private let busRepository: BusRepositoryProtocol
    private var isFetching = false

    init(route: BusRoute, direction: String, busRepository: BusRepositoryProtocol) {
        self.route = route
        self.direction = direction
        self.busRepository = busRepository
    }

    var screenState: ScreenState {
        if isLoading && stops.isEmpty { return .loading }
        if let error, stops.isEmpty { return .error(error) }
        return .loaded
    }

    func loadStops() async {
        guard !isFetching else { return }
        isFetching = true
        isLoading = true
        error = nil

        do {
            stops = try await busRepository.getStops(route: route.id, direction: direction)
        } catch {
            self.error = "Unable to load stops. Check your connection and try again."
        }

        isLoading = false
        isFetching = false
    }

    func filteredStops(searchText: String) -> [BusStop] {
        guard !searchText.isEmpty else { return stops }
        let query = searchText.lowercased()
        return stops.filter {
            $0.id.lowercased().contains(query) ||
            $0.name.lowercased().contains(query)
        }
    }
}
