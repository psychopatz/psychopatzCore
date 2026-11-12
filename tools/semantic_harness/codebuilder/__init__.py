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
    canonical_ir_fingerprint,
    canonicalize_dialogue,
    normalize_participants,
    normalize_references,
    normalize_slots,
    normalize_target,
    validate_canonical_ir,
    validate_context_path,
)
from .psdl_compiler import (
    PSDL_COMPILED_SCHEMA,
    PSDL_KINDS,
    PSDL_SCHEMA,
    compile_psdl_document,
    compile_psdl_sources,
    render_psdl_director_plan,
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
    "canonical_ir_fingerprint",
    "canonicalize_dialogue",
    "normalize_participants",
    "normalize_references",
    "normalize_slots",
    "normalize_target",
    "validate_canonical_ir",
    "validate_context_path",
    "PSDL_COMPILED_SCHEMA",
    "PSDL_KINDS",
    "PSDL_SCHEMA",
    "compile_psdl_document",
    "compile_psdl_sources",
    "render_psdl_director_plan",
    "render_psdl_runtime_plan",
]
