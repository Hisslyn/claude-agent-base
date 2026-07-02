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
  run "$NEWAGENT" good-agent claude-sonnet-5 "A helper role."
  [ "$status" -eq 0 ]
  [ -f "$AGENTS_DIR/good-agent.md" ]
  run "$NEWAGENT" good-agent claude-sonnet-5
  [ "$status" -ne 0 ]
  assert_contains "$output" "already exists"
}

@test "new-agent: scaffold carries no inert invocation fields" {
  run "$NEWAGENT" clean-agent claude-sonnet-5 "A helper role."
  [ "$status" -eq 0 ]
  run cat "$AGENTS_DIR/clean-agent.md"
  assert_not_contains "$output" "disable-model-invocation"
  assert_not_contains "$output" "user-invocable"
}

@test "new-agent: rejects a bare model alias" {
  run "$NEWAGENT" alias-agent sonnet "A helper role."
  [ "$status" -ne 0 ]
  assert_contains "$output" "claude-sonnet-5"
}

@test "new-agent: writes the given full model id into the scaffold" {
  run "$NEWAGENT" tiered-agent claude-haiku-4-5 "A helper role."
  [ "$status" -eq 0 ]
  run cat "$AGENTS_DIR/tiered-agent.md"
  assert_contains "$output" "model: claude-haiku-4-5"
}
