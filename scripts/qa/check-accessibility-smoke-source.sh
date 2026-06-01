#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
root_view="$repo_root/Penggie/Sources/PenggieRootView.swift"
session_model="$repo_root/Penggie/Sources/PenggieSessionModel.swift"
announcement_source="$repo_root/Penggie/Sources/PenggieAccessibilityAnnouncement.swift"
manual_qa="$repo_root/openspec/changes/productize-ui-ux-contract/product-grade-ui-ux-manual-qa-script.md"
voiceover_checklist="$repo_root/openspec/changes/productize-ui-ux-contract/voiceover-manual-qa-checklist.md"
release_checklist="$repo_root/openspec/changes/productize-ui-ux-contract/release-readiness-checklist.md"
automation_plan="$repo_root/openspec/changes/productize-ui-ux-contract/accessibility-smoke-automation-plan.md"
dynamic_evidence="$repo_root/openspec/changes/productize-ui-ux-contract/dynamic-announcements-evidence.md"

python3 - "$root_view" "$session_model" "$announcement_source" "$manual_qa" "$voiceover_checklist" "$release_checklist" "$automation_plan" "$dynamic_evidence" <<'PY'
import re
import sys
from pathlib import Path

root_path = Path(sys.argv[1])
session_path = Path(sys.argv[2])
announcement_path = Path(sys.argv[3])
manual_path = Path(sys.argv[4])
voiceover_path = Path(sys.argv[5])
release_path = Path(sys.argv[6])
plan_path = Path(sys.argv[7])
dynamic_path = Path(sys.argv[8])

root = root_path.read_text()
session = session_path.read_text()
announcement = announcement_path.read_text()
manual = manual_path.read_text()
voiceover = voiceover_path.read_text()
release = release_path.read_text()
plan = plan_path.read_text()
dynamic = dynamic_path.read_text()


def require(source: str, needle: str, label: str) -> None:
    if needle not in source:
        raise AssertionError(f"Missing {label}: {needle}")


def require_regex(source: str, pattern: str, label: str) -> None:
    if not re.search(pattern, source, flags=re.S):
        raise AssertionError(f"Missing {label}: {pattern}")


# Setup/start accessibility must remain explicit and stateful.
for needle, label in [
    ('.accessibilityLabel("Codex selected as local agent CLI")', "provider label"),
    ('.accessibilityLabel("Choose Project Folder")', "folder label"),
    ('.accessibilityValue(session.sessionFolderDisplayPath)', "folder value"),
    ('.accessibilityHint(session.canStartCodex ?', "folder state hint"),
    ('.accessibilityElement(children: .combine)', "combined status elements"),
    ('.accessibilityLabel(folderStatusText)', "folder status label"),
    ('.accessibilityLabel("Create with Penggie")', "create label"),
    ('.accessibilityHint(createHelpText)', "create state hint"),
    ('.accessibilityLabel("Send")', "send label"),
]:
    require(root, needle, label)

# Dynamic state announcements must remain centralized and mapped from session
# state or terminal-surface facts, not from local view-owned selection state.
for needle, label in [
    ("enum PenggieAccessibilityAnnouncementEvent", "announcement event enum"),
    ("struct PenggieAccessibilityAnnouncement", "announcement descriptor"),
    ("PenggieAccessibilityAnnouncementPriority", "announcement priority"),
    ("case checkingCodex", "checking Codex announcement"),
    ("case launching", "launching announcement"),
    ("case ready", "ready announcement"),
    ("case working", "working announcement"),
    ("case toolRunning", "tool running announcement"),
    ("case approvalRequired", "approval announcement"),
    ("case permissionRequired", "permission announcement"),
    ("case projectionDegraded", "projection degraded announcement"),
    ("case selectionSyncing", "selection syncing announcement"),
    ("case processExited", "process exited announcement"),
    ("case missingCodex", "missing Codex announcement"),
    ("case launchFailed", "launch failed announcement"),
]:
    require(announcement, needle, label)

for needle, label in [
    ("var accessibilityAnnouncement: PenggieAccessibilityAnnouncement?", "session announcement surface"),
    ("private var accessibilityAnnouncementEvent", "session event mapping"),
    ("activeTerminalSurfaceAnnouncementEvent", "terminal surface announcement mapping"),
    ("surface.hasFreshConfirmableSelection", "fresh confirmable selection gate"),
    ("case .approvalPrompt", "approval prompt event source"),
    ("case .permissionPrompt", "permission prompt event source"),
    ("$0.confidence == .low && $0.isLiveProjection", "live projection degraded gate"),
]:
    require(session, needle, label)

for needle, label in [
    ("lastAccessibilityAnnouncementID", "duplicate announcement guard"),
    ("session.accessibilityAnnouncement", "root announcement observation"),
    ("NSAccessibility.post(", "AppKit announcement post"),
    (".announcementRequested", "announcement requested notification"),
    (".announcement: announcement.message", "announcement message payload"),
    (".priority: announcement.priority.appKitPriority", "announcement priority payload"),
]:
    require(root, needle, label)

# Reading/Raw Terminal switching should not expose both surfaces at once.
for needle, label in [
    ('.accessibilityHidden(session.state != .terminal)', "Raw Terminal inactive AX hide"),
    ('.accessibilityHidden(session.state == .terminal)', "Reading inactive AX hide"),
]:
    require(root, needle, label)

# Terminal-owned candidate rows must expose terminal-backed state without
# inventing local per-surface accessibility strings.
for needle, label in [
    ('.accessibilityElement(children: .ignore)', "candidate isolated AX element"),
    ('.accessibilityLabel(candidate.text)', "candidate row text label"),
    ('PenggieTerminalSurfaceCandidateAccessibility.value(', "shared candidate value"),
    ('PenggieTerminalSurfaceCandidateAccessibility.hint(', "shared candidate hint"),
    ('.accessibilityAddTraits(isSelected ? [.isSelected] : [])', "selected trait"),
]:
    require(root, needle, label)

require_regex(
    root,
    r'PenggieTerminalSurfaceCandidateAccessibility\.value\(\s*isSelected:\s*isSelected,\s*isConfirmable:\s*candidate\.isConfirmable,\s*surfaceIsSyncing:\s*surfaceIsSyncing',
    "candidate value arguments",
)
require_regex(
    root,
    r'PenggieTerminalSurfaceCandidateAccessibility\.hint\(\s*isSelected:\s*isSelected,\s*isConfirmable:\s*candidate\.isConfirmable,\s*surfaceIsSyncing:\s*surfaceIsSyncing',
    "candidate hint arguments",
)

# Disclosure state must be inspectable by accessibility clients.
for needle, label in [
    ('.accessibilityLabel(disclosure.summary)', "disclosure label"),
    ('.accessibilityValue(isExpanded ? "Expanded" : "Collapsed")', "disclosure state"),
]:
    require(root, needle, label)

# Destructive confirmations must expose the system confirmation labels and must
# not bypass the explicit cancel/confirm lifecycle boundary.
for needle, label in [
    ('.alert(item: $session.pendingConfirmation)', "session confirmation alert"),
    ('title: Text(confirmation.title)', "confirmation title"),
    ('message: Text(confirmation.message)', "confirmation message"),
    ('primaryButton: .destructive(Text(confirmation.confirmationButtonTitle))', "destructive confirmation label"),
    ('session.confirm(confirmation)', "destructive confirmation action"),
    ('secondaryButton: .cancel', "confirmation cancel button"),
    ('session.cancelConfirmation()', "confirmation cancel action"),
]:
    require(root, needle, label)

# Documentation gates must keep live accessibility evidence manual and explicit.
for needle, label in [
    ("QA-AX-001", "keyboard-only manual scenario"),
    ("QA-AX-002", "dynamic announcements manual scenario"),
    ("VoiceOver:", "VoiceOver field"),
    ("Expected result:", "expected result field"),
    ("Do not launch a second Codex CLI", "same-session QA non-goal"),
]:
    require(manual, needle, label)

for needle, label in [
    ("VoiceOver never implies SwiftUI owns terminal-owned selected state.", "terminal-truth VoiceOver rule"),
    ("VoiceOver never allows confirmation when terminal evidence is stale, ambiguous, or low confidence.", "unsafe confirmation VoiceOver rule"),
    ("Do not synthesize Codex-owned selection state for accessibility.", "no synthetic selection rule"),
]:
    require(voiceover, needle, label)

for needle, label in [
    ("VoiceOver result:", "release VoiceOver field"),
    ("Dynamic announcement result:", "release announcement field"),
    ("Unsafe confirmation gate evidence:", "release unsafe confirmation evidence"),
    ("accessibility activation can confirm a stale, ambiguous, missing, or non-confirmable terminal-owned selection", "release rejection gate"),
]:
    require(release, needle, label)

for needle, label in [
    ("Automate source-level accessibility guardrails only.", "automation scope decision"),
    ("Do not automate live VoiceOver navigation", "manual live AX decision"),
    ("Revisit Criteria", "promotion criteria"),
    ("scripts/qa/check-accessibility-smoke-source.sh", "self reference"),
]:
    require(plan, needle, label)

for needle, label in [
    ("Task: `7.3", "dynamic evidence task reference"),
    ("checkingCodex", "dynamic evidence checking event"),
    ("approvalRequired", "dynamic evidence approval event"),
    ("permissionRequired", "dynamic evidence permission event"),
    ("selectionSyncing", "dynamic evidence selection syncing event"),
    ("No local selectedIndex", "dynamic evidence terminal truth constraint"),
    ("Manual VoiceOver QA remains required", "dynamic evidence live QA caveat"),
]:
    require(dynamic, needle, label)

print("Accessibility source smoke guard passed")
PY
