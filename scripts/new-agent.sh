#!/usr/bin/env bash
# new-agent.sh — scaffold a new agent file from the template (deterministic).
# Usage: new-agent.sh <kebab-name> [role description words...]
# Writes <AGENTS_DIR>/<name>.md and refuses to overwrite. The scaffold ships
# disable-model-invocation: true so an unrefined agent cannot auto-route until
# its description is written and the field removed via the agent-manager subagent.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"

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
# Kebab-case, with an optional leading underscore for throwaway/test agents (QA-012).
[[ "$name" =~ ^_?[a-z0-9]+(-[a-z0-9]+)*$ ]] || err "name must be kebab-case (optionally _-prefixed)"
shift || true
role="${*:-Describe the role.}"

dir="$(agents_dir)"
file="$dir/$name.md"
[[ -e "$file" ]] && err "already exists: $file"

cat >"$file" <<EOF
---
name: $name
description: $role
model: sonnet
disable-model-invocation: true
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

# The shell-redirect write above is not a Claude tool call, so the PostToolUse
# validate-frontmatter hook never fires here — validate explicitly (QA-013).
if ! python3 "$here/validate-frontmatter.py" --force "$file"; then
  rm -f "$file"
  err "scaffold failed frontmatter validation (removed): $file"
fi

printf 'created: %s\n' "$file"
printf 'next: write a real description, drop disable-model-invocation, and tighten tools via the agent-manager subagent.\n'
