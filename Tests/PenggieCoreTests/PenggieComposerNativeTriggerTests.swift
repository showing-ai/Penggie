import Testing
@testable import PenggieCore

@Suite
struct PenggieComposerNativeTriggerTests {
    @Test
    func slashStartsNativeInteraction() {
        #expect(PenggieComposerNativeTrigger.prefix(for: "/") == "/")
        #expect(PenggieComposerNativeTrigger.prefix(for: "/m") == "/")
    }

    @Test
    func dollarRequiresCodexCapability() {
        #expect(PenggieComposerNativeTrigger.prefix(for: "$") == nil)
        #expect(PenggieComposerNativeTrigger.prefix(for: "$", canUseCodexDollarCommand: true) == "$")
        #expect(PenggieComposerNativeTrigger.prefix(for: "$memory", canUseCodexDollarCommand: true) == "$")
    }

    @Test
    func firstKeyTriggerRequiresEmptyUnmarkedComposer() {
        #expect(PenggieComposerNativeTrigger.prefixForFirstKeyCharacters("/", existingText: "", hasMarkedText: false) == "/")
        #expect(PenggieComposerNativeTrigger.prefixForFirstKeyCharacters("/", existingText: "x", hasMarkedText: false) == nil)
        #expect(PenggieComposerNativeTrigger.prefixForFirstKeyCharacters("/", existingText: "", hasMarkedText: true) == nil)
        #expect(PenggieComposerNativeTrigger.prefixForFirstKeyCharacters("/m", existingText: "", hasMarkedText: false) == nil)
    }

    @Test
    func markedTextCountsAsVisibleComposerText() {
        #expect(PenggieComposerNativeTrigger.hasVisibleComposerText(string: "", hasMarkedText: false) == false)
        #expect(PenggieComposerNativeTrigger.hasVisibleComposerText(string: "", hasMarkedText: true) == true)
        #expect(PenggieComposerNativeTrigger.hasVisibleComposerText(string: "hello", hasMarkedText: false) == true)
    }
}
