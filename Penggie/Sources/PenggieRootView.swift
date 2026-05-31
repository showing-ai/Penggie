import SwiftUI

struct PenggieRootView: View {
    @EnvironmentObject private var session: PenggieSessionModel
    @Environment(\.penggieTheme) private var theme

    var body: some View {
        ZStack {
            theme.appBackground
                .ignoresSafeArea()

            switch session.state {
            case .idle, .closed:
                PenggieStartView()
            case .checkingCodex, .launching:
                PenggieStartView(startupState: session.state == .checkingCodex ? .checkingCodex : .launching)
            case .codexMissing:
                codexMissingState
            case .launchFailed(let message):
                launchFailedState(message)
            case .exited:
                exitedState
            case .reading, .terminal:
                if session.isHoldingInitialSurface {
                    PenggieStartView(startupState: .waitingForCodex)
                } else {
                    PenggieSessionView()
                }
            }
        }
        .background(PenggieWindowConfigurator())
        .alert(item: $session.pendingConfirmation) { confirmation in
            Alert(
                title: Text(confirmation.title),
                message: Text(confirmation.message),
                primaryButton: .destructive(Text(confirmation.confirmationButtonTitle)) {
                    session.confirm(confirmation)
                },
                secondaryButton: .cancel {
                    session.cancelConfirmation()
                }
            )
        }
    }

    private var codexMissingState: some View {
        PenggieErrorStateView(
            title: "Codex CLI not found",
            message: "Install Codex CLI or make sure it is available in your login shell PATH.",
            primaryActionTitle: "Check Again",
            primaryAction: session.startWithCodex,
            secondaryActionTitle: "Choose Folder",
            secondaryAction: { _ = session.chooseWorkingDirectory() }
        )
    }

    private func launchFailedState(_ message: String) -> some View {
        PenggieErrorStateView(
            title: "Codex failed to launch",
            message: message,
            primaryActionTitle: "Try Again",
            primaryAction: session.startWithCodex,
            secondaryActionTitle: "Choose Folder",
            secondaryAction: { _ = session.chooseWorkingDirectory() }
        )
    }

    @ViewBuilder
    private var exitedState: some View {
        if session.isInspectingExitedTerminal {
            PenggieExitedTerminalInspectionView()
        } else if session.hasExitedTerminalSurface {
            PenggieErrorStateView(
                title: "Codex session ended",
                message: "The Codex process exited. You can start a fresh chat, inspect the raw terminal output, or close this session.",
                primaryActionTitle: "Start Again",
                primaryAction: session.startWithCodex,
                secondaryActionTitle: "Inspect Raw Terminal",
                secondaryAction: session.inspectExitedTerminal,
                tertiaryActionTitle: "Close Session",
                tertiaryAction: session.requestCloseSession
            )
        } else {
            PenggieErrorStateView(
                title: "Codex session ended",
                message: "The Codex process exited. You can start a fresh chat or close this session.",
                primaryActionTitle: "Start Again",
                primaryAction: session.startWithCodex,
                tertiaryActionTitle: "Close Session",
                tertiaryAction: session.requestCloseSession
            )
        }
    }
}

private struct PenggieWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(window: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(window: nsView.window)
        }
    }

    private func configure(window: NSWindow?) {
        guard let window else { return }
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
    }
}

private enum PenggieStartupState {
    case checkingCodex
    case launching
    case waitingForCodex

    var title: String {
        switch self {
        case .checkingCodex:
            return "Checking Codex"
        case .launching:
            return "Starting Codex"
        case .waitingForCodex:
            return "Preparing Reading"
        }
    }

    var message: String {
        switch self {
        case .checkingCodex:
            return "Penggie is checking that the Codex CLI is available."
        case .launching:
            return "Penggie is starting the local Codex session."
        case .waitingForCodex:
            return "Penggie is waiting for the first stable terminal frame."
        }
    }
}

private struct PenggieStartView: View {
    @EnvironmentObject private var session: PenggieSessionModel
    @Environment(\.penggieTheme) private var theme
    var startupState: PenggieStartupState?

    private var folderIsMissing: Bool {
        session.selectedWorkingDirectory == nil
    }

    private var folderIsUsable: Bool {
        guard let url = session.selectedWorkingDirectory else { return false }
        return PenggieSessionModel.isUsableWorkingDirectory(url)
    }

    private var folderStatusText: String? {
        if folderIsMissing {
            return "Choose a project folder before creating a session."
        }
        if !folderIsUsable {
            return "Penggie cannot access this folder. Choose another project folder."
        }
        return nil
    }

    private var createButtonTitle: String {
        startupState?.title ?? "Create with Penggie"
    }

    private var createHelpText: String {
        if let startupState {
            return startupState.message
        }
        if folderIsMissing {
            return "Choose a project folder to create with Penggie"
        }
        if !folderIsUsable {
            return "Choose an accessible project folder to create with Penggie"
        }
        return "Create with Penggie in the selected folder"
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 80)

            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 58, height: 58)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(startupState?.title ?? "Welcome to Penggie")
                    .font(.system(size: 24, weight: .semibold))
                Text(startupState?.message ?? "Choose a project folder, then create with Penggie.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                HStack(spacing: 16) {
                    CodexProviderIcon()

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Codex")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Local agent CLI")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("Selected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.secondaryText)
                }
                .padding(16)
                .frame(maxWidth: 560)
                .background(theme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(theme.separator, lineWidth: 1)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Codex selected as local agent CLI")

                Button {
                    _ = session.chooseWorkingDirectory()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.secondaryText)
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Project Folder")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(theme.secondaryText)
                            Text(session.sessionFolderDisplayPath)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }

                        Spacer()

                        Text(session.selectedWorkingDirectory == nil ? "Choose" : "Change")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(theme.secondaryText)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: 560)
                    .background(theme.appBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(theme.quietSeparator, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!session.canStartCodex)
                .accessibilityLabel("Choose Project Folder")
                .accessibilityValue(session.sessionFolderDisplayPath)
                .accessibilityHint(session.canStartCodex ? "Choose the folder where this session will start" : "Project folder cannot be changed while Codex is starting")
                .help(session.canStartCodex ? "Choose the folder where this session will start" : "Project folder cannot be changed while Codex is starting")

                if let folderStatusText {
                    HStack(spacing: 8) {
                        Image(systemName: folderIsMissing ? "info.circle" : "exclamationmark.triangle")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(folderIsMissing ? theme.secondaryText : theme.semantic.warning.color)
                        Text(folderStatusText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(folderIsMissing ? theme.secondaryText : theme.semantic.warning.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: 560)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(folderStatusText)
                }

                Button {
                    session.startWithCodex()
                } label: {
                    HStack(spacing: 8) {
                        if startupState != nil {
                            ProgressView()
                                .controlSize(.small)
                                .accessibilityHidden(true)
                        }
                        Text(createButtonTitle)
                    }
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: 560)
                        .frame(height: 42)
                        .foregroundStyle(session.canStartConfiguredCodex ? theme.onAccent : theme.secondaryText)
                        .background(session.canStartConfiguredCodex ? theme.accent : theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!session.canStartConfiguredCodex)
                .accessibilityLabel("Create with Penggie")
                .accessibilityHint(createHelpText)
                .help(createHelpText)
            }

            Spacer(minLength: 100)
        }
    }
}

private struct CodexProviderIcon: View {
    @Environment(\.penggieTheme) private var theme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(theme.surface)

            Image("OpenAIProviderIcon")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 26, height: 26)
                .foregroundStyle(.primary)
        }
        .frame(width: 52, height: 52)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(theme.quietSeparator, lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

private struct PenggieProgressView: View {
    @EnvironmentObject private var session: PenggieSessionModel

    var body: some View {
        VStack(spacing: 18) {
            ProgressView()
                .controlSize(.large)
            VStack(spacing: 5) {
                Text(session.state == .checkingCodex ? "Checking Codex" : "Starting local session")
                    .font(.system(size: 17, weight: .semibold))
                Text(session.state == .checkingCodex ? "Looking in your login shell PATH." : "Preparing your Penggie workspace.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
        .frame(maxWidth: 380)
    }
}

private struct PenggieErrorStateView: View {
    @Environment(\.penggieTheme) private var theme

    let title: String
    let message: String
    let primaryActionTitle: String
    let primaryAction: () -> Void
    var secondaryActionTitle: String? = nil
    var secondaryAction: (() -> Void)? = nil
    var tertiaryActionTitle: String? = nil
    var tertiaryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
            }

            HStack(spacing: 10) {
                if let tertiaryActionTitle, let tertiaryAction {
                    Button(tertiaryActionTitle, role: .destructive, action: tertiaryAction)
                        .controlSize(.large)
                        .buttonStyle(.bordered)
                }

                if let secondaryActionTitle, let secondaryAction {
                    Button(secondaryActionTitle, action: secondaryAction)
                        .controlSize(.large)
                        .buttonStyle(.bordered)
                }

                Button(primaryActionTitle, action: primaryAction)
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .frame(maxWidth: 520)
        .background(theme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(theme.quietSeparator, lineWidth: 1)
        }
    }
}

private struct PenggieExitedTerminalInspectionView: View {
    @EnvironmentObject private var session: PenggieSessionModel
    @Environment(\.penggieTheme) private var theme

    var body: some View {
        ZStack(alignment: .top) {
            PenggieRawTerminalPlaceholder(isActive: true)
                .padding(.top, PenggieChromeMetrics.height)

            HStack(spacing: 12) {
                Color.clear
                    .frame(width: PenggieChromeMetrics.trafficLightSafeArea)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Codex session ended")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.secondaryText)
                    Text("Raw Terminal inspection")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.disabledAction)
                }

                Spacer()

                PenggieChromeIconButton(systemName: "arrow.uturn.left", label: "Show Recovery") {
                    session.returnToExitedRecovery()
                }
            }
            .padding(.trailing, 22)
            .frame(height: PenggieChromeMetrics.height)
            .background(theme.components.windowChrome.terminal.background.color)
        }
        .background(theme.terminalBackground)
        .ignoresSafeArea(.container, edges: .top)
    }
}

private struct PenggieSessionView: View {
    @EnvironmentObject private var session: PenggieSessionModel
    @Environment(\.penggieTheme) private var theme

    var body: some View {
        ZStack(alignment: .top) {
            PenggieRawTerminalPlaceholder(isActive: session.state == .terminal)
                .opacity(session.state == .terminal ? 1 : 0)
                .allowsHitTesting(session.state == .terminal)
                .accessibilityHidden(session.state != .terminal)
                .padding(.top, PenggieChromeMetrics.height)

            PenggieReadingChatView()
                .opacity(session.state == .terminal ? 0 : 1)
                .allowsHitTesting(session.state != .terminal)
                .accessibilityHidden(session.state == .terminal)
                .padding(.top, PenggieChromeMetrics.height)

            PenggieWindowChrome()
        }
        .background(session.state == .terminal ? theme.terminalBackground : theme.contentBackground)
        .ignoresSafeArea(.container, edges: .top)
    }
}

private enum PenggieChromeMetrics {
    static let height: CGFloat = 34
    static let trafficLightSafeArea: CGFloat = 84
}

private struct PenggieWindowChrome: View {
    @EnvironmentObject private var session: PenggieSessionModel
    @Environment(\.penggieTheme) private var theme

    private var chromeTheme: PenggieChromeTheme {
        session.state == .terminal ? theme.components.windowChrome.terminal : theme.components.windowChrome.reading
    }

    var body: some View {
        HStack(spacing: 12) {
            Color.clear
                .frame(width: PenggieChromeMetrics.trafficLightSafeArea)

            HStack(spacing: 5) {
                Image(systemName: "folder")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(chromeTheme.foreground.color)

                Text(session.sessionFolderTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(chromeTheme.foreground.color)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .help(session.sessionFolderDisplayPath)

            Spacer()

            PenggieModeToggleButton()
        }
        .padding(.trailing, 22)
        .frame(height: PenggieChromeMetrics.height)
        .background(chromeTheme.background.color)
    }
}

private struct PenggieModeToggleButton: View {
    @EnvironmentObject private var session: PenggieSessionModel

    var body: some View {
        if session.state == .terminal {
            PenggieChromeIconButton(systemName: "bubble.left.and.bubble.right", label: "Show Reading") {
                session.switchToReading()
            }
        } else {
            PenggieChromeIconButton(systemName: "terminal", label: "Show Raw Terminal") {
                session.switchToTerminal()
            }
        }
    }
}

private struct PenggieChromeIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    @State private var isHovering = false
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: systemName)
                .labelStyle(.iconOnly)
                .font(.system(size: 12, weight: .regular))
                .frame(width: 28, height: 22)
        }
        .buttonStyle(PenggieChromeIconButtonStyle(isHovering: isHovering, isFocused: isFocused))
        .focusable()
        .focused($isFocused)
        .accessibilityLabel(Text(label))
        .help(label)
        .onHover { isHovering = $0 }
    }
}

private struct PenggieChromeIconButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.penggieTheme) private var theme

    let isHovering: Bool
    let isFocused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? theme.secondaryText : theme.disabledAction)
            .background(background(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(isFocused ? theme.accent.opacity(0.58) : Color.clear, lineWidth: 2)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.12), value: isHovering)
            .animation(.easeOut(duration: 0.12), value: isFocused)
    }

    private func background(isPressed: Bool) -> Color {
        if !isEnabled {
            return Color.clear
        }

        if isPressed {
            return theme.selectedBackground
        }

        if isHovering || isFocused {
            return theme.surface
        }

        return Color.clear
    }
}

private struct PenggieReadingChatView: View {
    @EnvironmentObject private var session: PenggieSessionModel
    @Environment(\.penggieTheme) private var theme
    @State private var composerText = ""
    @State private var composerTextHeight: CGFloat = 58
    @State private var composerHasVisibleText = false
    @State private var nativeInteractionFocusRequestID = 0
    @State private var resumePickerFocusRequestID = 0

    var body: some View {
        GeometryReader { geometry in
            let visibleItems = PenggieReadingPresentation.visibleItems(
                from: session.readingBlocks,
                nativeInteractionIsActive: session.nativeInteractionIsActive
            )
            let contentWidth = contentWidth(for: geometry.size.width)
            let activeSurface = session.activeTerminalInteractionSurface

            VStack(spacing: 0) {
                if !session.hasObservedCodexScreen {
                    terminalOwnedInteractionState(contentWidth: contentWidth)
                } else if let activeSurface,
                          rendersAsFullPage(surface: activeSurface) {
                    terminalInteractionSurfaceState(activeSurface, contentWidth: contentWidth)
                } else if session.codexScreenKind.isTerminalOwnedInteraction {
                    terminalOwnedInteractionState(contentWidth: contentWidth)
                } else if visibleItems.isEmpty {
                    emptyState(contentWidth: contentWidth, activeSurface: activeSurface)
                } else {
                    transcriptContent(items: visibleItems, contentWidth: contentWidth)
                    composerStack(contentWidth: contentWidth, activeSurface: activeSurface)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 28)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.contentBackground)
        .onChange(of: session.nativeInteractionIsActive) { _, isActive in
            if session.state == .reading,
               isActive,
               !session.codexScreenKind.isTerminalOwnedInteraction {
                nativeInteractionFocusRequestID += 1
            }
        }
        .onChange(of: session.codexScreenKind) { _, screenKind in
            if session.state == .reading, screenKind == .resumePicker {
                resumePickerFocusRequestID += 1
            }
        }
    }

    private func contentWidth(for availableWidth: CGFloat) -> CGFloat {
        let reservedHorizontalInset: CGFloat = 56
        return max(1, min(880, availableWidth - reservedHorizontalInset))
    }

    private func rendersAsFullPage(surface: PenggieTerminalInteractionSurface) -> Bool {
        switch surface.kind {
        case .resumePicker, .approvalPrompt, .permissionPrompt, .modalChoice:
            return true
        case .transcript, .startup, .slashSuggestions, .slashContinuation, .modelPicker, .effortPicker, .pager, .opaqueTerminal:
            return false
        }
    }

    private func emptyState(
        contentWidth: CGFloat,
        activeSurface: PenggieTerminalInteractionSurface? = nil
    ) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Text("What should we work on?")
                .font(.system(size: 27, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: contentWidth)

            composerStack(contentWidth: contentWidth, activeSurface: activeSurface)

            Spacer(minLength: 96)
        }
        .padding(.horizontal, 28)
    }

    private func terminalOwnedInteractionState(contentWidth: CGFloat) -> some View {
        let copy = terminalOwnedInteractionCopy

        return VStack(spacing: 14) {
            Spacer()

            ProgressView()
                .controlSize(.small)

            VStack(spacing: 8) {
                Text(copy.title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary)
                Text(copy.message)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: min(contentWidth, 560))
            }

            Spacer(minLength: 96)
        }
        .padding(.horizontal, 28)
    }

    private func terminalInteractionSurfaceState(
        _ surface: PenggieTerminalInteractionSurface,
        contentWidth: CGFloat
    ) -> some View {
        switch surface.kind {
        case .resumePicker:
            AnyView(resumePickerState(surface: surface, contentWidth: contentWidth))
        case .approvalPrompt, .permissionPrompt, .modalChoice:
            AnyView(modalChoiceState(surface: surface, contentWidth: contentWidth))
        case .transcript, .startup, .slashSuggestions, .slashContinuation, .modelPicker, .effortPicker, .pager, .opaqueTerminal:
            AnyView(terminalOwnedInteractionState(contentWidth: contentWidth))
        }
    }

    private func resumePickerState(
        surface: PenggieTerminalInteractionSurface,
        contentWidth: CGFloat
    ) -> some View {
        let hasReliableSelection = surface.hasFreshConfirmableSelection

        return ZStack {
            VStack(spacing: 20) {
                Spacer(minLength: 72)

                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(theme.secondaryText)
                    Text("Resume a previous session")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Type to search, use ↑/↓ to browse, press Enter to resume.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        Label("Search in saved sessions", systemImage: "magnifyingglass")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(theme.secondaryText)

                        Spacer()

                        if let filterText = surface.metadata["filter"] {
                            Text("Filter: \(filterText)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(theme.secondaryText)
                        }
                        if let sortText = surface.metadata["sort"] {
                            Text("Sort: \(sortText)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(theme.secondaryText)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                    Divider()

                    if surface.candidates.isEmpty {
                        VStack(spacing: 10) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Loading saved sessions…")
                                .font(.system(size: 13))
                                .foregroundStyle(theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, minHeight: 220)
                    } else {
                        VStack(spacing: 0) {
                            PenggieTerminalSurfaceCandidateListView(
                                candidates: surface.candidates,
                                selectedRowID: surface.selection.confirmableRowID,
                                maxVisibleRows: 7
                            )

                            if !hasReliableSelection {
                                Divider()
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text(PenggieTerminalSurfaceStatusCopy.syncingSelection)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(theme.secondaryText)
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                            }
                        }
                        .frame(maxHeight: 430)
                    }

                    Divider()

                    HStack(spacing: 14) {
                        Text("↑/↓ browse")
                            .foregroundStyle(theme.secondaryText)
                        Text("Enter resume")
                            .foregroundStyle(hasReliableSelection ? theme.secondaryText : theme.secondaryText.opacity(0.45))
                        Text("Tab filter/sort")
                            .foregroundStyle(theme.secondaryText)
                        Text("Esc exit")
                            .foregroundStyle(theme.secondaryText)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                }
                .frame(width: min(contentWidth, 760))
                .background(theme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(theme.quietSeparator, lineWidth: 1)
                }
                .shadow(color: theme.shadow, radius: 16, y: 10)

                Spacer(minLength: 96)
            }
            .padding(.horizontal, 28)

            PenggieInteractionKeyCaptureView(
                shouldFocus: session.state == .reading,
                isEnabled: session.state == .reading && session.codexScreenKind == .resumePicker,
                focusRequestID: resumePickerFocusRequestID,
                onCommand: { command, _ in handleResumePickerCommand(command) },
                onTextInput: handleResumePickerText
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func modalChoiceState(
        surface: PenggieTerminalInteractionSurface,
        contentWidth: CGFloat
    ) -> some View {
        ZStack {
            VStack(spacing: 20) {
                Spacer(minLength: 72)

                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.shield")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(theme.secondaryText)
                    Text(surface.kind == .permissionPrompt ? "Permission required" : "Approval required")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Use ↑/↓ to choose, Enter to confirm, or Esc to cancel.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                VStack(spacing: 0) {
                    PenggieTerminalSurfaceCandidateListView(
                        candidates: surface.candidates,
                        selectedRowID: surface.selection.confirmableRowID,
                        maxVisibleRows: 5
                    )
                    .frame(minHeight: 120, maxHeight: 260)

                    if !surface.hasFreshConfirmableSelection {
                        Divider()
                        lowConfidenceSurfaceHint
                    }
                }
                .frame(width: min(contentWidth, 560))
                .background(theme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(theme.quietSeparator, lineWidth: 1)
                }
                .shadow(color: theme.shadow, radius: 16, y: 10)

                Spacer(minLength: 96)
            }
            .padding(.horizontal, 28)

            PenggieInteractionKeyCaptureView(
                shouldFocus: session.state == .reading,
                isEnabled: session.state == .reading && session.isRunning,
                focusRequestID: resumePickerFocusRequestID,
                onCommand: { command, _ in handleTerminalSurfaceCommand(command) },
                onTextInput: handleTerminalSurfaceText
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var terminalOwnedInteractionCopy: (title: String, message: String) {
        switch session.codexScreenKind {
        case .startupShell, .codexStartupStatus:
            return (
                "Starting Codex",
                "Penggie is waiting for Codex to finish launching."
            )
        case .resumePicker:
            return (
                "Resume a previous session",
                "Choose a saved session to continue."
            )
        case .unknown, .chat:
            return (
                "Waiting for Codex",
                "Codex is showing an interactive terminal screen. Reading will resume when a chat transcript is available."
            )
        }
    }

    private func transcriptContent(
        items: [PenggieReadingVisibleItem],
        contentWidth: CGFloat
    ) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ForEach(items) { item in
                    PenggieReadingVisibleItemView(item: item)
                }
            }
            .frame(width: contentWidth, alignment: .leading)
            .padding(.top, 44)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func composerStack(
        contentWidth: CGFloat,
        activeSurface: PenggieTerminalInteractionSurface? = nil
    ) -> some View {
        let composerWidth = min(contentWidth, 720)

        return VStack(spacing: 0) {
            if let activeSurface,
               rendersAsComposerOverlay(surface: activeSurface) {
                PenggieTerminalSurfaceOverlay(surface: activeSurface)
                    .padding(.bottom, 8)
            } else if session.nativeInteractionIsActive && !session.nativeInteractionRows.isEmpty {
                PenggieNativeInteractionOverlay(rows: session.nativeInteractionRows)
                    .padding(.bottom, 8)
            }

            composerSurface

            HStack {
                Spacer()
                Button {
                    submitComposer()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 38, height: 38)
                        .foregroundStyle(canSend ? theme.onAccent : theme.secondaryText)
                        .background(canSend ? theme.accent : theme.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .accessibilityLabel("Send")
                .help("Send")
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .frame(maxWidth: composerWidth)
        .background(theme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(theme.quietSeparator, lineWidth: 1)
        }
        .shadow(color: theme.shadow, radius: 14, y: 8)
    }

    private func rendersAsComposerOverlay(surface: PenggieTerminalInteractionSurface) -> Bool {
        switch surface.kind {
        case .slashSuggestions, .slashContinuation, .modelPicker, .effortPicker:
            return true
        case .transcript, .startup, .resumePicker, .modalChoice, .approvalPrompt, .permissionPrompt, .pager, .opaqueTerminal:
            return false
        }
    }

    private var composerSurface: some View {
        Group {
            if session.nativeInteractionIsActive {
                ZStack(alignment: .leading) {
                    Text(session.nativeInteractionDisplayText.isEmpty ? "Command" : session.nativeInteractionDisplayText)
                        .font(.system(size: 14))
                        .foregroundStyle(session.nativeInteractionDisplayText.isEmpty ? .tertiary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    PenggieInteractionKeyCaptureView(
                        shouldFocus: session.state == .reading,
                        isEnabled: session.state == .reading && session.nativeInteractionPhase.acceptsInput,
                        focusRequestID: nativeInteractionFocusRequestID,
                        onCommand: { command, _ in handleNativeInteractionCommand(command) },
                        onTextInput: handleNativeInteractionText
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: 58)
            } else {
                ZStack(alignment: .topLeading) {
                    if !composerHasVisibleText {
                        Text("Ask Codex anything")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 6)
                            .allowsHitTesting(false)
                    }

                    PenggieComposerTextView(
                        text: $composerText,
                        measuredHeight: $composerTextHeight,
                        hasVisibleText: $composerHasVisibleText,
                        isEnabled: session.state == .reading &&
                            session.isRunning &&
                            !session.codexScreenKind.isTerminalOwnedInteraction,
                        shouldFocus: session.state == .reading &&
                            !session.codexScreenKind.isTerminalOwnedInteraction,
                        minHeight: 58,
                        maxHeight: 140,
                        textColor: theme.semantic.textPrimary.nsColor,
                        disabledTextColor: theme.semantic.textDisabled.nsColor,
                        insertionPointColor: theme.semantic.focusRing.nsColor,
                        onSubmit: submitComposer,
                        onNativePrefix: { prefix in
                            let started = session.beginNativeInteraction(prefix: prefix)
                            if started {
                                composerText = ""
                                nativeInteractionFocusRequestID += 1
                            }
                            return started
                        }
                    )
                    .frame(height: composerTextHeight)
                    .onChange(of: composerText) { _, text in
                        handleComposerTextChange(text)
                    }
                }
                .frame(minHeight: 58)
            }
        }
    }

    private var canSend: Bool {
        if session.nativeInteractionIsActive {
            guard let surface = session.activeTerminalInteractionSurface else {
                return true
            }
            return surface.hasFreshConfirmableSelection
        }

        return session.canSubmitPrompt && !composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitComposer() {
        if session.nativeInteractionIsActive {
            if let surface = session.activeTerminalInteractionSurface {
                let decision = PenggieTerminalInputPolicy.commandDecision(.enter, surface: surface)
                if case .blocked = decision {
                    nativeInteractionFocusRequestID += 1
                    return
                }
            }
            _ = session.sendNativeInteractionEnter()
            nativeInteractionFocusRequestID += 1
            return
        }

        if session.sendPrompt(composerText) {
            composerText = ""
        }
    }

    private func handleComposerTextChange(_ text: String) {
        guard PenggieComposerNativeTrigger.prefix(for: text) != nil,
              session.beginNativeInteraction(initialText: text) else {
            return
        }

        composerText = ""
        nativeInteractionFocusRequestID += 1
    }

    private func handleNativeInteractionCommand(_ command: PenggieInteractionCommand) -> PenggieTerminalInputDecision {
        if let frame = session.latestTerminalFrame {
            let surface = PenggieTerminalBehaviorZoner.classify(
                frame: frame,
                currentInput: session.nativeInteractionDisplayText
            )
            let decision = PenggieTerminalInputPolicy.commandDecision(command, surface: surface)
            if case .blocked = decision {
                nativeInteractionFocusRequestID += 1
                return decision
            }
        }

        let sent: Bool
        if command == .escape {
            sent = session.cancelNativeInteraction()
        } else {
            sent = session.sendNativeInteractionCommand(command)
        }

        if session.nativeInteractionIsActive {
            nativeInteractionFocusRequestID += 1
        }

        return sent ? .handled : .unhandled
    }

    private func handleNativeInteractionText(_ text: String) -> Bool {
        let sent = session.sendNativeInteractionText(text)
        if sent {
            nativeInteractionFocusRequestID += 1
        }
        return sent
    }

    private func handleResumePickerCommand(_ command: PenggieInteractionCommand) -> PenggieTerminalInputDecision {
        let surface = session.latestTerminalFrame.flatMap { frame in
            PenggieTerminalBehaviorZoner.classify(frame: frame)
        }
        let decision = PenggieTerminalInputPolicy.commandDecision(command, surface: surface)
        if case .blocked = decision {
            resumePickerFocusRequestID += 1
            return decision
        }

        if surface == nil {
            let legacyDecision = PenggieTerminalInputPolicy.resumePickerCommandDecision(
                command,
                projection: session.resumePickerProjection
            )
            if case .blocked = legacyDecision {
                resumePickerFocusRequestID += 1
                return legacyDecision
            }
        }

        let sent = session.sendTerminalSurfaceCommand(command)
        if sent {
            resumePickerFocusRequestID += 1
        }
        return sent ? .handled : .unhandled
    }

    private func handleResumePickerText(_ text: String) -> Bool {
        let sent = session.sendTerminalSurfaceText(text)
        if sent {
            resumePickerFocusRequestID += 1
        }
        return sent
    }

    private func handleTerminalSurfaceCommand(_ command: PenggieInteractionCommand) -> PenggieTerminalInputDecision {
        let decision = PenggieTerminalInputPolicy.commandDecision(
            command,
            surface: session.activeTerminalInteractionSurface
        )
        if case .blocked = decision {
            resumePickerFocusRequestID += 1
            return decision
        }

        let sent = session.sendTerminalSurfaceCommand(command)
        if sent {
            resumePickerFocusRequestID += 1
        }
        return sent ? .handled : .unhandled
    }

    private func handleTerminalSurfaceText(_ text: String) -> Bool {
        let sent = session.sendTerminalSurfaceText(text)
        if sent {
            resumePickerFocusRequestID += 1
        }
        return sent
    }

    private var lowConfidenceSurfaceHint: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text(PenggieTerminalSurfaceStatusCopy.syncingSelection)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.secondaryText)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct PenggieTerminalSurfaceCandidateRowView: View {
    static let height: CGFloat = 38

    @Environment(\.penggieTheme) private var theme

    let candidate: PenggieTerminalInteractionCandidate
    let isSelected: Bool

    var body: some View {
        let overlay = theme.components.nativeTuiOverlay

        HStack(spacing: 12) {
            Text(isSelected ? "›" : "")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isSelected ? overlay.selectedForeground.color : .clear)
                .frame(width: 14, alignment: .center)

            Text(candidate.text)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? overlay.selectedForeground.color : overlay.rowForeground.color)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 12)
        }
        .padding(.horizontal, 10)
        .frame(height: Self.height)
        .background(isSelected ? overlay.selectedBackground.color : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct PenggieTerminalSurfaceCandidateListView: View {
    let candidates: [PenggieTerminalInteractionCandidate]
    let selectedRowID: String?
    var rowSpacing: CGFloat = 6
    var maxVisibleRows = 9

    var body: some View {
        let geometry = PenggieTerminalInteractionCandidateListGeometry.derive(
            candidateCount: candidates.count,
            maxVisibleCount: maxVisibleRows,
            rowHeight: Double(PenggieTerminalSurfaceCandidateRowView.height),
            rowSpacing: Double(rowSpacing),
            verticalPadding: 10
        )

        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: rowSpacing) {
                    ForEach(candidates) { candidate in
                        PenggieTerminalSurfaceCandidateRowView(
                            candidate: candidate,
                            isSelected: selectedRowID == candidate.id
                        )
                        .id(candidate.id)
                    }
                }
                .padding(10)
            }
            .scrollIndicators(candidates.count > geometry.visibleRowCount ? .visible : .hidden)
            .frame(height: CGFloat(geometry.viewportHeight))
            .onAppear {
                scrollSelectedCandidate(with: proxy)
            }
            .onChange(of: selectedRowID) { _, _ in
                scrollSelectedCandidate(with: proxy)
            }
            .onChange(of: candidates.map(\.id)) { _, _ in
                scrollSelectedCandidate(with: proxy)
            }
        }
    }

    private func scrollSelectedCandidate(with proxy: ScrollViewProxy) {
        let targetID: String?
        if let selectedRowID,
           candidates.contains(where: { $0.id == selectedRowID }) {
            targetID = selectedRowID
        } else {
            targetID = candidates.first?.id
        }

        guard let targetID else { return }

        DispatchQueue.main.async {
            var transaction = Transaction()
            transaction.animation = nil
            withTransaction(transaction) {
                proxy.scrollTo(targetID, anchor: selectedRowID == targetID ? .center : .top)
            }
        }
    }
}

private struct PenggieReadingVisibleItemView: View {
    let item: PenggieReadingVisibleItem

    var body: some View {
        switch item {
        case .block(let block):
            PenggieReadingBlockView(block: block)
        case .disclosure(let disclosure):
            PenggieReadingDisclosureView(disclosure: disclosure)
        }
    }
}

private struct PenggieReadingBlockView: View {
    @Environment(\.penggieTheme) private var theme

    let block: PenggieReadingBlock

    var body: some View {
        if PenggieReadingPresentation.isUserPromptBlock(block) {
            HStack {
                Spacer(minLength: 60)
                Text(PenggieReadingPresentation.promptText(for: block))
                    .font(.system(size: 14))
                    .foregroundStyle(theme.onAccent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        } else if PenggieReadingPresentation.isToolChromeBlock(block) {
            Text(PenggieReadingPresentation.terminalText(for: block))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            PenggieReadingContentView(block: block)
        }
    }
}

private struct PenggieReadingContentView: View {
    let block: PenggieReadingBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(PenggieReadingPresentation.displaySegments(for: block).enumerated()), id: \.offset) { _, segment in
                switch segment.kind {
                case .prose:
                    Text(segment.text)
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .preformatted:
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(segment.text)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.primary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.vertical, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PenggieReadingDisclosureView: View {
    @Environment(\.penggieTheme) private var theme

    let disclosure: PenggieReadingDisclosureBlock
    @State private var isExpanded: Bool

    init(disclosure: PenggieReadingDisclosureBlock) {
        self.disclosure = disclosure
        self._isExpanded = State(initialValue: !disclosure.isCollapsedByDefault)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                guard disclosure.hasDetails else { return }
                withAnimation(.easeOut(duration: 0.16)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(disclosure.summary)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if disclosure.hasDetails {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }
                .foregroundStyle(theme.secondaryText)
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(disclosure.summary)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .help(disclosure.hasDetails ? (isExpanded ? "Hide activity details" : "Show activity details") : disclosure.summary)

            if isExpanded, disclosure.hasDetails {
                Text(disclosure.detailText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PenggieNativeInteractionOverlay: View {
    @Environment(\.penggieTheme) private var theme

    let rows: [PenggieNativeInteractionLine]

    var body: some View {
        let overlay = theme.components.nativeTuiOverlay

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                Text("↑↓ select · Enter accept · Esc cancel")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(overlay.mutedForeground.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    nativeInteractionRowView(row)
                }
            }
        }
        .padding(10)
        .background(overlay.background.color)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(overlay.separator.color, lineWidth: 1)
        }
    }

    private func nativeInteractionRowView(_ row: PenggieNativeInteractionLine) -> some View {
        let overlay = theme.components.nativeTuiOverlay
        let foreground = row.isSelected ? overlay.selectedForeground.color : overlay.rowForeground.color
        let background = row.isSelected ? overlay.selectedBackground.color : Color.clear

        return Text(row.text.isEmpty ? " " : row.text)
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .truncationMode(.middle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct PenggieTerminalSurfaceOverlay: View {
    @Environment(\.penggieTheme) private var theme

    let surface: PenggieTerminalInteractionSurface

    var body: some View {
        let overlay = theme.components.nativeTuiOverlay

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                Text(helpText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(overlay.mutedForeground.color)
            }

            PenggieTerminalSurfaceCandidateListView(
                candidates: surface.candidates,
                selectedRowID: surface.selection.confirmableRowID,
                rowSpacing: 2,
                maxVisibleRows: 5
            )
            .frame(maxHeight: 260)

            if !surface.hasFreshConfirmableSelection {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(PenggieTerminalSurfaceStatusCopy.syncingSelection)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(overlay.mutedForeground.color)
                    Spacer(minLength: 0)
                }
                .padding(.top, 6)
            }
        }
        .padding(10)
        .background(overlay.background.color)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(overlay.separator.color, lineWidth: 1)
        }
    }

    private var helpText: String {
        switch surface.kind {
        case .modelPicker, .effortPicker, .slashContinuation:
            return "↑↓ select · Enter accept · Esc cancel"
        case .slashSuggestions:
            return "↑↓ select · Enter accept · Esc cancel"
        case .approvalPrompt, .permissionPrompt, .modalChoice:
            return "↑↓ choose · Enter confirm · Esc cancel"
        case .transcript, .startup, .resumePicker, .pager, .opaqueTerminal:
            return "Terminal-owned interaction"
        }
    }
}

private struct PenggieRawTerminalPlaceholder: View {
    @EnvironmentObject private var session: PenggieSessionModel
    @Environment(\.penggieTheme) private var theme
    let isActive: Bool

    var body: some View {
        Group {
            if let ghosttySession = session.ghosttySession {
                PenggieGhosttyTerminalView(session: ghosttySession, isActive: isActive)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "terminal")
                        .font(.system(size: 34))
                        .foregroundStyle(.secondary)
                    Text("Raw Terminal")
                        .font(.system(size: 22, weight: .semibold))
                    Text("No active Codex session.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.terminalBackground)
    }
}
