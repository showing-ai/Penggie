## 1. Screen Classification and Readiness Tests

- [x] 1.1 Add tests that classify `Starting MCP servers` and `esc to interrupt` startup/status projections as launch-blocking, not chat-ready.
- [x] 1.2 Add tests that generic non-empty text no longer unlocks the initial Reading surface unless it matches an explicit display-ready signal.
- [x] 1.3 Add tests for resume picker display readiness requiring projected rows, with selected row required only for confirmation.

## 2. Display-Ready Gate

- [x] 2.1 Introduce a display-ready decision separate from `PenggieCodexScreenKind`.
- [x] 2.2 Keep the start surface visible while Codex is in unknown, shell startup, Codex startup/status, or incomplete resume picker states.
- [x] 2.3 Release the start surface only after a stable Reading-ready or resume-picker-ready state.
- [x] 2.4 Prevent startup/status projections from updating `readingResumeHydrator` or `readingBlocks`.
- [x] 2.5 Disable or hide startup/resume mode switching until the session is inspectable without exposing transient terminal state.

## 3. Resume Picker Projection

- [x] 3.1 Parse visible terminal text for a unique resume picker `›` marker before applying snapshot-derived selection.
- [x] 3.2 Align visible marker selection to snapshot rows by source line or occurrence-aware `(age, title)` matching.
- [x] 3.3 Keep snapshot cursor/style fallback only when visible marker selection is unavailable and the fallback is unique.
- [x] 3.4 Ensure native resume picker never renders multiple selected rows.
- [x] 3.5 Ensure native resume picker does not accept Enter without a selected row and keeps projected rows visible while selection syncs.

## 4. Raw Terminal Visibility

- [x] 4.1 Propagate inactive state to the AppKit `PenggieGhosttyHostView` as real visibility and interactivity, not only SwiftUI opacity.
- [x] 4.2 Preserve the same Ghostty surface and Codex PTY when switching Reading to Raw Terminal and back.
- [x] 4.3 Verify inactive Raw Terminal does not draw over startup hold, Reading empty state, or native resume picker.

## 5. Verification

- [x] 5.1 Run `swift test --filter PenggieCodexScreenKindTests`.
- [x] 5.2 Run `swift test`.
- [x] 5.3 Run `git diff --check`.
- [x] 5.4 Run `xcodebuild -project Penggie/Penggie.xcodeproj -scheme Penggie -configuration Debug -destination 'platform=macOS' -derivedDataPath .build/XcodeDerivedData build`.
- [ ] 5.5 Manually verify start flow transitions directly from Welcome to Reading without showing startup/status or Raw Terminal frames.
- [ ] 5.6 Manually verify resume flow transitions directly to native resume picker rows, highlights exactly one selected row when available, and does not hide rows while selection syncs.
- [ ] 5.7 Manually verify explicit Reading/Terminal switching still uses the same active Codex session.
