# Diagnostics And Temporary Path Audit

Scope: `Penggie/Sources/PenggieSessionModel.swift` and `Penggie/Sources/PenggieGhosttySession.swift`.

## Summary

The current diagnostics are DEBUG-gated and were useful for stabilizing resume selection, terminal interaction surfaces, active input style, and embedded Ghostty theme reload. They should remain available for P0 product QA until terminal-owned overlay and Raw Terminal visual parity milestones are complete, but they need explicit release hygiene before public distribution.

## Findings

| File | Diagnostic | Trigger | Output | Classification | Release action |
| --- | --- | --- | --- | --- | --- |
| `PenggieSessionModel.swift` | `PenggieResumePickerDiagnostic` | Resume picker has rows but not exactly one selected row. | `NSLog` only. | Keep for P0 QA. It directly diagnoses selected-row drift. | Keep DEBUG-only; remove or feature-flag after terminal-owned overlay confidence gates are fully covered by fixtures/tests. |
| `PenggieSessionModel.swift` | `PenggieTerminalInteractionSurfaceDiagnostic` | Resume terminal surface has candidates but no fresh confirmable selection. | `NSLog` and opt-in `NSTemporaryDirectory()/Penggie/terminal-interaction-surface-diagnostic.log`. | Keep for P0 QA. It records surface evidence, selection evidence, candidates, visible/screen/snapshot rows. | Temp-file log writes are now gated behind `PENGGIE_DEBUG_FILE_DIAGNOSTICS`; DEBUG console output remains available. |
| `PenggieSessionModel.swift` | `PenggieActiveInputStyleDiagnostic` | Non-resume screen with cursor/wide-background/inverse candidate lines. | `NSLog` only. | Keep until Raw Terminal visual parity is accepted. It proves raw terminal cell style for active input. | Keep DEBUG-only; remove or gate once renderer normalization and theme parity have regression coverage. |
| `PenggieSessionModel.swift` | `appendDebugDiagnostic` | Used by terminal interaction surface diagnostic. | Opt-in append under `NSTemporaryDirectory()/Penggie/`. | Development diagnostic path. | Temp-file log appenders under `NSTemporaryDirectory()/Penggie/*.log` are now gated by `PENGGIE_DEBUG_FILE_DIAGNOSTICS`. |
| `PenggieGhosttySession.swift` | `PenggieTerminalThemeDiagnostic` | Theme apply and Ghostty reload-config actions. | `NSLog` and opt-in `terminal-style-diagnostic.log` through `logDebugDiagnostic`. | Keep until theme/reload parity is accepted. | DEBUG console output remains available; temp-file log writes are gated by `PENGGIE_DEBUG_FILE_DIAGNOSTICS`. |
| `PenggieGhosttySession.swift` | `PenggieTerminalStyleDiagnostic` | Screen model contains cursor, terminal marker, wide background, or inverse lines. | `NSLog` and opt-in `NSTemporaryDirectory()/Penggie/terminal-style-diagnostic.log`. | Keep for Raw Terminal visual parity and active-input verification. | DEBUG console output remains available; temp-file log writes are gated by `PENGGIE_DEBUG_FILE_DIAGNOSTICS`. |
| `PenggieGhosttySession.swift` | `PenggieCodexLaunchEnvironment` | Launch environment override creation. | Opt-in `NSLog`. | Keep for development only; helps verify color env override behavior. | `PenggieCodexLaunchEnvironment` is now gated by `PENGGIE_DEBUG_LAUNCH_ENV_DIAGNOSTIC`. |
| `PenggieGhosttySession.swift` | `writePenggieEmbeddedTerminalConfig` temp files | Every embedded Ghostty session writes config/theme files. | `NSTemporaryDirectory()/Penggie/ghostty-embedded.conf`, `penggie-terminal-light.theme`, `penggie-terminal-dark.theme`. | Product runtime temp assets, not debug logs. | Keep. These are required to configure embedded Ghostty unless replaced by a stable app support location. |

## Product QA Diagnostics To Keep Temporarily

- Resume/terminal interaction selection diagnostics.
- Active input/terminal style diagnostics.
- Theme reload diagnostics.

These remain useful while `productize-ui-ux-contract` P0/P1 tasks validate terminal-owned overlays and Raw Terminal visual parity.

## Diagnostics Gated For Release Hygiene

- Temp-file log appenders under `NSTemporaryDirectory()/Penggie/*.log` are now gated by `PENGGIE_DEBUG_FILE_DIAGNOSTICS`.
- `PenggieCodexLaunchEnvironment` is now gated by `PENGGIE_DEBUG_LAUNCH_ENV_DIAGNOSTIC`.
- DEBUG console diagnostics remain available for local QA while P0/P1 terminal-owned overlays and Raw Terminal visual parity are still being validated.

## Required Follow-up

Task `10.4` final behavior:

1. File diagnostics require `PENGGIE_DEBUG_FILE_DIAGNOSTICS=1`, `true`, or `yes`.
2. Launch environment diagnostics require `PENGGIE_DEBUG_LAUNCH_ENV_DIAGNOSTIC=1`, `true`, or `yes`.
3. Product runtime temp assets remain enabled because embedded Ghostty requires `ghostty-embedded.conf`, `penggie-terminal-light.theme`, and `penggie-terminal-dark.theme`.
4. Release hygiene is enforced by `scripts/qa/check-diagnostics-release-hygiene.sh`.
