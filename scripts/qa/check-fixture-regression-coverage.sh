#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
terminal_fixtures="$repo_root/Tests/PenggieCoreTests/Fixtures/terminal-interaction-surfaces"
display_fixtures="$repo_root/Tests/PenggieCoreTests/Fixtures/agent-terminal-display"
terminal_tests="$repo_root/Tests/PenggieCoreTests/PenggieTerminalInteractionSurfaceTests.swift"
display_tests="$repo_root/Tests/PenggieCoreTests/PenggieDisplayFixtureTests.swift"
tasks="$repo_root/openspec/changes/productize-ui-ux-contract/tasks.md"
evidence="$repo_root/openspec/changes/productize-ui-ux-contract/fixture-regression-coverage.md"

python3 - "$terminal_fixtures" "$display_fixtures" "$terminal_tests" "$display_tests" "$tasks" "$evidence" <<'PY'
import sys
from pathlib import Path

terminal_dir = Path(sys.argv[1])
display_dir = Path(sys.argv[2])
terminal_tests = Path(sys.argv[3]).read_text()
display_tests = Path(sys.argv[4]).read_text()
tasks = Path(sys.argv[5]).read_text()
evidence = Path(sys.argv[6]).read_text()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def require_file(path: Path) -> None:
    require(path.exists(), f"Missing required fixture file: {path}")


def require_text(source: str, needle: str, label: str) -> None:
    require(needle in source, f"Missing {label}: {needle}")


required_terminal_fixtures = [
    "resume-filter-sort-pager-selected.json",
    "resume-scrolled-selected.json",
    "resume-unselected.json",
    "resume-ambiguous.json",
    "resume-low-confidence.json",
    "slash-suggestions.json",
    "slash-style-selected.json",
    "slash-ambiguous.json",
    "slash-stale-unselected.json",
    "slash-continuation.json",
    "model-picker.json",
    "model-cursor-fallback.json",
    "model-stale-unselected.json",
    "effort-picker.json",
    "effort-cursor-fallback.json",
    "effort-stale-unselected.json",
    "approval-prompt.json",
    "approval-cancel-selected.json",
    "approval-style-selected.json",
    "approval-ambiguous.json",
    "approval-reject-selected.json",
    "approval-missing-selection.json",
    "permission-prompt.json",
    "permission-cancel-selected.json",
    "permission-allow-this-selected.json",
    "permission-missing-selection.json",
    "negative-historical-transcript.txt",
]

for filename in required_terminal_fixtures:
    require_file(terminal_dir / filename)

terminal_readme = (terminal_dir / "README.md").read_text()
for phrase in [
    "Resume selected/filter/sort/pager",
    "Resume scrolled selected",
    "Resume unselected",
    "Resume ambiguous",
    "Resume low confidence",
    "Slash continuation",
    "Model cursor fallback",
    "Effort cursor fallback",
    "Approval prompt",
    "Permission prompt",
    "Historical transcript negative",
    "no remaining P0 fixture gap",
    "Ambiguous, stale, waiting-for-frame, or missing selection states must consume Enter",
    "Raw Terminal parity is represented by candidate `sourceLineIndex`, frame evidence, and selected-source evidence",
]:
    require_text(terminal_readme, phrase, "terminal fixture README coverage")

for function in [
    "terminalInteractionFixtureCatalogClassifiesSupportedSurfacesAndNegativeTranscript",
    "resumeFixtureCoversFilterSortPagerAndFooterEvidence",
    "resumeScrolledFixturePreservesPagerMetadataAndFooterZones",
    "slashModelAndEffortFixturesCoverMarkerStyleCursorAmbiguousAndStaleSelection",
    "terminalInteractionFixturesCoverScrolledAmbiguousLowConfidenceAndBlockedConfirmationStates",
    "modalChoiceFixturesPreserveTerminalEvidenceAndRawParity",
    "modalChoiceConfirmationGateBlocksUnsafeEnterAndRoutesCancelToPTY",
    "staleSelectedRowsAreNotConfirmableEvenWhenRowIDStillExists",
    "waitingForTerminalFrameBlocksEnterWhileKeepingRowsVisible",
    "freshnessGateWaitsForChangedTerminalContentBeforeAcceptingFreshSurface",
    "nonConfirmingNavigationStaysPTYRoutedAndDoesNotMutateSelectionPolicy",
    "lowConfidenceSurfaceKeepsRowsVisibleBlocksEnterAndExplainsRefresh",
    "unsafeEnterConsumesEventInsteadOfFallingThroughToComposerSubmission",
]:
    require_text(terminal_tests, f"func {function}", "terminal interaction regression test")

for fixture in [
    "resume-filter-sort-pager-selected",
    "resume-scrolled-selected",
    "resume-ambiguous",
    "resume-low-confidence",
    "slash-continuation",
    "model-cursor-fallback",
    "effort-cursor-fallback",
    "approval-ambiguous",
    "approval-missing-selection",
    "permission-missing-selection",
    "permission-allow-this-selected",
]:
    require_text(terminal_tests, fixture, "terminal interaction test fixture reference")

for invariant in [
    "PenggieTerminalInputPolicy.commandDecision(.enter",
    ".blocked",
    ".waitingForTerminalFrame",
    ".stale",
    "sourceLineIndex",
    "explicitSelectedCells",
    "screenModelMarker",
]:
    require_text(terminal_tests, invariant, "terminal interaction safety invariant")

required_display_fixture_dirs = [
    "approval-prompt",
    "cjk-table-code",
    "long-session-stable",
    "low-confidence-fallback",
    "markdown-prose",
    "slash-negative",
    "table-box-cjk",
    "theme-style",
    "tool-heavy-warning-hierarchy",
    "warning-status-tools",
]

for name in required_display_fixture_dirs:
    require_file(display_dir / name / "raw-text.txt")
    require_file(display_dir / name / "display-ast.json")

for function in [
    "historicalInlineAndIndentedSlashTextStayInTranscript",
    "warningStatusAndToolRowsDoNotHideAnswerText",
    "approvalPromptAndChoicesStayVisibleAsFallbackText",
    "longSessionFixtureKeepsCompletedAnswerAndClassifiesLaterStatusRows",
    "cjkTableCodeFixturePreservesTerminalSensitiveOutput",
    "toolHeavyWarningFixtureMaintainsFinalAnswerHierarchy",
    "lowConfidenceDisplayFixtureUsesFallbackWithoutInventingMarkdown",
    "lowConfidenceFallbackExposesTraceabilityAndPreservesTerminalEvidence",
]:
    require_text(display_tests, f"func {function}", "Display AST regression test")

display_readme = (display_dir / "README.md").read_text()
for phrase in [
    "CJK prose + table + code",
    "Warning/status/tool rows",
    "Tool-heavy hierarchy",
    "Long sessions",
    "Low-confidence fallback",
    "Approval prompt",
    "Markdown structure just to make Reading look cleaner",
]:
    require_text(display_readme, phrase, "Display fixture README coverage")

for phrase in [
    "Task 9.2",
    "Task 9.4",
    "terminal-owned selectedIndex/list state",
    "unsafe confirmability",
    "broken fallback",
    "lost Raw Terminal parity",
    "scripts/qa/check-fixture-regression-coverage.sh",
]:
    require_text(evidence, phrase, "fixture regression evidence")

require_text(tasks, "- [x] 9.2 Expand `Tests/PenggieCoreTests/Fixtures/terminal-interaction-surfaces/`", "9.2 completion")
require_text(tasks, "- [x] 9.4 Add or update unit tests", "9.4 completion")

print("Fixture regression coverage guard passed")
PY
