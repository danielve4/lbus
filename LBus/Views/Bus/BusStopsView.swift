import SwiftUI

struct BusStopsView: View {
    @State private var viewModel: BusStopsViewModel
    @State private var searchText = ""

    init(route: BusRoute, direction: String, busRepository: BusRepositoryProtocol) {
        _viewModel = State(initialValue: BusStopsViewModel(
            route: route,
            direction: direction,
            busRepository: busRepository
        ))
    }

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loading:
                BusStopsSkeletonView()
            case .error(let message):
                ContentUnavailableView {
                    Label("Unable to Load", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.loadStops() }
                    }
                }
            case .loaded:
                stopsList
            }
        }
        .navigationTitle("Route \(viewModel.route.shortName) \(viewModel.direction)")
        .task { await viewModel.loadStops() }
    }

    private var stopsList: some View {
        let filtered = viewModel.filteredStops(searchText: searchText)
        return List {
            if filtered.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView {
                        Label("No Stops", systemImage: "mappin.slash")
                    } description: {
                        Text("No stops available for this route and direction.")
                    } actions: {
                        Button("Retry") {
                            Task { await viewModel.loadStops() }
                        }
                    }
                } else {
                    ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("No stops match \"\(searchText)\""))
                }
            } else {
                ForEach(filtered) { stop in
                    NavigationLink(value: BusNavigation.arrivals(
                        stopId: stop.id,
                        stopName: stop.name,
                        route: viewModel.route.id,
                        direction: viewModel.direction
                    )) {
                        VStack(alignment: .leading) {
                            Text(stop.name)
                            Text("Stop #\(stop.id)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search stops")
    }
}
