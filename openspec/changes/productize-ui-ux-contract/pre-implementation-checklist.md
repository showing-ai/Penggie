# Pre-Implementation Checklist

Use this before starting any product-grade UI/UX implementation task from this change.

## Required Setup

- Identify the exact OpenSpec task ID and milestone.
- List primary Swift files and test/fixture files that will change.
- State whether the work touches terminal-owned state, Reading transcript state, lifecycle state, Raw Terminal, theme, accessibility, or QA only.
- Define the evidence needed before marking the task complete: unit tests, fixtures, manual QA, visual capture, accessibility QA, source guard, or explicit not-applicable note.

## Hard Rejection Criteria

Reject or redesign the implementation if it introduces any of the following:

- Local authoritative command, model, effort, resume, approval, permission, or modal-choice lists.
- Local selected indexes or optimistic selected-row movement for Codex-owned surfaces.
- Confirmation that does not require fresh terminal-frame evidence of exactly one confirmable selected row.
- A second user-visible Codex process, SDK session, `codex exec --json` session, or headless semantic session.
- A second Raw Terminal/Ghostty session for the same active work.
- SwiftUI overlays that fake active terminal rows, active input, selected row, terminal scrollback, or approval state.
- Reading transcript blocks created from terminal chrome, footer/help rows, active input rows, startup noise, or active terminal-owned menus.
- Visual polish that hides low-confidence projection instead of preserving evidence or exposing Raw Terminal audit.
- Theme or color patches in feature views that bypass `PenggieTheme`/scene/component tokens without documented exception.
- Changes to Codex key event routing that bypass the PTY path for terminal-owned decisions.

## Terminal-Owned Surface Checklist

For slash, model, effort, resume, approval, permission, or modal choice work:

- Rows come from the current Ghostty/Codex terminal frame.
- Selected row source is recorded: marker, style, cursor, selected cell, or none.
- Confidence and freshness are explicit.
- Arrow, Tab, text, Enter, Esc, and Backspace route according to the active surface input policy.
- The UI enters waiting-for-terminal-frame after navigation instead of locally moving selection.
- Enter/click/accessibility activation is blocked when selection is stale, ambiguous, missing, or non-confirmable.
- Low-confidence rows remain visible when useful.
- Raw Terminal parity is part of QA.

## Reading/Transcript Checklist

- Completed turns remain stable across repaint, resize, Raw Terminal switch, later output, process exit, and subsequent prompts.
- Display AST/fallback evidence is sufficient for CJK, tables, code, warnings, tools, and low-confidence content affected by the change.
- Active terminal-owned UI is excluded from sealed assistant content.
- Raw/preformatted fallback preserves visible terminal evidence when classification is uncertain.

## Composer/Focus Checklist

- IME marked text is not overwritten.
- Enter does not submit while marked text exists.
- Shift-Enter, paste, large paste, draft preservation, and disabled send states are covered when relevant.
- Focus owner is explicit for setup, Reading, composing, terminal-owned overlay, Raw Terminal, confirmation, process exit, and recovery.

## Raw Terminal Checklist

- Reading and Raw Terminal continue to share one `PenggieGhosttySession`.
- Switching views preserves process, cwd, scrollback, terminal-owned state, process state, draft state, and transcript state.
- Ghostty host owns keyboard focus when Raw Terminal is visible.
- Copy/paste/mouse behavior is tested or explicitly out of scope.

## Completion Gate

Do not mark a task complete until:

- Code/docs are scoped to the task.
- Tests/QA evidence listed above exists or is explicitly not applicable.
- `openspec validate <change> --strict` passes.
- `openspec validate --all --strict` passes.
- `git diff --check` passes.
