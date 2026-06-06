import Foundation

enum APIKeyStore {
    static let didChangeNotification = Notification.Name("FlightBarAPIKeyDidChange")

    private static let apiKeyName = "AVIATIONSTACK_API_KEY"

    static func load() throws -> String? {
        for url in dotenvURLs {
            guard FileManager.default.fileExists(atPath: url.path) else {
                continue
            }

            let values = try parseDotenvFile(at: url)
            if let key = values[apiKeyName]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !key.isEmpty {
                return key
            }
        }

        return nil
    }

    static func reload() {
        postChangeNotification()
    }

    static var dotenvLocationsDescription: String {
        dotenvURLs
            .map(\.path)
            .joined(separator: "\n")
    }

    private static var dotenvURLs: [URL] {
        var urls: [URL] = []

        if let configuredPath = ProcessInfo.processInfo.environment["FLIGHTBAR_DOTENV_PATH"],
           !configuredPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            urls.append(URL(fileURLWithPath: configuredPath).standardizedFileURL)
        }

        urls.append(URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".env")
            .standardizedFileURL)

        if let resourceURL = Bundle.main.resourceURL {
            urls.append(resourceURL
                .appendingPathComponent(".env")
                .standardizedFileURL)
        }

        urls.append(Bundle.main.bundleURL
            .deletingLastPathComponent()
            .appendingPathComponent(".env")
            .standardizedFileURL)

        return urls.uniqued()
    }

    private static func parseDotenvFile(at url: URL) throws -> [String: String] {
        let contents = try String(contentsOf: url, encoding: .utf8)
        var values: [String: String] = [:]

        for line in contents.components(separatedBy: .newlines) {
            guard let assignment = parseAssignment(line) else {
                continue
            }
            values[assignment.key] = assignment.value
        }

        return values
    }

    private static func parseAssignment(_ line: String) -> (key: String, value: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else {
            return nil
        }

        let assignment = trimmed.hasPrefix("export ")
            ? String(trimmed.dropFirst("export ".count))
            : trimmed

        guard let equalsIndex = assignment.firstIndex(of: "=") else {
            return nil
        }

        let key = assignment[..<equalsIndex].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            return nil
        }

        let rawValue = assignment[assignment.index(after: equalsIndex)...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (key, cleanValue(rawValue))
    }

    private static func cleanValue(_ value: String) -> String {
        guard let first = value.first else {
            return value
        }

        if first == "\"" || first == "'" {
            let start = value.index(after: value.startIndex)
            if let end = value[start...].firstIndex(of: first) {
                return String(value[start..<end])
            }
        }

        if let commentIndex = value.firstIndex(of: "#") {
            return value[..<commentIndex].trimmingCharacters(in: .whitespaces)
        }

        return value
    }

    private static func postChangeNotification() {
        if Thread.isMainThread {
            NotificationCenter.default.post(name: didChangeNotification, object: nil)
        } else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: didChangeNotification, object: nil)
            }
        }
    }
}

private extension Array where Element == URL {
    func uniqued() -> [URL] {
        var seen: Set<String> = []
        return filter { url in
            seen.insert(url.path).inserted
        }
    }
}
