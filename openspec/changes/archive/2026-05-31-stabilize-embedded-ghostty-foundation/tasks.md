## 1. Evidence and Diagnostics

- [x] 1.1 Add or document a Raw Terminal environment probe for `TERM`, `COLORTERM`, `TERM_PROGRAM`, `NO_COLOR`, `CLICOLOR`, `CLICOLOR_FORCE`, and `FORCE_COLOR`.
- [x] 1.2 Add or document a Raw Terminal ANSI probe covering 16-color foregrounds, truecolor, faint, bold, and inverse rendering.
- [x] 1.3 Capture current Codex resume picker behavior and classify whether color loss occurs before SGR emission, inside Ghostty rendering, or inside Penggie projection.
- [x] 1.4 Record the probe findings in the change notes or design before making behavior changes.

## 2. Codex Launch Environment

- [x] 2.1 Replace color-related global process environment mutation with explicit per-surface environment overrides where Ghostty embedded config supports them.
- [x] 2.2 Preserve Ghostty-owned `TERM`, `COLORTERM`, and `TERM_PROGRAM` behavior while preventing inherited color-disabling variables from reaching Codex.
- [x] 2.3 Add regression coverage or debug diagnostics proving the Codex child environment matches the expected color-capable contract.

## 3. Ghostty Theme and Color Scheme

- [x] 3.1 Replace the hand-written embedded light palette config with theme-based Ghostty configuration.
- [x] 3.2 Remove or lower the high `minimum-contrast` setting so ANSI foreground, faint, bold, inverse, and selection styles remain distinguishable.
- [x] 3.3 Add macOS effective-appearance synchronization to embedded Ghostty app and active surfaces using the available color-scheme APIs.
- [x] 3.4 Verify whether Ghostty soft reload actions need host `action_cb` handling for live theme changes and implement the minimal required bridge if needed.
- [x] 3.5 Manually verify Raw Terminal light and dark mode rendering against Ghostty.app or equivalent Ghostty theme output.

## 4. Screen Model Style Export

- [x] 4.1 Update the embedded Ghostty screen model patch to generate viewport rows directly from terminal row iteration instead of relying only on dumped text splitting.
- [x] 4.2 Export structured style facts or compact style runs for foreground, background, bold, faint, inverse, and text/background cell coverage.
- [x] 4.3 Rename or separate terminal text selection data so it is not confused with Codex TUI current-row selection.
- [x] 4.4 Preserve background-only cell coverage for highlighted rows with styled empty space.
- [x] 4.5 Update Swift screen model decoding to consume the new style facts while keeping old fields only as compatibility fallback if needed.

## 5. Native Projection Foundation

- [x] 5.1 Refactor terminal-owned selected line or region inference into a shared primitive usable by resume picker and slash overlay.
- [x] 5.2 Keep resume picker row parsing separate from slash overlay row parsing.
- [x] 5.3 Change resume picker fallback order to prefer current visible marker, then screen model style/cursor facts, then backing text marker, then unselected rows.
- [x] 5.4 Ensure native resume picker never maintains a local session list or selected index.
- [x] 5.5 Ensure slash overlay behavior still routes navigation to Codex and derives selection from terminal-owned facts.

## 6. Verification

- [x] 6.1 Run `swift test --filter PenggieCodexScreenKindTests`.
- [x] 6.2 Run `swift test --filter PenggieNativeInteractionProjectionTests`.
- [x] 6.3 Run full `swift test`.
- [x] 6.4 Run `git diff --check`.
- [x] 6.5 Rebuild the Ghostty substrate if the embedded patch changes.
- [x] 6.6 Run `xcodebuild -project Penggie/Penggie.xcodeproj -scheme Penggie -configuration Debug -destination 'platform=macOS' -derivedDataPath .build/XcodeDerivedData build`.
- [x] 6.7 Manually verify Raw Terminal ANSI probe output in light and dark modes.
- [x] 6.8 Manually verify Codex resume picker highlights exactly one terminal-owned selected row when available and blocks Enter when selection is ambiguous.
- [x] 6.9 Manually verify slash overlay navigation and model/continuation menus do not regress.
- [x] 6.10 Manually verify Reading and Raw Terminal still share the same active Codex PTY.

## 7. Embedded Explicit RGB Normalization

- [x] 7.1 Record runtime evidence that the non-adaptive active input row is explicit RGB terminal cell background, not selection, palette, or inverse style.
- [x] 7.2 Add a Penggie-generated embedded Ghostty theme/config token for the active input normalization target.
- [x] 7.3 Add an embedded-only Ghostty renderer adapter rule that maps known TUI control explicit RGB backgrounds to the active input token without changing PTY state or arbitrary truecolor output.
- [x] 7.4 Add regression coverage for generated light/dark normalization config.
- [x] 7.5 Run Swift tests, theme guard, whitespace check, and macOS Debug build.
