import AppKit
import SwiftUI

enum PenggieInteractionCommand {
    case tab
    case enter
    case escape
    case arrowUp
    case arrowDown
    case arrowLeft
    case arrowRight
    case backspace
    case delete
}

struct PenggieInteractionKeyCaptureView: NSViewRepresentable {
    let shouldFocus: Bool
    let isEnabled: Bool
    let focusRequestID: Int
    let onCommand: (PenggieInteractionCommand, NSEvent) -> Bool
    let onTextInput: (String) -> Bool

    func makeNSView(context: Context) -> PenggieInteractionKeyCaptureNSView {
        let view = PenggieInteractionKeyCaptureNSView()
        view.onCommand = onCommand
        view.onTextInput = onTextInput
        return view
    }

    func updateNSView(_ nsView: PenggieInteractionKeyCaptureNSView, context: Context) {
        nsView.onCommand = onCommand
        nsView.onTextInput = onTextInput
        nsView.isEnabled = isEnabled

        let focusRequestChanged = nsView.focusRequestID != focusRequestID
        nsView.focusRequestID = focusRequestID
        if isEnabled, shouldFocus || focusRequestChanged {
            nsView.requestFocus()
        }
    }
}

final class PenggieInteractionKeyCaptureNSView: NSView {
    var isEnabled = true
    var focusRequestID = 0
    var onCommand: ((PenggieInteractionCommand, NSEvent) -> Bool)?
    var onTextInput: ((String) -> Bool)?
    private var wantsFocus = false

    override var acceptsFirstResponder: Bool {
        isEnabled
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if wantsFocus {
            requestFocus()
        }
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        requestFocus()
    }

    func requestFocus() {
        wantsFocus = true
        focusAfterLayout(delay: 0)
        focusAfterLayout(delay: 0.03)
        focusAfterLayout(delay: 0.12)
    }

    private func focusAfterLayout(delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.isEnabled else { return }
            self.window?.makeFirstResponder(self)
        }
    }

    override func keyDown(with event: NSEvent) {
        guard isEnabled else {
            super.keyDown(with: event)
            return
        }

        if let command = penggieInteractionCommand(for: event),
           onCommand?(command, event) == true {
            return
        }

        guard let characters = penggieInteractionText(for: event),
              onTextInput?(characters) == true else {
            super.keyDown(with: event)
            return
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if penggieIsPasteKeyEquivalent(event),
           let pasted = NSPasteboard.general.string(forType: .string),
           !pasted.isEmpty {
            return onTextInput?(pasted) == true
        }

        return super.performKeyEquivalent(with: event)
    }
}

private func penggieInteractionCommand(for event: NSEvent) -> PenggieInteractionCommand? {
    let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    guard !modifierFlags.contains(.command),
          !modifierFlags.contains(.control),
          !modifierFlags.contains(.option) else {
        return nil
    }

    switch event.keyCode {
    case 48:
        return .tab
    case 36, 76:
        return .enter
    case 53:
        return .escape
    case 126:
        return .arrowUp
    case 125:
        return .arrowDown
    case 123:
        return .arrowLeft
    case 124:
        return .arrowRight
    case 51:
        return .backspace
    case 117:
        return .delete
    default:
        return nil
    }
}

private func penggieInteractionText(for event: NSEvent) -> String? {
    let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    guard !modifierFlags.contains(.command),
          !modifierFlags.contains(.control),
          !modifierFlags.contains(.option),
          let characters = event.characters,
          !characters.isEmpty else {
        return nil
    }

    return characters
}

private func penggieIsPasteKeyEquivalent(_ event: NSEvent) -> Bool {
    let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    return modifierFlags.contains(.command)
        && !modifierFlags.contains(.control)
        && !modifierFlags.contains(.option)
        && event.charactersIgnoringModifiers?.lowercased() == "v"
}
