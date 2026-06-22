---
name: agent-lock
description: Lock an agent file (edit-protection) by adding the locked_ prefix. Explicit-only.
disable-model-invocation: true
allowed-tools: Bash(bash:*)
---
Run `bash "$CLAUDE_PROJECT_DIR/scripts/roster.sh" lock $ARGUMENTS` and report the result. Do nothing else.
