"""Transactional preview/apply authority for canonical ConvoEngine changes (Port D).

All canonical family create, edit, move, and delete operations route through
``ConvoTransaction`` and ``ChangeSet`` so Studio UI, CLI, and Python callers
share the exact same owner routing, identity move semantics, dangling-reference
validation, stale source-fingerprint guards, lock discipline, and CodeBuilder
regeneration.
"""

from __future__ import annotations

import contextlib
import copy
import fcntl
import hashlib
import json
import os
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterator, Mapping

from .conversation_model import fingerprint
from .convo_catalog import ConvoCatalog, FamilySummary
from .convo_engine_authoring import (
    apply_family_patch,
    build_convo_engine_family_document,
    load_json_document,
    resolve_authorized_source_path,
    source_fingerprint_mismatch,
    strip_stale_migration_metadata,
)
from .errors import CompileError
from .generation_ownership import (
    CORE_OWNER,
    DT_COMMON_OWNER,
    HOOMANS_OWNER,
    OwnerConfigurationError,
    generated_conversation_root,
    normalize_owner,
)
from .psdl_compiler import CONVO_ENGINE_SCHEMA
from .workspace_catalog import WorkspaceSnapshot


def _canonical_id(namespace: Any, family_id: Any) -> str:
    ns = str(namespace or "").strip()
    fid = str(family_id or "").strip()
    return f"{ns}.{fid}" if ns else fid


def _safe_owner_str(raw: Any) -> str | None:
    if raw is None or not str(raw).strip():
        return None
    try:
        return normalize_owner(raw)
    except OwnerConfigurationError:
        return str(raw).strip()


def _lock_path_for_workspace(workspace: WorkspaceSnapshot) -> Path:
    lock_dir = Path(tempfile.gettempdir()) / "psychopatz_convo_locks"
    digest = hashlib.sha256(str(workspace.core_repository).encode("utf-8")).hexdigest()[:16]
    return lock_dir / f"workspace_{digest}.lock"


@contextlib.contextmanager
def workspace_generation_lock(workspace: WorkspaceSnapshot) -> Iterator[Path]:
    """Acquire an inter-process lock outside any PZ ``media/`` directory."""
    lock_file = _lock_path_for_workspace(workspace)
    lock_file.parent.mkdir(parents=True, exist_ok=True)
    with lock_file.open("a+", encoding="utf-8") as handle:
        fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
        try:
            yield lock_file
        finally:
            fcntl.flock(handle.fileno(), fcntl.LOCK_UN)


def atomic_write_json(path: Path, document: Mapping[str, Any]) -> None:
    """Atomically write JSON to *path* using a sibling temp file and ``os.replace``."""
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(
        prefix=".tmp_",
        suffix=".json",
        dir=str(path.parent),
        text=True,
    )
    tmp_path = Path(tmp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(json.dumps(document, ensure_ascii=False, indent=2) + "\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp_path, path)
    except Exception:
        with contextlib.suppress(OSError):
            tmp_path.unlink(missing_ok=True)
        raise


@dataclass(frozen=True)
class ChangeSet:
    """Normalized canonical ConvoEngine mutation request."""

    operation: str  # create | edit | move | delete | write
    target: str | Path | None = None  # canonicalID, sourceID, or source file path
    dest_path: str | Path | None = None
    expected_fingerprint: str | None = None
    requested_owner: str | None = None
    requested_identity: Mapping[str, Any] | None = None
    document: Mapping[str, Any] | None = None
    patch: Mapping[str, Any] | None = None
    remove_source: bool = True
    overwrite: bool = False
    allow_legacy_schema: bool = False
    regenerate: bool | str = "auto"

    @classmethod
    def from_payload(cls, payload: Mapping[str, Any]) -> "ChangeSet":
        op = str(payload.get("operation") or payload.get("action") or "edit").strip().lower()
        return cls(
            operation=op,
            target=payload.get("target") or payload.get("familyID") or payload.get("sourcePath") or payload.get("source"),
            dest_path=payload.get("destPath") or payload.get("dest"),
            expected_fingerprint=payload.get("expectedFingerprint") or payload.get("expectedSourceFingerprint"),
            requested_owner=payload.get("requestedOwner") or payload.get("owner"),
            requested_identity=payload.get("requestedIdentity"),
            document=payload.get("document") or payload.get("spec"),
            patch=payload.get("patch"),
            remove_source=bool(payload.get("removeSource", True)),
            overwrite=bool(payload.get("overwrite", False)),
            allow_legacy_schema=bool(payload.get("allowLegacySchema", False)),
            regenerate=payload.get("regenerate", "auto"),
        )


def _has_buildable_runtime(workspace: WorkspaceSnapshot) -> bool:
    manifest_file = workspace.core_repository / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json"
    if not manifest_file.is_file():
        return False
    try:
        manifest = json.loads(manifest_file.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return False
    profiles = manifest.get("sourceProfiles") if isinstance(manifest, dict) else None
    shards = manifest.get("shards") if isinstance(manifest, dict) else None
    if not isinstance(profiles, dict) or not profiles:
        return False
    # Require explicit runtime registry/shards before auto-regenerating so minimal
    # isolated test fixtures without full UI/Patterns shards are not broken.
    if not isinstance(shards, list) or not shards:
        return False
    hoomans_repo = workspace.repository_for(HOOMANS_OWNER)
    if hoomans_repo is not None:
        reg = (
            hoomans_repo
            / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Registry.lua"
        )
        return reg.is_file()
    reg_core = (
        workspace.core_repository
        / "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Registry.lua"
    )
    return reg_core.is_file()


class ConvoTransaction:
    """Safe preview/apply transaction boundary over canonical ConvoEngine families."""

    def __init__(self, service: Any) -> None:
        self.service = service

    def _allowed_roots(self, workspace: WorkspaceSnapshot) -> list[Path]:
        roots = [self.service.repository.resolve(), workspace.core_repository.resolve()]
        for repo in workspace.repository_by_owner.values():
            roots.append(repo.resolve())
        for src in workspace.source_contributions:
            roots.append(src.source_root.resolve())
        for repo in getattr(self.service, "package_repositories", {}).values():
            roots.append(Path(repo).expanduser().resolve())
        unique: list[Path] = []
        seen: set[Path] = set()
        for root in roots:
            if root not in seen:
                seen.add(root)
                unique.append(root)
        return unique

    def _resolve_owner(
        self,
        *,
        changeset: ChangeSet,
        candidate_doc: Mapping[str, Any] | None,
        existing_summary: FamilySummary | None,
        path_hint: Path | None,
        workspace: WorkspaceSnapshot,
    ) -> str:
        raw_owner = (
            _safe_owner_str(changeset.requested_owner)
            or _safe_owner_str((candidate_doc or {}).get("owner"))
            or (existing_summary.owner if existing_summary is not None else None)
        )
        if raw_owner is None and path_hint is not None:
            raw_owner = _safe_owner_str(self.service._resolve_convo_engine_default_owner(path_hint))
        if raw_owner is None:
            # Match repository root against discovered owners without blind Core assumption.
            repo_resolved = self.service.repository.resolve()
            for owner_name, repo_path in workspace.repository_by_owner.items():
                if repo_path.resolve() == repo_resolved:
                    raw_owner = owner_name
                    break
        if raw_owner is None:
            raw_owner = CORE_OWNER
        return raw_owner

    def preview(self, changeset: ChangeSet) -> dict[str, Any]:
        """Validate, route, check refs & fingerprints, and build a preview without side effects."""
        op = changeset.operation.strip().lower()
        if op not in {"create", "edit", "move", "delete", "write"}:
            raise CompileError(f"Unsupported ConvoTransaction operation: {changeset.operation!r}")

        workspace: WorkspaceSnapshot = self.service.workspace_snapshot
        catalog: ConvoCatalog = self.service.convo_catalog
        allowed_roots = self._allowed_roots(workspace)

        existing_summary: FamilySummary | None = None
        src_path: Path | None = None
        if changeset.target is not None:
            existing_summary = catalog.resolve_summary(changeset.target)
            if existing_summary is not None:
                src_path = existing_summary.source_path
            else:
                src_path = resolve_authorized_source_path(
                    changeset.target,
                    repository=self.service.repository,
                    allowed_roots=allowed_roots,
                    check_forbidden_segments=False,
                )

        # Fail closed on stale expected fingerprint whenever targeting an existing file.
        if op in {"edit", "move", "delete", "write"} and src_path is not None and src_path.is_file():
            stale = source_fingerprint_mismatch(src_path, changeset.expected_fingerprint)
            if stale is not None:
                stale["previewOnly"] = True
                stale["effectFree"] = True
                stale["operation"] = op
                return stale

        if op == "delete":
            if src_path is None or not src_path.is_file():
                return {
                    "ok": False,
                    "previewOnly": True,
                    "effectFree": True,
                    "operation": "delete",
                    "diagnostics": [{"severity": "error", "message": f"ConvoEngine source is missing: {changeset.target}"}],
                    "writes": [],
                }
            base_doc = load_json_document(src_path)
            old_owner = _safe_owner_str(base_doc.get("owner")) or (
                existing_summary.owner if existing_summary is not None else CORE_OWNER
            )
            old_id = _canonical_id(base_doc.get("namespace"), base_doc.get("id"))
            dangling = catalog.dangling_references_if_removed([old_id])
            if dangling:
                callers = ", ".join(item["callerID"] for item in dangling[:5])
                return {
                    "ok": False,
                    "previewOnly": True,
                    "effectFree": True,
                    "operation": "delete",
                    "canonicalID": old_id,
                    "owner": old_owner,
                    "sourcePath": str(src_path),
                    "blockedBy": "dangling_references",
                    "danglingReferences": dangling,
                    "diagnostics": [
                        {
                            "severity": "error",
                            "message": f"Cannot delete {old_id}: referenced by {callers}",
                        }
                    ],
                    "writes": [],
                }
            impact = catalog.impact(old_id)
            return {
                "ok": True,
                "previewOnly": True,
                "effectFree": True,
                "operation": "delete",
                "canonicalID": old_id,
                "owner": old_owner,
                "sourcePath": str(src_path),
                "destPath": None,
                "sourceFingerprint": fingerprint(base_doc),
                "affectedClosure": impact,
                "plannedModules": (impact or {}).get("generated", []),
                "writes": [],
            }

        # Build candidate document for create / edit / move / write.
        base_doc: dict[str, Any] | None = None
        old_id: str | None = None
        old_owner: str | None = None
        old_identity: tuple[str, str, str] | None = None
        if src_path is not None and src_path.is_file():
            base_doc = load_json_document(src_path)
            old_id = _canonical_id(base_doc.get("namespace"), base_doc.get("id"))
            old_owner = _safe_owner_str(base_doc.get("owner")) or (
                existing_summary.owner if existing_summary is not None else None
            )
            old_identity = (
                str(base_doc.get("kind") or "dialogue"),
                str(base_doc.get("namespace") or ""),
                str(base_doc.get("id") or ""),
            )

        if op == "create":
            if changeset.document is None:
                raise CompileError("create operation requires a family document")
            resolved_owner = self._resolve_owner(
                changeset=changeset,
                candidate_doc=changeset.document,
                existing_summary=None,
                path_hint=Path(changeset.dest_path) if changeset.dest_path is not None else src_path,
                workspace=workspace,
            )
            candidate_doc = build_convo_engine_family_document(
                changeset.document,
                default_owner=resolved_owner,
            )
            effective_op = "create"
        elif op == "edit":
            if base_doc is None and changeset.document is None:
                raise CompileError("edit operation requires an existing source or base document")
            source_doc = copy.deepcopy(dict(base_doc if base_doc is not None else changeset.document or {}))
            if changeset.patch is not None:
                candidate_doc = apply_family_patch(source_doc, changeset.patch)
            elif changeset.document is not None:
                candidate_doc = copy.deepcopy(dict(changeset.document))
            else:
                raise CompileError("edit operation requires patch or document")
            resolved_owner = self._resolve_owner(
                changeset=changeset,
                candidate_doc=candidate_doc,
                existing_summary=existing_summary,
                path_hint=src_path,
                workspace=workspace,
            )
            candidate_doc.setdefault("owner", resolved_owner)
            effective_op = "edit"
        elif op == "move":
            if base_doc is None:
                raise CompileError(f"move operation requires existing source: {changeset.target}")
            if base_doc.get("schema") != CONVO_ENGINE_SCHEMA:
                raise CompileError(
                    f"move requires canonical schema {CONVO_ENGINE_SCHEMA}"
                )
            candidate_doc = copy.deepcopy(dict(changeset.document if changeset.document is not None else base_doc))
            if changeset.requested_identity:
                ident = changeset.requested_identity
                if "owner" in ident and ident["owner"]:
                    candidate_doc["owner"] = _safe_owner_str(ident["owner"]) or str(ident["owner"])
                if "kind" in ident and ident["kind"]:
                    candidate_doc["kind"] = str(ident["kind"])
                if "namespace" in ident:
                    if ident["namespace"]:
                        candidate_doc["namespace"] = str(ident["namespace"])
                    else:
                        candidate_doc.pop("namespace", None)
                if "id" in ident and ident["id"]:
                    candidate_doc["id"] = str(ident["id"])
            resolved_owner = self._resolve_owner(
                changeset=changeset,
                candidate_doc=candidate_doc,
                existing_summary=existing_summary,
                path_hint=Path(changeset.dest_path) if changeset.dest_path is not None else src_path,
                workspace=workspace,
            )
            if changeset.requested_owner:
                candidate_doc["owner"] = resolved_owner
            else:
                candidate_doc.setdefault("owner", resolved_owner)
            effective_op = "move"
        else:
            # op == "write"
            if changeset.document is None:
                raise CompileError("write operation requires a document")
            candidate_doc = copy.deepcopy(dict(changeset.document))
            if (
                not changeset.allow_legacy_schema
                and isinstance(candidate_doc, dict)
                and candidate_doc.get("schema") == CONVO_ENGINE_SCHEMA
            ):
                candidate_doc = strip_stale_migration_metadata(candidate_doc)
            resolved_owner = self._resolve_owner(
                changeset=changeset,
                candidate_doc=candidate_doc,
                existing_summary=existing_summary,
                path_hint=src_path,
                workspace=workspace,
            )
            if candidate_doc.get("owner") is None:
                candidate_doc["owner"] = resolved_owner
            new_identity = (
                str(candidate_doc.get("kind") or "dialogue"),
                str(candidate_doc.get("namespace") or ""),
                str(candidate_doc.get("id") or ""),
            )
            if old_identity is not None and (new_identity != old_identity or (old_owner and resolved_owner != old_owner)):
                # Auto-promote identity or owner change from UI write to safe move semantics.
                effective_op = "move"
            elif src_path is not None and src_path.is_file():
                effective_op = "write"
            else:
                effective_op = "create"

        # Resolve destination path atomically from owner/catalog unless explicitly fixed safely.
        cand_kind = str(candidate_doc.get("kind") or "dialogue")
        cand_ns = candidate_doc.get("namespace")
        cand_id_raw = str(candidate_doc.get("id") or "")
        cand_canonical = _canonical_id(cand_ns, cand_id_raw)

        # Ensure owner is resolvable in workspace if creating/moving without explicit dest_path
        if changeset.dest_path is not None:
            dest_path = resolve_authorized_source_path(
                changeset.dest_path,
                repository=self.service.repository,
                allowed_roots=allowed_roots,
                check_forbidden_segments=not changeset.allow_legacy_schema,
            )
        elif effective_op == "move":
            dest_path = catalog.default_source_path(
                resolved_owner,
                cand_kind,
                str(cand_ns) if cand_ns else None,
                cand_id_raw,
            )
        elif effective_op in {"create"}:
            if src_path is not None and (
                resolved_owner == CORE_OWNER or workspace.repository_for(resolved_owner) is None
            ):
                dest_path = src_path
            elif src_path is not None and any(
                (workspace.repository_for(resolved_owner) or src_path).resolve() == parent
                or (workspace.repository_for(resolved_owner) or src_path).resolve() in src_path.parents
                for parent in [src_path.resolve()]
            ):
                dest_path = src_path
            else:
                owner_repo = workspace.repository_for(resolved_owner)
                if src_path is not None and owner_repo is not None and (
                    owner_repo == src_path or owner_repo in src_path.parents
                ):
                    dest_path = src_path
                elif owner_repo is None and src_path is None:
                    raise CompileError(f"Unresolved owner repository for {resolved_owner!r}")
                else:
                    dest_path = catalog.default_source_path(
                        resolved_owner,
                        cand_kind,
                        str(cand_ns) if cand_ns else None,
                        cand_id_raw,
                    )
        else:
            dest_path = src_path

        if dest_path is None:
            raise CompileError("Cannot determine destination source path for ConvoTransaction")

        if effective_op == "create" and dest_path.exists() and not changeset.overwrite and op != "write":
            raise CompileError(f"ConvoEngine destination already exists: {dest_path}")
        if effective_op == "move" and src_path is not None and dest_path != src_path and dest_path.exists() and not changeset.overwrite:
            raise CompileError(f"ConvoEngine destination already exists: {dest_path}")

        # Compile/validate candidate document.
        report = self.service.validate_convo_engine_document(
            candidate_doc,
            source_path=dest_path,
            default_owner=resolved_owner,
            allow_legacy_schema=changeset.allow_legacy_schema,
        )
        if report.get("ok") is not True:
            report["operation"] = effective_op
            report["previewOnly"] = True
            report["effectFree"] = True
            return report

        # Enforce global dangling-reference protection on moves that change canonical identity.
        if (
            effective_op == "move"
            and changeset.remove_source
            and old_id is not None
            and cand_canonical != old_id
        ):
            dangling = catalog.dangling_references_if_removed([old_id])
            if dangling:
                callers = ", ".join(item["callerID"] for item in dangling[:5])
                return {
                    "ok": False,
                    "previewOnly": True,
                    "effectFree": True,
                    "operation": "move",
                    "canonicalID": old_id,
                    "newCanonicalID": cand_canonical,
                    "owner": resolved_owner,
                    "sourcePath": str(src_path) if src_path else None,
                    "destPath": str(dest_path),
                    "blockedBy": "dangling_references",
                    "danglingReferences": dangling,
                    "diagnostics": [
                        {
                            "severity": "error",
                            "message": f"Cannot rename/move {old_id} to {cand_canonical}: referenced by {callers}",
                        }
                    ],
                    "writes": [],
                }

        persisted = (
            strip_stale_migration_metadata(candidate_doc)
            if not changeset.allow_legacy_schema
            and isinstance(candidate_doc, dict)
            and candidate_doc.get("schema") == CONVO_ENGINE_SCHEMA
            else copy.deepcopy(dict(candidate_doc))
        )
        impact = catalog.impact(old_id or cand_canonical)
        planned_modules = (impact or {}).get("generated") or []
        return {
            "ok": True,
            "previewOnly": True,
            "effectFree": True,
            "operation": effective_op,
            "owner": resolved_owner,
            "canonicalID": cand_canonical,
            "previousCanonicalID": old_id,
            "sourcePath": str(src_path) if src_path is not None else str(dest_path),
            "destPath": str(dest_path),
            "sourceFingerprint": fingerprint(persisted),
            "compiledFingerprint": report["compiled"]["fingerprint"],
            "affectedClosure": impact,
            "plannedModules": planned_modules,
            "document": persisted,
            "preview": report,
            "writes": [],
        }

    def apply(
        self,
        changeset: ChangeSet,
        *,
        raise_on_error: bool = False,
    ) -> dict[str, Any]:
        """Acquire generation lock, re-verify preview under lock, mutate atomically, and refresh."""
        workspace: WorkspaceSnapshot = self.service.workspace_snapshot
        with workspace_generation_lock(workspace):
            preview = self.preview(changeset)
            if preview.get("ok") is not True:
                if raise_on_error:
                    diags = preview.get("diagnostics") or []
                    msg = diags[0].get("message") if diags else "ConvoTransaction rejected"
                    raise CompileError(str(msg))
                return preview

            op = str(preview["operation"])
            src_raw = preview.get("sourcePath")
            dst_raw = preview.get("destPath")
            src_path = Path(src_raw) if src_raw else None
            dst_path = Path(dst_raw) if dst_raw else None
            persisted = preview.get("document")

            writes: list[str] = []
            removed: str | None = None
            if op == "delete":
                if src_path is not None and src_path.is_file():
                    src_path.unlink()
                    removed = str(src_path)
            else:
                if dst_path is None or not isinstance(persisted, Mapping):
                    raise CompileError("Missing destination or persisted document for apply")
                atomic_write_json(dst_path, persisted)
                writes.append(str(dst_path))
                if op == "move" and changeset.remove_source and src_path is not None and src_path != dst_path and src_path.is_file():
                    src_path.unlink()
                    removed = str(src_path)

            generated_writes: list[str] = []
            regenerated = False
            should_regen = (
                changeset.regenerate is True
                or (changeset.regenerate == "auto" and _has_buildable_runtime(workspace))
            )
            if should_regen:
                from .build import write_conversation_output

                runtime_target = workspace.repository_for(HOOMANS_OWNER) or workspace.core_repository
                written_paths = write_conversation_output(
                    runtime_target,
                    core_repository=workspace.core_repository,
                    dynamic_trading_repository=workspace.repository_for(DT_COMMON_OWNER),
                )
                generated_writes = [str(p) for p in written_paths]
                regenerated = True

            # Refresh catalog view after canonical disk mutation.
            self.service.refresh_workspace()

            return {
                **preview,
                "previewOnly": False,
                "effectFree": False,
                "writeApproved": True,
                "generatedOutputRequired": True,
                "regenerated": regenerated,
                "removedSource": removed,
                "writes": writes,
                "generatedWrites": generated_writes,
            }


__all__ = [
    "ChangeSet",
    "ConvoTransaction",
    "atomic_write_json",
    "workspace_generation_lock",
]
