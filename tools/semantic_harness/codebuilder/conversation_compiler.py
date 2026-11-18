"""Manifest-backed Conversation source compiler and generated artifact plan.

Conversation authoring is deliberately compiled through this module instead of
adding another source loader beside CodeBuilder.  The manifest is the only
filesystem discovery boundary; all runtime and authoring consumers receive the
same merged, validated model.
"""

from __future__ import annotations

from copy import deepcopy
import json
import os
from pathlib import Path
import pickle
import threading
from typing import Any, Iterable, Mapping

from .dialogue_content import (
    _lua_value,
    render_dialogue_content_shard_plan,
)
from .errors import CompileError
from .conversation_manifest import (
    CONVERSATION_MANIFEST_SCHEMA,
    load_manifest as _load_manifest,
    read_json as _read_json,
    validate_id as _validate_id,
)
from .conversation_ui_contract import text_key
from .conversation_contract import (
    CONVERSATION_MANIFEST_RELATIVE,
    CONVERSATION_MAX_SHARD_BYTES,
    CONVERSATION_MAX_INDEX_BYTES,
    CONVERSATION_MAX_SOURCE_BYTES,
    CONVERSATION_MODEL_SCHEMA,
    CONVERSATION_RUNTIME_RELATIVE,
    CONVERSATION_SHARD_SCHEMA,
    CONVERSATION_SOURCE_RELATIVE,
    CONVERSATION_UI_RUNTIME_RELATIVE,
)
from .conversation_validation import (
    CONVERSATION_MAX_RECORDS_PER_SHARD,
    _merge_director_sources,
    _merge_realization_sources,
    _validate_behavior_shard,
    _validate_beat_shard,
    _validate_director_predicate,
    _validate_realization_shard,
)
from .conversation_rendering import (
    CONVERSATION_MAX_SHARD_BYTES,
    _chunk_records,
    _render_pack_shard_plan,
    render_conversation_lua_records,
    render_conversation_ui_module,
)
from .catalog_naming import ModuleNameRegistry, module_path, semantic_chunk_label
from .conversation_discovery import (
    conversation_discovery_index,
    render_conversation_discovery_indexes,
)
from .conversation_health import (
    conversation_affected_closure,
    conversation_context_health,
)
from .conversation_registry import (
    render_conversation_manifest_lua,
    render_conversation_registry,
)
from .conversation_assembly import (
    _add_global_id,
    _compile_shard,
    _content_source,
    _conversation_record_ids,
    _hydrate_shard_provenance,
    _merge_dialogue_sources,
    _merge_semantic_sources,
    _ui_translations,
)
from tools.semantic_harness.codebuilder.conversation_model import (
    copy_json as _copy_json,
    fingerprint as _fingerprint,
    register_global_id as _register_global_id_core,
)
from tools.semantic_harness.codebuilder.conversation_assembler import assemble_shards
from tools.semantic_harness.codebuilder.translation_support import (
    DEFAULT_LANGUAGE,
    merge_language_sets,
    normalize_language,
)
from .capability_abi import validate_target_capabilities
from .generation_ownership import (
    HOOMANS_OWNER,
    combined_target_descriptor,
    conversation_prefix,
    normalize_owner,
    package_descriptor as owner_package_descriptor,
    route_module_for_owner,
    resolve_core_repository,
    resolve_hoomans_repository,
    source_owner,
)
from .backend_registry import render_portable_plan_for_target
from .portable_runtime import compile_portable_plan
from .convo_engine_compiler import (
    _validate_cross_references as _validate_convo_engine_cross_references,
    compile_convo_engine_document,
    render_convo_director_plan,
    render_convo_flow_plan,
    render_convo_realization_plan,
    render_convo_response_pool_plan,
    render_convo_semantic_pack_plan,
    render_convo_runtime_plan,
    render_convo_ui_plan,
)
from .conversation_assembly import CONVO_ENGINE_SHARD_KINDS


def _registry_owner(model: dict[str, Any]) -> str:
    manifest = model.get("manifest")
    owner = manifest.get("registryOwner") if isinstance(manifest, dict) else None
    return normalize_owner(owner)


def _package_for_entry(
    package_doc: Mapping[str, Any] | None,
    entry: Mapping[str, Any],
) -> dict[str, Any] | None:
    if package_doc is None:
        return None
    pkg = dict(package_doc)
    if entry.get("owner"):
        pkg["defaultOwner"] = entry["owner"]
    return pkg


def _make_sidecar_loader(source_root: Path, entry: Mapping[str, Any]):
    if entry.get("sourceRepository") and entry.get("sourcePath"):
        base_root = Path(str(entry["sourceRepository"])).expanduser().resolve()
        shard_dir = (base_root / str(entry["sourcePath"])).parent
    else:
        base_root = source_root.expanduser().resolve()
        shard_dir = (base_root / str(entry["path"])).parent

    def load_sidecar(rel_path: str) -> dict[str, Any]:
        candidate = (shard_dir / rel_path).resolve()
        if not candidate.is_file():
            candidate = (base_root / rel_path).resolve()
        if base_root not in candidate.parents and candidate != base_root:
            raise CompileError(f"textSidecars path escapes source root: {rel_path!r}")
        if not candidate.is_file():
            raise CompileError(f"Missing textSidecars file {rel_path!r} for {entry['path']}")
        return _read_json(candidate, f"textSidecars {rel_path}")

    return load_sidecar


def _compiled_psdl_documents(
    loaded: list[tuple[dict[str, Any], dict[str, Any], str]],
    *,
    default_owner: str | None = None,
    package: Mapping[str, Any] | None = None,
    source_root: Path | None = None,
) -> list[tuple[dict[str, Any], dict[str, Any]]]:
    compiled: list[tuple[dict[str, Any], dict[str, Any]]] = []
    for document, entry, _fingerprint_value in loaded:
        if entry.get("kind") not in CONVO_ENGINE_SHARD_KINDS:
            continue
        loader = (
            _make_sidecar_loader(source_root, entry)
            if source_root is not None
            else None
        )
        compiled.append(
            (
                compile_convo_engine_document(
                    document,
                    source_path=entry["path"],
                    default_owner=entry.get("owner") or default_owner,
                    validate_cross_references=False,
                    package=_package_for_entry(package, entry),
                    text_loader=loader,
                ),
                entry,
            )
        )
    return compiled








_COMPILE_CACHE_LOCK = threading.RLock()
_COMPILE_CACHE: dict[
    tuple[Any, ...],
    tuple[tuple[tuple[str, int, int], ...], bytes],
] = {}


def _stat_tuple(path: Path) -> tuple[str, int, int] | None:
    try:
        st = os.stat(path)
    except OSError:
        return None
    return (str(path), st.st_mtime_ns, st.st_size)


def _watched_files_unchanged(watched: tuple[tuple[str, int, int], ...]) -> bool:
    for path_str, mtime_ns, size in watched:
        try:
            st = os.stat(path_str)
        except OSError:
            return False
        if st.st_mtime_ns != mtime_ns or st.st_size != size:
            return False
    return True


def _collect_watched_files(
    repository: Path,
    manifest_path: Path,
    resolved_package_repositories: Mapping[str, Path],
    model: Mapping[str, Any],
) -> tuple[tuple[str, int, int], ...]:
    paths: dict[str, Path] = {str(manifest_path): manifest_path}
    roots_to_watch: list[Path] = [manifest_path.parent]
    for extra_owner, extra_repo in resolved_package_repositories.items():
        extra_desc = owner_package_descriptor(extra_owner)
        extra_pkg = extra_repo / extra_desc.source_root_relative / "package.json"
        if extra_pkg.is_file():
            paths[str(extra_pkg)] = extra_pkg
            roots_to_watch.append(extra_pkg.parent)
    for root_dir in roots_to_watch:
        if root_dir.is_dir():
            for dirpath, _dirnames, _filenames in os.walk(root_dir):
                paths[dirpath] = Path(dirpath)
    source_docs = model.get("_source_documents") or {}
    for entry in model.get("_manifest_entries") or []:
        if not isinstance(entry, dict):
            continue
        source_repo = Path(entry.get("sourceRepository") or repository)
        source_rel = entry.get("sourcePath")
        if source_rel:
            full = (source_repo / str(source_rel)).resolve()
        else:
            full = (manifest_path.parent / str(entry.get("path") or "")).resolve()
        paths[str(full)] = full
        doc = source_docs.get(entry.get("path"))
        if isinstance(doc, dict) and isinstance(doc.get("textSidecars"), dict):
            base_dir = full.parent
            for rel in doc["textSidecars"].values():
                if isinstance(rel, str) and rel:
                    sidecar = (base_dir / rel).resolve()
                    if not sidecar.is_file():
                        sidecar = (manifest_path.parent / rel).resolve()
                    paths[str(sidecar)] = sidecar
    stats: list[tuple[str, int, int]] = []
    for p in sorted(paths):
        st = _stat_tuple(paths[p])
        if st is not None:
            stats.append(st)
    return tuple(stats)


def compile_conversation_sources(
    repository: Path,
    *,
    manifest_path: Path | None = None,
    runtime_root: Path | None = None,
    source_overrides: dict[str, dict[str, Any]] | None = None,
    package_repositories: Mapping[str, Path] | None = None,
    target_descriptor: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    """Load, validate, merge, sort, fingerprint, and index Conversation shards.

    source_overrides is an effect-free preview hook keyed by manifest-relative
    shard path. It never writes to disk and is used by the shared authoring
    service to validate edits against the complete Conversation model.
    """
    repository = repository.expanduser().resolve()
    resolved_package_repositories = {
        HOOMANS_OWNER: resolve_hoomans_repository(
            repository,
            runtime_root=runtime_root,
        ),
        "PsychopatzCore": resolve_core_repository(
            repository,
            runtime_root=runtime_root,
        ),
        **{
            normalize_owner(owner): Path(path).expanduser().resolve()
            for owner, path in (package_repositories or {}).items()
        },
    }
    explicit_manifest = manifest_path is not None
    if manifest_path is None:
        hoomans_repo = resolved_package_repositories.get(HOOMANS_OWNER)
        hoomans_pkg_path = (
            hoomans_repo
            / owner_package_descriptor(HOOMANS_OWNER).source_root_relative
            / "package.json"
            if hoomans_repo is not None
            else None
        )
        local_pkg_path = repository / CONVERSATION_SOURCE_RELATIVE / "package.json"
        local_manifest_path = repository / CONVERSATION_MANIFEST_RELATIVE
        core_pkg_path = (
            resolved_package_repositories["PsychopatzCore"]
            / CONVERSATION_SOURCE_RELATIVE
            / "package.json"
        )
        core_manifest_path = (
            resolved_package_repositories["PsychopatzCore"]
            / CONVERSATION_MANIFEST_RELATIVE
        )
        if local_pkg_path.is_file() and repository != resolved_package_repositories["PsychopatzCore"]:
            manifest_path = local_pkg_path
        elif local_manifest_path.is_file() and repository != resolved_package_repositories["PsychopatzCore"]:
            manifest_path = local_manifest_path
        elif hoomans_pkg_path is not None and hoomans_pkg_path.is_file():
            manifest_path = hoomans_pkg_path
        elif core_pkg_path.is_file():
            manifest_path = core_pkg_path
        else:
            manifest_path = core_manifest_path
    manifest_path = manifest_path.expanduser().resolve()
    runtime_root = (runtime_root or repository).expanduser().resolve()

    cache_key: tuple[Any, ...] | None = None
    if not source_overrides:
        cache_key = (
            str(repository),
            str(manifest_path),
            str(runtime_root),
            tuple(sorted((k, str(v)) for k, v in resolved_package_repositories.items())),
            json.dumps(target_descriptor, sort_keys=True) if target_descriptor is not None else None,
        )
        with _COMPILE_CACHE_LOCK:
            cached = _COMPILE_CACHE.get(cache_key)
            if cached is not None:
                watched, cached_bytes = cached
                if _watched_files_unchanged(watched):
                    return pickle.loads(cached_bytes)

    model = _compile_conversation_sources_uncached(
        repository=repository,
        manifest_path=manifest_path,
        explicit_manifest=explicit_manifest,
        runtime_root=runtime_root,
        source_overrides=source_overrides,
        package_repositories=package_repositories,
        resolved_package_repositories=resolved_package_repositories,
        target_descriptor=target_descriptor,
    )
    if cache_key is not None:
        watched = _collect_watched_files(
            repository, manifest_path, resolved_package_repositories, model
        )
        cached_bytes = pickle.dumps(model, protocol=pickle.HIGHEST_PROTOCOL)
        with _COMPILE_CACHE_LOCK:
            _COMPILE_CACHE[cache_key] = (watched, cached_bytes)
    return model


def _compile_conversation_sources_uncached(
    *,
    repository: Path,
    manifest_path: Path,
    explicit_manifest: bool,
    runtime_root: Path,
    source_overrides: dict[str, dict[str, Any]] | None,
    package_repositories: Mapping[str, Path] | None,
    resolved_package_repositories: Mapping[str, Path],
    target_descriptor: Mapping[str, Any] | None,
) -> dict[str, Any]:
    visited_packages: set[str] = set()
    manifest, entries = _load_manifest(
        repository,
        manifest_path,
        package_repositories=resolved_package_repositories,
        visited_packages=visited_packages,
    )
    if not explicit_manifest:
        seen_entry_keys = {
            (
                str(e.get("owner") or ""),
                str(e.get("sourcePath") or e.get("path") or ""),
            )
            for e in entries
        }
        seen_logical_paths = {str(e.get("path") or "") for e in entries}
        for extra_owner, extra_repo in sorted(resolved_package_repositories.items()):
            if extra_owner in visited_packages:
                continue
            extra_desc = owner_package_descriptor(extra_owner)
            extra_root = extra_repo / extra_desc.source_root_relative
            extra_pkg = extra_root / "package.json"
            if not extra_pkg.is_file():
                continue
            extra_manifest, extra_entries = _load_manifest(
                extra_repo,
                extra_pkg,
                package_repositories=resolved_package_repositories,
                visited_packages=visited_packages,
            )
            manifest["sourceProfiles"].update(extra_manifest.get("sourceProfiles") or {})
            for extra_entry in extra_entries:
                dedup_key = (
                    str(extra_entry.get("owner") or ""),
                    str(extra_entry.get("sourcePath") or extra_entry.get("path") or ""),
                )
                if dedup_key in seen_entry_keys:
                    continue
                seen_entry_keys.add(dedup_key)
                cloned = dict(extra_entry)
                if not cloned.get("sourceRepository"):
                    cloned["sourceRepository"] = str(extra_repo.expanduser().resolve())
                if not cloned.get("sourcePath"):
                    cloned["sourcePath"] = (
                        extra_root.relative_to(extra_repo).as_posix()
                        + "/"
                        + str(cloned["path"])
                    )
                cloned.setdefault("sourceOwner", str(cloned.get("owner") or extra_desc.owner))
                if cloned["path"] in seen_logical_paths:
                    cloned["path"] = f"packages/{extra_desc.owner}/{cloned['path']}"
                seen_logical_paths.add(cloned["path"])
                entries.append(cloned)
        entries.sort(key=lambda item: (item["order"], item["path"]))
    package_descriptor_doc = manifest.get("_packageDescriptor")
    source_root = manifest_path.parent

    def compile_shard(document: dict[str, Any], entry: dict[str, Any]) -> Any:
        _hydrate_shard_provenance(document, entry, manifest["sourceProfiles"])
        return _compile_shard(
            document,
            entry,
            runtime_root=runtime_root,
            default_owner=manifest["defaultOwner"],
            package_repositories=resolved_package_repositories,
            package=_package_for_entry(package_descriptor_doc, entry),
            text_loader=_make_sidecar_loader(source_root, entry),
        )

    def record_ids_for(document: dict[str, Any], entry: dict[str, Any]) -> list[str]:
        return _conversation_record_ids(
            document,
            entry,
            package=_package_for_entry(package_descriptor_doc, entry),
            text_loader=_make_sidecar_loader(source_root, entry),
        )

    def owner_for(_document: dict[str, Any], entry: dict[str, Any]) -> str:
        return normalize_owner(entry.get("owner"))

    loaded, shard_reports, source_documents = assemble_shards(
        entries,
        source_root=source_root,
        source_overrides=source_overrides,
        read_document=_read_json,
        compile_shard=compile_shard,
        record_ids_for=record_ids_for,
        owner_for=owner_for,
    )

    content, content_source = _content_source(loaded)
    dialogue, _dialogue_translations = _merge_dialogue_sources(loaded)
    semantic = _merge_semantic_sources(
        loaded,
        runtime_root,
        manifest["defaultOwner"],
        package_repositories,
    )
    behaviors = _merge_director_sources(
        loaded,
        "behaviors",
        default_owner=manifest["defaultOwner"],
    )
    beats = _merge_director_sources(
        loaded,
        "beats",
        default_owner=manifest["defaultOwner"],
    )
    realization = _merge_realization_sources(loaded)
    psdl_documents = _compiled_psdl_documents(
        loaded,
        default_owner=manifest["defaultOwner"],
        package=package_descriptor_doc,
        source_root=source_root,
    )
    merged_convo_records = [
        record
        for compiled_psdl, _entry in psdl_documents
        for record in compiled_psdl.get("records", [])
    ]
    resolved_target_descriptor = (
        dict(target_descriptor)
        if target_descriptor is not None
        else combined_target_descriptor([manifest["registryOwner"]])
    )
    if merged_convo_records:
        _validate_convo_engine_cross_references(merged_convo_records)
        if target_descriptor is None:
            active_owners = {
                normalize_owner(rec.get("owner"), default=manifest["defaultOwner"])
                for rec in merged_convo_records
            } | {manifest["registryOwner"]}
            resolved_target_descriptor = combined_target_descriptor(sorted(active_owners))
        validate_target_capabilities(
            merged_convo_records,
            resolved_target_descriptor,
        )
    entry_by_record_id: dict[str, dict[str, Any]] = {}
    for compiled_psdl, entry in psdl_documents:
        for record in compiled_psdl.get("records", []):
            rec_id = str(record.get("id") or "")
            if rec_id:
                entry_by_record_id[rec_id] = entry

    portable_plan = compile_portable_plan(
        merged_convo_records,
        package=manifest["registryOwner"],
    )
    backend_projection = render_portable_plan_for_target(
        portable_plan,
        target_descriptor=resolved_target_descriptor,
        entry_by_record_id=entry_by_record_id,
        default_owner=manifest["defaultOwner"],
    )
    psdl_ui = backend_projection["ui"]
    psdl_packs = backend_projection["semanticPacks"]
    psdl_runtime_plans = backend_projection["runtimePlans"]
    behaviors["records"].extend(backend_projection["behaviors"])
    beats["records"].extend(backend_projection["beats"])
    psdl_response_pools = backend_projection["responsePools"]
    psdl_response_pool_owners = backend_projection["responsePoolOwners"]
    psdl_flows = backend_projection["flows"]
    psdl_realizations = backend_projection["realizations"]
    if psdl_response_pools:
        dialogue["responsePools"].extend(psdl_response_pools)
        dialogue["responsePools"].sort(key=lambda item: str(item.get("id", "")))
        dialogue["_responsePoolOwners"] = psdl_response_pool_owners
    if psdl_flows:
        semantic["flows"].extend(psdl_flows)
        semantic["flows"].sort(key=lambda item: str(item.get("id", "")))
    if psdl_realizations:
        realization["records"].extend(psdl_realizations)
        realization["records"].sort(key=lambda item: str(item.get("id", "")))
    behaviors["records"].sort(key=lambda item: str(item.get("id", "")))
    beats["records"].sort(key=lambda item: str(item.get("id", "")))
    psdl_runtime_plans.sort(key=lambda item: str(item.get("id", "")))
    packs = [*psdl_packs]
    for document, entry, _fingerprint_value in loaded:
        if entry["kind"] != "packs":
            continue
        owner = normalize_owner(
            entry.get("owner"),
        )
        for pack in document.get("packs", []):
            record = _copy_json(pack)
            record["owner"] = owner
            record["domain"] = entry["domain"]
            record["sourceShard"] = entry["path"]
            packs.append(record)
    packs.sort(key=lambda item: str(item.get("id", "")))
    ui = sorted(
        [
            item
            for document, entry, _ in loaded
            if entry["kind"] == "ui"
            for item in document.get("suggestions", [])
        ] + psdl_ui,
        key=lambda item: (item.get("order", 0), item.get("id", "")),
    )
    ui_texts = sorted(
        [
            item
            for document, entry, _ in loaded
            if entry["kind"] == "ui"
            for item in document.get("texts", [])
        ],
        key=lambda item: item.get("id", ""),
    )

    locations: dict[str, dict[str, Any]] = {}
    ui_locations: dict[str, dict[str, Any]] = {}
    for document, entry, _fingerprint_value in loaded:
        path = entry["path"]
        entry = {
            **entry,
            "owner": normalize_owner(entry.get("owner")),
        }
        if entry["kind"] == "content":
            for family in document.get("phraseFamilies", []):
                _add_global_id(
                    locations,
                    "phrase." + str(family.get("semanticTemplateID")),
                    kind="content",
                    shard=entry,
                    path=path,
                )
            for choice in document.get("playerChoices", []):
                _add_global_id(locations, choice.get("id"), kind="content", shard=entry, path=path)
        elif entry["kind"] == "patterns":
            for pattern in document.get("patterns", []):
                _add_global_id(locations, pattern.get("id"), kind="pattern", shard=entry, path=path)
        elif entry["kind"] == "responses":
            for pool in document.get("responsePools", []):
                _add_global_id(locations, pool.get("id"), kind="responsePool", shard=entry, path=path)
        elif entry["kind"] == "flows":
            for definition in document.get("definitions", []):
                _add_global_id(locations, definition.get("id"), kind="flowDefinition", shard=entry, path=path)
                flow = definition.get("flow") if isinstance(definition, dict) else None
                if isinstance(flow, dict):
                    _add_global_id(locations, flow.get("id"), kind="flow", shard=entry, path=path)
                responses = definition.get("responses") if isinstance(definition, dict) else None
                if isinstance(responses, dict):
                    _add_global_id(locations, responses.get("poolID"), kind="responsePool", shard=entry, path=path)
        elif entry["kind"] == "behaviors":
            for behavior in document.get("behaviors", []):
                _add_global_id(locations, behavior.get("id"), kind="behavior", shard=entry, path=path)
        elif entry["kind"] == "beats":
            for beat in document.get("beats", []):
                _add_global_id(locations, beat.get("id"), kind="beat", shard=entry, path=path)
        elif entry["kind"] == "realization":
            for realization_record in document.get("realizations", []):
                _add_global_id(
                    locations,
                    realization_record.get("id"),
                    kind="realization",
                    shard=entry,
                    path=path,
                )
        elif entry["kind"] == "packs":
            for pack in document.get("packs", []):
                _add_global_id(
                    locations,
                    pack.get("id"),
                    kind="pack",
                    shard=entry,
                    path=path,
                )
        elif entry["kind"] in CONVO_ENGINE_SHARD_KINDS:
            for compiled_psdl, psdl_entry in psdl_documents:
                if psdl_entry["path"] != path:
                    continue
                psdl_ids: set[str] = set()
                for record in compiled_psdl["records"]:
                    rec_id = record.get("id")
                    if isinstance(rec_id, str):
                        psdl_ids.add(rec_id)
                    _add_global_id(
                        locations,
                        rec_id,
                        kind=record.get("kind", "dialogue"),
                        shard=entry,
                        path=path,
                    )
                for row in render_convo_realization_plan(compiled_psdl):
                    row_id = row.get("id")
                    if row_id not in psdl_ids:
                        _add_global_id(
                            locations,
                            row_id,
                            kind="realization",
                            shard=entry,
                            path=path,
                        )
                for row in render_convo_ui_plan(compiled_psdl):
                    _add_global_id(
                        ui_locations,
                        row.get("id"),
                        kind="ui",
                        shard=entry,
                        path=path,
                    )
                for pack in render_convo_semantic_pack_plan(compiled_psdl):
                    _add_global_id(
                        locations,
                        pack.get("id"),
                        kind="pack",
                        shard=entry,
                        path=path,
                    )
        else:
            for suggestion in document.get("suggestions", []):
                _add_global_id(ui_locations, suggestion.get("id"), kind="ui", shard=entry, path=path)
            for text in document.get("texts", []):
                _add_global_id(ui_locations, text.get("id"), kind="uiText", shard=entry, path=path)

    behavior_ids = {record["id"] for record in behaviors["records"]}
    available_content_templates = {
        str(item.get("semanticTemplateID"))
        for item in content.get("phraseFamilies", [])
        if isinstance(item, dict)
    }
    # PSDL adopter records may split a bounded response family into multiple
    # runtime plans while retaining the existing semantic content-template ID
    # used by Core-owned behaviors. The adopter runtime projects those plans
    # back into the existing phrase-family authority; Core validation must
    # therefore recognize the declared alias without creating a second
    # content authoring format or runtime.
    for compiled_psdl, _entry in psdl_documents:
        for record in compiled_psdl.get("records", []):
            payload = record.get("payload")
            if (
                record.get("kind") == "dialogue"
                and isinstance(payload, dict)
                and isinstance(record.get("id"), str)
            ):
                if payload.get("say") is not None:
                    available_content_templates.add(record["id"])
                if isinstance(payload.get("reply"), dict):
                    available_content_templates.add(record["id"])
                    for outcome_name in payload["reply"]:
                        if isinstance(outcome_name, str) and outcome_name.strip():
                            available_content_templates.add(
                                f"{record['id']}.{outcome_name.strip()}"
                            )
            metadata = payload.get("metadata") if isinstance(payload, dict) else None
            if not isinstance(metadata, dict):
                continue
            template_id = metadata.get("responseTemplateID")
            if isinstance(template_id, str) and template_id.strip():
                available_content_templates.add(template_id.strip())
    behavior_by_id = {
        record["id"]: record for record in behaviors["records"]
    }
    if not bool(manifest.get("allowUnresolvedTemplateContracts", False)):
        for behavior in behaviors["records"]:
            outputs = behavior.get("outputs", {})
            for output_name in ("speech", "flavor"):
                output = outputs.get(output_name)
                if isinstance(output, dict):
                    content_template_id = output.get("contentTemplateID")
                    if content_template_id not in available_content_templates:
                        raise CompileError(
                            f"behavior {behavior.get('id')} {output_name} output references "
                            f"unknown Dialogue Content template {content_template_id}"
                        )
    for beat in beats["records"]:
        for candidate in beat.get("candidates", []):
            behavior_id = candidate.get("behavior")
            if behavior_id not in behavior_ids:
                raise CompileError(
                    f"beat {beat.get('id')} references unknown behavior {behavior_id}"
                )
            if behavior_by_id[behavior_id].get("mode") != "beat":
                raise CompileError(
                    f"beat {beat.get('id')} references non-beat behavior {behavior_id}"
                )

    available_patterns = {
        str(item.get("id")) for item in dialogue.get("patterns", [])
    } | {str(item.get("id")) for item in semantic.get("patterns", [])}
    available_patterns |= {
        str(pattern.get("id"))
        for pack in packs
        for pattern in pack.get("patterns", [])
        if isinstance(pattern, dict)
    }
    external_pattern_ids = set(
        (manifest.get("externalReferences") or {}).get("patternIDs", [])
    )
    for suggestion in ui:
        pattern_id = suggestion.get("patternID")
        if pattern_id not in available_patterns and pattern_id not in external_pattern_ids:
            raise CompileError(
                f"UI suggestion {suggestion.get('id')} references unregistered pattern {pattern_id}"
            )

    for family in content["phraseFamilies"]:
        owner = locations.get("phrase." + str(family["semanticTemplateID"]))
        if owner is not None:
            family["conversationDomain"] = owner["domain"]
            family["sourceShard"] = owner["sourceShard"]
    for choice in content["playerChoices"]:
        owner = locations.get(choice["id"])
        if owner is not None:
            choice["conversationDomain"] = owner["domain"]
            choice["sourceShard"] = owner["sourceShard"]

    # Semantic-authoring patterns are generated from the flow definitions but
    # are still canonical runtime IDs. Register them globally so a later
    # shard cannot accidentally mint an ID already used by a data pattern.
    for pattern in semantic.get("patterns", []):
        pattern_id = pattern.get("id")
        if not isinstance(pattern_id, str):
            continue
        definition_id = ".".join(pattern_id.split(".")[:3])
        owner = locations.get(definition_id)
        if owner is not None:
            _add_global_id(
                locations,
                pattern_id,
                kind="pattern",
                shard={
                    "domain": owner["domain"],
                    "owner": owner.get("owner"),
                },
                path=owner["sourceShard"],
            )

    identity_content = _copy_json(content)
    for family in identity_content.get("phraseFamilies", []):
        family.pop("conversationDomain", None)
        family.pop("sourceShard", None)
    for choice in identity_content.get("playerChoices", []):
        choice.pop("conversationDomain", None)
        choice.pop("sourceShard", None)
    semantic_payload = {
        "content": {
            key: value for key, value in identity_content.items()
            if key not in ("contentFingerprint",)
        },
        "dialogue": dialogue,
        "semantic": semantic,
        "behaviors": behaviors["records"],
        "beats": beats["records"],
        "realization": realization["records"],
        "packs": packs,
        "convoRuntimePlans": psdl_runtime_plans,
        "ui": ui,
        "uiTexts": ui_texts,
    }
    whole_fingerprint = _fingerprint(semantic_payload)
    locations = {key: locations[key] for key in sorted(locations)}
    try:
        manifest_display_path = manifest_path.relative_to(repository)
    except ValueError:
        core_repository = resolved_package_repositories.get("PsychopatzCore")
        try:
            manifest_display_path = manifest_path.relative_to(core_repository)
        except (TypeError, ValueError):
            manifest_display_path = manifest_path
    model = {
        "schema": CONVERSATION_MODEL_SCHEMA,
        "manifestPath": str(manifest_display_path),
        "manifest": manifest,
        "source": content_source,
        "content": content,
        "dialogue": dialogue,
        "semantic": semantic,
        "behaviors": behaviors["records"],
        "beats": beats["records"],
        "realization": realization["records"],
        "packs": packs,
        "convoRuntimePlans": psdl_runtime_plans,
        "portablePlan": portable_plan,
        "targetBackend": backend_projection.get("backend"),
        "portableArtifacts": backend_projection.get("portableArtifacts", {}),
        "ui": ui,
        "uiTexts": ui_texts,
        "uiTranslations": _ui_translations(ui, ui_texts),
        "shards": shard_reports,
        "locations": locations,
        "uiLocations": ui_locations,
        "wholeModelFingerprint": whole_fingerprint,
        # Private build-time provenance used for shard-targeted authoring.
        # Private fields are never written into generated runtime artifacts.
        "_repository": repository,
        "_package_repositories": {
            normalize_owner(owner): Path(path).expanduser().resolve()
            for owner, path in (package_repositories or {}).items()
        },
        "_source_documents": source_documents,
        "_manifest_entries": entries,
    }
    return model


def conversation_record(model: dict[str, Any], canonical_id: str) -> dict[str, Any] | None:
    location = (model.get("locations") or {}).get(str(canonical_id))
    if not isinstance(location, dict):
        return None
    return _copy_json(location)


def conversation_languages(model: dict[str, Any]) -> tuple[str, ...]:
    """Return locale codes present in the merged canonical Conversation model."""
    languages = merge_language_sets(
        model.get("content", {}).get("translations", {}),
        model.get("uiTranslations", {}),
        model.get("dialogue", {}).get("translations", {}),
        model.get("semantic", {}).get("translations", {}),
        {
            language: {}
            for plan in model.get("convoRuntimePlans", [])
            for language in _psdl_plan_languages(plan)
        },
    )
    if DEFAULT_LANGUAGE not in languages:
        raise CompileError(f"Conversation content requires {DEFAULT_LANGUAGE} fallback translations")
    return languages


def _psdl_plan_languages(plan: Mapping[str, Any]) -> tuple[str, ...]:
    """Return locales carried by one PSDL runtime plan's authored payload."""
    languages: set[str] = set()

    def visit(value: Any) -> None:
        if isinstance(value, Mapping):
            keys = list(value)
            if DEFAULT_LANGUAGE in value:
                for raw_language in keys:
                    if isinstance(raw_language, str):
                        languages.add(normalize_language(raw_language, "PSDL locale"))
            for child in value.values():
                visit(child)
        elif isinstance(value, list):
            for child in value:
                visit(child)

    visit(plan.get("payload"))
    return tuple(sorted(languages))


def _psdl_plan_text_rows(
    plan: Mapping[str, Any],
) -> list[tuple[str, str, str, str]]:
    """Project explicitly requested PSDL text targets into flat catalogs.

    PSDL response text remains authored inline.  Only records that declare a
    ``metadata.textTarget`` opt into the native Conversation/Text compatibility
    boundary used by adopter runtimes; UI-only PSDL records continue through
    the normal generated UI catalog path.
    """
    payload = plan.get("payload")
    if not isinstance(payload, Mapping):
        return []
    metadata = payload.get("metadata")
    if not isinstance(metadata, Mapping):
        return []
    target = metadata.get("textTarget")
    if not isinstance(target, str) or not target.strip():
        return []
    target = target.strip().strip("/")
    domain = "Text/" + target
    rows: list[tuple[str, str, str, str]] = []

    def add(localized: Any, key: Any) -> None:
        if not isinstance(localized, Mapping) or not isinstance(key, str):
            return
        for raw_language, raw_values in localized.items():
            if not isinstance(raw_language, str):
                continue
            language = normalize_language(raw_language, "PSDL text locale")
            values = raw_values if isinstance(raw_values, list) else [raw_values]
            if values and isinstance(values[0], str):
                rows.append((language, domain, key, values[0]))

    def metadata_key(value: Any, field: str, fallback: str) -> str:
        if isinstance(value, Mapping):
            candidate = value.get(field)
            if isinstance(candidate, str) and candidate.strip():
                return candidate.strip()
        return fallback

    record_id = str(plan.get("id") or "record")
    response = payload.get("response")
    if isinstance(response, Mapping):
        response_text = response.get("text")
        if response_text is not None:
            add(response_text, metadata_key(metadata, "responseKey", "response"))
        variants = response.get("variants")
        if isinstance(variants, list):
            for index, variant in enumerate(variants):
                if not isinstance(variant, Mapping):
                    continue
                variant_metadata = variant.get("metadata")
                variant_id = str(variant.get("id") or f"variant_{index + 1}")
                add(
                    variant.get("text"),
                    metadata_key(variant_metadata, "textKey", variant_id),
                )
        turns = response.get("turns")
    else:
        affordance = payload.get("affordance")
        if isinstance(affordance, Mapping):
            aff_metadata = affordance.get("metadata")
            label_key = None
            if isinstance(aff_metadata, Mapping) and isinstance(aff_metadata.get("textKey"), str):
                label_key = aff_metadata.get("textKey")
            elif isinstance(metadata.get("labelKey"), str):
                label_key = metadata.get("labelKey")
            if label_key:
                add(affordance.get("label"), label_key)
        has_explicit_rows = isinstance(metadata.get("textRows"), list) and len(metadata["textRows"]) > 0
        say = payload.get("say")
        if isinstance(say, Mapping) and isinstance(say.get("realizations"), Mapping):
            realizations = say["realizations"]
            key_order = say.get("keyOrder") if isinstance(say.get("keyOrder"), list) else sorted(realizations)
            for rkey in key_order:
                real = realizations.get(rkey)
                if not isinstance(real, Mapping):
                    continue
                for index, variant in enumerate(real.get("variants") or []):
                    if not isinstance(variant, Mapping):
                        continue
                    variant_metadata = variant.get("metadata")
                    explicit_key = (
                        isinstance(variant_metadata, Mapping)
                        and isinstance(variant_metadata.get("textKey"), str)
                        and variant_metadata.get("textKey").strip()
                    )
                    if explicit_key or not has_explicit_rows:
                        variant_id = str(variant.get("id") or f"say_{rkey}_{index + 1}")
                        add(
                            variant.get("text"),
                            metadata_key(variant_metadata, "textKey", variant_id),
                        )
        reply = payload.get("reply")
        if isinstance(reply, Mapping):
            for outcome_name, branch in reply.items():
                if not isinstance(branch, Mapping):
                    continue
                branch_say = branch.get("say")
                if isinstance(branch_say, Mapping) and isinstance(branch_say.get("realizations"), Mapping):
                    realizations = branch_say["realizations"]
                    key_order = (
                        branch_say.get("keyOrder")
                        if isinstance(branch_say.get("keyOrder"), list)
                        else sorted(realizations)
                    )
                    for rkey in key_order:
                        real = realizations.get(rkey)
                        if not isinstance(real, Mapping):
                            continue
                        for index, variant in enumerate(real.get("variants") or []):
                            if not isinstance(variant, Mapping):
                                continue
                            variant_metadata = variant.get("metadata")
                            if isinstance(variant_metadata, Mapping) and isinstance(variant_metadata.get("textKey"), str):
                                add(variant.get("text"), variant_metadata.get("textKey"))
        turns = payload.get("turns")
    if turns is None:
        turns = payload.get("turns")
    if isinstance(turns, list):
        for index, turn in enumerate(turns):
            if not isinstance(turn, Mapping):
                continue
            turn_metadata = turn.get("metadata")
            turn_id = str(turn.get("id") or f"turn_{index + 1}")
            key = metadata_key(turn_metadata, "textKey", f"turn.{turn_id}")
            add(turn.get("text"), key)
            for offer in turn.get("offers", []):
                if not isinstance(offer, Mapping):
                    continue
                offer_id = str(offer.get("id") or "offer")
                offer_metadata = offer.get("metadata")
                choice_key = metadata_key(
                    offer_metadata,
                    "choiceKey",
                    f"offer.{offer_id}.label",
                )
                utterance_key = metadata_key(
                    offer_metadata,
                    "utteranceKey",
                    f"offer.{offer_id}.utterance",
                )
                add(offer.get("label"), choice_key)
                add(offer.get("utterance"), utterance_key)
                if isinstance(offer_metadata, Mapping):
                    add(offer_metadata.get("responseText"), metadata_key(
                        offer_metadata,
                        "responseKey",
                        f"offer.{offer_id}.response",
                    ))
    for field in ("text", "label", "utterance"):
        if field in payload:
            add(payload.get(field), metadata_key(metadata, f"{field}Key", field))
    if isinstance(payload.get("offers"), list):
        for offer in payload["offers"]:
            if not isinstance(offer, Mapping):
                continue
            offer_id = str(offer.get("id") or "offer")
            offer_metadata = offer.get("metadata")
            add(offer.get("label"), metadata_key(
                offer_metadata, "choiceKey", f"offer.{offer_id}.label"
            ))
            add(offer.get("utterance"), metadata_key(
                offer_metadata, "utteranceKey", f"offer.{offer_id}.utterance"
            ))
    text_rows = metadata.get("textRows")
    if isinstance(text_rows, list):
        for row in text_rows:
            if not isinstance(row, Mapping):
                continue
            add(row.get("text"), row.get("key"))
    return rows


def conversation_translation_catalogs(model: dict[str, Any]) -> dict[str, dict[str, dict[str, str]]]:
    """Partition generated translations by Conversation domain, not history."""
    languages = conversation_languages(model)
    catalogs = {language: {} for language in languages}

    def add(language: str, domain: str, key: str, value: Any) -> None:
        if language not in catalogs or not isinstance(key, str) or not isinstance(value, str):
            return
        catalogs[language].setdefault(domain, {})[key] = value

    for family in model["content"].get("phraseFamilies", []):
        domain = str(family.get("conversationDomain") or family.get("group") or "general").title()
        keys = [
            phrase["key"]
            for phrases in family.get("styles", {}).values()
            for phrase in phrases
            if isinstance(phrase, dict) and isinstance(phrase.get("key"), str)
        ]
        for language in languages:
            values = model["content"].get("translations", {}).get(language, {})
            for key in keys:
                add(language, domain, key, values.get(key))
    for choice in model["content"].get("playerChoices", []):
        domain = str(choice.get("conversationDomain") or "greeting").title()
        for language in languages:
            values = model["content"].get("translations", {}).get(language, {})
            add(language, domain, choice.get("labelKey"), values.get(choice.get("labelKey")))
            add(language, domain, choice.get("choiceKey"), values.get(choice.get("choiceKey")))
    for language in languages:
        for key, value in model.get("uiTranslations", {}).get(language, {}).items():
            add(language, "UI", key, value)
        for key, value in model.get("dialogue", {}).get("translations", {}).get(language, {}).items():
            add(language, "Patterns", key, value)
        for key, value in model.get("semantic", {}).get("translations", {}).get(language, {}).items():
            add(language, "Flows", key, value)
    for plan in model.get("convoRuntimePlans", []):
        for language, domain, key, value in _psdl_plan_text_rows(plan):
            add(language, domain, key, value)
    for language in languages:
        catalogs[language] = {
            domain: {key: values[key] for key in sorted(values)}
            for domain, values in sorted(catalogs[language].items())
            if values
        }
    return catalogs


def conversation_translation_catalogs_by_owner(
    model: dict[str, Any],
    *,
    package_repositories: Mapping[str, Path] | None = None,
) -> dict[str, dict[str, dict[str, dict[str, str]]]]:
    """Partition Conversation translations by canonical package owner."""
    languages = conversation_languages(model)
    manifest = model.get("manifest") or {}
    default_owner = normalize_owner(manifest.get("defaultOwner"))
    registry_owner = normalize_owner(
        manifest.get("registryOwner"),
        default=default_owner,
    )
    catalogs: dict[str, dict[str, dict[str, dict[str, str]]]] = {}

    def add(
        owner: Any,
        language: str,
        domain: str,
        key: Any,
        value: Any,
    ) -> None:
        if (
            language not in languages
            or not isinstance(key, str)
            or not isinstance(value, str)
        ):
            return
        canonical_owner = normalize_owner(owner, default=registry_owner)
        owner_catalogs = catalogs.setdefault(canonical_owner, {})
        language_catalogs = owner_catalogs.setdefault(language, {})
        language_catalogs.setdefault(domain, {})[key] = value

    def record_owner(canonical_id: str) -> str:
        record = conversation_record(model, canonical_id) or {}
        return normalize_owner(record.get("owner"), default=default_owner)

    for family in model["content"].get("phraseFamilies", []):
        owner = record_owner("phrase." + str(family.get("semanticTemplateID")))
        domain = str(
            family.get("conversationDomain")
            or family.get("group")
            or "general"
        ).title()
        keys = [
            phrase["key"]
            for phrases in family.get("styles", {}).values()
            for phrase in phrases
            if isinstance(phrase, dict) and isinstance(phrase.get("key"), str)
        ]
        for language in languages:
            values = model["content"].get("translations", {}).get(language, {})
            for key in keys:
                add(owner, language, domain, key, values.get(key))

    for choice in model["content"].get("playerChoices", []):
        owner = record_owner(str(choice.get("id") or ""))
        domain = str(choice.get("conversationDomain") or "greeting").title()
        for language in languages:
            values = model["content"].get("translations", {}).get(language, {})
            add(owner, language, domain, choice.get("labelKey"), values.get(choice.get("labelKey")))
            add(owner, language, domain, choice.get("choiceKey"), values.get(choice.get("choiceKey")))

    def ui_record_owner(canonical_id: str) -> str:
        ui_record = (model.get("uiLocations") or {}).get(str(canonical_id))
        if isinstance(ui_record, dict) and ui_record.get("owner") is not None:
            return normalize_owner(ui_record.get("owner"), default=default_owner)
        return record_owner(canonical_id)

    ui_key_owners: dict[str, str] = {}
    for suggestion in model.get("ui", []):
        owner = ui_record_owner(str(suggestion.get("id") or ""))
        for key in (suggestion.get("labelKey"), suggestion.get("utteranceKey")):
            if isinstance(key, str):
                ui_key_owners[key] = owner
    for text in model.get("uiTexts", []):
        key = text.get("key")
        if isinstance(key, str):
            ui_key_owners[key] = ui_record_owner(str(text.get("id") or ""))
    for language in languages:
        for key, value in model.get("uiTranslations", {}).get(language, {}).items():
            owner = ui_key_owners.get(key, registry_owner)
            add(owner, language, "UI", key, value)
            # The adopter registry is a runtime composition boundary.  Its
            # package-owned UI catalog must include Core UI text because the
            # composed PNC surface loads one package catalog in lightweight
            # harnesses and in installations that do not merge translation
            # manifests across dependencies.
            if owner != registry_owner:
                add(registry_owner, language, "UI", key, value)

    semantic_owner = normalize_owner(
        (model.get("semantic") or {}).get("source", {}).get("owner")
        if isinstance((model.get("semantic") or {}).get("source"), dict)
        else None,
        default=registry_owner,
    )
    for language in languages:
        for key, value in model.get("dialogue", {}).get("translations", {}).get(language, {}).items():
            add(registry_owner, language, "Patterns", key, value)
        for key, value in model.get("semantic", {}).get("translations", {}).get(language, {}).items():
            add(semantic_owner, language, "Flows", key, value)

    locations = model.get("locations") or {}
    pool_owners = (model.get("dialogue") or {}).get("_responsePoolOwners") or {}
    for pool in (model.get("dialogue") or {}).get("responsePools", []):
        if not isinstance(pool, Mapping):
            continue
        raw_pool_id = str(pool.get("id") or "")
        loc = locations.get(raw_pool_id) or {}
        pool_owner = normalize_owner(
            pool_owners.get(raw_pool_id) or loc.get("owner"),
            default=registry_owner,
        )
        for variant in pool.get("variants") or []:
            if not isinstance(variant, Mapping):
                continue
            template_id = str(variant.get("templateID") or "").strip()
            translations = variant.get("translations")
            if template_id and isinstance(translations, Mapping):
                runtime_key = (
                    f"semantic.{template_id}"
                    if (
                        not template_id.startswith("UI_")
                        and not template_id.startswith("semantic.")
                        and not template_id.startswith("conversation.content.")
                        and raw_pool_id
                        and not raw_pool_id.startswith("semantic.")
                        and (template_id == raw_pool_id or template_id.startswith(raw_pool_id + "."))
                    )
                    else template_id
                )
                for raw_lang, raw_vals in translations.items():
                    lang = normalize_language(raw_lang, "response pool locale")
                    vals = raw_vals if isinstance(raw_vals, list) else [raw_vals]
                    if vals and isinstance(vals[0], str):
                        add(pool_owner, lang, "Text/convo/SemanticResponses", runtime_key, vals[0])

    for plan in model.get("convoRuntimePlans", []):
        owner = normalize_owner(plan.get("owner"), default=default_owner)
        for language, domain, key, value in _psdl_plan_text_rows(plan):
            add(owner, language, domain, key, value)
            if domain == "Text/UI_PNC_Conversation":
                add(owner, language, "UI", text_key("UI_PNC_Conversation", key), value)

    return {
        owner: {
            language: {
                domain: {key: values[key] for key in sorted(values)}
                for domain, values in sorted(domains.items())
                if values
            }
            for language, domains in sorted(languages_by_owner.items())
        }
        for owner, languages_by_owner in sorted(catalogs.items())
    }




def render_conversation_runtime_plan(
    model: dict[str, Any],
    *,
    registry_owner: str | None = None,
) -> tuple[list[tuple[str, str]], list[dict[str, Any]]]:
    """Render bounded runtime modules using canonical source ownership."""
    registry_owner = normalize_owner(registry_owner or _registry_owner(model))
    prefix = conversation_prefix(registry_owner)
    content_modules, content_reports = render_dialogue_content_shard_plan(
        model["content"], prefix, max_bytes=CONVERSATION_MAX_SHARD_BYTES
    )
    locations = model.get("locations") or {}
    ui_locations = model.get("uiLocations") or {}
    convo_entries_by_path = {
        str(entry.get("path")): entry
        for entry in (model.get("_manifest_entries") or [])
        if isinstance(entry, dict) and entry.get("kind") == "convo_engine" and entry.get("path")
    }

    def _convo_module_shard(source_shard: str) -> str | None:
        entry = convo_entries_by_path.get(source_shard)
        if entry is None:
            return None
        domain_path = str(entry.get("domainPath") or entry.get("domain") or "general")
        parts = source_shard.split("/")
        if len(parts) >= 3 and parts[0] == "adopters":
            category = parts[2]
        elif parts:
            category = parts[0]
        else:
            category = "dialogue"
        if category in {"behavior", "beat"}:
            return f"director/{domain_path}.json"
        if category == "realization":
            return f"templates/{domain_path}.json"
        return f"dialogue/{domain_path}.json"

    def owned(
        item: dict[str, Any],
        *,
        domain: str,
        lookup: dict[str, dict[str, Any]] | None = None,
    ) -> dict[str, Any]:
        record_id = str(item.get("id") or "")
        loc_map = locations if lookup is None else lookup
        owner = loc_map.get(record_id) if record_id else None
        source_shard = item.get("sourceShard") or (
            owner.get("sourceShard") if isinstance(owner, dict) else None
        )
        resolved_shard = str(source_shard or f"{domain}/{record_id or 'general'}.json")
        module_shard = _convo_module_shard(resolved_shard)
        result = {
            **item,
            "domain": domain,
            "sourceShard": resolved_shard,
        }
        if isinstance(owner, dict) and owner.get("owner") and "owner" not in result:
            result["owner"] = owner["owner"]
        if module_shard is not None:
            result["moduleSourceShard"] = module_shard
        return result

    patterns = [
        *model["dialogue"].get("patterns", []),
        *model["semantic"].get("patterns", []),
    ]
    patterns = [
        owned(
            item,
            domain=(
                str(item.get("id", "general")).split(".")[2]
                if len(str(item.get("id", "")).split(".")) > 2
                else "general"
            ),
        )
        for item in patterns
    ]

    response_pools = [
        *model["dialogue"].get("responsePools", []),
        *model["semantic"].get("responsePools", []),
    ]
    response_pools = [
        owned(
            item,
            domain=(
                str(item.get("id", "general")).split(".")[1]
                if len(str(item.get("id", "")).split(".")) > 1
                else "general"
            ),
        )
        for item in response_pools
    ]

    flow_records = [
        owned(item, domain="semantic")
        for item in model["semantic"].get("flows", [])
    ]
    behavior_records = [
        owned(item, domain=str(item.get("domain") or "social"))
        for item in model.get("behaviors", [])
    ]
    beat_records = [
        owned(item, domain=str(item.get("domain") or "social"))
        for item in model.get("beats", [])
    ]
    realization_records = [
        owned(item, domain=str(item.get("domain") or "general"))
        for item in model.get("realization", [])
    ]
    pack_records = [
        owned(item, domain=str(item.get("domain") or "general"))
        for item in model.get("packs", [])
    ]
    ui_records = [
        owned(item, domain=str(item.get("topic") or "general"), lookup=ui_locations)
        for item in model["ui"]
    ]

    pattern_modules, pattern_reports = _chunk_records(
        patterns, kind="Patterns", module_prefix=prefix
    )
    response_modules, response_reports = _chunk_records(
        response_pools, kind="Responses", module_prefix=prefix
    )
    flow_modules, flow_reports = _chunk_records(
        flow_records, kind="Flows", module_prefix=prefix
    )
    behavior_modules, behavior_reports = _chunk_records(
        behavior_records, kind="Behaviors", module_prefix=prefix
    )
    beat_modules, beat_reports = _chunk_records(
        beat_records, kind="Beats", module_prefix=prefix
    )
    realization_modules, realization_reports = _chunk_records(
        realization_records, kind="Realization", module_prefix=prefix
    )
    pack_modules, pack_reports = _render_pack_shard_plan(
        pack_records,
        module_prefix=prefix,
    )
    psdl_modules: list[tuple[str, str]] = []
    psdl_reports: list[dict[str, Any]] = []
    psdl_groups: dict[tuple[str, str, str], list[dict[str, Any]]] = {}
    for plan in model.get("convoRuntimePlans", []):
        record_id = str(plan.get("id") or "")
        if not record_id:
            raise CompileError("PSDL runtime plan requires id")
        owner = normalize_owner(plan.get("owner"))
        kind = str(plan.get("kind") or "dialogue").lower()
        domain_path = str(plan.get("domainPath") or plan.get("domain") or "general")
        psdl_groups.setdefault((owner, kind, domain_path), []).append(plan)

    psdl_names = ModuleNameRegistry()
    for (owner, kind, domain_path), grouped_plans in sorted(psdl_groups.items()):
        grouped_plans.sort(key=lambda item: str(item.get("id") or ""))
        domain = domain_path.split("/")[0]
        owner_prefix = conversation_prefix(owner)
        start = 0
        while start < len(grouped_plans):
            end = min(start + CONVERSATION_MAX_RECORDS_PER_SHARD, len(grouped_plans))
            while end > start:
                chunk = grouped_plans[start:end]
                first_id = str(chunk[0].get("id") or "record")
                last_id = str(chunk[-1].get("id") or first_id)
                chunk_key = f"{owner}:{kind}:{domain_path}:{first_id}:{last_id}"
                is_split = start > 0 or end < len(grouped_plans)
                path_segments = [kind.title(), *domain_path.split("/")]
                segments = (
                    [*path_segments, semantic_chunk_label((str(p.get("id") or "") for p in chunk), domain=domain)]
                    if is_split
                    else path_segments
                )
                temp_names = psdl_names.clone()
                module = module_path(
                    owner_prefix,
                    segments,
                    chunk_key,
                    temp_names,
                )
                for plan in chunk:
                    plan["module"] = module
                source = render_conversation_lua_records(chunk)
                size = len(source.encode("utf-8"))
                if size <= CONVERSATION_MAX_SHARD_BYTES:
                    psdl_names = temp_names
                    break
                if len(chunk) == 1:
                    raise CompileError(
                        "PSDL runtime plan shard renders above the generated budget: "
                        + f"{owner}/{kind}/{domain}/{first_id}"
                    )
                end -= 1
            start = end
            psdl_modules.append((module, source))
            psdl_reports.append({
                "module": module,
                "kind": "ConvoEngine",
                "domain": domain,
                "sourceShard": str(chunk[0].get("sourceShard") or ""),
                "recordCount": len(chunk),
                "recordIDs": [
                    str(item.get("id"))
                    for item in chunk
                    if isinstance(item.get("id"), str)
                ],
                "bytes": size,
            })
    ui_modules, ui_reports = _chunk_records(
        ui_records, kind="UI", module_prefix=prefix
    )
    modules = [
        *content_modules,
        *pattern_modules,
        *response_modules,
        *flow_modules,
        *behavior_modules,
        *beat_modules,
        *realization_modules,
        *pack_modules,
        *psdl_modules,
        *ui_modules,
    ]
    reports = [
        *content_reports,
        *pattern_reports,
        *response_reports,
        *flow_reports,
        *behavior_reports,
        *beat_reports,
        *realization_reports,
        *pack_reports,
        *psdl_reports,
        *ui_reports,
    ]

    # Canonical source ownership controls physical package ownership.  The
    # combined Hoomans registry may reference Core modules, but CodeBuilder
    # writes those modules into PsychopatzCore instead of duplicating them
    # under the PNC package.
    source_reports = {
        str(item.get("path")): item
        for item in model.get("shards", [])
        if isinstance(item, dict) and item.get("path")
    }
    routed_modules: list[tuple[str, str]] = []
    for (module, source), report in zip(modules, reports):
        owner = source_owner(model, report.get("sourceShard"))
        routed_module = route_module_for_owner(module, owner)
        source_report = source_reports.get(str(report.get("sourceShard")))
        if source_report is not None:
            for key in ("sourceOwner", "sourceRepository", "sourcePath"):
                if key in source_report:
                    report[key] = source_report[key]
        report["shardOwner"] = owner
        report["owner"] = owner
        report["registryOwner"] = registry_owner
        report["module"] = routed_module
        routed_modules.append((routed_module, source))
    modules = routed_modules

    # The existing Hoomans UtterancePlan loader consumes one stable social
    # realization discovery module. Keep that runtime contract while routing
    # the actual flattened realization shards through the Core-owned builder.
    # This is generated package wiring only; PSDL remains the sole source.
    realization_entries = [
        {
            "kind": "realization",
            "generated": [report["module"]],
            "id": report["module"],
        }
        for report in reports
        if report.get("kind") == "Realization"
    ]
    if realization_entries:
        realization_entries.sort(key=lambda item: str(item["id"]))
        realization_index_module = (
            f"{prefix}/Index/Realization/Social"
        )
        realization_index_source = (
            "-- Generated Conversation realization discovery index; do not edit by hand.\n"
            "return " + _lua_value(
                {
                    entry["id"]: entry
                    for entry in realization_entries
                },
                0,
            ) + "\n"
        )
        realization_index_size = len(realization_index_source.encode("utf-8"))
        if realization_index_size > CONVERSATION_MAX_INDEX_BYTES:
            raise CompileError(
                "Conversation realization discovery index exceeds the hard index budget"
            )
        modules.append((realization_index_module, realization_index_source))
        reports.append({
            "module": realization_index_module,
            "kind": "Index",
            "domain": "realization",
            "indexKind": "Realization",
            "sourceShard": "@index/realization/social",
            "recordCount": len(realization_entries),
            "recordIDs": [entry["id"] for entry in realization_entries],
            "bytes": realization_index_size,
            "shardOwner": registry_owner,
            "owner": registry_owner,
            "registryOwner": registry_owner,
        })

    index_modules, index_reports, _ = render_conversation_discovery_indexes(
        model,
        reports,
        module_prefix=prefix,
    )
    for report in index_reports:
        report["shardOwner"] = registry_owner
        report["owner"] = registry_owner
        report["registryOwner"] = registry_owner
    modules.extend(index_modules)
    reports.extend(index_reports)
    return modules, reports







