# Architecture Audit

Analyzer version: `2.0.0`  
Scoring scope: `production`

> Static analysis is triage evidence, not permission to refactor. Low coverage means inspect the source; preserve behavior and choose the smallest coherent ownership/boundary change.

## Project summary

| Metric | Value |
|---|---:|
| Production Health | 71.2/100 |
| Coverage | 78.3% |
| Confidence | 64.0% |
| Max Refactor Pressure | 100.0/100 |
| Production files | 400 |
| Tests indexed | 202 |
| Tooling files indexed | 88 |
| Generated files indexed | 21 |
| Production LOC scored | 67741 |
| Logical subsystems | 37 |
| Production findings | 75 |
| Test findings | 12 |

## Subsystems by refactor pressure

| Subsystem | Pressure | Health | Coverage | Confidence | Files | LOC | Findings | Fan-in | Fan-out |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| (composition) | 100.0 | 61.1/100 | 73.1% | 59.7% | 3 | 4 | 8 | 9 | 1 |
| Bridge | 100.0 | 62.9/100 | 81.5% | 68.4% | 7 | 719 | 7 | 2 | 2 |
| Composition | 100.0 | 61.1/100 | 78.5% | 63.8% | 12 | 206 | 9 | 1 | 21 |
| UI | 100.0 | 52.5/100 | 78.3% | 65.7% | 149 | 24030 | 17 | 6 | 10 |
| Profiler | 99.4 | 63.2/100 | 77.9% | 63.0% | 11 | 1608 | 6 | 3 | 1 |
| Debug | 88.0 | 63.2/100 | 79.5% | 64.3% | 14 | 1707 | 5 | 4 | 6 |
| Kernel | 56.6 | 67.7/100 | 78.5% | 65.1% | 8 | 1076 | 4 | 1 | 25 |
| World | 49.3 | 69.8/100 | 81.4% | 67.1% | 44 | 9841 | 5 | 6 | 5 |
| Actors | 41.7 | 76.3/100 | 81.5% | 66.1% | 30 | 6801 | 2 | 7 | 4 |
| Conversation | 38.9 | 76.1/100 | 81.5% | 68.4% | 5 | 1240 | 3 | 4 | 4 |
| Inventory | 22.1 | 88.2/100 | 81.5% | 66.1% | 26 | 4514 | 1 | 5 | 2 |
| Radio | 19.7 | 87.5/100 | 76.3% | 61.9% | 10 | 785 | 1 | 3 | 2 |
| Preview | 18.7 | 87.5/100 | 77.1% | 62.6% | 8 | 1954 | 1 | 2 | 1 |
| Traits | 18.2 | 87.5/100 | 67.0% | 54.1% | 3 | 487 | 1 | 2 | 1 |
| Economy | 17.9 | 87.5/100 | 74.4% | 60.3% | 7 | 1326 | 1 | 1 | 1 |
| Semantics | 7.5 | 96.4/100 | 78.5% | 62.7% | 23 | 3896 | 2 | 3 | 1 |
| Translation | 7.1 | 96.7/100 | 78.5% | 61.6% | 4 | 1067 | 1 | 4 | 2 |
| Voice | 3.8 | 99.8/100 | 78.5% | 61.1% | 1 | 552 | 1 | 2 | 2 |
| Runtime | 3.6 | 100.0/100 | 54.6% | 41.0% | 1 | 22 | 0 | 6 | 0 |
| Serialization | 3.1 | 100.0/100 | 78.5% | 58.9% | 2 | 284 | 0 | 5 | 0 |
| Travel | 3.1 | 100.0/100 | 78.5% | 58.9% | 1 | 243 | 0 | 1 | 3 |
| Events | 3.0 | 100.0/100 | 54.6% | 41.0% | 1 | 73 | 0 | 5 | 0 |
| Content | 2.7 | 100.0/100 | 78.5% | 58.9% | 1 | 275 | 0 | 3 | 1 |
| WorldLoot | 2.6 | 100.0/100 | 78.5% | 58.9% | 4 | 674 | 0 | 0 | 3 |
| Journal | 2.1 | 100.0/100 | 78.5% | 58.9% | 1 | 165 | 0 | 2 | 1 |
| Collections | 1.8 | 100.0/100 | 54.6% | 41.0% | 1 | 77 | 0 | 3 | 0 |
| WorldKnowledge | 1.6 | 100.0/100 | 78.5% | 58.9% | 4 | 681 | 0 | 1 | 1 |
| Compatibility | 1.5 | 100.0/100 | 54.6% | 41.0% | 4 | 911 | 0 | 2 | 0 |
| ZombieKillDetector | 1.5 | 100.0/100 | 78.5% | 58.9% | 6 | 790 | 0 | 2 | 0 |
| Input | 1.3 | 100.0/100 | 54.6% | 41.0% | 1 | 312 | 0 | 2 | 0 |
| Spatial | 1.3 | 100.0/100 | 54.6% | 41.0% | 1 | 301 | 0 | 2 | 0 |
| Text | 1.3 | 100.0/100 | 54.6% | 41.0% | 1 | 246 | 0 | 2 | 0 |
| CustomTranslation | 0.8 | 100.0/100 | 72.9% | 54.7% | 1 | 1 | 0 | 0 | 1 |
| SurvivorWorld | 0.8 | 100.0/100 | 73.1% | 54.8% | 1 | 1 | 0 | 0 | 1 |
| Settings | 0.7 | 100.0/100 | 57.7% | 43.3% | 1 | 213 | 0 | 1 | 0 |
| Animation | 0.1 | 100.0/100 | 54.6% | 41.0% | 1 | 411 | 0 | 0 | 0 |
| EventMarkers | 0.1 | 100.0/100 | 67.0% | 50.2% | 2 | 248 | 0 | 0 | 0 |

## Finding counts

| Scope | Rule | Severity | Count |
|---|---|---|---:|
| production | `DEPENDENCY_CYCLE` | HIGH | 55 |
| production | `CORE_DOMAIN_DEPENDENCY` | HIGH | 7 |
| production | `LARGE_FUNCTION` | MEDIUM | 6 |
| production | `HOT_PATH_EVENT_RISK` | LOW | 3 |
| production | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | 2 |
| production | `LARGE_MODULE` | MEDIUM | 2 |
| test | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | 12 |

## Finding index

Query evidence with `architecture_audit finding <repo> <finding-id> --context 4` before changing code.

| ID | Rule | Severity | Confidence | Subsystem | Summary |
|---|---|---|---:|---|---|
| `ARC-0C19555970` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Conversation -> Actors -> Inventory -> (composition) |
| `ARC-0D9341684F` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: Debug -> Preview -> UI -> Debug |
| `ARC-105888C7C7` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Conversation -> Actors -> Inventory -> (composition) |
| `ARC-1383592D1C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Kernel -> Economy -> (composition) |
| `ARC-187BDADF3C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Conversation -> Actors -> Inventory -> (composition) |
| `ARC-18977C7137` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Kernel -> Traits -> (composition) |
| `ARC-1D32F09058` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-1D3AA8B978` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | World | Subsystem participates in dependency cycle: Debug -> World -> UI -> Debug |
| `ARC-203F5FBA5F` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Traits | Subsystem participates in dependency cycle: (composition) -> Composition -> Kernel -> Traits -> (composition) |
| `ARC-2BF62D5948` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-3943FC3314` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-43C1236A1E` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: Debug -> World -> UI -> Debug |
| `ARC-4DE6505818` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-5084D9F95D` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Actors | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Conversation -> Actors -> (composition) |
| `ARC-50D80D116C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-527EE409B2` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Radio | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-5336F4426D` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Kernel -> Traits -> (composition) |
| `ARC-53D9AAC057` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-53E2E7317F` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Preview | Subsystem participates in dependency cycle: Debug -> Preview -> UI -> Debug |
| `ARC-546245A3FE` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | World | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-553D15D3CA` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Kernel | Subsystem participates in dependency cycle: (composition) -> Composition -> Kernel -> Traits -> (composition) |
| `ARC-6351138374` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-64C35C03D3` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-65378F6B40` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Conversation | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Conversation -> Actors -> (composition) |
| `ARC-654465462D` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Conversation -> Actors -> (composition) |
| `ARC-6B610D055B` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-6FA26DDCC4` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Conversation | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Conversation -> Actors -> Inventory -> (composition) |
| `ARC-784AD0CACF` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: Debug -> World -> UI -> Debug |
| `ARC-78A320F60C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: Debug -> Preview -> UI -> Debug |
| `ARC-79DF217D18` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-7B5445309A` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: Debug -> UI -> Debug |
| `ARC-7CED0E69ED` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: Debug -> UI -> Debug |
| `ARC-807599C1DD` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Kernel -> Economy -> (composition) |
| `ARC-86391EC7F1` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Economy | Subsystem participates in dependency cycle: (composition) -> Composition -> Kernel -> Economy -> (composition) |
| `ARC-9533BB986C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-9D50A77F4C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-A2D47000E4` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-A5F4F3C99C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Conversation -> Actors -> (composition) |
| `ARC-A65273EB6D` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Inventory | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Conversation -> Actors -> Inventory -> (composition) |
| `ARC-B0B2DDC325` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-B5B8B64A29` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-B942A06771` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-CC9D16060D` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-D29AF383AA` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Kernel | Subsystem participates in dependency cycle: (composition) -> Composition -> Kernel -> Economy -> (composition) |
| `ARC-D9F7E5619E` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-DEF8A27FAC` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Conversation -> Actors -> Inventory -> (composition) |
| `ARC-E483EFE360` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Actors | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Conversation -> Actors -> Inventory -> (composition) |
| `ARC-EAE514D8A5` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-EAF4D8F50C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Composition | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-ED3C88AEEC` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Conversation -> Actors -> Inventory -> (composition) |
| `ARC-F050E4DF6B` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Conversation -> Actors -> (composition) |
| `ARC-F5B275ECDF` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Conversation -> Actors -> (composition) |
| `ARC-F88F91EF7C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-FB1F9BB930` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Conversation -> Actors -> (composition) |
| `ARC-FEA50E40C3` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Composition -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-059B1384F8` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPortrait.lua depends on non-core files. |
| `ARC-155DE1C765` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput.lua depends on non-core files. |
| `ARC-292A1037C8` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/PsychopatzConversationSettings.lua depends on non-core files. |
| `ARC-2FEE80CCB8` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | Kernel | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Kernel/PC_CapabilityCatalog.lua depends on non-core files. |
| `ARC-6D526E986A` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/PsychopatzConversationSettings_UI.lua depends on non-core files. |
| `ARC-A06BE1C2A3` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/PsychopatzAudioSettings.lua depends on non-core files. |
| `ARC-BBDD52F84B` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/Core/PsychopatzUITheme.lua depends on non-core files. |
| `ARC-976CD72A36` | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | HIGH (82%) | Composition | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Composition/PC_SharedFoundation_Language.lua directly depends on 5 foreign subsystems. |
| `ARC-EA22F0FFED` | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | HIGH (82%) | Kernel | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Kernel/PC_CapabilityCatalog.lua directly depends on 25 foreign subsystems. |
| `ARC-2E9DBFDD38` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Translation | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Translation/PsychopatzCustomTranslationManager.lua has 803 code lines; review responsibility density. |
| `ARC-96AF6D2FC2` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | World | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldDiscovery.lua has 847 code lines; review responsibility density. |
| `ARC-0B6DDAD4EF` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Semantics | Parser.ParseCandidates spans 140 lines. |
| `ARC-3EB65001B9` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | createWindowSupport spans 161 lines. |
| `ARC-4AAD959971` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | World | Planner.BuildCommunityPlan spans 131 lines. |
| `ARC-B3EECDCE18` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Semantics | PackRegistry.RegisterPack spans 139 lines. |
| `ARC-E7AF9C127A` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | OS.Open spans 155 lines. |
| `ARC-F2A11AA73F` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | World | Planner.BuildGroupPlan spans 139 lines. |
| `ARC-06FE02703D` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Bridge | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Bridge/PsychopatzBridge.lua publishes events and contains a recurring hot-path signal. |
| `ARC-26CAED0862` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Voice | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Voice/PsychopatzVoiceGateway.lua publishes events and contains a recurring hot-path signal. |
| `ARC-B488C6DD30` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Conversation | Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/Conversation/PsychopatzSocialFlavorClient.lua publishes events and contains a recurring hot-path signal. |
| `ARC-019314ECA3` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (80%) | Serialization | Repeated test setup appears across 7 tests (~240 repeated LOC). |
| `ARC-4BD2C13DA1` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | tools | Repeated test setup appears across 3 tests (~12 repeated LOC). |
| `ARC-55633D0E1C` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (95%) | Actors | Repeated test setup appears across 61 tests (~1446 repeated LOC). |
| `ARC-7303B115A3` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | UI | Repeated test setup appears across 3 tests (~12 repeated LOC). |
| `ARC-A18991104B` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (72%) | World | Repeated test setup appears across 4 tests (~36 repeated LOC). |
| `ARC-B91DA22AEC` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | Bridge | Repeated test setup appears across 3 tests (~36 repeated LOC). |
| `ARC-BA13AB613D` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (72%) | Debug | Repeated test setup appears across 4 tests (~96 repeated LOC). |
| `ARC-C444AF33D8` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (95%) | tests | Repeated test setup appears across 39 tests (~534 repeated LOC). |
| `ARC-CE287FEB58` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | Compatibility | Repeated test setup appears across 3 tests (~12 repeated LOC). |
| `ARC-D47065C5F7` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (72%) | (composition) | Repeated test setup appears across 4 tests (~36 repeated LOC). |
| `ARC-E50A71C6E8` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (82%) | Profiler | Repeated test setup appears across 8 tests (~120 repeated LOC). |
| `ARC-EB0F9D55BC` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | Economy | Repeated test setup appears across 3 tests (~12 repeated LOC). |

## Largest maintained modules

Generated artifacts and tooling are indexed but excluded from this table and production scoring.

| ID | File | Code LOC |
|---|---|---:|
| `ARC-96AF6D2FC2` | `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldDiscovery.lua` | 847 |
| `ARC-2E9DBFDD38` | `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Translation/PsychopatzCustomTranslationManager.lua` | 803 |

## Largest functions

| ID | Function | File | Start | LOC |
|---|---|---|---:|---:|
| `ARC-3EB65001B9` | `createWindowSupport` | `Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/PsychopatzActorNotificationToast.lua` | 56 | 161 |
| `ARC-E7AF9C127A` | `OS.Open` | `Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSDevice.lua` | 209 | 155 |
| `ARC-0B6DDAD4EF` | `Parser.ParseCandidates` | `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/PsychopatzSemanticParser.lua` | 380 | 140 |
| `ARC-B3EECDCE18` | `PackRegistry.RegisterPack` | `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/PsychopatzSemanticPackRegistry.lua` | 269 | 139 |
| `ARC-F2A11AA73F` | `Planner.BuildGroupPlan` | `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationPlanner.lua` | 211 | 139 |
| `ARC-4AAD959971` | `Planner.BuildCommunityPlan` | `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationPlanner.lua` | 79 | 131 |

## Recommended workflow

1. Select a high-pressure subsystem with adequate coverage.
2. Inspect grouped findings and individual evidence.
3. Read the smallest relevant production slice and establish ownership/contracts.
4. Save a baseline and refactor one coherent vertical slice.
5. Query affected tests, run them, rescan, and compare the baseline.
