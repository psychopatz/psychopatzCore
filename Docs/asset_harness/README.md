# Psychopatz Asset Harness

> **ACTIVE FIRST READ (2026-10-16):** [Radio Visual Harness Recovery](RADIO_VISUAL_HARNESS_RECOVERY.md) — fix the simulator and input calibration so it shows the authored modular W5; then publish inspected actual PNGs to the existing Project Zomboid `common/media/ui/Radio/` directories and repeat for **all ten devices**. Earlier W5 mask/diff pilot tasks are historical. JSON and test artifacts are supportive, never substitutes for images. See [current `/goal`](../../RADIO_MODULAR_ASSET_GOAL_PROMPT.md).


> **Radio modular-asset goal (2026-10-16):** Read [RADIO_MODULAR_ASSET_PRODUCTION.md](RADIO_MODULAR_ASSET_PRODUCTION.md) first. The active radio-art scope extends the implemented Asset Harness, uses the canonical `Contents/mods/PsychopatzCore/common/media/ui/Radio/` filesystem, stores `Chassis/Pristine.png` and `Chassis/Worn.png` separately, and must **not** change runtime code or activate new skins. The older scaffold H0–H9 and Radio OS I0–I9 text remains historical/next-stage context, not a command to rebuild or edit game Lua.


> **Implementation handoff (2026-10-15):** Existing agent CLI, Pillow image pipeline, optional GUI and radio simulator are now present in `tools/asset_harness/`. The NEXT work for radio hardware, navigation/Back and editable animated control sprites is covered by [Radio Interaction v2](../radio_os/CORE_RADIO_OS_INTERACTION_V2.md), [Device Art Spec](../radio_os/CORE_RADIO_OS_DEVICE_ART_SPEC_V2.md) and [I0–I9 roadmap](../radio_os/CORE_RADIO_OS_INTERACTION_ROADMAP.md). Do not treat the older H0–H9 scaffold milestones as unimplemented; this new track **extends** the tool and live game controllers, with asset-first pilot after schema freeze.


**Agent-first developer tooling for PsychopatzCore.** The offline Python/Pillow CLI, partial modular compositor and Tk radio simulator are implemented, but at the 2026-10-16 checkpoint the **GUI is NOT yet connected to the new W5 modular artwork** and interactive geometry is visibly inaccurate. The active task is to fix this with real PNG previews and correct inputs, not to add more metadata-only tests.

Read in order:
1. [Agent runbook](ASSET_HARNESS_AGENT_RUNBOOK.md)
2. [Architecture contract](ASSET_HARNESS_CONTRACT.md)
3. [H0–H9 roadmap](ASSET_HARNESS_ROADMAP.md)
4. [Progress ledger](ASSET_HARNESS_PROGRESS.md)
5. [Pasteable Codex /goal](../../ASSET_HARNESS_GOAL_PROMPT.md)

Prior radio production direction remains in [CORE_RADIO_DEVICE_ASSETS.md](../radio_os/CORE_RADIO_DEVICE_ASSETS.md). The broken PZ Headless Harness must not be used. Native Build 42 game verification remains a separate requirement.
