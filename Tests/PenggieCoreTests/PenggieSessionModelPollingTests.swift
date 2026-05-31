import Testing
@testable import PenggieCore

@Suite
struct PenggieSessionModelPollingTests {
    @Test
    func ordinaryChatTranscriptSkipsExpensiveScreenModelRead() {
        let visibleText = """
        如果你愿意，我可以继续按你的具体目的对比：

        1. 旅游
        2. 留学
        › Ask Codex anything
        """

        #expect(PenggieTerminalScreenModelReadPolicy.requiresScreenModelJSON(
            visibleText: visibleText,
            screenText: visibleText,
            screenKind: .chat,
            nativeInteractionIsActive: false
        ) == false)
    }

    @Test
    func terminalOwnedResumePickerRequiresScreenModelRead() {
        let visibleText = """
        Resume a previous session
        Type to search
        Filter: [Cwd] All     Sort: [Updated] Created
        › 1h ago    对比一下伦敦和巴黎
        enter resume  esc exit
        """

        #expect(PenggieTerminalScreenModelReadPolicy.requiresScreenModelJSON(
            visibleText: visibleText,
            screenText: visibleText,
            screenKind: .resumePicker,
            nativeInteractionIsActive: false
        ))
    }

    @Test
    func terminalOwnedChoiceCuesRequireScreenModelRead() {
        let visibleText = """
        Approve command?
        › Allow once
          Deny
        ↑/↓ select · Enter accept · Esc cancel
        """

        #expect(PenggieTerminalScreenModelReadPolicy.requiresScreenModelJSON(
            visibleText: visibleText,
            screenText: visibleText,
            screenKind: .chat,
            nativeInteractionIsActive: false
        ))
    }

    @Test
    func nativeInteractionRequiresScreenModelReadForSlashProjection() {
        #expect(PenggieTerminalScreenModelReadPolicy.requiresScreenModelJSON(
            visibleText: "› /",
            screenText: "› /",
            screenKind: .chat,
            nativeInteractionIsActive: true
        ))
    }
}
