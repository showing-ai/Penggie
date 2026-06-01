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
- \`manifest.tsv\`: required scenarios, owning task IDs, review scope, and required coverage.

## Required Local Checks

\`\`\`bash
openspec validate productize-ui-ux-contract --strict
openspec validate --all --strict
scripts/qa/check-product-grade-ui-ux-manual-qa.sh
scripts/qa/check-product-ui-ux-evidence-bundle.sh --allow-pending "$evidence_dir"
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

For final acceptance of live manual QA, rerun:

\`\`\`bash
scripts/qa/check-product-ui-ux-evidence-bundle.sh "$evidence_dir"
\`\`\`

The strict checker fails until every required scenario note has a non-placeholder
result, observed result, Raw Terminal parity note where applicable, follow-up,
and the coverage required by \`manifest.tsv\`.

EOF

cat > "$evidence_dir/manifest.tsv" <<'EOF'
Scenario ID	Task ID	Scope	Coverage
QA-SETUP-001	2.2	Valid folder start	theme=light,dark;window=normal;voiceover=on;terminal=none;keyboard=tab-space
QA-SETUP-002	2.2	Invalid or missing folder recovery	theme=light,dark;window=normal,narrow;voiceover=on;terminal=none;keyboard=tab-enter
QA-LIFE-001	2.6	New Chat confirmation	theme=light,dark;window=normal;voiceover=on;terminal=live;keyboard=esc-enter;raw-terminal=not-required
QA-LIFE-002	2.6	Close Session confirmation	theme=light,dark;window=normal;voiceover=on;terminal=live;keyboard=esc-enter;raw-terminal=not-required
QA-OVERLAY-001	3.10	Slash suggestions	theme=light,dark;window=normal,narrow;voiceover=on;terminal=live;keyboard=arrows-enter-esc-backspace-filter;raw-terminal=required
QA-OVERLAY-002	3.10	Model and effort picker	theme=light,dark;window=normal,narrow;voiceover=on;terminal=live;keyboard=arrows-tab-enter-esc;raw-terminal=required
QA-OVERLAY-003	3.10	Resume picker scroll, filter, sort, and page boundary	theme=light,dark;window=normal,narrow;voiceover=on;terminal=live;keyboard=arrows-tab-enter-esc-backspace-filter;raw-terminal=required;screenshot=required
QA-OVERLAY-004	3.10	Approval and permission modal choices	theme=light,dark;window=normal;voiceover=on;terminal=live;keyboard=arrows-enter-esc;raw-terminal=required;screenshot=required
QA-COMP-001	4.2	IME marked text	theme=light,dark;window=normal;voiceover=optional;terminal=live;keyboard=ime-enter;raw-terminal=not-required
QA-COMP-002	4.3	Ordinary composer behavior	theme=light,dark;window=normal,narrow;voiceover=on;terminal=live;keyboard=enter-shift-enter-paste-large-paste;raw-terminal=not-required
QA-COMP-003	4.4	Slash handoff focus	theme=light,dark;window=normal;voiceover=on;terminal=live;keyboard=slash-arrows-esc;raw-terminal=required
QA-FOCUS-001	4.5	Focus transitions across app states	theme=light,dark;window=normal,narrow;voiceover=on;terminal=live;keyboard=tab-esc-enter-mode-switch;raw-terminal=required
QA-READ-001	5.3	Long transcript stability	theme=light,dark;window=normal,narrow;voiceover=optional;terminal=live-or-fixture;keyboard=scroll-switch-resize-submit;raw-terminal=required
QA-READ-002	5.6	CJK, table, code, warning, and fallback display	theme=light,dark;window=normal,narrow,large-text;voiceover=on;terminal=live-or-fixture;keyboard=scroll-resize-switch;raw-terminal=required;screenshot=required
QA-RAW-001	6.2	Reading to Raw Terminal round trip	theme=light,dark;window=normal;voiceover=on;terminal=live;keyboard=mode-switch;raw-terminal=required
QA-RAW-002	6.4	Raw Terminal keyboard focus and clipboard	theme=light,dark;window=normal;voiceover=optional;terminal=live;keyboard=raw-keys-copy-paste;pointer=selection;raw-terminal=required
QA-RAW-003	6.3	Raw Terminal availability during low-confidence projection	theme=light,dark;window=normal;voiceover=optional;terminal=live-or-fixture;keyboard=mode-switch;raw-terminal=required
QA-RAW-004	6.5	Raw Terminal text selection, copy, paste, and mouse reporting	theme=light,dark;window=normal;voiceover=optional;terminal=live;keyboard=copy-paste;pointer=selection-shift-drag;raw-terminal=required
QA-RAW-005	6.6	Raw Terminal visual parity	theme=light,dark;window=normal,narrow;voiceover=optional;terminal=live;keyboard=mode-switch;raw-terminal=required;screenshot=required
QA-AX-001	7.4	Keyboard-only and larger text journey	theme=light,dark;window=normal,large-text;voiceover=on;terminal=live;keyboard=keyboard-only;raw-terminal=required;screenshot=required
QA-AX-002	7.5	Reduced motion and dynamic announcements	theme=light,dark;window=normal;voiceover=on;terminal=live;keyboard=working-approval-permission;motion=reduced;raw-terminal=required
QA-VIS-001	8.3	Light and dark visual capture matrix	theme=light,dark;window=normal,narrow,large-text;voiceover=optional;terminal=live;keyboard=visual-path;screenshot=required
QA-VIS-002	8.4	Density rules	theme=light,dark;window=normal,narrow,large-text;voiceover=optional;terminal=live-or-fixture;keyboard=visual-path;screenshot=required
QA-VIS-003	8.5	Contrast targets	theme=light,dark;window=normal,narrow;voiceover=optional;terminal=live-or-fixture;keyboard=visual-path;contrast=required;screenshot=required
EOF

cat > "$evidence_dir/notes/scenario-template.md" <<'EOF'
# Scenario Evidence

- Scenario ID:
- Task ID:
- Scope:
- Required coverage:
- Result: pass / fail / blocked / not applicable
- Commit SHA:
- Build configuration:
- macOS appearance:
- Window size:
- Project folder:
- Terminal fixture or live terminal setup:
- Keyboard path:
- Pointer path:
- VoiceOver state:
- Expected result:
- Observed result:
- Raw Terminal parity note:
- Screenshot/recording path:
- Follow-up:
EOF

tail -n +2 "$evidence_dir/manifest.tsv" | while IFS=$'\t' read -r scenario_id task_id scope coverage; do
  note_path="$evidence_dir/notes/$scenario_id.md"
  cat > "$note_path" <<EOF
# Scenario Evidence: $scenario_id

- Scenario ID: $scenario_id
- Task ID: $task_id
- Scope: $scope
- Required coverage: $coverage
- Result: pending
- Commit SHA: $commit_sha
- Build configuration: Debug
- macOS appearance:
- Window size:
- Project folder:
- Terminal fixture or live terminal setup:
- Keyboard path:
- Pointer path:
- VoiceOver state:
- Expected result:
- Observed result:
- Raw Terminal parity note:
- Screenshot/recording path:
- Follow-up:

## Notes

EOF
done

echo "Prepared product UI/UX QA evidence directory:"
echo "$evidence_dir"
