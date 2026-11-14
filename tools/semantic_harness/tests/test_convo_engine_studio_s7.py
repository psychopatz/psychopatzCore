from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.studio.convo_engine_authoring_pane import ConvoEngineAuthoringPane


HOOMANS_ROOT = ROOT.parent / "ProjectHoomans"
DT_ROOT = ROOT.parent / "DynamicTrading"


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


class ConvoEngineStudioS7Tests(unittest.TestCase):
    def _service(self) -> SemanticLabAuthoringService:
        repo = HOOMANS_ROOT if HOOMANS_ROOT.is_dir() else ROOT
        return SemanticLabAuthoringService(
            repo,
            core_repository=ROOT,
            dynamic_trading_repository=DT_ROOT if DT_ROOT.is_dir() else None,
        )

    def test_service_lists_families_and_contracts_and_simulates_camp_trace(self) -> None:
        if not HOOMANS_ROOT.is_dir():
            self.skipTest("ProjectHoomans sibling repository unavailable")
        svc = self._service()
        families = svc.list_convo_engine_families()
        self.assertGreaterEqual(len(families), 500)
        contracts = svc.list_convo_engine_action_contracts()
        contract_ids = {item["id"] for item in contracts}
        self.assertIn("pnc.companion.camp", contract_ids)

        camp_path = (
            HOOMANS_ROOT
            / "tools/providers/pnc/codebuilder/sources/conversation/dialogue/companion_commands_lifecycle/command_camp.json"
        )
        camp_doc = json.loads(camp_path.read_text(encoding="utf-8"))
        sim_valid = svc.simulate_convo_engine_family(
            camp_doc,
            source_path=camp_path,
            speaker="player",
            addressee="npc",
            target="Harley",
            slot_values={"camp": {"locationPhrase": "inside the farmhouse"}},
            result_outcome="completed",
            result_fields={"locationPhrase": "inside the farmhouse"},
            context={"camp": {"locationPhrase": "inside the farmhouse"}},
        )
        self.assertTrue(sim_valid["ok"])
        self.assertEqual(sim_valid["buttonPreview"]["textRole"], "button_label")
        self.assertEqual(sim_valid["initiatingSpeechPreview"]["textRole"], "spoken_action")
        self.assertEqual(sim_valid["executePreview"]["action"], "pnc.companion.camp")
        self.assertEqual(sim_valid["replyPreview"]["outcome"], "completed")
        self.assertEqual(sim_valid["replyPreview"]["speech"]["textRole"], "response")
        stages = [step["stage"] for step in sim_valid["trace"]]
        self.assertEqual(
            stages,
            ["predicate", "affordance", "invoke", "speech", "execute", "result", "reply", "after"],
        )

        # Same authored source also supports NPC<->NPC simulation context and result.reasonClass branching.
        sim_npc = svc.simulate_convo_engine_family(
            camp_doc,
            source_path=camp_path,
            speaker="npc",
            addressee="npc",
            target="companion_2",
            result_outcome="rejected",
            result_reason_class="target_unavailable",
        )
        self.assertTrue(sim_npc["ok"])
        self.assertEqual(sim_npc["previewContext"]["speaker"], "npc")
        self.assertEqual(sim_npc["previewContext"]["addressee"], "npc")
        self.assertEqual(sim_npc["replyPreview"]["outcome"], "rejected_no_site")

    def test_studio_convo_engine_pane_browse_edit_trace_and_audit(self) -> None:
        svc = self._service()
        pane = ConvoEngineAuthoringPane(
            _FakeWidget(),
            _FakeTk,
            _FakeTtk,
            _FakeWidget,
            _FakeMessageBox(),
            svc,
        )
        self.assertIsInstance(pane, ConvoEngineAuthoringPane)
        self.assertGreaterEqual(pane._family_list.size(), 40)

        report = pane.preview_record()
        self.assertTrue(report and report["ok"], f"Preview failed: {report}")
        pane._reply_outcome_var.set("custom_ack")
        pane._reply_say_var.set("Copy that.")
        pane.set_reply_outcome()
        edited = pane._form_document()
        self.assertEqual(edited["reply"]["custom_ack"]["say"], "Copy that.")

        pane.new_family()
        draft_report = pane.preview_record()
        self.assertTrue(draft_report and draft_report["ok"], f"Draft preview failed: {draft_report}")

        audit_report = pane.run_s6m8_audit()
        if HOOMANS_ROOT.is_dir() and DT_ROOT.is_dir():
            self.assertTrue(audit_report["ok"], f"Audit violations: {audit_report['violations']}")


if __name__ == "__main__":
    unittest.main()
