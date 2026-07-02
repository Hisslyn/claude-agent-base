---
name: agent-roster-reference
description: Reference knowledge for maintaining a Claude Code agent roster — discovery and identity rules, native invocation-control fields, locking and disabling conventions, the no-nested-spawning delegation model, the frontmatter schema, and the new-agent template. Consumed by meta-agents via the `skills:` preload field; also load when reasoning about how agents are discovered, routed, locked, or disabled.
user-invocable: false
---
# Agent Roster Reference

Stable platform knowledge for roster work. Kept separate from agent behavior so each evolves on its own. Meta-agents pull this in via `skills: [agent-roster-reference]`, which injects the full content at startup.

## Discovery and identity (confirmed against current docs)
- Identity comes only from the frontmatter `name`, not the filename or the subfolder path. Renaming a file does not change how Claude Code discovers or routes it.
- `.claude/agents/` and `~/.claude/agents/` are scanned recursively, so subfolders are fine for organization. Project scope is discovered by walking up from the cwd to the repo root.
- Only `.md` files are loaded. Anything with another extension (`.md.off`, `.bak`) is ignored by discovery.
- Keep `name` unique across the tree. On a collision within one scope, Claude Code keeps one file and silently discards the other.
- `model:` accepts aliases (`sonnet`, `opus`, `haiku`), full model IDs, or `inherit` (matches the main conversation).
- Model-tier options as of 2026-06-30: `claude-sonnet-5` is live in Claude Code — near-Opus-4.8 quality on coding/tool-use/knowledge work at substantially lower cost, with lower hallucination and better prompt-injection resistance than Sonnet 4.6; still below Opus 4.8 on hardest-accuracy tasks and overall safety. Two caveats: the model ID is a PINNED snapshot, not evergreen — re-verify it is still current before relying on it; and its updated tokenizer maps the same input to roughly 1.0–1.35x more tokens than Sonnet 4.6 (intro pricing is approximately cost-neutral through 2026-08-31, standard pricing applies after). Tier guidance: Sonnet 5 is now the default mid-tier candidate and a viable Opus replacement for many non-frontier agentic tasks; reserve Opus for hardest-accuracy / highest-safety work; Haiku is unchanged for mechanical tasks.

## Invocation-control fields (prefer these over prose guards)
Encode invocation policy in frontmatter, not in English inside `description` — the description is the router's match text, so prose there cannot reliably suppress routing.
- `disable-model-invocation: true` — hide the agent from auto-routing; it runs only when invoked explicitly.
- `user-invocable: false` — keep it out of the chat dropdown; reachable only as a subagent or via preload.
- `disallowedTools:` — a denylist complement to the `tools:` allowlist; enforced, unlike instructions.
- `agents:` on a coordinator — restrict which subagents it may use; explicitly listing one overrides that agent's `disable-model-invocation`.
- VERIFY on your installed CLI version that `disable-model-invocation` / `user-invocable` are honored on `.claude/agents/*.md` (they are documented for skills/commands and the agent surface, but one issue's subagent field list omits them). If not honored, keep the short "explicit-only, confirm before mutating" guard in the agent body as a fallback.
- OPEN VERIFICATION ITEM: whether the installed CLI resolves the short alias `sonnet` to Claude Sonnet 5 or still to Sonnet 4.6 is UNVERIFIED — checked 2026-07-01 on CLI 2.1.178, no non-mutating model-list/inspect subcommand was found (`claude model list` is not a real subcommand; `--help` documents `--model` but not what the bare alias currently resolves to). Must be checked live (e.g. by starting a session with `--model sonnet` and reading back the resolved model name, or any future inspect command) before any roster re-tier that relies on the alias rather than a pinned model ID.

## Locking (edit-protection only — honor-system)
"Locked" means the file or folder NAME starts with the exact, case-sensitive prefix `locked_`. This marker is respected only by tools and agents that choose to; the platform does not enforce it. For anything that truly must not be edited, prefer enforced protection (permission deny rules, read-only perms, git) over the prefix.
- A locked item is off-limits: do not read, audit, edit, or descend into it. A locked folder locks everything inside.
- Lock by prefixing the NAME via `mv`; unlock by removing the prefix. Never alter `name:` — it stays the routing key.
- Per-file locking (`locked_<name>.md`, same dir) is the safe default: discovery is by `name`, so routing is unaffected.
- Folder-rename locking (`locked_business/`) keeps Claude Code routing intact under recursive discovery (the current default), but it changes paths — so any external reference (an Orchestra layer, hooks, `settings.json`, an `agents:` list resolved by path) can break. Only fold-lock after confirming nothing references those files by path.
- Locking does not take an agent out of rotation. To do that, disable it.

## Disabling / removing
Rename `name.md` → `name.md.off` (`mv`). Claude Code loads only `.md`, so `.off` drops it from discovery while keeping it recoverable; re-enable by stripping `.off`. "Remove" and "disable" are the same reversible operation — never hard-delete (`rm`). `name:` is preserved for restore.

## Delegation model
No subagent can spawn another subagent (the default). Claude Code returns a subagent's single result to its caller; only the caller (the main session, or your orchestration layer) re-delegates. So `orchestrator → coder → code-reviewer` means the orchestrator issues coder, gets the result, then issues code-reviewer — never coder spawning code-reviewer. Handoff instructions inside an agent are recommendations returned upward, not nested calls. Rewrite any "delegate to X" / "call X" into "return to the orchestrator with a recommendation to run X next."

## Scaling the roster — routing tiers (do not rely on a flat description match)
Routing is flat description-matching: every agent's `description` is injected as router match text, and subfolders are cosmetic (identity is the `name`). This holds at a few dozen agents; past ~50–100 the combined descriptions bloat the router context every turn and overlapping "Use when…" lines stop discriminating, so mis-routing climbs. The roster directory is an organization surface, not a routing surface.
- Make routing two-level. Keep a small set of top-level, auto-routable **domain coordinators** (e.g. build, data, business) whose descriptions are the only ones competing for the first hop; give each a scoped `agents:` allowlist of the specialists it may delegate to.
- Set `disable-model-invocation: true` on the specialists so they never compete in the global router — they are reached only through their coordinator's `agents:` list (which overrides the flag). Only the handful of coordinators carry auto-routing descriptions.
- This bounds the descriptions the router weighs at each hop to a handful regardless of total roster size, and keeps domains independently evolvable.
- Audit signal: if a single flat tier exceeds ~30–40 auto-routable agents, split by domain behind coordinators before adding more.

## Frontmatter schema
Required: `name`, `description`. Common optional: `model`, `tools` (allowlist; omit to inherit the thread's tools), `disallowedTools`, `disable-model-invocation`, `user-invocable`, `skills` (preloads skill content at startup), `permissionMode`, `agents`. The documented canonical form for `tools` is comma-separated (`tools: Read, Edit, Glob`); the YAML block-list form is common too — confirm your version accepts it before standardizing on one.

## New agent template
```markdown
---
name: [kebab-case]
description: [What it does. When to use it. What triggers auto-delegation — or set disable-model-invocation: true for explicit-only.]
model: sonnet | haiku | inherit
tools:
  - [only what's needed]
---
[System prompt: role, responsibilities, output format, handoff instructions.]

## Token rules
No preamble. No recap. No filler. Stop when done.
```

## Pinned facts (v2)

### Model ID table
| Tier | Pinned model ID |
| --- | --- |
| opus | `claude-opus-4-8` |
| sonnet | `claude-sonnet-5` |
| haiku | `claude-haiku-4-5` |

Aliases (opus/sonnet/haiku) are banned in agent files; re-tier passes update this table.

### Valid subagent frontmatter fields
`name`, `description`, `tools`, `disallowedTools`, `model`, `permissionMode`, `maxTurns`, `skills`, `mcpServers`, `hooks`, `memory`, `background`, `effort`, `isolation`, `color`, `initialPrompt`.

Closed list — fields outside it are invalid; `disable-model-invocation` and `user-invocable` are inert on subagents (valid on skills/commands only).

### Nonce-marker verification pattern
1. Generate a fresh nonce.
2. The target writes it to a marker file as a side effect of the work.
3. Check the marker file's content after the run.
4. The marker overrides narrated text, always.

### suggestion.md spec
- Per-directory pool: one `suggestion.md` per agent directory.
- Append-only: never edit prior entries.
- One line per entry, format: `- [YYYY-MM-DD] [<agent name>] <suggestion, max 2 sentences>`.
- Entries are optional and appear only on genuine capability gaps.

### Funnel model
UNRESOLVED — pending nested-spawn verification (Prompt B). Do not assume coordinators can spawn.

## Critical rules to propagate
- Bound danger with the `tools:` allowlist (and `disallowedTools`) first, prose second.
- Never change `name:`. Never `rm` an agent — all destructive ops go through `mv` (→ `.off` / `.bak`).
- After any edit, frontmatter must still parse; if not, restore from a snapshot and flag. (The `validate-frontmatter` hook enforces this automatically.)
- Scope every git commit to the single file edited; never `-am` / `-A` (the roster may share a repo with application code).
- Test descriptions mentally: would Claude auto-delegate the right task here, and not unrelated ones?
