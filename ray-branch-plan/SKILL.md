---
name: branch-plan
description: Create a plan document for the current branch, or for a specified new/existing branch. The complete template and all instructions are provided below — do not search for examples elsewhere.
disable-model-invocation: true
---

# Branch Plan Skill

## Usage

```
/branch-plan [<branch-name>]
```

- `/branch-plan` — plan for the current branch
- `/branch-plan ray/refactor-backend-gateway` — create branch and plan

## Instructions for Claude

When the user invokes `/branch-plan`:

1. **Discover branch**: Use current branch, or create the named branch
2. **Create plan file**: `PLAN.<sanitized-name>.md` (replace `/` with `-`) using the template below
3. **Update `CLAUDE.local.md`**: Replace existing `@PLAN.*.md` (or legacy `@CLAUDE.*.md`) reference with the new file
4. **Ask the user** for a one-line goal (optional)
5. **Report** created branch and file paths
6. **On "what's next" prompts during the branch's lifecycle**: offer 2–3 short options with tradeoffs, not a sequential rundown. Users steer better from a menu than a march.

### Planning and execution guidelines

When populating or updating a plan:

**Vertical slice**: One branch = one complete feature, backend to frontend. No horizontal layers. For multi-slice plans, number slices (Slice 1, 2) with per-slice Scope/Tasks sections and prefixed task IDs (1.1a, 1.2, 2.1a).

**Test-first**: Tests (lettered sub-IDs: 1a, 1b) precede implementation (2, 3). Implementation makes tests pass — no more, no less. Note explicitly when test-first isn't feasible.

**Single plan file**: Tests and implementation tasks together in execution order.

**Refactoring slices first**: When a feature will awkwardly extend existing structure (renames, contract widenings, constraint changes), plan a dedicated refactoring slice *before* the feature slice. Behavior-preserving + test-covered. Keeps each PR reviewable and limits blast radius.

**Split plan at slice boundaries once a slice seals**: When a multi-slice plan's shipped-slice detail starts crowding the active slice, split into `PLAN.<branch>-1.md` (shipped, reference) + `PLAN.<branch>-2.md` (active). Update `CLAUDE.local.md` to point at the active file.

**Update after each phase**: After each phase completes (tests written, implementation passing, frontend updated, verification), immediately update the plan: mark completed tasks, record findings/decisions, update Current State.

**Scope decisions**: Record deferrals and rationale. Cross resolved Questions off with the decision made — don't delete them, rejected alternatives need to stay findable. Number questions as Q1, Q2, … so later plan sections and PRs can reference them unambiguously.

**External reference materials**: When porting a reference design or spec, include:

- File path + one-line summary of what to port (a bare "see the reference" line rots the moment the file moves).
- An index table mapping `reference-unit → location → target-file` (e.g. function + line → file). Drives each task with zero ambiguity.
- Storage + deletion policy from day 1: either (a) a gitignored durable location that survives worktree resets, or (b) a committed-then-deleted-post-port path with the deletion commit pre-planned. Avoid the middle-state of "checked in and forgotten".

**Schema + deploy safety** (when a plan touches the database):

- Audit the deploy mechanism first. Verify the project's deploy pipeline auto-runs migrations on release (release hooks, CI migration steps, etc.). If it doesn't, the first task of the plan is wiring that up — a dev shouldn't need to remember a manual migration step.
- Audit production data before tightening a nullable → NOT NULL or adding a new constraint. Include the concrete query + expected outcome as an explicit sub-task. Zero offending rows → proceed; any rows → pause and resolve with the user.
- Capture a pre-deploy snapshot/backup before the first release carrying a schema change, regardless of the platform's automatic backup story. Explicit labeled backups make rollback decisions fast.

**Commit + merge hygiene**:

- Hold commits for user review by default on feature-shaping work. Propose a commit message + summary, pause, commit on explicit go. Trivial fixups inside an active task (getting a test to green) can commit without a pause.
- Squash pre-PR into logical commits, not via squash-merge at PR time. When a working branch has 5+ commits with mid-implementation reverts and plan-doc churn, squash locally into 2–4 reviewable commits before pushing. Preserves reviewer context and gives control over commit messages.
- Force-push blast-radius check before rewriting shared branch history: (a) anyone else pulled this branch? (b) CI/deploy hooks off feature-branch pushes? (c) is the target branch the protected main/trunk? (Refuse if so without explicit override.)

**Post-feature refactor pass**: Once a feature lands and tests are green, allow a *scope-limited* refactor pass:

- List 3–5 candidate extractions based on architectural smells surfaced by the new code.
- Ship 1–3; reject the rest with a one-line reason in the plan ("X rejected because ceremonial", "Y rejected because obsoleted by Qn").
- Sweep the newly-landed services/modules for logic that should live in domain objects instead — validation, cross-field rules, enrichment.

Goal: remove friction, not build a parallel architecture.

**Markdownlint clean**: The final plan document must have no markdownlint warnings. Verify before finishing. Note: line-length limits (MD013) are disabled — do not wrap lines to 80 characters. If a `.markdownlint.json` does not already exist in the project root, create one to codify these and any other deliberate rule exclusions from this skill.

## Plan file lifecycle

Plan files are working docs, not ADRs. They carry in-progress states, rejected alternatives, self-debates that rot post-merge. Decide upfront per project whether:

- **Plan lives in main after merge**: noisy but built-in audit trail.
- **Plan archived out before merge**: clean main; decisions captured in commit messages, PR body, and any project-specific decisions doc (e.g. `doc/future-work.md` for deferrals).

Ask the user which convention applies when creating a new plan. If archived, the archive location is a project-specific choice (common options: a gitignored in-repo directory, an external notes vault, etc.).

## Plan File Template

```markdown
# [Title based on branch name]

> **IMPORTANT**: This plan must be kept up-to-date at all times. Assume context can be cleared at any time — this file is the single source of truth for the current state of this work. Update this plan before and after task and subtask implementations.

## Branch

`<branch-name>`

## Goal

[To be filled in]

## Strategy: Vertical Slice

Deliver a complete, testable feature end-to-end:

1. **Backend test** — Write failing test for new behavior (red)
2. **Backend implementation** — Make the test pass (green)
3. **Frontend update** — Remove old logic, consume new API
4. **Verify** — Manual or E2E test confirms behavior

## Current State

- [ ] Plan created
- [ ] [Additional items to be added]

## Key Findings

[Analysis of existing code, capabilities, and gaps — to be filled in during investigation]

## Questions

> Questions must be numbered (Q1, Q2, ...) and crossed off when resolved. Note the decision made.

- [ ] Q1. [To be added]

## Scope

[What's in and out of scope]

**Backend changes**:

- [Description of backend work]

**Frontend changes**:

- [Description of frontend work]

## Tasks

> **Check tasks off as soon as each one (or each grouped set) is finished** — do not batch multiple completions before updating the plan.
>
> **Test-first**: Write or update tests that fail (red) before writing the implementation to make them pass (green).

- [ ] 1a [Failing test for expected behavior]
- [ ] 1b [Additional test scenarios]
- [ ] 2 [Implementation to make tests pass]
- [ ] 3 [Frontend update]
- [ ] 4 Manual verification

## Manual test feedback

> Captured during in-browser / staging verification. Each item: observation → fix direction → decision → status.

- [ ] [Item 1]

## Completed

(none yet)

---

Last updated: [date]
```

## Example

Input: `/branch-plan ray/add-file-uploads`

Creates:

- Branch: `ray/add-file-uploads`
- File: `PLAN.ray-add-file-uploads.md`
- Updates: `CLAUDE.local.md` → `@PLAN.ray-add-file-uploads.md`
