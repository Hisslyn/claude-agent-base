#!/usr/bin/env python3
"""validate-frontmatter.py — enforce that an edited agent file still has valid
frontmatter: a non-empty `name`, a non-empty/non-placeholder `description`, and
a `name` that is unique across the agents tree.

Designed as a Claude Code PostToolUse / SubagentStop hook for Edit|Write.
- Reads the edited file path from argv, or from the hook JSON on stdin
  (tool_input.file_path / .path).
- By default validates only `.md` files living under a `.claude/agents` OR a
  project-root `agents/` path; anything else exits 0 (QA-010).
- `--force` validates the given file regardless of location — used by
  new-agent.sh, whose shell-redirect write never triggers the tool hook (QA-013).
- Exit 0 = valid. Exit 2 = invalid frontmatter (blocks the tool / flags).
Run standalone too:  validate-frontmatter.py [--force] path/to/agent.md
"""
import json
import os
import re
import sys

# Legacy scaffold placeholder; an unrefined description must not reach the router.
PLACEHOLDER = "what triggers auto-delegation"


def target_from_stdin():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return None
    ti = data.get("tool_input") or data.get("toolInput") or {}
    return ti.get("file_path") or ti.get("path") or data.get("file_path")


def is_agent_md(path):
    p = path.replace("\\", "/")
    if not p.endswith(".md"):
        return False
    return "/.claude/agents" in p or "/agents/" in p


def split_frontmatter(text):
    """Return (ok, message, block_text)."""
    if not text.startswith("---"):
        return False, "missing opening --- fence", ""
    lines = text.splitlines()
    close = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            close = i
            break
    if close is None:
        return False, "missing closing --- fence", ""
    return True, "ok", "\n".join(lines[1:close])


def _clean(val):
    val = re.sub(r"\s+#.*$", "", val).strip()  # strip inline comment
    if len(val) >= 2 and val[0] == val[-1] and val[0] in "\"'":
        val = val[1:-1]
    return val


def parse_meta(block):
    """Best-effort frontmatter -> dict. PyYAML if importable, else a lenient
    top-level key parser that strips quotes and inline comments (QA-022 — keeps
    this in agreement with how the shell tools and Claude read the value).
    Returns None on malformed input."""
    try:
        import yaml  # type: ignore

        meta = yaml.safe_load(block)
        if isinstance(meta, dict):
            return meta
    except ImportError:
        pass
    except Exception:
        return None
    meta = {}
    for raw in block.splitlines():
        line = raw.rstrip()
        s = line.lstrip()
        if not s or s.startswith("#") or s.startswith("- "):
            continue
        if line[0] in " \t":  # nested mapping value — skip
            continue
        m = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if not m:
            return None
        meta[m.group(1)] = _clean(m.group(2))
    return meta


def agents_root(path):
    p = os.path.abspath(path).replace("\\", "/")
    key = "/.claude/agents"
    i = p.find(key)
    if i != -1:
        return p[: i + len(key)]
    parts = p.split("/")
    for j in range(len(parts) - 2, -1, -1):  # exclude the filename itself
        if parts[j] == "agents":
            return "/".join(parts[: j + 1])
    return os.path.dirname(p)


def name_of(path):
    try:
        with open(path, "r", encoding="utf-8") as fh:
            ok, _, block = split_frontmatter(fh.read())
    except OSError:
        return None
    if not ok:
        return None
    meta = parse_meta(block)
    if not isinstance(meta, dict):
        return None
    n = meta.get("name")
    return str(n).strip() if n is not None else None


def duplicates(target, name):
    root = agents_root(target)
    tgt = os.path.abspath(target)
    dupes = []
    for dirpath, _dirs, files in os.walk(root):
        for f in files:
            if not f.endswith(".md"):
                continue
            fp = os.path.join(dirpath, f)
            if os.path.abspath(fp) == tgt:
                continue
            if name_of(fp) == name:
                dupes.append(fp)
    return dupes


def validate(target):
    try:
        with open(target, "r", encoding="utf-8") as fh:
            text = fh.read()
    except OSError as exc:
        return 2, "cannot read %s: %s" % (target, exc)
    ok, msg, block = split_frontmatter(text)
    if not ok:
        return 2, msg
    meta = parse_meta(block)
    if not isinstance(meta, dict):
        return 2, "invalid YAML / frontmatter is not a mapping"
    name = str(meta.get("name", "")).strip()
    if not name:
        return 2, "missing or empty `name`"
    desc = str(meta.get("description", "")).strip()
    if not desc:
        return 2, "missing or empty `description`"
    if PLACEHOLDER in desc:
        return 2, "placeholder description — refine before use"
    dupes = duplicates(target, name)
    if dupes:
        return 2, "duplicate name %r also defined in: %s" % (name, ", ".join(dupes))
    return 0, "ok"


def main():
    argv = sys.argv[1:]
    force = "--force" in argv
    argv = [a for a in argv if a != "--force"]
    target = argv[0] if argv else target_from_stdin()
    if not target or (not force and not is_agent_md(target)):
        return 0
    code, msg = validate(target)
    if code != 0:
        print("validate-frontmatter: %s — %s" % (target, msg), file=sys.stderr)
    return code


if __name__ == "__main__":
    sys.exit(main())
