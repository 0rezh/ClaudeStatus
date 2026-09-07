# Contributing

## Build

Requires Xcode 26 or later. The deployment target is macOS 14.

```bash
xcodebuild -project claude-status.xcodeproj -scheme claude-status -configuration Release build
```

Or open `claude-status.xcodeproj` in Xcode and hit Run. The app is a menu bar agent (no Dock icon, no window).

## Architecture (MVVM)

```
claude-status/
├── App/            ClaudeStatusApp, AppDelegate  — composition root, builds and wires everything
├── Models/         ServiceStatus, ServiceComponent, Incident, StatusSnapshot, ConnectionState
│                   plain Codable value types + business rules (severity, isActive, activeIncidents)
├── Services/       StatuspageClient (HTTP + uptime HTML parsing)
│                   StatusSource protocol → PollingStatusSource (AsyncStream)
│                   PreferencesStore (UserDefaults), LaunchAtLoginService (SMAppService)
├── ViewModels/     StatusViewModel   — state of truth: snapshot, connection, settings, actions
│                   MenuBarViewModel  — bar colors + tooltip for the status item
│                   IncidentViewModel, ComponentRowViewModel — display-ready rows
│                   StatusPresentation — colors and labels for domain values
├── Views/          PopoverView, IncidentView, ComponentRowView, SettingsView (SwiftUI)
│                   MenuBar/StatusBarController (NSStatusItem + NSPopover), BarsRenderer
└── Support/        ISODate
```

Data flow: a `StatusSource` emits `StatusSourceEvent`s (snapshot / connection / failure) on an `AsyncStream`; `StatusViewModel` consumes them and publishes state with `@Published`; SwiftUI views observe it with `@ObservedObject`, and `StatusBarController` observes `MenuBarViewModel` through Combine. Dependencies are injected through protocols (`StatuspageClientProtocol`, `StatusSource`, `PreferencesStore`, `LaunchAtLoginService`) so view models can be tested with fakes.

## Development

```bash
# open the popover automatically 1.5 s after launch (handy for screenshots)
./build/claude-status.app/Contents/MacOS/claude-status --open-popover
```

## Release

```bash
scripts/release.sh                  # build, sign, notarize → dist/claude-status-<version>.zip
scripts/release.sh 1.1              # same, after bumping MARKETING_VERSION to 1.1 and committing
scripts/release.sh 1.1 --publish    # ... then tag v1.1, push, and create the GitHub release
```

The script builds a universal (Apple Silicon + Intel) Release app. If a "Developer ID Application"
identity is in the keychain it signs with it (hardened runtime, no `get-task-allow`), notarizes the zip,
staples the ticket and checks the result with Gatekeeper. Without one, the app is ad-hoc signed and
users must right-click > Open the first time.

One-time setup for notarization, with an app-specific password from appleid.apple.com:

```bash
xcrun notarytool store-credentials notary --apple-id <email> --team-id <TEAMID>
```

`--publish` requires a clean working tree, a logged-in `gh`, and no existing tag for that version.
To redo a release, delete it first: `gh release delete v1.1 --cleanup-tag`.

## Commits

Commit messages follow the [Angular convention](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit): `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`…
