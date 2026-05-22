import Foundation

struct TrackedFlight: Codable, Identifiable, Equatable {
    let id: UUID
    let flightNumber: String      // User input (e.g. "SQ321")
    var isWatching: Bool           // True = poll on interval, false = on-demand only
    var addedAt: Date

    init(flightNumber: String, isWatching: Bool = false) {
        self.id = UUID()
        self.flightNumber = flightNumber
        self.isWatching = isWatching
        self.addedAt = Date()
    }
}