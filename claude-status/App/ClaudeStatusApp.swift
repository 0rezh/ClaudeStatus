import SwiftUI
import AppKit

@main
struct ClaudeStatusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusViewModel: StatusViewModel?
    private var statusBar: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let statusViewModel = StatusViewModel(
            preferences: UserDefaultsPreferencesStore(),
            source: PollingStatusSource(client: StatuspageClient()),
            launchAtLoginService: SMAppLaunchAtLoginService()
        )
        let menuBarViewModel = MenuBarViewModel(status: statusViewModel)
        let statusBar = StatusBarController(
            viewModel: menuBarViewModel,
            popoverContent: PopoverView(viewModel: statusViewModel)
        )
        self.statusViewModel = statusViewModel
        self.statusBar = statusBar
        statusViewModel.start()

        if CommandLine.arguments.contains("--open-popover") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.statusBar?.togglePopover(nil)
            }
        }
    }
}
