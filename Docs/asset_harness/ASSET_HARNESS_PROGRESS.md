# Psychopatz Asset Harness — Progress Ledger

**Updated:** 2026-10-15. **Status:** documentation committed; implementation **not started** by this goal-writing session.

## Immediate next task: H0

Read `ASSET_HARNESS_AGENT_RUNBOOK.md`, `ASSET_HARNESS_CONTRACT.md`, `ASSET_HARNESS_ROADMAP.md`; re-audit current HEAD across Core (and consumers only for compatibility). Inspect *actual code*, not just README:

- `tools/profiler/profiler_cli.py`, `profiler_core.py`, `bridge/client.py`, `bridge/transport.py`, tests and `docs/profiler.md`
- `tools/radio_os/`, `tests/radio_os/`, Core Radio OS manifests and actual `common/media/ui/psychopatz/radio` PNGs
- `docs/preview-framework.md`, `Preview/PC_PreviewSnapshot.lua`, `docs/bridge-capabilities.md`
- `Docs/radio_os/CORE_RADIO_DEVICE_ASSETS.md`

Produce a verified reuse/new-work matrix, file/path and CLI schema, tests baseline, catalog of actual available/approved art and a bounded first H1 implementation chunk. Continue automatically through safe tasks.

## Verified baseline from the planning review

- Core main HEAD at planning: `834220758bc7b588de629fd8131855102f823997`; refresh HEAD on every agent run.
- Existing Python profiler CLI returns bounded JSON, has tests and supports `bridge status|ping|capabilities`.
- Existing optional local external bridge has validated explicit capabilities and separate opt-in configuration; this does **not** establish an asset-harness-specific live capability.
- Existing radio Python atlas builders and alpha/compositor smokes exist; active manifest still uses v1 six-walkie atlas, not individual device v2.
- Core's reusable game images are under `Contents/mods/PsychopatzCore/common/media/ui/`; six legacy radio atlases remain active.
- Original 11 generated concept PNG binaries have **not been verified as Git-tracked**, and concept art should not be treated as approved/faithful game-device art.
- Python Flask UI, standalone asset CLI, image-region command suite and production export are **proposed only**.
- Native PZ GUI, HAM/manpack correctness and profiler verification are **pending**. PZ Headless Harness prohibited.

## H phase status

| Phase | Source | Unit | Image | CLI | Export | Native |
|---|---|---|---|---|---|---|
| H0 | **NEXT** | pending | pending | pending | N/A | N/A |
| H1–H3 | not started | pending | pending | pending | N/A | N/A |
| H4–H5 | not started | pending | pending | pending | N/A | N/A |
| H6 | not started | pending | pending | pending | pending | pending |
| H7 | not started | pending | pending | pending | pending | pending |
| H8 | not started | pending | pending | pending | pending | pending |
| H9 | not started | pending | pending | pending | pending | pending |

## Agent update format (append per checkpoint)

```text
Date / HEAD:
Phase completed / next:
Ownership and changed files:
Reused code vs new modules:
Commands actually run and test results:
JSON preview / PNG artifact paths + SHA-256:
Source/master provenance and approval state:
Native SP / Native MP / profiler: verified or pending:
Git commit SHA / push state:
Blockers / exact next action:
```

No implementation success claims in this documentation-only commit. Do not regenerate, overwrite or mark approved radio skins without real input art and verification.
