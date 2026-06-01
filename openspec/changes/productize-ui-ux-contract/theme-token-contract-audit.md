# Theme Token Contract Audit

Task: 8.1

## Scope

This audit reviews the current theme implementation against the product-grade token contract:

- primitive tokens
- semantic tokens
- scene tokens
- component tokens
- terminal renderer palette
- theme controller and runtime application

This is a read-only productization audit. It does not change visual values or application code.

## Files Reviewed

- `Penggie/Sources/PenggieTheme.swift`
- `Penggie/Sources/PenggieThemeController.swift`
- `Penggie/Sources/PenggieRootView.swift`
- `Penggie/Sources/PenggieGhosttySession.swift`
- `openspec/changes/productize-ui-ux-contract/design.md`
- `openspec/changes/productize-ui-ux-contract/specs/raw-terminal-fallback/spec.md`
- `openspec/changes/productize-ui-ux-contract/specs/reading-chat-ui/spec.md`
- `openspec/changes/productize-ui-ux-contract/specs/penggie-app-shell/spec.md`

## Current Architecture

`PenggieTheme` is now structured as the intended layered model:

- `PenggiePrimitivePalette`
- `PenggieSemanticTheme`
- `PenggieSceneTheme`
- `PenggieComponentTheme`

The main scene split is explicit:

- `PenggieReadingSceneTheme`
- `TerminalSceneTheme`

The main component split is also explicit:

- `PenggieWindowChromeTheme`
- `PenggieReadingComposerTheme`
- `NativeTuiOverlayTheme`
- `TerminalRendererPalette`

`PenggieThemeController` owns OS appearance observation and publishes an immutable current `PenggieTheme` through `EnvironmentValues.penggieTheme`. `PenggieApp` applies the terminal configuration to the active session whenever the controller publishes a new theme.

## Contract Matches

- Theme data is centralized in `PenggieTheme.swift`; the implementation is no longer a collection of local ad-hoc color patches.
- Reading and terminal scenes are separate, so terminal renderer requirements do not have to overload ordinary Reading/composer tokens.
- `TerminalSceneTheme` explicitly separates:
  - terminal canvas/chrome
  - active input
  - TUI selected row
  - terminal text selection
  - warning/accent foreground
- `TerminalRendererPalette` is a full renderer palette contract rather than a bare Ghostty theme name.
- Light and dark renderer theme files are generated from Penggie-owned data.
- Ghostty host fallback background comes from `TerminalThemeConfiguration.hostBackgroundColor`.
- Native terminal-owned overlay rows use `theme.components.nativeTuiOverlay`, preserving the product rule that selected row styling is a projection display concern, not local selected-state ownership.
- Window chrome is mode-aware: `PenggieWindowChrome` picks reading or terminal chrome tokens based on display mode.

## Gaps And Risks

### 1. Legacy convenience accessors still hide token ownership

`PenggieTheme` still exposes convenience colors such as `contentBackground`, `surface`, `elevatedSurface`, `selectedBackground`, `terminalBackground`, `secondaryText`, and `disabledAction`.

These keep call sites concise, but they make it easier for feature views to bypass the explicit scene/component layer. Future visual changes should prefer direct semantic paths such as:

- `theme.scenes.reading.background`
- `theme.scenes.terminal.canvasBackground`
- `theme.components.nativeTuiOverlay.selectedBackground`
- `theme.components.windowChrome.terminal.background`

Keep the convenience properties only as compatibility shims until 8.2/8.6 can enforce stricter usage.

### 2. Root views still use SwiftUI system styles in product surfaces

`PenggieRootView.swift` still has multiple `.primary`, `.secondary`, `.tertiary`, `.orange`, and similar system styles in setup, recovery, transcript, composer placeholder, and fallback views.

Some system colors are acceptable for platform-native controls, but product surfaces that must pass light/dark visual QA should move to approved semantic/component tokens. This should be handled in 8.2 and guarded in 8.6.

### 3. Reading composer component tokens are incomplete

`PenggieReadingComposerTheme` currently covers background, placeholder, and focus ring. The actual composer shell also depends on:

- border
- shadow
- send button enabled background
- send button disabled background
- send foreground
- disabled send foreground
- native-overlay host spacing/attachment

Those are currently assembled from broad theme convenience values in `PenggieRootView.swift`. This is acceptable for the current state, but it is not yet a fully explicit component contract.

### 4. Window chrome button style uses reading-level convenience tokens

`PenggieChromeIconButtonStyle` uses `theme.secondaryText`, `theme.disabledAction`, `theme.selectedBackground`, and `theme.surface` instead of the already-resolved mode-aware chrome token.

This can reintroduce terminal/reading visual seams in hover/focus states even when the chrome background itself is mode-aware.

### 5. Renderer palette and terminal scene are intentionally separate but partially duplicated

`TerminalSceneTheme` and `TerminalRendererPalette` both contain concepts around foreground, active input, selection, and cursor. This separation is correct because SwiftUI surfaces and Ghostty renderer config have different semantics.

The risk is accidental re-coupling. `activeInputBackground` should remain a terminal scene/native overlay token unless Ghostty has an explicit supported key for that role. Renderer selection keys must continue to map to text selection, not active input.

### 6. Appearance propagation depends on runtime apply paths

`PenggieThemeController` publishes new theme values, `PenggieApp` calls `session.applyTheme`, and `PenggieGhosttySession` forwards the configuration to the host view plus Ghostty color scheme sync.

This is the right ownership split, but QA should keep verifying that:

- the running app is using the current built Ghostty substrate
- generated theme files match the current Penggie palette
- the active Ghostty surface reloads or applies the expected conditional theme
- Raw Terminal, Reading chrome, and native overlays agree after OS appearance changes

## Follow-Up Mapping

- 8.2 should verify and migrate product surfaces away from scattered system styles where those styles affect product-owned visuals.
- 8.3 should capture light/dark visual states for setup, Reading, transcript, composer, terminal-owned overlays, Raw Terminal, and recovery.
- 8.5 should verify contrast for all terminal scene/component roles, especially selected rows, warning text, disabled text, and renderer palette colors.
- 8.6 should add a static guard that prevents new feature-view raw/system color use unless explicitly allowed.
- 10.4 should decide whether DEBUG-only theme diagnostics and generated temporary theme paths are acceptable product QA tooling or should be gated further.

## Acceptance Evidence For 8.1

- The current implementation has a recognizable token hierarchy matching the product-grade UI/UX contract.
- The current implementation has a separate Ghostty renderer palette contract and no longer relies on Ghostty built-in theme names as source of truth.
- Remaining token risks are identified and mapped to later tasks rather than hidden behind local visual patches.
- No application code was changed by this audit.

## Non-Goals

- Do not tune colors in this task.
- Do not remove system styles in this task.
- Do not alter Ghostty renderer configuration in this task.
- Do not claim light/dark visual QA is complete; that belongs to 8.3, 8.5, and 8.6.
