---
name: ray-init
description: Initialize Claude Code in a repository with standard project scaffolding. Use this skill whenever the user wants to set up Claude Code in a new repo, initialize claude configuration, run /init with extras, or mentions "ray-init". This goes beyond the built-in /init by adding gitignore rules, Sideways files, and a local planning doc.
allowed-tools: Bash, Read, Edit, Write, Skill
---

# ray-init: Initialize Claude Code in a Repository

Set up Claude Code in a repo with the standard scaffolding: CLAUDE.md in `.claude/`, gitignore rules for AI tooling and Sideways, local planning doc, and Sideways manifest files.

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

### 3. Add entries to .gitignore

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

**Sideways block** (only if the project will use a cross-machine sync helper such as [Sideways](https://github.com/soumyaray/sideways) or a similar alternative — skip otherwise):
```
# Cross-machine sync manifests (e.g. Sideways)
.swcopy
.swsymlink
```

When checking for duplicates, look for the comment headers (`# AI tooling`, `# Sideways files`) or the key entries themselves. If some entries exist but the block is incomplete, add only the missing lines.

### 4. Create CLAUDE.local.md

Create `CLAUDE.local.md` in the project root with this exact content:

```
# Local planning document(s) referenced below
```

This is a local-only file (gitignored) used for planning docs and scratch notes that shouldn't be committed.

### 5. Create cross-machine sync manifests (optional)

Skip this step unless the project will be used with an external cross-machine sync helper such as [Sideways](https://github.com/soumyaray/sideways) (or a similar alternative). When in doubt, ask the user.

Create two files in the project root:

**.swcopy** — files that should be copied per-machine (not symlinked):
```
CLAUDE.local.md
```

**.swsymlink** — files/dirs that should be symlinked across machines:
```
.claude/archive/
.claude/settings.local.json
```

The entries above are sensible defaults — `.claude/archive/` and `.claude/settings.local.json` are commonly shared across machines, while `CLAUDE.local.md` is per-machine. Adjust the lists to fit the project. These manifest files tell the sync tool which local files to manage; `.swcopy` lists files to copy (each machine gets its own version), `.swsymlink` lists files to symlink (shared across machines via a sync service such as Dropbox).

### 6. Offer to commit

After all files are in place, show the user a summary of what was created/modified:

- `.claude/CLAUDE.md` (moved/created by /init)
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
