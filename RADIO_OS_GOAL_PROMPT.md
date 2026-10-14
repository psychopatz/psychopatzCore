# PsychopatzCore Radio OS — Luna/Codex Entry Point

This goal is **cross-repository**, not a Core-only rewrite. Execute it from an agent workspace containing `psychopatzCore`, `ProjectHoomans` and `DynamicTrading` checkouts (or discover accessible checkouts first). The full authoritative milestones/progress ledger are in `DynamicTrading/Docs/radio_os/`. If those sources are unavailable, do not guess the full project plan; inspect the actual repos and request the missing repository if indispensable.

```text
/goal

Build the reusable, modular Radio OS platform **in PsychopatzCore**, NOT in DTCommon or DTAbstract. Core owns device skins/atlases, cached renderer, OS navigation, Home/Settings, buttons/widgets, generic app registry, contact-provider registry, dynamic contact cards/portrait slots and public extension APIs so any future mod can register apps and contacts.

Read:
1. psychopatzCore/Docs/radio_os/CORE_RADIO_OS_CONTRACT.md
2. DynamicTrading/Docs/radio_os/DT_RADIO_OS_AGENT_RUNBOOK.md
3. DynamicTrading/Docs/radio_os/DT_RADIO_OS_CONTRACT.md
4. DynamicTrading/Docs/radio_os/DT_RADIO_OS_ROADMAP.md
5. DynamicTrading/Docs/radio_os/DT_RADIO_OS_PROGRESS.md

Inspect installed source, dependencies and native Project Zomboid Build 42 APIs before changing code. Reuse Core RadioDeviceState, RadioActions, RadioSignalHost and generic PortraitPanel instead of creating competing implementations. Migrate the six production walkie atlases, manifest, build tools and preview from DynamicTrading/DTAbstract into Core; preserve alpha cutouts and coordinate contracts. Do not mark HAM/manpack assets complete.

Project Hoomans registers its own contacts/discovery/phone-like radio applications in Core and retains NPC knowledge, portraits, dialogue and server authorization. Reuse real PNC WorldDiscovery radio_scan/call_contact actions as supported, but do not mistake discover/locate actions for actual NPC chatter. Dynamic Trading registers trader/scanner functionality without Core dependencies on it: DTCommon owns trading and existing V2 trade window, DTAbstract remote access when server-authorized even without a spawned NPC, DTHoomans real nearby NPC/role/proximity requirements. Never allow displayed radio contacts or client-selected modes to bypass authoritative access. Don't add a second trading screen/price/economy implementation to the device.

Work through R0–R9 unattended in small validated chunks, updating DynamicTrading/Docs/radio_os/DT_RADIO_OS_PROGRESS.md. Run offline tests and native B42 SP/MP where available, profile responsiveness and redraws, and check module load isolation/Core-only functionality. Commit and safely fast-forward push coherent changes per owning repository. Do not overwrite user edits or saves, reset/force-push, or invent native test success. Stop for actual dangerous/conflicting blockers, not routine authorization requests. Continue through all safe milestones.

Begin R0 now.
```
