import Foundation

enum OverallIndicator: String, StatuspageEnum {
    case none
    case minor
    case major
    case critical
    case maintenance
    case unknown
}

struct OverallStatus: Codable, Sendable, Hashable {
    let indicator: OverallIndicator
    let description: String
}

struct PageInfo: Codable, Sendable, Hashable {
    let name: String?
    let url: String?
    let updatedAt: String?
}

struct StatusSnapshot: Codable, Sendable, Hashable {
    let type: String?
    let page: PageInfo?
    let overall: OverallStatus
    let components: [ServiceComponent]
    let incidents: [Incident]
    let generatedAt: String?

    var activeIncidents: [Incident] { incidents.filter(\.isActive) }

    var pageURL: URL? { page?.url.flatMap(URL.init(string:)) }
}
