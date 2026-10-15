# Psychopatz Asset Harness

This is the offline, agent-operated asset pipeline for PsychopatzCore. The
agent-facing CLI and core use Python and Pillow only; ordinary CLI operations
do not import Tk, start a server, contact the PZ bridge, or use the prohibited
PZ Headless Harness.

An optional Tk/Pillow viewer is provided as a thin client for people who want
to look at the same PNGs and project renders visually. It does not replace the
CLI or change the validation/export rules:

```sh
./run.sh
# or, from the repository root:
./tools/asset_harness/run.sh
```

The viewer opens the tracked legacy walkie shell atlas by default. Use `Open
PNG` for another image, `Open Project` and `Render` for an asset-harness
project, and `Validate` to inspect its diagnostics. `Save Preview` writes a
PNG only when you explicitly choose a destination. Set `PYTHON_BIN` when a
different Python interpreter provides Tkinter and Pillow.

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
