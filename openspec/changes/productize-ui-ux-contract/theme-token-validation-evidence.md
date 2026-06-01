# Theme Token Validation Evidence

## Scope

This evidence closes task 8.2 for `productize-ui-ux-contract`.

Validated product surfaces:

- setup/start copy and provider card text
- progress and recovery copy
- empty Reading canvas
- terminal-owned interaction waiting copy
- resume and modal choice headings
- composer placeholder
- Reading transcript prose, preformatted fallback, tool chrome, and disclosure details
- Raw Terminal placeholder

## Evidence

- Added semantic convenience tokens to `PenggieTheme` for primary text, warning text, and composer placeholder text.
- Migrated remaining product-surface `foregroundStyle(.primary)`, `foregroundStyle(.secondary)`, `foregroundStyle(.tertiary)`, and `foregroundStyle(.orange)` usages in `PenggieRootView.swift` to `PenggieTheme` tokens.
- Tightened `scripts/theme-token-usage-baseline.txt` so no product-surface SwiftUI system foreground styles are allowed.
- Verified `scripts/check-theme-token-usage.sh` passes after the baseline was tightened.
- Verified `rg -n "foregroundStyle\\(\\.(primary|secondary|tertiary|orange)\\)" Penggie/Sources/PenggieRootView.swift` returns no matches.

## Non-goals

- This does not introduce new visual styling, renderer palette behavior, or terminal-owned state.
- This does not alter Codex PTY input, Ghostty substrate behavior, Raw Terminal session ownership, or terminal-owned overlay selection logic.
- Visual capture, contrast review, density review, and large-text review remain covered by tasks 8.3, 8.4, and 8.5.
