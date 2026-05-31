## Context

Penggie uses a single Codex CLI process inside a Ghostty-backed PTY. Reading, Raw Terminal, native slash overlay, and the native resume picker are all projections of that same terminal state.

Recent resume/startup fixes prevented some terminal-owned screens from hydrating into Reading, but they introduced a weaker product boundary: any non-empty terminal projection that is not recognized as resume picker or shell startup falls back to `.chat`. This allows transient Codex screens such as MCP startup progress to unlock the product UI and render as Reading content. Resume picker also unlocks the UI before its native projection has a reliable selected row, and Raw Terminal is mounted underneath Reading with SwiftUI opacity rather than AppKit-level hiding.

Constraints:
- Keep one real Codex CLI process and one Ghostty PTY.
- Do not maintain a local session list or selected index.
- Do not route startup/resume through Raw Terminal as the product experience.
- Do not couple this work to slash command list ownership or Reading markdown rendering.

## Goals / Non-Goals

**Goals:**
- Keep the Welcome/start surface visible until the next product surface is display-ready.
- Prevent Codex startup/status text from hydrating into Reading or showing with the composer.
- Show native resume picker rows once rows are available, and require exactly one selected row only for highlight and Enter confirmation.
- Use Codex/Ghostty visible text markers as the first resume selected-row source when present.
- Prevent inactive Raw Terminal from visually leaking during Reading startup/resume transitions.
- Preserve same-session Reading/Terminal switching after the session is display-ready.

**Non-Goals:**
- Replacing Codex resume with a locally owned session database.
- Splitting Reading and Raw Terminal into separate Codex sessions.
- Redesigning the resume picker visuals beyond readiness and selection correctness.
- Changing native slash command behavior.
- Reworking the Reading blockizer, markdown renderer, or table renderer.

## Decisions

### Decision 1: Separate `screenKind` from `displayReady`

`PenggieCodexScreenKind` should classify terminal screens, but it should not by itself unlock the app UI. A separate display-ready decision should decide whether the current projection is safe to show as a Penggie product surface.

Ready states:
- Reading empty/chat-ready when Codex is idle enough for the composer surface, not just any fallback `.chat` text.
- Resume picker ready when `resumePickerProjection.rows` is non-empty; exactly one selected row is required before Enter can confirm a resume.

Blocking states:
- Shell startup and blank/unknown screen.
- Codex startup/status screens such as `Starting MCP servers`, `esc to interrupt`, and similar one-line progress/status output.
- Resume picker frames whose rows are incomplete.

Alternative considered: make `.chat` stricter and keep using `hasReachedStableCodexScreen`. Rejected because `.chat` is still a broad terminal classification; readiness needs product-level context such as picker row selection and transcript/composer readiness.

### Decision 2: Add startup/status classification before chat fallback

Codex startup/status text should be recognized before the `.chat` fallback. A minimal matcher should cover current observed startup lines such as `Starting MCP servers (2/3): figma (2s • esc to interrupt)` and generic `esc to interrupt` startup progress.

Alternative considered: hide all first transcript frames for a fixed timeout. Rejected because it would be timing-based, flaky on slow starts, and could hide legitimate fast-ready states.

### Decision 3: Debounce initial release

The startup hold should release only after the same ready target is observed across a short stability window, such as 2-3 polls or 300-500ms. This prevents single transient frames from swapping the whole product surface.

Alternative considered: release immediately on first ready signal. Rejected because current regressions are caused by overly early release.

### Decision 4: Prefer visible marker selection for resume picker

When parsing resume picker with both `visibleText` and `screenModelJSON`, the visible text `›` marker should be parsed first. If it yields a unique selected row, that selection should override snapshot-derived selection while snapshot data can still supply rows and style metadata.

Fallback order:
1. Unique visible text `›` marker aligned by source line or `(age, title, occurrence)`.
2. Snapshot `line.selected` or explicit selected/inverse style.
3. Snapshot cursor row only if it matches a parsed resume row.
4. Unique weak style signal such as foreground-selected age text.
5. No selected row, keeping rows visible but selection-dependent confirmation disabled.

Alternative considered: keep strengthening style heuristics. Rejected because style is noisy and previously caused multiple unrelated rows to become selected.

### Decision 5: Hide inactive Raw Terminal at AppKit view level

The Raw Terminal fallback may remain mounted to avoid Ghostty surface attach/detach churn, but inactive state should be propagated to the `PenggieGhosttyHostView` as real visibility/interactivity, not just SwiftUI opacity.

Expected behavior:
- Inactive Raw Terminal host view is hidden and non-interactive.
- Active Raw Terminal remains the same Ghostty surface and PTY.
- Startup/resume hold does not expose a terminal-owned transition page.

Alternative considered: unmount Raw Terminal entirely until user switches modes. Rejected for now because previous crash risk points to Ghostty surface lifecycle sensitivity during repeated attach/detach.

## Risks / Trade-offs

- **Risk:** Readiness gating could hold Welcome too long if Codex output format changes.  
  **Mitigation:** Prefer positive ready signals from stable composer/resume projection and keep Raw Terminal explicitly available only after the session is inspectable.

- **Risk:** Resume picker selection matching by `(age, title, occurrence)` can be ambiguous with duplicate rows.  
  **Mitigation:** Use occurrence-aware matching and require exactly one selected marker before highlighting or accepting Enter.

- **Risk:** AppKit-level hiding of Ghostty view could affect resize/focus.  
  **Mitigation:** Keep resize lifecycle unchanged and only gate visibility/interactivity; verify Reading/Terminal switching after startup.

- **Risk:** Debounce may make startup feel slightly delayed.  
  **Mitigation:** Use a short poll-count/time threshold and preserve the stable Welcome surface during the wait.

## Migration Plan

1. Add screen classification tests for Codex startup/status lines.
2. Add display-ready gating in the session model without changing PTY launch.
3. Update resume picker projection to honor visible `›` marker before snapshot fallback.
4. Hide inactive Raw Terminal at the host view layer.
5. Add tests for resume marker precedence and startup/status blocking.
6. Run Swift tests, macOS app build, and manual verification for new chat, resume picker, Raw Terminal switch, and no intermediate startup surfaces.
