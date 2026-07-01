# agent-manager Self-Audit — claude-agent-base

**Date:** 2026-06-30
**Scope:** /Users/azat/Desktop/claude-agent-base (agents-base-v1)
**Auditor:** agent-manager (read-only run)
**Components audited:** 14

---

## 1. Component Inventory

### 1.1 Agent body — `agents/agent-manager.md`

**Purpose:** Slim judgment-only subagent for roster maintenance. Auditing descriptions, merge/split, tuning, rewriting handoffs, flagging dormant agents.

**Findings:**

| # | Severity | Finding |
|---|----------|---------|
| AM-01 | Low | `state-scribe` is named in the Handoff section ("Record the roster change through `state-scribe` if that agent exists") but `state-scribe` does not exist in this repo. The fallback ("note it in `PROJECT_STATE.json`") is unreachable because `PROJECT_STATE.json` does not exist either. Both dead-code paths; the handoff instruction reduces to a no-op on every run. |
| AM-02 | Low | The `--allow-self` flag is referenced ("Never edit your own file unless invoked with `--allow-self`") but there is no mechanism in any command, script, or frontmatter that reads or enforces this flag. It is a prose guard only; any invocation with that string in the prompt would be indistinguishable from an instruction fabricated inside a file the agent reads. |
| AM-03 | Info | `user-invocable: true` is set but `disable-model-invocation: true` is also set. The combination is intentional (user can invoke from the dropdown but not auto-routed), but the interaction between these two flags is noted in the skill as needing per-version verification. No active risk if the CLI honors both, but it is the one unverified currency item. |
| AM-04 | Info | The Bash tool is in the `tools:` allowlist, which is broader than most operations need. This is intentional (git operations, script calls) and appropriate, but gives the agent unconstrained shell access. `disallowedTools:` is not used to restrict dangerous Bash patterns. |

---

### 1.2 Slash commands

#### `/agents-list` (`commands/agents-list.md`)

**Purpose:** Delegate `roster.sh list` and return output verbatim.

**Findings:**

| # | Severity | Finding |
|---|----------|---------|
| AL-01 | Low | No `disable-model-invocation` frontmatter. The description ("List active, locked, and disabled agents") is broad enough that the router could auto-invoke it on any query mentioning agents. Since it is read-only the impact is low, but it should carry `disable-model-invocation: true` for consistency with the explicit-only pattern used by the mutating commands. |

---

#### `/agent-disable` and `/agent-enable` (`commands/agent-disable.md`, `commands/agent-enable.md`)

**Purpose:** Delegate disable/enable to `roster.sh`.

**Findings:** No bugs. Properly guarded with `disable-model-invocation: true`. `allowed-tools: Bash(bash:*)` is present. The commands do nothing beyond passing through to the script; no edge case ownership.

---

#### `/agent-lock` and `/agent-unlock` (`commands/agent-lock.md`, `commands/agent-unlock.md`)

**Purpose:** Delegate lock/unlock to `roster.sh`.

**Findings:** No bugs. Same pattern as disable/enable. Properly guarded.

---

#### `/agent-new` (`commands/agent-new.md`)

**Purpose:** Scaffold a new agent file, then invoke agent-manager to refine it.

**Findings:**

| # | Severity | Finding |
|---|----------|---------|
| AN-01 | Medium | Step 1 passes `$ARGUMENTS` bare and unquoted to the script: `bash "$CLAUDE_PROJECT_DIR/scripts/new-agent.sh" $ARGUMENTS`. If the user's arguments contain spaces or shell-special characters, word-splitting will break the call. The script itself validates the name as kebab-case (which disallows spaces), but the role description words are all concatenated as the rest of the arguments and arrive correctly due to the script's `$*` handling. The risk is if a future script change drops that tolerance. Low practical risk today; still a correctness gap. |
| AN-02 | Low | The command says "Invoke the **agent-manager** subagent" in step 2, which is a direct subagent spawn instruction. The delegation model documented in the skill says subagents return recommendations upward rather than spawning each other. However, `/agent-new` is a command (not a subagent), so it is the orchestrator layer and is legitimately allowed to invoke subagents. This is architecturally correct; not a violation. Noted for clarity only. |

---

#### `/agents-tune` (`commands/agents-tune.md`)

**Purpose:** Resumable bulk-tune loop driver. Owns no state; script owns it.

**Findings:**

| # | Severity | Finding |
|---|----------|---------|
| AT-01 | Low | The `allowed-tools` field uses `allowed-tools` (kebab) rather than `tools` (the documented canonical frontmatter key). The skill notes "confirm your version accepts it before standardizing." All other commands also use `allowed-tools`. This is a cross-command inconsistency with the frontmatter schema reference (which says `tools:`) — worth confirming the installed CLI version's canonical key. |
| AT-02 | Info | Step 2 says "invoke the **agent-manager** subagent to tune that file." Same delegation-model note as AN-02 — this is a command acting as orchestrator, so it is architecturally correct to invoke subagents from here. |

---

### 1.3 Scripts

#### `scripts/roster.sh`

**Purpose:** Deterministic list/lock/unlock/disable/enable. No LLM.

**Findings:**

| # | Severity | Finding |
|---|----------|---------|
| RS-01 | Low | `warn_inbound_refs` greps only within the agents dir, not across `settings.json`, `commands/`, or any orchestrator config that might reference the agent name. The ACCEPTANCE.md residual-risks section already documents this as a known limitation ("non-fatal substring grep within the agents dir only; can false-positive/negative and won't see external orchestrator/settings refs"). Risk is documented and accepted; flagged here for completeness. |
| RS-02 | Info | `cmd_list` uses three separate `find` invocations. The QA-025 fix added `fm_pair` for a single-pass awk on the active section, but the LOCKED and DISABLED sections still use separate `find` calls. Low performance impact (those two are not awk-heavy), but inconsistent with the optimization intent. |
| RS-03 | Low | `is_locked_path` checks for `/locked_` in the path string. If the agents dir itself were named with `locked_` in its path, all agents would falsely appear locked. Unlikely but a latent correctness edge case. |

---

#### `scripts/tune-roster.sh`

**Purpose:** Resumable bulk-tune loop state machine: manifest, resume, per-file git commit, backups, exclusions.

**Findings:**

| # | Severity | Finding |
|---|----------|---------|
| TR-01 | Medium | **Backup retention (Assessment B).** `cmd_init` copies all tunable files to `.bak` when not in git. `cmd_finish` deletes all `.bak` files. There is no keep-last-N logic. Across multiple `--fresh` runs or multiple `--pass` IDs, backups from different passes accumulate in the state dir until `finish` is run for each. If a pass is abandoned (never finished), its `.bak` files are never cleaned up — the state dir grows unboundedly. Detailed recommendation in Section 3B. |
| TR-02 | Low | `acquire_lock` spins up to 200 iterations with `sleep 0.05` (10 seconds total). On macOS `flock` is absent; `mkdir`-based locking is used instead. If a worker dies holding the lock directory, the lock is never released and the next call hangs for 10 seconds before erroring. There is no stale-lock detection (e.g., check lock age). The ACCEPTANCE.md residual-risks section documents this as reasoned-correct but not load-tested. |
| TR-03 | Low | `cmd_done` silently succeeds and prints status even when `file` is empty or the file was deleted (`[[ -n "$file" && -f "$file" ]]` guards the git commit but not the status print). A deleted-mid-pass file is marked `done` with no warning, which could mask a problem. |
| TR-04 | Info | The `_manifest` and `_statedir` subcommands are undocumented in the usage string at the bottom of the script. They are used by the bats test suite (e.g., `$TUNE _statedir`). They are effectively internal/test-only APIs with no visibility guard. Not a bug, but a maintenance hazard if their behavior changes without updating the tests. |

---

#### `scripts/new-agent.sh`

**Purpose:** Scaffold a new agent file from the template.

**Findings:**

| # | Severity | Finding |
|---|----------|---------|
| NA-01 | Info | The scaffold description is set from the CLI argument `$role`, which defaults to `"Describe the role."`. The `validate-frontmatter.py --force` call after scaffolding checks for the specific placeholder string `"what triggers auto-delegation"` but not for `"Describe the role."` — so if no role argument is passed, the default text passes validation and an effectively placeholder description enters the roster. The description is not empty, does not contain the checked placeholder, so the gate passes. `disable-model-invocation: true` in the scaffold mitigates the routing risk, but the description quality gate is incomplete for the no-arg case. |

---

#### `scripts/validate-frontmatter.py`

**Purpose:** PostToolUse hook — re-parses frontmatter on every Edit/Write, exits 2 on invalid.

**Findings:**

| # | Severity | Finding |
|---|----------|---------|
| VF-01 | Low | `is_agent_md` checks for `"/.claude/agents"` or `"/agents/"` as substrings. A path like `/home/user/my-agents/foo.md` contains `/agents/` and would be validated unnecessarily. This is a false-positive gate miss — the file is validated when it perhaps should not be. Exit 0 on valid frontmatter means no harm done, but a duplicate-name check against the wrong tree root could surface spurious duplicates. The `agents_root()` function has a similar `"/agents/"` heuristic that would anchor to the wrong tree in this edge case. |
| VF-02 | Low | `parse_meta` falls back to the lenient awk-alike parser when PyYAML is absent or throws. The ACCEPTANCE.md residual note confirms PyYAML is absent in this environment. The lenient parser skips YAML list items (`s.startswith("- ")`), which means `tools:` block-list values are silently ignored. This is fine for the checks performed (name, description) but leaves a gap if future validation needs to inspect tool lists. |
| VF-03 | Info | `duplicates()` uses `os.walk(root)` which follows the OS-level directory traversal (no `-L` symlink-following equivalent). A symlinked agent file outside the discovered root could pass the uniqueness check with a duplicate name. The shell scripts use `find -L` to follow symlinks; this validator does not. |

---

#### `scripts/install.sh`

**Purpose:** Wire the agent-base into a project's `.claude/` via symlinks.

**Findings:**

| # | Severity | Finding |
|---|----------|---------|
| IS-01 | Low | `link()` silently skips if destination exists (`-e "$dst" || -L "$dst"`). If a previous install left a broken symlink (`-L` true but `-e` false because the target was deleted), the skip message is printed but the broken symlink is not repaired. A re-install would silently leave a broken symlink in place. |
| IS-02 | Low | `chmod +x "$root"/scripts/*.sh` and `.py` run with `2>/dev/null || true`. If the scripts directory is empty (unlikely but possible) or no files match the glob on a version of bash that does not expand empty globs to nothing, this could error silently. Benign in practice. |
| IS-03 | Info | When `target != root`, the script symlinks `$root/scripts` into `$target/scripts`. This means the target project's commands reach the scripts via `$CLAUDE_PROJECT_DIR/scripts/<x>`, but the actual scripts live in the agent-base repo. If the agent-base repo is moved or deleted, all projects that were installed this way break silently (the symlink remains but the target is gone). No integrity check after linking. |

---

### 1.4 PostToolUse hook config — `.claude/settings.json`

**Purpose:** Register `validate-frontmatter.py` as a PostToolUse hook on Edit/Write/MultiEdit.

**Findings:**

| # | Severity | Finding |
|---|----------|---------|
| HC-01 | Low | The hook matcher is `"Edit|Write|MultiEdit"`. The `MultiEdit` tool is listed in the matcher but the agent body and skill documentation do not mention it in the supported tool list. This is protective (also validates multi-edits) but may indicate inconsistency if `MultiEdit` is not in the agent's `tools:` allowlist (which it is not — the agent lists Read, Write, Edit, Glob, Bash). The hook fires on tool calls regardless of which agent made them; this is correct behavior for a project-wide hook. Info only. |

---

### 1.5 Preloaded skill — `skills/agent-roster-reference/SKILL.md`

**Purpose:** Stable reference knowledge: discovery, locking, delegation model, frontmatter schema, template. Injected at agent startup via `skills:` preload.

**Findings:**

| # | Severity | Finding |
|---|----------|---------|
| SK-01 | Low | The `Invocation-control fields` section says to "VERIFY on your installed CLI version that `disable-model-invocation` / `user-invocable` are honored on `.claude/agents/*.md`" and notes that one tracked issue's subagent field list omits them. The ACCEPTANCE.md confirms these were never live-verified (currency checks 1–3 still require an install + restart). The skill correctly documents the uncertainty, but the uncertainty remains open. Any consumer of the skill (including agent-manager) could be operating under a false assumption about whether these fields actually work. |
| SK-02 | Info | The `New agent template` includes `disable-model-invocation: true` as a comment-placeholder but not as an explicit default field. The `new-agent.sh` scaffold does emit `disable-model-invocation: true` by default. There is a minor alignment gap: a human following the template literally could produce a scaffold without the field and accidentally create an auto-routable unrefined agent. |

---

### 1.6 README — `README.md`

**Purpose:** Explains decomposition, wiring, install model, and the one platform behavior to verify.

**Findings:**

| # | Severity | Finding |
|---|----------|---------|
| RD-01 | Info | The README says "Run `bash scripts/install.sh [TARGET_PROJECT_DIR]` (defaults to this repo)." When run with no argument, `install.sh` defaults to the repo root and creates symlinks from `.claude/{agents,skills,commands}` pointing at the same directories they already are (since they live in the same repo). The `link()` function's skip-if-exists behavior means this is safe but a no-op. The README implies this is meaningful for self-install, which it is not after the initial install. |

---

## 2. Assessment A — Repo-Root Verification

**Issue:** When agent-manager edits files across different repos (its own project, `~/.claude`, other config dirs), it currently identifies the target by reading `PROJECT_STATE.json` at the repo root via `git rev-parse --show-toplevel`. It does not verify that the target file being edited is inside that root. If the target dir is not a git repo, the agent discovers this only at commit time (when `git -C ... commit` fails, or when the snapshot restore step references `git checkout -- <file>` which silently fails). The `.bak` fallback in the agent body requires non-git detection, but the agent body's snapshot section does not surface non-git status proactively — it describes the logic but the agent must re-derive it during the run.

**Recommendation:** Add an explicit repo-root and git-status check to the **agent body** (not a script — this is judgment about where to anchor edits) as a named step before any mutating single-edit run:

**Placement:** `agents/agent-manager.md`, inside the `## Single-edit workflow (ad-hoc)` section, as a new first step before "Read target."

**Concrete change — add to the workflow preamble:**

```
Before "Read target": run `git -C "$(dirname <target>)" rev-parse --show-toplevel` to confirm
the target file's containing directory is inside a git repo. If it is, record that root as the
anchor for all git ops in this run. If it is NOT a git repo, surface this immediately:
"Target is not in a git repo. I will use a .bak snapshot instead. If you want git-based undo,
run `git init` (and optionally add a .gitignore) in <dir> before proceeding — continue without
git (bak only), abort, or git-init first?" Wait for user confirmation. Do not proceed to edit
until the user selects an option.
```

This belongs in the agent body (not a script) because: (a) the decision branches on user intent, (b) it gates the choice between two snapshot strategies (git vs .bak), and (c) it is the only place in the workflow with the necessary context (the target file path) before edits begin.

---

## 3. Assessment B — Backup Retention

**Issue:** `tune-roster.sh cmd_init` copies all tunable files to `<state_dir>/*.bak` when the agents dir is not in git. `cmd_finish` deletes all `.bak` files. There is no keep-last-N logic. Scenarios where backups accumulate unboundedly:

1. Multiple `--fresh` passes: each `init --fresh` overwrites the `.bak` files in place (same state dir, same filenames), so they do not accumulate per-agent — but different `--pass <id>` values create separate manifests that could generate separate `.bak` sets with different suffixes if the naming were pass-scoped (currently they are not; baks are named `$(basename "$f").bak` without pass-id, so different passes do overwrite each other's baks — this is a correctness risk on concurrent passes in non-git mode, but it does prevent accumulation in the single-pass case).
2. Abandoned passes (never `finish`ed): the `.bak` files remain in `<state_dir>` indefinitely. There is no cleanup path for an abandoned pass.
3. Multiple concurrent `--pass <id>` runs in non-git mode: since bak filenames are not namespaced by pass-id, concurrent passes would race-overwrite each other's backups (correctness gap) and the per-pass `finish` would delete files that other passes still need.

**Recommendation:** Keep-last-N logic belongs in **`scripts/tune-roster.sh`**, specifically in `cmd_init` (where backups are written) and a new `_cleanup_old_baks` helper called from `cmd_init` and `cmd_finish`.

**Concrete change:**

- Namespace `.bak` filenames by pass-id: `$(basename "$f").$PASS_ID.bak` (fixes the concurrent-pass overwrite race and enables per-pass cleanup).
- In `cmd_finish`: delete only `.bak` files matching `*.$PASS_ID.bak` (not all `.bak` files).
- In `cmd_init` (after writing new baks): enumerate `*.bak` files across all pass-ids, group by agent basename, and delete all but the N most recent (by mtime or manifest sequence). Default N=10.
- Expose `N` as an env var `ROSTER_BAK_KEEP` defaulting to 10.

No change needed in any other component. The current behavior is entirely within `tune-roster.sh` and the state dir it manages.

---

## 4. Additional Hardening Items (ranked by risk)

| Rank | Severity | Item | Location |
|------|----------|------|----------|
| 1 | Medium | `mk_agent` helper in `tests/helper.bash` does not include a `description:` field in the scaffold. The `validate-frontmatter.py` hook (post-QA-024) requires a non-empty, non-placeholder description; agents created by the test helper would fail this check in production. Tests pass because the hook is not wired during bats runs (no Claude Code session), but any test that exercises the validator directly against these fixtures would get false failures. A description line should be added to `mk_agent`. | `tests/helper.bash` |
| 2 | Medium | The pre-commit guard (`hooks/pre-commit`) is only active if manually installed to `.git/hooks/pre-commit`. It is not installed by `install.sh` (which only sets up `.claude/` wiring). `ACCEPTANCE.md` documents this: "Pre-commit guard is local (`.git/hooks` not cloned), has an `ALLOW_BASE_EDIT=1` override." Any contributor who clones the repo gets no baseline protection until they manually run `cp hooks/pre-commit .git/hooks/pre-commit`. A note should be added to `install.sh` or a separate install step should wire the hook. | `scripts/install.sh` / `hooks/pre-commit` |
| 3 | Low | `tune-roster.sh cmd_done` always exits 0 and calls `cmd_status` even if the git commit fails (`|| true` swallows it). A failed commit is logged to `/dev/null` and the pass continues. This means a pass can complete with a `DONE` status while some files were never actually committed. There is no post-pass commit audit. | `scripts/tune-roster.sh` |
| 4 | Low | `tune-roster.sh state_dir` uses `sha256sum` to compute a stable key for non-git repos. `sha256sum` is a GNU coreutils command; on macOS, the equivalent is `shasum -a 256`. The script works because it runs via `bash` and the pipeline `printf '%s' "$dir" | sha256sum` — if `sha256sum` is absent (possible on a clean macOS without GNU coreutils), `state_dir` returns a path with an empty hash component, potentially colliding across different agents dirs. `shasum` is present on macOS by default; `sha256sum` is not guaranteed. | `scripts/tune-roster.sh` |
| 5 | Low | `validate-frontmatter.py` reads from `sys.stdin` unconditionally in `target_from_stdin()` with `json.load(sys.stdin)`. When invoked standalone (e.g., `python3 validate-frontmatter.py myfile.md`), if stdin is a terminal, this call blocks waiting for input before the argv path is resolved. The `try/except` catches the JSON parse error eventually, but the behavior is confusing when running interactively. `target_from_stdin` should only be called when stdin is not a tty (i.e., guard with `not sys.stdin.isatty()`). | `scripts/validate-frontmatter.py` |
| 6 | Low | The `agents-tune` command frontmatter uses `allowed-tools` (kebab) rather than `tools` (the schema-canonical form per the reference skill). All commands use `allowed-tools`; the skill's `Frontmatter schema` section lists `tools` as the canonical key. The discrepancy may be intentional (commands may use a different key than agents), or may reflect an undocumented command-specific field name. Worth confirming in the CLI docs. | All `commands/*.md` |

---

## 5. Items Not Inspectable

- **Live platform behavior** of `disable-model-invocation: true` and `user-invocable: true`/`false` on `.claude/agents/*.md`: requires an active installed Claude Code session after `install.sh` + restart. Not verifiable by static read. ACCEPTANCE.md confirms these were not live-verified during the QA pass either.
- **`state-scribe` agent**: does not exist in this repo or as a file under `~/.claude/agents/` (out of scope for this audit). Cannot verify what it does or whether it would work if created.
- **`~/.claude/agents/`** and **Obsidian vault**: explicitly out of scope per audit guards. Not read.
- **Locked files/folders**: none found in this repo with the `locked_` prefix; none skipped.
- **`.pycache`** (`scripts/__pycache__/validate-frontmatter.cpython-314.pyc`): binary; content not read. Not a source component.
- **Git objects and history**: not audited beyond the last 5 commits visible in the system context.
