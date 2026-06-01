#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

root = Path(".")
manual_qa = (root / "openspec/changes/productize-ui-ux-contract/product-grade-ui-ux-manual-qa-script.md").read_text()
release = (root / "openspec/changes/productize-ui-ux-contract/release-readiness-checklist.md").read_text()
prepare = (root / "scripts/qa/prepare-product-ui-ux-local-qa.sh").read_text()
accessibility_guard = (root / "scripts/qa/check-accessibility-smoke-source.sh").read_text()
theme_guard = (root / "scripts/check-theme-token-usage.sh").read_text()
theme_evidence = (root / "openspec/changes/productize-ui-ux-contract/theme-token-validation-evidence.md").read_text()
reduced_motion = (root / "openspec/changes/productize-ui-ux-contract/reduced-motion-source-evidence.md").read_text()
visual_evidence = (root / "openspec/changes/productize-ui-ux-contract/visual-accessibility-readiness.md").read_text()
tasks = (root / "openspec/changes/productize-ui-ux-contract/tasks.md").read_text()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def contains(source: str, needle: str, message: str) -> None:
    require(needle in source, message)


for scenario in [
    "### QA-VIS-001: Theme and chrome parity",
    "### QA-VIS-002: Density and contrast review",
]:
    contains(manual_qa, scenario, f"Missing visual manual QA scenario: {scenario}")

for phrase in [
    "capture setup, empty Reading, long transcript, composer focus, slash",
    "overlay, resume picker, approval/permission, Raw Terminal, recovery",
    "Window size: normal, narrow, and large-text review",
    "Theme: light and dark",
    "topbar, canvas, composer, native overlays, Raw Terminal",
    "density comes from hierarchy and disclosure",
    "text, icons, selected rows, disabled state, warnings",
    "danger, and focus indicators meet contrast expectations",
]:
    contains(manual_qa, phrase, f"Missing visual QA expectation: {phrase}")

for phrase in [
    "Light mode captures:",
    "Dark mode captures:",
    "Narrow window captures:",
    "Large-text captures:",
    "Dynamic Type or larger text result:",
    "Reduced motion result:",
    "Known visual defects:",
]:
    contains(release, phrase, f"Missing release visual/accessibility evidence field: {phrase}")

for phrase in [
    "mkdir -p",
    "\"$evidence_dir/screenshots\"",
    "\"$evidence_dir/recordings\"",
    "\"$evidence_dir/logs\"",
    "\"$evidence_dir/notes\"",
    "Do not launch a second Codex CLI",
    "large text",
    "light mode",
    "dark mode",
    "narrow window",
    "Scenario Evidence",
]:
    contains(prepare, phrase, f"Missing visual QA evidence bundle support: {phrase}")

for phrase in [
    r"@Environment(\\.accessibilityReduceMotion) private var reduceMotion",
    "Chrome icon button press scaling is disabled",
    "Reading disclosure expansion toggles without",
    "terminal candidate scroll remains non-animated",
]:
    source = accessibility_guard + "\n" + reduced_motion
    contains(source, phrase, f"Missing reduced-motion source/readiness evidence: {phrase}")

for phrase in [
    "STRICT_PATTERN",
    "NSColor\\.(windowBackgroundColor|textBackgroundColor|controlBackgroundColor|separatorColor|selectedMenuItemTextColor)",
    "Color\\.accentColor",
    "One Half Dark",
    "Builtin Light",
    "scripts/check-theme-token-usage.sh",
    "Visual capture, contrast review, density review, and large-text review remain covered",
]:
    source = theme_guard + "\n" + theme_evidence
    contains(source, phrase, f"Missing theme/visual static guard evidence: {phrase}")

for task in [
    "- [ ] 7.4 Validate Dynamic Type or larger text behavior",
    "- [ ] 7.5 Validate reduced motion behavior",
    "- [ ] 8.3 Create visual QA captures",
    "- [ ] 8.4 Validate density rules",
    "- [ ] 8.5 Validate contrast targets",
]:
    contains(tasks, task, f"Task must remain open until live visual/accessibility QA is performed: {task}")

for phrase in [
    "does not claim a live Dynamic Type/larger text",
    "Tasks `7.4`, `7.5`, `8.3`, `8.4`, and `8.5` remain open",
    "Current source still uses fixed SwiftUI font sizes",
    "The script is an evidence scaffold only",
    "not a contrast checker",
    "Do not launch a second Codex process",
    "Do not introduce local command, model, resume, approval, permission, or",
]:
    contains(visual_evidence, phrase, f"Missing visual/accessibility evidence boundary: {phrase}")

print("P1 visual/accessibility readiness guard passed")
PY
