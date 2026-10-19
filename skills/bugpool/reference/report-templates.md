# Report templates

## Score

`score = max(0, 100 − Σ deductions)` over **validated** findings only (`CONFIRMED` and `CONFIRMED (partly pre-existing)`; not `PRE-EXISTING`):
CRITICAL 30 · HIGH 15 · MEDIUM 5 · LOW 2 · NIT 0. Unvalidated LOW/NIT findings are listed but never deduct.
Grade: A ≥ 90 · B ≥ 80 · C ≥ 70 · D ≥ 60 · F < 60.
Verdict: any open CRITICAL/HIGH → REQUEST CHANGES; only MEDIUM or lower open → APPROVE WITH NITS; nothing open → APPROVE.
The verdict line always names every open validated MEDIUM+ finding (`file:line`), marked `reproduced` when the validator ran a repro, e.g. `APPROVE WITH NITS — open: MEDIUM lib/x.ts:40 (reproduced)`.

## Sticky PR summary (PR mode, not dry-run)

Write to a temp file and post with `scripts/post.sh sticky <pr> <file>` (the script adds the marker and bot header).

```markdown
## 🎯 Bugpool Review Summary <sub>(@ <short_sha>, round <n>)</sub>

**Verdict:** <APPROVE | APPROVE WITH NITS | REQUEST CHANGES> · **Score:** <score>/100 (<grade>)

| Stage | Result |
| :--- | :--- |
| Pre-pass | lint <ok/fail/skipped> · typecheck <…> · tests <ok/flaky/inconclusive/fail/skipped> · <ignored: N (globs)> |
| Router (`haiku`) | danger <LEVEL> · extra lenses: <list or none> |
| Lenses (`sonnet`) | <lens: n findings, skipped: <files or none>; …> |
| Validation | <n> confirmed (<r> reproduced) · <n> rejected · <n> pre-existing · <n> LOW dropped |
| Not verified | <suites the pre-pass did not run or found inconclusive, e.g. e2e> |

> [!WARNING]
> **Scope drift:** <only if detected — files and why>

### Open findings
| Severity | Location | Issue |
| :--- | :--- | :--- |
| <SEV> | `<file>:<line>` | <one line> |

### Actions
- Auto-fixed: <n> (commit `<sha>` on `<branch>`, pushed: <yes/no>)
- Bot nits resolved: <n> · Human threads untouched: <n> · Ambiguous for author: <n>

<details><summary>History</summary>

- round <n> @ <sha> — <verdict>, <score>
</details>
```

## Terminal report (always)

```markdown
### 🦹 Bugpool — <PR #n | local> <(dry-run)>

**Verdict:** <…> — open: <SEV file:line (reproduced)>, … · **Score:** <score>/100 (<grade>) · **Danger:** <LEVEL>
Pre-pass: lint <…> · typecheck <…> · tests <…> · <ignored: N> · Lenses: <list> · Validation: <c> confirmed (<r> reproduced) / <r> rejected
Coverage: <lens: skipped files, only for lenses that skipped changed code> · Not verified: <…>

#### Findings (validated, most severe first)
1. **<SEV>** `<file>:<line>` — <issue> → <fix>   <[reproduced: <path>] | [fixed in <sha>] | [ambiguous] | [partly pre-existing] | [pre-existing]>

#### Not validated (LOW/NIT, max 5; <n> dropped)
- `<file>:<line>` — <issue>

#### Needs your decision
1. **[Human thread]** `<file>:<line>` — @<author>: "<excerpt>"
2. **[Ambiguous]** `<file>:<line>` — <why it needs a decision>

<Scope drift line, if any>
<Auto-fix line: done / skipped (reason: dry-run | dirty tree | none actionable)>
```

## Quick mode report (`--quick`)

```markdown
### ⚡ Bugpool Quick Review — <PR #n | local>

#### 🛡️ Correctness & Security
- **Findings:** <count> | **Worst:** <none or SEV file:line — description>
<list of findings, or "No critical issues spotted.">

#### 📐 Standards & Spec
- **Findings:** <count> | **Worst:** <none or SEV file:line — description>
<list of findings, or "Conforms to repo standards and spec.">

---
**Summary:** Correctness: <n> · Standards/Spec: <n> · Mode: quick
```
