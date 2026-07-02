# Improvement Log

Findings and fixes surfaced during roster maintenance. Newest entries appended at the end.

## 2026-07-02 — source: unlock thread

- **validate-frontmatter / PostToolUse hook false-positive on "report" filenames.** The hook fired on `report-writer.md` (an agent definition) because its filename contains the substring "report". Fix: match on artifact content/location, not a filename substring.
- **Plan-then-apply deadlock when agent-manager runs as a subagent.** A gated pass relayed a confirmation correctly rejected it — there is no user→subagent channel, so the pass could not proceed. Fix: document that gated passes require a direct session.
- **Nested spawning (depth 2) verified dead on CLI 2.1.198** via nonce-marker test; depth-1 `--agent` faithful. Already pinned in the skill; logged here for version history.
