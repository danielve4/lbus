import SwiftUI

struct BusDirectionsView: View {
    @State private var viewModel: BusDirectionsViewModel

    init(route: BusRoute, busRepository: BusRepositoryProtocol) {
        _viewModel = State(initialValue: BusDirectionsViewModel(
            route: route,
            busRepository: busRepository
        ))
    }

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loading:
                BusDirectionsSkeletonView()
            case .error(let message):
                ContentUnavailableView {
                    Label("Unable to Load", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.loadDirections() }
                    }
                }
            case .loaded:
                directionsList
            }
        }
        .navigationTitle("Route \(viewModel.route.shortName)")
        .task { await viewModel.loadDirections() }
    }

    private var directionsList: some View {
        List {
            if viewModel.directions.isEmpty {
                ContentUnavailableView {
                    Label("No Directions", systemImage: "arrow.left.arrow.right")
                } description: {
                    Text("No directions available for this route.")
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.loadDirections() }
                    }
                }
            } else {
                ForEach(viewModel.directions, id: \.direction) { direction in
                    NavigationLink(value: BusNavigation.stops(
                        route: viewModel.route,
                        direction: direction.direction
                    )) {
                        Label(direction.direction, systemImage: "arrow.right")
                    }
                }
            }
        }
    }
}
