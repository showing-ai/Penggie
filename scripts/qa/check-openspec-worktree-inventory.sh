#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
changes_dir="$repo_root/openspec/changes"
archive_dir="$changes_dir/archive"
ghostty_dir="$repo_root/Vendor/ghostty"

python3 - "$repo_root" <<'PY'
import subprocess
import sys
from pathlib import Path

sys.tracebacklimit = 0

repo_root = Path(sys.argv[1])
changes_dir = repo_root / "openspec/changes"
archive_dir = changes_dir / "archive"
ghostty_dir = repo_root / "Vendor/ghostty"

expected_active = {"productize-ui-ux-contract"}
expected_archived_by_change = {
    "implement-p0-terminal-surface-lifecycle": "2026-05-31-implement-p0-terminal-surface-lifecycle",
    "harden-terminal-ux-qa-foundation": "2026-05-31-harden-terminal-ux-qa-foundation",
    "define-product-grade-ui-ux": "2026-06-01-define-product-grade-ui-ux",
    "stabilize-embedded-ghostty-foundation": "2026-05-31-stabilize-embedded-ghostty-foundation",
}


def run(cmd: list[str], cwd: Path) -> str:
    result = subprocess.run(cmd, cwd=cwd, text=True, capture_output=True, check=False)
    if result.returncode != 0:
        raise AssertionError(
            f"Command failed ({' '.join(cmd)}):\nSTDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}"
        )
    return result.stdout


if not changes_dir.exists():
    raise AssertionError(f"Missing OpenSpec changes directory: {changes_dir}")
if not archive_dir.exists():
    raise AssertionError(f"Missing OpenSpec archive directory: {archive_dir}")
if not ghostty_dir.exists():
    raise AssertionError(f"Missing Ghostty vendor directory: {ghostty_dir}")

active_changes = {
    path.name
    for path in changes_dir.iterdir()
    if path.is_dir() and path.name != "archive"
}
unexpected_active = sorted(active_changes - expected_active)
missing_active = sorted(expected_active - active_changes)
if unexpected_active:
    raise AssertionError(
        "Unexpected active OpenSpec changes require explicit triage before product UI/UX QA: "
        + ", ".join(unexpected_active)
    )
if missing_active:
    raise AssertionError(
        "Expected active OpenSpec change is missing: " + ", ".join(missing_active)
    )

missing_archives = []
for change_id, archive_name in expected_archived_by_change.items():
    archive_path = archive_dir / archive_name
    if not archive_path.is_dir():
        missing_archives.append(f"{change_id} -> {archive_name}")
if missing_archives:
    raise AssertionError(
        "Expected OpenSpec archives are missing: " + "; ".join(missing_archives)
    )

ghostty_status = run(["git", "status", "--short"], ghostty_dir).strip()
if ghostty_status:
    raise AssertionError(
        "Vendor/ghostty has dirty changes; classify them before product UI/UX QA:\n"
        + ghostty_status
    )

ghostty_branch = run(["git", "status", "--short", "--branch"], ghostty_dir).splitlines()[0].strip()
if not ghostty_branch.startswith("## "):
    raise AssertionError(f"Unable to read Vendor/ghostty branch state: {ghostty_branch}")

print(
    "OpenSpec/worktree inventory guard passed "
    f"({len(active_changes)} active change, {len(expected_archived_by_change)} expected archives, "
    f"Vendor/ghostty clean: {ghostty_branch})"
)
PY
