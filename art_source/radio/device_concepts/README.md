# Radio device concept source sheets — labeled inventory

These are **11 generated full-resolution PNG concept sheets**, not final sliced textures. All originals are **1254 × 1254 RGBA**, and the intended LCD/buttons/LED frames still need individually measured crop coordinates and alpha validation. Core owns the future runtime assets; this folder contains human-editable reference/source sheets only.

**GitHub publication status:** the catalog and reproducible import tool are committed here. The **PNG bytes are not in this commit** because the connected GitHub writer does not accept local image-file references; they must be imported from the original asset bundle via the script below. Do not report images as published until each target PNG exists in the Git tree and matches SHA-256.

## Upload the original full-size files

Download the accompanying original concept-sheet bundle from the conversation, then on a workstation with a clone of `psychopatzCore` run:

```sh
python tools/radio_os/import_radio_concept_bundle.py /path/to/psychopatz_radio_concept_sheets_2026-10-15.zip --commit --push
```

The importer checks PNG size/format/alpha, exact SHA-256, safe archive paths, and preexisting files. It commits **only** new concept images, refuses to overwrite any different art, and performs a normal non-force Git push. If source files already match, importing again is safe. To review without Git write operations, omit `--commit --push`; it still copies files after verification.

## Classification rules

- `walkie/us_army`: four **alternative** military handheld studies, **not** four separate vanilla devices and not separate finalized clean/worn source layers.
- `walkie/makeshift`: two taped/exposed-wire handheld concepts. The generated filename `post_apocalyptic_ham_radio_sprite_sheet.png` is visually a handheld and is therefore organized under makeshift **walkie**, not HAM.
- `walkie/tactical`, `walkie/rugged`, `walkie/unassigned`: additional handheld studies; **no confirmed Base fullType** until game-art audit.
- `ham/desktop`: one horizontal desktop HAM visual concept. HAM models and placed-radio behavior are not exhaustively represented.
- **Manpack: not generated.** Do not label any existing handheld as a manpack. Create and approve manpack art separately.
- Within each concept sheet, shells, glass overlays, hardware buttons and LED/glow frames are *visual regions*, not prevalidated runtime animation assets. Slice and label exact regions before integration.

For each future production device, use `Docs/radio_os/CORE_RADIO_DEVICE_ASSETS.md` and keep independent transparent shell art, measured display and control geometry, overlay variants, static shared UI atlases, and time-driven LED state selection in Core. No baked NPC names, text, contact images, or trading UI screens.

## Integrity

`catalog.json` records every original image name, intended staging path and exact SHA-256. Imported files are intentionally not attached to the game-loaded `media/ui` directory until each model is individually reviewed, sliced and validated.
