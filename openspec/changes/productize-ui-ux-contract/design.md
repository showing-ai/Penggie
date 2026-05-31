## Context

`define-product-grade-ui-ux` is the accepted product-grade UX contract for Penggie. It establishes the product promise, terminal source-of-truth rules, state matrix, component expectations, accessibility contract, and QA matrix.

The current app already has the core runtime primitives:

- Session lifecycle in `PenggieSessionModel.swift`.
- Window shell, setup, Reading, Raw Terminal container, overlays, and recovery views in `PenggieRootView.swift`.
- AppKit composer and IME behavior in `PenggieComposerTextView.swift`.
- Key capture/routing in `PenggieInteractionKeyCaptureView.swift`.
- Terminal screen kind, frame normalization, surface zoning, and native projection in `PenggieCodexScreenKind.swift`, `PenggieTerminalFrameNormalizer.swift`, and `PenggieNativeInteractionProjection.swift`.
- Display AST and Reading reconciliation in `PenggieDisplayAST*.swift`, `PenggieDisplayRuleEngine.swift`, `PenggieDisplayTranscriptReconciler.swift`, and `PenggieReadingTranscript.swift`.
- Ghostty PTY, Raw Terminal host, theme application, mouse/keyboard bridge, and copy/paste bridge in `PenggieGhosttySession.swift`.
- Theme tokens and theme controller in `PenggieTheme.swift` and `PenggieThemeController.swift`.
- Unit fixtures under `Tests/PenggieCoreTests/Fixtures/`.

This change does not revisit the UX direction. It turns the accepted contract into a productization execution plan.

## Goals / Non-Goals

**Goals:**

- Convert the approved UI/UX contract into prioritized P0/P1/P2 implementation milestones.
- Map each milestone to existing Swift modules, tests, fixtures, scripts, and manual QA responsibilities.
- Define acceptance criteria that can be used by engineering, design, QA, and product review.
- Define fixture requirements for terminal-owned overlays, Display AST fallback, CJK/table/code output, session lifecycle, and Raw Terminal parity.
- Define accessibility QA, keyboard-only QA, VoiceOver QA, Dynamic Type QA, visual QA, and theme/density review gates.
- Preserve terminal ground truth, same-session continuity, Raw Terminal auditability, and terminal-owned overlay rules.

**Non-Goals:**

- Do not implement app code in this OpenSpec change.
- Do not replace Codex CLI, Ghostty PTY, or the embedded Raw Terminal with an SDK/headless/session-mirror runtime.
- Do not add local session lists, command lists, model lists, approval lists, permission lists, or selected-index state.
- Do not make Reading the owner of terminal-owned interactions.
- Do not hide low-confidence projection with decorative polish or optimistic local UI.
- Do not split Raw Terminal and Reading into separate sessions.
- Do not redesign the Display AST architecture or Ghostty substrate in this plan.

## Decisions

### Decision 1: Productization is milestone-driven, not component-by-component polish

The implementation plan is organized by user-visible workflow milestones:

| Priority | Milestone | User-visible outcome |
| --- | --- | --- |
| P0 | Shell/session lifecycle hardening | Setup, create, launch, exit, New Chat, Close Session, recovery, and Raw Terminal availability are deterministic and reviewable. |
| P0 | Terminal-owned overlay reliability | Slash/model/resume/approval/permission surfaces use terminal-backed rows, selection, scrolling, clipping, freshness, and confirm gates. |
| P0 | Composer/IME/focus integrity | Prompt entry, marked text, Enter/Shift-Enter, paste, focus restore, and key ownership work under Reading, Raw Terminal, and overlays. |
| P0 | Reading transcript stability | Completed turns stay stable; terminal chrome/current menus do not pollute transcript; raw fallback preserves uncertain display. |
| P0 | Same-session audit/control parity | Raw Terminal proves and controls the same Codex/Ghostty session and survives view switching. |
| P1 | Accessibility and keyboard-only completion | VoiceOver, focus order, selected/unavailable/syncing values, Dynamic Type, reduced motion, and keyboard-only journeys are verified. |
| P1 | Visual system convergence | Theme, density, chrome/canvas/composer/overlay polish use shared tokens and pass light/dark review. |
| P1 | Display AST fixture expansion | Long sessions, CJK, tables, code, warnings, tool-heavy output, and low-confidence fallback have fixture coverage. |
| P2 | Launch polish and review tooling | QA scripts, visual review captures, review checklists, diagnostics cleanup, and product copy refinements are standardized. |

Alternative considered: polish by Swift file or visual component. Rejected because the current regressions cross module boundaries: terminal frame facts, projection confidence, key routing, focus, scroll geometry, and visual presentation all participate in one user-visible behavior.

### Decision 2: Every milestone has a module ownership map

Each task must identify its primary implementation files before work begins:

| Workstream | Primary modules | Supporting tests/fixtures |
| --- | --- | --- |
| App shell / start setup / lifecycle | `PenggieApp.swift`, `PenggieRootView.swift`, `PenggieSessionModel.swift` | `PenggieSessionModelPollingTests.swift`, app-shell spec scenarios, manual lifecycle QA |
| Reading transcript hierarchy | `PenggieReadingTranscript.swift`, `PenggieDisplayAST*.swift`, `PenggieDisplayRuleEngine.swift`, `PenggieDisplayTranscriptReconciler.swift`, `PenggieRootView.swift` | `agent-terminal-display` fixtures, Reading transcript tests |
| Composer / IME / focus | `PenggieComposerTextView.swift`, `PenggieComposerNativeTrigger.swift`, `PenggieInteractionKeyCaptureView.swift`, `PenggieRootView.swift`, `PenggieSessionModel.swift` | composer/native trigger tests, manual IME QA |
| Native terminal-owned overlays | `PenggieNativeInteractionProjection.swift`, `PenggieNativeInteractionPhase.swift`, `PenggieCodexScreenKind.swift`, `PenggieTerminalFrameNormalizer.swift`, `PenggieSessionModel.swift`, `PenggieRootView.swift` | `terminal-interaction-surfaces` fixtures and projection tests |
| Raw Terminal audit/control | `PenggieGhosttySession.swift`, `PenggieGhosttySubstrate.swift`, `PenggieRootView.swift`, `PenggieTheme.swift` | Raw Terminal manual QA, Ghostty substrate scripts |
| Display AST fallback | `PenggieDisplayAST.swift`, `PenggieDisplayASTRenderer.swift`, `PenggieDisplayRuleEngine.swift`, `PenggieDisplayTranscriptReconciler.swift` | display fixture snapshot tests |
| Accessibility and announcements | `PenggieRootView.swift`, `PenggieComposerTextView.swift`, `PenggieInteractionKeyCaptureView.swift`, overlay row views | manual AX/VoiceOver QA, future AX smoke scripts |
| Theme / density / visual polish | `PenggieTheme.swift`, `PenggieThemeController.swift`, `PenggieRootView.swift`, `PenggieGhosttySession.swift` | theme tests, visual QA captures |
| QA scripts | `scripts/`, `Tests/PenggieCoreTests/Fixtures/`, OpenSpec scenario scripts | CI/local validation docs |

Alternative considered: assign tasks only by user story. Rejected because Penggie's architecture is intentionally split between SwiftUI, AppKit, Ghostty, and terminal projection; implementation without file ownership would drift into local patches.

### Decision 3: P0 work must preserve terminal source-of-truth before visual polish

The first implementation milestone must verify that every product-facing surface still uses the same Codex/Ghostty session and terminal-owned interaction facts. Visual improvements are accepted only when they do not invent state.

Required P0 gates:

- Reading and Raw Terminal share the same `PenggieGhosttySession`.
- Terminal-owned overlays only confirm from fresh reliable terminal evidence.
- Navigation keys route to PTY and wait for terminal frames before selected-row changes.
- Low-confidence rows remain visible when useful, but confirmation stays blocked.
- `Create with Penggie` starts the intended create/new-session path and does not accidentally route users into resume unless Codex itself is launched in resume mode or the user explicitly chooses a resume path.
- Raw Terminal remains available when an inspectable session exists.

Alternative considered: implement native UX first and reconcile terminal truth later. Rejected because the historical bugs were caused by visual state drifting from terminal truth.

### Decision 4: QA assets are part of the implementation, not after-the-fact review

Each milestone must include:

- Manual QA steps.
- Fixture additions or explicit statement that no fixture is needed.
- Accessibility checks.
- Visual review checks.
- Regression guard or unit test when practical.
- Negative cases and "do not do" constraints.

Alternative considered: keep QA in a separate release checklist. Rejected because projection and focus bugs are easiest to prevent when fixtures and QA expectations are added with the implementation task.

### Decision 5: Accessibility and dynamic announcements are first-class workstreams

Accessibility is not a final polish pass. Terminal-owned surfaces, composer focus, setup, recovery, Raw Terminal switching, and confirmations need accessibility state and announcements as part of their implementation acceptance.

The plan requires manual VoiceOver and keyboard-only QA before a milestone is complete. Automated AX tests may be added later where stable, but they do not replace manual review for terminal-owned surfaces.

Alternative considered: defer accessibility until launch hardening. Rejected because focus ownership and selected-row semantics are architectural, not cosmetic.

### Decision 6: Visual polish uses tokens and scene contracts

Visual work must use `PenggieTheme` token layers and scene/component tokens. Raw hex values or system colors in feature views require justification and review. Terminal renderer palette work must remain separate from Reading/composer tokens and must not reinterpret Codex state.

Alternative considered: patch individual backgrounds or selected row colors. Rejected because recent regressions showed that local color patches break light/dark parity and terminal renderer contracts.

## Risks / Trade-offs

- **Risk: The plan becomes too broad to execute.** -> Mitigation: tasks are grouped into P0/P1/P2 milestones with explicit acceptance criteria; implementation can stop after P0 for launch readiness.
- **Risk: Product polish accidentally clones terminal state.** -> Mitigation: each affected spec repeats terminal source-of-truth constraints and forbids local selected indexes/lists.
- **Risk: QA scope grows faster than implementation.** -> Mitigation: every QA item is tied to a concrete milestone and fixture/manual scenario; P2 review tooling can follow after P0/P1 behavior is stable.
- **Risk: Visual review becomes subjective.** -> Mitigation: require screenshots/captures for light/dark, setup, Reading, Raw Terminal, overlays, CJK/table/code, and large text, with token usage constraints.
- **Risk: Accessibility is hard to automate.** -> Mitigation: define manual VoiceOver, keyboard-only, Dynamic Type, and reduced motion checks as required acceptance gates.
- **Risk: Future semantic sources conflict with terminal truth.** -> Mitigation: semantic data may improve Reading display only when bound to the same active session and never drives terminal-owned surfaces.

## Migration Plan

This change is a planning change only. Future implementation should proceed in this order:

1. Land P0 shell/session lifecycle and same-session guard tasks.
2. Land P0 terminal-owned overlay reliability tasks, including resume/slash/model/approval/permission fixtures and auto-scroll/clipping behavior.
3. Land P0 composer/IME/focus and Reading transcript stability tasks.
4. Land P0 Raw Terminal audit/control parity tasks.
5. Land P1 accessibility, Dynamic Type, theme, density, and Display AST fixture expansion tasks.
6. Land P2 QA script consolidation, visual review automation, diagnostics cleanup, and polish refinements.

Rollback is per implementation change. No app runtime behavior changes are introduced by this planning change.

## Open Questions

- Which P0 items are required before the next tagged internal build versus before public release?
- Should resume be exposed as an explicit setup action separate from `Create with Penggie`, or remain terminal-owned only when Codex enters resume mode?
- Which accessibility checks can become automated AX smoke tests after the manual QA matrix stabilizes?
- Which visual captures should be generated by script versus manually collected from the running macOS app?
