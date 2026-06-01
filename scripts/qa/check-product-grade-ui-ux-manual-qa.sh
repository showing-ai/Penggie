#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
qa_script="$repo_root/openspec/changes/productize-ui-ux-contract/product-grade-ui-ux-manual-qa-script.md"

python3 - "$qa_script" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
source = path.read_text()

required_sections = [
    "Required Evidence Record",
    "Global Setup",
    "Review Matrix",
    "P0 App Shell And Lifecycle",
    "P0 Terminal-Owned Overlays",
    "P0 Composer, IME, Focus, And Input Routing",
    "P0 Reading Transcript And Display AST",
    "P0 Raw Terminal Audit And Control",
    "P1 Accessibility And Dynamic State",
    "P1 Visual QA",
    "Pass Criteria",
    "Non-Goals",
]

required_terms = [
    "Terminal fixture",
    "Window size",
    "Theme",
    "Keyboard",
    "VoiceOver",
    "Expected result",
    "Raw Terminal",
    "same Codex process",
    "terminal-frame",
    "Do not launch a second Codex CLI",
]

required_scenarios = [
    "QA-SETUP-001",
    "QA-SETUP-002",
    "QA-LIFE-001",
    "QA-LIFE-002",
    "QA-OVERLAY-001",
    "QA-OVERLAY-002",
    "QA-OVERLAY-003",
    "QA-OVERLAY-004",
    "QA-COMP-001",
    "QA-COMP-002",
    "QA-COMP-003",
    "QA-READ-001",
    "QA-READ-002",
    "QA-RAW-001",
    "QA-RAW-002",
    "QA-AX-001",
    "QA-AX-002",
    "QA-VIS-001",
    "QA-VIS-002",
]

for section in required_sections:
    if f"## {section}" not in source:
        raise AssertionError(f"Missing required section: {section}")

for term in required_terms:
    if term not in source:
        raise AssertionError(f"Missing required QA field or invariant: {term}")

for scenario in required_scenarios:
    if f"### {scenario}:" not in source:
        raise AssertionError(f"Missing scenario: {scenario}")

for scenario in required_scenarios:
    match = re.search(
        rf"### {re.escape(scenario)}:.*?(?=\n### |\n## |\Z)",
        source,
        flags=re.S,
    )
    if not match:
        raise AssertionError(f"Could not parse scenario body: {scenario}")
    body = match.group(0)
    for field in ["Setup:", "Terminal fixture:", "Window size:", "Theme:", "Keyboard:", "VoiceOver:", "Expected result:"]:
        if field not in body:
            raise AssertionError(f"{scenario} is missing field {field}")

print("Product-grade UI/UX manual QA script guard passed")
PY
