import Foundation
import SwiftUI

struct IncidentViewModel: Identifiable, Hashable {
    struct Update: Identifiable, Hashable {
        let id: String
        let statusLabel: String
        let dateText: String?
        let body: String
    }

    let id: String
    let title: String
    let impactLabel: String
    let impactColor: Color
    let updates: [Update]
    let link: URL?

    init(incident: Incident) {
        id = incident.id
        title = incident.name
        impactLabel = StatusPresentation.label(for: incident.impact)
        impactColor = StatusPresentation.color(for: incident.impact)
        updates = incident.updates.map { update in
            Update(
                id: update.id,
                statusLabel: StatusPresentation.label(for: update.status),
                dateText: ISODate.parse(update.displayAt)?.formatted(date: .abbreviated, time: .shortened),
                body: update.body
            )
        }
        link = incident.shortlink.flatMap(URL.init(string:))
    }
}
