import SwiftUI

struct RoutesView: View {
    @State private var viewModel: RoutesViewModel
    @State private var searchText = ""

    init(busRepository: BusRepositoryProtocol, trainRepository: TrainRepositoryProtocol) {
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
                        NavigationLink(value: BusNavigation.directions(route: route)) {
                            busRouteRow(route)
                        }
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
