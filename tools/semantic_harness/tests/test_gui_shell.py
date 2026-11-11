from __future__ import annotations

import unittest
from types import SimpleNamespace
from unittest.mock import patch

from tools.semantic_harness.ui.shell import SemanticHarnessApp
from tools.semantic_harness.ui.selection_surface import (
    _selection_banner,
    _selection_summary,
    _sync_provider_labels,
)


def _request(*provider_ids: str, save_name: str = "") -> dict[str, object]:
    plan = _SelectionPlan(provider_ids)
    request: dict[str, object] = {
        "mode": "save" if save_name else "preset",
        "presetID": None if save_name else "pnc",
        "providerIDs": list(provider_ids),
        "plan": plan,
    }
    if save_name:
        request["save"] = {"saveName": save_name}
        request["activation"] = {
            "modIDs": ["PsychopatzCore", "ProjectHoomans", "MarketSense"],
            "unknownModIDs": ["MarketSense"],
            "status": "partial",
        }
    return request


class _SelectionVar:
    def __init__(self) -> None:
        self.value = ""

    def set(self, value: str) -> None:
        self.value = value

    def get(self) -> str:
        return self.value


class _SelectionRoot:
    def __init__(self) -> None:
        self.after_idle_callbacks: list[object] = []

    def after_idle(self, callback: object) -> str:
        self.after_idle_callbacks.append(callback)
        return "after-idle"


class _SelectionPlan:
    def __init__(self, provider_ids: tuple[str, ...]) -> None:
        self.provider_ids = provider_ids
        self.materialization_mode = "physical"
        self.routes: dict[str, str] = {}

    def to_dict(self) -> dict[str, object]:
        return {
            "providerIDs": list(self.provider_ids),
            "materializationMode": self.materialization_mode,
        }


class _SelectionListbox:
    def __init__(self, labels: list[str]) -> None:
        self.labels = labels
        self.selected: set[int] = set()

    def selection_clear(self, _start: int, _end: str) -> None:
        self.selected.clear()

    def size(self) -> int:
        return len(self.labels)

    def get(self, index: int) -> str:
        return self.labels[index]

    def selection_set(self, index: int) -> None:
        self.selected.add(index)


class GuiShellTests(unittest.TestCase):
    def test_selected_mods_flattens_repeatable_comma_values(self) -> None:
        app = object.__new__(SemanticHarnessApp)
        app.arguments = SimpleNamespace(mods=["ProjectHoomans,DTCommon", "DTHoomans"])

        self.assertEqual(
            app._selected_mods(),
            ("ProjectHoomans", "DTCommon", "DTHoomans"),
        )

    def test_selected_mods_returns_none_for_empty_selection(self) -> None:
        app = object.__new__(SemanticHarnessApp)
        app.arguments = SimpleNamespace(mods=None)

        self.assertIsNone(app._selected_mods())

    def test_pending_save_composition_is_distinguished_from_active_worker(self) -> None:
        app = SimpleNamespace(
            selection_active=_request("PsychopatzCore", "ProjectHoomans"),
            selection_pending=_request(
                "PsychopatzCore", "DTCommon", "DTAbstract", save_name="modv1"
            ),
        )

        banner = _selection_banner(app)

        self.assertIn("Active: pnc", banner)
        self.assertIn("Pending: save modv1", banner)

    def test_save_summary_surfaces_unknown_mods_without_raw_plan(self) -> None:
        summary = _selection_summary(
            _request("PsychopatzCore", "ProjectHoomans", save_name="NPCEngine")
        )

        self.assertIn("Save: NPCEngine", summary)
        self.assertIn("resolution: PARTIAL", summary)
        self.assertIn("Unavailable to harness: MarketSense", summary)
        self.assertNotIn("activationPlan", summary)

    def test_provider_sync_selects_resolved_rows_once(self) -> None:
        labels = ["PNC · ProjectHoomans", "DT · DTCommon", "DT · DTAbstract"]
        app = SimpleNamespace(
            selection_provider_listbox=_SelectionListbox(labels),
            selection_provider_ids_by_label={
                labels[0]: "ProjectHoomans",
                labels[1]: "DTCommon",
                labels[2]: "DTAbstract",
            },
            _selection_syncing=False,
        )

        _sync_provider_labels(app, ["ProjectHoomans", "DTAbstract"])

        self.assertEqual(app.selection_provider_listbox.selected, {0, 2})
        self.assertFalse(app._selection_syncing)

    def test_save_load_does_not_reconfigure_when_plan_is_already_active(self) -> None:
        from tools.semantic_harness.ui.selection_surface import ensure_selection_for_save

        request = _request(
            "PsychopatzCore", "ProjectHoomans", save_name="NPCEngine"
        )
        app = SimpleNamespace(
            closed=False,
            selection_mode_var=_SelectionVar(),
            selection_active=request,
            selection_pending=None,
            _selection_syncing=False,
            selection_provider_listbox=_SelectionListbox(
                ["PNC · ProjectHoomans"]
            ),
            selection_provider_ids_by_label={
                "PNC · ProjectHoomans": "ProjectHoomans"
            },
            selection_active_var=_SelectionVar(),
            selection_summary_var=_SelectionVar(),
            selection_plan_text=object(),
            selection_details_visible=False,
            _selection_plan_rendered="",
            _set_text=lambda *_args: None,
            selection_status_var=_SelectionVar(),
            busy=False,
            _selection_ensure_after=None,
            root=_SelectionRoot(),
        )
        app.selection_mode_var.set("Selected save")
        completed: list[bool] = []

        with patch(
            "tools.semantic_harness.ui.selection_surface._active_request",
            return_value=request,
        ):
            ensure_selection_for_save(app, lambda: completed.append(True))

        self.assertIsNone(app.selection_pending)
        self.assertEqual(len(app.root.after_idle_callbacks), 1)
        app.root.after_idle_callbacks[0]()
        self.assertEqual(completed, [True])


if __name__ == "__main__":
    unittest.main()
