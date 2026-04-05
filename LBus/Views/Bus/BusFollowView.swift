import SwiftUI

struct BusFollowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: BusFollowViewModel
    @State private var showRefreshShimmer = false

    private static let refreshTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm:ss a"
        f.timeZone = TimeZone(identifier: "America/Chicago")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    init(
        vehicleId: String,
        stopId: String,
        busRepository: BusRepositoryProtocol
    ) {
        _viewModel = State(initialValue: BusFollowViewModel(
            vehicleId: vehicleId,
            originatingStopId: stopId,
            busRepository: busRepository
        ))
    }

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loading:
                BusFollowSkeletonView()
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
                followContent
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close", systemImage: "xmark") { dismiss() }
            }
            ToolbarItem(placement: .bottomBar) {
                Button {
                    Task { await viewModel.manualRefresh() }
                } label: {
                    if viewModel.isRefreshing {
                        ProgressView()
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
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
        .onChange(of: viewModel.refreshCount) { _, _ in
            showRefreshShimmer = true
            Task {
                try? await Task.sleep(for: .seconds(1.0))
                showRefreshShimmer = false
            }
        }
    }

    private var navigationTitle: String {
        var parts: [String] = []
        if let route = viewModel.route { parts.append("RT\(route)") }
        parts.append("Bus#\(viewModel.vehicleId)")
        if let direction = viewModel.routeDirection { parts.append(direction) }
        return parts.joined(separator: " ")
    }

    private var followContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding()

                if viewModel.stops.isEmpty {
                    ContentUnavailableView {
                        Label("No Stops", systemImage: "bus")
                    } description: {
                        Text("No upcoming stops predicted for this vehicle right now.")
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
                        ForEach(viewModel.stops) { stop in
                            stopRow(stop)
                                .modifier(RefreshShimmerModifier(isActive: showRefreshShimmer))

                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let destination = viewModel.destination {
                    Text("To \(destination)")
                        .font(.subheadline)
                        .foregroundStyle(.pink)
                }
                if let lastUpdated = viewModel.lastUpdated {
                    Text("Last refreshed at \(Self.refreshTimeFormatter.string(from: lastUpdated))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private func stopRow(_ stop: BusArrival) -> some View {
        let isOriginating = stop.stopId == viewModel.originatingStopId

        return HStack(spacing: 0) {
            Rectangle()
                .fill(isOriginating ? Color.pink : Color.clear)
                .frame(width: 4)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stop.stopName)
                        .font(.subheadline)
                        .fontWeight(isOriginating ? .semibold : .regular)
                    Text("Stop \(stop.stopId)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let distance = stop.distanceText {
                        Text(distance)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(stop.countdownText)
                        .font(.headline)
                        .foregroundStyle(stop.countdown == .due ? .red : .primary)
                    Text("\(stop.clockTimeText) \(stop.dayContextText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if stop.isDelayed {
                        Text("Delayed")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).fill(.red))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(isOriginating ? Color.pink.opacity(0.08) : Color.clear)
    }
}
