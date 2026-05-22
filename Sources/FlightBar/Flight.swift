import Foundation

struct Flight: Codable, Identifiable, Equatable {
    let id: UUID
    let number: String          // Raw input (e.g. "SQ321")
    let flightIATA: String      // Normalized IATA code
    let airlineIATA: String    // Airline IATA code
    let airlineName: String
    let departureAirport: String
    let departureAirportName: String?
    let departureAirportICAO: String?
    let departureTerminal: String?
    let departureGate: String?
    let departureDelayMinutes: Int?
    let arrivalAirport: String
    let arrivalAirportName: String?
    let arrivalAirportICAO: String?
    let arrivalTerminal: String?
    let arrivalGate: String?
    let arrivalBaggage: String?
    let arrivalDelayMinutes: Int?
    let scheduledDeparture: Date?
    let estimatedDeparture: Date?
    let actualDeparture: Date?
    let departureEstimatedRunway: Date?
    let departureActualRunway: Date?
    let scheduledArrival: Date?
    let estimatedArrival: Date?
    let actualArrival: Date?
    let arrivalEstimatedRunway: Date?
    let arrivalActualRunway: Date?
    let aircraftRegistration: String?
    let aircraftIATA: String?
    let aircraftICAO: String?
    let liveUpdated: Date?
    let liveLatitude: Double?
    let liveLongitude: Double?
    let liveAltitude: Double?
    let liveDirection: Double?
    let liveSpeedHorizontal: Double?
    let liveSpeedVertical: Double?
    let isOnGround: Bool?
    var status: FlightStatus
    var lastUpdated: Date

    init(
        id: UUID = UUID(),
        number: String,
        flightIATA: String,
        airlineIATA: String,
        airlineName: String,
        departureAirport: String,
        departureAirportName: String? = nil,
        departureAirportICAO: String? = nil,
        departureTerminal: String? = nil,
        departureGate: String? = nil,
        departureDelayMinutes: Int? = nil,
        arrivalAirport: String,
        arrivalAirportName: String? = nil,
        arrivalAirportICAO: String? = nil,
        arrivalTerminal: String? = nil,
        arrivalGate: String? = nil,
        arrivalBaggage: String? = nil,
        arrivalDelayMinutes: Int? = nil,
        scheduledDeparture: Date? = nil,
        estimatedDeparture: Date? = nil,
        actualDeparture: Date? = nil,
        departureEstimatedRunway: Date? = nil,
        departureActualRunway: Date? = nil,
        scheduledArrival: Date? = nil,
        estimatedArrival: Date? = nil,
        actualArrival: Date? = nil,
        arrivalEstimatedRunway: Date? = nil,
        arrivalActualRunway: Date? = nil,
        aircraftRegistration: String? = nil,
        aircraftIATA: String? = nil,
        aircraftICAO: String? = nil,
        liveUpdated: Date? = nil,
        liveLatitude: Double? = nil,
        liveLongitude: Double? = nil,
        liveAltitude: Double? = nil,
        liveDirection: Double? = nil,
        liveSpeedHorizontal: Double? = nil,
        liveSpeedVertical: Double? = nil,
        isOnGround: Bool? = nil,
        status: FlightStatus = .unknown,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.number = number
        self.flightIATA = flightIATA
        self.airlineIATA = airlineIATA
        self.airlineName = airlineName
        self.departureAirport = departureAirport
        self.departureAirportName = departureAirportName
        self.departureAirportICAO = departureAirportICAO
        self.departureTerminal = departureTerminal
        self.departureGate = departureGate
        self.departureDelayMinutes = departureDelayMinutes
        self.arrivalAirport = arrivalAirport
        self.arrivalAirportName = arrivalAirportName
        self.arrivalAirportICAO = arrivalAirportICAO
        self.arrivalTerminal = arrivalTerminal
        self.arrivalGate = arrivalGate
        self.arrivalBaggage = arrivalBaggage
        self.arrivalDelayMinutes = arrivalDelayMinutes
        self.scheduledDeparture = scheduledDeparture
        self.estimatedDeparture = estimatedDeparture
        self.actualDeparture = actualDeparture
        self.departureEstimatedRunway = departureEstimatedRunway
        self.departureActualRunway = departureActualRunway
        self.scheduledArrival = scheduledArrival
        self.estimatedArrival = estimatedArrival
        self.actualArrival = actualArrival
        self.arrivalEstimatedRunway = arrivalEstimatedRunway
        self.arrivalActualRunway = arrivalActualRunway
        self.aircraftRegistration = aircraftRegistration
        self.aircraftIATA = aircraftIATA
        self.aircraftICAO = aircraftICAO
        self.liveUpdated = liveUpdated
        self.liveLatitude = liveLatitude
        self.liveLongitude = liveLongitude
        self.liveAltitude = liveAltitude
        self.liveDirection = liveDirection
        self.liveSpeedHorizontal = liveSpeedHorizontal
        self.liveSpeedVertical = liveSpeedVertical
        self.isOnGround = isOnGround
        self.status = status
        self.lastUpdated = lastUpdated
    }

    var departureDisplayName: String {
        airportDisplay(code: departureAirport, name: departureAirportName)
    }

    var arrivalDisplayName: String {
        airportDisplay(code: arrivalAirport, name: arrivalAirportName)
    }

    var departureBestTime: (label: String, date: Date)? {
        bestTime(scheduled: scheduledDeparture, estimated: estimatedDeparture, actual: actualDeparture)
    }

    var arrivalBestTime: (label: String, date: Date)? {
        bestTime(scheduled: scheduledArrival, estimated: estimatedArrival, actual: actualArrival)
    }

    var aircraftSummary: String? {
        let parts = [aircraftRegistration, aircraftIATA, aircraftICAO]
            .compactMap { value -> String? in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }

    private func airportDisplay(code: String, name: String?) -> String {
        guard let name, !name.isEmpty else { return code }
        return "\(code) - \(name)"
    }

    private func bestTime(scheduled: Date?, estimated: Date?, actual: Date?) -> (label: String, date: Date)? {
        if let actual {
            return ("Actual", actual)
        }
        if let estimated {
            return ("Est", estimated)
        }
        if let scheduled {
            return ("Sched", scheduled)
        }
        return nil
    }
}

enum FlightStatus: String, Codable, CaseIterable {
    case scheduled = "scheduled"
    case active = "active"
    case departed = "departed"
    case inflight = "inflight"
    case arrived = "arrived"
    case delayed = "delayed"
    case diverted = "diverted"
    case cancelled = "cancelled"
    case incident = "incident"
    case landed = "landed"
    case unknown = "unknown"

    var icon: String {
        switch self {
        case .scheduled: return "clock"
        case .active, .departed, .inflight: return "airplane"
        case .arrived, .landed: return "checkmark.circle"
        case .delayed: return "exclamationmark.triangle"
        case .cancelled: return "xmark.circle"
        case .diverted, .incident: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    var color: String {
        switch self {
        case .scheduled: return "gray"
        case .active, .departed, .inflight: return "blue"
        case .arrived, .landed: return "green"
        case .delayed: return "orange"
        case .cancelled: return "red"
        case .diverted, .incident: return "red"
        case .unknown: return "gray"
        }
    }
}
