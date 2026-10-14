# Radio OS UI Stabilization — Luna/Codex /goal (current priority)

**Use with the current PsychopatzCore, ProjectHoomans and DynamicTrading checkouts.** The initial framework and provider integrations exist already. Do not restart the original implementation roadmap.

```text
/goal

Stabilize and complete the existing **PsychopatzCore Radio OS UI**. The user has tested it in real Build 42 and shown that the physical radio shell draws, but the window is rigid, cannot be dragged or interactively resized/persisted, LCD text is crowded/clipped, actual icon atlas artwork is not rendered on Home, and app rows are not directly clickable. This is a UI FOUNDATION CORRECTION, not a new trade or NPC system.

Read in order:
1. psychopatzCore/Docs/radio_os/CORE_RADIO_OS_UI_STABILIZATION.md
2. psychopatzCore/Docs/radio_os/CORE_RADIO_OS_CONTRACT.md
3. DynamicTrading/Docs/radio_os/DT_RADIO_OS_AGENT_RUNBOOK.md
4. DynamicTrading/Docs/radio_os/DT_RADIO_OS_CONTRACT.md
5. DynamicTrading/Docs/radio_os/DT_RADIO_OS_ROADMAP.md
6. DynamicTrading/Docs/radio_os/DT_RADIO_OS_PROGRESS.md

NONNEGOTIABLE: DO NOT USE THE PZ HEADLESS HARNESS. It is broken and explicitly excluded. Do not install, repair, configure, run, query, depend on or create tasks involving that harness. Ordinary isolated offline Lua tests, assets checks, syntax/regressions and normal Project Zomboid Build42 launches are allowed. If you cannot operate normal PZ, label native tests pending and provide one concise manual in-game test checklist. Never claim mocks as in-game verification.

Start U0 (fresh read-only source re-audit, failing tests), then implement U1 movable/persisted uniform-scale frameless radio via existing Core window geometry helpers, U2 reliable layout/font measurement/clipping/paging, U3 actual atlas icons/button states/UI chrome, U4 clickable LCD apps/contact rows plus physical buttons/keyboard, U5 safe portrait/contact view, U6 integration regression and U7 native handoff/acceptance. These U0–U7 priority gates supersede the older R8/R9 completion sequence; previously implemented R0–R7 adapters should be preserved, not duplicated.

Critical affected Core files: PsychopatzRadioOSWindow.lua, _Input.lua, _Renderer.lua, _Pages.lua, _Contacts.lua, _Navigation.lua, PsychopatzRadioOSDevice.lua, PsychopatzRadioManifest.lua, and PsychopatzWindow geometry/resize/persistence helpers. Verify their actual interfaces; do not blindly subclass PsychopatzWindow if that forces an opaque generic titlebar. Keep the actual device casing frameless; drag only noninteractive shell regions, provide a visible resize grip, fixed 256:432 proportion, min/max and offscreen clamping, save player-specific position/scale across reopen and UI-resolution changes, and update all LCD/hardware hitboxes after rescaling. Clicking a screen row must select it; dragging must never trigger keys.

Do not change source radio PNGs merely to paper over broken layout. Existing six Core atlases should supply real app icons, buttons, statuses, and screen furniture dynamically. The LCD is ~72–83x55–61 source pixels; derive row fit from measured font and available space, paginate/zoom, and strictly clip text/portraits. No generic green placeholder bars as final UI. Keep portrait panels inside LCD, avoid per-frame texture reload or scans, keep runtime scalable and reusable for future mods.

Maintain Core-only module independence and extension APIs. ProjectHoomans owns NPC knowledge/portrait/conversation/discovery; DTCommon owns V2 trade UI/MarketSense/trader transactions; DTAbstract owns server-authorized remote trader access without spawned body, DTHoomans owns actual nearby merchant checks. No second radio trading basket/UI and no new fake conversational backend. Preserve and test these existing integrations while fixing presentation.

Work unattended, in small safe chunks. Run fail-first regression tests, scoped Lua/mock/PNG checks and all applicable existing unit suites; safely commit/push coherent changes to each owning repo and update DynamicTrading/Docs/radio_os/DT_RADIO_OS_PROGRESS.md with exact stage, evidence, regressions, SHAs, blockers and next step. Continue automatically rather than repeatedly asking for permission. Preserve unrelated edits, saves, installed mods and user's Git changes. No force-push or destructive reset.

Only mark U1–U7 'native passed' after evidence from a normal PZ Build42 SP/MP run (screenshots, actual interactions and logs). If native UI isn't accessible, finish safe offline work, provide one concise in-game reproduction/acceptance script, and explicitly leave native gates open. Don't claim production readiness until manual/native acceptance is real.

Begin U0 NOW, then continue through U1–U7 without waiting for routine approvals.
```
