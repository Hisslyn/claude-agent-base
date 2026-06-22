#!/usr/bin/env bash
# install.sh — wire the agent-base into a project's .claude/ so Claude Code
# discovers it (project-vendored model). Source dirs (agents/, skills/,
# commands/) are NOT discovery paths on their own; they must live under
# .claude/, and scripts must be reachable as $CLAUDE_PROJECT_DIR/scripts (QA-008).
# Usage: install.sh [TARGET_PROJECT_DIR]   (defaults to this repo root)
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(dirname "$here")"
target="${1:-$root}"
target="$(cd "$target" && pwd)"

link() {
  local src="$1" dst="$2"
  if [[ -e "$dst" || -L "$dst" ]]; then
    printf 'skip (exists): %s\n' "$dst"
    return
  fi
  ln -s "$src" "$dst"
  printf 'linked: %s -> %s\n' "$dst" "$src"
}

mkdir -p "$target/.claude"
for d in agents skills commands; do
  link "$root/$d" "$target/.claude/$d"
done

# When installing into a different project, vendor the scripts so the commands'
# $CLAUDE_PROJECT_DIR/scripts/<x> path resolves there too.
if [[ "$target" != "$root" ]]; then
  link "$root/scripts" "$target/scripts"
fi

chmod +x "$root"/scripts/*.sh 2>/dev/null || true
chmod +x "$root"/scripts/*.py 2>/dev/null || true

if [[ -e "$target/.claude/settings.json" ]]; then
  printf 'note: %s exists — merge hooks/settings.snippet.json yourself\n' "$target/.claude/settings.json"
else
  cat >"$target/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          { "type": "command", "command": "python3 \"$CLAUDE_PROJECT_DIR/scripts/validate-frontmatter.py\"" }
        ]
      }
    ]
  }
}
JSON
  printf 'wrote %s (validate-frontmatter PostToolUse hook)\n' "$target/.claude/settings.json"
fi

printf '\nDONE. Restart Claude Code so it discovers .claude/{agents,skills,commands}.\n'
