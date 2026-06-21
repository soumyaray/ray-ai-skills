#!/usr/bin/env bash
# Show how skills under ~/.claude/skills/ relate to this repo's mirror.
# Reports four groups:
#   1. source-only   — skills in ~/.claude/skills/ not listed in .shared-skills
#   2. missing-source — names in .shared-skills with no matching source dir
#   3. orphaned-repo  — mirrored skill dirs (have SKILL.md) not in .shared-skills
#   4. drifted        — listed+mirrored skills whose content differs from source
# Read-only: changes nothing. Run from the repo root.

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

# Registered names, comments/blank lines stripped, sorted.
registered() {
  grep -vE '^\s*(#|$)' "$LIST" | sed 's/[[:space:]]//g' | sort -u
}

# Skill dirs (those containing a SKILL.md) directly under a given root, sorted.
skill_dirs() {
  local root="$1"
  [[ -d "$root" ]] || return 0
  find "$root" -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/SKILL.md' ';' -print \
    | sed 's|.*/||' | sort -u
}

reg="$(registered)"
src="$(skill_dirs "$SRC")"
repo="$(skill_dirs "$REPO_ROOT")"

echo "=== source-only (in ~/.claude/skills/, not in .shared-skills) ==="
comm -23 <(printf '%s\n' "$src") <(printf '%s\n' "$reg") | sed 's/^/  + /' || true
echo

echo "=== missing-source (in .shared-skills, no source dir) ==="
comm -23 <(printf '%s\n' "$reg") <(printf '%s\n' "$src") | sed 's/^/  ! /' || true
echo

echo "=== orphaned-repo (mirrored dir, not in .shared-skills) ==="
comm -23 <(printf '%s\n' "$repo") <(printf '%s\n' "$reg") | sed 's/^/  ? /' || true
echo

echo "=== drifted (listed + mirrored, content differs from source) ==="
while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  src_dir="${SRC}/${name}"
  dst_dir="${REPO_ROOT}/${name}"
  [[ -d "$src_dir" && -d "$dst_dir" ]] || continue
  if ! diff -rq \
      --exclude='.DS_Store' --exclude='__pycache__' \
      --exclude='.Rhistory' --exclude='.RData' \
      "$src_dir" "$dst_dir" >/dev/null 2>&1; then
    echo "  ~ ${name}"
  fi
done <<< "$reg"
echo

echo "done. add a source-only skill to the mirror by listing it in .shared-skills, then ./sync.sh"
