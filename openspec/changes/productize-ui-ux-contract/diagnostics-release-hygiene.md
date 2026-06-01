# Diagnostics Release Hygiene

Scope: `productize-ui-ux-contract` task 10.4.

## Decision

Temp-file diagnostic logs are disabled by default. DEBUG console diagnostics remain available for local QA, but persistent diagnostic `.log` files under `NSTemporaryDirectory()/Penggie/` require an explicit opt-in.

## Runtime Behavior

| Output | Default behavior | Opt-in | Reason |
| --- | --- | --- | --- |
| `PenggieResumePickerDiagnostic` console log | DEBUG-only console output | N/A | Keeps selected-row drift diagnosable without persistent temp files. |
| `PenggieTerminalInteractionSurfaceDiagnostic` console log | DEBUG-only console output | N/A | Keeps surface confidence and confirm gate evidence visible during local QA. |
| `terminal-interaction-surface-diagnostic.log` | Disabled | `PENGGIE_DEBUG_FILE_DIAGNOSTICS=1` | File logs are useful for deep local debugging but should not accumulate by default. |
| `PenggieActiveInputStyleDiagnostic` console log | DEBUG-only console output | N/A | Keeps terminal style evidence available while Raw Terminal parity is under review. |
| `PenggieTerminalThemeDiagnostic` console log | DEBUG-only console output | N/A | Keeps Ghostty reload and theme application evidence available. |
| `terminal-style-diagnostic.log` | Disabled | `PENGGIE_DEBUG_FILE_DIAGNOSTICS=1` | File logs are useful for deep renderer/theme debugging but should not accumulate by default. |
| `PenggieCodexLaunchEnvironment` console log | Disabled | `PENGGIE_DEBUG_LAUNCH_ENV_DIAGNOSTIC=1` | Launch environment details are development-only and too noisy for normal QA. |

Accepted truthy values for diagnostic opt-in flags are `1`, `true`, and `yes`.

## Product Runtime Temp Assets

Product runtime temp assets remain enabled:

- `ghostty-embedded.conf`
- `penggie-terminal-light.theme`
- `penggie-terminal-dark.theme`

These files configure the embedded Ghostty surface. They are not diagnostic logs and must not be removed as part of 10.4 unless a replacement configuration location is introduced.

## Source Guard

Run:

```bash
scripts/qa/check-diagnostics-release-hygiene.sh
```

The guard verifies:

- file diagnostic writes are gated by `PENGGIE_DEBUG_FILE_DIAGNOSTICS`;
- `PenggieCodexLaunchEnvironment` is gated by `PENGGIE_DEBUG_LAUNCH_ENV_DIAGNOSTIC`;
- product runtime Ghostty config/theme temp files remain documented;
- task 10.4 stays marked complete only while the source and documentation gates hold.

## Non-Goals

- Do not remove DEBUG console diagnostics that remain useful for P0/P1 QA.
- Do not remove embedded Ghostty runtime config/theme temp files.
- Do not add UI controls for diagnostics.
- Do not route diagnostics through a second Codex or Ghostty session.
