# Diagnostics And Temporary Path Audit

Scope: `Penggie/Sources/PenggieSessionModel.swift` and `Penggie/Sources/PenggieGhosttySession.swift`.

## Summary

The current diagnostics are DEBUG-gated and were useful for stabilizing resume selection, terminal interaction surfaces, active input style, and embedded Ghostty theme reload. They should remain available for P0 product QA until terminal-owned overlay and Raw Terminal visual parity milestones are complete, but they need explicit release hygiene before public distribution.

## Findings

| File | Diagnostic | Trigger | Output | Classification | Release action |
| --- | --- | --- | --- | --- | --- |
| `PenggieSessionModel.swift` | `PenggieResumePickerDiagnostic` | Resume picker has rows but not exactly one selected row. | `NSLog` only. | Keep for P0 QA. It directly diagnoses selected-row drift. | Keep DEBUG-only; remove or feature-flag after terminal-owned overlay confidence gates are fully covered by fixtures/tests. |
| `PenggieSessionModel.swift` | `PenggieTerminalInteractionSurfaceDiagnostic` | Resume terminal surface has candidates but no fresh confirmable selection. | `NSLog` and `NSTemporaryDirectory()/Penggie/terminal-interaction-surface-diagnostic.log`. | Keep for P0 QA. It records surface evidence, selection evidence, candidates, visible/screen/snapshot rows. | Keep DEBUG-only for now; before release either move behind explicit diagnostic opt-in or remove temp-file writes. |
| `PenggieSessionModel.swift` | `PenggieActiveInputStyleDiagnostic` | Non-resume screen with cursor/wide-background/inverse candidate lines. | `NSLog` only. | Keep until Raw Terminal visual parity is accepted. It proves raw terminal cell style for active input. | Keep DEBUG-only; remove or gate once renderer normalization and theme parity have regression coverage. |
| `PenggieSessionModel.swift` | `appendDebugDiagnostic` | Used by terminal interaction surface diagnostic. | Appends under `NSTemporaryDirectory()/Penggie/`. | Development diagnostic path. | Must be gated or removed before release; temp-file accumulation is not product QA by default. |
| `PenggieGhosttySession.swift` | `PenggieTerminalThemeDiagnostic` | Theme apply and Ghostty reload-config actions. | `NSLog` and `terminal-style-diagnostic.log` through `logDebugDiagnostic`. | Keep until theme/reload parity is accepted. | Keep DEBUG-only; before release move to explicit diagnostic mode or remove file write. |
| `PenggieGhosttySession.swift` | `PenggieTerminalStyleDiagnostic` | Screen model contains cursor, terminal marker, wide background, or inverse lines. | `NSLog` and `NSTemporaryDirectory()/Penggie/terminal-style-diagnostic.log`. | Keep for Raw Terminal visual parity and active-input verification. | Keep DEBUG-only for current P0/P1 work; remove or opt-in gate for release. |
| `PenggieGhosttySession.swift` | `PenggieCodexLaunchEnvironment` | Launch environment override creation. | `NSLog`. | Keep for development only; helps verify color env override behavior. | Remove or opt-in gate before public release. |
| `PenggieGhosttySession.swift` | `writePenggieEmbeddedTerminalConfig` temp files | Every embedded Ghostty session writes config/theme files. | `NSTemporaryDirectory()/Penggie/ghostty-embedded.conf`, `penggie-terminal-light.theme`, `penggie-terminal-dark.theme`. | Product runtime temp assets, not debug logs. | Keep. These are required to configure embedded Ghostty unless replaced by a stable app support location. |

## Product QA Diagnostics To Keep Temporarily

- Resume/terminal interaction selection diagnostics.
- Active input/terminal style diagnostics.
- Theme reload diagnostics.

These remain useful while `productize-ui-ux-contract` P0/P1 tasks validate terminal-owned overlays and Raw Terminal visual parity.

## Diagnostics To Gate Or Remove Before Release

- Temp-file log appenders under `NSTemporaryDirectory()/Penggie/*.log`.
- Launch environment diagnostic `NSLog`.
- Unconditional DEBUG theme reload logs if they are too noisy for internal QA builds.

## Required Follow-up

Task `10.4` must decide final release behavior:

1. Add an explicit diagnostic opt-in switch for file logs, or
2. Remove temp diagnostic file writes and keep only structured DEBUG console logs, or
3. Replace logs with stable test fixtures/source guards.

No release candidate should ship with unbounded temp log appends unless product QA explicitly depends on them and cleanup/rotation is defined.
