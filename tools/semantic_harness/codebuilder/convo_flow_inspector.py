"""Pure inspector for modular `.convo` scripts, flows, offers, and variants.

Used by the Semantic Harness "Convo Flows" tab (and CLI/tests) to display every
authored flow/beat/pool, its dynamic `offer` buttons, and all conditional `say`
variants sorted by priority without touching Tkinter.
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from .convo_dsl_integration import find_convo_scripts_root

_BLOCK_RE = re.compile(r"^\s*(pool|beat|flow)\s+([a-zA-Z0-9_.-]+)\s*$")
_LEX_RE = re.compile(r"^\s*lex\s+([a-zA-Z0-9_.-]+)\s*$")
_OFFER_RE = re.compile(r"^\s*offer\s+([a-zA-Z0-9_.-]+)\s*:\s*$")
_OFFER_FIELD_RE = re.compile(r"^\s{4,}([a-zA-Z0-9_]+)\s*:\s*(.+?)\s*$")
_SAY_RE = re.compile(
    r"^\s*say(?:\s+\[([^\]]*)\])?(?:\s*\(pri\s+(\d+)\))?(?:\s+as\s+([a-zA-Z0-9_.-]+))?\s*:\s*(.*)$"
)


def _strip_quotes(value: str) -> str:
    text = value.strip()
    if len(text) >= 2 and text[0] == '"' and text[-1] == '"':
        return text[1:-1]
    return text


def parse_convo_flows(path: Path, repo_root: Path | None = None) -> list[dict[str, Any]]:
    """Parse all `flow`, `beat`, and `pool` blocks from a `.convo` file."""
    rel = str(path.relative_to(repo_root)) if repo_root and path.is_relative_to(repo_root) else str(path)
    lang = path.parent.name.upper()
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    flows: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None
    current_offer: dict[str, Any] | None = None
    pending_say: dict[str, Any] | None = None
    in_lex = False

    def flush_say() -> None:
        nonlocal pending_say
        if current is not None and pending_say is not None:
            text = pending_say["text"]
            pending_say["multiTurn"] = ">>" in text
            pending_say["hasClosure"] = "closure" in text.lower() or "all i know" in text.lower()
            current["variants"].append(pending_say)
        pending_say = None

    def flush_offer() -> None:
        nonlocal current_offer
        if current is not None and current_offer is not None:
            current["offers"].append(current_offer)
        current_offer = None

    for line_no, raw in enumerate(lines, start=1):
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue

        if _LEX_RE.match(raw):
            flush_say()
            flush_offer()
            current = None
            in_lex = True
            continue

        m_block = _BLOCK_RE.match(raw)
        if m_block:
            flush_say()
            flush_offer()
            in_lex = False
            current = {
                "kind": m_block.group(1),
                "poolId": m_block.group(2),
                "language": lang,
                "scriptName": path.name,
                "scriptPath": rel,
                "lineNo": line_no,
                "offers": [],
                "variants": [],
            }
            flows.append(current)
            continue

        if in_lex or current is None:
            continue

        m_offer = _OFFER_RE.match(raw)
        if m_offer:
            flush_say()
            flush_offer()
            current_offer = {
                "id": m_offer.group(1),
                "lineNo": line_no,
                "label": "",
                "say": "",
                "intent": "",
                "subject": "",
                "utility": "",
            }
            continue

        m_say = _SAY_RE.match(raw)
        if m_say:
            flush_say()
            flush_offer()
            preds = [p.strip() for p in (m_say.group(1) or "").split(",") if p.strip()]
            pri = int(m_say.group(2)) if m_say.group(2) else 5
            variant = m_say.group(3) or f"variant_{len(current['variants']) + 1}"
            inline_text = _strip_quotes(m_say.group(4) or "")
            pending_say = {
                "variant": variant,
                "priority": pri,
                "predicates": preds,
                "text": inline_text,
                "lineNo": line_no,
                "multiTurn": False,
                "hasClosure": False,
            }
            if inline_text:
                flush_say()
            continue

        if pending_say is not None and stripped.startswith('"'):
            pending_say["text"] = _strip_quotes(stripped)
            flush_say()
            continue

        if current_offer is not None:
            m_field = _OFFER_FIELD_RE.match(raw)
            if m_field:
                key = m_field.group(1).strip()
                current_offer[key] = _strip_quotes(m_field.group(2))
                continue

    flush_say()
    flush_offer()

    for flow in flows:
        flow["variants"].sort(key=lambda v: (-v["priority"], v["lineNo"]))
    return flows


def collect_repo_convo_flows(repo_root: Path) -> list[dict[str, Any]]:
    """Discover and parse all `.convo` flows across `repo_root`."""
    scripts_root = find_convo_scripts_root(repo_root)
    if scripts_root is None:
        return []
    all_flows: list[dict[str, Any]] = []
    for path in sorted(scripts_root.rglob("*.convo")):
        all_flows.extend(parse_convo_flows(path, repo_root=repo_root))
    return all_flows


def format_flow_report(flow: dict[str, Any]) -> str:
    """Format one flow's dynamic offers, branches, and variants for display."""
    out: list[str] = []
    out.append(f"{flow['kind'].upper()}  {flow['poolId']}")
    out.append(f"Source: {flow['scriptPath']}:{flow['lineNo']}  [{flow['language']}]")
    out.append(
        f"Offers: {len(flow['offers'])}   Variants: {len(flow['variants'])}"
    )
    out.append("")

    if flow["offers"]:
        out.append("=== DYNAMIC SUGGESTION BUTTONS (OFFERS) ===")
        for offer in flow["offers"]:
            route = " / ".join(
                part for part in (offer.get("intent"), offer.get("subject")) if part
            ) or "semantic"
            out.append(
                f"  [Button] \"{offer.get('label') or offer['id']}\"  ->  say: \"{offer.get('say', '')}\""
            )
            out.append(
                f"           id={offer['id']}  route={route}  utility={offer.get('utility') or '-'}"
            )
        out.append("")

    out.append("=== BRANCHES & VARIANTS (PRIORITY ORDER) ===")
    for idx, var in enumerate(flow["variants"], start=1):
        preds = ", ".join(var["predicates"]) if var["predicates"] else "default"
        flags: list[str] = []
        if var.get("multiTurn"):
            flags.append("MULTI-TURN >>")
        if var.get("hasClosure"):
            flags.append("CLOSURE")
        flag_str = f"  [{' | '.join(flags)}]" if flags else ""
        out.append(
            f"  {idx}. (pri {var['priority']}) as {var['variant']}  [{preds}]{flag_str}"
        )
        out.append(f"     \"{var['text']}\"")
    return "\n".join(out)
