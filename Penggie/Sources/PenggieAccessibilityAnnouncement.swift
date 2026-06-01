import Foundation

enum PenggieAccessibilityAnnouncementPriority: String, Equatable, Sendable {
    case polite
    case assertive
}

struct PenggieAccessibilityAnnouncement: Equatable, Sendable {
    let id: String
    let message: String
    let priority: PenggieAccessibilityAnnouncementPriority
}

enum PenggieAccessibilityAnnouncementEvent: String, CaseIterable, Equatable, Sendable {
    case checkingCodex
    case launching
    case ready
    case working
    case toolRunning
    case approvalRequired
    case permissionRequired
    case projectionDegraded
    case selectionSyncing
    case processExited
    case missingCodex
    case launchFailed

    var announcement: PenggieAccessibilityAnnouncement {
        PenggieAccessibilityAnnouncement(
            id: rawValue,
            message: message,
            priority: priority
        )
    }

    private var message: String {
        switch self {
        case .checkingCodex:
            return "Checking Codex."
        case .launching:
            return "Starting Codex."
        case .ready:
            return "Penggie is ready."
        case .working:
            return "Codex is working."
        case .toolRunning:
            return "Codex is running a tool."
        case .approvalRequired:
            return "Approval required."
        case .permissionRequired:
            return "Permission required."
        case .projectionDegraded:
            return "Reading projection is degraded. Terminal text is preserved."
        case .selectionSyncing:
            return "Selection is syncing with the terminal."
        case .processExited:
            return "Codex process exited."
        case .missingCodex:
            return "Codex CLI not found."
        case .launchFailed:
            return "Codex failed to launch."
        }
    }

    private var priority: PenggieAccessibilityAnnouncementPriority {
        switch self {
        case .approvalRequired, .permissionRequired, .processExited, .missingCodex, .launchFailed:
            return .assertive
        case .checkingCodex, .launching, .ready, .working, .toolRunning, .projectionDegraded, .selectionSyncing:
            return .polite
        }
    }
}
