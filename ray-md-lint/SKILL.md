---
description: Lint and fix markdown (.md) files — find and resolve structural issues like missing blank lines, fenced code languages, trailing punctuation in headings, and configure sensible defaults for prose-heavy projects
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# Markdown Linting

Lint markdown files with `markdownlint-cli2` and fix all reported issues.

## CLI tool

Use `npx markdownlint-cli2` (not `npx markdownlint`). These are two different npm packages wrapping the same engine — `markdownlint-cli2` is config-first and uses `#` prefix for excludes. Do not mix them.

```shell
npx markdownlint-cli2 "**/*.md" "#node_modules" 2>&1
```

Output goes to stderr — the `2>&1` redirect is required.

## Workflow: categorize first, fix once

**Before editing any files**, scan the full linter output and sort every fired rule into one of two buckets:

1. **Disable via `.markdownlint.json`** — style rules incompatible with the project:

   | Rule | Typical reason to disable |
   | --- | --- |
   | MD013 (line-length) | Impractical for prose, tables, long URLs |
   | MD060 (table-column-style) | Compact separators are valid and widely used |

2. **Fix in files** — structural rules (MD022, MD032, MD040, MD026, MD036, etc.)

Create/update `.markdownlint.json` and re-run the linter **before** starting file edits. This eliminates discovering new rule categories on a later pass.

## Batch-fix MD022/MD032

When a file has 20+ missing-blank-line errors, use this script instead of individual edits:

```python
python3 << 'PYEOF'
import re

with open('TARGET_FILE.md', 'r') as f:
    lines = f.readlines()

result = []
for i, line in enumerate(lines):
    prev = result[-1] if result else '\n'
    if re.match(r'^#{1,6}\s', line) and prev.strip() != '' and prev.strip() != '---':
        result.append('\n')
    if re.match(r'^[-*+]\s|^\d+\.\s', line) and prev.strip() != '' and not re.match(r'^[-*+]\s|^\d+\.\s|^\s+[-*+]\s|^\s+\d+\.\s', prev):
        result.append('\n')
    result.append(line)
    if re.match(r'^#{1,6}\s', line) and i + 1 < len(lines) and lines[i + 1].strip() != '':
        result.append('\n')

text = ''.join(result)
text = re.sub(r'\n{4,}', '\n\n\n', text)
with open('TARGET_FILE.md', 'w') as f:
    f.write(text)
PYEOF
```

Fix remaining rules (MD040, MD026, MD036) individually with Edit — these are low-count and context-specific.

## Final verification

Always re-run the linter after all fixes — the batch script handles common cases but can miss edge cases (headings in blockquotes, etc.).

```shell
npx markdownlint-cli2 "**/*.md" "#node_modules" 2>&1
```

Expect `Summary: 0 error(s)`.
