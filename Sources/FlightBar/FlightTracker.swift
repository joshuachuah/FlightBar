import Foundation

@MainActor
class FlightTracker: ObservableObject {
    @Published var trackedFlights: [TrackedFlight] = []
    @Published var flightData: [UUID: Flight] = [:]
    @Published var loadingFlightIDs: Set<UUID> = []
    @Published var flightErrors: [UUID: String] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let store = FlightStore()
    private let client = AviationStackClient()
    private var watchTimer: Timer?

    init() {
        loadFlights()
        if !trackedFlights.isEmpty {
            refreshAll()
        }
        if trackedFlights.contains(where: \.isWatching) {
            NotificationManager.shared.requestAuthorizationIfNeeded()
        }
        restartWatchTimer()
    }

    // MARK: - Persistence

    func loadFlights() {
        trackedFlights = store.load()
    }

    func saveFlights() {
        store.save(trackedFlights)
    }

    // MARK: - Add / Remove

    func addFlight(_ number: String, watch: Bool = false) {
        let normalized = FlightNumberParser.normalize(number)
        let tracked = TrackedFlight(flightNumber: normalized, isWatching: watch)
        trackedFlights.append(tracked)
        saveFlights()
        if watch {
            NotificationManager.shared.requestAuthorizationIfNeeded()
        }
        refreshFlight(tracked)
    }

    func removeFlight(_ tracked: TrackedFlight) {
        trackedFlights.removeAll { $0.id == tracked.id }
        flightData.removeValue(forKey: tracked.id)
        loadingFlightIDs.remove(tracked.id)
        flightErrors.removeValue(forKey: tracked.id)
        saveFlights()
    }

    func toggleWatch(_ tracked: TrackedFlight) {
        if let index = trackedFlights.firstIndex(where: { $0.id == tracked.id }) {
            trackedFlights[index].isWatching.toggle()
            saveFlights()
            if trackedFlights[index].isWatching {
                NotificationManager.shared.requestAuthorizationIfNeeded()
            }
            restartWatchTimer()
        }
    }

    // MARK: - Refresh

    func refreshAll() {
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            for tracked in trackedFlights {
                await refreshFlightAsync(tracked)
            }
            isLoading = false
        }
    }

    func refreshFlight(_ tracked: TrackedFlight) {
        Task { @MainActor in
            await refreshFlightAsync(tracked)
        }
    }

    private func refreshFlightAsync(_ tracked: TrackedFlight) async {
        loadingFlightIDs.insert(tracked.id)
        flightErrors.removeValue(forKey: tracked.id)

        defer {
            loadingFlightIDs.remove(tracked.id)
        }

        do {
            let flight = try await client.fetchFlight(number: tracked.flightNumber)
            let oldStatus = flightData[tracked.id]?.status
            flightData[tracked.id] = flight

            // Notify on status change
            if let old = oldStatus, old != flight.status {
                NotificationManager.shared.sendStatusChange(
                    flight: flight,
                    oldStatus: old
                )
            }
        } catch {
            let message = Self.displayMessage(for: error)
            flightErrors[tracked.id] = message
            errorMessage = message
        }
    }

    private static func displayMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }
        return error.localizedDescription
    }

    // MARK: - Watch Timer

    func startWatchTimer() {
        restartWatchTimer()
    }

    func restartWatchTimer() {
        watchTimer?.invalidate()

        let watchedFlights = trackedFlights.filter { $0.isWatching }
        guard !watchedFlights.isEmpty else { return }

        watchTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshWatchedFlights()
            }
        }
    }

    private func refreshWatchedFlights() {
        for tracked in trackedFlights where tracked.isWatching {
            refreshFlight(tracked)
        }
    }
}
