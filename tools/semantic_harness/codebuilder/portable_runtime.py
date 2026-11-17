"""G8B & G8E: Target-neutral Portable Dialogue Plan IR and versioned Python Reference VM.

Standard runtime owns:
- predicate evaluation
- exact / morphological / fuzzy recognition (named policies: exact, tolerant, safe_recovered)
- beat director (entry, maintain, exit, cooldownTurns, maxTurns, candidate relevance)
- behavior director (when, baseRelevance, modifiers, requiredCapabilities, outputs)
- realization selection (locale + style + anti-repeat history)
- generic action / result outcome lifecycle
"""

from __future__ import annotations

import copy
import re
from collections.abc import Callable, Mapping, Sequence
from typing import Any

from .errors import CompileError


PORTABLE_PLAN_SCHEMA = "psychopatz.psdl.portable-plan.v1"
STANDARD_RUNTIME_VERSION = "1.0.0"

_RECOGNITION_POLICIES = frozenset({"exact", "tolerant", "safe_recovered"})
_IR_TOP_KEYS = (
    "schema",
    "canonicalIRVersion",
    "participants",
    "roles",
    "participantSet",
    "namespace",
    "localID",
    "target",
    "slots",
    "references",
    "lineage",
    "sourcePath",
    "sourceSchema",
    "source",
)
_TOKEN_RE = re.compile(r"[a-z0-9']+")


def _normalize_tokens(text: str) -> list[str]:
    return _TOKEN_RE.findall(str(text or "").lower())


def _levenshtein(a: str, b: str) -> int:
    if a == b:
        return 0
    if not a:
        return len(b)
    if not b:
        return len(a)
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        curr = [i]
        for j, cb in enumerate(b, 1):
            cost = 0 if ca == cb else 1
            curr.append(min(prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost))
        prev = curr
    return prev[-1]


def _resolve_path(context: Mapping[str, Any], path: str) -> Any:
    cursor: Any = context
    for part in str(path).split("."):
        if isinstance(cursor, Mapping) and part in cursor:
            cursor = cursor[part]
        else:
            return None
    return cursor


def evaluate_predicate(predicate: Any, context: Mapping[str, Any]) -> bool:
    """Evaluate a canonical predicate AST against a runtime context."""
    if predicate is None:
        return True
    if not isinstance(predicate, Mapping):
        raise CompileError("Predicate must be a mapping")
    if "all" in predicate:
        return all(evaluate_predicate(child, context) for child in predicate["all"])
    if "any" in predicate:
        return any(evaluate_predicate(child, context) for child in predicate["any"])
    if "not" in predicate:
        return not evaluate_predicate(predicate["not"], context)

    path = predicate.get("path") or predicate.get("field")
    op = predicate.get("op", "eq")
    actual = _resolve_path(context, str(path or ""))
    if op == "exists":
        return actual is not None
    if op == "truthy":
        return bool(actual)
    if op == "eq":
        return actual == predicate.get("value")
    if op == "neq":
        return actual != predicate.get("value")
    if op in ("gt", "gte", "lt", "lte"):
        expected = predicate.get("value")
        if actual is None or expected is None:
            return False
        if op == "gt":
            return actual > expected
        if op == "gte":
            return actual >= expected
        if op == "lt":
            return actual < expected
        return actual <= expected
    if op == "in":
        return actual in (predicate.get("values") or [])
    if op == "not_in":
        return actual not in (predicate.get("values") or [])
    raise CompileError(f"Unsupported predicate op {op!r}")


def _expand_match_tokens(match: Sequence[Any], concept_map: Mapping[str, list[str]]) -> list[str]:
    """Expand a structured match token sequence (literals + @CONCEPT) into flat phrases."""
    phrases = [""]
    for tok in match:
        options: list[str] = []
        if isinstance(tok, str):
            if tok.startswith("@"):
                cid = tok[1:].strip().lower()
                options = list(concept_map.get(cid) or [tok])
            else:
                options = [tok]
        elif isinstance(tok, Mapping):
            kind = tok.get("kind")
            if kind == "concept":
                cid = str(tok.get("id") or "").strip().lower()
                options = list(concept_map.get(cid) or [])
            elif kind == "literal":
                val = str(tok.get("value") or "")
                options = [val]
                if tok.get("optional"):
                    options.append("")
        if not options:
            continue
        next_phrases: list[str] = []
        for prefix in phrases:
            for opt in options:
                joined = f"{prefix} {opt}".strip() if prefix and opt else (prefix or opt)
                next_phrases.append(joined)
                if len(next_phrases) >= 256:
                    break
            if len(next_phrases) >= 256:
                break
        phrases = next_phrases
    return [p for p in phrases if p]


def compile_portable_plan(
    records: Sequence[Mapping[str, Any]],
    *,
    package: str = "default",
) -> dict[str, Any]:
    """Compile canonical PSDL IR records into a target-neutral Portable Dialogue Plan JSON."""
    dialogues: dict[str, dict[str, Any]] = {}
    behaviors: dict[str, dict[str, Any]] = {}
    beats: dict[str, dict[str, Any]] = {}
    realizations: dict[str, dict[str, Any]] = {}
    recognition_rules: list[dict[str, Any]] = []

    for rec in records:
        rec_id = str(rec.get("id") or "")
        kind = rec.get("kind")
        payload = copy.deepcopy(rec.get("payload") or {})
        entry = {
            "id": rec_id,
            "kind": kind,
            "owner": rec.get("owner"),
            "when": copy.deepcopy(rec.get("when")),
            **payload,
        }
        for top_key in _IR_TOP_KEYS:
            if top_key in rec and rec[top_key] is not None:
                entry[top_key] = copy.deepcopy(rec[top_key])
        if kind == "dialogue":
            dialogues[rec_id] = entry
            recog = payload.get("recognition")
            if isinstance(recog, Mapping):
                concept_map = {
                    str(c.get("id") or "").strip().lower(): [str(a) for a in (c.get("aliases") or [])]
                    for c in (recog.get("concepts") or [])
                    if isinstance(c, Mapping) and c.get("id")
                }
                for pat in recog.get("patterns") or []:
                    if isinstance(pat, Mapping):
                        flat_patterns = list(pat.get("patterns") or pat.get("phrases") or [])
                        if not flat_patterns and isinstance(pat.get("match"), list):
                            flat_patterns = _expand_match_tokens(pat["match"], concept_map)
                        recognition_rules.append({
                            "id": pat.get("id") or rec_id,
                            "dialogueID": rec_id,
                            "policy": pat.get("policy") or recog.get("policy") or "exact",
                            "mutating": bool(pat.get("mutating") or payload.get("action")),
                            "patterns": flat_patterns,
                            "semantic": copy.deepcopy(pat.get("semantic") or pat.get("emit") or {}),
                        })
            meta = payload.get("metadata")
            if isinstance(meta, Mapping) and isinstance(meta.get("utterances"), Mapping):
                positives = meta["utterances"].get("positives") or []
                if positives:
                    recognition_rules.append({
                        "id": rec_id,
                        "dialogueID": rec_id,
                        "policy": meta.get("recognitionPolicy") or "tolerant",
                        "mutating": bool(payload.get("action") or meta.get("capability")),
                        "patterns": list(positives),
                        "semantic": copy.deepcopy(meta.get("emit") or {}),
                    })
        elif kind == "behavior":
            behaviors[rec_id] = entry
        elif kind == "beat":
            beats[rec_id] = entry
        elif kind == "realization":
            realizations[rec_id] = entry

    recognition_rules.sort(key=lambda item: str(item.get("id") or ""))
    return {
        "schema": PORTABLE_PLAN_SCHEMA,
        "runtimeVersion": STANDARD_RUNTIME_VERSION,
        "package": package,
        "dialogues": {k: dialogues[k] for k in sorted(dialogues)},
        "behaviors": {k: behaviors[k] for k in sorted(behaviors)},
        "beats": {k: beats[k] for k in sorted(beats)},
        "realizations": {k: realizations[k] for k in sorted(realizations)},
        "recognitionRules": recognition_rules,
    }


def portable_plan_records(plan: Mapping[str, Any]) -> list[dict[str, Any]]:
    """Reconstruct canonical IR record envelopes from a validated Portable Dialogue Plan."""
    if plan.get("schema") != PORTABLE_PLAN_SCHEMA:
        raise CompileError(f"Unsupported portable plan schema: {plan.get('schema')!r}")
    records: list[dict[str, Any]] = []
    for section, default_kind in (
        ("behaviors", "behavior"),
        ("beats", "beat"),
        ("dialogues", "dialogue"),
        ("realizations", "realization"),
    ):
        bucket = plan.get(section) or {}
        if not isinstance(bucket, Mapping):
            continue
        for rec_id in sorted(bucket):
            entry = copy.deepcopy(dict(bucket[rec_id]))
            kind = str(entry.pop("kind", None) or default_kind)
            owner = entry.pop("owner", None)
            when = entry.pop("when", None)
            entry_id = str(entry.pop("id", None) or rec_id)
            rec: dict[str, Any] = {
                "id": entry_id,
                "kind": kind,
                "owner": owner,
                "when": when,
            }
            for top_key in _IR_TOP_KEYS:
                if top_key in entry:
                    rec[top_key] = entry.pop(top_key)
            rec["payload"] = entry
            records.append(rec)
    records.sort(key=lambda item: item["id"])
    return records


class PortableReferenceVM:
    """Versioned standard-runtime reference VM executing Portable Dialogue Plan JSON."""

    def __init__(
        self,
        plan: Mapping[str, Any],
        *,
        capability_adapter: Callable[[str, Mapping[str, Any], Mapping[str, Any]], Mapping[str, Any]] | None = None,
    ) -> None:
        if plan.get("schema") != PORTABLE_PLAN_SCHEMA:
            raise CompileError(f"Unsupported portable plan schema: {plan.get('schema')!r}")
        self.plan = copy.deepcopy(dict(plan))
        self.capability_adapter = capability_adapter
        self.active_beat: str | None = None
        self.beat_turns: int = 0
        self.beat_cooldowns: dict[str, int] = {}
        self.variant_history: dict[str, int] = {}

    def recognize(self, utterance: str, *, policy: str | None = None) -> dict[str, Any] | None:
        norm_input = " ".join(_normalize_tokens(utterance))
        if not norm_input:
            return None
        best: dict[str, Any] | None = None
        for rule in self.plan.get("recognitionRules") or []:
            rule_policy = policy or rule.get("policy") or "exact"
            if rule_policy not in _RECOGNITION_POLICIES:
                raise CompileError(f"Unsupported recognition policy: {rule_policy!r}")
            for pat in rule.get("patterns") or []:
                norm_pat = " ".join(_normalize_tokens(str(pat)))
                if not norm_pat:
                    continue
                if norm_input == norm_pat:
                    return {
                        "ruleID": rule["id"],
                        "dialogueID": rule["dialogueID"],
                        "mode": "exact",
                        "confidence": 1.0,
                        "requiresConfirmation": False,
                        "semantic": copy.deepcopy(rule.get("semantic") or {}),
                    }
                if rule_policy in ("tolerant", "safe_recovered"):
                    dist = _levenshtein(norm_input, norm_pat)
                    max_len = max(len(norm_input), len(norm_pat))
                    sim = 1.0 - (dist / max_len)
                    if dist <= 2 and sim >= 0.75:
                        cand = {
                            "ruleID": rule["id"],
                            "dialogueID": rule["dialogueID"],
                            "mode": "fuzzy",
                            "confidence": round(sim, 3),
                            "requiresConfirmation": (rule_policy == "safe_recovered" and bool(rule.get("mutating"))),
                            "semantic": copy.deepcopy(rule.get("semantic") or {}),
                        }
                        if best is None or cand["confidence"] > best["confidence"]:
                            best = cand
        return best

    def _select_variant(self, dlg: Mapping[str, Any], *, locale: str, style: str, context: Mapping[str, Any]) -> str:
        say = dlg.get("say") or {}
        variants = say.get("variants") or []
        if not variants and isinstance(say.get("realizations"), Mapping):
            realizations = say["realizations"]
            key_order = say.get("keyOrder") if isinstance(say.get("keyOrder"), list) else sorted(realizations)
            if key_order and key_order[0] in realizations:
                variants = (realizations[key_order[0]] or {}).get("variants") or []
        if isinstance(say.get(locale), list) and say[locale]:
            lines = say[locale]
        elif isinstance(say.get("EN"), list) and say["EN"]:
            lines = say["EN"]
        else:
            chosen = next((v for v in variants if v.get("id") == style), variants[0] if variants else None)
            if not chosen:
                return ""
            txt = chosen.get("text") or {}
            raw_lines = txt.get(locale) or txt.get("EN") or [""]
            lines = raw_lines if isinstance(raw_lines, list) else [raw_lines]
        idx = self.variant_history.get(dlg["id"], 0) % len(lines)
        self.variant_history[dlg["id"]] = idx + 1
        return str(lines[idx])

    def step(
        self,
        *,
        utterance: str = "",
        context: Mapping[str, Any] | None = None,
        locale: str = "EN",
        style: str = "neutral",
    ) -> dict[str, Any]:
        ctx: dict[str, Any] = copy.deepcopy(dict(context or {}))
        for k in list(self.beat_cooldowns):
            if self.beat_cooldowns[k] > 0:
                self.beat_cooldowns[k] -= 1

        recog = self.recognize(utterance) if utterance else None
        if recog:
            stim = ctx.setdefault("stimulus", {})
            if isinstance(stim, dict):
                sem = stim.setdefault("semantic", {})
                if isinstance(sem, dict):
                    sem.update(recog["semantic"])

        # Beat lifecycle
        beats = self.plan.get("beats") or {}
        if self.active_beat and self.active_beat in beats:
            cur = beats[self.active_beat]
            self.beat_turns += 1
            beat_ctx = {**ctx, "beat": {"turnsInBeat": self.beat_turns}}
            should_exit = (
                (cur.get("exit") and evaluate_predicate(cur["exit"], beat_ctx))
                or (cur.get("maintain") and not evaluate_predicate(cur["maintain"], beat_ctx))
                or (cur.get("maxTurns") and self.beat_turns >= int(cur["maxTurns"]))
            )
            if should_exit:
                self.beat_cooldowns[self.active_beat] = int(cur.get("cooldownTurns") or 0)
                self.active_beat = None
                self.beat_turns = 0

        if self.active_beat is None:
            best_beat: tuple[float, str] | None = None
            for bid, beat in beats.items():
                if self.beat_cooldowns.get(bid, 0) > 0:
                    continue
                if beat.get("entry") and evaluate_predicate(beat["entry"], ctx):
                    score = float(beat.get("baseRelevance") or 0.0)
                    if best_beat is None or score > best_beat[0]:
                        best_beat = (score, bid)
            if best_beat is not None:
                self.active_beat = best_beat[1]
                self.beat_turns = 0

        # Behavior selection
        behaviors = self.plan.get("behaviors") or {}
        selected_behavior: str | None = None
        best_beh_score = -1e9
        candidate_list: list[tuple[str, float]] = []
        if self.active_beat and self.active_beat in beats:
            for c in beats[self.active_beat].get("candidates") or []:
                candidate_list.append((str(c["behavior"]), float(c.get("relevance") or 0.0)))
        else:
            for bid, beh in behaviors.items():
                candidate_list.append((bid, float(beh.get("baseRelevance") or 0.0)))

        for bid, base_rel in candidate_list:
            beh = behaviors.get(bid)
            if not beh:
                continue
            if not evaluate_predicate(beh.get("when"), ctx):
                continue
            score = base_rel
            for mod in beh.get("modifiers") or []:
                if evaluate_predicate(mod.get("when"), ctx):
                    score += float(mod.get("delta") or 0.0)
            if score > best_beh_score:
                best_beh_score = score
                selected_behavior = bid

        text = ""
        dialogue_id = recog["dialogueID"] if recog else None
        action_outcome: str | None = None
        if selected_behavior:
            speech_out = (behaviors[selected_behavior].get("outputs") or {}).get("speech") or {}
            tpl_id = speech_out.get("contentTemplateID")
            if tpl_id and tpl_id in (self.plan.get("dialogues") or {}):
                dialogue_id = tpl_id

        if dialogue_id and dialogue_id in (self.plan.get("dialogues") or {}):
            dlg = self.plan["dialogues"][dialogue_id]
            action = dlg.get("action")
            if isinstance(action, Mapping) and self.capability_adapter is not None:
                if recog and recog.get("requiresConfirmation"):
                    action_outcome = "confirmation_required"
                else:
                    res = self.capability_adapter(str(action.get("capability") or ""), action, ctx)
                    action_outcome = str(res.get("outcome") or "queued")
            reply = dlg.get("reply")
            if action_outcome and isinstance(reply, Mapping) and action_outcome in reply:
                branch = reply[action_outcome]
                text = self._select_variant({"id": f"{dialogue_id}.{action_outcome}", "say": branch.get("say") or {}}, locale=locale, style=style, context=ctx)
            else:
                text = self._select_variant(dlg, locale=locale, style=style, context=ctx)

        return {
            "runtimeVersion": STANDARD_RUNTIME_VERSION,
            "recognition": recog,
            "activeBeat": self.active_beat,
            "selectedBehavior": selected_behavior,
            "selectedDialogue": dialogue_id,
            "actionOutcome": action_outcome,
            "text": text,
        }


__all__ = [
    "PORTABLE_PLAN_SCHEMA",
    "PortableReferenceVM",
    "STANDARD_RUNTIME_VERSION",
    "compile_portable_plan",
    "evaluate_predicate",
]
