import SwiftUI

struct TrainArrivalsView: View {
    @State private var viewModel: TrainArrivalsViewModel
    @State private var followTarget: FollowTarget?

    private let trainRepository: TrainRepositoryProtocol

    private struct FollowTarget: Identifiable {
        let runNumber: String
        let stationId: String
        var id: String { "\(runNumber)-\(stationId)" }
    }

    private static let refreshTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm:ss a"
        f.timeZone = TimeZone(identifier: "America/Chicago")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    init(
        stationId: String,
        stationName: String,
        line: TrainLine?,
        trainRepository: TrainRepositoryProtocol,
        favoritesRepository: FavoritesRepositoryProtocol
    ) {
        self.trainRepository = trainRepository
        _viewModel = State(initialValue: TrainArrivalsViewModel(
            stationId: stationId,
            stationName: stationName,
            line: line,
            trainRepository: trainRepository,
            favoritesRepository: favoritesRepository
        ))
    }

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loading:
                TrainArrivalsSkeletonView()
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
                    if viewModel.hasMultipleLines {
                        linePillBar
                            .padding(.vertical, 12)
                    }
                    arrivalsList
                }
            }
        }
        .navigationTitle(viewModel.stationName)
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
                Text("Following train \(target.runNumber)")
            }.presentationDetents([.medium, .large])
        }
    }

    // MARK: - Line Filter Pills

    private var linePillBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                linePill(label: "All", colorHex: nil, textColorHex: nil, isSelected: viewModel.effectiveSelectedLine == nil) {
                    viewModel.selectLine(nil)
                }
                ForEach(viewModel.availableLineIds, id: \.self) { lineId in
                    let tl = viewModel.trainLine(for: lineId)
                    linePill(
                        label: viewModel.lineDisplayName(for: lineId),
                        colorHex: tl?.colorHex,
                        textColorHex: tl?.textColorHex,
                        isSelected: viewModel.effectiveSelectedLine == lineId
                    ) {
                        viewModel.selectLine(lineId)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }

    private func linePill(label: String, colorHex: String?, textColorHex: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? pillTextColor(textColorHex) : .primary)
                .background(
                    Capsule().fill(isSelected ? pillFillColor(colorHex) : .clear)
                )
                .overlay(
                    Capsule().stroke(.gray, lineWidth: isSelected ? 0 : 2)
                )
        }
        .buttonStyle(.plain)
    }

    private func pillFillColor(_ colorHex: String?) -> Color {
        guard let hex = colorHex else { return .gray }
        return Color(hex: hex)
    }

    private func pillTextColor(_ textColorHex: String?) -> Color {
        guard let hex = textColorHex else { return .white }
        return Color(hex: hex)
    }

    // MARK: - Arrivals List

    private var arrivalsList: some View {
        List {
            // Header section
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Station ID: \(viewModel.stationId)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    servingLineChips
                }
            }
            .listRowSeparator(.hidden)

            // Arrival groups
            let groups = viewModel.groupedArrivals
            if groups.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label("No Arrivals", systemImage: "clock")
                    } description: {
                        Text(emptyStateMessage)
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
                ForEach(groups) { group in
                    Section {
                        ForEach(group.arrivals) { arrival in
                            Button {
                                followTarget = FollowTarget(
                                    runNumber: arrival.runNumber,
                                    stationId: viewModel.stationId
                                )
                            } label: {
                                arrivalRow(arrival)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        if groups.count > 1 || viewModel.effectiveSelectedLine != nil {
                            Text(viewModel.groupTitle(for: group))
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

    private var servingLineChips: some View {
        let lineIds = viewModel.availableLineIds
        return Group {
            if !lineIds.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(lineIds, id: \.self) { lineId in
                        lineChip(for: lineId)
                    }
                }
            }
        }
    }

    private var emptyStateMessage: String {
        if let selectedLine = viewModel.effectiveSelectedLine {
            return "No \(viewModel.lineDisplayName(for: selectedLine)) arrivals predicted for this station right now."
        }
        return "No arrivals predicted for this station right now."
    }

    private var headerSubtitle: String {
        guard let lastUpdated = viewModel.lastUpdated else { return "" }
        if viewModel.isRefreshing {
            return "Updating..."
        }
        return "Last refreshed at \(Self.refreshTimeFormatter.string(from: lastUpdated))"
    }

    // MARK: - Arrival Row

    private func arrivalRow(_ arrival: TrainArrival) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    lineChip(for: arrival.line)
                    Text(arrival.destinationName)
                        .font(.subheadline)
                }
                Text("Run #\(arrival.runNumber)")
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
                    if arrival.isApproaching {
                        badge("Approaching", color: .blue)
                    }
                    if arrival.isDelayed {
                        badge("Delayed", color: .red)
                    }
                    if arrival.hasAlert {
                        badge("Alert", color: .orange)
                    }
                }
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
    }

    // MARK: - Shared Components

    private func lineChip(for routeId: String) -> some View {
        let tl = viewModel.trainLine(for: routeId)
        let fillColor = tl.map { Color(hex: $0.colorHex) } ?? .gray
        let textColor = tl.map { Color(hex: $0.textColorHex) } ?? .primary
        return Text(routeId)
            .font(.caption.bold())
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(textColor)
            .background(RoundedRectangle(cornerRadius: 4).fill(fillColor))
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 4).fill(color))
    }
}

// MARK: - Flow Layout for Serving Line Chips

private struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, offset) in result.offsets.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, offsets: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var offsets: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            offsets.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), offsets)
    }
}
