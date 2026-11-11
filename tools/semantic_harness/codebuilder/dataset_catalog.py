"""Canonical Semantic Lab dataset catalog over modular Conversation shards."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Mapping

from .lexicon_compiler import CompileError
from .generation_ownership import (
    CORE_OWNER,
    HOOMANS_OWNER,
    normalize_owner,
    resolve_core_repository,
)
from .dialogue_dataset import compile_dialogue_dataset
from .semantic_definition_compiler import (
    compile_semantic_definitions,
    discover_registered_capability_ids,
)
from tools.semantic_harness.codebuilder.translation_support import pretty_json

CONVERSATION_SOURCE_ROOT = Path(
    "tools/semantic_harness/codebuilder/sources/conversation"
)

DATASET_SOURCE_SPECS = (
    {
        "id": "semantic_flows",
        "label": "Semantic flows",
        "kind": "semantic",
        "path": CONVERSATION_SOURCE_ROOT / "flows/semantic_flows.json",
    },
    {
        "id": "common_dialogue",
        "label": "Common dialogue",
        "kind": "dialogue",
        "patternPaths": (
            CONVERSATION_SOURCE_ROOT / "patterns/common/greeting_whats_up.json",
            CONVERSATION_SOURCE_ROOT / "patterns/common/wellbeing_activity.json",
            CONVERSATION_SOURCE_ROOT / "patterns/common/identity.json",
            CONVERSATION_SOURCE_ROOT / "patterns/common/weather_needs.json",
        ),
        "responsePaths": (
            CONVERSATION_SOURCE_ROOT / "flows/common/social.json",
            CONVERSATION_SOURCE_ROOT / "flows/common/questions.json",
            CONVERSATION_SOURCE_ROOT / "flows/common/needs_weather.json",
        ),
        "patternRoutes": (
            ("pnc.dataset.greeting.", "patterns/common/greeting_whats_up.json"),
            ("pnc.dataset.question.whats_up.", "patterns/common/greeting_whats_up.json"),
            ("pnc.dataset.question.wellbeing.", "patterns/common/wellbeing_activity.json"),
            ("pnc.dataset.question.activity.", "patterns/common/wellbeing_activity.json"),
            ("pnc.dataset.question.identity.", "patterns/common/identity.json"),
            ("pnc.dataset.", "patterns/common/weather_needs.json"),
        ),
        "responseRoutes": (
            ("semantic.greeting", "flows/common/social.json"),
            ("semantic.thanks", "flows/common/social.json"),
            ("semantic.accept", "flows/common/social.json"),
            ("semantic.refuse", "flows/common/social.json"),
            ("semantic.offer", "flows/common/social.json"),
            ("semantic.compliment", "flows/common/social.json"),
            ("semantic.question.needs.", "flows/common/needs_weather.json"),
            ("semantic.flow.weather.", "flows/common/needs_weather.json"),
            ("semantic.question.", "flows/common/questions.json"),
        ),
    },
    {
        "id": "grounded_personal",
        "label": "Grounded personal dialogue",
        "kind": "dialogue",
        "patternPaths": (
            CONVERSATION_SOURCE_ROOT / "patterns/grounded_personal.json",
        ),
        "responsePaths": (
            CONVERSATION_SOURCE_ROOT / "flows/grounded_personal_responses.json",
        ),
    },
    {
        "id": "wordnet_concepts",
        "label": "Reviewed WordNet concepts",
        "kind": "lexicon",
        "path": Path(
    "tools/semantic_harness/codebuilder/sources/wordnet_concepts.json"
        ),
    },
)


WORKFLOW_DATASET_KINDS = frozenset(("semantic", "dialogue"))


def _read_json(path: Path, label: str) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise CompileError(f"cannot read {label} {path}: {error}") from error
    if not isinstance(document, dict):
        raise CompileError(f"{label} must contain an object")
    return document


class SemanticDatasetCatalog:
    """Own canonical dataset discovery, validation, and explicit shard writes."""

    def __init__(
        self,
        repository: Path,
        runtime_root: Path,
        package_repositories: Mapping[str, Path] | None = None,
    ) -> None:
        self.repository = repository
        self.runtime_root = runtime_root
        self.package_repositories = dict(package_repositories or {})

    def _spec_paths(self, spec: dict[str, Any]) -> list[Path]:
        if spec["kind"] == "dialogue":
            return [
                *spec.get("patternPaths", ()),
                *spec.get("responsePaths", ()),
            ]
        return [spec["path"]]

    def _source_path(self, path: Path) -> Path:
        """Resolve a logical shard through the manifest's owner boundary."""
        candidate = self.repository / path
        if candidate.is_file():
            return candidate
        try:
            logical_path = path.relative_to(CONVERSATION_SOURCE_ROOT).as_posix()
        except ValueError:
            return candidate
        core_repository = self.package_repositories.get(CORE_OWNER)
        if core_repository is None:
            core_repository = resolve_core_repository(self.repository)
        core_candidate = Path(core_repository).expanduser().resolve() / path
        manifest_path = self.repository / CONVERSATION_SOURCE_ROOT / "manifest.json"
        if not manifest_path.is_file():
            manifest_path = (
                Path(core_repository).expanduser().resolve()
                / CONVERSATION_SOURCE_ROOT
                / "manifest.json"
            )
        if core_candidate.is_file() and manifest_path.is_file():
            candidate = core_candidate
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as error:
            raise CompileError(
                f"cannot read Conversation manifest {manifest_path}: {error}"
            ) from error
        for shard in manifest.get("externalShards", []):
            if not isinstance(shard, dict) or shard.get("path") != logical_path:
                continue
            owner = normalize_owner(shard.get("owner"))
            repository = self.package_repositories.get(owner)
            if repository is None and owner == CORE_OWNER:
                repository = resolve_core_repository(self.repository)
            if repository is None:
                raise CompileError(
                    f"no repository configured for external Conversation owner {owner}"
                )
            source_path = shard.get("sourcePath")
            if not isinstance(source_path, str) or not source_path:
                raise CompileError(
                    f"external Conversation shard has no sourcePath: {logical_path}"
                )
            return Path(repository).expanduser().resolve() / source_path
        return candidate

    def list_dataset_sources(self) -> list[dict[str, Any]]:
        """Return logical authoring domains backed only by canonical shards."""
        output: list[dict[str, Any]] = []
        for spec in DATASET_SOURCE_SPECS:
            paths = self._spec_paths(spec)
            output.append({
                "id": spec["id"],
                "label": spec["label"],
                "kind": spec["kind"],
                "path": str(paths[0]),
                "paths": [str(path) for path in paths],
                "exists": all(self._source_path(path).is_file() for path in paths),
                "editable": True,
            })
        return output

    def list_workflow_datasets(self) -> list[dict[str, Any]]:
        return [
            {
                **source,
                "generationKind": source["kind"],
                "workflowReady": True,
            }
            for source in self.list_dataset_sources()
            if source["kind"] in WORKFLOW_DATASET_KINDS
        ]

    def _dataset_spec(self, source_id: str) -> dict[str, Any]:
        for spec in DATASET_SOURCE_SPECS:
            if spec["id"] == source_id:
                return spec
        raise ValueError(f"unknown canonical dataset source: {source_id}")

    def _dataset_path(self, source_id: str) -> Path:
        """Return the primary physical shard for diagnostics."""
        spec = self._dataset_spec(source_id)
        return self._source_path(self._spec_paths(spec)[0])

    def _dialogue_documents(
        self, spec: dict[str, Any]
    ) -> tuple[dict[str, Any], dict[str, Any]]:
        pattern_documents = [
            _read_json(
                self._source_path(path),
                f"{spec['id']} pattern shard",
            )
            for path in spec.get("patternPaths", ())
        ]
        response_documents = [
            _read_json(
                self._source_path(path),
                f"{spec['id']} response shard",
            )
            for path in spec.get("responsePaths", ())
        ]
        if not pattern_documents or not response_documents:
            raise CompileError(f"{spec['id']} requires pattern and response shards")
        source = (
            pattern_documents[0].get("source")
            or response_documents[0].get("source")
        )
        return (
            {
                "source": source,
                "patterns": [
                    item
                    for document in pattern_documents
                    for item in document.get("patterns", [])
                ],
            },
            {
                "source": source,
                "responsePools": [
                    item
                    for document in response_documents
                    for item in document.get("responsePools", [])
                ],
            },
        )

    def _dialogue_partition(
        self,
        spec: dict[str, Any],
        *,
        paths_key: str,
        routes_key: str,
        records_key: str,
        records: list[dict[str, Any]],
        source: Any,
    ) -> list[tuple[Path, dict[str, Any]]]:
        paths = list(spec.get(paths_key, ()))
        if not paths:
            raise CompileError(f"{spec['id']} has no {records_key} shards")
        source_root = self.repository / CONVERSATION_SOURCE_ROOT
        loaded: dict[Path, dict[str, Any]] = {
            path: _read_json(
                self._source_path(path),
                f"{spec['id']} {records_key} shard",
            )
            for path in paths
        }
        owner_by_id: dict[str, Path] = {}
        for path, document in loaded.items():
            for item in document.get(records_key, []):
                if isinstance(item, dict) and isinstance(item.get("id"), str):
                    owner_by_id[item["id"]] = path

        route_rows = [
            (prefix, CONVERSATION_SOURCE_ROOT / relative)
            for prefix, relative in spec.get(routes_key, ())
        ]
        buckets: dict[Path, list[dict[str, Any]]] = {path: [] for path in paths}
        for item in records:
            if not isinstance(item, dict) or not isinstance(item.get("id"), str):
                raise CompileError(f"{spec['id']} {records_key} records require IDs")
            record_id = item["id"]
            owner = owner_by_id.get(record_id)
            if owner is None and len(paths) == 1:
                owner = paths[0]
            if owner is None:
                for prefix, candidate in route_rows:
                    if record_id.startswith(prefix):
                        owner = candidate
                        break
            if owner not in buckets:
                raise CompileError(
                    f"{spec['id']} cannot route new {records_key} record {record_id}"
                )
            buckets[owner].append(item)

        output: list[tuple[Path, dict[str, Any]]] = []
        for path in paths:
            document = loaded[path]
            existing_source = (
                document.get("source")
                if isinstance(document.get("source"), dict)
                else {}
            )
            incoming_source = source if isinstance(source, dict) else {}
            merged_source = {
                **incoming_source,
            "owner": normalize_owner(
                existing_source.get("owner"),
                default=HOOMANS_OWNER,
            ),
            }
            # Shard ownership is a physical package contract. Editing the
            # logical mixed dataset may update shared provenance, but cannot
            # migrate a shard between Core and Hoomans as a side effect.
            document["source"] = merged_source or existing_source or source
            document[records_key] = buckets[path]
            output.append((self.repository / path, document))
        return output

    def load_dataset_document(self, source_id: str) -> dict[str, Any]:
        """Load one logical dataset from its canonical modular shard(s)."""
        spec = self._dataset_spec(source_id)
        if spec["kind"] == "semantic":
            shard = _read_json(
                self._source_path(spec["path"]),
                f"{source_id} shard",
            )
            return {
                "schema": "pnc.semantic_authoring.v1",
                "source": shard.get("source"),
                "definitions": shard.get("definitions", []),
            }
        if spec["kind"] == "dialogue":
            patterns, responses = self._dialogue_documents(spec)
            return {
                "schemaVersion": 1,
                "source": patterns.get("source") or responses.get("source"),
                "patterns": patterns.get("patterns", []),
                "responsePools": responses.get("responsePools", []),
            }
        return _read_json(
            self._source_path(spec["path"]),
            f"{source_id} source",
        )

    def search_dataset(
        self,
        query: str = "",
        *,
        source_id: str | None = None,
        limit: int = 64,
    ) -> list[dict[str, Any]]:
        if limit < 1:
            return []
        specs = [self._dataset_spec(source_id)] if source_id else list(
            DATASET_SOURCE_SPECS
        )
        needle = str(query or "").strip().lower()
        rows_by_source: dict[str, list[dict[str, Any]]] = {
            spec["id"]: [] for spec in specs
        }
        for spec in specs:
            document = self.load_dataset_document(spec["id"])
            entries: list[tuple[str, str, Any]] = []
            if spec["kind"] == "semantic":
                entries = [
                    ("definition", str(item.get("id", "<missing>")), item)
                    for item in document.get("definitions", [])
                    if isinstance(item, dict)
                ]
            elif spec["kind"] == "dialogue":
                entries = [
                    ("pattern", str(item.get("id", "<missing>")), item)
                    for item in document.get("patterns", [])
                    if isinstance(item, dict)
                ]
                for pool in document.get("responsePools", []):
                    if not isinstance(pool, dict):
                        continue
                    entries.extend(
                        ("response", str(item.get("id", "<missing>")), item)
                        for item in pool.get("variants", [])
                        if isinstance(item, dict)
                    )
            else:
                concepts = document.get("concepts", {})
                entries = [
                    ("concept", str(concept_id), {"id": concept_id, **value})
                    for concept_id, value in concepts.items()
                    if isinstance(value, dict)
                ]
            path_label = ", ".join(
                str(path) for path in self._spec_paths(spec)
            )
            for entry_kind, entry_id, entry in entries:
                serialized = json.dumps(entry, ensure_ascii=False, sort_keys=True)
                if needle and needle not in serialized.lower():
                    continue
                rows_by_source[spec["id"]].append({
                    "sourceID": spec["id"],
                    "sourceLabel": spec["label"],
                    "kind": entry_kind,
                    "id": entry_id,
                    "path": path_label,
                    "summary": serialized[:512],
                })

        if source_id is not None:
            return rows_by_source[source_id][:limit]
        rows: list[dict[str, Any]] = []
        for spec in specs:
            candidates = rows_by_source[spec["id"]]
            if candidates:
                rows.append(candidates.pop(0))
                if len(rows) >= limit:
                    return rows[:limit]
        for spec in specs:
            for candidate in rows_by_source[spec["id"]]:
                rows.append(candidate)
                if len(rows) >= limit:
                    return rows[:limit]
        return rows

    def preview_dataset_edit(
        self,
        source_id: str,
        document: dict[str, Any],
    ) -> dict[str, Any]:
        spec = self._dataset_spec(source_id)
        report: dict[str, Any] = {
            "ok": False,
            "type": "dataset_edit_preview",
            "sourceID": source_id,
            "sourcePath": ", ".join(
                str(path) for path in self._spec_paths(spec)
            ),
            "previewOnly": True,
            "effectFree": True,
            "writes": [],
        }
        if not isinstance(document, dict):
            report["diagnostics"] = [{
                "severity": "error",
                "message": "dataset root must be an object",
            }]
            return report
        try:
            if spec["kind"] == "semantic":
                compiled = compile_semantic_definitions(
                    document,
                    discover_registered_capability_ids(
                        self.runtime_root,
                        package_repositories=self.package_repositories,
                    ),
                )
                summary = {
                    "definitions": len(document.get("definitions", [])),
                    "patterns": len(compiled["patterns"]),
                    "flows": len(compiled["flows"]),
                }
            elif spec["kind"] == "dialogue":
                compiled = compile_dialogue_dataset(document)
                summary = {
                    "patterns": len(compiled["patterns"]),
                    "responsePools": len(compiled["responsePools"]),
                    "responseVariants": sum(
                        len(pool["variants"])
                        for pool in compiled["responsePools"]
                    ),
                }
            else:
                concepts = document.get("concepts")
                if not isinstance(concepts, dict):
                    raise CompileError(
                        "wordnet concepts requires a concepts object"
                    )
                if any(
                    not isinstance(value, dict)
                    for value in concepts.values()
                ):
                    raise CompileError(
                        "wordnet concepts values must be objects"
                    )
                summary = {
                    "concepts": len(concepts),
                    "sourceVersion": (
                        document.get("source", {}).get("version")
                        if isinstance(document.get("source", {}), dict)
                        else None
                    ),
                }
        except (CompileError, OSError, ValueError, TypeError) as error:
            report["diagnostics"] = [{
                "severity": "error",
                "message": str(error),
            }]
            return report
        report.update({
            "ok": True,
            "diagnostics": [],
            "summary": summary,
        })
        return report

    def _write_semantic_shard(
        self,
        spec: dict[str, Any],
        document: dict[str, Any],
    ) -> list[Path]:
        path = self.repository / spec["path"]
        current = _read_json(path, "semantic flow shard")
        current["source"] = document.get("source")
        current["definitions"] = document.get("definitions", [])
        path.write_text(
            pretty_json(current),
            encoding="utf-8",
            newline="\n",
        )
        return [path]

    def _write_dialogue_shards(
        self,
        spec: dict[str, Any],
        document: dict[str, Any],
    ) -> list[Path]:
        partitions = [
            *self._dialogue_partition(
                spec,
                paths_key="patternPaths",
                routes_key="patternRoutes",
                records_key="patterns",
                records=document.get("patterns", []),
                source=document.get("source"),
            ),
            *self._dialogue_partition(
                spec,
                paths_key="responsePaths",
                routes_key="responseRoutes",
                records_key="responsePools",
                records=document.get("responsePools", []),
                source=document.get("source"),
            ),
        ]
        paths: list[Path] = []
        for path, shard in partitions:
            self._source_path(path).write_text(
                pretty_json(shard),
                encoding="utf-8",
                newline="\n",
            )
            paths.append(self._source_path(path))
        return paths

    def conversation_source_overrides(
        self,
        source_id: str,
        document: dict[str, Any],
    ) -> dict[str, dict[str, Any]]:
        """Map one logical dataset edit back to its canonical Conversation shard(s)."""
        spec = self._dataset_spec(source_id)
        if spec["kind"] == "semantic":
            path = self.repository / spec["path"]
            shard = _read_json(path, "semantic flow shard")
            shard["source"] = document.get("source")
            shard["definitions"] = document.get("definitions", [])
            relative = path.relative_to(
                self.repository / CONVERSATION_SOURCE_ROOT
            ).as_posix()
            return {relative: shard}
        if spec["kind"] == "dialogue":
            partitions = [
                *self._dialogue_partition(
                    spec,
                    paths_key="patternPaths",
                    routes_key="patternRoutes",
                    records_key="patterns",
                    records=document.get("patterns", []),
                    source=document.get("source"),
                ),
                *self._dialogue_partition(
                    spec,
                    paths_key="responsePaths",
                    routes_key="responseRoutes",
                    records_key="responsePools",
                    records=document.get("responsePools", []),
                    source=document.get("source"),
                ),
            ]
            source_root = self.repository / CONVERSATION_SOURCE_ROOT
            return {
                path.relative_to(source_root).as_posix(): shard
                for path, shard in partitions
            }
        return {}

    def write_dataset_document(
        self,
        source_id: str,
        document: dict[str, Any],
    ) -> dict[str, Any]:
        """Explicitly write validated canonical shard(s); never writes projections."""
        report = self.preview_dataset_edit(source_id, document)
        if report.get("ok") is not True:
            return report
        spec = self._dataset_spec(source_id)
        if spec["kind"] == "semantic":
            paths = self._write_semantic_shard(spec, document)
        elif spec["kind"] == "dialogue":
            paths = self._write_dialogue_shards(spec, document)
        else:
            path = self.repository / spec["path"]
            path.write_text(
                pretty_json(document),
                encoding="utf-8",
                newline="\n",
            )
            paths = [path]
        return {
            **report,
            "previewOnly": False,
            "effectFree": False,
            "writes": [str(path) for path in paths],
        }
