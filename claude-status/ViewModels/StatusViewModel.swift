import Foundation
import Combine
import SwiftUI

@MainActor
final class StatusViewModel: ObservableObject {
    @Published private(set) var snapshot: StatusSnapshot?
    @Published private(set) var connection: ConnectionState = .connecting
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var lastError: String?

    @Published private(set) var hiddenComponentIDs: Set<String> {
        didSet { preferences.hiddenComponentIDs = hiddenComponentIDs }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != oldValue else { return }
            do { try launchAtLoginService.setEnabled(launchAtLogin) }
            catch {
                lastError = "Launch at login: \(error.localizedDescription)"
                launchAtLogin = launchAtLoginService.isEnabled
            }
        }
    }

    private let preferences: PreferencesStore
    private let source: StatusSource
    private let launchAtLoginService: LaunchAtLoginService
    private var runner: Task<Void, Never>?

    init(preferences: PreferencesStore,
         source: StatusSource,
         launchAtLoginService: LaunchAtLoginService) {
        self.preferences = preferences
        self.source = source
        self.launchAtLoginService = launchAtLoginService
        hiddenComponentIDs = preferences.hiddenComponentIDs
        launchAtLogin = launchAtLoginService.isEnabled
    }

    func start() {
        guard runner == nil else { return }
        let source = source
        runner = Task { [weak self] in
            for await event in source.events() {
                guard let self, !Task.isCancelled else { return }
                self.handle(event)
            }
        }
    }

    func restart() {
        runner?.cancel()
        runner = nil
        connection = .connecting
        start()
    }

    func refreshNow() { restart() }

    private func handle(_ event: StatusSourceEvent) {
        switch event {
        case .snapshot(let new):
            if snapshot != new { snapshot = new }
            lastUpdated = Date()
            lastError = nil
        case .connection(let state):
            connection = state
        case .failure(let message):
            lastError = message
        }
    }

    var components: [ServiceComponent] { snapshot?.components ?? [] }

    var menuBarComponents: [ServiceComponent] {
        components.filter { !hiddenComponentIDs.contains($0.id) }
    }

    func isShownInMenuBar(_ componentID: String) -> Bool {
        !hiddenComponentIDs.contains(componentID)
    }

    func setShownInMenuBar(_ componentID: String, _ shown: Bool) {
        if shown { hiddenComponentIDs.remove(componentID) } else { hiddenComponentIDs.insert(componentID) }
    }

    var overallTitle: String {
        snapshot?.overall.description ?? (connection == .offline ? "Unreachable" : "Loading…")
    }

    var overallColor: Color {
        StatusPresentation.color(for: snapshot?.overall.indicator ?? .unknown)
    }

    var connectionLabel: String { StatusPresentation.label(for: connection) }
    var connectionColor: Color { StatusPresentation.color(for: connection) }

    var connectionHelp: String {
        switch connection {
        case .polling: "Polling status.claude.com every 60 s"
        case .connecting: "Connecting…"
        case .offline: lastError ?? "Could not reach the status source"
        }
    }

    var incidentRows: [IncidentViewModel] {
        (snapshot?.activeIncidents ?? []).map(IncidentViewModel.init(incident:))
    }

    var componentRows: [ComponentRowViewModel] {
        components.map(ComponentRowViewModel.init(component:))
    }

    var emptyComponentsText: String {
        connection == .offline ? (lastError ?? "Unreachable") : "Loading…"
    }

    var lastUpdatedText: String? {
        lastUpdated.map { "Updated \($0.formatted(date: .omitted, time: .shortened))" }
    }

    var statusPageURL: URL {
        snapshot?.pageURL ?? StatuspageClient.defaultOrigin
    }
}
