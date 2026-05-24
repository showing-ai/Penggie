import Foundation

enum PenggieNativeInteractionPhase: Equatable {
    case inactive
    case editing
    case resolving
    case continuation
    case cancelling

    var isActive: Bool {
        self != .inactive
    }

    var ownsComposerInput: Bool {
        switch self {
        case .editing, .continuation:
            return true
        case .inactive, .resolving, .cancelling:
            return false
        }
    }

    var acceptsInput: Bool {
        ownsComposerInput
    }

    var capturesTextInput: Bool {
        ownsComposerInput
    }
}

enum PenggieNativeInteractionTiming {
    static let resolvingSettleInterval: TimeInterval = 0.35
}
