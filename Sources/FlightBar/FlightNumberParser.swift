import Foundation

struct FlightNumberParser {
    /// Normalize a flight number input (strip whitespace, uppercase)
    static func normalize(_ input: String) -> String {
        input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    /// Parse airline code from a flight number
    /// "SQ321" -> (airlineCode: "SQ", flightNum: "321")
    /// "321" -> (airlineCode: "", flightNum: "321")
    static func parse(_ input: String) -> (airlineCode: String, flightNum: String) {
        let normalized = normalize(input)

        // Split letters from digits: "SQ321" -> "SQ", "321"
        let letterPart = String(normalized.prefix(while: { $0.isLetter }))
        let digitPart = String(normalized.drop(while: { $0.isLetter }))

        return (airlineCode: letterPart, flightNum: digitPart)
    }

    // MARK: - Airline Overrides
    // Ported from FlightCLI's airline overrides map

    static let airlineOverrides: [String: String] = [
        "RPA": "YX",
        "SCX": "SY",
        "ENY": "MQ",
        "ASA": "AS",
        "AVA": "AV",
        "DLA": "EN",
    ]

    /// Resolve airline IATA code, applying overrides
    static func resolveAirlineIATA(_ code: String) -> String {
        airlineOverrides[code] ?? code
    }
}