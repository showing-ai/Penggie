# Terminal Interaction Surface Fixtures

These fixtures are representative Ghostty screen-model snapshots for terminal-owned
Codex surfaces. They intentionally encode terminal facts, not local Penggie state:
visible text, row markers, cursor rows, style summaries, and frame shape.

## Source Of Truth

Fixtures in this directory must describe terminal-owned behavior from the Ghostty
screen model. They must not become local product data for command lists, model
lists, resume sessions, approval choices, permission choices, or selected indices.

## Expected Fixture Facts

Each fixture should make these facts inspectable either directly in the screen
model or in nearby test expectations:

- Surface kind: resume, slash suggestions, slash continuation, model, effort, approval, permission, or negative transcript.
- Candidate rows and their source terminal lines.
- Selected evidence: marker, style, cursor, row position, or absence of reliable evidence.
- Selection confidence: reliable, stale, ambiguous, low confidence, or none.
- Confirmability: whether Enter, click, or accessibility activation may route confirmation to the PTY.
- Negative behavior: what must not happen, especially local selected-index movement or unsafe Enter fallthrough.
- Viewport facts for scrolled or paged surfaces.

## Current Coverage

| Area | Current fixtures | Status |
| --- | --- | --- |
| Resume selected/filter/sort/pager | `resume-filter-sort-pager-selected.json` | Covered for selected rows and header/footer metadata. |
| Resume scrolled selected | `resume-scrolled-selected.json` | Covered for selected row near the visible boundary. |
| Resume unselected | `resume-unselected.json` | Covered for missing selected evidence. |
| Resume ambiguous | `resume-ambiguous.json` | Covered for ambiguous selected evidence. |
| Resume low confidence | `resume-low-confidence.json` | Covered for visible rows with no reliable selected evidence. |
| Slash suggestions | `slash-suggestions.json` | Covered for basic slash menu projection. |
| Slash style selection | `slash-style-selected.json` | Covered for style-backed selected evidence. |
| Slash ambiguous selection | `slash-ambiguous.json` | Covered for conflicting marker evidence. |
| Slash continuation | `slash-continuation.json` | Covered for numbered continuation menu projection. |
| Model picker | `model-picker.json` | Covered for basic selectable model list. |
| Model cursor fallback | `model-cursor-fallback.json` | Covered for cursor-backed selected evidence. |
| Model missing selection | `model-stale-unselected.json` | Covered for visible rows with no reliable selected evidence. |
| Effort picker | `effort-picker.json` | Covered for basic selectable effort list. |
| Effort cursor fallback | `effort-cursor-fallback.json` | Covered for cursor-backed selected evidence. |
| Effort missing selection | `effort-stale-unselected.json` | Covered for visible rows with no reliable selected evidence. |
| Approval prompt | `approval-prompt.json`, `approval-cancel-selected.json`, `approval-missing-selection.json` | Covered for visible choices, selected cancel, and missing selected evidence. |
| Permission prompt | `permission-prompt.json`, `permission-cancel-selected.json`, `permission-missing-selection.json` | Covered for visible choices, selected cancel, and missing selected evidence. |
| Historical transcript negative | `negative-historical-transcript.txt` | Covered for non-active text that mentions terminal-owned surfaces. |

## Coverage Gaps For `harden-terminal-ux-qa-foundation`

- Resume: add filtered and sorted variants that explicitly assert metadata and confirmability.
- Slash/model/effort: add more stale selection variants with explicit prior-frame metadata once the fixture schema stores frame history.
- Approval/permission: add stale selected evidence, blocked Enter, Esc/cancel, and Raw Terminal parity expectations once the fixture schema stores input actions.
- Pager/viewport: add explicit visible-window or pager metadata expectations for scrolled and paged lists.

## Review Rule

When a terminal-owned fixture changes, the related test must state why the selected
row is reliable or why confirmation is blocked. A visual row list alone is not
enough evidence.
