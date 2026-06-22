---
name: agent-enable
description: Re-enable a disabled agent by stripping the .off extension. Explicit-only.
disable-model-invocation: true
allowed-tools: Bash(bash:*)
---
Run `bash "$CLAUDE_PROJECT_DIR/scripts/roster.sh" enable $ARGUMENTS` and report the result. Do nothing else.
