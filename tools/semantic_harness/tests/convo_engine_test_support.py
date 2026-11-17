"""Shared hermetic workspace and stub-Tk support helpers for ConvoEngine tests."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from tools.semantic_harness.codebuilder.psdl_compiler import CONVO_ENGINE_SCHEMA


class _FakeVar:
    def __init__(self, value: str = "") -> None:
        self._value = value

    def get(self) -> str:
        return self._value

    def set(self, value: Any) -> None:
        self._value = str(value)


class _FakeWidget:
    def __init__(self, *_args: Any, **_kwargs: Any) -> None:
        self._items: list[str] = []
        self._selection: list[int] = []
        self._text = ""
        self._config: dict[str, Any] = {}

    def grid(self, *_args: Any, **_kwargs: Any) -> None:
        return None

    def pack(self, *_args: Any, **_kwargs: Any) -> None:
        return None

    def bind(self, *_args: Any, **_kwargs: Any) -> None:
        return None

    def add(self, *_args: Any, **_kwargs: Any) -> None:
        return None

    def rowconfigure(self, *_args: Any, **_kwargs: Any) -> None:
        return None

    def columnconfigure(self, *_args: Any, **_kwargs: Any) -> None:
        return None

    def configure(self, **kwargs: Any) -> None:
        self._config.update(kwargs)

    def yview(self, *_args: Any, **_kwargs: Any) -> None:
        return None

    def set(self, *_args: Any, **_kwargs: Any) -> None:
        return None

    def delete(self, start: Any, end: Any = None) -> None:
        if end == "end" and start in {0, "1.0"}:
            self._items.clear()
            self._selection.clear()
            self._text = ""

    def insert(self, index: Any, value: str) -> None:
        if index == "end":
            self._items.append(value)
        else:
            self._text += value

    def get(self, *_args: Any) -> str:
        return self._text

    def size(self) -> int:
        return len(self._items)

    def selection_set(self, index: int) -> None:
        self._selection = [index]

    def curselection(self) -> tuple[int, ...]:
        return tuple(self._selection)


class _FakeTk:
    StringVar = _FakeVar
    Listbox = _FakeWidget


class _FakeTtk:
    Frame = _FakeWidget
    LabelFrame = _FakeWidget
    Label = _FakeWidget
    Entry = _FakeWidget
    Button = _FakeWidget
    Combobox = _FakeWidget
    Scrollbar = _FakeWidget
    Notebook = _FakeWidget
    PanedWindow = _FakeWidget


class _FakeMessageBox:
    def askyesno(self, *_args: Any) -> bool:
        return True


def _write_json(path: Path, payload: dict[str, Any]) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8", newline="\n")
    return path


def _sample_family(
    *,
    owner: str,
    namespace: str,
    family_id: str,
    after: dict[str, Any] | None = None,
    when: dict[str, Any] | None = None,
    extra: dict[str, Any] | None = None,
) -> dict[str, Any]:
    doc: dict[str, Any] = {
        "schema": CONVO_ENGINE_SCHEMA,
        "kind": "dialogue",
        "namespace": namespace,
        "id": family_id,
        "owner": owner,
        "participants": {"speaker": ["participant"], "addressee": ["participant"]},
        "invoke": {"intent": "GREET"},
        "affordance": {"label": f"Label {family_id}"},
        "say": f"Say {family_id}.",
        "reply": {"acknowledged": {"say": f"Reply {family_id}."}},
    }
    if after is not None:
        doc["after"] = after
    if when is not None:
        doc["when"] = when
    if extra:
        doc.update(extra)
    return doc


def _sample_ui_family(*, owner: str, namespace: str, family_id: str, pattern_id: str, order: int) -> dict[str, Any]:
    return {
        "schema": "psychopatz.convo-engine.v1",
        "kind": "dialogue",
        "namespace": namespace,
        "id": family_id,
        "owner": owner,
        "participants": {"speaker": ["participant"], "addressee": ["participant"]},
        "invoke": {"intent": "QUESTION", "speechAct": "QUESTION", "subject": "WELLBEING", "patternID": pattern_id},
        "affordance": {"label": {"EN": f"Ask {family_id}", "TL": f"Itanong {family_id}"}},
        "say": {"EN": f"Tell me {family_id}?", "TL": f"Sabihin {family_id}?"},
        "reply": {"acknowledged": {"say": {"EN": f"Answer {family_id}.", "TL": f"Sagot {family_id}."}}},
        "metadata": {
            "textNamespace": "UI_PNC_Conversation_Suggestion",
            "ui": {
                "id": f"question.{family_id}",
                "order": order,
                "topic": "wellbeing",
                "domain": "wellbeing",
            },
        },
    }


def _setup_three_repo_workspace(base: Path) -> dict[str, Path]:
    core_repo = base / "core_repo"
    hoomans_repo = base / "isolated_adopters" / "hoomans_repo"
    dt_repo = base / "isolated_adopters" / "dt_repo"

    _write_json(
        core_repo / "tools/semantic_harness/provider.json",
        {
            "schema": "semantic.provider_manifest.v2",
            "providerID": "PsychopatzCore",
            "displayName": "PsychopatzCore",
            "repositoryKind": "core",
            "providers": [
                {
                    "providerID": "PsychopatzCore",
                    "displayName": "PsychopatzCore",
                    "repositoryKind": "core",
                    "capabilities": ["semantic.parse", "semantic.ir", "semantic.conversation"],
                    "materializationModes": ["none", "abstract", "physical"],
                    "optional": False,
                    "runtimeModules": ["PsychopatzCore"],
                }
            ],
        },
    )
    _write_json(
        core_repo / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json",
        {
            "schema": "pnc.conversation.manifest.v1",
            "defaultOwner": "PsychopatzCore",
            "registryOwner": "PsychopatzCore",
            "version": 1,
            "shards": [],
            "sourceRoots": [
                {
                    "path": "dialogue",
                    "kind": "convo_engine",
                    "domain": "general",
                    "order": 3003,
                    "owner": "PsychopatzCore",
                    "domainFromSubdir": True,
                }
            ],
            "sourceProfiles": {
                "conversation.source.psychopatzcore.seed": {
                    "owner": "PsychopatzCore",
                    "name": "Seed",
                    "version": "1",
                    "contentLicense": "Core test fixture",
                }
            },
        },
    )
    _write_json(
        core_repo / "tools/semantic_harness/codebuilder/sources/conversation/dialogue/social/core_greet.json",
        _sample_family(owner="PsychopatzCore", namespace="social", family_id="core_greet"),
    )
    (core_repo / "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine").mkdir(
        parents=True, exist_ok=True
    )

    _write_json(
        hoomans_repo / "tools/providers/pnc/provider.json",
        {
            "schema": "semantic.provider_manifest.v2",
            "providerID": "ProjectHoomans",
            "displayName": "PNC",
            "providers": [
                {
                    "providerID": "ProjectHoomans",
                    "displayName": "Project Hoomans",
                    "repositoryKind": "project_hoomans",
                    "requires": ["PsychopatzCore"],
                    "capabilities": ["semantic.conversation", "semantic.interaction"],
                    "materializationModes": ["physical"],
                    "optional": True,
                    "runtimeModules": ["ProjectHoomans"],
                }
            ],
            "conversationManifest": "tools/providers/pnc/codebuilder/sources/conversation/manifest.json",
        },
    )
    _write_json(
        hoomans_repo / "tools/providers/pnc/codebuilder/sources/conversation/manifest.json",
        {
            "schema": "pnc.conversation.manifest.v1",
            "defaultOwner": "ProjectHoomans",
            "shards": [],
        },
    )
    _write_json(
        hoomans_repo / "tools/providers/pnc/codebuilder/sources/conversation/dialogue/social/pnc_checkin.json",
        _sample_family(owner="ProjectHoomans", namespace="social", family_id="pnc_checkin"),
    )
    (hoomans_repo / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine").mkdir(
        parents=True, exist_ok=True
    )

    _write_json(
        dt_repo / "tools/providers/dt/provider.json",
        {
            "schema": "semantic.provider_manifest.v2",
            "providerID": "DTCommon",
            "displayName": "Dynamic Trading",
            "providers": [
                {
                    "providerID": "DTCommon",
                    "displayName": "Dynamic Trading common contract",
                    "repositoryKind": "dynamic_trading",
                    "requires": ["PsychopatzCore"],
                    "capabilities": ["trading.conversation"],
                    "materializationModes": ["abstract", "physical"],
                    "optional": True,
                    "runtimeModules": ["DTCommon"],
                }
            ],
            "conversationSources": [
                "tools/providers/dt/codebuilder/sources/conversation/manifest.json"
            ],
        },
    )
    _write_json(
        dt_repo / "tools/providers/dt/codebuilder/sources/conversation/manifest.json",
        {
            "schema": "pnc.conversation.manifest.v1",
            "defaultOwner": "DTCommon",
            "shards": [],
        },
    )
    _write_json(
        dt_repo / "tools/providers/dt/codebuilder/sources/conversation/dialogue/trade/dt_quote.json",
        _sample_family(owner="DTCommon", namespace="trade", family_id="dt_quote"),
    )
    (dt_repo / "Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine").mkdir(
        parents=True, exist_ok=True
    )

    return {"core": core_repo, "hoomans": hoomans_repo, "dt": dt_repo}


def _build_three_repo_fixture(base: Path) -> dict[str, Path]:
    repos = _setup_three_repo_workspace(base)
    core_repo = repos["core"]
    _write_json(
        core_repo / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json",
        {
            "schema": "pnc.conversation.manifest.v1",
            "defaultOwner": "PsychopatzCore",
            "registryOwner": "PsychopatzCore",
            "version": 1,
            "shards": [],
            "sourceRoots": [
                {
                    "path": "dialogue",
                    "kind": "convo_engine",
                    "domain": "general",
                    "order": 3003,
                    "owner": "PsychopatzCore",
                    "domainFromSubdir": True,
                }
            ],
            "externalSourceRoots": [
                {
                    "path": "adopters/dt/dialogue",
                    "kind": "convo_engine",
                    "domain": "trading",
                    "order": 3010,
                    "owner": "DTCommon",
                    "optional": True,
                    "sourcePath": "tools/providers/dt/codebuilder/sources/conversation/dialogue",
                    "domainFromSubdir": True,
                },
                {
                    "path": "adopters/hoomans/dialogue",
                    "kind": "convo_engine",
                    "domain": "general",
                    "order": 3011,
                    "owner": "ProjectHoomans",
                    "optional": True,
                    "sourcePath": "tools/providers/pnc/codebuilder/sources/conversation/dialogue",
                    "domainFromSubdir": True,
                },
            ],
            "sourceProfiles": {
                "conversation.source.psychopatzcore.seed": {
                    "owner": "PsychopatzCore",
                    "name": "Seed",
                    "version": "1",
                    "contentLicense": "Core test fixture",
                }
            },
        },
    )
    return repos
