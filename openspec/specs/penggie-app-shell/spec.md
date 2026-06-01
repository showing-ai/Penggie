# penggie-app-shell Specification

## Purpose
Define the Penggie-owned macOS shell, branding, start/connect flow, session states, and top bar responsibilities for v0.1.
## Requirements
### Requirement: Penggie-branded macOS shell
The system SHALL present Penggie as the user-visible macOS app identity.

#### Scenario: App identity is Penggie
- **WHEN** the user opens the app
- **THEN** the app name, bundle display name, menu name, window title, and app icon identify the product as Penggie

#### Scenario: Legacy shell branding is absent
- **WHEN** the user views v0.1 product surfaces
- **THEN** user-visible ShowCLI and Ghostty product shell text is not shown

### Requirement: Codex-only start screen
The system SHALL show a Penggie-branded start/connect screen with a single Codex-backed entry path and explicit pre-launch folder selection.

#### Scenario: User opens Penggie without an active session
- **WHEN** no Codex session is running
- **THEN** the user sees a Penggie-branded start screen with Codex as the v0.1 local agent CLI and `Create with Penggie` as the primary action

#### Scenario: Unsupported providers are hidden
- **WHEN** the start screen is shown in v0.1
- **THEN** provider options other than Codex are not presented as selectable product paths

### Requirement: Productized session states
The system SHALL show Penggie-owned state pages for session setup and failure conditions.

#### Scenario: Codex is missing
- **WHEN** Codex CLI cannot be found
- **THEN** the app shows a clear Penggie-branded `Codex CLI not found` state with a retry path

#### Scenario: Codex launch fails
- **WHEN** starting Codex fails
- **THEN** the app shows a Penggie-branded launch failure state instead of dropping the user into terminal output

#### Scenario: Codex process exits
- **WHEN** the active Codex process exits
- **THEN** the app shows a Penggie-branded ended-session state with paths to start again or view Raw Terminal when available

#### Scenario: Launching blocks inspect-only actions
- **WHEN** Penggie is checking Codex or launching a session
- **THEN** prompt submission, Raw Terminal switching, New Chat, and Close Session are unavailable until an inspectable session or recovery state exists

### Requirement: Product top bar
The system SHALL provide Penggie-owned active-session chrome aligned with the macOS titlebar region.

#### Scenario: Reading session is active
- **WHEN** the user is in an active Codex session
- **THEN** the chrome exposes session folder identity and a Reading/Raw Terminal destination mode switch without showing New Chat and Close Session as heavy always-visible toolbar controls

#### Scenario: Top bar remains Penggie-owned
- **WHEN** the user switches between Reading and Raw Terminal
- **THEN** the visible chrome remains Penggie-owned and does not expose Ghostty product chrome

### Requirement: P0 manual QA covers setup and lifecycle safety
The system SHALL include setup and lifecycle scenarios in the first product-grade manual QA foundation.

#### Scenario: Create path is tested
- **WHEN** the user activates `Create with Penggie`
- **THEN** QA verifies the app starts the intended create/new-session path and does not enter resume picker unless Codex is explicitly launched in resume mode or the user explicitly chooses resume

#### Scenario: Failure states are tested
- **WHEN** missing Codex, launch failure, invalid folder, process exited with terminal surface, or process exited without terminal surface is triggered
- **THEN** QA verifies specific recovery copy, enabled actions, blocked actions, keyboard owner, and Raw Terminal availability

#### Scenario: Destructive actions are tested
- **WHEN** New Chat or Close Session is invoked
- **THEN** QA verifies confirmation, focus trap, cancel restoration, and no session discard before confirmation

### Requirement: Icon-only chrome controls are accessible
The system SHALL make icon-only active-session controls discoverable and operable without relying on visible text labels.

#### Scenario: User hovers an icon-only control
- **WHEN** the user hovers the mode switch, New Chat, or Close Session control
- **THEN** the app shows a tooltip that names the action

#### Scenario: Assistive technology reads an icon-only control
- **WHEN** assistive technology focuses the mode switch, New Chat, or Close Session control
- **THEN** the app exposes an accessibility label that names the action

#### Scenario: User targets an icon-only control
- **WHEN** the user points at an icon-only window chrome control
- **THEN** the hit target is large enough for reliable desktop interaction and has visible hover, focus, pressed, and disabled states

### Requirement: App shell is a project session container
The system SHALL present Penggie's window as one project-scoped Codex workbench session rather than a generic page stack or provider launcher.

#### Scenario: User opens Penggie without an active session
- **WHEN** the app has no active session
- **THEN** the user sees a Penggie-owned setup state with project folder selection, Codex as the current local agent CLI, and a disabled or enabled `Create with Penggie` action based on folder validity

#### Scenario: User starts a session
- **WHEN** the user creates a session from a valid folder
- **THEN** the app launches the real Codex CLI for that folder and transitions into the active session shell without exposing terminal startup noise as product content

#### Scenario: User works in an active session
- **WHEN** Reading or Raw Terminal is visible
- **THEN** the session folder identity remains visible in low-chrome macOS titlebar-scale chrome

### Requirement: Start action uses Penggie product language
The system SHALL use `Create with Penggie` as the v0.1 setup primary action rather than maintaining parallel `Start with Codex` and `Create with Penggie` entry labels.

#### Scenario: Start screen is shown
- **WHEN** no active session is running
- **THEN** the setup surface presents `Create with Penggie` as the primary launch action and does not present `Start with Codex` as a competing current-product action

#### Scenario: Existing specification is interpreted
- **WHEN** older requirements mention `Start with Codex`
- **THEN** the product-grade UX contract treats that label as superseded by `Create with Penggie` while preserving Codex as the only v0.1 agent CLI

### Requirement: App shell exposes mature session lifecycle states
The system SHALL make setup, launch, active, failure, exit, and destructive session actions explicit and recoverable.

#### Scenario: Codex is missing
- **WHEN** Penggie cannot find a runnable Codex CLI
- **THEN** the app shows a specific missing-Codex product state with a retry path and does not show an empty Reading surface

#### Scenario: Codex launch fails
- **WHEN** the Codex process cannot be launched
- **THEN** the app shows a launch-failed state with actionable context and does not silently retry or hide the failure behind startup progress

#### Scenario: Codex exits
- **WHEN** the active Codex process exits
- **THEN** the app explains that the session ended and offers inspect, restart/new chat, or close actions as appropriate for the inspectable session state

#### Scenario: User requests New Chat or Close Session
- **WHEN** the action would discard or end the current session
- **THEN** Penggie presents a clear confirmation and preserves the current session until the user confirms

### Requirement: App shell follows a state matrix contract
The system SHALL define each major app state by visible UI, primary action, blocked actions, keyboard owner, prompt availability, Raw Terminal availability, and recovery path.

#### Scenario: State is reviewed
- **WHEN** a product or QA reviewer evaluates a state such as no-folder, ready, checking, launching, Reading idle, composing, agent running, terminal-owned interaction, approval needed, Raw Terminal visible, projection degraded, exited, launch failed, or confirmation
- **THEN** the expected user-visible content, allowed actions, blocked actions, keyboard routing, and recovery behavior are unambiguous

### Requirement: App shell remains Penggie-owned but low chrome
The system SHALL preserve a mature native macOS shell without turning active work into a toolbar-heavy or decorative interface.

#### Scenario: Active session chrome is visible
- **WHEN** the user is in Reading or Raw Terminal
- **THEN** the chrome exposes session identity and destination switching without duplicating provider branding, nested navigation bars, or decorative brand panels

#### Scenario: Session actions are available
- **WHEN** the user needs New Chat or Close Session
- **THEN** the actions are available as session-level menu/shortcut commands with confirmation rather than heavy always-visible top-bar controls

#### Scenario: Visual polish is applied
- **WHEN** app shell visuals are refined
- **THEN** the refinement does not obscure session state, recovery actions, terminal truth, keyboard focus, or Raw Terminal access
