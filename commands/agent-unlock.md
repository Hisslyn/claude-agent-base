---
name: agent-unlock
description: Unlock an agent file by removing the locked_ prefix. Explicit-only.
disable-model-invocation: true
allowed-tools: Bash(bash:*)
---
Run `bash "$CLAUDE_PROJECT_DIR/scripts/roster.sh" unlock $ARGUMENTS` and report the result. Do nothing else.
