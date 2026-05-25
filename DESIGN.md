# Penggie Design Baseline

## Scene

A developer is using Penggie on a Mac desktop during real work. The ambient mood is focused and calm. The app should feel like a native utility with enough warmth from the Penggie identity, but the interface should stay out of the way of the conversation.

## Visual Direction

Penggie uses restrained product minimalism: tinted neutral surfaces, a single blue accent for primary actions, quiet borders, and system-native controls. The design should feel deliberate and desktop-grade, not decorative.

## Layout

- Use one native-feeling chrome strip for active session identity and controls.
- Reserve space around macOS traffic lights and keep identity aligned with the titlebar region.
- Reading content is a transcript flow, not a framed terminal canvas.
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
- `terminalBackground`: Raw Terminal fallback background.
- `terminalText`: Raw Terminal fallback foreground.
- `selection`: native slash overlay selected row background.

Never use pure `#000000` or `#FFFFFF` in new UI code. Tint neutrals slightly and verify contrast.

## Components

### Window Chrome

- Left side: Penggie icon, `Penggie`, and quiet `Codex` session label.
- Right side: one destination mode icon, New Chat, Close Session.
- Icon buttons need 44 pt hit targets, tooltips, accessibility labels, hover, focus, pressed, and disabled states.
- The mode icon shows the destination, not the current state.

### Reading

- Empty state centers a concise prompt and composer.
- Conversation state shows user prompts as right-aligned bubbles and assistant output as readable left-aligned content.
- Tool and working details may collapse under `Working... Ns` or `Worked for Ns`.
- Collapsing details must not remove or rewrite completed turns.

### Composer

- Placeholder must never overlap IME marked text.
- The send affordance is disabled when there is no submittable text.
- Slash help is a hint, not a fake button, unless clicking it opens real native slash interaction.

### Native Slash Overlay

- Overlay rows come from the terminal screen model and styled rows.
- Selection state comes from terminal styles, not local index state.
- Overlay visual contrast should be clear enough to track keyboard navigation.

## Interaction Rules

- Reading to Terminal to Reading is a view switch only. It must not restart Codex.
- Raw Terminal must show the same PTY state and scrollback.
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
