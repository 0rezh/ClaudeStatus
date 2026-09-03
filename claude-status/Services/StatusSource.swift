import Foundation

enum StatusSourceEvent: Sendable {
    case connection(ConnectionState)
    case snapshot(StatusSnapshot)
    case failure(String)
}

protocol StatusSource: Sendable {
    func events() -> AsyncStream<StatusSourceEvent>
}
