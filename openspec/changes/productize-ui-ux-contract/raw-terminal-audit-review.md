# Raw Terminal Audit And Control Review

Task: 6.1

## Reviewed Files

- `Penggie/Sources/PenggieGhosttySession.swift`
- `Penggie/Sources/PenggieGhosttySubstrate.swift`
- `Penggie/Sources/PenggieRootView.swift`
- `Penggie/Sources/PenggieTheme.swift`
- `Penggie/Sources/PenggieSessionModel.swift`
- `Penggie/Sources/PenggieSessionLifecyclePolicy.swift`

## Current Contract

Raw Terminal is an audit/control surface for the same Codex process and Ghostty surface used by Reading. It is not a second session, not a reconstructed terminal, and not a SwiftUI replay of terminal state.

## Evidence

- Single Ghostty session:
  - `PenggieSessionModel.ghosttySession` owns one optional `PenggieGhosttySession`.
  - `PenggieGhosttySession` creates one `PenggieGhosttyHostView` and one Ghostty surface during init.
  - `PenggieGhosttyTerminalView.makeNSView` returns `session.terminalView`, so Reading/Raw mode switching reuses the same host view rather than allocating a second surface.
- Mode-only switching:
  - `PenggieSessionModel.switchToTerminal()` and `switchToReading()` delegate to `PenggieSessionLifecyclePolicy.displayTransition`.
  - `displayTransition` only allows Reading/Terminal switches after `hasInspectableSession` is true.
  - `PenggieSessionView` keeps Reading and Raw Terminal in the same ZStack and toggles opacity/hit testing/accessibility visibility by `session.state`.
- Recovery audit:
  - `exited` sessions remain inspectable through lifecycle policy.
  - `PenggieExitedTerminalInspectionView` exposes the existing terminal surface with a recovery return action, not a new Codex launch.
- Input/control:
  - Raw Terminal keyboard/mouse events are forwarded through `PenggieGhosttyHostView` to `PenggieGhosttySession`.
  - Clipboard reads/writes go through Ghostty runtime callbacks and `copySelectionToPasteboard()`.
  - Theme application flows from `PenggieTheme.terminalConfiguration` into `PenggieSessionModel.applyTheme`, then `PenggieGhosttySession.applyTheme`, then host fallback background and Ghostty color scheme sync.
- Substrate boundary:
  - `PenggieGhosttySubstrate` only exposes Ghostty availability/version/build mode and does not own session state.

## Risks Deferred To Manual QA Tasks

The following are intentionally not marked complete by this review because they require runtime/manual evidence:

- 6.2 Reading-to-Raw-to-Reading round trip state preservation.
- 6.3 Raw Terminal availability during degraded Reading projection.
- 6.4 keyboard focus parity.
- 6.5 text selection/copy/paste and mouse reporting behavior.
- 6.6 visual parity across light/dark theme.

## Non-Goals

- Do not split Reading and Raw Terminal into separate Ghostty sessions.
- Do not mirror Raw Terminal with SwiftUI text rows.
- Do not maintain local terminal scrollback, selected row, command list, or Codex state.
- Do not expose Raw Terminal before a stable inspectable surface exists, except exited-session audit where the terminal surface already exists.
