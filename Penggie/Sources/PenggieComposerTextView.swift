import AppKit
import SwiftUI

struct PenggieComposerTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var measuredHeight: CGFloat
    @Binding var hasVisibleText: Bool

    let isEnabled: Bool
    let shouldFocus: Bool
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let textColor: NSColor
    let disabledTextColor: NSColor
    let insertionPointColor: NSColor
    let onSubmit: () -> Void
    let onNativePrefix: (String) -> Bool

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.autohidesScrollers = true

        let textView = PenggieComposerNSTextView(frame: .zero)
        let coordinator = context.coordinator
        textView.onFirstCharacterNativePrefix = { [weak coordinator] prefix in
            coordinator?.parent.onNativePrefix(prefix) ?? false
        }
        textView.onVisibleTextStateMayHaveChanged = { [weak coordinator] in
            coordinator?.updateVisibleTextState()
        }
        textView.delegate = coordinator
        textView.string = text
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = textColor
        textView.insertionPointColor = insertionPointColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isEditable = isEnabled
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.minSize = NSSize(width: 0, height: minHeight)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 0, height: 6)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false

        scrollView.documentView = textView
        coordinator.textView = textView
        coordinator.scrollView = scrollView
        coordinator.updateMeasuredHeight()
        coordinator.updateVisibleTextState(deferringBindingUpdate: true)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.scrollView = scrollView

        guard let textView = context.coordinator.textView else { return }

        if textView.string != text,
           !textView.hasMarkedText() {
            context.coordinator.isUpdatingFromSwiftUI = true
            textView.string = text
            context.coordinator.isUpdatingFromSwiftUI = false
        }

        textView.isEditable = isEnabled
        textView.textColor = isEnabled ? textColor : disabledTextColor
        textView.insertionPointColor = insertionPointColor
        context.coordinator.updateMeasuredHeight()
        context.coordinator.updateVisibleTextState(deferringBindingUpdate: true)

        if shouldFocus,
           isEnabled,
           scrollView.window?.firstResponder !== textView {
            DispatchQueue.main.async {
                guard textView.window === scrollView.window else { return }
                scrollView.window?.makeFirstResponder(textView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PenggieComposerTextView
        weak var textView: NSTextView?
        weak var scrollView: NSScrollView?
        var isUpdatingFromSwiftUI = false

        init(parent: PenggieComposerTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdatingFromSwiftUI,
                  let textView = notification.object as? NSTextView else {
                return
            }

            parent.text = textView.string
            updateMeasuredHeight()
            updateVisibleTextState()
        }

        func textDidBeginEditing(_ notification: Notification) {
            updateVisibleTextState()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            updateVisibleTextState()
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) ||
                    commandSelector == #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)) else {
                return false
            }

            if textView.hasMarkedText() {
                return false
            }

            let modifiers = NSApp.currentEvent?.modifierFlags.intersection(.deviceIndependentFlagsMask) ?? []
            if modifiers.contains(.shift) {
                return false
            }

            parent.onSubmit()
            return true
        }

        func updateMeasuredHeight() {
            guard let textView, let scrollView, let textContainer = textView.textContainer else { return }

            let availableWidth = max(1, scrollView.contentSize.width)
            textContainer.containerSize = NSSize(
                width: availableWidth,
                height: CGFloat.greatestFiniteMagnitude
            )
            textView.layoutManager?.ensureLayout(for: textContainer)

            let usedHeight = (textView.layoutManager?.usedRect(for: textContainer).height ?? 0) +
                textView.textContainerInset.height * 2
            let nextHeight = min(max(ceil(usedHeight), parent.minHeight), parent.maxHeight)

            scrollView.hasVerticalScroller = usedHeight > parent.maxHeight + 1

            guard abs(parent.measuredHeight - nextHeight) > 0.5 else { return }
            let measuredHeight = parent.$measuredHeight
            Task { @MainActor in
                await Task.yield()
                measuredHeight.wrappedValue = nextHeight
            }
        }

        func updateVisibleTextState(deferringBindingUpdate: Bool = false) {
            guard let textView else { return }

            let nextValue = PenggieComposerNativeTrigger.hasVisibleComposerText(
                string: textView.string,
                hasMarkedText: textView.hasMarkedText()
            )
            guard parent.hasVisibleText != nextValue else { return }

            guard !deferringBindingUpdate else {
                let hasVisibleText = parent.$hasVisibleText
                Task { @MainActor in
                    await Task.yield()
                    hasVisibleText.wrappedValue = nextValue
                }
                return
            }

            parent.hasVisibleText = nextValue
        }
    }
}

private final class PenggieComposerNSTextView: NSTextView {
    var onFirstCharacterNativePrefix: ((String) -> Bool)?
    var onVisibleTextStateMayHaveChanged: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        if handleFirstCharacterNativePrefix(event) {
            onVisibleTextStateMayHaveChanged?()
            return
        }

        super.keyDown(with: event)
        onVisibleTextStateMayHaveChanged?()
    }

    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        super.insertText(insertString, replacementRange: replacementRange)
        onVisibleTextStateMayHaveChanged?()
    }

    override func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        super.setMarkedText(string, selectedRange: selectedRange, replacementRange: replacementRange)
        onVisibleTextStateMayHaveChanged?()
    }

    override func unmarkText() {
        super.unmarkText()
        onVisibleTextStateMayHaveChanged?()
    }

    private func handleFirstCharacterNativePrefix(_ event: NSEvent) -> Bool {
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard !modifierFlags.contains(.command),
              !modifierFlags.contains(.control),
              !modifierFlags.contains(.option) else {
            return false
        }

        guard let prefix = PenggieComposerNativeTrigger.prefixForFirstKeyCharacters(
            event.characters,
            existingText: string,
            hasMarkedText: hasMarkedText()
        ) else {
            return false
        }

        return onFirstCharacterNativePrefix?(prefix) == true
    }
}
