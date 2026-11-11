"""Compact per-rendered-sentence evidence schema and serializer.

Represents one rendered NPC sentence/response occurrence with triggering
parameters, semantic/realization paths, translation identity, persona/relationship
context, selection provenance, and bounded authority/effect evidence.
Full traces remain lazy rather than being duplicated into every row.
"""

from __future__ import annotations

from copy import deepcopy
from dataclasses import asdict, dataclass, field
import hashlib
import json
from pathlib import Path
from typing import Any, Mapping

from ..inspection.conversation_inspector import build_conversation_inspector
from tools.semantic_harness.inspection.conversation_inspector_support import bounded

EVIDENCE_SCHEMA_V1 = "pnc.semantic-dialogue-quality-evidence.v1"
ALLOWED_EVIDENCE_SCHEMAS = frozenset({EVIDENCE_SCHEMA_V1})


@dataclass(frozen=True)
class QualityFlag:
    """A deterministic or review quality flag."""

    name: str
    severity: str  # "CRITICAL", "HIGH", "MEDIUM", "LOW", "INFO"
    confidence: str  # "DEFINITE", "SUSPECT", "REVIEW"
    detail: str = ""

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "severity": self.severity,
            "confidence": self.confidence,
            "detail": self.detail,
        }


def _bound_str(val: Any, max_len: int = 500) -> str:
    if val is None:
        return ""
    s = str(val)
    if len(s) > max_len:
        return s[:max_len] + "…"
    return s


def _bound_dict(d: Any, limit: int = 16) -> dict[str, Any]:
    if not isinstance(d, dict):
        return {}
    res = {}
    for i, (k, v) in enumerate(d.items()):
        if i >= limit:
            break
        if isinstance(v, (int, float, bool, str)) or v is None:
            res[str(k)] = v
        elif isinstance(v, (list, tuple)):
            res[str(k)] = [x for x in v[:8] if isinstance(x, (int, float, bool, str))]
        elif isinstance(v, dict):
            res[str(k)] = {str(sk): sv for j, (sk, sv) in enumerate(v.items()) if j < 4 and isinstance(sv, (int, float, bool, str))}
    return res


def extract_evidence_rows_from_turn(
    record: dict[str, Any],
    *,
    turn_index: int = 0,
    case_id: str = "case-1",
    sweep_id: str = "sweep-1",
    batch_id: str | None = None,
    strategy: str = "manual",
    parameters: Mapping[str, Any] | None = None,
    language: str = "EN",
    salt: str | None = None,
    history_mode: str | None = "isolated",
    input_spec: Mapping[str, Any] | None = None,
    planned_surface: str | None = None,
    surface_missing: bool = False,
    expect_fallback: bool = False,
    worker: Any | None = None,
    lineage_cache: Mapping[str, str] | None = None,
) -> list[dict[str, Any]]:
    """Extract compact evidence rows for every rendered NPC sentence in a turn."""
    view = build_conversation_inspector(record)
    messages = record.get("messages", [])
    npc_messages = [
        m for m in messages
        if isinstance(m, dict) and m.get("speaker") == "npc"
    ]

    # Context extraction from inspector view
    semantic = view.get("semantic") or {}
    persona_choices = view.get("personaChoices") or {}
    response_trace = persona_choices.get("responseTrace") or {}
    context = view.get("context") or {}
    actor_context = persona_choices.get("actorConversationContext") or {}
    social_context = view.get("socialContext") or {}
    execution = view.get("execution") or {}
    effects = view.get("effects") or {}
    visible_response = view.get("visibleResponse") or {}
    obs = record.get("observation") or {}
    facts = view.get("facts") or {}

    # Trigger parameter vector (normalized)
    params = dict(parameters or {})

    # Personal relationship extraction - prioritize current actorConversationContext
    personal_rel = (
        actor_context.get("personalRelationship")
        or actor_context.get("relationship")
        or social_context.get("personalRelationship")
        or context.get("personalRelationship")
        or {}
    )
    npc_rec = record.get("npc") if isinstance(record.get("npc"), dict) else {}
    npc_rec_rel = npc_rec.get("relationship") if isinstance(npc_rec.get("relationship"), dict) else {}

    approval = personal_rel.get("approval")
    if approval is None:
        approval = context.get("approval")
    if approval is None:
        approval = npc_rec_rel.get("approval")
    if approval is None and "relationship.approval" in params:
        approval = params["relationship.approval"]

    respect = personal_rel.get("respect")
    if respect is None:
        respect = context.get("respect")
    if respect is None:
        respect = npc_rec_rel.get("respect")
    if respect is None and "relationship.respect" in params:
        respect = params["relationship.respect"]

    familiarity = personal_rel.get("familiarity")
    if familiarity is None:
        familiarity = context.get("familiarity")
    if familiarity is None:
        familiarity = npc_rec_rel.get("familiarity")
    if familiarity is None and "relationship.familiarity" in params:
        familiarity = params["relationship.familiarity"]

    identity_trust = personal_rel.get("identityTrust")
    if identity_trust is None:
        identity_trust = context.get("identityTrust")
    if identity_trust is None:
        identity_trust = npc_rec_rel.get("identityTrust")
    if identity_trust is None and "relationship.identityTrust" in params:
        identity_trust = params["relationship.identityTrust"]

    relationship_state = (
        personal_rel.get("state")
        or personal_rel.get("relationshipState")
        or context.get("relationshipState")
        or social_context.get("relationshipState")
        or npc_rec.get("relationshipState")
    )

    # Durable bond
    durable_bond = (
        social_context.get("durableBond")
        or actor_context.get("bond")
        or response_trace.get("bond")
        or context.get("bond")
        or {}
    )
    bond_kind = durable_bond.get("kind") or context.get("bondKind") or params.get("persona.bondKind") or "none"
    bond_class = durable_bond.get("class") or durable_bond.get("bondClass")
    if bond_class == "none":
        bond_class = None

    # Personality & Social Style
    actor_personality = actor_context.get("personality") or {}
    if not actor_personality:
        actor_personality = persona_choices.get("npcPersonality") or context.get("personality") or {}
    personality = _bound_dict(actor_personality)

    social_style = (
        actor_personality.get("socialStyle")
        or actor_context.get("socialStyle")
        or context.get("socialStyle")
        or persona_choices.get("socialStyle")
        or (persona_choices.get("speechStyleContext") or {}).get("variant")
        or params.get("persona.socialStyle")
    )

    # Traits & Archetype
    raw_traits = (
        actor_context.get("traits")
        or context.get("traits")
        or obs.get("npcTraits")
        or npc_rec.get("traits")
        or params.get("persona.traits")
        or []
    )
    if isinstance(raw_traits, (list, tuple)):
        traits = [str(t.get("value") if isinstance(t, dict) else t) for t in raw_traits][:16]
    else:
        traits = [str(raw_traits)]

    archetype = actor_context.get("archetype") or context.get("archetype") or obs.get("npcArchetype") or npc_rec.get("archetype")

    # Situation / Needs / Health / Activity
    situation = actor_context.get("situation") or {}
    sit_activity = situation.get("activity")
    if isinstance(sit_activity, dict):
        activity_str = sit_activity.get("label") or sit_activity.get("id")
    else:
        activity_str = sit_activity or situation.get("activeBehavior") or context.get("activity")

    npc_health_state = situation.get("healthState") or (obs.get("npcHealth") or {}).get("state") or "normal"
    npc_health = _bound_dict(obs.get("npcHealth") or context.get("npcHealth") or {"state": npc_health_state})
    if "state" not in npc_health and npc_health_state:
        npc_health["state"] = npc_health_state

    player_needs = _bound_dict(context.get("playerNeeds") or obs.get("playerNeeds") or {})
    npc_needs_data = situation.get("needs") or context.get("npcNeeds") or obs.get("npcNeeds") or {}
    npc_needs = _bound_dict(npc_needs_data)

    # Actor & Authority
    roles = actor_context.get("roles") or {}
    actor_summary = {
        "speakerID": _bound_str(actor_context.get("actorID") or record.get("speaker") or context.get("npcID") or "npc", 64),
        "listenerID": _bound_str(context.get("playerID") or "player", 64),
        "roles": _bound_dict(roles),
        "authorityFlags": _bound_dict(roles if roles else view.get("commandAuthority") or {}),
    }

    persona_summary = {
        "personality": personality,
        "socialStyle": str(social_style) if social_style else None,
        "traits": traits,
        "archetype": str(archetype) if archetype else None,
    }

    relationship_summary = {
        "bondKind": str(bond_kind),
        "bondClass": str(bond_class) if bond_class else None,
        "approval": approval,
        "respect": respect,
        "familiarity": familiarity,
        "identityTrust": identity_trust,
        "relationshipState": str(relationship_state) if relationship_state else None,
    }

    state_summary = {
        "playerNeeds": player_needs,
        "npcNeeds": npc_needs,
        "npcHealth": npc_health,
        "activity": _bound_str(activity_str, 64) if activity_str else None,
        "activeBehavior": _bound_str(situation.get("activeBehavior") or npc_rec.get("activeBehavior"), 64) if (situation.get("activeBehavior") or npc_rec.get("activeBehavior")) else None,
    }

    # Authority and effects
    actions = list(effects.get("actions") or [])[:4]
    authority_summary = {
        "actionCount": int(effects.get("actionCount", 0)),
        "transportCount": int(effects.get("transportCount", 0)),
        "actions": [_bound_dict(a) for a in actions if isinstance(a, dict)],
        "executionStatus": execution.get("status"),
        "executionAuthority": execution.get("authority"),
        "rejectionReason": execution.get("rejectionReason"),
    }

    # If no NPC messages occurred, emit one empty row to capture the failure/silence
    targets = npc_messages if npc_messages else [
        {
            "speaker": "npc",
            "payload": {
                "text": "",
                "key": visible_response.get("key"),
                "translationKey": visible_response.get("translationKey"),
            },
        }
    ]

    rows: list[dict[str, Any]] = []

    for msg_idx, msg in enumerate(targets):
        payload = msg.get("payload") if isinstance(msg.get("payload"), dict) else {}
        final_text = str(payload.get("text") or msg.get("text") or "")
        rendered_key = payload.get("key") or msg.get("key")
        translation_key = payload.get("translationKey") or response_trace.get("translationKey")

        # Semantic paths
        semantic_template_id = (
            payload.get("semanticTemplateID")
            or response_trace.get("semanticTemplateID")
            or rendered_key
        )
        render_template_id = payload.get("renderTemplateID") or response_trace.get("renderTemplateID")
        realization_family = (
            payload.get("realizationFamily")
            or response_trace.get("realizationFamily")
            or persona_choices.get("realizationFamily")
        )
        realization_variant = (
            payload.get("realizationVariant")
            or response_trace.get("realizationVariant")
            or persona_choices.get("realizationVariant")
        )
        semantic_variant_id = payload.get("semanticVariantID")
        phrase_id = payload.get("phraseID")
        fallback_reason = (
            payload.get("fallbackReason")
            or response_trace.get("fallbackReason")
            or persona_choices.get("realizationFallbackReason")
        )
        family_address = response_trace.get("familyAddress") or (payload.get("args") or {}).get("familyAddress")

        # Determine planned surface
        eff_planned_surface = (
            planned_surface
            or (input_spec.get("surface") if input_spec else None)
            or (f"scenario.rootChoice:{input_spec.get('rootChoice')}" if input_spec and input_spec.get("rootChoice") else None)
            or (f"scenario.utterance:{input_spec.get('text')}" if input_spec and input_spec.get("text") else None)
            or (f"scenario.utterance:{record.get('input')}" if record.get("input") else "unknown_surface")
        )

        # Determine reached route
        if (
            semantic_template_id == "semantic.ask_clarification"
            or translation_key == "semantic.ask_clarification"
            or rendered_key == "semantic.ask_clarification"
            or final_text == "I'm not sure what you mean."
        ):
            reached_route = "semantic.ask_clarification"
        else:
            reached_route = str(
                semantic_variant_id
                or semantic_template_id
                or render_template_id
                or payload.get("phraseSemanticTemplateID")
                or translation_key
                or "semantic.unknown_route"
            )

        # Classify surface status
        eff_expect_fallback = expect_fallback or (input_spec.get("expect_fallback", False) if input_spec else False)
        eff_surface_missing = surface_missing or (input_spec.get("surface_missing", False) if input_spec else False)

        if eff_surface_missing:
            surface_status = "INVALID_SURFACE"
        elif eff_expect_fallback:
            surface_status = "EXPECTED_FALLBACK" if reached_route == "semantic.ask_clarification" else "MATCHED"
        elif reached_route == "semantic.ask_clarification":
            surface_status = "INVALID_SURFACE"
        else:
            surface_status = "MATCHED"

        initial_flags: list[dict[str, Any]] = []
        initial_cluster_keys: list[str] = []
        if surface_status == "INVALID_SURFACE":
            flag = QualityFlag(
                name="INVALID_SURFACE",
                severity="HIGH",
                confidence="DEFINITE",
                detail=f"Planned surface '{eff_planned_surface}' was missing or fell into clarification fallback '{reached_route}'",
            )
            initial_flags.append(flag.to_dict())
            initial_cluster_keys.append("invalid_surface")

        # Provenance resolution
        provenance = "UNKNOWN"
        selected_variant_id = None
        candidate_count = 0
        candidate_rejections: list[dict[str, Any]] = []
        best_match: dict[str, Any] | None = None

        plan_source_pool = None
        if isinstance(payload.get("plan"), dict) and payload["plan"].get("sourcePoolID"):
            plan_source_pool = payload["plan"]["sourcePoolID"]

        if worker is not None and hasattr(worker, "response_key_lookup"):
            lookup_keys = [
                k for k in [
                    semantic_variant_id,
                    semantic_template_id,
                    rendered_key,
                    plan_source_pool,
                ] if k
            ]
            for lk in lookup_keys:
                try:
                    lookup = worker.response_key_lookup(str(lk))
                except Exception:
                    lookup = None
                if lookup and isinstance(lookup, dict) and lookup.get("ok"):
                    matched = lookup.get("matches", [])
                    if matched:
                        candidate_count = lookup.get("matchCount", len(matched))
                        direct = [
                            row for row in matched
                            if row.get("matchKind") == "REGISTERED_VARIANT_ID"
                        ]
                        best_match = direct[0] if direct else matched[0]
                        if len(direct) == 1 and lookup.get("matchCount") == 1 and not lookup.get("truncated"):
                            provenance = "EXACT_EMITTED_VARIANT_ID"
                            selected_variant_id = direct[0].get("variantID")
                        elif direct:
                            provenance = "EXACT_EMITTED_VARIANT_ID"
                            selected_variant_id = direct[0].get("variantID")
                        else:
                            provenance = "TEMPLATE_CANDIDATES_ONLY"
                            selected_variant_id = best_match.get("variantID") or semantic_variant_id
                        break

        if provenance == "UNKNOWN" and semantic_variant_id:
            provenance = "EXACT_EMITTED_VARIANT_ID"
            selected_variant_id = semantic_variant_id

        # Canonical source ownership
        canonical_source = "UNKNOWN"
        if lineage_cache:
            for ck in [selected_variant_id, semantic_variant_id, semantic_template_id, rendered_key, plan_source_pool]:
                if ck and str(ck) in lineage_cache:
                    canonical_source = lineage_cache[str(ck)]
                    break

        if canonical_source == "UNKNOWN" and best_match:
            src_path = best_match.get("sourcePath")
            var_id = str(best_match.get("variantID") or selected_variant_id or semantic_variant_id or "")
            if src_path and src_path != "UNKNOWN":
                if ".dataset." in var_id:
                    parts = var_id.split(".dataset.")[0].split(".")
                    topic = parts[-1] if parts else "dialogue"
                    canonical_source = f"dialogue_dataset.{topic}"
                else:
                    canonical_source = Path(src_path).name

        if canonical_source == "UNKNOWN":
            if (
                reached_route == "semantic.ask_clarification"
                or semantic_template_id == "semantic.ask_clarification"
                or rendered_key == "semantic.ask_clarification"
                or final_text == "I'm not sure what you mean."
            ):
                canonical_source = "core.fallback"
            elif payload.get("contentOwner"):
                canonical_source = str(payload.get("contentOwner"))
            elif payload.get("domain") == "pnc.system.shared.categories" or str(rendered_key or "").startswith("response."):
                canonical_source = "categories.json"
            elif semantic_variant_id and ".dataset." in str(semantic_variant_id):
                parts = str(semantic_variant_id).split(".dataset.")[0].split(".")
                canonical_source = f"dialogue_dataset.{parts[-1] if parts else 'dialogue'}"
            elif semantic_template_id and ".dataset." in str(semantic_template_id):
                parts = str(semantic_template_id).split(".dataset.")[0].split(".")
                canonical_source = f"dialogue_dataset.{parts[-1] if parts else 'dialogue'}"

        row_id = f"{case_id}:{turn_index}:{msg_idx}"

        row: dict[str, Any] = {
            "schema": EVIDENCE_SCHEMA_V1,
            "schemaVersion": 1,
            "rowID": row_id,
            "identity": {
                "sweepID": sweep_id,
                "caseID": case_id,
                "batchID": batch_id,
                "strategy": strategy,
                "turnIndex": turn_index,
                "messageIndex": msg_idx,
                "speaker": "npc",
                "language": language,
                "salt": salt,
                "historyMode": history_mode,
                "plannedSurface": eff_planned_surface,
                "reachedSurface": reached_route,
                "surfaceStatus": surface_status,
                "input": {
                    "text": input_spec.get("text") or record.get("input") if input_spec else record.get("input"),
                    "rootChoice": input_spec.get("rootChoice") if input_spec else None,
                    "suggestionClick": input_spec.get("suggestionClick") if input_spec else None,
                    "action": input_spec.get("action") if input_spec else None,
                },
            },
            "trigger": {
                "parameters": params,
                "personaSummary": persona_summary,
                "relationshipSummary": relationship_summary,
                "stateSummary": state_summary,
                "actorSummary": actor_summary,
            },
            "semanticPath": {
                "intent": semantic.get("intent"),
                "speechAct": semantic.get("speechAct"),
                "subject": semantic.get("subject"),
                "flowID": view.get("selectedFlow", {}).get("id") if isinstance(view.get("selectedFlow"), dict) else None,
                "policyBranch": view.get("dialoguePlan", {}).get("policyBranch") if isinstance(view.get("dialoguePlan"), dict) else None,
                "semanticTemplateID": str(semantic_template_id) if semantic_template_id else None,
                "renderTemplateID": str(render_template_id) if render_template_id else None,
                "semanticVariantID": str(semantic_variant_id) if semantic_variant_id else None,
                "realizationFamily": str(realization_family) if realization_family else None,
                "realizationVariant": str(realization_variant) if realization_variant else None,
                "phraseID": str(phrase_id) if phrase_id else None,
                "translationKey": str(translation_key) if translation_key else None,
                "familyAddress": str(family_address) if family_address else None,
                "reachedRoute": reached_route,
            },
            "output": {
                "finalText": final_text,
                "renderedKey": str(rendered_key) if rendered_key else None,
                "fallbackReason": str(fallback_reason) if fallback_reason else None,
                "recentResponses": [str(rendered_key)] if rendered_key else [],
            },
            "selectionProvenance": {
                "provenance": provenance,
                "selectedVariantID": str(selected_variant_id) if selected_variant_id else None,
                "candidateCount": candidate_count,
                "candidateRejectionReasons": candidate_rejections,
                "canonicalSourceOwner": canonical_source,
                "sourcePath": best_match.get("sourcePath") if best_match else None,
                "sourceKind": best_match.get("sourceKind") if best_match else None,
                "fingerprints": {
                    "catalogFingerprint": record.get("catalogFingerprint"),
                    "revision": record.get("revision"),
                },
            },
            "authority": authority_summary,
            "quality": {
                "flags": initial_flags,
                "clusterKeys": initial_cluster_keys,
                "reviewState": "FLAGGED" if initial_flags else "UNREVIEWED",
                "reviewNotes": None,
            },
            "traceHandle": {
                "caseID": case_id,
                "turnIndex": turn_index,
                "lazy": True,
                "catalogFingerprint": record.get("catalogFingerprint"),
                "revision": record.get("revision"),
            },
        }
        rows.append(row)

    return rows


def resolve_trace_handle(
    trace_handle: Mapping[str, Any],
    *,
    worker: Any | None = None,
    parameters: Mapping[str, Any] | None = None,
    input_spec: Mapping[str, Any] | None = None,
    language: str = "EN",
    inventory: Any | None = None,
    traces_dir: Path | str | None = None,
) -> dict[str, Any]:
    """Resolve a compact row's lazy trace handle into full Conversation Inspector view."""
    case_id = str(trace_handle.get("caseID") or "unknown")
    turn_index = int(trace_handle.get("turnIndex", 0))

    if traces_dir:
        trace_path = Path(traces_dir) / f"{case_id}_turn-{turn_index}.json"
        if trace_path.exists():
            with open(trace_path, "r", encoding="utf-8") as f:
                cached_record = json.load(f)
            return build_conversation_inspector(cached_record)

    if worker is None:
        raise ValueError("Cannot resolve trace handle: neither cached trace file nor worker was provided.")

    expected_fp = trace_handle.get("catalogFingerprint")
    if expected_fp and hasattr(worker, "simulation_control_catalog"):
        current_fp = worker.simulation_control_catalog().get("catalogFingerprint")
        if current_fp and current_fp != expected_fp:
            return {
                "stale": True,
                "staleReason": f"Catalog fingerprint changed (recorded: {expected_fp}, current: {current_fp})",
                "caseID": case_id,
                "turnIndex": turn_index,
            }

    if hasattr(worker, "set_language"):
        worker.set_language(language)

    text_input = (input_spec.get("text") or "hello") if input_spec else "hello"
    root_choice = input_spec.get("rootChoice") if input_spec else None
    suggestion_frame = input_spec.get("suggestionClick") if input_spec else None

    if root_choice:
        worker.open_conversation()
        view = worker.conversation_projection()
        rows = ((view.get("presentation") or {}).get("responseChannel") or {}).get("rows") or []
        matched = None
        for r in rows:
            rid = str(r.get("id") or "")
            ext = (r.get("frame") or {}).get("extensions") or {}
            if (
                rid == root_choice
                or rid.endswith(":" + root_choice)
                or ext.get("actionID") == root_choice
                or ext.get("rootChoiceID") == root_choice
                or ("orders" in rid and root_choice in ("orders", "companion_orders"))
            ):
                matched = r
                break
        if matched and "frame" in matched:
            record = worker.suggestion_click(matched["frame"])
        else:
            record = worker.input(f"root:{root_choice}")
    elif suggestion_frame:
        record = worker.suggestion_click(suggestion_frame)
    else:
        record = worker.input(text_input)

    return build_conversation_inspector(record)


def validate_evidence_row(row: Mapping[str, Any]) -> None:
    """Validate that an evidence row conforms to EVIDENCE_SCHEMA_V1."""
    if not isinstance(row, Mapping):
        raise ValueError("Evidence row must be a dictionary")
    schema = row.get("schema")
    if schema not in ALLOWED_EVIDENCE_SCHEMAS:
        raise ValueError(f"Evidence schema '{schema}' is not supported. Expected {EVIDENCE_SCHEMA_V1}")
    if row.get("schemaVersion") != 1:
        raise ValueError(f"Evidence schemaVersion must be 1, got {row.get('schemaVersion')}")
    if not row.get("rowID"):
        raise ValueError("Evidence row must have a non-empty rowID")

    for req_field in (
        "identity",
        "trigger",
        "semanticPath",
        "output",
        "selectionProvenance",
        "authority",
        "quality",
        "traceHandle",
    ):
        if req_field not in row or not isinstance(row[req_field], Mapping):
            raise ValueError(f"Evidence row missing or invalid required field '{req_field}'")

    if row["traceHandle"].get("lazy") is not True:
        raise ValueError("Evidence row traceHandle must have lazy=True")
