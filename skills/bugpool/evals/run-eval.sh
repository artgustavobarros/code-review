#!/usr/bin/env bash
# Run one bugpool evaluation scenario with a fresh headless Claude ("Claude B").
#
# Usage: run-eval.sh <scenario> [--baseline|--code-review] [--label <name>] [--keep]
#   <scenario>  a manifest name in manifests/ (dev, clean, heldout, range, composition, flaky)
#   --baseline     run one generic single-reviewer prompt instead of /bugpool
#   --code-review  run Claude Code's built-in /code-review (default level) instead of /bugpool.
#                  The bench changes are left staged on top of the review base, since
#                  /code-review reviews the current diff.
#   --label     suffix for the run file (default: skill version or "baseline")
#   --keep      keep the benchmark worktree after the run
#
# Env: BUGPOOL_EVAL_DIR (default $TMPDIR/bugpool-eval), BUGPOOL_EVAL_BUDGET (USD, default 3),
#      BUGPOOL_EVAL_MODEL (orchestrator model, default sonnet),
#      BUGPOOL_EVAL_SKILL (skill dir under test, default: this skill; e.g. a copy of the
#      previous version to record "before" numbers with the current manifests).
# Safety: runs inside a throwaway worktree outside the repo; push, commit, gh and Edit are
# disallowed. Write stays allowed because lenses write $RUN/lens-*.md (3.1.0+); the skill's
# own git-status check reports any write into the worktree. Nothing is posted to GitHub.
set -euo pipefail

scenario="${1:?scenario required: a manifest name in manifests/}"
shift
mode="skill"
label=""
keep=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --baseline) mode="baseline" ;;
    --code-review) mode="code-review" ;;
    --label) label="$2"; shift ;;
    --keep) keep=1 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="${BUGPOOL_EVAL_SKILL:-$(dirname "$here")}"
repo="$(git -C "$here" rev-parse --show-toplevel)"
manifest="$here/manifests/$scenario.json"
out_dir="${BUGPOOL_EVAL_DIR:-${TMPDIR:-/tmp}/bugpool-eval}"
budget="${BUGPOOL_EVAL_BUDGET:-3}"
model="${BUGPOOL_EVAL_MODEL:-sonnet}"
[[ -f "$manifest" ]] || { echo "no manifest: $manifest" >&2; exit 2; }
title="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["title"])' "$manifest")"
version="$(sed -n 's/^version: *"\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' "$skill_dir/SKILL.md" | head -1)"
if [[ -z "$label" ]]; then
  case "$mode" in
    baseline) label="baseline" ;;
    code-review) label="code-review" ;;
    *) label="v${version:-unknown}" ;;
  esac
fi

wt="$(cd "$repo" && python3 "$here/build-bench.py" "$manifest" "$out_dir" --skill "$skill_dir")"
# Review base from build-bench (differs from the manifest base when it has `setup`).
base="$(cat "$out_dir/$scenario.base")"
cleanup() { [[ $keep -eq 1 ]] || git -C "$repo" worktree remove --force "$wt" >/dev/null 2>&1 || true; }
trap cleanup EXIT

if [[ $mode == code-review ]]; then
  git -C "$wt" reset -q --soft "$base"
  prompt="/code-review"
elif [[ $mode == baseline ]]; then
  prompt="You are a senior code reviewer. Review the changes in \`git diff $base...HEAD\` (PR title: \"$title\") for real bugs: security, correctness, reliability, React/Next.js pitfalls, and files unrelated to the stated goal. Read surrounding code to verify each finding; report only findings you can defend with file:line evidence. Do not modify files. Output only a STRUCTURED_FINDINGS list: - file: <path> | line: <n> | severity: <CRITICAL|HIGH|MEDIUM|LOW|NIT> | category: <...> | body: <issue + fix + why>"
else
  prompt="/bugpool --local --base $base --dry-run"
fi

stamp="$(date +%Y%m%d-%H%M%S)"
run_file="$here/runs/$stamp-$scenario-$label.json"
mkdir -p "$here/runs"

start_s=$SECONDS
(
  cd "$wt"
  claude -p "$prompt" \
    --model "$model" \
    --output-format json \
    --max-budget-usd "$budget" \
    --permission-mode bypassPermissions \
    --disallowedTools "Bash(git push:*)" "Bash(git commit:*)" "Bash(git reset:*)" "Bash(git checkout:*)" "Bash(gh:*)" "Edit" "NotebookEdit"
) >"$run_file"
wall_s=$((SECONDS - start_s))

python3 - "$run_file" "$wall_s" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(f"run file: {sys.argv[1]}")
d['wall_s'] = int(sys.argv[2])
json.dump(d, open(sys.argv[1], 'w'), ensure_ascii=False)
print(f"cost_usd={d.get('total_cost_usd')} wall_s={d['wall_s']} turns={d.get('num_turns')} error={d.get('is_error')}")
PY
python3 "$here/score.py" "$manifest" "$run_file" || true
