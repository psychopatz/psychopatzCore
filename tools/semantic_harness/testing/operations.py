"""Allowlisted typed fixture operation registry for declarative semantic tests.

Maps stable fixture action IDs to payload validators, bounded production
authority bindings (worker or compiler), and normalized result envelopes.
Never dispatches arbitrary strings to arbitrary Python or Lua methods.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Callable, Literal

from .compiler_probes import (
    probe_backend_projection_inspect,
    probe_canonical_ir_inspect,
    probe_portable_plan_inspect,
    probe_convo_engine_inspect,
    probe_convo_engine_validate,
    probe_source_lineage_locate,
)

OperationAuthority = Literal["worker", "compiler"]


class OperationValidationError(ValueError):
    """Raised when a fixture operation ID or payload fails validation."""


@dataclass(frozen=True)
class OperationSpec:
    action_id: str
    authority: OperationAuthority
    mutating: bool
    validator: Callable[[dict[str, Any], dict[str, Any]], dict[str, Any]]
    runner: Callable[[Any, dict[str, Any], dict[str, Any]], Any]
    list_key: str | None = None


def _ensure_payload_dict(payload: Any, action_id: str) -> dict[str, Any]:
    if payload is None:
        return {}
    if not isinstance(payload, dict):
        raise OperationValidationError(
            f"Operation '{action_id}' payload must be an object, got {type(payload).__name__}"
        )
    return dict(payload)


def _require_nonempty_str(
    payload: dict[str, Any], key: str, action_id: str
) -> str:
    value = payload.get(key)
    if not isinstance(value, str) or not value.strip():
        raise OperationValidationError(
            f"Operation '{action_id}' requires non-empty string '{key}'"
        )
    return value


def _optional_str(
    payload: dict[str, Any],
    key: str,
    default: str | None,
    action_id: str,
) -> str | None:
    if key not in payload or payload[key] is None:
        return default
    value = payload[key]
    if not isinstance(value, str):
        raise OperationValidationError(
            f"Operation '{action_id}' field '{key}' must be a string"
        )
    return value


def _require_int(payload: dict[str, Any], key: str, action_id: str) -> int:
    value = payload.get(key)
    if isinstance(value, bool) or not isinstance(value, int):
        raise OperationValidationError(
            f"Operation '{action_id}' requires integer '{key}'"
        )
    return value


def _optional_int(
    payload: dict[str, Any],
    key: str,
    default: int,
    action_id: str,
    *,
    minimum: int | None = None,
) -> int:
    if key not in payload or payload[key] is None:
        return default
    value = payload[key]
    if isinstance(value, bool) or not isinstance(value, int):
        raise OperationValidationError(
            f"Operation '{action_id}' field '{key}' must be an integer"
        )
    if minimum is not None and value < minimum:
        raise OperationValidationError(
            f"Operation '{action_id}' field '{key}' must be >= {minimum}"
        )
    return value


def _optional_float(
    payload: dict[str, Any], key: str, default: float, action_id: str
) -> float:
    if key not in payload or payload[key] is None:
        return default
    value = payload[key]
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise OperationValidationError(
            f"Operation '{action_id}' field '{key}' must be numeric"
        )
    return float(value)


def _optional_bool(
    payload: dict[str, Any], key: str, default: bool, action_id: str
) -> bool:
    if key not in payload or payload[key] is None:
        return default
    value = payload[key]
    if not isinstance(value, bool):
        raise OperationValidationError(
            f"Operation '{action_id}' field '{key}' must be a boolean"
        )
    return value


def _require_dict(
    payload: dict[str, Any], key: str, action_id: str
) -> dict[str, Any]:
    value = payload.get(key)
    if not isinstance(value, dict) or not value:
        raise OperationValidationError(
            f"Operation '{action_id}' requires non-empty object '{key}'"
        )
    return dict(value)


def _optional_dict(
    payload: dict[str, Any], key: str, action_id: str
) -> dict[str, Any]:
    if key not in payload or payload[key] is None:
        return {}
    value = payload[key]
    if not isinstance(value, dict):
        raise OperationValidationError(
            f"Operation '{action_id}' field '{key}' must be an object"
        )
    return dict(value)


def _call_worker(worker: Any, method_name: str, action_id: str, *args: Any, **kwargs: Any) -> Any:
    method = getattr(worker, method_name, None)
    if not callable(method):
        raise RuntimeError(
            f"Active worker '{type(worker).__name__}' does not support operation '{action_id}'"
        )
    return method(*args, **kwargs)


# --- Validators & Runners ---

def _validate_empty(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    return _ensure_payload_dict(payload, action_id)


def _validate_definition(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    return {"definition": _require_dict(data, "definition", action_id)}


def _validate_preview(payload: dict[str, Any], turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    text = turn.get("text") or turn.get("input") or data.get("text")
    if not isinstance(text, str) or not text.strip():
        raise OperationValidationError(
            f"Operation '{action_id}' requires non-empty 'text'"
        )
    return {"text": text}


def _validate_beat_preview(payload: dict[str, Any], turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    definition = _require_dict(data, "definition", action_id)
    text = data.get("text") or turn.get("text") or turn.get("input")
    if not isinstance(text, str) or not text.strip():
        raise OperationValidationError(
            f"Operation '{action_id}' requires non-empty 'text'"
        )
    return {"definition": definition, "text": text}


def _validate_interaction_preview(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    stimulus = data.get("stimulus", data)
    if not isinstance(stimulus, dict) or not stimulus:
        raise OperationValidationError(
            f"Operation '{action_id}' requires non-empty stimulus object"
        )
    return {"stimulus": dict(stimulus)}


def _validate_knowledge_bootstrap(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    return {
        "requestID": _optional_str(
            data, "requestID", "harness-knowledge-bootstrap", action_id
        )
    }


def _validate_knowledge_metrics(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    return {
        "syntheticNPCs": _optional_int(data, "syntheticNPCs", 0, action_id, minimum=0),
        "factsPerNPC": _optional_int(data, "factsPerNPC", 1, action_id, minimum=0),
    }


def _validate_knowledge_inspect(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    return {
        "actorID": _optional_str(data, "actorID", None, action_id),
        "factID": _optional_str(data, "factID", None, action_id),
        "maxFacts": _optional_int(data, "maxFacts", 32, action_id, minimum=1),
    }


def _validate_knowledge_propagate(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    return {
        "fromActorID": _require_nonempty_str(data, "fromActorID", action_id),
        "toActorID": _require_nonempty_str(data, "toActorID", action_id),
        "channel": _optional_str(data, "channel", "conversation", action_id),
        "authorized": _optional_bool(data, "authorized", True, action_id),
        "now": _optional_float(data, "now", 1000.0, action_id),
    }


def _validate_knowledge_discover(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    return {
        "topicID": _require_nonempty_str(data, "topicID", action_id),
        "npcID": _optional_str(data, "npcID", None, action_id),
    }


def _validate_backstory_inspect(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    save_seed = data.get("saveSeed")
    if save_seed is not None and not isinstance(save_seed, (str, int)):
        raise OperationValidationError(
            f"Operation '{action_id}' field 'saveSeed' must be string or integer"
        )
    return {
        "identitySeed": _require_int(data, "identitySeed", action_id),
        "tacticalClass": _optional_str(data, "tacticalClass", "colonist", action_id),
        "npcID": _optional_str(data, "npcID", "harness-backstory-npc", action_id),
        "saveSeed": save_seed,
    }


def _validate_backstory_fact(payload: dict[str, Any], turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    base = _validate_backstory_inspect(payload, turn, action_id)
    data = _ensure_payload_dict(payload, action_id)
    base["kind"] = _require_nonempty_str(data, "kind", action_id)
    base["language"] = _optional_str(data, "language", "EN", action_id)
    return base


def _validate_commitment_apply(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    if not data:
        raise OperationValidationError(
            f"Operation '{action_id}' requires a non-empty payload object"
        )
    return data


def _validate_response_lookup(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    return {"key": _require_nonempty_str(data, "key", action_id)}


def _validate_response_list(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    return {
        "filter": _optional_str(data, "filter", "", action_id) or "",
        "offset": _optional_int(data, "offset", 0, action_id, minimum=0),
        "limit": _optional_int(data, "limit", 32, action_id, minimum=1),
    }


def _validate_response_detail(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    return {
        "poolID": _require_nonempty_str(data, "poolID", action_id),
        "offset": _optional_int(data, "offset", 0, action_id, minimum=0),
        "limit": _optional_int(data, "limit", 8, action_id, minimum=1),
    }


def _validate_response_selection(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    return {
        "poolID": _require_nonempty_str(data, "poolID", action_id),
        "context": _optional_dict(data, "context", action_id),
        "salt": _optional_str(data, "salt", "", action_id) or "",
    }


def _validate_convo_engine_validate(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    return {"recordID": _optional_str(data, "recordID", None, action_id)}


def _validate_convo_engine_inspect(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    mode = _optional_str(data, "mode", "summary", action_id) or "summary"
    if mode not in {"summary", "source", "ir", "impact"}:
        raise OperationValidationError(
            f"Operation '{action_id}' field 'mode' must be summary, source, ir, or impact"
        )
    return {
        "recordID": _require_nonempty_str(data, "recordID", action_id),
        "mode": mode,
    }


def _validate_record_id(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    return {"recordID": _require_nonempty_str(data, "recordID", action_id)}


def _validate_portable_plan_inspect(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    return {
        "recordID": _optional_str(data, "recordID", None, action_id),
        "section": _optional_str(data, "section", None, action_id),
    }


def _validate_backend_projection_inspect(payload: dict[str, Any], _turn: dict[str, Any], action_id: str) -> dict[str, Any]:
    data = _ensure_payload_dict(payload, action_id)
    return {
        "recordID": _require_nonempty_str(data, "recordID", action_id),
        "backend": _optional_str(data, "backend", "pz-lua", action_id) or "pz-lua",
    }


def _compiler_kwargs(context: Any) -> dict[str, Any]:
    if isinstance(context, dict):
        return {
            "core_repository": context.get("core_repository"),
            "repository": context.get("repository"),
            "config": context.get("config"),
        }
    return {}


def _build_registry() -> dict[str, OperationSpec]:
    specs = [
        OperationSpec(
            action_id="preview",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_preview(p, t, "preview"),
            runner=lambda w, p, _t: _call_worker(w, "preview", "preview", p["text"]),
        ),
        # Beats
        OperationSpec(
            action_id="beat.catalog",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_empty(p, t, "beat.catalog"),
            runner=lambda w, _p, _t: _call_worker(w, "beat_catalog", "beat.catalog"),
        ),
        OperationSpec(
            action_id="beat.validate",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_definition(p, t, "beat.validate"),
            runner=lambda w, p, _t: _call_worker(w, "validate_beat", "beat.validate", p["definition"]),
        ),
        OperationSpec(
            action_id="beat.register",
            authority="worker",
            mutating=True,
            validator=lambda p, t: _validate_definition(p, t, "beat.register"),
            runner=lambda w, p, _t: _call_worker(w, "register_beat", "beat.register", p["definition"]),
        ),
        OperationSpec(
            action_id="beat.preview",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_beat_preview(p, t, "beat.preview"),
            runner=lambda w, p, _t: _call_worker(
                w, "preview_beat", "beat.preview", p["definition"], p["text"]
            ),
        ),
        # Behaviors
        OperationSpec(
            action_id="behavior.validate",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_definition(p, t, "behavior.validate"),
            runner=lambda w, p, _t: _call_worker(
                w, "validate_behavior", "behavior.validate", p["definition"]
            ),
        ),
        OperationSpec(
            action_id="behavior.register",
            authority="worker",
            mutating=True,
            validator=lambda p, t: _validate_definition(p, t, "behavior.register"),
            runner=lambda w, p, _t: _call_worker(
                w, "register_behavior", "behavior.register", p["definition"]
            ),
        ),
        # Interaction preview
        OperationSpec(
            action_id="interaction.preview",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_interaction_preview(p, t, "interaction.preview"),
            runner=lambda w, p, _t: _call_worker(
                w, "preview_interaction", "interaction.preview", p["stimulus"]
            ),
        ),
        # Knowledge / backstory / commitment
        OperationSpec(
            action_id="knowledge.bootstrap",
            authority="worker",
            mutating=True,
            validator=lambda p, t: _validate_knowledge_bootstrap(p, t, "knowledge.bootstrap"),
            runner=lambda w, p, _t: _call_worker(
                w, "knowledge_bootstrap", "knowledge.bootstrap", request_id=p["requestID"]
            ),
        ),
        OperationSpec(
            action_id="knowledge.metrics",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_knowledge_metrics(p, t, "knowledge.metrics"),
            runner=lambda w, p, _t: _call_worker(
                w,
                "knowledge_metrics",
                "knowledge.metrics",
                synthetic_npcs=p["syntheticNPCs"],
                facts_per_npc=p["factsPerNPC"],
            ),
        ),
        OperationSpec(
            action_id="knowledge.inspect",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_knowledge_inspect(p, t, "knowledge.inspect"),
            runner=lambda w, p, _t: _call_worker(
                w,
                "world_knowledge_inspect",
                "knowledge.inspect",
                actor_id=p["actorID"],
                fact_id=p["factID"],
                max_facts=p["maxFacts"],
            ),
        ),
        OperationSpec(
            action_id="knowledge.propagate",
            authority="worker",
            mutating=True,
            validator=lambda p, t: _validate_knowledge_propagate(p, t, "knowledge.propagate"),
            runner=lambda w, p, _t: _call_worker(
                w,
                "world_knowledge_propagate",
                "knowledge.propagate",
                p["fromActorID"],
                p["toActorID"],
                channel=p["channel"],
                authorized=p["authorized"],
                now=p["now"],
            ),
        ),
        OperationSpec(
            action_id="knowledge.discover",
            authority="worker",
            mutating=True,
            validator=lambda p, t: _validate_knowledge_discover(p, t, "knowledge.discover"),
            runner=lambda w, p, _t: _call_worker(
                w,
                "knowledge_discover",
                "knowledge.discover",
                p["topicID"],
                npc_id=p["npcID"],
            ),
        ),
        OperationSpec(
            action_id="backstory.inspect",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_backstory_inspect(p, t, "backstory.inspect"),
            runner=lambda w, p, _t: _call_worker(
                w,
                "backstory",
                "backstory.inspect",
                p["identitySeed"],
                tactical_class=p["tacticalClass"],
                npc_id=p["npcID"],
                save_seed=p["saveSeed"],
            ),
        ),
        OperationSpec(
            action_id="backstory.fact",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_backstory_fact(p, t, "backstory.fact"),
            runner=lambda w, p, _t: _call_worker(
                w,
                "backstory_fact",
                "backstory.fact",
                p["identitySeed"],
                p["kind"],
                tactical_class=p["tacticalClass"],
                language=p["language"],
                npc_id=p["npcID"],
                save_seed=p["saveSeed"],
            ),
        ),
        OperationSpec(
            action_id="commitment.apply",
            authority="worker",
            mutating=True,
            validator=lambda p, t: _validate_commitment_apply(p, t, "commitment.apply"),
            runner=lambda w, p, _t: _call_worker(
                w, "commitment", "commitment.apply", p
            ),
        ),
        # Response pools / realization selection
        OperationSpec(
            action_id="response.lookup",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_response_lookup(p, t, "response.lookup"),
            runner=lambda w, p, _t: _call_worker(
                w, "response_key_lookup", "response.lookup", p["key"]
            ),
        ),
        OperationSpec(
            action_id="response.list",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_response_list(p, t, "response.list"),
            runner=lambda w, p, _t: _call_worker(
                w,
                "response_pool_list",
                "response.list",
                filter=p["filter"],
                offset=p["offset"],
                limit=p["limit"],
            ),
        ),
        OperationSpec(
            action_id="response.detail",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_response_detail(p, t, "response.detail"),
            runner=lambda w, p, _t: _call_worker(
                w,
                "response_pool_detail",
                "response.detail",
                p["poolID"],
                offset=p["offset"],
                limit=p["limit"],
            ),
        ),
        OperationSpec(
            action_id="response.explain",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_response_selection(p, t, "response.explain"),
            runner=lambda w, p, _t: _call_worker(
                w,
                "explain_response_selection",
                "response.explain",
                p["poolID"],
                p["context"],
                p["salt"],
            ),
        ),
        OperationSpec(
            action_id="response.sample",
            authority="worker",
            mutating=True,
            validator=lambda p, t: _validate_response_selection(p, t, "response.sample"),
            runner=lambda w, p, _t: _call_worker(
                w,
                "sample_response_selection",
                "response.sample",
                p["poolID"],
                p["context"],
                p["salt"],
            ),
        ),
        # Flows / facts / events
        OperationSpec(
            action_id="flow.catalog",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_empty(p, t, "flow.catalog"),
            runner=lambda w, _p, _t: _call_worker(w, "flow_catalog", "flow.catalog"),
        ),
        OperationSpec(
            action_id="flow.validate",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_definition(p, t, "flow.validate"),
            runner=lambda w, p, _t: _call_worker(w, "validate_flow", "flow.validate", p["definition"]),
        ),
        OperationSpec(
            action_id="flow.register",
            authority="worker",
            mutating=True,
            validator=lambda p, t: _validate_definition(p, t, "flow.register"),
            runner=lambda w, p, _t: _call_worker(w, "register_flow", "flow.register", p["definition"]),
        ),
        OperationSpec(
            action_id="flow.generate",
            authority="worker",
            mutating=True,
            validator=lambda p, t: _validate_empty(p, t, "flow.generate"),
            runner=lambda w, _p, _t: _call_worker(w, "generate_flows", "flow.generate"),
        ),
        OperationSpec(
            action_id="flow.coverage",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_empty(p, t, "flow.coverage"),
            runner=lambda w, _p, _t: _call_worker(w, "flow_coverage", "flow.coverage"),
            list_key="capabilityCoverage",
        ),
        OperationSpec(
            action_id="fact.catalog",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_empty(p, t, "fact.catalog"),
            runner=lambda w, _p, _t: _call_worker(w, "fact_catalog", "fact.catalog"),
            list_key="facts",
        ),
        OperationSpec(
            action_id="event.catalog",
            authority="worker",
            mutating=False,
            validator=lambda p, t: _validate_empty(p, t, "event.catalog"),
            runner=lambda w, _p, _t: _call_worker(w, "event_catalog", "event.catalog"),
            list_key="events",
        ),
        # Compiler / ConvoEngine probes
        OperationSpec(
            action_id="compiler.convo_engine_validate",
            authority="compiler",
            mutating=False,
            validator=lambda p, t: _validate_convo_engine_validate(p, t, "compiler.convo_engine_validate"),
            runner=lambda ctx, p, _t: probe_convo_engine_validate(
                record_id=p["recordID"], **_compiler_kwargs(ctx)
            ),
        ),
        OperationSpec(
            action_id="compiler.convo_engine_inspect",
            authority="compiler",
            mutating=False,
            validator=lambda p, t: _validate_convo_engine_inspect(p, t, "compiler.convo_engine_inspect"),
            runner=lambda ctx, p, _t: probe_convo_engine_inspect(
                record_id=p["recordID"], mode=p["mode"], **_compiler_kwargs(ctx)
            ),
        ),
        OperationSpec(
            action_id="compiler.canonical_ir",
            authority="compiler",
            mutating=False,
            validator=lambda p, t: _validate_record_id(p, t, "compiler.canonical_ir"),
            runner=lambda ctx, p, _t: probe_canonical_ir_inspect(
                record_id=p["recordID"], **_compiler_kwargs(ctx)
            ),
        ),
        OperationSpec(
            action_id="compiler.portable_plan",
            authority="compiler",
            mutating=False,
            validator=lambda p, t: _validate_portable_plan_inspect(p, t, "compiler.portable_plan"),
            runner=lambda ctx, p, _t: probe_portable_plan_inspect(
                record_id=p["recordID"], section=p["section"], **_compiler_kwargs(ctx)
            ),
        ),
        OperationSpec(
            action_id="compiler.backend_projection",
            authority="compiler",
            mutating=False,
            validator=lambda p, t: _validate_backend_projection_inspect(p, t, "compiler.backend_projection"),
            runner=lambda ctx, p, _t: probe_backend_projection_inspect(
                record_id=p["recordID"], backend=p["backend"], **_compiler_kwargs(ctx)
            ),
        ),
        OperationSpec(
            action_id="compiler.source_lineage",
            authority="compiler",
            mutating=False,
            validator=lambda p, t: _validate_record_id(p, t, "compiler.source_lineage"),
            runner=lambda ctx, p, _t: probe_source_lineage_locate(
                record_id=p["recordID"], **_compiler_kwargs(ctx)
            ),
        ),
    ]
    return {spec.action_id: spec for spec in specs}


OPERATION_REGISTRY: dict[str, OperationSpec] = _build_registry()


def get_operation_spec(action_id: str) -> OperationSpec:
    spec = OPERATION_REGISTRY.get(action_id)
    if spec is None:
        raise OperationValidationError(
            f"Unsupported fixture action '{action_id}'. "
            f"Registered actions: {sorted(OPERATION_REGISTRY)}"
        )
    return spec


def validate_operation_turn(
    action_id: str,
    payload: Any,
    turn_spec: dict[str, Any],
) -> dict[str, Any]:
    spec = get_operation_spec(action_id)
    payload_dict = _ensure_payload_dict(payload, action_id)
    return spec.validator(payload_dict, turn_spec)


def normalize_operation_result(
    spec: OperationSpec,
    raw: Any,
) -> dict[str, Any]:
    if isinstance(raw, list):
        result_dict: dict[str, Any] = {
            "items": list(raw),
            "count": len(raw),
        }
        if spec.list_key:
            result_dict[spec.list_key] = list(raw)
    elif isinstance(raw, dict):
        result_dict = dict(raw)
    else:
        result_dict = {"value": raw}

    has_error = bool(result_dict.get("error")) or result_dict.get("ok") is False
    status = "error" if has_error else "ok"

    envelope: dict[str, Any] = {
        "operation": {
            "id": spec.action_id,
            "status": status,
            "authority": spec.authority,
            "mutating": spec.mutating,
        },
        "result": result_dict,
    }
    if isinstance(result_dict.get("observation"), dict):
        envelope["observation"] = result_dict["observation"]
    for key in ("messages", "dispatchTransport", "transport", "toolCalls"):
        if key in result_dict:
            envelope[key] = result_dict[key]
    return envelope


def execute_operation(
    action_id: str,
    worker: Any,
    turn_spec: dict[str, Any],
) -> dict[str, Any]:
    spec = get_operation_spec(action_id)
    validated_payload = spec.validator(
        _ensure_payload_dict(turn_spec.get("payload"), action_id),
        turn_spec,
    )
    raw = spec.runner(worker, validated_payload, turn_spec)
    if spec.action_id == "preview":
        return raw
    return normalize_operation_result(spec, raw)


__all__ = [
    "OPERATION_REGISTRY",
    "OperationAuthority",
    "OperationSpec",
    "OperationValidationError",
    "execute_operation",
    "get_operation_spec",
    "normalize_operation_result",
    "validate_operation_turn",
]
