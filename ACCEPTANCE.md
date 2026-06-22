# ACCEPTANCE — agents-base-v1

Tag `agents-base-v1` (076390d). Ledger: 26 defects, 0 open. Suite: bats 22/22, shellcheck clean, shfmt -i2 clean, py_compile OK.

## Defects & fixes by pass

### Mechanical (QA-001…007) — pre-existing, fixed
- QA-001 tune-roster: `-m` after `--` pathspec → commit failed silently. Fixed (msg before `--`).
- QA-002 tune-roster: `grep -P` unsupported by BSD grep. Fixed (`grep -E`).
- QA-003 roster: `find -type f` skipped symlinked agents. Fixed (`find -L`).
- QA-004 tune-roster: same symlink class in `tunable_files`. Fixed (`find -L`).
- QA-005/006/007 roster/tune/new-agent: shfmt -i2 nonconformance. Fixed.

### Currency (QA-008…011) — version behavior
- QA-008 sources not discovery paths; restart loaded nothing. Fixed: `scripts/install.sh` (project-vendored symlink into `.claude/`) + README; restart required.
- QA-009 hook hardcoded abs path. Fixed: `.claude/settings.json` uses `$CLAUDE_PROJECT_DIR`; verified hook fires.
- QA-010 hook gate only matched `.claude/agents`. Fixed: also matches `agents/`; `--force` added.
- QA-011 commands lacked `allowed-tools` → Bash prompts. Fixed: `allowed-tools: Bash(bash:*)` on all 7.

### Integration (QA-012…013)
- QA-012 new-agent rejected `_`-prefixed names. Fixed: regex allows optional leading `_`.
- QA-013 scaffold write bypassed the hook. Fixed: new-agent runs `validate-frontmatter --force` post-write.

### Design (QA-014…026)
- QA-014 flat description routing doesn't scale. Fixed (doc): routing-tier pattern in reference skill.
- QA-015 no name-uniqueness. Fixed: hook fails on tree-wide dup; `resolve_file` errors on >1 match.
- QA-016 relative `scripts/` path. Fixed: `$CLAUDE_PROJECT_DIR/scripts/<x>.sh` (decision below).
- QA-017 manifest race. Fixed: mkdir-based lock + atomic pending→inprogress claim.
- QA-018 single AGENTS_DIR vs project+global merge. Fixed: cross-scope shadow report + warnings (when AGENTS_DIR unset).
- QA-019 `locked_` cosmetic/misleading. Fixed: list relabelled advisory; real enforcement via freeze guard.
- QA-020 rename dangling refs. Fixed: inbound-ref warning on lock/disable; `done` re-resolves path by name.
- QA-021 scaffold auto-routable with placeholder. Fixed: default `disable-model-invocation: true` + clean description.
- QA-022 two divergent parsers. Fixed: awk strips quotes/inline-comments to match YAML on common cases.
- QA-023 single global manifest. Fixed: additive `--pass <id>` namespacing (default behavior preserved).
- QA-024 hook checked only `name`. Fixed: description non-empty/non-placeholder + uniqueness.
- QA-025 O(n) multi-spawn list. Fixed: single awk pass (`fm_pair`).
- QA-026 manifest/.bak littered agents dir. Fixed: state under git-dir or TMPDIR slot, outside discovery tree.

## Currency-pass version-behavior results
1. Suppression (`disable-model-invocation`) — could not live-verify; probe not in a discovery path (root cause QA-008, now installable).
2. Skills preload — same; blocked, not verified.
3. Recursive discovery — capability confirmed live (user roster loads from `~/.claude/agents/` subfolders); probe itself blocked.
4. tools YAML block-list form — PASS; live roster loads block-list `tools:` with tools intact (no comma-form switch needed).
5. PostToolUse hook — fires/blocks under `.claude/agents`; did NOT on source `agents/` (QA-010) and `$CLAUDE_PROJECT_DIR` unused (QA-009); both fixed + verified.
6. `/agents-list` bash mode — blocked (command not installed; no allowed-tools, QA-011); fixed.

## Test coverage (tests/, bats — 22)
- roster.bats (9): empty-dir section headers; lock/unlock w/ spaces; disable/enable unicode; disable/enable leading-dash; already-locked refused; disable-refuses-locked; symlinked agent listed/resolved; stem-wins resolve; 200-agent scale.
- tune-roster.bats (9): no-git .bak backup (now in state dir); done commit scoped to one file; never `add -A`/`commit -a`; half-written manifest `next`; `--fresh` reset; differing-standard refusal; manager excluded; symlink included; 200-agent scale.
- new-agent.bats (4): refuses spaces / unicode / leading-dash; creates kebab + refuses overwrite.
- Not in bats (verified manually only): QA-015 ambiguity, QA-017 claim, QA-018 shadow, QA-020 re-resolve, QA-022 quoted name, QA-023 multi-pass, install.sh.

## Decisions made during the loop
- Install model: **project-vendored** (`$CLAUDE_PROJECT_DIR`), user-selected over global tooling — sets QA-008/011/016.
- QA-019: chose advisory relabel for `list`, not `chmod` enforcement; real protection of baseline files delegated to the pre-commit guard.
- QA-024: description + uniqueness enforced; tool-name/model validation deliberately omitted (would false-reject MCP/custom tools).
- QA-023: additive `--pass` so default single-pass UX (and the "differing standard refuses" contract) is unchanged.
- Baseline freeze: enforced `hooks/pre-commit` over the honor-system `locked_` prefix.
- `.claude/settings.json` committed (was untracked) to ship the portable hook.

## Residual risks (not fully closed)
- Concurrency (QA-017): mkdir-lock + bounded spin (`sleep 0.05`); reasoned correct but not load-tested under real parallel workers; `flock` absent on macOS.
- QA-018 shadow logic active only when AGENTS_DIR is unset; bats pins AGENTS_DIR, so it is manual-verify only.
- QA-014 is documentation, not enforced — nothing stops a flat 100-agent roster.
- QA-020 inbound-ref check is non-fatal substring grep within the agents dir only; can false-positive/negative and won't see external orchestrator/settings refs.
- QA-022 alignment covers quotes/inline-comments, not full YAML (folded/multiline); PyYAML absent here, so the hook also runs the lenient parser.
- Hook checks only fire on Edit/Write tool calls under `agents/`/`.claude/agents`; bulk/out-of-band or global `~/.claude/agents` edits bypass uniqueness/description validation.
- Pre-commit guard is local (`.git/hooks` not cloned), has an `ALLOW_BASE_EDIT=1` override, and there is no server-side/CODEOWNERS gate.
- Currency checks 1–3 (suppression, skills preload, recursive discovery via the probes) still need an install + restart to live-verify; not re-run in-session (fixtures were deleted).
- install.sh writes `.claude/settings.json` only when absent; an existing settings file must be merged by hand.
