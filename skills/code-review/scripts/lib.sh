#!/usr/bin/env bash
# Shared helpers for code-review scripts. Source, don't execute.
# All checks are NON-MUTATING: never pass --fix / --write / --apply to any tool.

# has_dep <name>: true if package.json lists <name> in any dependency field.
has_dep() {
  python3 - "$1" <<'PY' 2>/dev/null
import json, sys
p = json.load(open("package.json"))
deps = {**p.get("dependencies", {}), **p.get("devDependencies", {})}
sys.exit(0 if sys.argv[1] in deps else 1)
PY
}

# has_script <name>: true if package.json defines scripts.<name>.
has_script() {
  python3 - "$1" <<'PY' 2>/dev/null
import json, sys
sys.exit(0 if sys.argv[1] in json.load(open("package.json")).get("scripts", {}) else 1)
PY
}

# code_files <files...>: keep existing source files a linter/test runner can take.
code_files() {
  local f
  for f in "$@"; do
    [[ -f "$f" ]] || continue
    case "$f" in
      *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.css) echo "$f" ;;
    esac
  done
}

# run_typecheck: project typecheck via npm (works with symlinked node_modules).
run_typecheck() {
  if has_script typecheck; then
    npm run -s typecheck
  elif [[ -f tsconfig.json ]]; then
    npx --no-install tsc --noEmit
  else
    return 127
  fi
}

# run_lint_check <files...>: lint/format check on the given files, no fixes.
run_lint_check() {
  [[ $# -gt 0 ]] || return 127
  if has_dep ultracite; then
    npx --no-install ultracite check "$@"
  elif has_dep @biomejs/biome; then
    npx --no-install biome check "$@"
  elif has_dep eslint; then
    npx --no-install eslint "$@"
  elif has_script lint; then
    npm run -s lint
  else
    return 127
  fi
}

# vitest_failures <report.json>: classify a vitest JSON report. Prints
# "<passed> <failed> <skipped> <kind> [timed-out test files...]" where kind is
# none | hook-timeout (every failure is a setup/hook timeout) | assertion.
vitest_failures() {
  python3 - "$1" <<'PY'
import json, os, sys
try:
    d = json.load(open(sys.argv[1]))
except (OSError, ValueError):
    print("0 0 0 assertion")  # no report: treat as a real failure
    sys.exit()
timeout = "Hook timed out"
files, other = [], False
for t in d.get("testResults", []):
    failed = [a for a in t.get("assertionResults", []) if a.get("status") == "failed"]
    if t.get("status") != "failed" and not failed:
        continue
    msgs = [t.get("message") or ""] + [m for a in failed for m in a.get("failureMessages", [])]
    msgs = [m for m in msgs if m]
    if msgs and all(timeout in m for m in msgs):
        files.append(os.path.relpath(t["name"]))
    else:
        other = True
skipped = d.get("numPendingTests", 0) + d.get("numTodoTests", 0)
kind = "assertion" if other else ("hook-timeout" if files else "none")
print(d.get("numPassedTests", 0), d.get("numFailedTests", 0), skipped, kind, *files)
PY
}

# run_related_tests <files...>: unit tests related to the given files. Test files that
# failed ONLY on setup/hook timeouts are re-run once; assertion failures never are.
# Last line: "TESTS: <ok|flaky|inconclusive|fail> passed=… failed=… skipped=… [retried=…]".
# Exit: 0 ok/flaky · 3 inconclusive · 1 fail · 127 unavailable.
run_related_tests() {
  [[ $# -gt 0 ]] || return 127
  has_dep vitest || return 127
  local report status rest p f s kind
  local -a retry
  report="$(mktemp)"
  npx --no-install vitest related --run --passWithNoTests \
    --reporter=default --reporter=json --outputFile.json="$report" "$@"
  status=$?
  read -r p f s kind rest <<<"$(vitest_failures "$report")"
  if [[ $status -eq 0 ]]; then
    echo "TESTS: ok passed=$p failed=$f skipped=$s"
    rm -f "$report"
    return 0
  fi
  if [[ $kind != "hook-timeout" ]]; then
    echo "TESTS: fail passed=$p failed=$f skipped=$s"
    rm -f "$report"
    return 1
  fi
  read -ra retry <<<"$rest"
  echo
  echo "Retrying once (setup/hook timeouts only): ${retry[*]}"
  npx --no-install vitest run --passWithNoTests \
    --reporter=default --reporter=json --outputFile.json="$report" "${retry[@]}"
  status=$?
  local first="first run: passed=$p failed=$f skipped=$s"
  read -r p f s kind rest <<<"$(vitest_failures "$report")"
  rm -f "$report"
  if [[ $status -eq 0 ]]; then
    echo "TESTS: flaky $first · retry: passed=$p failed=$f skipped=$s retried=${retry[*]}"
    return 0
  fi
  if [[ $kind == "hook-timeout" ]]; then
    echo "TESTS: inconclusive $first · retry: passed=$p failed=$f skipped=$s retried=${retry[*]}"
    return 3
  fi
  echo "TESTS: fail $first · retry: passed=$p failed=$f skipped=$s retried=${retry[*]}"
  return 1
}

# Default diff noise filter: lockfiles and generated migration metadata. BUGPOOL_IGNORE
# (space-separated globs) replaces it; BUGPOOL_IGNORE_DIRS (default "openspec/ docs/")
# adds whole directories; BUGPOOL_NO_IGNORE=1 turns the filter off.
BUGPOOL_DEFAULT_IGNORE="*.lock pnpm-lock.yaml package-lock.json yarn.lock bun.lockb skills-lock.json **/meta/*_snapshot.json **/meta/_journal.json"

# ignore_globs: the active ignore globs, one per line (read -a: no shell globbing).
ignore_globs() {
  [[ "${BUGPOOL_NO_IGNORE:-0}" == 1 ]] && return 0
  local -a globs dirs
  local d
  read -ra globs <<<"${BUGPOOL_IGNORE-$BUGPOOL_DEFAULT_IGNORE}"
  read -ra dirs <<<"${BUGPOOL_IGNORE_DIRS-openspec/ docs/}"
  for d in "${dirs[@]}"; do globs+=("${d%/}/**"); done
  [[ ${#globs[@]} -gt 0 ]] && printf '%s\n' "${globs[@]}"
  return 0
}

# ignore_pathspecs: git pathspecs excluding the ignored files (a glob without "/"
# matches at any depth).
ignore_pathspecs() {
  local g
  while IFS= read -r g; do
    [[ "$g" == */* ]] || g="**/$g"
    printf ':(exclude,glob)%s\n' "$g"
  done < <(ignore_globs)
}

# changed_files <base> <local:0|1> [--all]: changed paths (filtered unless --all).
# Deleted files are left out; untracked ones count in local mode.
changed_files() {
  local base="$1" local_mode="$2"
  local -a ps=()
  [[ "${3:-}" == "--all" ]] || mapfile -t ps < <(ignore_pathspecs)
  {
    git diff --name-only --diff-filter=ACMR "$base...HEAD" -- . "${ps[@]}"
    if [[ $local_mode -eq 1 ]]; then
      git diff --name-only --diff-filter=ACMR HEAD -- . "${ps[@]}"
      git ls-files --others --exclude-standard -- . "${ps[@]}"
    fi
  } | sort -u
}

# review_diff <base> <local:0|1>: the filtered diff every reviewer reads.
review_diff() {
  local base="$1" local_mode="$2"
  local -a ps
  mapfile -t ps < <(ignore_pathspecs)
  git diff "$base...HEAD" -- . "${ps[@]}"
  [[ $local_mode -eq 1 ]] && git diff HEAD -- . "${ps[@]}"
  return 0
}

# ignored_summary <base> <local:0|1>: "ignored: N (<globs>)" for the report.
ignored_summary() {
  local all kept
  all="$(changed_files "$1" "$2" --all | grep -c .)"
  kept="$(changed_files "$1" "$2" | grep -c .)"
  echo "ignored: $((all - kept)) ($(ignore_globs | paste -sd ' ' -))"
}

# link_deps <src_repo> <dst_worktree>: symlink node_modules and .env* (not .env.example).
link_deps() {
  local src="$1" dst="$2" f
  [[ -e "$src/node_modules" && ! -e "$dst/node_modules" ]] && ln -s "$src/node_modules" "$dst/node_modules"
  for f in "$src"/.env*; do
    [[ -e "$f" ]] || continue
    [[ "$(basename "$f")" == ".env.example" ]] && continue
    [[ -e "$dst/$(basename "$f")" ]] || ln -s "$f" "$dst/$(basename "$f")"
  done
}
