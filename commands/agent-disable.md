---
name: agent-disable
description: Disable (remove from rotation) an agent by renaming it to .md.off. Reversible. Explicit-only.
disable-model-invocation: true
allowed-tools: Bash(bash:*)
---
Run `bash "$CLAUDE_PROJECT_DIR/scripts/roster.sh" disable $ARGUMENTS` and report the result. Do nothing else.
