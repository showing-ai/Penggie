#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GHOSTTY_DIR="$ROOT_DIR/Vendor/ghostty"

if [[ ! -d "$GHOSTTY_DIR" ]]; then
  echo "Missing Ghostty submodule at $GHOSTTY_DIR" >&2
  echo "Run: git submodule update --init --recursive" >&2
  exit 1
fi

cd "$GHOSTTY_DIR"
zig build -Demit-xcframework=true -Demit-macos-app=false
