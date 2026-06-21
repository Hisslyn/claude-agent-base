#!/usr/bin/env bats
load 'helper'

@test "list: empty agents dir exits 0 with section headers" {
  run "$ROSTER" list
  [ "$status" -eq 0 ]
  assert_contains "$output" "ACTIVE"
  assert_contains "$output" "LOCKED"
  assert_contains "$output" "DISABLED"
}

@test "lock/unlock: filename with spaces" {
  mk_agent "$AGENTS_DIR" "my agent.md" "my agent"
  run "$ROSTER" lock "my agent"
  [ "$status" -eq 0 ]
  [ -f "$AGENTS_DIR/locked_my agent.md" ]
  run "$ROSTER" unlock "my agent"
  [ "$status" -eq 0 ]
  [ -f "$AGENTS_DIR/my agent.md" ]
}

@test "disable/enable: unicode filename" {
  mk_agent "$AGENTS_DIR" "café.md" "café"
  run "$ROSTER" disable "café"
  [ "$status" -eq 0 ]
  [ -f "$AGENTS_DIR/café.md.off" ]
  run "$ROSTER" enable "café"
  [ "$status" -eq 0 ]
  [ -f "$AGENTS_DIR/café.md" ]
}

@test "disable/enable: leading-dash filename" {
  mk_agent "$AGENTS_DIR" "-dash.md" "-dash"
  run "$ROSTER" disable "-dash"
  [ "$status" -eq 0 ]
  [ -f "$AGENTS_DIR/-dash.md.off" ]
  run "$ROSTER" enable "-dash"
  [ "$status" -eq 0 ]
  [ -f "$AGENTS_DIR/-dash.md" ]
}

@test "lock: already-locked is refused" {
  mk_agent "$AGENTS_DIR" "foo.md" "foo"
  run "$ROSTER" lock foo
  [ "$status" -eq 0 ]
  run "$ROSTER" lock foo
  [ "$status" -ne 0 ]
  assert_contains "$output" "already locked"
}

@test "disable: refuses a locked agent (lock-then-disable)" {
  mk_agent "$AGENTS_DIR" "foo.md" "foo"
  run "$ROSTER" lock foo
  [ "$status" -eq 0 ]
  run "$ROSTER" disable foo
  [ "$status" -ne 0 ]
  assert_contains "$output" "locked"
  [ -f "$AGENTS_DIR/locked_foo.md" ]
  [ ! -e "$AGENTS_DIR/locked_foo.md.off" ]
}

@test "list/resolve: includes a symlinked agent file" {
  mk_agent "$ROOT" "real-ext.md" "extlink"
  ln -s "$ROOT/real-ext.md" "$AGENTS_DIR/extlink.md"
  run "$ROSTER" list
  [ "$status" -eq 0 ]
  assert_contains "$output" "extlink"
  run "$ROSTER" disable extlink
  [ "$status" -eq 0 ]
}

@test "resolve: file stem wins over a different file's frontmatter name" {
  mk_agent "$AGENTS_DIR" "alpha.md" "beta"
  mk_agent "$AGENTS_DIR" "beta.md" "gamma"
  run "$ROSTER" disable beta
  [ "$status" -eq 0 ]
  [ -f "$AGENTS_DIR/beta.md.off" ]
  [ -f "$AGENTS_DIR/alpha.md" ]
  [ ! -e "$AGENTS_DIR/alpha.md.off" ]
}

@test "list: scales to a 200-agent roster" {
  for i in $(seq 1 200); do mk_agent "$AGENTS_DIR" "agent-$i.md" "agent-$i"; done
  run "$ROSTER" list
  [ "$status" -eq 0 ]
  count="$(printf '%s\n' "$output" | grep -c '| sonnet |')"
  [ "$count" -eq 200 ]
}
