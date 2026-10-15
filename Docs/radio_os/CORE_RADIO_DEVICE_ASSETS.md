# PsychopatzCore Radio Device Skin Architecture — Per-Device High-Fidelity Assets

> **Interaction and art-production refinement (2026-10-15):** User chose the **gameplay-first radio-shaped mini-computer**, not a strict radio-only interface or smartphone. See [Interaction v2](CORE_RADIO_OS_INTERACTION_V2.md) and [Device Art Spec v2](CORE_RADIO_OS_DEVICE_ART_SPEC_V2.md) before producing or approving any new model. Each actual radio must have a generous clickable LCD **and** recognizable tactile radio hardware, a discoverable BACK/HOME/OK path, and separately animated knobs/PTT/LEDs. The A0–A8 fidelity/family/provenance requirements below remain, but a static flattened shell or phone silhouette no longer passes A3–A8 acceptance. New I0–I9 interaction milestones are documented [here](CORE_RADIO_OS_INTERACTION_ROADMAP.md). **No production art was changed by this notice.**


**Status:** approved architectural direction / implementation and art-production plan, updated 2026-10-15. **No new shell art is included by this documentation change.** Canonical source of truth for the next asset overhaul. Existing Core Radio OS, six legacy walkie shells, shared widget atlases, LCD compositor, adaptive zoom, Hoomans contacts, and Dynamic Trading integrations must remain functional during migration.

## Decision

**Do not package all device shell art into one low-resolution walkie source/atlas.** Each real device model gets an independently editable, transparent high-resolution shell package and a versioned manifest. Walkie, HAM, and manpack are **all in scope**. Core continues to own one mod-agnostic Radio OS, renderer, shared UI assets, contact/app registry, dynamic portraits and scaling. This is an asset-authoring/packaging separation, **not** three OS implementations.

A unified atlas is not intrinsically low-quality. The **specific current pipeline** suffered source-fidelity loss: it generated a 1024×1024 shell atlas by enlarging an already reduced 341×341 six-device source. The separate-model architecture removes that source bottleneck, improves maintainability and allows condition variants. Do not mislabel legacy upscale or pixel-scaling changes as newly authored detail.

**Never bake** NPC portraits/names, faction data, frequency, status text, item condition percentages, app UIs, trader stocks, fake LCD contents or multiple shop screens into a physical shell texture. These are live content handled by the reusable OS.

## Actual audited starting point

At planning audit, PsychopatzCore main HEAD `13d8aefbd23b17b41cac5f5e7cebe48a5e61626e`:
- `.../UI/Radio/OS/PsychopatzRadioManifest.lua` is walkie-only, with `M.family="walkie"`, 256×432 shell cells, shared `sheets.shells`, `skin.sprite` and uniform **three** `controls.left/center/right` registrations.
- `PsychopatzRadioOSDevice.lua` exposes `RegisterDeviceSkin`/ `GetDeviceSkin`, but `validateSkin` currently requires `sprite`, `screen` and **all three** rectangular controls. This is too rigid for HAM/manpack consoles; preserve old API while extending validation and input dispatch to variable control layouts.
- `PsychopatzRadioOSWindow_Renderer.lua` already performs LCD matte/background + content + effects + front shell composition with pixel-snapped geometry. There is a recorded six-walkie alpha aperture audit and isolated atlas UV gutters. **Do not rebuild compositor from scratch**; generalize texture resolution and geometry per skin.
- `RadioDeviceState` currently validates **portable, two-way, powered, audible, unmuted** radios. A stationary HAM radio may not pass portable validation: visual UI availability and actual transmission/trade permission are **different** gates. Inspect base-game item script/DeviceData and world-vs-inventory interaction methods for each HAM/manpack model before making promises.
- Source PNGs/manifest, builder scripts and full Core radio tests exist. Normal-game native acceptance is still pending. Historical DTAbstract asset copies are not production owners.

Reinspect HEAD, mods, device IDs, sprite artwork and normal-game API before implementing.

## Family and model inventory (item IDs are candidates until audited against the installed Build 42 scripts)

| Family | Current planned models | Core source status |
|---|---|---|
| Walkie | `Base.WalkieTalkie1`, `2`, `3`, `4`, `5`, `Base.WalkieTalkieMakeShift` | Six legacy PNG cells exist; **no approved individual high-detail shell source** in the audited repos |
| HAM | `Base.HamRadio1`, `Base.HamRadio2`, `Base.HamRadioMakeShift` | **No production shell assets yet**; verify fullTypes, portable/placed variants and controls |
| Manpack | `Base.ManPackRadio` | **No production shell asset yet**; verify exact case-sensitive fullType and in-world/portable usage |
| Receive-only / vehicle / future | Not part of this asset completion gate | Registerable later; don't pretend receive-only supports two-way calls or remote trade |

**Do not assume** list entry is valid or two-way/transmitting merely because a texture exists. Record verified vanilla `fullType`, capability flags, actual item sprite/icon and use context for each device in the A0 inventory. No HAM/manpack designs can be marked complete before their authentic device-specific artwork and measured geometry exist.

## File ownership and proposed structure

Keep the original authoring masters separate from game-runtime exports. Paths below are **proposals**, not already existing files:

```text
PsychopatzCore/
  Docs/radio_os/
    CORE_RADIO_DEVICE_ASSETS.md              <- this contract
  tools/radio_os/
    devices/                                 <- manifests or authoring metadata
    build_device_shells.py                   <- reproducible per-model export
    audit_device_assets.py                   <- per-skin alpha/dimensions/coverage
  Contents/mods/PsychopatzCore/common/media/
    ui/psychopatz/radio/
      common/
        UI_Core.png
        Buttons.png
        Icons.png
        Indicators.png
        Overlays.png
      devices/
        walkie/
          us_army/
            shell_front.png
            wear_light.png                  <- only if actually authored
            wear_heavy.png
          toys_r_mine/
          valutech/
          premium/
          tactical/
          makeshift/
        ham/
          civilian/
          military/
          makeshift/
        manpack/
          army/
    lua/client/PsychopatzCore/UI/Radio/OS/
      PsychopatzRadioDeviceSkins.lua           <- registry/schema module
      Skins/                                  <- per-model registered definitions
```

Current `DTA_Walkie_UI_Core.png`, `DTA_Walkie_Buttons.png`, `DTA_Walkie_Icons.png`, `DTA_Walkie_Indicators.png`, `DTA_Walkie_Overlays.png` **remain shared and functional** during migration. Do not duplicate them for every model or break existing texture paths; optional renaming only after compatibility testing.

Authoring masters may live in a dedicated `art_source/radio/devices/<family>/<model>/` folder with layered masters/source attribution/exports. They are not necessarily all copied to the game runtime. No font files should be distributed.

## Per-model high-resolution art specification

- Each model: separate **straight-alpha RGBA PNG** with untouched transparent exterior, complete device silhouette and any antenna/knobs within its own canvas. No labels, thumbnails, decorative pedestal, background or checkerboard baked behind the radio. No invented hyperrealistic/metallic PBR appearance; use coherent Project Zomboid-like illustrated pixel-art styling informed by actual device items/icons.
- **No 341×341 intermediate reduction**. Build runtime textures directly from a verified high-resolution authoring master; a model should have enough true source detail for the configured maximum on-screen zoom. A larger PNG made by upscaling the compact legacy source is not a fidelity improvement.
- Device families can have different aspect ratios, natural base sizes and control counts. Never force HAM/manpack into walkie's 256×432 grid. A resolution such as 512×864 for a walkie is an **illustrative base only**, not a universal exported size; decide per model from actual source and target maximum display pixels. If high zoom requires higher resolution, consider an authored high-DPI export or LOD from that master, not a fake upscale.
- Asset IDs, names and exported dimensions must be stable, versioned, and verified by tests. Pixel art may require explicit point filtering; verify actual B42 subtexture/full texture sampling rather than globally changing vanilla filtering. Prevent alpha fringes, straight/premultiplied blending mismatches and texture bleeding.
- Shell composition: matte/opaque LCD backing, optional genuine themed LCD background, clipped dynamic app/portrait, optional effects, **shell front including authored physical wear**, hardware highlights. Art that covers the LCD/glass must be a distinct optional glass overlay and respect content clipping; scratches on chassis must not cover interactive content or fill the clear window.
- Cutout must be **truly alpha-zero** across the entire designated visible screen aperture. Store a separate, slightly inset content safe rect. Do not fill all alpha-zero pixels indiscriminately: outer body and antenna gaps remain transparent.
- Use simple consistent visual cues and condition wear aligned to item art; never put item/game status as static image text. Buttons can remain physically on the shell, with independent clickable hit regions and dynamic highlighted states.
- Do not automatically create fake LCDs or second merchant/trading panels just to fit an app. If a vanilla HAM model's interface is analog, propose a plausible **single** integrated communication display or OS attachment for review, rather than asserting a base-game feature. Keep trader basket in the existing V2 UI.

## Device skin schema v2 — proposed (do not call implemented)

```lua
-- Pseudocode / declarative contract, not immediately usable code
{
  id = "psychopatz:walkie_usarmy",
  family = "walkie",
  fullType = "Base.WalkieTalkie5",
  artwork = {
    sourceSize = { w = 768, h = 1296 }, -- example only
    shell = "media/ui/psychopatz/radio/devices/walkie/us_army/shell_front.png",
    variants = {
      pristine = nil, -- implicit clean baseline
      scratched = "media/ui/psychopatz/radio/devices/walkie/us_army/wear_light.png",
      worn = "media/ui/psychopatz/radio/devices/walkie/us_army/wear_heavy.png",
    }
  },
  lcd = {
    aperture = { x = 290, y = 702, w = 250, h = 240 },
    backing = { x = 290, y = 702, w = 250, h = 240 },
    content = { x = 314, y = 737, w = 205, h = 160 },
  },
  controls = {
    { id="back", rect={x=210,y=965,w=90,h=70}, action="back" },
    { id="select", rect={x=340,y=965,w=90,h=70}, action="select" },
    { id="next", rect={x=470,y=965,w=90,h=70}, action="next" },
  },
  preferredTheme = "green",
}
```

All coordinates are **local to that model's own source canvas**, top-left origin. The aperture, matte/backing, content and control rectangles must be measured **from actual art** after creation, not invented beforehand. Runtime draws using a single physical-to-screen transform, with correct hit-testing and aspect-preserving user zoom. The real schema should permit zero/variable/mappable controls and optional analog knobs, and validate required capabilities without making existing `RegisterDeviceSkin` consumers fail.

## Condition / cosmetic variants — keep modular and economical

- Author baseline **pristine** shell, then independent alpha overlays `scratched`, `worn`, `dirty`, `damaged` as appropriate; model-specific finish, palette and markings are part of the base model identity. Do **not** stamp random scratches all over screens, fake controls, or NPC content.
- Build pipeline can offline-precompose combined condition variants when the actual runtime render/caching cost warrants it; source stays layered and editable. Avoid a combinatorial runtime explosion (wear x dirt x decals x paint). Prefer one resolved primary condition state plus at most a few bounded lightweight overlays.
- Derive appearance from **the real InventoryItem condition** if a stable mapping makes sense (illustrative thresholds only; agent must decide after source audit), with optional cosmetic seed when genuinely stable item identity is available. No new save-wide variant table, no per-frame randomization, and no ModData inflation. Condition variants are cosmetic and **never** imply enhanced/reduced radio power, access, battery level or merchant authorization.
- Item-specific variants are OPTIONAL if no art exists: clean default remains valid, no missing-texture crashes. Use lazy texture caching for active shell/needed variant, shared UI texture caches once, no per-frame file searches/recompositing on CPU.
- Reserve an explicit version and fallback path for models/variants, and consider MP consistency only if other players can actually observe the device cosmetic appearance. Never trust a client-chosen cosmetic variant to grant server permissions.

## Manifest and runtime compatibility

- Refactor from monolithic `M.sheets.shells`/ `skin.sprite`/ 256×432 assumptions to per-device full texture or optional subtexture references. **Full transparent shell PNGs need not live in an atlas**. Existing widgets can stay in their shared atlases.
- Keep compatibility for all six existing walkie IDs, old `GetSkin`, `GetSprite`, `GetDeviceSkin`, app/contacts providers, and old test fixtures while migrating. A v1 wrapper or adapter may still resolve the legacy atlas during a transitional phase. Never force Core to require DynamicTrading.
- Do not require exactly 3 hardware controls for HAM/manpack; renderer, input, focus, hotboxes and test fixtures must dispatch a registered control schema. The OS can provide on-screen and keyboard equivalents even if a radio lacks buttons.
- Distinguish `visualCapability` / `interaction` / `remoteTradeCapability`. An existing validation routine requiring a portable two-way microphone must not accidentally prevent a placed HAM radio's legitimate UI **or** grant remote trade access to an unauthorized device. Feature actions stay server-authoritative in Hoomans and DTCommon.
- No per-frame asset scanning, manifest rebuild, cropping or noise generation. Texture budgets are validated: a 1024×1728 RGBA shell costs ~6.75 MiB uncompressed before mipmaps, and multiplying by many loaded condition variants becomes significant; measure and cap concurrent texture residency where APIs permit.

## Ordered production and integration milestones (A0–A8)

### A0 — Fresh device/item/source inventory (next engineering step)
Audit latest Core manifests/rendering, B42 vanilla item script `fullType`, sprite/icon source and actual device capabilities of walkie, HAM and manpack; identify placed vs carried variants; locate any genuine high-resolution approved masters; audit legacy compatibility and shell PNG alpha. Produce a source/evidence table for every model. **Do not edit PNGs yet**.

### A1 — Establish versioned skin schema and model-local coordinates
Design v2 manifest, family/model registry, texture lookup, variable controls, skin fallback, display aperture/backing/content geometry, optional variants; tests and a compatibility adapter for all six walkies. Do not change visual output in this phase. Gate: Core-only registration and existing provider smokes stay green.

### A2 — Authoring export/validation pipeline
Create per-model input/output structure, manifest checker, pixel/alpha mask tests, high-res source integrity checks, optional preview against opaque synthetic LCD sandwich, sampled condition overlay alignment and normal-game review instructions. **No fake upscaling or auto-generated substitute source art.** Gate: per-model file generation and validation works from an authentic source, and shared UI atlases untouched.

### A3 — US Army walkie pilot (first art approval checkpoint)
Create/retrieve **genuinely detailed original** `Base.WalkieTalkie5` art in the agreed Zomboid-like style, own high-resolution transparent PNG, proper LCD aperture and accurate per-skin controls; optional one wear overlay. Require user visual approval **before replacing production skin for everyone**. Confirm normal-game zoom/backplate/portrait/navigation after integration. Missing master or art input is an honest art blocker, not permission to upscale old PNG.

### A4 — Other five walkies
One model at a time: Toys-R-Mine, ValuTech, Premium, Tactical, Makeshift. Each model has its own edited master/PNG, geometry tests and game screenshot. Do not automatically clone one silhouette and recolor it as six different devices.

### A5 — HAM radio family production
Audit vanilla models first; create civilian, military and makeshift HAM shells as actually existing in B42, with accurate casing/controls/single integrated screen approach, distinct aspect/interaction policy and optional wear variants. Verify portable vs world-placed/device data and screen clipping in a real game. No new radio UI or economy fork.

### A6 — Manpack family production
Audit actual `Base.ManPackRadio` type and wear/equipment access; author high-resolution manpack chassis, straps/antenna/knobs, its own aspect, single integrated OS display and control mapping. Test scale and real item use; no walkie 3-button template forced.

### A7 — Condition variants and extension SDK
Finalize optional pristine/scratched/worn/damaged overlays, realistic selection/fallback, bounded caching and mod-agnostic skin registration documentation. Add third-party family example using the same Core OS without consumer dependencies.

### A8 — Normal-game acceptance and legacy retirement
Normal installed Project Zomboid Build42: all verified walkie/HAM/manpack models, alpha screen sandwich, screens/portraits, 720p–4K zoom, UI hitboxes, physical/placed device interactions, condition variants, SP and MP where applicable, performance, and old DT/Hoomans integration/authorization regressions. Remove old runtime walkie atlas **only after** no longer needed and test rollback/compatibility path. Preserve original approved art sources and any historical DTAbstract copies until safe migration; avoid duplicate runtime loading.

## Checkpoint, safety and pause boundary

- Current user request was **documentation first**. Do not replace or generate shell artwork as part of the documentation commit. Begin real image-asset production **after** A0–A2 decisions and device-by-device art direction are ready. For significant creative changes, present transparent shell preview for approval; existing approved assets remain fallback until then.
- Work unattended on safe source audits, manifests, tests and scripts; commit/push verified in-scope changes to PsychopatzCore, updating `DynamicTrading/Docs/radio_os/DT_RADIO_OS_PROGRESS.md`. Do not ask repeated permission for routine coding steps. A visual-art approval is appropriate before replacing production imagery with newly drawn content.
- No force push, unsafe resets, unrelated modifications, user-save changes, unexpected changes to Hoomans or trading settlement. Never use the **PZ Headless Harness** (known broken); use offline Lua/Pillow tests and normal user-operated game SP/MP for native evidence. Don't claim native success from synthetic RGBA composites.
- Preserve ongoing C0–C6 compositor work as upstream prerequisites/foundations; asset A0–A8 is a new stage addressing the source-resolution and per-device-family limitations. Do not undo successful compositor/zoom patches.

## Verified Project Zomboid asset installation convention (2026-10-15)

PsychopatzCore already stores shared radio-signal frames in `Contents/mods/PsychopatzCore/common/media/ui/Radio/Signal_found/`, and its conversation background loader resolves `media/ui/Conversation/Backgrounds/*.png` from `common/media/ui`. Therefore place **all Radio OS game-loadable texture exports** in `Contents/mods/PsychopatzCore/common/media/ui/psychopatz/radio/` (or another established `common/media/ui/Radio/` subtree when the relevant Lua virtual texture path is updated together). Client Lua can remain under `42.20/media/lua` if B42-specific.

The current six legacy production PNGs were moved byte-for-byte from `42.20/media/ui/psychopatz/radio/` to that matching `common/media/ui/psychopatz/radio/` path; existing `getTexture("media/ui/psychopatz/radio/...")` virtual paths remain unchanged. Do not keep identical virtual texture names in both common and version-specific directories, which would introduce ambiguous resolution. Future walkie, HAM and manpack **runtime shell/LED/glass/condition** PNG exports must use `common/media/ui` as well.

**Important separate concern:** full multi-component 1254×1254 concept sheets are *unsliced art references*, not a PZ-renderable radio skin. The importer stores those labeled reference sheets in `common/media/ui/Radio/DeviceConcepts/` for discovery and review, but they must **not be referenced by the live renderer**. Device-specific production assets are cropped/validated into `common/media/ui/psychopatz/radio/devices/<family>/<model>/` only after approval. The compact 341px legacy **builder input** is kept separately at `art_source/radio/legacy/`, not treated as a game texture.

Offline and source-level path checks are possible; only normal Project Zomboid Build 42 use confirms actual engine texture resolution. The PZ Headless Harness is not permitted.

## Agent-first implementation tool (2026-10-15)

The reusable CLI that will author, slice, assemble, validate and export these individual radio-model sources is specified in [`../asset_harness/ASSET_HARNESS_CONTRACT.md`](../asset_harness/ASSET_HARNESS_CONTRACT.md), with H0–H9 implementation stages and its own [Codex /goal](../../ASSET_HARNESS_GOAL_PROMPT.md). **This is a developer asset harness, not the broken PZ Headless Harness.** It has no required Flask/browser/Qt interface; the agent operates JSON CLI plus full-resolution PNG previews. Current per-model A0–A8 art goals remain valid, and live game acceptance remains separate. No new images are included by this documentation cross-link.
