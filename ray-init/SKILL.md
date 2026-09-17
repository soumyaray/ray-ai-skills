---
name: ray-init
description: Initialize Claude Code in a repository with standard project scaffolding. Use this skill whenever the user wants to set up Claude Code in a new repo, initialize claude configuration, run /init with extras, or mentions "ray-init". This goes beyond the built-in /init by adding gitignore rules, Sideways files, a gitignored .claude/plans/ directory, and a local planning doc.
allowed-tools: Bash, Read, Edit, Write, Skill
---

# ray-init: Initialize Claude Code in a Repository

Set up Claude Code in a repo with the standard scaffolding: CLAUDE.md in `.claude/`, gitignore rules for AI tooling and Sideways, a gitignored `.claude/plans/` directory, a local planning doc, and Sideways manifest files.

## Steps

### 1. Run the built-in /init

Invoke the built-in `init` skill first. This generates the initial `CLAUDE.md` with project context.

### 2. Move CLAUDE.md into .claude/

After `/init` completes, it typically creates `CLAUDE.md` in the project root. Move it into the `.claude/` folder:

```bash
mkdir -p .claude
mv CLAUDE.md .claude/CLAUDE.md
```

If `.claude/CLAUDE.md` already exists and `/init` created a new root-level `CLAUDE.md`, replace the old one. If `/init` placed it directly in `.claude/` already, no move is needed — just confirm it's there.

### 3. Create the plans directory

Always create a `.claude/plans/` directory so planning docs have a home from day one:

```bash
mkdir -p .claude/plans
```

This directory is gitignored (covered by the `.claude/*` rule in step 4), so git tracks neither it nor its contents — that is intended; plans are local (and shared across the repo's worktrees via Sideways when configured), never committed. Git does not track empty directories, so the folder only needs to exist on disk (no `.gitkeep` — it would be ignored anyway).

Then add a **Plans** section to `.claude/CLAUDE.md` so every future session puts planning docs in one place. Append (or merge into) this block:

```markdown
## Plans

Planning and working docs live in `.claude/plans/` (gitignored, and symlinked
into new worktrees via Sideways when configured). Each work stream gets its own
folder there.
```

**Write no naming convention here.** The `ray-branch-plan` skill owns the convention, and it fills this section in the first time it creates a plan in the project. Nothing names a plan file at init time, so an empty rule costs nothing. If the project already documents a convention, leave that text alone.

### 4. Add entries to .gitignore

Append the following blocks to `.gitignore` if they aren't already present. Check for existing content first to avoid duplicates. Each block should be separated by a blank line from surrounding content.

**AI tooling block:**
```
# AI tooling
CLAUDE.local.md
.claude/*
!.claude/CLAUDE.md
!.claude/settings.json
!.claude/skills/
```

**Sideways block** (only if the project will use the [Sideways](https://github.com/soumyaray/sideways) git-worktree helper — skip otherwise):
```
# Sideways files
.swcopy
.swsymlink
```

When checking for duplicates, look for the comment headers (`# AI tooling`, `# Sideways files`) or the key entries themselves. If some entries exist but the block is incomplete, add only the missing lines.

### 5. Create CLAUDE.local.md

Create `CLAUDE.local.md` in the project root with this exact content:

```
# Local planning document(s) referenced below
```

This is a local-only file (gitignored) used for planning docs and scratch notes that shouldn't be committed.

### 6. Create Sideways worktree manifests (optional)

Skip this step unless the project will use [Sideways](https://github.com/soumyaray/sideways) (the `sw` git-worktree helper). When in doubt, ask the user.

When `sw add <branch>` creates a worktree, it reads these manifests from the base directory and brings the listed gitignored files into the new worktree, which git would otherwise leave out.

Create two files in the project root:

**.swcopy** — gitignored files to copy into each new worktree (each worktree then has its own version):
```
CLAUDE.local.md
```

**.swsymlink** — gitignored files/dirs to symlink from the base directory (all worktrees share one version; end directories with `/`):
```
.claude/plans/
.claude/settings.local.json
```

The entries above are sensible defaults — `.claude/plans/` (Claude Code plans) and `.claude/settings.local.json` are shared by every worktree, while `CLAUDE.local.md` starts as a copy that each worktree can change on its own. Adjust the lists to fit the project. Only gitignored items are acted on, and an item listed in both files is an error.

### 7. Offer to commit

After all files are in place, show the user a summary of what was created/modified:

- `.claude/CLAUDE.md` (moved/created by /init; now includes a **Plans** section)
- `.claude/plans/` (new directory, gitignored — not staged)
- `.gitignore` (updated with AI tooling and Sideways entries)
- `CLAUDE.local.md` (new, gitignored)
- `.swcopy` (new, gitignored)
- `.swsymlink` (new, gitignored)

Then ask: **"Would you like me to commit these setup files?"**

If yes, stage only the committed files (`.claude/CLAUDE.md`, `.gitignore`, and any `.claude/settings.json` if it exists) and create a commit with a message like:

```
Initialize Claude Code configuration
```

The gitignored files (`CLAUDE.local.md`, `.swcopy`, `.swsymlink`) should NOT be staged — they are local-only by design.
