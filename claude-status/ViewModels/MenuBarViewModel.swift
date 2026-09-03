import AppKit
import Combine

@MainActor
final class MenuBarViewModel: ObservableObject {
    private let status: StatusViewModel
    private var cancellables = Set<AnyCancellable>()

    init(status: StatusViewModel) {
        self.status = status
        status.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var barColors: [NSColor] {
        let components = status.menuBarComponents
        let noData = status.connection == .offline && status.snapshot == nil
        guard !components.isEmpty else { return [.systemGray] }
        return components.map { noData ? .systemGray : StatusPresentation.nsColor(for: $0.status) }
    }

    var tooltip: String {
        guard let snapshot = status.snapshot else {
            return "Claude Status — \(status.connectionLabel)"
        }
        let lines = status.menuBarComponents.map { "\($0.name): \(StatusPresentation.label(for: $0.status))" }
        return ([snapshot.overall.description] + lines).joined(separator: "\n")
    }
}
