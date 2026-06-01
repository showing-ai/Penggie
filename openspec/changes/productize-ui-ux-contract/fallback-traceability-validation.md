# Fallback Traceability Validation

Task: 5.6

## Scope

This validation covers low-confidence Display AST fallback behavior for Reading UI. It does not introduce a second Codex session, local semantic state, or a SwiftUI overlay that edits terminal-owned facts.

## Evidence

- `PenggieDisplayFixtureTests.lowConfidenceDisplayFixtureUsesFallbackWithoutInventingMarkdown`
  verifies the `low-confidence-fallback` fixture preserves visible terminal evidence without upgrading it into markdown paragraphs or terminal-owned overlay content.
- `PenggieDisplayFixtureTests.lowConfidenceFallbackExposesTraceabilityAndPreservesTerminalEvidence`
  verifies fallback blocks retain:
  - `DisplayDocument.Metadata.source == terminalProjection`
  - terminal dimensions
  - fallback confidence
  - non-empty fallback messages
  - fallback reason codes for generic visible text and terminal-shaped table output
  - every visible raw terminal line from the fixture
- `PenggieSessionLifecyclePolicyTests.lowConfidenceFallbackAuditCanSwitchToRawTerminalWhenSessionIsInspectable`
  verifies that stable Reading sessions can switch to Raw Terminal audit, while unstable pre-inspectable Reading sessions cannot expose Raw Terminal controls.

## Contract

When Display AST classification is low confidence:

- Reading must preserve useful visible terminal text.
- Fallback blocks must carry traceability where practical through fallback code/message and terminal projection metadata.
- Reading must not invent markdown semantics or hide raw terminal evidence.
- Raw Terminal audit remains available for stable inspectable sessions and remains blocked before a stable inspectable terminal surface exists.

## Non-Goals

- Do not infer additional Codex semantic roles from low-confidence text.
- Do not use a separate Codex or Ghostty session for audit.
- Do not localize terminal-owned state into SwiftUI.
- Do not expose Raw Terminal before the session is inspectable.
