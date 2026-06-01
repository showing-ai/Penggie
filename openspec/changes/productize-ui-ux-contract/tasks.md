## 1. P0 Planning And Guardrails

- [x] 1.1 Build the P0/P1/P2 implementation board from `design.md`, with each task tagged by priority, affected Swift files, fixtures, manual QA, accessibility QA, visual QA, and non-goals.
- [x] 1.2 Add a pre-implementation checklist that rejects local command/model/resume/approval/permission lists, local selected indexes, forked Codex sessions, forked Raw Terminal sessions, and SwiftUI overlays that fake terminal-owned state.
- [x] 1.3 Add a release-readiness checklist that requires `openspec validate --all --strict`, relevant `swift test` filters, fixture review, manual QA evidence, and visual QA captures before each milestone is accepted.
- [x] 1.4 Audit current diagnostic logs and temporary debug paths in `PenggieSessionModel.swift` and `PenggieGhosttySession.swift`; classify which diagnostics remain for product QA and which must be gated or removed before release.

## 2. P0 App Shell, Setup, And Session Lifecycle

- [x] 2.1 Review `PenggieApp.swift`, `PenggieRootView.swift`, and `PenggieSessionModel.swift` against the app-shell state matrix; document any mismatch in visible UI, blocked actions, keyboard owner, Raw Terminal availability, and recovery path.
- [x] 2.2 Implement setup/start acceptance criteria: valid folder, invalid folder, missing folder, `Create with Penggie`, disabled/enabled states, keyboard order, VoiceOver labels, and no startup terminal noise leakage.
- [x] 2.3 Verify `Create with Penggie` starts the intended create/new-session path and does not enter resume picker unless Codex is explicitly launched in resume mode or the user chooses a resume path.
- [x] 2.4 Harden checking/launching states so prompt input, folder change, Raw Terminal, New Chat, and Close Session are blocked until an inspectable session or recovery state exists.
- [x] 2.5 Harden missing Codex, launch failed, process exited with terminal surface, and process exited without terminal surface states with specific copy, retry/close/start actions, and correct Raw Terminal availability.
- [x] 2.6 Validate New Chat and Close Session confirmations: focus trap, destructive copy, cancel restoration, confirm behavior, and no background session discard before confirmation.
- [x] 2.7 Add or update unit/manual QA coverage for setup, checking, launching, missing Codex, launch failed, process exited, New Chat, and Close Session.

## 3. P0 Terminal-Owned Overlay Reliability

- [x] 3.1 Review `PenggieNativeInteractionProjection.swift`, `PenggieNativeInteractionPhase.swift`, `PenggieCodexScreenKind.swift`, `PenggieTerminalFrameNormalizer.swift`, `PenggieSessionModel.swift`, and `PenggieRootView.swift` against the terminal-owned surface contract.
- [x] 3.2 Add or update fixtures for resume selected, resume unselected, resume ambiguous, resume filtered, resume sorted, resume paged, resume scrolled, and resume low-confidence states.
- [x] 3.3 Add or update fixtures for slash suggestions, slash continuation, model picker, effort picker, marker-selected rows, style-selected rows, cursor fallback, ambiguous selection, and stale selection.
- [x] 3.4 Add or update fixtures for approval, permission, and safety-sensitive modal choices with visible choices, selected evidence, confirmable state, blocked Enter, Esc/cancel behavior, and Raw Terminal parity.
- [x] 3.5 Implement visible selected-row geometry rules so selected rows are never clipped and the native list scrolls or repositions when selection moves outside the visible region.
- [x] 3.6 Implement freshness behavior so arrow/Tab/text input routes to PTY, the UI enters waiting-for-terminal-frame state, and selected highlight updates only after fresh terminal evidence.
- [x] 3.7 Ensure low-confidence rows remain visible when useful, Enter is blocked/consumed, and the syncing message is understandable without hiding the candidate list.
- [x] 3.8 Validate overlay metadata rendering for resume filter/sort/pager/help text without causing flashing, layout jump, clipped headers, or footer overlap.
- [x] 3.9 Add accessibility values for candidate rows: selected/not selected, confirmable/unavailable, syncing/unknown, row text, and non-color selected affordance.
- [ ] 3.10 Run manual QA for slash/model/resume/approval/permission in Reading and Raw Terminal, including rapid arrow navigation, page/scroll boundaries, Esc, Enter, Tab, Backspace, and typed filtering.

## 4. P0 Composer, IME, Focus, And Input Routing

- [x] 4.1 Review `PenggieComposerTextView.swift`, `PenggieComposerNativeTrigger.swift`, `PenggieInteractionKeyCaptureView.swift`, `PenggieRootView.swift`, and `PenggieSessionModel.swift` against the focus state machine.
- [ ] 4.2 Validate IME marked text behavior: placeholder hidden, marked text not overwritten by SwiftUI state, Enter not submitted while marked text exists, and committed text submits correctly.
- [ ] 4.3 Validate ordinary composer behavior: Enter submit, Shift-Enter newline, paste, large paste, draft preservation, send enablement, disabled send reasons, and bounded height/internal scroll.
- [ ] 4.4 Validate native slash handoff: first slash from composer sends to Codex, terminal-owned key capture takes over, local composer does not own selection, and dismissal restores the correct focus owner.
- [ ] 4.5 Validate focus transitions for setup, Reading idle, composing, terminal-owned overlay, full-page resume/approval/permission, Raw Terminal, confirmation, process exit, and recovery.
- [ ] 4.6 Add manual keyboard-only QA that completes setup, prompt submission, slash/model selection, resume selection, approval/permission choice, Raw Terminal switch, New Chat confirmation, and Close Session confirmation.

## 5. P0 Reading Transcript And Display AST Fallback

- [x] 5.1 Review `PenggieReadingTranscript.swift`, `PenggieDisplayAST.swift`, `PenggieDisplayASTRenderer.swift`, `PenggieDisplayRuleEngine.swift`, and `PenggieDisplayTranscriptReconciler.swift` against the Reading transcript anatomy.
- [x] 5.2 Validate turn roles: user prompt, working/tool summary, assistant answer, collapsible detail, raw/preformatted fallback, and active terminal-owned surface exclusion.
- [x] 5.3 Validate completed-turn stability under repaint, resize, later terminal output, Raw Terminal switching, long sessions, process exit, and subsequent prompt submission.
- [x] 5.4 Expand Display AST fixtures for CJK prose, CJK tables, box drawing, code blocks, warnings, tool-heavy output, low-confidence classification, and long transcripts.
- [x] 5.5 Validate that terminal footers, model/status rows, active input rows, slash/resume/approval surfaces, and transient startup/status UI do not become sealed assistant transcript content.
- [x] 5.6 Validate fallback behavior: low-confidence rendering preserves visible terminal text, exposes traceability/fallback reason where practical, and keeps Raw Terminal audit available.

## 6. P0 Raw Terminal Audit And Control Surface

- [x] 6.1 Review `PenggieGhosttySession.swift`, `PenggieGhosttySubstrate.swift`, `PenggieRootView.swift`, and `PenggieTheme.swift` against Raw Terminal audit/control requirements.
- [ ] 6.2 Validate Reading-to-Raw-to-Reading round trip preserves one Codex process, cwd, Ghostty session, scrollback, active terminal-owned state, process state, draft state, and transcript state.
- [ ] 6.3 Validate Raw Terminal remains available when Reading projection is low confidence and an inspectable terminal surface exists.
- [ ] 6.4 Validate Raw Terminal keyboard focus: Ghostty host receives keys when visible, local composer does not capture terminal input, and focus restores correctly when returning to Reading.
- [ ] 6.5 Validate Raw Terminal text selection, copy, pasteboard result, paste, mouse reporting behavior, and any platform modifier requirement such as Shift-drag if applicable.
- [ ] 6.6 Validate Raw Terminal visual parity in light and dark mode: canvas, titlebar chrome, active input, cursor, terminal selection, ANSI palette, selected rows, and native overlay tokens.

## 7. P1 Accessibility, Announcements, And Dynamic Type

- [x] 7.1 Create a manual VoiceOver QA checklist for setup, Reading, composer, tool disclosure, native overlay rows, resume, approval, permission, Raw Terminal switch, recovery, and confirmations.
- [ ] 7.2 Implement or verify accessibility labels, hints, values, roles, selected states, disabled/unavailable states, syncing states, expanded/collapsed states, and destructive confirmation labels.
- [ ] 7.3 Implement or verify dynamic state announcements for checking, launching, ready, working, tool running, approval required, permission required, projection degraded, selection syncing, process exited, missing Codex, and launch failed.
- [ ] 7.4 Validate Dynamic Type or larger text behavior across setup, Reading, composer, overlays, recovery, Raw Terminal chrome, and narrow windows; document accepted truncation and accessible full values.
- [ ] 7.5 Validate reduced motion behavior for disclosure, surface switching, focus affordances, and overlay transitions.
- [x] 7.6 Decide which accessibility checks can become automated smoke tests and add scripts only where the result is stable enough to avoid noisy failures.

## 8. P1 Theme, Density, And Visual Polish

- [x] 8.1 Review `PenggieTheme.swift`, `PenggieThemeController.swift`, `PenggieRootView.swift`, and `PenggieGhosttySession.swift` against the token layer, scene token, component token, and renderer palette contract.
- [ ] 8.2 Validate that setup, Reading canvas, composer, transcript content, terminal-owned overlays, Raw Terminal, titlebar chrome, recovery states, and confirmations use approved tokens rather than scattered raw colors or system backgrounds.
- [ ] 8.3 Create visual QA captures for light mode and dark mode across setup, empty Reading, long transcript, composer focus, slash overlay, resume picker, approval/permission, Raw Terminal, recovery, narrow window, and large text.
- [ ] 8.4 Validate density rules: high information density from hierarchy and disclosure, not smaller body text, hidden state, overloaded titlebar, nested cards, or decorative visual weight.
- [ ] 8.5 Validate contrast targets for normal text, large text/icons, focus rings, disabled state, selected rows, warnings, danger, and terminal renderer colors.
- [x] 8.6 Run or add static checks that prevent new scattered `windowBackgroundColor`, `textBackgroundColor`, hardcoded terminal background hex, or feature-view raw color use unless explicitly allowed.

## 9. P1 Fixture And Regression Expansion

- [ ] 9.1 Expand `Tests/PenggieCoreTests/Fixtures/agent-terminal-display/` for long-session transcript, CJK prose, CJK table, box drawing, warning/status, tool-heavy output, fallback, and large preformatted content.
- [ ] 9.2 Expand `Tests/PenggieCoreTests/Fixtures/terminal-interaction-surfaces/` for resume scroll/pager/filter/sort, slash continuation, model/effort pickers, approval, permission, stale selection, ambiguous selection, and low-confidence rows.
- [x] 9.3 Add fixture README entries describing source terminal facts, expected Display AST, expected Reading rendering, expected selected-row evidence, and expected low-confidence behavior.
- [ ] 9.4 Add or update unit tests so fixture changes fail on transcript pollution, wrong selected-row evidence, unsafe confirmability, broken fallback, or lost Raw Terminal parity assumptions.

## 10. P2 QA Scripts, Review Tooling, And Release Hygiene

- [x] 10.1 Create a repeatable manual QA script for the product-grade UI/UX matrix with exact setup, terminal fixture, window size, theme, keyboard, VoiceOver, and expected result steps.
- [ ] 10.2 Add optional scripts for visual capture or local QA setup where practical, without depending on a separate Codex session as user-visible truth.
- [x] 10.3 Add a release review checklist that records manual QA evidence, visual captures, accessibility notes, fixture coverage, known limitations, and deferred P2 items.
- [ ] 10.4 Remove or gate debug-only diagnostic logs and temporary files that were useful during development but are not part of product QA.
- [x] 10.5 Review product copy for setup, low-confidence syncing, projection degraded, missing Codex, launch failed, process exited, confirmation, approval, permission, and Raw Terminal audit paths.

## 11. Validation

- [x] 11.1 Run `openspec validate productize-ui-ux-contract --strict`.
- [x] 11.2 Run `openspec show productize-ui-ux-contract --json`.
- [x] 11.3 Run `openspec validate --all --strict` before applying implementation tasks from this change.
