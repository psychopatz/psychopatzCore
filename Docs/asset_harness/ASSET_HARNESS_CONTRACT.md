# Psychopatz Asset Harness — Agent-First Architecture Contract

**Status:** implementation design, 2026-10-15. **Documentation only:** there is no implemented Asset Harness CLI, HTTP service, or committed new image set in this planning commit. **Owner:** `psychopatz/psychopatzCore`, as reusable developer tooling for Psychopatz mods.

## Goal and non-goals

An LLM with command execution and image-reading capability must be able to take authentic transparent source art, inspect dimensions/alpha, detect or manually define slices, assemble named layers and bounded animations, inspect lossless rendered previews, validate precise geometry, and export correctly labeled Project Zomboid textures + versioned Core-readable skin metadata **without a mouse or desktop automation**. The first end-to-end device is the **US Army walkie**, then other five walkies, verified HAM radios and manpack. Later consumers can register unrelated icons, buildings, NPC UI and widgets without new Core dependencies.

**Not:** a Project Zomboid Headless Harness, native-game emulator, arbitrary Lua executor, LLM inference engine, generative-image model, authoring tool that invents missing true high-resolution pixels, or proof of native PZ behavior. Browser/Flask/Qt GUI are **optional clients only**, not the foundation.

## Verified existing project parts to audit and reuse

- `tools/profiler/profiler_cli.py`: argparse/JSON command interface, bounded output and machine-readable errors. Reuse *patterns* and small independently useful helpers, not its performance/NPC report logic.
- `tools/profiler/profiler_core.py`: separation of platform-neutral model, file IO and GUI.
- `tools/profiler/bridge/{client,transport,models,config}.py`: existing validated request/response transport, bounded pending/results and runtime IDs. **Only for future optional native live diagnostics when explicitly enabled.** No bridge setup or side effects during offline image operations.
- `tools/profiler/tests/`: Python regression convention; do not couple asset tests to the profiler's Tk UI or process monitoring.
- `docs/profiler.md` and `tools/profiler/README.md`: LLM CLI contract and opt-in local bridge. The bridge is not a generic console.
- `docs/preview-framework.md` and `42.20/media/lua/client/PsychopatzCore/Preview/PC_PreviewSnapshot.lua`: primitive-only bounded snapshot boundary, useful for planning an eventual radio render-plan capture. Do not assume it currently exports PNG screenshots.
- `tools/radio_os/build_dtabstract_walkie_*.py`, `tools/radio_os/import_radio_concept_bundle.py`, `tests/radio_os/`: real source art builders, import checks, atlas-alpha and compositor tests. **Adapter/wrapper migration**, not deletion.
- `42.20/media/lua/client/PsychopatzCore/UI/Radio/OS/PsychopatzRadioManifest.lua`: current *v1* shared 256x432 six-walkie atlas and three physical controls; it is not v2 per-model source geometry. Implement a compatibility adapter.
- `Docs/radio_os/CORE_RADIO_DEVICE_ASSETS.md`: authoritative per-model design and asset provenance plan.

**Reality check:** 11 previously generated concept sheets were cataloged, but their original PNG binaries were not committed in the earlier session. Several are not faithful to vanilla items; no valid final HAM/manpack production set is demonstrated by the repository. A2+ must handle missing/unapproved originals honestly, not generate fake fidelity or mark devices done.

## Tool layout (planned, not files already created)

```text
PsychopatzCore/
  tools/asset_harness/
    cli.py                     # thin argparse dispatcher
    core/
      project.py               # versioned editable project JSON + migrations
      source.py                # image registration, dimensions, alpha, hashes
      regions.py               # detection / manual slice definitions
      layers.py                # transforms, anchors, composite order
      animations.py            # deterministic sampled states / frames
      render.py                # Pillow-based lossless previews
      validation.py            # geometry/alpha/pixel/source contract checks
      export.py                # staged verified media + Lua manifest exports
      responses.py             # bounded JSON, codes, artifact descriptors
    tests/
  Docs/asset_harness/          # plan, runbook, roadmap, progress
  Contents/mods/PsychopatzCore/common/media/ui/
    psychopatz/radio/devices/<family>/<model>/
      ...                      # ONLY validated, approved runtime exports
```

Editable JSON projects and intermediate generated previews/diff images live in a controlled **development work directory**, outside the `common/media/ui` runtime tree; actual runtime PNGs follow Core's established `Contents/mods/PsychopatzCore/common/media/ui/` convention. The `42.20/media/lua` directory may contain Build-42-specific Lua consumers. Do not create unrequested `42.20/media/ui` exports or duplicate virtual texture names.

## Agent-first CLI contract

One CLI entry point is the primary integration; Python functions share its exact domain logic. Command names below are **proposed**, not yet implemented:

```sh
python tools/asset_harness/cli.py doctor --format json
python tools/asset_harness/cli.py assets list --family walkie --format json
python tools/asset_harness/cli.py source inspect --input /path/to/source.png --format json
python tools/asset_harness/cli.py regions detect --project projects/us_army.json --source shell --format json
python tools/asset_harness/cli.py regions set --project projects/us_army.json --id led_off --rect 123,234,20,20
python tools/asset_harness/cli.py layers set --project projects/us_army.json --id led --source led_on --x 204 --y 152 --z 70
python tools/asset_harness/cli.py render --project projects/us_army.json --state receiving --scale 1 --out artifacts/usarmy_receiving.png
python tools/asset_harness/cli.py validate --project projects/us_army.json --format json
python tools/asset_harness/cli.py export plan --project projects/us_army.json --format json
python tools/asset_harness/cli.py export apply --project projects/us_army.json --approved
```

Use readable verbs, typed arguments and `--help`/machine-readable command discovery. Allow a **single optional JSON batch file** of these whitelisted operations to avoid high per-command overhead in large jobs. Operations must be deterministic and idempotent: the same project/assets/configuration -> same bytes and manifest, except an explicitly versioned metadata timestamp if indispensable. No cwd-dependent mystery defaults, interactive confirmation or process requiring a graphical display.

### Stable JSON response envelope v1

Every command returns **one JSON object on stdout**, with warnings/errors/diagnostics in fields. Progress/logging goes to stderr; no free-form stdout fallback. Standard fields:
```json
{
  "schema_version": 1,
  "ok": false,
  "command": "validate",
  "project_id": "walkie_usarmy",
  "revision": "sha256-of-input-contract",
  "summary": {"checks": 14, "passed": 13, "failed": 1},
  "diagnostics": [{
    "code": "LCD_BACKDROP_GAP",
    "severity": "error",
    "asset": "shell_front",
    "rect": [202, 301, 4, 11],
    "message": "Opaque backing misses part of intended aperture"
  }],
  "artifacts": [{"kind": "png", "path": "artifacts/lcd_gap.png", "sha256": "…"}],
  "truncated": false
}
```
This is a **schema example**, not a reported test result. Require stable error codes and actionable region/asset identifiers; nonzero exit for invalid requests, validation failure (configurable), missing files, rejected exports and internal errors. `--token-budget`/output-size bound, pagination/chunking for catalogs, explicit truncation and a `--format json` default. Never embed raw PNG/base64 or entire image data in JSON. Return a sandbox/local artifact path that Codex can inspect directly.

## Editable project JSON (proposed v1)

- `schema_version`, `project_id`, `device.family` (`walkie|ham|manpack` or registered extension), `device.model`, optional verified `fullType`, canvas width/height and origin.
- `sources`: explicit relative/allowlisted file path, SHA-256, dimensions, color/alpha mode, provenance, item-reference confidence, approved flag; **separate approved reference from generated suggestion**.
- `regions`: stable id, source image, exact integer `[x,y,w,h]`, purpose (`shell|lcd_aperture|button|led|wear|glass|icon`), padding/gutters, alpha-mask method.
- `layers`: ordered z value, source/region, anchor, destination x/y, transform, opacity, state predicate. Pixel coordinates are **device-local**, not scaled editor pixels.
- `lcd`: separate aperture, opaque matte/backdrop, content safe rectangle, optional glass/effects mask, all validated from actual image alpha.
- `controls`: zero-or-more IDs with hitboxes and semantic action keys, independent of pixel art; do not force the old 3-key walkie layout on HAM/manpack.
- `animations`: named timeline with frame/state durations and bounds (`led.off`, `led.green`, `led.red`, `led.amber`, `button.pressed`), ordered deterministic frame rendering, no need for GIF inside PZ.
- `variants`: pristine plus optional scratched/worn/dirty/damaged layers, aligned by anchor; don't duplicate whole canvases if only small art changes.
- `export`: destinations and texture/manifest targets, explicit approved runtime promotion, compatibility fallback, and `output_hashes`.

Do not pre-populate coordinates from a guess and label them verified. Computer-vision region proposals are tagged **proposed**; accepted slices/anchors need validation. Exact device and B42 item mapping still require vanilla source checks.

## Render and export pipeline

1. `inspect` full RGBA source (retain original bytes, dimensions, SHA, alpha histogram, transparent/opaque bounds and color profile metadata where supported).
2. `detect` candidate connected alpha islands or user-defined regions with non-destructive preview; **manual `regions set` always supported**. Do not assume disconnected islands correspond to full objects (glows, wires, mic curls, holes).
3. `compose` deterministic order: backing/matte -> LCD theme -> clipped dynamic placeholder *for preview only* -> overlay effects -> front shell -> hardware states -> condition overlay (respect LCD clip) -> LEDs; no baked portrait/trading content on export.
4. `render` PNG with exact transparent exterior, alpha-safe compositing, optional grid/bounds/mask debug view, text not pretending to be native PZ font, scale presets, and LED animation contact sheets; full resolution, never compress all models into a tiny collage.
5. `validate` dimensions, straight-alpha/alpha-hole coverage, opaque backing, LCD safe rect, control bounds, nonoverlapping region ownership where required, layer ordering, variant/LED anchor alignment, PNG content/source hashes, source/master fidelity, scale transform.
6. `export plan` calculates paths, file operations and expected hashes in a **temporary/staging** tree; reports would-overwrite/conflicts, file sizes, and expected changes. `export apply` only after passing validation **and explicit approved production opt-in**, atomically installs reviewed files with backups/rollback or refuses conflicts. Never rewrite other Core or player assets silently.
7. `verify export` reopens written PNGs/manifests, revalidates hashes and game-relative `media/ui/...` references. A successful export is **not** native PZ UI acceptance.

## Safety and operational requirements

- No unrestricted `eval`, dynamic Python expression execution, arbitrary shell through commands, unsafe pickle, arbitrary Lua execution or unreviewed plugin code.
- No arbitrary path writes: confine to approved project roots; resolve symlinks, `..`, archive traversal and ZIP bombs; cap decoded pixels/byte sizes, execution time, image count, layer count, batch length, animation frames and artifacts. Avoid excessive memory/resource use. Catalog actions read-only by default.
- Separate writable development workspace from source and production game files; preserve authored PNG bytes by default and never silently recompress/resample. Reject output collisions, mismatched provenance/hashes and generated PNGs with baked full scene/screen content.
- No background daemon/localhost/network needed for CLI. If an optional HTTP/UI frontend is added later it calls the same library, binds `127.0.0.1` and never bypasses validations.
- Runtime/game bridge, if ever used, is explicitly opt-in, capability-listed, timeout-bounded, local-only, owner-authorized and **not** an arbitrary console. Game side provides observation only initially.
- The existing **PZ Headless Harness is explicitly prohibited**, including setup, repair, investigations and evidence claims. Offline image tests and browser-free CLI tests may be automated; actual normal game SP/MP screenshots are a separate final verification gate.
- Preserve Hoomans identity/contact APIs, DTCommon V2 trade settlement, DTAbstract remote authorization and DTHoomans physical merchant checks. Core's asset tool cannot grant gameplay authority.

## Definition of done

One **approved authentic** US Army source can be imported, precisely sliced, layered, rendered as pristine/worn and multiple LED states, validated with a synthetic alpha sandwich, exported into the correct `common/media/ui` paths + compatible skin declaration, reopened deterministically, and inspected by an LLM **entirely through CLI and PNGs**. Show real command transcripts with bounded JSON and generated previews; remain honest if input art is missing or native PZ cannot be operated. Then generalize and test other walkie/HAM/manpack models without changing the CLI API.
