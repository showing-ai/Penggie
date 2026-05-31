# App Shell And Session Lifecycle Audit

Scope: task 2.1 in `productize-ui-ux-contract`.

Reviewed implementation:

- `Penggie/Sources/PenggieApp.swift`
- `Penggie/Sources/PenggieRootView.swift`
- `Penggie/Sources/PenggieSessionModel.swift`
- `Penggie/Sources/PenggieSessionLifecyclePolicy.swift`
- `Tests/PenggieCoreTests/PenggieSessionLifecyclePolicyTests.swift`
- `scripts/qa/check-p0-session-lifecycle-source.sh`

This audit records the current app-shell state matrix before P0 implementation tasks 2.2 through 2.7. It does not change application code.

## Current State Matrix

| Lifecycle state | Visible UI | Allowed actions | Blocked actions | Keyboard owner | Raw Terminal availability | Recovery path | Findings |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `.idle` | Setup/start surface with provider, project folder, and `Create with Penggie`. | Choose or change folder; start when folder is usable. | New Chat, Close Session, Raw Terminal. | SwiftUI setup controls. | Not available. | Choose folder, then create. | Aligned. Setup is product-facing and does not expose terminal startup noise. |
| `.closed` | Same setup/start surface as `.idle`. | Choose or change folder; start when folder is usable. | New Chat, Close Session, Raw Terminal. | SwiftUI setup controls. | Not available. | Start a new session. | Aligned. Used after confirmed close/new chat teardown. |
| `.checkingCodex` | Setup/start surface is held instead of terminal/progress content. | No real start action should be accepted; `startWithCodex()` guard returns because lifecycle policy disallows start. | Prompt input, folder changes, New Chat, Close Session, Raw Terminal, second start. | Setup view remains focusable. | Not available. | Success moves to `.launching`; failure moves to `.codexMissing`. | Mismatch A1: `holdsDuringStartup` makes the Create button look enabled and not disabled even though the model blocks the action. Mismatch A2: `PenggieProgressView` has checking copy but is not rendered. |
| `.launching` | Setup/start surface is held while Codex/Ghostty starts. | No real start action should be accepted; `startWithCodex()` guard returns. | Prompt input, folder changes, New Chat, Close Session, Raw Terminal, second start. | Setup view remains focusable. | Not available. | Success creates `PenggieGhosttySession`, starts polling, enters `.reading`; failure moves to `.launchFailed`. | Same mismatch as `.checkingCodex`: visible button state and progress copy do not fully communicate blocked startup. |
| `.reading` before stable Codex screen | Setup/start surface is held while polling waits for stable terminal evidence. | No prompt or Raw Terminal action should be available. | Prompt input, Raw Terminal, New Chat, Close Session. | Setup view remains focusable. | Not available until `hasReachedStableCodexScreen`. | Polling eventually reveals Reading, a terminal-owned surface, or recovery. | Aligned on terminal-noise hiding, but the setup surface can still appear action-capable during hold. |
| `.reading` stable | Reading chat view with transcript/composer or terminal-owned surface projection. | Prompt submit when session running, not terminal-owned, and turn store allows; New Chat/Close via confirmation; switch to Raw Terminal. | Prompt blocked during terminal-owned surfaces or low-confidence confirm gates. | Composer, terminal-owned key capture, or SwiftUI confirmation depending on active surface. | Available through mode toggle because lifecycle policy marks stable reading inspectable. | New Chat/Close confirmations; Raw Terminal audit; process exit recovery. | Mostly aligned. Terminal-owned surfaces are now routed through `PenggieTerminalInteractionSurface` and PTY-backed input. |
| `.terminal` stable | Embedded Raw Terminal surface with chrome toggle. | Terminal keyboard/mouse through Ghostty; switch back to Reading; New Chat/Close via confirmation. | Local Reading composer input. | Ghostty host view. | Active and authoritative. | Return to Reading or close/new chat confirmation. | Aligned with same-session parity: Reading and Raw Terminal are mounted with opacity/hit-testing instead of recreating the session view. |
| `.codexMissing` | Error card: `Codex CLI not found`, `Check Again`. | Retry `startWithCodex()` when folder remains valid. | Prompt input, Raw Terminal, New Chat, Close Session. | Error view primary action. | Not available. | Install/fix Codex PATH, then Check Again. | Partial mismatch A3: recovery copy has one primary action but no explicit route to change folder or close/reset setup state. |
| `.launchFailed(message)` | Error card: `Codex failed to launch`, `Try Again`. | Retry `startWithCodex()` when folder remains valid. | Prompt input, Raw Terminal, New Chat, Close Session. | Error view primary action. | Not available. | Fix cause or Try Again. | Partial mismatch A4: no secondary route to change folder/return to setup is visible. |
| `.exited` | Error card: `Codex session ended`, `Start Again`; copy says the raw terminal state can be inspected. | `requestNewChat()` and `requestCloseSession()` are allowed by `hasInspectableSession`; `Start Again` can launch a new session. | Prompt input. | Error view primary action or menu confirmations. | Policy reports inspectable, but the root view renders the error card and `displayTransition` cannot switch from `.exited` to `.terminal`. | Start Again or close/new chat via menus. | Mismatch A5: copy and policy say Raw Terminal inspection is available, but the UI has no visible Raw Terminal path and `switchToTerminal()` is a no-op from `.exited`. |

## Aligned Invariants

- `Create with Penggie` enters `startWithCodex()` and `launchCodexSession()` without `codex resume`, `--last`, or a local resume path. The source guard script enforces this.
- `canStartCodex`, `hasInspectableSession`, `isRunning`, `canSubmitPrompt`, and display transitions are centralized in `PenggieSessionLifecyclePolicy`.
- Checking and launching phases are non-inspectable and non-running.
- Prompt submission is blocked unless the session is running, the screen is not terminal-owned, and the Reading turn store allows submission.
- Stable Reading and stable Raw Terminal mode transitions are mode-only; they do not close, recreate, or fork `PenggieGhosttySession`.
- Reading and Raw Terminal are mounted together under `PenggieSessionView` with opacity/hit-testing, preserving the same embedded terminal surface across display mode changes.
- Terminal-owned full-page surfaces route navigation/text/confirm/cancel through terminal-surface commands and PTY-backed input.

## Mismatches And Follow-up Mapping

### A1: Startup button visual state does not match blocked model state

During `.checkingCodex`, `.launching`, and initial `.reading` hold, `PenggieStartView(holdsDuringStartup: true)` allows the Create button to look enabled and disables it only when both `canStartConfiguredCodex` and `holdsDuringStartup` are false. The model guard prevents a duplicate launch, but the visible state does not clearly communicate that startup is in progress.

Follow-up tasks: 2.2, 2.4, 2.7.

Acceptance direction:

- Startup should expose a distinct checking/launching/holding state.
- The create action should be visibly blocked or replaced by progress copy while the model blocks it.
- Keyboard order should not land users on a no-op primary action.

### A2: Dedicated progress copy exists but is not rendered

`PenggieProgressView` contains checking/starting copy, but `PenggieRootView` renders the setup surface for `.checkingCodex` and `.launching`. This hides raw terminal noise, but weakens the lifecycle state matrix because the user cannot distinguish checking from launching.

Follow-up tasks: 2.2, 2.4.

Acceptance direction:

- Keep terminal startup noise hidden.
- Show explicit checking/launching status without exposing an active prompt or Raw Terminal before inspectability.

### A3: Missing Codex recovery lacks secondary setup path

`.codexMissing` provides `Check Again` but no visible way to return to setup, choose a different folder, or close/reset. This is acceptable for retry-only recovery, but not enough for product-grade setup/recovery criteria.

Follow-up tasks: 2.2, 2.5.

### A4: Launch failed recovery lacks secondary setup path

`.launchFailed` provides `Try Again` but no visible way to change folder or close/reset. Since launch failure can come from an inaccessible or invalid folder, recovery needs a safer secondary action.

Follow-up tasks: 2.2, 2.5.

### A5: Exited Raw Terminal availability is inconsistent

The lifecycle policy reports `.exited` as inspectable, and exited copy says the user can inspect raw terminal state. However:

- `PenggieRootView` renders `PenggieErrorStateView`, not `PenggieSessionView`, for `.exited`.
- `PenggieModeToggleButton` is unavailable because chrome only appears in `PenggieSessionView`.
- `displayTransition(from: .exited, to: .terminal)` returns `.noOp`.

This is the clearest state matrix mismatch.

Follow-up tasks: 2.5, 6.3.

Acceptance direction:

- If a terminal surface exists after process exit, Raw Terminal inspection must be visible and reachable.
- If no terminal surface exists, copy should not promise Raw Terminal inspection.
- Policy, root view, and display transition behavior must agree.

### A6: Confirmation focus trap is unverified

New Chat and Close Session use SwiftUI `Alert`. The model preserves the active session until confirmation, but focus trap, cancellation focus restoration, VoiceOver copy, and destructive action review are not proven by current tests.

Follow-up tasks: 2.6, 7.2, 7.3.

Acceptance direction:

- Cancel must restore the previous focus owner.
- Confirm must be destructive and explicit.
- Background session teardown must not happen before confirmation.

## QA Evidence To Add In Later Tasks

Manual QA scenarios required by tasks 2.2 through 2.7:

- Setup with valid folder, missing folder, invalid/inaccessible folder.
- `Create with Penggie` from setup enters create/new-session path and does not route into resume by default.
- Checking/launching state blocks prompt, folder changes, Raw Terminal, New Chat, Close Session, and duplicate create.
- Missing Codex retry and setup recovery.
- Launch failure retry and setup recovery.
- Process exited with terminal surface: Raw Terminal is reachable.
- Process exited without terminal surface: Raw Terminal is not promised.
- New Chat confirmation: cancel preserves session; confirm tears down and starts a fresh session.
- Close Session confirmation: cancel preserves session; confirm closes and returns to setup.
- Keyboard-only setup and lifecycle recovery.
- VoiceOver labels and hints for folder, create, retry, close, destructive confirmation, and Raw Terminal inspection.

Automated/source guard evidence already present:

- `PenggieSessionLifecyclePolicyTests.swift` covers non-inspectable launch phases, stable-mode transitions, exited inspectability, and terminal-owned prompt blocking.
- `scripts/qa/check-p0-session-lifecycle-source.sh` rejects `codex resume`, `--last`, or local resume routing in the create path and enforces lifecycle-policy use for mode switching.

## Task 2.1 Result

Task 2.1 is complete as an audit. It identifies current state matrix alignment and the mismatches that must be fixed or validated by tasks 2.2 through 2.7 before the P0 app-shell lifecycle milestone can be accepted.
