# terminal-ux-qa-foundation Specification

## Purpose
TBD - created by archiving change harden-terminal-ux-qa-foundation. Update Purpose after archive.
## Requirements
### Requirement: P0 manual QA script is versioned
The system SHALL include a repository-tracked manual QA script for the first product-grade terminal UX foundation.

#### Scenario: QA script is created
- **WHEN** this change is implemented
- **THEN** the repository contains a manual QA script covering setup/create, slash/model, resume, approval/permission, Raw Terminal round trip, New Chat/Close, missing/failed/exited states, and low-confidence projection

#### Scenario: QA script is run
- **WHEN** a reviewer follows the manual QA script
- **THEN** each scenario provides setup, trigger, expected result, failure examples, and whether Raw Terminal parity must be checked

### Requirement: Terminal interaction fixtures are evidence-backed
The system SHALL add or update fixtures that encode terminal-frame evidence for terminal-owned interaction surfaces.

#### Scenario: Fixture captures selected state
- **WHEN** a terminal interaction fixture represents a selected row
- **THEN** it includes source evidence such as marker, style, cursor, line position, frame facts, or confidence metadata sufficient to explain the selected row

#### Scenario: Fixture captures unsafe state
- **WHEN** a fixture represents stale, ambiguous, or low-confidence selection
- **THEN** it asserts that confirmation is not allowed and that rows remain inspectable when useful

#### Scenario: Fixture captures scrolled or paged state
- **WHEN** a fixture represents a selected row near or beyond the visible list boundary
- **THEN** it includes expected visible-window, pager, or scroll metadata sufficient to test that the selected row is not clipped

### Requirement: Display fallback fixtures cover terminal-sensitive output
The system SHALL add or update Display AST fixtures for terminal-sensitive output before broad Reading UI productization begins.

#### Scenario: Terminal-sensitive output is captured
- **WHEN** a fixture contains long session output, CJK prose, CJK tables, box drawing, code, warning/status rows, tool-heavy output, or low-confidence layout
- **THEN** the expected output preserves visible terminal evidence through Display AST or raw/preformatted fallback

#### Scenario: Transcript pollution is captured
- **WHEN** a fixture contains terminal footers, status rows, active input rows, or terminal-owned interaction surfaces
- **THEN** the expected Reading output does not seal those transient rows as assistant answer content

### Requirement: Foundation implementation is test-first and minimal
The system SHALL use fixtures and tests to drive only the minimal code changes needed for terminal UX safety.

#### Scenario: Test exposes projection bug
- **WHEN** a new fixture or test fails because selected-row freshness, confirm gating, low-confidence blocking, or fallback behavior is incorrect
- **THEN** implementation changes are limited to the smallest projection, gating, frame, or fallback path needed to make the test pass

#### Scenario: UI polish is proposed
- **WHEN** implementation work expands into visual polish, broad Reading layout rewrite, explicit resume entry, semantic source, or overlay redesign
- **THEN** that work is deferred to a separate change

