---
name: agent-new
description: Scaffold a new agent file from the template, then refine it. Use when adding an agent for a real workflow gap.
---
`$ARGUMENTS` is the kebab-case name followed by a short role description.

1. Run `bash scripts/new-agent.sh $ARGUMENTS` to write the skeleton.
2. Invoke the **agent-manager** subagent to refine the new file's description (for correct auto-delegation) and tighten its tool list to the minimum needed.
