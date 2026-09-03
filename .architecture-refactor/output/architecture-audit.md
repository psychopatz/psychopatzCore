# Architecture Audit

Analyzer version: `2.0.0`  
Scoring scope: `production`

> Static analysis is triage evidence, not permission to refactor. Low coverage means inspect the source; preserve behavior and choose the smallest coherent ownership/boundary change.

## Project summary

| Metric | Value |
|---|---:|
| Production Health | 69.2/100 |
| Coverage | 76.9% |
| Confidence | 63.2% |
| Max Refactor Pressure | 100.0/100 |
| Production files | 144 |
| Tests indexed | 66 |
| Tooling files indexed | 12 |
| Generated files indexed | 0 |
| Production LOC scored | 21863 |
| Logical subsystems | 23 |
| Production findings | 38 |
| Test findings | 3 |

## Subsystems by refactor pressure

| Subsystem | Pressure | Health | Coverage | Confidence | Files | LOC | Findings | Fan-in | Fan-out |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| (composition) | 100.0 | 61.1/100 | 78.5% | 63.8% | 3 | 54 | 7 | 7 | 15 |
| UI | 100.0 | 52.4/100 | 77.6% | 65.0% | 56 | 10939 | 14 | 3 | 7 |
| Profiler | 67.2 | 63.2/100 | 77.9% | 63.0% | 11 | 1375 | 4 | 3 | 1 |
| Bridge | 66.7 | 62.9/100 | 81.5% | 68.4% | 7 | 837 | 5 | 1 | 1 |
| Inventory | 24.9 | 86.2/100 | 81.5% | 68.2% | 22 | 2620 | 2 | 3 | 2 |
| Debug | 20.9 | 87.5/100 | 73.6% | 59.6% | 6 | 673 | 1 | 1 | 5 |
| Radio | 19.1 | 87.5/100 | 76.3% | 61.9% | 10 | 700 | 1 | 2 | 2 |
| World | 18.9 | 87.5/100 | 78.5% | 63.8% | 5 | 853 | 1 | 3 | 1 |
| Traits | 17.5 | 87.5/100 | 67.0% | 54.1% | 2 | 290 | 1 | 1 | 1 |
| Voice | 3.2 | 99.8/100 | 78.5% | 61.1% | 1 | 548 | 1 | 1 | 2 |
| WorldLoot | 2.6 | 100.0/100 | 78.5% | 58.9% | 4 | 674 | 0 | 0 | 3 |
| ZombieKillDetector | 2.6 | 98.2/100 | 78.5% | 62.7% | 4 | 742 | 1 | 1 | 0 |
| Runtime | 1.8 | 100.0/100 | 54.6% | 41.0% | 1 | 22 | 0 | 3 | 0 |
| Journal | 1.5 | 100.0/100 | 78.5% | 58.9% | 1 | 165 | 0 | 1 | 1 |
| Composition | 1.4 | 100.0/100 | 78.5% | 58.9% | 2 | 60 | 0 | 1 | 1 |
| Conversation | 1.3 | 100.0/100 | 57.7% | 43.3% | 1 | 176 | 0 | 2 | 0 |
| Input | 1.3 | 100.0/100 | 54.6% | 41.0% | 1 | 229 | 0 | 2 | 0 |
| Text | 1.3 | 100.0/100 | 54.6% | 41.0% | 1 | 246 | 0 | 2 | 0 |
| Collections | 1.2 | 100.0/100 | 54.6% | 41.0% | 1 | 77 | 0 | 2 | 0 |
| Events | 1.2 | 100.0/100 | 54.6% | 41.0% | 1 | 73 | 0 | 2 | 0 |
| Settings | 0.7 | 100.0/100 | 57.7% | 43.3% | 1 | 213 | 0 | 1 | 0 |
| EventMarkers | 0.1 | 100.0/100 | 67.0% | 50.2% | 2 | 248 | 0 | 0 | 0 |
| Compatibility | 0.0 | 100.0/100 | 54.6% | 41.0% | 1 | 49 | 0 | 0 | 0 |

## Finding counts

| Scope | Rule | Severity | Count |
|---|---|---|---:|
| production | `DEPENDENCY_CYCLE` | HIGH | 23 |
| production | `LARGE_FUNCTION` | MEDIUM | 6 |
| production | `CORE_DOMAIN_DEPENDENCY` | HIGH | 5 |
| production | `HOT_PATH_EVENT_RISK` | LOW | 2 |
| production | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | 1 |
| production | `UNBOUNDED_LOOP` | MEDIUM | 1 |
| test | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | 3 |

## Finding index

Query evidence with `architecture_audit finding <repo> <finding-id> --context 4` before changing code.

| ID | Rule | Severity | Confidence | Subsystem | Summary |
|---|---|---|---:|---|---|
| `ARC-0445CE7CB0` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Inventory -> (composition) |
| `ARC-0AAF8C69DB` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Inventory | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Inventory -> (composition) |
| `ARC-2239D1D20A` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Traits -> (composition) |
| `ARC-3495608B46` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Inventory -> (composition) |
| `ARC-3773A8B514` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Debug -> (composition) |
| `ARC-3F1FB54A3B` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: (composition) -> Debug -> (composition) |
| `ARC-43261252E3` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-494A74D143` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-545522E1C2` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-55F0FAC477` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Traits | Subsystem participates in dependency cycle: (composition) -> Traits -> (composition) |
| `ARC-5D7A860962` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-6340551EE1` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> World -> (composition) |
| `ARC-7821AC302D` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Inventory -> (composition) |
| `ARC-797FDD2498` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-7B7701F9B5` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-A77D50EC2C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> World -> (composition) |
| `ARC-B551542E4F` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-C6082263FB` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | World | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> World -> (composition) |
| `ARC-CB4F5AFD2F` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Inventory -> (composition) |
| `ARC-E6447418A7` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-E9E8124C90` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> World -> (composition) |
| `ARC-EAAF595596` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Radio | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-F69D2FCEA6` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> World -> (composition) |
| `ARC-5B58B79A64` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/42.19/media/lua/client/PsychopatzCore/UI/Core/PsychopatzUITheme.lua depends on non-core files. |
| `ARC-630E8F3A25` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/PsychopatzAudioSettings.lua depends on non-core files. |
| `ARC-7DDDF08E0D` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPortrait.lua depends on non-core files. |
| `ARC-D1150902D5` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput.lua depends on non-core files. |
| `ARC-EA3A078AFC` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/PsychopatzConversationSettings.lua depends on non-core files. |
| `ARC-9830D6DAC6` | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | HIGH (82%) | (composition) | Contents/mods/PsychopatzCore/42.19/media/lua/shared/PsychopatzCore/00_PsychopatzCore_Init.lua directly depends on 12 foreign subsystems. |
| `ARC-FF522A2B89` | `UNBOUNDED_LOOP` | MEDIUM | HIGH (92%) | Inventory | Potential unbounded loop in Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Inventory/PsychopatzInventory.lua. |
| `ARC-07A213BB70` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | PsychopatzConversationChat:render spans 124 lines. |
| `ARC-1862355AAF` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | VirtualizedList.Install spans 251 lines. |
| `ARC-712263E72E` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | PsychopatzConversationView:createChildren spans 151 lines. |
| `ARC-75E695864C` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | list:prerender spans 128 lines. |
| `ARC-8983BD725E` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | PsychopatzConversationChoices:render spans 125 lines. |
| `ARC-ED4EDDDCD1` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | ZombieKillDetector | Internal.HandleClientCommand spans 122 lines. |
| `ARC-3172799948` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Voice | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Voice/PsychopatzVoiceGateway.lua publishes events and contains a recurring hot-path signal. |
| `ARC-E74551A113` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Bridge | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Bridge/PsychopatzBridge.lua publishes events and contains a recurring hot-path signal. |
| `ARC-113762D8E2` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | Inventory | Repeated test setup appears across 3 tests (~24 repeated LOC). |
| `ARC-3403298725` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (80%) | Profiler | Repeated test setup appears across 7 tests (~108 repeated LOC). |
| `ARC-4E0EE034B0` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (95%) | tests | Repeated test setup appears across 27 tests (~348 repeated LOC). |

## Largest maintained modules

Generated artifacts and tooling are indexed but excluded from this table and production scoring.

| ID | File | Code LOC |
|---|---|---:|

## Largest functions

| ID | Function | File | Start | LOC |
|---|---|---|---:|---:|
| `ARC-1862355AAF` | `VirtualizedList.Install` | `Contents/mods/PsychopatzCore/42.19/media/lua/client/PsychopatzCore/UI/Components/PsychopatzVirtualizedList.lua` | 130 | 251 |
| `ARC-712263E72E` | `PsychopatzConversationView:createChildren` | `Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/PsychopatzConversationView.lua` | 31 | 151 |
| `ARC-75E695864C` | `list:prerender` | `Contents/mods/PsychopatzCore/42.19/media/lua/client/PsychopatzCore/UI/Components/PsychopatzVirtualizedList.lua` | 250 | 128 |
| `ARC-8983BD725E` | `PsychopatzConversationChoices:render` | `Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChoices.lua` | 111 | 125 |
| `ARC-07A213BB70` | `PsychopatzConversationChat:render` | `Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChat.lua` | 135 | 124 |
| `ARC-ED4EDDDCD1` | `Internal.HandleClientCommand` | `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector_Transport.lua` | 75 | 122 |

## Recommended workflow

1. Select a high-pressure subsystem with adequate coverage.
2. Inspect grouped findings and individual evidence.
3. Read the smallest relevant production slice and establish ownership/contracts.
4. Save a baseline and refactor one coherent vertical slice.
5. Query affected tests, run them, rescan, and compare the baseline.
