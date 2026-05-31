import Testing
@testable import PenggieCore

@Suite
struct PenggieThemeTests {
    @Test
    func lightTerminalRendererUsesCompleteOneHalfPaletteContract() {
        let renderer = PenggieTheme.light.components.terminalRenderer

        #expect(renderer.ansiPalette.colors.count == 16)
        #expect(renderer.background.ghosttyHex == "#fafafa")
        #expect(renderer.foreground.ghosttyHex == "#383a42")
        #expect(renderer.ansiPalette.colors[0].ghosttyHex == "#383a42")
        #expect(renderer.ansiPalette.colors[15].ghosttyHex == "#ffffff")
        #expect(renderer.ansiPalette.colors[15] != renderer.foreground)
        #expect(renderer.selectionBackground == PenggieTheme.light.scenes.terminal.textSelectionBackground)
        #expect(renderer.selectionForeground == PenggieTheme.light.scenes.terminal.textSelectionForeground)
        #expect(renderer.selectionBackground != PenggieTheme.light.scenes.terminal.activeInputBackground)
        #expect(renderer.embeddedControlBackgroundSource.ghosttyHex == "#f0f0f0")
        #expect(renderer.embeddedControlBackgroundTarget == PenggieTheme.light.scenes.terminal.activeInputBackground)
    }

    @Test
    func darkTerminalRendererUsesCompleteOneHalfPaletteContract() {
        let renderer = PenggieTheme.dark.components.terminalRenderer

        #expect(renderer.ansiPalette.colors.count == 16)
        #expect(renderer.background.ghosttyHex == "#282c34")
        #expect(renderer.foreground.ghosttyHex == "#dcdfe4")
        #expect(renderer.ansiPalette.colors[0].ghosttyHex == "#282c34")
        #expect(renderer.ansiPalette.colors[15].ghosttyHex == "#dcdfe4")
        #expect(renderer.selectionBackground == PenggieTheme.dark.scenes.terminal.textSelectionBackground)
        #expect(renderer.selectionForeground == PenggieTheme.dark.scenes.terminal.textSelectionForeground)
        #expect(renderer.selectionBackground != PenggieTheme.dark.scenes.terminal.activeInputBackground)
        #expect(renderer.embeddedControlBackgroundSource.ghosttyHex == "#f0f0f0")
        #expect(renderer.embeddedControlBackgroundTarget == PenggieTheme.dark.scenes.terminal.activeInputBackground)
    }

    @Test
    func generatedGhosttyLightThemeMatchesRendererPresetSnapshot() {
        #expect(TerminalRendererPalette.oneHalfLight.rendererThemeContents == """
        palette = 0=#383a42
        palette = 1=#e45649
        palette = 2=#50a14f
        palette = 3=#c18401
        palette = 4=#0184bc
        palette = 5=#a626a4
        palette = 6=#0997b3
        palette = 7=#bababa
        palette = 8=#4f525e
        palette = 9=#e06c75
        palette = 10=#98c379
        palette = 11=#d8b36e
        palette = 12=#61afef
        palette = 13=#c678dd
        palette = 14=#56b6c2
        palette = 15=#ffffff
        background = #fafafa
        foreground = #383a42
        cursor-color = #a5b4e5
        cursor-text = #383a42
        selection-background = #bfceff
        selection-foreground = #383a42
        penggie-embedded-control-background-source = #f0f0f0
        penggie-embedded-control-background-target = #eaeef4

        """)
    }

    @Test
    func generatedGhosttyDarkThemeMatchesRendererPresetSnapshot() {
        #expect(TerminalRendererPalette.oneHalfDark.rendererThemeContents == """
        palette = 0=#282c34
        palette = 1=#e06c75
        palette = 2=#98c379
        palette = 3=#e5c07b
        palette = 4=#61afef
        palette = 5=#c678dd
        palette = 6=#56b6c2
        palette = 7=#dcdfe4
        palette = 8=#5d677a
        palette = 9=#e06c75
        palette = 10=#98c379
        palette = 11=#e5c07b
        palette = 12=#61afef
        palette = 13=#c678dd
        palette = 14=#56b6c2
        palette = 15=#dcdfe4
        background = #282c34
        foreground = #dcdfe4
        cursor-color = #a3b3cc
        cursor-text = #e9ecf1
        selection-background = #474e5d
        selection-foreground = #dcdfe4
        penggie-embedded-control-background-source = #f0f0f0
        penggie-embedded-control-background-target = #363c48

        """)
    }
}
