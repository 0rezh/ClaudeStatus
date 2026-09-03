import Foundation

final class PollingStatusSource: StatusSource {
    let client: StatuspageClientProtocol
    let interval: Duration
    let retryInterval: Duration
    let uptimeMaxAge: TimeInterval

    init(client: StatuspageClientProtocol,
         interval: Duration = .seconds(60),
         retryInterval: Duration = .seconds(20),
         uptimeMaxAge: TimeInterval = 600) {
        self.client = client
        self.interval = interval
        self.retryInterval = retryInterval
        self.uptimeMaxAge = uptimeMaxAge
    }

    func events() -> AsyncStream<StatusSourceEvent> {
        AsyncStream { continuation in
            let task = Task { await self.run(continuation) }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run(_ continuation: AsyncStream<StatusSourceEvent>.Continuation) async {
        var uptime: [String: UptimeInfo] = [:]
        var uptimeFetchedAt: Date?
        continuation.yield(.connection(.connecting))

        while !Task.isCancelled {
            let uptimeIsStale = uptimeFetchedAt.map { Date().timeIntervalSince($0) > uptimeMaxAge } ?? true
            if uptimeIsStale, let fresh = try? await client.fetchUptime(), !fresh.isEmpty {
                uptime = fresh
                uptimeFetchedAt = Date()
            }
            do {
                let summary = try await client.fetchSummary()
                guard !Task.isCancelled else { break }
                continuation.yield(.snapshot(StatusSnapshot(summary: summary, uptime: uptime)))
                continuation.yield(.connection(.polling))
                try? await Task.sleep(for: interval)
            } catch {
                guard !Task.isCancelled else { break }
                continuation.yield(.failure(error.localizedDescription))
                continuation.yield(.connection(.offline))
                try? await Task.sleep(for: retryInterval)
            }
        }
        continuation.finish()
    }
}
