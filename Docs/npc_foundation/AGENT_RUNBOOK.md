# Core NPC Foundation — Agent Runbook

Read this first, then ARCHITECTURE.md, ROADMAP.md, PROGRESS.md and current PHASE doc. This goal covers three repositories; inspect all checked-out branches, recent commits, working-tree statuses, dependency versions, upstream divergence and existing goal docs before any writes.

## Execution loop
1. Read current PROGRESS and phase gate. Re-audit code where source changed, not only prose.
2. Execute exactly the one Next Chunk; preserve unrelated work in all repositories.
3. Use the actual Project Zomboid Lua and mod APIs. Make a focused failing behavior test *before* extraction when feasible. Do not waste time building JSON-only simulations unrelated to the running code.
4. Run focused tests, Lua syntax/Kahlua checks, actual mod bootstrap/harness interactions where available, then broader dependency regressions. Clearly separate mocked, source-backed harness, native/headless (only if explicitly permitted), and USER MANUAL real-game evidence.
5. Update roadmap/progress/runbook only as appropriate, commit coherent validated changes in owner repo(s), and report SHA and test commands/results. Advance to next bounded Next Chunk only when acceptance supported.
6. Do not overwrite root GOAL_PROMPT.md of DynamicTrading, any Radio OS goal, or existing Hoomans semantic jobs.

## Non-negotiable safety
- NEVER publish or republish to Steam Workshop, upload mod builds, touch workshop.txt publication fields, or claim user authorization from an earlier agent error.
- Final normal-game SP/MP live playtest belongs to USER. Agents may prepare exact manual instructions and inspect user-provided logs; never claim it passed when not executed.
- Do not run PZ headless native harness for this project unless user separately authorizes it. Synthetic Lua/unit tests are encouraged but must not replace functional harness interaction or manual live tests.
- Do not reset, discard or overwrite installed saves, player worlds, configs, assets, uncommitted user changes or other jobs.
- Use fetch and fast-forward-safe integration; no ambiguous git pull, force push or conflict overwrite. Push only to authorized GitHub destination under existing project policy after checking local/remote divergence. A Git commit is NOT authorization for Workshop publication.
- Read ProjectHoomans/AGENTS.md before editing Hoomans media. Never stage temporary directories inside watched media/ tree; Project Zomboid debug file watcher can break.
- Do not use pcall/xpcall for ordinary flow control in Hoomans; respect existing source conventions and explicit external-callback guardrails.
- Incompatible or unknown legacy schema: do not call old reset/prune writer or overwrite the source; return actionable failure and keep a readable backup/recovery path.
- Engine objects never persist in Core NPC records. Never duplicate item IDs, merchant stock, actor records or live-body leases.
- Only one journey authority; server owns all authoritative changes. Mod-agnostic Core must not require PNC/DT classes.
- Preserve MarketSense valuation authority and DTCommon stock/transaction authority.

## Genuine stop / ask conditions
Unclear destructive save migration; Git conflicts with user work; missing permission; incompatible native mechanism with no safe fallback; unauthorized public publish/release; unresolvable gameplay product choice. Missing manual game test is an OPEN gate, not a reason to misreport success or publish.

## Reporting format
Current phase/chunk; changed owner repos and files; exact code paths; focused command outcomes; remaining unverified runtime/manual gates; commits pushed or unpushed; next bounded chunk, or true blocker.
