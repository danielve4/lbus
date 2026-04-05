import SwiftUI

struct BusArrivalsView: View {
    @State private var viewModel: BusArrivalsViewModel
    @State private var showRefreshShimmer = false

    private static let refreshTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm:ss a"
        f.timeZone = TimeZone(identifier: "America/Chicago")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

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
        .onChange(of: viewModel.refreshCount) { _, _ in
            showRefreshShimmer = true
            Task {
                try? await Task.sleep(for: .seconds(1.0))
                showRefreshShimmer = false
            }
        }
    }

    private var arrivalsList: some View {
        ScrollView {
            VStack(spacing: 32) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.direction)
                            .font(.headline)
                            .foregroundStyle(.pink)
                        Text(headerSubtitle)
                            .font(.subheadline)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                if viewModel.arrivals.isEmpty {
                    ContentUnavailableView {
                        Label("No Arrivals", systemImage: "clock")
                    } description: {
                        Text("No arrivals predicted for this stop right now.")
                    } actions: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Button("Refresh") {
                                Task { await viewModel.manualRefresh() }
                            }
                        }
                    }
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.arrivals) { arrival in
                            NavigationLink(value: BusNavigation.follow(
                                vehicleId: arrival.vehicleId,
                                stopId: arrival.stopId
                            )) {
                                arrivalRow(arrival)
                            }
                            .modifier(RefreshShimmerModifier(isActive: showRefreshShimmer))

                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
        .refreshable {
            await viewModel.manualRefresh()
        }
    }

    private var headerSubtitle: String {
        if let lastUpdated = viewModel.lastUpdated {
            return "Last refreshed at \(Self.refreshTimeFormatter.string(from: lastUpdated))"
        }
        return ""
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
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
