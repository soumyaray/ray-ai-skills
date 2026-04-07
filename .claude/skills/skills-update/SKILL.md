---
name: skills-update
description: Update the ray-ai-skills repo from source skills under ~/.claude/skills/ — audit, then sync, then stop before commit. Also handles adding a new skill to .shared-skills, removing a skill from the mirror, or auditing without syncing. Use this skill whenever the user wants to sync skills into the repo, publish skill changes, update the skills mirror, add a skill to the shared list, remove a skill from the shared list, or says "skills-update". Accepts natural-language targets like "sync all", "update ray-tdd and ray-commit", "remove ray-foo", "audit only", etc.
allowed-tools: Bash, Read, Edit, Glob, Grep, Skill
---

# skills-update

Update the `ray-ai-skills` repo from the canonical sources under `~/.claude/skills/`. This skill **audits first, then syncs**, and always stops before committing so the user can review `git diff` themselves.

It also handles the adjacent lifecycle operations on `.shared-skills` (add / remove) so the user can express intent in natural language instead of editing that file by hand.

## Usage

The user may invoke this skill with any of the following shapes (natural language, not a fixed grammar):

- *default* — "skills-update" / "sync my skills" / "publish skill changes"
  → audit + sync every skill in `.shared-skills` whose source has changed (or is new).
- *named targets* — "update ray-tdd and ray-commit" / "sync ray-knowledgebase only"
  → audit + sync exactly those skills.
- *add* — "add ray-foo to the shared skills" / "publish ray-foo"
  → append to `.shared-skills`, then audit + sync just that skill. Remind the user to add a README row.
- *remove* — "remove ray-foo" / "unpublish ray-foo" / "drop ray-foo from the mirror"
  → remove from `.shared-skills`, delete `./ray-foo/` from the repo, remind the user to also delete the README row. Do **not** touch the source under `~/.claude/skills/ray-foo/`.
- *audit only* — "audit my skills" / "just audit, don't sync"
  → delegate to the `skills-audit` skill and stop. (Or tell the user to call `skills-audit` directly.)

If the user's phrasing is ambiguous (e.g. "update ray-foo" when `ray-foo` is not yet in `.shared-skills`), ask whether they mean *add* or *sync-existing* before proceeding.

## Instructions for Claude

### Step 1: Classify the request

Parse the user's message into one of these modes:

| Mode        | Trigger phrasing                                               | Action                                    |
|-------------|----------------------------------------------------------------|-------------------------------------------|
| `sync-all`  | no targets named, or "all"                                     | audit + sync everything changed           |
| `sync-some` | names listed, all already in `.shared-skills`                  | audit + sync just those                   |
| `add`       | "add", "publish", "include" + a name NOT in `.shared-skills`   | append to `.shared-skills`, audit + sync  |
| `remove`    | "remove", "unpublish", "drop", "delete from mirror" + a name   | strip from `.shared-skills`, delete mirror dir |
| `audit`     | "audit only", "don't sync", "just check"                       | hand off to `skills-audit`                |

If a named skill is not in `.shared-skills` and the verb is ambiguous, ask the user before acting.

If a named skill does not exist under `~/.claude/skills/<name>/` (and the mode is not `remove`), stop and report the missing source — something is probably mistyped.

### Step 2: Handle `add`

1. Read `.shared-skills` and confirm the name isn't already there.
2. Append the name on a new line at the end of `.shared-skills` (preserve trailing newline).
3. Fall through to Step 4 (audit + sync) with that single name as the target list.
4. After sync, remind the user to add a row to the README skill table per the "Adding a new skill" workflow in `.claude/CLAUDE.md`.

### Step 3: Handle `remove`

1. Read `.shared-skills` and remove the matching line (exact match, ignoring surrounding whitespace and `#` comments on the line).
2. If `./<name>/` exists in the repo root, delete it with `rm -rf ./<name>`. Confirm the path is inside the repo before deleting.
3. Do **not** delete or modify `~/.claude/skills/<name>/` — the source stays put; only the public mirror is removed.
4. Run `git status` and show it.
5. Remind the user to:
   - remove the corresponding row from the README skill table
   - review and commit manually
6. Do **not** run the audit or `./sync.sh` in this mode — removal is self-contained.

### Step 4: Handle `audit` (audit-only mode)

Delegate to the `skills-audit` skill with whatever target list the user specified (or no list for "everything changed"). Do not run `./sync.sh`. Stop after the report.

### Step 5: Handle `sync-all` / `sync-some` (the main path)

1. **Determine the target list.**
   - `sync-some`: use the names the user gave.
   - `sync-all`: walk `.shared-skills`, compare each entry's `~/.claude/skills/<name>/` against `./<name>/` using the same diff logic as `skills-audit` Step 1, and keep only the changed/new entries.
   - If the resulting list is empty, report "no skills changed since last sync — nothing to update" and stop.

2. **Run the audit.** Invoke the `skills-audit` skill on the target list. Show the audit report verbatim.

3. **Gate on findings.**
   - **blocker** → stop. Do not sync. Name the skill and the reason.
   - **significant** or **minor** → ask the user how to proceed:
     1. Edit the source files now and re-audit (recommended).
     2. Sync anyway (only if the user explicitly accepts the findings).
     3. Cancel.
   - **all clean** → proceed straight to sync without prompting.

4. **Sync.** Run `./sync.sh` from the repo root. Show its output.

5. **Show the resulting state:**

   ```sh
   git status
   git diff --stat
   ```

6. **Hand off.** Tell the user:
   - The sync is complete and the changes are unstaged.
   - They should review `git diff` before committing.
   - Do **not** auto-commit or auto-stage.
   - If any new skills were added (i.e. they were in `add` mode or appeared as `new:` during the diff walk), also remind them to add a row for each in the README skill table.

## Important constraints

- **Never run `./sync.sh` without first running the audit**, except in `remove` mode (which doesn't sync at all).
- **Never commit, stage, or push** as part of this skill. The user reviews `git diff` themselves.
- **Never edit files under `./<name>/` in the repo mirror.** The canonical source lives in `~/.claude/skills/<name>/`; repo copies are overwritten on sync. (Editing `.shared-skills` in the repo root is fine — that file is the repo's own configuration, not a mirror.)
- **Never delete or modify the source** at `~/.claude/skills/<name>/`. Removal only affects the public mirror and `.shared-skills`.
- **Confirm before destructive actions.** Deleting a mirrored skill directory or rewriting `.shared-skills` should be announced ("I'll remove `ray-foo` from `.shared-skills` and delete `./ray-foo/` from the repo — source at `~/.claude/skills/ray-foo/` is untouched. Proceed?") unless the user's request was already unambiguous.
- **If a named skill is not in `.shared-skills`**, warn the user — `sync.sh` won't pick it up. Ask whether to add it first (transitioning into `add` mode).
