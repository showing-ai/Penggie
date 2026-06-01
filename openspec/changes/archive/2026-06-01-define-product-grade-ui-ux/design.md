# Product-Grade Penggie UI/UX Contract

## Executive Summary

Penggie is a native macOS workbench for the complete local Codex CLI session.

The product promise is:

- **Readable:** Reading makes the work easier to follow than a terminal.
- **Trustworthy:** every meaningful action still belongs to the real Codex CLI/Ghostty PTY session.
- **Inspectable:** Raw Terminal can prove and control the same session at any time.
- **Recoverable:** errors, exits, projection uncertainty, and approval states have visible paths forward.
- **Native:** focus, keyboard, IME, titlebar, accessibility, density, and visual rhythm feel like a mature Mac app.

Penggie's differentiator is not a prettier chat UI. It is a product-quality projection layer over a real terminal-owned agent session.

### Principles Summary

This contract should not be read as a generic chat UI spec. Penggie is an agent workbench: the default surface is Reading, the underlying truth is the real Codex/Ghostty session, and Raw Terminal is the same-session audit/control surface.

- **Low chrome means low noise, not low discoverability.** Status, recovery, focus, approval, permission, and projection uncertainty must remain visible.
- **High density means organized hierarchy, not compressed text.** Use grouping, disclosure, spacing, and typography to keep long work scannable without damaging readability or accessibility.
- **Native does not mean locally owned.** Native overlays can feel like macOS controls, but rows, selection, confirmation, disabled state, and syncing state still come from terminal-frame evidence.
- **Readable does not mean Markdown recovery.** Reading may use Markdown-like presentation when evidence supports it, but Display AST is a display transcript compiler and must fall back to raw/preformatted output when confidence is low.
- **Inspectable does not mean terminal-first.** Users should not have to manage terminal details for ordinary work, but Raw Terminal must always be able to prove the same session when needed.

## Product Non-Negotiables

These are P0 UX invariants. Product polish must never weaken them.

1. **One real session.**
   Reading and Raw Terminal observe the same Codex process, cwd, PTY, Ghostty surface, terminal frame, and terminal-owned state.

2. **Terminal owns interaction truth.**
   Slash, model, effort, resume, approval, permission, modal choice, current row, and confirmability come from Codex/Ghostty terminal facts.

3. **Reading is a projection.**
   Reading improves comprehension of terminal-derived work. It is not a second agent UI and not a replacement runtime.

4. **Raw Terminal is an audit surface.**
   Raw Terminal is not a hidden fallback of last resort. It is the same-session visual truth and full-fidelity control path.

5. **Projection is evidence-based.**
   A native UI may display only what it can justify from terminal frame evidence, Display AST evidence, or an explicit future semantic source tied to the same session.

6. **Low confidence is visible.**
   When Penggie cannot prove rows, selection, answer boundaries, or display classification, it must show syncing/degraded/raw fallback instead of inventing state.

7. **Keyboard and IME integrity are core UX.**
   Enter, Shift-Enter, Esc, arrows, Tab, Backspace, paste, marked text, focus restoration, and Raw Terminal switching are first-order product behavior.

8. **Long-session durability is product quality.**
   Completed turns must not drift, duplicate, disappear, or rewrite unexpectedly after repaint, resize, view switch, or later output.

## Implemented Baseline

This document assumes the following already exists in the repository:

- Start/setup with project folder selection and `Create with Penggie`.
- Real Codex launch through embedded Ghostty PTY.
- Reading and Raw Terminal view switch over the same session.
- Minimal titlebar chrome with project folder identity and destination mode icon.
- Reading empty state, transcript, composer, send flow, Working/Worked state, disclosures, and raw/preformatted fallback.
- AppKit-backed composer with IME-aware marked text handling.
- Native terminal-owned overlays and full-page surfaces for slash/model/resume/approval-style interactions.
- Terminal frame, screen snapshot, terminal interaction surface, selection confidence, freshness, evidence, and input policy models.
- Display AST, terminal frame normalization, rule engine, renderer, transcript reconciler, and test coverage for core behavior.

The UX work is therefore productization: raising these primitives to a consistent, reviewable, launch-quality experience.

## Users, Jobs, And Work Modes

### Primary User

A developer or technical builder on macOS who wants the complete power of Codex CLI without living in a raw terminal for every turn.

### Core Jobs

- Start a trusted Codex session in the correct project folder.
- Read and act on agent output with less terminal noise.
- Use native-feeling slash/model/resume/approval flows without losing Codex truth.
- Inspect the real terminal when output, state, or selection is uncertain.
- Recover from missing CLI, failed launch, exited process, projection degradation, or approval/permission waits.
- Continue long sessions without transcript instability or keyboard/focus surprises.

### Work Modes

| Mode | User intent | Primary surface | Source of truth |
| --- | --- | --- | --- |
| Setup | Choose project and start Codex | Start/setup | Penggie session model |
| Reading | Do normal agent work | Reading transcript + composer | Codex/Ghostty session projected by Penggie |
| Native terminal-owned interaction | Select slash/model/resume/approval choices | Native overlay/full-page surface | Terminal frame and PTY key path |
| Inspect/control | Verify exact terminal state | Raw Terminal | Ghostty PTY visual state |
| Recovery | Understand and resolve failure | Product recovery state + Raw Terminal when inspectable | Session/process/terminal facts |

## End-To-End User Journeys

### First Launch Without Folder

1. User opens Penggie.
2. Start state shows Penggie identity, Codex as the active local agent CLI, and project folder selection.
3. `Create with Penggie` is disabled until a valid folder is selected.
4. Keyboard focus makes folder selection reachable before the primary action.
5. No terminal content leaks into the start state.

### Launch With Recent Folder

1. User opens Penggie with a valid last folder.
2. The folder is visible and changeable before launch.
3. `Create with Penggie` starts the real Codex CLI in that folder.
4. If the folder is invalid, Penggie explains the issue and returns to folder selection.

### Normal Reading Work

1. User submits a prompt in Reading.
2. Prompt appears as user-owned transcript content.
3. Working state appears quickly and quietly.
4. Tool/status details are summarized and collapsible.
5. Final assistant answer is readable without terminal footer/menu noise.
6. Composer becomes ready again only when terminal state is safe for prompt submission.

### Long Task With Inspection

1. User sees that Codex is working, running a tool, or waiting.
2. User expands details for context without losing answer position.
3. User switches to Raw Terminal to inspect exact output.
4. Raw Terminal shows the same session and current terminal state.
5. User returns to Reading without session restart, duplicate transcript, or lost composer state.

### Slash And Model Flow

1. User types `/` or `/m` as active composer input.
2. Penggie sends the text to Codex and projects terminal-owned candidates.
3. Arrows, Tab, Enter, Esc, Backspace, and typed filter text route to the PTY.
4. Reading highlight changes only after a fresh terminal frame proves the selected row.
5. If selected row is ambiguous or stale, Enter is blocked/consumed and a syncing hint is shown.

### Resume, Approval, And Permission Flow

1. Codex renders a terminal-owned full-page or modal choice surface.
2. Penggie projects it as a native full-page state when confidence is sufficient.
3. Candidate rows, metadata, footer help, selected row, and confirmability come from terminal facts.
4. Approval/permission choices are never hidden inside ordinary transcript blocks.
5. Low-confidence state keeps candidates visible, blocks unsafe confirmation, and preserves Raw Terminal inspection.

### Failure And Recovery

1. Codex missing, launch failed, process exited, or projection degraded is shown as a product state.
2. The state explains what happened and what the user can do next.
3. If a terminal session exists, Raw Terminal remains available for inspection.
4. Penggie never silently restarts Codex or hides the failure behind an empty state.

## Information Architecture

```text
Penggie Window = Project Session Container

  Start / Setup
    Folder identity
    Codex readiness
    Create with Penggie
    Recovery for invalid folder / missing Codex

  Active Session
    Titlebar chrome
      Folder identity
      Destination mode switch
      Session actions through menu / confirmation

    Reading
      Transcript
        User prompt
        Working / tool summary
        Assistant answer
        Collapsible details
        Raw/preformatted fallback
      Composer
      Composer-attached terminal-owned overlay

    Full-page terminal-owned surface
      Resume
      Approval / permission / modal choice
      Low-confidence sync state

    Raw Terminal
      Same Ghostty surface
      Same Codex process
      Full terminal scrollback and live TUI

  Recovery
    Missing Codex
    Launch failed
    Process exited
    Projection degraded
    Confirmation for New Chat / Close Session
```

### IA Rules

- The window represents one project session, not a generic page stack.
- Reading and Raw Terminal are destinations inside the same session, not separate sessions.
- Full-page terminal-owned surfaces temporarily replace the Reading transcript region, not the session chrome.
- Composer-attached overlays are used for slash/model/effort surfaces tied to active input.
- Recovery states must preserve project/session identity whenever possible.

## State Matrix

| State | User sees | Allowed actions | Blocked actions | Keyboard owner | Raw Terminal | Recovery |
| --- | --- | --- | --- | --- | --- | --- |
| No folder | Start state, folder picker, disabled create | Choose folder | Create session | Penggie | Hidden | Select valid folder |
| Ready | Start state with valid folder | Change folder, create | Raw Terminal | Penggie | Hidden | Create session |
| Checking Codex | Start held with progress | Wait; app/window system controls only | Prompt, folder change, Raw Terminal, New Chat, Close Session | Penggie | Hidden | Missing CLI state or launch transition |
| Launching | Start held, launching copy | Wait; app/window system controls only | Prompt, folder change, Raw Terminal, New Chat, Close Session | Penggie | Hidden | Launch failure state or Reading |
| Reading idle | Empty/transcript + composer | Prompt, slash, switch Terminal, New Chat, Close | None except invalid send | Composer | Available | Normal work |
| Composing | Composer text/draft | Type, paste, Enter, Shift-Enter, slash trigger | Unsafe terminal-owned confirm | Composer | Available | Submit or edit |
| Agent running | Transcript + working/tool status | Inspect details, switch Terminal | New prompt until Codex returns to Reading idle | Penggie unless terminal-owned surface appears | Available | Wait, inspect, or handle surfaced terminal-owned request |
| Tool running | Tool summary/detail | Expand details, switch Terminal | Prompt until Codex returns to Reading idle | Penggie unless terminal-owned surface appears | Available | Wait, inspect, or handle surfaced approval/permission |
| Terminal-owned interaction | Native overlay/full-page surface | Arrow/Tab/Esc/Enter/text through PTY | Local selection mutation, ordinary prompt send | Codex via PTY | Available | Confirm, cancel, or inspect |
| Approval needed | Approval surface | Choose via PTY, inspect Terminal | Hidden auto-approval, local confirm | Codex via PTY | Available | Approve, deny, cancel |
| Projection degraded | Raw/preformatted/syncing state | Inspect Terminal; read preserved fallback content | Fabricated semantic rendering, fabricated selection, unsafe confirm | Penggie/terminal | Available | Continue through Raw Terminal or preserved fallback only |
| Raw Terminal visible | Ghostty surface | Terminal input, switch Reading | Separate session start | Ghostty/Codex | Active | Switch back or continue terminal |
| Process exited with terminal surface | Ended state + inspect option | Inspect Raw Terminal, start again, close | Prompt old process | Penggie | Available | Start New Chat or Close |
| Process exited without terminal surface | Ended state only | Start again, close | Prompt old process, Raw Terminal | Penggie | Hidden | Start New Chat or Close |
| Launch failed | Error state | Retry, choose another folder, close | Prompt, Raw Terminal when no session exists | Penggie | Hidden unless a terminal surface exists | Fix cause and retry |
| Confirm close/new | Confirmation dialog/sheet | Confirm/cancel | Background destructive action | Penggie modal | Preserve current availability | Cancel or complete |

## macOS Interaction Matrix

| Interaction | Expected behavior |
| --- | --- |
| Tab order | Folder/action controls in setup; chrome controls; transcript details; composer; overlay rows only when active. |
| Enter in composer | Submit prompt when no marked text, no terminal-owned interaction, and text is submittable. |
| Shift-Enter | Insert newline or preserve native multiline behavior; never submit marked text. |
| Enter in terminal-owned surface | Confirm only with fresh, exactly-one, confirmable terminal-owned selection; otherwise block/consume. |
| Esc | Cancel terminal-owned interaction through PTY; dismiss confirmation dialogs; never erase completed transcript. |
| Arrows/Tab/Backspace in terminal-owned surface | Route to Codex through PTY and wait for next frame before changing UI selection. |
| Cmd+V | Paste into focused composer or terminal-owned input path; large paste should not break focus or marked text. |
| Raw Terminal switch | Preserve session, cwd, scrollback, current picker, and process state. |
| Return to Reading | Restore Reading/composer focus only if no terminal-owned surface requires capture. |
| IME marked text | Placeholder hidden; SwiftUI state does not overwrite AppKit marked text; send disabled until text is committed. |
| Window resize | Transcript and overlays reflow without content overlap, duplicate turns, or lost selection evidence. |
| Close/New Chat | Destructive enough to require confirmation and clear copy. |

### Focus State Machine

| Transition | First responder after transition | Must not happen |
| --- | --- | --- |
| Setup opens with no folder | Folder picker action or first setup control | Focus lands on disabled create action |
| Setup opens with valid folder | `Create with Penggie` is reachable after folder control; default action may be create | Folder path is hidden from keyboard/VoiceOver |
| Reading idle appears | Composer receives focus after display-ready state | Composer focuses before terminal-owned startup/resume state is resolved |
| User starts native slash/model interaction | Invisible key capture for the terminal-owned surface receives focus | Text remains in local composer while Codex owns the interaction |
| Terminal-owned surface dismisses to Reading idle | Composer receives focus after a fresh terminal frame proves ordinary Reading state | Focus restored while surface is still active or low confidence |
| Full-page resume/approval/permission appears | Full-page key capture receives focus; VoiceOver announces surface title and selected row | Background transcript controls remain reachable as active controls |
| Raw Terminal opens | Ghostty terminal view receives keyboard focus | Local composer captures terminal keystrokes |
| Raw Terminal returns to Reading | Terminal-owned key capture if a surface is active; otherwise composer | Draft is submitted, erased, or duplicated by view switch |
| IME composition active | AppKit composer keeps first responder until marked text is committed or canceled | SwiftUI text binding overwrites marked text |
| Confirmation opens | Confirmation dialog traps focus until confirm/cancel | Background terminal-owned Enter remains confirmable |

Reverse traversal with Shift-Tab follows the same containment rules. Modal confirmations and full-page terminal-owned surfaces trap focus inside their active surface until they are dismissed or replaced by a new terminal frame.

## Component Specs

### Window Chrome

- Titlebar-scale, low chrome, aligned around macOS traffic-light safe area.
- Shows project/session folder identity with full path tooltip.
- Contains one destination mode icon: show where the user can go, not a tab strip competing with titlebar.
- Titlebar chrome owns project/session identity. Model/status summaries, if shown later, must be lightweight terminal-derived session status and should not crowd the titlebar or become Penggie-owned model state.
- Session actions such as New Chat and Close Session live in menu/shortcut/confirmation flows unless a stronger visible affordance is later justified.
- Icon-only controls require label, tooltip, accessibility label, hover, pressed, focus, and disabled states.

### Start / Setup

- Product identity is Penggie-first, Codex-specific for current scope.
- Folder selection is the main required setup task.
- Invalid/missing folder states are explained before launch.
- No terminal content or startup noise should appear in the start surface.
- The start screen should feel like a mature utility entry point, not a provider launcher placeholder.

### Reading Transcript

Turn anatomy:

```text
User prompt
  Working / tool summary
  Assistant answer
  Collapsible operational detail
  Raw/preformatted fallback when needed
```

Rules:

- Assistant answer is the main content. Tool logs support it; they do not dominate by default.
- Completed turns are sealed and stable unless there is explicit evidence to reconcile the same turn.
- Active terminal-owned surfaces are excluded from permanent transcript blocks.
- Terminal footer, model/status line, menus, and active input rows should not pollute final answers.
- Low-confidence display classification preserves visible text and source traceability.
- Table, box drawing, code, and CJK-sensitive content may use monospace/preformatted/cell-aware rendering.

### Composer

- Composer is a prompt/input surface, not a local command palette.
- Placeholder is not a label; it must disappear for visible or marked text.
- Send button state follows submittable content and session readiness.
- Visual height grows within bounded limits and then scrolls internally.
- Draft state should survive incidental focus changes and Reading/Raw Terminal round trips where possible.
- Slash lifecycle starts only from active composer/input state, not from historical transcript text.

### Tool Disclosure

- Tool summaries are compact, near the turn, and collapsed by default when verbose.
- Expanded detail uses readable monospaced formatting with enough contrast.
- Local Working/Worked timing is quiet and tabular.
- Details should not introduce nested card stacks or compete with the final answer.

### Native Terminal-Owned Surface

One interaction system covers slash suggestions, slash continuation, model picker, effort picker, resume picker, approval prompts, permission prompts, modal choices, and future terminal-owned pickers.

Shared properties:

- Surface kind.
- Terminal frame id.
- Candidate rows.
- Selected-row id if proven.
- Selection confidence.
- Freshness.
- Confirmability.
- Evidence list.
- Metadata such as filter, sort, pager, or help text.

Selected-row proof must include frame id, candidate row id, source row/column or line index, evidence kind, freshness, and confidence. Evidence kinds include visible marker, screen-model marker, selected/inverse/background style, foreground/faint contrast, cursor row, and contiguous region inference. A navigation key may set a waiting-for-terminal-frame state, but it must not move the visible highlight locally before a fresh frame proves the new row.

Presentation:

- Composer-attached overlay for slash/model/effort surfaces.
- Full-page centered surface for resume and approval/permission/modal choices.
- Candidate rows share typography, spacing, selected state, overflow indicators, low-confidence hints, and help text rhythm.
- Unsafe confirmation is visibly disabled or blocked.
- Low-confidence state says syncing rather than pretending the surface is broken.

Candidate row states:

| State | Visual | Accessibility value | Confirm behavior |
| --- | --- | --- | --- |
| Default | Normal row text, no marker, no selected background | Not selected | Not confirmed unless terminal later selects it |
| Selected fresh | Marker or selected background plus stronger text weight | Selected, confirmable or selected, unavailable | Enter routes to PTY only if confirmable |
| Selected stale | Prior visible row may be shown only with syncing treatment, not as authoritative highlight | Selection updating | Enter blocked/consumed |
| Disabled/unconfirmable | Muted text plus non-color affordance such as unavailable label | Unavailable | Enter blocked/consumed |
| Low confidence | Rows remain visible with syncing hint and no authoritative selected row | Selection unknown | Enter blocked/consumed |
| Overflow | Leading/trailing overflow indicator, not selectable | More rows available | Navigation routes to PTY |

Surface density rules:

- Composer-attached overlays show up to five visible candidates before overflow treatment.
- Full-page resume surfaces show enough rows for browsing without pushing help text out of view.
- Approval and permission surfaces prioritize the prompt and choices over decoration; the safest/default-looking choice must still come from terminal-selected state, not product opinion.
- Help text uses one concise row and never replaces actual terminal choices.

### Raw Terminal

- Shows the real Ghostty surface, not a reconstructed transcript.
- Uses Penggie terminal scene colors without flattening terminal style fidelity.
- When active during a picker/approval/model state, it is the same controllable surface Reading would project.
- After process exit, Raw Terminal can remain inspectable if the surface exists.

### Recovery States

- Error copy includes: what happened, why it matters, and the next action.
- Codex missing, launch failed, process exited, projection degraded, and invalid folder must have distinct language.
- Recovery states should preserve project identity and avoid generic empty-state polish.

## Terminal Source-Of-Truth Contract

```text
TerminalSource
  real Codex process
  Ghostty PTY bytes
  screen model / styled rows
  keyboard event path
  current terminal-owned state

NativeInteractionSurface
  projected candidates
  selected row confidence
  freshness / confirmability
  low-confidence fallback

Display AST
  readable transcript blocks
  table/code/CJK display preservation
  source range / rule hits / fallback reasons

Raw Terminal
  same-session visual truth
```

Display AST is not a Markdown recovery layer, not a semantic source, and not a control/selection authority. It compiles terminal display evidence into Reading blocks with confidence and fallback metadata. It must not override terminal-owned interaction surfaces, invent omitted Markdown syntax, or decide command/model/approval state.

Future `SemanticSource` may enhance Reading answer/tool rendering only if it is bound to the same active session. It must not drive slash/model/resume/approval/permission state, replace Raw Terminal parity, create a second agent session, take over transcript segmentation when terminal evidence is low confidence, or suppress raw/preformatted fallback that preserves visible terminal text.

## Design System Contract

### Token Layers

- **Primitive tokens:** base colors, spacing scale, radii, shadows, font sizes.
- **Semantic tokens:** textPrimary, textSecondary, accent, danger, separator, surface, disabled, focus.
- **Scene tokens:** Reading scene, terminal scene, overlay scene, recovery scene.
- **Component tokens:** chrome button, composer, transcript block, disclosure, overlay row, selected row, error state.

### Theme Model

- Light and dark themes are designed as paired themes, not inverted colors.
- Reading, terminal, overlay, and recovery scenes each resolve their own background, foreground, separator, focus, selected, warning, danger, and muted tokens.
- Terminal scene tokens generate Ghostty renderer configuration. Reading tokens must not flatten terminal ANSI/SGR style facts.
- Theme changes must not change Display AST classification, selected-row inference, command semantics, or safety decisions.

### Contrast And Scales

- Normal text contrast target: at least 4.5:1 against its immediate background.
- Large title/icon contrast target: at least 3:1.
- Focus ring contrast target: at least 3:1 against adjacent surfaces.
- Disabled text may fall below normal text contrast only when accompanied by disabled semantics and no critical information depends on it.
- Spacing uses a 4 pt base scale with 8 pt grouping rhythm.
- Radius scale: 6 pt for small row states, 8 pt for repeated content/detail blocks, 12 pt for composer/overlay, 16 pt max for modal/recovery surfaces unless a platform control requires otherwise.
- Elevation scale: no shadow for transcript content; subtle shadow only for composer, overlay, modal, or recovery surfaces that float above the transcript.

### Component Token Examples

| Component | Required tokens |
| --- | --- |
| Chrome button | foreground, hoverBackground, pressedBackground, focusRing, disabledForeground |
| Composer | background, border, text, placeholder, insertionPoint, disabledText, sendEnabled, sendDisabled |
| Transcript answer | textPrimary, codeBackground, preformattedText, linkText, mutedMetadata |
| Tool disclosure | summaryText, detailBackground, detailBorder, chevron, expandedFocus |
| Overlay row | rowForeground, rowBackground, selectedForeground, selectedBackground, disabledForeground, syncingText |
| Recovery state | icon, titleText, messageText, primaryAction, secondaryAction, dangerAction |

### Visual Direction

- Quiet, precise, work-focused, native macOS utility.
- Restrained neutral surfaces with a single primary accent.
- Low chrome and high information density, with the explicit meaning that essential state remains discoverable and text is not compressed below readable/accessibility-safe density.
- Cards only where framing is functionally needed: composer, overlay, modal, repeated candidate rows.
- No nested cards, decorative gradients, blobs, heavy brand panels, or marketing hero layouts in the work surface.
- Penguin identity appears in app icon, start state, and occasional recovery/empty states; not as repeated transcript ornament.

### Layout And Density

- Reading content max width should support 65-75 character prose on wide windows.
- Composer max width should remain comfortable for prompt drafting.
- Overlays should not occlude critical transcript context unless they are full-page terminal-owned surfaces.
- Narrow windows, large text, and CJK content must wrap or fall back cleanly.
- Horizontal scrolling is acceptable for preformatted table/code content, not for the whole app.
- Density is achieved through hierarchy, inline disclosure, quiet metadata, and stable spacing. It must not be achieved by shrinking body text, removing focus affordances, hiding state, or overloading the titlebar.

### Typography

- Use macOS system typography.
- Body and transcript text must be readable under long sessions.
- Use monospaced text for code, terminal fallback, tables, and tool detail.
- Use tabular figures for timers and durations.
- Do not use negative letter spacing or viewport-scaled font sizes.

### Motion

- Motion is state continuity only: opening disclosure, switching surfaces, focus affordance.
- Animations should be short, interruptible, and disabled/reduced for reduced motion.
- No decorative animation in transcript or terminal-owned state.

## Accessibility Contract

- Every icon-only button has accessibility label, hint when useful, tooltip, focus state, and minimum practical hit area.
- Candidate rows expose selected/unselected and disabled/unconfirmable state to accessibility.
- Disclosure controls expose expanded/collapsed state.
- Error states are announced as states with actionable next steps.
- VoiceOver reading order follows visual task order: chrome, main state/transcript, details, composer/overlay.
- Keyboard-only users can complete setup, prompt submission, slash/model flows, resume, approval/permission, Raw Terminal switch, retry, New Chat, and Close Session.
- Color is never the only state indicator.
- Dynamic type/larger text should not clip core controls; text wraps before truncating except known bounded metadata.
- Reduced motion is respected.

### Accessibility Component Contract

| Component | Role/name | Value/state | Action/announcement |
| --- | --- | --- | --- |
| Mode toggle | Button, `Show Raw Terminal` or `Show Reading` | Enabled/disabled; focused when keyboard targeted | Activates destination switch; announces destination, not current mode only |
| Folder picker | Button, `Choose Project Folder` | Current abbreviated path, invalid/missing when applicable | Opens folder chooser; invalid folder error announced near control |
| Create action | Button, `Create with Penggie` | Disabled until valid folder; busy while checking/launching | Starts session; busy state announced when launch begins |
| Composer | Text area, `Ask Codex anything` | Draft text, marked text composition, disabled when Codex owns input | Enter submits only when allowed; marked text changes not announced as submitted |
| Send button | Button, `Send` | Disabled when no submittable text or terminal-owned surface blocks prompt | Sends prompt; disabled reason available through hint when practical |
| User prompt block | Static text/group, `User prompt` | Prompt content | Read in transcript order |
| Assistant answer block | Static text/group, `Assistant answer` | Content role; code/preformatted blocks identifiable | Read after related prompt/status in transcript order |
| Tool disclosure | Disclosure button | Expanded/collapsed, summary text | Toggles detail; expanded detail follows immediately in reading order |
| Overlay candidate row | Option/list row | Selected/not selected, confirmable/unavailable, syncing/unknown when applicable | Enter routed through PTY only when fresh confirmable selection exists |
| Approval/permission surface | Dialog-like group | Prompt title, selected choice, confidence/syncing state | Announces required decision; Esc/cancel and Enter/confirm behavior follow PTY policy |
| Raw Terminal | Terminal region | Active/inactive, process exited when applicable | Receives keyboard focus when visible; Reading controls are not active inside terminal focus |
| Error/recovery state | Alert/status group | Error type and message | Announces actionable next step and primary retry/close action |
| New Chat command | Menu item/command, `New Chat` | Available only with inspectable session | Opens confirmation; does not immediately discard session |
| Close Session command | Menu item/command, `Close Session` | Available only with inspectable session | Opens confirmation; destructive action requires explicit confirm |
| Retry action | Button, `Try Again` or `Check Again` | Enabled in launch/missing/error states | Re-enters checking/launching state and announces progress |
| Confirmation primary action | Button with destructive action label | Destructive; focused only inside confirmation | Confirms New Chat/Close; announces resulting state |
| Confirmation secondary action | Button, `Cancel` | Default safe escape | Dismisses confirmation and restores previous focus owner |

Dynamic type failure condition: no primary control, candidate text, error message, or composer content may clip without tooltip/expansion or fallback wrapping. If a row must truncate bounded metadata, the full value must remain available through accessibility value or help text.

### Dynamic State Announcements

| State change | Announcement style | Announcement content |
| --- | --- | --- |
| Checking Codex begins | Polite status | `Checking Codex CLI` |
| Launching begins | Polite status | `Starting Codex session` |
| Reading becomes ready | Polite status | `Codex session ready` |
| Working starts | Polite status, throttled | `Codex is working` |
| Tool running appears | Polite status | Tool/activity summary when available |
| Approval required | Assertive alert | `Approval required` plus current choice summary |
| Permission required | Assertive alert | `Permission required` plus current choice summary |
| Projection degraded | Polite status | `Reading projection degraded; raw terminal is available` |
| Selection becomes low confidence | Polite status | `Selection syncing; confirmation unavailable` |
| Process exited | Assertive alert | `Codex session ended` |
| Launch failed / Codex missing | Assertive alert | Error title and primary recovery action |
| Confirmation opened | Assertive alert | Dialog title and destructive action name |

## Performance And Long-Session Stability

- Terminal polling and Reading reconciliation must avoid full-history expensive work on every frame.
- Native overlay projection must stay responsive during arrow-key navigation.
- Transcript identities must be stable enough for SwiftUI diffing, scroll position, and disclosure state.
- Raw/preformatted fallback should not perform unbounded layout on long scrollback.
- Switching Reading/Raw Terminal must not trigger replay, duplicate transcript hydration, or session restart.

## Anti-Patterns

- A local slash/model/approval mirror that looks native but drifts from Codex.
- Local selected index changed immediately on arrow key before a terminal frame confirms it.
- A second `codex exec --json`, SDK, or headless session used as the real user session while Raw Terminal shows a different process.
- Treating ANSI colors as stable semantic truth.
- Hiding low-confidence output to make Reading look cleaner.
- Showing Raw Terminal as a separate Ghostty.app shell with Ghostty product chrome.
- Making Reading a terminal screenshot inside a card.
- Making Penggie a generic web chat, IDE, terminal replacement, multi-provider launcher, or session dashboard before the Codex workbench is mature.

## QA Matrix

| Area | Acceptance criteria |
| --- | --- |
| Session truth | Reading and Raw Terminal share one Codex process, cwd, PTY, model state, and terminal-owned surface. |
| Launch | No terminal startup noise leaks into start/setup; missing/failed Codex states are specific and actionable. |
| Folder identity | User can identify the active project folder in setup and active session; invalid folder blocks launch clearly. |
| Reading answer | Final assistant answer is readable without terminal footer/menu/status pollution. |
| Tool detail | Tool output is available but collapsed/summarized enough that it does not bury the answer. |
| Long session | Repaint, resize, later turns, and view switches do not duplicate, delete, or rewrite completed turns. |
| Raw Terminal parity | Switching to Raw Terminal never restarts or forks Codex and shows the same current state. |
| Slash/model | `/`, `/m`, `/model`, arrows, Enter, Esc, Backspace, and Tab route through the PTY; no local command table or selected index. |
| Resume/approval | Candidates, selection, and confirmation are derived from terminal facts; unsafe Enter is blocked. |
| Low confidence | Ambiguous/stale selection or display classification shows syncing/raw fallback and does not fabricate certainty. |
| Composer | IME marked text, placeholder, Enter, Shift-Enter, paste, send disabled state, and focus restore behave reliably. |
| CJK/table/code | Terminal-sensitive output remains readable and aligned through cell-aware/preformatted fallback when needed. |
| Accessibility | Keyboard-only and VoiceOver users can complete primary setup, Reading, overlay, Raw Terminal, and recovery flows. |
| Visual maturity | Low chrome, restrained surfaces, clear hierarchy, no nested cards, no decorative gradients/blobs, no brand overuse. |
| Recovery | Missing CLI, launch failed, exited process, projection degraded, and close/new confirmation each have clear next action. |

## Scenario QA Scripts

| Scenario | Fixture / setup | Trigger | Pass criteria | Fail criteria |
| --- | --- | --- | --- | --- |
| No folder state | Clear saved folder / invalid defaults | Open Penggie | Folder picker visible; `Create with Penggie` disabled; Raw Terminal hidden | Create enabled or terminal visible |
| Ready state | Valid saved folder | Open Penggie | Folder visible; `Create with Penggie` enabled; user can change folder before launch | Folder hidden or launch action named `Start with Codex` |
| Start CTA naming | No active session | Open setup | Primary action is `Create with Penggie`; no `Start with Codex` user-facing copy remains in current UX path | Both labels appear as competing actions |
| Session controls IA | Active Reading session | Inspect chrome and menus | Chrome shows folder identity and destination mode; New Chat/Close Session are session commands with confirmation, not heavy toolbar buttons | Destructive controls appear as unconfirmed primary chrome actions |
| Checking/launching | Valid folder, Codex check in progress | Start session | Setup is held; prompt, folder change, Raw Terminal, New Chat, Close Session are unavailable | User can type prompt or switch Raw Terminal before inspectable session exists |
| Missing Codex | Codex unavailable in PATH | Create session | Missing-Codex state appears with `Check Again`; no Reading/composer shown | User is dropped into terminal output or empty Reading |
| Launch failed | Force launch failure | Create session | Launch-failed state includes actionable message, retry, and folder recovery path | Failure hidden behind spinner or generic empty state |
| Reading idle | Stable Codex session, no prompt | Reach display-ready state | Empty/transcript surface and composer ready; Raw Terminal available | Composer disabled despite idle, or Raw Terminal unavailable |
| Composing | Reading idle | Type ordinary text and Shift-Enter | Draft persists, newline behavior is native, send enabled only for submittable committed text | Marked text submits or placeholder overlaps |
| Agent running | Submit long prompt fixture | Observe turn | Working status visible; prompt blocked until Codex returns idle; Raw Terminal available | Second prompt sends while terminal not ready |
| Tool running | Tool/activity fixture | Observe turn | Tool summary visible, details expandable, answer remains primary | Tool logs bury final answer by default |
| Raw Terminal round trip | Active session with transcript and draft | Switch Terminal then Reading | Same process/cwd/state; draft not submitted/erased; no transcript replay | Codex restarts, transcript duplicates, or draft changes unexpectedly |
| Slash/model selection | Active Reading composer | Type `/m`, press Down | Highlight changes only after fresh terminal frame evidence | UI moves highlight immediately from local index |
| Resume picker | Resume picker terminal fixture | Render Reading projection | Full-page resume surface shows rows/filter/sort; selected row proof-backed; unsafe Enter blocked when stale | Resume rows become transcript or local selection moves |
| Approval prompt | Approval terminal fixture | Render Reading projection | Approval surface is explicit; choices and selected state terminal-backed; unsafe confirm blocked | Approval prompt hidden in transcript or auto-confirmed |
| Stale selection | Surface rows visible, no fresh selected row | Press Enter | Enter blocked/consumed; syncing state visible | Enter submits composer text or confirms unknown row |
| Permission prompt | Terminal permission surface fixture | Project in Reading | Permission prompt is separate from approval/resume, choices visible, unsafe confirm blocked when selection uncertain | Permission prompt is hidden in transcript or merged into generic approval without safety semantics |
| Projection degraded | Low-confidence terminal frame fixture | Render Reading | Syncing/degraded/raw fallback visible; Raw Terminal audit available; no fabricated semantics | Output hidden or confident semantic rendering invented |
| Display AST fallback | Table/CJK/box drawing fixture | Render Reading | Visible text preserved with preformatted/cell-aware fallback and Raw Terminal audit path | Output hidden, over-interpreted as Markdown, or alignment destroyed without fallback |
| Semantic source future guard | Semantic answer exists, terminal evidence low confidence | Render Reading | Semantic data may enhance but does not suppress raw/preformatted fallback or drive terminal-owned surfaces | Semantic data replaces uncertain terminal evidence as control truth |
| Accessibility overlay | Terminal-owned surface active | VoiceOver through rows | Rows expose selected/unavailable/syncing values and do not allow unsafe confirm | VoiceOver reports all rows as ordinary text with no state |
| Dynamic type | Large text enabled | Open setup, Reading, overlay, recovery | Core controls wrap or resize without clipping; bounded truncation has accessible full value | Primary action, composer, candidate row, or error copy clips invisibly |
| Focus restore | Active terminal-owned surface, Raw Terminal switch, IME draft | Switch views and dismiss surface | First responder follows focus state machine; marked text preserved | Composer steals focus from terminal surface or marked text is overwritten |
| Process exited with inspectable terminal | Active session exits after terminal surface exists | Wait for exit | Ended state explains exit; Raw Terminal inspect available; old prompt blocked | App silently restarts or allows prompt to dead process |
| Process exited without terminal surface | Launch exits before inspectable terminal | Wait for exit | Ended state offers start again/close; Raw Terminal hidden | Raw Terminal opens to empty/stale surface |
| Confirm New Chat | Active session | Invoke New Chat command | Confirmation traps focus; cancel restores previous state; confirm closes old session before creating new one | New session starts without confirmation |
| Confirm Close Session | Active session | Invoke Close Session command | Confirmation traps focus; cancel restores previous state; confirm closes session and returns closed/start state | Session closes from background command without confirmation |

## Productization Gaps

These are the gaps to review against the current implementation, not proof that the underlying capability is absent:

- Start/setup maturity: whether it feels like a finished Penggie entry point rather than a provider selector.
- Session identity: whether folder/cwd and same-session continuity are visible enough without adding toolbar weight.
- Reading hierarchy: whether answer, tools, timing, and raw fallback are balanced in real long tasks.
- Overlay consistency: whether slash/model/resume/approval/permission feel like one terminal-owned interaction system.
- Low-confidence language: whether syncing/degraded states are understandable and not alarming.
- Raw Terminal round trip: whether focus, draft, scrollback, picker state, and transcript stability feel seamless.
- Recovery copy: whether each failure state is specific, actionable, and inspectable.
- Accessibility coverage: whether labels, focus, selected values, dynamic type, reduced motion, and keyboard-only flows are complete.
- QA coverage: whether manual and automated tests cover user-visible journeys, not only parser/projection units.

## Open Questions

- Which productization gaps are launch-blocking for the first public Penggie release?
- How much project/session history should appear in setup without turning Penggie into a session dashboard?
- What is the exact copy style for low-confidence projection: quiet technical hint, inline warning, or explicit fallback banner?
- Which future semantic source, if any, can enrich Reading while remaining bound to the same Codex session?
