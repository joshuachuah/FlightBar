import Foundation

class FlightStore {
    private let defaults = UserDefaults.standard
    private let key = "tracked_flights"

    func save(_ flights: [TrackedFlight]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(flights) {
            defaults.set(data, forKey: key)
        }
    }

    func load() -> [TrackedFlight] {
        guard let data = defaults.data(forKey: key) else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([TrackedFlight].self, from: data)) ?? []
    }
}