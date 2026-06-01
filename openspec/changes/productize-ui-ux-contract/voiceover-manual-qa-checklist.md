# VoiceOver Manual QA Checklist

Task: 7.1

## Scope

This checklist verifies product-grade accessibility behavior without changing terminal ownership. VoiceOver must describe Penggie-owned controls and projected terminal-owned surfaces, while Raw Terminal remains the audit/control surface for opaque or low-confidence terminal state.

## Test Setup

- Build/run current Debug app.
- Test both light and dark appearance where practical.
- Use a folder with existing Codex sessions and at least one session that can trigger approval/permission prompts.
- Enable VoiceOver.
- Use keyboard navigation only unless a step explicitly mentions pointer interaction.
- Record failures with screenshot, screen state, spoken phrase, expected phrase, and whether Raw Terminal matched the same Codex/Ghostty session.

## Setup And Start

- Tab order reaches agent card, project folder row, folder change action, and `Create with Penggie`.
- VoiceOver announces the selected agent, selected folder, and whether `Create with Penggie` is enabled.
- Invalid/missing folder states announce the blocking reason and recovery action.
- Pressing `Create with Penggie` announces checking/launching progress without leaking startup shell text into Reading.

## Reading Transcript

- Completed user turns, assistant prose, warnings, tool events, status rows, preformatted fallback, and collapsible details have distinct roles or useful labels.
- Low-confidence fallback announces that terminal text was preserved, not silently reclassified.
- Terminal-owned transient surfaces are not announced as completed assistant transcript content after they disappear.
- Long transcript navigation remains stable after resize, Raw Terminal round trip, and later terminal output.

## Composer, IME, And Focus

- Empty composer announces placeholder and disabled send reason.
- Focused composer announces editable text and send availability.
- IME marked text does not trigger submit and does not produce duplicate announcements.
- `Enter`, `Shift-Enter`, paste, large paste, disabled send, and bounded-height/internal scroll are understandable.
- When a terminal-owned surface takes focus, VoiceOver no longer treats the local composer as the active owner.

## Native Terminal-Owned Overlays

For slash suggestions, model picker, effort picker, resume picker, approval prompt, and permission prompt:

- Each candidate row announces row text, selected/not selected, confirmable/unavailable, syncing/unknown if applicable, and position if available.
- Selected row has a non-color affordance in the spoken value.
- `Enter` is announced/allowed only when the terminal frame provides fresh confirmable selection.
- Low-confidence rows remain visible and VoiceOver explains why confirmation is blocked.
- `Esc`, `Tab`, arrow keys, typed filtering, and Backspace route to the terminal-owned surface and announce updated state only after fresh terminal evidence.

## Approval And Permission

- Safety-sensitive prompt title and visible choices are announced before the user can confirm.
- Deny/cancel paths are discoverable.
- Ambiguous or stale selection blocks confirm and does not fall through into composer submit.
- Raw Terminal shows the same underlying prompt and selected row.

## Raw Terminal Switch

- The chrome control announces `Show Raw Terminal` from Reading and `Show Reading` from Raw Terminal.
- Switching to Raw Terminal moves keyboard focus to the Ghostty host when visible.
- Switching back restores Reading focus without creating a second Codex/Ghostty session.
- Exited sessions announce the recovery state and expose Raw Terminal inspection only when a terminal surface exists.

## Recovery And Confirmations

- Missing Codex, launch failed, process exited, New Chat, and Close Session states announce the problem, destructive consequence, primary action, secondary action, and cancel path.
- Confirmation dialogs trap focus until dismissed.
- Cancel restores the previous owner and does not discard the live session.

## Dynamic State Announcements To Verify Later

Track these for task 7.3 implementation/verification:

- checking Codex
- launching
- ready
- working/tool running
- approval required
- permission required
- projection degraded
- selection syncing
- process exited
- missing Codex
- launch failed

## Pass Criteria

- A keyboard-only VoiceOver user can complete setup, submit a prompt, use slash/model selection, choose a resume session, answer approval/permission prompts, inspect Raw Terminal, return to Reading, and cancel destructive confirmations.
- VoiceOver never implies SwiftUI owns terminal-owned selected state.
- VoiceOver never allows confirmation when terminal evidence is stale, ambiguous, or low confidence.
- Raw Terminal audit remains available only when the lifecycle policy allows an inspectable surface.

## Non-Goals

- Do not synthesize Codex-owned selection state for accessibility.
- Do not create a second Codex session for VoiceOver audit.
- Do not hide low-confidence terminal evidence to make announcements cleaner.
- Do not mark tasks 7.2-7.6 complete from this checklist alone; they require implementation and runtime evidence.
