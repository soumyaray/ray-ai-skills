# ray-ai-skills

A shareable mirror of [Claude Code](https://claude.com/claude-code) skills authored in `~/.claude/skills/`. Each top-level directory is one skill containing a `SKILL.md` plus any supporting files. Skills keep their `ray-` prefix to avoid colliding with built-in commands like `/init` or `/commit`.

## Layout

- `<skill-name>/` — one directory per skill, mirrored from `~/.claude/skills/<skill-name>/`. Top-level directories with a `SKILL.md` are the installable units.
- `.shared-skills` — newline-delimited list of which skill directories `sync.sh` mirrors from `~/.claude/skills/`. Lines starting with `#` are comments.
- `sync.sh` — pulls each listed skill from `~/.claude/skills/<name>/` into `./<name>/` via `rsync -a --delete`. Excludes `.DS_Store` and `__pycache__`. Run from the repo root, then review with `git status` / `git diff` before committing.
- `install.sh` — symlinks each repo skill directory (anything containing a `SKILL.md`) into `~/.claude/skills/<name>`. Won't clobber existing entries unless `--force` is passed (which renames the existing entry to `<name>.bak-<timestamp>`). Accepts a list of skill names to limit which ones get installed.
- `README.md` — public-facing install / update / authoring instructions and the table of skills.
- `LICENSE` — MIT.

## Authoring workflow

The canonical copy of each skill lives in `~/.claude/skills/<name>/`, where Claude Code picks it up live. This repo is a downstream mirror. To update the repo after editing a skill:

```sh
./sync.sh
git status
git diff
```

Never edit files inside `<skill-name>/` here directly — `sync.sh` will overwrite them on the next run. Edit the source in `~/.claude/skills/<name>/` instead.

## Adding a new skill to the repo

1. Author it in `~/.claude/skills/<name>/` with a `SKILL.md`.
2. Add `<name>` to `.shared-skills`.
3. Run `./sync.sh`.
4. Add a row to the skill table in `README.md`.
5. Commit.

## Things to be careful about

- **Personal data.** Some skills mirrored here reference my personal filesystem layout (`/Users/soumyaray/...`), private notes, or local tools. Before publishing changes, audit for hardcoded paths, tokens, or private references.
- **`rsync --delete`.** `sync.sh` deletes files in the repo copy that no longer exist in the source. If you intentionally added a file under `<skill-name>/` in the repo (e.g. a public-only README), it will be removed on the next sync. Don't do that — keep all skill content in the source under `~/.claude/skills/`.
- **Symlinks vs files.** Consumers install via symlink (`install.sh`), so changes from `git pull` are picked up immediately. The mirror itself stores real files (committed), not symlinks.
