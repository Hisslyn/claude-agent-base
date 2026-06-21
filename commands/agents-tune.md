---
name: agents-tune
description: Resumable bulk tune of the whole roster against a named standard. Drives the loop; tuning judgment runs in the agent-manager subagent. Explicit-only.
disable-model-invocation: true
---
Resumable bulk tune. `$ARGUMENTS` is the tuning standard or exemplar reference.

1. Run `bash scripts/tune-roster.sh init "$ARGUMENTS"`. Append `--fresh` only if the user explicitly asked to restart. If it reports a different standard already in progress, stop and ask the user whether to resume or restart with `--fresh`.
2. Run `bash scripts/tune-roster.sh next`.
   - If it prints `DONE`, go to step 4.
   - Otherwise it prints a file path, then a `---STANDARD---` line, then the standard. Invoke the **agent-manager** subagent to tune that file to that standard.
   - Then run `bash scripts/tune-roster.sh done <name>`, where `<name>` is the agent's frontmatter `name`.
3. Repeat step 2.
4. On `DONE`, run `bash scripts/tune-roster.sh finish`.

The script owns the manifest, resume point, per-file git commits, and exclusions (locked, `.off`, the manager itself). Do not maintain that state yourself.
