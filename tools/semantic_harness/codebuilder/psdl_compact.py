"""G8A: Compact PSDL authoring parser, predicate expression compiler, shallow defaults, and sidecar loader.

Compact PSDL (``psychopatz.psdl.v2``) is an authoring representation only.
It expands deterministically into the explicit canonical ``psychopatz.convo-engine.v1``
document and Semantic Dialogue IR without creating a second semantic model.
"""

from __future__ import annotations

import copy
import json
import re
from collections.abc import Callable, Mapping
from pathlib import Path
from typing import Any

from .errors import CompileError
from .semantic_dialogue_ir import CONVO_ENGINE_SCHEMA, validate_context_path


COMPACT_PSDL_SCHEMA = "psychopatz.psdl.v2"
PACKAGE_DESCRIPTOR_SCHEMA = "psychopatz.psdl.package.v2"
PROVENANCE_LOCK_SCHEMA = "psychopatz.psdl.provenance.v1"

_IDENT_OR_PATH_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_.]*")
_NUMBER_RE = re.compile(r"-?(?:\d+\.\d+|\.\d+|\d+)")

_OP_MAP = {
    "==": "eq",
    "!=": "neq",
    ">=": "gte",
    "<=": "lte",
    ">": "gt",
    "<": "lt",
    "in": "in",
    "not_in": "not_in",
}


def _tokenize_expr(expr: str) -> list[tuple[str, str]]:
    tokens: list[tuple[str, str]] = []
    i = 0
    n = len(expr)
    while i < n:
        ch = expr[i]
        if ch.isspace():
            i += 1
            continue
        if expr.startswith("&&", i):
            tokens.append(("AND", "&&"))
            i += 2
            continue
        if expr.startswith("||", i):
            tokens.append(("OR", "||"))
            i += 2
            continue
        for two in ("==", "!=", ">=", "<="):
            if expr.startswith(two, i):
                tokens.append(("OP", two))
                i += 2
                break
        else:
            if ch in (">", "<"):
                tokens.append(("OP", ch))
                i += 1
                continue
            if ch == "!":
                tokens.append(("NOT", "!"))
                i += 1
                continue
            if ch in ("(", ")", "[", "]", ","):
                tokens.append((ch, ch))
                i += 1
                continue
            if ch in ('"', "'"):
                quote = ch
                i += 1
                buf: list[str] = []
                while i < n and expr[i] != quote:
                    if expr[i] == "\\" and i + 1 < n:
                        i += 1
                        buf.append(expr[i])
                    else:
                        buf.append(expr[i])
                    i += 1
                if i >= n or expr[i] != quote:
                    raise CompileError(f"Unterminated string literal in predicate {expr!r}")
                i += 1
                tokens.append(("STR", "".join(buf)))
                continue
            m_num = _NUMBER_RE.match(expr, i)
            if m_num:
                tokens.append(("NUM", m_num.group(0)))
                i = m_num.end()
                continue
            m_id = _IDENT_OR_PATH_RE.match(expr, i)
            if m_id:
                word = m_id.group(0)
                if word in ("in", "not_in"):
                    tokens.append(("OP", word))
                elif word == "exists":
                    tokens.append(("EXISTS", word))
                elif word in ("true", "false"):
                    tokens.append(("BOOL", word))
                else:
                    tokens.append(("IDENT", word))
                i = m_id.end()
                continue
            raise CompileError(f"Unexpected character {ch!r} in predicate {expr!r}")
    return tokens


class _PredicateParser:
    def __init__(self, tokens: list[tuple[str, str]], raw: str, label: str) -> None:
        self.tokens = tokens
        self.pos = 0
        self.raw = raw
        self.label = label

    def peek(self) -> tuple[str, str] | None:
        return self.tokens[self.pos] if self.pos < len(self.tokens) else None

    def consume(self, expected_kind: str | None = None) -> tuple[str, str]:
        tok = self.peek()
        if tok is None:
            raise CompileError(f"{self.label}: unexpected end of predicate {self.raw!r}")
        if expected_kind is not None and tok[0] != expected_kind:
            raise CompileError(
                f"{self.label}: expected {expected_kind}, got {tok[1]!r} in {self.raw!r}"
            )
        self.pos += 1
        return tok

    def parse_or(self) -> dict[str, Any]:
        items = [self.parse_and()]
        while self.peek() and self.peek()[0] == "OR":
            self.consume("OR")
            items.append(self.parse_and())
        return items[0] if len(items) == 1 else {"any": items}

    def parse_and(self) -> dict[str, Any]:
        items = [self.parse_unary()]
        while self.peek() and self.peek()[0] == "AND":
            self.consume("AND")
            items.append(self.parse_unary())
        return items[0] if len(items) == 1 else {"all": items}

    def parse_unary(self) -> dict[str, Any]:
        if self.peek() and self.peek()[0] == "NOT":
            self.consume("NOT")
            return {"not": self.parse_unary()}
        if self.peek() and self.peek()[0] == "(":
            self.consume("(")
            inner = self.parse_or()
            self.consume(")")
            return inner
        return self.parse_atom()

    def parse_value(self) -> Any:
        tok = self.peek()
        if tok is None:
            raise CompileError(f"{self.label}: expected value in predicate {self.raw!r}")
        kind, val = tok
        if kind == "NUM":
            self.consume("NUM")
            return float(val) if "." in val else int(val)
        if kind == "BOOL":
            self.consume("BOOL")
            return val == "true"
        if kind in ("STR", "IDENT"):
            self.consume(kind)
            return val
        raise CompileError(f"{self.label}: invalid literal {val!r} in {self.raw!r}")

    def parse_list(self) -> list[Any]:
        self.consume("[")
        values: list[Any] = []
        if self.peek() and self.peek()[0] != "]":
            values.append(self.parse_value())
            while self.peek() and self.peek()[0] == ",":
                self.consume(",")
                values.append(self.parse_value())
        self.consume("]")
        if not values:
            raise CompileError(f"{self.label}: list in predicate {self.raw!r} cannot be empty")
        return values

    def parse_atom(self) -> dict[str, Any]:
        _, path = self.consume("IDENT")
        validate_context_path(path, f"{self.label}.path")
        nxt = self.peek()
        if nxt is None or nxt[0] in ("AND", "OR", ")"):
            return {"op": "truthy", "path": path}
        if nxt[0] == "EXISTS":
            self.consume("EXISTS")
            return {"op": "exists", "path": path}
        if nxt[0] == "OP":
            _, op_tok = self.consume("OP")
            op = _OP_MAP[op_tok]
            if op in ("in", "not_in"):
                return {"op": op, "path": path, "values": self.parse_list()}
            return {"op": op, "path": path, "value": self.parse_value()}
        raise CompileError(
            f"{self.label}: unexpected token {nxt[1]!r} after {path!r} in {self.raw!r}"
        )


def parse_predicate_expr(value: Any, label: str = "predicate") -> Any:
    """Compile a compact predicate string into the canonical predicate AST."""
    if value is None or isinstance(value, Mapping):
        return value
    if not isinstance(value, str) or not value.strip():
        raise CompileError(f"{label} must be a predicate object or non-empty expression string")
    tokens = _tokenize_expr(value)
    if not tokens:
        raise CompileError(f"{label} expression is empty")
    parser = _PredicateParser(tokens, value, label)
    ast = parser.parse_or()
    if parser.peek() is not None:
        raise CompileError(
            f"{label}: unexpected trailing token {parser.peek()[1]!r} in {value!r}"
        )
    return ast


def validate_package_descriptor(doc: Mapping[str, Any]) -> dict[str, Any]:
    """Validate a compact shallow package descriptor (no deep inheritance)."""
    if not isinstance(doc, Mapping):
        raise CompileError("Package descriptor must be a JSON object")
    schema = doc.get("schema")
    if schema != PACKAGE_DESCRIPTOR_SCHEMA:
        raise CompileError(
            f"Invalid package descriptor schema {schema!r}; expected {PACKAGE_DESCRIPTOR_SCHEMA!r}"
        )
    if "extends" in doc or "inherits" in doc:
        raise CompileError("Package descriptors must not use inheritance chains (extends/inherits)")
    defaults = doc.get("defaults") or {}
    if not isinstance(defaults, Mapping):
        raise CompileError("Package descriptor defaults must be an object")
    profiles = doc.get("profiles") or {}
    if not isinstance(profiles, Mapping):
        raise CompileError("Package descriptor profiles must be an object")
    for name, profile in profiles.items():
        if not isinstance(profile, Mapping):
            raise CompileError(f"Package profile {name!r} must be an object")
        if "extends" in profile or "inherits" in profile or "profile" in profile:
            raise CompileError(
                f"Package profile {name!r} must be shallow (no nested profile/extends/inherits)"
            )
    return copy.deepcopy(dict(doc))


def split_manifest_and_provenance(
    manifest_doc: Mapping[str, Any],
) -> tuple[dict[str, Any], dict[str, Any]]:
    """Split a legacy manifest into a compact package descriptor + provenance lock."""
    pkg: dict[str, Any] = {
        "schema": PACKAGE_DESCRIPTOR_SCHEMA,
        "version": manifest_doc.get("version", 1),
        "package": manifest_doc.get("registryOwner") or manifest_doc.get("defaultOwner") or "PsychopatzCore",
        "defaultOwner": manifest_doc.get("defaultOwner") or "PsychopatzCore",
        "registryOwner": manifest_doc.get("registryOwner") or manifest_doc.get("defaultOwner") or "PsychopatzCore",
        "defaults": {
            "participants": {"speaker": ["participant"], "addressee": ["participant"]},
        },
        "profiles": {
            "social_beat": {
                "kind": "beat",
                "stimuli": ["HUMAN_UTTERANCE", "NPC_SEMANTIC_ACT"],
            },
            "social_behavior": {
                "kind": "behavior",
                "mode": "beat",
                "stimuli": ["HUMAN_UTTERANCE", "NPC_SEMANTIC_ACT"],
                "requiredCapabilities": ["speech"],
            },
        },
    }
    for key in (
        "sourceRoots",
        "externalSourceRoots",
        "auxiliaryRoots",
        "externalReferences",
        "requiredCapabilities",
        "imports",
    ):
        if key in manifest_doc:
            pkg[key] = copy.deepcopy(manifest_doc[key])

    provenance: dict[str, Any] = {
        "schema": PROVENANCE_LOCK_SCHEMA,
        "version": 1,
        "sourceProfiles": copy.deepcopy(manifest_doc.get("sourceProfiles") or {}),
    }
    return pkg, provenance


def _infer_kind_and_ns(
    raw_id: str,
    explicit_kind: Any,
    explicit_ns: Any,
    profile_data: Mapping[str, Any],
) -> tuple[str, str | None, str]:
    kind = explicit_kind or profile_data.get("kind")
    if not kind:
        if raw_id.startswith("behavior."):
            kind = "behavior"
        elif raw_id.startswith("beat."):
            kind = "beat"
        elif raw_id.startswith("lexeme.") or raw_id.startswith("construction."):
            kind = "realization"
        else:
            kind = "dialogue"

    if isinstance(explicit_ns, str) and explicit_ns.strip():
        return str(kind), explicit_ns.strip(), raw_id

    if "." in raw_id:
        ns, leaf = raw_id.rsplit(".", 1)
        return str(kind), ns, leaf
    return str(kind), None, raw_id


def _expand_predicates_in_tree(node: Any, label: str) -> Any:
    if isinstance(node, list):
        return [_expand_predicates_in_tree(item, f"{label}[{i}]") for i, item in enumerate(node)]
    if not isinstance(node, Mapping):
        return node
    out: dict[str, Any] = {}
    for k, v in node.items():
        if k in ("when", "entry", "maintain", "exit") and isinstance(v, str):
            out[k] = parse_predicate_expr(v, f"{label}.{k}")
        else:
            out[k] = _expand_predicates_in_tree(v, f"{label}.{k}")
    return out


def expand_compact_psdl_document(
    document: Mapping[str, Any],
    *,
    package: Mapping[str, Any] | None = None,
    text_loader: Callable[[str], Mapping[str, Any]] | None = None,
) -> dict[str, Any]:
    """Expand a compact PSDL document into an explicit ``psychopatz.convo-engine.v1`` document.

    Passes through existing ``psychopatz.convo-engine.v1`` / legacy documents unchanged
    unless they contain compact fields (``profile``, string predicates, keyed ``candidates``,
    or ``textSidecars``).
    """
    if not isinstance(document, Mapping):
        raise CompileError("PSDL document must be an object")

    schema = document.get("schema")
    is_compact = schema == COMPACT_PSDL_SCHEMA or "profile" in document or "textSidecars" in document
    if not is_compact and schema is not None and schema != COMPACT_PSDL_SCHEMA:
        # Still allow compact predicate / candidate sugar if present, otherwise return copy
        if isinstance(document.get("records"), list):
            return copy.deepcopy(dict(document))

    pkg = validate_package_descriptor(package) if package is not None else {}
    pkg_defaults = dict(pkg.get("defaults") or {})
    profile_name = document.get("profile")
    profile_data: dict[str, Any] = {}
    if profile_name is not None:
        if not isinstance(profile_name, str) or not profile_name.strip():
            raise CompileError("PSDL profile must be a non-empty string")
        profiles = pkg.get("profiles") or {}
        if profile_name not in profiles:
            raise CompileError(f"Unknown PSDL profile {profile_name!r}")
        profile_data = dict(profiles[profile_name])

    merged_defaults = {**pkg_defaults, **profile_data}
    merged_defaults.pop("kind", None)

    doc = copy.deepcopy(dict(document))
    doc.pop("profile", None)

    # Apply shallow defaults (only keys not explicitly overridden locally)
    for k, v in merged_defaults.items():
        if k not in doc:
            doc[k] = copy.deepcopy(v)

    if "owner" not in doc and pkg.get("defaultOwner"):
        doc["owner"] = pkg["defaultOwner"]

    raw_id = doc.get("id")
    if isinstance(raw_id, str) and raw_id.strip():
        kind, ns, leaf_id = _infer_kind_and_ns(
            raw_id.strip(),
            doc.get("kind"),
            doc.get("namespace"),
            profile_data,
        )
        doc["kind"] = kind
        doc["id"] = leaf_id
        if ns is not None:
            doc["namespace"] = ns

    # Dialogue doesn't use top-level participants if omitted and kind != dialogue?
    # Wait: behavior/beat do NOT allow `participants` in PSDL_RECORD_FIELDS?
    # Let's check: PSDL_RECORD_FIELDS allows `participants` on all kinds, or keep it only for dialogue/realization
    if doc.get("kind") in ("behavior", "beat", "realization") and "participants" in doc and "participants" not in document:
        doc.pop("participants", None)

    # Expand keyed candidates map -> ordered list of {behavior, relevance}
    if isinstance(doc.get("candidates"), Mapping):
        doc["candidates"] = [
            {"behavior": str(beh_id), "relevance": rel}
            for beh_id, rel in doc["candidates"].items()
        ]

    # Expand family-owned text sidecars
    sidecars = doc.pop("textSidecars", None)
    if sidecars is not None:
        if not isinstance(sidecars, Mapping):
            raise CompileError("textSidecars must be a map of {locale: relativePath}")
        if text_loader is None:
            raise CompileError("textSidecars requires a sidecar loader")
        loaded_by_locale: dict[str, Mapping[str, Any]] = {}
        for lang, rel_path in sorted(sidecars.items()):
            loaded_by_locale[str(lang).upper()] = text_loader(str(rel_path))
        # Merge sidecar wording into say.variants / translations
        if any("variants" in sc for sc in loaded_by_locale.values() if isinstance(sc, Mapping)):
            by_var: dict[str, dict[str, Any]] = {}
            for lang, sc in loaded_by_locale.items():
                for var_id, txt in (sc.get("variants") or {}).items():
                    by_var.setdefault(str(var_id), {})[lang] = txt
            existing_variants = (doc.get("say") or {}).get("variants") or []
            if existing_variants:
                for v in existing_variants:
                    vid = str(v.get("id") or "")
                    if vid in by_var:
                        v["text"] = by_var[vid]
            else:
                doc["say"] = {
                    "variants": [
                        {"id": vid, "text": lang_map}
                        for vid, lang_map in by_var.items()
                    ]
                }
        elif any("reply" in sc for sc in loaded_by_locale.values() if isinstance(sc, Mapping)):
            reply_doc = doc.setdefault("reply", {})
            for outcome, outcome_payload in reply_doc.items():
                if not isinstance(outcome_payload, dict):
                    continue
                say_block = outcome_payload.get("say")
                if not isinstance(say_block, dict):
                    continue
                for turn_key, turn_payload in say_block.items():
                    if not isinstance(turn_payload, dict):
                        continue
                    variants = turn_payload.get("variants")
                    if not isinstance(variants, list):
                        continue
                    for variant in variants:
                        if not isinstance(variant, dict):
                            continue
                        vid = str(variant.get("id") or "")
                        lang_map: dict[str, Any] = {}
                        for lang, sc in loaded_by_locale.items():
                            sc_turn = ((sc.get("reply") or {}).get(outcome) or {}).get(str(turn_key)) or {}
                            if vid in sc_turn:
                                lang_map[lang] = sc_turn[vid]
                        if lang_map:
                            variant["text"] = lang_map
        elif any("translations" in sc for sc in loaded_by_locale.values() if isinstance(sc, Mapping)):
            merged_tr: dict[str, Any] = {}
            for lang, sc in loaded_by_locale.items():
                merged_tr[lang] = sc["translations"]
            doc["translations"] = merged_tr

    doc = _expand_predicates_in_tree(doc, str(doc.get("id") or "psdl"))
    doc["_authoringSchema"] = str(schema or COMPACT_PSDL_SCHEMA)
    doc["schema"] = CONVO_ENGINE_SCHEMA
    return doc


__all__ = [
    "COMPACT_PSDL_SCHEMA",
    "PACKAGE_DESCRIPTOR_SCHEMA",
    "PROVENANCE_LOCK_SCHEMA",
    "expand_compact_psdl_document",
    "parse_predicate_expr",
    "split_manifest_and_provenance",
    "validate_package_descriptor",
]
