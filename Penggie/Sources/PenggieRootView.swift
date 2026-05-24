import SwiftUI

struct PenggieRootView: View {
    @EnvironmentObject private var session: PenggieSessionModel

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
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
        .alert(item: $session.pendingConfirmation) { confirmation in
            Alert(
                title: Text(confirmation.title),
                message: Text(confirmation.message),
                primaryButton: .destructive(Text("Continue")) {
                    session.confirm(confirmation)
                },
                secondaryButton: .cancel {
                    session.cancelConfirmation()
                }
            )
        }
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
                Text("Welcome to Penggie")
                    .font(.system(size: 24, weight: .semibold))
                Text("Choose how to start.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }

            Button {
                session.startWithCodex()
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .medium))
                        .frame(width: 52, height: 52)
                        .foregroundStyle(.primary)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Start with Codex")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Use your local Codex CLI in Reading mode.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(width: 560)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor).opacity(0.7), lineWidth: 1)
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
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text(session.state == .checkingCodex ? "Checking Codex..." : "Starting Codex...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
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
    }
}

private struct PenggieSessionView: View {
    @EnvironmentObject private var session: PenggieSessionModel

    var body: some View {
        VStack(spacing: 0) {
            PenggieTopBar()

            Divider()

            if session.state == .terminal {
                PenggieRawTerminalPlaceholder()
            } else {
                PenggieReadingChatView()
            }
        }
    }
}

private struct PenggieTopBar: View {
    @EnvironmentObject private var session: PenggieSessionModel

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 22, height: 22)
                Text("Penggie")
                    .font(.system(size: 13, weight: .semibold))
            }

            Text("Codex")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(Capsule())

            Spacer()

            Picker("", selection: Binding(
                get: { session.state == .terminal ? "terminal" : "reading" },
                set: { value in
                    value == "terminal" ? session.switchToTerminal() : session.switchToReading()
                }
            )) {
                Text("Reading").tag("reading")
                Text("Terminal").tag("terminal")
            }
            .pickerStyle(.segmented)
            .frame(width: 176)

            Button {
                session.requestNewChat()
            } label: {
                Image(systemName: "plus")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .help("New Chat")

            Button {
                session.requestCloseSession()
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .help("Close Session")
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct PenggieReadingChatView: View {
    @EnvironmentObject private var session: PenggieSessionModel
    @State private var composerText = ""
    @State private var composerTextHeight: CGFloat = 58
    @State private var composerHasVisibleText = false
    @State private var nativeInteractionFocusRequestID = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            let visibleBlocks = PenggieReadingPresentation.visibleBlocks(
                from: session.readingBlocks,
                nativeInteractionIsActive: session.nativeInteractionIsActive
            )

            if visibleBlocks.isEmpty {
                Text("What should we work on in \(session.projectDisplayName)?")
                    .font(.system(size: 27, weight: .medium))
                    .foregroundStyle(.primary)
                    .padding(.bottom, 6)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(visibleBlocks) { block in
                            PenggieReadingBlockView(block: block)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                .frame(width: 760, height: 380)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor).opacity(0.65), lineWidth: 1)
                }
            }

            VStack(spacing: 0) {
                if session.nativeInteractionIsActive && !session.nativeInteractionRows.isEmpty {
                    PenggieNativeInteractionOverlay(rows: session.nativeInteractionRows)
                        .padding(.bottom, 10)
                }

                composerSurface

                HStack {
                    Button {
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.borderless)

                    Text("/ commands")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        submitComposer()
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 34, height: 34)
                            .foregroundStyle(.white)
                            .background(canSend ? Color.primary : Color.gray)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSend)
                }
                .padding(.top, 10)
            }
            .padding(14)
            .frame(width: 620)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.75), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.06), radius: 20, y: 12)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.18))
        .onChange(of: session.nativeInteractionIsActive) { _, isActive in
            if isActive {
                nativeInteractionFocusRequestID += 1
            }
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

        return !composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitComposer() {
        if session.nativeInteractionIsActive {
            _ = session.sendNativeInteractionEnter()
            nativeInteractionFocusRequestID += 1
            return
        }

        session.sendPrompt(composerText)
        composerText = ""
    }

    private func handleComposerTextChange(_ text: String) {
        guard PenggieComposerNativeTrigger.prefix(for: text) != nil,
              session.beginNativeInteraction(initialText: text) else {
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

private struct PenggieReadingBlockView: View {
    let block: PenggieReadingBlock

    var body: some View {
        if PenggieReadingPresentation.isUserPromptBlock(block) {
            HStack {
                Spacer(minLength: 60)
                Text(PenggieReadingPresentation.promptText(for: block))
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .textSelection(.enabled)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            Text(PenggieReadingPresentation.chatText(for: block))
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct PenggieNativeInteractionOverlay: View {
    let rows: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Spacer()
                Text("↑↓ select · Enter accept · Esc cancel")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    Text(row)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(nativeRowIsSelected(row) ? Color.black.opacity(0.08) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
            .padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.75), lineWidth: 1)
        }
    }

    private func nativeRowIsSelected(_ row: String) -> Bool {
        let trimmed = row.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix(">") || trimmed.hasPrefix("›") || trimmed.hasPrefix("●")
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
        .background(Color.black)
    }
}
