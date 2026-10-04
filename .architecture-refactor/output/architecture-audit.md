# Architecture Audit

Analyzer version: `2.0.0`  
Scoring scope: `production`

> Static analysis is triage evidence, not permission to refactor. Low coverage means inspect the source; preserve behavior and choose the smallest coherent ownership/boundary change.

## Project summary

| Metric | Value |
|---|---:|
| Production Health | 99.5/100 |
| Coverage | 64.0% |
| Confidence | 49.9% |
| Max Refactor Pressure | 10.3/100 |
| Production files | 269 |
| Tests indexed | 105 |
| Tooling files indexed | 46 |
| Generated files indexed | 0 |
| Production LOC scored | 38207 |
| Logical subsystems | 2 |
| Production findings | 2 |
| Test findings | 3 |

## Subsystems by refactor pressure

| Subsystem | Pressure | Health | Coverage | Confidence | Files | LOC | Findings | Fan-in | Fan-out |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| PsychopatzCore | 10.3 | 99.5/100 | 64.0% | 49.9% | 268 | 38206 | 2 | 1 | 0 |
| (root) | 0.8 | 100.0/100 | 66.6% | 50.0% | 1 | 1 | 0 | 0 | 1 |

## Finding counts

| Scope | Rule | Severity | Count |
|---|---|---|---:|
| production | `HOT_PATH_EVENT_RISK` | LOW | 2 |
| test | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | 3 |

## Finding index

Query evidence with `architecture_audit finding <repo> <finding-id> --context 4` before changing code.

| ID | Rule | Severity | Confidence | Subsystem | Summary |
|---|---|---|---:|---|---|
| `ARC-43A17EA6D0` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | PsychopatzCore | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Voice/PsychopatzVoiceGateway.lua publishes events and contains a recurring hot-path signal. |
| `ARC-E37DE3497D` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | PsychopatzCore | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Bridge/PsychopatzBridge.lua publishes events and contains a recurring hot-path signal. |
| `ARC-3C61FE751F` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (95%) | PsychopatzCore | Repeated test setup appears across 24 tests (~372 repeated LOC). |
| `ARC-4BD2C13DA1` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | tools | Repeated test setup appears across 3 tests (~12 repeated LOC). |
| `ARC-98F4B175F0` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (95%) | tests | Repeated test setup appears across 37 tests (~528 repeated LOC). |

## Largest maintained modules

Generated artifacts and tooling are indexed but excluded from this table and production scoring.

| ID | File | Code LOC |
|---|---|---:|

## Largest functions

| ID | Function | File | Start | LOC |
|---|---|---|---:|---:|

## Recommended workflow

1. Select a high-pressure subsystem with adequate coverage.
2. Inspect grouped findings and individual evidence.
3. Read the smallest relevant production slice and establish ownership/contracts.
4. Save a baseline and refactor one coherent vertical slice.
5. Query affected tests, run them, rescan, and compare the baseline.
