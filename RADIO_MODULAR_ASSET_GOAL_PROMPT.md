# Codex /goal — Harness-Only Modular Radio Assets

This is the short entry point. **Detailed scope and acceptance tests are in** [Docs/asset_harness/RADIO_MODULAR_ASSET_PRODUCTION.md](Docs/asset_harness/RADIO_MODULAR_ASSET_PRODUCTION.md).

~~~text
/goal

In psychopatz/psychopatzCore, implement the harness-only modular radio asset production work defined in Docs/asset_harness/RADIO_MODULAR_ASSET_PRODUCTION.md (AH-R0 through AH-R6).

Read that document FIRST, then the current Asset Harness runbook/contract/progress, Radio OS art spec and interaction v2. Re-audit actual HEAD, worktree, real PNG sources and existing harness implementation before modifying anything. Extend the existing CLI/Pillow compositor/simulator; do not rebuild the harness or start old H0–H9 phases.

The canonical Project Zomboid radio image filesystem is Contents/mods/PsychopatzCore/common/media/ui/Radio/ (WalkieTalkie, Ham, ManPack, RadioMenu). Each model needs independently verified, modular components and separate Chassis/Pristine.png and Chassis/Worn.png files. Keep originals immutable. Use exact masks, correct empty sockets, real component state artwork and per-device reconstruction/alpha/diff QA; reject guessed rectangles and fake shift/darken states.

STRICT SCOPE: improve only tools/asset_harness/, focused tests, harness docs/progress, staged art and newly reviewed modular PNGs under the existing Radio family folders. DO NOT edit mod Lua, gameplay code, runtime renderer/manifests, old textures/atlases, other mods, game saves or the PZ Headless Harness. DO NOT invoke production export apply.

Work unattended through safe testable checkpoints. Start with the known WalkieTalkie4 cropping regression, then the official US Army WalkieTalkie5 pilot and remaining individual devices. Emit bounded JSON CLI evidence, image previews/contact sheets, alpha/geometry/diff diagnostics, provenance and clear verified/blocked statuses. Never call unreviewed art production-ready; report real manual-art blockers without stopping independent harness work. Commit only scoped verified changes safely; keep an append-only progress ledger and report changed paths/tests/commits.
~~~
