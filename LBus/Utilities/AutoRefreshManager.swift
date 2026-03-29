import Foundation

@MainActor
protocol AutoRefreshManagerProtocol: Observable {
    var lastUpdated: Date? { get }
    var isRefreshing: Bool { get }

    /// Begins the periodic auto-refresh timer. The first refresh fires after the configured
    /// interval, not immediately — call `refreshNow()` first if you need an immediate load.
    func start()
    func stop()
    func refreshNow() async
}

@MainActor
@Observable
final class AutoRefreshManager: AutoRefreshManagerProtocol {

    // MARK: - Observable Properties

    private(set) var lastUpdated: Date? = nil
    private(set) var isRefreshing: Bool = false

    // MARK: - Configuration

    private let action: () async throws -> Void
    private let userDefaults: UserDefaults

    // MARK: - Internal State

    private var timerTask: Task<Void, Never>?
    private var settingsObserver: (any NSObjectProtocol)?

    // MARK: - Init

    init(action: @escaping () async throws -> Void, userDefaults: UserDefaults = .standard) {
        self.action = action
        self.userDefaults = userDefaults
        observeSettingsChanges()
    }

    deinit {
        MainActor.assumeIsolated {
            timerTask?.cancel()
            if let observer = settingsObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }

    // MARK: - Public

    func start() {
        startTimerIfNeeded()
    }

    func stop() {
        cancelTimer()
    }

    func refreshNow() async {
        await performRefresh()
        restartTimerIfNeeded()
    }

    // MARK: - Timer

    private func startTimerIfNeeded() {
        cancelTimer()
        guard isAutoRefreshEnabled else { return }

        let interval = refreshInterval
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                await self?.performRefresh()
            }
        }
    }

    private func cancelTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func restartTimerIfNeeded() {
        guard timerTask != nil || isAutoRefreshEnabled else { return }
        cancelTimer()
        startTimerIfNeeded()
    }

    // MARK: - Refresh

    private func performRefresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        do {
            try await action()
            lastUpdated = Date()
        } catch {
            // lastUpdated intentionally not updated on failure
        }
        isRefreshing = false
    }

    // MARK: - Settings

    private var isAutoRefreshEnabled: Bool {
        if userDefaults.object(forKey: SettingsKeys.autoRefreshEnabled) == nil {
            return true
        }
        return userDefaults.bool(forKey: SettingsKeys.autoRefreshEnabled)
    }

    private var refreshInterval: Int {
        let value = userDefaults.integer(forKey: SettingsKeys.refreshIntervalSeconds)
        return value > 0 ? value : 30
    }

    private func observeSettingsChanges() {
        settingsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: userDefaults,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.timerTask != nil else { return }
                self.startTimerIfNeeded()
            }
        }
    }
}
