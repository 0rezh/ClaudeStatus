import Foundation

enum ConnectionState: Equatable, Sendable {
    case connecting
    case polling
    case offline
}
