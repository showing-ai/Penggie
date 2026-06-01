#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
pid=""

usage() {
  cat <<'EOF'
Usage: scripts/qa/check-running-penggie-build-identity.sh [--pid PID] EVIDENCE_DIR

Checks that the running Penggie process is the same Debug build recorded in a
product UI/UX QA evidence bundle.

This is a QA guard only. It does not launch Penggie, Codex, Ghostty, or any
second user-visible session.

Options:
  --pid PID  Check a specific Penggie process when more than one is running.
  -h, --help Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pid)
      if [[ $# -lt 2 ]]; then
        echo "--pid requires a process id" >&2
        exit 2
      fi
      pid="$2"
      shift 2
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
build_identity="$bundle_dir/logs/build-identity.txt"

if [[ ! -f "$build_identity" ]]; then
  echo "Missing build identity log: $build_identity" >&2
  exit 1
fi

field_value() {
  local label="$1"
  sed -n "s/^- ${label}: //p" "$build_identity" | head -1
}

build_commit="$(field_value "Repo commit")"
expected_app="$(field_value "Built app")"
expected_dylib="$(field_value "Penggie debug dylib")"
expected_dylib_sha="$(field_value "Penggie debug dylib SHA256")"
expected_dylib_inode="$(sed -n 's/^- Penggie debug dylib stat: inode=\([0-9][0-9]*\).*/\1/p' "$build_identity" | head -1)"
expected_ghostty_sha="$(field_value "GhosttyKit static library SHA256")"
ghostty_static="$repo_root/Vendor/ghostty/macos/GhosttyKit.xcframework/macos-arm64_x86_64/ghostty-internal.a"

if [[ -z "$build_commit" || -z "$expected_app" || -z "$expected_dylib" ]]; then
  echo "Build identity is missing commit/app/dylib fields: $build_identity" >&2
  exit 1
fi

if [[ "$expected_dylib_sha" == "not found" || -z "$expected_dylib_sha" ]]; then
  echo "Build identity has no Penggie.debug.dylib SHA256: $build_identity" >&2
  exit 1
fi

if [[ "$expected_dylib_inode" == "" ]]; then
  echo "Build identity has no Penggie.debug.dylib inode: $build_identity" >&2
  exit 1
fi

current_commit="$(git -C "$repo_root" rev-parse HEAD)"
if [[ "$current_commit" != "$build_commit" ]]; then
  echo "Current repo commit does not match QA bundle build commit:" >&2
  echo "  current: $current_commit" >&2
  echo "  bundle:  $build_commit" >&2
  exit 1
fi

if [[ ! -d "$expected_app" ]]; then
  echo "Recorded Penggie.app does not exist: $expected_app" >&2
  exit 1
fi

if [[ ! -f "$expected_dylib" ]]; then
  echo "Recorded Penggie.debug.dylib does not exist: $expected_dylib" >&2
  exit 1
fi

actual_dylib_sha="$(shasum -a 256 "$expected_dylib" | awk '{ print $1 }')"
if [[ "$actual_dylib_sha" != "$expected_dylib_sha" ]]; then
  echo "Recorded Penggie.debug.dylib hash no longer matches disk:" >&2
  echo "  expected: $expected_dylib_sha" >&2
  echo "  actual:   $actual_dylib_sha" >&2
  exit 1
fi

if [[ "$expected_ghostty_sha" != "not found" && -n "$expected_ghostty_sha" ]]; then
  if [[ ! -f "$ghostty_static" ]]; then
    echo "GhosttyKit static library no longer exists: $ghostty_static" >&2
    exit 1
  fi
  actual_ghostty_sha="$(shasum -a 256 "$ghostty_static" | awk '{ print $1 }')"
  if [[ "$actual_ghostty_sha" != "$expected_ghostty_sha" ]]; then
    echo "Recorded GhosttyKit hash no longer matches disk:" >&2
    echo "  expected: $expected_ghostty_sha" >&2
    echo "  actual:   $actual_ghostty_sha" >&2
    exit 1
  fi
fi

if [[ -z "$pid" ]]; then
  pids=()
  while IFS= read -r found_pid; do
    [[ -n "$found_pid" ]] && pids+=("$found_pid")
  done < <(pgrep -x Penggie || true)
  if [[ "${#pids[@]}" -eq 0 ]]; then
    echo "No running Penggie process found. Start the recorded Debug app before live QA:" >&2
    echo "  open '$expected_app'" >&2
    exit 1
  fi
  if [[ "${#pids[@]}" -gt 1 ]]; then
    echo "Multiple Penggie processes are running; pass --pid explicitly:" >&2
    printf '  %s\n' "${pids[@]}" >&2
    exit 1
  fi
  pid="${pids[0]}"
fi

if ! ps -p "$pid" -o comm= >/dev/null 2>&1; then
  echo "Process is not running: $pid" >&2
  exit 1
fi

lsof_output="$(lsof -w -F pfin -p "$pid" 2>/dev/null || true)"
if [[ -z "$lsof_output" ]]; then
  echo "Unable to inspect process files with lsof: $pid" >&2
  exit 1
fi

tmp_lsof="$(mktemp)"
trap 'rm -f "$tmp_lsof"' EXIT
printf '%s\n' "$lsof_output" > "$tmp_lsof"

python3 - "$pid" "$expected_dylib" "$expected_dylib_inode" "$tmp_lsof" <<'PY'
import sys
from pathlib import Path

pid = sys.argv[1]
expected_path = Path(sys.argv[2])
expected_inode = sys.argv[3]
lsof_path = Path(sys.argv[4])
source = lsof_path.read_text().splitlines()

files = []
current = {}
for line in source:
    if not line:
        continue
    tag, value = line[0], line[1:]
    if tag == "p":
        continue
    if tag == "f":
        if current:
            files.append(current)
        current = {"fd": value}
    elif current:
        current[tag] = value
if current:
    files.append(current)

matches = [item for item in files if item.get("n") == str(expected_path)]
if not matches:
    dylibs = [item for item in files if item.get("n", "").endswith("/Penggie.debug.dylib")]
    if dylibs:
        loaded = "\n".join(f"  path={item.get('n')} inode={item.get('i', 'unknown')}" for item in dylibs)
        raise SystemExit(
            "Running Penggie loaded a different Penggie.debug.dylib than the QA bundle:\n"
            f"{loaded}\n"
            f"  expected path={expected_path} inode={expected_inode}"
        )
    raise SystemExit(f"Running process {pid} has not loaded Penggie.debug.dylib")

bad = [item for item in matches if item.get("i") != expected_inode]
if bad:
    loaded = "\n".join(f"  path={item.get('n')} inode={item.get('i', 'unknown')}" for item in matches)
    raise SystemExit(
        "Running Penggie.debug.dylib path matches, but inode differs; this is likely an old running process:\n"
        f"{loaded}\n"
        f"  expected path={expected_path} inode={expected_inode}"
    )

print(f"Running Penggie build identity matches QA bundle (pid={pid}, dylib inode={expected_inode})")
PY
