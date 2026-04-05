import SwiftUI

struct BusStopsView: View {
    @State private var viewModel: BusStopsViewModel
    @State private var searchText = ""
    var onStopSelected: ((BusNavigation) -> Void)?
    var onClose: (() -> Void)?

    init(route: BusRoute, direction: String, busRepository: BusRepositoryProtocol, onStopSelected: ((BusNavigation) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        _viewModel = State(initialValue: BusStopsViewModel(
            route: route,
            direction: direction,
            busRepository: busRepository
        ))
        self.onStopSelected = onStopSelected
        self.onClose = onClose
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
        .toolbar {
            if let onClose {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", action: onClose)
                }
            }
        }
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
                    if let onStopSelected {
                        Button {
                            onStopSelected(BusNavigation.arrivals(
                                stopId: stop.id,
                                stopName: stop.name,
                                route: viewModel.route.id,
                                direction: viewModel.direction
                            ))
                        } label: {
                            stopRow(stop)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink(value: BusNavigation.arrivals(
                            stopId: stop.id,
                            stopName: stop.name,
                            route: viewModel.route.id,
                            direction: viewModel.direction
                        )) {
                            stopRow(stop)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search stops")
    }

    private func stopRow(_ stop: BusStop) -> some View {
        VStack(alignment: .leading) {
            Text(stop.name)
            Text("Stop #\(stop.id)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
