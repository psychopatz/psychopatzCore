# Architecture Audit

Analyzer version: `2.0.0`  
Scoring scope: `production`

> Static analysis is triage evidence, not permission to refactor. Low coverage means inspect the source; preserve behavior and choose the smallest coherent ownership/boundary change.

## Project summary

| Metric | Value |
|---|---:|
| Production Health | 91.5/100 |
| Coverage | 67.7% |
| Confidence | 53.3% |
| Max Refactor Pressure | 26.4/100 |
| Production files | 221 |
| Tests indexed | 67 |
| Tooling files indexed | 12 |
| Generated files indexed | 0 |
| Production LOC scored | 35897 |
| Logical subsystems | 23 |
| Production findings | 16 |
| Test findings | 4 |

## Subsystems by refactor pressure

| Subsystem | Pressure | Health | Coverage | Confidence | Files | LOC | Findings | Fan-in | Fan-out |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| UI | 26.4 | 84.7/100 | 65.1% | 52.7% | 93 | 19320 | 9 | 1 | 4 |
| (composition) | 18.7 | 93.6/100 | 73.5% | 59.5% | 6 | 114 | 2 | 0 | 11 |
| Inventory | 7.8 | 98.1/100 | 80.9% | 62.9% | 24 | 3511 | 1 | 2 | 1 |
| Conversation | 3.7 | 99.8/100 | 81.5% | 63.4% | 4 | 836 | 1 | 3 | 1 |
| Voice | 3.2 | 99.8/100 | 78.5% | 61.1% | 1 | 548 | 1 | 1 | 2 |
| ZombieKillDetector | 2.6 | 98.2/100 | 78.5% | 62.7% | 4 | 742 | 1 | 1 | 0 |
| World | 2.1 | 100.0/100 | 70.1% | 52.6% | 6 | 916 | 0 | 3 | 0 |
| WorldLoot | 2.0 | 100.0/100 | 75.3% | 56.5% | 6 | 1264 | 0 | 0 | 2 |
| Debug | 1.8 | 100.0/100 | 60.5% | 45.4% | 10 | 1166 | 0 | 1 | 1 |
| Events | 1.8 | 100.0/100 | 54.6% | 41.0% | 1 | 73 | 0 | 3 | 0 |
| Radio | 1.8 | 100.0/100 | 62.4% | 46.8% | 19 | 1308 | 0 | 1 | 1 |
| Runtime | 1.8 | 100.0/100 | 54.6% | 41.0% | 1 | 22 | 0 | 3 | 0 |
| Journal | 1.5 | 100.0/100 | 78.5% | 58.9% | 1 | 165 | 0 | 1 | 1 |
| Text | 1.3 | 100.0/100 | 54.6% | 41.0% | 1 | 246 | 0 | 2 | 0 |
| Bridge | 1.2 | 99.8/100 | 77.2% | 60.1% | 8 | 928 | 1 | 0 | 0 |
| Collections | 1.2 | 100.0/100 | 54.6% | 41.0% | 1 | 77 | 0 | 2 | 0 |
| Profiler | 0.8 | 100.0/100 | 67.7% | 50.8% | 17 | 2483 | 0 | 0 | 0 |
| EventMarkers | 0.2 | 100.0/100 | 57.8% | 43.3% | 4 | 496 | 0 | 0 | 0 |
| Input | 0.2 | 100.0/100 | 54.6% | 41.0% | 2 | 458 | 0 | 0 | 0 |
| Traits | 0.2 | 100.0/100 | 57.8% | 43.3% | 4 | 580 | 0 | 0 | 0 |
| Settings | 0.1 | 100.0/100 | 57.7% | 43.3% | 2 | 426 | 0 | 0 | 0 |
| Compatibility | 0.0 | 100.0/100 | 54.6% | 41.0% | 2 | 98 | 0 | 0 | 0 |
| Composition | 0.0 | 100.0/100 | 60.9% | 45.7% | 4 | 120 | 0 | 0 | 0 |

## Finding counts

| Scope | Rule | Severity | Count |
|---|---|---|---:|
| production | `LARGE_FUNCTION` | MEDIUM | 10 |
| production | `HOT_PATH_EVENT_RISK` | LOW | 3 |
| production | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | 2 |
| production | `UNBOUNDED_LOOP` | MEDIUM | 1 |
| test | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | 4 |

## Finding index

Query evidence with `architecture_audit finding <repo> <finding-id> --context 4` before changing code.

| ID | Rule | Severity | Confidence | Subsystem | Summary |
|---|---|---|---:|---|---|
| `ARC-571063E5B9` | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | HIGH (82%) | (composition) | Contents/mods/PsychopatzCore/42.19/media/lua/shared/PsychopatzCore/00_PsychopatzCore_Init.lua directly depends on 10 foreign subsystems. |
| `ARC-CA74DE30E8` | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | HIGH (82%) | (composition) | Contents/mods/PsychopatzCore/42.20/media/lua/shared/PsychopatzCore/00_PsychopatzCore_Init.lua directly depends on 10 foreign subsystems. |
| `ARC-FF522A2B89` | `UNBOUNDED_LOOP` | MEDIUM | HIGH (92%) | Inventory | Potential unbounded loop in Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Inventory/PsychopatzInventory.lua. |
| `ARC-07A213BB70` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | PsychopatzConversationChat:render spans 124 lines. |
| `ARC-1862355AAF` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | VirtualizedList.Install spans 251 lines. |
| `ARC-712263E72E` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | PsychopatzConversationView:createChildren spans 151 lines. |
| `ARC-75E695864C` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | list:prerender spans 128 lines. |
| `ARC-8983BD725E` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | PsychopatzConversationChoices:render spans 125 lines. |
| `ARC-A3FBB4A811` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | list:prerender spans 128 lines. |
| `ARC-D86F662C14` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | ISPsychopatzCommandHubSettingsWindow:createChildren spans 130 lines. |
| `ARC-DD1A9C7D55` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | ISPsychopatzCommandHubSettingsWindow:createChildren spans 130 lines. |
| `ARC-ED4EDDDCD1` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | ZombieKillDetector | Internal.HandleClientCommand spans 122 lines. |
| `ARC-EF0A486FA0` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | VirtualizedList.Install spans 251 lines. |
| `ARC-034313527A` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Conversation | Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/Conversation/PsychopatzSocialFlavorClient.lua publishes events and contains a recurring hot-path signal. |
| `ARC-3172799948` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Voice | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Voice/PsychopatzVoiceGateway.lua publishes events and contains a recurring hot-path signal. |
| `ARC-E74551A113` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Bridge | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Bridge/PsychopatzBridge.lua publishes events and contains a recurring hot-path signal. |
| `ARC-113762D8E2` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | Inventory | Repeated test setup appears across 3 tests (~24 repeated LOC). |
| `ARC-3147ADDCAA` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | World | Repeated test setup appears across 3 tests (~24 repeated LOC). |
| `ARC-4E0EE034B0` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (95%) | tests | Repeated test setup appears across 27 tests (~348 repeated LOC). |
| `ARC-E50A71C6E8` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (82%) | Profiler | Repeated test setup appears across 8 tests (~120 repeated LOC). |

## Largest maintained modules

Generated artifacts and tooling are indexed but excluded from this table and production scoring.

| ID | File | Code LOC |
|---|---|---:|

## Largest functions

| ID | Function | File | Start | LOC |
|---|---|---|---:|---:|
| `ARC-1862355AAF` | `VirtualizedList.Install` | `Contents/mods/PsychopatzCore/42.19/media/lua/client/PsychopatzCore/UI/Components/PsychopatzVirtualizedList.lua` | 130 | 251 |
| `ARC-EF0A486FA0` | `VirtualizedList.Install` | `Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/Components/PsychopatzVirtualizedList.lua` | 130 | 251 |
| `ARC-712263E72E` | `PsychopatzConversationView:createChildren` | `Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/PsychopatzConversationView.lua` | 31 | 151 |
| `ARC-D86F662C14` | `ISPsychopatzCommandHubSettingsWindow:createChildren` | `Contents/mods/PsychopatzCore/42.19/media/lua/client/PsychopatzCore/UI/PsychopatzCommandHubSettingsWindow.lua` | 70 | 130 |
| `ARC-DD1A9C7D55` | `ISPsychopatzCommandHubSettingsWindow:createChildren` | `Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/PsychopatzCommandHubSettingsWindow.lua` | 70 | 130 |
| `ARC-75E695864C` | `list:prerender` | `Contents/mods/PsychopatzCore/42.19/media/lua/client/PsychopatzCore/UI/Components/PsychopatzVirtualizedList.lua` | 250 | 128 |
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
