#!/usr/bin/env bash
# new-agent.sh — scaffold a new agent file from the template (deterministic).
# Usage: new-agent.sh <kebab-name> [role description words...]
# Writes <AGENTS_DIR>/<name>.md and refuses to overwrite. Refine the
# description and tool list afterward via the agent-manager subagent.
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

name="${1:-}"
[[ -n "$name" ]] || err "usage: new-agent.sh <kebab-name> [role...]"
[[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || err "name must be kebab-case"
shift || true
role="${*:-Describe the role.}"

dir="$(agents_dir)"
file="$dir/$name.md"
[[ -e "$file" ]] && err "already exists: $file"

cat >"$file" <<EOF
---
name: $name
description: $role When to use it; what triggers auto-delegation. (Or add 'disable-model-invocation: true' for explicit-only.)
model: sonnet
tools:
  - Read
---
You are $name. $role

## Responsibilities
- TODO

## Output
- TODO

## Handoff
Return results to the caller with a recommendation for what to run next (no agent spawns another).

## Token rules
No preamble. No recap. No filler. Stop when done.
EOF

printf 'created: %s\n' "$file"
printf 'next: refine description + tools via the agent-manager subagent.\n'
