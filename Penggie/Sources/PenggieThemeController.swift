import AppKit
import SwiftUI

@MainActor
final class PenggieThemeController: ObservableObject {
    @Published private(set) var theme: PenggieTheme

    private var appearanceObserver: NSKeyValueObservation?

    init() {
        theme = PenggieTheme.resolved(for: NSApplication.shared.effectiveAppearance)
        appearanceObserver = NSApplication.shared.observe(
            \.effectiveAppearance,
             options: [.new]
        ) { [weak self] application, _ in
            Task { @MainActor in
                self?.theme = PenggieTheme.resolved(for: application.effectiveAppearance)
            }
        }
    }

    var terminalConfiguration: TerminalThemeConfiguration {
        theme.terminalConfiguration
    }
}

private struct PenggieThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = PenggieTheme.fallback
}

extension EnvironmentValues {
    var penggieTheme: PenggieTheme {
        get { self[PenggieThemeEnvironmentKey.self] }
        set { self[PenggieThemeEnvironmentKey.self] = newValue }
    }
}
