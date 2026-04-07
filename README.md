# ray-ai-skills

A collection of [Claude Code](https://claude.com/claude-code) skills I use day to day, packaged so others can install them too.

Each top-level directory is a single skill containing a `SKILL.md` (and any supporting files). Skills are kept under their original `ray-` prefix to avoid colliding with names like `/init`, `/commit`, etc. that other tools or your own setup may already use. If a name still collides, rename the directory after installing — see [Renaming a skill](#renaming-a-skill) below.

> **Disclaimer:** You are responsible for reviewing any skill before installing it. Skills can run shell commands, read files, and call out to external services. Read each `SKILL.md` first.

## Skills

<!-- Generated manually. Update when adding/removing skills. -->

| Skill | What it does |
| --- | --- |
| `ray-branch-plan` | Draft a branch plan for a piece of work |
| `ray-branch-review` | Review a branch's implementation against its branch plan |
| `ray-branch-squash` | Squash branch commits into meaningful groups via scripted interactive rebase |
| `ray-commit` | Create a properly formatted commit following project conventions |
| `ray-ddd` | Domain-Driven Design architecture patterns and conventions |
| `ray-gem-release` | Release a Ruby gem — bump version, commit, tag, push to RubyGems |
| `ray-init` | Initialize Claude Code in a repository with standard project scaffolding |
| `ray-knowledgebase` | Search and retrieve notes from an Obsidian knowledgebase |
| `ray-md-lint` | Lint and fix markdown files for prose-heavy projects |
| `ray-papers-library` | Find and retrieve academic papers from a Papers reference library |
| `ray-poster-create` | Generate or update an event poster PDF for a workshop project |
| `ray-pr-create` | Push a branch and create or update a GitHub PR with a structured description |
| `ray-settings-trim` | Remove redundant entries from `.claude/settings.local.json` permissions |
| `ray-tdd` | Test-Driven Development discipline for writing code |
| `ray-test-demos` | Analyze branch changes for test gaps, generate a demo-based manual test plan |
| `ray-transcript-speechify` | Convert a raw transcript into a clean, flowing speech document |

Some skills (e.g. `ray-knowledgebase`, `ray-papers-library`, `ray-poster-create`, `ray-init`) reference my personal filesystem layout and workflow. They're included for reference and adaptation rather than drop-in use — read the `SKILL.md` and adjust paths before relying on them.

## Installing

Clone the repo somewhere stable, then run `install.sh` to symlink skills into `~/.claude/skills/`:

```sh
git clone https://github.com/soumyaray/ray-ai-skills.git ~/code/ray-ai-skills
cd ~/code/ray-ai-skills
./install.sh                 # install everything (skips existing entries)
./install.sh ray-commit ray-tdd   # install only specific skills
./install.sh --force         # back up existing entries and replace them
```

Symlinking means `git pull` in the repo updates your installed skills automatically — no re-running `install.sh`.

To uninstall a skill, just remove the symlink:

```sh
rm ~/.claude/skills/ray-commit
```

### Renaming a skill

If a name collides with something you already have, install only the ones you want and create your own symlink with a different name:

```sh
ln -s ~/code/ray-ai-skills/ray-commit ~/.claude/skills/sr-commit
```

## Updating

```sh
cd ~/code/ray-ai-skills
git pull
```

That's it — symlinked skills pick up changes immediately.

## Contributing / authoring

I author these skills in `~/.claude/skills/` directly so Claude Code picks them up live, then mirror them into this repo. `.shared-skills` controls which skill directories get mirrored; `sync.sh` uses `rsync -a --delete`, so files removed from the source skill are removed from the repo copy too.

The repo also ships two **project-local maintainer skills** under `.claude/skills/` that Claude Code loads automatically when you run it from inside this repo:

- **`skills-audit`** — scans skill source files for hardcoded personal paths, credentials, and other publication blockers before syncing. Read-only.
- **`skills-update`** — audits, then runs `sync.sh`, then stops before commit. Also handles `add` / `remove` against `.shared-skills` via natural-language requests like "add ray-foo" or "remove ray-bar".

Typical flow:

```sh
cd ~/code/ray-ai-skills
claude   # then: "skills-update" — audits and syncs everything changed
git diff # review, then commit manually
```

Or do it by hand:

```sh
./sync.sh
git status
git diff
```

If you want to suggest changes, please open an issue rather than a PR. Since the canonical source lives in `~/.claude/skills/` and the repo copy is overwritten by `sync.sh`, I need to fold changes back into the source by hand — an issue describing the problem or proposed change is the most useful starting point.

## License

[MIT](LICENSE)
