#!/usr/bin/env bash
# Install skills from this repo into ~/.claude/skills/ as symlinks.
#
# Each top-level directory containing a SKILL.md is treated as an installable
# skill. Existing entries in ~/.claude/skills/<name> are NOT overwritten unless
# you pass --force (which moves the existing entry aside to <name>.bak-<ts>).
#
# Usage:
#   ./install.sh                 # install all skills
#   ./install.sh ray-commit ...  # install only the named skills
#   ./install.sh --force [...]   # back up and replace existing entries

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="${HOME}/.claude/skills"

force=0
selected=()
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *) selected+=("$arg") ;;
  esac
done

mkdir -p "$DEST"

install_one() {
  local name="$1"
  local src="${REPO_ROOT}/${name}"
  local dst="${DEST}/${name}"

  if [[ ! -f "${src}/SKILL.md" ]]; then
    echo "skip: $name (no SKILL.md in $src)"
    return
  fi

  if [[ -L "$dst" ]]; then
    local current
    current="$(readlink "$dst")"
    if [[ "$current" == "$src" ]]; then
      echo "ok:   $name (already linked)"
      return
    fi
    if [[ "$force" -eq 1 ]]; then
      rm "$dst"
    else
      echo "skip: $name (symlink exists -> $current; use --force to replace)"
      return
    fi
  elif [[ -e "$dst" ]]; then
    if [[ "$force" -eq 1 ]]; then
      local backup="${dst}.bak-$(date +%Y%m%d%H%M%S)"
      mv "$dst" "$backup"
      echo "back: $name -> $(basename "$backup")"
    else
      echo "skip: $name (exists at $dst; use --force to back up and replace)"
      return
    fi
  fi

  ln -s "$src" "$dst"
  echo "link: $name"
}

if [[ ${#selected[@]} -gt 0 ]]; then
  for name in "${selected[@]}"; do
    install_one "$name"
  done
else
  for dir in "${REPO_ROOT}"/*/; do
    name="$(basename "$dir")"
    install_one "$name"
  done
fi
