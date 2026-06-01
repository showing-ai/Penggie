# Terminal Display AST Implementation Plan

## Core Decision

Penggie will not treat terminal output as a lossy transport for original Markdown. It will treat terminal output as the authoritative display transcript produced by the real Agent CLI TUI.

```text
Codex CLI TUI
  -> PTY ANSI bytes
  -> Ghostty styled cells
  -> Penggie terminal display adapters
  -> Penggie Display AST
  -> Reading renderer
```

The Display AST is a Reading contract, not a Markdown AST. It can represent Markdown-ish structures when visible evidence is strong, but it must also represent terminal-native structures such as box drawing, activity rows, warnings, approval prompts, slash menus, and preformatted output.

## Invariants

- The real Codex CLI remains the backend and interaction source of truth.
- Ghostty PTY/screen model remains the source for Raw Terminal and native overlay projection.
- Penggie does not maintain local slash/model command tables or selected-index state.
- Visible text is stronger evidence than style.
- Layout and cell width are stronger evidence than color.
- Style attributes are hints, not semantic truth.
- Low-confidence output must degrade to readable raw/preformatted display.

## Architecture

```text
Ghostty screen model
  -> TerminalStyledSnapshot
  -> TerminalRowRuns
  -> TerminalRowFeatures
  -> TranscriptReconciler
  -> LogicalLines
  -> BlockSegmenter
  -> RuleEngine
  -> DisplayASTNormalizer
  -> ReadingRenderer
```

### TerminalStyledSnapshot

Captures one Ghostty projection with enough detail to explain Reading output:

- terminal width/height
- cursor position
- row index and stable row identity when available
- cell grapheme and display width
- foreground/background style
- bold/faint/italic/underline/inverse attributes
- selected/background-highlight state
- raw visible text per row

The current row summary style is useful for slash overlay, but Display AST requires cell/run-level data for CJK, table, and style-span fidelity.

### TerminalRowRuns

Normalizes cells into contiguous visible runs:

- joins adjacent cells with same style summary
- strips trailing blank cells while preserving source columns
- preserves grapheme boundaries and cell widths
- records raw text, normalized text, style summary, and source row/column range

### TerminalRowFeatures

Extracts stable terminal facts without knowing the agent provider:

- blank row
- indent level
- line marker: bullet, numbered list, checkbox, quote, prompt marker
- visible Markdown-ish markers: backticks, `**`, fences, headings, links
- divider candidates
- box drawing / ASCII table / pipe table candidates
- wrap candidates
- selected row candidates
- background block candidates
- status-like icon or warning-like prefix

### TranscriptReconciler

Terminal screen is a projection, not an append-only transcript. The reconciler owns stability:

- merges new snapshots into Penggie's turn store
- separates active mutable output from sealed history
- strips prompt echo duplication where Penggie owns submitted prompts
- detects overlap after viewport scroll or resize
- avoids treating old viewport rows as new transcript content
- keeps native overlay regions out of the transcript flow

### LogicalLines

Builds display logical lines from terminal physical rows:

- joins high-confidence soft wraps
- preserves hard breaks and blank rows
- does not claim to recover original hard/soft Markdown line breaks
- keeps source row/column ranges for debugging and fallback

### BlockSegmenter

Cuts logical lines into candidate blocks using hard boundaries first:

- user prompt
- native overlay/menu region
- approval/menu region
- fenced code block
- table/preformatted cluster
- divider-only row
- status/activity cluster
- blank-line paragraph break

### RuleEngine

Applies versioned rule packs and emits Display AST blocks with confidence.

Rule shape:

```swift
Rule {
  id
  phase: row | segment | block | ast
  priority
  mode: hard | heuristic | fallback
  predicate(context) -> Bool
  action(context) -> RuleResult
  confidenceDelta
}
```

Rule classes:

- **Hard rules**: deterministic evidence such as user prompt ownership, native overlay, visible fences, divider-only rows, explicit menu selection rows.
- **Heuristics**: evidence combinations such as pipe table clusters, Codex activity phrases, path-like cyan spans, indented code-ish output.
- **Fallback rules**: always preserve readable output as paragraph, preformatted, or raw fallback.

Confidence bands:

```text
>= 0.85 high
0.55 - 0.84 medium
< 0.55 low
```

Every emitted node stores rule hits and fallback reason if applicable.

## Display AST

### Document Shape

```swift
DisplayDocument
DisplayTurn
DisplayBlock
DisplaySpan
```

### Block Kinds

```text
userPrompt
paragraph
list
listItem
codeBlock
preformatted
table
warning
status
activity
toolEvent
disclosure
overlay
divider
rawFallback
```

### Span Kinds

```text
text
lineBreak
softBreak
code
emphasis
strong
link
path
command
statusToken
terminalStyled
```

### Required Metadata

```text
id
kind
role: user | assistant | system | tool | terminal
sourceRange: row/column range
sourceFingerprint
confidence
ruleHits
isLive
isSealed
renderHints
fallbackReason
```

This metadata is part of the implementation contract. Without it, adapter drift will be hard to debug.

## Adapter Strategy

Adapters must be layered so agent-specific rules cannot leak into generic terminal handling.

```text
TerminalFrameNormalizer
  -> GenericAnsiAdapter
  -> AgentAdapter
     -> CodexAdapter
     -> ClaudeAdapter (future)
     -> AiderAdapter (future)
```

### GenericAnsiAdapter

Handles cross-CLI facts:

- visible text
- row/column/cell widths
- blank rows
- indentation
- wrapping
- box drawing and dividers
- selected/background/faint/bold summaries
- cursor proximity
- contiguous menu-like regions
- raw/preformatted fallback

It must not know about `Codex`, `Worked for`, `gpt-`, `/model`, or any provider-specific command.

### CodexAdapter

Handles Codex display conventions:

- `Working`, `Worked for`, `Search`, `Read`, `Edited`, `Ran`
- Codex footer/session metadata
- slash/menu continuation shapes
- `/model` menu and continuation menu projection
- approval prompt shape
- Codex warning/status rows
- Codex chrome that can be hidden, collapsed, or rendered as activity

CodexAdapter still does not own command lists or selected indexes. It only interprets current terminal facts.

### Probe Result

Startup should produce an `AgentProbeResult`:

```text
provider: codex | claude | aider | unknown
executablePath
versionRaw
versionNormalized
themeMode: penggie-owned | cli-owned | unknown
capabilities: Set<AgentCapability>
rulePackID
confidence
```

Version is a hint; observed screen behavior is stronger. Unknown versions must fall back conservatively.

## Rule Pack Versioning

Rules are versioned as packs:

```text
codex/0.134/default
codex/0.x/fallback
unknown/generic
```

Each rule pack declares:

- provider
- version range
- expected terminal contract
- confidence thresholds
- fallback policy
- fixture set

CLI updates should add or adjust rule packs with fixture replay, not mutate behavior invisibly.

## Rendering Policy

Reading renderer consumes Display AST only. It should not re-parse terminal rows directly.

Rendering rules:

- `paragraph`, `list`, and high-confidence inline spans may use native Reading typography.
- `preformatted`, `table`, low-confidence code-ish output, box drawing, and CJK columnar output must use a cell-aware/monospace renderer.
- `warning`, `status`, `activity`, and `toolEvent` may be collapsed or styled, but must not hide final answers.
- `overlay` nodes are rendered through the native overlay path and are not inserted into the transcript flow.
- `rawFallback` must preserve all visible text and provide Raw Terminal fallback.

## Streaming, Resize, and Sealing

- Active turns are mutable; sealed turns are stable.
- Block IDs should use normalized source fingerprint + occurrence + turn identity, not physical row index alone.
- Resize may change wrapping but should not create duplicate transcript content.
- Fence/table/code clusters may start as medium/low confidence and upgrade when closed.
- The last live block can be recompiled; old sealed Display AST should be reused.
- Native overlay regions are ephemeral and must not be sealed as transcript content.

## Testing and Fixtures

Use multi-layer fixtures for each important scenario:

```text
fixtures/agent-terminal-display/<case-id>/
  manifest.json
  input.ansi
  ghostty-screen.json
  raw-text.txt
  display-ast.json
  reading-snapshot.json
  screenshots/
    terminal-light.png
    terminal-dark.png
    reading-light.png
    reading-dark.png
```

### P0 Fixture Families

- Markdown/prose: headings, lists, quotes, inline code, fenced code, links, mixed CJK.
- Tables: pipe tables, ASCII tables, box drawing tables, CJK wide character tables, long wrapped cells.
- CJK/Unicode: Chinese, Japanese, Korean, emoji, combining marks, full-width punctuation.
- Slash/model: `/`, `/m`, `/mo`, `/model`, continuation menus, arrow selection, Esc, Backspace.
- Overlay negative cases: historical `/model`, inline `hello /model`, leading-space ` /model`, answers listing slash commands.
- Approval: allow/deny prompt, selected option, multi-line approval text.
- Warnings/status: working/search/read/edited/rate-limit/permission-denied rows.
- Theme/style: light/dark/high contrast, ANSI 16/256/truecolor, bold/faint/inverse/background selection.
- Resize/viewport: 60/80/120/160 columns, live resize, viewport losing history.

### Acceptance Gates

Blocking failures:

- A real answer is classified as chrome/status/menu and hidden.
- Historical or ordinary `/model` text triggers native overlay.
- Approval prompt or selected choice is invisible or wrong.
- Theme color changes alter Display AST semantics.
- CJK/table output becomes unreadable in Reading.
- Resize duplicates or drops content.
- Reading and Raw Terminal no longer correspond to the same PTY state.

Allowed degradation:

```json
{
  "kind": "rawFallback",
  "confidence": "low",
  "fallbackReason": "unrecognized-screen-shape",
  "sourceRows": [12, 18]
}
```

Allowed fallback must preserve text, avoid false overlays, and keep Raw Terminal available.

## Migration Plan

1. Introduce Display AST types and rule metadata without changing visible behavior.
2. Build the terminal snapshot normalizer from current screen text/styled rows.
3. Move existing blockizer heuristics behind a first Codex rule pack.
4. Route Reading rendering through Display AST while preserving current transcript output.
5. Add preformatted/cell-aware rendering for table, box drawing, and CJK-sensitive blocks.
6. Add multi-layer fixtures and convert existing transcript/slash tests to AST-golden tests.
7. Expand Ghostty bridge from row summary to run/cell-level style data where needed.
8. Harden resize/streaming reconciliation and sealing rules.

## Ghostty Bridge Gaps

Current Penggie integration exposes enough data for v0.1 Reading and native slash overlay:

- `readScreenText()` / `readVisibleText()` provide terminal-projected visible text.
- `readScreenModelJSON()` provides row-level screen metadata used by native overlay selection.
- `PenggieTerminalScreenSnapshot.Line.StyleSummary` captures row-level selected/bold/faint/inverse/background/foreground counts.

Display AST needs a stricter terminal display contract before it can fully replace the existing Reading blockizer:

- **Cell runs**: each row should expose contiguous visible runs with grapheme text, start/end columns, display width, and style attributes.
- **Cell width**: CJK wide characters, emoji, combining marks, and box drawing must preserve terminal cell width rather than Swift proportional text width.
- **Style values**: foreground/background, bold, faint, italic, underline, inverse, selected/background-highlight should be carried as hints, not semantics.
- **Wrap identity**: soft-wrapped physical rows should be marked so LogicalLines can join high-confidence wraps without losing hard breaks.
- **Viewport identity**: screen vs viewport rows should be distinguishable enough for TranscriptReconciler to avoid scroll/resize duplicates.
- **Cursor/proximity**: cursor row/column and visibility should stay available for active composer, overlay, and approval prompt detection.
- **Stable diagnostics**: fixtures need a redacted JSON shape that records text, cell widths, runs, styles, and source ranges without leaking sensitive prompts by default.

Follow-up integration tasks:

1. Extend `ghostty_surface_read_screen_model` output or add a parallel bridge call that exposes per-cell/per-run style data.
2. Map the bridge payload into `TerminalStyledSnapshot` without routing it through Reading UI code.
3. Keep `PenggieTerminalScreenSnapshot` for native overlay until the new snapshot can prove exact parity for `/`, `/m`, `/model`, selection, Esc, and Backspace.
4. Add fixture capture tooling for raw screen text, screen model JSON, and normalized `TerminalStyledSnapshot`.
5. Validate that theme changes affect render colors only and do not change Display AST semantics.

## Open Questions

- How much cell-level style data can be exposed from the current Ghostty integration without taking on more Ghostty internals than necessary?
- Should fixtures store raw PTY ANSI bytes immediately, or begin with Ghostty screen JSON and add ANSI replay later?
- Which Codex CLI version range should become the first locked rule pack baseline?
- What diagnostic payload is acceptable for user bug reports without exposing prompts or sensitive terminal content?
