---
name: ray-bugfix-plan
description: Plan and track a bugfix with diagnosis-first discipline — create a BUGFIX.<branch>.md working doc, trace the reported symptom to a proven root cause, and write a failing test that reproduces the bug BEFORE fixing it. Use when the user reports a bug to fix, asks to investigate or diagnose a defect, starts a bugfix branch, or mentions "ray-bugfix-plan". The complete template and all instructions are below — do not search for examples elsewhere.
---

# Bugfix Plan Skill

A bugfix is not a small feature. Features start from a goal; bugfixes start from a **symptom whose cause is unknown**. The plan therefore centers on diagnosis, and the fix is not done until a test that reproduces the bug has been seen to fail without the fix and pass with it.

## Usage

```text
/ray-bugfix-plan [<branch-name>]
```

- `/ray-bugfix-plan` — plan for the current branch
- `/ray-bugfix-plan fix-dead-button` — create branch and plan

## Instructions for Claude

1. **Discover branch**: Use current branch, or create the named branch.
2. **Choose doc location** (first that applies):
   - `.claude/bugfixes/` if it exists
   - `.claude/archive/` if it exists
   - `.claude/plans/` if it exists
   - otherwise create `.claude/bugfixes/`
3. **Create doc**: `BUGFIX.<sanitized-branch>.md` (replace `/` with `-`) in that location, from the template below.
4. **Update `CLAUDE.local.md`** (if the project uses one): add/replace an `@`-reference to the bugfix doc so context survives clearing.
5. **Record the symptom verbatim** before touching any code: the user's/reporter's words, plus every observed detail.
6. **Work the process below**, updating the doc as each phase completes — it is the single source of truth if context is cleared.

## The bugfix process

### Phase 1 — Diagnose (no code changes yet)

The bug report is a **symptom, not a diagnosis**. The reporter names what they saw; what they saw is often not what you assume ("the Add X button" may be a different control entirely).

- **Every detail is a clue.** Odd details are the most valuable — "clicking did nothing" points somewhere very different than "clicking errored". A root cause must explain **all** observed symptoms; if one detail remains unexplained, keep digging.
- **Form explicit hypotheses; kill them with evidence, cheapest probe first.** Client-side state a reporter can check in seconds beats a database query beats a code audit. Record each ruled-out hypothesis *and the evidence that killed it* in the doc — this prevents re-litigating and shows reviewers the path.
- **Trace the actual execution path yourself.** Read the real code with file:line references. Do not trust summaries (including subagent reports) for the final diagnosis — verify the gate/branch/route that actually runs.
- **"The code says it can't happen" + "it happened" = you traced the wrong path.** Different entry point, stale build, different control, drifted data. Widen the search instead of doubting the report.
- **Need production data? Never ask for credentials.** Design the smallest read-only probe the user can run themselves and paste back (one query, one console snippet, a devtools check). Offer a scoped read-only role or a backup restore only if direct access is truly needed.
- **State the blast radius honestly.** Check every defense layer: is this exploitable, or cosmetic because a deeper layer (server-side authorization, validation) holds? Record which layers held and which leaked.

Write the root cause in the doc **with file:line evidence** before moving on.

### Phase 2 — Reproduce as a failing test (red)

Write a test that reproduces the bug **before** writing the fix. The red run is non-negotiable proof that (a) the bug is real and understood, and (b) the test actually guards it.

- **No test infrastructure? That's not an exemption.** Either set up the project's missing test runner, or build a minimal throwaway harness from what is already installed — but obtain a red somehow.
- **Fix already written before the test?** (It happens.) Prove the test anyway: stash/revert the fix, run the test, confirm it fails against the buggy code, restore the fix, confirm it passes. Record both runs in the doc.
- **The failing output should visibly show the bug** (e.g., the leaked element in the rendered output), not just a generic assertion error.

### Phase 3 — Fix

- Smallest change that makes the test pass and fully addresses the root cause — not the symptom, not a broader refactor.
- Prefer fixing at the layer that owns the invariant, plus belt-and-suspenders where cheap (e.g., both "don't route them there" and "don't render it for them").
- **Collateral bugs found while diagnosing** (broken tooling, stale config) get fixed in their **own commits** — never entangled with the main fix. One concern per commit: fix, test infra, collateral fix, docs.

### Phase 4 — Verify and close out

- Re-run the regression test (green) and the project's full suite.
- **Unrelated failures encountered during verification must be proven pre-existing** — run them on the base branch, or show the branch touches zero files in that area. Never hand-wave "probably unrelated".
- **Mark every claim in the doc as `verified` (test or direct observation) or `reasoned` (logic only).** Reasoned-only parts of the fix get an explicit manual-verification task that survives into the PR description.
- Record discovered-but-deferred issues (dependency vulnerabilities, missing coverage, adjacent bugs) in the project's future-work doc or the Follow-ups section.

## Doc lifecycle

Like branch plans, bugfix docs are working docs, not permanent records. Check the project's `.gitignore` first — if the doc location is already ignored, the convention is decided (local/archived, never committed) and there is nothing to ask. Otherwise ask the user (once per project) whether docs live in the repo after merge or get archived out. The PR description and commit messages carry the durable story either way.

## BUGFIX File Template

```markdown
# Bugfix: [short title]

> Keep this doc updated as the single source of truth — context may be cleared at any time.

## Branch

`<branch-name>`

## Symptom

[Reporter's words, verbatim, plus every observed detail — who, where, what happened, what was expected. Odd details are clues; record them all.]

## Hypotheses ruled out

> Record each dead end and the evidence that killed it.

- H1. [hypothesis] — ruled out by [evidence]

## Root cause

[Filled in when found. Must cite file:line evidence and explain ALL observed symptoms. Note blast radius: which defense layers held, which leaked.]

## Fix

[What changed and why this layer. Collateral fixes listed separately.]

## Regression test

- Red: [test name/location; failing output against buggy code — date/run noted]
- Green: [passing run with fix — date/run noted]

## Tasks

- [ ] 1 Reproduce / trace root cause (with evidence)
- [ ] 2 Failing test written and seen red
- [ ] 3 Fix applied; test green
- [ ] 4 Full suite run; unrelated failures proven pre-existing
- [ ] 5 Manual verification of reasoned-only parts

## Verification status

- verified: [claims proven by test or observation]
- reasoned: [claims by logic only → covered by task 5]

## Follow-ups

- [Deferred discoveries, recorded here or in the project's future-work doc]

---

Last updated: [date]
```

## Example

Input: `/ray-bugfix-plan fix-dead-button`

Creates:

- Branch: `fix-dead-button`
- File: `.claude/bugfixes/BUGFIX.fix-dead-button.md`
- Updates: `CLAUDE.local.md` → `@.claude/bugfixes/BUGFIX.fix-dead-button.md`
