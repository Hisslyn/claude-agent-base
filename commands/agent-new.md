---
name: agent-new
description: Scaffold a new agent file from the template, then refine it. Use when adding an agent for a real workflow gap.
allowed-tools: Bash(bash:*), Task
---
`$ARGUMENTS` is the kebab-case name followed by a short role description.

1. Split `$ARGUMENTS` into the kebab-case name and the role description, then run `bash "$CLAUDE_PROJECT_DIR/scripts/new-agent.sh" "<name>" "<role description>"` — quote each piece as its own shell word so spaces or shell-special characters in the role text are not word-split or glob-expanded.
2. Invoke the **agent-manager** subagent to refine the new file's description (for correct auto-delegation) and tighten its tool list to the minimum needed.
