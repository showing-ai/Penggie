#!/usr/bin/env bash
set -euo pipefail

allow_pending=false

usage() {
  cat <<'EOF'
Usage: scripts/qa/check-product-ui-ux-evidence-bundle.sh [--allow-pending] EVIDENCE_DIR

Validates a product-grade UI/UX manual QA evidence bundle.

Without --allow-pending, every manifest scenario note must contain a filled
result, observation fields, and the scenario-specific coverage required by the
manifest. This script checks evidence completeness only; it does not treat
screenshots as terminal-owned state truth.

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
build_identity="$bundle_dir/logs/build-identity.txt"

if [[ ! -d "$bundle_dir" ]]; then
  echo "Evidence directory does not exist: $bundle_dir" >&2
  exit 1
fi

for required in "$readme" "$manifest" "$notes_dir/scenario-template.md" "$build_identity"; do
  if [[ ! -e "$required" ]]; then
    echo "Missing required evidence artifact: $required" >&2
    exit 1
  fi
done

if ! grep -q '^- Repo commit: [0-9a-f]' "$build_identity"; then
  echo "Build identity is missing the repository commit: $build_identity" >&2
  exit 1
fi
build_commit="$(sed -n 's/^- Repo commit: //p' "$build_identity" | head -1)"

if ! grep -Eq '^- Built app: .*/Penggie\.app$' "$build_identity"; then
  echo "Build identity is missing the Debug Penggie.app path: $build_identity" >&2
  exit 1
fi

if [[ "$allow_pending" != true ]]; then
  if grep -q '^- Built app stat: not found$' "$build_identity"; then
    echo "Strict evidence requires an existing built Penggie.app: $build_identity" >&2
    exit 1
  fi
  if grep -q '^- Penggie debug dylib SHA256: not found$' "$build_identity"; then
    echo "Strict evidence requires a built Penggie.debug.dylib hash: $build_identity" >&2
    exit 1
  fi
  if grep -q '^- GhosttyKit static library SHA256: not found$' "$build_identity"; then
    echo "Strict evidence requires a GhosttyKit static library hash: $build_identity" >&2
    exit 1
  fi
fi

python3 - "$manifest" "$notes_dir" "$allow_pending" "$build_commit" "$bundle_dir" <<'PY'
import re
import sys
from pathlib import Path

sys.tracebacklimit = 0

manifest = Path(sys.argv[1])
notes_dir = Path(sys.argv[2])
allow_pending = sys.argv[3] == "true"
build_commit = sys.argv[4]
bundle_dir = Path(sys.argv[5]).resolve()

rows = manifest.read_text().splitlines()
if not rows or rows[0] != "Scenario ID\tTask ID\tScope\tCoverage":
    raise AssertionError("manifest.tsv must start with the expected header")

required_fields = [
    "Scenario ID",
    "Task ID",
    "Scope",
    "Required coverage",
    "Result",
    "Commit SHA",
    "Build configuration",
    "macOS appearance",
    "Window size",
    "Project folder",
    "Terminal fixture or live terminal setup",
    "Keyboard path",
    "Pointer path",
    "VoiceOver state",
    "Expected result",
    "Observed result",
    "Raw Terminal parity note",
    "Screenshot/recording path",
    "Diagnostic/log path",
    "Follow-up",
]

allowed_results = {"pass", "fail", "blocked", "not applicable"}
pending_results = {"pending", ""}
allowed_coverage_keys = {
    "theme",
    "window",
    "voiceover",
    "terminal",
    "keyboard",
    "pointer",
    "raw-terminal",
    "screenshot",
    "motion",
    "contrast",
}


def field_value(source: str, field: str) -> str:
    match = re.search(rf"^- {re.escape(field)}:[ \t]*(.*)$", source, flags=re.M)
    if not match:
        raise AssertionError(f"missing field {field}")
    return match.group(1).strip()


def parse_coverage(raw: str) -> dict[str, list[str]]:
    if not raw:
        raise AssertionError("coverage must not be blank")
    parsed: dict[str, list[str]] = {}
    for clause in raw.split(";"):
        clause = clause.strip()
        if not clause:
            continue
        if "=" not in clause:
            raise AssertionError(f"invalid coverage clause: {clause!r}")
        key, values = clause.split("=", 1)
        key = key.strip()
        values = values.strip()
        if key not in allowed_coverage_keys:
            raise AssertionError(f"unknown coverage key: {key!r}")
        if not values:
            raise AssertionError(f"coverage key {key!r} has no values")
        tokens = [token.strip().lower() for token in values.split(",") if token.strip()]
        if not tokens:
            raise AssertionError(f"coverage key {key!r} has no tokens")
        parsed[key] = tokens
    if not parsed:
        raise AssertionError("coverage must include at least one key")
    return parsed


def token_present(value: str, token: str) -> bool:
    normalized = value.lower()
    token = token.lower()
    if token in {"optional", "not-required", "none", "required"}:
        return True
    token_words = re.split(r"[-_]", token)
    return all(word in normalized for word in token_words if word)


def referenced_paths(value: str) -> list[str]:
    paths: list[str] = []
    for part in re.split(r"[,;]", value):
        part = part.strip()
        if part:
            paths.append(part)
    return paths


def require_existing_artifacts(
    value: str,
    scenario_id: str,
    field: str,
    allowed_roots: set[str],
) -> list[str]:
    errors: list[str] = []
    paths = referenced_paths(value)
    if not paths:
        return [f"{scenario_id}: {field} must reference an evidence artifact path"]

    for raw_path in paths:
        path = Path(raw_path)
        if path.is_absolute():
            errors.append(f"{scenario_id}: {field} must use a relative evidence path: {raw_path}")
            continue
        if not path.parts or path.parts[0] not in allowed_roots:
            allowed = ", ".join(sorted(allowed_roots))
            errors.append(f"{scenario_id}: {field} must be under {allowed}: {raw_path}")
            continue

        resolved = (bundle_dir / path).resolve()
        try:
            resolved.relative_to(bundle_dir)
        except ValueError:
            errors.append(f"{scenario_id}: {field} escapes evidence bundle: {raw_path}")
            continue
        if not resolved.exists():
            errors.append(f"{scenario_id}: {field} path does not exist: {raw_path}")

    return errors


def require_coverage(values: dict[str, str], coverage: dict[str, list[str]], scenario_id: str) -> list[str]:
    errors: list[str] = []
    field_for_key = {
        "theme": "macOS appearance",
        "window": "Window size",
        "voiceover": "VoiceOver state",
        "terminal": "Terminal fixture or live terminal setup",
        "keyboard": "Keyboard path",
        "pointer": "Pointer path",
        "raw-terminal": "Raw Terminal parity note",
        "screenshot": "Screenshot/recording path",
        "motion": "Observed result",
        "contrast": "Observed result",
    }
    for key, tokens in coverage.items():
        field = field_for_key[key]
        value = values[field]
        if key in {"raw-terminal", "screenshot", "pointer"} and tokens == ["not-required"]:
            continue
        if not value or value.lower() in {"pending", "todo", "tbd"}:
            errors.append(f"{scenario_id}: {field} is required by coverage {key}={','.join(tokens)}")
            continue
        if key == "screenshot" and "required" in tokens:
            errors.extend(
                require_existing_artifacts(
                    value,
                    scenario_id,
                    field,
                    {"screenshots", "recordings"},
                )
            )
        for token in tokens:
            if not token_present(value, token):
                errors.append(f"{scenario_id}: {field} does not include coverage token {token!r}")
    return errors


scenario_count = 0
strict_missing = []

for line in rows[1:]:
    if not line.strip():
        continue
    parts = line.split("\t")
    if len(parts) != 4:
        raise AssertionError(f"manifest row must have 4 tab-separated columns: {line!r}")
    scenario_id, task_id, scope, coverage_raw = parts
    coverage = parse_coverage(coverage_raw)
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
    if values["Required coverage"] != coverage_raw:
        raise AssertionError(f"{note} required coverage mismatch: {values['Required coverage']} != {coverage_raw}")
    if values["Commit SHA"] != build_commit:
        raise AssertionError(f"{note} commit mismatch: {values['Commit SHA']} != {build_commit}")
    if f"### {scenario_id}:" not in source or "## Manual QA Steps" not in source:
        raise AssertionError(f"{note} is missing embedded manual QA steps for {scenario_id}")

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
            "Pointer path",
            "VoiceOver state",
            "Expected result",
            "Observed result",
            "Raw Terminal parity note",
            "Follow-up",
        ]:
            value = values[field]
            if not value or value.lower() in {"pending", "todo", "tbd"}:
                strict_missing.append(f"{scenario_id}: {field} is not filled")
        strict_missing.extend(require_coverage(values, coverage, scenario_id))
        if result in {"fail", "blocked"}:
            strict_missing.extend(
                require_existing_artifacts(
                    values["Diagnostic/log path"],
                    scenario_id,
                    "Diagnostic/log path",
                    {"logs"},
                )
            )
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
