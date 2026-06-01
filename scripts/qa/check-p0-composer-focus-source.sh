#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
composer_view="$repo_root/Penggie/Sources/PenggieComposerTextView.swift"
native_trigger="$repo_root/Penggie/Sources/PenggieComposerNativeTrigger.swift"
key_capture="$repo_root/Penggie/Sources/PenggieInteractionKeyCaptureView.swift"
root_view="$repo_root/Penggie/Sources/PenggieRootView.swift"
session_model="$repo_root/Penggie/Sources/PenggieSessionModel.swift"
trigger_tests="$repo_root/Tests/PenggieCoreTests/PenggieComposerNativeTriggerTests.swift"
audit_doc="$repo_root/openspec/changes/productize-ui-ux-contract/composer-focus-state-machine-audit.md"
evidence_doc="$repo_root/openspec/changes/productize-ui-ux-contract/composer-focus-source-evidence.md"

python3 - "$composer_view" "$native_trigger" "$key_capture" "$root_view" "$session_model" "$trigger_tests" "$audit_doc" "$evidence_doc" <<'PY'
import re
import sys
from pathlib import Path

composer = Path(sys.argv[1]).read_text()
trigger = Path(sys.argv[2]).read_text()
key_capture = Path(sys.argv[3]).read_text()
root = Path(sys.argv[4]).read_text()
session = Path(sys.argv[5]).read_text()
tests = Path(sys.argv[6]).read_text()
audit = Path(sys.argv[7]).read_text()
evidence = Path(sys.argv[8]).read_text()


def require(source: str, needle: str, label: str) -> None:
    if needle not in source:
        raise AssertionError(f"Missing {label}: {needle}")


def require_regex(source: str, pattern: str, label: str) -> None:
    if not re.search(pattern, source, flags=re.S):
        raise AssertionError(f"Missing {label}: {pattern}")


for needle, label in [
    ("!textView.hasMarkedText()", "SwiftUI text replacement skips marked text"),
    ("if textView.hasMarkedText() {\n                return false\n            }", "Enter falls through during marked text"),
    ("modifiers.contains(.shift)", "Shift-Enter is not submitted"),
    ("parent.onSubmit()", "unmarked Enter submits through callback"),
    ("override func setMarkedText", "marked text visibility hook"),
    ("override func unmarkText()", "unmark visibility hook"),
    ("onVisibleTextStateMayHaveChanged?()", "visible text state refresh"),
    ("handleFirstCharacterNativePrefix(event)", "first-character native prefix interception"),
]:
    require(composer, needle, label)

for needle, label in [
    ("guard existingText.isEmpty,", "native prefix requires empty composer"),
    ("!hasMarkedText,", "native prefix refuses marked text"),
    ("characters.count == 1", "native prefix requires single key"),
    ('case "/":', "slash prefix support"),
    ("canUseCodexDollarCommand ? \"$\" : nil", "dollar prefix remains capability gated"),
    ("!string.isEmpty || hasMarkedText", "marked text counts as visible composer text"),
]:
    require(trigger, needle, label)

for needle, label in [
    ("case .handled, .blocked:\n                return", "blocked terminal commands are consumed"),
    ("case .unhandled:\n                break", "unhandled commands can fall through"),
    ("onTextInput?(characters) == true", "text input routes to terminal handler"),
    ("performKeyEquivalent", "paste key equivalent bridge"),
    ("penggieIsPasteKeyEquivalent(event)", "Cmd-V detection"),
    ("NSPasteboard.general.string(forType: .string)", "pasteboard text source"),
]:
    require(key_capture, needle, label)

for needle, label in [
    ("session.nativeInteractionIsActive", "Reading composer switches to terminal-owned input shell"),
    ("PenggieInteractionKeyCaptureView(", "terminal-owned key capture view"),
    ("shouldFocus: session.state == .reading", "terminal-owned key capture focuses in Reading"),
    ("isEnabled: session.state == .reading && session.nativeInteractionPhase.acceptsInput", "native key capture enablement"),
    ("session.codexScreenKind.isTerminalOwnedInteraction", "composer disabled for terminal-owned full-page surfaces"),
    ("let started = session.beginNativeInteraction(prefix: prefix)", "first slash handoff enters session model"),
    ("composerText = \"\"", "local composer is cleared after native handoff"),
    ("PenggieTerminalInputPolicy.commandDecision(.enter, surface: surface)", "Enter gate checks terminal input policy"),
    ("case .blocked = decision", "blocked Enter path"),
    ("nativeInteractionFocusRequestID += 1", "key capture refocus after blocked/sent input"),
]:
    require(root, needle, label)

for needle, label in [
    ("guard isRunning,", "native interaction requires running session"),
    ("!nativeInteractionIsActive", "native interaction cannot nest"),
    ("PenggieComposerNativeTrigger.prefix(for: initialText) != nil", "native interaction requires approved prefix"),
    ("ghosttySession?.sendText(initialText)", "native prefix goes to PTY"),
    ("markActiveTerminalInteractionSurfaceWaitingForFrame()", "terminal-owned input waits for fresh frame"),
    ("ghosttySession?.sendText(text)", "terminal-owned text goes to PTY"),
    ("sendNativeKey(command)", "terminal-owned commands go to PTY"),
]:
    require(session, needle, label)

for needle, label in [
    ("firstKeyTriggerRequiresEmptyUnmarkedComposer", "empty unmarked native-prefix test"),
    ("markedTextCountsAsVisibleComposerText", "marked text visible-state test"),
    ("dollarRequiresCodexCapability", "dollar capability-gate test"),
]:
    require(tests, needle, label)

for needle, label in [
    ("Task 4.1 is complete as an audit.", "composer audit result"),
    ("Tasks 4.2 through 4.6 remain required", "manual QA boundary"),
    ("IME marked text", "IME QA scenario"),
    ("Slash handoff", "slash handoff QA scenario"),
    ("Raw Terminal switch", "Raw Terminal focus QA scenario"),
]:
    require(audit, needle, label)

for needle, label in [
    ("Task: `4.2` through `4.5`", "evidence task range"),
    ("Source-backed guard only", "source-only caveat"),
    ("Live composer, IME, slash handoff, and focus QA remain open", "live QA caveat"),
    ("No local selectedIndex", "terminal truth constraint"),
    ("No local command/model/resume/approval/permission list", "local list constraint"),
]:
    require(evidence, needle, label)

require_regex(
    root,
    r"if session\.nativeInteractionIsActive \{.*?PenggieInteractionKeyCaptureView\(.*?\} else \{.*?PenggieComposerTextView\(",
    "Reading composer and key capture remain mutually exclusive",
)

print("P0 composer/focus source guard passed")
PY
