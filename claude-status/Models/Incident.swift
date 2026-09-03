import Foundation

enum IncidentStatus: String, StatuspageEnum {
    case investigating
    case identified
    case monitoring
    case resolved
    case postmortem
    case unknown

    var isActive: Bool {
        switch self {
        case .investigating, .identified, .monitoring, .unknown: true
        case .resolved, .postmortem: false
        }
    }
}

enum IncidentImpact: String, StatuspageEnum {
    case none
    case minor
    case major
    case critical
    case unknown
}

struct IncidentUpdate: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let status: IncidentStatus
    let body: String
    let displayAt: String?
}

struct Incident: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let name: String
    let status: IncidentStatus
    let impact: IncidentImpact
    let shortlink: String?
    let createdAt: String?
    let updatedAt: String?
    let affectedComponentIds: [String]
    let updates: [IncidentUpdate]

    var isActive: Bool { status.isActive }
}
