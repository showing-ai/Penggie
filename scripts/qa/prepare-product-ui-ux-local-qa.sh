#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
change_id="productize-ui-ux-contract"
evidence_root="$repo_root/tmp/product-ui-ux-qa"
run_build=false

usage() {
  cat <<'EOF'
Usage: scripts/qa/prepare-product-ui-ux-local-qa.sh [--build] [--evidence-dir PATH]

Creates a local QA evidence directory for the product-grade UI/UX matrix.
This script does not launch Codex, Ghostty, or a second user-visible session.

Options:
  --build              Run the Debug macOS xcodebuild before writing evidence notes.
  --evidence-dir PATH  Write the evidence bundle under PATH instead of tmp/product-ui-ux-qa.
  -h, --help           Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build)
      run_build=true
      shift
      ;;
    --evidence-dir)
      if [[ $# -lt 2 ]]; then
        echo "--evidence-dir requires a path" >&2
        exit 2
      fi
      evidence_root="$2"
      shift 2
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

commit_sha="$(git -C "$repo_root" rev-parse HEAD)"
timestamp="$(date -u +"%Y%m%dT%H%M%SZ")"
evidence_dir="$evidence_root/$timestamp-$commit_sha"

if [[ "$run_build" == true ]]; then
  xcodebuild \
    -project "$repo_root/Penggie/Penggie.xcodeproj" \
    -scheme Penggie \
    -configuration Debug \
    -destination 'platform=macOS' \
    build
fi

mkdir -p \
  "$evidence_dir/screenshots" \
  "$evidence_dir/recordings" \
  "$evidence_dir/logs" \
  "$evidence_dir/notes"

cat > "$evidence_dir/README.md" <<EOF
# Product-Grade UI/UX QA Evidence

- Change: \`$change_id\`
- Commit: \`$commit_sha\`
- Created UTC: \`$timestamp\`

## Source Of Truth Rules

- Use the running Penggie app and its embedded Ghostty/Codex session as the only user-visible truth.
- Do not launch a second Codex CLI, second Ghostty session, SDK mirror, or \`codex exec --json\` session for pass/fail evidence.
- Screenshots and recordings are review artifacts only; terminal-frame fixtures and Raw Terminal parity remain authoritative for terminal-owned state.

## Evidence Folders

- \`screenshots/\`: light/dark, narrow, large text, overlay, Raw Terminal, recovery captures.
- \`recordings/\`: optional short videos for flicker, focus, or scrolling behavior.
- \`logs/\`: relevant app/system logs when a scenario fails.
- \`notes/\`: per-scenario manual QA notes.

## Required Local Checks

\`\`\`bash
openspec validate productize-ui-ux-contract --strict
openspec validate --all --strict
scripts/qa/check-product-grade-ui-ux-manual-qa.sh
scripts/qa/check-fixture-regression-coverage.sh
scripts/qa/check-accessibility-smoke-source.sh
scripts/qa/check-diagnostics-release-hygiene.sh
scripts/check-theme-token-usage.sh
swift test --filter PenggieDisplayFixtureTests
swift test --filter PenggieTerminalInteractionSurfaceTests
xcodebuild -project Penggie/Penggie.xcodeproj -scheme Penggie -configuration Debug -destination 'platform=macOS' build
\`\`\`

## Manual QA References

- \`openspec/changes/productize-ui-ux-contract/product-grade-ui-ux-manual-qa-script.md\`
- \`openspec/changes/productize-ui-ux-contract/voiceover-manual-qa-checklist.md\`
- \`openspec/changes/productize-ui-ux-contract/release-readiness-checklist.md\`

## Visual QA Capture Matrix

Capture pass/fail evidence for:

- setup
- empty Reading
- long transcript
- composer focus
- slash overlay
- resume picker
- approval or permission
- Raw Terminal
- recovery
- narrow window
- large text
- light mode
- dark mode

EOF

cat > "$evidence_dir/notes/scenario-template.md" <<'EOF'
# Scenario Evidence

- Scenario ID:
- Result: pass / fail / blocked / not applicable
- Commit SHA:
- Build configuration:
- macOS appearance:
- Window size:
- Project folder:
- Terminal fixture or live terminal setup:
- Keyboard path:
- VoiceOver state:
- Expected result:
- Observed result:
- Raw Terminal parity note:
- Screenshot/recording path:
- Follow-up:
EOF

echo "Prepared product UI/UX QA evidence directory:"
echo "$evidence_dir"
