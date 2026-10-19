---
name: bugpool
description: >
  Multi-lens PR review and triage. Runs a deterministic pre-pass (lint check, typecheck,
  related tests), always-on correctness and security lenses plus router-selected extras,
  framework invariants check, empirical hands-on verification (mandatory PoC for HIGH/CRITICAL),
  historical intent audit (git log), refute-first validation, and human-safe triage.
  Supports PR mode, --local (no PR needed) and --dry-run.
version: "3.4.0"
argument-hint: "[pr-number|pr-url] [--local] [--base <ref>] [--dry-run] [--push] [--no-ignore] [--quick] [--spec <ref>]"
---

# Bugpool

`<skill>` below means this skill's base directory. Lens prompts live in `<skill>/reference/lenses/`, report formats in `<skill>/reference/report-templates.md`, helpers in `<skill>/scripts/`.

## Invocation

```
/bugpool [<pr number|url>] [--local] [--base <ref>] [--dry-run] [--push] [--no-ignore] [--quick] [--spec <ref>]
```

| Flag | Effect |
| :--- | :--- |
| *(none)* | PR mode on the current branch's PR |
| `--local` | Review `<base>...HEAD` plus uncommitted/untracked changes. No GitHub calls. `--base` defaults to `origin/main` (or `main`) |
| `--dry-run` | Review and report only. **No GitHub writes, no commits, no pushes, no file edits.** |
| `--push` | Allow pushing the auto-fix commit to the PR branch. Without it, fixes stay on a local branch |
| `--no-ignore` | Review every changed file. By default lockfiles, generated migration metadata (`**/meta/*_snapshot.json`, `_journal.json`) and `BUGPOOL_IGNORE_DIRS` (default `openspec/ docs/`) are left out; `BUGPOOL_IGNORE` replaces the default globs |
| `--quick` | Fast 2-axis review (Correctness & Security vs Standards & Spec) in < 30s. Skips heavy worktree, repros, and auto-fix |
| `--spec <ref>` | Explicit specification source (file path, URL, or text) to audit against |

## Hard rules

- Never run `git checkout -- …`, `git reset --hard`, `git stash`, `git clean`, or any lint/format command with `--fix`/`--write` in the user's working tree.
- Never auto-fix, reply to, or resolve a thread with any human comment (`scripts/threads.sh` marks it `"human": true`).
- Every posted comment goes through `scripts/post.sh` (adds the bot header, sends the body from a file).
- Report MEDIUM+ findings and LOW findings of category `bug` only after validation, always with `file:line` evidence; other LOW/NIT go under "Not validated".
- Reviewers and validators never write to the repository. Validators may write throwaway reproductions under `$RUN/repro/` only.
- For every finding rated HIGH or CRITICAL of category `bug`, the validator MUST construct an empirical reproduction proof under `$RUN/repro/` (or verified payload/command), and audit historical commit intent (`git log`) before confirming. Unproven hypotheses must be demoted or rejected.

## Quick Mode (`--quick`)

When `--quick` is passed, bypass the heavyweight multi-stage pipeline, worktree isolation, throwaway repros, and auto-fix. Execute this fast 2-axis review directly:

1. **Context & Diff**: Run Step 1 (Context & Spec discovery) to set the review root and write `$RUN/diff` and `$RUN/spec.txt` (if available).
2. **Light Pre-pass**: Run lint check and typecheck on changed files via `bash <skill>/scripts/prepass.sh <base> [--local] [--no-ignore] > $RUN/prepass.md`.
3. **Two Parallel Axes** (`sonnet`, in one message):
   - **Axis 1 (Correctness & Security)**: Read diff, prepass, and hunt for runtime defects, race conditions, auth/data leaks, and unhandled errors using `<skill>/reference/lenses/correctness-stack.md` and `<skill>/reference/lenses/security.md`. Under 300 words.
   - **Axis 2 (Standards & Spec)**: Read diff, repo standards, Fowler smells baseline (`<skill>/reference/lenses/architecture.md`), and spec (`$RUN/spec.txt` if available). Audit repo conventions, baseline smells, missing requirements, or spec divergence. Under 300 words.
4. **Report**: Print the Quick Mode template from `<skill>/reference/report-templates.md` showing both axes and the worst issue found in each. No GitHub writes, no worktrees, no commits. Stop here.

## Standard Workflow

Copy this checklist and tick it as you go:

```
- [ ] 1. Context
- [ ] 2. Pre-pass
- [ ] 3. Router
- [ ] 4. Lenses
- [ ] 5. Dedupe + validation
- [ ] 6. Triage (PR mode)
- [ ] 7. Auto-fix (not dry-run)
- [ ] 8. Report
```

### 1. Context

- **PR mode**: `gh pr view <pr> --json number,title,body,state,baseRefName,headRefName,headRefOid`. If MERGED/CLOSED and not `--dry-run`, stop. `git fetch origin <baseRefName> <headRefName>`; base = `origin/<baseRefName>`. If `git rev-parse HEAD` ≠ `headRefOid`, run `<skill>/scripts/fix-worktree.sh create <headRefOid>` and use that path as the review root for every later step.
- **Local mode**: review root = repo root, base = `--base` value; title/body = branch name + `git log --format=%s <base>..HEAD`. More than one commit in `<base>..HEAD` → **multi-commit range** (tell the Router; the title/body is only a commit log).
- Create a fresh run directory: `RUN=$(mktemp -d "${TMPDIR:-/tmp}/bugpool-$(git rev-parse --short HEAD)-XXXX")`. Never reuse an earlier run's directory or its files (stale `lens-*.md` would be read as this run's output). Write the filtered diff once: `bash <skill>/scripts/diff.sh <base> [--local] [--no-ignore] > $RUN/diff`. Note changed line count.
- **Spec discovery**:
  1. If `--spec <arg>` was passed: write it (or its content if a file path) to `$RUN/spec.txt`.
  2. If PR mode: inspect PR body and any referenced issues (`#123`, `Closes #45`) via `gh issue view <id> --json title,body`; write to `$RUN/spec.txt`.
  3. If local mode without `--spec`: check `specs/`, `openspec/`, `docs/specs/` or `.scratch/` matching the branch name or feature; if found, write to `$RUN/spec.txt`.
  4. If found, mark spec as available for Router and Lenses; otherwise mark `Spec: none`.
- Snapshot `git status --porcelain > $RUN/status.before` (used after validation).

### 2. Pre-pass

From the review root: `bash <skill>/scripts/prepass.sh <base> [--local] [--no-ignore] > $RUN/prepass.md`. Read it. Tests labelled `fail` and lint diagnostics on changed lines are leads for the lenses, not automatic findings. `flaky` (setup/hook timeout that passed on the script's single retry) and `inconclusive` (timed out twice) are not evidence of a regression; never re-run tests yourself to second-guess the label. Keep the `ignored: N` line and the "not verified" layers for the report.

### 3. Router (`haiku`)

Spawn one Agent (`model: haiku`) with: "Read `<skill>/reference/lenses/router.md` and follow it. Repo: <review root>. Base: <base>. Diff: <diff path>. Pre-pass: <prepass path>. Title/body: …. Spec: <spec path or none>. Multi-commit local range: <yes|no>". Keep its SCOPE_DRIFT, DANGER and EXTRA_LENSES. If the reply is not exactly the documented format (extra notes, missing DANGER, unknown lens), re-ask once with the format quoted; then use what parses and say so in the report.

### 4. Lenses (`sonnet`, in parallel)

In **one message**, spawn an Agent (`model: sonnet`) per lens: always `correctness-stack` and `security`, plus each lens in EXTRA_LENSES. Prompt: "Read `<skill>/reference/lenses/<lens>.md` and follow it exactly. Repo: … Base: … Diff: … Pre-pass: … Title/body: … Spec: <spec path or none> … Scope: … Output file: `$RUN/lens-<lens>.md`". Lenses are never skipped: not because another lens found a CRITICAL issue, and not because the diff is small. Never review the diff yourself in place of the lens agents; a small diff just makes them fast.

Each lens writes `STRUCTURED_FINDINGS` and `COVERAGE` to its output file and replies with the path and count; read the files, not the replies. If a lens lists changed code files under `skipped`, you may re-dispatch that lens **once**, scoped to those files, writing `$RUN/lens-<lens>-2.md`.

### 5. Dedupe + validation

1. Parse all `STRUCTURED_FINDINGS` and `COVERAGE` blocks from the lens files. Merge findings with the same file, line within ±3, and the same defect; keep the highest severity, prefer category `bug`, and list contributing lenses. Give each an id (F1, F2, …).
2. To validate: every MEDIUM+ finding and every LOW finding of category `bug`.
3. Other LOW/NIT: keep at most 5, not validated, chosen in this order: `bug` > `spec/divergence` > `spec/creep` > `architecture` > consistency > missing-test > weak-assertion > other (then higher severity first). Count the rest as dropped.
4. In **one message**, spawn validators reading `<skill>/reference/lenses/validator.md`, passing `$RUN` and the Router's DANGER:
   - each `security` finding rated CRITICAL/HIGH → its own Agent with `model: opus`;
   - all other findings to validate → batches of up to 8 per Agent with `model: sonnet`.
5. Drop REJECTED. Mark PRE-EXISTING (reported, excluded from score); `CONFIRMED (partly pre-existing)` scores like CONFIRMED. Use validated severities and keep each repro path.
6. Compare `git status --porcelain` with `$RUN/status.before`. Any difference means a reviewer or validator wrote to the repository: report it as a skill error at the top of the report and do not touch the files.

### 6. Triage (PR mode only)

1. `<skill>/scripts/threads.sh list <pr>`; count `human: true` threads as untouched and list them for the author.
2. Bot threads: NIT/obsolete → (not dry-run) reply with a one-line technical reason via `scripts/post.sh reply`, then `scripts/threads.sh resolve <thread_id>`. Concrete fixable issue → add to the fix queue. Product/architecture choice → AMBIGUOUS.
3. Validated findings: ACTIONABLE when severity ≥ MEDIUM, the fix is local (≤ 2 files) and unambiguous; otherwise AMBIGUOUS.

### 7. Auto-fix (skip in `--dry-run`; skip in local mode unless the user asked for fixes)

1. In the user's checkout: `<skill>/scripts/fix-worktree.sh check-clean`. Dirty → skip auto-fix and say so.
2. Reuse the review worktree, or `<skill>/scripts/fix-worktree.sh create HEAD`.
3. Spawn one Agent (`model: sonnet`) with `<skill>/reference/lenses/fixer.md`, the worktree path, and the ACTIONABLE list.
4. If anything is FIXED: `fix-worktree.sh commit <wt> "fix(review): bugpool round <n>"`. With `--push`: `fix-worktree.sh push <wt> <headRefName>`, then reply on fixed bot threads with the SHA and resolve them. NOT_FIXED → AMBIGUOUS with the gate error.
5. **Bounded loop**: re-run the `correctness-stack` lens on `git diff <old head>..<fix sha>` and validate. Repeat at most 2 extra rounds; stop as soon as a round adds no new validated MEDIUM+ finding.
6. `fix-worktree.sh remove <wt>` unless the user wants to inspect it (the branch is kept).

### 8. Report

Score and templates: `<skill>/reference/report-templates.md`. Unvalidated LOW/NIT never deduct. The verdict line names every open validated MEDIUM+ finding and marks reproduced ones. Include per-lens coverage gaps, `ignored: N`, the LOW dropped count and what was not verified (pre-pass `inconclusive`, suites it does not run such as e2e).
- PR mode, not dry-run: write the summary to a temp file, `<skill>/scripts/post.sh sticky <pr> <file>` (updates the existing summary in place).
- Always print the terminal report. End with `Agents: <n> · Rounds: <n>`.

## Evaluation

Benchmarks, seeded-bug manifests and the scorecard live in `<skill>/evals/` (`run-eval.sh <scenario> [--baseline]`; scenarios dev, clean, heldout, range, composition, flaky). Run them after changing this skill; do not tune the skill to specific seeds or known defects.

## Credits

Builds on [qa-swarm](https://github.com/pauldambra/dotfiles/tree/main/ai/skills/qa-swarm) and [review-triage](https://github.com/pauldambra/dotfiles/tree/main/ai/skills/review-triage) by Paul D'Ambra (router + lenses, structured findings, sticky summary, human immunity) and on the review methodology of [yooh-digital/ai-workflow](https://github.com/yooh-digital/ai-workflow) (two-pass review, constructive friction, scope drift, SIZE rubric).
