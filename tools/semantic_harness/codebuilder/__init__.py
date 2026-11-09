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
from .errors import CompileError
from .translation_support import (
    DEFAULT_LANGUAGE,
    merge_language_sets,
    normalize_language,
    normalize_translations,
    pretty_json,
)

__all__ = [
    "CatalogNameError",
    "CompileError",
    "DEFAULT_LANGUAGE",
    "ModuleNameRegistry",
    "compact_hash",
    "compact_segment",
    "merge_language_sets",
    "module_file",
    "module_path",
    "normalize_language",
    "normalize_translations",
    "pascal_segment",
    "pretty_json",
    "source_owned_module",
]
