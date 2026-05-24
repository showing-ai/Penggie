import Foundation

enum PenggieComposerNativeTrigger {
    static func prefix(for text: String) -> String? {
        guard text.first == "/" else { return nil }
        return "/"
    }

    static func prefixForFirstKeyCharacters(
        _ characters: String?,
        existingText: String,
        hasMarkedText: Bool
    ) -> String? {
        guard existingText.isEmpty,
              !hasMarkedText,
              let characters,
              characters.count == 1 else {
            return nil
        }

        return prefix(for: characters)
    }

    static func hasVisibleComposerText(string: String, hasMarkedText: Bool) -> Bool {
        !string.isEmpty || hasMarkedText
    }
}
