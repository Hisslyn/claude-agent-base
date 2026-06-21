# agent-manager, decomposed

The original single `agent-manager.md` mixed four concerns. Each now lives in the primitive that fits: reference knowledge → a skill, deterministic ops → scripts/commands, post-edit safety → a hook, judgment → a slim subagent. Invocation policy moved into frontmatter.

```
agents/
  agent-manager.md                     slim subagent — judgment only (audit, merge/split, tune, handoffs)
skills/
  agent-roster-reference/SKILL.md      knowledge — discovery, locking, delegation model, schema, template
commands/
  agents-list.md                       /agents-list            -> roster.sh list
  agent-lock.md   agent-unlock.md      /agent-lock|unlock <n>  -> roster.sh lock|unlock     (explicit-only)
  agent-disable.md agent-enable.md     /agent-disable|enable   -> roster.sh disable|enable  (explicit-only)
  agents-tune.md                       /agents-tune <standard> -> drives the bulk loop      (explicit-only)
  agent-new.md                         /agent-new <name> <role>-> scaffold then refine
scripts/
  roster.sh                            list / lock / unlock / disable / enable (no LLM)
  tune-roster.sh                       resumable bulk-tune loop: manifest, resume, git, backups, exclusions
  new-agent.sh                         deterministic skeleton from the template
  validate-frontmatter.py              hook script: re-parse frontmatter, exit 2 on invalid
hooks/
  settings.snippet.json                registers validate-frontmatter as a PostToolUse hook
```

## Wiring
- Drop `agents/`, `skills/`, `commands/` into `.claude/` (project) or `~/.claude/` (global).
- Put `scripts/` at the project root (the commands call `scripts/<x>.sh`; adjust the path if you place them elsewhere). `chmod +x scripts/*.sh scripts/*.py`.
- Merge `hooks/settings.snippet.json` into `.claude/settings.json`.
- The slim agent preloads the reference skill via `skills: [agent-roster-reference]`, so the knowledge is in its context at startup without bloating every other agent.
- All scripts auto-detect the agents dir from the git root, or set `AGENTS_DIR`.

## What stays in the LLM vs not
Judgment (the subagent): auditing a description for routing quality, merge/split decisions, tuning to a standard, rewriting handoffs, flagging dormancy. Everything else is a fully-specified file operation and runs as a script — no model in the loop for a rename or a directory listing.

## The one thing to verify
Confirm your installed Claude Code version honors `disable-model-invocation: true` and `user-invocable` on `.claude/agents/*.md` (documented for skills/commands and the agent surface; one tracked issue's subagent field list omits them). If it does, the slim agent's "Invocation safety" prose is just a fallback — the frontmatter does the work. If it does not, keep that prose as the active guard. Either way, never encode invocation policy as instructions inside `description`: that text is the router's match input.
