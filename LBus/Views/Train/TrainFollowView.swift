import SwiftUI

struct TrainFollowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TrainFollowViewModel

    private static let refreshTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm:ss a"
        f.timeZone = TimeZone(identifier: "America/Chicago")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    init(
        runNumber: String,
        stationId: String,
        trainRepository: TrainRepositoryProtocol
    ) {
        _viewModel = State(initialValue: TrainFollowViewModel(
            runNumber: runNumber,
            originatingStationId: stationId,
            trainRepository: trainRepository
        ))
    }

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loading:
                TrainFollowSkeletonView()
            case .error(let message):
                ContentUnavailableView {
                    Label("Unable to Load", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.manualRefresh() }
                    }
                }
            case .loaded:
                followContent
            }
        }
        .navigationTitle("Run #\(viewModel.runNumber)")
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
    }

    private var followContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    if let line = viewModel.line {
                        Text(line)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let destination = viewModel.destinationName {
                        Text("To \(destination)")
                            .font(.subheadline)
                            .foregroundStyle(.pink)
                    }
                    if let lastUpdated = viewModel.lastUpdated {
                        Text("Last refreshed at \(Self.refreshTimeFormatter.string(from: lastUpdated))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 12)

                if viewModel.stations.isEmpty {
                    ContentUnavailableView {
                        Label("No Stations", systemImage: "tram")
                    } description: {
                        Text(viewModel.emptyStateMessage)
                    }
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.stations) { arrival in
                            stationRow(arrival)

                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }
            }
        }
    }

    private func stationRow(_ arrival: TrainArrival) -> some View {
        let isOriginating = arrival.stationId == viewModel.originatingStationId

        return HStack(spacing: 0) {
            Rectangle()
                .fill(isOriginating ? Color.pink : Color.clear)
                .frame(width: 4)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(arrival.stationName)
                        .font(.subheadline)
                        .fontWeight(isOriginating ? .semibold : .regular)
                    Text(arrival.stopDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(arrival.countdownText)
                        .font(.headline)
                        .foregroundStyle(arrival.countdown == .due ? .red : .primary)
                    Text("\(arrival.clockTimeText) \(arrival.dayContextText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        ForEach(arrival.statusBadges, id: \.label) { b in
                            StatusBadgeView(label: b.label, style: b.style)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(isOriginating ? Color.pink.opacity(0.08) : Color.clear)
    }
}
