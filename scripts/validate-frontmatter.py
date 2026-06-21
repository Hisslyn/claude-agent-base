#!/usr/bin/env python3
"""validate-frontmatter.py — enforce that an edited agent file still has a
valid YAML frontmatter block with a non-empty `name`.

Designed as a Claude Code PostToolUse / SubagentStop hook for Edit|Write.
- Reads the edited file path from argv[1], or from the hook JSON on stdin
  (tool_input.file_path / .path).
- Validates only `.md` files living under a `.claude/agents` path; anything
  else exits 0 (do not block unrelated edits).
- Exit 0 = valid. Exit 2 = invalid frontmatter (blocks the tool / flags).
Run standalone too:  validate-frontmatter.py path/to/agent.md
"""
import json
import re
import sys


def target_from_stdin():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return None
    ti = data.get("tool_input") or data.get("toolInput") or {}
    return ti.get("file_path") or ti.get("path") or data.get("file_path")


def is_agent_md(path):
    return path.endswith(".md") and ".claude/agents" in path.replace("\\", "/")


def parse_frontmatter(text):
    """Return (ok, message). Uses PyYAML if present, else a lenient check."""
    if not text.startswith("---"):
        return False, "missing opening --- fence"
    lines = text.splitlines()
    # find closing fence after line 0
    close = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            close = i
            break
    if close is None:
        return False, "missing closing --- fence"
    block = "\n".join(lines[1:close])

    try:
        import yaml  # type: ignore
    except ImportError:
        yaml = None
    if yaml is not None:
        try:
            meta = yaml.safe_load(block)
        except Exception as exc:  # malformed YAML
            return False, "invalid YAML: %s" % (str(exc).splitlines() or [""])[0]
        if not isinstance(meta, dict):
            return False, "frontmatter is not a mapping"
        if not str(meta.get("name", "")).strip():
            return False, "missing or empty `name`"
        return True, "ok"

    # Lenient fallback: every non-empty, non-list, non-comment line must look
    # like `key:`; `name` must appear with a value.
    has_name = False
    key_re = re.compile(r"^[A-Za-z0-9_-]+:(\s|$)")
    for raw in block.splitlines():
        line = raw.rstrip()
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.lstrip().startswith("- "):  # block-list item
            continue
        if not key_re.match(line.lstrip()):
            return False, "malformed frontmatter line: %r" % line
        if re.match(r"^name:\s*\S", line.strip()):
            has_name = True
    if not has_name:
        return False, "missing or empty `name`"
    return True, "ok (lenient: PyYAML not installed)"


def main():
    target = sys.argv[1] if len(sys.argv) > 1 else target_from_stdin()
    if not target or not is_agent_md(target):
        return 0
    try:
        with open(target, "r", encoding="utf-8") as fh:
            text = fh.read()
    except OSError as exc:
        print("validate-frontmatter: cannot read %s: %s" % (target, exc), file=sys.stderr)
        return 2
    ok, msg = parse_frontmatter(text)
    if not ok:
        print("validate-frontmatter: %s — %s" % (target, msg), file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
