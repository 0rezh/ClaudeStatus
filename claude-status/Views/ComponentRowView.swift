import SwiftUI

struct ComponentRowView: View {
    let row: ComponentRowViewModel
    @Binding var shown: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Toggle("", isOn: $shown)
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                Text(row.name)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                HStack(spacing: 5) {
                    Circle().fill(row.statusColor).frame(width: 7, height: 7)
                    Text(row.statusLabel)
                        .font(.caption)
                        .foregroundStyle(row.statusColor)
                }
            }
            if row.hasUptimeHistory {
                HStack(spacing: 8) {
                    UptimeStripView(days: row.days)
                    if let text = row.uptimeText {
                        Text(text)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 52, alignment: .trailing)
                    }
                }
                .padding(.leading, 24)
            }
        }
    }
}

struct UptimeStripView: View {
    let days: [ComponentRowViewModel.Day]

    var body: some View {
        HStack(spacing: 1) {
            ForEach(days) { day in
                RoundedRectangle(cornerRadius: 1)
                    .fill(day.color)
                    .frame(height: 8)
                    .help(day.tooltip)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
