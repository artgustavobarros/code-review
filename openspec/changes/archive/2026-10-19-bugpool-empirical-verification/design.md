# Technical Design: Bugpool 3.4.0 — Empirical Verification & Framework Invariants

## Context

The comparative benchmarks on both `book-manager` and `condius` revealed that while Bugpool 3.3.0 possesses high signal-to-noise ratio and strong execution-path tracing, pure LLM text-scanning review remains vulnerable to:
1. Passive theoretical assumptions rather than practical execution verification.
2. Accidental false alarms when atypical patterns are intentional decisions documented in prior issues/commits.
3. Blind spots around framework-specific client routing invariants (e.g. Next.js soft navigation) and in-flight hook loading states (`isLoading`).

Bugpool 3.4.0 addresses these by establishing a hands-on **Empirical Verification Protocol**, mandating historical context checks, and adding specific lenses for framework traps and branch parity.

## Goals / Non-Goals

**Goals:**
- Mandate reproducible PoC generation (scripts in `scratch/repro/`, CLI commands, or curl invocations) for HIGH/CRITICAL findings.
- Introduce mandatory historical intent audit (`git log -S` / `git log -L`) before reporting atypical code as a defect, preventing false alarms.
- Codify runtime checks for framework traps (Next.js App Router soft navigation vs `beforeunload`, route segment exports in client components, async query loading states).
- Codify branch parity verification across template/selection matrices.
- Keep the primary report output focused 100% on high-signal triage findings, with an optional Architectural Health appendix.

**Non-Goals:**
- Replacing automated unit test suites or linter CI steps (these remain in Bugpool's pre-pass).
- Emitting 30+ low-value style nitpicks that create review fatigue.

## Decisions

### 1. Mandatory PoC Artifacts for HIGH/CRITICAL Findings
- **Rationale**: If a reviewer cannot simulate or construct a payload proving how a defect triggers, the finding is unproven. Requiring a PoC forces the agent to trace real runtime execution.
- **Alternatives considered**: Relying solely on textual reasoning. Rejected because textual reasoning missed the legal bracket validation blocker in Matt's review and generated a false alarm on SMTP signup.

### 2. Historical Intent Check (`git log`) in Refutation
- **Rationale**: Many "unusual" lines of code exist precisely to fix an edge-case bug discovered in production. Checking `git log` before claiming a bug prevents embarrassing false positives.
- **Alternatives considered**: Only checking the PR diff. Rejected because the diff does not provide context for existing code modified or touched by the change.

### 3. Dedicated Framework Invariants Lens
- **Rationale**: Frameworks have subtle invariants that static typecheckers miss (e.g. `window.beforeunload` not intercepting Next.js client-side App Router links).
- **Alternatives considered**: Expecting general correctness lens to catch framework traps. Rejected because without explicit checklists, agents forget framework routing lifecycle mechanics.

## Risks / Trade-offs

- **[Risk] Slower review execution time due to PoC construction and git log checks** → Mitigation: Restrict mandatory PoC generation to candidate HIGH and CRITICAL findings only. Low and Nit items use standard refutation logic.
