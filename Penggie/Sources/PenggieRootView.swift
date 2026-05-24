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

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if session.transcriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("What should we work on in \(session.projectDisplayName)?")
                    .font(.system(size: 27, weight: .medium))
                    .foregroundStyle(.primary)
                    .padding(.bottom, 6)
            } else {
                ScrollView {
                    Text(session.transcriptText)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                TextEditor(text: $composerText)
                    .font(.system(size: 14))
                    .scrollContentBackground(.hidden)
                    .frame(height: 58)
                    .overlay(alignment: .topLeading) {
                        if composerText.isEmpty {
                            Text("Ask Codex anything")
                                .font(.system(size: 14))
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }

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
                        session.sendPrompt(composerText)
                        composerText = ""
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 34, height: 34)
                            .foregroundStyle(.white)
                            .background(composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.primary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
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
