## 1. Implementation Boundary

- [x] 1.1 Confirm the current source state for `PenggieSessionModel.swift`, `PenggieRootView.swift`, `PenggieNativeInteractionProjection.swift`, `PenggieInteractionKeyCaptureView.swift`, and `PenggieGhosttySession.swift`.
- [x] 1.2 Confirm no task in this change requires local selected indexes, local Codex-owned lists, a second Codex runtime, broad visual polish, or a Reading transcript rewrite.
- [x] 1.3 Run `openspec validate implement-p0-terminal-surface-lifecycle --strict` before code changes.

## 2. Create Path And Session Lifecycle

- [x] 2.1 Audit `Create with Penggie` launch path and verify Penggie-owned code does not invoke `codex resume`, `--last`, or any resume-specific command from the create button.
- [x] 2.2 Add or update a unit/manual QA guard proving `Create with Penggie` starts a new/create path unless Codex itself independently presents resume.
- [x] 2.3 Harden inspectable-session gating so Raw Terminal, New Chat, Close Session, and prompt submission remain unavailable during checking/launching and available only after a stable inspectable session exists.

## 3. Terminal-Owned Input Freshness And Confirm Gate

- [x] 3.1 Add tests for active terminal-owned surface Enter handling: fresh confirmable selection routes, stale/missing/ambiguous selection blocks and consumes.
- [x] 3.2 Add tests or assertions that arrow, Tab, Backspace, and text filter input route to PTY and do not mutate a local selected index.
- [x] 3.3 Implement minimal session/input-policy changes needed for terminal-owned surface commands to preserve rows while waiting for terminal evidence and to keep Enter blocked until fresh confirmation is available.
- [x] 3.4 Verify unsafe Enter cannot fall through to ordinary composer submission.

## 4. Native Candidate Viewport Stability

- [x] 4.1 Add viewport tests for selected row near the top, middle, bottom, and beyond the visible native list window.
- [x] 4.2 Ensure `PenggieTerminalInteractionCandidateViewport` keeps the selected row fully visible with enough context when possible.
- [x] 4.3 Adjust `PenggieTerminalSurfaceCandidateListView` or its containers only as needed to prevent selected-row clipping, footer overlap, and half-rendered highlights.
- [x] 4.4 Manually verify resume picker and slash/model overlays at list boundaries.

## 5. Raw Terminal Same-Session Round Trip

- [x] 5.1 Add or update tests around state transitions for Reading -> Raw Terminal -> Reading without replacing `ghosttySession`.
- [x] 5.2 Verify active terminal-owned surface projection remains tied to the same latest terminal frame after mode switching.
- [x] 5.3 Verify Raw Terminal remains unavailable before an inspectable session and available after an inspectable session or exited inspectable session.

## 6. Validation

- [x] 6.1 Run `swift test --filter PenggieTerminalInteractionSurfaceTests`.
- [x] 6.2 Run `swift test --filter PenggieNativeInteractionProjectionTests`.
- [x] 6.3 Run `swift test --filter PenggieSessionModelPollingTests`.
- [x] 6.4 Run `openspec validate implement-p0-terminal-surface-lifecycle --strict`.
- [x] 6.5 Run `openspec show implement-p0-terminal-surface-lifecycle --json`.
- [x] 6.6 Run `openspec validate --all --strict`.
- [x] 6.7 Run `git diff --check`.
- [x] 6.8 Run `scripts/qa/check-p0-session-lifecycle-source.sh`.
