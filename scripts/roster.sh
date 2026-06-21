#!/usr/bin/env bash
# roster.sh — deterministic agent-roster operations (no LLM).
# Usage:
#   roster.sh list
#   roster.sh lock|unlock <name>
#   roster.sh disable|enable <name>
# <name> is the frontmatter name or the file stem (with or without .md).
# AGENTS_DIR overrides auto-detection (and selects a single authoritative scope).
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

# Other discovery scopes Claude merges in (project + global). Empty when
# AGENTS_DIR pins a single authoritative scope (QA-018).
other_scope_dirs() {
  [[ -n "${AGENTS_DIR:-}" ]] && return 0
  local primary="$1" root
  root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$root" && -d "$root/.claude/agents" && "$root/.claude/agents" != "$primary" ]]; then
    printf '%s\n' "$root/.claude/agents"
  fi
  if [[ -d "$HOME/.claude/agents" && "$HOME/.claude/agents" != "$primary" ]]; then
    printf '%s\n' "$HOME/.claude/agents"
  fi
}

# Value of a frontmatter key, with inline comment and surrounding quotes
# stripped so the shell tools read the same value Claude/YAML do (QA-022).
fm_field() {
  awk -v key="$2" '
    function clean(v) {
      sub(/[ \t]+#.*$/, "", v)
      sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      if (v ~ /^".*"$/ || v ~ /^'\''.*'\''$/) v = substr(v, 2, length(v) - 2)
      return v
    }
    /^---[[:space:]]*$/ { f++; if (f == 2) exit; next }
    f == 1 && $0 ~ "^" key ":" {
      sub("^" key ":[[:space:]]*", "")
      print clean($0)
      exit
    }
  ' "$1"
}

# name<TAB>model in a single pass (QA-025: avoid two awk spawns per file).
fm_pair() {
  awk '
    function clean(v) {
      sub(/[ \t]+#.*$/, "", v)
      sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      if (v ~ /^".*"$/ || v ~ /^'\''.*'\''$/) v = substr(v, 2, length(v) - 2)
      return v
    }
    /^---[[:space:]]*$/ { f++; if (f == 2) exit; next }
    f == 1 && /^name:/ { v = $0; sub(/^name:[[:space:]]*/, "", v); nm = clean(v) }
    f == 1 && /^model:/ { v = $0; sub(/^model:[[:space:]]*/, "", v); md = clean(v) }
    END { printf "%s\t%s\n", nm, md }
  ' "$1"
}

# Resolve <name> to an existing file path inside DIR. Stem wins; on the
# frontmatter-name fallback, refuse an ambiguous (colliding) match (QA-015).
resolve_file() {
  local dir="$1" name="$2" f
  name="${name%.md}"
  for f in "$dir/$name.md" "$dir/$name"; do
    [[ -f "$f" ]] && {
      printf '%s' "$f"
      return
    }
  done
  local -a matches=()
  while IFS= read -r f; do
    [[ "$(fm_field "$f" name)" == "$name" ]] && matches+=("$f")
  done < <(find -L "$dir" -type f -name '*.md' ! -name '*.md.off')
  if ((${#matches[@]} > 1)); then
    {
      printf 'error: ambiguous name %s resolves to multiple files:\n' "$name"
      printf '  %s\n' "${matches[@]}"
    } >&2
    exit 1
  fi
  ((${#matches[@]} == 1)) && {
    printf '%s' "${matches[0]}"
    return
  }
  err "agent not found: $name"
}

is_locked_path() { [[ "$1" == *"/locked_"* ]]; }

# Warn (non-fatal) if other files reference this name — a rename/disable may
# dangle an `agents:` allowlist entry or a handoff reference (QA-020).
warn_inbound_refs() {
  local dir="$1" name="$2" target="$3" hits
  hits="$(grep -rlF --include='*.md' -- "$name" "$dir" 2>/dev/null | grep -vxF -- "$target" || true)"
  if [[ -n "$hits" ]]; then
    printf 'warning: "%s" is referenced by other files; a rename/disable may dangle:\n' "$name" >&2
    printf '%s\n' "$hits" | sed 's/^/  /' >&2
  fi
}

# Warn (non-fatal) if the name also exists in another discovery scope, since
# this op only touches the primary scope (QA-018).
warn_if_shadowed() {
  local primary="$1" name="$2" d f
  while IFS= read -r d; do
    while IFS= read -r f; do
      [[ "$(fm_field "$f" name)" == "$name" ]] &&
        printf 'warning: "%s" is also defined in another scope (%s); this op affects only %s\n' \
          "$name" "$f" "$primary" >&2
    done < <(find -L "$d" -type f -name '*.md' ! -name '*.md.off')
  done < <(other_scope_dirs "$primary")
}

# List names in another scope that collide with a name in the primary scope.
report_shadows() {
  local primary="$1" d f nm tmpp header_done=0
  local -a others=()
  while IFS= read -r d; do others+=("$d"); done < <(other_scope_dirs "$primary")
  ((${#others[@]})) || return 0
  tmpp="$(mktemp)"
  while IFS= read -r f; do fm_field "$f" name; done \
    < <(find -L "$primary" -type f -name '*.md' ! -name '*.md.off') | sort -u >"$tmpp"
  for d in "${others[@]}"; do
    while IFS= read -r f; do
      nm="$(fm_field "$f" name)"
      [[ -n "$nm" ]] || continue
      if grep -qxF -- "$nm" "$tmpp"; then
        if [[ $header_done -eq 0 ]]; then
          printf '\nSHADOWING (also defined in another scope; project shadows global)\n'
          header_done=1
        fi
        printf '  %s  (other: %s)\n' "$nm" "$f"
      fi
    done < <(find -L "$d" -type f -name '*.md' ! -name '*.md.off')
  done
  rm -f "$tmpp"
}

cmd_list() {
  local dir f pair
  dir="$(agents_dir)"
  printf 'agents in %s\n\n' "$dir"
  printf 'ACTIVE (name | model | file)\n'
  find -L "$dir" -type f -name '*.md' ! -name '*.md.off' -not -path '*/locked_*' |
    sort | while IFS= read -r f; do
    pair="$(fm_pair "$f")"
    printf '  %s | %s | %s\n' "${pair%%$'\t'*}" "${pair#*$'\t'}" "$(basename "$f")"
  done
  printf '\nLOCKED (advisory edit-protect marker only — still discovered/routable by name; use disable to remove from rotation)\n'
  find -L "$dir" -type f \( -name 'locked_*' -o -path '*/locked_*' \) ! -name '*.md.off' |
    sort | sed "s#^$dir/#  #" || true
  printf '\nDISABLED (.off)\n'
  find -L "$dir" -type f -name '*.md.off' | sort | sed "s#^$dir/#  #" || true
  report_shadows "$dir"
}

cmd_lock() {
  local dir f base nm
  dir="$(agents_dir)"
  f="$(resolve_file "$dir" "$1")"
  is_locked_path "$f" && err "already locked: $1"
  nm="$(fm_field "$f" name)"
  warn_if_shadowed "$dir" "$nm"
  warn_inbound_refs "$dir" "$nm" "$f"
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
  local dir f nm
  dir="$(agents_dir)"
  f="$(resolve_file "$dir" "$1")"
  is_locked_path "$f" && err "locked: unlock first"
  nm="$(fm_field "$f" name)"
  warn_if_shadowed "$dir" "$nm"
  warn_inbound_refs "$dir" "$nm" "$f"
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
