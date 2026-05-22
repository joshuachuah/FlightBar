import Foundation

actor AviationStackClient {
    private let apiKey: String
    private let baseURL = "https://api.aviationstack.com/v1"
    private let session: URLSession

    init() {
        self.apiKey = AviationStackClient.loadAPIKey()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }

    // MARK: - Fetch

    func fetchFlight(number: String) async throws -> Flight {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AviationStackError.missingAPIKey
        }

        let (data, urlResponse) = try await session.data(from: buildURL(number))
        let decoder = JSONDecoder()

        if let httpResponse = urlResponse as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            if let response = try? decoder.decode(AviationStackResponse.self, from: data),
               let apiError = response.error {
                throw AviationStackError.from(apiError)
            }
            throw AviationStackError.requestFailed(httpResponse.statusCode)
        }

        let response = try decoder.decode(AviationStackResponse.self, from: data)

        if let apiError = response.error {
            throw AviationStackError.from(apiError)
        }

        guard let flightData = response.data?.first else {
            throw AviationStackError.notFound(number)
        }

        return mapToFlight(raw: flightData, input: number)
    }

    // MARK: - URL Building

    private func buildURL(_ flightNumber: String) -> URL {
        var components = URLComponents(string: "\(baseURL)/flights")!
        components.queryItems = [
            URLQueryItem(name: "access_key", value: apiKey),
            URLQueryItem(name: "flight_iata", value: flightNumber.uppercased())
        ]
        return components.url!
    }

    // MARK: - Mapping

    private func mapToFlight(raw: AviationStackFlightData, input: String) -> Flight {
        let parsed = FlightNumberParser.parse(input)
        let status = FlightStatus(rawValue: raw.flight_status?.lowercased() ?? "") ?? .unknown

        return Flight(
            number: input,
            flightIATA: clean(raw.flight?.iata) ?? input,
            airlineIATA: clean(raw.airline?.iata) ?? parsed.airlineCode,
            airlineName: clean(raw.airline?.name) ?? "",
            departureAirport: clean(raw.departure?.iata) ?? "???",
            departureAirportName: clean(raw.departure?.airport),
            departureAirportICAO: clean(raw.departure?.icao),
            departureTerminal: clean(raw.departure?.terminal),
            departureGate: clean(raw.departure?.gate),
            departureDelayMinutes: raw.departure?.delay,
            arrivalAirport: clean(raw.arrival?.iata) ?? "???",
            arrivalAirportName: clean(raw.arrival?.airport),
            arrivalAirportICAO: clean(raw.arrival?.icao),
            arrivalTerminal: clean(raw.arrival?.terminal),
            arrivalGate: clean(raw.arrival?.gate),
            arrivalBaggage: clean(raw.arrival?.baggage),
            arrivalDelayMinutes: raw.arrival?.delay,
            scheduledDeparture: parseDate(raw.departure?.scheduled),
            estimatedDeparture: parseDate(raw.departure?.estimated),
            actualDeparture: parseDate(raw.departure?.actual),
            departureEstimatedRunway: parseDate(raw.departure?.estimatedRunway),
            departureActualRunway: parseDate(raw.departure?.actualRunway),
            scheduledArrival: parseDate(raw.arrival?.scheduled),
            estimatedArrival: parseDate(raw.arrival?.estimated),
            actualArrival: parseDate(raw.arrival?.actual),
            arrivalEstimatedRunway: parseDate(raw.arrival?.estimatedRunway),
            arrivalActualRunway: parseDate(raw.arrival?.actualRunway),
            aircraftRegistration: clean(raw.aircraft?.registration),
            aircraftIATA: clean(raw.aircraft?.iata),
            aircraftICAO: clean(raw.aircraft?.icao),
            liveUpdated: parseDate(raw.live?.updated),
            liveLatitude: raw.live?.latitude,
            liveLongitude: raw.live?.longitude,
            liveAltitude: raw.live?.altitude,
            liveDirection: raw.live?.direction,
            liveSpeedHorizontal: raw.live?.speedHorizontal,
            liveSpeedVertical: raw.live?.speedVertical,
            isOnGround: raw.live?.isGround,
            status: status
        )
    }

    private func parseDate(_ string: String?) -> Date? {
        guard let string = clean(string) else { return nil }

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: string) {
            return date
        }

        let internetFormatter = ISO8601DateFormatter()
        internetFormatter.formatOptions = [.withInternetDateTime]
        if let date = internetFormatter.date(from: string) {
            return date
        }

        let localFormatter = DateFormatter()
        localFormatter.locale = Locale(identifier: "en_US_POSIX")
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return localFormatter.date(from: string)
    }

    private func clean(_ string: String?) -> String? {
        guard let value = string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    // MARK: - API Key

    private static func loadAPIKey() -> String {
        // Try environment variable first, then UserDefaults for local app runs.
        if let key = ProcessInfo.processInfo.environment["AVIATIONSTACK_API_KEY"] {
            return key
        }
        // Fallback: store in UserDefaults for development
        if let key = UserDefaults.standard.string(forKey: "aviationstack_api_key") {
            return key
        }
        return ""
    }
}

// MARK: - Response Models

struct AviationStackResponse: Codable {
    let data: [AviationStackFlightData]?
    let error: AviationStackAPIError?
}

struct AviationStackAPIError: Codable {
    let code: String?
    let message: String?
}

struct AviationStackFlightData: Codable {
    let flight: AviationStackFlight?
    let airline: AviationStackAirline?
    let departure: AviationStackAirport?
    let arrival: AviationStackAirport?
    let aircraft: AviationStackAircraft?
    let live: AviationStackLive?
    let flight_status: String?

    enum CodingKeys: String, CodingKey {
        case flight, airline, departure, arrival, aircraft, live
        case flight_status = "flight_status"
    }
}

struct AviationStackFlight: Codable {
    let iata: String?
    let icao: String?
    let number: String?
}

struct AviationStackAirline: Codable {
    let name: String?
    let iata: String?
    let icao: String?
}

struct AviationStackAirport: Codable {
    let iata: String?
    let icao: String?
    let airport: String?
    let timezone: String?
    let terminal: String?
    let gate: String?
    let baggage: String?
    let delay: Int?
    let scheduled: String?
    let estimated: String?
    let actual: String?
    let estimatedRunway: String?
    let actualRunway: String?

    enum CodingKeys: String, CodingKey {
        case iata, icao, airport, timezone, terminal, gate, baggage, delay, scheduled, estimated, actual
        case estimatedRunway = "estimated_runway"
        case actualRunway = "actual_runway"
    }
}

struct AviationStackAircraft: Codable {
    let registration: String?
    let iata: String?
    let icao: String?
    let icao24: String?
}

struct AviationStackLive: Codable {
    let updated: String?
    let latitude: Double?
    let longitude: Double?
    let altitude: Double?
    let direction: Double?
    let speedHorizontal: Double?
    let speedVertical: Double?
    let isGround: Bool?

    enum CodingKeys: String, CodingKey {
        case updated, latitude, longitude, altitude, direction
        case speedHorizontal = "speed_horizontal"
        case speedVertical = "speed_vertical"
        case isGround = "is_ground"
    }
}

// MARK: - Errors

enum AviationStackError: LocalizedError {
    case missingAPIKey
    case notFound(String)
    case invalidAPIKey
    case rateLimited
    case requestFailed(Int)
    case api(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing AviationStack API key. Set AVIATIONSTACK_API_KEY before launching FlightBar or save aviationstack_api_key in UserDefaults."
        case .notFound(let number): return "Flight \(number) not found"
        case .invalidAPIKey: return "Invalid AviationStack API key"
        case .rateLimited: return "API rate limit exceeded"
        case .requestFailed(let statusCode): return "AviationStack request failed with HTTP \(statusCode)"
        case .api(let message): return message
        }
    }

    static func from(_ apiError: AviationStackAPIError) -> AviationStackError {
        switch apiError.code?.lowercased() {
        case "missing_access_key":
            return .missingAPIKey
        case "invalid_access_key", "inactive_user":
            return .invalidAPIKey
        case "usage_limit_reached", "rate_limit_reached":
            return .rateLimited
        default:
            if let message = apiError.message, !message.isEmpty {
                return .api(message)
            }
            return .api("AviationStack request failed")
        }
    }
}
