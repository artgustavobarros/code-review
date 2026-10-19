## Context

The benchmark of Bugpool against Matt Pocock's review on `book-manager` demonstrated that while Bugpool excels at zero false positives, factual reproduction, and stack reliability, it suffered from two key limitations:
1. It failed to identify unrequested functionality (`GET /api/public-shelf`) because its spec audit only verified forward coverage (did the PR deliver what the issue asked?) rather than reverse verification (does every new capability in the PR trace back to a requirement?).
2. It verified UI state statically (checking if "Ver estante completa" exists and triggers `clear()`) without simulating the state lifecycle after execution (the notice banner text was derived from initial server props, remaining stale on the screen after clearing filters).
3. The deduplication pipeline dropped LOW/NIT scope and smell findings below the radar.

## Goals / Non-Goals

**Goals:**
- Implement bi-directional spec auditing (Diff $\leftrightarrow$ Spec) in `reference/lenses/spec.md`.
- Ensure new endpoints, routes, or exports lacking an explicit requirement in the spec are classified as `spec/creep` with **MEDIUM** severity so they are not dropped in deduplication.
- Establish a concrete UI state lifecycle simulation checklist in `reference/lenses/correctness-stack.md` and `spec.md` for components that handle reset, clear, dismiss, or toggle interactions.
- Refine `reference/lenses/architecture.md` with concrete thresholds for *Divergent Change* and *Feature Envy*.
- Preserve `spec/divergence` and `spec/creep` findings in Step 5.3 of `SKILL.md` ahead of generic style comments.

**Non-Goals:**
- Weakening Bugpool's refute-first validation or allowing unverified hunches to fail a PR.
- Penalizing code smells with score deductions (smells remain advisory unless causing functional regressions).

## Decisions

### Decision 1: Reverse Spec Audit (Diff-Inversion Table)
- **Rationale**: A reviewer reading a PR must construct a quick inverted table of every new entry point added in the diff:
  `[Added Route/Export] -> [Corresponding Spec Requirement] -> [Status: MATCHED | CREEP]`.
- **Alternative considered**: Relying on general PM instructions to "look for scope creep". Rejected because LLMs focus on answering whether listed tasks were done and overlook unlisted additions.

### Decision 2: Severity of Unsolicited Network Endpoints
- **Rationale**: An unsolicited API route handler (`GET /api/...`) represents unexpected attack surface and unmaintained endpoints. It should be flagged as `spec/creep` at **MEDIUM** severity. This guarantees it surfaces in the report and validation queue instead of being dropped as an unvalidated LOW.
- **Alternative considered**: Keep as LOW. Rejected because the deduplication step limits unvalidated LOWs to 5 items and prioritizes `bug` over `creep`.

### Decision 3: Post-Action Interaction Simulation Checklist
- **Rationale**: When reviewing components with interaction handlers (`onClick`, `onClose`, `clear()`), the agent must trace state mutations:
  1. What state changes?
  2. What UI elements are derived from props vs internal state?
  3. Does any header, banner, or badge display stale information after the action?
- **Alternative considered**: Rely on e2e tests. In review environments, e2e tests are often skipped or inconclusive; static simulation in the correctness lens catches this instantly.

## Risks / Trade-offs

- **[Risk]** Over-flagging legitimate internal helper functions as scope creep.
  $\to$ **Mitigation**: Restrict reverse auditing strictly to public surface area: HTTP route handlers, server actions, CLI commands, and exported library APIs. Internal utilities do not trigger `spec/creep`.
- **[Risk]** Increased token consumption during the spec lens execution.
  $\to$ **Mitigation**: Diff inversion operates only on files containing exports and routes, keeping the prompt compact.
