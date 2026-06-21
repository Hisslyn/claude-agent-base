#!/usr/bin/env bash
# roster.sh — deterministic agent-roster operations (no LLM).
# Usage:
#   roster.sh list
#   roster.sh lock|unlock <name>
#   roster.sh disable|enable <name>
# <name> is the frontmatter name or the file stem (with or without .md).
# AGENTS_DIR overrides auto-detection.
set -euo pipefail

err() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

agents_dir() {
  if [[ -n "${AGENTS_DIR:-}" ]]; then
    printf '%s' "$AGENTS_DIR"
    return
  fi
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$root" && -d "$root/.claude/agents" ]]; then
    printf '%s' "$root/.claude/agents"
    return
  fi
  if [[ -d "$HOME/.claude/agents" ]]; then
    printf '%s' "$HOME/.claude/agents"
    return
  fi
  err "no agents dir found (set AGENTS_DIR)"
}

# Value of a frontmatter key from the block between the first two --- fences.
fm_field() {
  awk -v key="$2" '
    /^---[[:space:]]*$/ { f++; if (f==2) exit; next }
    f==1 && $0 ~ "^"key":" { sub("^"key":[[:space:]]*",""); print; exit }
  ' "$1"
}

# Resolve <name> to an existing file path inside DIR.
resolve_file() {
  local dir="$1" name="$2" f
  name="${name%.md}"
  for f in "$dir/$name.md" "$dir/$name"; do
    [[ -f "$f" ]] && {
      printf '%s' "$f"
      return
    }
  done
  while IFS= read -r f; do
    [[ "$(fm_field "$f" name)" == "$name" ]] && {
      printf '%s' "$f"
      return
    }
  done < <(find -L "$dir" -type f -name '*.md' ! -name '*.md.off')
  err "agent not found: $2"
}

is_locked_path() { [[ "$1" == *"/locked_"* ]]; }

cmd_list() {
  local dir
  dir="$(agents_dir)"
  printf 'agents in %s\n\n' "$dir"
  printf 'ACTIVE (name | model | file)\n'
  find -L "$dir" -type f -name '*.md' ! -name '*.md.off' -not -path '*/locked_*' |
    sort | while IFS= read -r f; do
    printf '  %s | %s | %s\n' \
      "$(fm_field "$f" name)" "$(fm_field "$f" model)" "$(basename "$f")"
  done
  printf '\nLOCKED (filename only — contents not read)\n'
  find -L "$dir" -type f \( -name 'locked_*' -o -path '*/locked_*' \) ! -name '*.md.off' |
    sort | sed "s#^$dir/#  #" || true
  printf '\nDISABLED (.off)\n'
  find -L "$dir" -type f -name '*.md.off' | sort | sed "s#^$dir/#  #" || true
}

cmd_lock() {
  local dir f base
  dir="$(agents_dir)"
  f="$(resolve_file "$dir" "$1")"
  is_locked_path "$f" && err "already locked: $1"
  base="$(basename "$f")"
  mv -n -- "$f" "$(dirname "$f")/locked_$base"
  printf 'locked: %s -> locked_%s\n' "$base" "$base"
}

cmd_unlock() {
  local dir name f base stem
  dir="$(agents_dir)"
  name="${1%.md}"
  while IFS= read -r f; do
    base="$(basename "$f")"
    stem="${base#locked_}"
    stem="${stem%.md}"
    if [[ "$stem" == "$name" || "$(fm_field "$f" name)" == "$name" ]]; then
      mv -n -- "$f" "$(dirname "$f")/${base#locked_}"
      printf 'unlocked: %s\n' "$base"
      return
    fi
  done < <(find -L "$dir" -type f -name 'locked_*' ! -name '*.md.off')
  err "not locked (per-file): $1"
}

cmd_disable() {
  local dir f
  dir="$(agents_dir)"
  f="$(resolve_file "$dir" "$1")"
  is_locked_path "$f" && err "locked: unlock first"
  mv -n -- "$f" "$f.off"
  printf 'disabled: %s -> %s.off\n' "$(basename "$f")" "$(basename "$f")"
}

cmd_enable() {
  local dir name f base stem
  dir="$(agents_dir)"
  name="${1%.md}"
  while IFS= read -r f; do
    base="$(basename "$f")"
    stem="${base%.md.off}"
    if [[ "$stem" == "$name" || "$(fm_field "$f" name)" == "$name" ]]; then
      mv -n -- "$f" "${f%.off}"
      printf 'enabled: %s\n' "$(basename "${f%.off}")"
      return
    fi
  done < <(find -L "$dir" -type f -name '*.md.off')
  err "not disabled: $1"
}

case "${1:-}" in
list) cmd_list ;;
lock)
  [[ $# -ge 2 ]] || err "usage: roster.sh lock <name>"
  cmd_lock "$2"
  ;;
unlock)
  [[ $# -ge 2 ]] || err "usage: roster.sh unlock <name>"
  cmd_unlock "$2"
  ;;
disable)
  [[ $# -ge 2 ]] || err "usage: roster.sh disable <name>"
  cmd_disable "$2"
  ;;
enable)
  [[ $# -ge 2 ]] || err "usage: roster.sh enable <name>"
  cmd_enable "$2"
  ;;
*) err "usage: roster.sh list|lock|unlock|disable|enable [name]" ;;
esac
