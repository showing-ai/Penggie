#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

root = Path(".")
fixtures = root / "Tests/PenggieCoreTests/Fixtures/terminal-interaction-surfaces"
fixture_readme = (fixtures / "README.md").read_text()
surface_tests = (root / "Tests/PenggieCoreTests/PenggieTerminalInteractionSurfaceTests.swift").read_text()
codex_screen_kind = (root / "Penggie/Sources/PenggieCodexScreenKind.swift").read_text()
session_model = (root / "Penggie/Sources/PenggieSessionModel.swift").read_text()
root_view = (root / "Penggie/Sources/PenggieRootView.swift").read_text()
manual_qa = (root / "openspec/changes/productize-ui-ux-contract/product-grade-ui-ux-manual-qa-script.md").read_text()
evidence = (root / "openspec/changes/productize-ui-ux-contract/terminal-owned-live-qa-readiness.md").read_text()
tasks = (root / "openspec/changes/productize-ui-ux-contract/tasks.md").read_text()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def contains(haystack: str, needle: str, message: str) -> None:
    require(needle in haystack, message)


def require_file(name: str) -> None:
    path = fixtures / name
    require(path.exists(), f"Missing required terminal-owned fixture: {path}")


required_fixtures = [
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
]

for fixture in required_fixtures:
    require_file(fixture)

for phrase in [
    "Surface kind: resume, slash suggestions, slash continuation, model, effort, approval, permission",
    "Selection confidence: reliable, stale, ambiguous, low confidence, or none.",
    "Confirmability: whether Enter, click, or accessibility activation may route confirmation to the PTY.",
    "Resume selected/filter/sort/pager",
    "Resume scrolled selected",
    "Slash continuation",
    "Model cursor fallback",
    "Effort cursor fallback",
    "Approval prompt",
    "Permission prompt",
    "Ambiguous, stale, waiting-for-frame, or missing selection states must consume Enter",
    "Raw Terminal parity is represented by candidate `sourceLineIndex`, frame evidence, and selected-source evidence",
]:
    contains(fixture_readme, phrase, f"Missing fixture README coverage: {phrase}")

for test_name in [
    "resumePickerSurfaceCarriesFrameIdentityCandidatesAndSelection",
    "approvalPromptSurfaceIsModalChoiceAndUsesTerminalMarker",
    "permissionPromptSurfaceIsModalChoiceAndUsesTerminalMarker",
    "modelPickerSurfaceParsesNumberedCandidates",
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
    "lowConfidenceSurfaceKeepsRowsVisibleBlocksEnterAndExplainsRefresh",
    "unsafeEnterConsumesEventInsteadOfFallingThroughToComposerSubmission",
]:
    contains(surface_tests, f"func {test_name}", f"Missing terminal-owned regression test: {test_name}")

for invariant in [
    "PenggieTerminalBehaviorZoner.classify(frame:",
    "PenggieTerminalInputPolicy.commandDecision(.enter",
    ".waitingForTerminalFrame",
    ".blocked",
    "approval-missing-selection",
    "permission-missing-selection",
    "approval-ambiguous",
    "permission-allow-this-selected",
    "sourceLineIndex",
    "screenModelMarker",
    "explicitSelectedCells",
]:
    contains(surface_tests, invariant, f"Missing terminal-owned safety invariant: {invariant}")

for source_phrase in [
    "containsTerminalOwnedSurfaceCue",
    "\"allow once\"",
    "\"deny\"",
    "\"approve command\"",
    "\"approve one retry\"",
    "\"choose what model\"",
    "\"reasoning effort\"",
    "nativeInteractionIsActive",
]:
    contains(codex_screen_kind, source_phrase, f"Missing screen model read policy cue: {source_phrase}")

for source_phrase in [
    "@Published private(set) var activeTerminalInteractionSurface",
    "activeTerminalInteractionSurface = activeTerminalInteractionSurface",
    ".withFreshness(.waitingForTerminalFrame)",
    "sendTerminalSurfaceCommand",
    "sendTerminalSurfaceText",
    "PenggieTerminalBehaviorZoner.classify",
    "PenggieTerminalSurfaceFreshnessGate.resolve",
]:
    contains(session_model, source_phrase, f"Missing session model terminal-owned source path: {source_phrase}")

for source_phrase in [
    "case .resumePicker, .approvalPrompt, .permissionPrompt, .modalChoice",
    "case .approvalPrompt, .permissionPrompt, .modalChoice",
    "PenggieTerminalInputPolicy.commandDecision(.enter",
    "surface.hasFreshConfirmableSelection",
    "PenggieTerminalSurfaceStatusCopy.syncingSelection",
    "nativeInteractionFocusRequestID",
]:
    contains(root_view, source_phrase, f"Missing Reading terminal-owned UI gate: {source_phrase}")

for qa_id in [
    "### QA-OVERLAY-001: Slash suggestions",
    "### QA-OVERLAY-002: Model and effort picker",
    "### QA-OVERLAY-003: Resume picker scroll, filter, sort, and page boundary",
    "### QA-OVERLAY-004: Approval and permission modal choices",
]:
    contains(manual_qa, qa_id, f"Missing manual QA scenario: {qa_id}")

for phrase in [
    "Down, Up, Enter, Esc, Backspace, and typed filtering",
    "arrows, Tab when available, Enter, Esc",
    "arrows past the visible bounds, Tab to filter/sort, type filter",
    "arrows, Enter, Esc/cancel",
    "Raw Terminal matches the same selected row",
    "confirm follows the same fresh exactly-one confirmable gate as Enter",
]:
    contains(manual_qa, phrase, f"Missing manual QA expectation: {phrase}")

contains(manual_qa, "Raw Terminal shows the same", "Missing manual QA Raw Terminal state parity expectation.")
contains(manual_qa, "terminal-owned state", "Missing manual QA terminal-owned state parity expectation.")

contains(tasks, "- [ ] 3.10 Run manual QA", "Task 3.10 must remain open until live manual QA is performed.")

for phrase in [
    "does not claim live overlay QA pass",
    "Task `3.10` remains open",
    "No local command, model, resume, approval, permission, or selected-index state",
    "No second Codex process",
    "No SwiftUI overlay may fake terminal-owned selected state",
]:
    contains(evidence, phrase, f"Missing evidence boundary: {phrase}")

contains(evidence, "P0 terminal-owned", "Missing evidence verification summary.")
contains(evidence, "live QA readiness guard passed", "Missing evidence verification pass text.")

print("P0 terminal-owned live QA readiness guard passed")
PY
