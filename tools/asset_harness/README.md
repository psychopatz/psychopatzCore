# Psychopatz Asset Harness

## Current radio runtime contract

The harness is the authoring/validation/CLI side of the unified radio system. It discovers only canonical `*_pilot.json` projects, and its GUI has no supported source-catalog mode. Compile the same data consumed by Core Lua with:

```sh
PYTHONPATH=tools python3 tools/asset_harness/cli.py runtime-manifest \
  --out Contents/mods/PsychopatzCore/common/media/ui/Radio/DeviceManifest.json
```

The default build creates pixel-equivalent runtime composites in each device's
`Shell/` directory and crops full-canvas component states into
`Optimized/Components/`. The pilot JSON remains the only authoring source; the
generated manifest carries the preserved positions consumed by Core Lua.
Use `--no-optimize-assets` only when inspecting the unoptimized fallback path.

The generated JSON and `Contents/mods/PsychopatzCore/common/media/ui/Radio/` assets are the runtime package. DynamicTrading's preview reads that Core manifest rather than maintaining a second catalog. Python/Lua smoke tests prove data and behavior parity; only a normal Project Zomboid run proves native acceptance.

> **Offline harness status (2026-10-17):** `./run.sh` opens canonical pilot projects only and sends pointer, PTT, and LED events through the shared reducer. The old source-catalog mode is retired.
>
> **Runtime status:** Core Lua now consumes the generated `DeviceManifest.json`; the harness remains the authoring/validation/CLI side of that same contract. Native Project Zomboid acceptance is still a separate pending gate.

This is the offline, agent-operated asset pipeline for PsychopatzCore. The
agent-facing CLI and core use Python and Pillow only; ordinary CLI operations
do not import Tk, start a server, contact the PZ bridge, or use the prohibited
PZ Headless Harness.

The default Tk/Pillow client is an interactive Radio OS simulator. It shares a
deterministic state/event reducer with the JSON client, so human clicks and LLM
commands exercise the same behavior. The legacy image viewer remains available
with `--asset-viewer`:

```sh
./run.sh
# or, from the repository root:
./tools/asset_harness/run.sh

# Drive the same simulator without a GUI:
python3 tools/asset_harness/simulator_cli.py snapshot
python3 tools/asset_harness/simulator_cli.py event \
  --json '{"event":"press","control":"power"}' \
  --json '{"event":"press","control":"center"}'
```

The simulator opens the staged WalkieTalkie/Ham/ManPack artwork, provides
clickable physical controls, renders the LCD state, and exposes a JSON event
entry. Its LCD panels, selected rows, signal indicator, and app icons come from
`Contents/mods/PsychopatzCore/common/media/ui/Radio/RadioMenu/radioUI.png`.
All ten staged radio types have independent LCD-aperture/content calibration
for both clean and worn sheet halves, plus an aspect-matched atlas screen
texture; this avoids stretching one wide panel or a second bezel into every
device. The `Show hitboxes` toggle exposes the measured
source-coordinate placements (orange LCD aperture, blue content-safe area,
green controls) when calibrating new device art. Known source-sheet seam bleed
is guarded at render time without rewriting the staged PNGs. Set `PYTHON_BIN`
when a different Python interpreter provides Tkinter and Pillow. To open the
previous image viewer explicitly, run:

```sh
./run.sh --asset-viewer
```

The entry point always emits one bounded JSON object on stdout by default.
Human-readable progress belongs on stderr. Image files are referenced by path
and SHA-256; PNG bytes are never embedded in responses.

```sh
python3 tools/asset_harness/cli.py doctor
python3 tools/asset_harness/cli.py project init \
  --project tools/asset_harness/projects/us_army.json \
  --family walkie --model us_army --width 768 --height 1296
python3 tools/asset_harness/cli.py source register \
  --project tools/asset_harness/projects/us_army.json \
  --id shell --input /path/to/authentic-shell.png \
  --provenance 'artist master; review ticket 123'
python3 tools/asset_harness/cli.py source inspect \
  --input /path/to/authentic-shell.png
python3 tools/asset_harness/cli.py regions detect \
  --project tools/asset_harness/projects/us_army.json --source shell
python3 tools/asset_harness/cli.py regions set \
  --project tools/asset_harness/projects/us_army.json \
  --id shell_front --source shell --rect 0,0,768,1296 \
  --purpose shell --status verified
python3 tools/asset_harness/cli.py layers set \
  --project tools/asset_harness/projects/us_army.json \
  --id shell_front --source shell --region shell_front \
  --x 0 --y 0 --z 50 --role shell_front
python3 tools/asset_harness/cli.py lcd set \
  --project tools/asset_harness/projects/us_army.json \
  --aperture 290,702,250,240 --backing 290,702,250,240 \
  --content 314,737,205,160
python3 tools/asset_harness/cli.py render \
  --project tools/asset_harness/projects/us_army.json \
  --state receiving --content-color '#294d37' \
  --out tools/asset_harness/projects/artifacts/receiving.png
python3 tools/asset_harness/cli.py validate \
  --project tools/asset_harness/projects/us_army.json
python3 tools/asset_harness/cli.py export plan \
  --project tools/asset_harness/projects/us_army.json
python3 tools/asset_harness/cli.py export apply \
  --project tools/asset_harness/projects/us_army.json --approved
python3 tools/asset_harness/cli.py export verify \
  --project tools/asset_harness/projects/us_army.json
```

Use `--approved` only after reviewing authentic source provenance. Synthetic
fixtures may exercise the complete pipeline, but they do not count as vanilla
Project Zomboid art or native-game acceptance. Existing legacy radio atlases
remain fallback assets and are not rewritten by this tool.

## Project model

Projects are schema-versioned JSON files containing registered sources,
proposed/verified regions, device-local layers, LCD geometry, variable control
hitboxes, bounded animation frames, cosmetic variant selectors, and an export
target. Source records retain dimensions, alpha/mode information, provenance,
approval state, and an input SHA-256. Coordinates use a top-left origin in
source pixels. Rendering uses nearest-neighbour only when an explicit preview
scale is requested.

Useful failure codes include `FILE_NOT_FOUND`, `IMAGE_UNREADABLE`,
`SOURCE_HASH_MISMATCH`, `LCD_ALPHA_HOLE_FILLED`, `LCD_BACKDROP_GAP`,
`CONTROL_OUT_OF_BOUNDS`, `VALIDATION_FAILED`, `SOURCE_NOT_APPROVED`,
`EXPORT_CONFLICT`, and `EXPORT_VERIFY_FAILED`.

For repeated work, `batch --file batch.json` accepts a bounded list of argv
arrays for the same whitelisted commands. It never executes shell text.

## Radio modular audit and authoring

`assets audit` is read-only with respect to the canonical Radio PNGs. It
records exact owner paths, SHA-256, dimensions, alpha coverage, conservative
paired-sheet detection, immutable-source status, and blocked/proposed reasons
for all six walkies, three HAM radios, and the ManPack:

```sh
python3 tools/asset_harness/cli.py assets audit \
  --write-manifests \
  --write-artifacts \
  --out /tmp/ah-r0-audit.json
```

The generated manifests are developer evidence, not runtime approvals. The
current canonical files are single full-front canvases; `clean`/`worn` aliases
must not be implemented by cropping their two sides. The literal filename
`Base.HamRadioMakeShift .png` is preserved and reported as-is.

When the W5 source is in scope, `--write-artifacts` also writes
`walkie_5_pilot_acceptance.png` and `walkie_5_pilot_acceptance.json` under the
ignored review workspace. These are blocked evidence only: they show the
immutable source, full-resolution alpha, and human review gates, but they do
not create chassis, sockets, component states, or runtime approval.

Every single-canvas source also carries a blocked `manual_reconstruction_plan`
with explicit chassis, socket-mask, component-state, and visual-review gates.
This records the concealed-pixel problem directly; it cannot be cleared by
adding filenames or by promoting an automatic crop.
Each device also receives a blocked source-to-idle JSON diff report with the
immutable source hash and `after: null`; no fake idle image is generated.

Source-space masks are imported losslessly and remain proposed until visually
reviewed. A `verified` mask also needs explicit `--reviewed-by` or
`--review-artifact` evidence; status alone cannot approve it. Rectangle
proposals cannot satisfy the production mask gate:

```sh
python3 tools/asset_harness/cli.py masks import \
  --project tools/asset_harness/projects/radio/walkie_5_pilot.json \
  --id back_socket --input /path/to/back_socket.png \
  --source canonical --method hand_authored --status proposed
python3 tools/asset_harness/cli.py masks polygon \
  --project tools/asset_harness/projects/radio/walkie_5_pilot.json \
  --id back_socket_candidate --source canonical \
  --points '300,600;340,590;380,620' --status proposed
python3 tools/asset_harness/cli.py masks preview \
  --project tools/asset_harness/projects/radio/walkie_5_pilot.json \
  --id back_socket --source canonical --out tools/asset_harness/workspace/back_socket_preview.png
python3 tools/asset_harness/cli.py masks validate \
  --project tools/asset_harness/projects/radio/walkie_5_pilot.json \
  --id back_socket
```

Modular projects can register independent `pristine`/`worn` chassis images,
socket masks, keyed button/PTT/power/LED states, rotary detents and integer
hitboxes. `modular validate`, `modular render`, and `modular contact-sheet`
are offline only; missing sockets, identical fake states, anchor drift, and
unreviewed components remain failures or incomplete evidence.

LCD shell layers are registered separately so the transparent glass and bezel
overlay cannot be mistaken for baked dynamic content:

```sh
python3 tools/asset_harness/cli.py modular lcd set \
  --project tools/asset_harness/projects/radio/walkie_5_pilot.json \
  --glass LCD/Glass.png --bezel-overlay LCD/BezelOverlay.png \
  --status proposed
```
