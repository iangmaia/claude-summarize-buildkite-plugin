# Runtime Secret Reference Follow-up

## Problem

The plugin environment hook eagerly resolves API-key references before repository `pre-command` hooks run, which can freeze an older agent-level value. Runtime references also omit the common `${VARIABLE}` form, and Buildkite token validation can disagree with the resolved token used at runtime.

## Approach

Keep secret references unchanged in `hooks/environment` and resolve them at their point of use in `hooks/post-command`. Extend `plugin_read_secret_config` to accept only exact `$VARIABLE` and `${VARIABLE}` references. Make validation rely on the resolved Buildkite token passed by the caller.

## Tasks

- [x] Preserve API-key references through the environment hook.
- [x] Support exact braced and unbraced runtime references without evaluating shell input.
- [x] Align Buildkite token validation with runtime resolution.
- [x] Update README and plugin schema descriptions.
- [x] Add regression tests for hook ordering, brace syntax, malformed references, fallback behavior, and validation.
- [x] Ensure the shell-expression regression test invokes the secret resolver directly.
- [x] Run available tests and static checks.

## Implementation Notes

The existing hardening was preserved separately in commit `0884ff7` before applying these follow-up fixes. Exact regex branches are used for braced and unbraced references so mismatched braces remain literal. Validation now treats its token argument as authoritative because callers pass the resolved value.

`bash -n`, `git diff --check`, YAML parsing, and a focused Bash regression harness passed. After OrbStack became available, the containerized Bats suite also passed all 45 tests, with the existing API-failure test skipped as expected. ShellCheck was not installed locally.
