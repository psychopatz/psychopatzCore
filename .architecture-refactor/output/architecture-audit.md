# Architecture Audit

Analyzer version: `2.0.0`  
Scoring scope: `production`

> Static analysis is triage evidence, not permission to refactor. Low coverage means inspect the source; preserve behavior and choose the smallest coherent ownership/boundary change.

## Project summary

| Metric | Value |
|---|---:|
| Production Health | 71.7/100 |
| Coverage | 77.5% |
| Confidence | 63.1% |
| Max Refactor Pressure | 100.0/100 |
| Production files | 307 |
| Tests indexed | 129 |
| Tooling files indexed | 85 |
| Generated files indexed | 0 |
| Production LOC scored | 46319 |
| Logical subsystems | 30 |
| Production findings | 54 |
| Test findings | 9 |

## Subsystems by refactor pressure

| Subsystem | Pressure | Health | Coverage | Confidence | Files | LOC | Findings | Fan-in | Fan-out |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| (composition) | 100.0 | 61.1/100 | 73.1% | 59.7% | 3 | 13 | 8 | 8 | 6 |
| Composition | 100.0 | 61.1/100 | 78.5% | 63.8% | 12 | 158 | 8 | 1 | 17 |
| UI | 100.0 | 53.0/100 | 78.5% | 65.8% | 138 | 21514 | 14 | 4 | 10 |
| Debug | 87.4 | 63.2/100 | 79.3% | 64.2% | 14 | 1823 | 5 | 3 | 6 |
| Bridge | 83.5 | 62.9/100 | 81.5% | 68.4% | 7 | 719 | 6 | 1 | 2 |
| Profiler | 82.7 | 63.2/100 | 77.9% | 63.0% | 11 | 1608 | 5 | 2 | 1 |
| Inventory | 20.9 | 88.2/100 | 81.5% | 66.1% | 26 | 4512 | 1 | 3 | 2 |
| World | 20.2 | 88.2/100 | 81.5% | 66.1% | 14 | 2385 | 1 | 3 | 2 |
| Radio | 19.1 | 87.5/100 | 76.3% | 61.9% | 10 | 785 | 1 | 2 | 2 |
| Economy | 18.5 | 87.5/100 | 74.4% | 60.3% | 7 | 1324 | 1 | 2 | 1 |
| Preview | 18.1 | 87.5/100 | 77.1% | 62.6% | 8 | 1954 | 1 | 1 | 1 |
| Traits | 17.6 | 87.5/100 | 67.0% | 54.1% | 3 | 475 | 1 | 1 | 1 |
| Conversation | 4.3 | 99.8/100 | 81.5% | 63.4% | 4 | 849 | 1 | 4 | 1 |
| Translation | 3.7 | 100.0/100 | 78.5% | 58.9% | 3 | 886 | 0 | 3 | 2 |
| Voice | 3.2 | 99.8/100 | 78.5% | 61.1% | 1 | 552 | 1 | 1 | 2 |
| WorldLoot | 2.6 | 100.0/100 | 78.5% | 58.9% | 4 | 674 | 0 | 0 | 3 |
| Serialization | 2.5 | 100.0/100 | 78.5% | 58.9% | 2 | 287 | 0 | 4 | 0 |
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
| production | `LARGE_FUNCTION` | MEDIUM | 1 |
| test | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | 9 |

## Finding index

Query evidence with `architecture_audit finding <repo> <finding-id> --context 4` before changing code.

| ID | Rule | Severity | Confidence | Subsystem | Summary |
|---|---|---|---:|---|---|
| `ARC-06D18FFE44` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-0D9341684F` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: Debug -> Preview -> UI -> Debug |
| `ARC-235550D6CB` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-2E0B8144DA` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-38D333E5B9` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-3E4036A9DB` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-416894EBF7` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-539A833821` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Traits | Subsystem participates in dependency cycle: (composition) -> Composition -> Traits -> (composition) |
| `ARC-53E2E7317F` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Preview | Subsystem participates in dependency cycle: Debug -> Preview -> UI -> Debug |
| `ARC-53F818153D` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Inventory | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-5458A2C686` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-55B4DC3E59` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-57E1CE898E` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Economy -> (composition) |
| `ARC-58F85E1F75` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-5AB6789132` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-76CEA68EC9` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-76D1B8A79E` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-78045BFAC0` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-78A320F60C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: Debug -> Preview -> UI -> Debug |
| `ARC-7B5445309A` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: Debug -> UI -> Debug |
| `ARC-7C7CB32B51` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Economy | Subsystem participates in dependency cycle: (composition) -> Composition -> Economy -> (composition) |
| `ARC-7CD81FD5E9` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-7CED0E69ED` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: Debug -> UI -> Debug |
| `ARC-8598962271` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-9146D08DEF` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Radio | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-9657DEFC4F` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-9CCA6E1F12` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-A459B9C9E6` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Economy -> (composition) |
| `ARC-C11FCF3DFB` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-C553F8CEF2` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Traits -> (composition) |
| `ARC-C6AC792493` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-CB9AB07467` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-E1D86FFB57` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-E4CB079C9A` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-E6FAB96E28` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-EB61A737D9` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | World | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-EBE6F43584` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-ED989BF550` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-F42FB88AE0` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-FB45616188` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-FDDD94140E` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Traits -> (composition) |
| `ARC-FE291A3A00` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-059B1384F8` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPortrait.lua depends on non-core files. |
| `ARC-292A1037C8` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/PsychopatzConversationSettings.lua depends on non-core files. |
| `ARC-6D526E986A` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/PsychopatzConversationSettings_UI.lua depends on non-core files. |
| `ARC-82F285D27E` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput.lua depends on non-core files. |
| `ARC-A06BE1C2A3` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/PsychopatzAudioSettings.lua depends on non-core files. |
| `ARC-BBDD52F84B` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/Core/PsychopatzUITheme.lua depends on non-core files. |
| `ARC-3CCF516BDE` | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | HIGH (82%) | (composition) | Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/00_PsychopatzCore_Client_Init.lua directly depends on 6 foreign subsystems. |
| `ARC-976CD72A36` | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | HIGH (82%) | Composition | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Composition/PC_SharedFoundation_Language.lua directly depends on 5 foreign subsystems. |
| `ARC-E7AF9C127A` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | OS.Open spans 155 lines. |
| `ARC-06FE02703D` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Bridge | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Bridge/PsychopatzBridge.lua publishes events and contains a recurring hot-path signal. |
| `ARC-26CAED0862` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Voice | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Voice/PsychopatzVoiceGateway.lua publishes events and contains a recurring hot-path signal. |
| `ARC-B488C6DD30` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Conversation | Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/Conversation/PsychopatzSocialFlavorClient.lua publishes events and contains a recurring hot-path signal. |
| `ARC-2808E9ADA6` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (80%) | Inventory | Repeated test setup appears across 7 tests (~84 repeated LOC). |
| `ARC-6C5D369599` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (77%) | tools | Repeated test setup appears across 6 tests (~24 repeated LOC). |
| `ARC-A18991104B` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (72%) | World | Repeated test setup appears across 4 tests (~36 repeated LOC). |
| `ARC-AA585FCCAA` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (95%) | tests | Repeated test setup appears across 44 tests (~606 repeated LOC). |
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
| `ARC-E7AF9C127A` | `OS.Open` | `Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSDevice.lua` | 209 | 155 |

## Recommended workflow

1. Select a high-pressure subsystem with adequate coverage.
2. Inspect grouped findings and individual evidence.
3. Read the smallest relevant production slice and establish ownership/contracts.
4. Save a baseline and refactor one coherent vertical slice.
5. Query affected tests, run them, rescan, and compare the baseline.
