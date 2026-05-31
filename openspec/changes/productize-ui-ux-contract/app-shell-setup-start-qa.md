# App Shell Setup And Start QA Notes

Scope: task 2.2 in `productize-ui-ux-contract`.

Implementation files touched:

- `Penggie/Sources/PenggieRootView.swift`
- `Penggie/Sources/PenggieSessionModel.swift`

## Implemented Acceptance Criteria

| Requirement | Evidence |
| --- | --- |
| Missing folder has clear disabled state | `PenggieStartView` shows "Choose a project folder before creating a session."; `Create with Penggie` remains disabled because `canStartConfiguredCodex` is false. |
| Invalid or inaccessible folder has clear disabled state | `PenggieStartView` checks `PenggieSessionModel.isUsableWorkingDirectory(_:)` and shows "Penggie cannot access this folder. Choose another project folder."; the create action remains disabled. |
| Valid folder enables create | `canStartConfiguredCodex` still requires `canStartCodex` plus a usable selected directory. |
| Checking/launching startup states do not expose a fake enabled action | `PenggieStartView(startupState:)` renders progress copy and the create button is disabled because `canStartConfiguredCodex` is false during `.checkingCodex`, `.launching`, and initial Reading hold. |
| Folder change is blocked during startup | The folder button is disabled when `session.canStartCodex` is false, matching `chooseWorkingDirectory()` model guard. |
| Startup terminal noise remains hidden | `.checkingCodex`, `.launching`, and initial `.reading` hold still render setup/start state rather than `PenggieSessionView` or Raw Terminal. |
| Accessibility labels and hints exist | Folder button exposes label, value, and state-sensitive hint; Create button exposes label and state-sensitive hint; folder status text is a combined accessibility element. |
| Folder validity uses the launch-time guard | The setup UI and `canStartConfiguredCodex` both use `PenggieSessionModel.isUsableWorkingDirectory(_:)`, so invalid/missing folders share the same validation path as launch. |

## Manual QA Script

Run these after building the app:

1. Launch Penggie with no saved folder. Expected: setup page shows missing-folder helper text, `Create with Penggie` is disabled, folder button is first actionable setup control.
2. Choose a valid project folder. Expected: folder row shows the selected path, helper text disappears, `Create with Penggie` becomes enabled.
3. Choose or restore an inaccessible/non-directory path using a test defaults override if needed. Expected: invalid-folder helper text appears and `Create with Penggie` stays disabled.
4. Activate `Create with Penggie`. Expected: setup remains visible with checking/starting/preparing copy, progress indicator appears, folder change and duplicate create are blocked, no terminal startup noise appears.
5. Use keyboard-only navigation on setup. Expected: provider is informational, folder selection is reachable, then create is reachable only when enabled.
6. Inspect VoiceOver labels. Expected: folder control announces selected folder path and state hint; create control announces why it is unavailable during missing/invalid/startup states.

## Deferred To Later Tasks

- Task 2.3 will verify create/new-session path does not enter resume picker.
- Task 2.4 will harden all checking/launching blocked actions beyond setup controls.
- Task 2.5 will refine missing Codex, launch failed, and exited recovery.
- Task 2.7 will consolidate lifecycle unit/manual QA coverage for the full app-shell milestone.
