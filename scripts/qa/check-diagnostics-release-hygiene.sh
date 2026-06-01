#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
session_model="$repo_root/Penggie/Sources/PenggieSessionModel.swift"
ghostty_session="$repo_root/Penggie/Sources/PenggieGhosttySession.swift"
diagnostics_audit="$repo_root/openspec/changes/productize-ui-ux-contract/diagnostics-audit.md"
release_hygiene="$repo_root/openspec/changes/productize-ui-ux-contract/diagnostics-release-hygiene.md"
tasks="$repo_root/openspec/changes/productize-ui-ux-contract/tasks.md"

python3 - "$session_model" "$ghostty_session" "$diagnostics_audit" "$release_hygiene" "$tasks" <<'PY'
import re
import sys
from pathlib import Path

session_model = Path(sys.argv[1]).read_text()
ghostty_session = Path(sys.argv[2]).read_text()
diagnostics_audit = Path(sys.argv[3]).read_text()
release_hygiene = Path(sys.argv[4]).read_text()
tasks = Path(sys.argv[5]).read_text()


def require(source: str, needle: str, label: str) -> None:
    if needle not in source:
        raise AssertionError(f"Missing {label}: {needle}")


def require_regex(source: str, pattern: str, label: str) -> None:
    if not re.search(pattern, source, flags=re.S):
        raise AssertionError(f"Missing {label}: {pattern}")


def extract_function(source: str, name: str) -> str:
    match = re.search(rf"(?:private\s+)?(?:static\s+)?func\s+{re.escape(name)}(?:<[^>]+>)?\s*\(", source)
    if not match:
        raise AssertionError(f"Missing function {name}")

    start = match.start()
    brace = source.find("{", match.end() - 1)
    depth = 0
    for index in range(brace, len(source)):
        char = source[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[start:index + 1]
    raise AssertionError(f"Could not parse function {name}")


for source, label in [
    (session_model, "PenggieSessionModel"),
    (ghostty_session, "PenggieGhosttySession"),
]:
    require(source, "PENGGIE_DEBUG_FILE_DIAGNOSTICS", f"{label} file diagnostic opt-in flag")
    require(source, "debugFileDiagnosticsEnabled", f"{label} file diagnostic gate")
    require(source, "debugBooleanEnvironmentFlag", f"{label} boolean environment parser")

append_debug = extract_function(session_model, "appendDebugDiagnostic")
require(append_debug, "guard debugFileDiagnosticsEnabled else { return }", "SessionModel temp diagnostic write guard")
require(append_debug, "NSTemporaryDirectory()", "SessionModel temp diagnostic path remains non-product and gated")

log_debug = extract_function(ghostty_session, "logDebugDiagnostic")
require(log_debug, "NSLog(\"%@\", message)", "Ghostty console DEBUG diagnostic remains available")
require(log_debug, "guard debugFileDiagnosticsEnabled else { return }", "Ghostty temp diagnostic write guard")
require(log_debug, "terminal-style-diagnostic.log", "Ghostty temp diagnostic file name remains auditable")

launch_env = extract_function(ghostty_session, "withCodexSurfaceEnvironmentOverrides")
require(ghostty_session, "PENGGIE_DEBUG_LAUNCH_ENV_DIAGNOSTIC", "launch environment diagnostic opt-in flag")
require(ghostty_session, "debugLaunchEnvironmentDiagnosticEnabled", "launch environment diagnostic gate")
require(launch_env, "if debugLaunchEnvironmentDiagnosticEnabled", "launch environment NSLog gate")
require(launch_env, "PenggieCodexLaunchEnvironment", "launch environment diagnostic remains opt-in")

# Runtime config/theme temp assets are not debug logs and must remain documented.
for needle, label in [
    ("ghostty-embedded.conf", "embedded Ghostty config file"),
    ("penggie-terminal-light.theme", "embedded light theme file"),
    ("penggie-terminal-dark.theme", "embedded dark theme file"),
]:
    require(ghostty_session, needle, label)
    require(diagnostics_audit, needle, f"audit documents {label}")
    require(release_hygiene, needle, f"release hygiene documents {label}")

for needle, label in [
    ("PENGGIE_DEBUG_FILE_DIAGNOSTICS", "file diagnostics opt-in docs"),
    ("PENGGIE_DEBUG_LAUNCH_ENV_DIAGNOSTIC", "launch environment opt-in docs"),
    ("Temp-file diagnostic logs are disabled by default", "default disabled statement"),
    ("Product runtime temp assets remain enabled", "runtime temp asset distinction"),
    ("scripts/qa/check-diagnostics-release-hygiene.sh", "source guard self reference"),
]:
    require(release_hygiene, needle, label)

for needle, label in [
    ("Temp-file log appenders under `NSTemporaryDirectory()/Penggie/*.log` are now gated", "audit final file log action"),
    ("`PenggieCodexLaunchEnvironment` is now gated", "audit final launch log action"),
    ("`PENGGIE_DEBUG_FILE_DIAGNOSTICS`", "audit file diagnostics flag"),
    ("`PENGGIE_DEBUG_LAUNCH_ENV_DIAGNOSTIC`", "audit launch diagnostics flag"),
]:
    require(diagnostics_audit, needle, label)

require(tasks, "- [x] 10.4 Remove or gate debug-only diagnostic logs", "10.4 task completion")

require_regex(
    session_model,
    r"debugBooleanEnvironmentFlag\([^)]*\).*?value == \"1\".*?value == \"true\".*?value == \"yes\"",
    "SessionModel accepted boolean opt-in values",
)
require_regex(
    ghostty_session,
    r"debugBooleanEnvironmentFlag\([^)]*\).*?value == \"1\".*?value == \"true\".*?value == \"yes\"",
    "GhosttySession accepted boolean opt-in values",
)

print("Diagnostics release hygiene guard passed")
PY
