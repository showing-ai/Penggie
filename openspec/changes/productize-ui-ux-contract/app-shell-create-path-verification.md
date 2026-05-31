# App Shell Create Path Verification

Scope: task 2.3 in `productize-ui-ux-contract`.

## Verified Path

`Create with Penggie` is the create/new-session action. It is not a resume action.

| Entry Point | Evidence |
| --- | --- |
| Setup button | `PenggieStartView` calls `session.startWithCodex()` when the create button is activated. |
| App command menu | `PenggieApp` command menu `Create with Penggie` calls `session.startWithCodex()` directly. |
| Session model create path | `PenggieSessionModel.startWithCodex()` checks configuration, stores the working directory, enters `.checkingCodex`, verifies Codex availability, enters `.launching`, and calls `launchCodexSession()`. |
| Ghostty session launch | `launchCodexSession()` constructs `PenggieGhosttySession(codexPath:workingDirectory:themeConfiguration:)` and resets resume projection state before entering `.reading`. |
| Source guard | `scripts/qa/check-p0-session-lifecycle-source.sh` rejects `resume`, `--last`, and `codex resume` inside `startWithCodex()` and `launchCodexSession()`, and verifies the app-level menu command calls `session.startWithCodex()` directly. |

## Acceptance Criteria

- `Create with Penggie` SHALL start the regular Codex CLI create/new-session path.
- `Create with Penggie` SHALL NOT append `resume`, `--last`, or a saved session identifier.
- `Create with Penggie` SHALL NOT locally choose a saved session.
- Resume picker UI SHALL appear only when the real Codex terminal screen enters resume picker mode.
- Resume projection state SHALL be cleared before a newly launched session begins polling terminal frames.

## Manual QA Script

1. Start Penggie from the setup screen with a valid project folder.
2. Expected: setup transitions through checking/starting/preparing copy and then reaches a new Reading session or normal Codex chat screen.
3. Expected: the resume picker does not appear unless the launched Codex CLI itself displays a resume picker.
4. Open the app `Session` menu and choose `Create with Penggie` when no session is active.
5. Expected: the command follows the same behavior as the setup button.
6. If Codex independently opens a resume picker, switch to Raw Terminal and verify the same terminal-owned picker is visible; this is not a Penggie create-path fork.

## Non-Goals

- Do not add a local saved-session list.
- Do not add local resume selected-index state.
- Do not create a second Codex process to discover sessions.
- Do not hide a real Codex-owned resume picker if the PTY enters that screen.
