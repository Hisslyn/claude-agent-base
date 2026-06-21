#!/usr/bin/env bats
load 'helper'

@test "init: no-git repo backs up tunable files to .bak" {
  mk_agent "$AGENTS_DIR" "a.md" "a"
  mk_agent "$AGENTS_DIR" "b.md" "b"
  run "$TUNE" init "be excellent"
  [ "$status" -eq 0 ]
  assert_contains "$output" ".bak"
  [ -f "$AGENTS_DIR/a.md.bak" ]
  [ -f "$AGENTS_DIR/b.md.bak" ]
}

@test "done: commits scoped to exactly one file, never -A/-am" {
  git_init_agents
  mk_agent "$AGENTS_DIR" "a.md" "a"
  mk_agent "$AGENTS_DIR" "b.md" "b"
  git -C "$AGENTS_DIR" add -A
  git -C "$AGENTS_DIR" commit -q -m "init"
  "$TUNE" init "std" >/dev/null
  # Unrelated dirty state that an -A/-am commit would wrongly capture.
  echo "dirty" >"$AGENTS_DIR/UNRELATED.txt"
  echo "tuned" >>"$AGENTS_DIR/a.md"
  run "$TUNE" done a
  [ "$status" -eq 0 ]
  run git -C "$AGENTS_DIR" diff-tree --no-commit-id --name-only -r HEAD
  [ "$output" = "a.md" ]
  run git -C "$AGENTS_DIR" log -1 --format=%s
  [ "$output" = "agents: tune a" ]
  run git -C "$AGENTS_DIR" status --porcelain
  assert_contains "$output" "?? UNRELATED.txt"
}

@test "scripts never invoke git add -A or commit -a" {
  run grep -nE '(add[[:space:]]+-A|commit[[:space:]]+-a)' "$TUNE" "$ROSTER" "$NEWAGENT"
  [ "$status" -ne 0 ]
}

@test "next: half-written manifest with one pending returns that file" {
  mk_agent "$AGENTS_DIR" "a.md" "a"
  mk_agent "$AGENTS_DIR" "b.md" "b"
  m="$AGENTS_DIR/_roster_manifest"
  {
    printf '# hash deadbeef\n'
    printf '# standard the standard\n'
    printf 'a\tdone\t%s\n' "$AGENTS_DIR/a.md"
    printf 'b\tpending\t%s\n' "$AGENTS_DIR/b.md"
  } >"$m"
  run "$TUNE" next
  [ "$status" -eq 0 ]
  assert_contains "$output" "b.md"
  assert_contains "$output" "---STANDARD---"
  assert_contains "$output" "the standard"
  run "$TUNE" status
  assert_contains "$output" "1/2 done"
  assert_contains "$output" "next: b"
}

@test "init --fresh: resets an in-progress pass" {
  mk_agent "$AGENTS_DIR" "a.md" "a"
  mk_agent "$AGENTS_DIR" "b.md" "b"
  mk_agent "$AGENTS_DIR" "c.md" "c"
  "$TUNE" init "standard one" >/dev/null
  "$TUNE" done a >/dev/null
  run "$TUNE" status
  assert_contains "$output" "1/3 done"
  run "$TUNE" init "standard two" --fresh
  [ "$status" -eq 0 ]
  run "$TUNE" status
  assert_contains "$output" "0/3 done"
}

@test "init: differing standard without --fresh refuses" {
  mk_agent "$AGENTS_DIR" "a.md" "a"
  "$TUNE" init "standard one" >/dev/null
  run "$TUNE" init "standard two"
  [ "$status" -ne 0 ]
  assert_contains "$output" "different standard"
}

@test "init: excludes agent-manager from the tunable set" {
  mk_agent "$AGENTS_DIR" "agent-manager.md" "agent-manager"
  mk_agent "$AGENTS_DIR" "a.md" "a"
  mk_agent "$AGENTS_DIR" "b.md" "b"
  "$TUNE" init "std" >/dev/null
  run "$TUNE" status
  assert_contains "$output" "0/2 done"
}

@test "init: includes a symlinked agent in the tunable set" {
  mk_agent "$ROOT" "ext.md" "ext"
  ln -s "$ROOT/ext.md" "$AGENTS_DIR/ext.md"
  mk_agent "$AGENTS_DIR" "a.md" "a"
  "$TUNE" init "std" >/dev/null
  run "$TUNE" status
  assert_contains "$output" "0/2 done"
}

@test "init/status: scales to a 200-agent roster" {
  for i in $(seq 1 200); do mk_agent "$AGENTS_DIR" "agent-$i.md" "agent-$i"; done
  run "$TUNE" init "scale standard"
  [ "$status" -eq 0 ]
  run "$TUNE" status
  assert_contains "$output" "0/200 done"
}
