#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

root = Path(".")
composer = (root / "Penggie/Sources/PenggieComposerTextView.swift").read_text()
trigger = (root / "Penggie/Sources/PenggieComposerNativeTrigger.swift").read_text()
key_capture = (root / "Penggie/Sources/PenggieInteractionKeyCaptureView.swift").read_text()
root_view = (root / "Penggie/Sources/PenggieRootView.swift").read_text()
session_model = (root / "Penggie/Sources/PenggieSessionModel.swift").read_text()
tests = (root / "Tests/PenggieCoreTests/PenggieComposerNativeTriggerTests.swift").read_text()
manual_qa = (root / "openspec/changes/productize-ui-ux-contract/product-grade-ui-ux-manual-qa-script.md").read_text()
audit = (root / "openspec/changes/productize-ui-ux-contract/composer-focus-state-machine-audit.md").read_text()
evidence = (root / "openspec/changes/productize-ui-ux-contract/composer-ime-focus-readiness.md").read_text()
tasks = (root / "openspec/changes/productize-ui-ux-contract/tasks.md").read_text()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def contains(haystack: str, needle: str, message: str) -> None:
    require(needle in haystack, message)


for source_phrase in [
    "if textView.string != text,",
    "!textView.hasMarkedText()",
    "if textView.hasMarkedText()",
    "return false",
    "modifiers.contains(.shift)",
    "parent.onSubmit()",
    "textView.isRichText = false",
    "textView.importsGraphics = false",
    "textView.allowsUndo = true",
    "scrollView.hasVerticalScroller = usedHeight > parent.maxHeight + 1",
    "PenggieComposerNativeTrigger.hasVisibleComposerText",
    "override func setMarkedText",
    "override func unmarkText",
    "handleFirstCharacterNativePrefix",
    "onFirstCharacterNativePrefix?(prefix) == true",
]:
    contains(composer, source_phrase, f"Missing composer IME/input source protection: {source_phrase}")

for source_phrase in [
    "existingText.isEmpty",
    "!hasMarkedText",
    "characters.count == 1",
    "case \"/\"",
    "canUseCodexDollarCommand ? \"$\" : nil",
    "!string.isEmpty || hasMarkedText",
]:
    contains(trigger, source_phrase, f"Missing native trigger invariant: {source_phrase}")

for source_phrase in [
    "override var acceptsFirstResponder",
    "func requestFocus()",
    "focusAfterLayout(delay: 0)",
    "focusAfterLayout(delay: 0.03)",
    "focusAfterLayout(delay: 0.12)",
    "override func keyDown(with event: NSEvent)",
    "PenggieTerminalInputDecision",
    "case .handled, .blocked:",
    "override func performKeyEquivalent",
    "penggieIsPasteKeyEquivalent",
    "NSPasteboard.general.string(forType: .string)",
    "onTextInput?(pasted) == true",
]:
    contains(key_capture, source_phrase, f"Missing terminal-owned key capture invariant: {source_phrase}")

for source_phrase in [
    "isEnabled: session.state == .reading &&",
    "!session.codexScreenKind.isTerminalOwnedInteraction",
    "shouldFocus: session.state == .reading &&",
    "session.beginNativeInteraction(prefix: prefix)",
    "composerText = \"\"",
    "nativeInteractionFocusRequestID += 1",
    "session.nativeInteractionIsActive",
    "PenggieInteractionKeyCaptureView",
    "handleNativeInteractionCommand",
    "handleNativeInteractionText",
    "PenggieTerminalInputPolicy.commandDecision",
    "case .blocked = decision",
    "session.sendTerminalSurfaceCommand(command)",
    "session.sendTerminalSurfaceText(text)",
]:
    contains(root_view, source_phrase, f"Missing Reading composer/focus gate: {source_phrase}")

for source_phrase in [
    "var canSubmitPrompt",
    "func sendPrompt(_ prompt: String) -> Bool",
    "canSubmitPrompt else { return false }",
    "func beginNativeInteraction(initialText: String) -> Bool",
    "!nativeInteractionIsActive",
    "PenggieComposerNativeTrigger.prefix(for: initialText) != nil",
    "ghosttySession?.sendText(initialText)",
    "nativeInteractionPhase = .editing",
    "nativeInteractionDisplayText = initialText",
    "func sendTerminalSurfaceCommand(_ command: PenggieInteractionCommand) -> Bool",
    "func sendTerminalSurfaceText(_ text: String) -> Bool",
    "markActiveTerminalInteractionSurfaceWaitingForFrame()",
]:
    contains(session_model, source_phrase, f"Missing session composer/focus source path: {source_phrase}")

for test_name in [
    "slashStartsNativeInteraction",
    "dollarRequiresCodexCapability",
    "firstKeyTriggerRequiresEmptyUnmarkedComposer",
    "markedTextCountsAsVisibleComposerText",
]:
    contains(tests, f"func {test_name}", f"Missing composer native trigger regression test: {test_name}")

for qa_id in [
    "### QA-COMP-001: IME marked text",
    "### QA-COMP-002: Ordinary composer behavior",
    "### QA-COMP-003: Slash handoff focus",
]:
    contains(manual_qa, qa_id, f"Missing manual QA scenario: {qa_id}")

for phrase in [
    "use Chinese or Japanese IME marked text, commit text, then Enter",
    "placeholder hides during marked text",
    "Enter does not submit while text is marked",
    "Enter submit, Shift-Enter newline, paste, large paste",
    "draft restore after mode switch",
    "bounded height and internal scroll work",
    "type slash, arrows, Esc, then resume ordinary typing",
    "first slash is sent to Codex",
    "local composer does not own selection",
]:
    contains(manual_qa, phrase, f"Missing composer manual QA expectation: {phrase}")

contains(manual_qa, "dismissal restores the", "Missing composer manual QA focus restoration expectation.")
contains(manual_qa, "correct focus owner", "Missing composer manual QA focus owner expectation.")

for phrase in [
    "Task 4.1 is complete as an audit",
    "Tasks 4.2 through 4.6 remain required",
    "IME marked text is not overwritten",
    "Enter does not submit while marked text exists",
    "First-character slash handoff is guarded",
    "Terminal-owned overlay key capture routes navigation",
    "Unsafe Enter for terminal-owned surfaces is consumed",
    "Reading and Raw Terminal continue to share one `PenggieGhosttySession`",
]:
    contains(audit, phrase, f"Missing composer audit boundary: {phrase}")

for task in [
    "- [ ] 4.2 Validate IME marked text behavior",
    "- [ ] 4.3 Validate ordinary composer behavior",
    "- [ ] 4.4 Validate native slash handoff",
    "- [ ] 4.5 Validate focus transitions",
]:
    contains(tasks, task, f"Task must remain open until live manual QA is performed: {task}")

for phrase in [
    "does not claim live IME QA pass",
    "Tasks `4.2` through `4.5` remain open",
    "No local command, model, resume, approval, permission, or selected-index state",
    "No second Codex process",
    "No SwiftUI overlay may own terminal-owned selection or confirmation state",
]:
    contains(evidence, phrase, f"Missing evidence boundary: {phrase}")

contains(evidence, "P0 composer IME/focus", "Missing evidence verification summary.")
contains(evidence, "readiness guard passed", "Missing evidence verification pass text.")

print("P0 composer IME/focus readiness guard passed")
PY
