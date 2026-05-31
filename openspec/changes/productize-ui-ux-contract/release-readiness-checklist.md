# Release Readiness Checklist

Use this checklist before accepting each product-grade UI/UX milestone.

## Required Commands

- `openspec validate productize-ui-ux-contract --strict`
- `openspec show productize-ui-ux-contract --json`
- `openspec validate --all --strict`
- Relevant `swift test --filter ...` commands for changed logic.
- Relevant QA/source guard scripts, including:
  - `scripts/qa/check-p0-session-lifecycle-source.sh` when lifecycle/session guards are touched.
  - `scripts/check-theme-token-usage.sh` when visual/theme tokens are touched.
- `git diff --check`
- `xcodebuild -project Penggie/Penggie.xcodeproj -scheme Penggie -configuration Debug -destination 'platform=macOS' build`

## Milestone Evidence Record

For each milestone, record:

- OpenSpec task IDs completed.
- Source files changed.
- Tests run and result.
- Fixtures added or updated, or reason not applicable.
- Manual QA scenario names and result.
- Accessibility QA result.
- Visual QA captures reviewed, or reason not applicable.
- Raw Terminal parity evidence when a live/inspectable terminal surface exists.
- Known limitations and deferred P1/P2 follow-ups.

## P0 Manual QA Minimum

- Setup/start: valid folder, invalid folder, missing folder, `Create with Penggie`, disabled states, keyboard order.
- Lifecycle: checking, launching, active Reading, active Raw Terminal, missing Codex, launch failed, exited, New Chat, Close Session.
- Terminal-owned overlays: slash, model, effort, resume, approval, permission, low-confidence rows, stale selection, blocked Enter, Esc/cancel.
- Composer: IME marked text, committed text, Enter, Shift-Enter, paste, large paste, draft preservation, disabled send reason.
- Reading: long session, CJK, table, code, warning, tool-heavy output, fallback, process exit, Raw Terminal switch.
- Raw Terminal: view switching, same process/cwd/session, keyboard focus, text selection/copy, paste, active overlay parity.

## Accessibility QA Minimum

- Keyboard-only completion of setup, prompt submit, slash/model selection, resume, approval/permission, Raw Terminal switch, New Chat, Close Session.
- VoiceOver labels/hints/values for setup controls, composer, overlay rows, selected rows, disabled rows, syncing state, recovery actions, confirmations.
- Dynamic announcements for checking, launching, ready, working, approval required, permission required, projection degraded, selection syncing, process exited, missing Codex, launch failed.
- Dynamic Type or larger text review for setup, Reading, composer, overlays, recovery, Raw Terminal chrome, and narrow windows.
- Reduced motion review for disclosure, surface switching, focus affordances, and overlay transitions.

## Visual QA Minimum

- Light and dark mode:
  - setup
  - empty Reading
  - long transcript
  - composer focus
  - slash overlay
  - resume picker
  - approval/permission
  - Raw Terminal
  - recovery
  - narrow window
  - large text
- Review token usage for background, text, border, focus, disabled, warning, danger, selected, terminal renderer, and titlebar/canvas seams.

## Acceptance Rule

A milestone is not accepted when:

- Reading and Raw Terminal disagree about process, cwd, prompt readiness, terminal-owned rows, selected row, or process state without visible degraded fallback.
- Enter/click/accessibility activation can confirm a stale, ambiguous, missing, or non-confirmable terminal-owned selection.
- Visual polish hides low-confidence projection or terminal evidence.
- Debug-only diagnostics leak into release without an explicit product QA purpose.
