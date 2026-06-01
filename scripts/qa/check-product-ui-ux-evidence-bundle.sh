#!/usr/bin/env bash
set -euo pipefail

allow_pending=false

usage() {
  cat <<'EOF'
Usage: scripts/qa/check-product-ui-ux-evidence-bundle.sh [--allow-pending] EVIDENCE_DIR

Validates a product-grade UI/UX manual QA evidence bundle.

Without --allow-pending, every manifest scenario note must contain a filled
result and observation fields. This script checks evidence completeness only; it
does not treat screenshots as terminal-owned state truth.

Options:
  --allow-pending  Validate generated bundle structure without requiring filled results.
  -h, --help       Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --allow-pending)
      allow_pending=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 2
fi

bundle_dir="$1"
manifest="$bundle_dir/manifest.tsv"
readme="$bundle_dir/README.md"
notes_dir="$bundle_dir/notes"

if [[ ! -d "$bundle_dir" ]]; then
  echo "Evidence directory does not exist: $bundle_dir" >&2
  exit 1
fi

for required in "$readme" "$manifest" "$notes_dir/scenario-template.md"; do
  if [[ ! -e "$required" ]]; then
    echo "Missing required evidence artifact: $required" >&2
    exit 1
  fi
done

python3 - "$manifest" "$notes_dir" "$allow_pending" <<'PY'
import re
import sys
from pathlib import Path

sys.tracebacklimit = 0

manifest = Path(sys.argv[1])
notes_dir = Path(sys.argv[2])
allow_pending = sys.argv[3] == "true"

rows = manifest.read_text().splitlines()
if not rows or rows[0] != "Scenario ID\tTask ID\tScope":
    raise AssertionError("manifest.tsv must start with the expected header")

required_fields = [
    "Scenario ID",
    "Task ID",
    "Scope",
    "Result",
    "Commit SHA",
    "Build configuration",
    "macOS appearance",
    "Window size",
    "Project folder",
    "Terminal fixture or live terminal setup",
    "Keyboard path",
    "VoiceOver state",
    "Expected result",
    "Observed result",
    "Raw Terminal parity note",
    "Screenshot/recording path",
    "Follow-up",
]

allowed_results = {"pass", "fail", "blocked", "not applicable"}
pending_results = {"pending", ""}


def field_value(source: str, field: str) -> str:
    match = re.search(rf"^- {re.escape(field)}:\s*(.*)$", source, flags=re.M)
    if not match:
        raise AssertionError(f"missing field {field}")
    return match.group(1).strip()


scenario_count = 0
strict_missing = []

for line in rows[1:]:
    if not line.strip():
        continue
    parts = line.split("\t")
    if len(parts) != 3:
        raise AssertionError(f"manifest row must have 3 tab-separated columns: {line!r}")
    scenario_id, task_id, scope = parts
    note = notes_dir / f"{scenario_id}.md"
    if not note.exists():
        raise AssertionError(f"missing scenario note: {note}")
    source = note.read_text()
    values = {}
    for field in required_fields:
        values[field] = field_value(source, field)
    if values["Scenario ID"] != scenario_id:
        raise AssertionError(f"{note} scenario id mismatch: {values['Scenario ID']} != {scenario_id}")
    if values["Task ID"] != task_id:
        raise AssertionError(f"{note} task id mismatch: {values['Task ID']} != {task_id}")
    if values["Scope"] != scope:
        raise AssertionError(f"{note} scope mismatch: {values['Scope']} != {scope}")

    result = values["Result"].lower()
    if allow_pending:
        if result not in allowed_results | pending_results:
            raise AssertionError(f"{note} has invalid result: {values['Result']}")
    else:
        if result not in allowed_results:
            strict_missing.append(f"{scenario_id}: result is not final ({values['Result'] or 'blank'})")
        for field in [
            "macOS appearance",
            "Window size",
            "Project folder",
            "Terminal fixture or live terminal setup",
            "Keyboard path",
            "VoiceOver state",
            "Expected result",
            "Observed result",
            "Raw Terminal parity note",
            "Follow-up",
        ]:
            value = values[field]
            if not value or value.lower() in {"pending", "todo", "tbd"}:
                strict_missing.append(f"{scenario_id}: {field} is not filled")
    scenario_count += 1

if scenario_count < 24:
    raise AssertionError(f"expected at least 24 manual QA scenarios, found {scenario_count}")

if strict_missing:
    preview = "\n".join(f"- {item}" for item in strict_missing[:40])
    extra = "" if len(strict_missing) <= 40 else f"\n... and {len(strict_missing) - 40} more"
    raise AssertionError("manual QA evidence is incomplete:\n" + preview + extra)

mode = "structure" if allow_pending else "strict"
print(f"Product UI/UX evidence bundle {mode} check passed ({scenario_count} scenarios)")
PY
