# Define Product-Grade Penggie UI/UX

## Product Goal

Penggie is a native macOS agent workbench for the complete local Codex CLI session.

It does not replace Codex, hide Codex, or simulate Codex. It productizes the real local Codex CLI into a mature desktop experience: Reading provides high-signal work, Raw Terminal provides same-session audit and full fidelity, and every terminal-owned interaction remains sourced from the real Codex/Ghostty PTY state.

## Why

Penggie already has the basic product loop implemented: start/setup, selected project folder, real Codex CLI launch, Ghostty-backed PTY, Reading, Raw Terminal fallback, native terminal-owned interaction projection, composer/IME handling, Display AST/fallback rendering, error states, New Chat/Close Session, and core tests.

The remaining product risk is not whether Penggie can show the experience. The risk is whether the implemented primitives behave like a mature macOS workbench under real use: long sessions, uncertain projection, slash/model/resume/approval flows, CJK and table-heavy output, IME, resize/repaint, process exits, and recovery.

This change rewrites the UI/UX plan as a product-grade contract instead of a principle list. It defines the user journeys, information architecture, state matrix, interaction contracts, component specifications, terminal source-of-truth rules, visual system requirements, accessibility requirements, and QA matrix needed to evaluate maturity.

## Implemented Baseline

These capabilities exist and should be treated as the baseline, not as future scope:

- Real Codex CLI launched through a Ghostty-backed PTY.
- Reading and Raw Terminal over the same Codex process, cwd, and terminal session.
- Penggie-owned start/setup surface with project folder selection and `Create with Penggie`.
- Codex availability, launch failure, missing CLI, exited, and closed states.
- Reading empty state, transcript, composer, send flow, Working/Worked timing, and disclosure blocks.
- AppKit-backed composer with IME-aware marked text behavior.
- Native slash/model-style composer overlays and full-page terminal-owned surfaces such as resume and approval-style choices.
- Terminal interaction surface model with candidates, selected-row confidence, freshness, evidence, and input routing policy.
- Display AST, terminal frame normalization, display rule engine, renderer, transcript reconciler, and fallback/preformatted rendering.
- No local slash command table, model table, approval table, or selected-index state.
- Unit tests for core display, transcript, native interaction, theme, and polling behavior.

## What Changes

- Reposition Penggie as a complete local Codex CLI workbench, not merely a Reading/Terminal toggle.
- Define non-negotiable product invariants around same-session continuity and terminal-owned state.
- Define complete user journeys for setup, normal work, long-running work, native command flows, Raw Terminal inspection, failure, and recovery.
- Define a state matrix with visible UI, allowed actions, blocked actions, keyboard owner, prompt availability, Raw Terminal availability, and recovery path.
- Define Reading transcript anatomy, composer/input behavior, terminal-owned overlay behavior, Raw Terminal behavior, visual system expectations, and accessibility expectations.
- Convert the quality bar into a QA matrix with concrete acceptance criteria.
- Clarify that future semantic sources may improve Reading but cannot take ownership from the real Codex/Ghostty session.

## Non-Goals

- Do not implement application UI changes in this change.
- Do not replace Codex CLI, Ghostty PTY, or Raw Terminal with a custom runtime, SDK session, or `codex exec --json` session.
- Do not create a web chat shell, IDE, generic terminal replacement, multi-provider launcher, session inbox, or dashboard.
- Do not introduce local slash command lists, model lists, approval choices, permission choices, resume session lists, or selected indexes.
- Do not use animation, brand art, gradients, cards, or visual polish to hide missing state or uncertain projection.
- Do not force all terminal output into Markdown or claim original Markdown can always be recovered from terminal display state.
- Do not redesign the implemented Display AST, native terminal interaction projection, or embedded Ghostty foundation as part of this UX exploration.

## Impact

- Affected specs:
  - `penggie-app-shell`
  - `reading-chat-ui`
  - `raw-terminal-fallback`
  - `codex-single-session`
  - `terminal-interaction-surfaces`
- Affected docs:
  - Product-grade UI/UX contract under this OpenSpec change.
