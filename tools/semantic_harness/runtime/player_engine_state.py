"""Project Hoomans identity binding over Core's native player decoder."""

from __future__ import annotations

from tools.semantic_harness.player_engine_state import (
    PLAYER_WORLD_VERSION,
    PlayerEngineStateError,
    OfflinePlayerEngineStateProvider as _CorePlayerEngineStateProvider,
)


class OfflinePlayerEngineStateProvider(_CorePlayerEngineStateProvider):
    """Match native records using Hoomans' persisted character identity."""

    def __init__(self) -> None:
        super().__init__(
            identity_key="PNC_CharacterUUID",
            identity_metadata_keys=(
                "PNC_CharacterUUID",
                "PNC_CharacterAccountKey",
                "PNC_CharacterIdentityVersion",
            ),
        )


__all__ = [
    "OfflinePlayerEngineStateProvider",
    "PLAYER_WORLD_VERSION",
    "PlayerEngineStateError",
]
