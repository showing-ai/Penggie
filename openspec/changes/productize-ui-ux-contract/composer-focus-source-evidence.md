# Composer And Focus Source Evidence

Task: `4.2` through `4.5` source guard support.

## Scope

Source-backed guard only. This records source-level invariants that support IME, ordinary composer, native slash handoff, and focus ownership. It does not claim a live composer/focus QA pass.

## Covered Source Behavior

- SwiftUI does not overwrite `NSTextView` content while IME marked text exists.
- Enter is not consumed for prompt submit while marked text exists.
- Shift-Enter is not consumed by the submit path.
- Marked text counts as visible composer text, keeping placeholder state honest.
- First-character native prefix handoff only happens for an empty, unmarked composer.
- Native prefix handoff sends the prefix to the Codex PTY and clears local composer text.
- Terminal-owned key capture consumes blocked commands and routes navigation/text/paste back to the PTY path.
- Reading composer and terminal-owned key capture remain mutually exclusive in the composer shell.
- Terminal-owned input marks the active surface as waiting for a fresh terminal frame after routed input.

## Terminal Truth Constraints

- No local selectedIndex is introduced.
- No local command/model/resume/approval/permission list is introduced.
- Composer source state does not become the source of truth for terminal-owned choices.
- Raw Terminal remains the audit/control surface for live focus and terminal input behavior.

## Acceptance Boundary

Live composer, IME, slash handoff, and focus QA remain open. Tasks 4.2, 4.3, 4.4, and 4.5 must not be marked complete until a running Penggie app is validated for the relevant IME, paste, focus, terminal-owned handoff, Raw Terminal, confirmation, and recovery scenarios.

## Verification

Run:

```bash
scripts/qa/check-p0-composer-focus-source.sh
swift test --filter PenggieComposerNativeTriggerTests
openspec validate productize-ui-ux-contract --strict
openspec validate --all --strict
git diff --check
xcodebuild -project Penggie/Penggie.xcodeproj -scheme Penggie -configuration Debug -destination 'platform=macOS' build
```

## Non-Goals

- Do not mark live IME or focus tasks complete from source evidence.
- Do not use composer text state as selected-row evidence.
- Do not locally move terminal-owned selection on arrow keys.
- Do not split Raw Terminal and Reading into separate Codex/Ghostty sessions.
