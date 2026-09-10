# Architecture Audit

Analyzer version: `2.0.0`  
Scoring scope: `production`

> Static analysis is triage evidence, not permission to refactor. Low coverage means inspect the source; preserve behavior and choose the smallest coherent ownership/boundary change.

## Project summary

| Metric | Value |
|---|---:|
| Production Health | 68.5/100 |
| Coverage | 77.3% |
| Confidence | 63.6% |
| Max Refactor Pressure | 100.0/100 |
| Production files | 149 |
| Tests indexed | 70 |
| Tooling files indexed | 13 |
| Generated files indexed | 0 |
| Production LOC scored | 23937 |
| Logical subsystems | 23 |
| Production findings | 49 |
| Test findings | 6 |

## Subsystems by refactor pressure

| Subsystem | Pressure | Health | Coverage | Confidence | Files | LOC | Findings | Fan-in | Fan-out |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| (composition) | 100.0 | 61.1/100 | 78.5% | 63.8% | 3 | 59 | 8 | 7 | 17 |
| UI | 100.0 | 51.8/100 | 77.6% | 65.0% | 57 | 11669 | 17 | 3 | 8 |
| Profiler | 83.3 | 63.2/100 | 77.9% | 63.0% | 11 | 1550 | 5 | 3 | 1 |
| Bridge | 82.7 | 62.9/100 | 81.5% | 68.4% | 7 | 866 | 6 | 1 | 1 |
| Debug | 69.7 | 63.2/100 | 76.9% | 62.1% | 7 | 982 | 4 | 2 | 5 |
| Inventory | 24.9 | 86.2/100 | 81.5% | 68.2% | 22 | 2620 | 2 | 3 | 2 |
| World | 23.6 | 85.5/100 | 78.5% | 66.0% | 5 | 1017 | 2 | 3 | 1 |
| Radio | 19.1 | 87.5/100 | 76.3% | 61.9% | 10 | 700 | 1 | 2 | 2 |
| Traits | 17.5 | 87.5/100 | 67.0% | 54.1% | 2 | 290 | 1 | 1 | 1 |
| Conversation | 3.7 | 99.8/100 | 81.5% | 63.4% | 4 | 838 | 1 | 3 | 1 |
| Voice | 3.2 | 99.8/100 | 78.5% | 61.1% | 1 | 548 | 1 | 1 | 2 |
| WorldLoot | 2.6 | 100.0/100 | 78.5% | 58.9% | 4 | 674 | 0 | 0 | 3 |
| ZombieKillDetector | 2.6 | 98.2/100 | 78.5% | 62.7% | 4 | 742 | 1 | 1 | 0 |
| Events | 1.8 | 100.0/100 | 54.6% | 41.0% | 1 | 73 | 0 | 3 | 0 |
| Runtime | 1.8 | 100.0/100 | 54.6% | 41.0% | 1 | 22 | 0 | 3 | 0 |
| Journal | 1.5 | 100.0/100 | 78.5% | 58.9% | 1 | 165 | 0 | 1 | 1 |
| Composition | 1.4 | 100.0/100 | 78.5% | 58.9% | 2 | 60 | 0 | 1 | 1 |
| Input | 1.3 | 100.0/100 | 54.6% | 41.0% | 1 | 229 | 0 | 2 | 0 |
| Text | 1.3 | 100.0/100 | 54.6% | 41.0% | 1 | 246 | 0 | 2 | 0 |
| Collections | 1.2 | 100.0/100 | 54.6% | 41.0% | 1 | 77 | 0 | 2 | 0 |
| Settings | 0.7 | 100.0/100 | 57.7% | 43.3% | 1 | 213 | 0 | 1 | 0 |
| Compatibility | 0.6 | 100.0/100 | 54.6% | 41.0% | 1 | 49 | 0 | 1 | 0 |
| EventMarkers | 0.1 | 100.0/100 | 67.0% | 50.2% | 2 | 248 | 0 | 0 | 0 |

## Finding counts

| Scope | Rule | Severity | Count |
|---|---|---|---:|
| production | `DEPENDENCY_CYCLE` | HIGH | 30 |
| production | `LARGE_FUNCTION` | MEDIUM | 7 |
| production | `CORE_DOMAIN_DEPENDENCY` | HIGH | 5 |
| production | `HOT_PATH_EVENT_RISK` | LOW | 3 |
| production | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | 2 |
| production | `UNBOUNDED_LOOP` | MEDIUM | 2 |
| test | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | 6 |

## Finding index

Query evidence with `architecture_audit finding <repo> <finding-id> --context 4` before changing code.

| ID | Rule | Severity | Confidence | Subsystem | Summary |
|---|---|---|---:|---|---|
| `ARC-02F213FFD8` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-0325664FE2` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-151355A301` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Traits | Subsystem participates in dependency cycle: (composition) -> Traits -> (composition) |
| `ARC-1A9C3B695F` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-2C7EB86509` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Radio | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-2FCF35CC0B` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Inventory | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-308588813B` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Traits -> (composition) |
| `ARC-4554EAEE38` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-45B43587AE` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-49CF5AFBA5` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-7B5445309A` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: Debug -> UI -> Debug |
| `ARC-7B87560A67` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-7CED0E69ED` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: Debug -> UI -> Debug |
| `ARC-7DF687DFED` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-7EA86200E9` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-878EEE1ED9` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-8D8BBED322` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-9530C10A6A` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-97078B4D49` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-A08FFB4A57` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-AA195056E4` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-AE965CCA21` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-AE9BBB4195` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | World | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> World -> (composition) |
| `ARC-B978D62030` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-E419E288F3` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> Inventory -> (composition) |
| `ARC-ED186B0949` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-EE13DBFE3D` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-FC7250921D` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-FD4ABEBFE7` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-FDF3C9705C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Debug -> (composition) |
| `ARC-059B1384F8` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPortrait.lua depends on non-core files. |
| `ARC-523904185E` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput.lua depends on non-core files. |
| `ARC-A755D07BBC` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/PsychopatzConversationSettings.lua depends on non-core files. |
| `ARC-BBDD52F84B` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/Core/PsychopatzUITheme.lua depends on non-core files. |
| `ARC-C71AC82421` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/PsychopatzAudioSettings.lua depends on non-core files. |
| `ARC-5B36627A03` | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | HIGH (82%) | (composition) | Contents/mods/PsychopatzCore/42.20/media/lua/shared/PsychopatzCore/00_PsychopatzCore_Init.lua directly depends on 13 foreign subsystems. |
| `ARC-869C0B2E6E` | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | HIGH (82%) | (composition) | Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/00_PsychopatzCore_Client_Init.lua directly depends on 5 foreign subsystems. |
| `ARC-17B6F562A1` | `UNBOUNDED_LOOP` | MEDIUM | HIGH (92%) | World | Potential unbounded loop in Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/World/PsychopatzSquareRules.lua. |
| `ARC-FF522A2B89` | `UNBOUNDED_LOOP` | MEDIUM | HIGH (92%) | Inventory | Potential unbounded loop in Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Inventory/PsychopatzInventory.lua. |
| `ARC-07A213BB70` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | PsychopatzConversationChat:render spans 124 lines. |
| `ARC-712263E72E` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | PsychopatzConversationView:createChildren spans 151 lines. |
| `ARC-8983BD725E` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | PsychopatzConversationChoices:render spans 125 lines. |
| `ARC-A3FBB4A811` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | list:prerender spans 128 lines. |
| `ARC-DD1A9C7D55` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | ISPsychopatzCommandHubSettingsWindow:createChildren spans 130 lines. |
| `ARC-ED4EDDDCD1` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | ZombieKillDetector | Internal.HandleClientCommand spans 122 lines. |
| `ARC-EF0A486FA0` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | VirtualizedList.Install spans 251 lines. |
| `ARC-06FE02703D` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Bridge | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Bridge/PsychopatzBridge.lua publishes events and contains a recurring hot-path signal. |
| `ARC-3172799948` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Voice | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Voice/PsychopatzVoiceGateway.lua publishes events and contains a recurring hot-path signal. |
| `ARC-DE0DE3248F` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Conversation | Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/Conversation/PsychopatzSocialFlavorClient.lua publishes events and contains a recurring hot-path signal. |
| `ARC-113762D8E2` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | Inventory | Repeated test setup appears across 3 tests (~24 repeated LOC). |
| `ARC-3147ADDCAA` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | World | Repeated test setup appears across 3 tests (~24 repeated LOC). |
| `ARC-4BD2C13DA1` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | tools | Repeated test setup appears across 3 tests (~12 repeated LOC). |
| `ARC-4E0EE034B0` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (95%) | tests | Repeated test setup appears across 27 tests (~348 repeated LOC). |
| `ARC-B91DA22AEC` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | Bridge | Repeated test setup appears across 3 tests (~36 repeated LOC). |
| `ARC-E50A71C6E8` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (82%) | Profiler | Repeated test setup appears across 8 tests (~120 repeated LOC). |

## Largest maintained modules

Generated artifacts and tooling are indexed but excluded from this table and production scoring.

| ID | File | Code LOC |
|---|---|---:|

## Largest functions

| ID | Function | File | Start | LOC |
|---|---|---|---:|---:|
| `ARC-EF0A486FA0` | `VirtualizedList.Install` | `Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/Components/PsychopatzVirtualizedList.lua` | 130 | 251 |
| `ARC-712263E72E` | `PsychopatzConversationView:createChildren` | `Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/PsychopatzConversationView.lua` | 31 | 151 |
| `ARC-DD1A9C7D55` | `ISPsychopatzCommandHubSettingsWindow:createChildren` | `Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/PsychopatzCommandHubSettingsWindow.lua` | 70 | 130 |
| `ARC-A3FBB4A811` | `list:prerender` | `Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/Components/PsychopatzVirtualizedList.lua` | 250 | 128 |
| `ARC-8983BD725E` | `PsychopatzConversationChoices:render` | `Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChoices.lua` | 111 | 125 |
| `ARC-07A213BB70` | `PsychopatzConversationChat:render` | `Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChat.lua` | 135 | 124 |
| `ARC-ED4EDDDCD1` | `Internal.HandleClientCommand` | `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector_Transport.lua` | 75 | 122 |

## Recommended workflow

1. Select a high-pressure subsystem with adequate coverage.
2. Inspect grouped findings and individual evidence.
3. Read the smallest relevant production slice and establish ownership/contracts.
4. Save a baseline and refactor one coherent vertical slice.
5. Query affected tests, run them, rescan, and compare the baseline.
