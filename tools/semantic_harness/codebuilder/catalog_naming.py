"""Stable, compact names for generated semantic catalog modules."""

from __future__ import annotations

import hashlib
import re
from collections.abc import Iterable
from pathlib import PurePosixPath

from .errors import CompileError


class CatalogNameError(CompileError):
    """Raised when generated catalog names cannot be made unambiguous."""


def pascal_segment(value: str) -> str:
    """Convert a semantic identifier fragment into a readable Lua segment."""
    words = re.findall(
        r"[A-Z]+(?=[A-Z][a-z]|\d|$)|[A-Z]?[a-z]+|\d+",
        str(value),
    )
    if not words:
        return "Catalog"
    return "".join(word[:1].upper() + word[1:].lower() for word in words)


def compact_hash(value: str, length: int = 8) -> str:
    """Return a deterministic, compact collision suffix."""
    return hashlib.sha1(value.encode("utf-8")).hexdigest()[:length]


def compact_segment(
    value: str,
    canonical_id: str,
    *,
    maximum: int = 32,
) -> str:
    """Create a readable segment, hashing only when the label is too long."""
    slug = pascal_segment(value)
    if len(slug) <= maximum:
        return slug
    suffix = "__" + compact_hash(canonical_id)
    return slug[: max(1, maximum - len(suffix))] + suffix


class ModuleNameRegistry:
    """Detect same-directory name collisions without relying on file order."""

    def __init__(self) -> None:
        self._names: dict[tuple[str, str], str] = {}

    def child(
        self,
        parent: str,
        label: str,
        canonical_id: str,
    ) -> str:
        segment = compact_segment(label, canonical_id)
        key = (parent, segment)
        previous = self._names.get(key)
        if previous is not None and previous != canonical_id:
            segment = f"{segment}__{compact_hash(canonical_id)}"
            key = (parent, segment)
            previous = self._names.get(key)
            if previous is not None and previous != canonical_id:
                raise CatalogNameError(
                    "generated catalog module collision between "
                    f"{previous!r} and {canonical_id!r} at {parent}/{segment}"
                )
        self._names[key] = canonical_id
        return f"{parent}/{segment}"


def module_path(
    parent: str,
    segments: Iterable[str],
    canonical_id: str,
    registry: ModuleNameRegistry,
) -> str:
    """Build a scoped module path with collision checks on the final segment."""
    values = list(segments)
    if not values:
        raise CatalogNameError("generated catalog module requires a path segment")
    current = parent
    for segment in values[:-1]:
        current = f"{current}/{pascal_segment(segment)}"
    return registry.child(current, values[-1], canonical_id)


def module_file(relative_module: str) -> str:
    """Convert a Lua module path into its repository-relative source path."""
    return relative_module.replace("/", "/") + ".lua"


SOURCE_ROOT_SEGMENTS = frozenset({
    "content",
    "patterns",
    "flows",
    "ui",
    "behaviors",
    "beats",
    "affordances",
    "realization",
})


def source_owned_module(
    parent: str,
    source_shard: str,
    registry: ModuleNameRegistry,
) -> str:
    """Map one canonical source shard to one readable generated module path."""
    source = PurePosixPath(str(source_shard))
    if source.suffix.lower() != ".json":
        raise CatalogNameError(
            f"canonical source shard must be a JSON path: {source_shard!r}"
        )
    parts = list(source.with_suffix("").parts)
    if parts and parts[0] in SOURCE_ROOT_SEGMENTS:
        parts = parts[1:]
    if not parts:
        raise CatalogNameError(
            f"canonical source shard has no semantic path: {source_shard!r}"
        )
    return module_path(
        parent,
        parts,
        source.as_posix(),
        registry,
    )


__all__ = [
    "CatalogNameError",
    "ModuleNameRegistry",
    "SOURCE_ROOT_SEGMENTS",
    "compact_hash",
    "compact_segment",
    "module_file",
    "module_path",
    "pascal_segment",
    "source_owned_module",
]
