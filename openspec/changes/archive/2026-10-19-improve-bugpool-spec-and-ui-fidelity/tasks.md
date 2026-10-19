## 1. Spec Fidelity & Diff Inversion

- [x] 1.1 Update `skills/bugpool/reference/lenses/spec.md` with the Diff-Inversion protocol: require constructing a reverse lookup table from new endpoints/routes to explicit spec requirements.
- [x] 1.2 Add rule to `skills/bugpool/reference/lenses/spec.md` classifying unrequested HTTP routes or public endpoints as `spec/creep` with MEDIUM severity.
- [x] 1.3 Add dynamic UI state lifecycle simulation checklist to `skills/bugpool/reference/lenses/spec.md` and `skills/bugpool/reference/lenses/correctness-stack.md` for reset, clear, and dismiss user interactions.

## 2. Architecture & Smells Metrics

- [x] 2.1 Update `skills/bugpool/reference/lenses/architecture.md` with explicit metric heuristic for Divergent Change (>300 LOC and $\ge 5$ distinct domain responsibilities).
- [x] 2.2 Update `skills/bugpool/reference/lenses/architecture.md` with presentation Feature Envy heuristic (filtering/query algorithms implemented inside JSX instead of pure domain helpers).

## 3. Deduplication & Triage Refinements

- [x] 3.1 Update `skills/bugpool/SKILL.md` step 5.3 drop priority to `bug > spec/divergence > spec/creep > architecture > consistency > missing-test > weak-assertion > other`.
- [x] 3.2 Update `skills/bugpool/reference/report-templates.md` to cleanly separate Runtime Reliability (scored) from Advisory Scope & Architecture notes.

## 4. Verification & Evals

- [x] 4.1 Re-run Bugpool evaluation scenario on `book-manager` changes to verify detection of `GET /api/public-shelf` as `spec/creep` and the stale banner text on "Ver estante completa".
- [x] 4.2 Verify zero false positive regression on existing benchmark suites in `skills/bugpool/evals/`.
