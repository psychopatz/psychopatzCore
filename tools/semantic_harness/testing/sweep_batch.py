"""Bounded batch execution, manifest management, and resume logic for sweeps.

Executes planned cases in safe chunks (<=64 cases each) through production Lua,
records versioned manifests with catalog fingerprint validation, streams compact
evidence rows into JSONL, and safely resumes interrupted runs without mixing stale
data.
"""

from __future__ import annotations

from copy import deepcopy
from dataclasses import asdict, dataclass, field
import json
import os
from pathlib import Path
import time
from typing import Any, Callable, Generator, Mapping, Sequence

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from .sweep_dimensions import SweepDimensionInventory
from .sweep_evidence import extract_evidence_rows_from_turn
from .sweep_planner import CoveragePlan, PlannedCase, MAX_BATCH_SIZE

MANIFEST_SCHEMA_V1 = "pnc.semantic-dialogue-quality-manifest.v1"
ALLOWED_MANIFEST_SCHEMAS = frozenset({MANIFEST_SCHEMA_V1})


class SweepBatchError(ValueError):
    """Base error for batch execution and manifest operations."""


class StaleFingerprintError(SweepBatchError):
    """Raised when attempting to resume a sweep against an incompatible catalog fingerprint."""


class SweepExecutionCancelled(SweepBatchError):
    """Raised when sweep execution was cancelled by the user/caller."""


@dataclass
class SweepBatch:
    """A bounded batch of cases within a coverage plan."""

    batch_id: str
    sweep_id: str
    case_ids: list[str]
    status: str = "PENDING"  # PENDING, RUNNING, COMPLETED, COMPLETED_WITH_INVALID_SURFACE, FAILED, CANCELLED
    cases_count: int = 0
    completed_cases: int = 0
    failed_cases: int = 0
    invalid_surface_cases: int = 0
    completed_case_ids: list[str] = field(default_factory=list)
    started_at: float | None = None
    completed_at: float | None = None
    duration: float = 0.0
    error: str | None = None

    def to_dict(self) -> dict[str, Any]:
        return {
            "batchID": self.batch_id,
            "sweepID": self.sweep_id,
            "caseIDs": self.case_ids,
            "status": self.status,
            "casesCount": self.cases_count,
            "completedCases": self.completed_cases,
            "failedCases": self.failed_cases,
            "invalidSurfaceCases": self.invalid_surface_cases,
            "completedCaseIDs": list(self.completed_case_ids),
            "startedAt": self.started_at,
            "completedAt": self.completed_at,
            "duration": self.duration,
            "error": self.error,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> SweepBatch:
        return cls(
            batch_id=str(data["batchID"]),
            sweep_id=str(data["sweepID"]),
            case_ids=list(data.get("caseIDs", [])),
            status=str(data.get("status", "PENDING")),
            cases_count=int(data.get("casesCount", 0)),
            completed_cases=int(data.get("completedCases", 0)),
            failed_cases=int(data.get("failedCases", 0)),
            invalid_surface_cases=int(data.get("invalidSurfaceCases", 0)),
            completed_case_ids=list(data.get("completedCaseIDs", [])),
            started_at=data.get("startedAt"),
            completed_at=data.get("completedAt"),
            duration=float(data.get("duration", 0.0)),
            error=data.get("error"),
        )


@dataclass
class SweepManifest:
    """Persistent, versioned manifest tracking sweep progress and artifacts."""

    sweep_id: str
    strategy: str
    plan_digest: str
    catalog_fingerprint: str
    total_cases: int
    batch_size: int
    batches: list[SweepBatch]
    status: str = "PLANNED"  # PLANNED, RUNNING, COMPLETED, COMPLETED_WITH_INVALID_SURFACE, FAILED, CANCELLED
    completed_cases: int = 0
    failed_cases: int = 0
    invalid_surface_cases: int = 0
    artifact_directory: str = ""
    evidence_file: str = "evidence.jsonl"
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    schema: str = MANIFEST_SCHEMA_V1
    schema_version: int = 1

    def to_dict(self) -> dict[str, Any]:
        return {
            "schema": self.schema,
            "schemaVersion": self.schema_version,
            "sweepID": self.sweep_id,
            "strategy": self.strategy,
            "planDigest": self.plan_digest,
            "catalogFingerprint": self.catalog_fingerprint,
            "totalCases": self.total_cases,
            "completedCases": self.completed_cases,
            "failedCases": self.failed_cases,
            "invalidSurfaceCases": self.invalid_surface_cases,
            "batchSize": self.batch_size,
            "status": self.status,
            "artifactDirectory": self.artifact_directory,
            "evidenceFile": self.evidence_file,
            "createdAt": self.created_at,
            "updatedAt": self.updated_at,
            "batches": [b.to_dict() for b in self.batches],
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> SweepManifest:
        schema = data.get("schema")
        if schema not in ALLOWED_MANIFEST_SCHEMAS:
            raise SweepBatchError(f"Unsupported manifest schema: {schema}")
        batches = [SweepBatch.from_dict(b) for b in data.get("batches", [])]
        return cls(
            sweep_id=str(data["sweepID"]),
            strategy=str(data["strategy"]),
            plan_digest=str(data["planDigest"]),
            catalog_fingerprint=str(data["catalogFingerprint"]),
            total_cases=int(data["totalCases"]),
            batch_size=int(data.get("batchSize", MAX_BATCH_SIZE)),
            batches=batches,
            status=str(data.get("status", "PLANNED")),
            completed_cases=int(data.get("completedCases", 0)),
            failed_cases=int(data.get("failedCases", 0)),
            invalid_surface_cases=int(data.get("invalidSurfaceCases", 0)),
            artifact_directory=str(data.get("artifactDirectory", "")),
            evidence_file=str(data.get("evidenceFile", "evidence.jsonl")),
            created_at=float(data.get("createdAt", time.time())),
            updated_at=float(data.get("updatedAt", time.time())),
        )

    def save(self, directory: Path | str) -> Path:
        dir_path = Path(directory)
        dir_path.mkdir(parents=True, exist_ok=True)
        manifest_path = dir_path / "manifest.json"
        tmp_path = dir_path / "manifest.json.tmp"
        self.updated_at = time.time()
        self.artifact_directory = str(dir_path)
        with open(tmp_path, "w", encoding="utf-8") as f:
            json.dump(self.to_dict(), f, indent=2)
        os.replace(tmp_path, manifest_path)
        return manifest_path

    @classmethod
    def load(cls, manifest_path: Path | str) -> SweepManifest:
        p = Path(manifest_path)
        if not p.exists():
            raise FileNotFoundError(f"Manifest not found at {p}")
        with open(p, "r", encoding="utf-8") as f:
            data = json.load(f)
        return cls.from_dict(data)

    def validate_catalog_fingerprint(self, current_fingerprint: str) -> None:
        if self.catalog_fingerprint != current_fingerprint:
            raise StaleFingerprintError(
                f"Cannot resume sweep '{self.sweep_id}': production catalog fingerprint changed!\n"
                f"Manifest fingerprint: {self.catalog_fingerprint}\n"
                f"Current fingerprint:  {current_fingerprint}"
            )

    def validate_compatibility(self, inventory: Any, plan: Any) -> None:
        """Validate that current inventory and plan match the recorded manifest."""
        self.validate_catalog_fingerprint(inventory.production_fingerprint)
        if self.plan_digest != plan.plan_digest:
            raise SweepBatchError(
                f"Cannot resume sweep '{self.sweep_id}': plan digest changed!\n"
                f"Manifest digest: {self.plan_digest}\n"
                f"Current digest:  {plan.plan_digest}"
            )


def split_plan_into_batches(
    plan: CoveragePlan,
    batch_size: int = MAX_BATCH_SIZE,
) -> list[SweepBatch]:
    """Partition planned cases into bounded batches (default <= 64 cases)."""
    batches: list[SweepBatch] = []
    cases = plan.cases
    total = len(cases)
    batch_idx = 0

    for i in range(0, total, batch_size):
        chunk = cases[i : i + batch_size]
        batch_id = f"batch-{batch_idx:04d}"
        batch = SweepBatch(
            batch_id=batch_id,
            sweep_id=plan.sweep_id,
            case_ids=[c.case_id for c in chunk],
            status="PENDING",
            cases_count=len(chunk),
        )
        batches.append(batch)
        batch_idx += 1

    return batches


class SweepBatchExecutor:
    """Executes planned sweep batches through actual LuaSemanticWorker."""

    def __init__(
        self,
        plan: CoveragePlan,
        inventory: SweepDimensionInventory,
        *,
        artifact_dir: Path | str | None = None,
        worker_factory: Callable[..., Any] = LuaSemanticWorker,
        batch_size: int = MAX_BATCH_SIZE,
    ) -> None:
        self.plan = plan
        self.inventory = inventory
        self.worker_factory = worker_factory
        self.batch_size = min(batch_size, MAX_BATCH_SIZE)

        default_reports_dir = Path("tools/semantic_harness/reports/sweeps") / plan.sweep_id
        self.artifact_dir = Path(artifact_dir) if artifact_dir else default_reports_dir
        self.artifact_dir.mkdir(parents=True, exist_ok=True)
        self.manifest_path = self.artifact_dir / "manifest.json"
        self.evidence_path = self.artifact_dir / "evidence.jsonl"

        self.case_map: dict[str, PlannedCase] = {c.case_id: c for c in plan.cases}
        self.manifest = self._init_manifest()

    def _init_manifest(self) -> SweepManifest:
        if self.manifest_path.exists():
            manifest = SweepManifest.load(self.manifest_path)
            manifest.validate_compatibility(self.inventory, self.plan)
            return manifest

        batches = split_plan_into_batches(self.plan, self.batch_size)
        manifest = SweepManifest(
            sweep_id=self.plan.sweep_id,
            strategy=self.plan.strategy,
            plan_digest=self.plan.plan_digest,
            catalog_fingerprint=self.inventory.production_fingerprint,
            total_cases=self.plan.total_cases,
            batch_size=self.batch_size,
            batches=batches,
            status="PLANNED",
            artifact_directory=str(self.artifact_dir),
            evidence_file="evidence.jsonl",
        )
        manifest.save(self.artifact_dir)
        return manifest

    def execute_next_batch(
        self,
        *,
        is_cancelled: Callable[[], bool] | None = None,
    ) -> SweepBatch | None:
        """Execute the next pending/incomplete batch. Returns None when all batches are complete."""
        # Find first incomplete batch (including CANCELLED batches that are being resumed)
        batch = next(
            (b for b in self.manifest.batches if b.status in ("PENDING", "FAILED", "CANCELLED", "RUNNING")),
            None,
        )
        if batch is None:
            if all(b.status in ("COMPLETED", "COMPLETED_WITH_INVALID_SURFACE") for b in self.manifest.batches):
                if any(b.status == "COMPLETED_WITH_INVALID_SURFACE" for b in self.manifest.batches):
                    self.manifest.status = "COMPLETED_WITH_INVALID_SURFACE"
                else:
                    self.manifest.status = "COMPLETED"
                self.manifest.save(self.artifact_dir)
            return None

        if is_cancelled and is_cancelled():
            batch.status = "CANCELLED"
            self.manifest.status = "CANCELLED"
            self.manifest.save(self.artifact_dir)
            raise SweepExecutionCancelled(f"Execution cancelled before {batch.batch_id}")

        batch.status = "RUNNING"
        if not batch.started_at:
            batch.started_at = time.time()
        self.manifest.status = "RUNNING"
        self.manifest.save(self.artifact_dir)

        completed_in_batch = len(batch.completed_case_ids)
        failed_in_batch = batch.failed_cases
        invalid_in_batch = batch.invalid_surface_cases
        batch_start = time.monotonic()

        # Open evidence file in append mode
        with open(self.evidence_path, "a", encoding="utf-8") as out_f:
            for case_id in batch.case_ids:
                if case_id in batch.completed_case_ids:
                    # Already completed in a prior interrupted/partial run: do not re-run or duplicate
                    continue

                if is_cancelled and is_cancelled():
                    batch.status = "CANCELLED"
                    self.manifest.status = "CANCELLED"
                    self.manifest.save(self.artifact_dir)
                    raise SweepExecutionCancelled(f"Execution cancelled during {batch.batch_id}")

                planned_case = self.case_map.get(case_id)
                if not planned_case:
                    continue

                try:
                    case_res = self._execute_single_case(planned_case, batch.batch_id, out_f)
                    completed_in_batch += 1
                    batch.completed_case_ids.append(case_id)
                    if case_res.get("invalid_surface"):
                        invalid_in_batch += 1
                except Exception as exc:
                    failed_in_batch += 1
                    batch.completed_case_ids.append(case_id)
                    # Record failure as a synthetic error row rather than crashing the batch
                    error_row = {
                        "schema": "pnc.semantic-dialogue-quality-evidence.v1",
                        "schemaVersion": 1,
                        "rowID": f"{case_id}:0:0",
                        "identity": {
                            "sweepID": self.plan.sweep_id,
                            "caseID": case_id,
                            "batchID": batch.batch_id,
                            "strategy": planned_case.strategy,
                            "turnIndex": 0,
                            "messageIndex": 0,
                            "speaker": "npc",
                            "language": planned_case.language,
                            "salt": None,
                            "historyMode": "isolated",
                            "plannedSurface": planned_case.surface,
                            "reachedSurface": "execution_error",
                            "surfaceStatus": "EXECUTION_ERROR",
                            "input": {"text": planned_case.surface},
                        },
                        "trigger": {
                            "parameters": planned_case.parameters,
                            "personaSummary": {},
                            "relationshipSummary": {},
                            "stateSummary": {},
                            "actorSummary": {},
                        },
                        "semanticPath": {},
                        "output": {
                            "finalText": "",
                            "fallbackReason": f"execution_error: {exc}",
                            "recentResponses": [],
                        },
                        "selectionProvenance": {
                            "provenance": "UNKNOWN",
                            "canonicalSourceOwner": "UNKNOWN",
                            "fingerprints": {},
                        },
                        "authority": {"actionCount": 0, "transportCount": 0, "actions": []},
                        "quality": {
                            "flags": [
                                {
                                    "name": "EXECUTION_ERROR",
                                    "severity": "CRITICAL",
                                    "confidence": "DEFINITE",
                                    "detail": str(exc),
                                }
                            ],
                            "clusterKeys": ["execution_error"],
                            "reviewState": "FLAGGED",
                            "reviewNotes": str(exc),
                        },
                        "traceHandle": {"caseID": case_id, "turnIndex": 0, "lazy": True},
                    }
                    out_f.write(json.dumps(error_row) + "\n")
                    out_f.flush()

        batch.duration += time.monotonic() - batch_start
        batch.completed_at = time.time()
        batch.completed_cases = completed_in_batch
        batch.failed_cases = failed_in_batch
        batch.invalid_surface_cases = invalid_in_batch

        if failed_in_batch > 0 and completed_in_batch == 0:
            batch.status = "FAILED"
        elif invalid_in_batch > 0:
            batch.status = "COMPLETED_WITH_INVALID_SURFACE"
        else:
            batch.status = "COMPLETED"

        self.manifest.completed_cases = sum(b.completed_cases for b in self.manifest.batches)
        self.manifest.failed_cases = sum(b.failed_cases for b in self.manifest.batches)
        self.manifest.invalid_surface_cases = sum(b.invalid_surface_cases for b in self.manifest.batches)

        if all(b.status in ("COMPLETED", "COMPLETED_WITH_INVALID_SURFACE") for b in self.manifest.batches):
            if any(b.status == "COMPLETED_WITH_INVALID_SURFACE" for b in self.manifest.batches):
                self.manifest.status = "COMPLETED_WITH_INVALID_SURFACE"
            else:
                self.manifest.status = "COMPLETED"
        elif any(b.status == "FAILED" for b in self.manifest.batches):
            self.manifest.status = "FAILED"

        self.manifest.save(self.artifact_dir)
        return batch

    def execute_all(
        self,
        *,
        is_cancelled: Callable[[], bool] | None = None,
        progress_callback: Callable[[SweepBatch, SweepManifest], None] | None = None,
    ) -> SweepManifest:
        """Execute all remaining batches until complete or cancelled."""
        while True:
            batch = self.execute_next_batch(is_cancelled=is_cancelled)
            if batch is None:
                break
            if progress_callback:
                progress_callback(batch, self.manifest)
        return self.manifest

    def _execute_single_case(
        self,
        case: PlannedCase,
        batch_id: str,
        out_file: Any,
    ) -> dict[str, Any]:
        """Execute a planned case against LuaSemanticWorker and stream rows."""
        scenario = self.inventory.project_to_scenario(case.parameters, DEFAULT_SCENARIO)
        phrase_salt = f"{case.case_id}:{case.strategy}"
        scenario.setdefault("runtime", {})["language"] = case.language
        scenario["runtime"]["phraseSalt"] = phrase_salt
        scenario["runtime"]["caseID"] = case.case_id

        has_invalid_surface = False

        with self.worker_factory(scenario) as worker:
            if hasattr(worker, "set_language"):
                worker.set_language(case.language)

            for turn_idx, turn_spec in enumerate(case.turns):
                if "language" in turn_spec and hasattr(worker, "set_language"):
                    worker.set_language(turn_spec["language"])

                root_choice = turn_spec.get("rootChoice")
                input_text = turn_spec.get("text") or turn_spec.get("input")
                suggestion_frame = turn_spec.get("suggestionClick")
                surface_missing = False

                if root_choice:
                    worker.open_conversation()
                    view = worker.conversation_projection()
                    choice_rows = (
                        ((view.get("presentation") or {}).get("responseChannel") or {}).get("rows")
                        or []
                    )
                    target = str(root_choice).strip()
                    matched = None
                    for r in choice_rows:
                        if not isinstance(r, dict):
                            continue
                        rid = str(r.get("id") or "")
                        ext = (r.get("frame") or {}).get("extensions") or {}
                        aid = ext.get("actionID") or ext.get("rootChoiceID")
                        if (
                            rid == target
                            or rid.endswith(":" + target)
                            or aid == target
                            or ("orders" in rid and target in ("orders", "companion_orders"))
                        ):
                            matched = r
                            break

                    if matched and "frame" in matched:
                        record = worker.suggestion_click(matched["frame"])
                    else:
                        surface_missing = True
                        record = worker.input(f"root:{root_choice}")
                elif suggestion_frame:
                    record = worker.suggestion_click(suggestion_frame)
                elif input_text is not None:
                    record = worker.input(input_text)
                else:
                    record = worker.input("hello")

                rows = extract_evidence_rows_from_turn(
                    record,
                    turn_index=turn_idx,
                    case_id=case.case_id,
                    sweep_id=self.plan.sweep_id,
                    batch_id=batch_id,
                    strategy=case.strategy,
                    parameters=case.parameters,
                    language=case.language,
                    salt=phrase_salt,
                    input_spec=turn_spec,
                    planned_surface=case.surface,
                    surface_missing=surface_missing,
                    worker=worker,
                )

                for row in rows:
                    if row.get("identity", {}).get("surfaceStatus") == "INVALID_SURFACE":
                        has_invalid_surface = True
                    out_file.write(json.dumps(row) + "\n")
                out_file.flush()

        return {"invalid_surface": has_invalid_surface}

    def iter_evidence_rows(self) -> Generator[dict[str, Any], None, None]:
        """Stream read parsed evidence rows from evidence.jsonl."""
        if not self.evidence_path.exists():
            return
        with open(self.evidence_path, "r", encoding="utf-8") as f:
            for line in f:
                stripped = line.strip()
                if stripped:
                    yield json.loads(stripped)
