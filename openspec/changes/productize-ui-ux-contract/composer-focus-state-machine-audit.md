# Composer, IME, Focus, And Input Routing Audit

Scope: task 4.1 in `productize-ui-ux-contract`.

Reviewed implementation:

- `Penggie/Sources/PenggieComposerTextView.swift`
- `Penggie/Sources/PenggieComposerNativeTrigger.swift`
- `Penggie/Sources/PenggieInteractionKeyCaptureView.swift`
- `Penggie/Sources/PenggieRootView.swift`
- `Penggie/Sources/PenggieSessionModel.swift`
- `Tests/PenggieCoreTests/PenggieComposerNativeTriggerTests.swift`

This audit records the current focus owner and input-routing state before P0 tasks 4.2 through 4.6. It does not change application code.

## Current Focus Owner Matrix

| State | Expected keyboard owner | Current implementation | Findings |
| --- | --- | --- | --- |
| Setup / `.idle` / `.closed` | SwiftUI setup controls. | Setup is rendered outside the session view; composer and Raw Terminal are absent. | Aligned. |
| Checking / launching hold | Startup surface, with prompt and Raw Terminal blocked. | Lifecycle policy blocks start/prompt/Raw Terminal; setup surface remains visible during startup hold. | Covered by app-shell tasks; no composer ownership. |
| Reading idle with prompt-ready Codex | `PenggieComposerTextView`. | `PenggieRootView` focuses the AppKit text view when state is `.reading` and the screen is not terminal-owned. `PenggieSessionModel.canSubmitPrompt` gates actual prompt submission. | Aligned, but manual QA is still needed for focus restoration and draft behavior. |
| Reading composer editing | `PenggieComposerTextView`. | NSTextView owns text input, undo, paste, selection, measured height, and scroll behavior. Enter submits only when there is no marked text and Shift is not held. | Mostly aligned; paste, large paste, bounded scroll, and draft preservation need validation in task 4.3. |
| IME composition | `PenggieComposerTextView` and AppKit IME. | SwiftUI text replacement is skipped while `textView.hasMarkedText()` is true. Marked text counts as visible composer text, hiding the placeholder. Enter falls through to AppKit while marked text exists. | Aligned by source inspection; task 4.2 must provide manual IME evidence. |
| First-character slash command | Terminal-owned Codex surface. | `PenggieComposerNSTextView.keyDown` intercepts `/` only when the local composer is empty, unmarked, and not modified by command/control/option. `PenggieSessionModel.beginNativeInteraction` sends the prefix to the PTY, clears local rows, and starts polling. | Aligned with terminal ground truth. Live focus handoff still needs task 4.4 QA. |
| Legacy native slash/model/effort overlay | `PenggieInteractionKeyCaptureView`. | When `nativeInteractionIsActive`, the composer surface displays terminal-owned input text and overlays a key-capture NSView. Navigation/text is routed to PTY; blocked Enter is consumed. | Aligned as a compatibility path. It must not regain local selected-index ownership. |
| Full-page resume / approval / permission / modal choice | `PenggieInteractionKeyCaptureView`. | Full-page terminal-owned surfaces render from `activeTerminalInteractionSurface` and use the same key-capture view. Enter is routed through `PenggieTerminalInputPolicy` and blocked unless selection is fresh and confirmable. | Aligned. Manual QA remains for resume/approval/permission and accessibility activation. |
| Raw Terminal mode | Ghostty host view. | Reading and Raw Terminal are mounted under the same session view with opacity/hit-testing mode switches. Raw Terminal is hit-testable only in `.terminal`; Reading composer/key capture is hidden from hit testing. | Aligned structurally. Raw Terminal keyboard/mouse/copy QA remains in task 6.x. |
| New Chat / Close Session confirmation | SwiftUI confirmation. | Session model preserves the active session until confirmation; cancellation and focus restoration rely on SwiftUI alert behavior and have not been proven in this audit. | Gap C5. Needs task 4.5/4.6 and accessibility confirmation QA. |
| Process exit / recovery | Recovery view or Raw Terminal if inspectable. | Composer is disabled or absent through lifecycle policy. Recovery focus details are covered by lifecycle tasks, not by composer code. | No composer ownership, but focus restoration after recovery still needs manual QA. |

## Aligned Invariants

- IME marked text is not overwritten by SwiftUI state updates because `PenggieComposerTextView.updateNSView` does not replace the NSTextView string while marked text exists.
- Marked text hides the placeholder through `PenggieComposerNativeTrigger.hasVisibleComposerText`.
- Enter does not submit while marked text exists; the key is returned to AppKit for IME commit.
- Shift-Enter is not consumed by the submit path and can insert a newline through the text view.
- First-character slash handoff is guarded to empty, unmarked composer text and sends the slash to Codex through the PTY.
- Terminal-owned overlay key capture routes navigation, text input, Enter, Esc, Backspace, and paste through terminal-surface/native-interaction handlers rather than moving local selected rows.
- Unsafe Enter for terminal-owned surfaces is consumed as `.blocked`; it must not fall through into composer submission.
- Reading and Raw Terminal continue to share one `PenggieGhosttySession`; focus ownership changes with display mode, not by creating a second session.

## Gaps And Follow-Up Mapping

### C1: IME behavior has source-level protection but no manual QA evidence

The implementation protects marked text and Enter behavior, but there is no recorded manual QA for Chinese/Japanese/Korean IME marked text, commit, cancellation, placeholder visibility, or Enter behavior.

Follow-up task: 4.2.

Acceptance direction:

- Verify marked text hides placeholder.
- Verify SwiftUI state updates do not overwrite marked text.
- Verify Enter commits marked text rather than submitting a prompt.
- Verify committed text submits correctly after composition ends.

### C2: Ordinary composer behavior is not fully validated

The AppKit text view supports text selection, paste, undo, rich-text disabled mode, measured height, and internal scrolling, but task-level evidence is missing for paste, large paste, draft preservation, disabled send reasons, Enter submit, Shift-Enter newline, and bounded height.

Follow-up task: 4.3.

### C3: Slash handoff needs live focus and first-responder QA

`PenggieComposerNativeTriggerTests` cover helper logic, and the AppKit text view intercepts the first slash before local text insertion. However, live QA must prove that focus transfers from NSTextView to `PenggieInteractionKeyCaptureView`, that the local composer no longer owns selection, and that dismissal restores the correct focus owner.

Follow-up task: 4.4.

### C4: Focus ownership is distributed rather than centralized

Focus is currently coordinated through lifecycle state, `codexScreenKind`, `nativeInteractionPhase`, `activeTerminalInteractionSurface`, `focusRequestID`, and AppKit `makeFirstResponder` calls. This is workable, but it means task 4.5 must validate the full transition matrix instead of assuming a single focus enum proves behavior.

Follow-up task: 4.5.

### C5: Confirmation focus trap and restoration remain unproven

New Chat and Close Session use SwiftUI confirmation surfaces. The session is not discarded before confirmation, but this audit does not prove focus trap, cancellation focus restoration, destructive copy, or VoiceOver behavior.

Follow-up tasks: 4.5, 4.6, 7.2.

### C6: Terminal-owned paste needs explicit QA

`PenggieInteractionKeyCaptureNSView.performKeyEquivalent` captures Cmd-V and forwards paste to the terminal-owned surface. This is correct for search/filter-like terminal-owned interactions, but it needs manual validation for large paste, resume filtering, slash text input, and Raw Terminal mode.

Follow-up tasks: 3.10, 4.4, 6.5.

### C7: Raw Terminal focus is out of scope for composer source inspection

The Reading composer is hidden from hit testing in Raw Terminal mode, but Ghostty first responder behavior, copy, paste, and mouse reporting must be validated against the live embedded surface.

Follow-up tasks: 6.2 through 6.5.

## Required QA Evidence For Later Tasks

Manual QA scenarios required before the P0 composer/focus milestone is accepted:

- IME marked text: type with IME, keep composition active, press Enter, commit, then submit.
- Ordinary composer: Enter submit, Shift-Enter newline, paste, large paste, undo, draft preservation, disabled send state, and internal scroll above max height.
- Slash handoff: empty composer `/`, terminal-owned rows appear, arrow navigation waits for terminal frame, Enter confirm gate works, Esc returns focus.
- Full-page terminal-owned surfaces: resume, approval, permission, modal choice, Tab/filter/sort, Esc, Backspace, typed filtering, and blocked Enter when selection is stale or ambiguous.
- Raw Terminal switch: composer no longer captures keys, Ghostty host receives input, returning to Reading restores composer or key capture according to active surface.
- Confirmations: New Chat and Close Session trap focus, cancel restores the previous owner, confirm performs the destructive action only after acceptance.
- Recovery: exited, missing Codex, launch failure, and retry states do not leave the composer as an active keyboard owner.

## Task 4.1 Result

Task 4.1 is complete as an audit. The implementation has clear source-level protections for IME, native-prefix handoff, PTY-routed terminal-owned input, and blocked unsafe Enter. Tasks 4.2 through 4.6 remain required to provide manual QA evidence and close the distributed focus-state gaps.
