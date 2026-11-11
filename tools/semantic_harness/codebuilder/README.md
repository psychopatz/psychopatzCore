# Semantic Harness CodeBuilder

CodeBuilder has one canonical Conversation authoring tree:

```text
sources/conversation/
├─ manifest.json
├─ content/
├─ patterns/
├─ flows/
├─ behaviors/
├─ beats/
├─ realization/
└─ ui/
```

`wordnet_concepts.json` remains the canonical reviewed lexicon mapping.

Generated artifacts follow the canonical source owner's package. Ownership is declared in each source shard's `source.owner` metadata; a missing owner defaults to `ProjectHoomans`.

Current package routes are:

- `PsychopatzCore` → `psychopatzCore/Contents/mods/PsychopatzCore/common/...`
- `ProjectHoomans` → `ProjectHoomans/Contents/mods/ProjectHoomans/common/...`

The combined Project Hoomans Conversation registry/manifest remains the adopter composition layer and may require Core-owned generated modules. CodeBuilder does not duplicate Core-owned modules under the PNC namespace.

The reviewed WordNet lexicon is generic semantic infrastructure and generates into PsychopatzCore.

## Generate Conversation artifacts

```bash
python3 tools/semantic_harness/codebuilder/build.py \
  --conversation-manifest \
  tools/semantic_harness/codebuilder/sources/conversation/manifest.json \
  --conversation-output-root . \
  --core-repository ../psychopatzCore
```

This deterministically generates owner-routed bounded Lua modules, the Hoomans composition registry/manifest and indexes, Hoomans Conversation-domain translation bundles, the generated Hoomans translation manifest, and per-artifact deterministic hashes/diffs from the canonical shard model.

Generated Lua/JSON is never an authoring source.

## Ownership rules

Move a generated artifact between packages by changing the canonical shard's `source.owner`; never move generated files by hand.

Logical Semantic Lab datasets may combine shards from different owners. Editing such a dataset preserves each physical shard's existing owner. A logical edit must not migrate package ownership as a side effect.

Generic Core-owned source currently includes the common parser pattern shards. Hoomans-specific dialogue content, response pools, backstory, gameplay capabilities, social behaviors/beats, commands/tasks, and UI remain Hoomans-owned unless their canonical source is explicitly migrated.

## Authoring service

Semantic Lab and agent workflows use logical dataset IDs backed directly by canonical shards:

- `semantic_flows`
- `common_dialogue`
- `grounded_personal`
- `wordnet_concepts`

Dialogue logical datasets combine their pattern and response shards in memory for validation and split writes back to those real shards. The preview/write service reports generated paths in the owning repository.

## Locales

EN is the required fallback. Other locales are data-driven through generic `translations` maps and generated translation discovery. Adding another locale must not require a CodeBuilder language whitelist.

## WordNet

WordNet generation targets PsychopatzCore by default:

```bash
python3 tools/semantic_harness/codebuilder/build.py \
  --wordnet-home /path/to/WordNet-3.0 \
  --core-repository ../psychopatzCore
```

`--output` may override the exact lexicon output path when needed.
