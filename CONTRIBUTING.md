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
scripts/release.sh                       # ad-hoc signed → dist/claude-status-<version>.zip
gh release create v1.0 dist/claude-status-1.0.zip --title "v1.0" --generate-notes
```

With a paid Apple Developer account you can sign with a Developer ID and notarize, so users don't get the Gatekeeper prompt:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" scripts/release.sh
xcrun notarytool submit dist/claude-status-1.0.zip --keychain-profile notary --wait
xcrun stapler staple build/Build/Products/Release/claude-status.app
# stapling modifies the .app, so rebuild the zip before uploading it
ditto -c -k --keepParent build/Build/Products/Release/claude-status.app dist/claude-status-1.0.zip
spctl -a -vv -t exec build/Build/Products/Release/claude-status.app   # expect "Notarized Developer ID"
```

The `notary` keychain profile is created once with `xcrun notarytool store-credentials notary --apple-id <email> --team-id <TEAMID>` and an app-specific password.

Bump `MARKETING_VERSION` in the Xcode project before each release.

## Commits

Commit messages follow the [Angular convention](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit): `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`…
