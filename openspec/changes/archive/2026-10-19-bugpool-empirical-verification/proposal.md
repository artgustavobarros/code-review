# Proposal: Bugpool 3.4.0 — Empirical Verification & Framework Invariants

## Why

Code review agents that rely solely on passive text scanning suffer from two critical failure modes:
1. **Theoretical blindness**: They miss subtle runtime execution blockers (such as dynamic validator regexes failing on cold-start bracket placeholders, or plan quotas deadlocking on retries) because they don't simulate real-world execution.
2. **False alarms and lack of empirical rigor**: Without an active refutation protocol that verifies historical intent (`git log`) and executes reproducible proofs-of-concept (PoCs), agents produce false positives on intentional architecture decisions (e.g. flagging deliberate transactional rollbacks as bugs).

Bugpool 3.4.0 establishes an active **Empirical Verification Protocol** and introduces a **Framework Invariants & In-Flight State Lens**, ensuring reviewers don't merely read code, but actively test, verify, and validate software functionality in practice.

## What Changes

- **Empirical Refutation & PoC Execution Requirement**: For every finding rated HIGH or CRITICAL, the review agent MUST construct a reproduction script or execute concrete simulation calls (in `scratch/repro/` or via local API/CLI) proving the failure before reporting it.
- **Historical Intent Audit (`git log`)**: Before classifying any unusual code pattern as a defect, the refuter must audit git history (`git log -S` / `git log -L`) or ticket references to verify if the behavior was an intentional fix or design decision, eliminating false alarms.
- **Framework Invariants Lens**: Codify explicit invariant checks for modern frameworks (e.g. Next.js App Router soft navigation bypassing `window.beforeunload`, route segment exports inside `'use client'`, server component waterfalls).
- **In-Flight & Race State Simulation**: Expand the UI Lifecycle Simulation beyond cold-start (`[]`) to include pending and concurrent hook states (`isLoading: true`, rapid double-submits, network drop during multi-entity batch mutations).
- **Branch & Template Matrix Parity**: Require auditing alternative user selections (e.g. alternative templates or layouts) to guarantee they maintain entity and navigation parity with the primary default flow.

## Capabilities

### New Capabilities
- `empirical-verification-protocol`: Mandates hands-on execution proofs (PoCs), active simulation of user flows against live endpoints/scripts when available, and historical intent audits (`git log`) before accepting high-severity defects.
- `framework-invariants-lens`: Audits framework-specific runtime traps (Next.js App Router client routing vs beforeunload, client/server boundaries) and in-flight/race conditions.
- `branch-parity-lens`: Audits alternative paths, templates, and options to prevent asymmetric entity provisionings.

### Modified Capabilities
<!-- None: existing specs remain intact -->

## Impact

- Modifies `skills/bugpool/SKILL.md` (and installed agent skill copies).
- Increases triage Signal-to-Noise Ratio (SNR) by eliminating false positives through mandatory historical audits.
- Deepens bug discovery across framework-specific edge cases and multi-entity workflows.
