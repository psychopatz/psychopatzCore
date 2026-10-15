# Radio OS Interaction & Animation v2 — Progress

**Date:** 2026-10-15. **State:** design documented; no controller/asset/runtime implementation performed in this documentation update. Next **I0**, then freeze I1 before producing pilot animation art.

## Locked product direction

- **Radio-shaped mini-computer** rather than strict period-correct walkie or smartphone UI.
- Realistic-enough radio chassis/speaker/antenna/knobs/PTT; deliberately generous, clickable monochrome LCD for gameplay.
- Universal discoverable BACK/HOME/OK/directions, power and device-aware radio functions.
- Pivot-registered independent physical animations (rotary, buttons, PTT, LED), not one flattened skin.
- One Core-owned OS/controller contract with per-family physical mapping; Python simulator and PZ Lua follow common scenario tests.
- Start with **US Army walkie**; family coverage afterwards includes 5 other walkies, 3 HAM and manpack.
- Real art approval separate from tool fixture success and native game acceptance. Existing skin fallbacks preserved.

## GitHub code audit baseline (read-only, 2026-10-15, HEAD 0a86b2e)

| Evidence | Status |
|---|---|
| `tools/asset_harness/{cli.py,simulator_cli.py,simulator_gui.py}` | Present. Offline agent CLI and optional simulator GUI exist. |
| `tools/asset_harness/simulator/catalog.py` | 10 staged device definitions; walkie controls reused between models; manpack includes a physical Back, most other families do not. |
| `tools/asset_harness/simulator/model.py` | `back` action available via software/Escape but returns straight home; `transmit_toggle` is not hold-to-talk; no complete page stack, pointer capture, rotary visual transition. |
| `tools/asset_harness/simulator/render.py` | Screen content composited over 627px half-sheets; no separate pivot-rotated knob, PTT or LED parts demonstrated there. |
| `RadioOSDevice.lua` | Current registered skin validator still requires `left/center/right`. |
| `RadioOSWindow_Renderer.lua` | Only iterates three generic square controls; highlights are not physical animations. |
| `RadioOSWindow_Navigation.lua` | Back present; left overloaded; page selection not equivalent to Python reducer. |
| `RadioOSWindow_Input.lua` | Keyboard Escape/Back and joypad B present. |
| `RadioImageAnimation.lua` and `asset_harness/core/animations.py` | Reusable frame/time logic exists, but neither supplies integrated per-hardware animation parity by itself. |
| `common/media/ui/Radio/` | 10 staged device-specific two-variant PNGs are Git-tracked; they are not necessarily approved, authentic or component-separated final art. |
| `common/media/ui/psychopatz/radio/` | Legacy production walkie and shared UI atlases tracked; v2 replacement not claimed. |

**No tests were executed during this documentation-only review.** These are code/source observations, not screenshots from actual Project Zomboid. Re-audit Git HEAD and local untracked changes before implementing.

## Phase ledger

| Phase | Status | Next evidence |
|---|---|---|
| I0 | NEXT | Source audit, vanilla reference verification, existing tests baseline |
| I1 | pending | Accepted semantic action schema and variable-control manifest |
| I2 | pending | Navigation/Back+softkey/keyboard/joypad tests |
| I3 | pending | Input lifecycle/rotary/PTT scenario tests |
| I4 | pending | Hardware animation state/image regression |
| I5 | pending | Asset harness v2 manifest and authoring template |
| I6 | pending | Real US Army art components, preview and visual approval |
| I7 | pending | Lua runtime + provider regression + native status |
| I8 | pending | Other 9 family/device assets + verified art |
| I9 | pending | Native SP/MP and profiler evidence |

## Agent checkpoint append format

```text
Date / exact HEAD:
I phase / next:
Read/audited files and B42 source provenance:
Actual art original/master SHA + approval:
Commands and tests actually run:
Rendered artifacts and hashes:
Back/Home/PTT/knob/LED behavior evidence:
Simulator vs Lua scenario parity:
Source/image/offline Lua/native SP/native MP/profiler evidence:
Changed paths, commit SHA, push status:
Precise blockers and next safe tasks:
```

Keep progress append-only; don't rewrite source evidence with optimistic claims. Never mistake a generated concept pair, a clicked GUI demo or an offline PNG composite for production-native acceptance.
