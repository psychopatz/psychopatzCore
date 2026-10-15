# Radio-Shaped Mini-Computer — Device Art Production Specification v2

> **Single-system decision (2026-10-16):** The `common/media/ui/Radio/` family folders and separate per-device chassis/parts are the intended exclusive device-sprite system. Old `DTA_Walkie_*` sheets mentioned in historical v1 passages are referenced in Lua but absent from the current tracked image tree; do not author or preserve parallel fallback art. See the [harness-only modular production contract](../asset_harness/RADIO_MODULAR_ASSET_PRODUCTION.md) for the correct stage boundary and later clean-cutover requirement.


**Status:** approved direction and **pre-production contract**; no new sprites created by this documentation change. **Do not generate a final uneditable full sprite sheet first.** Produce model-local editable masters and independent layered components so the game can animate individual parts. See [interaction v2](CORE_RADIO_OS_INTERACTION_V2.md) and [milestones](CORE_RADIO_OS_INTERACTION_ROADMAP.md).

## Visual brief

**Game usability over strict hardware historicity**, but a player must instantly recognize **a radio, not a smartphone**. A fictional large usable LCD is allowed on all device families, including basic walkies; physical tactile hardware gives the device identity. Stay coherent with Project Zomboid's illustrated, subtly pixelated inventory-art aesthetic: hand-painted wear, believable plastic/metal/rubber/wood, front-facing silhouette, clear separation of controls and screen, no photorealistic/PBR sheen or modern high-tech touchscreen framing.

**Non-negotiable visual elements:**
- Strong antenna, credible speaker grille, grip/handheld chassis or proper broad HAM console, mechanical power/channel/volume elements, PTT where usable, radio/status cues.
- Enlarged monochrome LCD inside a **substantial mechanical bezel** with enough content-safe pixels for readable clickable contacts/apps, optional NPC portraits. LCD must be a genuine alpha aperture or separately cut shell mask with independently rendered dark backing, not a black-painted screen or baked status text.
- **Discoverable, permanently available Back function** on every device, preferably its own `BACK` button, otherwise a conspicuous LCD footer softkey. Also HOME/MENU, directional/focus, SELECT/OK and power; label shape/placement at smallest expected screen scale. Must be visibly clickable without hitbox debug.
- Interactive knobs and keys are not baked irreversibly into the only chassis PNG. The base panel contains the **empty seat/socket and correct occlusion/shadow** behind moving components; keyed part master supplies idle, pressed, rotation/detent and lit/unlit layers. If extraction from an existing generated concept fails, **re-author that region**.
- Each model remains distinctive. Not six recolors of one phone/radio. Preserve vanilla inspiration and confirmed item family silhouettes; fictional mini-computer controls may be added without lying about real vanilla item capabilities.

## Device references and family fidelity

These identities are **candidate item mappings** from current simulator `catalog.py`, pending actual installed Build 42 item-script, icon and game-context verification:

| Family | Candidate models | Distinct artwork goals |
|---|---|---|
| Walkie | `Base.WalkieTalkie1` Toys-R-Mine | low-grade/toy shell, simpler mold, obvious buttons and antenna; still usable LCD |
| Walkie | `Base.WalkieTalkie2` ValuTech | conspicuous yellow commercial/consumer treatment, different housing |
| Walkie | `Base.WalkieTalkie3` Premium Technologies | premium coral/red consumer-industrial shell, coherent painted plastics |
| Walkie | `Base.WalkieTalkie4` Tactical | angular green tactical grip and protective controls, distinct from Army |
| Walkie | `Base.WalkieTalkie5` US Army | olive/dark military rectangular rugged radio-computer, antenna/speaker, thumb-navigation and PTT; **first pilot** |
| Walkie | `Base.WalkieTalkieMakeShift` | improvised salvaged casing/tape/wiring, irregular mechanical controls; not a polished phone |
| HAM | `Base.HamRadio1` Premium | compact low/wide silver civilian desktop transceiver, left microphone, knobs/speaker; enlarged landscape screen |
| HAM | `Base.HamRadio2` US Army COMM | olive rectangular military tabletop chassis, left mic, speaker and tactical knobs, landscape screen |
| HAM | `Base.HamRadioMakeShift` | **strict front-facing**, exposed wooden crate/hand-built electronics/cord and metal faceplate; same style and distinct screen, no 3/4 oblique view |
| Manpack | `Base.ManPackRadio` | tall chunky olive backpack communications set with straps/handle/protectors, wide enough control panel and screen, not another tall handheld phone |

Verify exact vanilla fullTypes, portable/placed use and native permissions before runtime binding. Existing staged art under `Contents/mods/PsychopatzCore/common/media/ui/Radio/{WalkieTalkie,Ham,ManPack}` may be used as **reference/working input**, but not assumed approved, final, individually layered or native-tested. Initial simulator uses paired clean/worn concepts sliced from 627px-wide source halves with device-specific coordinates. The v2 artwork master is not restricted to that size.

## Layout architecture

Reserve visual **zones**, not one globally fixed hitbox or aspect:
- **Radio identity zone:** antenna, speaker, microphone/handset, straps or rugged housing, physically credible.
- **Primary LCD zone:** large enough for meaningful menu/readability but still visually framed by radio hardware. Screen may be landscape on HAM and manpack and portrait or near-square on walkies. Keep LCD/footer navigation visible at game UI zoom; validate with full-size and expected runtime-size preview.
- **Navigation zone:** separated BACK and HOME/MENU keys plus a D-pad/encoder and OK; sufficient finger-target size and spacing in final rendered scale.
- **Radio hardware zone:** power/volume knob, channel/scan tuning, prominent PTT and RX/TX indicators; deliberate control affordances so rotating knob/pressing button visually makes sense.

Do not accept a generated image simply because it looks stylish: test click/target clarity, minimum display legibility, side-button discoverability, proper screen cutout, visually plausible knob motion and exact mouse hotspot alignment.

## Authoring/source package (one independent model)

**2026-10-16 filesystem correction:** The canonical Project Zomboid image hierarchy is `Contents/mods/PsychopatzCore/common/media/ui/Radio/`, with existing `WalkieTalkie/`, `Ham/`, `ManPack/` and `RadioMenu/` subdirectories. Earlier `art_source/radio/devices/<family>/<model>/` and `common/media/ui/psychopatz/radio/devices/<family>/<model>/` destinations are **superseded for new radio modular PNGs**. Read [Radio Modular Asset Production — Harness Only](../asset_harness/RADIO_MODULAR_ASSET_PRODUCTION.md) for the authoritative filesystem, state separation, and scoped production/QA plan.

For example, keep `Radio/WalkieTalkie/Base.WalkieTalkie4.png` unchanged and place future reviewed modular PNGs alongside it under `Radio/WalkieTalkie/Base.WalkieTalkie4/`:

~~~text
Base.WalkieTalkie4/
  Chassis/Pristine.png             # independently reconstructed base, empty sockets
  Chassis/Worn.png                 # separate complete chassis; identical anchors
  Buttons/<control>/Idle.png
  Buttons/<control>/Pressed.png
  PTT/Idle.png
  PTT/Held.png
  Knobs/<knob>/Frame_00.png
  Switches/Power/Off.png
  Switches/Power/On.png
  LEDs/<indicator>/Off.png
  LEDs/<indicator>/On.png
  LCD/Glass.png
  LCD/BezelOverlay.png
~~~

Only author controls actually verified on each model. Store harness project JSON, editable masks, source provenance, intermediate art masters, compositing/diff QA, previews, and contact sheets in the **developer harness workspace outside** game-loading `common/media/ui`. The original single/paired concept PNG remains immutable source/reference, not automatically approved production art. Avoid duplicating full source canvases for every control frame.

**Harness-only production gate:** do not alter live game code, Lua manifests, legacy atlases, active textures, or the PZ UI. Stage and validate new modular artwork first; do not call runtime `export apply`. Actual binding/activation belongs to the separate I7+ integration work after art approval.

## Required component metadata

For each **physical part**: exact PNG/atlas path, source rect, logical id/kind, unique semantic action, device-local hit shape/rectangle, canvas x/y, pivot x/y for rotary, component z-order, available states, frame index/order/duration, optional rotation range/detents, idle/release alignment, scaled click tolerance, and cap/softkey label. The art harness measures and validates pixel data, not guessed coordinates.

For **LCD**: device-local clear alpha aperture, matte/backdrop coverage, safe content inset, clip/stencil, optional bezel/glass mask with z-order, dynamic portrait/menu/softkey areas, and available source/render scales. Dynamic text/portraits/contacts/calls/stocks/status must **never** be baked into the physical shell PNG.

For **condition**: pristine and worn (minimum pilot), optional scratch/dirt/heavy-damage overlays that preserve the same LCD/button pivots. Use single consistent transparent canvas/anchor; do not shift controls because clean/worn pictures were originally misaligned.

### Animation asset rules

- **Knobs:** sample several *actual visually distinct rotational poses* (start with 8–16 detents if art supports it) or supply a genuinely pivot-clean lossless rotatable component if PZ renderer supports it; do not rotate an attached speaker/label/switch or pretend an opaque source knob can spin. Preserve shadow and mechanical registration throughout.
- **Buttons:** at least idle/pressed registered pixel-for-pixel to socket; optionally hover/disabled; down travel visually obvious at displayed size.
- **PTT:** release/held must be a separate component, with off-screen release safe. No permanent pressed overlay.
- **LEDs:** off, steady on, optional blink/glow with separate alpha masks. Glow may overlap chassis but cannot wash out text/content or require new huge textures per frame.
- **LCD:** independent screen theme/content, light matte behind transparent shell, optional subtle scanline/refresh; no baked UI navigation decisions.

### Proposed US Army pilot acceptance sheet

Produce these as distinct inspectable outputs before active runtime substitution:

1. **Art reference and traceability**: verified `Base.WalkieTalkie5` identity and vanilla reference/approximation notes; original and approved source hashes.
2. **Flat model-front render** with obvious antenna, speaker and tactile hardware; must not resemble generic smartphone at small game UI size.
3. **Clean/pristine and worn** renders on common canvas with identical control anchors.
4. **LCD alpha/extraction debug**: exterior alpha, aperture alpha, matte backing, safe content and Back softkey/physical targets.
5. **Knob contact sheet**: at least distinct idle + multiple angular detents; no wobbling axis.
6. **Button state contact sheet**: D-pad, BACK, HOME, OK, PTT idle/down/held/up.
7. **LED preview**: power idle/on, RX, TX, unlit and animated blink.
8. **Gameplay screens**: home, contacts list, contact detail/portrait, settings, scanner and an authorized action status; contents **rendered dynamically**, not embedded in art.
9. **Real-size composite and automated report** for anticipated in-game scale and zoom, hover/click hitbox layer, clipped portrait/menu, power-off, and LCD Back accessibility.
10. **Source/visual approval checkpoint**: approve shell and interaction placement **before exporting over active production**, then native Build 42 SP/MP screenshot and profiler acceptance later.

If current paired source art is fundamentally phone-like, **recreate the shell with correct radio-computer layout rather than pixel editing for days**. If it resembles a radio but components are baked, recover reusable radio housing and redraw only controls. Decide with a source audit per model. Do not pre-generate all 10 before pilot is accepted.

## Asset-to-code synchronization gate

The **event/control schema in [interaction v2](CORE_RADIO_OS_INTERACTION_V2.md)** must be frozen/implemented at least in a simulator validator **before final asset production**. Otherwise art authors cannot know how many physical buttons, pivots and states to draw. Codex may still draft independent shell studies and button studies while implementing the controller, but cannot mark art *production ready* until the game/source contract is fulfilled. The harness CLI remains the primary path; Tk optional; no Flask requirement.

Each device can replace artwork incrementally behind fallback. Keep v1 six-walkie renderer functioning, including Hoomans and Dynamic Trading hooks, until native acceptance permits promotion. The broken PZ Headless Harness is not part of asset processing or verification.
