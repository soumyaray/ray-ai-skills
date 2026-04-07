---
name: ray-papers-library
description: >
  Find and retrieve academic papers/PDFs from the user's ReadCube Papers reference library
  (default location on macOS: `~/Documents/Papers Library/`). Use this skill whenever the user asks to
  find, retrieve, locate, search for, or get a paper, PDF, reference, citation, or article
  from their library. Trigger on phrases like "find the PDF", "retrieve the pdf",
  "can you retrieve", "do you have the paper", "locate the paper", "search my papers",
  "from my Papers app", "in my library", "where is that file", or when the user references
  a specific author/year combination that needs to be found as a file. Also trigger when
  the user says "do you wish I provide a PDF" or similar — check the library first before
  asking the user to provide it. Also trigger when the user asks about categorization,
  collections, lists, tags, or how papers are organized — e.g., "what papers do I have on
  logistic regression", "what list is this paper in", "show me my collections",
  "papers tagged with X", "check my papers library for".
---

# Papers Library Search

Search for academic papers in the Papers Library managed by the ReadCube Papers reference manager app.

## Library location

Default location for ReadCube Papers on macOS:

```
~/Documents/Papers Library/
```

This is the standard ReadCube install location. If the user's library lives elsewhere, substitute that path everywhere this skill references the library.

## Papers database location

ReadCube Papers stores all categorization metadata in a SQLite database. There is a single `.db` file in the Papers app support directory — find it dynamically:

```
~/Library/Application Support/Papers/*.db
```

To resolve the path before querying:
```bash
PAPERS_DB="$(ls ~/Library/Application\ Support/Papers/*.db)"
sqlite3 "$PAPERS_DB" "SELECT ..."
```

**IMPORTANT:** This database must only be queried with read-only `SELECT` statements. Never run `INSERT`, `UPDATE`, `DELETE`, `CREATE`, `DROP`, or any other write operation.

## Filename conventions

Most files follow the pattern `Author-Year-Title Keywords.pdf`, e.g.:
- `Trommsdorf-1994-Future Time Perspective and Control Orientation- Social Conditions and Consequences.pdf`
- `Bandura-1997-Self-Efficacy.pdf`

Some files use opaque IDs (UUIDs, numeric IDs) with no author/title info. These cannot be matched by filename alone — use the database to find them.

## Database schema overview

The database uses a JSON-in-SQLite design. Key tables:

| Table | Records | Purpose |
|-------|---------|---------|
| `items` | ~1,538 active | Individual papers. Each row has an `id` (UUID) and a `json` blob with article metadata, file paths, and user data. |
| `lists` | ~632 active | Manual collections/folders. **Hierarchical** (up to 4+ levels deep via `parent_id`). Each stores an `item_ids` JSON array linking to items. |
| `smartlists` | 2 | Saved search queries (legacy, mostly incomplete). |
| `collections` | 1 | Single top-level library container. |
| `groups` | 0 | Unused. |

### Item JSON structure (key fields)

```
json_extract(json, '$.article.title')    -- paper title
json_extract(json, '$.article.authors')  -- JSON array of author names
json_extract(json, '$.article.year')     -- publication year
json_extract(json, '$.article.journal')  -- journal name
json_extract(json, '$.article.abstract') -- abstract text
json_extract(json, '$.article.url')      -- URL
json_extract(json, '$.ext_ids.doi')      -- DOI
json_extract(json, '$.deleted')          -- true if deleted
json_extract(json, '$.files')            -- array with localPath, file info
json_extract(json, '$.user_data.star')   -- boolean, starred
json_extract(json, '$.user_data.color')  -- color label
json_extract(json, '$.user_data.rating') -- 0-5 rating
json_extract(json, '$.user_data.tags')   -- JSON array of tag strings
json_extract(json, '$.user_data.notes')  -- free-text notes
json_extract(json, '$.user_data.citekey') -- BibTeX cite key
json_extract(json, '$.user_data.unread') -- boolean
```

### List JSON structure (key fields)

```
json_extract(json, '$.name')       -- list name
json_extract(json, '$.id')         -- list UUID
json_extract(json, '$.parent_id')  -- parent list UUID (null if top-level)
json_extract(json, '$.item_ids')   -- JSON array of item UUIDs
json_extract(json, '$.deleted')    -- true if deleted
json_array_length(json, '$.item_ids') -- number of items in list
```

## Search strategy

### 1. File-based search (fast, for finding PDFs by author/year/title)

Extract **author surname** and/or **year** and/or **title keywords** from the request, then:

1. **Glob by author+year**: `*Author*Year*` in the Papers Library directory.
2. **Glob by author only**: `*[Aa]uthor*` as fallback.
3. **Glob by year only**: `*Year*` as further fallback.
4. **Fuzzy matching**: Try shorter prefixes (first 5-6 chars) or alternate spellings.

### 2. Database search (for categorization, metadata, and opaque-ID files)

Use when: the user asks about collections/lists/categories, asks "what papers do I have on X", or when file-based search fails (e.g., UUID-named files).

**Find which lists a paper belongs to (by title or author):**
```sql
SELECT json_extract(l.json, '$.name') AS list_name
FROM lists l, json_each(l.json, '$.item_ids') je
JOIN items i ON i.id = je.value
WHERE json_extract(i.json, '$.article.title') LIKE '%search term%'
  AND json_extract(l.json, '$.deleted') != 1;
```

**List all papers in a given list (by list name):**
```sql
SELECT json_extract(i.json, '$.article.title') AS title,
       json_extract(i.json, '$.article.authors') AS authors,
       json_extract(i.json, '$.article.year') AS year
FROM lists l, json_each(l.json, '$.item_ids') je
JOIN items i ON i.id = je.value
WHERE json_extract(l.json, '$.name') = 'List Name'
  AND json_extract(l.json, '$.deleted') != 1;
```

**Search for lists by name (partial match):**
```sql
SELECT json_extract(json, '$.name') AS name,
       json_array_length(json, '$.item_ids') AS item_count
FROM lists
WHERE json_extract(json, '$.name') LIKE '%keyword%'
  AND json_extract(json, '$.deleted') != 1;
```

**Show list hierarchy (parent-child):**
```sql
SELECT c.name AS child, p.name AS parent
FROM
  (SELECT json_extract(json, '$.name') AS name,
          json_extract(json, '$.parent_id') AS parent_id
   FROM lists
   WHERE json_extract(json, '$.parent_id') IS NOT NULL
     AND json_extract(json, '$.parent_id') != ''
     AND json_extract(json, '$.deleted') != 1) c
JOIN
  (SELECT json_extract(json, '$.name') AS name,
          json_extract(json, '$.id') AS id
   FROM lists) p
ON c.parent_id = p.id
ORDER BY p.name, c.name;
```

**Find top-level (root) lists:**
```sql
SELECT json_extract(json, '$.name') AS name,
       json_array_length(json, '$.item_ids') AS item_count
FROM lists
WHERE (json_extract(json, '$.parent_id') IS NULL
       OR json_extract(json, '$.parent_id') = '')
  AND json_extract(json, '$.deleted') != 1
ORDER BY name;
```

**Find items by tag:**
```sql
SELECT json_extract(json, '$.article.title') AS title,
       json_extract(json, '$.user_data.tags') AS tags
FROM items
WHERE json_extract(json, '$.user_data.tags') LIKE '%tag name%'
  AND json_extract(json, '$.deleted') != 1;
```

**Find starred/rated papers:**
```sql
SELECT json_extract(json, '$.article.title') AS title,
       json_extract(json, '$.user_data.rating') AS rating
FROM items
WHERE json_extract(json, '$.user_data.star') = 1
  AND json_extract(json, '$.deleted') != 1;
```

**Search items by author in database (useful when filename search fails):**
```sql
SELECT json_extract(json, '$.article.title') AS title,
       json_extract(json, '$.article.authors') AS authors,
       json_extract(json, '$.article.year') AS year,
       json_extract(json, '$.files[0].localPath') AS file_path
FROM items
WHERE json_extract(json, '$.article.authors') LIKE '%Author%'
  AND json_extract(json, '$.deleted') != 1;
```

### 3. Combined strategy

For most requests, start with file-based Glob search (fast). If it fails or the user asks about categorization/collections, query the database. When the database returns an item, extract `$.files[0].localPath` to get the PDF path.

## What to return

ALWAYS show the full absolute path to each matching PDF. Long paths with spaces may not be clickable in the terminal, so after showing results, offer to open the file. Format like:

```
Found in Papers Library:
~/Documents/Papers Library/Author-Year-Title.pdf

Would you like me to open it?
```

- If the user says yes (or asks to "open it", "open the file", "show me", etc.), use `open "<path>"` via Bash to open the PDF in their default app
- If multiple matches exist, list all paths and let the user pick which to open
- If no match is found, tell the user the paper wasn't found in the library
- Even when you proceed to read or use the PDF, still show the path — the user may want to open it externally
- When returning categorization info, show the list name(s) and hierarchy path if nested

## Example

User: "can you retrieve the PDF for Rothbaum et al. 1982?"

Search steps:
1. Glob: `*Rothbaum*1982*` in `~/Documents/Papers Library/`
2. If no match, try `*Rothbaum*` then `*1982*`
3. Return the path(s) found

User: "what papers do I have on logistic regression?"

Search steps:
1. Query database: find lists with name LIKE '%logistic%regression%'
2. List all papers in matching lists
3. Return titles, authors, years, and file paths
