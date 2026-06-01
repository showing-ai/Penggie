# Visual Review Fixture Evidence

This evidence closes task `2.3` for the product-grade UI/UX contract definition
change. The visual review fixture set is intentionally split between
terminal-display fixtures, terminal-interaction fixtures, and the productization
QA capture matrix:

- terminal-display fixtures prove long-session, CJK, table, code, tool-heavy,
  warning/status, fallback, and wide/preformatted content behavior from
  terminal-visible facts;
- terminal-interaction fixtures prove selected-row, modal-choice, low-confidence,
  scrolled, paged, and terminal-owned overlay states;
- the productization QA capture scaffold defines narrow-window, large-text,
  light-mode, and dark-mode visual review evidence for the running macOS app.

These fixtures are visual review inputs. They are not a replacement for live
visual QA, and screenshots are not terminal-owned state authority.

The live capture matrix explicitly includes narrow window, large text, light mode, and dark mode review states.
It also requires capture coverage for setup, empty Reading, long transcript, composer focus, slash overlay, resume picker, approval/permission, Raw Terminal, recovery, narrow window, and large text.

## Fixture Matrix

| Review area | Fixture or evidence source | Expected review use |
| --- | --- | --- |
| Long sessions | `Tests/PenggieCoreTests/Fixtures/agent-terminal-display/long-session-stable/` | Verify completed output remains visually stable when later terminal status and prompt-ready rows appear. |
| CJK prose/table/code | `Tests/PenggieCoreTests/Fixtures/agent-terminal-display/cjk-table-code/` | Verify CJK prose, table-like output, and code-fence text preserve visible terminal evidence. |
| Tables and box drawing | `Tests/PenggieCoreTests/Fixtures/agent-terminal-display/table-box-cjk/` | Verify cell-width-sensitive table/box drawing content remains inspectable. |
| Tool-heavy output | `Tests/PenggieCoreTests/Fixtures/agent-terminal-display/tool-heavy-warning-hierarchy/` | Verify repeated tool/status rows and warning rows retain hierarchy without polluting final answer text. |
| Warning/status output | `Tests/PenggieCoreTests/Fixtures/agent-terminal-display/warning-status-tools/` | Verify warnings, activity rows, tool rows, status rows, and final answer text stay visually distinct. |
| Low-confidence fallback | `Tests/PenggieCoreTests/Fixtures/agent-terminal-display/low-confidence-fallback/` | Verify uncertain display preserves raw/preformatted visible evidence instead of inventing Markdown structure. |
| Large/wide content | `Tests/PenggieCoreTests/Fixtures/agent-terminal-display/large-preformatted/` | Verify wide terminal-shaped rows remain cell-aware and horizontally inspectable. |
| Resume and paged lists | `Tests/PenggieCoreTests/Fixtures/terminal-interaction-surfaces/resume-filter-sort-pager-selected.json` and `resume-scrolled-selected.json` | Verify native surfaces show selected rows, metadata, and pager/scroll evidence without clipped highlights. |
| Approval/permission choices | `Tests/PenggieCoreTests/Fixtures/terminal-interaction-surfaces/approval-prompt.json`, `approval-missing-selection.json`, `permission-prompt.json`, and `permission-missing-selection.json` | Verify safety-sensitive modal choices expose visible rows, selected evidence, blocked Enter states, and Raw Terminal parity. |
| Narrow windows | `openspec/changes/productize-ui-ux-contract/product-grade-ui-ux-manual-qa-script.md` and `scripts/qa/prepare-product-ui-ux-local-qa.sh` | Capture setup, Reading, overlays, Raw Terminal, recovery, and long transcript under narrow-window constraints. |
| Large text | `openspec/changes/productize-ui-ux-contract/product-grade-ui-ux-manual-qa-script.md` and `scripts/qa/prepare-product-ui-ux-local-qa.sh` | Capture setup, Reading, composer, overlays, recovery, and Raw Terminal chrome under larger text settings. |
| Light/dark themes | `openspec/changes/productize-ui-ux-contract/product-grade-ui-ux-manual-qa-script.md`, `scripts/qa/prepare-product-ui-ux-local-qa.sh`, and `openspec/changes/productize-ui-ux-contract/theme-token-validation-evidence.md` | Capture theme parity across setup, Reading, composer, terminal-owned overlays, Raw Terminal, and recovery. |

## Boundary

This closes the planning requirement to define visual review fixtures. It does not close live visual QA in `productize-ui-ux-contract`; tasks `8.3`, `8.4`,
and `8.5` remain open until screenshots/captures, density review, and contrast
review are recorded from the running app.

## Verification

- `scripts/qa/check-define-product-grade-ui-ux-visual-fixtures.sh` verifies the
  fixture matrix, README coverage, productization visual QA script, evidence
  scaffold, and live-QA boundary.

## Non-Goals

- Do not treat screenshots as the source of truth for terminal-owned selection
  or confirmability.
- Do not introduce local command, model, resume, approval, permission, or
  selected-index state for visual review.
- Do not launch a second Codex process, SDK session, `codex exec --json`
  session, or second Ghostty surface for user-visible visual review.
