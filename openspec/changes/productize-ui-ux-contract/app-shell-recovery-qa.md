# App Shell Recovery QA

Scope: task 2.5 in `productize-ui-ux-contract`.

This note records the P0 recovery-state behavior implemented for missing Codex,
launch failure, and process exit. It keeps the recovery UI aligned with the
single Codex/Ghostty session invariant: Raw Terminal is only offered when an
exited terminal surface still exists.

## Acceptance Evidence

- Missing Codex renders product recovery copy with:
  - primary action: `Check Again`
  - secondary action: `Choose Folder`
  - no Raw Terminal promise
- Launch failure renders product recovery copy with:
  - primary action: `Try Again`
  - secondary action: `Choose Folder`
  - no Raw Terminal promise
- Process exit with retained terminal surface renders:
  - primary action: `Start Again`
  - secondary action: `Inspect Raw Terminal`
  - tertiary action: `Close Session`
  - Raw Terminal inspection view backed by the same retained `PenggieGhosttySession`
- Process exit without a retained terminal surface renders:
  - primary action: `Start Again`
  - tertiary action: `Close Session`
  - no copy or button promising Raw Terminal inspection
- `Start Again` from `.exited` cleans up the exited terminal surface before
  launching a fresh Codex session.
- The Ghostty `onExit` callback ignores stale closed or replaced sessions, so a
  delayed exit callback cannot move a closed/new session back to `.exited`.

## Manual QA

Run these on a Debug build:

1. Missing Codex:
   - Launch Penggie with `PENGGIE_CODEX_COMMAND` pointing to a missing binary.
   - Verify the recovery card says Codex CLI is not found.
   - Verify `Check Again` retries the check.
   - Verify `Choose Folder` opens the folder picker.
   - Verify no Raw Terminal inspection action appears.
2. Launch failed:
   - Launch Penggie with `PENGGIE_FORCE_LAUNCH_FAILURE=1`.
   - Verify the recovery card shows the launch failure message.
   - Verify `Try Again` retries launch.
   - Verify `Choose Folder` opens the folder picker.
   - Verify no Raw Terminal inspection action appears.
3. Process exited with terminal surface:
   - Start a normal session, then make the Codex process exit.
   - Verify the recovery card offers `Start Again`, `Inspect Raw Terminal`, and `Close Session`.
   - Click `Inspect Raw Terminal`.
   - Verify the retained Raw Terminal output is visible and no second Codex/Ghostty session is created.
   - Click `Show Recovery` and verify the recovery card returns.
4. Process exited without terminal surface:
   - Force or simulate `.exited` after the terminal surface has been cleared.
   - Verify the recovery card does not promise Raw Terminal inspection.
   - Verify `Start Again` and `Close Session` remain available.

## Automated Coverage

- `PenggieSessionLifecyclePolicyTests.exitedSessionIsInspectableButNotRunningOrPromptSubmittable`
  proves exited sessions are inspectable but cannot submit prompts.
- `scripts/qa/check-p0-session-lifecycle-source.sh` verifies:
  - exited start cleanup
  - stale Ghostty exit callback guard
  - terminal-surface-aware exited inspection properties
  - missing/failed recovery folder action
  - RootView exited inspection UI wiring

## Non-Goals

- Do not route missing Codex or launch failure into Raw Terminal; no inspectable
  terminal surface exists in those states.
- Do not represent an exited process as `.terminal`; exited is not running.
- Do not create a second Codex/Ghostty session to inspect exit output.
- Do not move terminal-owned process state into SwiftUI local state.
