"""Versioned OperationRegistry for Semantic Harness ConvoEngine GUI & CLI (Port C)."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Mapping

from .convo_transaction import ChangeSet
from .errors import CompileError


OPERATION_REGISTRY_SCHEMA = "semantic.operations.v1"


@dataclass(frozen=True)
class OperationDescriptor:
    """Self-describing metadata for one harness operation."""

    id: str
    mode: str  # "query" | "command"
    required_capability: str | None
    worker_requirement: str  # "none" | "optional" | "required"
    mutates_canonical: bool
    mutates_runtime: bool
    input_version: str
    output_version: str
    summary: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "mode": self.mode,
            "requiredCapability": self.required_capability,
            "workerRequirement": self.worker_requirement,
            "mutatesCanonical": self.mutates_canonical,
            "mutatesRuntime": self.mutates_runtime,
            "inputVersion": self.input_version,
            "outputVersion": self.output_version,
            "summary": self.summary,
        }


class OperationRegistry:
    """Single discoverable command/query dispatch surface for GUI, CLI, and agents."""

    def __init__(self, service: Any) -> None:
        self.service = service
        self._descriptors: dict[str, OperationDescriptor] = {}
        self._handlers: dict[str, Callable[[Mapping[str, Any]], dict[str, Any]]] = {}
        self._register_defaults()

    def register(
        self,
        descriptor: OperationDescriptor,
        handler: Callable[[Mapping[str, Any]], dict[str, Any]],
    ) -> None:
        self._descriptors[descriptor.id] = descriptor
        self._handlers[descriptor.id] = handler

    def list_operations(self) -> list[dict[str, Any]]:
        return [
            self._descriptors[key].to_dict()
            for key in sorted(self._descriptors)
        ]

    def describe(self, operation_id: str) -> dict[str, Any] | None:
        desc = self._descriptors.get(str(operation_id).strip())
        return desc.to_dict() if desc is not None else None

    def dispatch(
        self,
        operation_id: str,
        payload: Mapping[str, Any] | None = None,
    ) -> dict[str, Any]:
        op_id = str(operation_id).strip()
        handler = self._handlers.get(op_id)
        if handler is None:
            raise CompileError(f"Unknown harness operation: {op_id!r}")
        result = handler(payload or {})
        if isinstance(result, dict):
            result.setdefault("operation", op_id)
            result.setdefault("ok", True)
        return result

    def _register_defaults(self) -> None:
        self.register(
            OperationDescriptor(
                id="workspace.describe",
                mode="query",
                required_capability=None,
                worker_requirement="none",
                mutates_canonical=False,
                mutates_runtime=False,
                input_version="1",
                output_version="semantic.workspace.v1",
                summary="Describe discovered provider manifests, owners, source roots, and capabilities.",
            ),
            lambda _payload: self.service.describe_workspace(),
        )
        self.register(
            OperationDescriptor(
                id="convo.catalog",
                mode="query",
                required_capability=None,
                worker_requirement="none",
                mutates_canonical=False,
                mutates_runtime=False,
                input_version="1",
                output_version="semantic.convo.catalog.v1",
                summary="Search and paginate lightweight ConvoEngine family summaries.",
            ),
            lambda payload: self.service.query_convo_catalog(
                query=str(payload.get("query") or ""),
                owner=payload.get("owner"),
                kind=payload.get("kind"),
                action=payload.get("action"),
                limit=int(payload.get("limit", 50)),
                offset=int(payload.get("offset", 0)),
            ),
        )
        self.register(
            OperationDescriptor(
                id="convo.get",
                mode="query",
                required_capability=None,
                worker_requirement="none",
                mutates_canonical=False,
                mutates_runtime=False,
                input_version="1",
                output_version="1",
                summary="Load one canonical ConvoEngine family document and refs on demand.",
            ),
            self._handle_get,
        )
        self.register(
            OperationDescriptor(
                id="convo.impact",
                mode="query",
                required_capability=None,
                worker_requirement="none",
                mutates_canonical=False,
                mutates_runtime=False,
                input_version="1",
                output_version="1",
                summary="Compute bounded incoming/outgoing refs and generated routing for one family.",
            ),
            self._handle_impact,
        )
        self.register(
            OperationDescriptor(
                id="convo.validate",
                mode="query",
                required_capability=None,
                worker_requirement="none",
                mutates_canonical=False,
                mutates_runtime=False,
                input_version="1",
                output_version="1",
                summary="Compile-validate a ConvoEngine document or source without side effects.",
            ),
            self._handle_validate,
        )
        self.register(
            OperationDescriptor(
                id="convo.simulate",
                mode="query",
                required_capability="semantic.convo_probe",
                worker_requirement="required",
                mutates_canonical=False,
                mutates_runtime=False,
                input_version="1",
                output_version="1",
                summary="Simulate affordance -> speech -> execute -> result -> reply trace.",
            ),
            self._handle_simulate,
        )
        self.register(
            OperationDescriptor(
                id="convo.change.preview",
                mode="query",
                required_capability=None,
                worker_requirement="none",
                mutates_canonical=False,
                mutates_runtime=False,
                input_version="1",
                output_version="1",
                summary="Preview a canonical create/edit/move/delete ChangeSet safely.",
            ),
            lambda payload: self.service.convo_transaction.preview(ChangeSet.from_payload(payload)),
        )
        self.register(
            OperationDescriptor(
                id="convo.change.apply",
                mode="command",
                required_capability=None,
                worker_requirement="none",
                mutates_canonical=True,
                mutates_runtime=True,
                input_version="1",
                output_version="1",
                summary="Atomically apply a validated ChangeSet under workspace generation lock.",
            ),
            lambda payload: self.service.convo_transaction.apply(ChangeSet.from_payload(payload)),
        )
        self.register(
            OperationDescriptor(
                id="convo.build.preview",
                mode="query",
                required_capability=None,
                worker_requirement="none",
                mutates_canonical=False,
                mutates_runtime=False,
                input_version="1",
                output_version="1",
                summary="Compile and plan generated ConvoEngine artifacts without modifying live media/.",
            ),
            self._handle_build_preview,
        )
        self.register(
            OperationDescriptor(
                id="convo.build.apply",
                mode="command",
                required_capability=None,
                worker_requirement="none",
                mutates_canonical=False,
                mutates_runtime=True,
                input_version="1",
                output_version="1",
                summary="Regenerate and verify ConvoEngine Lua and translation outputs via CodeBuilder.",
            ),
            self._handle_build_apply,
        )
        self.register(
            OperationDescriptor(
                id="convo.audit",
                mode="query",
                required_capability=None,
                worker_requirement="none",
                mutates_canonical=False,
                mutates_runtime=False,
                input_version="1",
                output_version="psychopatz.convo-engine.integrity-audit.v1",
                summary="Run cross-repository ConvoEngine hygiene and determinism audit.",
            ),
            lambda payload: self.service.run_convo_engine_integrity_audit(
                check_determinism=bool(payload.get("checkDeterminism", False)),
                require_all_owners=bool(payload.get("requireAllOwners", True)),
            ),
        )

    def _handle_get(self, payload: Mapping[str, Any]) -> dict[str, Any]:
        target = payload.get("target") or payload.get("id") or payload.get("sourcePath")
        if not target:
            raise CompileError("convo.get requires target / id / sourcePath")
        item = self.service.get_convo_family(
            target,
            include_document=bool(payload.get("includeDocument", True)),
        )
        if item is None:
            return {"ok": False, "found": False, "target": str(target)}
        return {"ok": True, "found": True, **item}

    def _handle_impact(self, payload: Mapping[str, Any]) -> dict[str, Any]:
        target = payload.get("target") or payload.get("id") or payload.get("sourcePath")
        if not target:
            raise CompileError("convo.impact requires target / id / sourcePath")
        impact = self.service.convo_impact(target, limit=int(payload.get("limit", 24)))
        if impact is None:
            return {"ok": False, "found": False, "target": str(target)}
        return {"ok": True, "found": True, **impact}

    def _handle_validate(self, payload: Mapping[str, Any]) -> dict[str, Any]:
        doc = payload.get("document")
        source_path = payload.get("sourcePath") or payload.get("target")
        if doc is None and source_path is not None:
            loaded = self.service.get_convo_family(source_path, include_document=True)
            if loaded is None:
                raise CompileError(f"ConvoEngine family not found: {source_path}")
            doc = loaded["document"]
            source_path = loaded["sourcePath"]
        if not isinstance(doc, Mapping):
            raise CompileError("convo.validate requires document or target")
        return self.service.validate_convo_engine_document(
            dict(doc),
            source_path=source_path,
            default_owner=payload.get("owner"),
            allow_legacy_schema=bool(payload.get("allowLegacySchema", False)),
        )

    def _handle_simulate(self, payload: Mapping[str, Any]) -> dict[str, Any]:
        doc = payload.get("document")
        source_path = payload.get("sourcePath") or payload.get("target")
        if doc is None and source_path is not None:
            loaded = self.service.get_convo_family(source_path, include_document=True)
            if loaded is None:
                raise CompileError(f"ConvoEngine family not found: {source_path}")
            doc = loaded["document"]
            source_path = loaded["sourcePath"]
        if not isinstance(doc, Mapping):
            raise CompileError("convo.simulate requires document or target")
        return self.service.simulate_convo_engine_family(
            dict(doc),
            source_path=source_path,
            speaker=str(payload.get("speaker") or "player"),
            addressee=str(payload.get("addressee") or "npc"),
            target=payload.get("npcTarget"),
            slot_values=payload.get("slotValues"),
            style=str(payload.get("style") or "neutral"),
            locale=str(payload.get("locale") or "EN"),
            result_outcome=payload.get("resultOutcome"),
            result_reason_class=payload.get("resultReasonClass"),
            result_fields=payload.get("resultFields"),
            context=payload.get("context"),
            realization_key=payload.get("realizationKey"),
        )

    def _build_port(self) -> Any:
        harness = getattr(self.service, "harness", None)
        planner = getattr(harness, "build", None)
        if planner is None:
            raise CompileError("BuildPlanner port is not wired in HarnessContext")
        return planner

    def _handle_build_preview(self, payload: Mapping[str, Any]) -> dict[str, Any]:
        return self._build_port().preview(
            owner=payload.get("owner"),
            check_determinism=bool(payload.get("checkDeterminism", False)),
            limit=int(payload.get("limit", 64)),
        )

    def _handle_build_apply(self, payload: Mapping[str, Any]) -> dict[str, Any]:
        return self._build_port().apply(
            owner=payload.get("owner"),
            limit=int(payload.get("limit", 64)),
        )


__all__ = [
    "OPERATION_REGISTRY_SCHEMA",
    "OperationDescriptor",
    "OperationRegistry",
]
