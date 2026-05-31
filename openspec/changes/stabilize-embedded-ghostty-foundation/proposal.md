## Why

Penggie's Reading UI, Raw Terminal, native slash overlay, and native resume picker all depend on the same embedded Ghostty/Codex PTY, but the terminal substrate is not yet a reliable source of visual truth. Raw Terminal colors can diverge from Ghostty.app, and native UI projections still infer selected rows from weak text/style summaries instead of a stable terminal-owned screen model.

This change rebuilds the foundation before continuing startup/resume polish: verify Codex color output first, make embedded Ghostty theme/color-scheme behavior explicit, and export enough terminal style data for UI projections without local session lists or selected indexes.

## What Changes

- Add a foundation contract for embedded Ghostty configuration, process environment, color/theme parity, screen model export, and terminal-owned selection projection.
- Replace global process-environment mutation as the primary color-control mechanism with explicit per-surface environment overrides where Ghostty supports them.
- Move Raw Terminal away from a hand-written light palette and high `minimum-contrast` default toward Ghostty theme-based rendering with light/dark color-scheme synchronization.
- Expand the embedded screen model from line text plus coarse counters toward viewport-row style facts, including style runs or equivalent fingerprints for foreground, background, bold, faint, inverse, and background-only cells.
- Clarify that Ghostty text selection is not the same as Codex TUI current-row selection; native UI must infer current rows from terminal style facts and markers, not from a local selected index.
- Keep resume picker and slash overlay source-of-truth in the active Codex/Ghostty session while sharing only the common terminal selection projection primitive.

## Capabilities

### New Capabilities

- `embedded-ghostty-foundation`: Defines the substrate contract for embedded Ghostty environment, theme/color-scheme parity, screen model style export, and terminal-owned selection facts.

### Modified Capabilities

- `codex-single-session`: Strengthen the single-session contract so environment/theme/screen-model fixes preserve one Codex process and one Ghostty PTY.
- `raw-terminal-fallback`: Require Raw Terminal to use the same embedded Ghostty color pipeline and theme behavior as the source of visual truth.
- `reading-chat-ui`: Require native resume/slash projections to consume terminal-owned marker/style facts without local selected-index state.

## Impact

- Affected code: `PenggieGhosttySession.swift`, `PenggieSessionModel.swift`, `PenggieCodexScreenKind.swift`, `PenggieNativeInteractionProjection.swift`, `PenggieRootView.swift`, and `patches/ghostty/0001-embedded-screen-model-api.patch`.
- Affected vendor integration: Ghostty embedded API usage for per-surface environment variables, app/surface color-scheme synchronization, and screen model export.
- Verification impact: requires Raw Terminal ANSI/environment probes, Codex resume picker visual checks, Swift projection tests, Ghostty substrate rebuild, full Swift tests, and macOS app build.
- Non-impact: does not replace Codex resume with a local session database, split Reading and Raw Terminal into separate PTYs, change Codex key routing, or couple this work to Markdown/table rendering.
