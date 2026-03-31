import SwiftUI

struct BusArrivalsView: View {
    @State private var viewModel: BusArrivalsViewModel

    init(
        stopId: String,
        stopName: String,
        route: String,
        direction: String,
        busRepository: BusRepositoryProtocol,
        favoritesRepository: FavoritesRepositoryProtocol
    ) {
        _viewModel = State(initialValue: BusArrivalsViewModel(
            stopId: stopId,
            stopName: stopName,
            route: route,
            direction: direction,
            busRepository: busRepository,
            favoritesRepository: favoritesRepository
        ))
    }

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loading:
                BusArrivalsSkeletonView()
            case .error(let message):
                ContentUnavailableView {
                    Label("Unable to Load", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.loadArrivals() }
                    }
                }
            case .loaded:
                arrivalsList
            }
        }
        .navigationTitle(viewModel.stopName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleFavorite()
                } label: {
                    Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(viewModel.isFavorite ? .yellow : .secondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isRefreshing {
                    ProgressView()
                } else {
                    Button {
                        Task { await viewModel.manualRefresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await viewModel.initialLoad()
        }
        .onAppear {
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
    }

    private var arrivalsList: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.stopName)
                        .font(.headline)
                    Text("Stop #\(viewModel.stopId)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.arrivals.isEmpty {
                ContentUnavailableView {
                    Label("No Arrivals", systemImage: "clock")
                } description: {
                    Text("No arrivals predicted for this stop right now.")
                } actions: {
                    Button("Refresh") {
                        Task { await viewModel.manualRefresh() }
                    }
                }
            } else {
                Section {
                    ForEach(viewModel.arrivals) { arrival in
                        NavigationLink(value: BusNavigation.follow(
                            vehicleId: arrival.vehicleId,
                            stopId: arrival.stopId
                        )) {
                            arrivalRow(arrival)
                        }
                    }
                }
            }

            if let lastUpdated = viewModel.lastUpdated {
                Section {
                    Text("Updated \(lastUpdated.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func arrivalRow(_ arrival: BusArrival) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(arrival.route)
                        .font(.caption.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(minWidth: 24)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(.tertiary))
                    Text(arrival.routeDirection)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(arrival.destination)
                    .font(.subheadline)
                if let distance = arrival.distanceText {
                    Text(distance)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(arrival.countdownText)
                    .font(.headline)
                    .foregroundStyle(arrival.countdown == .due ? .red : .primary)
                Text("\(arrival.clockTimeText) \(arrival.dayContextText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if arrival.isDelayed {
                    Text("Delayed")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(.red))
                }
            }
        }
        .padding(.vertical, 2)
    }
}
