## Why

The active-session chrome currently renders as an extra in-app top bar below the macOS traffic lights, which makes Penggie feel like a web UI placed inside a desktop window. Moving the product identity and session controls into the window chrome will make v0.1 feel more like a native macOS app while preserving the already-stable Reading, Raw Terminal, PTY, and native slash behavior.

## What Changes

- Move the active-session Penggie top bar into the hidden-titlebar window chrome region, visually aligned with the macOS traffic lights.
- Replace the Reading/Terminal segmented text control with one icon-only mode toggle:
  - In Reading, show a Terminal icon that switches to Raw Terminal.
  - In Terminal, show a Reading/chat icon that switches to Reading.
- Keep New Chat and Close Session as icon-only window chrome actions with clear hover, focus, pressed, tooltip, and accessibility states.
- Present `Codex` as a quiet session label/subtitle instead of a pill-style tag.
- Remove the extra content-row top bar so Reading and Raw Terminal start below one native-feeling chrome strip.
- Do not change Reading transcript extraction, turn history, composer IME behavior, Ghostty PTY, Raw Terminal data source, or native slash overlay source-of-truth behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `penggie-app-shell`: active-session top bar requirements change from an in-content product bar to a native-feeling window chrome with icon-only mode switching and session controls.

## Impact

- Affected code is expected to stay within Penggie app shell/view composition, primarily `PenggieRootView.swift` and, if required, small macOS window chrome helpers.
- Existing `PenggieSessionModel` state transitions may be reused but should not be semantically changed.
- No changes are expected to Ghostty integration, PTY routing, Codex CLI launch, Reading transcript store, native slash overlay projection, or Raw Terminal rendering.
