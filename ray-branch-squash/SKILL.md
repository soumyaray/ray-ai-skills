---
name: branch-squash
description: Squash branch commits into meaningful groups via scripted interactive rebase
---

# Branch Squash

Analyze commits on the current branch, propose meaningful groupings, and execute a scripted interactive rebase to squash them.

## Usage

```text
/branch-squash [<base-branch>]
```

- `/branch-squash` — base branch auto-detected
- `/branch-squash develop` — squash against `develop`

## Instructions for Claude

### Step 1: Determine the base branch

If the user provides a base branch as an argument, use it. Otherwise, auto-detect:

1. Check if a `develop` branch exists (`git rev-parse --verify develop 2>/dev/null`)
2. If `develop` exists and the current branch is not a release branch (`release/*`), use `develop`
3. If on a release branch, ask the user — both `main`/`master` and `develop` are reasonable targets
4. Otherwise, use `main` — or `master` if `main` does not exist

**Always confirm the detected base branch with the developer before proceeding.** Show them: "I detected `<branch>` as the base. Is that correct?"

### Step 2: Check for merge commits

Run:

```bash
git log <base>..HEAD --merges --oneline
```

If merge commits exist, **warn the developer** and ask how to proceed:

- **Abort** — the developer should clean up merge commits first
- **Continue** — include the merge commit content in groupings (may complicate rebase)

If the developer chooses to continue, add `--rebase-merges` context to the rebase strategy. However, recommend aborting in most cases — a clean linear history is easier to squash.

### Step 3: List and analyze commits

Run:

```bash
git log <base>..HEAD --oneline --reverse
```

Display the full list to the developer so they can see what will be grouped.

### Step 4: Propose groupings

Analyze the commits and propose meaningful groups. Follow these heuristics:

**Grouping rules:**

1. **Group by logical concern** — consecutive commits that contribute to the same logical change belong together, regardless of category prefix
2. **Absorb small interleaved docs** — planning doc updates, progress tracking commits, and phase-completion docs that sit between code commits should be absorbed into the adjacent code group (these are implementation artifacts, not standalone deliverables)
3. **Keep substantial docs separate** — large standalone documentation efforts (initial planning, comprehensive API docs, naming convention documents) remain their own group
4. **Keep cleanup/chore commits last** — any final cleanup commits (removing planning files, formatting, etc.) stay as the last commit(s)
5. **Keep standalone test commits separate** — if tests are their own logical effort (e.g., snapshot regression tests), keep them as a group; if tests accompany a code change, absorb into that group
6. **Respect phase boundaries** — if the branch has clear phases (e.g., "read-side refactoring" then "write-side refactoring"), each phase is a natural group boundary

**Commit message conventions for squashed groups:**

Follow the `<category>: <purpose>` convention:

- All lowercase
- Category reflects the primary nature of the group (`refactor`, `feature`, `fix`, `docs`, `tests`, `chore`)
- Purpose describes the outcome as a capability, not the action taken
- If a group mixes categories (e.g., refactoring + absorbed doc updates), use the dominant code category

**Present the proposed plan as a table:**

```
| Group | Commits squashed              | Proposed message                                            |
|-------|-------------------------------|-------------------------------------------------------------|
| 1     | abc1234, def5678, ghi9012     | refactor: read-side matrix access replaced with accessors   |
| 2     | jkl3456, mno7890              | docs: naming conventions and demo-based test plan           |
| 3     | pqr1234                       | chore: branch planning files cleaned up                     |
```

### Step 5: Confirm with the developer

Present the grouping plan and **wait for explicit approval** before proceeding. The developer may want to:

- Adjust group boundaries
- Change proposed commit messages
- Split or merge groups
- Reorder groups

Do NOT proceed to the rebase until the developer confirms.

### Step 6: Create backup branch

```bash
git branch backup-before-squash
```

Inform the developer: "Created backup branch `backup-before-squash`. Your original history is safe."

If a branch named `backup-before-squash` already exists, append a timestamp:

```bash
git branch backup-before-squash-$(date +%Y%m%d-%H%M%S)
```

### Step 7: Generate and execute the scripted rebase

**Do NOT use `git rebase -i` interactively** — it requires terminal input that is not supported.

Instead, use the scripted rebase approach:

1. **Write a rebase editor script** to `/tmp/rebase-editor.sh`:

```bash
cat > /tmp/rebase-editor.sh << 'REBASE_SCRIPT'
#!/bin/bash
cat > "$1" << 'EOF'
pick <first-hash-of-group-1> <short description>
fixup <second-hash-of-group-1> <short description>
fixup <third-hash-of-group-1> <short description>
exec git commit --amend -m "<squashed commit message for group 1>"

pick <first-hash-of-group-2> <short description>
fixup <second-hash-of-group-2> <short description>
exec git commit --amend -m "<squashed commit message for group 2>"

pick <hash-of-final-commit> <short description>
EOF
REBASE_SCRIPT
chmod +x /tmp/rebase-editor.sh
```

**Key rules for the todo file:**

- Each group starts with `pick` for the first commit
- All subsequent commits in the group use `fixup` (not `squash` — avoids editor prompts)
- After each group's fixups, an `exec git commit --amend -m "..."` line sets the final message
- The last group (if it's a single commit) needs only `pick`, no `exec`
- Separate groups with a blank line for readability
- Use short commit hashes (7+ chars) from the `git log` output
- Commit messages in `exec` lines must not contain single quotes — use double quotes

2. **Execute the rebase:**

```bash
GIT_SEQUENCE_EDITOR=/tmp/rebase-editor.sh git rebase -i <base-branch>
```

### Step 8: Handle rebase interruptions

If the rebase stops with an error:

1. Run `git status` to assess the situation
2. If it says "all conflicts fixed" and "nothing to commit, working tree clean" — run `git rebase --continue`
3. If there are actual merge conflicts — **stop and inform the developer**. Do not attempt to resolve conflicts automatically during a squash rebase. The developer should:
   - Run `git rebase --abort` to return to the pre-rebase state
   - Investigate the conflicts manually
4. If the rebase fails completely — run `git rebase --abort` and inform the developer that the backup branch is intact

**Never force through a rebase with unresolved conflicts.**

### Step 9: Verify integrity

After the rebase completes successfully:

```bash
git diff backup-before-squash HEAD
```

This diff **must be empty**. If it shows any differences:

- **Stop immediately** — something went wrong
- Inform the developer of the differences
- Suggest: `git reset --hard backup-before-squash` to restore the original state

If the diff is empty, report: "Verified: the rebased tree is identical to the original. No changes were lost."

Also show the new commit log:

```bash
git log <base>..HEAD --oneline
```

### Step 10: Cleanup

Ask the developer: "The backup branch `backup-before-squash` is no longer needed. Shall I delete it?"

- If yes: `git branch -D backup-before-squash`
- If no: leave it for the developer to delete later

Clean up the temp script:

```bash
rm -f /tmp/rebase-editor.sh
```

## Important

- Do NOT push after squashing unless the developer explicitly asks.
- Do NOT add a `Co-Authored-By` line or reference AI in commit messages.
- Do NOT proceed past the grouping proposal without developer confirmation.
- If the branch has already been pushed, warn the developer that squashing will require a force push to update the remote.
- If the rebase goes wrong at any point, the backup branch is the safety net. Never delete it until integrity is verified.
