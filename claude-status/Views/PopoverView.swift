import SwiftUI

struct PopoverView: View {
    @ObservedObject var viewModel: StatusViewModel
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    incidentsSection
                    Divider()
                    componentsSection
                    if showSettings {
                        Divider()
                        SettingsView(viewModel: viewModel)
                    }
                }
                .padding(14)
            }
            .frame(maxHeight: 560)
            Divider()
            footer
        }
        .frame(width: 380)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.overallColor)
                .frame(width: 10, height: 10)
            Text(viewModel.overallTitle)
                .font(.headline)
            Spacer()
            HStack(spacing: 4) {
                Circle().fill(viewModel.connectionColor).frame(width: 6, height: 6)
                Text(viewModel.connectionLabel)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .help(viewModel.connectionHelp)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var incidentsSection: some View {
        let incidents = viewModel.incidentRows
        if incidents.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text("No active incidents").foregroundStyle(.secondary)
            }
            .font(.callout)
        } else {
            ForEach(incidents) { incident in
                IncidentView(incident: incident)
            }
        }
    }

    private var componentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Services").font(.subheadline.weight(.semibold))
                Spacer()
                Text("Checked = shown in menu bar")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            let rows = viewModel.componentRows
            if rows.isEmpty {
                Text(viewModel.emptyComponentsText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            ForEach(rows) { row in
                ComponentRowView(
                    row: row,
                    shown: Binding(
                        get: { viewModel.isShownInMenuBar(row.id) },
                        set: { viewModel.setShownInMenuBar(row.id, $0) }
                    )
                )
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            if let text = viewModel.lastUpdatedText {
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button { viewModel.refreshNow() } label: { Image(systemName: "arrow.clockwise") }
                .buttonStyle(.borderless)
                .help("Refresh now")
            Spacer()
            Link(destination: viewModel.statusPageURL) {
                Image(systemName: "safari")
            }
            .help("Open status.claude.com")
            Button { showSettings.toggle() } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("Settings")
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.borderless)
                .keyboardShortcut("q")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
