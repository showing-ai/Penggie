import SwiftUI
import GhosttyKit
import os

/// This delegate is notified of actions and property changes regarding the terminal view. This
/// delegate is optional and can be used by a TerminalView caller to react to changes such as
/// titles being set, cell sizes being changed, etc.
protocol TerminalViewDelegate: AnyObject {
    /// Called when the currently focused surface changed. This can be nil.
    func focusedSurfaceDidChange(to: Ghostty.SurfaceView?)

    /// The URL of the pwd should change.
    func pwdDidChange(to: URL?)

    /// The cell size changed.
    func cellSizeDidChange(to: NSSize)

    /// Perform an action. At the time of writing this is only triggered by the command palette.
    func performAction(_ action: String, on: Ghostty.SurfaceView)

    /// A split tree operation
    func performSplitAction(_ action: TerminalSplitOperation)
}

/// The view model is a required implementation for TerminalView callers. This contains
/// the main state between the TerminalView caller and SwiftUI. This abstraction is what
/// allows AppKit to own most of the data in SwiftUI.
protocol TerminalViewModel: ObservableObject {
    /// The tree of terminal surfaces (splits) within the view. This is mutated by TerminalView
    /// and children. This should be @Published.
    var surfaceTree: SplitTree<Ghostty.SurfaceView> { get set }

    /// The command palette state.
    var commandPaletteIsShowing: Bool { get set }

    /// The update overlay should be visible.
    var updateOverlayIsVisible: Bool { get }
}

/// The main terminal view. This terminal view supports splits.
struct TerminalView<ViewModel: TerminalViewModel>: View {
    @ObservedObject var ghostty: Ghostty.App

    // The required view model
    @ObservedObject var viewModel: ViewModel

    // An optional delegate to receive information about terminal changes.
    weak var delegate: (any TerminalViewDelegate)?

    /// The most recently focused surface, equal to `focusedSurface` when it is non-nil.
    @State private var lastFocusedSurface: Weak<Ghostty.SurfaceView>?

    @StateObject private var showCLIController = ShowCLICurrentSessionController()

    // This seems like a crutch after switching from SwiftUI to AppKit lifecycle.
    @FocusState private var focused: Bool

    // Various state values sent back up from the currently focused terminals.
    @FocusedValue(\.ghosttySurfaceView) private var focusedSurface
    @FocusedValue(\.ghosttySurfacePwd) private var surfacePwd
    @FocusedValue(\.ghosttySurfaceCellSize) private var cellSize

    // The pwd of the focused surface as a URL
    private var pwdURL: URL? {
        guard let surfacePwd, surfacePwd != "" else { return nil }
        return URL(fileURLWithPath: surfacePwd)
    }

    var body: some View {
        switch ghostty.readiness {
        case .loading:
            Text("Loading")
        case .error:
            ErrorView()
        case .ready:
            ZStack {
                VStack(spacing: 0) {
                    // If we're running in debug mode we show a warning so that users
                    // know that performance will be degraded.
                    if Ghostty.info.mode == GHOSTTY_BUILD_MODE_DEBUG || Ghostty.info.mode == GHOSTTY_BUILD_MODE_RELEASE_SAFE {
                        DebugBuildWarningView()
                    }

                    TerminalSplitTreeView(
                        tree: viewModel.surfaceTree,
                        action: { delegate?.performSplitAction($0) })
                        .environmentObject(ghostty)
                        .ghosttyLastFocusedSurface(lastFocusedSurface)
                        .focused($focused)
                        .onAppear { self.focused = true }
                        .onChange(of: focusedSurface) { newValue in
                            // We want to keep track of our last focused surface so even if
                            // we lose focus we keep this set to the last non-nil value.
                            if newValue != nil {
                                lastFocusedSurface = .init(newValue)
                                showCLIController.updateSurface(newValue)
                                self.delegate?.focusedSurfaceDidChange(to: newValue)
                            }
                        }
                        .onChange(of: pwdURL) { newValue in
                            self.delegate?.pwdDidChange(to: newValue)
                        }
                        .onChange(of: cellSize) { newValue in
                            guard let size = newValue else { return }
                            self.delegate?.cellSizeDidChange(to: size)
                        }
                        .frame(idealWidth: lastFocusedSurface?.value?.initialSize?.width,
                               idealHeight: lastFocusedSurface?.value?.initialSize?.height)
                }
                // Ignore safe area to extend up in to the titlebar region if we have the "hidden" titlebar style
                .ignoresSafeArea(.container, edges: ghostty.config.macosTitlebarStyle == .hidden ? .top : [])
                .opacity(showCLIController.activeMode == .terminal && !showCLIController.showsAgentPicker ? 1 : 0)
                .allowsHitTesting(showCLIController.activeMode == .terminal && !showCLIController.showsAgentPicker)
                .accessibilityHidden(showCLIController.activeMode != .terminal || showCLIController.showsAgentPicker)

                if showCLIController.showsAgentPicker {
                    ShowCLIAgentPickerView(controller: showCLIController)
                } else if showCLIController.activeMode == .reading {
                    ShowCLIReadingModeView(controller: showCLIController)
                }

                if showCLIController.activeMode == .terminal,
                   !showCLIController.showsAgentPicker,
                   let surfaceView = lastFocusedSurface?.value {
                    TerminalCommandPaletteView(
                        surfaceView: surfaceView,
                        isPresented: $viewModel.commandPaletteIsShowing,
                        ghosttyConfig: ghostty.config,
                        updateViewModel: (NSApp.delegate as? AppDelegate)?.updateViewModel) { action in
                        self.delegate?.performAction(action, on: surfaceView)
                    }
                }

                // Show update information above all else.
                if showCLIController.activeMode == .terminal &&
                    !showCLIController.showsAgentPicker &&
                    viewModel.updateOverlayIsVisible {
                    UpdateOverlay()
                }
            }
            .frame(maxWidth: .greatestFiniteMagnitude, maxHeight: .greatestFiniteMagnitude)
            .onChange(of: showCLIController.activeMode) { mode in
                focused = mode == .terminal && !showCLIController.showsAgentPicker
            }
            .onChange(of: showCLIController.showsAgentPicker) { showsAgentPicker in
                focused = showCLIController.activeMode == .terminal && !showsAgentPicker
            }
            .onReceive(NotificationCenter.default.publisher(for: .showCLIActiveModeDidChange)) { notification in
                showCLIController.switchMode(from: notification)
            }
        }
    }
}

private struct ShowCLIAgentPickerView: View {
    @ObservedObject var controller: ShowCLICurrentSessionController

    private var agentPresets: [ShowCLIAgentPreset] {
        ShowCLIAgentPreset.allCases.filter { !$0.isShellFallback }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 80)

            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image("AppIconImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 56, height: 56)
                        .accessibilityHidden(true)

                    VStack(spacing: 6) {
                        Text("Welcome to ShowCLI")
                            .font(.system(size: 24, weight: .semibold))

                        Text("Choose a local Agent CLI to start.")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(spacing: 12) {
                    ForEach(agentPresets) { preset in
                        presetRow(preset)
                    }
                }
                .frame(width: 560)

                HStack(spacing: 12) {
                    Button {
                        controller.refreshAgentAvailability()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(controller.isCheckingAgentAvailability)

                    Button {
                        controller.startPreset(.shell)
                    } label: {
                        Label("Open Shell", systemImage: "terminal")
                    }
                    .disabled(!controller.hasCurrentSurface)
                }
                .controlSize(.large)

                if !controller.hasCurrentSurface {
                    Text("Starting local terminal...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            controller.refreshAgentAvailability()
        }
    }

    private func presetRow(_ preset: ShowCLIAgentPreset) -> some View {
        let available = controller.isPresetAvailable(preset)

        return Button {
            controller.startPreset(preset)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: preset.systemImageName)
                    .font(.system(size: 22, weight: .medium))
                    .frame(width: 48, height: 48)
                    .foregroundStyle(available ? Color.primary : Color.secondary)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(preset.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(available ? Color.primary : Color.secondary)

                        if let command = preset.command {
                            Text(command)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(nsColor: .textBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    }

                    Text(preset.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(rowStatus(for: preset, available: available))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(available ? Color.accentColor : Color.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.65), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!available || !controller.hasCurrentSurface)
        .opacity(available ? 1 : 0.5)
        .help(available ? "Launch \(preset.title)" : "\(preset.title) is not installed")
    }

    private func rowStatus(for preset: ShowCLIAgentPreset, available: Bool) -> String {
        if controller.isCheckingAgentAvailability {
            return "Checking"
        }

        return available ? "Installed" : "Not installed"
    }
}

private struct UpdateOverlay: View {
    var body: some View {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            VStack {
                Spacer()

                HStack {
                    Spacer()
                    UpdatePill(model: appDelegate.updateViewModel)
                        .padding(.bottom, 9)
                        .padding(.trailing, 9)
                }
            }
        }
    }
}

struct DebugBuildWarningView: View {
    @State private var isPopover = false

    private var appDisplayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
            Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ??
            "ShowCLI"
    }

    var body: some View {
        HStack {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)

            Text("You're running a debug build of \(appDisplayName)! Performance will be degraded.")
                .padding(.all, 8)
                .popover(isPresented: $isPopover, arrowEdge: .bottom) {
                    Text("""
                    Debug builds of \(appDisplayName) are very slow and you may experience
                    performance problems. Debug builds are only recommended during
                    development.
                    """)
                    .padding(.all)
                }

            Spacer()
        }
        .background(Color(.windowBackgroundColor))
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Debug build warning")
        .accessibilityValue("Debug builds of \(appDisplayName) are very slow and you may experience performance problems. Debug builds are only recommended during development.")
        .accessibilityAddTraits(.isStaticText)
        .onTapGesture {
            isPopover = true
        }
    }
}
