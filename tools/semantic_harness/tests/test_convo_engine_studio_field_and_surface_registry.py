"""S9H4 tests: compiler FieldDescriptor registry, SurfaceRegistry, read-only legacy gating, and round-trip preservation."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

CORE_ROOT = Path(__file__).resolve().parents[3]
if str(CORE_ROOT) not in sys.path:
    sys.path.insert(0, str(CORE_ROOT))

from tools.semantic_harness.codebuilder.convo_engine_fields import (
    CONVO_ENGINE_FIELD_DESCRIPTORS,
    describe_unknown_fields,
    known_field_names,
    list_field_descriptors,
)
from tools.semantic_harness.codebuilder.convo_engine_compiler import CONVO_ENGINE_RECORD_FIELDS
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.studio.dataset_library import DatasetLibraryPane
from tools.semantic_harness.studio.surface_registry import SurfaceRegistry
from tools.semantic_harness.ui.studio_surface_builder import build_studio_editors
from tools.semantic_harness.ui.surface_builder import build_ui


class _DummyVar:
    def __init__(self, value=None) -> None:
        self._value = value

    def get(self):
        return self._value

    def set(self, value) -> None:
        self._value = value


class _DummyWidget:
    def __init__(self, *args, **kwargs) -> None:
        self.args = args
        self.kwargs = dict(kwargs)
        self._children = []
        self._tabs = []
        self._selected = None
        self._state = "normal"
        self._text = ""

    def grid(self, *args, **kwargs):
        return None

    def grid_remove(self, *args, **kwargs):
        return None

    def pack(self, *args, **kwargs):
        return None

    def rowconfigure(self, *args, **kwargs):
        return None

    def columnconfigure(self, *args, **kwargs):
        return None

    def configure(self, **kwargs):
        if "state" in kwargs:
            self._state = kwargs["state"]

    def bind(self, *args, **kwargs):
        return None

    def add(self, child, text=""):
        key = str(child)
        if key not in self._tabs:
            self._tabs.append(key)
            self._children.append((key, child, text))
        if self._selected is None:
            self._selected = key

    def forget(self, child):
        key = str(child)
        self._tabs = [item for item in self._tabs if item != key]
        self._children = [item for item in self._children if item[0] != key]
        if self._selected == key:
            self._selected = self._tabs[0] if self._tabs else None

    def tabs(self):
        return list(self._tabs)

    def tab(self, index_or_key, option=None):
        for key, _child, text in self._children:
            if key == str(index_or_key):
                return {"text": text} if option is None else text
        return {}

    def select(self, target=None):
        if target is None:
            return self._selected
        if isinstance(target, int):
            self._selected = self._tabs[target]
        else:
            self._selected = str(target)
        return self._selected

    def delete(self, *args, **kwargs):
        self._text = ""

    def insert(self, _pos, value):
        self._text = value

    def get(self, *args, **kwargs):
        return self._text

    def curselection(self):
        return (0,)

    def selection_set(self, *_args):
        return None

    def yview(self, *args):
        return None

    def set(self, *args, **kwargs):
        return None

    def heading(self, *args, **kwargs):
        return None

    def column(self, *args, **kwargs):
        return None

    def tag_configure(self, *args, **kwargs):
        return None

    def yscrollcommand(self, *args, **kwargs):
        return None

    def get_children(self):
        return ()

    def winfo_ismapped(self):
        return False


class _DummyTk:
    StringVar = _DummyVar
    BooleanVar = _DummyVar

    def Listbox(self, *args, **kwargs):
        return _DummyWidget(*args, **kwargs)

    def Canvas(self, *args, **kwargs):
        return _DummyWidget(*args, **kwargs)


class _DummyTtk:
    Frame = _DummyWidget
    Label = _DummyWidget
    Entry = _DummyWidget
    Button = _DummyWidget
    Checkbutton = _DummyWidget
    LabelFrame = _DummyWidget
    Notebook = _DummyWidget
    PanedWindow = _DummyWidget
    Scrollbar = _DummyWidget
    Combobox = _DummyWidget
    Treeview = _DummyWidget


class _DummyScrolledText(_DummyWidget):
    pass


class _DummyMessagebox:
    @staticmethod
    def askyesno(_title, _message):
        return True


class ConvoEngineStudioFieldAndSurfaceRegistryTests(unittest.TestCase):
    def test_field_descriptor_registry_covers_all_compiler_fields_and_unknown_round_trip(self) -> None:
        known = known_field_names()
        self.assertTrue(CONVO_ENGINE_RECORD_FIELDS.issubset(known))
        exchange_json = list_field_descriptors(category="exchange", editor_kind="json")
        names = [item["name"] for item in exchange_json]
        self.assertEqual(
            names,
            ["when", "invoke", "affordance", "execute", "say", "reply", "after", "metadata"],
        )
        self.assertTrue(all("label" in item and "summary" in item for item in CONVO_ENGINE_FIELD_DESCRIPTORS and [item.to_dict() for item in CONVO_ENGINE_FIELD_DESCRIPTORS] or []))
        sample = {
            "schema": "psychopatz.convo-engine.v1",
            "id": "demo",
            "futureSignal": {"weight": 2},
        }
        extra = describe_unknown_fields(sample)
        self.assertEqual(extra, {"futureSignal": {"weight": 2}})

    def test_dataset_library_and_dialogue_content_disable_edits_when_sources_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            service = SemanticLabAuthoringService(root)
            sources = service.list_dataset_sources()
            self.assertTrue(sources)
            self.assertTrue(all(item["exists"] is False and item["editable"] is False for item in sources))
            workflows = service.list_workflow_datasets()
            self.assertTrue(workflows)
            self.assertTrue(all(item["workflowReady"] is False for item in workflows))

            lib_pane = DatasetLibraryPane(
                _DummyWidget(),
                _DummyTk(),
                _DummyTtk(),
                _DummyScrolledText,
                _DummyMessagebox(),
                service,
            )
            self.assertEqual(lib_pane._validate_button._state, "disabled")
            self.assertEqual(lib_pane._write_button._state, "disabled")
            rejected = lib_pane.write_canonical()
            self.assertIsNotNone(rejected)
            self.assertFalse(rejected["ok"])
            self.assertEqual(rejected["reason"], "source_not_editable")

    def test_surface_registry_promotes_convo_engine_home_and_retires_legacy_surfaces(self) -> None:
        registry = SurfaceRegistry()
        self.assertEqual(registry.primary_surface_ids(), ["conversations", "source_impact", "review"])
        # Active canonical / pattern / WordNet sources must NOT trigger legacyDatasetsPresent
        non_legacy_sources = [
            {"id": "convo_engine", "exists": True, "kind": "convo_engine"},
            {"id": "nlu_patterns", "exists": True, "kind": "nlu_patterns"},
            {"id": "wordnet", "exists": True, "kind": "wordnet"},
        ]
        self.assertFalse(registry.has_active_legacy_datasets(non_legacy_sources))
        surfaces = {item["id"]: item for item in registry.list_surfaces(dataset_sources=non_legacy_sources)}
        self.assertTrue(surfaces["conversations"]["visible"])
        self.assertTrue(surfaces["source_impact"]["visible"])
        self.assertTrue(surfaces["review"]["visible"])
        self.assertFalse(surfaces["conversations"]["legacyDatasetsPresent"])
        self.assertIn("canonical_data_sources", surfaces)
        self.assertIn("interaction_explorer", surfaces)
        for retired_id in ("dialogue_content", "explore", "dataset_library", "interaction_specs", "workflow"):
            self.assertNotIn(retired_id, surfaces)

        dev_surfaces = {item["id"]: item["visible"] for item in registry.list_surfaces(include_developer=True)}
        self.assertTrue(dev_surfaces["canonical_data_sources"])
        self.assertTrue(dev_surfaces["interaction_explorer"])
        self.assertTrue(dev_surfaces["semantic_blocks"])

    def test_studio_surface_builder_shows_primary_tabs_and_retires_legacy_toggle(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            service = SemanticLabAuthoringService(root)
            app = mock.MagicMock()
            app._tk = _DummyTk()
            app._ttk = _DummyTtk()
            app._scrolled_text = _DummyScrolledText
            app.root = _DummyWidget()
            app.authoring_service = service
            app._filedialog = mock.MagicMock()
            app._messagebox = _DummyMessagebox()
            app._start_background_operation = lambda *a, **kw: None
            app.workbench_status_var = _DummyVar()
            app.worker_status_var = _DummyVar()
            app.simulation_context_var = _DummyVar()
            app.active_speaker_var = _DummyVar()
            app.active_addressee_var = _DummyVar()
            del app.legacy_surfaces_toggle
            del app.toggle_legacy_surfaces

            with (
                mock.patch("tools.semantic_harness.ui.surface_builder.build_quality_sweep_workbench"),
                mock.patch("tools.semantic_harness.ui.surface_builder.build_saved_world_browser"),
                mock.patch("tools.semantic_harness.ui.surface_builder.build_selection_surface"),
                mock.patch("tools.semantic_harness.ui.surface_builder.build_simulation_panes", return_value=(_DummyWidget(), _DummyWidget())),
                mock.patch("tools.semantic_harness.ui.surface_builder.build_conversation_panel"),
                mock.patch("tools.semantic_harness.ui.surface_builder.build_workbench_controls"),
                mock.patch("tools.semantic_harness.ui.surface_builder.build_conversation_trace"),
                mock.patch("tools.semantic_harness.ui.surface_builder.build_diagnostic_trace"),
                mock.patch("tools.semantic_harness.ui.studio_surface_builder.SemanticObservatoryPane"),
                mock.patch("tools.semantic_harness.ui.studio_surface_builder.CanonicalSourceExplorerPane"),
                mock.patch("tools.semantic_harness.ui.studio_surface_builder.InteractionExplorerPane"),
                mock.patch("tools.semantic_harness.ui.studio_surface_builder.InteractionModulesPane"),
                mock.patch("tools.semantic_harness.ui.studio_surface_builder.FlowEditorPane"),
                mock.patch("tools.semantic_harness.ui.studio_surface_builder.SemanticBlockRegistryPane"),
                mock.patch("tools.semantic_harness.ui.studio_surface_builder.ConvoEngineAuthoringPane") as pane_cls,
            ):
                build_ui(app)
                build_studio_editors(app, **app._studio_editor_kwargs)

            pane_cls.assert_called_once()
            tab_titles = [app.studio_notebook.tab(tab_id, "text") for tab_id in app.studio_notebook.tabs()]
            self.assertEqual(tab_titles, ["Conversations", "Source / Impact", "Review"])
            self.assertFalse(hasattr(app, "legacy_surfaces_toggle"))
            self.assertFalse(hasattr(app, "toggle_legacy_surfaces"))
            adv_titles = [app.advanced_notebook.tab(tab_id, "text") for tab_id in app.advanced_notebook.tabs()]
            self.assertIn("Interaction Explorer", adv_titles)
            self.assertIn("Canonical Data Sources", adv_titles)
            self.assertNotIn("Workflow composer", adv_titles)
            self.assertNotIn("Interaction composer", adv_titles)

            # Caller-zero proof: retired pane modules no longer exist
            studio_dir = Path(__file__).resolve().parents[1] / "studio"
            self.assertFalse((studio_dir / "dialogue_content_pane.py").exists())
            self.assertFalse((studio_dir / "workflow.py").exists())
            self.assertFalse((studio_dir / "interaction_spec_pane.py").exists())


if __name__ == "__main__":
    unittest.main()
