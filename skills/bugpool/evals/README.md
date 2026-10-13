# Bugpool evaluation harness

Measures the skill the way a user runs it: a fresh headless Claude Code session invokes
`/bugpool --local --base <base> --dry-run` inside a throwaway git worktree with seeded bugs,
and reports cost and wall time (subagents included). Nothing is pushed, committed or posted.

## Files

- `build-bench.py <manifest> <out_dir> [--skill <dir>]` — creates a detached worktree outside the
  repo at the manifest head, applies each seed (exact find/replace, must match once), commits
  locally, symlinks `node_modules`, `.env*` and the skill under test, writes `<scenario>.diff` and
  `<scenario>.base` (the ref to review against). `setup` edits are committed on `base` and the
  linear `base..head` commits are cherry-picked over them, so the setup stays out of the diff.
- `run-eval.sh <scenario> [--baseline] [--label <name>] [--keep]` — builds the bench and runs
  `claude -p` (orchestrator `sonnet`, budget cap `BUGPOOL_EVAL_BUDGET`, default $3) with
  `git push/commit/reset/checkout`, `gh`, `Edit` and `Write` disallowed. `--baseline` runs one
  generic single-reviewer prompt instead; `--code-review` runs Claude Code's built-in `/code-review`
  (default level) with the scenario changes staged on the review base, the reference bugpool has to
  beat. Output JSON goes to `runs/` (git-ignored).
  Any manifest name works as `<scenario>`.
- `score.py <manifest> <run.json>` — scoring aid run after each eval: lists the expected items
  (non-support seeds + `known_defects`) with a "file mentioned" hint and, for `setup` scenarios,
  whether the report says `flaky`. Final scoring stays manual.
- `manifests/` — one JSON per scenario (create your own; see below).

Each run spends real usage on your account. Keep `runs/` and manifests out of public repos when
they contain code from private projects.

## Manifest format

```json
{
  "scenario": "dev",
  "description": "feature PR with seeded bugs",
  "base": "<base sha>",
  "head": "<head sha>",
  "title": "<PR title used as review context>",
  "seeds": [
    {
      "id": "S1",
      "file": "path/to/file.ts",
      "class": "security/IDOR",
      "severity": "CRITICAL",
      "defect": "one-line description used when scoring",
      "find": "exact original text (must occur exactly once)",
      "replace": "buggy replacement"
    }
  ]
}
```

Optional fields:

- `"support": true` on a seed: an edit that is not a bug to catch (e.g. removing the unit test
  that would catch another seed). Not counted in recall.
- `"setup": [...]`: edits with the seed shape that must stay out of the reviewed diff (e.g. a
  test harness that times out on the first run). Requires a linear `base..head` range.
- `"known_defects": [{ "id", "file", "also": [...], "class", "severity", "defect" }]`: ground truth
  for an unmodified real range (no seeds). Use such scenarios for development only.

Recommended set: a **dev** scenario to iterate on, a **held-out** scenario in a different domain
run only for final acceptance, and a **clean** scenario (no seeds) to count false positives.
Since 3.1.0 also: a **range** scenario (a real multi-commit range with `known_defects`, for
large-diff recall), a **composition** scenario (bugs that only show with two operations in
sequence, with the covering tests removed as `support` seeds) and a **flaky** scenario (a
`setup` that times out once; the pre-pass must say `flaky` and no finding may cite it).
Never put seed-specific hints in the skill text.

## Scoring

A seed counts as caught when a reported finding names its file and describes its defect.
A false positive (clean scenario) is a finding that manual verification shows to be wrong;
real pre-existing defects are not false positives. Keep a scorecard with recall, FPs, severity
calibration (caught items more than one severity level from the expected one), cost and wall
time per run. Do not use validator downgrades as a calibration metric: downgrading is the
validator's job.

## Reference results (3.1.0 vs Claude Code `/code-review`, private Next.js + Drizzle repo, 2026-10-13)

| Scenario | `/code-review` (default level) | bugpool 3.1.0 |
| :--- | :--- | :--- |
| dev (5 seeds) | 3/5 · $0.10 · 23 s | 5/5 · $1.17 · 141 s |
| held-out (5 seeds) | 5/5 · $0.15 · 36 s | 5/5 · $1.33 · 159 s |
| range (3 real defects, ~2.9k filtered diff lines) | 1/3 · $0.20 · 48 s | 2/3 · $1.45 · 431 s |
| composition (2 seeds) | 2/2 · $0.11 · 26 s | 1/2 · $0.75 · 90 s |
| clean (FPs) | 2 · $0.09 · 27 s | 0 · $0.85 · 109 s |

Bugpool finds more (13/15 vs 11/15) with fewer false positives, at ~8.5x the cost and ~6x the time.
Costs are the API-equivalent `total_cost_usd` the CLI reports (on a subscription they count against
usage limits instead). Single runs each; LLM reviews are stochastic, so repeat borderline results.
