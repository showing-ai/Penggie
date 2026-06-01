# Reduced Motion Source Evidence

Task: `7.5 Validate reduced motion behavior for disclosure, surface switching, focus affordances, and overlay transitions.`

## Scope

Source-backed evidence only. This records that identifiable Penggie-owned SwiftUI motion now honors macOS Reduce Motion. It does not claim a live reduced-motion QA pass.

## Covered Source Behavior

- Chrome icon button press scaling is disabled when `accessibilityReduceMotion` is enabled.
- Chrome icon button press, hover, and focus animations are disabled when `accessibilityReduceMotion` is enabled.
- Reading disclosure expansion toggles without `withAnimation` when `accessibilityReduceMotion` is enabled.
- Terminal-owned candidate list scrolling remains non-animated through an explicit `Transaction` with `animation = nil`.

## Terminal Truth Constraints

- No local selectedIndex is introduced.
- No local command, model, resume, approval, or permission list is introduced.
- Terminal-owned overlay state remains PTY-routed and terminal-frame-backed.
- Raw Terminal remains the audit/control surface for live terminal behavior.

## Acceptance Boundary

Live reduced motion QA remains open. Task 7.5 must not be marked complete until a running Penggie app is validated with Reduce Motion enabled for disclosure, surface switching, focus affordances, and overlay transitions.

## Verification

Run:

```bash
scripts/qa/check-accessibility-smoke-source.sh
openspec validate productize-ui-ux-contract --strict
openspec validate --all --strict
git diff --check
xcodebuild -project Penggie/Penggie.xcodeproj -scheme Penggie -configuration Debug -destination 'platform=macOS' build
```

## Non-Goals

- Do not use animation state as evidence of terminal-owned selection.
- Do not animate or locally smooth selected-row updates ahead of terminal evidence.
- Do not mark live VoiceOver, Dynamic Type, or reduced motion QA complete from this source evidence.
