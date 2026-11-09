# Semantic Harness Migration Roadmap

## Phase 0 — Contract seam

- establish Core-owned provider/profile descriptors;
- discover Core as required and adopters independently;
- accept legacy `PNC_HARNESS_*` names only as reported compatibility aliases;
- prove Core-only resolution without Hoomans or DynamicTrading.

## Phase 1 — Core worker kernel

- move the bounded JSON-lines protocol and worker lifecycle;
- add a Core-only Lua worker bootstrap;
- expose startup capabilities and module manifests;
- keep provider loading behind the descriptor boundary.

## Phase 2 — CodeBuilder

- move the generic compiler and package ownership descriptors;
- keep Hoomans and DT source datasets in their owning repositories;
- make generated registries and translations package-local and deterministic.

## Phase 3 — Provider adapters

- register the Project Hoomans provider;
- register DTCommon and DTAbstract;
- register DTHoomans as the physical materialization adapter;
- run the Core-only, Hoomans, DTAbstract, DTHoomans, and combined matrix.

## Phase 4 — Shared tooling and cleanup

- move generic UI, inspection, studio, and test orchestration;
- remove Hoomans-specific defaults from generic projections;
- delete the compatibility launcher and old duplicate harness only after all
  profiles and generated-output checks pass.
