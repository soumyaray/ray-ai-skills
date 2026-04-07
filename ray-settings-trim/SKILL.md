---
description: Remove redundant entries from .claude/settings.local.json permissions
allowed-tools: Read, Edit
---

Clean up the `allow` list in `.claude/settings.local.json` by removing redundant permission entries.

## Rules

A permission entry is **redundant** if a broader wildcard pattern already covers it. Apply these rules:

1. **Wildcard subsumes specific**: If `Bash(gh pr create *)` exists, remove any entry that is a specific `gh pr create` invocation (e.g., a full `gh pr create --title "..." --body "..."` command).

2. **Broader wildcard subsumes narrower**: If `Bash(git push *)` exists, remove `Bash(git push)` (no args variant). If `Bash(Rscript *)` exists, remove entries like `Bash(SCRATCHPAD="..." Rscript *)` that are session-specific wrappers around the same command.

3. **git `-C` worktree consolidation**: Path-specific `git -C <path> <subcommand>` entries (e.g., `Bash(git -C /some/worktree status)`) are subsumed by the glob variant `Bash(git -C * <subcommand>*)`. Remove any path-specific `-C` entries. Also remove any overly broad catch-all like `Bash(git -C *)` — permissions should be scoped per subcommand. Every `git` subcommand should have two permission lines — the naked form and the `-C` worktree form:

   ```
   "Bash(git <subcommand> *)",
   "Bash(git -C * <subcommand>*)",
   ```

   **Important — no space before the trailing `*`:** The pattern must be `<subcommand>*` (no space), NOT `<subcommand> *` (with space). A space before the `*` creates a trailing-args gap: `Bash(git -C * status *)` only matches commands with arguments after the subcommand (e.g., `git -C /path status --short`) but NOT the bare form (`git -C /path status`). Without the space, `Bash(git -C * status*)` matches both.

4. **Garbled entries**: Remove entries that appear to be fragments of commit messages, PR bodies, or other text that was accidentally saved as a permission (e.g., entries starting mid-sentence or containing prose paragraphs).

5. **Exact duplicates**: Remove duplicate entries, keeping only one copy.

## Steps

1. Read `.claude/settings.local.json`.
2. Identify all wildcard patterns (entries ending in ` *)`).
3. For each non-wildcard entry, check if any wildcard pattern already covers it.
4. Flag garbled/broken entries that don't look like valid permission patterns.
5. Remove all redundant and garbled entries.
6. Group the remaining entries logically:
   - General shell utilities (`wc`, `ls`, etc.)
   - `Rscript`
   - `git` commands (alphabetical)
   - `gh` commands grouped by subcommand: `issue`, `pr`, `run`, `workflow`, `api`, `search`, `repo` (alphabetical within groups)
   - Web tools (`WebSearch`, `WebFetch`)
7. Apply the edit and report what was removed.
