"""Human-readable JSON rendering shared by the harness clients."""

from __future__ import annotations

import json
from typing import Any


def pretty(value: Any) -> str:
    return json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True)


def conversation_first(value: Any) -> str:
    """Render the conversation projection before raw/authority details."""

    if not isinstance(value, dict) or "understanding" not in value:
        return pretty(value)

    sections = (
        ("UNDERSTANDING", value.get("understanding", {})),
        ("SURFACE + RECOVERY", value.get("surface", {})),
        ("CANDIDATE SELECTION", value.get("candidateSelection", {})),
        ("DISCOURSE FRAME", value.get("discourse", {})),
        ("CONTEXT", value.get("context", {})),
        ("SOCIAL CONTEXT", value.get("socialContext", {})),
        ("DYNAMIC AFFORDANCES", value.get("affordances", {})),
        ("PERSONA + CHOICES", value.get("personaChoices", {})),
        ("FACTS AND PROVENANCE", value.get("facts", {})),
        ("DIALOGUE PLANNING", value.get("dialoguePlanning", {})),
        ("UTTERANCE REALIZATION", value.get("realization", {})),
        ("STORAGE OWNERSHIP", value.get("storagePointers", {})),
        ("SOCIAL EFFECT + CONDUCT MEMORY", value.get("socialEffect", {})),
        ("FINAL NPC RESPONSE", value.get("finalResponse", {})),
        ("COMMAND AUTHORITY (SEPARATE)", value.get("commandAuthority", {})),
    )
    rendered = []
    for title, section in sections:
        rendered.append(title)
        rendered.append(pretty(section))
    return "\n\n".join(rendered)


def print_result(value: Any, jsonl: bool) -> None:
    if jsonl:
        print(json.dumps(value, ensure_ascii=False, separators=(",", ":")))
    else:
        print(pretty(value))
