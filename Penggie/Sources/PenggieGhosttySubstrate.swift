import Foundation
import GhosttyKit

struct PenggieGhosttySubstrate {
    var versionDescription: String {
        let info = ghostty_info()
        guard let version = info.version else {
            return "GhosttyKit"
        }

        return String(cString: version)
    }

    var buildModeDescription: String {
        let info = ghostty_info()
        switch info.build_mode {
        case GHOSTTY_BUILD_MODE_DEBUG:
            return "debug"
        case GHOSTTY_BUILD_MODE_RELEASE_SAFE:
            return "release-safe"
        case GHOSTTY_BUILD_MODE_RELEASE_FAST:
            return "release-fast"
        case GHOSTTY_BUILD_MODE_RELEASE_SMALL:
            return "release-small"
        default:
            return "unknown"
        }
    }

    var isAvailable: Bool {
        !versionDescription.isEmpty
    }
}
