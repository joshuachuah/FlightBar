import SwiftUI

struct FlightRowView: View {
    let tracked: TrackedFlight
    @EnvironmentObject var tracker: FlightTracker
    @State private var showingDetails = false

    private var flight: Flight? {
        tracker.flightData[tracked.id]
    }

    private var isLoading: Bool {
        tracker.loadingFlightIDs.contains(tracked.id)
    }

    private var errorMessage: String? {
        tracker.flightErrors[tracked.id]
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    private var lastUpdatedFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        HStack(spacing: 8) {
            rowContent

            Button(action: { tracker.removeFlight(tracked) }) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help("Remove flight")
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var rowContent: some View {
        if let flight = flight {
            loadedContent(flight)
        } else if let errorMessage = errorMessage {
            errorContent(errorMessage)
        } else {
            loadingContent
        }
    }

    private func loadedContent(_ flight: Flight) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: flight.status.icon)
                .foregroundColor(colorForStatus(flight.status))
                .frame(width: 16)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(flight.flightIATA)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)

                    if tracked.isWatching {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .help("Auto-refreshing")
                    }

                    statusBadge(flight.status)
                }

                Text("\(flight.departureAirport) -> \(flight.arrivalAirport)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if let timingSummary = timingSummary(for: flight) {
                    Text(timingSummary)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if let airportSummary = airportSummary(for: flight) {
                    Text(airportSummary)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Text(metaSummary(for: flight))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            if isLoading {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 18)
            } else if let errorMessage = errorMessage {
                retryButton(systemImage: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                    .help(errorMessage)
            } else {
                Button(action: { showingDetails.toggle() }) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .help("Show flight details")
                .popover(isPresented: $showingDetails, arrowEdge: .trailing) {
                    FlightDetailView(flight: flight)
                }
            }
        }
        .frame(minWidth: 320, alignment: .leading)
    }

    private var loadingContent: some View {
        HStack(spacing: 8) {
            Text(tracked.flightNumber)
                .foregroundColor(.secondary)
            Spacer()
            if isLoading {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 18)
            } else {
                Text("Pending")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func errorContent(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(tracked.flightNumber)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)

                Text(message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
            retryButton(systemImage: "arrow.clockwise")
        }
    }

    private func retryButton(systemImage: String) -> some View {
        Button(action: { tracker.refreshFlight(tracked) }) {
            Image(systemName: systemImage)
                .font(.caption2)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .help("Retry lookup")
    }

    private func statusBadge(_ status: FlightStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .foregroundStyle(colorForStatus(status))
    }

    private func timingSummary(for flight: Flight) -> String? {
        let parts = [
            bestTimeSummary(prefix: "Dep", bestTime: flight.departureBestTime),
            bestTimeSummary(prefix: "Arr", bestTime: flight.arrivalBestTime)
        ].compactMap { $0 }

        return parts.isEmpty ? nil : parts.joined(separator: "  ")
    }

    private func bestTimeSummary(prefix: String, bestTime: (label: String, date: Date)?) -> String? {
        guard let bestTime else { return nil }
        return "\(prefix) \(timeFormatter.string(from: bestTime.date)) \(bestTime.label.lowercased())"
    }

    private func airportSummary(for flight: Flight) -> String? {
        var parts: [String] = []

        if let departure = locationSummary(
            terminal: flight.departureTerminal,
            gate: flight.departureGate,
            baggage: nil
        ) {
            parts.append("Dep \(departure)")
        }

        if let arrival = locationSummary(
            terminal: flight.arrivalTerminal,
            gate: flight.arrivalGate,
            baggage: flight.arrivalBaggage
        ) {
            parts.append("Arr \(arrival)")
        }

        if let departureDelay = delaySummary(prefix: "Dep", delay: flight.departureDelayMinutes) {
            parts.append(departureDelay)
        }

        if let arrivalDelay = delaySummary(prefix: "Arr", delay: flight.arrivalDelayMinutes) {
            parts.append(arrivalDelay)
        }

        return parts.isEmpty ? nil : parts.joined(separator: "  ")
    }

    private func locationSummary(terminal: String?, gate: String?, baggage: String?) -> String? {
        var parts: [String] = []
        if let terminal, !terminal.isEmpty {
            parts.append("T\(terminal)")
        }
        if let gate, !gate.isEmpty {
            parts.append("G\(gate)")
        }
        if let baggage, !baggage.isEmpty {
            parts.append("Bag \(baggage)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    private func delaySummary(prefix: String, delay: Int?) -> String? {
        guard let delay, delay > 0 else { return nil }
        return "\(prefix) +\(delay)m"
    }

    private func metaSummary(for flight: Flight) -> String {
        var parts: [String] = []

        if let airline = airlineSummary(for: flight) {
            parts.append(airline)
        }

        if let aircraftSummary = flight.aircraftSummary {
            parts.append(aircraftSummary)
        }

        parts.append("Updated \(lastUpdatedFormatter.string(from: flight.lastUpdated))")
        return parts.joined(separator: "  ")
    }

    private func airlineSummary(for flight: Flight) -> String? {
        if !flight.airlineName.isEmpty && !flight.airlineIATA.isEmpty {
            return "\(flight.airlineName) (\(flight.airlineIATA))"
        }
        if !flight.airlineName.isEmpty {
            return flight.airlineName
        }
        if !flight.airlineIATA.isEmpty {
            return flight.airlineIATA
        }
        return nil
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
