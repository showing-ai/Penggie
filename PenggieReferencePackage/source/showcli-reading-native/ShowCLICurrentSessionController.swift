#if os(macOS)
import AppKit
import Combine
import GhosttyKit

enum ShowCLIActiveMode: String {
    case terminal
    case reading

    init?(keyboardEvent event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.contains(.command),
              !flags.contains(.control),
              !flags.contains(.option),
              !flags.contains(.shift) else { return nil }

        switch event.charactersIgnoringModifiers {
        case "1":
            self = .terminal
        case "2":
            self = .reading
        default:
            return nil
        }
    }
}

enum ShowCLILaunchSurface {
    case picker
    case session
}

enum ShowCLIAgentPreset: String, CaseIterable, Identifiable {
    case codex
    case claude
    case aider
    case shell

    var id: String { rawValue }

    var title: String {
        switch self {
        case .codex:
            return "Codex CLI"
        case .claude:
            return "Claude Code"
        case .aider:
            return "Aider"
        case .shell:
            return "Open Shell"
        }
    }

    var subtitle: String {
        switch self {
        case .codex:
            return "Launch your local Codex CLI in Reading mode."
        case .claude:
            return "Launch your local Claude Code CLI in Reading mode."
        case .aider:
            return "Launch your local Aider CLI in Reading mode."
        case .shell:
            return "Use ShowCLI as a native terminal."
        }
    }

    var command: String? {
        switch self {
        case .codex:
            return "codex"
        case .claude:
            return "claude"
        case .aider:
            return "aider"
        case .shell:
            return nil
        }
    }

    var systemImageName: String {
        switch self {
        case .codex:
            return "sparkles"
        case .claude:
            return "hexagon"
        case .aider:
            return "hammer"
        case .shell:
            return "terminal"
        }
    }

    var isShellFallback: Bool {
        self == .shell
    }
}

extension Notification.Name {
    static let showCLIActiveModeDidChange = Notification.Name("com.thinkbig.showcli.activeModeDidChange")
}

struct ShowCLIComposerSubmission: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let submittedAt: Date
}

enum ShowCLIReadingBlockKind: String {
    case input
    case output
}

struct ShowCLIReadingBlock: Identifiable, Equatable {
    var id: UUID
    let kind: ShowCLIReadingBlockKind
    var text: String
    var displayText: String
    let createdAt: Date
    var updatedAt: Date
    var variant: ShowCLITranscriptVariant
    var confidence: ShowCLITranscriptConfidence
    var transcriptFeatures: ShowCLITranscriptFeatures
    var isLiveProjection: Bool
    var composerSubmissionID: UUID?

    init(
        id: UUID = UUID(),
        kind: ShowCLIReadingBlockKind,
        text: String,
        displayText: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        variant: ShowCLITranscriptVariant? = nil,
        confidence: ShowCLITranscriptConfidence = .medium,
        transcriptFeatures: ShowCLITranscriptFeatures? = nil,
        isLiveProjection: Bool = false,
        composerSubmissionID: UUID? = nil
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.displayText = displayText ?? text
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.variant = variant ?? (kind == .input ? .prompt : .unknown)
        self.confidence = confidence
        self.transcriptFeatures = transcriptFeatures ?? .init(
            marker: .none,
            indentLevel: 0,
            dividerBefore: false,
            dividerAfter: false,
            wrapDetected: false,
            hintIDs: [],
            lineCount: max(1, text.components(separatedBy: .newlines).count),
            containsBlankRows: text.components(separatedBy: .newlines).contains { $0.isEmpty }
        )
        self.isLiveProjection = isLiveProjection
        self.composerSubmissionID = composerSubmissionID
    }
}

struct ShowCLISurfaceStatus: Equatable {
    var ttyName: String?
    var foregroundPID: Int?
    var terminalColumns: Int?
    var terminalRows: Int?
    var widthPixels: Int?
    var heightPixels: Int?
    var cellWidthPixels: Int?
    var cellHeightPixels: Int?
    var processExited = false
    var childExitCode: Int?
    var childRuntimeMilliseconds: Int?
    var childExitLevel: String?
}

enum ShowCLINativeInteractionPhase: Equatable {
    case inactive
    case editing
    case resolving
    case continuation
    case cancelling

    var isActive: Bool {
        self != .inactive
    }

    var ownsComposerInput: Bool {
        switch self {
        case .editing, .continuation:
            return true
        case .inactive, .resolving, .cancelling:
            return false
        }
    }

    var acceptsInput: Bool {
        switch self {
        case .editing, .continuation:
            return true
        case .inactive, .resolving, .cancelling:
            return false
        }
    }

    var capturesTextInput: Bool {
        switch self {
        case .editing, .continuation:
            return true
        case .inactive, .resolving, .cancelling:
            return false
        }
    }
}

enum ShowCLINativeInteractionOrigin: Equatable {
    case explicit
    case prefix(String)
    case paste
}

enum ShowCLINativeInteractionTiming {
    static let editingAnchorLossGraceInterval: TimeInterval = 0.45
    static let resolvingSettleInterval: TimeInterval = 0.35
    static let refreshBurstDelays: [TimeInterval] = [
        0.016,
        0.050,
        0.100,
        0.180,
        0.300,
        0.450,
    ]
}

enum ShowCLIReadingProjectionModel {
    static func blocks(
        from projection: String,
        terminalColumns: Int?,
        previousBlocks: [ShowCLIReadingBlock] = [],
        composerSubmissions: [ShowCLIComposerSubmission] = [],
        consumedComposerSubmissionIDs: Set<UUID> = [],
        createdAt: Date = Date()
    ) -> [ShowCLIReadingBlock] {
        var blocks = ShowCLITranscriptBlockizer.blockizeOutput(
            projection,
            terminalColumns: terminalColumns,
            createdAt: createdAt
        )
        blocks = promoteComposerOwnedPromptBlocks(
            blocks,
            previousBlocks: previousBlocks,
            composerSubmissions: composerSubmissions,
            consumedComposerSubmissionIDs: consumedComposerSubmissionIDs
        )

        guard !blocks.isEmpty, !previousBlocks.isEmpty else {
            return blocks
        }

        let previousIDs = stableIDMap(for: previousBlocks)
        var occurrenceCounts: [String: Int] = [:]

        for index in blocks.indices {
            let base = stableIdentityBase(for: blocks[index])
            let occurrence = (occurrenceCounts[base] ?? 0) + 1
            occurrenceCounts[base] = occurrence

            if let stableID = previousIDs[stableIdentityKey(base: base, occurrence: occurrence)] {
                blocks[index].id = stableID
            }
        }

        return blocks
    }

    static func rawText(from blocks: [ShowCLIReadingBlock]) -> String {
        blocks.map(\.text).joined(separator: "\n")
    }

    private static func stableIDMap(for blocks: [ShowCLIReadingBlock]) -> [String: UUID] {
        var occurrenceCounts: [String: Int] = [:]
        var output: [String: UUID] = [:]

        for block in blocks {
            let base = stableIdentityBase(for: block)
            let occurrence = (occurrenceCounts[base] ?? 0) + 1
            occurrenceCounts[base] = occurrence
            output[stableIdentityKey(base: base, occurrence: occurrence)] = block.id
        }

        return output
    }

    private static func stableIdentityBase(for block: ShowCLIReadingBlock) -> String {
        [
            block.kind.rawValue,
            block.variant.rawValue,
            block.text,
            block.composerSubmissionID?.uuidString ?? ""
        ].joined(separator: "\u{1F}")
    }

    private static func stableIdentityKey(base: String, occurrence: Int) -> String {
        "\(base)\u{1E}\(occurrence)"
    }

    private static func promoteComposerOwnedPromptBlocks(
        _ blocks: [ShowCLIReadingBlock],
        previousBlocks: [ShowCLIReadingBlock],
        composerSubmissions: [ShowCLIComposerSubmission],
        consumedComposerSubmissionIDs: Set<UUID>
    ) -> [ShowCLIReadingBlock] {
        guard !composerSubmissions.isEmpty else { return blocks }

        var consumedSubmissionIDs = consumedComposerSubmissionIDs
        var previousPromotions = previousComposerPromotionsByRawText(previousBlocks)

        return blocks.map { block in
            guard block.kind == .output,
                  block.variant == .prompt else {
                return block
            }

            if var existingPromotions = previousPromotions[block.text],
               !existingPromotions.isEmpty {
                let previous = existingPromotions.removeFirst()
                previousPromotions[block.text] = existingPromotions

                if let composerSubmissionID = previous.composerSubmissionID {
                    consumedSubmissionIDs.insert(composerSubmissionID)
                }

                return composerPromptBlock(
                    from: block,
                    displayText: previous.displayText,
                    createdAt: previous.createdAt,
                    composerSubmissionID: previous.composerSubmissionID
                )
            }

            guard let matchIndex = matchingComposerSubmissionIndex(
                    for: block,
                    in: composerSubmissions,
                    consumedSubmissionIDs: consumedSubmissionIDs
            ) else {
                return block
            }

            let submission = composerSubmissions[matchIndex]
            consumedSubmissionIDs.insert(submission.id)

            return composerPromptBlock(
                from: block,
                displayText: submission.text,
                createdAt: submission.submittedAt,
                composerSubmissionID: submission.id
            )
        }
    }

    private static func composerPromptBlock(
        from terminalBlock: ShowCLIReadingBlock,
        displayText: String,
        createdAt: Date,
        composerSubmissionID: UUID?
    ) -> ShowCLIReadingBlock {
        ShowCLIReadingBlock(
            id: terminalBlock.id,
            kind: .input,
            text: terminalBlock.text,
            displayText: displayText,
            createdAt: createdAt,
            updatedAt: terminalBlock.updatedAt,
            variant: .prompt,
            confidence: .high,
            transcriptFeatures: terminalBlock.transcriptFeatures,
            isLiveProjection: terminalBlock.isLiveProjection,
            composerSubmissionID: composerSubmissionID
        )
    }

    private static func previousComposerPromotionsByRawText(
        _ blocks: [ShowCLIReadingBlock]
    ) -> [String: [ShowCLIReadingBlock]] {
        blocks.reduce(into: [:]) { output, block in
            guard block.kind == .input,
                  block.variant == .prompt,
                  block.composerSubmissionID != nil else { return }

            output[block.text, default: []].append(block)
        }
    }

    private static func matchingComposerSubmissionIndex(
        for block: ShowCLIReadingBlock,
        in submissions: [ShowCLIComposerSubmission],
        consumedSubmissionIDs: Set<UUID>
    ) -> Int? {
        let promptText = normalizedPromptText(terminalPromptText(for: block))
        guard !promptText.isEmpty else { return nil }

        return submissions.indices.first { index in
            !consumedSubmissionIDs.contains(submissions[index].id) &&
                normalizedPromptText(submissions[index].text) == promptText
        }
    }

    private static func terminalPromptText(for block: ShowCLIReadingBlock) -> String {
        block.displayText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
    }

    private static func normalizedPromptText(_ text: String) -> String {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}

@MainActor
final class ShowCLICurrentSessionController: ObservableObject {
    @Published private(set) var activeMode: ShowCLIActiveMode = .terminal
    @Published private(set) var launchSurface: ShowCLILaunchSurface = .picker
    @Published private(set) var selectedAgentPreset: ShowCLIAgentPreset?
    @Published private(set) var agentAvailability: [ShowCLIAgentPreset: Bool] = [:]
    @Published private(set) var isCheckingAgentAvailability = false
    @Published private(set) var nativeInteractionPhase: ShowCLINativeInteractionPhase = .inactive
    @Published private(set) var nativeInteractionOrigin: ShowCLINativeInteractionOrigin?
    @Published private(set) var nativeInteractionDisplayText = ""
    @Published private(set) var nativeInteractionMinimumScreenLineIndex: Int?
    @Published private(set) var capturedText = ""
    @Published private(set) var capturedVTText = ""
    @Published private(set) var capturedScreenSnapshot: ShowCLITerminalScreenSnapshot?
    @Published private(set) var nativeInteractionScreenSnapshot: ShowCLITerminalScreenSnapshot?
    @Published private(set) var composerSubmissions: [ShowCLIComposerSubmission] = []
    @Published private(set) var readingBlocks: [ShowCLIReadingBlock] = []
    @Published private(set) var surfaceStatus = ShowCLISurfaceStatus()

    private weak var surfaceView: Ghostty.SurfaceView?
    private var consumedComposerSubmissionIDs = Set<UUID>()
    private var surfaceCancellables = Set<AnyCancellable>()
    private var surfaceObservers: [NSObjectProtocol] = []
    private var projectionRefreshTask: Task<Void, Never>?
    private var projectionRefreshBurstTask: Task<Void, Never>?
    private var nativeInteractionRefreshBurstTask: Task<Void, Never>?
    private var nativeInteractionResolvingBeganAt: Date?
    private var nativeInteractionLastInputAt: Date?
    private var nativeInteractionBaselineScreenSnapshot: ShowCLITerminalScreenSnapshot?
    private var nativeInteractionPreResolvingScreenSnapshot: ShowCLITerminalScreenSnapshot?
    private var researchRunner: ShowCLIResearchRunner?

    var hasCurrentSurface: Bool {
        surfaceView?.surfaceModel != nil
    }

    var nativeInteractionOwnsInput: Bool {
        nativeInteractionPhase.ownsComposerInput
    }

    var nativeInteractionIsActive: Bool {
        nativeInteractionPhase.isActive
    }

    var nativeInteractionPresentationRows: [ShowCLINativeInteractionLine] {
        ShowCLINativeInteractionPresentation.rows(
            from: nativeInteractionScreenSnapshot,
            phase: nativeInteractionPhase,
            currentInput: nativeInteractionDisplayText,
            minimumScreenLineIndex: nativeInteractionMinimumScreenLineIndex,
            excludingRowsUnchangedFrom: nativeInteractionBaselineScreenSnapshot
        )
    }

    var showsAgentPicker: Bool {
        launchSurface == .picker
    }

    var canUseCodexDollarCommand: Bool {
        selectedAgentPreset == .codex
    }

    var visibleText: String {
        capturedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func updateSurface(_ surfaceView: Ghostty.SurfaceView?) {
        guard self.surfaceView !== surfaceView else { return }

        self.surfaceView = surfaceView
        endNativeInteraction()
        composerSubmissions.removeAll()
        consumedComposerSubmissionIDs.removeAll()
        readingBlocks.removeAll()
        capturedText = ""
        capturedVTText = ""
        capturedScreenSnapshot = nil
        nativeInteractionScreenSnapshot = nil
        surfaceStatus = currentSurfaceStatus()
        observeCurrentSurface()
        refreshProjection()
        startResearchRunnerIfConfigured()
    }

    func refreshAgentAvailability() {
        guard !isCheckingAgentAvailability else { return }

        isCheckingAgentAvailability = true
        let presets = ShowCLIAgentPreset.allCases.filter { !$0.isShellFallback }

        Task.detached(priority: .userInitiated) {
            var availability: [ShowCLIAgentPreset: Bool] = [.shell: true]
            for preset in presets {
                availability[preset] = Self.commandExistsInLoginShell(preset.command)
            }

            let checkedAvailability = availability
            await MainActor.run {
                self.agentAvailability = checkedAvailability
                self.isCheckingAgentAvailability = false
            }
        }
    }

    func isPresetAvailable(_ preset: ShowCLIAgentPreset) -> Bool {
        if preset.isShellFallback {
            return true
        }

        return agentAvailability[preset] == true
    }

    @discardableResult
    func startPreset(_ preset: ShowCLIAgentPreset) -> Bool {
        if preset.isShellFallback {
            launchSurface = .session
            selectedAgentPreset = .shell
            switchMode(to: .terminal)
            return true
        }

        guard isPresetAvailable(preset), let command = preset.command else {
            return false
        }

        launchSurface = .session
        selectedAgentPreset = preset
        switchMode(to: .reading)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            self.clearCurrentPTYInputLine()
            self.sendPTYText(command)
            self.sendPTYEnter()
            self.refreshProjection()
        }

        return true
    }

    func switchMode(to mode: ShowCLIActiveMode) {
        activeMode = mode
        if mode == .terminal {
            endNativeInteraction()
        }

        if mode == .reading {
            refreshProjection()
            observeCurrentSurface()
        } else {
            stopProjectionObservation()
        }
    }

    func switchMode(from notification: Notification) {
        if let mode = notification.object as? ShowCLIActiveMode {
            switchMode(to: mode)
            return
        }

        guard let rawValue = notification.object as? String,
              let mode = ShowCLIActiveMode(rawValue: rawValue) else { return }

        switchMode(to: mode)
    }

    func refreshProjection() {
        let latestProjection = surfaceView?.readScreenContents() ?? ""
        let latestVTProjection = surfaceView?.readScreenContentsVT() ?? ""
        let latestScreenSnapshot = ShowCLITerminalScreenSnapshot(
            json: surfaceView?.readScreenModelJSON() ?? ""
        )
        surfaceStatus = currentSurfaceStatus()

        let projectionChanged = latestProjection != capturedText
        let vtProjectionChanged = latestVTProjection != capturedVTText
        let screenSnapshotChanged = latestScreenSnapshot != capturedScreenSnapshot
        guard projectionChanged || vtProjectionChanged || screenSnapshotChanged else {
            reconcileNativeInteractionAfterScreenRefresh()
            return
        }

        capturedVTText = latestVTProjection
        capturedScreenSnapshot = latestScreenSnapshot
        reconcileNativeInteractionAfterScreenRefresh()
        guard projectionChanged else { return }

        let latestBlocks = ShowCLIReadingProjectionModel.blocks(
            from: latestProjection,
            terminalColumns: surfaceStatus.terminalColumns,
            previousBlocks: readingBlocks,
            composerSubmissions: composerSubmissions,
            consumedComposerSubmissionIDs: consumedComposerSubmissionIDs
        )
        consumedComposerSubmissionIDs.formUnion(
            latestBlocks.compactMap(\.composerSubmissionID)
        )
        readingBlocks = latestBlocks
        capturedText = latestProjection
    }

    func refreshNativeInteractionSnapshot() {
        guard activeMode == .reading else { return }

        let latestScreenModelJSON = surfaceView?.readScreenModelJSON() ?? ""
        dumpNativeInteractionScreenModelIfConfigured(latestScreenModelJSON)
        let latestScreenSnapshot = ShowCLITerminalScreenSnapshot(json: latestScreenModelJSON)
        surfaceStatus = currentSurfaceStatus()

        let screenSnapshotChanged = latestScreenSnapshot != nativeInteractionScreenSnapshot
        guard screenSnapshotChanged else {
            reconcileNativeInteractionAfterScreenRefresh()
            return
        }

        nativeInteractionScreenSnapshot = latestScreenSnapshot
        reconcileNativeInteractionAfterScreenRefresh()
    }

    private func reconcileNativeInteractionAfterScreenRefresh() {
        guard activeMode == .reading else { return }

        switch nativeInteractionPhase {
        case .inactive, .cancelling:
            return
        case .editing:
            if nativeInteractionDisplayText.isEmpty {
                endNativeInteraction()
                return
            }

            if let anchorScreenLineIndex = ShowCLINativeInteractionScope.inputAnchorScreenLineIndex(
                in: nativeInteractionScreenSnapshot,
                currentInput: nativeInteractionDisplayText
            ) {
                nativeInteractionMinimumScreenLineIndex = anchorScreenLineIndex
                return
            }

            if let lastInputAt = nativeInteractionLastInputAt,
               Date().timeIntervalSince(lastInputAt) >= ShowCLINativeInteractionTiming.editingAnchorLossGraceInterval,
               ShowCLINativeInteractionScope.rows(
                   from: nativeInteractionScreenSnapshot,
                   currentInput: nativeInteractionDisplayText,
                   excludingRowsUnchangedFrom: nativeInteractionBaselineScreenSnapshot
               ).isEmpty {
                if case .prefix = nativeInteractionOrigin,
                   ShowCLIComposerNativeTrigger.prefix(
                       for: nativeInteractionDisplayText,
                       canUseCodexDollarCommand: canUseCodexDollarCommand
                   ) != nil {
                    return
                }

                endNativeInteraction()
                scheduleProjectionRefresh()
            }
        case .resolving:
            if let beganAt = nativeInteractionResolvingBeganAt,
               Date().timeIntervalSince(beganAt) < ShowCLINativeInteractionTiming.resolvingSettleInterval {
                return
            }

            if ShowCLINativeInteractionScope.hasActiveContinuation(
                in: nativeInteractionScreenSnapshot,
                minimumScreenLineIndex: nativeInteractionMinimumScreenLineIndex,
                excludingRowsUnchangedFrom: nativeInteractionPreResolvingScreenSnapshot
            ) {
                nativeInteractionPhase = .continuation
                nativeInteractionResolvingBeganAt = nil
                nativeInteractionPreResolvingScreenSnapshot = nil
                return
            }

            endNativeInteraction()
            scheduleProjectionRefresh()
        case .continuation:
            guard ShowCLINativeInteractionScope.hasActiveContinuation(
                in: nativeInteractionScreenSnapshot,
                minimumScreenLineIndex: nativeInteractionMinimumScreenLineIndex
            ) else {
                endNativeInteraction()
                scheduleProjectionRefresh()
                return
            }
        }
    }

    private func dumpNativeInteractionScreenModelIfConfigured(_ json: String) {
        guard !json.isEmpty,
              let path = ProcessInfo.processInfo.environment["SHOWCLI_DEBUG_NATIVE_INTERACTION_SCREEN_MODEL_PATH"] else {
            return
        }

        do {
            try json.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            // Diagnostic-only path; keep production behavior unchanged.
        }
    }

    func matchCount(for query: String) -> Int {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return 0 }

        let haystack = visibleText
        var count = 0
        var searchRange = haystack.startIndex..<haystack.endIndex
        while let range = haystack.range(of: needle, options: [.caseInsensitive], range: searchRange) {
            count += 1
            searchRange = range.upperBound..<haystack.endIndex
        }
        return count
    }

    func copyCurrentProjection() {
        let text = visibleText
        guard !text.isEmpty else { return }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func canSubmitComposer(_ text: String) -> Bool {
        hasCurrentSurface &&
            !nativeInteractionIsActive &&
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @discardableResult
    func submitComposer(_ text: String) -> Bool {
        let submittedText = text
        guard canSubmitComposer(submittedText),
              let surfaceView,
              let surface = surfaceView.surfaceModel else { return false }

        composerSubmissions.append(.init(text: submittedText, submittedAt: Date()))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self, weak surfaceView] in
            surface.sendText(submittedText)
            surface.sendKeyEvent(.init(key: .enter, action: .press, text: "\r", unshiftedCodepoint: 13))
            surface.sendKeyEvent(.init(key: .enter, action: .release, text: "\r", unshiftedCodepoint: 13))

            guard let self, surfaceView != nil else { return }
            self.refreshProjection()
        }

        return true
    }

    @discardableResult
    func triggerAgentPrefix(_ prefix: String) -> Bool {
        guard let validatedPrefix = ShowCLIComposerNativeTrigger.prefix(
            for: prefix,
            canUseCodexDollarCommand: canUseCodexDollarCommand
        ) else { return false }

        return beginNativeInteraction(initialText: prefix, origin: .prefix(validatedPrefix))
    }

    func endPTYInteraction() {
        endNativeInteraction()
    }

    @discardableResult
    func beginNativeInteraction(
        initialText: String = "",
        origin: ShowCLINativeInteractionOrigin = .explicit
    ) -> Bool {
        guard hasCurrentSurface,
              let validatedPrefix = ShowCLIComposerNativeTrigger.prefix(
                  for: initialText,
                  canUseCodexDollarCommand: canUseCodexDollarCommand
              ),
              origin == .prefix(validatedPrefix) else { return false }

        nativeInteractionPhase = .editing
        nativeInteractionOrigin = origin
        nativeInteractionResolvingBeganAt = nil
        nativeInteractionLastInputAt = Date()
        nativeInteractionBaselineScreenSnapshot = readCurrentScreenSnapshot()
        nativeInteractionPreResolvingScreenSnapshot = nil
        nativeInteractionMinimumScreenLineIndex = nil
        nativeInteractionScreenSnapshot = nil
        if nativeInteractionDisplayText.isEmpty == false && initialText.isEmpty == false {
            nativeInteractionDisplayText = ""
        }

        nativeInteractionDisplayText = initialText
        let sent = sendPTYText(initialText, nativeInteractionOnly: true)
        if !sent {
            endNativeInteraction()
        }

        return sent
    }

    func endNativeInteraction() {
        nativeInteractionPhase = .inactive
        nativeInteractionOrigin = nil
        nativeInteractionDisplayText = ""
        nativeInteractionResolvingBeganAt = nil
        nativeInteractionLastInputAt = nil
        nativeInteractionBaselineScreenSnapshot = nil
        nativeInteractionPreResolvingScreenSnapshot = nil
        nativeInteractionMinimumScreenLineIndex = nil
        nativeInteractionScreenSnapshot = nil
        nativeInteractionRefreshBurstTask?.cancel()
        nativeInteractionRefreshBurstTask = nil
    }

    @discardableResult
    func cancelNativeInteraction() -> Bool {
        guard nativeInteractionPhase.acceptsInput else { return false }

        nativeInteractionPhase = .cancelling
        sendPTYKey(.escape)
        endNativeInteraction()
        return true
    }

    @discardableResult
    func sendNativeInteractionText(_ text: String) -> Bool {
        guard nativeInteractionPhase.acceptsInput, !text.isEmpty else { return false }

        nativeInteractionDisplayText += text
        let sent = sendPTYText(text, nativeInteractionOnly: true)
        if sent {
            nativeInteractionLastInputAt = Date()
        } else {
            nativeInteractionDisplayText.removeLast(text.count)
        }
        return sent
    }

    @discardableResult
    func sendNativeInteractionPaste(_ text: String) -> Bool {
        guard nativeInteractionPhase.acceptsInput, !text.isEmpty else { return false }
        return sendNativeInteractionText(text)
    }

    @discardableResult
    func sendNativeInteractionEnter() -> Bool {
        guard nativeInteractionPhase.acceptsInput else { return false }

        let preResolvingSnapshot = latestNativeInteractionScreenSnapshot()
        sendPTYEnter()
        transitionNativeInteractionAfterEnter(preResolvingSnapshot: preResolvingSnapshot)
        return true
    }

    private func transitionNativeInteractionAfterEnter(
        preResolvingSnapshot: ShowCLITerminalScreenSnapshot?
    ) {
        switch nativeInteractionPhase {
        case .editing, .continuation:
            nativeInteractionPhase = .resolving
            nativeInteractionDisplayText = ""
            nativeInteractionScreenSnapshot = nil
            nativeInteractionResolvingBeganAt = Date()
            nativeInteractionLastInputAt = nil
            nativeInteractionBaselineScreenSnapshot = nil
            nativeInteractionPreResolvingScreenSnapshot = preResolvingSnapshot
            scheduleNativeInteractionRefreshBurst()
        case .resolving, .cancelling, .inactive:
            break
        }
    }

    @discardableResult
    func sendNativeInteractionKey(_ key: Ghostty.Input.Key) -> Bool {
        guard nativeInteractionPhase.acceptsInput else { return false }

        switch key {
        case .enter, .numpadEnter:
            return sendNativeInteractionEnter()
        case .escape:
            return cancelNativeInteraction()
        case .tab:
            nativeInteractionLastInputAt = Date()
            sendPTYKey(.tab, text: "\t", unshiftedCodepoint: 9, nativeInteractionOnly: true)
        case .backspace:
            nativeInteractionLastInputAt = Date()
            sendPTYKey(.backspace, nativeInteractionOnly: true)
            removeLastNativeInteractionCharacter()
        case .delete:
            nativeInteractionLastInputAt = Date()
            sendPTYKey(.delete, nativeInteractionOnly: true)
        default:
            nativeInteractionLastInputAt = Date()
            sendPTYKey(key, nativeInteractionOnly: true)
        }

        return true
    }

    @discardableResult
    func sendNativeInteractionEvent(_ event: NSEvent) -> Bool {
        guard nativeInteractionPhase.acceptsInput, hasCurrentSurface else { return false }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard !flags.contains(.command),
              !flags.contains(.control),
              !flags.contains(.option),
              let key = Ghostty.Input.Key(keyCode: event.keyCode) else { return false }

        switch key {
        case .enter, .numpadEnter:
            guard nativeInteractionPhase.acceptsInput else { return false }
            let preResolvingSnapshot = latestNativeInteractionScreenSnapshot()
            guard sendPTYKeyEvent(event) else { return false }
            transitionNativeInteractionAfterEnter(preResolvingSnapshot: preResolvingSnapshot)
            return true
        case .escape:
            nativeInteractionPhase = .cancelling
            guard sendPTYKeyEvent(event) else {
                endNativeInteraction()
                return false
            }
            endNativeInteraction()
            return true
        case .tab, .arrowUp, .arrowDown, .arrowLeft, .arrowRight, .delete:
            guard nativeInteractionPhase.acceptsInput else { return false }
            nativeInteractionLastInputAt = Date()
            return sendPTYKeyEvent(event, nativeInteractionOnly: true)
        case .backspace:
            guard nativeInteractionPhase.acceptsInput else { return false }
            guard sendPTYKeyEvent(event, nativeInteractionOnly: true) else { return false }
            nativeInteractionLastInputAt = Date()
            removeLastNativeInteractionCharacter()
            return true
        default:
            return false
        }
    }

    @discardableResult
    func handlePTYInteractionKey(_ event: NSEvent) -> Bool {
        if sendNativeInteractionEvent(event) {
            return true
        }

        guard let characters = event.characters, !characters.isEmpty else {
            return false
        }

        guard nativeInteractionPhase.acceptsInput, hasCurrentSurface else { return false }

        nativeInteractionDisplayText += characters
        guard sendPTYKeyEvent(event, nativeInteractionOnly: true) else {
            nativeInteractionDisplayText.removeLast(characters.count)
            return false
        }

        nativeInteractionLastInputAt = Date()
        return true
    }

    private func removeLastNativeInteractionCharacter() {
        guard !nativeInteractionDisplayText.isEmpty else { return }
        nativeInteractionDisplayText.removeLast()

        if nativeInteractionDisplayText.isEmpty {
            endNativeInteraction()
            scheduleProjectionRefreshBurst()
        }
    }

    private func latestNativeInteractionScreenSnapshot() -> ShowCLITerminalScreenSnapshot? {
        nativeInteractionScreenSnapshot
            ?? readCurrentScreenSnapshot()
    }

    private func readCurrentScreenSnapshot() -> ShowCLITerminalScreenSnapshot? {
        ShowCLITerminalScreenSnapshot(json: surfaceView?.readScreenModelJSON() ?? "")
    }

    @discardableResult
    func sendPTYText(_ text: String, nativeInteractionOnly: Bool = false) -> Bool {
        guard let surface = surfaceView?.surfaceModel else { return false }
        surface.sendText(text)
        if nativeInteractionOnly {
            scheduleNativeInteractionRefreshBurst()
        } else {
            scheduleProjectionRefreshBurst()
        }
        return true
    }

    @discardableResult
    private func sendPTYKeyEvent(_ event: NSEvent, nativeInteractionOnly: Bool = false) -> Bool {
        guard let surfaceView else { return false }

        surfaceView.keyDown(with: event)
        if nativeInteractionOnly {
            scheduleNativeInteractionRefreshBurst()
        } else {
            scheduleProjectionRefreshBurst()
        }
        return true
    }

    func sendPTYEnter() {
        sendPTYKey(.enter, text: "\r", unshiftedCodepoint: 13)
    }

    func clearCurrentPTYInputLine() {
        sendPTYKey(.u, unshiftedCodepoint: 117, mods: .ctrl)
    }

    func sendPTYKey(
        _ key: Ghostty.Input.Key,
        text: String? = nil,
        unshiftedCodepoint: UInt32 = 0,
        mods: Ghostty.Input.Mods = [],
        nativeInteractionOnly: Bool = false
    ) {
        guard let surface = surfaceView?.surfaceModel else { return }

        surface.sendKeyEvent(.init(
            key: key,
            action: .press,
            text: text,
            mods: mods,
            unshiftedCodepoint: unshiftedCodepoint
        ))
        surface.sendKeyEvent(.init(
            key: key,
            action: .release,
            text: text,
            mods: mods,
            unshiftedCodepoint: unshiftedCodepoint
        ))
        if nativeInteractionOnly {
            scheduleNativeInteractionRefreshBurst()
        } else {
            scheduleProjectionRefreshBurst()
        }
    }

    private func startResearchRunnerIfConfigured() {
        guard researchRunner == nil else { return }
        guard ProcessInfo.processInfo.environment["SHOWCLI_RESEARCH_PLAN_PATH"] != nil else { return }

        let runner = ShowCLIResearchRunner(controller: self)
        researchRunner = runner
        runner.start()
    }

    func copyReadingBlock(_ block: ShowCLIReadingBlock) {
        let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func currentSurfaceStatus() -> ShowCLISurfaceStatus {
        guard let surfaceView else {
            return .init()
        }

        let childExitedMessage = surfaceView.childExitedMessage
        return .init(
            ttyName: surfaceView.surfaceModel?.ttyName,
            foregroundPID: surfaceView.surfaceModel?.foregroundPID,
            terminalColumns: surfaceView.surfaceSize.map { Int($0.columns) },
            terminalRows: surfaceView.surfaceSize.map { Int($0.rows) },
            widthPixels: surfaceView.surfaceSize.map { Int($0.width_px) },
            heightPixels: surfaceView.surfaceSize.map { Int($0.height_px) },
            cellWidthPixels: surfaceView.surfaceSize.map { Int($0.cell_width_px) },
            cellHeightPixels: surfaceView.surfaceSize.map { Int($0.cell_height_px) },
            processExited: surfaceView.processExited,
            childExitCode: childExitedMessage?.exitCode,
            childRuntimeMilliseconds: childExitedMessage?.runtimeMilliseconds,
            childExitLevel: childExitedMessage.map { message in
                switch message.level {
                case .success:
                    return "success"
                case .error:
                    return "error"
                }
            }
        )
    }

    private func observeCurrentSurface() {
        surfaceCancellables.removeAll()
        removeSurfaceObservers()

        guard activeMode == .reading, let surfaceView else { return }

        surfaceView.objectWillChange
            .sink { [weak self, weak surfaceView] _ in
                guard let self, self.surfaceView === surfaceView else { return }
                self.scheduleProjectionRefresh()
            }
            .store(in: &surfaceCancellables)

        let center = NotificationCenter.default
        surfaceObservers.append(center.addObserver(
            forName: .ghosttyDidUpdateScrollbar,
            object: surfaceView,
            queue: .main
        ) { [weak self, weak surfaceView] _ in
            Task { @MainActor [weak self, weak surfaceView] in
                guard let self, self.surfaceView === surfaceView else { return }
                self.scheduleProjectionRefresh()
            }
        })

        surfaceObservers.append(center.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.scheduleProjectionRefresh()
            }
        })
    }

    private func stopProjectionObservation() {
        surfaceCancellables.removeAll()
        removeSurfaceObservers()
        projectionRefreshTask?.cancel()
        projectionRefreshTask = nil
        projectionRefreshBurstTask?.cancel()
        projectionRefreshBurstTask = nil
        nativeInteractionRefreshBurstTask?.cancel()
        nativeInteractionRefreshBurstTask = nil
    }

    private func removeSurfaceObservers() {
        let center = NotificationCenter.default
        surfaceObservers.forEach { center.removeObserver($0) }
        surfaceObservers.removeAll()
    }

    private func scheduleProjectionRefresh() {
        guard activeMode == .reading else { return }

        projectionRefreshTask?.cancel()
        projectionRefreshTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 75_000_000)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            self?.refreshProjection()
        }
    }

    private func scheduleProjectionRefreshBurst() {
        guard activeMode == .reading else { return }

        refreshProjection()
        projectionRefreshBurstTask?.cancel()
        projectionRefreshBurstTask = Task { @MainActor [weak self] in
            let delays: [UInt64] = [
                50_000_000,
                150_000_000,
                300_000_000,
            ]

            for delay in delays {
                do {
                    try await Task.sleep(nanoseconds: delay)
                } catch {
                    return
                }

                guard !Task.isCancelled else { return }
                self?.refreshProjection()
            }
        }
    }

    private func scheduleNativeInteractionRefreshBurst() {
        guard activeMode == .reading else { return }

        nativeInteractionScreenSnapshot = nil
        refreshNativeInteractionSnapshot()
        nativeInteractionRefreshBurstTask?.cancel()
        nativeInteractionRefreshBurstTask = Task { @MainActor [weak self] in
            for delay in ShowCLINativeInteractionTiming.refreshBurstDelays {
                do {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } catch {
                    return
                }

                guard !Task.isCancelled else { return }
                self?.refreshNativeInteractionSnapshot()
            }
        }
    }

    nonisolated private static func commandExistsInLoginShell(_ command: String?) -> Bool {
        guard let command else { return true }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", "command -v \(shellQuoted(command)) >/dev/null 2>&1"]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    nonisolated private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}

private struct ShowCLIResearchPlan: Decodable {
    var samples: [ShowCLIResearchPlanSample]
}

private struct ShowCLIResearchPlanSample: Decodable {
    var sampleID: String
    var prompt: String
    var taskCategory: String
    var actions: [ShowCLIResearchAction]?

    enum CodingKeys: String, CodingKey {
        case sampleID = "sample_id"
        case prompt
        case taskCategory = "task_category"
        case actions
    }
}

private struct ShowCLIResearchAction: Decodable {
    var kind: String
    var text: String?
    var key: String?
    var seconds: Double?
    var width: Double?
    var height: Double?
}

@MainActor
private final class ShowCLIResearchRunner {
    private weak var controller: ShowCLICurrentSessionController?
    private var task: Task<Void, Never>?
    private let environment = ProcessInfo.processInfo.environment
    private let fileManager = FileManager.default

    init(controller: ShowCLICurrentSessionController) {
        self.controller = controller
    }

    func start() {
        guard task == nil else { return }
        task = Task { @MainActor [weak self] in
            await self?.run()
        }
    }

    private func run() async {
        guard let controller else { return }
        guard let planPath = environment["SHOWCLI_RESEARCH_PLAN_PATH"] else { return }

        let rootPath = environment["SHOWCLI_RESEARCH_DIR"]
            ?? "/Users/showing/A-ThinkBig/Project-ShowCLI/corpus/showcli-codex-tui-patterns-v0"
        let rootURL = URL(fileURLWithPath: rootPath, isDirectory: true)
        let planURL = URL(fileURLWithPath: planPath)

        do {
            try createCorpusDirectories(rootURL)
            let plan = try JSONDecoder().decode(ShowCLIResearchPlan.self, from: Data(contentsOf: planURL))
            try writePipelineCheck(rootURL: rootURL, planURL: planURL)
            let completedSampleIDs = try loadCompletedSampleIDs(rootURL: rootURL)

            controller.refreshAgentAvailability()
            try await sleep(seconds: 1.5)
            await waitForCodexAvailability(controller)

            if controller.selectedAgentPreset != .codex {
                _ = controller.startPreset(.codex)
                try await sleep(seconds: startupDelaySeconds())
            }

            for sample in plan.samples {
                try Task.checkCancellation()
                if completedSampleIDs.contains(sample.sampleID) {
                    try appendJSONLine([
                        "timestamp_ns": nowNs(),
                        "kind": "sample_skip_completed",
                        "sample_id": sample.sampleID
                    ], to: rootURL.appending(path: "runner-events.jsonl"))
                    continue
                }
                try await capture(sample, rootURL: rootURL)
            }

            try writeCompletionMarker(rootURL)
        } catch {
            try? appendJSONLine(
                ["timestamp_ns": nowNs(), "kind": "runner_error", "error": "\(error)"],
                to: rootURL.appending(path: "runner-events.jsonl")
            )
        }
    }

    private func capture(_ sample: ShowCLIResearchPlanSample, rootURL: URL) async throws {
        guard let controller else { return }

        let sampleID = sample.sampleID
        let eventsURL = rootURL.appending(path: "events/\(sampleID).events.jsonl")
        let snapshotURL = rootURL.appending(path: "snapshots/\(sampleID).projection.json")
        let annotationURL = rootURL.appending(path: "annotations/\(sampleID).annotation.json")
        let manifestURL = rootURL.appending(path: "manifest.jsonl")

        let startNs = nowNs()
        try appendJSONLine([
            "timestamp_ns": startNs,
            "kind": "sample_start",
            "sample_id": sampleID,
            "task_category": sample.taskCategory,
            "mode": controller.activeMode.rawValue
        ], to: eventsURL)

        if let actions = sample.actions, !actions.isEmpty {
            for action in actions {
                try await perform(action, eventsURL: eventsURL)
            }
        } else {
            try appendJSONLine([
                "timestamp_ns": nowNs(),
                "kind": "submit_prompt",
                "text": sample.prompt
            ], to: eventsURL)
            let sent = await submitPrompt(sample.prompt, eventsURL: eventsURL)
            try appendJSONLine([
                "timestamp_ns": nowNs(),
                "kind": "submit_result",
                "sent": sent
            ], to: eventsURL)
        }

        let waitResult = try await waitForProjectionIdle(eventsURL: eventsURL)
        controller.refreshProjection()
        let endNs = nowNs()

        let snapshot: [String: Any] = [
            "sample_id": sampleID,
            "timestamp_ns": endNs,
            "mode": controller.activeMode.rawValue,
            "projection": controller.capturedText,
            "reading_blocks": controller.readingBlocks.map { block in
                [
                    "id": block.id.uuidString,
                    "kind": block.kind.rawValue,
                    "text": block.text,
                    "created_at": iso8601(block.createdAt),
                    "updated_at": iso8601(block.updatedAt),
                    "is_live_projection": block.isLiveProjection
                ] as [String: Any]
            },
            "surface_status": [
                "tty_name": controller.surfaceStatus.ttyName as Any,
                "foreground_pid": controller.surfaceStatus.foregroundPID as Any,
                "terminal_cols": controller.surfaceStatus.terminalColumns as Any,
                "terminal_rows": controller.surfaceStatus.terminalRows as Any,
                "width_px": controller.surfaceStatus.widthPixels as Any,
                "height_px": controller.surfaceStatus.heightPixels as Any,
                "cell_width_px": controller.surfaceStatus.cellWidthPixels as Any,
                "cell_height_px": controller.surfaceStatus.cellHeightPixels as Any,
                "process_exited": controller.surfaceStatus.processExited,
                "child_exit_code": controller.surfaceStatus.childExitCode as Any,
                "child_runtime_milliseconds": controller.surfaceStatus.childRuntimeMilliseconds as Any,
                "child_exit_level": controller.surfaceStatus.childExitLevel as Any
            ]
        ]
        try writeJSONObject(snapshot, to: snapshotURL)

        try writeJSONObject([
            "sample_id": sampleID,
            "items": [],
            "notes": "Research-only placeholder. Manual or postprocessed annotation must preserve all uncertain content as terminal-derived item."
        ], to: annotationURL)

        try appendJSONLine([
            "sample_id": sampleID,
            "prompt": sample.prompt,
            "task_category": sample.taskCategory,
            "timestamp_start_ns": startNs,
            "timestamp_end_ns": endNs,
            "terminal_cols": controller.surfaceStatus.terminalColumns as Any,
            "terminal_rows": controller.surfaceStatus.terminalRows as Any,
            "codex_cli_version": environment["SHOWCLI_RESEARCH_CODEX_VERSION"] ?? "",
            "showcli_build_version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            "showcli_git_commit": environment["SHOWCLI_RESEARCH_GIT_COMMIT"] ?? "",
            "capture_method": "ShowCLI/Ghostty research-only runner using real interactive Codex CLI TUI; raw bytes recorded from Ghostty termio and projection from ghostty_surface_read_text screen.",
            "raw_artifact_path": "raw/\(sampleID).pty",
            "raw_chunk_source_path": "raw/raw-events.bin",
            "snapshot_path": "snapshots/\(sampleID).projection.json",
            "screenshot_path": "screenshots/\(sampleID).png",
            "annotation_path": "annotations/\(sampleID).annotation.json",
            "interaction_events_path": "events/\(sampleID).events.jsonl",
            "capture_limitations": [
                "Raw sample artifact is created by postprocessing timestamped Ghostty PTY output chunks between timestamp_start_ns and timestamp_end_ns.",
                "Projection snapshot is the ShowCLI Reading input seam, not semantic assistant extraction.",
                "Terminal rows/cols come from ghostty_surface_size via the live SurfaceView when available.",
                waitResult
            ]
        ], to: manifestURL)

        try appendJSONLine([
            "timestamp_ns": endNs,
            "kind": "sample_end",
            "sample_id": sampleID
        ], to: eventsURL)
    }

    private func perform(_ action: ShowCLIResearchAction, eventsURL: URL) async throws {
        guard let controller else { return }

        try appendJSONLine([
            "timestamp_ns": nowNs(),
            "kind": "action",
            "action_kind": action.kind,
            "text": action.text as Any,
            "key": action.key as Any
        ], to: eventsURL)

        switch action.kind {
        case "submit_prompt":
            let sent = await submitPrompt(action.text ?? "", eventsURL: eventsURL)
            try? appendJSONLine([
                "timestamp_ns": nowNs(),
                "kind": "submit_result",
                "sent": sent
            ], to: eventsURL)
        case "text":
            _ = controller.sendPTYText(action.text ?? "")
        case "prefix":
            _ = controller.triggerAgentPrefix(action.text ?? "/")
        case "enter":
            controller.sendPTYEnter()
        case "key":
            sendKey(action.key ?? "")
        case "wait":
            try await sleep(seconds: action.seconds ?? 1)
        case "resize_window":
            resizeWindow(width: action.width, height: action.height)
        default:
            break
        }
    }

    private func resizeWindow(width: Double?, height: Double?) {
        guard let window = NSApp.mainWindow ?? NSApp.windows.first else { return }
        var frame = window.frame
        if let width {
            frame.size.width = max(420, width)
        }
        if let height {
            frame.size.height = max(360, height)
        }
        window.setFrame(frame, display: true, animate: false)
        controller?.refreshProjection()
    }

    private func sendKey(_ key: String) {
        guard let controller else { return }
        switch key {
        case "escape":
            controller.sendPTYKey(.escape)
            controller.endPTYInteraction()
        case "tab":
            controller.sendPTYKey(.tab, text: "\t", unshiftedCodepoint: 9)
        case "arrow_up":
            controller.sendPTYKey(.arrowUp)
        case "arrow_down":
            controller.sendPTYKey(.arrowDown)
        case "arrow_left":
            controller.sendPTYKey(.arrowLeft)
        case "arrow_right":
            controller.sendPTYKey(.arrowRight)
        case "ctrl_c":
            controller.sendPTYKey(.c, unshiftedCodepoint: 99, mods: .ctrl)
            controller.endPTYInteraction()
        case "ctrl_u":
            controller.clearCurrentPTYInputLine()
        default:
            break
        }
    }

    private func submitPrompt(_ text: String, eventsURL: URL) async -> Bool {
        guard let controller else { return false }
        if controller.nativeInteractionIsActive {
            controller.sendPTYKey(.escape)
            controller.endPTYInteraction()
            try? await sleep(seconds: 0.25)
            controller.clearCurrentPTYInputLine()
            try? await sleep(seconds: 0.25)
        }

        let sent = controller.submitComposer(text)
        if sent { return true }

        try? appendJSONLine([
            "timestamp_ns": nowNs(),
            "kind": "submit_retry_after_reset"
        ], to: eventsURL)
        controller.endPTYInteraction()
        controller.sendPTYKey(.escape)
        try? await sleep(seconds: 0.25)
        controller.clearCurrentPTYInputLine()
        try? await sleep(seconds: 0.25)
        return controller.submitComposer(text)
    }

    private func waitForProjectionIdle(eventsURL: URL) async throws -> String {
        guard let controller else { return "controller unavailable" }

        let minSeconds = doubleEnv("SHOWCLI_RESEARCH_SAMPLE_MIN_SECONDS", defaultValue: 8)
        let maxSeconds = doubleEnv("SHOWCLI_RESEARCH_SAMPLE_MAX_SECONDS", defaultValue: 90)
        let idleSeconds = doubleEnv("SHOWCLI_RESEARCH_SAMPLE_IDLE_SECONDS", defaultValue: 5)
        let started = Date()
        var lastProjection = controller.capturedText
        var lastChange = Date()

        while Date().timeIntervalSince(started) < maxSeconds {
            try await sleep(seconds: 1)
            controller.refreshProjection()

            if controller.capturedText != lastProjection {
                lastProjection = controller.capturedText
                lastChange = Date()
                try appendJSONLine([
                    "timestamp_ns": nowNs(),
                    "kind": "projection_changed",
                    "projection_utf8_count": controller.capturedText.utf8.count
                ], to: eventsURL)
            }

            if Date().timeIntervalSince(started) >= minSeconds,
               Date().timeIntervalSince(lastChange) >= idleSeconds {
                return "ended after projection idle window"
            }
        }

        return "ended after max sample seconds"
    }

    private func waitForCodexAvailability(_ controller: ShowCLICurrentSessionController) async {
        for _ in 0..<20 {
            if controller.isPresetAvailable(.codex) { return }
            try? await sleep(seconds: 0.5)
        }
    }

    private func createCorpusDirectories(_ rootURL: URL) throws {
        for name in ["raw", "snapshots", "screenshots", "annotations", "events", "reports"] {
            try fileManager.createDirectory(at: rootURL.appending(path: name), withIntermediateDirectories: true)
        }
    }

    private func loadCompletedSampleIDs(rootURL: URL) throws -> Set<String> {
        let manifestURL = rootURL.appending(path: "manifest.jsonl")
        guard fileManager.fileExists(atPath: manifestURL.path) else { return [] }
        let text = try String(contentsOf: manifestURL, encoding: .utf8)
        var ids = Set<String>()
        for line in text.split(separator: "\n") where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            guard
                let data = String(line).data(using: .utf8),
                let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let sampleID = object["sample_id"] as? String
            else { continue }
            ids.insert(sampleID)
        }
        return ids
    }

    private func writePipelineCheck(rootURL: URL, planURL: URL) throws {
        let text = """
        # Pipeline Check

        - Capture method: env-gated ShowCLI/Ghostty research runner.
        - Plan path: `\(planURL.path)`.
        - Raw PTY chunks: `raw/raw-events.bin`, emitted by Ghostty termio before terminal parsing.
        - Projection snapshots: `ghostty_surface_read_text` screen via ShowCLI current session controller.
        - Interaction events: `events/*.events.jsonl`, emitted by the research runner when it sends text/keys.
        - Product behavior: recorder and runner are disabled unless `SHOWCLI_RESEARCH_PLAN_PATH` and/or `SHOWCLI_RESEARCH_RAW_EVENTS_PATH` are set.
        - Postprocessing required: split timestamped raw chunks into per-sample `raw/sample-XXXX.pty` and render/capture screenshots.
        """
        try text.write(to: rootURL.appending(path: "reports/pipeline-check.md"), atomically: true, encoding: .utf8)
    }

    private func writeCompletionMarker(_ rootURL: URL) throws {
        try appendJSONLine(["timestamp_ns": nowNs(), "kind": "runner_complete"], to: rootURL.appending(path: "runner-events.jsonl"))
    }

    private func appendJSONLine(_ object: [String: Any], to url: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        var line = Data()
        line.append(data)
        line.append(0x0A)
        if !fileManager.fileExists(atPath: url.path) {
            fileManager.createFile(atPath: url.path, contents: nil)
        }
        let handle = try FileHandle(forWritingTo: url)
        try handle.seekToEnd()
        try handle.write(contentsOf: line)
        try handle.close()
    }

    private func writeJSONObject(_ object: [String: Any], to url: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url, options: .atomic)
    }

    private func sleep(seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(max(0, seconds) * 1_000_000_000))
    }

    private func startupDelaySeconds() -> Double {
        doubleEnv("SHOWCLI_RESEARCH_CODEX_STARTUP_SECONDS", defaultValue: 18)
    }

    private func doubleEnv(_ key: String, defaultValue: Double) -> Double {
        guard let value = environment[key], let parsed = Double(value) else { return defaultValue }
        return parsed
    }

    private func nowNs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1_000_000_000)
    }

    private func iso8601(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
#endif
