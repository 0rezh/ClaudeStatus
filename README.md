# Claude Status

**Is Claude down?** Know at a glance, right from your Mac's menu bar.

Claude Status puts one small colored bar per Claude service next to your clock:

```
 ▍▍▍▍▍     green = all good · yellow = degraded · orange = partial outage · red = major outage
```

Click it and you get the full picture: what's broken, what Anthropic is saying about it, and how each service has been doing over the last 90 days.

## Why

When Claude starts erroring, the first question is always "is it me or is it them?". Instead of opening [status.claude.com](https://status.claude.com) every time, the answer is already in your menu bar, and you notice an incident the moment a bar changes color.

## Features

- **One bar per service**: claude.ai, Claude Console, Claude API, Claude Code, Claude Cowork, Claude for Government.
- **Pick what you care about**: only use Claude Code? Uncheck the rest and keep a single bar.
- **Incident details**: every active incident with its full timeline (investigating → identified → monitoring → resolved), exactly as posted by Anthropic, plus a link to the incident page.
- **90-day history**: a mini uptime graph and the uptime percentage for each service.
- **Refreshes every minute**: uses the same public status feed as the status page. No account, no API key, nothing to configure.
- **Lightweight**: a native Swift app, no Dock icon, no window, no dependencies. Optional launch at login.
- **Free and open source**: MIT licensed.

## Install

1. Download the latest `claude-status-x.y.zip` from the [Releases](../../releases) page.
2. Unzip it and drag `claude-status.app` into your `Applications` folder.
3. Open it. The bars appear in the menu bar.

**First launch:** the app isn't signed with an Apple Developer certificate yet, so macOS will refuse to open it the first time. Right-click the app → **Open** → **Open**. You only have to do this once. Or, from a terminal:

```bash
xattr -d com.apple.quarantine /Applications/claude-status.app
```

Requires macOS 14 Sonoma or later.

## Using it

- **Click the bars** to open the panel. Click anywhere else to close it.
- **Hover the bars** for a quick text summary of every service.
- **Checkboxes** next to each service choose which ones get a bar in the menu bar.
- **Gear icon** opens the settings (launch at login).
- **Compass icon** opens status.claude.com in your browser.
- **Refresh icon** forces an update right away.

## Colors

| Bar | Meaning |
| --- | --- |
| 🟢 green | Operational |
| 🟡 yellow | Degraded performance |
| 🟠 orange | Partial outage |
| 🔴 red | Major outage |
| 🔵 blue | Under maintenance |
| ⚪ gray | Status unknown or status page unreachable |

## Privacy

The app only talks to `status.claude.com`, the public status page. It sends nothing about you, stores nothing but your service selection, and has no analytics.

## Contributing

Bug reports and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for how to build the app and how the code is organized.

## License

[MIT](LICENSE)
