## 1. P0 QA Foundation Scope

- [x] 1.1 Create a tracked P0 manual QA script for setup/create, slash/model, resume, approval/permission, Raw Terminal round trip, New Chat/Close, missing/failed/exited states, and low-confidence projection.
- [x] 1.2 Add a short implementation guardrail section to the QA script: no local selected index, no local Codex-owned lists, no second Codex runtime, no broad visual polish, no large Reading rewrite.
- [x] 1.3 Add expected-result and failure-example fields for every manual QA scenario.
- [x] 1.4 Decide and document where manual QA artifacts live, using `docs/qa/` or another repository-tracked location.

## 2. Terminal Interaction Fixtures

- [x] 2.1 Audit current fixtures in `Tests/PenggieCoreTests/Fixtures/terminal-interaction-surfaces/` and document coverage gaps for resume, slash, model, effort, approval, permission, stale, ambiguous, scrolled, paged, and low-confidence cases.
- [x] 2.2 Add or update resume fixtures for selected, unselected, ambiguous, low-confidence, filtered, sorted, paged, and scrolled selected-row states.
- [x] 2.3 Add or update slash/model/effort fixtures for marker selection, style selection, cursor fallback, stale selection, ambiguous selection, and no-local-index expectations.
- [x] 2.4 Add or update approval and permission fixtures for visible choices, selected evidence, missing selected evidence, blocked Enter, Esc/cancel, and Raw Terminal parity expectations.
- [x] 2.5 Update terminal interaction fixture README documentation with source terminal facts, expected surface kind, selected evidence, confidence, confirmability, and negative behavior.

## 3. Display AST Fallback Fixtures

- [x] 3.1 Audit current fixtures in `Tests/PenggieCoreTests/Fixtures/agent-terminal-display/` and document coverage gaps for long sessions, CJK/table/code, tool-heavy output, warning/status rows, and low-confidence fallback.
- [x] 3.2 Add or update long-session fixtures that assert stable completed turns and no transcript pollution from later terminal output.
- [x] 3.3 Add or update CJK/table/code fixtures that assert visible terminal evidence is preserved by Display AST or raw/preformatted fallback.
- [x] 3.4 Add or update tool-heavy and warning/status fixtures that assert final answer hierarchy and prevent terminal status rows from becoming assistant answer content.
- [x] 3.5 Add or update low-confidence display fixtures that assert raw/preformatted fallback instead of invented Markdown or hidden output.

## 4. Core Terminal-Owned Safety Tests

- [x] 4.1 Add tests asserting fresh exactly-one selected rows are confirmable only when current terminal-frame evidence proves selection.
- [x] 4.2 Add tests asserting stale selected rows are not confirmable.
- [x] 4.3 Add tests asserting ambiguous or missing selected-row evidence blocks or consumes Enter and does not fabricate local selection.
- [x] 4.4 Add tests asserting arrow, Tab, Backspace, and filter text route to PTY and do not mutate selected state from a local array index before a fresh frame arrives.
- [x] 4.5 Add tests asserting low-confidence rows remain visible when useful while confirmation stays unavailable.
- [x] 4.6 Add tests asserting unsafe Enter does not fall through to ordinary composer submission.

## 5. Minimal Implementation Fixes

- [x] 5.1 Run targeted terminal interaction tests and identify failures introduced by the new fixtures.
- [x] 5.2 Fix only the minimal projection, freshness, confirm-gate, or low-confidence path required for failing terminal interaction tests.
- [x] 5.3 Run targeted Display AST tests and identify failures introduced by the new fixtures.
- [x] 5.4 Fix only the minimal Display AST classification, renderer, reconciler, or fallback path required for failing display tests.
- [x] 5.5 Do not modify visual polish, broad Reading layout, explicit resume product entry, semantic source, or theme/density work in this change.

## 6. Raw Terminal And App Shell Manual QA

- [x] 6.1 Add manual QA steps for Reading to Raw Terminal to Reading round trip during ordinary Reading idle.
- [x] 6.2 Add manual QA steps for Reading to Raw Terminal to Reading round trip while a terminal-owned surface is active.
- [x] 6.3 Add manual QA steps for low-confidence projection with Raw Terminal inspection available.
- [x] 6.4 Add manual QA steps for `Create with Penggie` ensuring create/new-session path does not accidentally enter resume.
- [x] 6.5 Add manual QA steps for missing Codex, launch failed, process exited, New Chat confirmation, and Close Session confirmation.

## 7. Validation

- [x] 7.1 Run `openspec validate harden-terminal-ux-qa-foundation --strict`.
- [x] 7.2 Run `openspec show harden-terminal-ux-qa-foundation --json`.
- [x] 7.3 During implementation, run targeted `swift test` filters for terminal interaction, Display AST fixtures, native interaction projection, and session model polling.
- [x] 7.4 Before completion, run `openspec validate --all --strict`.
- [x] 7.5 Before completion, run `git diff --check`.
