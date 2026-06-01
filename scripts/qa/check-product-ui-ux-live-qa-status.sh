#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
change_id="productize-ui-ux-contract"
tasks_file="$repo_root/openspec/changes/$change_id/tasks.md"
manifest="$repo_root/scripts/qa/product-ui-ux-manifest.tsv"
evidence_dir=""
strict=false

usage() {
  cat <<'EOF'
Usage: scripts/qa/check-product-ui-ux-live-qa-status.sh [--strict] [--evidence-dir PATH]

Reports the remaining live/manual QA tasks for productize-ui-ux-contract and
verifies that each remaining task has manifest scenarios. With --evidence-dir,
also validates the evidence bundle. Without --strict, pending notes are allowed.
With --strict, the evidence must be final and the running Penggie process must
match the build identity recorded in the evidence bundle.

Options:
  --evidence-dir PATH  Existing QA evidence bundle to inspect.
  --strict             Require final evidence and matching running app identity.
  -h, --help           Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence-dir)
      if [[ $# -lt 2 ]]; then
        echo "--evidence-dir requires a path" >&2
        exit 2
      fi
      evidence_dir="$2"
      shift 2
      ;;
    --strict)
      strict=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

python3 - "$tasks_file" "$manifest" <<'PY'
import csv
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.tracebacklimit = 0

tasks_file = Path(sys.argv[1])
manifest = Path(sys.argv[2])

if not tasks_file.exists():
    raise AssertionError(f"Missing tasks file: {tasks_file}")
if not manifest.exists():
    raise AssertionError(f"Missing QA manifest: {manifest}")

live_task_ids = {
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

task_status: dict[str, tuple[str, str]] = {}
for line in tasks_file.read_text().splitlines():
    match = re.match(r"^- \[( |x)\] ((?:\d+\.)+\d+) (.+)$", line)
    if match:
        done_marker, task_id, description = match.groups()
        task_status[task_id] = ("complete" if done_marker == "x" else "open", description)

missing_task_entries = sorted(live_task_ids - task_status.keys())
if missing_task_entries:
    raise AssertionError(f"Live QA task ids missing from tasks.md: {', '.join(missing_task_entries)}")

scenarios_by_task: dict[str, list[tuple[str, str, str]]] = defaultdict(list)
with manifest.open(newline="") as handle:
    reader = csv.DictReader(handle, delimiter="\t")
    expected = ["Scenario ID", "Task ID", "Scope", "Coverage"]
    if reader.fieldnames != expected:
        raise AssertionError(f"manifest header mismatch: {reader.fieldnames!r}")
    for row in reader:
        task_id = row["Task ID"]
        scenarios_by_task[task_id].append((row["Scenario ID"], row["Scope"], row["Coverage"]))

missing_scenarios = sorted(task_id for task_id in live_task_ids if task_id not in scenarios_by_task)
if missing_scenarios:
    raise AssertionError(f"Live QA task ids missing manifest scenarios: {', '.join(missing_scenarios)}")

open_live_tasks = [task_id for task_id in sorted(live_task_ids, key=lambda value: [int(part) for part in value.split(".")]) if task_status[task_id][0] == "open"]
closed_live_tasks = [task_id for task_id in sorted(live_task_ids, key=lambda value: [int(part) for part in value.split(".")]) if task_status[task_id][0] == "complete"]

if closed_live_tasks:
    print("Completed live/manual QA tasks:")
    for task_id in closed_live_tasks:
        print(f"- {task_id}: {task_status[task_id][1]}")

print("Open live/manual QA tasks:")
for task_id in open_live_tasks:
    status, description = task_status[task_id]
    print(f"- {task_id}: {description}")
    for scenario_id, scope, coverage in scenarios_by_task[task_id]:
        print(f"  - {scenario_id}: {scope} [{coverage}]")

print(f"Live QA status: {len(open_live_tasks)} open, {len(closed_live_tasks)} complete, {len(live_task_ids)} tracked")
PY

if [[ -n "$evidence_dir" ]]; then
  if [[ "$strict" == true ]]; then
    "$repo_root/scripts/qa/check-running-penggie-build-identity.sh" "$evidence_dir"
    "$repo_root/scripts/qa/check-product-ui-ux-evidence-bundle.sh" "$evidence_dir"
  else
    "$repo_root/scripts/qa/check-product-ui-ux-evidence-bundle.sh" --allow-pending "$evidence_dir"
  fi
else
  echo
  echo "No evidence bundle supplied. To prepare one:"
  echo "scripts/qa/prepare-product-ui-ux-local-qa.sh --evidence-dir /tmp/penggie-ui-ux-qa"
fi
