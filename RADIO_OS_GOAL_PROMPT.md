# Radio Device Asset Refactor — Luna/Codex /goal

**Current stage:** per-device, per-family transparent radio shell source/art architecture, covering **walkie, HAM and manpack**. This supersedes the previous walkie-atlas-only image-production assumption; the existing Core OS and shared widget atlases remain.

```text
/goal

Prepare and implement a **device-family radio shell asset architecture in PsychopatzCore**, covering individual high-resolution walkie, HAM and manpack models. This is NOT a new Radio OS, nor another Dynamic Trading UI, and it must preserve current compositor, adaptive scaling, NPC contacts, and the existing V2 trade handoff.

Read in order:
1. psychopatzCore/Docs/radio_os/CORE_RADIO_DEVICE_ASSETS.md (canonical new A0–A8 plan)
2. psychopatzCore/Docs/radio_os/CORE_RADIO_OS_COMPOSITOR_SCALE.md (current LCD layering/scaling contract)
3. psychopatzCore/Docs/radio_os/CORE_RADIO_OS_CONTRACT.md
4. DynamicTrading/Docs/radio_os/DT_RADIO_OS_AGENT_RUNBOOK.md
5. DynamicTrading/Docs/radio_os/DT_RADIO_OS_ROADMAP.md
6. DynamicTrading/Docs/radio_os/DT_RADIO_OS_PROGRESS.md

Architecture: Core owns device-model shells, art export pipeline, family-specific manifest/geometry, variant selection, generic renderer, UI widgets, apps/contacts SDK. ProjectHoomans owns NPC contacts and actual conversation. DTCommon/DTAbstract/DTHoomans own trade authorization and existing V2 commerce. No Core dependency on consumer mods.

Split physical shell art ONE MODEL PER EDITABLE SOURCE AND TRANSPARENT HIGH-RES PNG, organized under walkie, HAM, and manpack families. Do NOT stretch or bundle new model sources into one low-res 341x341 sheet. Keep the five shared UI widget atlases for LCD components, icons, buttons, signal/battery indicators and effects. No thumbnail backgrounds, baked NPC portraits, name/status text, second trading screen, non-PZ hyperrealistic rendering, or clone/recolor placeholders passed off as unique devices.

Run A0 first: audit actual installed vanilla Build 42 item IDs, graphics, two-way/portable/placed capabilities, original approved source availability and current Core skin registry limitations (256x432 and exactly 3 controls). HAM/manpack item IDs are candidate mappings until audited. Make no assumptions that placed HAM satisfies the portable two-way validator. Extend the versioned manifest with per-model native source size, full texture path, lcd aperture/backdrop/safe content rects, variable hardware control definitions, and optional variant overlays. Preserve all six existing walkie APIs/fixtures using a safe compatibility adapter.

A1–A2: add per-device folders, asset/manifest validators, alpha aperture + synthetic opaque LCD composition tests, per-model export/pixel-fidelity pipeline, optional quality LOD, texture-cache budget and rollback/fallback support. The existing renderer's LCD sandwich/zoom must work with a full independent shell texture; do not rewrite it needlessly. Ensure clean Core-only startup and DT/Hoomans regressions.

A3: **US Army Walkie Talkie first**, using a genuinely detailed, original, transparent Project Zomboid-style master (not upscaled compact art) and measured aperture/controls. Prepare a visual approval checkpoint before changing its production appearance. If original master doesn't exist and an approved replacement art source is unavailable, document blocker and continue independent safe architecture tasks; never fabricate fidelity.

A4: build the other five unique walkies one by one, with measured geometry and validations. A5: build actual vanilla HAM radio variants (civilian, military, makeshift after fullType verification), including large/differently shaped controls and optional placed-radio interaction. A6: build actual manpack model(s) with their own shell aspect and input mapping. These are mandatory family coverage, not deferred afterthoughts. A7: add optional per-model pristine/scratched/worn/damaged cosmetic overlays, deterministic item-condition selection with fallback, bounded texture caching and no new huge ModData records. A8: normal-game SP/MP visual testing of all supported models, zoom/alpha/portraits/hitboxes and no trading security regression; only then consider retiring legacy shell atlas.

This turn's scope is DOCUMENTATION FIRST. Do not silently replace production PNGs or generate arbitrary art until user-approved image assets/masters are available. Continue all safe non-art engineering unattended and prepare the US Army pilot acceptance manifest for the separate art-production step.

The **PZ Headless Harness is prohibited**: do not install, use, repair or investigate. Offline Lua/Pillow tests and actual normal Project Zomboid for native verification only. No claims of native success from mocks. Update DynamicTrading/Docs/radio_os/DT_RADIO_OS_PROGRESS.md with A milestone, exact tests, asset source provenance, Core/DT commits, blocker and next step; commit/push safely without overwriting unrelated edits, force pushes or destructive resets. Preserve old approved artwork and settings as fallback.

Begin A0 now, then A1–A2 automatically. Present the US Army pilot's image requirements and explicit art approval gate before production asset substitution; continue any independent safe stages while waiting for actual source art.
```
