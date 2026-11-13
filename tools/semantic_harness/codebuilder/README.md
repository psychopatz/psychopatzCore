# Semantic Harness CodeBuilder

## Canonical authoring direction — ConvoEngine

**ConvoEngine** is the Core-owned first-party conversation authoring/compiler system shared by PsychopatzCore, ProjectHoomans, and DynamicTrading/DTCommon. The previous name **PSDL** meant **Psychopatz Semantic Dialogue Language**; `PSDL`/`psdl` is migration compatibility only and should not be introduced into new public APIs or final source/runtime paths. Normative goal documentation is in `Docs/semantic_dialogue_language_standard/`, with the compact agent contract in `CONVO_ENGINE.md`.

The current pre-ConvoEngine/legacy conversation source tree remains migration input while domains move to the final ConvoEngine model:

```text
sources/conversation/
├─ manifest.json
├─ content/       # migration input
├─ patterns/      # migration input where dialogue-specific
├─ flows/         # migration input
├─ responses/     # migration input where present
├─ ui/            # migration input for split suggestion authoring
├─ behaviors/     # migration input
├─ beats/         # migration input
└─ realization/   # migration input
```

Target steady-state authoring is organized by semantic module kind:

```text
sources/conversation/
├─ manifest.json
├─ dialogue/
├─ behaviors/
├─ beats/
└─ realization/
```

Do not add new first-party production dialogue to frozen old source kinds merely because migration is incomplete. Do not create `Legacy/`, `Compat/`, `Old/`, `V1/`, `Migrated/` or `PartNN/` copies. Existing old records are converted by semantic domain and deleted after parity/caller-zero proof. ProjectHoomans and DynamicTrading may own adopter-specific records, but must consume this Core compiler/service rather than duplicating it.

Every authored recipe keeps locale text with the semantic record it describes; generated runtime translation files are never read back as authoring source.
Content phrase arrays use explicit stable records; array position is not identity:

```json
{
  "styles": {
    "neutral": [
      {
        "EN": "Good morning.",
        "TL": "Magandang umaga."
      }
    ]
  }
}
```

UI suggestions use the same principle with a `display` locale map. Their
runtime `labelKey` and `utteranceKey` are generated from the source ID and
shard `textNamespace` at compile time. UI text-only records use `display` and
derive one runtime key from their ID.

Realization construction recipes also keep all locales in one source record:

```json
{
  "id": "construction.social.acknowledge",
  "type": "construction",
  "strategy": "ACKNOWLEDGE",
  "translations": {
    "EN": [{"kind": "literal", "value": "I hear you."}],
    "TL": [{"kind": "literal", "value": "Naririnig kita."}]
  }
}
```

The compiler expands that record to the existing locale-specific runtime IDs;
`locale` and `tokens` are generated fields, never authoring fields.

`wordnet_concepts.json` remains the canonical reviewed lexicon mapping.

Generated artifacts follow the canonical source owner's package. Ownership is
declared by the manifest entry and its source profile; a missing owner defaults
to `ProjectHoomans`. Runtime translation catalogs are emitted under each
owning mod's `common/media/translation/<LANG>` tree.

Current package routes are:

- `PsychopatzCore` → `psychopatzCore/Contents/mods/PsychopatzCore/common/...`
- `ProjectHoomans` → `ProjectHoomans/Contents/mods/ProjectHoomans/common/...`
- `DTCommon` → `DynamicTrading/Contents/mods/DTCommon/common/...`

The combined Project Hoomans Conversation registry/manifest remains the adopter composition layer and may require Core-owned generated modules. CodeBuilder does not duplicate Core-owned modules under the PNC namespace. Dynamic Trading keeps a provider-local `conversation/manifest.json` for standalone source audits while the Core manifest mounts its UI shard as an optional external composition.

The reviewed WordNet lexicon is generic semantic infrastructure and generates into PsychopatzCore.

## Generate Conversation artifacts

```bash
python3 tools/semantic_harness/codebuilder/build.py \
  --conversation-manifest \
  tools/semantic_harness/codebuilder/sources/conversation/manifest.json \
  --conversation-output-root . \
  --core-repository ../psychopatzCore
```

This deterministically generates owner-routed bounded Lua modules, composition
registries, and package-owned Conversation translation catalogs from the
canonical shard model. UI strings are maintained in the owning mod's common
translation catalogs and are not CodeBuilder dialogue sources. Generated UI
entries are merged into the existing package catalog so shared Core UI keys
authored outside CodeBuilder are never deleted by a rebuild.

Generated Lua/JSON is never an authoring source.

### Agent authoring rule

Agents must use the shared CodeBuilder ConvoEngine authoring/migration service for bulk conversation-content creation, sharding, moves, and writes once the required operation exists. Do not manually manufacture destination JSON trees or hand-edit/move generated runtime files. Direct file edits are appropriate for CodeBuilder/compiler/tests/docs themselves. The S6M roadmap adds a small headless create/edit/move/shard/write front door so Luna-class agents can follow this rule without custom Python snippets.

Final ConvoEngine runtime routing removes redundant path taxonomy: conversation-owned output converges from `<Owner>/Semantics/Generated/Conversation/PSDL/...` to `<Owner>/ConvoEngine/...`. Generic Core semantic infrastructure that is broader than conversation remains under `PsychopatzCore/Semantics/`. Generated provenance remains in headers/manifests/fingerprints rather than the directory name.

## Ownership rules

Move a generated artifact between packages by changing the canonical shard's `source.owner`; never move generated files by hand.

Logical Semantic Lab datasets may combine shards from different owners. Editing such a dataset preserves each physical shard's existing owner. A logical edit must not migrate package ownership as a side effect.

Generic Core-owned source currently includes the common parser pattern shards
and shared conversation UI translations. Hoomans-specific dialogue content,
response pools, backstory, gameplay capabilities, social behaviors/beats,
commands/tasks, and suggestion definitions remain Hoomans-owned unless their
canonical source is explicitly migrated.

## Authoring service

Semantic Lab and agent workflows use logical dataset IDs backed directly by canonical shards:

- `semantic_flows`
- `common_dialogue`
- `grounded_personal`
- `wordnet_concepts`

Dialogue logical datasets combine their pattern and response shards in memory for validation and split writes back to those real shards. The preview/write service reports generated paths in the owning repository.

## Ownership and locales

Core owns provider-neutral compiler and runtime contracts. Adopters own their
gameplay recipes and UI content. A logical dataset may combine those shards,
but editing it must preserve each record's physical owner.

EN is the required fallback locale. Other locales are discovered from inline
`translations` or `display` maps; adding a locale does not require a language
whitelist.

## WordNet

WordNet generation targets PsychopatzCore by default:

```bash
python3 tools/semantic_harness/codebuilder/build.py \
  --wordnet-home /path/to/WordNet-3.0 \
  --core-repository ../psychopatzCore
```

`--output` may override the exact lexicon output path when needed.
