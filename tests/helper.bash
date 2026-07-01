# Shared bats helpers for the scripts/ hardening suite.
SCRIPTS="${BATS_TEST_DIRNAME}/../scripts"
ROSTER="$SCRIPTS/roster.sh"
TUNE="$SCRIPTS/tune-roster.sh"
NEWAGENT="$SCRIPTS/new-agent.sh"

setup() {
  ROOT="$(mktemp -d)"
  AGENTS_DIR="$ROOT/agents"
  mkdir -p "$AGENTS_DIR"
  export AGENTS_DIR
}

teardown() {
  [ -n "${ROOT:-}" ] && rm -rf "$ROOT"
}

# mk_agent <dir> <filename> <frontmatter-name> [model]
mk_agent() {
  local dir="$1" fn="$2" nm="$3" model="${4:-sonnet}"
  cat >"$dir/$fn" <<EOF
---
name: $nm
description: Test fixture agent $nm used by the scripts/ hardening suite.
model: $model
tools:
  - Read
---
Body for $nm.
EOF
}

# Substring assertion as a *simple command* so bats' errexit catches a
# mid-body failure (a bare `[[ ]]` does not fail a bats test mid-body).
assert_contains() {
  case "$1" in
    *"$2"*) return 0 ;;
    *)
      printf 'assert_contains failed\n  needle: %s\n  haystack: %s\n' "$2" "$1" >&2
      return 1
      ;;
  esac
}

assert_not_contains() {
  case "$1" in
    *"$2"*)
      printf 'assert_not_contains failed\n  needle: %s\n  haystack: %s\n' "$2" "$1" >&2
      return 1
      ;;
    *) return 0 ;;
  esac
}

# Initialise AGENTS_DIR as a git repo with committable identity.
git_init_agents() {
  git -C "$AGENTS_DIR" init -q
  git -C "$AGENTS_DIR" config user.email "qa@example.com"
  git -C "$AGENTS_DIR" config user.name "qa"
  git -C "$AGENTS_DIR" config commit.gpgsign false
}
