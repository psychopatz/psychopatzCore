"""Shared Semantic Lab authoring/build service.

The service is the single boundary used by the Tk editor, headless CLI, and
direct Python/Codex callers. The lower-level compiler and writer remain in the
embedded CodeBuilder; the existing authoring module remains the compatibility
implementation for its report shapes and public helper functions.
"""

from __future__ import annotations

import copy
import json
import shutil
import tempfile
from pathlib import Path
from typing import Any

from . import authoring
from .dataset_catalog import (
    DATASET_SOURCE_SPECS,
    WORKFLOW_DATASET_KINDS,
    SemanticDatasetCatalog,
)
from .interaction_generation import SemanticInteractionAuthoring
from .blocks import SemanticBlockRegistry
from .codeblocks import validate_codeblock_document
from .dataset_adapters import preview_dataset_adapter, promote_reviewed_candidates
from .interaction_explorer import build_interaction_rows, search_interactions
from .dialogue_content import (
    compile_dialogue_content,
    derived_canonical_concept,
)
from .conversation_compiler import (
    CONVERSATION_MANIFEST_RELATIVE,
    CONVERSATION_SOURCE_RELATIVE,
    compile_conversation_sources,
    conversation_affected_closure,
    conversation_context_health,
    conversation_discovery_index,
    conversation_record,
    render_conversation_manifest_lua,
    render_conversation_registry,
    render_conversation_runtime_plan,
)
from .conversation_model import fingerprint
from .psdl_compiler import (
    compile_psdl_document as _compile_psdl_document,
    compile_psdl_sources as _compile_psdl_sources,
    render_psdl_runtime_plan,
)
from .lexicon_compiler import CompileError
from .generation_ownership import (
    CORE_OWNER,
    DT_COMMON_OWNER,
    HOOMANS_OWNER,
    conversation_prefix,
    generated_conversation_root,
    module_target,
    normalize_owner,
    owner_repository,
    resolve_core_repository,
)
from .translation_support import normalize_language


class SemanticLabAuthoringService:
    """Bind one repository/runtime configuration to all authoring operations."""

    def __init__(
        self,
        repository: Path | None = None,
        *,
        runtime_root: Path | None = None,
        core_repository: Path | None = None,
        dynamic_trading_repository: Path | None = None,
    ) -> None:
        self.repository = (repository or authoring.REPOSITORY).expanduser().resolve()
        self.runtime_root = (
            runtime_root or self.repository
        ).expanduser().resolve()
        self.core_repository = resolve_core_repository(
            self.repository,
            explicit=core_repository,
            runtime_root=self.runtime_root,
        )
        self.dynamic_trading_repository = (
            dynamic_trading_repository.expanduser().resolve()
            if dynamic_trading_repository is not None
            else None
        )
        self.package_repositories = {
            HOOMANS_OWNER: self.repository,
            CORE_OWNER: self.core_repository,
        }
        if self.dynamic_trading_repository is not None:
            self.package_repositories[DT_COMMON_OWNER] = (
                self.dynamic_trading_repository
            )
        self.dataset_catalog = SemanticDatasetCatalog(
            self.repository,
            self.runtime_root,
            self.package_repositories,
        )
        self.block_registry = SemanticBlockRegistry(
            self.repository,
            DATASET_SOURCE_SPECS,
        )
        self.interaction_authoring = SemanticInteractionAuthoring(
            self.dataset_catalog,
            self.block_registry,
            self.repository,
            self.runtime_root,
            self.core_repository,
            self.dynamic_trading_repository,
        )

    def list_dataset_sources(self) -> list[dict[str, Any]]:
        return self.dataset_catalog.list_dataset_sources()

    def list_workflow_datasets(self) -> list[dict[str, Any]]:
        return self.dataset_catalog.list_workflow_datasets()

    def _dataset_spec(self, source_id: str) -> dict[str, Any]:
        return self.dataset_catalog._dataset_spec(source_id)

    def _dataset_path(self, source_id: str) -> Path:
        return self.dataset_catalog._dataset_path(source_id)

    def load_dataset_document(self, source_id: str) -> dict[str, Any]:
        return self.dataset_catalog.load_dataset_document(source_id)

    def search_dataset(
        self,
        query: str = "",
        *,
        source_id: str | None = None,
        limit: int = 64,
    ) -> list[dict[str, Any]]:
        return self.dataset_catalog.search_dataset(
            query,
            source_id=source_id,
            limit=limit,
        )

    def preview_dataset_edit(
        self,
        source_id: str,
        document: dict[str, Any],
    ) -> dict[str, Any]:
        return self.dataset_catalog.preview_dataset_edit(source_id, document)

    def write_dataset_document(
        self,
        source_id: str,
        document: dict[str, Any],
    ) -> dict[str, Any]:
        return self.dataset_catalog.write_dataset_document(source_id, document)

    def preview_dataset_generation(self, source_id: str) -> dict[str, Any]:
        """Validate a logical canonical dataset through the full Conversation plan."""
        document = self.load_dataset_document(source_id)
        report = self.preview_dataset_edit(source_id, document)
        if report.get("ok") is True and self._dataset_spec(source_id)["kind"] in {
            "semantic", "dialogue"
        }:
            report.update(
                self.interaction_authoring._conversation_preview_artifacts(
                    source_id, document
                )
            )
        return report

    @property
    def dialogue_content_source_path(self) -> Path:
        """Return the manifest, never a generated compatibility snapshot."""
        return self.repository / CONVERSATION_MANIFEST_RELATIVE

    def _conversation_model(self) -> dict[str, Any]:
        return compile_conversation_sources(
            self.repository,
            runtime_root=self.runtime_root,
            package_repositories=self.package_repositories,
        )

    def preview_psdl_document(
        self,
        document: dict[str, Any],
        *,
        source_path: str | Path | None = None,
    ) -> dict[str, Any]:
        """Compile PSDL through the shared Core service without writing output."""
        compiled = _compile_psdl_document(document, source_path=source_path)
        return {
            "ok": True,
            "compiled": compiled,
            "runtimePlan": render_psdl_runtime_plan(compiled),
        }

    def preview_psdl_sources(
        self,
        sources: dict[str | Path, dict[str, Any]],
    ) -> dict[str, Any]:
        """Compile multiple adopter-owned PSDL sources through Core."""
        compiled = _compile_psdl_sources(sources)
        return {
            "ok": True,
            "compiled": compiled,
            "runtimePlan": render_psdl_runtime_plan(compiled),
        }

    def list_psdl_sources(self) -> list[dict[str, Any]]:
        """List manifest-routed PSDL sources across Core and adopter packages.

        Semantic Lab uses this index for structured authoring.  The source
        path is resolved through the manifest owner, so the UI cannot
        accidentally write a ProjectHoomans or DynamicTrading record into
        the Core checkout (or vice versa).
        """
        model = self._conversation_model()
        manifest = model.get("manifest") or {}
        documents = model.get("_source_documents") or {}
        sources: list[dict[str, Any]] = []
        for entry in manifest.get("externalShards", []):
            if not isinstance(entry, dict) or entry.get("kind") != "psdl":
                continue
            owner = normalize_owner(
                entry.get("owner"),
                default=normalize_owner(manifest.get("defaultOwner")),
            )
            repository = owner_repository(
                self.repository,
                owner,
                core_repository=self.core_repository,
                dynamic_trading_repository=self.dynamic_trading_repository,
                runtime_root=self.runtime_root,
            )
            source_path = repository / str(entry.get("sourcePath", entry.get("path", "")))
            document = documents.get(entry.get("path"))
            records = document.get("records", []) if isinstance(document, dict) else []
            source_id = f"{owner}:{entry.get('path')}"
            sources.append(
                {
                    "sourceID": source_id,
                    "path": entry.get("path"),
                    "sourcePath": str(source_path),
                    "owner": owner,
                    "domain": entry.get("domain"),
                    "shardID": entry.get("shardId"),
                    "sourceProfile": entry.get("sourceProfile"),
                    "exists": source_path.is_file(),
                    "editable": source_path.is_file(),
                    "schema": document.get("schema") if isinstance(document, dict) else None,
                    "recordCount": len(records) if isinstance(records, list) else 0,
                    "recordIDs": [
                        item.get("id")
                        for item in records
                        if isinstance(item, dict) and isinstance(item.get("id"), str)
                    ],
                }
            )
        return sorted(sources, key=lambda item: (str(item.get("owner")), str(item.get("path"))))

    def load_psdl_source(self, source_ref: str | Path) -> dict[str, Any]:
        """Load one manifest-routed PSDL document for structured editing."""
        reference = str(source_ref)
        source = next(
            (
                item
                for item in self.list_psdl_sources()
                if reference in {str(item.get("sourceID")), str(item.get("path")), str(item.get("sourcePath"))}
            ),
            None,
        )
        if source is None:
            raise CompileError(f"unknown PSDL source: {reference}")
        target = Path(str(source["sourcePath"])).expanduser().resolve()
        if not target.is_file():
            raise CompileError(f"PSDL source is missing: {target}")
        document = json.loads(target.read_text(encoding="utf-8"))
        if not isinstance(document, dict):
            raise CompileError(f"PSDL source must contain an object: {target}")
        return document

    @staticmethod
    def _psdl_authoring_records(document: dict[str, Any]) -> list[dict[str, Any]]:
        """Return mutable record copies for Core-owned source editing."""
        if not isinstance(document, dict):
            raise CompileError("PSDL authoring document must be an object")
        if document.get("schema") != "psychopatz.semantic.dialogue-language.v1":
            raise CompileError(
                "PSDL authoring document must use "
                "psychopatz.semantic.dialogue-language.v1"
            )
        records = document.get("records")
        if not isinstance(records, list) or not records:
            raise CompileError(
                "PSDL authoring operations require a non-empty records list"
            )
        if any(not isinstance(record, dict) for record in records):
            raise CompileError("PSDL authoring records must be objects")
        return records

    def validate_psdl_document(
        self,
        document: dict[str, Any],
        *,
        source_path: str | Path | None = None,
    ) -> dict[str, Any]:
        """Return bounded diagnostics for an effect-free PSDL validation pass."""
        try:
            return self.preview_psdl_document(document, source_path=source_path)
        except (CompileError, OSError, TypeError, ValueError) as error:
            return {
                "ok": False,
                "previewOnly": True,
                "effectFree": True,
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "writes": [],
            }

    def _psdl_authoring_result(
        self,
        document: dict[str, Any],
        *,
        source_path: str | Path | None = None,
    ) -> dict[str, Any]:
        report = self.validate_psdl_document(document, source_path=source_path)
        if report.get("ok") is not True:
            return report
        return {
            "ok": True,
            "previewOnly": True,
            "effectFree": True,
            "document": document,
            "sourceFingerprint": fingerprint(document),
            "compiledFingerprint": report["compiled"]["fingerprint"],
            "preview": report,
            "writes": [],
        }

    def create_psdl_record(
        self,
        document: dict[str, Any],
        record: dict[str, Any],
        *,
        index: int | None = None,
        source_path: str | Path | None = None,
    ) -> dict[str, Any]:
        """Create one source record, then validate the complete catalog."""
        candidate = copy.deepcopy(document)
        records = self._psdl_authoring_records(candidate)
        if not isinstance(record, dict):
            raise CompileError("PSDL record must be an object")
        record_id = record.get("id")
        if not isinstance(record_id, str) or not record_id.strip():
            raise CompileError("PSDL record.id is required")
        if any(item.get("id") == record_id for item in records):
            raise CompileError(f"PSDL authoring record already exists: {record_id}")
        if index is None:
            records.append(copy.deepcopy(record))
        else:
            if isinstance(index, bool) or not isinstance(index, int):
                raise CompileError("PSDL record index must be an integer")
            if index < 0 or index > len(records):
                raise CompileError("PSDL record index is outside the catalog")
            records.insert(index, copy.deepcopy(record))
        return self._psdl_authoring_result(candidate, source_path=source_path)

    def edit_psdl_record(
        self,
        document: dict[str, Any],
        record_id: str,
        patch: dict[str, Any],
        *,
        source_path: str | Path | None = None,
    ) -> dict[str, Any]:
        """Apply a bounded top-level edit without changing the canonical ID."""
        candidate = copy.deepcopy(document)
        records = self._psdl_authoring_records(candidate)
        if not isinstance(patch, dict):
            raise CompileError("PSDL record patch must be an object")
        matches = [item for item in records if item.get("id") == record_id]
        if len(matches) != 1:
            raise CompileError(f"unknown PSDL authoring record: {record_id}")
        if "id" in patch and patch["id"] != record_id:
            raise CompileError("PSDL authoring edits cannot change record.id")
        target = matches[0]
        target.update(copy.deepcopy(patch))
        return self._psdl_authoring_result(candidate, source_path=source_path)

    def duplicate_psdl_record(
        self,
        document: dict[str, Any],
        record_id: str,
        new_record_id: str,
        *,
        overrides: dict[str, Any] | None = None,
        index: int | None = None,
        source_path: str | Path | None = None,
    ) -> dict[str, Any]:
        """Duplicate a record with an explicit semantic identity."""
        candidate = copy.deepcopy(document)
        records = self._psdl_authoring_records(candidate)
        source = next((item for item in records if item.get("id") == record_id), None)
        if source is None:
            raise CompileError(f"unknown PSDL authoring record: {record_id}")
        if not isinstance(new_record_id, str) or not new_record_id.strip():
            raise CompileError("new PSDL record.id is required")
        duplicate = copy.deepcopy(source)
        duplicate["id"] = new_record_id
        if overrides is not None:
            if not isinstance(overrides, dict):
                raise CompileError("PSDL duplicate overrides must be an object")
            if "id" in overrides and overrides["id"] != new_record_id:
                raise CompileError("PSDL duplicate overrides cannot change record.id")
            duplicate.update(copy.deepcopy(overrides))
            duplicate["id"] = new_record_id
        if index is None:
            records.append(duplicate)
        else:
            if isinstance(index, bool) or not isinstance(index, int):
                raise CompileError("PSDL record index must be an integer")
            if index < 0 or index > len(records):
                raise CompileError("PSDL record index is outside the catalog")
            records.insert(index, duplicate)
        return self._psdl_authoring_result(candidate, source_path=source_path)

    def delete_psdl_record(
        self,
        document: dict[str, Any],
        record_id: str,
        *,
        source_path: str | Path | None = None,
    ) -> dict[str, Any]:
        """Delete one source record and validate remaining references."""
        candidate = copy.deepcopy(document)
        records = self._psdl_authoring_records(candidate)
        kept = [item for item in records if item.get("id") != record_id]
        if len(kept) == len(records):
            raise CompileError(f"unknown PSDL authoring record: {record_id}")
        if not kept:
            raise CompileError("PSDL authoring catalogs cannot become empty")
        candidate["records"] = kept
        return self._psdl_authoring_result(candidate, source_path=source_path)

    def reorder_psdl_records(
        self,
        document: dict[str, Any],
        record_ids: list[str],
        *,
        source_path: str | Path | None = None,
    ) -> dict[str, Any]:
        """Reorder authored records while preserving canonical ID identity."""
        candidate = copy.deepcopy(document)
        records = self._psdl_authoring_records(candidate)
        current = [item.get("id") for item in records]
        if sorted(record_ids) != sorted(current) or len(record_ids) != len(current):
            raise CompileError("PSDL reorder must name every record exactly once")
        by_id = {item["id"]: item for item in records}
        candidate["records"] = [by_id[record_id] for record_id in record_ids]
        return self._psdl_authoring_result(candidate, source_path=source_path)

    def write_psdl_source(
        self,
        source_path: str | Path,
        document: dict[str, Any],
        *,
        expected_source_fingerprint: str | None = None,
    ) -> dict[str, Any]:
        """Write only a validated PSDL source; generated output stays downstream."""
        target = Path(source_path)
        if not target.is_absolute():
            target = self.repository / target
        target = target.expanduser().resolve()
        allowed_roots = {
            self.repository.resolve(),
            self.core_repository.resolve(),
        }
        if self.dynamic_trading_repository is not None:
            allowed_roots.add(self.dynamic_trading_repository.resolve())
        if not any(
            target == root or root in target.parents
            for root in allowed_roots
        ):
            raise CompileError(
                "PSDL source must remain inside the service or a manifest-routed package repository"
            )
        if target.suffix.lower() != ".json":
            raise CompileError("PSDL source must be a JSON file")
        if expected_source_fingerprint and target.is_file():
            current = json.loads(target.read_text(encoding="utf-8"))
            actual = fingerprint(current)
            if actual != expected_source_fingerprint:
                return {
                    "ok": False,
                    "stale": True,
                    "reason": "source_fingerprint_mismatch",
                    "expectedSourceFingerprint": expected_source_fingerprint,
                    "sourceFingerprint": actual,
                    "writes": [],
                }
        report = self.validate_psdl_document(document, source_path=target)
        if report.get("ok") is not True:
            return report
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(
            json.dumps(document, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        return {
            "ok": True,
            "writeApproved": True,
            "generatedOutputRequired": True,
            "sourcePath": str(target),
            "sourceFingerprint": fingerprint(document),
            "compiledFingerprint": report["compiled"]["fingerprint"],
            "writes": [str(target)],
        }

    def _conversation_registry_location(
        self,
        model: dict[str, Any],
    ) -> tuple[Path, Path]:
        """Return the descriptor-routed aggregate registry repository/path."""
        manifest = model.get("manifest") or {}
        owner = normalize_owner(
            manifest.get("registryOwner"),
        )
        repository = owner_repository(
            self.repository,
            owner,
            core_repository=self.core_repository,
            dynamic_trading_repository=self.dynamic_trading_repository,
            runtime_root=self.runtime_root,
        )
        root = generated_conversation_root(
            self.repository,
            owner,
            core_repository=self.core_repository,
            dynamic_trading_repository=self.dynamic_trading_repository,
            runtime_root=self.runtime_root,
        )
        return repository, root.relative_to(repository)

    def _conversation_plan(
        self,
    ) -> tuple[dict[str, Any], list[tuple[str, str]], list[dict[str, Any]]]:
        model = self._conversation_model()
        rendered, reports = render_conversation_runtime_plan(model)
        return model, rendered, reports

    def conversation_context_health(self) -> dict[str, Any]:
        """Return bounded compiler-owned source/shard context-health evidence."""
        model, _rendered, reports = self._conversation_plan()
        return conversation_context_health(model, reports)

    def conversation_discovery_record(
        self,
        canonical_id: str,
    ) -> dict[str, Any] | None:
        """Return one lightweight ID->source->generated routing record."""
        model, _rendered, reports = self._conversation_plan()
        index = conversation_discovery_index(model, reports)
        record = index.get(str(canonical_id))
        return (
            json.loads(json.dumps(record, ensure_ascii=False))
            if isinstance(record, dict)
            else None
        )

    def conversation_affected_closure(
        self,
        canonical_id: str,
        *,
        limit: int = 24,
    ) -> dict[str, Any] | None:
        """Return the bounded one-hop authoring/runtime dependency closure."""
        model, _rendered, reports = self._conversation_plan()
        closure = conversation_affected_closure(
            model,
            reports,
            canonical_id,
            limit=limit,
        )
        return (
            json.loads(json.dumps(closure, ensure_ascii=False))
            if isinstance(closure, dict)
            else None
        )

    @staticmethod
    def _content_shard_report(model: dict[str, Any], source_shard: str) -> dict[str, Any]:
        for report in model.get("shards", []):
            if report.get("path") == source_shard:
                return report
        raise KeyError(f"unknown Conversation content shard: {source_shard}")

    @classmethod
    def _generated_module_for_shard(
        cls,
        model: dict[str, Any],
        source_shard: str,
        suffix: str,
    ) -> str:
        """Return a generated module name from the shard's package owner."""
        report = cls._content_shard_report(model, source_shard)
        manifest = model.get("manifest") or {}
        owner = normalize_owner(
            report.get("owner"),
            default=normalize_owner(manifest.get("defaultOwner")),
        )
        return f"{conversation_prefix(owner)}/{suffix}"

    def _content_source_path(self, source_shard: str) -> Path:
        return self.repository / CONVERSATION_SOURCE_RELATIVE / Path(source_shard)

    @staticmethod
    def _dehydrate_content_shard(document: dict[str, Any]) -> dict[str, Any]:
        """Remove compiler-only provenance before writing the source recipe."""
        result = json.loads(json.dumps(document, ensure_ascii=False))
        result.pop("source", None)
        result.pop("version", None)
        return result

    @staticmethod
    def _merge_editor_translations(
        current: Any,
        edited: Any,
        label: str,
    ) -> dict[str, str]:
        """Merge partial editor input without erasing untouched locales."""
        if not isinstance(current, dict) or not isinstance(edited, dict):
            raise CompileError(f"{label} requires a translation map")
        merged: dict[str, str] = {}
        for language, text in current.items():
            normalized = normalize_language(language, f"{label} language")
            if not isinstance(text, str) or not text.strip():
                raise CompileError(f"{label}.{normalized} requires non-empty text")
            merged[normalized] = text
        for language, text in edited.items():
            normalized = normalize_language(language, f"{label} language")
            if not isinstance(text, str) or not text.strip():
                raise CompileError(f"{label}.{normalized} requires non-empty text")
            merged[normalized] = text
        return {language: merged[language] for language in sorted(merged)}

    @staticmethod
    def _source_locale_map(value: Any) -> dict[str, str]:
        """Extract authored locale fields from a self-contained source record."""
        if not isinstance(value, dict):
            return {}
        result: dict[str, str] = {}
        for raw_language, text in value.items():
            try:
                language = normalize_language(raw_language, "source locale")
            except CompileError:
                continue
            if isinstance(text, str):
                result[language] = text
        return {language: result[language] for language in sorted(result)}

    def _conversation_content_document(self, model: dict[str, Any]) -> dict[str, Any]:
        """Merge authored content shards in memory without creating an aggregate file."""
        groups: dict[str, Any] = {}
        phrase_families: list[dict[str, Any]] = []
        player_choices: list[dict[str, Any]] = []
        source_metadata: dict[str, Any] | None = None

        for source_path, document in sorted(
            model.get("_source_documents", {}).items()
        ):
            if not str(source_path).startswith("content/"):
                continue
            if not isinstance(document, dict):
                continue
            if source_metadata is None and isinstance(document.get("source"), dict):
                source_metadata = json.loads(
                    json.dumps(document["source"], ensure_ascii=False)
                )
            for group_id, definition in (document.get("groups") or {}).items():
                existing = groups.get(group_id)
                if existing is not None and existing != definition:
                    raise CompileError(
                        f"Conversation content group {group_id} conflicts across shards"
                    )
                groups[group_id] = json.loads(
                    json.dumps(definition, ensure_ascii=False)
                )
            phrase_families.extend(
                json.loads(
                    json.dumps(document.get("phraseFamilies", []), ensure_ascii=False)
                )
            )
            player_choices.extend(
                json.loads(
                    json.dumps(document.get("playerChoices", []), ensure_ascii=False)
                )
            )

        phrase_families.sort(
            key=lambda item: str(item.get("semanticTemplateID") or item.get("id") or "")
        )
        player_choices.sort(key=lambda item: str(item.get("id") or ""))
        manifest = model.get("manifest") or {}
        default_owner = normalize_owner(manifest.get("defaultOwner"))
        return {
            "schemaVersion": 4,
            "source": source_metadata or {"owner": default_owner},
            "groups": {key: groups[key] for key in sorted(groups)},
            "phraseFamilies": phrase_families,
            "playerChoices": player_choices,
        }

    def _raw_content_item(
        self,
        model: dict[str, Any],
        content_id: str,
    ) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any]] | None:
        location = conversation_record(model, content_id)
        if not isinstance(location, dict) or location.get("kind") != "content":
            return None
        source_shard = str(location["sourceShard"])
        source_document = model.get("_source_documents", {}).get(source_shard)
        if not isinstance(source_document, dict):
            return None
        item = self._content_item(source_document, content_id)
        if item is None:
            return None
        return item, source_document, location

    def preview_dialogue_content_source(self) -> dict[str, Any]:
        try:
            model = self._conversation_model()
        except (OSError, ValueError, TypeError, CompileError) as error:
            return {
                "ok": False,
                "type": "conversation_compile_preview",
                "previewOnly": True,
                "effectFree": True,
                "sourcePath": str(self.dialogue_content_source_path),
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "writes": [],
            }
        return {
            "ok": True,
            "type": "conversation_compile_preview",
            "schema": model["schema"],
            "repository": str(self.repository),
            "sourcePath": str(self.dialogue_content_source_path),
            "previewOnly": True,
            "effectFree": True,
            "wholeModelFingerprint": model["wholeModelFingerprint"],
            "phraseFamilyCount": len(model["content"]["phraseFamilies"]),
            "phraseCount": sum(
                len(phrases)
                for family in model["content"]["phraseFamilies"]
                for phrases in family["styles"].values()
            ),
            "playerChoiceCount": len(model["content"]["playerChoices"]),
            "patternCount": len(model["dialogue"]["patterns"]),
            "flowCount": len(model["semantic"]["flows"]),
            "uiSuggestionCount": len(model["ui"]),
            "shards": model["shards"],
            "writes": [],
        }

    def generate_dialogue_content_source(self) -> dict[str, Any]:
        preview = self.preview_dialogue_content_source()
        if preview.get("ok") is not True:
            return preview
        try:
            from .build import write_conversation_output

            model = self._conversation_model()
            written = write_conversation_output(
                self.repository,
                model,
                core_repository=self.core_repository,
                dynamic_trading_repository=self.dynamic_trading_repository,
            )
        except (OSError, ValueError, TypeError, CompileError) as error:
            return {
                **preview,
                "ok": False,
                "generationApproved": True,
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "writes": [],
            }
        return {
            **self.preview_dialogue_content_source(),
            "generationApproved": True,
            "writes": [str(path) for path in written],
            "reloadedBy": "caller_restart_required",
        }

    def _dialogue_content_document(self) -> dict[str, Any]:
        return self._conversation_content_document(self._conversation_model())

    @staticmethod
    def _family_id(family: dict[str, Any]) -> str:
        return str(
            family.get("id")
            or "phrase." + str(family.get("semanticTemplateID") or "unknown")
        )

    @classmethod
    def _content_item(
        cls, document: dict[str, Any], content_id: str
    ) -> dict[str, Any] | None:
        for family in document.get("phraseFamilies", []):
            if isinstance(family, dict) and cls._family_id(family) == content_id:
                item = {"kind": "phraseFamily", **family}
                item["styles"] = {
                    style: [
                        {"translations": cls._source_locale_map(phrase)}
                        if isinstance(phrase, dict)
                        else phrase
                        for phrase in phrases
                    ]
                    for style, phrases in (family.get("styles") or {}).items()
                }
                item["id"] = cls._family_id(family)
                item["canonicalConcept"] = item.get("canonicalConcept") or derived_canonical_concept(
                    str(item.get("semanticTemplateID") or item["id"])
                )
                if not item.get("contentOwner"):
                    groups = document.get("groups") or {}
                    group = groups.get(item.get("group"))
                    if isinstance(group, dict):
                        item["contentOwner"] = group.get("contentOwner")
                return item
        for choice in document.get("playerChoices", []):
            if isinstance(choice, dict) and choice.get("id") == content_id:
                item = {
                    "kind": "playerChoice",
                    **{
                        key: value
                        for key, value in choice.items()
                        if key not in {"label", "choice"}
                    },
                    "labelTranslations": cls._source_locale_map(choice.get("label")),
                    "choiceTranslations": cls._source_locale_map(choice.get("choice")),
                }
                item["canonicalConcept"] = item.get("canonicalConcept") or derived_canonical_concept(
                    str(item["id"])
                )
                return item
        return None

    @staticmethod
    def _content_structure(item: dict[str, Any]) -> dict[str, Any]:
        """Return the fields that Dialogue Content is never allowed to edit."""
        value = json.loads(json.dumps(item, ensure_ascii=False))
        kind = value.get("kind")
        value.pop("kind", None)
        for metadata_key in (
            "sourcePath",
            "sourceShard",
            "sourceFingerprint",
            "generatedModule",
            "verifiedOwner",
        ):
            value.pop(metadata_key, None)
        if kind == "phraseFamily":
            for phrases in value.get("styles", {}).values():
                for phrase in phrases:
                    if isinstance(phrase, dict):
                        phrase.pop("translations", None)
        else:
            value.pop("labelTranslations", None)
            value.pop("choiceTranslations", None)
        return value

    def list_dialogue_content(self) -> list[dict[str, Any]]:
        model = self._conversation_model()
        document = self._conversation_content_document(model)
        groups = document.get("groups") or {}
        rows: list[dict[str, Any]] = []
        for family in document.get("phraseFamilies", []):
            if not isinstance(family, dict):
                continue
            location = conversation_record(
                model, self._family_id(family)
            ) or {}
            source_shard = str(location.get("sourceShard") or "")
            report = self._content_shard_report(model, source_shard)
            rows.append({
                "id": self._family_id(family),
                "kind": "phraseFamily",
                "semanticTemplateID": family.get("semanticTemplateID"),
                "canonicalConcept": family.get("canonicalConcept")
                or derived_canonical_concept(str(family.get("semanticTemplateID") or "unknown")),
                "group": family.get("group"),
                "contentOwner": family.get("contentOwner")
                or (
                    groups.get(family.get("group"), {}).get("contentOwner")
                    if isinstance(groups.get(family.get("group")), dict)
                    else None
                ),
                "styles": sorted(family.get("styles", {})),
                "sourcePath": str(self._content_source_path(source_shard)),
                "sourceShard": source_shard,
                "sourceFingerprint": report["fingerprint"],
                "generatedModule": self._generated_module_for_shard(
                    model,
                    source_shard,
                    "Content",
                ),
                "verifiedOwner": "CodeBuilder → Conversation Registry",
            })
        for choice in document.get("playerChoices", []):
            if not isinstance(choice, dict):
                continue
            location = conversation_record(model, str(choice.get("id") or "")) or {}
            source_shard = str(location.get("sourceShard") or "")
            report = self._content_shard_report(model, source_shard)
            rows.append({
                "id": choice.get("id"),
                "kind": "playerChoice",
                "canonicalConcept": choice.get("canonicalConcept")
                or derived_canonical_concept(str(choice.get("id") or "unknown")),
                "route": choice.get("route"),
                "hubID": choice.get("hubID"),
                "sourcePath": str(self._content_source_path(source_shard)),
                "sourceShard": source_shard,
                "sourceFingerprint": report["fingerprint"],
                "generatedModule": self._generated_module_for_shard(
                    model,
                    source_shard,
                    "Content/PlayerChoices",
                ),
                "verifiedOwner": "CodeBuilder → Conversation Registry",
            })
        return sorted(rows, key=lambda item: str(item.get("id") or ""))

    def load_dialogue_content(self, content_id: str) -> dict[str, Any]:
        model = self._conversation_model()
        result = self._raw_content_item(model, str(content_id))
        if result is None:
            raise KeyError(f"unknown dialogue content id: {content_id}")
        item, _source_document, location = result
        source_shard = str(location["sourceShard"])
        report = self._content_shard_report(model, source_shard)
        item["sourcePath"] = str(self.dialogue_content_source_path)
        item["sourceShard"] = source_shard
        item["sourcePath"] = str(self._content_source_path(source_shard))
        item["sourceFingerprint"] = report["fingerprint"]
        item["generatedModule"] = self._generated_module_for_shard(
            model,
            source_shard,
            "Content",
        )
        item["verifiedOwner"] = "CodeBuilder → Conversation Registry"
        return item

    def _apply_dialogue_content_edit(
        self,
        content_id: str,
        edited_item: dict[str, Any],
        *,
        expected_source_fingerprint: str | None = None,
    ) -> tuple[dict[str, Any] | None, dict[str, Any]]:
        model = self._conversation_model()
        result = self._raw_content_item(model, str(content_id))
        if result is None:
            return None, {
                "ok": False,
                "type": "dialogue_content_edit_preview",
                "contentID": content_id,
                "diagnostics": [{"severity": "error", "message": "unknown dialogue content id"}],
                "writes": [],
            }
        current, source_document, location = result
        source_shard = str(location["sourceShard"])
        shard_report = self._content_shard_report(model, source_shard)
        actual_fingerprint = str(shard_report["fingerprint"])
        if expected_source_fingerprint and expected_source_fingerprint != actual_fingerprint:
            return None, {
                "ok": False,
                "type": "dialogue_content_edit_preview",
                "contentID": content_id,
                "stale": True,
                "reason": "source_fingerprint_mismatch",
                "expectedSourceFingerprint": expected_source_fingerprint,
                "sourceFingerprint": actual_fingerprint,
                "sourceShard": source_shard,
                "writes": [],
            }
        if not isinstance(edited_item, dict):
            return None, {
                "ok": False,
                "type": "dialogue_content_edit_preview",
                "contentID": content_id,
                "diagnostics": [{"severity": "error", "message": "content edit must be an object"}],
                "writes": [],
            }
        if self._content_structure(current) != self._content_structure(edited_item):
            return None, {
                "ok": False,
                "type": "dialogue_content_edit_preview",
                "contentID": content_id,
                "structuralChange": True,
                "diagnostics": [{
                    "severity": "error",
                    "message": "structural fields are locked; edit phrase or verified player-facing wording only",
                }],
                "writes": [],
            }
        updated_shard = self._dehydrate_content_shard(source_document)
        updated_phrase_translations: dict[tuple[str, int], dict[str, str]] = {}
        if current.get("kind") == "phraseFamily":
            target = next(
                item for item in updated_shard["phraseFamilies"]
                if self._family_id(item) == content_id
            )
            edited_styles = edited_item.get("styles", {})
            for style, phrases in target.get("styles", {}).items():
                edited_phrases = edited_styles.get(style, [])
                for index, phrase in enumerate(phrases):
                    if index < len(edited_phrases):
                        edited_phrase = edited_phrases[index]
                        if isinstance(edited_phrase, dict):
                            current_phrase = (
                                current.get("styles", {})
                                .get(style, [])[index]
                            )
                            translations = self._merge_editor_translations(
                                current_phrase.get("translations")
                                if isinstance(current_phrase, dict)
                                else None,
                                edited_phrase.get("translations"),
                                f"{content_id}.{style}[{index + 1}].translations",
                            )
                            updated_phrase_translations[(style, index)] = translations
                            phrase.clear()
                            phrase.update(translations)
        else:
            target = next(item for item in updated_shard["playerChoices"] if item["id"] == content_id)
            label_translations = self._merge_editor_translations(
                current.get("labelTranslations"),
                edited_item.get("labelTranslations"),
                f"{content_id}.labelTranslations",
            )
            choice_translations = self._merge_editor_translations(
                current.get("choiceTranslations"),
                edited_item.get("choiceTranslations"),
                f"{content_id}.choiceTranslations",
            )
            target["label"] = label_translations
            target["choice"] = choice_translations
        aggregate = self._conversation_content_document(model)
        if current.get("kind") == "phraseFamily":
            aggregate_target = next(
                item for item in aggregate["phraseFamilies"]
                if self._family_id(item) == content_id
            )
            aggregate_target.clear()
            aggregate_target.update(json.loads(json.dumps(target, ensure_ascii=False)))
            for style, phrases in (aggregate_target.get("styles") or {}).items():
                edited_phrases = edited_item.get("styles", {}).get(style, [])
                for index, phrase in enumerate(phrases):
                    if index >= len(edited_phrases):
                        continue
                    edited_phrase = edited_phrases[index]
                    if isinstance(edited_phrase, dict):
                        phrase.clear()
                        phrase.update(json.loads(json.dumps(
                            updated_phrase_translations[(style, index)],
                            ensure_ascii=False,
                        )))
        else:
            aggregate_target = next(
                item for item in aggregate["playerChoices"]
                if item["id"] == content_id
            )
            aggregate_target.clear()
            aggregate_target.update(json.loads(json.dumps(target, ensure_ascii=False)))
            aggregate_target["label"] = json.loads(
                json.dumps(label_translations, ensure_ascii=False)
            )
            aggregate_target["choice"] = json.loads(
                json.dumps(choice_translations, ensure_ascii=False)
            )
        compiled_aggregate = compile_dialogue_content(aggregate)
        return aggregate, {
            "ok": True,
            "type": "dialogue_content_edit_preview",
            "contentID": content_id,
            "kind": current.get("kind"),
            "stale": False,
            "structuralLocked": True,
            "sourceShard": source_shard,
            "sourceFingerprint": actual_fingerprint,
            "newContentFingerprint": compiled_aggregate["contentFingerprint"],
            "contentBefore": json.loads(json.dumps(current, ensure_ascii=False)),
            "contentAfter": json.loads(json.dumps(edited_item, ensure_ascii=False)),
            "_updatedShard": updated_shard,
            "writes": [],
        }

    def preview_dialogue_content_edit(
        self,
        content_id: str,
        edited_item: dict[str, Any],
        *,
        expected_source_fingerprint: str | None = None,
    ) -> dict[str, Any]:
        try:
            updated, report = self._apply_dialogue_content_edit(
                content_id,
                edited_item,
                expected_source_fingerprint=expected_source_fingerprint,
            )
            if updated is None or report.get("ok") is not True:
                return report
            compiled = compile_dialogue_content(updated)
        except (OSError, ValueError, TypeError, CompileError) as error:
            return {
                "ok": False,
                "type": "dialogue_content_edit_preview",
                "contentID": content_id,
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "writes": [],
            }
        registry_repository, registry_root = self._conversation_registry_location(
            self._conversation_model()
        )
        return {
            **{
                key: value for key, value in report.items()
                if not key.startswith("_")
            },
            "diagnostics": [],
            "contentFingerprint": compiled["contentFingerprint"],
            "generatedPaths": [
                str(registry_repository / registry_root / "Registry.lua"),
                str(registry_repository / registry_root / "Manifest.lua"),
            ],
        }

    def write_dialogue_content_edit(
        self,
        content_id: str,
        edited_item: dict[str, Any],
        *,
        expected_source_fingerprint: str | None = None,
    ) -> dict[str, Any]:
        updated, report = self._apply_dialogue_content_edit(
            content_id,
            edited_item,
            expected_source_fingerprint=expected_source_fingerprint,
        )
        if updated is None or report.get("ok") is not True:
            return report
        try:
            compile_dialogue_content(updated)
            updated_shard = report.get("_updatedShard")
            source_shard = str(report.get("sourceShard") or "")
            if not isinstance(updated_shard, dict) or not source_shard:
                raise CompileError("Conversation edit did not resolve an owning source shard")
            source_path = self._content_source_path(source_shard)
            source_path.write_text(
                json.dumps(updated_shard, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
                newline="\n",
            )
            from .build import write_conversation_output

            model = self._conversation_model()
            generated = write_conversation_output(
                self.repository,
                model,
                core_repository=self.core_repository,
                dynamic_trading_repository=self.dynamic_trading_repository,
            )
        except (OSError, ValueError, TypeError, CompileError) as error:
            return {
                **report,
                "ok": False,
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "writes": [],
            }
        return {
            **report,
            "previewOnly": False,
            "effectFree": False,
            "writes": [
                str(source_path),
                *(str(path) for path in generated),
            ],
            "reloadedBy": "caller_restart_required",
        }
    @staticmethod
    def _interaction_collection(kind: str) -> str:
        if kind == "beat":
            return "beats"
        if kind == "behavior":
            return "behaviors"
        raise KeyError(f"unsupported interaction record kind: {kind}")

    def _raw_interaction_item(
        self,
        model: dict[str, Any],
        record_id: str,
    ) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any]] | None:
        location = conversation_record(model, str(record_id))
        if not isinstance(location, dict) or location.get("kind") not in {
            "beat", "behavior"
        }:
            return None
        source_shard = str(location["sourceShard"])
        document = model.get("_source_documents", {}).get(source_shard)
        if not isinstance(document, dict):
            return None
        collection = self._interaction_collection(str(location["kind"]))
        for record in document.get(collection, []):
            if isinstance(record, dict) and record.get("id") == record_id:
                return record, document, location
        return None

    def load_interaction_definition(self, record_id: str) -> dict[str, Any]:
        """Load one canonical beat/behavior record with source provenance."""
        model = self._conversation_model()
        resolved = self._raw_interaction_item(model, str(record_id))
        if resolved is None:
            raise KeyError(f"unknown interaction definition id: {record_id}")
        record, _document, location = resolved
        source_shard = str(location["sourceShard"])
        report = self._content_shard_report(model, source_shard)
        return {
            **json.loads(json.dumps(record, ensure_ascii=False)),
            "kind": location["kind"],
            "sourceShard": source_shard,
            "sourcePath": str(self._content_source_path(source_shard)),
            "sourceFingerprint": report["fingerprint"],
            "verifiedOwner": "CodeBuilder → Conversation Registry",
        }

    @staticmethod
    def _interaction_canonical_edit(
        current: dict[str, Any],
        edited: dict[str, Any],
        *,
        kind: str,
    ) -> dict[str, Any]:
        """Merge worker structural fields while keeping canonical translations."""
        if not isinstance(edited, dict):
            raise CompileError("interaction definition edit must be an object")
        if str(edited.get("id") or "") != str(current.get("id") or ""):
            raise CompileError("canonical interaction record id is locked")
        allowed = {
            "beat": {
                "id", "version", "owner", "group", "baseRelevance",
                "entry", "maintain", "exit", "candidates",
                "cooldownTurns", "maxTurns",
            },
            "behavior": {
                "id", "version", "owner", "act", "mode", "stimuli",
                "requiredCapabilities", "outputs", "continuation", "when",
                "baseRelevance", "modifiers",
            },
        }[kind]
        output = json.loads(json.dumps(current, ensure_ascii=False))
        for key in allowed:
            if key in edited:
                output[key] = json.loads(
                    json.dumps(edited[key], ensure_ascii=False)
                )
            elif key in output and key not in {"id", "version", "owner"}:
                # Optional canonical fields may deliberately be removed.
                if key in {"group", "when"}:
                    output.pop(key, None)
        # Translation text remains canonical source ownership. A future
        # dedicated wording editor can update it without allowing a worker
        # draft to replace locale maps with generated label keys.
        if isinstance(current.get("translations"), dict):
            output["translations"] = json.loads(
                json.dumps(current["translations"], ensure_ascii=False)
            )
        return output

    def _interaction_edit_model(
        self,
        record_id: str,
        edited: dict[str, Any],
        *,
        expected_source_fingerprint: str | None = None,
    ) -> tuple[dict[str, Any] | None, dict[str, Any]]:
        model = self._conversation_model()
        resolved = self._raw_interaction_item(model, str(record_id))
        if resolved is None:
            return None, {
                "ok": False,
                "type": "interaction_definition_edit_preview",
                "recordID": record_id,
                "diagnostics": [{
                    "severity": "error",
                    "message": "unknown canonical interaction definition",
                }],
                "writes": [],
            }
        current, source_document, location = resolved
        source_shard = str(location["sourceShard"])
        shard_report = self._content_shard_report(model, source_shard)
        actual_fingerprint = str(shard_report["fingerprint"])
        if (
            expected_source_fingerprint
            and expected_source_fingerprint != actual_fingerprint
        ):
            return None, {
                "ok": False,
                "type": "interaction_definition_edit_preview",
                "recordID": record_id,
                "stale": True,
                "reason": "source_fingerprint_mismatch",
                "expectedSourceFingerprint": expected_source_fingerprint,
                "sourceFingerprint": actual_fingerprint,
                "sourceShard": source_shard,
                "writes": [],
            }
        kind = str(location["kind"])
        try:
            canonical = self._interaction_canonical_edit(
                current, edited, kind=kind
            )
        except (KeyError, TypeError, CompileError) as error:
            return None, {
                "ok": False,
                "type": "interaction_definition_edit_preview",
                "recordID": record_id,
                "diagnostics": [{
                    "severity": "error",
                    "message": str(error),
                }],
                "writes": [],
            }
        updated_shard = json.loads(json.dumps(source_document, ensure_ascii=False))
        collection = self._interaction_collection(kind)
        found = False
        for index, record in enumerate(updated_shard.get(collection, [])):
            if isinstance(record, dict) and record.get("id") == record_id:
                updated_shard[collection][index] = canonical
                found = True
                break
        if not found:
            raise CompileError(f"interaction record vanished from {source_shard}")

        with tempfile.TemporaryDirectory() as directory:
            candidate_repo = Path(directory)
            source_root = self.repository / CONVERSATION_SOURCE_RELATIVE
            candidate_root = candidate_repo / CONVERSATION_SOURCE_RELATIVE
            shutil.copytree(source_root, candidate_root)
            candidate_path = candidate_root / source_shard
            candidate_path.write_text(
                json.dumps(
                    updated_shard,
                    ensure_ascii=False,
                    indent=2,
                    sort_keys=True,
                ) + "\n",
                encoding="utf-8",
                newline="\n",
            )
            try:
                candidate_model = compile_conversation_sources(
                    candidate_repo,
                    runtime_root=self.runtime_root,
                    package_repositories=self.package_repositories,
                )
            except (OSError, ValueError, TypeError, CompileError) as error:
                return None, {
                    "ok": False,
                    "type": "interaction_definition_edit_preview",
                    "recordID": record_id,
                    "kind": kind,
                    "sourceShard": source_shard,
                    "sourceFingerprint": actual_fingerprint,
                    "diagnostics": [{
                        "severity": "error",
                        "message": str(error),
                    }],
                    "writes": [],
                }

        return candidate_model, {
            "ok": True,
            "type": "interaction_definition_edit_preview",
            "recordID": record_id,
            "kind": kind,
            "sourceShard": source_shard,
            "sourcePath": str(self._content_source_path(source_shard)),
            "sourceFingerprint": actual_fingerprint,
            "current": json.loads(json.dumps(current, ensure_ascii=False)),
            "candidate": canonical,
            "_updatedShard": updated_shard,
            "writes": [],
        }

    def _interaction_generated_diffs(
        self, model: dict[str, Any]
    ) -> list[dict[str, Any]]:
        """Return bounded effect-free diffs for generated structural artifacts."""
        rendered, reports = render_conversation_runtime_plan(model)
        artifacts: list[tuple[Path, Path, str]] = []
        for module, source in rendered:
            if "/Beats/" in module or "/Behaviors/" in module:
                repository, target = module_target(
                    self.repository,
                    module,
                    core_repository=self.core_repository,
                    dynamic_trading_repository=self.dynamic_trading_repository,
                    runtime_root=self.runtime_root,
                )
                artifacts.append(
                    (repository, target.relative_to(repository), source)
                )
        registry_repository, registry_root = self._conversation_registry_location(
            model
        )
        artifacts.extend([
            (
                registry_repository,
                registry_root / "Registry.lua",
                render_conversation_registry(model, reports),
            ),
            (
                registry_repository,
                registry_root / "Manifest.lua",
                render_conversation_manifest_lua(model, reports),
            ),
        ])
        rows = []
        for repository, relative, expected in artifacts:
            row = authoring._artifact_diff(repository, str(relative), expected)
            row["repository"] = str(repository)
            rows.append(row)
        return rows

    def preview_interaction_definition_edit(
        self,
        record_id: str,
        edited: dict[str, Any],
        *,
        expected_source_fingerprint: str | None = None,
    ) -> dict[str, Any]:
        model, report = self._interaction_edit_model(
            record_id,
            edited,
            expected_source_fingerprint=expected_source_fingerprint,
        )
        if model is None or report.get("ok") is not True:
            return report
        diffs = self._interaction_generated_diffs(model)
        return {
            **{
                key: value for key, value in report.items()
                if not key.startswith("_")
            },
            "previewOnly": True,
            "effectFree": True,
            "wholeModelFingerprint": model["wholeModelFingerprint"],
            "generatedDiffs": diffs,
            "changedGeneratedPaths": [
                row["path"] for row in diffs
                if row.get("status") != "unchanged"
            ],
            "diagnostics": [],
        }

    def write_interaction_definition_edit(
        self,
        record_id: str,
        edited: dict[str, Any],
        *,
        expected_source_fingerprint: str | None = None,
    ) -> dict[str, Any]:
        model, report = self._interaction_edit_model(
            record_id,
            edited,
            expected_source_fingerprint=expected_source_fingerprint,
        )
        if model is None or report.get("ok") is not True:
            return report
        updated_shard = report.get("_updatedShard")
        source_shard = str(report.get("sourceShard") or "")
        if not isinstance(updated_shard, dict) or not source_shard:
            raise CompileError("interaction edit did not resolve an owning source shard")
        source_path = self._content_source_path(source_shard)
        try:
            source_path.write_text(
                json.dumps(
                    updated_shard,
                    ensure_ascii=False,
                    indent=2,
                    sort_keys=True,
                ) + "\n",
                encoding="utf-8",
                newline="\n",
            )
            from .build import write_conversation_output
            generated = write_conversation_output(
                self.repository,
                self._conversation_model(),
                core_repository=self.core_repository,
                dynamic_trading_repository=self.dynamic_trading_repository,
            )
        except (OSError, ValueError, TypeError, CompileError) as error:
            return {
                **{
                    key: value for key, value in report.items()
                    if not key.startswith("_")
                },
                "ok": False,
                "diagnostics": [{
                    "severity": "error",
                    "message": str(error),
                }],
                "writes": [str(source_path)],
            }
        refreshed = self.load_interaction_definition(record_id)
        return {
            **{
                key: value for key, value in report.items()
                if not key.startswith("_")
            },
            "previewOnly": False,
            "effectFree": False,
            "sourceFingerprint": refreshed["sourceFingerprint"],
            "writes": [str(source_path), *(str(path) for path in generated)],
            "reloadedBy": "caller_restart_required",
            "diagnostics": [],
        }

    def list_semantic_blocks(
        self,
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Return reusable blocks over the supplied live production catalog."""
        return self.block_registry.catalog(production_catalog)

    def search_semantic_blocks(
        self,
        query: str = "",
        *,
        category: str | None = None,
        production_catalog: dict[str, Any] | None = None,
        limit: int = 64,
    ) -> list[dict[str, Any]]:
        return self.block_registry.search(
            query,
            category=category,
            production_catalog=production_catalog,
            limit=limit,
        )

    @staticmethod
    def list_interactions(
        production_catalog: dict[str, Any] | None,
    ) -> list[dict[str, Any]]:
        """Return searchable rows from the live production interaction catalog."""

        return build_interaction_rows(production_catalog)

    @staticmethod
    def search_interactions(
        query: str = "",
        *,
        production_catalog: dict[str, Any] | None = None,
        limit: int = 128,
    ) -> list[dict[str, Any]]:
        return search_interactions(production_catalog, query, limit=limit)

    def validate_semantic_blocks(
        self,
        block_ids: list[str],
        *,
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.block_registry.validate_selection(
            block_ids,
            production_catalog=production_catalog,
        )

    def validate_workflow_selection(
        self,
        source_id: str,
        block_ids: list[str],
        *,
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.interaction_authoring.validate_workflow_selection(
            source_id,
            block_ids,
            production_catalog=production_catalog,
        )

    def validate_interaction_spec(
        self,
        spec: dict[str, Any],
        *,
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.interaction_authoring.validate_interaction_spec(
            spec,
            production_catalog=production_catalog,
        )

    def edit_interaction_graph(
        self,
        spec: dict[str, Any],
        operation: str,
        *,
        production_catalog: dict[str, Any] | None = None,
        **kwargs: Any,
    ) -> dict[str, Any]:
        return self.interaction_authoring.edit_interaction_graph(
            spec,
            operation,
            production_catalog=production_catalog,
            **kwargs,
        )

    def preview_interaction_spec(
        self,
        spec: dict[str, Any],
        *,
        source_id: str = "semantic_flows",
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.interaction_authoring.preview_interaction_spec(
            spec,
            source_id=source_id,
            production_catalog=production_catalog,
        )

    def generate_interaction_spec(
        self,
        spec: dict[str, Any],
        *,
        approved: bool,
        source_id: str = "semantic_flows",
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.interaction_authoring.generate_interaction_spec(
            spec,
            approved=approved,
            source_id=source_id,
            production_catalog=production_catalog,
        )

    def preview_interaction_collection(
        self,
        collection: dict[str, Any],
        *,
        source_id: str = "semantic_flows",
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.interaction_authoring.preview_interaction_collection(
            collection,
            source_id=source_id,
            production_catalog=production_catalog,
        )

    def generate_interaction_collection(
        self,
        collection: dict[str, Any],
        *,
        approved: bool,
        source_id: str = "semantic_flows",
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.interaction_authoring.generate_interaction_collection(
            collection,
            approved=approved,
            source_id=source_id,
            production_catalog=production_catalog,
        )

    def preview_workflow(
        self,
        source_id: str,
        block_ids: list[str],
        *,
        production_catalog: dict[str, Any] | None = None,
        interaction_spec: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.interaction_authoring.preview_workflow(
            source_id,
            block_ids,
            production_catalog=production_catalog,
            interaction_spec=interaction_spec,
        )

    def generate_workflow(
        self,
        source_id: str,
        block_ids: list[str],
        *,
        approved: bool,
        production_catalog: dict[str, Any] | None = None,
        interaction_spec: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.interaction_authoring.generate_workflow(
            source_id,
            block_ids,
            approved=approved,
            production_catalog=production_catalog,
            interaction_spec=interaction_spec,
        )
    def validate_codeblock_source(self, source_path: Path) -> dict[str, Any]:
        """Validate a declarative codeblock file without writing or dispatching."""
        source_path = source_path.expanduser().resolve()
        try:
            document = json.loads(source_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as error:
            return {
                "ok": False,
                "type": "codeblock_validation",
                "valid": False,
                "sourcePath": str(source_path),
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "effectFree": True,
                "writes": [],
            }
        report = validate_codeblock_document(document)
        report["sourcePath"] = str(source_path)
        return report

    def preview_external_dataset(
        self,
        adapter: str,
        source_path: Path,
        manifest_path: Path,
        *,
        max_records: int = 128,
    ) -> dict[str, Any]:
        """Review one external source without touching canonical or runtime files."""
        return preview_dataset_adapter(
            adapter,
            source_path,
            manifest_path,
            max_records=max_records,
        )

    def promote_external_candidates(
        self,
        report: dict[str, Any],
        decisions: list[dict[str, Any]],
    ) -> dict[str, Any]:
        """Convert explicit license-cleared review decisions to canonical records."""
        return promote_reviewed_candidates(report, decisions)
