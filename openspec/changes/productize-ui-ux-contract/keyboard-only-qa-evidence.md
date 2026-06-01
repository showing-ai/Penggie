# Keyboard-Only QA Evidence

Task: `4.6 Add manual keyboard-only QA that completes setup, prompt submission, slash/model selection, resume selection, approval/permission choice, Raw Terminal switch, New Chat confirmation, and Close Session confirmation.`

## Scope

This evidence records that the manual keyboard-only QA scenario exists in the product-grade UI/UX QA script. It does not claim the scenario has been executed against a live build.

## Manual QA Coverage

`product-grade-ui-ux-manual-qa-script.md` contains `QA-AX-001: Keyboard-only complete journey`, covering:

- Setup from the Penggie setup surface.
- Prompt submission.
- Slash/model selection.
- Resume selection.
- Approval/permission choice.
- Raw Terminal switch.
- New Chat confirmation.
- Close Session confirmation.
- Light and dark theme runs.
- A keyboard-only run followed by a VoiceOver run.

## Acceptance Boundary

This task is complete because it asks to add the manual keyboard-only QA path. Runtime validation remains open under the specific validation tasks:

- `3.10` for slash/model/resume/approval/permission overlay behavior in Reading and Raw Terminal.
- `4.2` through `4.5` for IME, composer, slash handoff, and focus transition validation.
- `6.2` through `6.6` for Raw Terminal same-session, focus, clipboard, mouse, and visual parity validation.

## Non-Goals

- Do not mark live keyboard-only QA as passed without running it.
- Do not synthesize terminal-owned selection state for keyboard-only accessibility.
- Do not add local command/model/resume/approval/permission lists for QA convenience.
- Do not launch a second Codex or Raw Terminal session for the user-visible workflow.
