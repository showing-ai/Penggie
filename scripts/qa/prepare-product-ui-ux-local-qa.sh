#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
change_id="productize-ui-ux-contract"
evidence_root="$repo_root/tmp/product-ui-ux-qa"
manual_qa_script="$repo_root/openspec/changes/$change_id/product-grade-ui-ux-manual-qa-script.md"
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

mkdir -p \
  "$evidence_dir/screenshots" \
  "$evidence_dir/recordings" \
  "$evidence_dir/logs" \
  "$evidence_dir/notes"

if [[ "$run_build" == true ]]; then
  xcodebuild \
    -project "$repo_root/Penggie/Penggie.xcodeproj" \
    -scheme Penggie \
    -configuration Debug \
    -destination 'platform=macOS' \
    build 2>&1 | tee "$evidence_dir/logs/xcodebuild-debug-macos.log"
fi

show_build_settings() {
  xcodebuild \
    -project "$repo_root/Penggie/Penggie.xcodeproj" \
    -scheme Penggie \
    -configuration Debug \
    -destination 'platform=macOS' \
    -showBuildSettings 2>/dev/null
}

target_build_dir="$(show_build_settings | awk -F' = ' '/ TARGET_BUILD_DIR = / { print $2; exit }')"
app_path=""
if [[ -n "$target_build_dir" ]]; then
  app_path="$target_build_dir/Penggie.app"
fi

dylib_path="$app_path/Contents/MacOS/Penggie.debug.dylib"
ghostty_static="$repo_root/Vendor/ghostty/macos/GhosttyKit.xcframework/macos-arm64_x86_64/ghostty-internal.a"

{
  echo "# Product UI/UX QA Build Identity"
  echo
  echo "- Change: $change_id"
  echo "- Repo root: $repo_root"
  echo "- Repo commit: $commit_sha"
  echo "- Created UTC: $timestamp"
  echo "- Prepare script ran build: $run_build"
  echo "- Git dirty status:"
  git -C "$repo_root" status --short | sed 's/^/  /' || true
  if [[ -z "$(git -C "$repo_root" status --short)" ]]; then
    echo "  clean"
  fi
  echo "- Vendor/ghostty dirty status:"
  git -C "$repo_root/Vendor/ghostty" status --short | sed 's/^/  /' || true
  if [[ -z "$(git -C "$repo_root/Vendor/ghostty" status --short)" ]]; then
    echo "  clean"
  fi
  echo "- Target build dir: ${target_build_dir:-not found}"
  echo "- Built app: ${app_path:-not found}"
  if [[ -d "$app_path" ]]; then
    stat -f "- Built app stat: inode=%i size=%z mtime=%Sm path=%N" "$app_path"
  else
    echo "- Built app stat: not found"
  fi
  echo "- Penggie debug dylib: $dylib_path"
  if [[ -f "$dylib_path" ]]; then
    stat -f "- Penggie debug dylib stat: inode=%i size=%z mtime=%Sm path=%N" "$dylib_path"
    shasum -a 256 "$dylib_path" | awk '{ print "- Penggie debug dylib SHA256: " $1 }'
  else
    echo "- Penggie debug dylib stat: not found"
    echo "- Penggie debug dylib SHA256: not found"
  fi
  echo "- GhosttyKit static library: $ghostty_static"
  if [[ -f "$ghostty_static" ]]; then
    stat -f "- GhosttyKit static library stat: inode=%i size=%z mtime=%Sm path=%N" "$ghostty_static"
    shasum -a 256 "$ghostty_static" | awk '{ print "- GhosttyKit static library SHA256: " $1 }'
  else
    echo "- GhosttyKit static library stat: not found"
    echo "- GhosttyKit static library SHA256: not found"
  fi
} > "$evidence_dir/logs/build-identity.txt"

cat > "$evidence_dir/README.md" <<EOF
# Product-Grade UI/UX QA Evidence

- Change: \`$change_id\`
- Commit: \`$commit_sha\`
- Created UTC: \`$timestamp\`
- Build identity: \`logs/build-identity.txt\`

## Source Of Truth Rules

- Use the running Penggie app and its embedded Ghostty/Codex session as the only user-visible truth.
- Do not launch a second Codex CLI, second Ghostty session, SDK mirror, or \`codex exec --json\` session for pass/fail evidence.
- Screenshots and recordings are review artifacts only; terminal-frame fixtures and Raw Terminal parity remain authoritative for terminal-owned state.

## Evidence Folders

- \`screenshots/\`: light/dark, narrow, large text, overlay, Raw Terminal, recovery captures.
- \`recordings/\`: optional short videos for flicker, focus, or scrolling behavior.
- \`logs/\`: relevant app/system logs when a scenario fails.
- \`notes/\`: per-scenario manual QA notes with embedded scenario-specific steps.
- \`manifest.tsv\`: required scenarios, owning task IDs, review scope, and required coverage.

When a scenario requires screenshots or recordings, record relative paths such
as \`screenshots/QA-OVERLAY-003-light.png\` in the scenario note. If a scenario
result is \`fail\` or \`blocked\`, record at least one relative path under
\`logs/\` in \`Diagnostic/log path\`.

## Required Local Checks

\`\`\`bash
scripts/qa/prepare-product-ui-ux-local-qa.sh --build --evidence-dir "$evidence_root"
scripts/qa/check-running-penggie-build-identity.sh "$evidence_dir"
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
scripts/qa/check-product-ui-ux-live-qa-status.sh --strict --evidence-dir "$evidence_dir"
\`\`\`

The strict checker fails until the recorded Debug app is the running Penggie
process and every required scenario note has a non-placeholder result, observed
result, Raw Terminal parity note where applicable, follow-up, and the coverage
required by \`manifest.tsv\`.

EOF

cp "$repo_root/scripts/qa/product-ui-ux-manifest.tsv" "$evidence_dir/manifest.tsv"

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
- Diagnostic/log path:
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
- Diagnostic/log path:
- Follow-up:

## Notes

EOF
done

python3 - "$repo_root" "$manual_qa_script" "$evidence_dir/manifest.tsv" "$evidence_dir/notes" <<'PY'
import re
import sys
from pathlib import Path

sys.tracebacklimit = 0

repo_root = Path(sys.argv[1])
manual_qa = Path(sys.argv[2])
manifest = Path(sys.argv[3])
notes_dir = Path(sys.argv[4])

source = manual_qa.read_text()
sections: dict[str, str] = {}
matches = list(re.finditer(r"^### (QA-[A-Z]+-\d+): .+$", source, flags=re.M))
for index, match in enumerate(matches):
    scenario_id = match.group(1)
    start = match.start()
    end = matches[index + 1].start() if index + 1 < len(matches) else len(source)
    sections[scenario_id] = source[start:end].strip()

rows = manifest.read_text().splitlines()[1:]
missing: list[str] = []
for line in rows:
    if not line.strip():
        continue
    scenario_id = line.split("\t", 1)[0]
    section = sections.get(scenario_id)
    if not section:
        missing.append(scenario_id)
        continue
    note = notes_dir / f"{scenario_id}.md"
    note.write_text(
        note.read_text()
        + "\n## Manual QA Steps\n\n"
        + f"Source: `{manual_qa.relative_to(repo_root)}`\n\n"
        + section
        + "\n"
    )

if missing:
    raise AssertionError(
        "manual QA script is missing scenario sections: " + ", ".join(sorted(missing))
    )
PY

echo "Prepared product UI/UX QA evidence directory:"
echo "$evidence_dir"
