import SwiftUI

struct FlightDetailView: View {
    let flight: Flight

    private var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    private var coordinateFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 0
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Divider()

            routeSection

            Divider()

            timeSection

            if hasAirportDetails {
                Divider()
                airportDetailsSection
            }

            if hasAircraftOrLiveDetails {
                Divider()
                aircraftAndLiveSection
            }

            Divider()

            Text("Updated \(flight.lastUpdated, style: .relative)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 360)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(flight.flightIATA)
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospaced()

                Text(airlineSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            statusBadge(flight.status)
        }
    }

    private var routeSection: some View {
        HStack(alignment: .top) {
            airportColumn(
                title: "DEPARTURE",
                code: flight.departureAirport,
                name: flight.departureAirportName,
                icao: flight.departureAirportICAO
            )

            Spacer()

            Image(systemName: "airplane")
                .font(.title3)
                .foregroundColor(.secondary)
                .padding(.top, 18)

            Spacer()

            airportColumn(
                title: "ARRIVAL",
                code: flight.arrivalAirport,
                name: flight.arrivalAirportName,
                icao: flight.arrivalAirportICAO
            )
            .multilineTextAlignment(.trailing)
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Times")

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    smallTitle("Departure")
                    optionalDateRow("Scheduled", flight.scheduledDeparture)
                    optionalDateRow("Estimated", flight.estimatedDeparture)
                    optionalDateRow("Actual", flight.actualDeparture)
                    optionalDateRow("Est runway", flight.departureEstimatedRunway)
                    optionalDateRow("Actual runway", flight.departureActualRunway)
                }

                VStack(alignment: .leading, spacing: 4) {
                    smallTitle("Arrival")
                    optionalDateRow("Scheduled", flight.scheduledArrival)
                    optionalDateRow("Estimated", flight.estimatedArrival)
                    optionalDateRow("Actual", flight.actualArrival)
                    optionalDateRow("Est runway", flight.arrivalEstimatedRunway)
                    optionalDateRow("Actual runway", flight.arrivalActualRunway)
                }
            }
        }
    }

    private var airportDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Airport Details")

            optionalTextRow("Departure terminal", flight.departureTerminal)
            optionalTextRow("Departure gate", flight.departureGate)
            optionalTextRow("Departure delay", delayText(flight.departureDelayMinutes))
            optionalTextRow("Arrival terminal", flight.arrivalTerminal)
            optionalTextRow("Arrival gate", flight.arrivalGate)
            optionalTextRow("Baggage", flight.arrivalBaggage)
            optionalTextRow("Arrival delay", delayText(flight.arrivalDelayMinutes))
        }
    }

    private var aircraftAndLiveSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Aircraft")

            optionalTextRow("Aircraft", flight.aircraftSummary)
            optionalTextRow("Live state", liveStateText)
            optionalTextRow("Live position", livePositionText)
            optionalDateRow("Live updated", flight.liveUpdated)
        }
    }

    private var airlineSummary: String {
        if flight.airlineName.isEmpty {
            return flight.airlineIATA
        }
        if flight.airlineIATA.isEmpty {
            return flight.airlineName
        }
        return "\(flight.airlineName) (\(flight.airlineIATA))"
    }

    private var hasAirportDetails: Bool {
        [
            flight.departureTerminal,
            flight.departureGate,
            delayText(flight.departureDelayMinutes),
            flight.arrivalTerminal,
            flight.arrivalGate,
            flight.arrivalBaggage,
            delayText(flight.arrivalDelayMinutes)
        ].contains { value in
            value?.isEmpty == false
        }
    }

    private var hasAircraftOrLiveDetails: Bool {
        flight.aircraftSummary != nil ||
            liveStateText != nil ||
            livePositionText != nil ||
            flight.liveUpdated != nil
    }

    private var liveStateText: String? {
        guard let isOnGround = flight.isOnGround else { return nil }
        return isOnGround ? "On ground" : "Airborne"
    }

    private var livePositionText: String? {
        guard let latitude = flight.liveLatitude,
              let longitude = flight.liveLongitude,
              let latitudeText = coordinateFormatter.string(from: NSNumber(value: latitude)),
              let longitudeText = coordinateFormatter.string(from: NSNumber(value: longitude)) else {
            return nil
        }
        return "\(latitudeText), \(longitudeText)"
    }

    private func airportColumn(title: String, code: String, name: String?, icao: String?) -> some View {
        VStack(alignment: title == "DEPARTURE" ? .leading : .trailing, spacing: 3) {
            smallTitle(title)

            Text(code)
                .font(.headline)
                .monospaced()

            if let name, !name.isEmpty {
                Text(name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if let icao, !icao.isEmpty {
                Text(icao)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospaced()
            }
        }
        .frame(maxWidth: 135, alignment: title == "DEPARTURE" ? .leading : .trailing)
    }

    @ViewBuilder
    private func optionalDateRow(_ title: String, _ date: Date?) -> some View {
        if let date {
            detailRow(title, formatter.string(from: date))
        }
    }

    @ViewBuilder
    private func optionalTextRow(_ title: String, _ value: String?) -> some View {
        if let value, !value.isEmpty {
            detailRow(title, value)
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.caption)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
    }

    private func smallTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption2)
            .foregroundColor(.secondary)
    }

    private func statusBadge(_ status: FlightStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(colorForStatus(status))
    }

    private func delayText(_ minutes: Int?) -> String? {
        guard let minutes else { return nil }
        return minutes == 1 ? "1 min" : "\(minutes) min"
    }

    private func colorForStatus(_ status: FlightStatus) -> Color {
        switch status {
        case .scheduled: return .gray
        case .active, .departed, .inflight: return .blue
        case .arrived, .landed: return .green
        case .delayed: return .orange
        case .cancelled, .diverted, .incident: return .red
        case .unknown: return .gray
        }
    }
}
