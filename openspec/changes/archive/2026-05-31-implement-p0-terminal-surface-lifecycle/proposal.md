## Why

`productize-ui-ux-contract` has been accepted as the product-grade UI/UX contract, and `harden-terminal-ux-qa-foundation` has landed the first fixture and safety-test foundation. The next implementation change should not start with broad visual polish or a Reading rewrite. It should make the first P0 user-visible lifecycle and terminal-owned surface behaviors reliable in app code.

Recent manual QA exposed the same class of failures across resume picker, slash/model overlays, and session entry:

- `Create with Penggie` can expose a resume picker even though the product action is a new/create path.
- Native terminal-owned lists can show rows before selected-row evidence is fresh, can jump or flicker during navigation, and can clip selected rows at list boundaries.
- Unsafe Enter must be consumed instead of falling through to the composer when selection is stale, missing, or ambiguous.
- Reading and Raw Terminal must remain two projections of the same Ghostty/Codex session, including while a terminal-owned surface is active.

This change implements the first P0 runtime slice from the productization plan.

## What Changes

- Add a P0 implementation slice for app shell/session lifecycle and terminal-owned interaction surfaces.
- Harden `Create with Penggie` so it starts the intended new/create session path and does not intentionally route users into resume unless an explicit resume path is added later.
- Harden terminal-owned surface input policy so navigation routes to the PTY, confirmation is gated by fresh reliable terminal evidence, and blocked Enter is consumed.
- Stabilize native terminal-owned list viewporting so selected rows remain fully visible and do not render clipped at the overlay boundary.
- Preserve useful low-confidence rows while preventing unsafe confirmation.
- Verify Reading-to-Raw-to-Reading round trip uses the same `PenggieGhosttySession` and does not discard terminal-owned surface state.
- Add targeted tests for the implementation slice.

## Capabilities

### Modified Capabilities

- `penggie-app-shell`: Adds implementation requirements for create/new-session entry safety and launch-state action gating.
- `terminal-interaction-surfaces`: Adds implementation requirements for fresh selection gating, PTY-routed navigation, visible selected-row viewporting, and low-confidence rendering.
- `raw-terminal-fallback`: Adds implementation requirements for same-session round trip while terminal-owned surfaces are active.
- `codex-single-session`: Adds implementation requirements preventing alternate local state authority or second Codex runtime during this P0 slice.

## Impact

- Affected source files:
  - `Penggie/Sources/PenggieSessionModel.swift`
  - `Penggie/Sources/PenggieRootView.swift`
  - `Penggie/Sources/PenggieNativeInteractionProjection.swift`
  - `Penggie/Sources/PenggieInteractionKeyCaptureView.swift`
  - `Penggie/Sources/PenggieGhosttySession.swift`
- Affected tests and fixtures:
  - `Tests/PenggieCoreTests/PenggieTerminalInteractionSurfaceTests.swift`
  - `Tests/PenggieCoreTests/PenggieNativeInteractionProjectionTests.swift`
  - `Tests/PenggieCoreTests/PenggieSessionModelPollingTests.swift`
  - `Tests/PenggieCoreTests/Fixtures/terminal-interaction-surfaces/`
- Validation:
  - `openspec validate implement-p0-terminal-surface-lifecycle --strict`
  - targeted `swift test` filters for terminal interaction, native projection, and session model polling
  - `openspec validate --all --strict`
  - `git diff --check`

## Non-Goals

- Do not implement broad UI visual polish, theme/density redesign, or Reading transcript layout changes.
- Do not add a local resume/session list, command list, model list, approval list, permission list, or local selected index.
- Do not split Reading and Raw Terminal into separate Codex/Ghostty sessions.
- Do not replace Codex CLI, Ghostty PTY, or Raw Terminal with an SDK/headless runtime.
- Do not make Chat UI own terminal selection state.
- Do not add a product resume entry point in this change; this change only ensures `Create with Penggie` is not treated as resume by Penggie-owned logic.
