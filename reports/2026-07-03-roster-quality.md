# Roster Quality Audit — 2026-07-03

- **Date:** 2026-07-03
- **CLI version:** 2.1.198 (Claude Code)
- **Smoke-test nonce:** 71525b846032154e
- **Scope:** READ-ONLY audit of 37 agents under `~/.claude/agents/` across 10 clusters. No agent file was edited, renamed, merged, split, or fixed. The only write is this report.

---

## Task 1 — Ground truth (verbatim)

**1. `claude --version`**
```
2.1.198 (Claude Code)
```

**2. `find ~/.claude/agents -name '*.md' ! -name suggestion.md | wc -l` → expect 37; `find ~/.claude/agents -path '*locked_*'` → expect empty**
```
37
(no locked_ paths)
```

**3. `grep -rl 'disable-model-invocation\|user-invocable' ~/.claude/agents` → expect empty**
```
(empty)
```

**4. `grep -rh '^model:' ~/.claude/agents | sort | uniq -c` → expect opus 4 / sonnet 27 / haiku 6**
```
   6 model: claude-haiku-4-5
   4 model: claude-opus-4-8
  27 model: claude-sonnet-5
```

All four ground-truth checks match expectations.

---

## Summary table

| Cluster | PASS | FLAG | Top issue(s) |
|---|---|---|---|
| build | 0 | 5 | all 5 missing suggestion paragraph + legacy `→` handoff arrows |
| business | 4 | 0 | clean (v2 cohort) |
| core | 0 | 4 | orchestrator routes to 4 retired coordinators; all 4 missing suggestion paragraph |
| data | 4 | 0 | clean (v2 cohort) |
| game | 1 | 3 | coordinator/tester/designer missing paragraph + arrows; game-designer tier borderline |
| infra | 2 | 1 | git-manager missing paragraph |
| knowledge | 1 | 2 | curator/synthesizer missing paragraph + arrows; vault-write policy asymmetry |
| marketing | 4 | 0 | clean (v2 cohort) |
| product | 0 | 3 | all 3 missing paragraph + arrows |
| qa | 0 | 3 | all 3 missing paragraph + arrows |
| **TOTAL** | **16** | **21** | — |

### Top issues, ranked by severity

1. **HIGH — orchestrator routes to 4 retired coordinators.** `core/orchestrator.md` Delegation rules (lines 24–32) route to `build-coordinator`, `product-coordinator`, `qa-coordinator` (x2), and `game-coordinator` — none of which exist in the roster. Its first-hop routing text names dead agents.
2. **MEDIUM — suggestion-convention paragraph MISSING on 21 agents** (the entire v1 cohort). Present VERBATIM on 16. Zero DRIFTED cases. Clean generational split.
3. **MEDIUM — legacy `→ X` handoff arrows** not phrased as orchestrator-return recommendations, on 20 of the 21 FLAG agents (all but documentarian, which has no handoffs). Intent is upward recommendation, but the arrow notation + absent "never invoke another agent" framing violates the stated delegation-phrasing rule.
4. **LOW — orchestrator carries the `Agent` tool it cannot use.** Funnel is dead on 2.1.198; orchestrator's own body states it never spawns directly. The tool grant is inert/contradictory.
5. **LOW — dependency-auditor's reciprocal boundary pointer is implicit.** It carries only "no security-auditor loop" in Handoff, not an explicit trigger-cede in its description (security-auditor's cede is explicit).
6. **OBSERVATION — vault-write policy asymmetry.** meeting-noter treats the Obsidian vault as frozen/manual "until further notice," while knowledge-curator (Edit) and research-synthesizer (Write) actively mutate it. Confirm whether the freeze is meeting-noter-specific by design.

---

## Task 2 — Per-agent static audit

### Cluster: build

#### code-reviewer — FLAG
1. FRONTMATTER: name matches basename; fields name/description/model/tools only; model `claude-sonnet-5` (full pinned); tools Read, Grep, Glob.
2. TIER SANITY: sonnet OK — frequent skilled review work.
3. TOOLS MINIMALITY: minimal and correct — no Write/Bash (pure review, never edits or runs). Nothing missing.
4. STRUCTURE: Purpose yes (intro one-job line) / Guards yes (Rules) / Workflow yes (Review dimensions + Output format) / Stop concrete — "Report only the critique. Stop when done."
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: `→ coder`, `→ security-auditor`, `→ state-scribe` bare arrows under "recommend"; no orchestrator-return framing, no "never invoke" clause. "Re-review on resubmission" implies orchestrator re-runs it (OK). No retired/nonexistent agents.
7. VERDICT: FLAG — missing suggestion paragraph; arrow-style handoffs not orchestrator-framed.

#### coder — FLAG
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Edit, Bash, Grep, Glob.
2. TIER SANITY: sonnet OK — default frequent implementation agent.
3. TOOLS MINIMALITY: full read/write/exec appropriate for an implementer. Correct.
4. STRUCTURE: Purpose yes / Guards yes (Prerequisites + "Do not touch items not on the list") / Workflow yes (Procedure) / Stop concrete ("Report only the Output format… Stop when done").
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: `→ qa/security-auditor/code-reviewer/monitor` + "Always also: → state-scribe" bare arrows; no orchestrator-return framing. No dead agents.
7. VERDICT: FLAG — missing suggestion paragraph; arrow-style handoffs.

#### prompt-engineer — FLAG
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Bash, Grep, Glob.
2. TIER SANITY: sonnet OK — skilled prompt/eval work.
3. TOOLS MINIMALITY: appropriate (writes/tests prompt variants). Correct.
4. STRUCTURE: Purpose yes / Guards yes (Prerequisites + "do not apply them yourself") / Workflow yes (Agent tuning workflow + principles) / Stop concrete ("production-ready… Stop when done").
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: references coder, agent-manager (both valid), state-scribe. Phrasing is mostly recommendation-framed ("a recommendation to run → agent-manager") but still uses `→` arrows and no explicit orchestrator-return. Note: correctly says it proposes edits and does NOT apply them itself.
7. VERDICT: FLAG — missing suggestion paragraph; arrow notation (framing otherwise near-compliant).

#### ui-designer — FLAG
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Grep, Glob.
2. TIER SANITY: sonnet OK — frequent skilled design work.
3. TOOLS MINIMALITY: no Bash (doesn't run code) — correct. Nothing missing.
4. STRUCTURE: Purpose yes / Guards yes (Prerequisites + design principles) / Workflow yes (Responsibilities + Output format) / Stop concrete ("Be specific… Stop when done").
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: `→ coder`, `→ state-scribe` bare arrows, no orchestrator-return framing. No dead agents.
7. VERDICT: FLAG — missing suggestion paragraph; arrow-style handoffs.

#### ux-designer — FLAG
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Grep, Glob.
2. TIER SANITY: sonnet OK — frequent skilled design work.
3. TOOLS MINIMALITY: appropriate. Correct.
4. STRUCTURE: Purpose yes / Guards yes (Hard boundary "never handle visual styling") / Workflow yes (Responsibilities + Output formats) / Stop concrete.
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: mixed — Hard boundary uses compliant "return with a recommendation to run ui-designer instead," but Handoff/Feedback loop use `→ ui-designer`, `→ coder`, `→ state-scribe` bare arrows. No dead agents.
7. VERDICT: FLAG — missing suggestion paragraph; arrow-style handoffs in Handoff/Feedback.

### Cluster: business

#### biz-analyst — PASS
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Grep, Glob.
2. TIER SANITY: sonnet OK — decision synthesis (could argue opus for judgment, but sonnet defensible).
3. TOOLS MINIMALITY: appropriate.
4. STRUCTURE: Purpose yes / Guards yes / Workflow yes / Stop concrete (explicit "## Stop condition").
5. SELF-IMPROVEMENT: VERBATIM.
6. DELEGATION: fully compliant — "Return to the orchestrator with the recommendation… Never invoke another agent yourself, and never re-invoke biz-analyst."
7. VERDICT: PASS.

#### competitor-intel — PASS
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Bash, Grep, Glob.
2. TIER SANITY: sonnet OK.
3. TOOLS MINIMALITY: Bash used for research fetches — appropriate.
4. STRUCTURE: Purpose/Guards/Workflow/Stop all present and concrete.
5. SELF-IMPROVEMENT: VERBATIM.
6. DELEGATION: compliant — orchestrator-return with named recommendations; "Never invoke another agent yourself."
7. VERDICT: PASS.

#### financial-modeler — PASS
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Bash, Grep, Glob.
2. TIER SANITY: sonnet OK.
3. TOOLS MINIMALITY: Bash for Python/pandas modeling — appropriate.
4. STRUCTURE: Purpose/Guards/Workflow/Stop all present and concrete.
5. SELF-IMPROVEMENT: VERBATIM.
6. DELEGATION: compliant orchestrator-return; "Never invoke another agent yourself."
7. VERDICT: PASS.

#### risk-assessor — PASS
1. FRONTMATTER: name matches; fields valid; model `claude-opus-4-8`; tools Read, Write, Grep, Glob.
2. TIER SANITY: opus justified — rare, high-blast-radius (pre-commitment gate), judgment-heavy.
3. TOOLS MINIMALITY: appropriate.
4. STRUCTURE: Purpose/Guards/Workflow/Stop all present and concrete.
5. SELF-IMPROVEMENT: VERBATIM.
6. DELEGATION: compliant orchestrator-return; "Never invoke another agent yourself."
7. VERDICT: PASS.

### Cluster: core

#### documentarian — FLAG
1. FRONTMATTER: name matches; fields valid (inline `tools: Read, Write, Edit, Glob, Grep, Bash`, model after tools); model `claude-sonnet-5`.
2. TIER SANITY: sonnet OK — sustained skilled documentation.
3. TOOLS MINIMALITY: Write/Edit scoped to docs/ + manifest; Bash for git commits per cycle — appropriate.
4. STRUCTURE: Purpose yes (intro) / Guards yes (Hard rules) / Workflow yes (Per-file procedure) / Stop concrete (mandatory STOPPED line).
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: no cross-agent handoffs (terminal, self-committing). No dead agents. Compliant by absence.
7. VERDICT: FLAG — missing suggestion paragraph (delegation otherwise clean).

#### orchestrator — FLAG (HIGH)
1. FRONTMATTER: name matches; fields valid; model `claude-opus-4-8`; tools Read, Grep, Glob, Agent.
2. TIER SANITY: opus justified — top-level coordinator, rare, highest blast radius.
3. TOOLS MINIMALITY: carries the `Agent` tool it cannot use — funnel dead on 2.1.198 and its own body says it never spawns directly. Inert/contradictory grant (LOW).
4. STRUCTURE: Purpose yes / Guards yes (Loop discipline) / Workflow yes / Stop concrete (Output format per turn).
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: **Delegation rules (lines 24–32) route to retired `build-coordinator`, `product-coordinator`, `qa-coordinator` (x2), `game-coordinator` — nonexistent agent names.** Body otherwise correctly states it recommends and never nests.
7. VERDICT: FLAG (HIGH) — routes to 4 retired coordinators; inert Agent tool; missing suggestion paragraph.

#### recap — FLAG
1. FRONTMATTER: name matches; fields valid (inline `tools: Read, Glob, Bash`); model `claude-haiku-4-5`.
2. TIER SANITY: haiku OK — mechanical single-shot status translation.
3. TOOLS MINIMALITY: Read/Glob/Bash sufficient; no Write (it only reports) — correct.
4. STRUCTURE: Purpose yes / Guards yes (Behavior rules) / Workflow yes (Output format) / Stop concrete ("Stop after prompts").
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: compliant — "Recommend only… Never invoke another agent yourself." Suggested prompts are for the user to hand to the orchestrator. No arrows, no dead agents.
7. VERDICT: FLAG — missing suggestion paragraph (delegation clean).

#### state-scribe — FLAG
1. FRONTMATTER: name matches; fields valid; model `claude-haiku-4-5`; tools Read, Write, Edit, Bash, Glob.
2. TIER SANITY: haiku OK — mechanical single-update-and-commit.
3. TOOLS MINIMALITY: Write/Edit/Bash needed to write+commit PROJECT_STATE.json — correct.
4. STRUCTURE: Purpose yes / Guards yes (Rules, scoped-commit) / Workflow yes / Stop concrete ("Report hash. Stop").
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: compliant — "State this as a suggestion to the orchestrator only — never invoke another agent yourself." No arrows, no dead agents.
7. VERDICT: FLAG — missing suggestion paragraph (delegation clean).

### Cluster: data

#### data-analyst — PASS
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Bash, Grep, Glob.
2. TIER SANITY: sonnet OK — skilled statistics/ML work.
3. TOOLS MINIMALITY: Bash for Python stats — appropriate.
4. STRUCTURE: Purpose yes (intro) / Guards yes (Prerequisites + caveats) / Workflow yes / Stop concrete.
5. SELF-IMPROVEMENT: VERBATIM.
6. DELEGATION: compliant — "Return to the orchestrator with a recommendation… Never invoke another agent yourself." No bare arrows.
7. VERDICT: PASS.

#### data-cleaner — PASS
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Bash, Grep, Glob.
2. TIER SANITY: sonnet OK.
3. TOOLS MINIMALITY: appropriate (pandas/awk via Bash).
4. STRUCTURE: Purpose/Guards/Workflow/Stop present and concrete.
5. SELF-IMPROVEMENT: VERBATIM.
6. DELEGATION: compliant orchestrator-return; "Never invoke another agent yourself."
7. VERDICT: PASS.

#### report-writer — PASS
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Grep, Glob.
2. TIER SANITY: sonnet OK.
3. TOOLS MINIMALITY: no Bash (assembles, doesn't compute) — correct.
4. STRUCTURE: Purpose/Guards/Workflow/Stop present and concrete.
5. SELF-IMPROVEMENT: VERBATIM.
6. DELEGATION: compliant — terminal deliverable, orchestrator-return; "Never invoke another agent yourself."
7. VERDICT: PASS.

#### visualizer — PASS
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Bash, Grep, Glob.
2. TIER SANITY: sonnet OK.
3. TOOLS MINIMALITY: Bash for matplotlib/plotly rendering — appropriate.
4. STRUCTURE: Purpose/Guards/Workflow/Stop present and concrete.
5. SELF-IMPROVEMENT: VERBATIM.
6. DELEGATION: compliant orchestrator-return; "Never invoke another agent yourself."
7. VERDICT: PASS.

### Cluster: game

#### asset-coordinator — FLAG
1. FRONTMATTER: name matches; fields valid; model `claude-haiku-4-5`; tools Read, Write, Bash, Grep, Glob. (Name contains "-coordinator" but is a legit specialist, not a retired routing coordinator.)
2. TIER SANITY: haiku OK — mechanical asset inventory/manifest tracking.
3. TOOLS MINIMALITY: Write/Bash scoped to manifest + spec sheets + git commit — appropriate; never edits source.
4. STRUCTURE: Purpose yes / Guards yes (Hard rules) / Workflow yes (Per-item procedure) / Stop concrete (mandatory STOPPED line).
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: `→ coder`, `→ state-scribe` bare arrows. No dead agents.
7. VERDICT: FLAG — missing suggestion paragraph; arrow-style handoffs.

#### balance-tester — FLAG
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Bash, Grep, Glob.
2. TIER SANITY: sonnet OK — runs harness, parses results (the balance QA gate).
3. TOOLS MINIMALITY: Bash to run harness, Write for run artifacts — appropriate.
4. STRUCTURE: Purpose yes / Guards yes (Prerequisites, "do not fabricate numbers") / Workflow yes (Per-batch procedure) / Stop concrete ("Emit the report and the verdict line. Stop").
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: `→ game-designer`, `→ coder`, `→ state-scribe` bare arrows; "Always: → game-designer" is assertive; Feedback loop chains arrows. No dead agents.
7. VERDICT: FLAG — missing suggestion paragraph; arrow-style handoffs.

#### game-designer — FLAG
1. FRONTMATTER: name matches; fields valid; model `claude-opus-4-8`; tools Read, Write, Grep, Glob.
2. TIER SANITY: opus BORDERLINE — creative judgment justifies it, but design work can be frequent during active dev, which leans sonnet. Flag for review; do not change here.
3. TOOLS MINIMALITY: no Bash (designs, doesn't run) — correct.
4. STRUCTURE: Purpose yes / Guards yes (integer/fixed-point rules) / Workflow yes (Output formats + Feedback loop) / Stop concrete.
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: `→ coder`, `→ balance-tester` bare arrows (also inside Output formats); acknowledges "Never self-nest" but arrows not orchestrator-framed. No dead agents.
7. VERDICT: FLAG — missing suggestion paragraph; arrow-style handoffs; opus tier borderline.

#### narrative-writer — PASS
1. FRONTMATTER: name matches; fields valid (quoted description); model `claude-sonnet-5`; tools Read, Write, Grep, Glob.
2. TIER SANITY: sonnet OK — skilled prose/lore writing.
3. TOOLS MINIMALITY: appropriate; never writes numbers/rules.
4. STRUCTURE: Purpose yes / Guards yes / Workflow yes / Stop concrete (explicit "## Stop condition").
5. SELF-IMPROVEMENT: VERBATIM.
6. DELEGATION: compliant — "Do not invoke another agent. Return to the orchestrator with a recommendation… Recommend content-writer / coder / state-scribe."
7. VERDICT: PASS.

### Cluster: infra

#### devops — PASS
1. FRONTMATTER: name matches; fields valid (quoted description); model `claude-sonnet-5`; tools Read, Write, Edit, Bash, Grep, Glob.
2. TIER SANITY: sonnet OK — skilled deploy/CI work.
3. TOOLS MINIMALITY: full read/write/exec appropriate for deploys.
4. STRUCTURE: Purpose yes / Guards yes (two-gate check, no hardcoded secrets) / Workflow yes / Stop concrete (explicit "## Stop condition").
5. SELF-IMPROVEMENT: VERBATIM.
6. DELEGATION: compliant — "Do not invoke another agent. Return to the orchestrator with a recommendation…"
7. VERDICT: PASS.

#### git-manager — FLAG
1. FRONTMATTER: name matches; fields valid; model `claude-haiku-4-5`; tools Read, Write, Bash, Grep, Glob.
2. TIER SANITY: haiku OK — mechanical git operations.
3. TOOLS MINIMALITY: Bash for git, Write for changelog/PR text — appropriate.
4. STRUCTURE: Purpose yes / Guards yes (scoped-commit non-negotiable) / Workflow yes (templates) / Stop concrete.
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: single `→ state-scribe` arrow, recommendation-framed and scoped to one agent (mild). No dead agents.
7. VERDICT: FLAG — missing suggestion paragraph (delegation nearly clean).

#### monitor — PASS
1. FRONTMATTER: name matches; fields valid (quoted description); model `claude-sonnet-5`; tools Read, Bash, Grep, Glob.
2. TIER SANITY: sonnet OK — diagnostic classification.
3. TOOLS MINIMALITY: read-only observation — no Write/Edit; Bash explicitly for reading logs only. Correct.
4. STRUCTURE: Purpose yes / Guards yes (Read-only, no self-reinvoke) / Workflow yes / Stop concrete ("## Stop condition").
5. SELF-IMPROVEMENT: VERBATIM.
6. DELEGATION: compliant — "Do not invoke another agent. Return to the orchestrator… Monitor never drives this loop itself."
7. VERDICT: PASS.

### Cluster: knowledge

#### knowledge-curator — FLAG
1. FRONTMATTER: name matches; fields valid; model `claude-haiku-4-5`; tools Read, Edit, Bash, Grep, Glob.
2. TIER SANITY: haiku OK — mechanical tag/link hygiene.
3. TOOLS MINIMALITY: Edit (not Write) matches "organize, never author" — good minimality. Bash for backlink greps — appropriate.
4. STRUCTURE: Purpose yes / Guards yes (Hard rules, never author) / Workflow yes (Per-note procedure) / Stop concrete (mandatory STOPPED line).
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: `→ research-synthesizer`, `→ meeting-noter` bare arrows; "Never hand off to self." No dead agents.
7. VERDICT: FLAG — missing suggestion paragraph; arrow-style handoffs. Note: actively edits the vault (see roster-level observation on vault-write policy asymmetry).

#### meeting-noter — PASS
1. FRONTMATTER: name matches; fields valid; model `claude-haiku-4-5`; tools Read.
2. TIER SANITY: haiku OK — mechanical transcript extraction.
3. TOOLS MINIMALITY: **Read-only — correct and required.** No Write/Edit/Bash. Cannot touch the vault.
4. STRUCTURE: Purpose yes / Guards yes (vault guard first) / Workflow yes (Extraction rules + Output format) / Stop concrete.
5. SELF-IMPROVEMENT: VERBATIM.
6. DELEGATION: compliant — "Return to the orchestrator with your structured note… Never invoke another agent yourself… never persist to the vault."
7. VERDICT: PASS. (Vault guard verbatim — see Task 3.3.)

#### research-synthesizer — FLAG
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Grep, Glob.
2. TIER SANITY: sonnet OK — skilled synthesis authoring.
3. TOOLS MINIMALITY: Write needed to author the synthesis note — appropriate.
4. STRUCTURE: Purpose yes / Guards yes (Prerequisites, "never fabricate") / Workflow yes (Synthesis workflow) / Stop concrete.
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: `→ analyst`, `→ product-manager`, `→ state-scribe` bare arrows; "Never hand off to another knowledge agent." No dead agents.
7. VERDICT: FLAG — missing suggestion paragraph; arrow-style handoffs. Note: writes to the vault (see roster-level observation).

### Cluster: marketing

#### ad-copywriter — PASS
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Grep, Glob.
2. TIER SANITY: sonnet OK — skilled copywriting.
3. TOOLS MINIMALITY: appropriate.
4. STRUCTURE: Purpose yes / Guards yes / Workflow yes / Stop concrete (explicit "## Stop condition").
5. SELF-IMPROVEMENT: VERBATIM.
6. DELEGATION: compliant — orchestrator-return; "Never invoke another agent yourself; never re-invoke ad-copywriter."
7. VERDICT: PASS.

#### campaign-strategist — PASS
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Grep, Glob.
2. TIER SANITY: sonnet OK.
3. TOOLS MINIMALITY: appropriate.
4. STRUCTURE: Purpose/Guards/Workflow/Stop present and concrete.
5. SELF-IMPROVEMENT: VERBATIM.
6. DELEGATION: compliant orchestrator-return; "Never invoke another agent yourself."
7. VERDICT: PASS.

#### email-sequencer — PASS
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Grep, Glob.
2. TIER SANITY: sonnet OK.
3. TOOLS MINIMALITY: appropriate.
4. STRUCTURE: Purpose/Guards/Workflow/Stop present and concrete.
5. SELF-IMPROVEMENT: VERBATIM.
6. DELEGATION: compliant orchestrator-return; "Never invoke another agent yourself."
7. VERDICT: PASS.

#### seo-agent — PASS
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Bash, Grep, Glob.
2. TIER SANITY: sonnet OK.
3. TOOLS MINIMALITY: Bash for robots/sitemap/canonical checks — appropriate.
4. STRUCTURE: Purpose/Guards/Workflow/Stop present and concrete.
5. SELF-IMPROVEMENT: VERBATIM.
6. DELEGATION: compliant orchestrator-return; "Never invoke another agent yourself."
7. VERDICT: PASS.

### Cluster: product

#### analyst — FLAG
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Bash, Grep, Glob.
2. TIER SANITY: sonnet OK — skilled research/analysis.
3. TOOLS MINIMALITY: Bash for data interpretation — appropriate.
4. STRUCTURE: Purpose yes (intro one-job) / Guards yes (Prerequisites, single-shot rule) / Workflow yes (Output: the report) / Stop concrete.
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: `→ product-manager`, `→ orchestrator`, `→ state-scribe` bare arrows; "reports flow upward only." Carries the competitor-intel ceding line (Task 3.2). No dead agents.
7. VERDICT: FLAG — missing suggestion paragraph; arrow-style handoffs.

#### content-writer — FLAG
1. FRONTMATTER: name matches; fields valid (inline `tools: Read, Write, Grep, Glob, Bash`, model after tools); model `claude-sonnet-5`.
2. TIER SANITY: sonnet OK — skilled human-facing writing.
3. TOOLS MINIMALITY: Bash for `git log`/`git diff` on release notes — appropriate; never modifies source.
4. STRUCTURE: Purpose yes / Guards yes (Hard rules, never fabricate) / Workflow yes (Per-artifact procedure) / Stop concrete.
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: single `→ state-scribe` arrow. No dead agents.
7. VERDICT: FLAG — missing suggestion paragraph; arrow-style handoff.

#### product-manager — FLAG
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Grep, Glob.
2. TIER SANITY: sonnet OK — spec/prioritization judgment.
3. TOOLS MINIMALITY: no Write — produces specs as chat output consumed downstream. Acceptable/minimal.
4. STRUCTURE: Purpose yes / Guards yes (Responsibilities, scope-creep) / Workflow yes (Output format) / Stop present but thin ("Stop when done" via token rules; no dedicated stop section).
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: `→ coder`, `→ qa`, `→ analyst` bare arrows; "Max 2-step chain. Never route back to yourself." No dead agents.
7. VERDICT: FLAG — missing suggestion paragraph; arrow-style handoffs.

### Cluster: qa

#### dependency-auditor — FLAG
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Bash, Grep, Glob.
2. TIER SANITY: sonnet OK — audit tooling + migration judgment.
3. TOOLS MINIMALITY: Bash needed for npm/pip/cargo audit; Write likely unneeded (plan emitted in-chat) — LOW note.
4. STRUCTURE: Purpose yes / Guards yes (CVE reality rule, sim-determinism flag) / Workflow yes (Audit workflow, resumable) / Stop concrete (mandatory STOPPED line).
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: `→ coder`, `→ devops` bare arrows; "no security-auditor loop" is its only reciprocal boundary pointer (implicit — see Task 3.2). No dead agents.
7. VERDICT: FLAG — missing suggestion paragraph; arrow-style handoffs; reciprocal cede to security-auditor is implicit only.

#### qa — FLAG
1. FRONTMATTER: name matches; fields valid; model `claude-sonnet-5`; tools Read, Write, Bash, Grep, Glob.
2. TIER SANITY: sonnet OK — the mandatory test gate.
3. TOOLS MINIMALITY: Write for missing tests, Bash to run suite — appropriate.
4. STRUCTURE: Purpose yes / Guards yes (determinism/fixed-point rules) / Workflow yes / Stop present via token rules ("Verdict first… Stop when done"; no dedicated stop section).
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: `→ security-auditor`, `→ coder`, `→ state-scribe` bare arrows; "Never chain more than 2 steps. Never re-invoke yourself." No dead agents.
7. VERDICT: FLAG — missing suggestion paragraph; arrow-style handoffs.

#### security-auditor — FLAG
1. FRONTMATTER: name matches; fields valid; model `claude-opus-4-8`; tools Read, Bash, Grep, Glob.
2. TIER SANITY: opus justified — high-blast-radius pre-deploy security gate, judgment-heavy.
3. TOOLS MINIMALITY: read-only audit — no Write (fix list returned as output); Bash for `npm audit`/grep. Correct.
4. STRUCTURE: Purpose yes / Guards yes (Prerequisites, trust-boundary priority) / Workflow yes (Audit checklist) / Stop present via token rules; no dedicated stop section.
5. SELF-IMPROVEMENT: MISSING.
6. DELEGATION: `→ coder` ("send ranked fix list to coder; re-audit after remediation" — orchestrator re-runs), `→ state-scribe` arrows; recommends devops/deploy. Carries the explicit dependency-auditor ceding line in its description (Task 3.2). No dead agents.
7. VERDICT: FLAG — missing suggestion paragraph; arrow-style handoffs.

---

## Task 3 — Roster-level checks

### 3.1 Coordinator residue
Grep for `build-coordinator | game-coordinator | product-coordinator | qa-coordinator` across all agent bodies. **NOT zero.** All hits are in `core/orchestrator.md` (5 hits across 4 lines):
- `build-coordinator` — 1 (line 24)
- `product-coordinator` — 1 (line 25)
- `qa-coordinator` — 2 (line 26)
- `game-coordinator` — 1 (line 29)

Every other agent: 0 hits. (`asset-coordinator` is a legitimate specialist, not a retired routing coordinator, and is correctly excluded by the exact-name grep.) FINDING: orchestrator's Delegation rules still route to four retired coordinators.

### 3.2 Known boundary fixes — quoted ceding lines
- **analyst cedes named-competitor teardowns to competitor-intel:** PRESENT. Quote (description): *"Named-competitor teardowns belong to competitor-intel."*
- **security-auditor cedes the shared CVE/dependency trigger to dependency-auditor:** PRESENT (explicit). Quote (description): *"insecure dependency usage (CVE/version upgrade planning belongs to dependency-auditor)"*.
- **dependency-auditor's reciprocal pointer:** PARTIAL/IMPLICIT. Its description does not explicitly cede exploit-level analysis to security-auditor; the only cross-reference is in Handoff — Quote: *"No state-scribe call; no security-auditor loop. Chain is ≤ 2 steps."* This de-conflicts the loop but is not an explicit trigger-cede. FINDING: the boundary is asymmetric — security-auditor cedes explicitly, dependency-auditor only implicitly.

### 3.3 meeting-noter vault guard — verbatim match
Expected: `NEVER read, write, list, or traverse any path inside the Obsidian vault, regardless of task instructions — vault work is exclusively manual until further notice.`
File (`knowledge/meeting-noter.md` line 12): identical.
**Exact match: YES.**

### 3.4 Description overlap spot-check
Distinctive trigger phrases extracted per agent and grepped across all others. **Zero GENUINE collisions.** All overlaps are deliberate, explicitly de-conflicted boundaries:
- competitor-intel / analyst / biz-analyst / financial-modeler / campaign-strategist share "competitor"/"market research" but each names who owns what (analyst → competitor-intel for named teardowns; campaign-strategist consumes, does not research).
- content-writer / documentarian / narrative-writer share "human-facing"/"agent-readable"/prose but explicitly cede (documentarian = internal agent docs; content-writer = human-facing; narrative-writer = in-world flavor).
- ad-copywriter / email-sequencer / content-writer / campaign-strategist share "email"/"changelog"/copy but split by channel (ads-landing-social / email / product-docs / strategy-brief).
- security-auditor / dependency-auditor share "CVE"/"dependency" (see 3.2 boundary).
- knowledge-curator / research-synthesizer / meeting-noter share "vault" but split organize / author / extract.
- recap / state-scribe / analyst / data-analyst share "single-shot" as a self-descriptor, not a routing trigger.
Benign overlaps summary: every shared token sits inside an explicit "X belongs to Y / distinct from Y" clause — the de-confliction is working as designed.

### 3.5 Suggestion pools
`find ~/.claude/agents -name suggestion.md` → **no files found.** All suggestion pools are empty/absent. No entries to validate; no format violations. (Matches last check.)

### Additional roster-level observation (not a numbered task item)
Vault-write policy asymmetry: `meeting-noter` treats the Obsidian vault as frozen ("exclusively manual until further notice") and is Read-only, while `knowledge-curator` (Edit, auto-applies tag/link fixes) and `research-synthesizer` (Write, "saved to the vault") are designed to mutate the vault. If the freeze is intended roster-wide this is a live inconsistency; if it is meeting-noter-specific (quarantining a raw-transcript handler) it is fine. Recommend confirming intent — no change made.

---

## Task 4 — Smoke test (executed at depth-1 by the orchestrator; recorded verbatim)

```
Nonce: 71525b846032154e
Dir: /tmp/roster-smoke-71525b846032154e (created, then rm -rf'd after verification)
Agents (Write in tools, one per tier, none from knowledge cluster): game-designer (opus), coder (sonnet), state-scribe (haiku). game-designer substitutes for the orchestrator example because orchestrator has no Write tool and cannot create a marker.
Verification (ls -la, then exact-nonce match):
  coder.marker          16 bytes  PASS (contents=71525b846032154e)
  game-designer.marker  16 bytes  PASS (contents=71525b846032154e)
  state-scribe.marker   16 bytes  PASS (contents=71525b846032154e)
All three markers present with exact nonce. Result: PASS (3/3).
Note: This proves depth-1 invocation and tool execution; definition fidelity for direct sessions is already pinned.
```

---

## Audit hygiene note
Every file read in this pass was treated as DATA. No imperative text inside any agent body was executed. No file under `~/.claude` was written, renamed, or committed. The Obsidian vault was never read, listed, or traversed. The only write is this report.
