# Product Copy Review

Task: `10.5 Review product copy for setup, low-confidence syncing, projection degraded, missing Codex, launch failed, process exited, confirmation, approval, permission, and Raw Terminal audit paths.`

## Scope

This review records the current product copy contract for user-visible
state transitions and safety-sensitive terminal-owned surfaces. It is a copy
review, not a runtime change.

The review keeps the core Penggie invariant intact:

- Terminal-owned state belongs to Codex/Ghostty/PTTY.
- Penggie copy may explain state, confidence, and available recovery actions.
- Penggie copy must not imply that Reading owns resume, slash, model, approval,
  permission, or modal-choice state.
- Raw Terminal is described only as the same-session audit/control surface, not
  as a second or reconstructed session.

## Reviewed Copy Paths

| Path | Current copy source | Review status | Acceptance rule |
| --- | --- | --- | --- |
| Setup welcome | `PenggieStartView`: `Welcome to Penggie`, `Choose a project folder, then create with Penggie.` | Accepted | Copy is product-facing and does not mention raw terminal or startup internals. |
| Missing folder | `PenggieStartView.folderStatusText`: `Choose a project folder before creating a session.` | Accepted | Copy gives a concrete next action and keeps create disabled until valid input exists. |
| Invalid folder | `PenggieStartView.folderStatusText`: `Penggie cannot access this folder. Choose another project folder.` | Accepted | Copy names the problem without exposing filesystem internals. |
| Create action | `PenggieStartView`: `Create with Penggie` | Accepted | Copy must continue to launch a new/create path, not a resume path, unless a future explicit resume entry is added. |
| Checking Codex | `PenggieStartupState.checkingCodex`: `Checking Codex`; `Penggie is checking that the Codex CLI is available.` | Accepted | Copy describes a blocked setup hold; no prompt or Raw Terminal action should be available. |
| Starting Codex | `PenggieStartupState.launching`: `Starting Codex`; `Penggie is starting the local Codex session.` | Accepted | Copy avoids leaking startup terminal text into Reading. |
| Preparing Reading | `PenggieStartupState.waitingForCodex`: `Preparing Reading`; `Penggie is waiting for the first stable terminal frame.` | Accepted with follow-up | Accurate for engineering, but slightly technical. Future product polish may replace "terminal frame" with "Codex screen" if design wants less implementation language. |
| Low-confidence selection | `PenggieTerminalSurfaceStatusCopy.syncingSelection` rendered in terminal-owned surfaces | Accepted | Copy may explain syncing, but rows must remain visible when useful and Enter must stay blocked until fresh reliable selection evidence exists. |
| Projection degraded / fallback | Release/manual QA docs require visible degraded/fallback behavior and Raw Terminal audit availability | Accepted as contract, implementation-specific copy remains surface-dependent | Copy must not hide low-confidence state behind optimistic transcript or selected-row certainty. |
| Missing Codex | `PenggieRootView.codexMissingState`: `Codex CLI not found`; `Install Codex CLI or make sure it is available in your login shell PATH.`; `Check Again`; `Choose Folder` | Accepted | Copy provides recovery actions and must not offer Raw Terminal because no inspectable terminal surface exists. |
| Launch failed | `PenggieRootView.launchFailedState`: `Codex failed to launch`; raw launch message; `Try Again`; `Choose Folder` | Accepted with caution | Raw launch messages are useful for recovery, but must remain bounded and not replace product-level title/action copy. |
| Process exited with terminal surface | `PenggieRootView.exitedState`: `Codex session ended`; `The Codex process exited. You can start a fresh chat, inspect the raw terminal output, or close this session.`; `Start Again`; `Inspect Raw Terminal`; `Close Session` | Accepted | Copy correctly offers Raw Terminal only when a retained Ghostty surface exists. |
| Process exited without terminal surface | `PenggieRootView.exitedState`: `Codex session ended`; `The Codex process exited. You can start a fresh chat or close this session.`; `Start Again`; `Close Session` | Accepted | Copy correctly omits Raw Terminal when there is no inspectable surface. |
| New Chat confirmation | `Confirmation.newChat`: `Start a new chat?`; `This ends the current session and starts a fresh Codex session in this window.`; `Start New Chat` | Accepted | Copy is destructive, specific, and preserves the current session until confirmed. |
| Close Session confirmation | `Confirmation.closeSession`: `End this Codex session?`; `This ends the current Codex session and returns to the Penggie start screen.`; `End Session` | Accepted | Copy is destructive and distinguishes close from starting a fresh chat. |
| Approval prompt | `PenggieReadingChatView.modalChoiceState`: `Approval required`; `Use ↑/↓ to choose, Enter to confirm, or Esc to cancel.` | Accepted as framing copy | The actual choice text must remain terminal-owned. Penggie must not replace Codex approval choices with local product copy. |
| Permission prompt | `PenggieReadingChatView.modalChoiceState`: `Permission required`; `Use ↑/↓ to choose, Enter to confirm, or Esc to cancel.` | Accepted as framing copy | The actual choice text must remain terminal-owned. Activation must follow the same fresh exactly-one confirmable gate as Enter. |
| Raw Terminal mode toggle | `PenggieModeToggleButton`: `Show Raw Terminal` / `Show Reading` | Accepted | Copy names the audit/control surface without implying a second session. |
| Exited Raw Terminal inspection | `PenggieExitedTerminalInspectionView`: `Raw Terminal inspection` | Accepted | Copy is specific to retained exited-output inspection and must remain backed by the same retained `PenggieGhosttySession`. |
| Raw Terminal empty fallback | `PenggieRawTerminalPlaceholder`: `Raw Terminal`; `No active Codex session.` | Accepted | Copy is plain and does not promise terminal audit when no session exists. |

## Copy Acceptance Checklist

Future copy changes in these paths must pass all of the following checks:

- Setup copy gives a concrete next action and never exposes prompt input before
  launch is inspectable.
- `Create with Penggie` continues to mean create/new session, not implicit
  resume.
- Recovery copy distinguishes missing Codex, launch failure, exited-with-terminal,
  and exited-without-terminal.
- Raw Terminal copy appears only when a live or retained inspectable Ghostty
  surface exists.
- Low-confidence copy keeps useful rows visible and blocks unsafe confirmation.
- Approval and permission framing copy does not rewrite or locally own Codex
  choices.
- Confirmation copy names the destructive result and the destructive action
  does not run before confirmation.
- Copy remains understandable with VoiceOver, keyboard-only navigation, and
  narrow windows.

## Accepted Follow-ups

These are copy follow-ups, not blockers for task 10.5:

- Consider replacing `first stable terminal frame` with less technical product
  language after P1 accessibility/dynamic announcement work decides the final
  announcement vocabulary.
- Align dynamic announcements with the reviewed strings once task 7.3 is
  implemented or verified.
- If Penggie adds an explicit product resume entry in the future, it must use
  separate setup copy and must not change `Create with Penggie` semantics.
- If approval/permission surfaces gain richer native framing, the choice labels
  still must come from the terminal-owned surface projection.

## Non-Goals

- Do not change application source copy in this review.
- Do not introduce local resume, command, model, approval, permission, or modal
  choice lists.
- Do not make product copy drive selected state, confirmability, or session
  lifecycle.
- Do not use Raw Terminal copy to mask low-confidence Reading projection.
- Do not use a second Codex process, SDK session, or separate Raw Terminal as
  product-copy evidence.

## Verification

- Source review: `PenggieRootView.swift`, `PenggieSessionModel.swift`, and
  `PenggieCodexScreenKind.swift`.
- Related QA docs: `app-shell-recovery-qa.md`,
  `app-shell-confirmation-qa.md`, `product-grade-ui-ux-manual-qa-script.md`,
  and `release-readiness-checklist.md`.
- This task is documentation-only; no Swift runtime behavior is changed.
