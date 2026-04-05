import SwiftUI

struct BusDirectionsView: View {
    @State private var viewModel: BusDirectionsViewModel
    var onClose: (() -> Void)?

    init(route: BusRoute, busRepository: BusRepositoryProtocol, onClose: (() -> Void)? = nil) {
        _viewModel = State(initialValue: BusDirectionsViewModel(
            route: route,
            busRepository: busRepository
        ))
        self.onClose = onClose
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
        .toolbar {
            if let onClose {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onClose)
                }
            }
        }
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
