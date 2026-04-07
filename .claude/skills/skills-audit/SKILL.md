---
name: skills-audit
description: Audit skill source files for personal references, credentials, and other publication blockers before mirroring them into the ray-ai-skills public repo. Use this skill whenever the user wants to audit one or more skills, check skills before publishing/syncing, look for hardcoded paths or sensitive content in skills, or asks "audit my skills". If no specific skills are named, audit every skill that has changed since the last sync (or is new and not yet mirrored).
allowed-tools: Bash, Read, Glob, Grep, Edit
---

# skills-audit

Audit skill source files in `~/.claude/skills/<name>/` for content that should not be published in the public `ray-ai-skills` mirror. This skill **reports findings** — it does not edit files automatically. After reviewing the report, edit the source files (or ask the user to confirm edits) before running `./sync.sh`.

## Usage

```text
/skills-audit                       # audit all changed/new skills since last sync
/skills-audit ray-knowledgebase     # audit a specific skill
/skills-audit ray-init ray-poster-create  # audit several
```

## Instructions for Claude

### Step 1: Determine target skills

If the user named one or more skills, use that exact list.

Otherwise, identify **changed and new** skills by walking the repo's `.shared-skills` file and comparing each entry's source (`~/.claude/skills/<name>/`) against the mirrored copy (`./<name>/` in the repo root).

```bash
# read .shared-skills, strip comments and blanks, then for each name check if changed
while IFS= read -r line || [[ -n "$line" ]]; do
  name="${line%%#*}"
  name="${name#"${name%%[![:space:]]*}"}"
  name="${name%"${name##*[![:space:]]}"}"
  [[ -z "$name" ]] && continue
  src="$HOME/.claude/skills/$name"
  dst="./$name"
  [[ ! -d "$src" ]] && { echo "missing-source: $name"; continue; }
  if [[ ! -d "$dst" ]]; then
    echo "new: $name"
  elif ! diff -rq --no-dereference \
        --exclude='.DS_Store' --exclude='__pycache__' \
        "$src" "$dst" >/dev/null 2>&1; then
    echo "changed: $name"
  fi
done < .shared-skills
```

Skills that are listed in `.shared-skills` but absent from `~/.claude/skills/` are reported as `missing-source` and skipped (these are likely typos or temporarily missing — flag them but do not audit). Skills that are identical between source and repo are clean from a sync standpoint and can be skipped.

If the resulting list is empty, report "no skills changed since last sync" and stop.

### Step 2: Audit each target skill

For each target skill, walk every `*.md` file under `~/.claude/skills/<name>/` (typically `SKILL.md` plus optional `references/`, `templates/`, etc.) and apply the checks below. Use `Grep` and `Read` — do not run shell `grep`/`cat`.

#### Check A: Hardcoded personal absolute paths

Patterns to flag:

- `/Users/<username>/...` — author's home directory
- `/home/<username>/...` — Linux home
- Any explicit `Dropbox`, `iCloud`, `Sync` folder paths under a user home
- `Documents/Papers Library/` only if **not** annotated as the ReadCube macOS default
- Vault-like paths under `Obsidian/`, `KnowledgeBase/`, `Notes/`

Recommend: replace with `~/...` form, `<placeholder>`, or document as a customizable default.

#### Check B: User identity / personal name references

Patterns to flag:

- The author's first or last name in prose ("Soumya's", "by Ray", etc.)
- Author-specific email addresses
- Specific colleague/student names

Recommend: rephrase as "the user's …" or generalize.

#### Check C: Credentials and secrets

Case-insensitive keywords to flag if they look like values rather than mere mentions:

- `api[-_]?key`, `secret`, `token`, `password`, `credential`, `bearer`, `private[-_]?key`
- Long base64-looking strings (`[A-Za-z0-9+/=]{32,}`) embedded in prose or examples
- AWS-style access key prefixes (`AKIA`), GitHub tokens (`gh[pousr]_…`), Slack tokens (`xox[bp]-…`)

Recommend: remove or replace with `<token>` placeholder. **Block sync** if any real-looking credential is found.

#### Check D: Private project / organization references

Patterns to flag:

- Internal-only project names, codenames, or product names not on the public web
- Organization initialisms that imply a specific institution (e.g., a workshop's host org)
- URLs to private repositories (`github.com/<org>/<repo>` where the repo is private)
- Specific event names, conference talks, course codes that are author-specific

Recommend: replace with neutral placeholders (`<event-name>`, `<your-org>`) or remove.

#### Check E: Skill-internal cross-references that leak naming

Patterns to flag:

- References to other skills by their `ray-`-prefixed name in instructional prose, where the consumer would expect a generic name (e.g., `/ray-commit` should usually be `/commit` or "your commit skill").
- Any frontmatter `name:` value that doesn't match the skill's directory name (non-blocking; flag for the user).

#### Check F: Plan-file naming convention

Flag occurrences of `CLAUDE.<something>.md` referring to per-branch or per-task plan files. The convention in this repo is `PLAN.<something>.md` (with `CLAUDE.local.md` as the index). The standard `CLAUDE.md` (project context) is fine and should NOT be flagged.

### Step 3: Produce the audit report

Output a single structured report. For each audited skill, classify as:

- **clean** — no findings; safe to sync as-is.
- **minor** — small edits required (one or two lines); not a sync blocker but should be fixed.
- **significant** — multiple findings or whole sections needing rewrite.
- **blocker** — credentials, real secrets, or content that must not be published.

Report shape:

```markdown
## skills-audit report

### Summary

- Audited: N skills (<list>)
- Clean: N
- Minor: N
- Significant: N
- Blocker: N

### Findings

#### <skill-name> — <status>

- **Check A (paths)**: `SKILL.md:<line>` — `<excerpt>` → recommend: `<fix>`
- **Check B (identity)**: …
- **Check C (credentials)**: …
- (omit checks with no findings)

#### <next-skill> — clean

(no findings)
```

For **clean** skills, a single line is enough; do not pad. For each finding, include the file path relative to `~/.claude/skills/`, the line number, a short excerpt of the offending content, and a one-line recommended fix.

### Step 4: Recommend next step

End the report with one of:

- "All audited skills are clean — safe to run `./sync.sh`."
- "Minor edits recommended in the source files above. Edit `~/.claude/skills/<name>/SKILL.md` (not the repo copy) and re-run `/skills-audit` to confirm."
- "Blocker(s) found — do **not** sync until the credential/secret issue is resolved."

## Important constraints

- **Read-only.** This skill never edits skill files or runs `sync.sh`. Use `/skills-update` if the user wants the audit + sync flow.
- **Audit the source, not the repo copy.** Edits in `./<name>/` are overwritten on the next sync, so audit findings must point to `~/.claude/skills/<name>/`.
- **Skip clean skills.** Do not waste context describing skills that have no findings beyond a one-line "clean" entry.
- **Honour `.shared-skills`.** Only audit skills the repo intends to publish. Anything in `~/.claude/skills/` not listed in `.shared-skills` is out of scope.
- **Do not invent findings.** If a path or name is already documented as a customizable default, it is not a finding.
