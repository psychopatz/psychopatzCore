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
    validate_predicate,
    validate_scalar_conditions,
    validate_source_refs,
    validate_typed_arguments,
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
    "source_owned_module",
    "validate_predicate",
    "validate_scalar_conditions",
    "validate_source_refs",
    "validate_source_metadata",
    "validate_typed_arguments",
]
