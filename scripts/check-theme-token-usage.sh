#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PATTERN='NSColor\.|windowBackgroundColor|textBackgroundColor|controlBackgroundColor|separatorColor|selectedMenuItemTextColor|Color\.accentColor|Color\.black|Color\.white|#[0-9A-Fa-f]{6}|One Half Dark|Builtin Light'

if rg -n "$PATTERN" "$ROOT_DIR/Penggie/Sources" -g'*.swift' | rg -v 'PenggieTheme\.swift'; then
  echo "Theme token check failed: use PenggieTheme semantic, scene, or component tokens outside PenggieTheme.swift." >&2
  exit 1
fi

echo "Theme token check passed."
