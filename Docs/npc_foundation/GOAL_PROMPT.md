# Core NPC Foundation — Continuous /goal

```text
/goal

Repository scope:
- /home/psychopatz/Zomboid/Workshop/psychopatzCore
- /home/psychopatz/Zomboid/Workshop/ProjectHoomans
- /home/psychopatz/Zomboid/Workshop/DynamicTrading

PARENT GOAL:
Repair the reopened Core NPC Foundation presentation/integration contract exposed by the 2026-11-03 audit. Preserve accepted canonical actor foundations, but finish the missing one-Core-map-host, authority→client actor presentation sync, production persistence, and production provider orchestration needed by Hoomans and DTAbstract.

READ:
Core AGENTS.md, then Docs/npc_foundation/AGENT_RUNBOOK.md, ARCHITECTURE.md, ROADMAP.md, PLAN.md, and PROGRESS.md LAST.
Also read DynamicTrading/Docs/Jobs/DTAbstractWorldSimulationPresentation/AUDIT.md, ARCHITECTURE.md, ROADMAP.md, and PROGRESS.md.

CURRENT START:
C1 / DynamicTrading R0-R1.
Add fail-first coverage for the missing Core map host and split authority/client projection, then implement the smallest generic Core seams and migrate adopters.

HARD RULES:
- existing main only; no new branches;
- preserve unrelated work;
- one Core production ISWorldMap host only;
- Hoomans/DT register layers/tools through Core;
- adopter-specific policy remains with adopter;
- no shared in-process registry in client/server acceptance;
- production persistence must exercise real lifecycle entry points;
- no duplicate actors, bodies, inventories, economy owners, provider leases, or map hooks;
- no Workshop/native PZ publication or launch unless explicitly authorized.

CONTINUE automatically through C1-C6 / DT recovery R0-R7. A green helper test or one phase is not completion.

FINAL developer status is READY FOR USER LIVE TEST only after all reopened map/network/persistence/orchestration gates pass. Otherwise report the exact blocker.
```
