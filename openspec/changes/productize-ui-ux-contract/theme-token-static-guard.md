# Theme Token Static Guard

Task: 8.6

## Scope

This adds a repeatable source-level guard for product-owned theme usage. It is
not a visual QA replacement and does not claim that all legacy system colors
have been migrated.

## Guard

Command:

```bash
scripts/check-theme-token-usage.sh
```

The script now performs two checks:

1. Hard-fail forbidden raw color or renderer-theme usage in `Penggie/Sources`
   outside `PenggieTheme.swift`:
   - `NSColor.windowBackgroundColor`
   - `NSColor.textBackgroundColor`
   - `NSColor.controlBackgroundColor`
   - `NSColor.separatorColor`
   - `NSColor.selectedMenuItemTextColor`
   - `Color.accentColor`
   - `Color.black`
   - `Color.white`
   - hardcoded hex colors such as `#282c34`
   - built-in Ghostty theme names such as `One Half Dark` or `Builtin Light`

2. Enforce a baseline for current SwiftUI product-surface system styles:
   - `.foregroundStyle(.primary)`
   - `.foregroundStyle(.secondary)`
   - `.foregroundStyle(.tertiary)`
   - `.foregroundStyle(.orange)`

The baseline lives in:

```bash
scripts/theme-token-usage-baseline.txt
```

Counts may decrease as task 8.2 migrates legacy views to explicit tokens, but
they may not increase. New UI code must use `PenggieTheme` semantic, scene, or
component tokens instead.

## Current Baseline

The only explicitly allowed current product-surface system style usage is in
`Penggie/Sources/PenggieRootView.swift`:

- `.foregroundStyle(.primary)`: 8
- `.foregroundStyle(.secondary)`: 11
- `.foregroundStyle(.tertiary)`: 1
- `.foregroundStyle(.orange)`: 1

These are compatibility debt, not approved target architecture. Task 8.2 owns
migrating product surfaces to approved tokens.

## Acceptance Evidence

The guard is executable and passes in the current tree:

```bash
scripts/check-theme-token-usage.sh
```

## Non-Goals

- Do not migrate legacy system styles in this task.
- Do not tune visual colors in this task.
- Do not change Ghostty renderer palette values in this task.
- Do not use the static guard as a substitute for manual light/dark visual QA.
