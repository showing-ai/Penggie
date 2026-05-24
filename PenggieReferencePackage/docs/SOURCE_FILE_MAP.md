# Source File Map

## `source/showcli-reading-native`

- `ShowCLIReadingMode.swift`: SwiftUI Reading UI, composer bar, native overlay, AppKit composer/key capture bridges.
- `ShowCLICurrentSessionController.swift`: session state, Agent launch, Reading projection, native interaction lifecycle, PTY send/key paths.
- `ShowCLIComposerNativeTrigger.swift`: first-character slash/dollar trigger rules and placeholder visible-text helper.
- `ShowCLITerminalScreenSnapshot.swift`: Codable Ghostty screen model, native row extraction, selected row styling logic.
- `ShowCLIReadingPresentation.swift`: Reading display normalization and chrome/tool/status classification.
- `ShowCLIItemTranscript.swift`: terminal transcript item modeling and extraction helpers.

## `tests`

- `ShowCLIItemTranscriptTests.swift`: current regression coverage for transcript, presentation, and native screen-model row extraction.

## `source/ghostty-integration-reference`

- `TerminalView.swift`: reference for mode switching and Reading/Terminal composition.
- `SurfaceView_AppKit.swift`: reference for AppKit key and screen model integration.
- `project.pbxproj.reference`: reference only. Do not copy directly into Penggie unless intentionally integrating with the same Xcode project structure.
