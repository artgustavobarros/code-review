## ADDED Requirements

### Requirement: Framework Runtime Invariants Check
The review system SHALL audit code against common runtime traps and conventions specific to the active framework stack.

#### Scenario: Next.js App Router client navigation guard check
- **WHEN** client-side code uses `window.beforeunload` to guard unsaved form or editor state
- **THEN** the reviewer SHALL flag that Next.js client-side App Router navigation (`<Link>`, `useRouter`) bypasses browser `beforeunload` events, creating unsaved draft loss risks

#### Scenario: Client component route segment export check
- **WHEN** a file declared with `'use client'` contains server-only route segment exports (such as `export const dynamic` or `revalidate`)
- **THEN** the reviewer SHALL flag the dead configuration and convention violation

### Requirement: In-Flight and Concurrent State Simulation
The review system SHALL simulate asynchronous hook and mutation states while requests are pending (`isLoading: true`, `isPending: true`) or submitted repeatedly.

#### Scenario: Form submission during unresolved hook loading state
- **WHEN** a submission or state transition accesses query data before checking loading state
- **THEN** the reviewer SHALL verify whether unresolved falsy/undefined states cause silent data drops, race conditions, or unhandled exceptions
