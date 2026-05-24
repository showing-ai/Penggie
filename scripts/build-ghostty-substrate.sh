#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GHOSTTY_DIR="$ROOT_DIR/Vendor/ghostty"
PATCH_DIR="$ROOT_DIR/patches/ghostty"

if [[ ! -d "$GHOSTTY_DIR" ]]; then
  echo "Missing Ghostty submodule at $GHOSTTY_DIR" >&2
  echo "Run: git submodule update --init --recursive" >&2
  exit 1
fi

cd "$GHOSTTY_DIR"
for patch in "$PATCH_DIR"/*.patch; do
  [[ -e "$patch" ]] || continue
  if git apply --check "$patch" >/dev/null 2>&1; then
    git apply "$patch"
  elif git apply --reverse --check "$patch" >/dev/null 2>&1; then
    echo "Ghostty patch already applied: $(basename "$patch")"
  else
    echo "Ghostty patch does not apply cleanly: $patch" >&2
    exit 1
  fi
done

zig build -Demit-xcframework=true -Demit-macos-app=false
