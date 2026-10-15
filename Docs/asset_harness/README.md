# Psychopatz Asset Harness

> **Implementation handoff (2026-10-15):** Existing agent CLI, Pillow image pipeline, optional GUI and radio simulator are now present in `tools/asset_harness/`. The NEXT work for radio hardware, navigation/Back and editable animated control sprites is covered by [Radio Interaction v2](../radio_os/CORE_RADIO_OS_INTERACTION_V2.md), [Device Art Spec](../radio_os/CORE_RADIO_OS_DEVICE_ART_SPEC_V2.md) and [I0–I9 roadmap](../radio_os/CORE_RADIO_OS_INTERACTION_ROADMAP.md). Do not treat the older H0–H9 scaffold milestones as unimplemented; this new track **extends** the tool and live game controllers, with asset-first pilot after schema freeze.


**Agent-first developer tooling for PsychopatzCore.** The primary interface is a deterministic Python CLI with bounded JSON and lossless PNG artifacts, not a Flask UI. **Planned**, not implemented in this documentation commit.

Read in order:
1. [Agent runbook](ASSET_HARNESS_AGENT_RUNBOOK.md)
2. [Architecture contract](ASSET_HARNESS_CONTRACT.md)
3. [H0–H9 roadmap](ASSET_HARNESS_ROADMAP.md)
4. [Progress ledger](ASSET_HARNESS_PROGRESS.md)
5. [Pasteable Codex /goal](../../ASSET_HARNESS_GOAL_PROMPT.md)

Prior radio production direction remains in [CORE_RADIO_DEVICE_ASSETS.md](../radio_os/CORE_RADIO_DEVICE_ASSETS.md). The broken PZ Headless Harness must not be used. Native Build 42 game verification remains a separate requirement.
