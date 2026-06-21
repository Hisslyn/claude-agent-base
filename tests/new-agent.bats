#!/usr/bin/env bats
load 'helper'

@test "new-agent: refuses a name with spaces" {
  run "$NEWAGENT" "my agent"
  [ "$status" -ne 0 ]
  assert_contains "$output" "kebab-case"
}

@test "new-agent: refuses a unicode name" {
  run "$NEWAGENT" "café"
  [ "$status" -ne 0 ]
  assert_contains "$output" "kebab-case"
}

@test "new-agent: refuses a leading-dash name" {
  run "$NEWAGENT" "-dash"
  [ "$status" -ne 0 ]
  assert_contains "$output" "kebab-case"
}

@test "new-agent: creates a kebab-case agent and refuses to overwrite" {
  run "$NEWAGENT" good-agent "A helper role."
  [ "$status" -eq 0 ]
  [ -f "$AGENTS_DIR/good-agent.md" ]
  run "$NEWAGENT" good-agent
  [ "$status" -ne 0 ]
  assert_contains "$output" "already exists"
}
