## ADDED Requirements

### Requirement: Product-grade UI/UX work is milestone-driven
The system SHALL organize execution of the approved product-grade UI/UX contract into P0, P1, and P2 milestones with module ownership and acceptance criteria.

#### Scenario: Milestone is created
- **WHEN** a product-grade UI/UX implementation task is planned
- **THEN** it identifies its priority, user-visible outcome, primary Swift modules, tests or fixtures, manual QA, accessibility QA, visual QA, and explicit non-goals

#### Scenario: P0 scope is reviewed
- **WHEN** launch-blocking UI/UX work is reviewed
- **THEN** P0 includes shell/session lifecycle, terminal-owned overlay reliability, composer/IME/focus integrity, Reading transcript stability, and same-session Raw Terminal parity

#### Scenario: P1 scope is reviewed
- **WHEN** product maturity work is reviewed after P0
- **THEN** P1 includes accessibility completion, keyboard-only completion, theme/density convergence, visual review, and Display AST fixture expansion

#### Scenario: P2 scope is reviewed
- **WHEN** launch polish and maintenance work is reviewed
- **THEN** P2 includes QA script consolidation, visual capture tooling, diagnostics cleanup, copy refinement, and release review checklists

### Requirement: Implementation tasks map to current Penggie modules
The system SHALL map each implementation task to existing Penggie source files and test areas before code work starts.

#### Scenario: App shell work is planned
- **WHEN** setup, launch, exit, recovery, New Chat, Close Session, or chrome work is planned
- **THEN** the task references `PenggieApp.swift`, `PenggieRootView.swift`, `PenggieSessionModel.swift`, and the relevant session lifecycle tests or manual QA scenarios

#### Scenario: Reading and Display AST work is planned
- **WHEN** transcript hierarchy, display fallback, CJK/table/code rendering, or turn stability work is planned
- **THEN** the task references `PenggieReadingTranscript.swift`, `PenggieDisplayAST*.swift`, `PenggieDisplayRuleEngine.swift`, `PenggieDisplayTranscriptReconciler.swift`, and display fixture tests

#### Scenario: Terminal-owned interaction work is planned
- **WHEN** slash, model, effort, resume, approval, permission, or modal choice work is planned
- **THEN** the task references `PenggieNativeInteractionProjection.swift`, `PenggieNativeInteractionPhase.swift`, `PenggieCodexScreenKind.swift`, `PenggieTerminalFrameNormalizer.swift`, `PenggieSessionModel.swift`, `PenggieRootView.swift`, and terminal interaction surface fixtures

#### Scenario: Raw Terminal work is planned
- **WHEN** Raw Terminal parity, copy/paste, mouse selection, theme, or audit/control work is planned
- **THEN** the task references `PenggieGhosttySession.swift`, `PenggieGhosttySubstrate.swift`, `PenggieRootView.swift`, `PenggieTheme.swift`, and Raw Terminal manual QA

### Requirement: QA assets are required implementation outputs
The system SHALL treat QA assets as part of product-grade implementation rather than optional post-implementation review.

#### Scenario: Milestone reaches implementation complete
- **WHEN** an implementation milestone is marked complete
- **THEN** its manual QA steps, fixture needs, accessibility checks, visual checks, and regression tests are either implemented or explicitly documented as not applicable

#### Scenario: Fixture is needed
- **WHEN** a milestone changes terminal projection, Display AST rendering, session lifecycle, focus routing, or terminal-owned selection
- **THEN** it includes a fixture or diagnostic capture that can reproduce the reviewed behavior without relying only on screenshots

#### Scenario: Visual QA is needed
- **WHEN** a milestone changes setup, Reading, composer, terminal-owned overlays, Raw Terminal, theme, density, or recovery visuals
- **THEN** it defines light, dark, large text, narrow window, and normal window review scenarios

#### Scenario: Accessibility QA is needed
- **WHEN** a milestone changes keyboard routing, focus, controls, overlays, candidate rows, recovery states, or confirmations
- **THEN** it defines keyboard-only and VoiceOver checks including role, label, selected state, disabled state, syncing state, and expected announcements

### Requirement: Productization forbids state-faking shortcuts
The system SHALL reject implementation tasks that make the UI appear polished by weakening terminal truth or same-session continuity.

#### Scenario: Local mirror is proposed
- **WHEN** an implementation proposes a local command list, model list, resume list, approval list, permission list, or selected index for a Codex-owned surface
- **THEN** the proposal is rejected unless it is explicitly marked non-authoritative diagnostic-only data

#### Scenario: Unsafe visual certainty is proposed
- **WHEN** an implementation proposes to show a selected row, confirm button, transcript block, or semantic rendering without terminal-frame or Display AST evidence
- **THEN** the proposal is rejected or must display low-confidence/degraded state and block unsafe confirmation

#### Scenario: Separate session is proposed
- **WHEN** an implementation proposes a second Codex process, SDK session, `codex exec --json` session, or separate Raw Terminal session for the user-visible workflow
- **THEN** the proposal is rejected because Reading and Raw Terminal must remain bound to one real session
