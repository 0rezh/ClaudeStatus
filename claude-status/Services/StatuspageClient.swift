import Foundation

struct StatuspageSummary: Decodable, Sendable {
    struct Page: Decodable, Sendable { let name: String?; let url: String?; let updated_at: String? }
    struct Component: Decodable, Sendable {
        let id: String; let name: String; let status: ServiceStatus
        let position: Int; let updated_at: String?; let group: Bool?
    }
    struct Affected: Decodable, Sendable { let code: String }
    struct Update: Decodable, Sendable {
        let id: String; let status: IncidentStatus; let body: String
        let display_at: String?; let affected_components: [Affected]?
    }
    struct Incident: Decodable, Sendable {
        let id: String; let name: String; let status: IncidentStatus; let impact: IncidentImpact
        let shortlink: String?; let created_at: String?; let updated_at: String?
        let incident_updates: [Update]?
    }
    struct Status: Decodable, Sendable { let indicator: OverallIndicator; let description: String }

    let page: Page?
    let components: [Component]
    let incidents: [Incident]
    let status: Status?
}

struct UptimeInfo: Sendable {
    var percent: Double?
    var days: [DayStatus]
}

protocol StatuspageClientProtocol: Sendable {
    func fetchSummary() async throws -> StatuspageSummary
    func fetchUptime() async throws -> [String: UptimeInfo]
}

struct StatuspageClient: StatuspageClientProtocol {
    static let defaultOrigin = URL(string: "https://status.claude.com")!

    let origin: URL

    init(origin: URL = StatuspageClient.defaultOrigin) {
        self.origin = origin
    }

    private var session: URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 20
        config.httpAdditionalHeaders = ["User-Agent": "claude-status-mac"]
        return URLSession(configuration: config)
    }

    func fetchSummary() async throws -> StatuspageSummary {
        let (data, _) = try await session.data(from: origin.appending(path: "api/v2/summary.json"))
        return try JSONDecoder().decode(StatuspageSummary.self, from: data)
    }

    func fetchUptime() async throws -> [String: UptimeInfo] {
        let (data, _) = try await session.data(from: origin)
        guard let html = String(data: data, encoding: .utf8) else { return [:] }
        return UptimeHTMLParser.parse(html)
    }
}

enum UptimeHTMLParser {
    static func parse(_ html: String) -> [String: UptimeInfo] {
        var result: [String: UptimeInfo] = [:]

        let percentRegex = #/id="uptime-percent-(?<id>[a-z0-9]+)"[\s\S]*?data-var="uptime-percent">\s*(?<pct>[\d.]+)/#
        for match in html.matches(of: percentRegex) {
            result[String(match.id)] = UptimeInfo(percent: Double(match.pct), days: [])
        }

        guard let range = html.range(of: "uptimeData = {"),
              let json = extractObjectLiteral(in: html, from: html.index(range.upperBound, offsetBy: -1)),
              let root = try? JSONSerialization.jsonObject(with: json) as? [String: Any] else {
            return result
        }
        for (id, entry) in root {
            guard let entry = entry as? [String: Any],
                  let rawDays = entry["days"] as? [[String: Any]] else { continue }
            let days: [DayStatus] = rawDays.map { day in
                let outages = day["outages"] as? [String: Any] ?? [:]
                let status: ServiceStatus
                if outages["m"] != nil { status = .majorOutage }
                else if outages["p"] != nil { status = .partialOutage }
                else if outages["d"] != nil { status = .degradedPerformance }
                else { status = .operational }
                return DayStatus(date: day["date"] as? String ?? "", status: status)
            }
            result[id, default: UptimeInfo(percent: nil, days: [])].days = days
        }
        return result
    }

    private static func extractObjectLiteral(in html: String, from start: String.Index) -> Data? {
        var depth = 0, inString = false, escaped = false
        var i = start
        while i < html.endIndex {
            let ch = html[i]
            if inString {
                if escaped { escaped = false }
                else if ch == "\\" { escaped = true }
                else if ch == "\"" { inString = false }
            } else if ch == "\"" { inString = true }
            else if ch == "{" { depth += 1 }
            else if ch == "}" {
                depth -= 1
                if depth == 0 { return html[start...i].data(using: .utf8) }
            }
            i = html.index(after: i)
        }
        return nil
    }
}

extension StatusSnapshot {
    init(summary: StatuspageSummary, uptime: [String: UptimeInfo]) {
        let components = summary.components
            .filter { $0.group != true }
            .sorted { $0.position < $1.position }
            .map { c in
                ServiceComponent(
                    id: c.id, name: c.name, status: c.status, position: c.position,
                    updatedAt: c.updated_at,
                    uptimePercent: uptime[c.id]?.percent,
                    days: uptime[c.id]?.days ?? []
                )
            }
        let incidents = summary.incidents.map { i in
            let updates = i.incident_updates ?? []
            var affected: [String] = []
            for u in updates { for a in u.affected_components ?? [] where !affected.contains(a.code) { affected.append(a.code) } }
            return Incident(
                id: i.id, name: i.name, status: i.status, impact: i.impact,
                shortlink: i.shortlink, createdAt: i.created_at, updatedAt: i.updated_at,
                affectedComponentIds: affected,
                updates: updates.map { IncidentUpdate(id: $0.id, status: $0.status, body: $0.body, displayAt: $0.display_at) }
            )
        }
        self.init(
            type: "snapshot",
            page: PageInfo(name: summary.page?.name, url: summary.page?.url, updatedAt: summary.page?.updated_at),
            overall: OverallStatus(indicator: summary.status?.indicator ?? .none, description: summary.status?.description ?? ""),
            components: components,
            incidents: incidents,
            generatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }
}
