#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GHOSTTY_DIR="$ROOT_DIR/Vendor/ghostty"
PATCH_DIR="$ROOT_DIR/patches/ghostty"
ARTIFACT="$GHOSTTY_DIR/macos/GhosttyKit.xcframework/macos-arm64_x86_64/ghostty-internal.a"
STAMP_FILE="$GHOSTTY_DIR/macos/GhosttyKit.xcframework/.penggie-substrate.stamp"

if [[ ! -d "$GHOSTTY_DIR" ]]; then
  echo "Missing Ghostty submodule at $GHOSTTY_DIR" >&2
  echo "Run: git submodule update --init --recursive" >&2
  exit 1
fi

cd "$GHOSTTY_DIR"

fingerprint() {
  {
    echo "build-options:zig build -Demit-xcframework=true -Demit-macos-app=false"
    echo "ghostty-head:$(git rev-parse HEAD)"
    echo "build-script:"
    shasum -a 256 "$ROOT_DIR/scripts/build-ghostty-substrate.sh"
    echo "patches:"
    find "$PATCH_DIR" -type f -name '*.patch' -print0 | sort -z | xargs -0 shasum -a 256
  } | shasum -a 256 | awk '{print $1}'
}

current_stamp="$(fingerprint)"
if [[ -f "$ARTIFACT" && -f "$STAMP_FILE" ]]; then
  recorded_stamp="$(cat "$STAMP_FILE")"
  if [[ "$recorded_stamp" == "$current_stamp" ]]; then
    echo "Ghostty substrate is up to date: $recorded_stamp"
    exit 0
  fi
fi

applied_patches=()
restore_applied_patches() {
  local index
  for (( index=${#applied_patches[@]}-1; index>=0; index-- )); do
    git apply --reverse "${applied_patches[$index]}"
  done
}

trap restore_applied_patches EXIT

for patch in "$PATCH_DIR"/*.patch; do
  [[ -e "$patch" ]] || continue
  if git apply --check "$patch" >/dev/null 2>&1; then
    git apply "$patch"
    applied_patches+=("$patch")
  elif git apply --reverse --check "$patch" >/dev/null 2>&1; then
    echo "Ghostty patch already applied: $(basename "$patch")"
  else
    echo "Ghostty patch does not apply cleanly: $patch" >&2
    exit 1
  fi
done

zig build -Demit-xcframework=true -Demit-macos-app=false
fingerprint > "$STAMP_FILE"
