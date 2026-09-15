# Architecture Audit

Analyzer version: `2.0.0`  
Scoring scope: `production`

> Static analysis is triage evidence, not permission to refactor. Low coverage means inspect the source; preserve behavior and choose the smallest coherent ownership/boundary change.

## Project summary

| Metric | Value |
|---|---:|
| Production Health | 80.3/100 |
| Coverage | 63.8% |
| Confidence | 53.5% |
| Max Refactor Pressure | 35.7/100 |
| Production files | 161 |
| Tests indexed | 81 |
| Tooling files indexed | 45 |
| Generated files indexed | 0 |
| Production LOC scored | 27740 |
| Logical subsystems | 2 |
| Production findings | 13 |
| Test findings | 3 |

## Subsystems by refactor pressure

| Subsystem | Pressure | Health | Coverage | Confidence | Files | LOC | Findings | Fan-in | Fan-out |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| PsychopatzCore | 35.7 | 80.3/100 | 63.8% | 53.5% | 160 | 27739 | 13 | 1 | 0 |
| (root) | 0.8 | 100.0/100 | 66.6% | 50.0% | 1 | 1 | 0 | 0 | 1 |

## Finding counts

| Scope | Rule | Severity | Count |
|---|---|---|---:|
| production | `LARGE_FUNCTION` | MEDIUM | 9 |
| production | `HOT_PATH_EVENT_RISK` | LOW | 2 |
| production | `UNBOUNDED_LOOP` | MEDIUM | 2 |
| test | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | 3 |

## Finding index

Query evidence with `architecture_audit finding <repo> <finding-id> --context 4` before changing code.

| ID | Rule | Severity | Confidence | Subsystem | Summary |
|---|---|---|---:|---|---|
| `ARC-42F416692C` | `UNBOUNDED_LOOP` | MEDIUM | HIGH (92%) | PsychopatzCore | Potential unbounded loop in Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Inventory/PsychopatzInventory.lua. |
| `ARC-A3CD4D40BB` | `UNBOUNDED_LOOP` | MEDIUM | HIGH (92%) | PsychopatzCore | Potential unbounded loop in Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/World/PsychopatzSquareRules.lua. |
| `ARC-0B8EC2A28E` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | PsychopatzCore | PsychopatzConversationView:createChildren spans 151 lines. |
| `ARC-2C0AD8E977` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | PsychopatzCore | PsychopatzConversationChat:render spans 124 lines. |
| `ARC-60CA0E0BEE` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | PsychopatzCore | list:prerender spans 128 lines. |
| `ARC-96D979BE48` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | PsychopatzCore | Model.Build spans 219 lines. |
| `ARC-A74A63EE0B` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | PsychopatzCore | parser spans 144 lines. |
| `ARC-ADC2F4DD5F` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | PsychopatzCore | VirtualizedList.Install spans 251 lines. |
| `ARC-C2062E3947` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | PsychopatzCore | PsychopatzConversationChoices:render spans 125 lines. |
| `ARC-C953AD29DF` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | PsychopatzCore | ISPsychopatzCommandHubSettingsWindow:createChildren spans 127 lines. |
| `ARC-DB187C8B3F` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | PsychopatzCore | Internal.HandleClientCommand spans 122 lines. |
| `ARC-43A17EA6D0` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | PsychopatzCore | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Voice/PsychopatzVoiceGateway.lua publishes events and contains a recurring hot-path signal. |
| `ARC-E37DE3497D` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | PsychopatzCore | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Bridge/PsychopatzBridge.lua publishes events and contains a recurring hot-path signal. |
| `ARC-3C61FE751F` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (95%) | PsychopatzCore | Repeated test setup appears across 19 tests (~264 repeated LOC). |
| `ARC-4BD2C13DA1` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | tools | Repeated test setup appears across 3 tests (~12 repeated LOC). |
| `ARC-4E0EE034B0` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (95%) | tests | Repeated test setup appears across 32 tests (~378 repeated LOC). |

## Largest maintained modules

Generated artifacts and tooling are indexed but excluded from this table and production scoring.

| ID | File | Code LOC |
|---|---|---:|

## Largest functions

| ID | Function | File | Start | LOC |
|---|---|---|---:|---:|
| `ARC-ADC2F4DD5F` | `VirtualizedList.Install` | `Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/Components/PsychopatzVirtualizedList.lua` | 130 | 251 |
| `ARC-96D979BE48` | `Model.Build` | `Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/Inventory/PsychopatzInventoryTooltipModel.lua` | 210 | 219 |
| `ARC-0B8EC2A28E` | `PsychopatzConversationView:createChildren` | `Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/PsychopatzConversationView.lua` | 31 | 151 |
| `ARC-A74A63EE0B` | `parser` | `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Serialization/PsychopatzJson.lua` | 111 | 144 |
| `ARC-60CA0E0BEE` | `list:prerender` | `Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/Components/PsychopatzVirtualizedList.lua` | 250 | 128 |
| `ARC-C953AD29DF` | `ISPsychopatzCommandHubSettingsWindow:createChildren` | `Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/PsychopatzCommandHubSettingsWindow.lua` | 73 | 127 |
| `ARC-C2062E3947` | `PsychopatzConversationChoices:render` | `Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChoices.lua` | 111 | 125 |
| `ARC-2C0AD8E977` | `PsychopatzConversationChat:render` | `Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChat.lua` | 135 | 124 |
| `ARC-DB187C8B3F` | `Internal.HandleClientCommand` | `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector_Transport.lua` | 75 | 122 |

## Recommended workflow

1. Select a high-pressure subsystem with adequate coverage.
2. Inspect grouped findings and individual evidence.
3. Read the smallest relevant production slice and establish ownership/contracts.
4. Save a baseline and refactor one coherent vertical slice.
5. Query affected tests, run them, rescan, and compare the baseline.
