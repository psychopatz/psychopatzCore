# Core NPC Foundation — Agent Runbook

Read this first, then ARCHITECTURE.md, ROADMAP.md, PROGRESS.md and current PHASE doc. This goal covers three repositories; inspect all checked-out branches, recent commits, working-tree statuses, dependency versions, upstream divergence and existing goal docs before any writes.

## Parent-goal completion contract (mandatory, supersedes any single-chunk stop rule)

**Parent goal:** Finish the entire Core NPC Foundation across P1–P9, including real Core NPC identity/appearance codec/registry, portable personal inventory, non-destructive migration, shared social, generic agent journeys, shared map/interaction UI, DynamicTrading merchant/adopters, provider switching, and integration regression. P0A/P0B are accepted **subphase evidence only**. Current P1–P9 acceptance and remaining user-owned gates are recorded in PROGRESS.md; do not restart a phase already accepted there.

**Execution policy:** ONE bounded chunk **at a time** to protect source/authority. After each chunk: implement → test the real modules → commit coherent code/docs → update current PROGRESS → immediately start the next unaccepted mandatory chunk in this same /goal. Do not stop or ask for a new /goal merely because a test passed, a phase was accepted, a commit pushed, a documentation update completed, or the one-chunk ledger advanced. Do not make broad unreviewed changes across several phases at once.

**Parent status** remains `IN PROGRESS` until ALL developer-owned P1–P9 functionality and end-to-end cross-repository compatibility are implemented and verified. Prior "completed and pushed" may describe an individual chunk only. Before final handoff, verify Core-only and cross-adopter Create→Save→Reload→Get, exact inventory/voice/appearance/social/journey preservation, safe existing-save migration, DTAbstract/DTHoomans provider switching, and relevant UI/map/trading behavior, with real source-backed tests and measured performance; explicitly mark what requires USER-run native PZ SP/MP. No Workshop publication or native game launch by agent.

**Stop rules:** stop only for (a) ALL developer-owned mandatory gates passing, yielding `READY FOR USER LIVE TEST` (NOT full live acceptance), or (b) genuinely unavoidable technical/authorization/worktree conflict with specific evidence and no allowed fallback. If one chunk is blocked but another independent mandatory phase is safe, continue it and document the blocked dependency. Never pretend a mocked CandidateCodec, tests with no Core writer, static syntax or old progress counts prove full product acceptance.

**Documentation:** ROADMAP describes complete P0–P9 scope and each gate. While developer work remains, PROGRESS records parent status and the active chunk; after all developer gates pass, it records READY FOR USER LIVE TEST and the user-owned matrix. Preserve prior accepted evidence and do not rewrite unrelated Semantic Dialogue scope.

## Execution loop
1. Read current PROGRESS and phase gate. Re-audit code where source changed, not only prose.
2. Execute exactly ONE Next Chunk at a time; preserve unrelated work in all repositories. When accepted, immediately continue to the following mandatory chunk without ending the parent /goal.
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
Current verified status; changed owner repos and files; exact code paths; focused command outcomes; remaining unverified runtime/manual gates; commits pushed or unpushed; next bounded chunk only when developer work remains.
