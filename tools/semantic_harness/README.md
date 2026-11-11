# Core Semantic Harness

This is the single executable Semantic Harness for PsychopatzCore and its
adopters. It owns the Python/Lua worker lifecycle, protocol, CodeBuilder,
inspection, GUI/studio, generic fixtures, testing, and Kahlua verification.

Adopters register provider manifests from their own repositories. Project
Hoomans/PNC and Dynamic Trading/DT provide policy, production adapters, and
content; neither repository contains another harness package.

The Python package is organized by ownership rather than keeping implementation
modules in this directory:

```text
entrypoints/  executable GUI and CLI modules
core/         provider-neutral lifecycle, state, and projection code
transport/    JSON-lines process and protocol primitives
providers/    provider discovery, profiles, and composition
discovery/    runtime and engine discovery
runtime/      Core worker orchestration and save/profile adapters
inspection/   transcript, response, and observatory views
codebuilder/  authoring and semantic generation pipeline
```

The package root contains only the package initializer and `__main__.py`; all
callers use the concrete modules in these owned packages.

## Selection manager

The harness is composed from provider manifests. Compatibility profiles are
data-defined presets; new providers can be added without changing Core code.

```text
core                  PsychopatzCore only
pnc                   PsychopatzCore + ProjectHoomans
dtabstract            PsychopatzCore + DTCommon + DTAbstract
dthoomans             PsychopatzCore + DTCommon + DTHoomans
pnc-with-dthoomans    ProjectHoomans conversation + DTHoomans trading
```

Inspect the available providers and presets:

```bash
bash tools/semantic_harness/run_harness.sh --list-mods --jsonl
bash tools/semantic_harness/run_harness.sh --list-presets --jsonl
```

## Running

```bash
PYTHONPATH=/path/to/psychopatzCore \
  python3 -m tools.semantic_harness --preset core --ping --no-gui
```

```bash
# Project Hoomans only
bash tools/semantic_harness/run_harness.sh --preset pnc --input "hello"

# Dynamic Trading without Project Hoomans
bash tools/semantic_harness/run_harness.sh --preset dtabstract --ping

# Project Hoomans conversation plus DTHoomans trading
bash tools/semantic_harness/run_harness.sh \
  --preset pnc-with-dthoomans --show-selection --jsonl

# Arbitrary future-provider composition
bash tools/semantic_harness/run_harness.sh \
  --mods ProjectHoomans,FutureExpansion --show-selection --jsonl
```

The `semantic-lab` console entrypoint and `run_harness.sh` launcher are also
owned by this Core package. Provider manifests are discovered from configured
repository roots and sibling workshop repositories. The resolver validates
dependencies, conflicts, materialization mode, load order, and capability
routes before starting a worker.
