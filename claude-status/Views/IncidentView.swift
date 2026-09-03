import SwiftUI

struct IncidentView: View {
    let incident: IncidentViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(incident.title)
                    .font(.callout.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Text(incident.impactLabel)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(incident.impactColor.opacity(0.2), in: Capsule())
            }
            ForEach(incident.updates) { update in
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(update.statusLabel).font(.caption.weight(.semibold))
                        if let date = update.dateText {
                            Text(date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(update.body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let link = incident.link {
                Link("View incident", destination: link).font(.caption)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}
