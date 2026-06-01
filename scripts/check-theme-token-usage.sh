#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BASELINE_FILE="$ROOT_DIR/scripts/theme-token-usage-baseline.txt"

STRICT_PATTERN='NSColor\.(windowBackgroundColor|textBackgroundColor|controlBackgroundColor|separatorColor|selectedMenuItemTextColor)|Color\.accentColor|Color\.black|Color\.white|#[0-9A-Fa-f]{6}|One Half Dark|Builtin Light'

if rg -n "$STRICT_PATTERN" "$ROOT_DIR/Penggie/Sources" -g'*.swift' | rg -v 'PenggieTheme\.swift'; then
  echo "Theme token check failed: use PenggieTheme semantic, scene, or component tokens outside PenggieTheme.swift." >&2
  exit 1
fi

python3 - "$ROOT_DIR" "$BASELINE_FILE" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
baseline_path = Path(sys.argv[2])

system_style_patterns = {
    r"\.foregroundStyle\(\.primary\)": "foregroundStyle(.primary)",
    r"\.foregroundStyle\(\.secondary\)": "foregroundStyle(.secondary)",
    r"\.foregroundStyle\(\.tertiary\)": "foregroundStyle(.tertiary)",
    r"\.foregroundStyle\(\.orange\)": "foregroundStyle(.orange)",
}

allowed = {}
for line_number, raw_line in enumerate(baseline_path.read_text().splitlines(), start=1):
    line = raw_line.strip()
    if not line or line.startswith("#"):
        continue
    parts = line.split("|", 3)
    if len(parts) < 3:
        raise SystemExit(f"{baseline_path}:{line_number}: expected path|regex|max_count|reason")
    relative_path, regex, max_count = parts[:3]
    try:
        allowed[(relative_path, regex)] = int(max_count)
    except ValueError:
        raise SystemExit(f"{baseline_path}:{line_number}: max_count must be an integer")

failures = []
for swift_file in sorted((root / "Penggie" / "Sources").rglob("*.swift")):
    relative_path = swift_file.relative_to(root).as_posix()
    text = swift_file.read_text()
    for regex, label in system_style_patterns.items():
        count = len(re.findall(regex, text))
        max_count = allowed.get((relative_path, regex), 0)
        if count > max_count:
            failures.append(
                f"{relative_path}: {label} count {count} exceeds allowed baseline {max_count}"
            )

if failures:
    print(
        "Theme token check failed: new product-surface system color styles must use PenggieTheme tokens.",
        file=sys.stderr,
    )
    for failure in failures:
        print(failure, file=sys.stderr)
    raise SystemExit(1)
PY

echo "Theme token check passed."
