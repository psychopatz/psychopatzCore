# Architecture Audit

Analyzer version: `2.0.0`  
Scoring scope: `production`

> Static analysis is triage evidence, not permission to refactor. Low coverage means inspect the source; preserve behavior and choose the smallest coherent ownership/boundary change.

## Project summary

| Metric | Value |
|---|---:|
| Production Health | 73.1/100 |
| Coverage | 76.6% |
| Confidence | 62.9% |
| Max Refactor Pressure | 100.0/100 |
| Production files | 118 |
| Tests indexed | 51 |
| Tooling files indexed | 12 |
| Generated files indexed | 0 |
| Production LOC scored | 15309 |
| Logical subsystems | 19 |
| Production findings | 31 |
| Test findings | 3 |

## Subsystems by refactor pressure

| Subsystem | Pressure | Health | Coverage | Confidence | Files | LOC | Findings | Fan-in | Fan-out |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| (composition) | 100.0 | 61.1/100 | 78.5% | 63.8% | 3 | 50 | 7 | 7 | 11 |
| UI | 90.9 | 58.3/100 | 76.1% | 63.6% | 37 | 6262 | 9 | 2 | 6 |
| Profiler | 67.2 | 63.2/100 | 77.9% | 63.0% | 11 | 1368 | 4 | 3 | 1 |
| Bridge | 66.7 | 62.9/100 | 81.5% | 68.4% | 7 | 837 | 5 | 1 | 1 |
| Inventory | 24.9 | 86.2/100 | 81.5% | 68.2% | 22 | 2620 | 2 | 3 | 2 |
| Debug | 20.1 | 87.5/100 | 73.2% | 59.3% | 6 | 664 | 1 | 1 | 4 |
| World | 18.9 | 87.5/100 | 78.5% | 63.8% | 5 | 853 | 1 | 3 | 1 |
| Radio | 18.3 | 87.5/100 | 75.9% | 61.5% | 10 | 690 | 1 | 2 | 1 |
| Traits | 17.5 | 87.5/100 | 67.0% | 54.1% | 2 | 290 | 1 | 1 | 1 |
| WorldLoot | 2.6 | 100.0/100 | 78.5% | 58.9% | 4 | 674 | 0 | 0 | 3 |
| Runtime | 1.8 | 100.0/100 | 54.6% | 41.0% | 1 | 22 | 0 | 3 | 0 |
| Journal | 1.5 | 100.0/100 | 78.5% | 58.9% | 1 | 165 | 0 | 1 | 1 |
| Composition | 1.4 | 100.0/100 | 78.5% | 58.9% | 2 | 60 | 0 | 1 | 1 |
| Collections | 1.2 | 100.0/100 | 54.6% | 41.0% | 1 | 77 | 0 | 2 | 0 |
| Settings | 0.7 | 100.0/100 | 57.7% | 43.3% | 1 | 175 | 0 | 1 | 0 |
| Conversation | 0.6 | 100.0/100 | 57.7% | 43.3% | 1 | 132 | 0 | 1 | 0 |
| Events | 0.6 | 100.0/100 | 54.6% | 41.0% | 1 | 73 | 0 | 1 | 0 |
| EventMarkers | 0.1 | 100.0/100 | 67.0% | 50.2% | 2 | 248 | 0 | 0 | 0 |
| Compatibility | 0.0 | 100.0/100 | 54.6% | 41.0% | 1 | 49 | 0 | 0 | 0 |

## Finding counts

| Scope | Rule | Severity | Count |
|---|---|---|---:|
| production | `DEPENDENCY_CYCLE` | HIGH | 23 |
| production | `LARGE_FUNCTION` | MEDIUM | 3 |
| production | `CORE_DOMAIN_DEPENDENCY` | HIGH | 2 |
| production | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | 1 |
| production | `HOT_PATH_EVENT_RISK` | LOW | 1 |
| production | `UNBOUNDED_LOOP` | MEDIUM | 1 |
| test | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | 3 |

## Finding index

Query evidence with `architecture_audit finding <repo> <finding-id> --context 4` before changing code.

| ID | Rule | Severity | Confidence | Subsystem | Summary |
|---|---|---|---:|---|---|
| `ARC-0F810F33AE` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-1122EEE06C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-31A3BFC106` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-31AC3CCD0E` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Debug | Subsystem participates in dependency cycle: (composition) -> Debug -> (composition) |
| `ARC-31FCAA11BA` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> World -> (composition) |
| `ARC-32B6217274` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Traits | Subsystem participates in dependency cycle: (composition) -> Traits -> (composition) |
| `ARC-4042CC1726` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Inventory -> (composition) |
| `ARC-489CE9E09A` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> World -> (composition) |
| `ARC-49776FB727` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | UI | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Inventory -> (composition) |
| `ARC-7377F6C7AB` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> World -> (composition) |
| `ARC-97D6DBE18B` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-987F8DD48A` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-B6061F51AB` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Debug -> (composition) |
| `ARC-BF0BF65AE2` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Inventory -> (composition) |
| `ARC-C4385CEF6C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-C8D6A0C27C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | World | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> World -> (composition) |
| `ARC-D0DD51A551` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Bridge | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-D24E3A5A50` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Traits -> (composition) |
| `ARC-D45A77F521` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | (composition) | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> (composition) |
| `ARC-D7E5116A5C` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Inventory -> (composition) |
| `ARC-E102AD2509` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Profiler | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> World -> (composition) |
| `ARC-EB88AB55EF` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Radio | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Radio -> (composition) |
| `ARC-FD4B9FE2A7` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Inventory | Subsystem participates in dependency cycle: (composition) -> Bridge -> Profiler -> UI -> Inventory -> (composition) |
| `ARC-774F8058C3` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/PsychopatzConversationSettings.lua depends on non-core files. |
| `ARC-7DDDF08E0D` | `CORE_DOMAIN_DEPENDENCY` | HIGH | MEDIUM (70%) | UI | Core/shared-looking file Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPortrait.lua depends on non-core files. |
| `ARC-9830D6DAC6` | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | HIGH (82%) | (composition) | Contents/mods/PsychopatzCore/42.19/media/lua/shared/PsychopatzCore/00_PsychopatzCore_Init.lua directly depends on 10 foreign subsystems. |
| `ARC-FF522A2B89` | `UNBOUNDED_LOOP` | MEDIUM | HIGH (92%) | Inventory | Potential unbounded loop in Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Inventory/PsychopatzInventory.lua. |
| `ARC-5254ECB8CD` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | PsychopatzConversationChat:render spans 131 lines. |
| `ARC-712263E72E` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | PsychopatzConversationView:createChildren spans 151 lines. |
| `ARC-C018F94A63` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | UI | PsychopatzConversationChoices:render spans 125 lines. |
| `ARC-E74551A113` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Bridge | Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Bridge/PsychopatzBridge.lua publishes events and contains a recurring hot-path signal. |
| `ARC-113762D8E2` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | Inventory | Repeated test setup appears across 3 tests (~24 repeated LOC). |
| `ARC-AEB6A8D6C6` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (77%) | Profiler | Repeated test setup appears across 6 tests (~102 repeated LOC). |
| `ARC-C8BC7BC6DE` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | HIGH (95%) | tests | Repeated test setup appears across 22 tests (~276 repeated LOC). |

## Largest maintained modules

Generated artifacts and tooling are indexed but excluded from this table and production scoring.

| ID | File | Code LOC |
|---|---|---:|

## Largest functions

| ID | Function | File | Start | LOC |
|---|---|---|---:|---:|
| `ARC-712263E72E` | `PsychopatzConversationView:createChildren` | `Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/PsychopatzConversationView.lua` | 31 | 151 |
| `ARC-5254ECB8CD` | `PsychopatzConversationChat:render` | `Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChat.lua` | 108 | 131 |
| `ARC-C018F94A63` | `PsychopatzConversationChoices:render` | `Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChoices.lua` | 91 | 125 |

## Recommended workflow

1. Select a high-pressure subsystem with adequate coverage.
2. Inspect grouped findings and individual evidence.
3. Read the smallest relevant production slice and establish ownership/contracts.
4. Save a baseline and refactor one coherent vertical slice.
5. Query affected tests, run them, rescan, and compare the baseline.
