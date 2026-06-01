#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
run_swift_tests=true
run_xcodebuild=true

usage() {
  cat <<'EOF'
Usage: scripts/qa/run-product-ui-ux-preflight.sh [--skip-swift-tests] [--skip-xcodebuild]

Runs the automatic preflight gates that must pass before product-grade UI/UX
live/manual QA starts. This script does not launch Penggie, Codex, Ghostty, or
any second user-visible terminal session.

Options:
  --skip-swift-tests  Skip swift test filters for fast local iteration.
  --skip-xcodebuild   Skip the Debug macOS Xcode build for fast local iteration.
  -h, --help          Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-swift-tests)
      run_swift_tests=false
      shift
      ;;
    --skip-xcodebuild)
      run_xcodebuild=false
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

run() {
  printf '\n==> %s\n' "$*"
  "$@"
}

cd "$repo_root"

run scripts/qa/check-openspec-worktree-inventory.sh
run openspec validate productize-ui-ux-contract --strict
run openspec validate --all --strict
run scripts/qa/check-product-grade-ui-ux-manual-qa.sh
run scripts/qa/check-product-ui-ux-task-evidence-map.sh
run scripts/qa/check-p0-terminal-owned-live-qa-readiness.sh
run scripts/qa/check-p0-composer-ime-focus-readiness.sh
run scripts/qa/check-p0-raw-terminal-source.sh
run scripts/qa/check-p1-visual-accessibility-readiness.sh
run scripts/qa/check-fixture-regression-coverage.sh
run scripts/qa/check-accessibility-smoke-source.sh
run scripts/qa/check-diagnostics-release-hygiene.sh
run scripts/check-theme-token-usage.sh

if [[ "$run_swift_tests" == true ]]; then
  run swift test --filter PenggieDisplayFixtureTests
  run swift test --filter PenggieTerminalInteractionSurfaceTests
else
  echo
  echo "Skipping swift test filters by request."
fi

if [[ "$run_xcodebuild" == true ]]; then
  run xcodebuild \
    -project Penggie/Penggie.xcodeproj \
    -scheme Penggie \
    -configuration Debug \
    -destination 'platform=macOS' \
    build
else
  echo
  echo "Skipping Debug macOS Xcode build by request."
fi

echo
echo "Product-grade UI/UX preflight passed"
