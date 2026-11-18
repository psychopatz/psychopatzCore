"""Build the semantic harness Studio editor panes."""

from __future__ import annotations

from typing import Any

from ..studio.block_registry import SemanticBlockRegistryPane
from ..studio.dataset_library import DatasetLibraryPane
from ..studio.interaction_explorer_pane import InteractionExplorerPane
from ..studio.convo_engine_authoring_pane import ConvoEngineAuthoringPane
from ..studio.source_explorer_pane import CanonicalSourceExplorerPane
from ..studio.observatory_pane import SemanticObservatoryPane
from .flow_editor.pane import FlowEditorPane
from .interaction_modules.pane import InteractionModulesPane


def build_studio_editors(
    app: Any,
    *,
    conversations_tab: Any = None,
    source_impact_tab: Any = None,
    review_tab: Any,
    developer_tools_parent: Any,
    ttk: Any,
    scrolled_text: Any,
) -> None:
    """Create Studio surfaces with ConvoEngine as primary conversation home.

    Primary Studio homes are Conversations (ConvoEngineAuthoringPane),
    Source / Impact (CanonicalSourceExplorerPane), and Review. Developer tools
    host Interaction Modules, Flow Editor, Interaction Explorer, Canonical Data
    Sources, and Block Contracts.
    """
    source_frame = source_impact_tab if source_impact_tab is not None else review_tab

    advanced_notebook = ttk.Notebook(developer_tools_parent)
    advanced_notebook.grid(row=0, column=0, sticky="nsew")
    developer_tools_parent.rowconfigure(0, weight=1)
    developer_tools_parent.columnconfigure(0, weight=1)
    app.advanced_notebook = advanced_notebook

    interaction_modules_frame = ttk.Frame(advanced_notebook)
    interaction_modules_frame.rowconfigure(0, weight=1)
    interaction_modules_frame.columnconfigure(0, weight=1)
    flow_frame = ttk.Frame(advanced_notebook)
    flow_frame.rowconfigure(0, weight=1)
    flow_frame.columnconfigure(0, weight=1)
    interaction_frame = ttk.Frame(advanced_notebook)
    library_frame = ttk.Frame(advanced_notebook)
    blocks_frame = ttk.Frame(advanced_notebook)
    responses_frame = ttk.Frame(advanced_notebook)
    if conversations_tab is None:
        psdl_frame = ttk.Frame(advanced_notebook)
        psdl_frame.rowconfigure(0, weight=1)
        psdl_frame.columnconfigure(0, weight=1)
    else:
        psdl_frame = conversations_tab
    for panel in (interaction_frame, library_frame, blocks_frame, responses_frame):
        panel.rowconfigure(0, weight=1)
        panel.columnconfigure(0, weight=1)
    advanced_notebook.add(interaction_modules_frame, text="Interaction Modules")
    advanced_notebook.add(flow_frame, text="Flow editor")
    advanced_notebook.add(interaction_frame, text="Interaction Explorer")
    advanced_notebook.add(library_frame, text="Canonical Data Sources")
    advanced_notebook.add(blocks_frame, text="Block contracts")
    advanced_notebook.add(responses_frame, text="Responses")
    if conversations_tab is None:
        advanced_notebook.add(psdl_frame, text="ConvoEngine")
    app.interaction_modules_frame = interaction_modules_frame
    app.flow_editor_frame = flow_frame
    app.interaction_explorer_frame = interaction_frame
    app.library_tab = library_frame
    app.blocks_tab = blocks_frame
    app.psdl_authoring_frame = psdl_frame

    app.observatory = SemanticObservatoryPane(
        responses_frame, app._tk, ttk, scrolled_text,
        run_worker=app._start_background_operation,
        repository=app.authoring_service.repository,
        filedialog=app._filedialog,
        review_parent=review_tab,
    )
    app.source_explorer = CanonicalSourceExplorerPane(
        source_frame,
        app._tk,
        ttk,
        scrolled_text,
        app.authoring_service,
    )
    app.explore_source_frame = source_frame

    app.interaction_explorer = InteractionExplorerPane(
        interaction_frame,
        app._tk,
        ttk,
        scrolled_text,
        app.authoring_service,
        on_open_flow=lambda flow_id: (
            app.advanced_notebook.select(app.flow_editor_frame)
            if hasattr(app, "advanced_notebook")
            else None
        ) or app.flow_editor.select_flow(flow_id),
    )

    app.interaction_modules = InteractionModulesPane(
        interaction_modules_frame,
        app._tk,
        ttk,
        scrolled_text,
        app._filedialog,
        app._messagebox,
        on_refresh=app.refresh_beat_catalog,
        on_validate=app.validate_beat_draft,
        on_preview=app.preview_beat_draft,
        on_register=app.register_beat_draft,
        on_validate_behavior=app.validate_behavior_draft,
        on_register_behavior=app.register_behavior_draft,
        on_load_canonical=app.load_canonical_interaction_definition,
        on_preview_promotion=app.preview_interaction_promotion,
        on_promote=app.promote_interaction_definition,
        on_open_content=lambda content_id: (
            app.main_tabs.select(app.studio_tab),
            app.studio_notebook.select(app.convo_engine_tab),
            app.convo_engine_authoring.open_family_from_completeness(content_id),
        ),
    )
    app.flow_editor = FlowEditorPane(
        flow_frame,
        app._tk,
        ttk,
        scrolled_text,
        app._filedialog,
        app._messagebox,
        on_refresh=app.refresh_flow_catalog,
        on_validate=app.validate_flow_draft,
        on_register=app.register_flow_draft,
    )
    app.dataset_library = DatasetLibraryPane(
        library_frame,
        app._tk,
        ttk,
        scrolled_text,
        app._messagebox,
        app.authoring_service,
    )
    app.block_registry = SemanticBlockRegistryPane(
        blocks_frame,
        app._tk,
        ttk,
        scrolled_text,
        app.authoring_service,
        on_refresh=app.refresh_flow_catalog,
        auto_load=False,
    )
    if (
        callable(getattr(advanced_notebook, "bind", None))
        and callable(getattr(advanced_notebook, "select", None))
    ):
        def _load_blocks_on_select(_event: Any = None) -> None:
            try:
                if str(advanced_notebook.select()) == str(blocks_frame):
                    app.block_registry.ensure_loaded()
            except Exception:
                pass

        advanced_notebook.bind("<<NotebookTabChanged>>", _load_blocks_on_select, add="+")
    main_tabs = getattr(app, "main_tabs", None)
    studio_tab = getattr(app, "studio_tab", None)
    defer_convo_refresh = (
        main_tabs is not None
        and studio_tab is not None
        and callable(getattr(main_tabs, "bind", None))
        and callable(getattr(main_tabs, "select", None))
    )
    def _preview_in_simulation(family_id: str | None, _doc: dict[str, Any] | None) -> None:
        if hasattr(app, "main_tabs") and hasattr(app, "simulation_tab"):
            app.main_tabs.select(app.simulation_tab)
        if family_id and hasattr(app, "status_var") and callable(getattr(app.status_var, "set", None)):
            app.status_var.set(f"Simulation workspace opened for {family_id}")

    app.convo_engine_authoring = ConvoEngineAuthoringPane(
        psdl_frame,
        app._tk,
        ttk,
        scrolled_text,
        app._messagebox,
        app.authoring_service,
        auto_refresh=not defer_convo_refresh,
        on_preview_in_simulation=_preview_in_simulation,
    )
    app.psdl_authoring = app.convo_engine_authoring
    if defer_convo_refresh:
        def _refresh_studio_on_select(_event: Any = None) -> None:
            try:
                if str(main_tabs.select()) == str(studio_tab):
                    app.convo_engine_authoring.ensure_refreshed()
            except Exception:
                pass

        main_tabs.bind("<<NotebookTabChanged>>", _refresh_studio_on_select, add="+")
        _refresh_studio_on_select()
