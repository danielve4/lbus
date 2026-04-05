import SwiftUI

struct RoutesView: View {
    @State private var viewModel: RoutesViewModel
    @State private var searchText = ""
    @State private var sheetCoordinator = BusRouteSheetCoordinator()

    let busRepository: BusRepositoryProtocol
    var onNavigateToArrivals: ((BusNavigation) -> Void)?

    init(busRepository: BusRepositoryProtocol, trainRepository: TrainRepositoryProtocol, onNavigateToArrivals: ((BusNavigation) -> Void)? = nil) {
        self.busRepository = busRepository
        self.onNavigateToArrivals = onNavigateToArrivals
        _viewModel = State(initialValue: RoutesViewModel(
            busRepository: busRepository,
            trainRepository: trainRepository
        ))
    }

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loading:
                RoutesSkeletonView()
            case .error(let message):
                ContentUnavailableView {
                    Label("Unable to Load", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.loadData() }
                    }
                }
            case .loaded:
                routesList
            }
        }
        .navigationTitle("Routes")
        .task { await viewModel.loadData() }
        .sheet(item: $sheetCoordinator.selectedRoute, onDismiss: {
            sheetCoordinator.handleDismiss { onNavigateToArrivals?($0) }
        }) { route in
            NavigationStack {
                BusDirectionsView(
                    route: route,
                    busRepository: busRepository,
                    onClose: { sheetCoordinator.close() }
                )
                .navigationDestination(for: BusNavigation.self) { destination in
                    switch destination {
                    case .stops(let route, let direction):
                        BusStopsView(
                            route: route,
                            direction: direction,
                            busRepository: busRepository,
                            onStopSelected: { sheetCoordinator.selectStop(navigation: $0) },
                            onClose: { sheetCoordinator.close() }
                        )
                    default:
                        EmptyView()
                    }
                }
            }
        }
    }

    private var routesList: some View {
        List {
            let filteredTrainLines = viewModel.filteredTrainLines(searchText: searchText)
            let filteredBusRoutes = viewModel.filteredBusRoutes(searchText: searchText)

            if !filteredTrainLines.isEmpty {
                Section("Train Lines") {
                    ForEach(filteredTrainLines) { line in
                        NavigationLink(value: TrainNavigation.stations(line: line)) {
                            trainLineRow(line)
                        }
                    }
                }
            }

            if !filteredBusRoutes.isEmpty {
                Section("Bus Routes") {
                    ForEach(filteredBusRoutes) { route in
                        Button {
                            sheetCoordinator.selectRoute(route)
                        } label: {
                            busRouteRow(route)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if filteredTrainLines.isEmpty && filteredBusRoutes.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView {
                        Label("No Routes Available", systemImage: "bus")
                    } description: {
                        Text("No routes or train lines are available right now.")
                    } actions: {
                        Button("Retry") {
                            Task { await viewModel.loadData() }
                        }
                    }
                } else {
                    ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("No routes match \"\(searchText)\""))
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search routes")
    }

    private func trainLineRow(_ line: TrainLine) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: line.colorHex))
                .frame(width: 12, height: 12)
            Text(line.name)
        }
    }

    private func busRouteRow(_ route: BusRoute) -> some View {
        HStack(spacing: 12) {
            Text(route.shortName)
                .font(.caption.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 36)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(.tertiary))
            Text(route.name)
        }
    }
}
