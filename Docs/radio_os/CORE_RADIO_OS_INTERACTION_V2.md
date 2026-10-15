# Radio OS Interaction & Animation v2 — Radio-Shaped Mini-Computer

**Decision locked 2026-10-15:** Gameplay-first, *radio-shaped mini-computer*. The fictional expanded LCD and rich app navigation are intentional, not an attempt to reproduce the limited UI of a real 1990s walkie-talkie. The device **must still clearly read as a Project Zomboid radio**, with an antenna, speaker, rugged case, tactile hardware, separate PTT, rotary controls and a distinct silhouette. **Do not revert to hardware-only or force separate portrait/dialogue overlays by default.**

**Status:** approved design / documentation-only. **Not yet implemented in both runtime and simulator.** Owning repo: `psychopatz/psychopatzCore`. New change milestones: **I0–I9** ([roadmap](CORE_RADIO_OS_INTERACTION_ROADMAP.md)). Prior C0–C6 compositor, U0–U7 stabilization, A0–A8 asset and H0–H9 harness milestones remain as compatibility/prerequisite tracks; they are not replaced or silently marked native-passed.

## Baseline from current repository (HEAD 0a86b2e; re-audit on implementation)

- Offline prototype: `tools/asset_harness/simulator/{catalog,model,render}.py`, `simulator_cli.py`, `simulator_gui.py`. The catalog lists **10 staged models** (6 walkies, 3 HAM, 1 manpack) with separate clean/worn crops, rectangles and click actions. The Python simulator includes `power`, `previous`, `next`, `select`, `menu`, `back`, simplistic `signal_cycle`, `transmit_toggle`, single `press` events, and direct screen clicks. This is a **simulation**, not confirmation of vanilla behavior.
- Simulator walkies use the same `_WALKIE_CONTROLS` map; they do **not** expose a dedicated physical `back`. Escape in the Tk client sends a software `back`. Manpack does expose `back`; HAM definitions vary. The Python model's `back` currently returns directly home; it does not maintain a full navigation stack. PTT presently toggles, not down/hold/up.
- Game implementation: `42.20/media/lua/client/PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSDevice.lua` validates required `left,center,right` hitboxes. `...Window_Renderer.lua` loops those three controls and draws generic square button highlights. `...Window_Navigation.lua` makes left context-sensitive and implements `Window:back()`; `...Window_Input.lua` provides Escape/Backspace and joypad B, but no consistently visible universal Back control. These **two controller stacks do not have contract parity**.
- `RadioImageAnimation.lua` is a reusable signal-frame animator, not a general pivot-aware hardware controller. `tools/asset_harness/core/animations.py` supports timeline PNG generation, but the simulator's physical shell remains essentially static.
- Staged clean/worn concept PNGs are presently Git-tracked under `common/media/ui/Radio/{WalkieTalkie,Ham,ManPack}`; **their existence does not approve their fidelity or make them game-ready v2 shells**. Actual live Radio OS still uses legacy `common/media/ui/psychopatz/radio/{shells,ui}/` atlases.

## Gameplay interaction principles

1. **Predictability beats mechanical realism.** Always display discoverable Back, Home/Menu and Select semantics. Menus remain mouse-clickable (including LCD rows), keyboard-operable and joypad-operable. The LCD is a gameplay interaction surface even when styled as a monochrome, non-touch radio display.
2. **Radio identity beats phone identity.** A generous *landscape or portrait* LCD may display contacts, portraits, scanner, settings and apps; the bezel, speaker, antenna, PTT, knob, signal/status indicators and industrial controls must remain visually dominant enough to read as a radio. No thin phone slabs, touchscreen-only affordance, modern app-phone chrome, generic flat glass fronts or copied silhouettes.
3. **One Radio OS, separate device adapters.** Applications and provider actions are common. Geometry, visual controls, gesture styles and control availability are per-model, with sane family defaults and optional per-device overrides.
4. **A Back action must always exist** independent of left/channel key overload. Prefer a visible separate BACK hardware button; where the art has insufficient keys, provide a visibly labeled LCD footer softkey with a measurable click region, plus keyboard Escape / joypad B.
5. **No invented gameplay facts.** Power, battery, reception, tuned frequency, range, transmission and privileges come from actual vanilla/Core device state and authoritative provider responses in game. A prototype may use explicitly labeled synthetic data, never claim that `signal_cycle` is a live PZ radio scan.
6. **Fast response with bounded feedback.** A physical key highlights/depresses immediately; actions give visible focus/selection/result feedback. Visual animations cannot block gameplay or be mistaken for server acknowledgement.
7. **No persistence of transient animations** in save ModData; visual event timestamps/frame indices remain client/window-local.

## Navigation and input contract

Every supported family must provide **semantic actions** `BACK`, `HOME`, `UP`, `DOWN`, `LEFT`, `RIGHT`, `SELECT`, `POWER` and supported radio features (`PTT`, `TUNE`, `VOLUME`, `SCAN`) via visible physical and/or labeled LCD soft controls. Provide accessibility keyboard and joypad equivalents.

| Intent | Behavior (power on unless noted) | Minimum affordance |
|---|---|---|
| `BACK` | Pop navigation history one level; from home close the Radio OS surface and restore the original host window when applicable. In modal/dialogue screens, cancel or let an extension's validated `onBack` handle first. Never lose app state arbitrarily. | Dedicated Back key **or** permanently visible labeled Back softkey |
| `HOME` / `MENU` | Return to OS home; Menu may open current contextual menu only where explicitly mapped. No surprise power toggle. | Visible key/softkey |
| `UP/DOWN` | Move focused row in menu/list; scroll when focused list; deterministic boundary behavior | D-pad or scroll/soft control |
| `LEFT/RIGHT` | Change focused tab/value or horizontal selection as visibly indicated; cannot silently mean `BACK` | D-pad or wheel |
| `SELECT` | Activate focused row/confirmed action once; no double event on mouse-down/up | OK/key and clickable LCD row |
| LCD click | Hit a visible row or softkey in screen-local coordinates; clipped to safe content and mapped through model/window scale | Full click-to-row precision |
| `POWER` | Toggle through real device API / validated state; off disables radio actions but preserves an obvious exit/close | Power key or rotary detent |
| `PTT` | Press begins an **eligible** transmit request, hold maintains, release/cancel/focus-loss ends; release must be delivered even outside hitbox | PTT physical button + optional key binding |
| `TUNE/VOLUME` | Wheel/drag/step changes numeric setting via validated constraints; each detent snaps and can animate | Knob/encoder/step key |
| Close window | Escape/Back at home closes, restores vanilla host, cancels held PTT and any pending pointer capture | Consistent keyboard/joypad |

Navigation holds a **page stack** with stable ids (`home`, `contacts`, `contact_detail`, `settings`, `custom:<provider-id>`), plus per-page focus/scroll restoration. Avoid introducing infinite stacks through repeated Home or redundant pushes. Back from `contact_detail` returns to `contacts`, from `contacts` to `home`, from `home` closes. Provider custom pages can intercept Back through existing callbacks, but must explicitly return handled/unhandled; denial should not strand the player.

**Screen placement:** A dedicated Back key is preferable on the walkie pilot, with a footer `BACK` hint as discoverability; if both appear they trigger the same command and are not two conflicting navigation systems. Maintain PZ window dragging/resizing and pointer capture, with controls and LCD taking hit-test precedence over dragging.

## Device-family controller profiles (design targets, not vanilla API claims)

| Family | Default physical layout | LCD/software |
|---|---|---|
| Toy / makeshift handheld | Power knob/switch, channel/volume, PTT, directional/select/back access (can use clearly labeled compact keys) | Larger **fictional** but radio-styled OS window; fewer direct physical shortcuts |
| ValuTech/Premium handheld | Power/volume knob, channel knob or rocker, D-pad + OK, separate BACK/MENU, PTT | Full LCD menu and clickable contacts |
| Tactical / US Army handheld | Antenna, speaker grille, power knob, rotary encoder, D-pad/OK, BACK, MENU and strong PTT side control, TX/RX LEDs | Full Radio OS; **US Army is the v2 production pilot** |
| HAM (three actual variants) | Wide chassis, knob(s), switches, control keys, microphone/PTT and signal indicators; custom proportions | Landscape menu/contacts; richer station/scanner readout |
| Manpack | Rugged portable radio chassis/straps, big knobs, protected BACK/OK/navigation, PTT, LEDs | Full Radio OS with field-status layout |

The software capability can be game-friendly even on a weak device; **do not invent stronger gameplay transmission range or permissions merely because its fictional LCD is larger**. No family-specific OS forks.

## Single authoritative command/animation contract

Use a **versioned, declarative device manifest** plus **shared JSON scenario fixtures** that both the Python simulator and Lua Radio OS consume or compile into equivalent data. Runtime remains Lua and simulator remains Python; do not claim they share executable code.

Logical pipeline:

```text
Mouse/keyboard/joypad/CLI event
  -> device-local hit-test + input normalization
  -> semantic command dispatch (one validated action per gesture)
  -> navigation/reducer state + validated radio/provider intent
  -> visual event intents (button travel, knob detent, LED, LCD feedback)
  -> device-specific animation instance + layered renderer
```

Example **proposed** neutral JSON manifest (not presently supported by the in-game validator):

```json
{
  "schema_version": 2,
  "device_id": "walkie_us_army",
  "family": "walkie",
  "controls": [
    { "id": "back", "kind": "momentary", "action": "BACK",
      "hitbox": [168, 850, 68, 56], "visual": "back_key" },
    { "id": "channel", "kind": "rotary", "action": "TUNE",
      "hitbox": [370, 180, 90, 90],
      "visual": "channel_knob", "pivot": [415, 225],
      "detents": 12, "input": ["wheel", "drag", "click_step"] },
    { "id": "ptt", "kind": "hold", "action": "PTT",
      "hitbox": [18, 375, 70, 190], "visual": "ptt_switch" }
  ],
  "softkeys": [{"id": "lcd_back", "action": "BACK", "label": "BACK"}]
}
```

These are **illustrative art-local pixels**, not actual measurements; validate per accepted PNG. The export compiler must ensure old `v1` three-button skins and third-party extensions still function while `v2` uses variable controls. Never force v1 shells into fake `left/center/right` assumptions. A skin manifest cannot register new gameplay authority.

### Normalized event lifecycle

- `pointer_down(control_id, pointer_id, timestamp)`: lock target, begin down/hold state and schedule local feedback. No duplicate SELECT on release.
- `pointer_move(pointer_id, dx, dy, timestamp)`: while captured, accumulate knob movement into bounded, discrete detents; pointer leaving does not silently drop a held PTT.
- `pointer_up(pointer_id, timestamp)`: release active control, end PTT, commit click exactly once where relevant.
- `pointer_cancel(reason)`: release capture and held PTT on window close, lost focus, game pause, device loss/invalid state, drag cancel, pointer-up outside, and unexpected UI teardown.
- `wheel(control_id, delta)`, `key_down/up`, `joypad_down/up`, `tick_ms` for explicit elapsed-time simulation. Do not rely on frame count for time.
- `press(control_id)` is a **legacy discrete convenience** translated to down+up for momentary keys, **not** PTT hold.

A single state reducer normalizes commands; an animation coordinator consumes *state changes*, not raw arbitrary client page strings. Separate `physical` (radio authority/source of truth), `navigation`, `input gesture`, and `visual` (ephemeral) states; report them separately. No replay of active transmitting status across sessions.

### Physical visual transitions

| Component kind | Input | Visual states and motion |
|---|---|---|
| momentary key / D-pad | down/up/cancel | idle -> pressed/inset -> release, short bounded tween |
| power toggle | click/detent | off/on frames and optional LED, never fake game power |
| rotary encoder | wheel, captured drag, optional click step | 8–16 **authored** or pre-rendered frame angles, pivot-locked, snap, short interpolation; do not recomposite/filter large textures every frame |
| PTT | down/hold/up/cancel | idle/held/released; TX feedback only when actual transmit allowed |
| RX/TX/PWR LED | device state | off/steady/blink/pulse/glow, layered emissive mask; no status updates from guessed signal |
| LCD | page/focus/result | lightweight scanline/focus/refresh cues; clipped content, no mandatory long transitions |
| wear/glass | static variant | independent mask/overlay aligned to physical chassis, must not cover interaction text |

**Target performance:** lazy-load/cache textures on demand; advance animation only while window open and transition active; no always-on `OnTick` listeners per device. Prefer sprite-frame tables and event-triggered invalidation over repeated pixel transformation. Measure normal-game cost with existing Psychopatz profiler after implementation; no unmeasured numerical guarantees.

## Compatibility and integration

- Preserve `PsychopatzRadioOS` app/contact registry, `Window:back()`, scaling, LCD matte sandwich, stencil/clipping, optional portraits, host-window restore and existing bridge/network authorization.
- Preserve Project Hoomans NPC contacts/relations, Dynamic Trading's remote trade request, DTCommon authoritative settlement, DTAbstract checks and any DTHoomans physical-merchant verification. A new `CALL`, `PTT` or `SCAN` button must not bypass any provider's authorization; no raw Lua action execution.
- Do not make real transmission dependent on local visual state; when server rejects a command, unwind pressed/request state and present a clear LCD status. No fake signal/reception manipulation in production.
- The current `tools/asset_harness/simulator/` is an excellent agent-visible test driver; extend it with command fixtures and PNG snapshots rather than building another simulation/UI app. No requirement for Flask/Tk to execute CLI. Simulator source renders do not prove native Build 42 acceptance.
- Treat existing sprite atlas/UI fonts/zoom patches as compatibility assets. Full per-device `common/media/ui/psychopatz/radio/devices/<family>/<model>/` is the production destination.
- No broken PZ Headless Harness, native spoofing, save changes or arbitrary execution. Normal Build 42 SP and multiplayer are required at final native gates.

## Acceptance

At minimum, v2's US Army pilot must demonstrate: (a) visually distinct radio-shaped computer at intended game UI scale, (b) identifiable and clickable Back/Home/OK and LCD rows, (c) Back stack and accessible keyboard/joypad equivalents, (d) knob step visibly changes physical knob angle AND proper value, (e) PTT visual hold/releases/cancels reliably, (f) power/TX/RX indicators follow true available state, (g) clean/worn art remains aligned, (h) identical semantic scenario output in Python vs Lua under mocks, (i) Hoomans/DT provider regressions unaffected, and (j) explicitly separate offline/image/native SP/native MP/profiler evidence.
