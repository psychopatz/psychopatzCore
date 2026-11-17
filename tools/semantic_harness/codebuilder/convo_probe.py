"""Production Lua ConvoProbe client (Port B) with strict capability negotiation.

Routes predicate evaluation, text-role rendering, slot expansion, affordance
scoring/selection, reply/after resolution, action-contract listing/projection,
and exchange simulation to the live Core/provider Lua runtime through
``CONVO_PROBE``. Never falls back silently to a Python re-implementation.
"""

from __future__ import annotations

import atexit
from pathlib import Path
from typing import Any, Callable, Mapping, Sequence

from ..core.activity import ActivityLog
from ..core.worker import SemanticWorker
from ..discovery.runtime import discover_lua
from ..transport.process import WorkerLaunchSpec
from .errors import CompileError
from .workspace_catalog import WorkspaceSnapshot


CONVO_TRACE_SCHEMA = "semantic.harness.convo_trace.v1"
REQUIRED_CAPABILITY = "semantic.convo_probe"
_ENGINE_CORE_ROOT = Path(__file__).resolve().parents[3]


class ConvoProbeUnavailableError(CompileError):
    """Raised explicitly when no capable production Lua ConvoProbe worker exists."""


def _capabilities_of(worker: Any) -> set[str]:
    hello = getattr(getattr(worker, "runtime", None), "hello", None)
    caps: list[Any] = []
    if isinstance(hello, Mapping) and isinstance(hello.get("capabilities"), (list, tuple)):
        caps.extend(hello["capabilities"])
    if hasattr(worker, "capabilities") and callable(worker.capabilities):
        try:
            snap = worker.capabilities()
        except Exception as error:
            raise ConvoProbeUnavailableError(
                f"Failed to query Lua worker capabilities: {error}"
            ) from error
        if isinstance(snap, Mapping) and isinstance(snap.get("capabilities"), (list, tuple)):
            caps.extend(snap["capabilities"])
    return {str(c) for c in caps}


class ConvoProbe:
    """Thin client wrapper over a production Lua ``CONVO_PROBE`` worker session."""

    def __init__(
        self,
        workspace: WorkspaceSnapshot,
        *,
        worker: Any | None = None,
        worker_factory: Callable[[WorkspaceSnapshot], Any] | None = None,
        lua_bin: str | Path | None = None,
        worker_script: str | Path | None = None,
    ) -> None:
        self.workspace = workspace
        self._external_worker = worker
        self._worker_factory = worker_factory
        self._lua_bin = lua_bin
        self._worker_script = Path(worker_script).expanduser() if worker_script is not None else None
        self._owned_worker: Any | None = None
        self._verified_worker_id: int | None = None
        self._atexit_registered = True
        atexit.register(self.close)

    def _resolve_engine_core_root(self) -> Path:
        repo_worker = self.workspace.core_repository / "tools/semantic_harness/lua/worker.lua"
        if repo_worker.is_file():
            return self.workspace.core_repository
        engine_worker = _ENGINE_CORE_ROOT / "tools/semantic_harness/lua/worker.lua"
        if engine_worker.is_file():
            return _ENGINE_CORE_ROOT
        raise ConvoProbeUnavailableError(
            f"ConvoProbe Lua worker script is unavailable under {self.workspace.core_repository}"
        )

    def _start_owned_worker(self) -> Any:
        engine_core = self._resolve_engine_core_root()
        worker_script = (
            self._worker_script
            if self._worker_script is not None
            else engine_core / "tools/semantic_harness/lua/worker.lua"
        ).expanduser().resolve()
        if not worker_script.is_file():
            raise ConvoProbeUnavailableError(
                f"Configured ConvoProbe worker script does not exist: {worker_script}"
            )
        try:
            lua_bin = discover_lua(self._lua_bin)
            launch_spec = WorkerLaunchSpec(
                lua_bin=lua_bin,
                worker_script=worker_script,
                core_repository=engine_core,
                working_directory=engine_core,
                profile="core",
                provider_ids=("PsychopatzCore",),
                materialization_mode="none",
                environment={
                    "SEMANTIC_HARNESS_REPOSITORY": str(engine_core),
                    "SEMANTIC_HARNESS_CORE_REPOSITORY": str(engine_core),
                },
            )
            return SemanticWorker(
                {},
                launch_spec,
                activity_log=ActivityLog(path=None, client="convo_probe"),
                import_source_on_start=False,
            )
        except ConvoProbeUnavailableError:
            raise
        except Exception as error:
            raise ConvoProbeUnavailableError(
                f"ConvoProbe failed to start production Lua worker: {error}"
            ) from error

    def _ensure_worker(self) -> Any:
        worker = self._external_worker or self._owned_worker
        if worker is None:
            if self._worker_factory is not None:
                try:
                    worker = self._worker_factory(self.workspace)
                except Exception as error:
                    raise ConvoProbeUnavailableError(
                        f"ConvoProbe worker_factory failed: {error}"
                    ) from error
            else:
                worker = self._start_owned_worker()
            self._owned_worker = worker
            if not self._atexit_registered:
                atexit.register(self.close)
                self._atexit_registered = True
        if worker is None:
            raise ConvoProbeUnavailableError("ConvoProbe worker is unavailable")

        if self._verified_worker_id != id(worker):
            caps = _capabilities_of(worker)
            if REQUIRED_CAPABILITY not in caps and "CONVO_PROBE" not in caps:
                raise ConvoProbeUnavailableError(
                    f"Connected Lua worker does not advertise required capability {REQUIRED_CAPABILITY!r}"
                )
            self._verified_worker_id = id(worker)
        return worker

    def attach_worker(self, worker: Any | None) -> None:
        self._external_worker = worker
        self._verified_worker_id = None

    def close(self) -> None:
        if self._atexit_registered:
            try:
                atexit.unregister(self.close)
            except Exception:
                pass
            self._atexit_registered = False
        worker = self._owned_worker
        self._owned_worker = None
        self._verified_worker_id = None
        if worker is not None and hasattr(worker, "close"):
            try:
                worker.close()
            except Exception:
                pass

    def call(self, op: str, payload: Mapping[str, Any] | None = None) -> dict[str, Any]:
        worker = self._ensure_worker()
        req = dict(payload or {})
        req["op"] = str(op)
        try:
            response = worker._request("CONVO_PROBE", req)
        except Exception as error:
            raise ConvoProbeUnavailableError(
                f"CONVO_PROBE {op!r} failed on Lua worker: {error}"
            ) from error
        if not isinstance(response, dict):
            raise ConvoProbeUnavailableError(
                f"CONVO_PROBE {op!r} returned non-object response"
            )
        return response

    def describe(self) -> dict[str, Any]:
        return self.call("describe", {})

    def evaluate_predicate(
        self,
        predicate: Mapping[str, Any] | None,
        context: Mapping[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.call(
            "evaluate_predicate",
            {"predicate": predicate, "context": dict(context or {})},
        )

    def render_role_text(
        self,
        plan_or_family: Mapping[str, Any],
        role: str,
        context: Mapping[str, Any] | None = None,
        options: Mapping[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.call(
            "render_role_text",
            {
                "plan": dict(plan_or_family),
                "role": str(role),
                "context": dict(context or {}),
                "options": dict(options or {}),
            },
        )

    def expand_slots(
        self,
        plan_or_family: Mapping[str, Any],
        context: Mapping[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.call(
            "expand_slots",
            {"plan": dict(plan_or_family), "context": dict(context or {})},
        )

    def score_affordance(
        self,
        plan_or_family: Mapping[str, Any],
        context: Mapping[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.call(
            "score_affordance",
            {"plan": dict(plan_or_family), "context": dict(context or {})},
        )

    def collect_affordances(
        self,
        plans: Sequence[Mapping[str, Any]],
        *,
        consumer: str = "participant",
        context: Mapping[str, Any] | None = None,
        options: Mapping[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.call(
            "collect_affordances",
            {
                "plans": [dict(p) for p in plans],
                "consumer": str(consumer),
                "context": dict(context or {}),
                "options": dict(options or {}),
            },
        )

    def select_npc_affordance(
        self,
        plans: Sequence[Mapping[str, Any]],
        *,
        context: Mapping[str, Any] | None = None,
        options: Mapping[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.call(
            "select_npc_affordance",
            {
                "plans": [dict(p) for p in plans],
                "context": dict(context or {}),
                "options": dict(options or {}),
            },
        )

    def select_reply(
        self,
        plan_or_family: Mapping[str, Any] | str,
        *,
        context: Mapping[str, Any] | None = None,
        options: Mapping[str, Any] | None = None,
        plans: Sequence[Mapping[str, Any]] | None = None,
    ) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "context": dict(context or {}),
            "options": dict(options or {}),
        }
        if isinstance(plan_or_family, Mapping):
            payload["plan"] = dict(plan_or_family)
        else:
            payload["familyID"] = str(plan_or_family)
        if plans is not None:
            payload["plans"] = [dict(p) for p in plans]
        return self.call("select_reply", payload)

    def resolve_after(
        self,
        plan_or_family: Mapping[str, Any] | str,
        *,
        outcome: str | None = None,
        context: Mapping[str, Any] | None = None,
        options: Mapping[str, Any] | None = None,
        plans: Sequence[Mapping[str, Any]] | None = None,
    ) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "outcome": outcome,
            "context": dict(context or {}),
            "options": dict(options or {}),
        }
        if isinstance(plan_or_family, Mapping):
            payload["plan"] = dict(plan_or_family)
        else:
            payload["familyID"] = str(plan_or_family)
        if plans is not None:
            payload["plans"] = [dict(p) for p in plans]
        return self.call("resolve_after", payload)

    def list_action_contracts(self) -> list[dict[str, Any]]:
        res = self.call("list_action_contracts", {})
        contracts = res.get("contracts")
        return list(contracts) if isinstance(contracts, list) else []

    def project_action_result(
        self,
        contract_or_id: Mapping[str, Any] | str,
        raw_result: Mapping[str, Any] | None = None,
        *,
        request_id: str | None = None,
        options: Mapping[str, Any] | None = None,
    ) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "rawResult": dict(raw_result or {}),
            "requestID": request_id,
            "options": dict(options or {}),
        }
        if isinstance(contract_or_id, Mapping):
            payload["contract"] = dict(contract_or_id)
        else:
            payload["contractID"] = str(contract_or_id)
        return self.call("project_action_result", payload)

    def simulate_exchange(
        self,
        plan: Mapping[str, Any],
        *,
        context: Mapping[str, Any] | None = None,
        options: Mapping[str, Any] | None = None,
        plans: Sequence[Mapping[str, Any]] | None = None,
    ) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "plan": dict(plan),
            "context": dict(context or {}),
            "options": dict(options or {}),
        }
        if plans is not None:
            payload["plans"] = [dict(p) for p in plans]
        return self.call("simulate_exchange", payload)

    def evaluate_s11_family(
        self,
        plan_entry: Mapping[str, Any],
        *,
        context: Mapping[str, Any] | None = None,
        role_bindings: Mapping[str, Any] | None = None,
        participant_set: Mapping[str, Any] | None = None,
        reply_outcome: str | None = None,
    ) -> dict[str, Any]:
        return self.call(
            "evaluate_s11_family",
            {
                "planEntry": dict(plan_entry),
                "context": dict(context or {}),
                "roleBindings": dict(role_bindings or {}),
                "participantSet": dict(participant_set) if participant_set is not None else None,
                "replyOutcome": reply_outcome,
            },
        )


__all__ = [
    "CONVO_TRACE_SCHEMA",
    "REQUIRED_CAPABILITY",
    "ConvoProbe",
    "ConvoProbeUnavailableError",
]
