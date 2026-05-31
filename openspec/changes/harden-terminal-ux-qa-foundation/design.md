## Context

`productize-ui-ux-contract` defines the full Penggie product-grade UI/UX implementation plan. External review approved the direction but flagged the first implementation slice as too broad if it starts with large UI work in `PenggieRootView`, overlay rendering, composer focus, theme, or Reading layout.

The current runtime already contains:

- Terminal frames and screen model normalization.
- Terminal behavior zoning and interaction surface projection.
- Resume/slash/model-style native surface rendering.
- Display AST fixture infrastructure.
- Raw Terminal same-session Ghostty surface.
- Session polling and PTY-routed input.

The risk is not missing architecture. The risk is unverified changes to cross-layer state machines. This change therefore creates the first implementation foundation: QA scripts, fixtures, and tests around the most regression-prone P0 behaviors.

## Goals / Non-Goals

**Goals:**

- Add a repeatable P0 manual QA script for terminal-grounded UX flows.
- Expand terminal interaction fixtures for selected, stale, ambiguous, low-confidence, scrolled/paged, approval, and permission surfaces.
- Expand Display AST fixtures for long session, CJK/table/code, tool-heavy, warning/status, and low-confidence fallback.
- Add tests for selection freshness, confirm gating, low-confidence blocking, and no local selected-index movement.
- Allow minimal implementation fixes only when required to make the new tests and fixtures pass.
- Preserve the current Codex/Ghostty same-session architecture.

**Non-Goals:**

- No visual polish pass.
- No large Reading transcript layout rewrite.
- No full overlay family redesign.
- No explicit resume product entry.
- No semantic source.
- No second Codex, SDK, `codex exec --json`, or user-visible alternate runtime.
- No local authoritative selected index, command list, model list, resume list, approval list, or permission list.

## Decisions

### Decision 1: Use tests and fixtures as the first implementation artifact

The first code-affecting work should be fixtures and tests, not UI rewrites. This makes terminal truth, selection confidence, confirmability, and fallback behavior executable before product polish starts.

Alternatives considered:

- Start with UI layout fixes. Rejected because layout changes can mask source-of-truth drift.
- Start with complete app shell lifecycle work. Rejected because it crosses launch, recovery, focus, Raw Terminal, and Reading in one change.

### Decision 2: Scope P0 to the smallest safety-critical surface contract

The initial implementation targets:

- Fresh selected-row evidence.
- Confirm gating for Enter/click/accessibility activation.
- Low-confidence blocking.
- Scrolled/paged selected-row fixture coverage.
- Approval/permission negative fixture coverage.
- Display fallback fixture coverage.
- Manual QA script for the cross-surface product flows.

This deliberately excludes broader polish such as density, theme, motion, and full accessibility completion.

### Decision 3: Manual QA script is a versioned artifact

Manual QA should live in the repository, likely under `docs/qa/` or `scripts/qa/`, with exact scenarios, setup, expected result, and failure examples. It should be useful before and after automated tests exist.

The script must cover:

- Setup/create path.
- Missing/failed/exited states.
- Slash/model navigation.
- Resume selected/stale/low-confidence states.
- Approval/permission blocked confirmation.
- Raw Terminal round trip during ordinary Reading and terminal-owned surfaces.
- New Chat/Close confirmation.

### Decision 4: Fixtures must encode source evidence, not just rendered rows

Terminal interaction fixtures must include enough terminal-frame evidence to prove why a row is selected or why selection is low confidence. Display fixtures must include raw text and expected fallback/classification behavior.

Fixture README files must describe:

- Source terminal facts.
- Expected surface kind.
- Expected selected-row evidence and confidence.
- Expected confirmability.
- Expected fallback/degraded behavior.
- Negative behavior that must not happen.

### Decision 5: Implementation fixes must be test-driven and minimal

If a new fixture exposes a bug, the fix should touch only the projection, gating, or fallback path required for the test. It must not broaden into visual polish or local state ownership.

Examples of acceptable implementation fixes:

- Correct stale selected-row handling.
- Consume unsafe Enter when selection is low confidence.
- Preserve rows while blocking confirmation.
- Ensure a scrolled selected row is represented in projection metadata.

Examples of unacceptable implementation in this change:

- Rebuilding the resume UI visual design.
- Adding a local selected index to smooth highlight movement.
- Adding a local resume/session list.
- Reworking the Reading transcript hierarchy beyond fixture fallback correctness.

## Risks / Trade-offs

- **Risk: The foundation change grows into product polish.** -> Mitigation: tasks explicitly forbid visual polish and large UI rewrites.
- **Risk: Fixtures are too synthetic to catch real bugs.** -> Mitigation: fixture READMEs must state source terminal facts and include negative cases from observed regressions.
- **Risk: Manual QA script becomes stale.** -> Mitigation: treat it as a versioned acceptance artifact and update it when specs or behavior change.
- **Risk: Tests require minor code changes despite the foundation scope.** -> Mitigation: allow minimal test-driven fixes only for projection/gating/fallback behavior.
- **Risk: Existing untracked OpenSpec changes make review confusing.** -> Mitigation: keep this change independent and do not edit `define-product-grade-ui-ux` or `productize-ui-ux-contract` except if explicitly requested.

## Migration Plan

1. Add QA script and fixture READMEs.
2. Add or update terminal interaction fixtures.
3. Add or update Display AST fallback fixtures.
4. Add tests that assert freshness, confirm gate, low-confidence block, and fallback behavior.
5. Make minimal implementation fixes only where tests fail.
6. Validate with targeted `swift test` filters and `openspec validate harden-terminal-ux-qa-foundation --strict`.

No runtime migration is required.

## Open Questions

- Should the manual QA artifact live under `docs/qa/`, `scripts/qa/`, or `Tests/PenggieCoreTests/Fixtures/README`?
- Which current diagnostic captures should be converted into stable fixtures before new fixture generation?
- Should this change include accessibility smoke tests now, or only manual accessibility QA script steps?
