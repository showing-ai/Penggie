## App Shell Launch Blocked Actions QA

Task: 2.4 Harden checking/launching states so prompt input, folder change, Raw Terminal, New Chat, and Close Session are blocked until an inspectable session or recovery state exists.

## Scope

This note covers non-inspectable startup phases only:

- `checkingCodex`
- `launching`
- initial `reading` before a stable Codex screen is observed
- initial `terminal` before a stable Codex screen is observed

Recovery states such as missing Codex, launch failure, and exited sessions are handled by task 2.5.

## Acceptance Evidence

| Requirement | Evidence |
| --- | --- |
| Prompt input is blocked | `PenggieSessionLifecyclePolicy.canSubmitPrompt(...)` returns false for non-inspectable startup phases. `PenggieRootView` also renders `PenggieStartView(startupState:)` instead of `PenggieSessionView` while `session.isHoldingInitialSurface` is true, so the Reading composer is not mounted. |
| Folder change is blocked | `PenggieStartView` disables the folder picker with `!session.canStartCodex`, and `PenggieSessionModel.chooseWorkingDirectory()` has a model-level `guard canStartCodex else`. |
| Raw Terminal is blocked | `PenggieSessionLifecyclePolicy.displayTransition(...)` returns `.noOp` until `hasInspectableSession` is true. `PenggieSessionView` and the chrome mode toggle are not mounted during initial surface hold. |
| New Chat is blocked | `PenggieApp` disables the New Chat command with `!session.canStartNewChat`, and `PenggieSessionModel.requestNewChat()` has a model-level `guard hasInspectableSession else`. |
| Close Session is blocked | `PenggieApp` disables Close Session with `!session.hasInspectableSession`, and `PenggieSessionModel.requestCloseSession()` has a model-level `guard hasInspectableSession else`. |
| Duplicate create/start is blocked | `PenggieStartView` and the app command disable create with `!session.canStartConfiguredCodex`; `startWithCodex()` also guards `canStartConfiguredCodex`. |
| Startup noise remains hidden | Checking, launching, and initial Reading hold render startup copy instead of Raw Terminal or transcript content. |

## Manual QA

1. Launch Penggie with a valid folder selected.
2. Activate `Create with Penggie`.
3. During `Checking Codex`, verify:
   - Project folder cannot be changed.
   - Create cannot be activated again.
   - New Chat is disabled.
   - Close Session is disabled.
   - Raw Terminal mode is not available.
   - No prompt composer is visible.
4. During `Starting Codex`, repeat the same checks.
5. During `Preparing Reading`, repeat the same checks.
6. After the first stable Codex screen appears, verify normal Reading/Raw Terminal availability returns.

## Automated Coverage

- `PenggieSessionLifecyclePolicyTests.nonInspectableStartupPhasesBlockInspectableActionsAndPromptSubmission`
- `scripts/qa/check-p0-session-lifecycle-source.sh`

## Non-Goals

- Do not expose Raw Terminal before an inspectable terminal surface exists.
- Do not let SwiftUI hold a local startup action state that bypasses `PenggieSessionLifecyclePolicy`.
- Do not start a second Codex/Ghostty session to provide startup inspection.
- Do not route create into resume mode.
