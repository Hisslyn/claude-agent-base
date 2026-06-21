#!/usr/bin/env bash
# tune-roster.sh — owns the resumable bulk-tune loop: manifest, resume,
# per-file git commit, backups, exclusions. It does NOT tune anything;
# the caller invokes the agent-manager subagent per file (see /agents-tune).
# Usage:
#   tune-roster.sh [--pass <id>] init "<standard or ref>" [--fresh]
#   tune-roster.sh [--pass <id>] next      # -> "<file>\n---STANDARD---\n<std>" or "DONE"
#   tune-roster.sh [--pass <id>] done <name>   # mark done; commit that file if in git
#   tune-roster.sh [--pass <id>] status
#   tune-roster.sh [--pass <id>] finish    # clean .bak + manifest once all done
# --pass <id> runs an independent pass (its own manifest), so several passes /
# subsets can coexist (QA-023). Transient state lives outside the agents tree
# (QA-026). AGENTS_DIR overrides auto-detection.
set -euo pipefail

err() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

PASS_ID="default"
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
  --pass)
    [[ $# -ge 2 ]] || err "usage: --pass <id>"
    PASS_ID="$2"
    shift 2
    ;;
  *)
    ARGS+=("$1")
    shift
    ;;
  esac
done
if ((${#ARGS[@]})); then set -- "${ARGS[@]}"; else set --; fi
[[ "$PASS_ID" =~ ^[A-Za-z0-9._-]+$ ]] || err "invalid --pass id: $PASS_ID"

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

# Transient state (manifest, .bak backups, lock) outside the discovery tree:
# under the git dir when available, else a TMPDIR slot keyed by the agents dir.
state_dir() {
  local dir gd tmp
  dir="$(agents_dir)"
  if gd="$(git -C "$dir" rev-parse --absolute-git-dir 2>/dev/null)"; then
    printf '%s/agent-roster' "$gd"
  else
    tmp="${TMPDIR:-/tmp}"
    tmp="${tmp%/}"
    printf '%s/agent-roster-%s' "$tmp" "$(printf '%s' "$dir" | sha256sum | cut -c1-12)"
  fi
}

manifest() { printf '%s/manifest-%s' "$(state_dir)" "$PASS_ID"; }

LOCK=""
release_lock() {
  if [[ -n "$LOCK" ]]; then
    rmdir "$LOCK" 2>/dev/null || true
  fi
  LOCK=""
}
trap 'release_lock' EXIT

# Portable mutual exclusion (flock is absent on macOS): atomic mkdir spin so
# concurrent next/done calls can't hand out or commit the same file (QA-017).
acquire_lock() {
  local sd n=0
  sd="$(state_dir)"
  mkdir -p "$sd"
  LOCK="$sd/.lock-$PASS_ID"
  until mkdir "$LOCK" 2>/dev/null; do
    n=$((n + 1))
    ((n > 200)) && err "could not acquire pass lock: $LOCK"
    sleep 0.05
  done
}

# Frontmatter value with inline comment + surrounding quotes stripped (QA-022).
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

# Current path of an agent by name (re-resolved, so a mid-pass lock/disable/
# rename does not leave `done` pointing at a stale path) (QA-020).
resolve_by_name() {
  local dir="$1" name="$2" f
  [[ -f "$dir/$name.md" ]] && {
    printf '%s' "$dir/$name.md"
    return
  }
  while IFS= read -r f; do
    [[ "$(fm_field "$f" name)" == "$name" ]] && {
      printf '%s' "$f"
      return
    }
  done < <(find -L "$dir" -type f -name '*.md' ! -name '*.md.off' -not -path '*/locked_*')
}

stored_hash() { [[ -f "$(manifest)" ]] && grep '^# hash ' "$(manifest)" | head -1 | cut -d' ' -f3 || true; }
stored_standard() { [[ -f "$(manifest)" ]] && sed -n 's/^# standard //p' "$(manifest)" | head -1 || true; }

cmd_init() {
  acquire_lock
  local dir std fresh=0 h mf sd
  dir="$(agents_dir)"
  std="${1:-}"
  [[ -n "$std" ]] || err "usage: tune-roster.sh init \"<standard>\" [--fresh]"
  [[ "${2:-}" == "--fresh" ]] && fresh=1
  h="$(hash_standard "$std")"
  mf="$(manifest)"
  sd="$(state_dir)"
  mkdir -p "$sd"
  if [[ -f "$mf" && $fresh -eq 0 ]]; then
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
  } >"$mf"
  if ! in_git "$dir"; then
    tunable_files "$dir" | while IFS= read -r f; do cp -- "$f" "$sd/$(basename "$f").bak"; done
    printf 'not a git repo: backed up tunable files to .bak\n'
  fi
  cmd_status
}

cmd_next() {
  acquire_lock
  local mf line name file tmp
  mf="$(manifest)"
  [[ -f "$mf" ]] || err "no manifest; run init first"
  line="$(grep -m1 $'\tpending\t' "$mf" || true)"
  if [[ -z "$line" ]]; then
    printf 'DONE\n'
    return
  fi
  name="$(printf '%s' "$line" | cut -f1)"
  file="$(printf '%s' "$line" | cut -f3)"
  # Claim it: pending -> inprogress, so no other worker is handed the same file.
  tmp="$(mktemp)"
  awk -F'\t' -v OFS='\t' -v n="$name" '$1 == n && $2 == "pending" { $2 = "inprogress" } { print }' "$mf" >"$tmp"
  mv -- "$tmp" "$mf"
  printf '%s\n---STANDARD---\n%s\n' "$file" "$(stored_standard)"
}

cmd_done() {
  acquire_lock
  local dir name tmp file mf
  dir="$(agents_dir)"
  name="${1:-}"
  [[ -n "$name" ]] || err "usage: tune-roster.sh done <name>"
  mf="$(manifest)"
  [[ -f "$mf" ]] || err "no manifest"
  grep -q "^$name"$'\t' "$mf" || err "unknown agent: $name"
  tmp="$(mktemp)"
  awk -F'\t' -v OFS='\t' -v n="$name" '$1 == n { $2 = "done" } { print }' "$mf" >"$tmp"
  mv -- "$tmp" "$mf"
  file="$(resolve_by_name "$dir" "$name")"
  if in_git "$dir" && [[ -n "$file" && -f "$file" ]]; then
    git -C "$dir" add -- "$file"
    git -C "$dir" commit -m "agents: tune $name" -- "$file" >/dev/null 2>&1 || true
  fi
  cmd_status
}

cmd_status() {
  local m total done_n nextn
  m="$(manifest)"
  [[ -f "$m" ]] || err "no manifest"
  total="$(grep -cE $'\t(pending|inprogress|done)\t' "$m" || true)"
  done_n="$(grep -cE $'\tdone\t' "$m" || true)"
  nextn="$(grep -m1 -E $'\t(pending|inprogress)\t' "$m" | cut -f1 || true)"
  printf 'ROSTER PASS: %s/%s done — next: %s\n' "${done_n:-0}" "${total:-0}" "${nextn:-DONE}"
}

cmd_finish() {
  acquire_lock
  local mf sd b
  mf="$(manifest)"
  [[ -f "$mf" ]] || err "no manifest"
  grep -qE $'\t(pending|inprogress)\t' "$mf" && err "pass not complete; run until DONE first"
  sd="$(state_dir)"
  shopt -s nullglob
  for b in "$sd"/*.bak; do rm -- "$b"; done
  rm -f -- "$mf"
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
_manifest) manifest ;;
_statedir) state_dir ;;
*) err "usage: tune-roster.sh [--pass <id>] init|next|done|status|finish" ;;
esac
