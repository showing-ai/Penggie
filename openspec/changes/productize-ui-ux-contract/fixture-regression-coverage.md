# Fixture Regression Coverage

This evidence file closes the fixture-backed portion of the product-grade UI/UX
implementation plan for terminal-owned surfaces. It does not claim that live
manual QA has been completed; those tasks remain separate.

## Scope

- **Task 9.2:** terminal interaction fixture expansion for resume, slash,
  model, effort, approval, permission, stale selection, ambiguous selection,
  low-confidence rows, filter/sort metadata, pager metadata, and scrolled
  selected rows.
- **Task 9.4:** regression tests that fail on wrong selected-row evidence,
  unsafe confirmability, broken fallback, transcript pollution, or lost Raw
  Terminal parity assumptions.

## Terminal Interaction Fixtures

Authoritative fixture directory:

- `Tests/PenggieCoreTests/Fixtures/terminal-interaction-surfaces/`

Current fixture coverage:

| Required behavior | Fixture evidence |
| --- | --- |
| Resume selected/filter/sort/pager | `resume-filter-sort-pager-selected.json` |
| Resume scrolled selected row | `resume-scrolled-selected.json` |
| Resume missing selection | `resume-unselected.json` |
| Resume ambiguous selection | `resume-ambiguous.json` |
| Resume low-confidence rows | `resume-low-confidence.json` |
| Slash suggestions and marker selection | `slash-suggestions.json` |
| Slash style-selected row | `slash-style-selected.json` |
| Slash ambiguous selection | `slash-ambiguous.json` |
| Slash stale/missing selection | `slash-stale-unselected.json` |
| Slash continuation | `slash-continuation.json` |
| Model picker and cursor fallback | `model-picker.json`, `model-cursor-fallback.json` |
| Model stale/missing selection | `model-stale-unselected.json` |
| Effort picker and cursor fallback | `effort-picker.json`, `effort-cursor-fallback.json` |
| Effort stale/missing selection | `effort-stale-unselected.json` |
| Approval modal choices | `approval-prompt.json`, `approval-cancel-selected.json`, `approval-style-selected.json`, `approval-reject-selected.json` |
| Approval ambiguous/missing selection | `approval-ambiguous.json`, `approval-missing-selection.json` |
| Permission modal choices | `permission-prompt.json`, `permission-cancel-selected.json`, `permission-allow-this-selected.json` |
| Permission missing selection | `permission-missing-selection.json` |
| Historical transcript negative | `negative-historical-transcript.txt` |

The fixtures encode terminal facts only: row text, marker evidence, selected
style evidence, cursor fallback, source line index, frame ID, filter/sort/pager
metadata, and visible/footer rows. They must not become local command/model/
resume/approval/permission lists or terminal-owned selectedIndex/list state.

## Regression Tests

Authoritative test files:

- `Tests/PenggieCoreTests/PenggieTerminalInteractionSurfaceTests.swift`
- `Tests/PenggieCoreTests/PenggieDisplayFixtureTests.swift`

The terminal interaction tests validate:

- fixture catalog classification for every supported terminal-owned surface;
- resume filter/sort/pager/footer metadata;
- scrolled selected-row viewport evidence;
- marker, style, and cursor-backed selected-row evidence;
- ambiguous, stale, waiting-for-frame, missing, and low-confidence selection;
- blocked Enter for unsafe confirmability;
- PTY-routed navigation without local selection mutation;
- modal choice source-line evidence and Raw Terminal parity assumptions.

The Display AST fixture tests validate:

- historical slash/model-looking text remains transcript content, not an active
  overlay;
- warning/status/tool rows do not hide visible answer text;
- approval prompt text remains visible fallback text instead of being sealed as
  a normal assistant answer;
- low-confidence fallback preserves terminal evidence without inventing
  Markdown structure;
- long-session fixture keeps completed answer content stable while later status
  rows remain classified.

## Guard Script

The source guard is:

```bash
scripts/qa/check-fixture-regression-coverage.sh
```

It fails if required fixture files, README coverage entries, regression test
functions, key fixture references, or safety invariants are removed. It also
checks that tasks 9.2 and 9.4 remain marked complete only while this evidence
and the guard are present.

The explicit failure classes are transcript pollution, wrong selected-row
evidence, unsafe confirmability, broken fallback, and lost Raw Terminal parity.

## Acceptance Boundary

This completes fixture/test-backed expansion for task 9.2 and regression-test
coverage for task 9.4.

Still out of scope here:

- task 9.1 Display AST fixture expansion for remaining large preformatted and
  Reading snapshot breadth;
- task 3.10 live manual QA for slash/model/resume/approval/permission;
- task 8.3 visual captures;
- task 6.x live Raw Terminal control QA.
