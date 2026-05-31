# P0 Terminal UX Foundation QA

This script is the tracked manual QA artifact for `harden-terminal-ux-qa-foundation`.
It verifies terminal-grounded product behavior before broad UI productization starts.

## Scope

Run these scenarios against a Debug build of Penggie with a real Codex CLI session.
Raw Terminal and Reading must share the same Ghostty PTY and the same Codex process.

## Implementation Guardrails

- Do not introduce a local selected index for Codex-owned menus.
- Do not introduce local command, model, resume, approval, or permission lists as product state.
- Do not introduce a second user-visible Codex runtime or SDK-backed replacement session.
- Do not hide terminal-owned uncertainty by fabricating a highlighted row.
- Do not route unsafe Enter, click, or accessibility activation to composer submit.
- Do not expand this change into visual polish, theme work, broad Reading layout rewrites, semantic source, or explicit resume product entry.
- Do keep Raw Terminal available as the audit surface whenever a real session exists.

## Evidence To Capture On Failure

For every failed scenario, capture:

- Penggie build timestamp and git commit.
- macOS appearance: light or dark.
- Display mode: Reading or Raw Terminal.
- Whether the same session survives Reading to Raw Terminal to Reading.
- Relevant screenshot.
- If terminal-owned state is involved, the visible selected marker, selected row, and whether Enter was enabled.
- Any available `PenggieTerminalInteractionSurfaceDiagnostic`, `PenggieResumePickerDiagnostic`, or active input style diagnostic.

## Scenario 1: Setup And Create Path

Setup:

- Quit all running Penggie instances.
- Launch the current Debug app.
- Select a valid project folder.

Trigger:

- Click `Create with Penggie`.

Expected result:

- Penggie starts the create/new-session path.
- The app does not enter the resume picker unless Codex was explicitly launched in resume mode or the user explicitly chose resume.
- Reading reaches a usable new-chat or startup state without flashing terminal-owned resume UI.
- Raw Terminal, if opened, shows the same Codex process and cwd.

Failure examples:

- `Create with Penggie` opens `Resume a previous session`.
- Reading and Raw Terminal show different cwd or different prompt state.
- The app shows a stale terminal screen before the first stable state.

Raw Terminal parity:

- Required.

## Scenario 2: Slash And Model Surface

Setup:

- Start a new or existing Codex session.
- Ensure the Reading composer is focused.

Trigger:

- Type `/`.
- Navigate with Up and Down.
- Open `/model` or the model/effort picker if available.

Expected result:

- Rows come from the terminal-owned surface, not a local Penggie command list.
- The highlighted row matches the terminal marker or terminal style evidence.
- Arrow keys route to the PTY and selection only changes after terminal evidence updates.
- Enter is enabled only when there is one fresh selected row.
- Esc closes or cancels the terminal-owned surface through the PTY.

Failure examples:

- Highlight moves immediately from a local array index before the terminal updates.
- Multiple rows are highlighted as selected.
- Enter confirms while selection is stale, missing, or ambiguous.
- Historical slash text in transcript is rendered as an active menu.

Raw Terminal parity:

- Required when selection or confirmation looks wrong.

## Scenario 3: Resume Picker

Setup:

- Launch Codex in resume mode or choose the product resume entry when one exists.
- Ensure there are enough saved sessions to scroll.

Trigger:

- Navigate down past the visible list boundary.
- Use Tab to move filter/sort focus if supported.
- Type filter text and clear it.

Expected result:

- The selected row is visible and not clipped.
- Scrolling follows the terminal-owned selected row without local selected-index ownership.
- Filter and sort metadata reflect terminal text.
- `Enter resume` is enabled only for fresh exactly-one selected-row evidence.
- Low-confidence states keep rows inspectable but disable confirmation.

Failure examples:

- Selection disappears while Raw Terminal still shows a selected marker.
- Highlight remains in the wrong viewport after the terminal scrolls.
- The list flashes between old and new row windows.
- Enter resumes while the footer says syncing or selection is ambiguous.

Raw Terminal parity:

- Required.

## Scenario 4: Approval And Permission Prompt

Setup:

- Trigger a Codex action that asks for approval or permission.
- If a live trigger is not available, use a deterministic fixture replay once automated fixture tooling exists.

Trigger:

- Navigate choices with Up and Down.
- Press Esc or the deny/cancel action.
- Repeat and press Enter only when selection is reliable.

Expected result:

- Approval and permission choices are terminal-owned modal choice surfaces.
- Choices are rendered from terminal frame facts.
- Enter, click, and accessibility activation confirm only with fresh exactly-one selected-row evidence.
- Missing, stale, low-confidence, or ambiguous selected evidence blocks or consumes confirmation.
- Unsafe Enter does not fall through to ordinary composer submission.

Failure examples:

- Penggie creates its own approval choice list.
- Enter sends a newline to the composer when the prompt selection is unsafe.
- Reading hides the prompt while Raw Terminal shows a blocking choice.

Raw Terminal parity:

- Required.

## Scenario 5: Reading To Raw Terminal Round Trip

Setup:

- Start an ordinary active Reading session and wait for prompt readiness.

Trigger:

- Switch Reading to Raw Terminal.
- Switch back to Reading.
- Repeat while a slash/model/resume/approval/permission surface is active.

Expected result:

- The same Codex process, cwd, Ghostty session, prompt state, and draft state are preserved.
- Terminal-owned rows and selected state match before and after switching.
- Switching modes does not restart the PTY.
- Switching modes does not detach or remount into a crash-prone state.

Failure examples:

- Raw Terminal shows a different prompt or cwd.
- Reading loses the active terminal-owned surface.
- A selected row changes without terminal input.
- The app crashes, beachballs, or restarts Codex.

Raw Terminal parity:

- This scenario is the parity check.

## Scenario 6: Low-Confidence Projection

Setup:

- Use a fixture or live state where rows are visible but selected evidence is missing, stale, or ambiguous.

Trigger:

- Try Enter, click activation, and accessibility activation.
- Switch to Raw Terminal.

Expected result:

- Rows remain visible when useful.
- Confirmation is unavailable.
- Enter is blocked or consumed and does not become composer submission.
- Raw Terminal remains available and shows the underlying terminal state.

Failure examples:

- Penggie invents a highlighted row.
- Enter confirms the wrong row.
- Rows disappear behind a generic spinner despite being inspectable.

Raw Terminal parity:

- Required.

## Scenario 7: Missing, Failed, And Exited States

Setup:

- Test missing Codex, launch failure, invalid folder, process exited with terminal surface, and process exited without terminal surface.

Trigger:

- Launch Penggie into each failure or recovery state.

Expected result:

- The app shows specific recovery copy.
- Enabled and blocked actions are clear.
- Keyboard focus belongs to the visible recovery action, not a hidden composer.
- Raw Terminal is available only when an inspectable session exists.

Failure examples:

- Generic blank screen or indefinite spinner.
- Composer remains enabled while no Codex process exists.
- Raw Terminal button appears without an inspectable terminal session.

Raw Terminal parity:

- Required only when a terminal session exists.

## Scenario 8: New Chat And Close Session

Setup:

- Start an active session with visible transcript or pending terminal-owned state.

Trigger:

- Invoke New Chat.
- Cancel.
- Invoke Close Session.
- Cancel.
- Repeat and confirm.

Expected result:

- Destructive actions show confirmation.
- Cancel restores focus and state.
- No session is discarded before confirmation.
- Confirmation does not bypass terminal-owned blocking prompts.

Failure examples:

- New Chat discards the current session immediately.
- Close Session kills the PTY before confirmation.
- Cancel returns to a stale or different terminal state.

Raw Terminal parity:

- Required before destructive confirmation when a terminal session exists.
