#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
qa_script="$repo_root/openspec/changes/productize-ui-ux-contract/product-grade-ui-ux-manual-qa-script.md"
manifest="$repo_root/scripts/qa/product-ui-ux-manifest.tsv"
live_status_script="$repo_root/scripts/qa/check-product-ui-ux-live-qa-status.sh"
evidence_checker="$repo_root/scripts/qa/check-product-ui-ux-evidence-bundle.sh"
task_evidence_map="$repo_root/scripts/qa/check-product-ui-ux-task-evidence-map.sh"
inventory_guard="$repo_root/scripts/qa/check-openspec-worktree-inventory.sh"
preflight="$repo_root/scripts/qa/run-product-ui-ux-preflight.sh"
release_checklist="$repo_root/openspec/changes/productize-ui-ux-contract/release-readiness-checklist.md"
local_qa_setup="$repo_root/openspec/changes/productize-ui-ux-contract/local-qa-setup-script.md"

python3 - "$qa_script" "$manifest" "$live_status_script" "$evidence_checker" "$task_evidence_map" "$inventory_guard" "$preflight" "$release_checklist" "$local_qa_setup" <<'PY'
import csv
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
manifest = Path(sys.argv[2])
live_status_script = Path(sys.argv[3])
evidence_checker = Path(sys.argv[4])
task_evidence_map = Path(sys.argv[5])
inventory_guard = Path(sys.argv[6])
preflight = Path(sys.argv[7])
release_checklist = Path(sys.argv[8])
local_qa_setup = Path(sys.argv[9])
source = path.read_text()
live_status_source = live_status_script.read_text()
evidence_checker_source = evidence_checker.read_text()
task_evidence_map_source = task_evidence_map.read_text()
inventory_guard_source = inventory_guard.read_text()
preflight_source = preflight.read_text()
release_checklist_source = release_checklist.read_text()
local_qa_setup_source = local_qa_setup.read_text()

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
    "QA-FOCUS-001",
    "QA-READ-001",
    "QA-READ-002",
    "QA-RAW-001",
    "QA-RAW-002",
    "QA-RAW-003",
    "QA-RAW-004",
    "QA-RAW-005",
    "QA-AX-001",
    "QA-AX-002",
    "QA-VIS-001",
    "QA-VIS-002",
    "QA-VIS-003",
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

with manifest.open(newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
manifest_scenarios = {row["Scenario ID"] for row in rows}
missing_from_manifest = sorted(set(required_scenarios) - manifest_scenarios)
extra_in_manifest = sorted(manifest_scenarios - set(required_scenarios))
if missing_from_manifest:
    raise AssertionError(f"Manual QA scenarios missing from manifest: {', '.join(missing_from_manifest)}")
if extra_in_manifest:
    raise AssertionError(f"Manifest scenarios missing from manual QA script: {', '.join(extra_in_manifest)}")
if any(not row["Coverage"].strip() for row in rows):
    raise AssertionError("Every manifest scenario must include coverage requirements")

if "check-running-penggie-build-identity.sh" not in live_status_source:
    raise AssertionError("Strict live QA status must verify the running Penggie build identity")
if '"$strict" == true' not in live_status_source:
    raise AssertionError("Live QA status script must keep a strict verification path")
if "running-build-identity.txt" not in live_status_source:
    raise AssertionError("Strict live QA status must persist the running app identity log")
if "running-build-identity.txt" not in evidence_checker_source:
    raise AssertionError("Strict evidence bundle check must require the persisted running app identity log")
if "Running Penggie build identity matches QA bundle" not in evidence_checker_source:
    raise AssertionError("Strict evidence bundle check must require a passing running app identity marker")
if "Diagnostic/log path" not in evidence_checker_source:
    raise AssertionError("Strict evidence bundle check must require diagnostic/log paths for failures")
if "Screenshot/recording path" not in evidence_checker_source:
    raise AssertionError("Strict evidence bundle check must validate screenshot/recording paths")
if "path does not exist" not in evidence_checker_source:
    raise AssertionError("Strict evidence bundle check must verify referenced evidence files exist")
if "Strict evidence requires a product UI/UX preflight log" not in evidence_checker_source:
    raise AssertionError("Strict evidence bundle check must require a recorded preflight log")
if "Product-grade UI/UX preflight passed" not in evidence_checker_source:
    raise AssertionError("Strict evidence bundle check must require a passing preflight marker")
if "preflight commit to match the evidence build identity" not in evidence_checker_source:
    raise AssertionError("Strict evidence bundle check must require the preflight commit to match the evidence bundle")
if '"contrast" and "required"' not in evidence_checker_source:
    raise AssertionError("Strict evidence bundle check must require diagnostic evidence for contrast-required scenarios")
if "Product UI/UX task evidence map guard passed" not in task_evidence_map_source:
    raise AssertionError("Manual QA guard must include the task-to-evidence mapping guard")
if "Unchecked tasks must be either implemented now" not in task_evidence_map_source:
    raise AssertionError("Task evidence map guard must fail on unexpected unchecked implementation tasks")
if "Protected live/manual QA tasks missing manifest scenarios" not in task_evidence_map_source:
    raise AssertionError("Task evidence map guard must fail on missing live QA manifest coverage")
if "OpenSpec/worktree inventory guard passed" not in inventory_guard_source:
    raise AssertionError("Manual QA guard must include the OpenSpec/worktree inventory guard")
if "Vendor/ghostty has dirty changes" not in inventory_guard_source:
    raise AssertionError("OpenSpec/worktree inventory guard must fail on dirty Vendor/ghostty state")
required_preflight_commands = [
    "Product UI/UX preflight commit",
    "check-openspec-worktree-inventory.sh",
    "openspec validate productize-ui-ux-contract --strict",
    "openspec validate --all --strict",
    "check-product-ui-ux-task-evidence-map.sh",
    "check-p0-terminal-owned-live-qa-readiness.sh",
    "check-p0-composer-ime-focus-readiness.sh",
    "check-p0-raw-terminal-source.sh",
    "check-p1-visual-accessibility-readiness.sh",
    "swift test --filter PenggieDisplayFixtureTests",
    "swift test --filter PenggieTerminalInteractionSurfaceTests",
    "xcodebuild",
]
for command in required_preflight_commands:
    if command not in preflight_source:
        raise AssertionError(f"Product UI/UX preflight script must run {command}")
for source_name, checked_source in [
    ("release readiness checklist", release_checklist_source),
    ("local QA setup evidence", local_qa_setup_source),
]:
    if "scripts/qa/check-openspec-worktree-inventory.sh" not in checked_source:
        raise AssertionError(f"{source_name} must require the OpenSpec/worktree inventory guard")
    if "scripts/qa/run-product-ui-ux-preflight.sh" not in checked_source:
        raise AssertionError(f"{source_name} must require the product UI/UX preflight script")
    if "logs/preflight.txt" not in checked_source:
        raise AssertionError(f"{source_name} must record the product UI/UX preflight log")

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

"$task_evidence_map"
