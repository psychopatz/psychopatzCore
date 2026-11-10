# Core Semantic Harness

This is the single executable Semantic Harness for PsychopatzCore and its
adopters. It owns the Python/Lua worker lifecycle, protocol, CodeBuilder,
inspection, GUI/studio, generic fixtures, testing, and Kahlua verification.

Adopters register provider manifests from their own repositories. Project
Hoomans/PNC and Dynamic Trading/DT provide policy, production adapters, and
content; neither repository contains another harness package.

## Profiles

- `core` — Core-only parsing and worker contracts.
- `pnc` — Core plus the Project Hoomans/PNC provider.
- `dtabstract` — Core plus DTAbstract, without PNC.
- `dthoomans` — Core plus DTHoomans, when explicitly selected.
- `combined` — Core plus PNC and DT composition.

## Running

```bash
PYTHONPATH=/path/to/psychopatzCore \
  python3 -m tools.semantic_harness --profile core --no-gui
```

The `semantic-lab` console entrypoint and `run_harness.sh` launcher are also
owned by this Core package. Provider manifests are resolved explicitly from
`tools/providers/<provider>/provider.json`.
