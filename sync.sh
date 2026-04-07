#!/usr/bin/env bash
# Sync skills listed in .shared-skills from ~/.claude/skills/ into this repo.
# Run from the repo root. Review `git diff` afterwards before committing.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="${HOME}/.claude/skills"
LIST="${REPO_ROOT}/.shared-skills"

if [[ ! -d "$SRC" ]]; then
  echo "error: source directory not found: $SRC" >&2
  exit 1
fi

if [[ ! -f "$LIST" ]]; then
  echo "error: $LIST not found" >&2
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "error: rsync is required" >&2
  exit 1
fi

while IFS= read -r line || [[ -n "$line" ]]; do
  # strip comments and whitespace
  name="${line%%#*}"
  name="${name#"${name%%[![:space:]]*}"}"
  name="${name%"${name##*[![:space:]]}"}"
  [[ -z "$name" ]] && continue

  src_dir="${SRC}/${name}"
  dst_dir="${REPO_ROOT}/${name}"

  if [[ ! -d "$src_dir" ]]; then
    echo "skip: $name (not found at $src_dir)"
    continue
  fi

  echo "sync: $name"
  mkdir -p "$dst_dir"
  rsync -a --delete \
    --exclude='.DS_Store' \
    --exclude='__pycache__' \
    "${src_dir}/" "${dst_dir}/"
done < "$LIST"

echo "done. review changes with: git status && git diff"
