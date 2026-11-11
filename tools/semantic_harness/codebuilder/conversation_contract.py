"""Shared Conversation compiler contracts and bounded work limits."""

from __future__ import annotations

from pathlib import Path


CONVERSATION_SHARD_SCHEMA = "psychopatz.semantic.shard.v2"
CONVERSATION_MODEL_SCHEMA = "pnc.conversation.model.v1"
CONVERSATION_SOURCE_RELATIVE = Path(
    "tools/semantic_harness/codebuilder/sources/conversation"
)
CONVERSATION_MANIFEST_RELATIVE = CONVERSATION_SOURCE_RELATIVE / "manifest.json"
CONVERSATION_RUNTIME_RELATIVE = Path(
    "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/"
    "Semantics/Generated/Conversation"
)
CONVERSATION_UI_RUNTIME_RELATIVE = CONVERSATION_RUNTIME_RELATIVE / "UI/StaticSuggestions.lua"

CONVERSATION_PREFERRED_SOURCE_BYTES = 64 * 1024
CONVERSATION_MAX_SOURCE_BYTES = 128 * 1024
CONVERSATION_PREFERRED_SHARD_BYTES = 64 * 1024
CONVERSATION_MAX_SHARD_BYTES = 192 * 1024
CONVERSATION_PREFERRED_RECORDS_PER_SHARD = 16
CONVERSATION_MAX_RECORDS_PER_SHARD = 32
CONVERSATION_MAX_INDEX_BYTES = 192 * 1024


__all__ = [name for name in globals() if name.startswith("CONVERSATION_")]
