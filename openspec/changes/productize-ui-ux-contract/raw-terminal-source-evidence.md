# Raw Terminal Source Evidence

Task support: `6.2` through `6.6`.

## Scope

This is source-backed evidence for the Raw Terminal audit/control surface. It
does not claim live Raw Terminal QA pass, visual parity pass, keyboard focus
pass, or clipboard/mouse pass.

Tasks `6.2` through `6.6` remain open until the running macOS app is validated
with the manual QA matrix.

## Source-Backed Invariants

### Same Session Ownership

- `PenggieSessionModel` owns one published `PenggieGhosttySession?`.
- Launch creates one `PenggieGhosttySession` and stores it in
  `ghosttySession`.
- The process-exit callback ignores stale callbacks unless
  `self.ghosttySession === session`.
- Closing a session closes and clears the same `ghosttySession`.
- Exited Raw Terminal inspection is available only when a retained terminal
  surface exists.

### Display Mode Switching

- `switchToReading()` and `switchToTerminal()` are lifecycle-gated through
  `PenggieSessionLifecyclePolicy.displayTransition(...)`.
- `PenggieSessionView` mounts Reading and Raw Terminal in one container.
- Mode switching changes opacity, hit testing, accessibility traversal, and
  interactivity; it does not create a second user-visible Codex/Ghostty session.
- The inactive surface is hidden from accessibility traversal so VoiceOver does
  not traverse both Reading and Raw Terminal at once.

### Raw Terminal Host

- `PenggieGhosttySession` creates and owns one `PenggieGhosttyHostView`.
- `PenggieGhosttyTerminalView.makeNSView` returns `session.terminalView`.
- `updateNSView` toggles `isInteractive`, updates opacity, restores first
  responder when active, and resizes the same Ghostty surface.
- The host forwards keyboard, scroll, mouse position, mouse button, copy, and
  paste actions to Ghostty.
- Copy prefers the Ghostty `copy_to_clipboard` binding and falls back to
  explicit terminal selection-to-pasteboard.
- Paste routes through the Ghostty `paste_from_clipboard` binding.

## Manual QA Boundary

The source guard verifies the code structure needed for Raw Terminal parity, but
it cannot prove:

- one live Codex process and cwd are preserved through mode switching;
- scrollback and terminal-owned surface state are preserved in the running app;
- Ghostty receives keyboard focus in every window/focus transition;
- text selection, copy, pasteboard result, paste, and mouse reporting behavior
  work with the current Codex TUI;
- light/dark Raw Terminal visual parity is correct.

Those checks remain covered by `QA-RAW-001` and `QA-RAW-002` in
`product-grade-ui-ux-manual-qa-script.md`.

## Verification

- `scripts/qa/check-p0-raw-terminal-source.sh` -> Raw Terminal source guard passed.

## Non-Goals

- No second Codex process.
- No second Ghostty session.
- No second Raw Terminal surface as user-visible truth.
- No local selected index/list/session state for terminal-owned surfaces.
- No SwiftUI overlay may fake terminal text selection, pasteboard state, or
  Raw Terminal keyboard focus.
