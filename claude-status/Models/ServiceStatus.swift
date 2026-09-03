import Foundation

protocol StatuspageEnum: RawRepresentable, Codable, Sendable, Hashable where RawValue == String {
    static var unknown: Self { get }
}

extension StatuspageEnum {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: raw) ?? .unknown
    }

    init(raw: String) {
        self = Self(rawValue: raw) ?? .unknown
    }
}

enum ServiceStatus: String, StatuspageEnum {
    case operational
    case degradedPerformance = "degraded_performance"
    case partialOutage = "partial_outage"
    case majorOutage = "major_outage"
    case underMaintenance = "under_maintenance"
    case unknown

    var severity: Int {
        switch self {
        case .unknown: 0
        case .operational: 1
        case .underMaintenance: 2
        case .degradedPerformance: 3
        case .partialOutage: 4
        case .majorOutage: 5
        }
    }

    var isHealthy: Bool { self == .operational }
}
