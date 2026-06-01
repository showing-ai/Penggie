# Composer, IME, And Focus Readiness

Task support: `4.2`, `4.3`, `4.4`, and `4.5`.

## Scope

This is source-backed readiness evidence for the P0 composer, IME, focus, and
input-routing manual QA pass. It does not claim live IME QA pass, ordinary
composer QA pass, slash handoff QA pass, Raw Terminal focus QA pass, or
confirmation focus restoration pass.

Tasks `4.2` through `4.5` remain open until the running macOS app is validated
with real keyboard, IME, paste, focus, terminal-owned overlay, Raw Terminal,
confirmation, and recovery flows.

## Source-Backed Readiness

### IME And Marked Text

`PenggieComposerTextView` keeps AppKit as the owner of marked text:

- SwiftUI text replacement is skipped while `NSTextView.hasMarkedText()` is
  true.
- marked text counts as visible composer text, so placeholder text is hidden
  during composition.
- Enter is returned to AppKit while marked text exists, so IME commit can happen
  before prompt submission.

### Ordinary Composer Input

The composer source path preserves ordinary prompt behavior:

- Enter submits through `onSubmit` only when marked text is absent and Shift is
  not held.
- Shift-Enter is not consumed by the submit path.
- rich-text and graphics import are disabled.
- undo, selection, paste through AppKit text editing, measured height, bounded
  max height, and internal vertical scrolling are enabled through the embedded
  `NSTextView`/`NSScrollView`.

### Native Slash Handoff

First-character native prefix handling remains terminal-owned:

- `/` is intercepted only when the composer is empty, unmarked, and not modified
  by command/control/option.
- the slash prefix is sent to the PTY through `PenggieSessionModel`.
- local composer text is cleared after handoff.
- `PenggieInteractionKeyCaptureView` receives focus for the terminal-owned
  interaction surface.

### Terminal-Owned Focus And Key Routing

Terminal-owned surfaces use a key-capture path instead of local SwiftUI state:

- navigation/text/Enter/Esc/Backspace route to `PenggieSessionModel` PTY
  handlers.
- unsafe Enter is evaluated through `PenggieTerminalInputPolicy` and consumed
  when blocked.
- paste key equivalents route to terminal-owned text input while the key-capture
  view owns focus.
- Reading composer is disabled while Codex is in a terminal-owned interaction.

## Manual QA Coverage

The manual QA matrix includes:

- `QA-COMP-001` IME marked text;
- `QA-COMP-002` ordinary composer behavior;
- `QA-COMP-003` slash handoff focus.

Those scenarios require live validation for marked text, committed text,
Enter/Shift-Enter, paste, large paste, disabled send state, draft restoration,
slash handoff, overlay focus ownership, dismissal focus restoration, and
terminal-owned key routing.

## Manual QA Boundary

This readiness guard cannot prove:

- real Chinese/Japanese/Korean IME marked text remains stable under AppKit and
  SwiftUI updates;
- large paste and internal scroll remain visually stable at runtime;
- focus restoration works after live overlay dismissal, Raw Terminal switching,
  confirmation cancellation, process exit, or recovery;
- VoiceOver announces focus and selected/unavailable states correctly.

Those checks remain part of tasks `4.2` through `4.5` and must be recorded from
a live app run.

## Verification

- `scripts/qa/check-p0-composer-ime-focus-readiness.sh` -> P0 composer IME/focus
  readiness guard passed.

## Non-Goals

- No local command, model, resume, approval, permission, or selected-index state.
- No second Codex process.
- No second Ghostty session.
- No forked Raw Terminal session.
- No SwiftUI overlay may own terminal-owned selection or confirmation state.
