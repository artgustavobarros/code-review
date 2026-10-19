## ADDED Requirements

### Requirement: Mandatory Reproducible PoC for High-Severity Findings
The review system SHALL require an executable proof-of-concept (PoC) script, reproduction command, or verified live simulation before accepting any defect rated HIGH or CRITICAL.

#### Scenario: High-severity finding requires empirical verification
- **WHEN** a reviewer identifies a candidate defect with severity HIGH or CRITICAL
- **THEN** the reviewer MUST generate an empirical proof (such as a reproduction script in `scratch/repro/`, concrete API call payload, or terminal simulation output) proving that the defect manifests under the stated preconditions

#### Scenario: Unverified hypothesis demotion
- **WHEN** a candidate defect cannot be empirically reproduced or proven through execution/payload simulation
- **THEN** the finding MUST be demoted to advisory status or rejected under the Refute-First protocol

### Requirement: Historical Intent Audit Before Defect Assertion
The reviewer SHALL audit git commit history (`git log -S` or `git log -L`) and project issue references for relevant code sections before asserting that an atypical pattern is a defect.

#### Scenario: Code pattern backed by intentional prior fix
- **WHEN** an atypical pattern in code is found to be introduced by an explicit prior bugfix or architecture decision
- **THEN** the reviewer MUST NOT report it as a defect, but instead treat it as an intentional requirement, noting the historical context if relevant

#### Scenario: Code pattern with no historical design justification
- **WHEN** an atypical pattern is investigated via git history and reveals no intentional bugfix or requirement justification, and causes negative behavior
- **THEN** the defect hypothesis proceeds to empirical verification
