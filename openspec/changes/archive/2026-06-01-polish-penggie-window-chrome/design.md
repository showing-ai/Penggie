## Context

Penggie v0.1 is a macOS product shell around a real Codex CLI session backed by Ghostty PTY. Reading, Raw Terminal, composer, native slash overlay, and transcript history are now stable enough that this change should polish only the visible app chrome.

Current active-session UI renders `PenggieTopBar` as the first row inside the app content. Because the app already uses a hidden title bar, this creates two layers: the macOS traffic-light region above, then a separate Penggie row below. The result feels like a web app toolbar inside a native window.

The physical use scene is a developer using Penggie on a Mac desktop as a quiet daily AI coding/chat tool. The UI should feel native, restrained, and task-focused, with product identity present but not decorative.

## Goals / Non-Goals

**Goals:**

- Make the active-session chrome feel like part of the macOS titlebar area.
- Preserve a clear Penggie identity: app icon, `Penggie`, and `Codex` session label.
- Replace the text segmented Reading/Terminal control with one icon-only mode switch.
- Keep New Chat and Close Session discoverable through icon buttons with tooltip and accessibility labels.
- Reduce vertical chrome height so Reading and Raw Terminal feel like the main surface.
- Preserve all stable session, PTY, transcript, composer, IME, and native slash behaviors.

**Non-Goals:**

- Do not redesign the Reading transcript.
- Do not change `PenggieReadingTurnStore` or transcript history ownership.
- Do not change Ghostty PTY creation, scrollback, or Raw Terminal rendering.
- Do not change native slash overlay data source, row extraction, or selection logic.
- Do not change Codex launch/session state semantics.
- Do not introduce new provider selection or multi-session behavior.

## Decisions

### 1. Treat active-session top controls as window chrome

Move the visible active-session controls into a chrome strip that occupies the hidden-titlebar region and aligns around the macOS traffic lights.

Rationale: this directly fixes the screenshot issue. The current row is product-owned but visually sits below the titlebar, so users perceive it as an extra web toolbar. A chrome strip makes the app feel like Penggie first, not a content page with controls attached.

Alternative considered: keep the existing in-content top bar and reduce its height. This would be less risky, but it would preserve the core visual problem.

### 2. Use a single destination icon for mode switching

Replace the `Reading | Terminal` segmented control with one icon-only button:

- In Reading, show a terminal icon and label it `Show Raw Terminal`.
- In Terminal, show a chat/reading icon and label it `Show Reading`.

Rationale: Reading and Terminal are mutually exclusive views of the same session, not peer tabs. The current view is already obvious from the main surface. Showing the destination action is cleaner and saves chrome space.

Alternative considered: keep text tabs for clarity. This is more explicit, but it makes the chrome feel heavier and repeats state the content already communicates.

### 3. Keep `Codex` as a quiet session label, not a pill

Render `Codex` as secondary text next to `Penggie`, not as a capsule tag.

Rationale: the session backend is important, but it is not a selectable filter or badge. A pill creates unnecessary component weight and makes the left side look like a web dashboard.

Alternative considered: hide `Codex` entirely. This is cleaner, but v0.1 is Codex-only and users benefit from seeing which CLI is connected.

### 4. Limit implementation to app shell composition

Implementation should mostly touch `PenggieRootView.swift`, plus a small macOS window helper only if needed to position content around the traffic-light safe area.

Rationale: the stability risk is in accidentally coupling chrome work to Reading projection or PTY state. Shell composition can change without changing source-of-truth logic.

Alternative considered: refactor root view and session model together. That would create unnecessary blast radius for a visual polish change.

### 5. Use restrained product UI rules

Use system typography, semantic colors, 44pt hit targets, visible hover/focus/pressed states, tooltips, and accessibility labels. Avoid decorative motion, nested cards, custom scrollbars, and extra gradients.

Rationale: the goal is a more credible native desktop product, not a new visual brand direction.

Alternative considered: add stronger brand styling to the titlebar. This risks making a task-focused tool feel decorative and distracts from the core Reading experience.

## Risks / Trade-offs

- [Risk] Hidden-titlebar layout can collide with macOS traffic lights on small window widths.  
  Mitigation: reserve a fixed leading safe area before the left identity group and test at the current minimum width.

- [Risk] Icon-only mode switching can be less discoverable than text tabs.  
  Mitigation: use recognizable SF Symbols, 44pt hit target, tooltip, accessibility label, and mode-specific icon that communicates the destination.

- [Risk] Moving chrome can accidentally reduce content height assumptions in Reading or Raw Terminal.  
  Mitigation: keep content below a single measured chrome height and verify Reading, Raw Terminal, slash overlay, and composer still render correctly.

- [Risk] Window chrome refinements can trigger broad SwiftUI layout churn.  
  Mitigation: keep the implementation local to view composition and add only targeted tests or manual checks for shell behavior.

## Migration Plan

1. Add the new chrome layout behind the existing session states.
2. Replace the segmented mode picker with the destination icon toggle.
3. Remove the redundant in-content top bar row.
4. Run existing core tests to protect transcript, PTY, and native slash behavior.
5. Manually verify Reading, Raw Terminal, New Chat, Close Session, and slash overlay in the app.

Rollback is straightforward: restore the previous `PenggieTopBar` placement and segmented mode picker if the chrome integration causes unacceptable macOS window layout issues.
