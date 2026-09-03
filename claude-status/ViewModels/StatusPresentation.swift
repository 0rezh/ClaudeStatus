import SwiftUI
import AppKit

enum StatusPresentation {
    static func label(for status: ServiceStatus) -> String {
        switch status {
        case .operational: "Operational"
        case .degradedPerformance: "Degraded Performance"
        case .partialOutage: "Partial Outage"
        case .majorOutage: "Major Outage"
        case .underMaintenance: "Under Maintenance"
        case .unknown: "Unknown"
        }
    }

    static func nsColor(for status: ServiceStatus) -> NSColor {
        switch status {
        case .operational: .systemGreen
        case .degradedPerformance: .systemYellow
        case .partialOutage: .systemOrange
        case .majorOutage: .systemRed
        case .underMaintenance: .systemBlue
        case .unknown: .systemGray
        }
    }

    static func color(for status: ServiceStatus) -> Color {
        Color(nsColor: nsColor(for: status))
    }

    static func color(for indicator: OverallIndicator) -> Color {
        switch indicator {
        case .none: .green
        case .minor: .orange
        case .major, .critical: .red
        case .maintenance: .blue
        case .unknown: .gray
        }
    }

    static func color(for impact: IncidentImpact) -> Color {
        switch impact {
        case .none, .unknown: .gray
        case .minor: .yellow
        case .major: .orange
        case .critical: .red
        }
    }

    static func label(for impact: IncidentImpact) -> String {
        switch impact {
        case .none: "No impact"
        case .minor: "Minor"
        case .major: "Major"
        case .critical: "Critical"
        case .unknown: "Unknown"
        }
    }

    static func label(for status: IncidentStatus) -> String {
        switch status {
        case .investigating: "Investigating"
        case .identified: "Identified"
        case .monitoring: "Monitoring"
        case .resolved: "Resolved"
        case .postmortem: "Postmortem"
        case .unknown: "Update"
        }
    }

    static func label(for connection: ConnectionState) -> String {
        switch connection {
        case .connecting: "Connecting…"
        case .polling: "Polling"
        case .offline: "Offline"
        }
    }

    static func color(for connection: ConnectionState) -> Color {
        switch connection {
        case .polling: .blue
        case .connecting: .gray
        case .offline: .red
        }
    }
}
