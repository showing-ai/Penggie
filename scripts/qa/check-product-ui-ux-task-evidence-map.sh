#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
change_id="productize-ui-ux-contract"
tasks_file="$repo_root/openspec/changes/$change_id/tasks.md"
manifest="$repo_root/scripts/qa/product-ui-ux-manifest.tsv"
manual_qa="$repo_root/openspec/changes/$change_id/product-grade-ui-ux-manual-qa-script.md"
live_status_script="$repo_root/scripts/qa/check-product-ui-ux-live-qa-status.sh"
evidence_checker="$repo_root/scripts/qa/check-product-ui-ux-evidence-bundle.sh"

python3 - "$tasks_file" "$manifest" "$manual_qa" "$live_status_script" "$evidence_checker" <<'PY'
import csv
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.tracebacklimit = 0

tasks_file = Path(sys.argv[1])
manifest = Path(sys.argv[2])
manual_qa = Path(sys.argv[3])
live_status_script = Path(sys.argv[4])
evidence_checker = Path(sys.argv[5])

protected_live_tasks = {
    "3.10",
    "4.2",
    "4.3",
    "4.4",
    "4.5",
    "6.2",
    "6.3",
    "6.4",
    "6.5",
    "6.6",
    "7.4",
    "7.5",
    "8.3",
    "8.4",
    "8.5",
}

for path in [tasks_file, manifest, manual_qa, live_status_script, evidence_checker]:
    if not path.exists():
        raise AssertionError(f"Missing required QA mapping source: {path}")

tasks_source = tasks_file.read_text()
manual_source = manual_qa.read_text()
live_status_source = live_status_script.read_text()
evidence_source = evidence_checker.read_text()

tasks: dict[str, tuple[bool, str]] = {}
for line in tasks_source.splitlines():
    match = re.match(r"^- \[( |x)\] ((?:\d+\.)+\d+) (.+)$", line)
    if match:
        marker, task_id, description = match.groups()
        tasks[task_id] = (marker == "x", description)

missing_protected = sorted(protected_live_tasks - tasks.keys(), key=lambda value: [int(part) for part in value.split(".")])
if missing_protected:
    raise AssertionError(
        "Protected live/manual QA task ids are missing from tasks.md: "
        + ", ".join(missing_protected)
    )

open_tasks = {task_id for task_id, (done, _) in tasks.items() if not done}
unexpected_open = sorted(open_tasks - protected_live_tasks, key=lambda value: [int(part) for part in value.split(".")])
if unexpected_open:
    raise AssertionError(
        "Unchecked tasks must be either implemented now or explicitly added to the protected live/manual QA set: "
        + ", ".join(unexpected_open)
    )

expected_header = ["Scenario ID", "Task ID", "Scope", "Coverage"]
scenarios_by_task: dict[str, list[str]] = defaultdict(list)
seen_scenarios: set[str] = set()
coverage_keys_by_task: dict[str, set[str]] = defaultdict(set)

with manifest.open(newline="") as handle:
    reader = csv.DictReader(handle, delimiter="\t")
    if reader.fieldnames != expected_header:
        raise AssertionError(f"manifest header mismatch: {reader.fieldnames!r}")
    for row in reader:
        scenario_id = row["Scenario ID"].strip()
        task_id = row["Task ID"].strip()
        scope = row["Scope"].strip()
        coverage = row["Coverage"].strip()
        if not re.fullmatch(r"QA-[A-Z]+-\d{3}", scenario_id):
            raise AssertionError(f"Invalid scenario id: {scenario_id!r}")
        if scenario_id in seen_scenarios:
            raise AssertionError(f"Duplicate scenario id: {scenario_id}")
        seen_scenarios.add(scenario_id)
        if task_id not in tasks:
            raise AssertionError(f"{scenario_id} maps to unknown task id {task_id}")
        if not scope:
            raise AssertionError(f"{scenario_id} has blank scope")
        if not coverage:
            raise AssertionError(f"{scenario_id} has blank coverage")
        scenarios_by_task[task_id].append(scenario_id)
        for clause in coverage.split(";"):
            if "=" not in clause:
                raise AssertionError(f"{scenario_id} has invalid coverage clause: {clause!r}")
            key, value = clause.split("=", 1)
            key = key.strip()
            value = value.strip()
            if not key or not value:
                raise AssertionError(f"{scenario_id} has incomplete coverage clause: {clause!r}")
            if task_id in protected_live_tasks:
                coverage_keys_by_task[task_id].add(key)

missing_manifest = sorted(
    protected_live_tasks - scenarios_by_task.keys(),
    key=lambda value: [int(part) for part in value.split(".")],
)
if missing_manifest:
    raise AssertionError(
        "Protected live/manual QA tasks missing manifest scenarios: "
        + ", ".join(missing_manifest)
    )

open_without_manifest = sorted(
    open_tasks - scenarios_by_task.keys(),
    key=lambda value: [int(part) for part in value.split(".")],
)
if open_without_manifest:
    raise AssertionError(
        "Open live/manual QA tasks missing manifest scenarios: "
        + ", ".join(open_without_manifest)
    )

for scenario_id in seen_scenarios:
    if f"### {scenario_id}:" not in manual_source:
        raise AssertionError(f"Manual QA script is missing scenario section: {scenario_id}")

for task_id in protected_live_tasks:
    if f'"{task_id}"' not in live_status_source:
        raise AssertionError(f"Live QA status script is missing protected task id: {task_id}")

for required_phrase in [
    "check-running-penggie-build-identity.sh",
    "check-product-ui-ux-evidence-bundle.sh",
    "--allow-pending",
    "--strict",
]:
    if required_phrase not in live_status_source:
        raise AssertionError(f"Live QA status script is missing strict/pending path phrase: {required_phrase}")

for required_phrase in [
    "Result",
    "Observed result",
    "Raw Terminal parity note",
    "Screenshot/recording path",
    "Diagnostic/log path",
    "Follow-up",
    "path does not exist",
    "escapes evidence bundle",
]:
    if required_phrase not in evidence_source:
        raise AssertionError(f"Evidence bundle checker is missing strict evidence phrase: {required_phrase}")

expected_by_task = {
    "3.10": {"theme", "window", "voiceover", "terminal", "keyboard", "raw-terminal"},
    "4.2": {"theme", "window", "voiceover", "terminal", "keyboard", "raw-terminal"},
    "4.3": {"theme", "window", "voiceover", "terminal", "keyboard", "raw-terminal"},
    "4.4": {"theme", "window", "voiceover", "terminal", "keyboard", "raw-terminal"},
    "4.5": {"theme", "window", "voiceover", "terminal", "keyboard", "raw-terminal"},
    "6.2": {"theme", "window", "voiceover", "terminal", "keyboard", "raw-terminal"},
    "6.3": {"theme", "window", "voiceover", "terminal", "keyboard", "raw-terminal"},
    "6.4": {"theme", "window", "voiceover", "terminal", "keyboard", "pointer", "raw-terminal"},
    "6.5": {"theme", "window", "voiceover", "terminal", "keyboard", "pointer", "raw-terminal"},
    "6.6": {"theme", "window", "voiceover", "terminal", "keyboard", "raw-terminal", "screenshot"},
    "7.4": {"theme", "window", "voiceover", "terminal", "keyboard", "raw-terminal", "screenshot"},
    "7.5": {"theme", "window", "voiceover", "terminal", "keyboard", "motion", "raw-terminal"},
    "8.3": {"theme", "window", "voiceover", "terminal", "keyboard", "screenshot"},
    "8.4": {"theme", "window", "voiceover", "terminal", "keyboard", "screenshot"},
    "8.5": {"theme", "window", "voiceover", "terminal", "keyboard", "contrast", "screenshot"},
}

for task_id, expected_keys in expected_by_task.items():
    missing_keys = expected_keys - coverage_keys_by_task[task_id]
    if missing_keys:
        raise AssertionError(
            f"Task {task_id} manifest coverage is missing keys: "
            + ", ".join(sorted(missing_keys))
        )

print(
    "Product UI/UX task evidence map guard passed "
    f"({len(open_tasks)} open live/manual tasks, {len(seen_scenarios)} scenarios)"
)
PY
