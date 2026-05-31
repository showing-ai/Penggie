## ADDED Requirements

### Requirement: Product UX preserves one complete local Codex CLI session
The system SHALL keep all product-grade UI/UX refinements bound to one real local Codex CLI process running through the Ghostty-backed PTY.

#### Scenario: User works in Reading
- **WHEN** the user submits prompts, invokes slash commands, changes model, resumes a session, approves actions, denies actions, or observes tool output
- **THEN** those actions are performed against the same active Codex CLI session rather than a parallel SDK, `codex exec --json`, or custom runtime session

#### Scenario: User switches views
- **WHEN** the user moves between Reading and Raw Terminal
- **THEN** both surfaces observe the same Codex process, cwd, terminal state, model state, and terminal-owned interaction state

### Requirement: Product UX does not clone Codex-owned state
The system SHALL NOT maintain local business-state copies of Codex-owned command, model, approval, permission, resume, or selection state.

#### Scenario: Native surface is displayed
- **WHEN** Penggie shows slash, model, effort, resume, approval, permission, or modal choice UI
- **THEN** the rows and selected state are projected from terminal frame evidence and not from a Penggie-maintained command list, model list, approval list, or selected index

#### Scenario: Navigation occurs
- **WHEN** the user presses navigation or confirmation keys in a Codex-owned surface
- **THEN** Penggie routes the input to the active PTY and waits for terminal evidence before updating selected-row UI

### Requirement: Future semantic sources remain auxiliary
The system SHALL treat future semantic/event sources as Reading enhancements, not replacements for the active terminal-owned session.

#### Scenario: Semantic source is added later
- **WHEN** Penggie uses semantic data to improve answer or tool rendering
- **THEN** the semantic data is bound to the same active session and does not drive slash/model/resume/approval state, replace Raw Terminal parity, or create a second user-visible agent session

#### Scenario: Terminal evidence is low confidence
- **WHEN** terminal-derived answer boundaries, layout, or display classification are uncertain
- **THEN** a future semantic source does not suppress raw/preformatted fallback, does not take over transcript segmentation as authoritative, and does not hide the Raw Terminal audit path

### Requirement: Unsafe certainty is forbidden
The system SHALL prefer visible low-confidence states over fabricated product certainty.

#### Scenario: Selection evidence is missing
- **WHEN** terminal facts do not prove a fresh exactly-one confirmable selection
- **THEN** Penggie does not allow a local confirmation path and does not show a fabricated selected row as authoritative

#### Scenario: Display semantics are uncertain
- **WHEN** terminal display cannot be confidently converted into semantic Reading content
- **THEN** Penggie preserves visible text with raw/preformatted fallback and keeps Raw Terminal as the audit path

### Requirement: Display AST is not interaction authority
The system SHALL treat Display AST as a terminal display transcript compiler, not as a Markdown recovery layer, semantic source, or control-state authority.

#### Scenario: Display AST classifies output
- **WHEN** Display AST produces Reading blocks, spans, fallback reasons, or table/code/CJK render hints
- **THEN** those outputs may improve Reading presentation but do not determine slash/model/resume/approval/permission state or selected-row confirmability

#### Scenario: Original Markdown is not visible
- **WHEN** terminal display lacks enough evidence to recover original Markdown syntax
- **THEN** Display AST preserves visible terminal text and confidence metadata rather than inventing source Markdown
