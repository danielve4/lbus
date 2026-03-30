import Foundation

@MainActor
@Observable
final class BusDirectionsViewModel {

    enum ScreenState {
        case loading
        case error(String)
        case loaded
    }

    private(set) var directions: [BusDirection] = []
    private(set) var isLoading = true
    private(set) var error: String? = nil

    let route: BusRoute

    private let busRepository: BusRepositoryProtocol
    private var isFetching = false

    init(route: BusRoute, busRepository: BusRepositoryProtocol) {
        self.route = route
        self.busRepository = busRepository
    }

    var screenState: ScreenState {
        if isLoading && directions.isEmpty { return .loading }
        if let error, directions.isEmpty { return .error(error) }
        return .loaded
    }

    func loadDirections() async {
        guard !isFetching else { return }
        isFetching = true
        isLoading = true
        error = nil

        do {
            directions = try await busRepository.getDirections(route: route.id)
        } catch {
            self.error = "Unable to load directions. Check your connection and try again."
        }

        isLoading = false
        isFetching = false
    }
}
