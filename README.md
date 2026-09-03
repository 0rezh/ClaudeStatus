# Claude Status

A tiny macOS menu bar app that shows the status of Claude services as colored bars.

```
| | | | |      one bar per service, green / yellow / orange / red
```

- **One bar per service** (claude.ai, Console, API, Claude Code, Cowork, Claude for Government). Uncheck the ones you don't care about, e.g. keep only Claude Code.
- **Click the bars** to open a popover with the active incidents (with every update), each service's status, its 90-day uptime, and settings.
- **No account, no API key**: everything comes from the public Statuspage API and page of [status.claude.com](https://status.claude.com), polled every 60 s.

## Install

Download the latest `claude-status-x.y.zip` from the [Releases](../../releases) page, unzip, and drag `claude-status.app` to `/Applications`.

The builds are ad-hoc signed (no Apple Developer ID), so the first launch is blocked by Gatekeeper: right-click the app → **Open** → **Open**, once. Or from a terminal:

```bash
xattr -d com.apple.quarantine /Applications/claude-status.app
```

Requires macOS 14 or later.

## Build

Requires Xcode 26 or later. The deployment target is macOS 14.

```bash
xcodebuild -project claude-status.xcodeproj -scheme claude-status -configuration Release build
```

Or open `claude-status.xcodeproj` in Xcode and hit Run. The app is a menu bar agent (no Dock icon, no window).

## Architecture (MVVM)

The app follows Model-View-ViewModel with a thin service layer. Views never talk to the network or to `UserDefaults`; view models never draw.

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
```

Bump `MARKETING_VERSION` in the Xcode project before each release.

## Colors

| Status | Color |
| --- | --- |
| Operational | green |
| Degraded performance | yellow |
| Partial outage | orange |
| Major outage | red |
| Under maintenance | blue |
| Unknown / unreachable | gray |

## Development

```bash
# open the popover automatically 1.5 s after launch (handy for screenshots)
./build/claude-status.app/Contents/MacOS/claude-status --open-popover
```

## License

MIT
