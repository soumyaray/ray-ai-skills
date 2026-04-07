---
description: >
  Search and retrieve notes from the user's Obsidian knowledgebase.
  Use this skill whenever the user asks to find, search, look up, or retrieve
  notes, topics, or information from their knowledgebase, Obsidian vault,
  or personal notes. Trigger on phrases like "find notes about",
  "what do my notes say about", "search my knowledgebase", "in my obsidian",
  "check my notes on", "do I have notes about", "look in my vault",
  "knowledgebase", "obsidian notes", or when the user references a specific
  note by name or wants to understand what they've written about a subject.
allowed-tools: Read, Glob, Grep, Edit, Write, Bash, Agent
---

# Knowledgebase Search and Retrieval

Search the user's Obsidian knowledgebase to find and surface relevant notes without cluttering context.

## Vault location

Default (customize for your own setup):

```
~/Obsidian/Vault/
```

Replace this path with the actual location of the user's vault. If the vault is itself a git repository, follow the conventions in its own `CLAUDE.md` (structure, frontmatter, tagging, wiki-links, linting) when creating or editing notes.

## MOCs (Maps of Content)

Many Obsidian vaults use **Maps of Content** — curated index notes (typically in a folder such as `_mocs/`) that list canonical notes for a topic with brief descriptions. MOCs are cheaper to consult than running grep across hundreds of files, so prefer reading a relevant MOC first when one exists.

The vault's actual MOC list will vary per user. For example:

| MOC file | Topics covered |
| --- | --- |
| `_mocs/<Topic A> MOC.md` | Notes related to topic A |
| `_mocs/<Topic B> MOC.md` | Notes related to topic B |

Discover the available MOCs at runtime with a glob such as `_mocs/*.md`, and let the file names guide topic routing.

## Search strategy — progressive disclosure

**Goal**: Find the right notes fast and only load what the user actually needs. Never bulk-read files speculatively.

### Step 1: Identify the topic area

If the vault uses a topical directory layout, build (or read from a project-specific note) a topic-to-location table to narrow the search space. The pattern looks like:

| Topic area | Directory | Relevant MOC |
| --- | --- | --- |
| `<topic A>` | `<path/to/topic-a/>` | `_mocs/<Topic A> MOC.md` |
| `<topic B>` | `<path/to/topic-b/>` | `_mocs/<Topic B> MOC.md` |
| `<topic C>` | `<path/to/topic-c/>` | — |

If no such map is available, fall back to a vault-wide glob/grep (Step 2.4 below) or read the vault's own `CLAUDE.md` for guidance.

### Step 2: Search — use the lightest tool first

Try these in order, stopping as soon as you have good results:

1. **Glob by filename** in the target directory — fastest, catches well-named notes:
   ```
   Glob: pattern = "*keyword*" path = "<target_dir>"
   ```

2. **Grep by content** in the target directory — for when filenames don't match:
   ```
   Grep: pattern = "keyword" path = "<target_dir>" output_mode = "files_with_matches"
   ```

3. **Read the relevant MOC** (if one exists for the topic) — MOCs list canonical note names with brief descriptions. This is cheaper than grep across hundreds of files.

4. **Grep vault-wide** as a last resort — only if targeted search fails:
   ```
   Grep: pattern = "keyword" path = "<vault_root>" glob = "*.md" output_mode = "files_with_matches"
   ```

5. **Grep by tag** — search YAML frontmatter for tagged notes:
   ```
   Grep: pattern = "^tags:.*keyword" path = "<target_dir>" glob = "*.md"
   ```

### Step 3: Present results before loading

After finding matching files, **list them to the user first** with a one-line summary of each (from filename or MOC context). Ask which ones to open, or make a judgment call if the user's intent is clear.

**Do NOT read all matching files.** Only read the files the user wants or the 1–3 most relevant ones.

### Step 4: Read and summarize

When reading a note:
- Read only the requested note(s)
- Summarize key points concisely
- Mention wiki-links (`[[Other Note]]`) that could be relevant for follow-up
- If the note references other notes the user might want, mention them but don't auto-load

## Multi-note exploration

If the user wants a broad overview of a topic area:

1. Read the relevant MOC first — it's a curated index with note descriptions
2. Summarize the MOC's coverage for the user
3. Let the user pick which notes to dive into

## For creating or editing notes

If the user wants to create or edit notes (not just search), read the vault's `CLAUDE.md` first for any project-specific tag taxonomy and conventions. The defaults below are common Obsidian patterns — adapt them to fit the vault you're working with:

- **Frontmatter**: `tags:` (flat, lowercase-kebab-case if the vault uses a controlled taxonomy), `aliases:` for acronyms/short names
- **Structured properties**: per-note-type properties (e.g. `cuisine:`, `serves:`, `source:`) where the vault defines them
- **Wiki-links**: `[[Note Name]]` for cross-references, `![[image.png]]` for embeds
- **Folder names**: follow whatever case convention the vault uses (commonly kebab-case)
- **No archiving** (if the vault prefers in-place curation): leave notes where they are
- **Lint**: run your markdown lint skill (e.g. `/md-lint`) on any `.md` file created or edited
- **MOC updates**: add a wiki-link entry to the relevant MOC after adding a note on a covered topic
- **Committing**: use your project's commit skill (e.g. `/commit`) following the vault's commit conventions

## Important constraints

- **Never bulk-read files** — always search first, then selectively read
- **Prefer MOCs over directory scans** for topic overviews
- **Skip binary files and attachments** — only search `.md` files
- **Use `head_limit`** on Grep results to avoid flooding context (start with 10–15 matches)
- **Use an Explore agent** for ambiguous or cross-cutting queries that span multiple topic areas
