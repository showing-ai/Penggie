## Why

`productize-ui-ux-contract` is broad enough to guide the full product-grade implementation, but its P0 scope crosses shell lifecycle, Reading, overlays, composer, Raw Terminal, accessibility, and theme. The first implementation change should reduce risk by adding P0 QA guardrails, fixture coverage, and core terminal-owned safety rules before large UI product code is changed.

## What Changes

- Add a P0 manual QA script for the terminal-grounded product flows: setup/create, slash/model, resume, approval/permission, Raw Terminal round trip, New Chat/Close, missing/failed/exited states, and low-confidence projection.
- Add fixture requirements and initial fixture expansion for terminal interaction surfaces:
  - selected rows
  - scrolled/paged lists
  - low-confidence and stale selection
  - blocked Enter
  - approval and permission negative cases
- Add fixture requirements and initial fixture expansion for Display AST fallback:
  - long sessions
  - CJK/table/code output
  - tool-heavy output
  - warning/status rows
  - low-confidence fallback
- Harden the core terminal-owned safety contract with tests first:
  - selection freshness
  - confirm gate
  - low-confidence block
  - no local selected-index movement
  - PTY-routed input only
- Allow only minimal implementation code needed to satisfy the new tests/fixtures.
- Defer visual polish, large Reading rewrites, full overlay family redesign, explicit resume product entry, semantic sources, and any alternate Codex runtime.

## Capabilities

### New Capabilities

- `terminal-ux-qa-foundation`: Defines the first product-grade implementation foundation: P0 manual QA scripts, fixture requirements, and core terminal-owned interaction safety gates.

### Modified Capabilities

- `terminal-interaction-surfaces`: Adds executable fixture and test requirements for selection freshness, confirm gating, low-confidence states, scrolled/paged surfaces, approval/permission negative cases, and blocked unsafe Enter.
- `reading-chat-ui`: Adds executable fixture and test requirements for Display AST fallback, long sessions, transcript pollution prevention, CJK/table/code preservation, and low-confidence display handling.
- `raw-terminal-fallback`: Adds executable manual QA requirements for same-session Raw Terminal round trips and Raw Terminal parity during terminal-owned interaction states.
- `penggie-app-shell`: Adds executable manual QA requirements for setup/create, missing/failed/exited states, New Chat, Close Session, and the create-vs-resume product path.
- `codex-single-session`: Adds implementation guardrails ensuring the first P0 foundation work does not introduce a second Codex runtime, local Codex-owned lists, or local selected-index authority.

## Impact

- Affected future implementation files:
  - `Penggie/Sources/PenggieNativeInteractionProjection.swift`
  - `Penggie/Sources/PenggieNativeInteractionPhase.swift`
  - `Penggie/Sources/PenggieCodexScreenKind.swift`
  - `Penggie/Sources/PenggieTerminalFrameNormalizer.swift`
  - `Penggie/Sources/PenggieSessionModel.swift`
  - `Penggie/Sources/PenggieRootView.swift`
  - `Penggie/Sources/PenggieDisplayAST*.swift`
  - `Penggie/Sources/PenggieDisplayRuleEngine.swift`
  - `Penggie/Sources/PenggieDisplayTranscriptReconciler.swift`
  - `Penggie/Sources/PenggieReadingTranscript.swift`
  - `Penggie/Sources/PenggieGhosttySession.swift`
- Affected test and QA areas:
  - `Tests/PenggieCoreTests/Fixtures/terminal-interaction-surfaces/`
  - `Tests/PenggieCoreTests/Fixtures/agent-terminal-display/`
  - `Tests/PenggieCoreTests/PenggieTerminalInteractionSurfaceTests.swift`
  - `Tests/PenggieCoreTests/PenggieNativeInteractionProjectionTests.swift`
  - `Tests/PenggieCoreTests/PenggieDisplayFixtureTests.swift`
  - `Tests/PenggieCoreTests/PenggieSessionModelPollingTests.swift`
  - `scripts/`
- No app UI product rewrite is included in this change.
