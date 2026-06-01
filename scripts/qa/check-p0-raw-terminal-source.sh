#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

root = Path(".")
session = (root / "Penggie/Sources/PenggieSessionModel.swift").read_text()
root_view = (root / "Penggie/Sources/PenggieRootView.swift").read_text()
ghostty = (root / "Penggie/Sources/PenggieGhosttySession.swift").read_text()
manual_qa = (root / "openspec/changes/productize-ui-ux-contract/product-grade-ui-ux-manual-qa-script.md").read_text()
evidence = (root / "openspec/changes/productize-ui-ux-contract/raw-terminal-source-evidence.md").read_text()

def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)

def contains(haystack: str, needle: str, message: str) -> None:
    require(needle in haystack, message)

contains(session, "@Published private(set) var ghosttySession: PenggieGhosttySession?", "Session model must own one published Ghostty session.")
contains(session, "self.ghosttySession = session", "Launch path must install the created Ghostty session as the authoritative session.")
contains(session, "self.ghosttySession === session", "Exit callback must guard against stale Ghostty session callbacks.")
contains(session, "func switchToReading()", "Session model must expose Reading display transition.")
contains(session, "func switchToTerminal()", "Session model must expose Raw Terminal display transition.")
contains(session, ") == .setDisplayMode(.reading) else { return }", "Reading transition must be lifecycle-gated.")
contains(session, ") == .setDisplayMode(.terminal) else { return }", "Raw Terminal transition must be lifecycle-gated.")
contains(session, "ghosttySession?.close()", "Close path must close the single Ghostty session.")
contains(session, "ghosttySession = nil", "Close path must clear the single Ghostty session.")
contains(session, "guard hasExitedTerminalSurface else { return }", "Exited Raw Terminal inspection must require a retained surface.")

contains(root_view, "PenggieRawTerminalPlaceholder(isActive: session.state == .terminal)", "Session view must mount Raw Terminal from session state.")
contains(root_view, "PenggieReadingChatView()", "Session view must mount Reading in the same container.")
contains(root_view, ".opacity(session.state == .terminal ? 1 : 0)", "Raw Terminal should be hidden by opacity, not recreated by mode switching.")
contains(root_view, ".allowsHitTesting(session.state == .terminal)", "Raw Terminal hit testing must only be active in terminal mode.")
contains(root_view, ".accessibilityHidden(session.state != .terminal)", "Inactive Raw Terminal must be hidden from accessibility traversal.")
contains(root_view, ".opacity(session.state == .terminal ? 0 : 1)", "Reading should be hidden by opacity in terminal mode.")
contains(root_view, ".allowsHitTesting(session.state != .terminal)", "Reading hit testing must be disabled in terminal mode.")
contains(root_view, ".accessibilityHidden(session.state == .terminal)", "Inactive Reading must be hidden from accessibility traversal.")
contains(root_view, "if let ghosttySession = session.ghosttySession", "Raw Terminal placeholder must use the session-owned Ghostty session.")
contains(root_view, "PenggieGhosttyTerminalView(session: ghosttySession, isActive: isActive)", "Raw Terminal representable must receive the existing Ghostty session.")
contains(root_view, "PenggieExitedTerminalInspectionView", "Exited terminal inspection view must exist for retained surface audit.")
contains(root_view, "session.inspectExitedTerminal", "Recovery copy must route retained terminal inspection through the session model.")

contains(ghostty, "let terminalView: PenggieGhosttyHostView", "Ghostty session must own the host terminal view.")
contains(ghostty, "self.terminalView = PenggieGhosttyHostView()", "Ghostty session must create the host terminal view once.")
contains(ghostty, "terminalView.session = self", "Host terminal view must route events to its owning Ghostty session.")
contains(ghostty, "func makeNSView(context: Context) -> PenggieGhosttyHostView", "Raw Terminal representable must bridge to AppKit.")
contains(ghostty, "return session.terminalView", "Raw Terminal representable must return the existing terminal view, not create a second view.")
contains(ghostty, "nsView.isInteractive = isActive", "Raw Terminal representable must toggle interactivity from display mode.")
contains(ghostty, "nsView.window?.makeFirstResponder(nsView)", "Raw Terminal must claim keyboard focus when active.")
contains(ghostty, "guard isInteractive else", "Ghostty host must guard input when inactive.")
contains(ghostty, "override func keyDown(with event: NSEvent)", "Ghostty host must receive keyboard events directly.")
contains(ghostty, "session?.sendKeyEvent(event)", "Ghostty host must route key events to Ghostty.")
contains(ghostty, "@IBAction func copy", "Ghostty host must expose copy action.")
contains(ghostty, "performGhosttyBindingAction(\"copy_to_clipboard\")", "Copy should prefer Ghostty binding action.")
contains(ghostty, "copySelectionToPasteboard()", "Copy must fall back to explicit selection-to-pasteboard.")
contains(ghostty, "@IBAction func paste", "Ghostty host must expose paste action.")
contains(ghostty, "performGhosttyBindingAction(\"paste_from_clipboard\")", "Paste should route through Ghostty.")
contains(ghostty, "override func mouseDragged(with event: NSEvent)", "Ghostty host must forward mouse drag.")
contains(ghostty, "sendMouseButton(", "Ghostty host must forward mouse button state.")
contains(ghostty, "sendMousePosition(point, in: bounds.size", "Ghostty host must forward mouse position.")
contains(ghostty, "override func scrollWheel(with event: NSEvent)", "Ghostty host must forward scroll wheel.")

contains(manual_qa, "### QA-RAW-001: Reading to Raw Terminal round trip", "Manual QA must include Reading/Raw round trip.")
contains(manual_qa, "### QA-RAW-002: Raw Terminal control and clipboard", "Manual QA must include Raw Terminal control and clipboard.")
contains(manual_qa, "same Codex process, cwd, Ghostty session", "Manual QA must verify same-session Raw Terminal parity.")
contains(manual_qa, "select text, copy, inspect pasteboard result", "Manual QA must verify terminal text selection/copy.")

contains(evidence, "does not claim live Raw Terminal QA pass", "Evidence must not overclaim live Raw Terminal validation.")
contains(evidence, "Tasks `6.2` through `6.6` remain open", "Evidence must keep live Raw Terminal tasks open.")
contains(evidence, "No second Codex process", "Evidence must preserve single-session non-goal.")
contains(evidence, "No SwiftUI overlay may fake terminal text selection", "Evidence must reject fake terminal selection overlays.")
contains(evidence, "Raw Terminal source guard passed", "Evidence must list the source guard verification.")

print("P0 Raw Terminal source guard passed")
PY
