import SwiftUI

struct BusArrivalsView: View {
    @State private var viewModel: BusArrivalsViewModel
    @State private var followTarget: FollowTarget?

    private let busRepository: BusRepositoryProtocol

    private struct FollowTarget: Identifiable {
        let vehicleId: String
        let stopId: String
        var id: String { vehicleId }
    }

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
        self.busRepository = busRepository
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
                VStack(spacing: 0) {
                    if viewModel.hasMultipleRoutes {
                        routePillBar
                            .padding(.vertical, 12)
                    }
                    arrivalsList
                }
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
        .sheet(item: $followTarget) { target in
            NavigationStack {
                BusFollowView(
                    vehicleId: target.vehicleId,
                    stopId: target.stopId,
                    busRepository: busRepository
                )
            }.presentationDetents([.medium, .large])
        }
    }

    private var routePillBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                routePill(label: "All", isSelected: viewModel.effectiveSelectedRoute == nil) {
                    viewModel.selectRoute(nil)
                }
                ForEach(viewModel.availableRoutes, id: \.self) { route in
                    routePill(label: route, isSelected: viewModel.effectiveSelectedRoute == route) {
                        viewModel.selectRoute(route)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }

    private func routePill(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? .white: .primary)
                .background(
                    Capsule().fill(isSelected ? .gray : .clear)
                )
                .overlay(
                    Capsule().stroke(.gray, lineWidth: isSelected ? 0 : 2)
                )
        }
        .buttonStyle(.plain)
    }

    private var arrivalsList: some View {
        List {
            let groups = viewModel.groupedArrivals
            if groups.isEmpty {
                Section {
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
                    .listRowSeparator(.hidden)
                }
            } else {
                ForEach(groups, id: \.direction) { group in
                    Section {
                        ForEach(group.arrivals) { arrival in
                            Button {
                                followTarget = FollowTarget(
                                    vehicleId: arrival.vehicleId,
                                    stopId: arrival.stopId
                                )
                            } label: {
                                arrivalRow(arrival)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        if groups.count > 1 || viewModel.effectiveSelectedRoute != nil {
                            Text(group.direction)
                                .font(.headline)
                                .foregroundStyle(.pink)
                                .textCase(nil)
                        }
                    }
                }
            }

            if !headerSubtitle.isEmpty {
                Text(headerSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .refreshable {
            await viewModel.manualRefresh()
        }
    }

    private var headerSubtitle: String {
        guard let lastUpdated = viewModel.lastUpdated else { return "" }
        if viewModel.isRefreshing {
            return "Updating..."
        }
        return "Last refreshed at \(Self.refreshTimeFormatter.string(from: lastUpdated))"
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
        .padding(.vertical, 10)
    }
}
