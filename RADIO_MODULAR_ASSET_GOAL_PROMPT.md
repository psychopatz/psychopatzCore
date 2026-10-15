# Codex /goal — Fix the Visual Harness, Then Deliver PZ Radio PNGs

**Authoritative execution contract:** [Docs/asset_harness/RADIO_VISUAL_HARNESS_RECOVERY.md](Docs/asset_harness/RADIO_VISUAL_HARNESS_RECOVERY.md), followed by [Docs/asset_harness/RADIO_MODULAR_ASSET_PRODUCTION.md](Docs/asset_harness/RADIO_MODULAR_ASSET_PRODUCTION.md) for fidelity and all ten devices.

~~~text
/goal

CONTINUE the PsychopatzCore radio Asset Harness work at current HEAD. Read Docs/asset_harness/RADIO_VISUAL_HARNESS_RECOVERY.md FIRST (VH1–VH4), then the production contract and current progress ledger. Do NOT redo AH-R0–R4, the already-authored W5 masks/art scripts, source/hash inventories or generic JSON audits.

THIS IS A PROJECT ZOMBOID SPRITE TASK. The primary result is REAL, VIEWABLE, INTERACTIVE modular PNG sprites, not JSON/test outputs. W5 candidate art already exists (c272542, 5523220); use and fix it instead of generating more disconnected scripts.

FIRST fix ./run.sh GUI / simulator_gui.py to load walkie_5_pilot.json and its actual modular layer PNGs, with explicit Source vs Modular WIP mode, portable paths, reload, independent pristine/worn chassis and correct physical LCD placement. Fix W5 hitboxes from project coordinates instead of the old shared catalog geometry. Wire mouse down/up/cancel, rotary wheel/drag, held PTT, and LEDs using the existing reducer. Visually inspect the GUI and matched CLI render; don't report VH1 or VH2 passed until the new hardware actually appears, aligns and responds.

THEN visually correct W5 button states, socket fills, LCD and worn chassis using the SAME harness authoring+rendering pipeline. After inspection, publish/commit the ACTUAL new chassis and component PNG files under Contents/mods/PsychopatzCore/common/media/ui/Radio/WalkieTalkie/Base.WalkieTalkie5/ using relative portable references. Keep any unapproved art labeled proposed; don't overwrite Base.WalkieTalkie5.png. Don't leave final PNG layers available only inside gitignored tools/asset_harness/workspace/.

THEN proceed unattended, one model at a time, to all other five walkies, three HAM and one ManPack, with independent Chassis/Pristine.png, Chassis/Worn.png, accurately masked components and calibrated harness previews for EACH. W5 is a gate, not goal completion.

QUOTA RULE: Each milestone must demonstrate an actual changed GUI interaction or visually examined PNG, relevant path, and exact reproduction command. Do focused image/GUI tests; save full suites for integration boundaries. Do not add more hash-only commits, blocker-only JSON, synthetic-only milestones, audit reports or device-specific extraction scripts where shared harness functionality suffices. If a specific art region is impossible, show the attempted close-up and continue independent tasks, rather than blocking the entire goal.

STRICT SCOPE: Asset Harness, focused tests/docs/projects, preview files and NEW modular PNGs in the canonical PZ Radio folder only. NO game/mod runtime Lua, original single-canvas sprite overwrite, game save change, rebuilding old DTA atlas, production export apply, or PZ Headless Harness. In-game Lua renderer wiring will be a separate clean cutover.

Work in verified VH1 -> VH2 -> VH3 -> VH4 checkpoints. Record concise visual evidence, screenshot/image paths, changes, tests and commit SHA in the progress ledger; don't claim graphical validation you didn't inspect. Start by fixing the modular GUI integration now.
~~~
