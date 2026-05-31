#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
session_model="$repo_root/Penggie/Sources/PenggieSessionModel.swift"
session_policy="$repo_root/Penggie/Sources/PenggieSessionLifecyclePolicy.swift"
app_source="$repo_root/Penggie/Sources/PenggieApp.swift"
root_view="$repo_root/Penggie/Sources/PenggieRootView.swift"

python3 - "$session_model" "$session_policy" "$app_source" "$root_view" <<'PY'
import re
import sys
from pathlib import Path

session_model_path = Path(sys.argv[1])
session_policy_path = Path(sys.argv[2])
app_path = Path(sys.argv[3])
root_path = Path(sys.argv[4])
source = session_model_path.read_text()
policy_source = session_policy_path.read_text()
app_source = app_path.read_text()
root_source = root_path.read_text()

def extract_function(name: str) -> str:
    match = re.search(rf"func\s+{re.escape(name)}\s*\([^)]*\)(?:\s*->[^\{{]+)?\s*\{{", source)
    if not match:
        raise AssertionError(f"Missing function {name}")

    index = match.start()
    brace_index = source.find("{", match.end() - 1)
    depth = 0
    for cursor in range(brace_index, len(source)):
        char = source[cursor]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[index:cursor + 1]

    raise AssertionError(f"Could not parse function {name}")

def extract_var(name: str) -> str:
    match = re.search(rf"var\s+{re.escape(name)}\s*:[^\n]+\s*\{{", source)
    if not match:
        raise AssertionError(f"Missing var {name}")

    index = match.start()
    brace_index = source.find("{", match.end() - 1)
    depth = 0
    for cursor in range(brace_index, len(source)):
        char = source[cursor]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[index:cursor + 1]

    raise AssertionError(f"Could not parse var {name}")

def assert_not_contains(label: str, body: str, forbidden: list[str]) -> None:
    hits = [pattern for pattern in forbidden if re.search(pattern, body)]
    if hits:
        raise AssertionError(f"{label} contains forbidden lifecycle mutation patterns: {hits}")

start = extract_function("startWithCodex")
launch = extract_function("launchCodexSession")
for label, body in [("startWithCodex", start), ("launchCodexSession", launch)]:
    assert_not_contains(label, body, [r"\bcodex\s+resume\b", r"--last\b", r"\bresume\b"])

if "if case .exited = state" not in start or "closeCurrentSession()" not in start:
    raise AssertionError("startWithCodex must clean up an exited terminal surface before starting again")

if "self.ghosttySession === session" not in launch:
    raise AssertionError("launchCodexSession onExit callback must ignore stale closed/replaced Ghostty sessions")

if 'Button("Create with Penggie")' not in app_source:
    raise AssertionError("Missing app-level Create with Penggie command")

create_command = re.search(
    r'Button\("Create with Penggie"\)\s*\{\s*session\.startWithCodex\(\)\s*\}',
    app_source,
    re.MULTILINE,
)
if not create_command:
    raise AssertionError("App-level Create with Penggie command must call session.startWithCodex() directly")

if ".disabled(!session.canStartConfiguredCodex)" not in app_source:
    raise AssertionError("App-level Create with Penggie command must be disabled unless the session can start")

if ".disabled(!session.canStartNewChat)" not in app_source:
    raise AssertionError("New Chat command must be disabled until a session can start a new chat")

if ".disabled(!session.hasInspectableSession)" not in app_source:
    raise AssertionError("Close Session command must be disabled until an inspectable session exists")

for name in ["switchToReading", "switchToTerminal"]:
    body = extract_function(name)
    if "PenggieSessionLifecyclePolicy.displayTransition" not in body:
        raise AssertionError(f"{name} must use PenggieSessionLifecyclePolicy.displayTransition")
    assert_not_contains(
        name,
        body,
        [
            r"ghosttySession",
            r"PenggieGhosttySession",
            r"closeCurrentSession",
            r"startWithCodex",
            r"latestTerminalFrame",
            r"activeTerminalInteractionSurface",
            r"readingBlocks",
            r"transcriptText",
        ],
    )

has_inspectable = extract_var("hasInspectableSession")
if "PenggieSessionLifecyclePolicy.hasInspectableSession" not in has_inspectable:
    raise AssertionError("hasInspectableSession must delegate to PenggieSessionLifecyclePolicy")

can_submit_prompt = re.search(
    r"static\s+func\s+canSubmitPrompt\s*\([^)]*\)\s*->\s*Bool\s*\{(?P<body>.*?)\n\s*\}",
    policy_source,
    re.S,
)
if not can_submit_prompt:
    raise AssertionError("Missing PenggieSessionLifecyclePolicy.canSubmitPrompt")

if "hasInspectableSession(in: phase)" not in can_submit_prompt.group("body"):
    raise AssertionError("canSubmitPrompt must require an inspectable session before allowing prompt submission")

choose_working_directory = extract_function("chooseWorkingDirectory")
if "guard canStartCodex else" not in choose_working_directory:
    raise AssertionError("chooseWorkingDirectory must block folder changes outside startable lifecycle states")

for name in ["inspectExitedTerminal", "returnToExitedRecovery"]:
    _ = extract_function(name)

has_exited_terminal_surface = extract_var("hasExitedTerminalSurface")
if "state == .exited" not in has_exited_terminal_surface or "ghosttySession != nil" not in has_exited_terminal_surface:
    raise AssertionError("hasExitedTerminalSurface must require both exited state and a retained terminal surface")

request_new_chat = extract_function("requestNewChat")
if "guard hasInspectableSession else { return }" not in request_new_chat:
    raise AssertionError("requestNewChat must block before an inspectable session exists")
for forbidden in ["closeCurrentSession()", "startWithCodex()", "state = .closed"]:
    if forbidden in request_new_chat:
        raise AssertionError("requestNewChat must only request confirmation and must not discard the session")

request_close_session = extract_function("requestCloseSession")
if "guard hasInspectableSession else { return }" not in request_close_session:
    raise AssertionError("requestCloseSession must block before an inspectable session exists")
for forbidden in ["closeCurrentSession()", "startWithCodex()", "state = .closed"]:
    if forbidden in request_close_session:
        raise AssertionError("requestCloseSession must only request confirmation and must not discard the session")

confirm = extract_function("confirm")
if confirm.count("closeCurrentSession()") < 2:
    raise AssertionError("confirm must be the only lifecycle path that closes New Chat and Close Session")
if "pendingConfirmation = nil" not in confirm:
    raise AssertionError("confirm must clear pending confirmation before performing destructive lifecycle actions")

cancel_confirmation = extract_function("cancelConfirmation")
if "pendingConfirmation = nil" not in cancel_confirmation:
    raise AssertionError("cancelConfirmation must clear pending confirmation")
for forbidden in ["closeCurrentSession()", "startWithCodex()", "state = .closed"]:
    if forbidden in cancel_confirmation:
        raise AssertionError("cancelConfirmation must preserve the current session and only dismiss confirmation")

if ".disabled(!session.canStartCodex)" not in root_source:
    raise AssertionError("Start view folder picker must be disabled while Codex is checking, launching, or running")

if ".disabled(!session.canStartConfiguredCodex)" not in root_source:
    raise AssertionError("Start view Create with Penggie button must be disabled while Codex is checking or launching")

if "if session.isHoldingInitialSurface" not in root_source:
    raise AssertionError("Root view must hold the setup/start surface until the initial terminal surface is inspectable")

if "PenggieSessionView()" not in root_source:
    raise AssertionError("Root view must keep the active session view as the only Reading/Raw Terminal container")

for required in [
    "Start a new chat?",
    "This ends the current session and starts a fresh Codex session in this window.",
    "Start New Chat",
    "End this Codex session?",
    "This ends the current Codex session and returns to the Penggie start screen.",
    "End Session",
]:
    if required not in source:
        raise AssertionError(f"Confirmation copy must remain specific and destructive: missing {required}")

for required in [
    ".alert(item: $session.pendingConfirmation)",
    "primaryButton: .destructive",
    "secondaryButton: .cancel",
    "session.confirm(confirmation)",
    "session.cancelConfirmation()",
]:
    if required not in root_source:
        raise AssertionError(f"Root confirmation alert must trap confirmation through system modal buttons: missing {required}")

if root_source.count("Choose Folder") < 2:
    raise AssertionError("Missing Codex and launch failure recovery must expose a Choose Folder action")

for required in [
    "session.hasExitedTerminalSurface",
    "session.isInspectingExitedTerminal",
    "PenggieExitedTerminalInspectionView()",
    "Inspect Raw Terminal",
    "Show Recovery",
]:
    if required not in root_source:
        raise AssertionError(f"Exited recovery must include terminal-surface-aware Raw Terminal inspection: missing {required}")

print("P0 session lifecycle source guard passed")
PY
