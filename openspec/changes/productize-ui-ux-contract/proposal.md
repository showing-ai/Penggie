## Why

The approved `define-product-grade-ui-ux` contract defines the product bar for Penggie, but it is still a UX contract rather than an execution plan. Penggie now needs a separate OpenSpec change that converts that contract into prioritized milestones, module ownership, QA fixtures, accessibility checks, and visual acceptance criteria without changing the Codex/Ghostty session architecture.

## What Changes

- Add a productization implementation plan for the approved UI/UX contract.
- Break the work into P0/P1/P2 milestones with explicit acceptance criteria.
- Map each workstream to the current Swift modules and test/fixture locations.
- Define manual QA, fixture, accessibility, visual QA, and regression guard requirements.
- Define implementation guardrails so product polish does not fork Codex, clone terminal-owned state, weaken Raw Terminal parity, or hide low-confidence projection.
- Do not implement application code in this change; this change only creates the execution specification.

## Capabilities

### New Capabilities

- `product-grade-ui-ux-implementation`: Defines how the approved product-grade UI/UX contract is translated into executable milestones, module ownership, QA assets, accessibility review, visual review, and non-goals.

### Modified Capabilities

- `penggie-app-shell`: Adds implementation requirements for setup/start, session lifecycle, chrome, recovery, and product-state QA.
- `reading-chat-ui`: Adds implementation requirements for transcript hierarchy, composer/IME/focus, Display AST fallback, and Reading QA fixtures.
- `terminal-interaction-surfaces`: Adds implementation requirements for native terminal-owned overlays, selection confidence, scroll/freshness behavior, accessibility state, and fixture coverage.
- `raw-terminal-fallback`: Adds implementation requirements for Raw Terminal audit/control parity, copy/paste and mouse-selection QA, same-session switching, and visual/theme parity.
- `codex-single-session`: Adds implementation requirements that all productization milestones preserve the real Codex CLI/Ghostty PTY as the only session authority.

## Impact

- Affected OpenSpec docs:
  - `openspec/changes/productize-ui-ux-contract/proposal.md`
  - `openspec/changes/productize-ui-ux-contract/design.md`
  - `openspec/changes/productize-ui-ux-contract/tasks.md`
  - `openspec/changes/productize-ui-ux-contract/specs/*/spec.md`
- Affected implementation areas for future work:
  - `Penggie/Sources/PenggieApp.swift`
  - `Penggie/Sources/PenggieRootView.swift`
  - `Penggie/Sources/PenggieSessionModel.swift`
  - `Penggie/Sources/PenggieComposerTextView.swift`
  - `Penggie/Sources/PenggieInteractionKeyCaptureView.swift`
  - `Penggie/Sources/PenggieNativeInteractionProjection.swift`
  - `Penggie/Sources/PenggieNativeInteractionPhase.swift`
  - `Penggie/Sources/PenggieCodexScreenKind.swift`
  - `Penggie/Sources/PenggieTerminalFrameNormalizer.swift`
  - `Penggie/Sources/PenggieDisplayAST*.swift`
  - `Penggie/Sources/PenggieDisplayRuleEngine.swift`
  - `Penggie/Sources/PenggieDisplayTranscriptReconciler.swift`
  - `Penggie/Sources/PenggieReadingTranscript.swift`
  - `Penggie/Sources/PenggieGhosttySession.swift`
  - `Penggie/Sources/PenggieTheme.swift`
  - `Penggie/Sources/PenggieThemeController.swift`
  - `Tests/PenggieCoreTests/Fixtures/`
  - `scripts/`
