#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
session_model="$repo_root/Penggie/Sources/PenggieSessionModel.swift"

python3 - "$session_model" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
source = path.read_text()

def extract_function(name: str) -> str:
    match = re.search(rf"func\s+{re.escape(name)}\s*\([^)]*\)\s*\{{", source)
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

print("P0 session lifecycle source guard passed")
PY
