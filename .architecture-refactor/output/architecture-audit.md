# Architecture Audit

Analyzer version: `2.0.0`  
Scoring scope: `production`

> Static analysis is triage evidence, not permission to refactor. Low coverage means inspect the source; preserve behavior and choose the smallest coherent ownership/boundary change.

## Project summary

| Metric | Value |
|---|---:|
| Production Health | 74.5/100 |
| Coverage | 77.3% |
| Confidence | 62.2% |
| Max Refactor Pressure | 100.0/100 |
| Production files | 280 |
| Tests indexed | 112 |
| Tooling files indexed | 46 |
| Generated files indexed | 0 |
| Production LOC scored | 40575 |
| Logical subsystems | 30 |
| Production findings | 53 |
| Test findings | 9 |

## Subsystems by refactor pressure

| Subsystem | Pressure | Health | Coverage | Confidence | Files | LOC | Findings | Fan-in | Fan-out |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| (composition) | 100.0 | 61.1/100 | 73.1% | 59.7% | 3 | 12 | 8 | 8 | 6 |
| Composition | 100.0 | 61.1/100 | 78.5% | 63.8% | 12 | 158 | 8 | 1 | 17 |
| UI | 100.0 | 53.6/100 | 78.3% | 64.5% | 111 | 15913 | 13 | 4 | 9 |
| Debug | 87.4 | 63.2/100 | 79.3% | 64.2% | 14 | 1823 | 5 | 3 | 6 |
| Bridge | 83.5 | 62.9/100 | 81.5% | 68.4% | 7 | 719 | 6 | 1 | 2 |
| Profiler | 82.7 | 63.2/100 | 77.9% | 63.0% | 11 | 1608 | 5 | 2 | 1 |
| Inventory | 20.9 | 88.2/100 | 81.5% | 66.1% | 26 | 4391 | 1 | 3 | 2 |
| World | 20.2 | 88.2/100 | 81.5% | 66.1% | 14 | 2385 | 1 | 3 | 2 |
| Radio | 19.1 | 87.5/100 | 76.3% | 61.9% | 10 | 764 | 1 | 2 | 2 |
| Economy | 18.5 | 87.5/100 | 74.4% | 60.3% | 7 | 1324 | 1 | 2 | 1 |
| Preview | 18.1 | 87.5/100 | 77.1% | 62.6% | 8 | 1954 | 1 | 1 | 1 |
| Traits | 17.6 | 87.5/100 | 67.0% | 54.1% | 3 | 475 | 1 | 1 | 1 |
| Conversation | 4.3 | 99.8/100 | 81.5% | 63.4% | 4 | 849 | 1 | 4 | 1 |
| Translation | 3.7 | 100.0/100 | 78.5% | 58.9% | 3 | 886 | 0 | 3 | 2 |
| Voice | 3.2 | 99.8/100 | 78.5% | 61.1% | 1 | 552 | 1 | 1 | 2 |
| WorldLoot | 2.6 | 100.0/100 | 78.5% | 58.9% | 4 | 674 | 0 | 0 | 3 |
| Serialization | 1.9 | 100.0/100 | 78.5% | 58.9% | 2 | 287 | 0 | 3 | 0 |
| Events | 1.8 | 100.0/100 | 54.6% | 41.0% | 1 | 73 | 0 | 3 | 0 |
| Runtime | 1.8 | 100.0/100 | 54.6% | 41.0% | 1 | 22 | 0 | 3 | 0 |
| Compatibility | 1.5 | 100.0/100 | 54.6% | 41.0% | 4 | 911 | 0 | 2 | 0 |
| Journal | 1.5 | 100.0/100 | 78.5% | 58.9% | 1 | 165 | 0 | 1 | 1 |
| Semantics | 1.4 | 100.0/100 | 78.5% | 58.9% | 19 | 2359 | 0 | 1 | 0 |
| Input | 1.3 | 100.0/100 | 54.6% | 41.0% | 1 | 295 | 0 | 2 | 0 |
| Text | 1.3 | 100.0/100 | 54.6% | 41.0% | 1 | 246 | 0 | 2 | 0 |
| Collections | 1.2 | 100.0/100 | 54.6% | 41.0% | 1 | 77 | 0 | 2 | 0 |
| ZombieKillDetector | 0.9 | 100.0/100 | 78.5% | 58.9% | 6 | 780 | 0 | 1 | 0 |
| CustomTranslation | 0.8 | 100.0/100 | 72.9% | 54.7% | 1 | 1 | 0 | 0 | 1 |
| Settings | 0.7 | 100.0/100 | 57.7% | 43.3% | 1 | 213 | 0 | 1 | 0 |
| Animation | 0.1 | 100.0/100 | 54.6% | 41.0% | 1 | 411 | 0 | 0 | 0 |
| EventMarkers | 0.1 | 100.0/100 | 67.0% | 50.2% | 2 | 248 | 0 | 0 | 0 |

## Finding counts

| Scope | Rule | Severity | Count |
|---|---|---|---:|
| production | `DEPENDENCY_CYCLE` | HIGH | 42 |
| production | `CORE_DOMAIN_DEPENDENCY` | HIGH | 6 |
| production | `HOT_PATH_EVENT_RISK` | LOW | 3 |
| production | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | 2 |
| test | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | 9 |

## Finding index

Query evidence with `architecture_audit finding <repo> <finding-id> --context 4` before changing code.

| ID | Rule | Severity | Confidence | Subsystem | Summary |
|---|---|---|---:|---|---|
| `ARC-0D9341684F` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: Debug -> Preview -> UI -> Debug |
| `ARC-0F06B860C2` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-0FB29D5C66` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Radio | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-105DA9A458` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Economy | Subsystem participates in dependency cycle: (composition) -> Composition -> Economy -> (composition) |
| `ARC-1BCD9A87AD` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-1C044AAAA1` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Inventory | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-2ACFFF0AF2` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-2C79ECF7EB` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | World | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-322A8C656F` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-36C59E878E` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-3BC1C7DDEA` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-3E84111128` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-443F30489E` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Traits | Subsystem participates in dependency cycle: (composition) -> Composition -> Traits -> (composition) |
| `ARC-49E1391292` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-53E2E7317F` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Preview | Subsystem participates in dependency cycle: Debug -> Preview -> UI -> Debug |
| `ARC-56C4CB4B83` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Traits -> (composition) |
| `ARC-5D9FF39353` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-65C70DAECA` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-6CC542DC44` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-70A230F3D4` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-73CEC26D95` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-78A320F60C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: Debug -> Preview -> UI -> Debug |
| `ARC-7B5445309A` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: Debug -> UI -> Debug |
| `ARC-7CED0E69ED` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: Debug -> UI -> Debug |
| `ARC-86F07FBE16` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-8AF46DE6F3` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-8FD80DB0E3` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-95056F8B5A` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Economy -> (composition) |
| `ARC-9DD746BB6C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-A2762FD055` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Traits -> (composition) |
| `ARC-A6B8C766B2` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-B10F7404D9` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-B69F06937F` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-BDE73AA888` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-BFF9880C83` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-CC1AFDCF37` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-CF55791443` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Economy -> (composition) |
| `ARC-DB1630FF51` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-DBF9E200C7` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-E2BE9009DB` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-E673F6B2CD` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-F236C19226` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-059B1384F8` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPortrait.lua depends on non-core files. |
| `ARC-292A1037C8` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/PsychopatzConversationSettings.lua depends on non-core files. |
| `ARC-6D526E986A` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/PsychopatzConversationSettings_UI.lua depends on non-core files. |
| `ARC-6DD3A465A6` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/PsychopatzAudioSettings.lua depends on non-core files. |
| `ARC-82F285D27E` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput.lua depends on non-core files. |
| `ARC-BBDD52F84B` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/Core/PsychopatzUITheme.lua depends on non-core files. |
| `ARC-3CCF516BDE` | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | HIGH (82%) | (composition) | Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/00_PsychopatzCore_Client_Init.lua directly depends on 6 foreign subsystems. |
| `ARC-976CD72A36` | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | HIGH (82%) | Composition | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Composition/PC_SharedFoundation_Language.lua directly depends on 5 foreign subsystems. |
| `ARC-06FE02703D` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Bridge | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Bridge/PsychopatzBridge.lua publishes events and contains a recurring hot-path signal. |
| `ARC-26CAED0862` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Voice | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Voice/PsychopatzVoiceGateway.lua publishes events and contains a recurring hot-path signal. |
| `ARC-B488C6DD30` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Conversation | Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/Conversation/PsychopatzSocialFlavorClient.lua publishes events and contains a recurring hot-path signal. |
| `ARC-2808E9ADA6` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (80%) | Inventory | Repeated test setup appears across 7 tests (~84 repeated LOC). |
| `ARC-4BD2C13DA1` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | tools | Repeated test setup appears across 3 tests (~12 repeated LOC). |
| `ARC-98F4B175F0` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (95%) | tests | Repeated test setup appears across 38 tests (~534 repeated LOC). |
| `ARC-A18991104B` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (72%) | World | Repeated test setup appears across 4 tests (~36 repeated LOC). |
| `ARC-B91DA22AEC` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | Bridge | Repeated test setup appears across 3 tests (~36 repeated LOC). |
| `ARC-BA13AB613D` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (72%) | Debug | Repeated test setup appears across 4 tests (~96 repeated LOC). |
| `ARC-CE287FEB58` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | Compatibility | Repeated test setup appears across 3 tests (~12 repeated LOC). |
| `ARC-E50A71C6E8` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (82%) | Profiler | Repeated test setup appears across 8 tests (~120 repeated LOC). |
| `ARC-EB0F9D55BC` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | Economy | Repeated test setup appears across 3 tests (~12 repeated LOC). |

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
