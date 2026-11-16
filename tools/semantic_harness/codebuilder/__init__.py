"""Core-owned provider-neutral CodeBuilder contracts and mechanisms.

Adopters provide source manifests, semantic catalogs, package ownership, and
artifact destinations. This package supplies shared validation errors,
translation normalization, and deterministic generated-module naming.
"""

from .catalog_naming import (
    CatalogNameError,
    ModuleNameRegistry,
    compact_hash,
    compact_segment,
    module_file,
    module_path,
    pascal_segment,
    source_owned_module,
)
from .dataset_compiler import compile_typed_dataset
from .dataset_contract import (
    DATASET_UTTERANCE,
    load_dataset_document,
    normalize_utterance,
    validate_source_metadata,
)
from .errors import CompileError
from .translation_support import (
    DEFAULT_LANGUAGE,
    merge_language_sets,
    normalize_language,
    normalize_translations,
    pretty_json,
)
from .rule_contract import (
    PREDICATE_OPERATORS,
    normalize_predicate,
    validate_predicate,
    validate_scalar_conditions,
    validate_source_refs,
    validate_typed_arguments,
)
from .source_manifest import (
    SourceManifestError,
    load_external_shard_entries,
    validate_relative_json_path,
    validate_relative_repository_path,
)
from .conversation_model import (
    canonical_json,
    copy_json,
    fingerprint,
    merge_source_metadata,
    register_global_id,
    runtime_records,
)
from .conversation_assembler import (
    assemble_shards,
)
from .conversation_source_audit import (
    audit_conversation_sources,
)
from .semantic_dialogue_ir import (
    CANONICAL_IR_SCHEMA,
    CONVO_ENGINE_SCHEMA,
    LEGACY_PSDL_SCHEMA,
    SUPPORTED_SOURCE_SCHEMAS,
    canonical_ir_fingerprint,
    canonicalize_dialogue,
    normalize_participants,
    normalize_references,
    normalize_slots,
    normalize_target,
    validate_canonical_ir,
    validate_context_path,
)
from .convo_engine_authoring import (
    apply_family_patch,
    build_convo_engine_family_document,
    prepare_shard_documents,
    resolve_authorized_source_path,
)
from .convo_engine_exchange import (
    RUNTIME_TEXT_ROLES,
    TEXT_ROLE_BUTTON_LABEL,
    TEXT_ROLE_RESPONSE,
    TEXT_ROLE_SPOKEN_ACTION,
    validate_semantic_reference,
)
from .convo_engine_ownership_inventory import (
    OWNERSHIP_INVENTORY_SCHEMA,
    build_ownership_inventory,
    map_generated_convo_engine_module,
)
from .generation_recipe import (
    DEFAULT_RECIPE_PATH,
    DESIRED_LEDGER_SCHEMA,
    DesiredArtifactLedger,
    DesiredArtifactRow,
    GENERATION_RECIPE_SCHEMA,
    GenerationRecipe,
    RetiredEntry,
    SurfaceRecipe,
    build_desired_artifact_ledger,
    load_generation_recipe,
    validate_generation_recipe,
)
from .reconcile import (
    GENERATION_RECEIPT_SCHEMA,
    RECONCILIATION_REPORT_SCHEMA,
    check_owner_surface_state,
    load_owner_receipt,
    reconcile_apply,
    reconcile_check,
    write_owner_receipt,
)
from .psdl_compiler import (
    CONVO_ENGINE_COMPILED_SCHEMA,
    PSDL_COMPILED_SCHEMA,
    PSDL_KINDS,
    PSDL_SCHEMA,
    compile_convo_engine_document,
    compile_convo_engine_sources,
    compile_psdl_document,
    compile_psdl_sources,
    render_convo_engine_runtime_plan,
    render_psdl_director_plan,
    render_psdl_semantic_pack_plan,
    render_psdl_ui_plan,
    render_psdl_runtime_plan,
)

__all__ = [
    "CatalogNameError",
    "CompileError",
    "DATASET_UTTERANCE",
    "DEFAULT_LANGUAGE",
    "ModuleNameRegistry",
    "compact_hash",
    "compact_segment",
    "compile_typed_dataset",
    "load_dataset_document",
    "merge_language_sets",
    "module_file",
    "module_path",
    "normalize_language",
    "normalize_utterance",
    "normalize_translations",
    "pascal_segment",
    "pretty_json",
    "PREDICATE_OPERATORS",
    "normalize_predicate",
    "source_owned_module",
    "validate_predicate",
    "validate_scalar_conditions",
    "validate_source_refs",
    "validate_source_metadata",
    "validate_typed_arguments",
    "SourceManifestError",
    "load_external_shard_entries",
    "validate_relative_json_path",
    "validate_relative_repository_path",
    "canonical_json",
    "copy_json",
    "fingerprint",
    "merge_source_metadata",
    "register_global_id",
    "runtime_records",
    "assemble_shards",
    "audit_conversation_sources",
    "CANONICAL_IR_SCHEMA",
    "CONVO_ENGINE_COMPILED_SCHEMA",
    "CONVO_ENGINE_SCHEMA",
    "OWNERSHIP_INVENTORY_SCHEMA",
    "build_ownership_inventory",
    "map_generated_convo_engine_module",
    "LEGACY_PSDL_SCHEMA",
    "RUNTIME_TEXT_ROLES",
    "SUPPORTED_SOURCE_SCHEMAS",
    "TEXT_ROLE_BUTTON_LABEL",
    "TEXT_ROLE_RESPONSE",
    "TEXT_ROLE_SPOKEN_ACTION",
    "apply_family_patch",
    "build_convo_engine_family_document",
    "canonical_ir_fingerprint",
    "canonicalize_dialogue",
    "compile_convo_engine_document",
    "compile_convo_engine_sources",
    "normalize_participants",
    "normalize_references",
    "normalize_slots",
    "normalize_target",
    "prepare_shard_documents",
    "render_convo_engine_runtime_plan",
    "resolve_authorized_source_path",
    "validate_canonical_ir",
    "validate_context_path",
    "validate_semantic_reference",
    "PSDL_COMPILED_SCHEMA",
    "PSDL_KINDS",
    "PSDL_SCHEMA",
    "compile_psdl_document",
    "compile_psdl_sources",
    "render_psdl_director_plan",
    "render_psdl_semantic_pack_plan",
    "render_psdl_ui_plan",
    "render_psdl_runtime_plan",
]
