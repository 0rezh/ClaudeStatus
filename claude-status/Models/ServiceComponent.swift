import Foundation

struct DayStatus: Codable, Sendable, Hashable {
    let date: String
    let status: ServiceStatus
}

struct ServiceComponent: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let name: String
    let status: ServiceStatus
    let position: Int
    let updatedAt: String?
    let uptimePercent: Double?
    let days: [DayStatus]

    var hasUptimeHistory: Bool { !days.isEmpty || uptimePercent != nil }
}
