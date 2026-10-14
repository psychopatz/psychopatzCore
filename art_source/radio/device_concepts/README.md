# Radio art: verified Core paths and import staging

**All game-loadable Radio OS textures belong under PsychopatzCore's existing `common/media/ui` convention.** This was verified against existing `common/media/ui/Radio/Signal_found` files and the conversation background texture loader. Earlier instructions placing game PNGs under `42.20/media/ui` were incorrect for this project's preferred layout.

## Production (game-loadable) radio textures

```text
Contents/mods/PsychopatzCore/common/media/ui/psychopatz/radio/
  shells/DTA_Walkie_Shells.png        # legacy approved shell atlas; fallback
  ui/DTA_Walkie_UI_Core.png           # shared reusable LCD/UI chrome
  ui/DTA_Walkie_Buttons.png           # shared button states
  ui/DTA_Walkie_Icons.png             # shared icons
  ui/DTA_Walkie_Indicators.png        # shared battery/signal art
  ui/DTA_Walkie_Overlays.png          # shared visual effects
  devices/walkie/<model>/             # FUTURE approved individual shells/LEDs/wear
  devices/ham/<model>/                # FUTURE approved HAM shells/LEDs/wear
  devices/manpack/<model>/            # FUTURE approved manpack shells/LEDs/wear
```

The six **existing** runtime PNGs were moved byte-for-byte to this directory. The Lua `getTexture` virtual texture names remain `media/ui/psychopatz/radio/...`; Lua source can stay under `42.20/media/lua`. The **legacy compact builder source** moved to `art_source/radio/legacy/` because it is an offline tool input, not a game image.

## Eleven unsliced concept sheets: staging only

The generated 1254x1254 concept-sheet **originals are not game-ready sprites**. They contain multiple mixed visual objects and unmeasured LCD/button/LED parts. For convenient browsing alongside your Core radio assets, the importer stages them at:

```text
Contents/mods/PsychopatzCore/common/media/ui/Radio/DeviceConcepts/
  walkie/us_army/...
  walkie/makeshift/...
  walkie/tactical/...
  walkie/rugged/...
  walkie/unassigned/...
  ham/desktop/...
```

The catalog lives at `art_source/radio/device_concepts/catalog.json`. Its `archive_path` points to each original ZIP member; `target_path` points to the Core common-media staging destination. They are **labeled unapproved source concepts**, not wired to the renderer, not sliced/validated, and not a full HAM or manpack set. **No manpack sheet is in the ZIP.** Keep their full original resolution and transparency. Large unsliced sources should not be registered as a game-facing skin.

## Import (not yet uploaded to GitHub)

In your cloned `psychopatzCore` folder, run:

```powershell
py tools/radio_os/import_radio_concept_bundle.py "$env:USERPROFILE\Downloads\psychopatz_radio_concept_sheets_2026-10-15.zip" --commit --push
```

This validates exact SHA-256, PNG alpha/dimensions, names and any existing destination before adding files. It does not change the active Radio OS. Do not claim that the 11 binary images have been pushed before this command succeeds. The importer commits and pushes only the staged images; all runtime skins must be individually reviewed and exported afterward.

## Future image production

Follow `Docs/radio_os/CORE_RADIO_DEVICE_ASSETS.md`: per-model high-resolution independent shell/art sources, correct LCD alpha hole and backdrop, animation-ready separated LED states and condition overlays; shared UI widget atlases remain unified. Test all future exports using normal game Build 42 and offline alpha/geometry validation. **PZ Headless Harness must not be used.**
