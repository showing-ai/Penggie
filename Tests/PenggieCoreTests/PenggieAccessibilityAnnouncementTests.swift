import Testing
@testable import PenggieCore

struct PenggieAccessibilityAnnouncementTests {
    @Test
    func dynamicAnnouncementEventsCoverProductGradeStateMatrix() {
        let requiredEvents: Set<PenggieAccessibilityAnnouncementEvent> = [
            .checkingCodex,
            .launching,
            .ready,
            .working,
            .toolRunning,
            .approvalRequired,
            .permissionRequired,
            .projectionDegraded,
            .selectionSyncing,
            .processExited,
            .missingCodex,
            .launchFailed
        ]

        #expect(Set(PenggieAccessibilityAnnouncementEvent.allCases) == requiredEvents)
    }

    @Test
    func announcementMessagesAreNonEmptyAndStable() {
        let messages = Dictionary(
            uniqueKeysWithValues: PenggieAccessibilityAnnouncementEvent.allCases.map { event in
                (event, event.announcement.message)
            }
        )

        #expect(messages[.checkingCodex] == "Checking Codex.")
        #expect(messages[.launching] == "Starting Codex.")
        #expect(messages[.ready] == "Penggie is ready.")
        #expect(messages[.working] == "Codex is working.")
        #expect(messages[.toolRunning] == "Codex is running a tool.")
        #expect(messages[.approvalRequired] == "Approval required.")
        #expect(messages[.permissionRequired] == "Permission required.")
        #expect(messages[.projectionDegraded] == "Reading projection is degraded. Terminal text is preserved.")
        #expect(messages[.selectionSyncing] == "Selection is syncing with the terminal.")
        #expect(messages[.processExited] == "Codex process exited.")
        #expect(messages[.missingCodex] == "Codex CLI not found.")
        #expect(messages[.launchFailed] == "Codex failed to launch.")
    }

    @Test
    func safetyAndRecoveryAnnouncementsAreAssertive() {
        for event in PenggieAccessibilityAnnouncementEvent.allCases {
            let priority = event.announcement.priority
            switch event {
            case .approvalRequired, .permissionRequired, .processExited, .missingCodex, .launchFailed:
                #expect(priority == .assertive)
            case .checkingCodex, .launching, .ready, .working, .toolRunning, .projectionDegraded, .selectionSyncing:
                #expect(priority == .polite)
            }
        }
    }
}
