# Radio OS v2 — Interaction, Hardware Animation, and Asset Delivery (I0–I9)

**Status:** approved plan, 2026-10-15; **I0 next**. This is **not** the earlier `R0–R9` radio-integration work, `H0–H9` Asset Harness implementation, `A0–A8` art production, `C0–C6` compositor fixes or `U0–U7` stabilization. Those remain dependencies and compatibility gates; do not restart completed tasks unnecessarily.

| Phase | Work / owning layer | Exit evidence |
|---|---|---|
| **I0 — NEXT** | Source audit of simulator/catalog/reducer/renderer/CLI, real RadioOS Lua manifest/navigation/hitboxes/renderer/input, existing device assets and reference vanilla items. Record Back/PTT/knob/LED gaps and what is implemented vs merely simulated. | Verified file mapping, model list, legacy compatibility matrix, art salvage-vs-redraw inventory and test baseline. No new art. |
| I1 | Freeze **semantic controller and manifest v2**: BACK/HOME/SELECT/directions/POWER/PTT/TUNE/VOLUME; per-model hitboxes, visible softkey fallback, family profiles and animation metadata. | Versioned JSON examples, strict validator, reusable Python/Lua fixture schema, v1 compatibility requirements. |
| I2 | Make navigation good **before drawing buttons**: stack/back/home, obvious LCD Back, click-to-row, keyboard and joypad parity, disabled states; no wrong channel-key overloading. | Simulator tests: contact detail -> list -> home -> close, custom app Back, settings value focus, no trapped state. |
| I3 | Gesture lifecycle and control reducer: pointer down/move/up/cancel, knob wheel/drag/detent, PTT hold with release on focus loss, no double dispatch. | Deterministic JSON scenario tests including outside-release and invalid inputs. |
| I4 | Generic animation component system: registered pivots, indexed knob frames, mechanical keys, PTT, LEDs and screen transitions with conditional clocks, cached resources. | CLI rendered frame/contact sheets and strict frame/anchor tests; no per-device animation code forks. |
| **I5 — ASSET PREP** | Extend existing `tools/asset_harness/` project/output schema and safe export for v2 component metadata, alpha masks, registered sprites, separate clean/worn pivots; audit current staged art. | Real actual-source/geometry audit, alpha/hitbox/knob validation and an **asset authoring template ready** for one device. |
| **I6 — FIRST ART** | Build a **distinct radio-shaped US Army walkie** front shell, real LCD aperture, BACK/HOME/OK, navigation, volume/channel rotary, PTT, LEDs and wear layers; avoid phone silhouette. | Reviewable per-component PNGs and full-res in-scale composites, contact sheets, provenance/approval, no production replacement before gate. |
| I7 | Integrate I1–I6 contract into Core's **actual Lua Radio OS**, while preserving v1 atlas fallback and unchanged provider authorization. | Real Lua tests for input/navigation and compositor; device skin v2 roundtrip; documented normal-game SP acceptance status. |
| I8 | Convert all remaining **five** distinct walkies, all **three** distinct HAM models and manpack using v2 manifest, family-specific aspect/control groups, shared OS/app logic. | Per-model provenance, geometry and animation state contact sheets; genuine silhouette distinctions. No unreviewed mass-recolors. |
| I9 | Hardening and normal-game acceptance: scale/zoom, mouse/wheel/keyboard/joypad, screen-reader clarity insofar supported, performance/profiler, paused/lost-focus PTT, hosted/dedicated MP and Hoomans/DT integrations. | Source/offline/image/native SP/native MP/profiler evidence separately; no unverified native pass. |

**Pragmatic schedule:** Run I0/I1 first, immediately produce I5's art template and test pilot while I2–I4 advance in parallel **only when contracts are stable**. The user wants to **make assets next**; don't waste effort rebuilding Flask/Tk or generating all models. At I6 show US Army pilot asset parts & render states; iterate on appearance before repeating families. I7 production export waits for approval and compatibility verification, but safe art/tool/fixture work can continue unattended.

## Execution and safety

- Core owns all new interaction/controller/asset code. No duplicated OS in DynamicTrading or Hoomans; provider APIs remain separate.
- `tools/asset_harness/` already has CLI, Pillow core, optional GUI and offline simulator; extend it, do not invent a new scaffold. CLI and screenshots must be usable by an LLM with image vision alone.
- Use real source+RGB/alpha comparisons and independent control-layer rendering; don't declare phone-like art fixed by renaming the sprite. Correct screens in situ with dynamic content/alpha matte, preserve CRT/monochrome PZ-era look.
- Stay within `common/media/ui` for *runtime* PNGs. Editable source/project and previews outside runtime image dir. Preserve legacy assets until proven safe to remove.
- Test unit, integration, CLI and Lua smoke before committing; have explicit visual and native gates. Pause only for a real missing art input/visual acceptance or unsafe production overwrite; otherwise continue scoped engineering.
- Update [I progress ledger](CORE_RADIO_OS_INTERACTION_PROGRESS.md) after every phase; record changes, commands, failures, SHA/branch and next step. No force pushes, destructive resets, game save edits, or broken PZ Headless Harness.
