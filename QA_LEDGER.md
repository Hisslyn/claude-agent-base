| id | file | issue | severity | found-by | status |
| --- | --- | --- | --- | --- | --- |
| QA-001 | scripts/tune-roster.sh | `git commit -- "$file" -m MSG` puts `-m`/message after the `--` pathspec separator, so git treats them as pathspecs and the commit fails; `\|\| true` swallows it, so tuned files are never committed | high | mechanical | fixed |
| QA-002 | scripts/tune-roster.sh | `grep -P` in cmd_status/cmd_finish is unsupported by BSD grep (present on host); status/finish counts silently break | high | mechanical | fixed |
| QA-003 | scripts/roster.sh | `find -type f` skips symlinked agent files, so list and frontmatter-name resolution hide them although stem resolution (`test -f`) follows symlinks | medium | mechanical | fixed |
| QA-004 | scripts/tune-roster.sh | `tunable_files` `find -type f` skips symlinked agents (same class as QA-003), excluding them from a tune pass | medium | mechanical | fixed |
| QA-005 | scripts/roster.sh | shfmt -i 2 formatting nonconformance | low | mechanical | fixed |
| QA-006 | scripts/tune-roster.sh | shfmt -i 2 formatting nonconformance | low | mechanical | fixed |
| QA-007 | scripts/new-agent.sh | shfmt -i 2 formatting nonconformance | low | mechanical | fixed |
