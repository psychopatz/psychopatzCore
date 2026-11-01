# PsychopatzCore Modular Capability & Composition Refactor — Harness Acceptance

The refactor is not accepted by syntax checks or reorganized folders alone. The harness must prove demand-driven loading and lifecycle ownership.

## Mandatory capability tests

### Minimal Core

With no adopter capability requests:

- kernel boots successfully
- no optional feature implementation is required merely by root composition
- no optional recurring callback is installed
- feature registry can report REGISTERED features without loading them

### Dependency closure

Requesting a feature:

- loads/activates its declared dependencies exactly once
- records the requesting consumer and dependency reason
- rejects unknown dependencies
- rejects cycles with an actionable path
- does not activate unrelated sibling features

### Reference counting

When two consumers require one feature:

- feature remains active after one releases it
- feature can become dormant/deactivated only after the final consumer releases it, when runtime deactivation is supported

### Runtime roles

- client-only features do not activate on dedicated/server roles
- server-only features do not activate on client-only paths
- shared contracts remain available where declared

### Callback/resource ownership

The harness must observe event registrations or equivalent lifecycle-owned resources. For migrated features, an unrequested feature must contribute zero recurring hooks. Activation must install only the expected hooks; deactivation must remove them when supported.

### Dynamic Trading pilot

For Core + DTCommon and Core + DTAbstract configurations:

- Inventory/Currency/Translation and other explicitly declared requirements work
- Radio OS/device capabilities activate only when the relevant frontend requests them
- Traits, ZombieKillDetector, PlayerAnimation, unrelated Preview/Debug/UI and other unrequested features remain unloaded/inactive
- trading behavior and existing DT authority boundaries remain unchanged

### Regression

Run focused feature tests plus the broad Core smoke suite and affected adopter suites. Existing unrelated failures must be identified, not silently treated as new regressions or passed gates.

## Architecture acceptance

At major gates compare against P0:

- composition/dependency cycles
- cross-subsystem imports
- direct adopter imports of internal modules
- module-load count/set for representative configurations
- recurring callback/resource count
- common-change retrieval depth where measurable

The goal is not an arbitrary zero-file or zero-callback number. The requirement is explainable, demand-driven ownership.

## Native handoff

After developer acceptance, the user validates native PZ SP/MP startup, save/reload, UI behavior, multiplayer authority/reconnect and real performance. Do not claim these passed from headless tests.
