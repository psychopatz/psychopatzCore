# Radio OS Compositor and Scaling — Luna/Codex /goal (current priority)

Use this goal with the current `psychopatzCore`, `DynamicTrading`, and `ProjectHoomans` checkouts. The core Radio OS already has a window, app/provider SDK, geometry/drag hooks and six atlases. **Do not rebuild them from scratch**.

```text
/goal

Fix the existing PsychopatzCore Radio OS's low-quality shell presentation, seemingly transparent LCD, inconsistent crop/composition, and undiscoverable/limited scaling, based on the user's two latest real Project Zomboid Build 42 screenshots. This is a focused COMPOSITOR / ASSET FIDELITY / ADAPTIVE ZOOM task, not new NPC or trading functionality.

Read in order:
1. psychopatzCore/Docs/radio_os/CORE_RADIO_OS_COMPOSITOR_SCALE.md
2. psychopatzCore/Docs/radio_os/CORE_RADIO_OS_UI_STABILIZATION.md
3. psychopatzCore/Docs/radio_os/CORE_RADIO_OS_CONTRACT.md
4. DynamicTrading/Docs/radio_os/DT_RADIO_OS_AGENT_RUNBOOK.md
5. DynamicTrading/Docs/radio_os/DT_RADIO_OS_ROADMAP.md
6. DynamicTrading/Docs/radio_os/DT_RADIO_OS_PROGRESS.md

IMPORTANT: ABSOLUTELY NO PZ HEADLESS HARNESS. Do not install, run, repair, inspect or use it. Use normal Project Zomboid Build 42 gameplay for native verification, offline Lua/Pillow tests for reproducible checks. If you cannot operate the actual game, finish safe offline tasks and provide one final manual screenshot/console.txt checklist. Never label mock tests as native.

Begin C0 by reviewing latest code/HEAD and comparing the actual alpha-zero screen opening in each PNG shell to the manifest's LCD rect, backing sprite alpha, render phases/stencil and child portrait order. Current renderer ALREADY tries drawing screen_bg_<theme> in prerender; don't simply assume no backing exists. Test whether its opaque coverage is smaller than the visible cutout or gets lost/covered due to blending, wrong UV/path or ISUI layering. Add exact atlas-alpha and synthetic layered-frame smoke tests plus optional in-game debug colored backplate/tint/bounds outlines (off by default).

C1: implement a correct skin-driven sandwich: optional shadow/back body; an actually OPAQUE matte LCD backplate fully covering only the intended aperture; themed LCD texture; clipped dynamic app content and provider portrait; optional low-alpha effects; front shell and physical keys/highlights. Ensure parent/child render stages and stencil do not leak; clear state even on render errors. Do not paint behind antenna/transparent outer body. Use shared transforms and declarative aperture/backplate/content inset per skin so future radio device families work.

C2: recover the best actual approved source assets without inventing them. Current shell atlas was downsized to a 341x341 compact source and then blown back up to 1024x1024 (confirmed in the builder), irreversibly discarding detail; do not call that high-res. Seek the genuine high-fidelity master already accessible in the project before changing art. If unavailable, note that limitation explicitly and retain approved style, while correcting texture sampling, UVs, alpha fringes and pixel-snapped drawing. Never replace art with generic or hyper-realistic radios.

C3: implement discoverable zoom in/out/reset/fit (mouse/UI and optionally keyboard), plus usable resize affordance, automatically fit to small and large real screen viewports, stable aspect ratio and one transform shared by shell, LCD, buttons and pointer hitboxes. Current opening clamp 0.75–2.25 and default max 1.75 are too rigid; derive limits from viewport with safety margin and preserve saved per-player/per-device preference using existing Core settings. Test 720p, 1080p, 1440p, 4K, UI scale, resolution changes and split-screen as possible. Bigger monitors may scale up; smaller ones can scale down. Do not distort 256:432 shell proportions.

C4: verify geometry, opacity and layering with deterministic offline composite/alpha-mask smoke tests for all six skins. Test per-skin transparent-hole coverage and sprite rect/cell mapping, pixel-snapped scale transformations, nonleaking clipping, hitboxes/resize control and overlay. Add a debug-only in-game backplate probe that colors each layer distinctly, proving the sandwich visually in normal gameplay. Native acceptance must be separately evidenced.

C5: make LCD content intentional and legible: page-fit text, paging, buttons/icons/indicators already present in the atlases, clipped portraits and actual provider actions. Don't cram big portraits and long contact names into the 72x55 content region; preserve Core generic API and use existing Hoomans portrait if authorized. No baked content, no new LLM/dialogue backend and no duplicate trade screen. Trade still hands off to existing V2.

C6: preserve all Core/Hoomans/DT functionality, radio-device authorization and server-side merchant security. Test Core only, combined mods, six radios, existing price/quote/settlement and abstract-without-NPC vs physical-nearby-NPC rules. Native SP/MP evidence requires a real normal game run; profiler measurements must also be genuine.

Work unattended in small validated changes. Commit and safely push coherent patches to each owning repo; log C phase, evidence classes (source/alpha image/Lua/native SP/native MP/profiler), test commands, SHAs, blockers and next chunk in DynamicTrading/Docs/radio_os/DT_RADIO_OS_PROGRESS.md. Preserve user code, saves, settings, installed mods and unrelated branches; never force push or destructively reset. Keep running independent safe tasks without recurring requests for permission. If high-resolution approved master is absent, record art limitation and still fix the compositor/scale.

Start C0 now and proceed automatically through C1–C6 as safely as possible, without falsely claiming native readiness.
```
