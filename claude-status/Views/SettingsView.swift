import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: StatusViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings").font(.subheadline.weight(.semibold))
            Toggle("Launch at login", isOn: $viewModel.launchAtLogin)
                .toggleStyle(.checkbox)
            if let error = viewModel.lastError {
                Text(error).font(.caption2).foregroundStyle(.red)
            }
        }
    }
}
