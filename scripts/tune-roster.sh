#!/usr/bin/env bash
# tune-roster.sh — owns the resumable bulk-tune loop: manifest, resume,
# per-file git commit, backups, exclusions. It does NOT tune anything;
# the caller invokes the agent-manager subagent per file (see /agents-tune).
# Usage:
#   tune-roster.sh init "<standard or ref>" [--fresh]
#   tune-roster.sh next            # -> "<file>\n---STANDARD---\n<standard>"  or  "DONE"
#   tune-roster.sh done <name>     # mark done; commit that file if in git
#   tune-roster.sh status
#   tune-roster.sh finish          # clean .bak + manifest once all done
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

fm_field() {
  awk -v key="$2" '
    /^---[[:space:]]*$/ { f++; if (f==2) exit; next }
    f==1 && $0 ~ "^"key":" { sub("^"key":[[:space:]]*",""); print; exit }
  ' "$1"
}

hash_standard() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' ' |
    sed 's/^ //;s/ $//' | sha256sum | cut -d' ' -f1
}

in_git() { git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1; }

# Tunable = active, unlocked, not the manager, not a backup/manifest.
tunable_files() {
  local dir="$1" f
  while IFS= read -r f; do
    [[ "$(basename "$f")" == agent-manager.md ]] && continue
    [[ "$(fm_field "$f" name)" == "agent-manager" ]] && continue
    printf '%s\n' "$f"
  done < <(find -L "$dir" -type f -name '*.md' ! -name '*.md.off' -not -path '*/locked_*' | sort)
}

manifest() { printf '%s/_roster_manifest' "$(agents_dir)"; }
stored_hash() { [[ -f "$(manifest)" ]] && grep '^# hash ' "$(manifest)" | head -1 | cut -d' ' -f3 || true; }
stored_standard() { [[ -f "$(manifest)" ]] && sed -n 's/^# standard //p' "$(manifest)" | head -1 || true; }

cmd_init() {
  local dir std fresh=0 h
  dir="$(agents_dir)"
  std="${1:-}"
  [[ -n "$std" ]] || err "usage: tune-roster.sh init \"<standard>\" [--fresh]"
  [[ "${2:-}" == "--fresh" ]] && fresh=1
  h="$(hash_standard "$std")"
  if [[ -f "$(manifest)" && $fresh -eq 0 ]]; then
    if [[ "$(stored_hash)" == "$h" ]]; then
      printf 'resuming existing pass\n'
      cmd_status
      return
    fi
    err "a different standard is in progress; pass --fresh to reset (this re-tunes the whole roster)"
  fi
  {
    printf '# hash %s\n' "$h"
    printf '# standard %s\n' "$(printf '%s' "$std" | tr '\n' ' ')"
    tunable_files "$dir" | while IFS= read -r f; do
      printf '%s\tpending\t%s\n' "$(fm_field "$f" name)" "$f"
    done
  } >"$(manifest)"
  if ! in_git "$dir"; then
    tunable_files "$dir" | while IFS= read -r f; do cp -- "$f" "$f.bak"; done
    printf 'not a git repo: backed up tunable files to .bak\n'
  fi
  cmd_status
}

cmd_next() {
  local line file
  [[ -f "$(manifest)" ]] || err "no manifest; run init first"
  line="$(grep -m1 $'\tpending\t' "$(manifest)" || true)"
  if [[ -z "$line" ]]; then
    printf 'DONE\n'
    return
  fi
  file="$(printf '%s' "$line" | cut -f3)"
  printf '%s\n---STANDARD---\n%s\n' "$file" "$(stored_standard)"
}

cmd_done() {
  local dir name tmp file
  dir="$(agents_dir)"
  name="${1:-}"
  [[ -n "$name" ]] || err "usage: tune-roster.sh done <name>"
  [[ -f "$(manifest)" ]] || err "no manifest"
  grep -q "^$name"$'\t' "$(manifest)" || err "unknown agent: $name"
  file="$(grep -m1 "^$name"$'\t' "$(manifest)" | cut -f3)"
  tmp="$(mktemp)"
  awk -F'\t' -v OFS='\t' -v n="$name" '$1==n{$2="done"} {print}' "$(manifest)" >"$tmp"
  mv -- "$tmp" "$(manifest)"
  if in_git "$dir" && [[ -f "$file" ]]; then
    git -C "$dir" add -- "$file"
    git -C "$dir" commit -m "agents: tune $name" -- "$file" >/dev/null 2>&1 || true
  fi
  cmd_status
}

cmd_status() {
  local m total done_n nextn
  m="$(manifest)"
  [[ -f "$m" ]] || err "no manifest"
  total="$(grep -cE $'\t(pending|done)\t' "$m" || true)"
  done_n="$(grep -cE $'\tdone\t' "$m" || true)"
  nextn="$(grep -m1 $'\tpending\t' "$m" | cut -f1 || true)"
  printf 'ROSTER PASS: %s/%s done — next: %s\n' "${done_n:-0}" "${total:-0}" "${nextn:-DONE}"
}

cmd_finish() {
  local dir
  dir="$(agents_dir)"
  [[ -f "$(manifest)" ]] || err "no manifest"
  grep -qE $'\tpending\t' "$(manifest)" && err "pass not complete; run until DONE first"
  shopt -s nullglob
  local b
  for b in "$dir"/*.bak; do rm -- "$b"; done
  rm -- "$(manifest)"
  printf 'pass complete: removed .bak files and manifest\n'
}

case "${1:-}" in
init)
  shift
  cmd_init "$@"
  ;;
next) cmd_next ;;
done) cmd_done "${2:-}" ;;
status) cmd_status ;;
finish) cmd_finish ;;
*) err "usage: tune-roster.sh init|next|done|status|finish" ;;
esac
