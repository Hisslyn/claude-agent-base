#!/usr/bin/env bash
# new-agent.sh — scaffold a new agent file from templates/base-agent.md (deterministic).
# Usage: new-agent.sh <kebab-name> <full-model-id> [role description words...]
# Writes <AGENTS_DIR>/<name>.md and refuses to overwrite. The scaffold carries NO
# inert invocation fields (disable-model-invocation / user-invocable are inert on
# subagents); tighten routing and tools via the agent-manager subagent afterward.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
template="$here/../templates/base-agent.md"

# Pinned model IDs (agent-roster-reference skill, "Pinned facts (v2)").
OPUS_ID="claude-opus-4-8"
SONNET_ID="claude-sonnet-5"
HAIKU_ID="claude-haiku-4-5"

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
[[ -n "$name" ]] || err "usage: new-agent.sh <kebab-name> <full-model-id> [role...]"
# Kebab-case, with an optional leading underscore for throwaway/test agents (QA-012).
[[ "$name" =~ ^_?[a-z0-9]+(-[a-z0-9]+)*$ ]] || err "name must be kebab-case (optionally _-prefixed)"
shift || true

model="${1:-}"
[[ -n "$model" ]] || err "usage: new-agent.sh <kebab-name> <full-model-id> [role...]"
# Reject bare aliases — agent files must carry full pinned model IDs.
case "$model" in
  opus|sonnet|haiku)
    err "model must be a full pinned ID, not the alias '$model' (use one of: $OPUS_ID, $SONNET_ID, $HAIKU_ID)"
    ;;
esac
shift || true

# Remaining args are the role/description. Quoted end-to-end below; never re-expanded
# by the shell after this assignment, so metacharacters in $role/$name are inert.
role="${*:-Describe the role.}"

[[ -f "$template" ]] || err "template not found: $template"

dir="$(agents_dir)"
file="$dir/$name.md"
[[ -e "$file" ]] && err "already exists: $file"

# Substitute placeholders literally (no eval, no shell re-expansion of user input):
# read the template line by line and replace the three placeholder tokens with the
# quoted variable values via bash parameter expansion.
scaffold=""
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line//<kebab-name>/$name}"
  line="${line//<TIER_ID>/$model}"
  case "$line" in
    "description:"*)
      line="description: $role"
      ;;
  esac
  scaffold+="$line"$'\n'
done <"$template"

printf '%s' "$scaffold" >"$file"

# The shell-redirect write above is not a Claude tool call, so the PostToolUse
# validate-frontmatter hook never fires here — validate explicitly (QA-013).
if ! python3 "$here/validate-frontmatter.py" --force "$file"; then
  rm -f "$file"
  err "scaffold failed frontmatter validation (removed): $file"
fi

printf 'created: %s\n' "$file"
printf 'next: write a real description and tighten tools via the agent-manager subagent.\n'
