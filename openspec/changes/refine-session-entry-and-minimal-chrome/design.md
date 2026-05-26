## Context

Penggie v0.1 is a native macOS shell for a real Codex CLI session backed by Ghostty PTY. The validated core now depends on a simple invariant: Reading and Raw Terminal are two views over the same launched process. Once that process starts, its working directory is not a cosmetic preference; it is part of the CLI process environment and cannot be changed without restarting the session.

Recent UI work made the active chrome quieter, but the start flow still lets the user select Codex and launch in one gesture. That hides a consequential decision: which project folder the agent should run in. The start screen needs to make that choice explicit while staying Penggie-first and not turning valuable first-screen space into Codex promotion.

The design guidance from Impeccable, UI UX Pro Max, and Front End Design points to restrained product minimalism: native system typography, low chrome weight, explicit configuration before irreversible launch, no fake affordances, no decorative toolbar, and no changes to stable PTY/Reading/slash code paths.

## Goals / Non-Goals

**Goals:**

- Make session folder selection explicit before Codex launches.
- Keep Codex visible as the v0.1 agent CLI without presenting provider choice that does not exist.
- Start the Ghostty/Codex PTY only after the user activates a product-level `Create with Penggie` action.
- Display the active folder as read-only context after launch.
- Simplify active-session chrome to a native titlebar-scale mode switch.
- Remove the composer `/ commands` affordance because slash commands are already triggered by typing `/`.
- Preserve Reading transcript history, native slash overlay, Raw Terminal, PTY routing, and IME behavior.

**Non-Goals:**

- No multi-provider abstraction.
- No multi-session or multi-window behavior.
- No ability to change the working directory during an active session.
- No local slash command list, local selected index, or semantic parser.
- No redesign of Reading transcript ownership or block extraction.
- No change to Raw Terminal scrollback/source-of-truth behavior.

## Decisions

### 1. Use a configure-then-start start screen

The start screen will show three conceptual pieces:

1. Penggie-owned welcome/entry copy.
2. The selected v0.1 agent CLI (`Codex`) as informational provider context.
3. A session folder picker followed by a `Create with Penggie` action.

`Codex` should not launch immediately when clicked. The launch gesture is `Create with Penggie`, which only becomes valid once the session folder is known.

Rationale: selecting an agent and selecting a working directory are both pre-launch choices. Combining provider selection with launch hides the folder decision and makes it impossible to correct without restarting.

Alternative considered: keep Codex row as the launch button and open the folder picker if no folder exists. This is lower implementation cost, but it makes launch behavior conditional and surprising.

### 2. Treat working directory as a session invariant

The chosen folder is passed into the Ghostty/Codex launch path and then frozen for that session. The app may remember a previously selected folder for convenience, but the UI must still make the folder visible before launch.

Rationale: this matches CLI reality and avoids pretending Reading can re-home an active PTY process.

Alternative considered: add a folder selector in the active composer. This looks convenient, but it would either be a fake control or require a disruptive session restart from inside the chat surface.

### 3. Show active folder as titlebar context, not a mutable control

During an active session, the folder appears in the titlebar region as quiet context. The composer footer should not duplicate that path because it competes with input affordances and suggests the folder might be part of the prompt. It must not look like a mutable path selector unless it can perform a real, safe action. If changing folders is supported later, it should be an explicit New Chat/restart flow.

Rationale: active-session UI should answer “where is this agent running?” without suggesting mid-session mutation.

Alternative considered: hide the folder after launch. This is cleaner, but users need persistent confidence about the project scope they gave the agent.

### 4. Collapse active chrome to one destination icon

The titlebar-aligned chrome should remove redundant Penggie icon/provider text and keep one mode switch:

- In Reading, show a Terminal destination icon.
- In Terminal, show a Reading/chat destination icon.

The icon communicates where the button takes the user, not the current state. The current state is apparent from the content surface.

Rationale: this matches the user's desired minimal chrome and saves vertical space. It also keeps mode switching as a view switch over the same session, not a tabbed multi-session metaphor.

Alternative considered: keep a text segmented control. It is explicit, but it adds toolbar weight and repeats state already visible in the main surface.

### 5. Remove `/ commands` from composer

The composer footer should not show `/ commands` as a button or fake affordance. Slash command discovery is driven by typing `/`, which routes through the real Codex PTY and native overlay projection.

Rationale: fake or redundant controls damage trust. The source-of-truth slash behavior is already working and should remain input-driven.

Alternative considered: keep `/ commands` as a passive hint. This still looks clickable and competes with the folder context that now matters more.

### 6. Use a Penggie light theme for Raw Terminal

Raw Terminal remains a fallback view over the same Ghostty PTY, but it should no longer look like a separate dark-mode product. Penggie will load a small, controlled Ghostty config for the embedded session with a light background, dark foreground, readable ANSI palette, selection colors, and cursor colors.

Rationale: Raw Terminal is part of Penggie's product surface, not Ghostty's product shell. A light theme keeps the fallback visually coherent with Reading while preserving terminal semantics and scrollback.

Alternative considered: only change the SwiftUI container background. This is not enough because Ghostty renders its own terminal background and text palette. The correct layer is the Ghostty config loaded before surface creation.

## Risks / Trade-offs

- [Risk] Users may not understand why they must choose a folder before starting.  
  Mitigation: keep copy short and concrete: `Choose a project folder, then create with Penggie.`

- [Risk] Remembering a last-used folder can make the first step feel implicit again.  
  Mitigation: show the resolved folder before launch and allow changing it before `Create with Penggie`.

- [Risk] Icon-only mode switching can be less discoverable.  
  Mitigation: provide 44pt hit area, hover/focus/pressed states, tooltip, and accessibility label.

- [Risk] Folder selection changes can accidentally affect PTY/session behavior.  
  Mitigation: restrict launch-path changes to passing the chosen directory into existing session creation, then verify Reading, Raw Terminal, and slash behavior against the same session.

- [Risk] Composer footer changes could regress slash entry.  
  Mitigation: remove only the visible `/ commands` control; do not alter keyboard handling that detects typed `/`.

- [Risk] Raw Terminal light theme could reduce ANSI contrast.  
  Mitigation: define foreground/background/selection/cursor and a full 16-color palette in the embedded Ghostty config, then verify Codex output and slash state remain readable.

## Migration Plan

1. Add session-folder state to the session model if not already present.
2. Update the start screen to separate provider context, folder selection, and `Create with Penggie`.
3. Pass the selected folder to Codex/Ghostty launch and freeze it as active session context.
4. Update active chrome and composer footer presentation without touching transcript/slash internals.
5. Load the Penggie light terminal config before creating the Ghostty surface.
6. Run existing core tests and manual checks for:
   - start flow with selected folder,
   - Codex missing/launch failure states,
   - Reading prompt submission,
   - Raw Terminal same-session view,
   - `/`, `/m`, `/model`, arrow/Enter/Esc/Backspace,
   - IME placeholder behavior.

Rollback is straightforward: restore the prior start action and active chrome if the new entry flow creates unexpected launch regressions. The session-folder invariant should remain documented even if UI placement changes.
