import Foundation

enum PenggieNativeInteractionPhase: Equatable {
    case inactive
    case editing
    case resolving
    case continuation

    var isActive: Bool {
        self != .inactive
    }

    var ownsComposerInput: Bool {
        switch self {
        case .editing, .continuation:
            return true
        case .inactive, .resolving:
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
    static let escapeObservationInterval: TimeInterval = 1.0
}
