"""Lightweight compiler-owned ConvoEngine catalog & read model (Port B).

Discovers canonical single-family ConvoEngine JSON sources via
``WorkspaceSnapshot``, keeps only discovery-level summaries in bounded
fingerprint-keyed caches, and loads full documents strictly on demand.
"""

from __future__ import annotations

import hashlib
import json
import re
from collections import OrderedDict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from .catalog_naming import pascal_segment
from .conversation_model import canonical_json, fingerprint
from .convo_engine_exchange import collect_semantic_references
from .errors import CompileError
from .generation_ownership import (
    PACKAGE_DESCRIPTORS,
    OwnerConfigurationError,
    conversation_prefix,
    normalize_owner,
)
from .workspace_catalog import CONVO_SUBDIRS, WorkspaceSnapshot


CONVO_CATALOG_SCHEMA = "semantic.convo.catalog.v1"
_LOCALE_KEY_RE = re.compile(r"^[A-Z]{2}(?:-[A-Z0-9]{2,8})?$")

_MAX_FILE_SUMMARY_CACHE = 4096
_MAX_INDEX_CACHE = 16

# Process-local bounded caches: keyed strictly by file (path, mtime_ns, size)
# and aggregate workspace/file-stat signature.
_FILE_SUMMARY_CACHE: OrderedDict[tuple[str, int, int], "_ParsedSummary"] = OrderedDict()
_INDEX_CACHE: OrderedDict[tuple[str, tuple[tuple[str, str, int, int], ...]], "_CatalogIndex"] = OrderedDict()


def _safe_owner(raw: Any, fallback: str) -> str:
    candidate = raw if (isinstance(raw, str) and raw.strip()) else fallback
    try:
        return normalize_owner(candidate)
    except OwnerConfigurationError:
        return str(candidate).strip()


def _safe_prefix(owner: str) -> str:
    if owner in PACKAGE_DESCRIPTORS:
        return conversation_prefix(owner)
    return f"{owner}/ConvoEngine"


def _extract_locales(doc: Mapping[str, Any]) -> tuple[str, ...]:
    locales: set[str] = set()

    def visit(value: Any, depth: int) -> None:
        if depth > 6:
            return
        if isinstance(value, Mapping):
            for key, child in value.items():
                if isinstance(key, str) and _LOCALE_KEY_RE.fullmatch(key):
                    if isinstance(child, (str, list)):
                        locales.add(key)
                        continue
                visit(child, depth + 1)
        elif isinstance(value, list):
            for item in value[:32]:
                visit(item, depth + 1)

    for section in ("say", "reply", "affordance", "realization", "text"):
        if section in doc:
            visit(doc[section], 0)
    return tuple(sorted(locales))


def _predicted_generated_modules(
    *,
    owner: str,
    kind: str,
    rel_path: str,
    namespace: str | None,
    has_say_or_reply: bool,
    has_affordance: bool,
) -> tuple[str, ...]:
    prefix = _safe_prefix(owner)
    parts = Path(rel_path).parts
    domain = parts[1] if len(parts) >= 2 else (namespace or "general")
    domain_seg = pascal_segment(domain)
    kind_seg = pascal_segment(kind)
    modules: list[str] = [f"{prefix}/{kind_seg}/{domain_seg}"]
    if kind == "dialogue":
        if has_say_or_reply:
            modules.append(f"{prefix}/Responses/Dialogue/{domain_seg}")
            modules.append(f"{prefix}/Realization/Templates/{domain_seg}")
        if has_affordance:
            modules.append(f"{prefix}/UI/Dialogue/{domain_seg}")
    elif kind == "behavior":
        modules.append(f"{prefix}/Behaviors/Director/{domain_seg}")
    elif kind == "beat":
        modules.append(f"{prefix}/Beats/Director/{domain_seg}")
    elif kind == "realization":
        modules.append(f"{prefix}/Realization/Templates/{domain_seg}")
    return tuple(dict.fromkeys(modules))


@dataclass(frozen=True)
class _ParsedSummary:
    canonical_id: str
    raw_id: str
    namespace: str | None
    kind: str
    owner: str
    source_id: str
    path: str
    source_path: Path
    source_root: Path
    source_fingerprint: str
    schema: str | None
    fields_present: tuple[str, ...]
    locales: tuple[str, ...]
    execute_action: str | None
    has_invoke: bool
    has_affordance: bool
    has_execute: bool
    reply_outcomes: tuple[str, ...]
    recommend_refs: tuple[str, ...]
    goto_ref: str | None
    outgoing_refs: tuple[tuple[str, str], ...]
    generated_modules: tuple[str, ...]


@dataclass(frozen=True)
class FamilySummary:
    """Bounded discovery-level ConvoEngine family summary (no full prose payload)."""

    canonical_id: str
    raw_id: str
    namespace: str | None
    kind: str
    owner: str
    source_id: str
    path: str
    source_path: Path
    source_root: Path
    source_fingerprint: str
    schema: str | None
    fields_present: tuple[str, ...]
    locales: tuple[str, ...]
    execute_action: str | None
    has_invoke: bool
    has_affordance: bool
    has_execute: bool
    reply_outcomes: tuple[str, ...]
    recommend_refs: tuple[str, ...]
    goto_ref: str | None
    outgoing_refs: tuple[tuple[str, str], ...]
    incoming_refs: tuple[str, ...]
    generated_modules: tuple[str, ...]

    @property
    def incoming_reference_count(self) -> int:
        return len(self.incoming_refs)

    @property
    def outgoing_reference_count(self) -> int:
        return len(self.outgoing_refs)

    @property
    def generated_artifact_count(self) -> int:
        return len(self.generated_modules)

    def to_dict(self) -> dict[str, Any]:
        return {
            "sourceID": self.source_id,
            "owner": self.owner,
            "kind": self.kind,
            "namespace": self.namespace,
            "id": self.raw_id,
            "rawID": self.raw_id,
            "canonicalID": self.canonical_id,
            "path": self.path,
            "sourcePath": str(self.source_path),
            "sourceFingerprint": self.source_fingerprint,
            "schema": self.schema,
            "fieldsPresent": list(self.fields_present),
            "locales": list(self.locales),
            "hasInvoke": self.has_invoke,
            "hasAffordance": self.has_affordance,
            "hasExecute": self.has_execute,
            "executeAction": self.execute_action,
            "replyOutcomes": list(self.reply_outcomes),
            "recommendRefs": list(self.recommend_refs),
            "gotoRef": self.goto_ref,
            "incomingReferenceCount": self.incoming_reference_count,
            "outgoingReferenceCount": self.outgoing_reference_count,
            "generatedModules": list(self.generated_modules),
            "generatedArtifactCount": self.generated_artifact_count,
        }


@dataclass(frozen=True)
class _CatalogIndex:
    catalog_fingerprint: str
    entries: tuple[FamilySummary, ...]
    by_canonical_id: Mapping[str, FamilySummary]
    by_source_path: Mapping[Path, FamilySummary]
    by_source_id: Mapping[str, FamilySummary]


def _parse_family_summary(
    file_path: Path,
    source_root: Path,
    default_owner: str,
    subdir: str,
) -> _ParsedSummary | None:
    try:
        doc = json.loads(file_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return None
    if not isinstance(doc, Mapping) or "id" not in doc:
        return None
    owner = _safe_owner(doc.get("owner"), default_owner)
    kind = str(doc.get("kind") or subdir)
    namespace_raw = doc.get("namespace")
    namespace = str(namespace_raw) if isinstance(namespace_raw, str) and namespace_raw else None
    raw_id = str(doc.get("id"))
    canonical_id = f"{namespace}.{raw_id}" if namespace else raw_id
    rel = file_path.relative_to(source_root).as_posix()
    after = doc.get("after") if isinstance(doc.get("after"), Mapping) else {}
    reply = doc.get("reply") if isinstance(doc.get("reply"), Mapping) else {}
    execute = doc.get("execute")
    execute_id = (
        execute.get("use")
        if isinstance(execute, Mapping)
        else (execute if isinstance(execute, str) else None)
    )
    outgoing = tuple(
        collect_semantic_references({"id": canonical_id, "payload": doc})
    )
    has_say_or_reply = ("say" in doc) or bool(reply)
    has_affordance = "affordance" in doc
    generated_modules = _predicted_generated_modules(
        owner=owner,
        kind=kind,
        rel_path=rel,
        namespace=namespace,
        has_say_or_reply=has_say_or_reply,
        has_affordance=has_affordance,
    )
    return _ParsedSummary(
        canonical_id=canonical_id,
        raw_id=raw_id,
        namespace=namespace,
        kind=kind,
        owner=owner,
        source_id=f"{owner}:{rel}",
        path=rel,
        source_path=file_path.resolve(),
        source_root=source_root.resolve(),
        source_fingerprint=fingerprint(doc),
        schema=str(doc.get("schema")) if doc.get("schema") is not None else None,
        fields_present=tuple(sorted(str(k) for k in doc)),
        locales=_extract_locales(doc),
        execute_action=str(execute_id) if execute_id else None,
        has_invoke="invoke" in doc,
        has_affordance=has_affordance,
        has_execute=bool(execute_id),
        reply_outcomes=tuple(sorted(str(k) for k in reply)),
        recommend_refs=tuple(str(item) for item in (after.get("recommend") or []) if isinstance(item, str)),
        goto_ref=str(after.get("goto")) if isinstance(after.get("goto"), str) else None,
        outgoing_refs=outgoing,
        generated_modules=generated_modules,
    )


def _cached_parsed_summary(
    file_path: Path,
    source_root: Path,
    default_owner: str,
    subdir: str,
    mtime_ns: int,
    size: int,
) -> _ParsedSummary | None:
    cache_key = (str(file_path), mtime_ns, size)
    cached = _FILE_SUMMARY_CACHE.get(cache_key)
    if cached is not None and cached.source_root == source_root and cached.owner:
        # Note: if default_owner changed on same file without editing, re-check only when owner missing.
        _FILE_SUMMARY_CACHE.move_to_end(cache_key)
        return cached
    parsed = _parse_family_summary(file_path, source_root, default_owner, subdir)
    if parsed is not None:
        _FILE_SUMMARY_CACHE[cache_key] = parsed
        _FILE_SUMMARY_CACHE.move_to_end(cache_key)
        while len(_FILE_SUMMARY_CACHE) > _MAX_FILE_SUMMARY_CACHE:
            _FILE_SUMMARY_CACHE.popitem(last=False)
    return parsed


class ConvoCatalog:
    """Bounded read model and query/impact authority over canonical ConvoEngine sources."""

    def __init__(self, workspace: WorkspaceSnapshot) -> None:
        self.workspace = workspace

    def _build_index(self) -> _CatalogIndex:
        discovered_files: list[tuple[str, Path, Path, str, int, int]] = []
        seen_paths: set[Path] = set()
        sig_parts: list[tuple[str, str, int, int]] = []

        for default_owner, root in self.workspace.source_roots_for():
            if not root.is_dir():
                continue
            for subdir in CONVO_SUBDIRS:
                folder = root / subdir
                if not folder.is_dir():
                    continue
                for file_path in sorted(folder.rglob("*.json")):
                    resolved = file_path.resolve()
                    if resolved in seen_paths:
                        continue
                    seen_paths.add(resolved)
                    try:
                        st = resolved.stat()
                    except OSError:
                        continue
                    discovered_files.append(
                        (default_owner, root, resolved, subdir, st.st_mtime_ns, st.st_size)
                    )
                    sig_parts.append((default_owner, str(resolved), st.st_mtime_ns, st.st_size))

        cache_key = (self.workspace.workspace_fingerprint, tuple(sig_parts))
        cached_index = _INDEX_CACHE.get(cache_key)
        if cached_index is not None:
            _INDEX_CACHE.move_to_end(cache_key)
            return cached_index

        parsed_rows: list[_ParsedSummary] = []
        for default_owner, root, resolved, subdir, mtime_ns, size in discovered_files:
            parsed = _cached_parsed_summary(resolved, root, default_owner, subdir, mtime_ns, size)
            if parsed is not None:
                parsed_rows.append(parsed)

        parsed_rows.sort(
            key=lambda item: (item.owner, item.kind, item.canonical_id, item.path)
        )

        # Build incoming reference lookup across lightweight outgoing_refs.
        incoming_map: dict[str, set[str]] = {}
        for row in parsed_rows:
            for _label, target_ref in row.outgoing_refs:
                if target_ref:
                    incoming_map.setdefault(target_ref, set()).add(row.canonical_id)

        entries: list[FamilySummary] = []
        by_canonical_id: dict[str, FamilySummary] = {}
        by_source_path: dict[Path, FamilySummary] = {}
        by_source_id: dict[str, FamilySummary] = {}

        fp_hasher = hashlib.sha256()
        fp_hasher.update(self.workspace.workspace_fingerprint.encode("utf-8"))
        for row in parsed_rows:
            incoming = tuple(sorted(incoming_map.get(row.canonical_id, ())))
            summary = FamilySummary(
                canonical_id=row.canonical_id,
                raw_id=row.raw_id,
                namespace=row.namespace,
                kind=row.kind,
                owner=row.owner,
                source_id=row.source_id,
                path=row.path,
                source_path=row.source_path,
                source_root=row.source_root,
                source_fingerprint=row.source_fingerprint,
                schema=row.schema,
                fields_present=row.fields_present,
                locales=row.locales,
                execute_action=row.execute_action,
                has_invoke=row.has_invoke,
                has_affordance=row.has_affordance,
                has_execute=row.has_execute,
                reply_outcomes=row.reply_outcomes,
                recommend_refs=row.recommend_refs,
                goto_ref=row.goto_ref,
                outgoing_refs=row.outgoing_refs,
                incoming_refs=incoming,
                generated_modules=row.generated_modules,
            )
            entries.append(summary)
            by_canonical_id.setdefault(summary.canonical_id, summary)
            by_source_path[summary.source_path] = summary
            by_source_id[summary.source_id] = summary
            fp_hasher.update(
                f"|{summary.source_id}:{summary.source_fingerprint}".encode("utf-8")
            )

        index = _CatalogIndex(
            catalog_fingerprint=fp_hasher.hexdigest(),
            entries=tuple(entries),
            by_canonical_id=by_canonical_id,
            by_source_path=by_source_path,
            by_source_id=by_source_id,
        )
        _INDEX_CACHE[cache_key] = index
        _INDEX_CACHE.move_to_end(cache_key)
        while len(_INDEX_CACHE) > _MAX_INDEX_CACHE:
            _INDEX_CACHE.popitem(last=False)
        return index

    @property
    def catalog_fingerprint(self) -> str:
        return self._build_index().catalog_fingerprint

    def list_summaries(
        self,
        *,
        owner: str | None = None,
        kind: str | None = None,
    ) -> list[dict[str, Any]]:
        index = self._build_index()
        rows: list[dict[str, Any]] = []
        for entry in index.entries:
            if owner and entry.owner != _safe_owner(owner, owner):
                continue
            if kind and entry.kind != kind:
                continue
            rows.append(entry.to_dict())
        return rows

    def query(
        self,
        *,
        query: str = "",
        owner: str | None = None,
        kind: str | None = None,
        action: str | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> dict[str, Any]:
        """Search catalog summaries with bounded pagination (never returns full prose docs)."""
        index = self._build_index()
        needle = str(query or "").strip().lower()
        norm_owner = _safe_owner(owner, owner) if owner else None
        norm_kind = str(kind).strip().lower() if kind else None
        norm_action = str(action).strip().lower() if action else None

        matched: list[FamilySummary] = []
        for entry in index.entries:
            if norm_owner and entry.owner != norm_owner:
                continue
            if norm_kind and entry.kind.lower() != norm_kind:
                continue
            if norm_action and (entry.execute_action or "").lower() != norm_action:
                continue
            if needle:
                haystack = " ".join((
                    entry.canonical_id,
                    entry.raw_id,
                    entry.namespace or "",
                    entry.owner,
                    entry.kind,
                    entry.path,
                    entry.execute_action or "",
                )).lower()
                if needle not in haystack:
                    continue
            matched.append(entry)

        bounded_limit = max(1, min(int(limit), 200))
        bounded_offset = max(0, int(offset))
        page = matched[bounded_offset : bounded_offset + bounded_limit]
        return {
            "schema": CONVO_CATALOG_SCHEMA,
            "workspaceFingerprint": self.workspace.workspace_fingerprint,
            "catalogFingerprint": index.catalog_fingerprint,
            "total": len(matched),
            "limit": bounded_limit,
            "offset": bounded_offset,
            "truncated": (bounded_offset + len(page)) < len(matched),
            "items": [entry.to_dict() for entry in page],
        }

    def find_by_id(self, canonical_id: str) -> FamilySummary | None:
        return self._build_index().by_canonical_id.get(str(canonical_id).strip())

    def find_by_source(self, source_path: str | Path) -> FamilySummary | None:
        resolved = Path(source_path).expanduser().resolve()
        return self._build_index().by_source_path.get(resolved)

    def resolve_summary(self, target: str | Path) -> FamilySummary | None:
        index = self._build_index()
        key = str(target).strip()
        if key in index.by_canonical_id:
            return index.by_canonical_id[key]
        if key in index.by_source_id:
            return index.by_source_id[key]
        try:
            resolved = Path(target).expanduser().resolve()
        except OSError:
            return None
        return index.by_source_path.get(resolved)

    def get_family(
        self,
        target: str | Path,
        *,
        include_document: bool = True,
    ) -> dict[str, Any] | None:
        """Load one ConvoEngine family on demand by canonical ID, sourceID, or path."""
        summary = self.resolve_summary(target)
        if summary is None:
            return None
        payload: dict[str, Any] = {
            **summary.to_dict(),
            "incomingReferences": list(summary.incoming_refs),
            "outgoingReferences": [
                {"field": field_label, "target": ref}
                for field_label, ref in summary.outgoing_refs
            ],
        }
        if include_document:
            try:
                doc = json.loads(summary.source_path.read_text(encoding="utf-8"))
            except (OSError, UnicodeError, json.JSONDecodeError) as error:
                raise CompileError(f"cannot read family source {summary.source_path}: {error}") from error
            payload["document"] = doc
            payload["sourceFingerprint"] = fingerprint(doc)
        return payload

    def impact(
        self,
        target: str | Path,
        *,
        limit: int = 24,
    ) -> dict[str, Any] | None:
        """Return bounded incoming/outgoing impact & generated routing for one family."""
        index = self._build_index()
        summary = self.resolve_summary(target)
        if summary is None:
            return None
        bounded = max(1, min(int(limit), 128))
        outgoing_ids = list(dict.fromkeys(ref for _field, ref in summary.outgoing_refs))
        incoming_ids = list(summary.incoming_refs)
        closure_ids: list[str] = [summary.canonical_id]
        for ref_id in (*outgoing_ids, *incoming_ids):
            if ref_id not in closure_ids and len(closure_ids) < bounded:
                closure_ids.append(ref_id)

        related_summaries = [
            index.by_canonical_id[cid]
            for cid in closure_ids
            if cid in index.by_canonical_id
        ]
        sources = sorted({str(item.source_path) for item in related_summaries})
        generated = sorted({
            module
            for item in related_summaries
            for module in item.generated_modules
        })
        return {
            "id": summary.canonical_id,
            "owner": summary.owner,
            "sourcePath": str(summary.source_path),
            "sourceFingerprint": summary.source_fingerprint,
            "incomingCount": len(incoming_ids),
            "outgoingCount": len(outgoing_ids),
            "incoming": incoming_ids[:bounded],
            "outgoing": [
                {"field": field_label, "target": ref}
                for field_label, ref in summary.outgoing_refs[:bounded]
            ],
            "closureIDs": closure_ids,
            "sources": sources[:bounded],
            "generated": generated[:bounded],
            "truncated": (
                len(incoming_ids) > bounded
                or len(outgoing_ids) > bounded
                or len(closure_ids) >= bounded
            ),
            "safeToDeleteOrRename": len(incoming_ids) == 0,
            "catalogFingerprint": index.catalog_fingerprint,
        }

    def dangling_references_if_removed(
        self,
        removed_ids: Sequence[str],
        *,
        replacement_ids: Mapping[str, str] | None = None,
    ) -> list[dict[str, str]]:
        """Check whether removing or renaming *removed_ids* leaves dangling semantic refs."""
        index = self._build_index()
        removed = {str(item) for item in removed_ids if item}
        active_replacements = set((replacement_ids or {}).values())
        dangling: list[dict[str, str]] = []
        for entry in index.entries:
            if entry.canonical_id in removed:
                continue
            for field_label, target_ref in entry.outgoing_refs:
                if target_ref in removed and target_ref not in active_replacements:
                    dangling.append({
                        "callerID": entry.canonical_id,
                        "callerSourcePath": str(entry.source_path),
                        "field": field_label,
                        "target": target_ref,
                    })
        return dangling

    def default_source_path(
        self,
        owner: str,
        kind: str,
        namespace: str | None,
        family_id: str,
    ) -> Path:
        """Compute canonical destination file path inside the resolved owner repository."""
        canonical_owner = _safe_owner(owner, owner)
        source_root = self.workspace.source_roots_by_owner.get(canonical_owner)
        if source_root is None:
            repo = self.workspace.repository_for(canonical_owner)
            if repo is None:
                raise CompileError(
                    f"No resolved source root or repository for owner {canonical_owner!r}"
                )
            source_root = repo / "tools/semantic_harness/codebuilder/sources/conversation"
        kind_dir = kind if kind in CONVO_SUBDIRS else "dialogue"
        ns_parts = [seg for seg in str(namespace or "").split(".") if seg]
        if ns_parts:
            target = source_root / kind_dir / Path(*ns_parts) / f"{family_id}.json"
        else:
            target = source_root / kind_dir / f"{family_id}.json"
        return target.resolve()


__all__ = [
    "CONVO_CATALOG_SCHEMA",
    "ConvoCatalog",
    "FamilySummary",
]
