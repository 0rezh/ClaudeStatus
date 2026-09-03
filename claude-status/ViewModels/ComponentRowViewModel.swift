import SwiftUI

struct ComponentRowViewModel: Identifiable, Hashable {
    struct Day: Identifiable, Hashable {
        let id: Int
        let color: Color
        let tooltip: String
    }

    let id: String
    let name: String
    let statusLabel: String
    let statusColor: Color
    let uptimeText: String?
    let days: [Day]

    var hasUptimeHistory: Bool { !days.isEmpty || uptimeText != nil }

    init(component: ServiceComponent) {
        id = component.id
        name = component.name
        statusLabel = StatusPresentation.label(for: component.status)
        statusColor = StatusPresentation.color(for: component.status)
        uptimeText = component.uptimePercent.map { String(format: "%.2f %%", $0) }
        days = component.days.enumerated().map { index, day in
            Day(id: index,
                color: StatusPresentation.color(for: day.status),
                tooltip: "\(day.date): \(StatusPresentation.label(for: day.status))")
        }
    }
}
