## Why

A comparative benchmark against Matt Pocock's two-axis review on the `book-manager` repository (`feat/public-shelf-sharing`) demonstrated Bugpool's superior rigor in avoiding false alarms (refuting concurrency races, false SSRF, auth bypass, and pre-existing code) and validating runtime defects with reproduction scripts. However, it also exposed two critical blind spots in Bugpool:
1. **Unsolicited scope (Scope Creep) was missed**: Bugpool's spec lens operates in a forward-only direction (Spec $\to$ Diff), verifying if asked requirements were built, but failing to audit newly introduced exports and routes backwards (Diff $\to$ Spec). Consequently, an unsolicited `GET /api/public-shelf` endpoint was overlooked.
2. **Dynamic UI state lifecycle bugs were missed**: Static spec auditing confirmed that the "Ver estante completa" clear button was implemented and called `clear()`, but failed to simulate the dynamic UI lifecycle after interaction—missing that the notice banner stayed visible with stale filter text because its label was bound to static initial props.

To ensure Bugpool matches architectural and PM-level review depth while retaining its engineering and verification rigor, we need diff-inversion auditing, dynamic UI state simulation, and deduplication preservation for spec findings.

## What Changes

- **Diff-Inversion Spec Audit**: Update `reference/lenses/spec.md` to require reverse auditing: every new API route handler, server action, CLI command, and major exported entity in the diff must be matched against an explicit spec requirement. Unmatched endpoints/capabilities are flagged as `spec/creep` with **MEDIUM** severity.
- **Dynamic UI State Lifecycle Simulation**: In both `reference/lenses/correctness-stack.md` and `reference/lenses/spec.md`, introduce a mandatory post-interaction state check for interactive components (modals, filter bars, banners, pagination): simulate state after user triggers "Clear", "Reset", "Close", or "Toggle" to ensure banners and derivative labels do not retain stale state.
- **Deduplication Priority Adjustment**: In `SKILL.md` step 5.3, update the drop hierarchy to preserve spec findings: `bug > spec/divergence > spec/creep > architecture > consistency > missing-test > weak-assertion > other`.
- **Fowler Smells Structural Thresholds**: Update `reference/lenses/architecture.md` with explicit detection heuristics for *Divergent Change* (single files > 300 LOC accumulating $\ge 5$ distinct domain responsibilities) and *Feature Envy* (presentation components running query/normalization algorithms that belong in pure domain modules).

## Capabilities

### New Capabilities
<!-- No new standalone capabilities required; existing review capabilities are expanded -->

### Modified Capabilities
- `spec-fidelity-lens`: Adds reverse diff-to-spec auditing for new routes/exports (flagging unmatched additions as `spec/creep` MEDIUM) and mandatory post-interaction UI state lifecycle simulation.
- `fowler-smell-catalog`: Adds explicit threshold metrics for Divergent Change and presentation-layer Feature Envy.

## Impact

- `skills/bugpool/SKILL.md`: Update step 5.3 deduplication priority order.
- `skills/bugpool/reference/lenses/spec.md`: Add Diff-Inversion section and reverse verification table.
- `skills/bugpool/reference/lenses/correctness-stack.md`: Add UI state lifecycle interaction checklist.
- `skills/bugpool/reference/lenses/architecture.md`: Add Divergent Change file-size/domain-responsibility heuristic and Feature Envy domain-in-JSX check.
