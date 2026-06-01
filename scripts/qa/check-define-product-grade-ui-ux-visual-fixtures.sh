#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

root = Path(".")
evidence = (root / "openspec/changes/define-product-grade-ui-ux/visual-review-fixture-evidence.md").read_text()
tasks = (root / "openspec/changes/define-product-grade-ui-ux/tasks.md").read_text()
manual_evidence = (root / "openspec/changes/define-product-grade-ui-ux/manual-qa-productization-evidence.md").read_text()
display_readme = (root / "Tests/PenggieCoreTests/Fixtures/agent-terminal-display/README.md").read_text()
surface_readme = (root / "Tests/PenggieCoreTests/Fixtures/terminal-interaction-surfaces/README.md").read_text()
product_manual = (root / "openspec/changes/productize-ui-ux-contract/product-grade-ui-ux-manual-qa-script.md").read_text()
prepare = (root / "scripts/qa/prepare-product-ui-ux-local-qa.sh").read_text()
theme_evidence = (root / "openspec/changes/productize-ui-ux-contract/theme-token-validation-evidence.md").read_text()
product_tasks = (root / "openspec/changes/productize-ui-ux-contract/tasks.md").read_text()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def contains(source: str, needle: str, message: str) -> None:
    require(needle in source, message)


for fixture in [
    "long-session-stable",
    "cjk-table-code",
    "table-box-cjk",
    "tool-heavy-warning-hierarchy",
    "warning-status-tools",
    "low-confidence-fallback",
    "large-preformatted",
]:
    path = root / f"Tests/PenggieCoreTests/Fixtures/agent-terminal-display/{fixture}"
    require(path.exists(), f"Missing display fixture directory: {fixture}")
    contains(display_readme, fixture, f"Display README does not document fixture: {fixture}")
    contains(evidence, fixture, f"Visual evidence does not map fixture: {fixture}")

for fixture in [
    "resume-filter-sort-pager-selected.json",
    "resume-scrolled-selected.json",
    "approval-prompt.json",
    "approval-missing-selection.json",
    "permission-prompt.json",
    "permission-missing-selection.json",
]:
    path = root / f"Tests/PenggieCoreTests/Fixtures/terminal-interaction-surfaces/{fixture}"
    require(path.exists(), f"Missing terminal interaction fixture: {fixture}")
    contains(surface_readme, fixture.split(".")[0].split("-")[0], f"Surface README lacks coverage for fixture family: {fixture}")
    contains(evidence, fixture, f"Visual evidence does not map fixture: {fixture}")

for phrase in [
    "narrow window",
    "large text",
    "light mode",
    "dark mode",
    "setup, empty Reading, long transcript, composer focus, slash",
    "overlay, resume picker, approval/permission, Raw Terminal, recovery",
]:
    source = product_manual + "\n" + prepare
    contains(source, phrase, f"Productization visual QA scaffold missing: {phrase}")
    contains(evidence, phrase, f"Visual evidence missing capture matrix item: {phrase}")

for phrase in [
    "theme parity",
    "setup, Reading, composer, terminal-owned overlays, Raw Terminal",
    "scripts/check-theme-token-usage.sh",
]:
    source = product_manual + "\n" + theme_evidence + "\n" + evidence
    contains(source, phrase, f"Theme/visual evidence missing: {phrase}")

contains(tasks, "- [x] 2.3 Add visual review fixtures", "define-product task 2.3 must be marked complete")
contains(
    manual_evidence,
    "Visual review fixtures are now documented in `visual-review-fixture-evidence.md`.",
    "manual QA evidence should point to the visual fixture evidence",
)

for task in [
    "- [ ] 8.3 Create visual QA captures",
    "- [ ] 8.4 Validate density rules",
    "- [ ] 8.5 Validate contrast targets",
]:
    contains(product_tasks, task, f"Productization live visual QA task must remain open: {task}")

for phrase in [
    "does not close live visual QA",
    "screenshots are not terminal-owned state authority",
    "Do not introduce local command, model, resume, approval, permission, or",
    "Do not launch a second Codex process",
]:
    contains(evidence, phrase, f"Visual evidence boundary missing: {phrase}")

print("define-product-grade-ui-ux visual fixture guard passed")
PY
