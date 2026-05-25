import SwiftUI

private enum PenggieTheme {
    static let appBackground = Color(nsColor: .windowBackgroundColor)
    static let contentBackground = Color(nsColor: .textBackgroundColor)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let elevatedSurface = Color(nsColor: .textBackgroundColor)
    static let separator = Color(nsColor: .separatorColor).opacity(0.6)
    static let quietSeparator = Color(nsColor: .separatorColor).opacity(0.32)
    static let secondaryText = Color(nsColor: .secondaryLabelColor)
    static let accent = Color.accentColor
    static let accentSoft = Color.accentColor.opacity(0.12)
    static let selectedBackground = Color.accentColor.opacity(0.16)
    static let terminalBackground = Color(nsColor: NSColor(calibratedRed: 0.055, green: 0.058, blue: 0.065, alpha: 1))
    static let disabledAction = Color(nsColor: .tertiaryLabelColor).opacity(0.44)
    static let shadow = Color(nsColor: .shadowColor).opacity(0.08)
    static let onAccent = Color(nsColor: .selectedMenuItemTextColor)
}

struct PenggieRootView: View {
    @EnvironmentObject private var session: PenggieSessionModel

    var body: some View {
        ZStack {
            PenggieTheme.appBackground
                .ignoresSafeArea()

            switch session.state {
            case .idle, .closed:
                PenggieStartView()
            case .checkingCodex, .launching:
                PenggieProgressView()
            case .codexMissing:
                PenggieErrorStateView(
                    title: "Codex CLI not found",
                    message: "Install Codex CLI or make sure it is available in your login shell PATH.",
                    primaryActionTitle: "Check Again",
                    primaryAction: session.startWithCodex
                )
            case .launchFailed(let message):
                PenggieErrorStateView(
                    title: "Codex failed to launch",
                    message: message,
                    primaryActionTitle: "Try Again",
                    primaryAction: session.startWithCodex
                )
            case .exited:
                PenggieErrorStateView(
                    title: "Codex session ended",
                    message: "The Codex process exited. You can start a fresh chat or inspect the raw terminal state.",
                    primaryActionTitle: "Start Again",
                    primaryAction: session.startWithCodex
                )
            case .reading, .terminal:
                PenggieSessionView()
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

private struct PenggieStartView: View {
    @EnvironmentObject private var session: PenggieSessionModel

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 80)

            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 58, height: 58)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Start a local Codex session")
                    .font(.system(size: 24, weight: .semibold))
                Text("Penggie opens Reading first. Raw Terminal stays available as a fallback.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }

            Button {
                session.startWithCodex()
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "terminal")
                        .font(.system(size: 22, weight: .medium))
                        .frame(width: 52, height: 52)
                        .foregroundStyle(.primary)
                        .background(PenggieTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Start with Codex")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Use the Codex CLI from your login shell.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: 560)
                .background(PenggieTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(PenggieTheme.separator, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 100)
        }
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
                Text(session.state == .checkingCodex ? "Looking in your login shell PATH." : "Preparing Reading with the active Ghostty PTY.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
        .frame(maxWidth: 380)
    }
}

private struct PenggieErrorStateView: View {
    let title: String
    let message: String
    let primaryActionTitle: String
    let primaryAction: () -> Void

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

            Button(primaryActionTitle, action: primaryAction)
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(maxWidth: 520)
        .background(PenggieTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(PenggieTheme.quietSeparator, lineWidth: 1)
        }
    }
}

private struct PenggieSessionView: View {
    @EnvironmentObject private var session: PenggieSessionModel

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if session.state == .terminal {
                    PenggieRawTerminalPlaceholder()
                } else {
                    PenggieReadingChatView()
                }
            }
            .padding(.top, PenggieChromeMetrics.height)

            PenggieWindowChrome()
        }
        .ignoresSafeArea(.container, edges: .top)
    }
}

private enum PenggieChromeMetrics {
    static let height: CGFloat = 52
    static let trafficLightSafeArea: CGFloat = 84
}

private struct PenggieWindowChrome: View {
    @EnvironmentObject private var session: PenggieSessionModel

    var body: some View {
        HStack(spacing: 12) {
            Color.clear
                .frame(width: PenggieChromeMetrics.trafficLightSafeArea)

            HStack(spacing: 8) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 22, height: 22)
                Text("Penggie")
                    .font(.system(size: 14, weight: .semibold))
            }

            Text("Codex")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            PenggieModeToggleButton()

            PenggieChromeIconButton(systemName: "plus", label: "New Chat") {
                session.requestNewChat()
            }

            PenggieChromeIconButton(systemName: "xmark", label: "Close Session") {
                session.requestCloseSession()
            }
        }
        .padding(.trailing, 18)
        .frame(height: PenggieChromeMetrics.height)
        .background(PenggieTheme.appBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PenggieTheme.quietSeparator)
                .frame(height: 1)
        }
    }
}

private struct PenggieModeToggleButton: View {
    @EnvironmentObject private var session: PenggieSessionModel

    var body: some View {
        if session.state == .terminal {
            PenggieChromeIconButton(systemName: "text.alignleft", label: "Show Reading") {
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
                .font(.system(size: 15, weight: .medium))
                .frame(width: 44, height: 36)
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

    let isHovering: Bool
    let isFocused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? PenggieTheme.secondaryText : PenggieTheme.disabledAction)
            .background(background(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(isFocused ? PenggieTheme.accent.opacity(0.58) : Color.clear, lineWidth: 2)
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
            return PenggieTheme.selectedBackground
        }

        if isHovering || isFocused {
            return PenggieTheme.surface
        }

        return Color.clear
    }
}

private struct PenggieReadingChatView: View {
    @EnvironmentObject private var session: PenggieSessionModel
    @State private var composerText = ""
    @State private var composerTextHeight: CGFloat = 58
    @State private var composerHasVisibleText = false
    @State private var nativeInteractionFocusRequestID = 0

    var body: some View {
        GeometryReader { geometry in
            let visibleItems = PenggieReadingPresentation.visibleItems(
                from: session.readingBlocks,
                nativeInteractionIsActive: session.nativeInteractionIsActive
            )
            let contentWidth = contentWidth(for: geometry.size.width)

            VStack(spacing: 0) {
                if visibleItems.isEmpty {
                    emptyState(contentWidth: contentWidth)
                } else {
                    transcriptContent(items: visibleItems, contentWidth: contentWidth)
                    composerStack(contentWidth: contentWidth)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 28)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PenggieTheme.contentBackground)
        .onChange(of: session.nativeInteractionIsActive) { _, isActive in
            if isActive {
                nativeInteractionFocusRequestID += 1
            }
        }
    }

    private func contentWidth(for availableWidth: CGFloat) -> CGFloat {
        let reservedHorizontalInset: CGFloat = 56
        return max(1, min(880, availableWidth - reservedHorizontalInset))
    }

    private func emptyState(contentWidth: CGFloat) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Text("What should we work on in \(session.projectDisplayName)?")
                .font(.system(size: 27, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: contentWidth)

            composerStack(contentWidth: contentWidth)

            Spacer(minLength: 96)
        }
        .padding(.horizontal, 28)
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

    private func composerStack(contentWidth: CGFloat) -> some View {
        let composerWidth = min(contentWidth, 720)

        return VStack(spacing: 0) {
            if session.nativeInteractionIsActive && !session.nativeInteractionRows.isEmpty {
                PenggieNativeInteractionOverlay(rows: session.nativeInteractionRows)
                    .padding(.bottom, 8)
            }

            composerSurface

            HStack(spacing: 12) {
                Button {
                    beginSlashCommand()
                } label: {
                    HStack(spacing: 6) {
                        Text("/")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        Text("commands")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                    .frame(height: 30)
                    .padding(.horizontal, 2)
                }
                .buttonStyle(.plain)
                .disabled(session.nativeInteractionIsActive)
                .accessibilityLabel("Open Commands")
                .help("Open Commands")

                Spacer()

                Button {
                    submitComposer()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 38, height: 38)
                        .foregroundStyle(canSend ? PenggieTheme.onAccent : PenggieTheme.secondaryText)
                        .background(canSend ? PenggieTheme.accent : PenggieTheme.surface)
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
        .background(PenggieTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(PenggieTheme.quietSeparator, lineWidth: 1)
        }
        .shadow(color: PenggieTheme.shadow, radius: 14, y: 8)
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
                        shouldFocus: true,
                        isEnabled: session.nativeInteractionPhase.acceptsInput,
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
                        isEnabled: session.isRunning,
                        shouldFocus: true,
                        minHeight: 58,
                        maxHeight: 140,
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
            return true
        }

        return session.canSubmitPrompt && !composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitComposer() {
        if session.nativeInteractionIsActive {
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

    private func beginSlashCommand() {
        guard !session.nativeInteractionIsActive,
              session.beginNativeInteraction(prefix: "/") else {
            return
        }

        composerText = ""
        nativeInteractionFocusRequestID += 1
    }

    private func handleNativeInteractionCommand(_ command: PenggieInteractionCommand) -> Bool {
        let sent: Bool
        if command == .escape {
            sent = session.cancelNativeInteraction()
        } else {
            sent = session.sendNativeInteractionCommand(command)
        }

        if session.nativeInteractionIsActive {
            nativeInteractionFocusRequestID += 1
        }

        return sent
    }

    private func handleNativeInteractionText(_ text: String) -> Bool {
        let sent = session.sendNativeInteractionText(text)
        if sent {
            nativeInteractionFocusRequestID += 1
        }
        return sent
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
    let block: PenggieReadingBlock

    var body: some View {
        if PenggieReadingPresentation.isUserPromptBlock(block) {
            HStack {
                Spacer(minLength: 60)
                Text(PenggieReadingPresentation.promptText(for: block))
                    .font(.system(size: 14))
                    .foregroundStyle(PenggieTheme.onAccent)
                    .textSelection(.enabled)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(PenggieTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        } else if PenggieReadingPresentation.isToolChromeBlock(block) {
            Text(PenggieReadingPresentation.terminalText(for: block))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(PenggieTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            Text(PenggieReadingPresentation.chatText(for: block))
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct PenggieReadingDisclosureView: View {
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
                .foregroundStyle(PenggieTheme.secondaryText)
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
                    .textSelection(.enabled)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(PenggieTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PenggieNativeInteractionOverlay: View {
    let rows: [PenggieNativeInteractionLine]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                Text("↑↓ select · Enter accept · Esc cancel")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    nativeInteractionRowView(row)
                }
            }
        }
        .padding(10)
        .background(PenggieTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(PenggieTheme.quietSeparator, lineWidth: 1)
        }
    }

    private func nativeInteractionRowView(_ row: PenggieNativeInteractionLine) -> some View {
        let foreground = row.isSelected ? Color.primary : Color.primary.opacity(0.9)
        let background = row.isSelected ? PenggieTheme.selectedBackground : Color.clear

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

private struct PenggieRawTerminalPlaceholder: View {
    @EnvironmentObject private var session: PenggieSessionModel

    var body: some View {
        Group {
            if let ghosttySession = session.ghosttySession {
                PenggieGhosttyTerminalView(session: ghosttySession)
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
        .background(PenggieTheme.terminalBackground)
    }
}
