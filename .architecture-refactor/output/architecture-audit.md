# Architecture Audit

Analyzer version: `2.0.0`  
Scoring scope: `production`

> Static analysis is triage evidence, not permission to refactor. Low coverage means inspect the source; preserve behavior and choose the smallest coherent ownership/boundary change.

## Project summary

| Metric | Value |
|---|---:|
| Production Health | 93.0/100 |
| Coverage | 64.1% |
| Confidence | 52.7% |
| Max Refactor Pressure | 16.7/100 |
| Production files | 348 |
| Tests indexed | 154 |
| Tooling files indexed | 86 |
| Generated files indexed | 0 |
| Production LOC scored | 53705 |
| Logical subsystems | 2 |
| Production findings | 5 |
| Test findings | 3 |

## Subsystems by refactor pressure

| Subsystem | Pressure | Health | Coverage | Confidence | Files | LOC | Findings | Fan-in | Fan-out |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| PsychopatzCore | 16.7 | 93.0/100 | 64.1% | 52.7% | 347 | 53704 | 5 | 1 | 0 |
| (root) | 0.8 | 100.0/100 | 66.6% | 50.0% | 1 | 1 | 0 | 0 | 1 |

## Finding counts

| Scope | Rule | Severity | Count |
|---|---|---|---:|
| production | `HOT_PATH_EVENT_RISK` | LOW | 2 |
| production | `LARGE_FUNCTION` | MEDIUM | 2 |
| production | `LARGE_MODULE` | MEDIUM | 1 |
| test | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | 3 |

## Finding index

Query evidence with `architecture_audit finding <repo> <finding-id> --context 4` before changing code.

| ID | Rule | Severity | Confidence | Subsystem | Summary |
|---|---|---|---:|---|---|
| `ARC-110A65BC22` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | PsychopatzCore | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Translation/PsychopatzCustomTranslationManager.lua has 803 code lines; review responsibility density. |
| `ARC-34AA3AD399` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | PsychopatzCore | OS.Open spans 155 lines. |
| `ARC-5378EC1770` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | PsychopatzCore | Parser.ParseCandidates spans 139 lines. |
| `ARC-43A17EA6D0` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | PsychopatzCore | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Voice/PsychopatzVoiceGateway.lua publishes events and contains a recurring hot-path signal. |
| `ARC-E37DE3497D` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | PsychopatzCore | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Bridge/PsychopatzBridge.lua publishes events and contains a recurring hot-path signal. |
| `ARC-4BD2C13DA1` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | tools | Repeated test setup appears across 3 tests (~12 repeated LOC). |
| `ARC-C444AF33D8` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (95%) | tests | Repeated test setup appears across 37 tests (~504 repeated LOC). |
| `ARC-CA1BC22496` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (95%) | PsychopatzCore | Repeated test setup appears across 58 tests (~960 repeated LOC). |

## Largest maintained modules

Generated artifacts and tooling are indexed but excluded from this table and production scoring.

| ID | File | Code LOC |
|---|---|---:|
| `ARC-110A65BC22` | `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Translation/PsychopatzCustomTranslationManager.lua` | 803 |

## Largest functions

| ID | Function | File | Start | LOC |
|---|---|---|---:|---:|
| `ARC-34AA3AD399` | `OS.Open` | `Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSDevice.lua` | 209 | 155 |
| `ARC-5378EC1770` | `Parser.ParseCandidates` | `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/PsychopatzSemanticParser.lua` | 343 | 139 |

## Recommended workflow

1. Select a high-pressure subsystem with adequate coverage.
2. Inspect grouped findings and individual evidence.
3. Read the smallest relevant production slice and establish ownership/contracts.
4. Save a baseline and refactor one coherent vertical slice.
5. Query affected tests, run them, rescan, and compare the baseline.
