"""Provider-neutral Conversation shard loading and assembly mechanics."""

from __future__ import annotations

from collections.abc import Callable, Mapping, Sequence
from pathlib import Path, PurePosixPath
from typing import Any

from .conversation_model import copy_json, fingerprint
from .errors import CompileError


DocumentReader = Callable[[Path, str], dict[str, Any]]
ShardCompiler = Callable[[dict[str, Any], dict[str, Any]], Any]
RecordIDExtractor = Callable[[dict[str, Any], dict[str, Any]], Sequence[str]]
OwnerResolver = Callable[[dict[str, Any], dict[str, Any]], str]


def _source_path(source_root: Path, entry: Mapping[str, Any]) -> Path:
    source_repository = entry.get("sourceRepository")
    source_relative = entry.get("sourcePath")
    if source_repository and source_relative:
        return Path(str(source_repository)) / Path(
            *PurePosixPath(str(source_relative)).parts
        )
    return source_root / Path(*PurePosixPath(str(entry["path"])).parts)


def assemble_shards(
    entries: Sequence[Mapping[str, Any]],
    *,
    source_root: Path,
    source_overrides: Mapping[str, Mapping[str, Any]] | None,
    read_document: DocumentReader,
    compile_shard: ShardCompiler,
    record_ids_for: RecordIDExtractor,
    owner_for: OwnerResolver,
) -> tuple[
    list[tuple[dict[str, Any], dict[str, Any], str]],
    list[dict[str, Any]],
    dict[str, dict[str, Any]],
]:
    """Load, compile, fingerprint, and report manifest-backed shards.

    Core owns only the assembly mechanics. Callers supply source parsing,
    domain compilation, record-ID extraction, and owner policy.
    """
    source_root = source_root.expanduser().resolve()
    overrides = dict(source_overrides or {})
    known_paths = {str(entry["path"]) for entry in entries}
    unknown_overrides = set(overrides) - known_paths
    if unknown_overrides:
        raise CompileError(
            "Conversation source override targets unknown shard(s): "
            + ", ".join(sorted(unknown_overrides))
        )

    loaded: list[tuple[dict[str, Any], dict[str, Any], str]] = []
    shard_reports: list[dict[str, Any]] = []
    source_documents: dict[str, dict[str, Any]] = {}
    for raw_entry in entries:
        entry = copy_json(raw_entry)
        path = str(entry["path"])
        if path in overrides:
            document = copy_json(overrides[path])
            if not isinstance(document, dict):
                raise CompileError(
                    f"Conversation source override must be an object: {path}"
                )
        else:
            document = read_document(_source_path(source_root, entry), "Conversation shard")

        compile_shard(document, entry)
        record_ids = sorted(
            str(record_id) for record_id in record_ids_for(document, entry)
        )
        owner = owner_for(document, entry)
        if not isinstance(owner, str) or not owner.strip():
            raise CompileError(f"Conversation shard {path} requires a valid owner")
        report = {
            "path": path,
            "kind": entry["kind"],
            "domain": entry["domain"],
            "order": entry["order"],
            "owner": owner,
            "fingerprint": fingerprint(document),
            "recordIDs": record_ids,
        }
        if entry.get("sourceRepository") and entry.get("sourcePath"):
            report["sourceOwner"] = entry["sourceOwner"]
            report["sourceRepository"] = entry["sourceRepository"]
            report["sourcePath"] = entry["sourcePath"]
        loaded.append((document, entry, report["fingerprint"]))
        shard_reports.append(report)
        source_documents[path] = document

    return loaded, shard_reports, source_documents


__all__ = [
    "DocumentReader",
    "OwnerResolver",
    "RecordIDExtractor",
    "ShardCompiler",
    "assemble_shards",
]
