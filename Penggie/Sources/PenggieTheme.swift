import AppKit
import Foundation
import SwiftUI

struct PenggieTheme {
    let colorScheme: PenggieThemeColorScheme
    let primitives: PenggiePrimitivePalette
    let semantic: PenggieSemanticTheme
    let scenes: PenggieSceneTheme
    let components: PenggieComponentTheme

    var appBackground: Color { semantic.appBackground.color }
    var contentBackground: Color { scenes.reading.background.color }
    var surface: Color { scenes.reading.surface.color }
    var elevatedSurface: Color { scenes.reading.elevatedSurface.color }
    var separator: Color { semantic.separator.color }
    var quietSeparator: Color { semantic.quietSeparator.color }
    var secondaryText: Color { semantic.textSecondary.color }
    var selectedBackground: Color { components.nativeTuiOverlay.selectedBackground.color }
    var terminalBackground: Color { scenes.terminal.canvasBackground.color }
    var disabledAction: Color { semantic.textDisabled.color }
    var shadow: Color { semantic.shadow }
    var onAccent: Color { semantic.accentText.color }
    var accentColor: Color { semantic.accent.color }
    var accent: Color { semantic.accent.color }
    var primaryAccent: Color { semantic.accent.color }
    var terminalConfiguration: TerminalThemeConfiguration {
        TerminalThemeConfiguration(
            colorScheme: colorScheme.terminalColorScheme,
            windowTheme: "system",
            minimumContrast: 1.1,
            hostBackgroundColor: scenes.terminal.canvasBackground.nsColor,
            lightRendererTheme: Self.light.components.terminalRenderer.rendererThemeContents,
            darkRendererTheme: Self.dark.components.terminalRenderer.rendererThemeContents
        )
    }

    static let fallback = PenggieTheme.light

    static func resolved(for appearance: NSAppearance) -> PenggieTheme {
        appearance.isPenggieDark ? .dark : .light
    }

    static let light: PenggieTheme = {
        let primitives = PenggiePrimitivePalette.light
        let semantic = PenggieSemanticTheme(
            appBackground: primitives.neutral050,
            textPrimary: primitives.neutral900,
            textSecondary: primitives.neutral600,
            textMuted: primitives.neutral500,
            textDisabled: primitives.neutral400,
            separator: primitives.neutral250,
            quietSeparator: primitives.neutral200,
            accent: primitives.accent600,
            accentText: primitives.neutral025,
            warning: primitives.warning700,
            danger: primitives.danger600,
            focusRing: primitives.accent500,
            shadow: Color.black.opacity(0.08)
        )
        let reading = PenggieReadingSceneTheme(
            background: primitives.neutral050,
            surface: primitives.neutral100,
            elevatedSurface: primitives.neutral025
        )
        let terminal = TerminalSceneTheme.light
        let scenes = PenggieSceneTheme(reading: reading, terminal: terminal)

        return PenggieTheme(
            colorScheme: .light,
            primitives: primitives,
            semantic: semantic,
            scenes: scenes,
            components: PenggieComponentTheme(
                windowChrome: PenggieWindowChromeTheme(
                    reading: PenggieChromeTheme(
                        background: primitives.neutral050,
                        foreground: primitives.neutral600,
                        separator: primitives.neutral250,
                        hoverBackground: primitives.neutral100,
                        disabledForeground: primitives.neutral400,
                        focusRing: primitives.accent500
                    ),
                    terminal: PenggieChromeTheme(
                        background: terminal.chromeBackground,
                        foreground: terminal.mutedForeground,
                        separator: terminal.chromeSeparator,
                        hoverBackground: terminal.activeInputBackground,
                        disabledForeground: terminal.placeholderForeground,
                        focusRing: terminal.accentForeground
                    )
                ),
                readingComposer: PenggieReadingComposerTheme(
                    background: primitives.neutral025,
                    placeholder: primitives.neutral400,
                    focusRing: primitives.accent500
                ),
                nativeTuiOverlay: NativeTuiOverlayTheme(
                    background: terminal.canvasBackground,
                    rowForeground: terminal.foreground,
                    mutedForeground: terminal.mutedForeground,
                    selectedBackground: terminal.tuiSelectedRowBackground,
                    selectedForeground: terminal.tuiSelectedRowForeground,
                    separator: terminal.chromeSeparator
                ),
                terminalRenderer: .oneHalfLight
            )
        )
    }()

    static let dark: PenggieTheme = {
        let primitives = PenggiePrimitivePalette.dark
        let semantic = PenggieSemanticTheme(
            appBackground: primitives.neutral900,
            textPrimary: primitives.neutral100,
            textSecondary: primitives.neutral300,
            textMuted: primitives.neutral400,
            textDisabled: primitives.neutral500,
            separator: primitives.neutral700,
            quietSeparator: primitives.neutral800,
            accent: primitives.accent400,
            accentText: primitives.neutral950,
            warning: primitives.warning400,
            danger: primitives.danger400,
            focusRing: primitives.accent400,
            shadow: Color.black.opacity(0.24)
        )
        let reading = PenggieReadingSceneTheme(
            background: primitives.neutral900,
            surface: primitives.neutral800,
            elevatedSurface: primitives.neutral850
        )
        let terminal = TerminalSceneTheme.dark
        let scenes = PenggieSceneTheme(reading: reading, terminal: terminal)

        return PenggieTheme(
            colorScheme: .dark,
            primitives: primitives,
            semantic: semantic,
            scenes: scenes,
            components: PenggieComponentTheme(
                windowChrome: PenggieWindowChromeTheme(
                    reading: PenggieChromeTheme(
                        background: primitives.neutral900,
                        foreground: primitives.neutral300,
                        separator: primitives.neutral700,
                        hoverBackground: primitives.neutral800,
                        disabledForeground: primitives.neutral500,
                        focusRing: primitives.accent400
                    ),
                    terminal: PenggieChromeTheme(
                        background: terminal.chromeBackground,
                        foreground: terminal.mutedForeground,
                        separator: terminal.chromeSeparator,
                        hoverBackground: terminal.activeInputBackground,
                        disabledForeground: terminal.placeholderForeground,
                        focusRing: terminal.accentForeground
                    )
                ),
                readingComposer: PenggieReadingComposerTheme(
                    background: primitives.neutral850,
                    placeholder: primitives.neutral500,
                    focusRing: primitives.accent400
                ),
                nativeTuiOverlay: NativeTuiOverlayTheme(
                    background: terminal.canvasBackground,
                    rowForeground: terminal.foreground,
                    mutedForeground: terminal.mutedForeground,
                    selectedBackground: terminal.tuiSelectedRowBackground,
                    selectedForeground: terminal.tuiSelectedRowForeground,
                    separator: terminal.chromeSeparator
                ),
                terminalRenderer: .oneHalfDark
            )
        )
    }()
}

enum PenggieThemeColorScheme {
    case light
    case dark

    var terminalColorScheme: PenggieTerminalColorScheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum PenggieTerminalColorScheme {
    case light
    case dark
}

struct PenggieColorToken: Equatable {
    let hex: UInt32

    var color: Color {
        Color(nsColor: nsColor)
    }

    var nsColor: NSColor {
        NSColor(hex: hex)
    }

    var ghosttyHex: String {
        String(format: "#%06x", hex)
    }
}

struct PenggiePrimitivePalette {
    let neutral025: PenggieColorToken
    let neutral050: PenggieColorToken
    let neutral100: PenggieColorToken
    let neutral200: PenggieColorToken
    let neutral250: PenggieColorToken
    let neutral300: PenggieColorToken
    let neutral400: PenggieColorToken
    let neutral500: PenggieColorToken
    let neutral600: PenggieColorToken
    let neutral700: PenggieColorToken
    let neutral800: PenggieColorToken
    let neutral850: PenggieColorToken
    let neutral900: PenggieColorToken
    let neutral950: PenggieColorToken
    let accent400: PenggieColorToken
    let accent500: PenggieColorToken
    let accent600: PenggieColorToken
    let warning400: PenggieColorToken
    let warning700: PenggieColorToken
    let danger400: PenggieColorToken
    let danger600: PenggieColorToken

    static let light = PenggiePrimitivePalette(
        neutral025: PenggieColorToken(hex: 0xFBFCFE),
        neutral050: PenggieColorToken(hex: 0xF7F8FA),
        neutral100: PenggieColorToken(hex: 0xEAEEF4),
        neutral200: PenggieColorToken(hex: 0xE2E6ED),
        neutral250: PenggieColorToken(hex: 0xD7DBE2),
        neutral300: PenggieColorToken(hex: 0xB8C0CC),
        neutral400: PenggieColorToken(hex: 0x8A94A6),
        neutral500: PenggieColorToken(hex: 0x697386),
        neutral600: PenggieColorToken(hex: 0x525D70),
        neutral700: PenggieColorToken(hex: 0x3A4351),
        neutral800: PenggieColorToken(hex: 0x303744),
        neutral850: PenggieColorToken(hex: 0x2C333E),
        neutral900: PenggieColorToken(hex: 0x242933),
        neutral950: PenggieColorToken(hex: 0x111827),
        accent400: PenggieColorToken(hex: 0x3BA7D4),
        accent500: PenggieColorToken(hex: 0x168FC1),
        accent600: PenggieColorToken(hex: 0x087EA4),
        warning400: PenggieColorToken(hex: 0xE7C16B),
        warning700: PenggieColorToken(hex: 0x9A6700),
        danger400: PenggieColorToken(hex: 0xE06C75),
        danger600: PenggieColorToken(hex: 0xB4232E)
    )

    static let dark = PenggiePrimitivePalette(
        neutral025: PenggieColorToken(hex: 0xF6F8FB),
        neutral050: PenggieColorToken(hex: 0xF0F4FA),
        neutral100: PenggieColorToken(hex: 0xE7ECF3),
        neutral200: PenggieColorToken(hex: 0xDCE3EC),
        neutral250: PenggieColorToken(hex: 0xB8C7DA),
        neutral300: PenggieColorToken(hex: 0xA3B3CC),
        neutral400: PenggieColorToken(hex: 0x98A4B6),
        neutral500: PenggieColorToken(hex: 0x7F8A9C),
        neutral600: PenggieColorToken(hex: 0x5C6370),
        neutral700: PenggieColorToken(hex: 0x474E5D),
        neutral800: PenggieColorToken(hex: 0x363C48),
        neutral850: PenggieColorToken(hex: 0x303640),
        neutral900: PenggieColorToken(hex: 0x282C34),
        neutral950: PenggieColorToken(hex: 0x1F2530),
        accent400: PenggieColorToken(hex: 0x78DCE8),
        accent500: PenggieColorToken(hex: 0x56B6C2),
        accent600: PenggieColorToken(hex: 0x087EA4),
        warning400: PenggieColorToken(hex: 0xE7C16B),
        warning700: PenggieColorToken(hex: 0x9A6700),
        danger400: PenggieColorToken(hex: 0xE06C75),
        danger600: PenggieColorToken(hex: 0xB4232E)
    )
}

struct PenggieSemanticTheme {
    let appBackground: PenggieColorToken
    let textPrimary: PenggieColorToken
    let textSecondary: PenggieColorToken
    let textMuted: PenggieColorToken
    let textDisabled: PenggieColorToken
    let separator: PenggieColorToken
    let quietSeparator: PenggieColorToken
    let accent: PenggieColorToken
    let accentText: PenggieColorToken
    let warning: PenggieColorToken
    let danger: PenggieColorToken
    let focusRing: PenggieColorToken
    let shadow: Color
}

struct PenggieSceneTheme {
    let reading: PenggieReadingSceneTheme
    let terminal: TerminalSceneTheme
}

struct PenggieReadingSceneTheme {
    let background: PenggieColorToken
    let surface: PenggieColorToken
    let elevatedSurface: PenggieColorToken
}

struct TerminalSceneTheme {
    let canvasBackground: PenggieColorToken
    let chromeBackground: PenggieColorToken
    let chromeSeparator: PenggieColorToken
    let foreground: PenggieColorToken
    let mutedForeground: PenggieColorToken
    let placeholderForeground: PenggieColorToken
    let activeInputBackground: PenggieColorToken
    let activeInputForeground: PenggieColorToken
    let activeInputCursor: PenggieColorToken
    let tuiSelectedRowBackground: PenggieColorToken
    let tuiSelectedRowForeground: PenggieColorToken
    let textSelectionBackground: PenggieColorToken
    let textSelectionForeground: PenggieColorToken
    let warningForeground: PenggieColorToken
    let accentForeground: PenggieColorToken

    static let light = TerminalSceneTheme(
        canvasBackground: PenggieColorToken(hex: 0xFAFAFA),
        chromeBackground: PenggieColorToken(hex: 0xFAFAFA),
        chromeSeparator: PenggieColorToken(hex: 0xD7DBE2),
        foreground: PenggieColorToken(hex: 0x383A42),
        mutedForeground: PenggieColorToken(hex: 0x697386),
        placeholderForeground: PenggieColorToken(hex: 0x8A94A6),
        activeInputBackground: PenggieColorToken(hex: 0xEAEEF4),
        activeInputForeground: PenggieColorToken(hex: 0x383A42),
        activeInputCursor: PenggieColorToken(hex: 0xA5B4E5),
        tuiSelectedRowBackground: PenggieColorToken(hex: 0xDCEBFA),
        tuiSelectedRowForeground: PenggieColorToken(hex: 0x172235),
        textSelectionBackground: PenggieColorToken(hex: 0xBFCEFF),
        textSelectionForeground: PenggieColorToken(hex: 0x383A42),
        warningForeground: PenggieColorToken(hex: 0x9A6700),
        accentForeground: PenggieColorToken(hex: 0x087EA4)
    )

    static let dark = TerminalSceneTheme(
        canvasBackground: PenggieColorToken(hex: 0x282C34),
        chromeBackground: PenggieColorToken(hex: 0x282C34),
        chromeSeparator: PenggieColorToken(hex: 0x3A414D),
        foreground: PenggieColorToken(hex: 0xDCDFe4),
        mutedForeground: PenggieColorToken(hex: 0x98A4B6),
        placeholderForeground: PenggieColorToken(hex: 0x7F8A9C),
        activeInputBackground: PenggieColorToken(hex: 0x363C48),
        activeInputForeground: PenggieColorToken(hex: 0xE9ECF1),
        activeInputCursor: PenggieColorToken(hex: 0xA3B3CC),
        tuiSelectedRowBackground: PenggieColorToken(hex: 0x3F4754),
        tuiSelectedRowForeground: PenggieColorToken(hex: 0xF0F4FA),
        textSelectionBackground: PenggieColorToken(hex: 0x474E5D),
        textSelectionForeground: PenggieColorToken(hex: 0xDCDFe4),
        warningForeground: PenggieColorToken(hex: 0xE7C16B),
        accentForeground: PenggieColorToken(hex: 0x78DCE8)
    )
}

struct PenggieComponentTheme {
    let windowChrome: PenggieWindowChromeTheme
    let readingComposer: PenggieReadingComposerTheme
    let nativeTuiOverlay: NativeTuiOverlayTheme
    let terminalRenderer: TerminalRendererPalette
}

struct PenggieWindowChromeTheme {
    let reading: PenggieChromeTheme
    let terminal: PenggieChromeTheme
}

struct PenggieChromeTheme {
    let background: PenggieColorToken
    let foreground: PenggieColorToken
    let separator: PenggieColorToken
    let hoverBackground: PenggieColorToken
    let disabledForeground: PenggieColorToken
    let focusRing: PenggieColorToken
}

struct PenggieReadingComposerTheme {
    let background: PenggieColorToken
    let placeholder: PenggieColorToken
    let focusRing: PenggieColorToken
}

struct NativeTuiOverlayTheme {
    let background: PenggieColorToken
    let rowForeground: PenggieColorToken
    let mutedForeground: PenggieColorToken
    let selectedBackground: PenggieColorToken
    let selectedForeground: PenggieColorToken
    let separator: PenggieColorToken
}

struct TerminalAnsiPalette: Equatable {
    let colors: [PenggieColorToken]

    static let oneHalfLight = TerminalAnsiPalette(colors: [
        PenggieColorToken(hex: 0x383A42),
        PenggieColorToken(hex: 0xE45649),
        PenggieColorToken(hex: 0x50A14F),
        PenggieColorToken(hex: 0xC18401),
        PenggieColorToken(hex: 0x0184BC),
        PenggieColorToken(hex: 0xA626A4),
        PenggieColorToken(hex: 0x0997B3),
        PenggieColorToken(hex: 0xBABABA),
        PenggieColorToken(hex: 0x4F525E),
        PenggieColorToken(hex: 0xE06C75),
        PenggieColorToken(hex: 0x98C379),
        PenggieColorToken(hex: 0xD8B36E),
        PenggieColorToken(hex: 0x61AFEF),
        PenggieColorToken(hex: 0xC678DD),
        PenggieColorToken(hex: 0x56B6C2),
        PenggieColorToken(hex: 0xFFFFFF)
    ])

    static let oneHalfDark = TerminalAnsiPalette(colors: [
        PenggieColorToken(hex: 0x282C34),
        PenggieColorToken(hex: 0xE06C75),
        PenggieColorToken(hex: 0x98C379),
        PenggieColorToken(hex: 0xE5C07B),
        PenggieColorToken(hex: 0x61AFEF),
        PenggieColorToken(hex: 0xC678DD),
        PenggieColorToken(hex: 0x56B6C2),
        PenggieColorToken(hex: 0xDCDFe4),
        PenggieColorToken(hex: 0x5D677A),
        PenggieColorToken(hex: 0xE06C75),
        PenggieColorToken(hex: 0x98C379),
        PenggieColorToken(hex: 0xE5C07B),
        PenggieColorToken(hex: 0x61AFEF),
        PenggieColorToken(hex: 0xC678DD),
        PenggieColorToken(hex: 0x56B6C2),
        PenggieColorToken(hex: 0xDCDFe4)
    ])
}

struct TerminalRendererPalette: Equatable {
    let background: PenggieColorToken
    let foreground: PenggieColorToken
    let cursorColor: PenggieColorToken
    let cursorText: PenggieColorToken
    let selectionBackground: PenggieColorToken
    let selectionForeground: PenggieColorToken
    let embeddedControlBackgroundSource: PenggieColorToken
    let embeddedControlBackgroundTarget: PenggieColorToken
    let ansiPalette: TerminalAnsiPalette

    static let oneHalfLight = TerminalRendererPalette(
        background: PenggieColorToken(hex: 0xFAFAFA),
        foreground: PenggieColorToken(hex: 0x383A42),
        cursorColor: PenggieColorToken(hex: 0xA5B4E5),
        cursorText: PenggieColorToken(hex: 0x383A42),
        selectionBackground: PenggieColorToken(hex: 0xBFCEFF),
        selectionForeground: PenggieColorToken(hex: 0x383A42),
        embeddedControlBackgroundSource: PenggieColorToken(hex: 0xF0F0F0),
        embeddedControlBackgroundTarget: PenggieColorToken(hex: 0xEAEEF4),
        ansiPalette: .oneHalfLight
    )

    static let oneHalfDark = TerminalRendererPalette(
        background: PenggieColorToken(hex: 0x282C34),
        foreground: PenggieColorToken(hex: 0xDCDFe4),
        cursorColor: PenggieColorToken(hex: 0xA3B3CC),
        cursorText: PenggieColorToken(hex: 0xE9ECF1),
        selectionBackground: PenggieColorToken(hex: 0x474E5D),
        selectionForeground: PenggieColorToken(hex: 0xDCDFe4),
        embeddedControlBackgroundSource: PenggieColorToken(hex: 0xF0F0F0),
        embeddedControlBackgroundTarget: PenggieColorToken(hex: 0x363C48),
        ansiPalette: .oneHalfDark
    )

    var rendererThemeContents: String {
        var lines = ansiPalette.colors.enumerated().map { index, color in
            "palette = \(index)=\(color.ghosttyHex)"
        }
        lines.append("background = \(background.ghosttyHex)")
        lines.append("foreground = \(foreground.ghosttyHex)")
        lines.append("cursor-color = \(cursorColor.ghosttyHex)")
        lines.append("cursor-text = \(cursorText.ghosttyHex)")
        lines.append("selection-background = \(selectionBackground.ghosttyHex)")
        lines.append("selection-foreground = \(selectionForeground.ghosttyHex)")
        lines.append("penggie-embedded-control-background-source = \(embeddedControlBackgroundSource.ghosttyHex)")
        lines.append("penggie-embedded-control-background-target = \(embeddedControlBackgroundTarget.ghosttyHex)")
        return lines.joined(separator: "\n") + "\n"
    }
}

struct TerminalThemeConfiguration {
    let colorScheme: PenggieTerminalColorScheme
    let windowTheme: String
    let minimumContrast: Double
    let hostBackgroundColor: NSColor
    let lightRendererTheme: String
    let darkRendererTheme: String

    static let fallback = PenggieTheme.fallback.terminalConfiguration

    func ghosttyConfigContents(lightThemePath: String, darkThemePath: String) -> String {
        """
        theme = light:\(lightThemePath),dark:\(darkThemePath)
        window-theme = \(windowTheme)
        minimum-contrast = \(minimumContrast)
        """
    }
}

#if DEBUG
extension PenggieTerminalColorScheme {
    var debugName: String {
        switch self {
        case .light:
            return "light"
        case .dark:
            return "dark"
        }
    }
}

extension TerminalThemeConfiguration {
    var debugPaletteSummary: String {
        [
            "scheme=\(colorScheme.debugName)",
            "lightChecksum=\(Self.stableChecksum(lightRendererTheme))",
            "darkChecksum=\(Self.stableChecksum(darkRendererTheme))",
            "light{\(Self.importantRendererLines(in: lightRendererTheme))}",
            "dark{\(Self.importantRendererLines(in: darkRendererTheme))}"
        ].joined(separator: " ")
    }

    private static func importantRendererLines(in contents: String) -> String {
        let importantPrefixes = [
            "background =",
            "foreground =",
            "cursor-color =",
            "selection-background =",
            "penggie-embedded-control-background-source =",
            "penggie-embedded-control-background-target =",
            "palette = 0=",
            "palette = 7=",
            "palette = 8=",
            "palette = 15="
        ]

        return contents
            .split(separator: "\n")
            .map(String.init)
            .filter { line in
                importantPrefixes.contains { line.hasPrefix($0) }
            }
            .joined(separator: ",")
    }

    private static func stableChecksum(_ contents: String) -> String {
        let hash = contents.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { partial, byte in
            (partial ^ UInt64(byte)) &* 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }
}
#endif

private extension NSAppearance {
    var isPenggieDark: Bool {
        name.rawValue.lowercased().contains("dark")
    }
}

private extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            calibratedRed: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: 1
        )
    }
}
