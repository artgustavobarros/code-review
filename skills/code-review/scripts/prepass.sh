#!/usr/bin/env bash
# Deterministic, NON-MUTATING pre-pass for code-review. Run from the repository root.
#
#   prepass.sh <base> [--local] [--no-ignore]
#
# Changed files = git diff <base>...HEAD (+ uncommitted and untracked with --local), minus
# the noise filter (lockfiles, generated migration metadata, BUGPOOL_IGNORE_DIRS; see lib.sh).
# Runs lint check (no fixes) on changed files, project typecheck, and related unit tests.
# Test files that fail only on setup/hook timeouts are re-run once: `flaky` = passed on the
# retry, `inconclusive` = timed out again. Assertion failures are never retried (`fail`).
# Prints a markdown block for reviewers. Always exits 0; per-tool status is
# ok|flaky|inconclusive|fail|skipped.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$here/lib.sh"

base="${1:?base ref required}"
shift
local_mode=0
for arg in "$@"; do
  case "$arg" in
    --local) local_mode=1 ;;
    --no-ignore) export BUGPOOL_NO_IGNORE=1 ;;
  esac
done
max_lines="${BUGPOOL_PREPASS_MAX_LINES:-150}"

mapfile -t changed < <(changed_files "$base" "$local_mode")
mapfile -t files < <(code_files "${changed[@]}")

print_block() {
  echo '```'
  printf '%s\n' "$1" | tail -n "$max_lines"
  echo '```'
}

section() {
  local name="$1"
  shift
  local out status
  out="$("$@" 2>&1)"
  status=$?
  local label="ok"
  [[ $status -eq 127 ]] && label="skipped"
  [[ $status -ne 0 && $status -ne 127 ]] && label="fail"
  echo "### $name: $label"
  if [[ $label != "ok" || -n "${BUGPOOL_PREPASS_VERBOSE:-}" ]]; then
    print_block "$out"
  fi
  echo
}

tests_section() {
  local out status label summary
  out="$(run_related_tests "$@" 2>&1)"
  status=$?
  if [[ $status -eq 127 ]]; then
    echo "### related unit tests: skipped"
    echo
    return
  fi
  summary="$(printf '%s\n' "$out" | grep '^TESTS: ' | tail -1)"
  label="$(awk '{print $2}' <<<"$summary")"
  echo "### related unit tests: ${label:-fail}"
  echo
  [[ -n "$summary" ]] && echo "${summary#TESTS: }"
  case "$label" in
    flaky) echo "Not evidence of a regression: the retried files timed out in setup and passed on the retry." ;;
    inconclusive) echo "Not evidence either way: the retried files timed out in setup twice. Report them as not verified." ;;
  esac
  if [[ $label != "ok" || -n "${BUGPOOL_PREPASS_VERBOSE:-}" ]]; then
    print_block "$out"
  fi
  echo
}

echo "## Pre-pass ($base...HEAD$([[ $local_mode -eq 1 ]] && echo ' + working tree'))"
echo
echo "Changed files (${#changed[@]}): ${changed[*]:-none}"
echo "$(ignored_summary "$base" "$local_mode")"
echo
if [[ ${#files[@]} -eq 0 ]]; then
  echo "No lintable source files changed."
  exit 0
fi
section "lint check (changed files, no fixes)" run_lint_check "${files[@]}"
section "typecheck (project)" run_typecheck
tests_section "${files[@]}"
echo "Not run by the pre-pass: integration/e2e suites unrelated to the changed files by import, browser tests. Report them as not verified."
exit 0
