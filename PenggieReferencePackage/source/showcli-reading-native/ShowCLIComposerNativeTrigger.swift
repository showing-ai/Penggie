#if os(macOS)
import Foundation

enum ShowCLIComposerNativeTrigger {
    static func prefix(
        for text: String,
        canUseCodexDollarCommand: Bool
    ) -> String? {
        guard let firstCharacter = text.first else { return nil }

        switch firstCharacter {
        case "/":
            return "/"
        case "$":
            return canUseCodexDollarCommand ? "$" : nil
        default:
            return nil
        }
    }

    static func prefixForFirstKeyCharacters(
        _ characters: String?,
        existingText: String,
        hasMarkedText: Bool,
        canUseCodexDollarCommand: Bool
    ) -> String? {
        guard existingText.isEmpty,
              !hasMarkedText,
              let characters,
              characters.count == 1 else { return nil }

        return prefix(
            for: characters,
            canUseCodexDollarCommand: canUseCodexDollarCommand
        )
    }

    static func hasVisibleComposerText(
        string: String,
        hasMarkedText: Bool
    ) -> Bool {
        !string.isEmpty || hasMarkedText
    }
}
#endif
