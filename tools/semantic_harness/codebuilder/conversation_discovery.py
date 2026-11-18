"""Discovery and bounded reverse-reference indexes for Conversation output."""

from __future__ import annotations

from typing import Any, Iterable

from tools.semantic_harness.codebuilder.catalog_naming import pascal_segment

from .conversation_model import runtime_records as _runtime_records
from .conversation_contract import CONVERSATION_MAX_INDEX_BYTES
from .errors import CompileError
from .generation_ownership import conversation_prefix, normalize_owner
from .dialogue_content import _lua_value


def _registry_owner(model: dict[str, Any]) -> str:
    manifest = model.get("manifest")
    owner = manifest.get("registryOwner") if isinstance(manifest, dict) else None
    return normalize_owner(owner)


def _runtime_record_index(model: dict[str, Any]) -> dict[str, dict[str, Any]]:
    records: dict[str, dict[str, Any]] = {}

    def add(values: Iterable[dict[str, Any]]) -> None:
        for record in values:
            if not isinstance(record, dict):
                continue
            record_id = record.get("id")
            if isinstance(record_id, str) and record_id:
                records[record_id] = record

    add(model.get("content", {}).get("phraseFamilies", []))
    add(model.get("content", {}).get("playerChoices", []))
    add(model.get("dialogue", {}).get("patterns", []))
    add(model.get("dialogue", {}).get("responsePools", []))
    add(model.get("semantic", {}).get("patterns", []))
    add(model.get("semantic", {}).get("responsePools", []))
    add(model.get("semantic", {}).get("flows", []))
    add(model.get("behaviors", []))
    add(model.get("beats", []))
    add(model.get("realization", []))
    add(model.get("packs", []))
    add(model.get("convoRuntimePlans", []))
    add(model.get("ui", []))
    return records

def _collect_known_ids(
    value: Any,
    known_ids: set[str],
    output: set[str],
    *,
    depth: int = 0,
) -> None:
    if depth > 8:
        return
    if isinstance(value, str):
        if value in known_ids:
            output.add(value)
        return
    if isinstance(value, list):
        for item in value[:64]:
            _collect_known_ids(
                item,
                known_ids,
                output,
                depth=depth + 1,
            )
        return
    if isinstance(value, dict):
        for key in sorted(value, key=str)[:64]:
            _collect_known_ids(
                value[key],
                known_ids,
                output,
                depth=depth + 1,
            )

def conversation_discovery_index(
    model: dict[str, Any],
    reports: list[dict[str, Any]],
    *,
    relation_limit: int = 8,
    generated_limit: int = 6,
) -> dict[str, dict[str, Any]]:
    """Build a bounded ID->source->generated routing index."""
    locations = model.get("locations") or {}
    known_ids = set(locations)
    generated_by_id: dict[str, str] = {}
    generated_by_source: dict[str, list[str]] = {}
    for report in reports:
        if report.get("kind") in ("Index", "IndexRegistry"):
            continue
        module = report.get("module")
        source_shard = report.get("sourceShard")
        if isinstance(module, str) and isinstance(source_shard, str):
            modules = generated_by_source.setdefault(source_shard, [])
            if module not in modules:
                modules.append(module)
        for record_id in report.get("recordIDs", []):
            if isinstance(record_id, str) and isinstance(module, str):
                generated_by_id[record_id] = module

    runtime_records = _runtime_record_index(model)
    related: dict[str, list[str]] = {}
    dependents: dict[str, set[str]] = {}
    for record_id, record in sorted(runtime_records.items()):
        refs: set[str] = set()
        _collect_known_ids(record, known_ids, refs)
        refs.discard(record_id)
        selected = sorted(refs)[:relation_limit]
        if selected:
            related[record_id] = selected
        for target in selected:
            dependents.setdefault(target, set()).add(record_id)

    index: dict[str, dict[str, Any]] = {}
    for record_id in sorted(locations):
        location = locations[record_id]
        source_shard = str(location.get("sourceShard") or "")
        direct = generated_by_id.get(record_id)
        generated = (
            [direct]
            if direct
            else sorted(generated_by_source.get(source_shard, []))[
                :generated_limit
            ]
        )
        entry = {
            "id": record_id,
            "kind": str(location.get("kind") or "unknown"),
            "domain": str(location.get("domain") or "general"),
            "source": source_shard,
            "generated": generated,
        }
        if related.get(record_id):
            entry["related"] = related[record_id]
        reverse = sorted(dependents.get(record_id, set()))[:relation_limit]
        if reverse:
            entry["dependents"] = reverse
        index[record_id] = entry
    return index

def render_conversation_discovery_indexes(
    model: dict[str, Any],
    reports: list[dict[str, Any]],
    *,
    module_prefix: str | None = None,
) -> tuple[
    list[tuple[str, str]],
    list[dict[str, Any]],
    dict[str, dict[str, Any]],
]:
    """Render small source-routing indexes without aggregating definitions."""
    if module_prefix is None:
        module_prefix = conversation_prefix(_registry_owner(model))
    index = conversation_discovery_index(model, reports)
    grouped: dict[tuple[str, str], dict[str, dict[str, Any]]] = {}
    for record_id, entry in index.items():
        key = (entry["kind"], entry["domain"])
        grouped.setdefault(key, {})[record_id] = entry

    modules: list[tuple[str, str]] = []
    index_reports: list[dict[str, Any]] = []
    manifest_rows: list[dict[str, Any]] = []
    for (kind, domain) in sorted(grouped):
        payload = grouped[(kind, domain)]
        source = (
            "-- Generated Conversation discovery index; do not edit by hand.\n"
            "return " + _lua_value(payload, 0) + "\n"
        )
        size = len(source.encode("utf-8"))
        if size > CONVERSATION_MAX_INDEX_BYTES:
            raise CompileError(
                "Conversation discovery index exceeds the hard index budget; "
                f"split the ownership domain: {kind}/{domain}"
            )
        module = (
            f"{module_prefix}/Index/"
            f"{pascal_segment(kind)}/{pascal_segment(domain)}"
        )
        modules.append((module, source))
        ids = sorted(payload)
        index_reports.append({
            "module": module,
            "kind": "Index",
            "domain": domain,
            "indexKind": kind,
            "sourceShard": f"@index/{kind}/{domain}",
            "recordCount": len(ids),
            "recordIDs": ids,
            "bytes": size,
        })
        manifest_rows.append({
            "kind": kind,
            "domain": domain,
            "module": module,
            "recordCount": len(ids),
        })

    registry_module = f"{module_prefix}/Index/Registry"
    registry_source = (
        "-- Generated Conversation discovery index registry; do not edit by hand.\n"
        "return " + _lua_value(manifest_rows, 0) + "\n"
    )
    registry_size = len(registry_source.encode("utf-8"))
    if registry_size > CONVERSATION_MAX_INDEX_BYTES:
        raise CompileError(
            "Conversation discovery index registry exceeds the hard index budget"
        )
    modules.append((registry_module, registry_source))
    index_reports.append({
        "module": registry_module,
        "kind": "IndexRegistry",
        "domain": "index",
        "sourceShard": "@index/registry",
        "recordCount": len(manifest_rows),
        "recordIDs": [],
        "bytes": registry_size,
    })
    return modules, index_reports, index

