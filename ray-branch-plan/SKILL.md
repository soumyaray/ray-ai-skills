---
name: ray-branch-plan
description: Create a plan document for the current branch, or for a specified new/existing branch. The complete template and all instructions are provided below — do not search for examples elsewhere.
disable-model-invocation: true
---

# Branch Plan Skill

## Usage

```
/ray-branch-plan [<branch-name>]
```

- `/ray-branch-plan` — plan for the current branch
- `/ray-branch-plan ray/refactor-backend-gateway` — create branch and plan

## Instructions for Claude

When the user invokes `/ray-branch-plan`:

1. **Discover branch**: Use current branch, or create the named branch
2. **Check the plan directory and its naming convention**: follow "Plan file naming" below — this can prompt the user before anything is written
3. **Create plan file**: `.claude/plans/NNN-PLAN-<slug>/PLAN.md` using the template below
4. **Update `CLAUDE.local.md`**: Replace the existing plan reference with an `@` include of the new file
5. **Ask the user** for a one-line goal (optional)
6. **Report** created branch and file paths
7. **On "what's next" prompts during the branch's lifecycle**: offer 2–3 short options with tradeoffs, not a sequential rundown. Users steer better from a menu than a march.

## Plan file naming

This section owns the convention. Other skills only need to know that plans live in `.claude/plans/` and that they must match what is already there. **This skill is also the only writer of the convention into `.claude/CLAUDE.md`.** The first time you create a plan in a project, state the convention in full in that file's **Plans** section. `ray-init` creates that section, but it says only where the docs live, so extend the block it left rather than adding a second one. Every other skill then reads the convention from the project, and none of them has to read this file.

Plans and their working docs live in `.claude/plans/` (gitignored, and symlinked into new worktrees by Sideways when configured). Create the directory if it does not exist.

**One folder per work stream**, named `NNN-PURPOSE-slug`:

- `NNN` — a zero-padded sequence number starting at `001`. It strictly increments and it is **never reused**. Before you create a new plan, list `.claude/plans/` and take the next unused number.
- `PURPOSE` — an uppercase tag for the kind of document that started the stream: `PLAN`, `BUGFIX`, `REFACTOR`, `HOTFIX`, and so on. It does not change when a second kind of document joins the folder.
- `slug` — a short kebab-case name, normally derived from the branch name (replace `/` with `-`, drop an owner prefix such as `ray/` when it adds nothing).

**Inside the folder**:

- The main document takes the name of its kind: `PLAN.md`, `BUGFIX.md`.
- When a folder holds two or more of these, prefix each one with a letter that gives the reading order: `a-PLAN.md`, `b-BUGFIX.md`. A lone document takes no letter, so a folder gains letters at the moment a second document arrives.
- Supporting files keep a kind tag and take no letter: `SKETCHES.html`, `SKETCHES-hifi.html`, `ASSET-og-card.html`. Add a suffix when a folder holds several files of one kind.
- A reference inside one folder uses the bare filename. A reference to another folder uses the full path from the repository root.

```
001-PLAN-design-initial/
  a-PLAN.md
  b-BUGFIX.md
  SKETCHES-shell-options.html
002-PLAN-projects/
  PLAN.md
```

### When the project already uses a different convention

Before writing the first file, look at `.claude/plans/` (and the repo root, where older plans often sit) for existing plan documents. If any of them do **not** match `NNN-PURPOSE-slug/PURPOSE.md` — for example a flat `NNN-PURPOSE-name.ext`, `PLAN.<branch>.md`, `PLAN-001-name.md`, or a root-level `PLAN.md` — stop and ask the developer a single y/n question:

> Existing plan files follow a different naming convention: `<list them>`. Move them into `NNN-PURPOSE-slug/` folders? (y/n)

- **y** — migrate first, then create the new plan:
  - Move with `git mv` for tracked files, plain `mv` for gitignored ones.
  - Keep each file's existing number when it already has one. Otherwise number by creation order (oldest first, `git log --diff-filter=A` or mtime) so the sequence reflects history.
  - Give the folder the purpose of the document that started the stream, and put every auxiliary doc of that stream in the same folder.
  - Update every reference: `@` includes in `CLAUDE.local.md`, cross-references inside the plan docs, and any path mentioned in committed files (code comments, stylesheets, READMEs). Grep for each old filename and confirm no hits remain.
  - Update the **Plans** section of `.claude/CLAUDE.md` to state the new convention, so later sessions follow it.
- **n** — keep the project's existing convention and name the new plan to match it. Do not mix two conventions in one directory. Record the choice in the plan so a later session does not re-open the question.

If the project documents a plan convention in `.claude/CLAUDE.md` that differs from this skill's, that document wins unless the developer chooses to migrate.

### Planning and execution guidelines

When populating or updating a plan:

**Vertical slice**: One branch = one complete feature, backend to frontend. No horizontal layers. For multi-slice plans, number slices (Slice 1, 2) with per-slice Scope/Tasks sections and prefixed task IDs (1.1a, 1.2, 2.1a).

**Test-first**: Tests (lettered sub-IDs: 1a, 1b) precede implementation (2, 3). Implementation makes tests pass — no more, no less. Note explicitly when test-first isn't feasible.

**Single plan file**: Tests and implementation tasks together in execution order.

**Refactoring slices first**: When a feature will awkwardly extend existing structure (renames, contract widenings, constraint changes), plan a dedicated refactoring slice *before* the feature slice. Behavior-preserving + test-covered. Keeps each PR reviewable and limits blast radius.

**Split plan at slice boundaries once a slice seals**: When a multi-slice plan's shipped-slice detail starts crowding the active slice, split `PLAN.md` into `a-PLAN.md` (shipped, reference) and `b-PLAN.md` (active) inside the same folder — one work stream keeps one folder. Update `CLAUDE.local.md` to point at the active file.

**Context-clear checkpoints**: Mark the points in the plan where it is safe to clear context before continuing — typically after a phase completes and the plan has been updated to capture its state. Write each checkpoint as a standalone line in the task list (e.g. `> ✅ Safe to clear context here`), never buried inside a longer paragraph, so the user can spot it at a glance.

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

Ask the user which convention applies when creating a new plan. The default is the second: `.claude/plans/` is gitignored, so plans never reach main. If archived elsewhere, the archive location is a project-specific choice (a gitignored in-repo directory, an external notes vault, etc.).

When a branch merges, mark its plan closed rather than deleting it: a short `> **CLOSED** (date): merged to <branch> as <sha>` note under the title, and a final Current State entry. Closed plans keep their number.

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

> ✅ Safe to clear context here (once the plan above is updated)

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

Input: `/ray-branch-plan ray/add-file-uploads`

With `.claude/plans/` holding `001-PLAN-design-initial/` and `002-PLAN-projects/`, this creates:

- Branch: `ray/add-file-uploads`
- File: `.claude/plans/003-PLAN-add-file-uploads/PLAN.md`
- Updates: `CLAUDE.local.md` → `@.claude/plans/003-PLAN-add-file-uploads/PLAN.md`
