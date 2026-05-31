# Penggie Design Baseline

## Scene

A developer is using Penggie on a Mac desktop during real work. The ambient mood is focused and calm. The app should feel like a native utility with enough warmth from the Penggie identity, but the interface should stay out of the way of the conversation.

## Visual Direction

Penggie uses restrained product minimalism: tinted neutral surfaces, a single blue accent for primary actions, quiet borders, and system-native controls. The design should feel deliberate and desktop-grade, not decorative.

## Layout

- Use one native-feeling chrome strip for active session identity and controls.
- Reserve space around macOS traffic lights and keep identity aligned with the titlebar region.
- Reading content is a transcript flow, not a framed terminal canvas.
- Reading should feel like a calm work surface, not a chat app clone or beautified terminal screenshot.
- Avoid fixed-width layouts that break on narrow windows or larger system text.
- Keep composer width responsive with a readable maximum.
- Keep body copy line length around 65 to 75 characters on wide screens.
- Do not nest cards. Use cards only for composer, overlay, modals, and repeated items that need framing.

## Typography

- Use the macOS system font stack.
- Keep body text readable and calm, with clear weight contrast between user prompts, assistant answers, status rows, and secondary labels.
- Do not use negative letter spacing.
- Use tabular figures for timers such as `Working... 14s` and `Worked for 14s`.

## Color Tokens

Use semantic tokens rather than raw color decisions in components:

- `appBackground`: primary window background.
- `surface`: composer and overlay surface.
- `surfaceSubtle`: low-emphasis hover or selected backgrounds.
- `separator`: quiet dividers and hairlines.
- `textPrimary`: main conversation text.
- `textSecondary`: Codex label, status rows, and hints.
- `textMuted`: placeholders and disabled controls.
- `accent`: primary action blue.
- `accentText`: text or symbols on accent.
- `danger`: destructive confirmation and failure messaging.
- `terminalScene.canvasBackground`: Raw Terminal and terminal-owned native surface background.
- `terminalScene.chromeBackground`: chrome background when Raw Terminal is visible.
- `terminalScene.activeInputBackground`: Codex active input row emphasis.
- `terminalScene.tuiSelectedRowBackground`: Codex-owned menu current-row emphasis.
- `terminalScene.textSelectionBackground`: mouse text selection emphasis.
- `terminalRenderer.ansiPalette`: Ghostty 16-color palette generated from Penggie terminal scene tokens.

Never use pure `#000000` or `#FFFFFF` in new UI code. Tint neutrals slightly and verify contrast.

### Terminal Scene Tokens

Raw Terminal, Codex-owned native pickers, and terminal-mode chrome share a `terminalScene`. This is a scene-level design token group, not a Raw Terminal patch.

- `activeInput`, `tuiSelectedRow`, and `textSelection` are separate semantic states.
- Ghostty renderer config is generated from Penggie terminal scene tokens, including `background`, `foreground`, `cursor-*`, `selection-*`, and palette `0...15`.
- Built-in Ghostty theme names may be used only as fallback/reference data, not as Penggie's final visual source of truth.
- Terminal mode chrome should visually merge with the terminal canvas, with only a subtle separator.
- Reading composer and Reading transcript surfaces remain part of the Reading scene; they should not inherit terminal input styling.

## Components

### Window Chrome

- Left side: quiet current session folder name aligned near the traffic-light region.
- Right side: one destination mode icon. New Chat and Close Session live in the macOS menu and shortcuts unless a stronger visible affordance is needed.
- Session chrome should visually align with the macOS traffic lights and use titlebar-scale text and glyphs.
- Icon buttons need tooltips, accessibility labels, hover, focus, pressed, and disabled states.
- The mode icon shows the destination, not the current state.

### Reading

- Empty state centers a concise prompt and composer.
- Conversation state shows user prompts as right-aligned bubbles and assistant output as readable left-aligned content.
- Tool and working details may collapse under `Working... Ns` or `Worked for Ns`.
- Collapsing details must not remove or rewrite completed turns.
- The main answer should be separated from terminal chrome such as footers, transient working rows, menus, and status lines.
- Reading should prioritize trust, readability, continuity, low chrome, native feel, and then brand polish, in that order.
- Reading should use display-aware rendering for Markdown-ish output, tables, paths, code, and CJK content rather than assuming all terminal output is plain prose.
- Low-confidence terminal output should remain visible as raw or preformatted content instead of being hidden or over-interpreted.

### Composer

- Placeholder must never overlap IME marked text.
- The send affordance is disabled when there is no submittable text.
- Slash commands are triggered by typing `/`; do not add a fake command button in the composer.
- Composer focus, IME behavior, placeholder visibility, slash lifecycle, and key routing must feel stable before any visual polish is added.

### Session Folder

- The session folder is selected before starting an agent session.
- The first launch should require an explicit folder selection unless a valid last-used folder exists.
- Once an agent session starts, the folder is read-only for that session.
- Changing folders requires starting a new session.

### Raw Terminal

- Raw Terminal is a same-session fallback, not a separate product surface.
- Use Penggie-generated embedded Ghostty light/dark renderer themes sourced from `terminalScene` tokens.
- Do not fake Raw Terminal by rendering Reading transcript text; it must remain the real Ghostty PTY view.
- Theme changes must be applied through Ghostty configuration and app/surface color-scheme synchronization, not only through outer SwiftUI container color.
- Raw Terminal mouse text selection must remain distinct from Codex TUI current-row selection in token names and projection semantics.

### Native Slash Overlay

- Overlay rows come from the terminal screen model and styled rows.
- Selection state comes from terminal styles, not local index state.
- Overlay visual contrast should be clear enough to track keyboard navigation.
- Historical transcript text that mentions slash commands must never be treated as the active overlay.

### Terminal-Owned Selection Projection

All Codex-owned keyboard selection surfaces must share one projection model. This includes slash command menus, resume session pickers, model and effort pickers, permission prompts, approval choices, and any future terminal UI controlled by `↑/↓`, `Enter`, `Esc`, or `Tab`.

- Codex and Ghostty are the only source of truth for the menu rows and selected row.
- Penggie must not maintain local copies of Codex menu lists, session lists, model lists, approval choices, or selected indexes.
- Reading and Raw Terminal must project from the same live Ghostty surface and Codex PTY session.
- Selection should be inferred through the shared terminal projection path: visible `›` marker, explicit selected cells, inverse or selected style, foreground/faint contrast, cursor row, and contiguous menu region.
- Domain-specific surfaces may parse row labels for presentation, but selection detection must stay centralized and terminal-owned.
- Chat UI may display a syncing hint when selection confidence is low, but it must not invent a highlighted row or hide rows that are already visible in the terminal projection.
- Keyboard input for these surfaces must be forwarded to Codex through the existing Ghostty key path. Chat UI must not mutate local selection state in response to arrow keys.
- Any new keyboard-owned picker must include coverage proving that when Raw Terminal shows a selected row, the Chat UI projection highlights the same row.

## Chat UI Quality Bar

Penggie's chat UI should answer these trust questions clearly:

- Did the user's input go to the real Codex CLI?
- Is the agent waiting on model output, a tool, approval, terminal output, or recovery?
- Is the final answer readable without terminal noise?
- Can the same session be inspected in Raw Terminal?
- Are slash, model, and approval states sourced from the real terminal state?
- Does long history remain stable after terminal repaint, resize, or later turns?

Avoid these anti-patterns:

- Heavy message cards, nested card stacks, and decorative transcript framing.
- Local copies of Codex slash commands, model lists, or selected indexes.
- Fully expanded tool logs that bury the answer.
- Color-only state communication.
- Hiding real errors behind polished empty states.
- Treating Raw Terminal as a restarted or separate session.
- Pretending all terminal output is recoverable Markdown.

## Interaction Rules

- Reading to Terminal to Reading is a view switch only. It must not restart Codex.
- Raw Terminal must show the same PTY state and scrollback.
- Keyboard-owned Codex pickers must use terminal-owned selection projection rather than per-surface selected-index logic.
- New Chat and Close Session are destructive enough to require clear confirmation copy.
- Error states should use product language and offer a next action.

## Accessibility

- Icon-only buttons require accessibility labels and hints when useful.
- Focus states must be visible.
- Hit targets should be at least 44 x 44 pt.
- Text should wrap instead of clipping when possible.
- Do not rely on color alone to communicate state.

## Performance

- Avoid per-frame transcript reprocessing work that grows with total session length.
- Do not add layout work to the slash overlay path that can slow key navigation.
- Prefer incremental transcript ownership and stable identities for conversation turns.
