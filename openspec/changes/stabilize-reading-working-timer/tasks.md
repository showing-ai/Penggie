## 1. Diagnose Current Timer Ownership

- [x] 1.1 Inspect Reading turn/disclosure rendering and identify where terminal-projected working rows suppress local timer display.
- [x] 1.2 Inspect session model timer refresh path and identify any per-second full projection/blockizer work.

## 2. Implement Stable Active Progress

- [x] 2.1 Add or expose turn metadata needed for local active/completed progress rendering without changing PTY or slash behavior.
- [x] 2.2 Render active `Working... Ns` from local turn timing even when terminal projection contains stale `Working... 0s`.
- [x] 2.3 Keep terminal-derived working/search/tool rows in disclosure details and out of the primary answer flow.
- [x] 2.4 Freeze completed `Worked for Ns` duration and prevent later ticks from changing completed turns.
- [x] 2.5 Replace any per-second full blockization refresh with a lightweight active-turn timer update path.

## 3. Tests and Verification

- [x] 3.1 Add focused tests for stale terminal `Working... 0s` plus locally advancing active progress.
- [x] 3.2 Add tests that completed duration freezes and multi-turn responses do not rewrite or merge previous turns.
- [x] 3.3 Run the existing Swift core tests covering Reading transcript and native slash behavior.
- [x] 3.4 Build the macOS app target.
