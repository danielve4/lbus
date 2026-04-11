import SwiftUI

struct TrainStationsView: View {
    @State private var viewModel: TrainStationsViewModel
    @State private var searchText = ""

    init(line: TrainLine, trainRepository: TrainRepositoryProtocol) {
        _viewModel = State(initialValue: TrainStationsViewModel(
            line: line,
            trainRepository: trainRepository
        ))
    }

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loading:
                TrainStationsSkeletonView()
            case .error(let message):
                ContentUnavailableView {
                    Label("Unable to Load", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.loadStations() }
                    }
                }
            case .loaded:
                stationsList
            }
        }
        .navigationTitle(viewModel.line.name)
        .task { await viewModel.loadStations() }
    }

    private var stationsList: some View {
        let filtered = viewModel.filteredStations(searchText: searchText)
        return List {
            if filtered.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView {
                        Label("No Stations", systemImage: "tram")
                    } description: {
                        Text("No stations available for this line.")
                    } actions: {
                        Button("Retry") {
                            Task { await viewModel.loadStations() }
                        }
                    }
                } else {
                    ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("No stations match \"\(searchText)\""))
                }
            } else {
                ForEach(filtered) { station in
                    NavigationLink(value: TrainNavigation.arrivals(
                        stationId: station.id,
                        stationName: station.name,
                        line: viewModel.line
                    )) {
                        stationRow(station)
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search stations")
    }

    private func stationRow(_ station: TrainStation) -> some View {
        HStack {
            Text(station.name)
            Spacer()
            HStack(spacing: 4) {
                ForEach(viewModel.linesByStation[station.id] ?? [], id: \.id) { serving in
                    Circle()
                        .fill(Color(hex: serving.colorHex))
                        .frame(width: 10, height: 10)
                }
            }
        }
    }
}
