"""Build simulation workbench and advanced runtime controls."""

from __future__ import annotations

from typing import Any

from tools.semantic_harness.runtime.npc_profiles import PROFILE_IDS, profile_id, profile_label


def build_workbench_controls(
    app: Any, workbench_pane: Any, ttk: Any
) -> None:
    """Create workbench controls and initialize their UI state."""

    app.simulation_workbench = ttk.Frame(workbench_pane)
    app.simulation_workbench.grid(
        row=0, column=0, sticky="nsew"
    )
    app.simulation_workbench.columnconfigure(0, weight=1)
    app.simulation_workbench.rowconfigure(1, weight=1)
    workbench_header = ttk.Frame(app.simulation_workbench)
    workbench_header.grid(row=0, column=0, sticky="ew")
    workbench_header.columnconfigure(4, weight=1)
    ttk.Label(
        workbench_header,
        text="Context / tools",
        font=("TkDefaultFont", 10, "bold"),
    ).grid(row=0, column=0, sticky="w", padx=(2, 10))
    ttk.Label(workbench_header, text="NPC profile").grid(
        row=0, column=1, sticky="e", padx=(0, 4)
    )
    app.npc_profile_label = workbench_header.grid_slaves(row=0, column=1)[0]
    app.npc_profile_var = app._tk.StringVar(
        value=profile_label(profile_id(app.scenario))
    )
    app.npc_profile_box = ttk.Combobox(
        workbench_header,
        textvariable=app.npc_profile_var,
        values=tuple(profile_label(value) for value in PROFILE_IDS),
        width=22,
        state="readonly",
    )
    app.npc_profile_box.grid(row=0, column=2, sticky="w", padx=(0, 8))
    app.npc_profile_box.bind("<<ComboboxSelected>>", lambda _: app._on_npc_profile())
    app.workbench_toggle_button = ttk.Button(
        workbench_header,
        text="Hide controls",
        command=app.toggle_simulation_workbench,
    )
    app.workbench_toggle_button.grid(row=0, column=5, sticky="e")
    app.workbench_content = ttk.Frame(app.simulation_workbench)
    app.workbench_content.grid(row=1, column=0, sticky="nsew", pady=(3, 0))
    app.workbench_content.columnconfigure(0, weight=1)
    app.workbench_content.rowconfigure(0, weight=1)
    app.workbench_notebook = ttk.Notebook(app.workbench_content)
    app.workbench_notebook.grid(row=0, column=0, sticky="nsew")
    app.workbench_status_var = app._tk.StringVar(
        value="Common context controls · changes apply through the Lua worker."
    )
    workbench_footer = ttk.Frame(app.workbench_content)
    app.workbench_footer = workbench_footer
    workbench_footer.grid(row=1, column=0, sticky="ew", pady=(3, 0))
    workbench_footer.columnconfigure(0, weight=1)
    ttk.Label(
        workbench_footer,
        textvariable=app.workbench_status_var,
        anchor="w",
        justify="left",
        wraplength=320,
    ).grid(row=0, column=0, sticky="ew", pady=(0, 3))
    app.provenance_status_var = app._tk.StringVar(
        value="Source provenance: FIXTURE · isolated working world"
    )
    ttk.Label(
        workbench_footer,
        textvariable=app.provenance_status_var,
        anchor="w",
        justify="left",
        wraplength=320,
    ).grid(row=1, column=0, sticky="ew", pady=(0, 3))
    workbench_actions = ttk.Frame(workbench_footer)
    workbench_actions.grid(row=2, column=0, sticky="ew")
    app.workbench_apply_button = ttk.Button(
        workbench_actions,
        text="Apply",
        command=app.apply_simulation_settings,
    )
    app.workbench_apply_button.grid(row=0, column=0, sticky="w")
    app.replay_button = ttk.Button(
        workbench_actions,
        text="Apply + replay",
        command=app.apply_and_replay,
    )
    app.replay_button.grid(row=0, column=1, sticky="w", padx=(6, 0))
    app.auto_replay_var = app._tk.BooleanVar(value=False)
    app.auto_replay_checkbutton = ttk.Checkbutton(
        workbench_actions,
        text="Auto replay (debounced)",
        variable=app.auto_replay_var,
    )
    app.auto_replay_checkbutton.grid(row=0, column=2, sticky="w", padx=(10, 0))
    workbench_actions.columnconfigure(3, weight=1)

    controls = ttk.Frame(workbench_pane)
    app.advanced_controls = controls
    controls.grid(row=1, column=0, sticky="ew", pady=(4, 0))
    controls.columnconfigure(0, weight=1)
    controls.columnconfigure(1, weight=0)
    action_controls = ttk.Frame(controls)
    action_controls.grid(row=0, column=0, columnspan=2, sticky="ew")
    primary_actions = ttk.Frame(action_controls)
    primary_actions.grid(row=0, column=0, sticky="ew")
    primary_actions.columnconfigure(0, weight=1)
    primary_actions.columnconfigure(1, weight=1)
    primary_actions.columnconfigure(2, weight=1)
    primary_actions.columnconfigure(3, weight=1)
    secondary_actions = ttk.Frame(action_controls)
    secondary_actions.grid(row=1, column=0, sticky="ew", pady=(4, 0))
    runtime_controls = ttk.Frame(controls)
    runtime_controls.grid(row=1, column=0, sticky="ew", pady=(4, 0))
    status_controls = ttk.Frame(controls)
    status_controls.grid(row=1, column=1, sticky="e", padx=(8, 0), pady=(4, 0))
    app.reset_button = ttk.Button(primary_actions, text="Reset", command=app.reset)
    app.reset_button.grid(row=0, column=0, sticky="ew", padx=(0, 3))
    app.settings_button = ttk.Button(
        primary_actions, text="Simulation settings…", command=app.open_runtime_settings
    )
    app.settings_button.grid(row=0, column=1, sticky="ew", padx=3)
    developer_test = ttk.LabelFrame(
        controls,
        text="Developer / Test fixtures",
        padding=(4, 3),
    )
    app.developer_test_frame = developer_test
    developer_test.grid(row=2, column=0, columnspan=2, sticky="ew", pady=(5, 0))
    developer_test.columnconfigure(4, weight=1)
    app.fixture_mode_var = app._tk.StringVar(
        value="Synthetic scenario controls · not save-backed authority"
    )
    ttk.Label(
        developer_test,
        textvariable=app.fixture_mode_var,
        anchor="w",
    ).grid(row=0, column=0, columnspan=5, sticky="w", padx=(0, 8))
    app.load_button = ttk.Button(developer_test, text="Load scenario", command=app.load)
    app.load_button.grid(row=1, column=0, sticky="w", pady=(3, 0))
    app.save_button = ttk.Button(developer_test, text="Save scenario", command=app.save)
    app.save_button.grid(row=1, column=1, sticky="w", padx=(6, 0), pady=(3, 0))
    ttk.Button(
        developer_test,
        text="Open World Browser",
        command=app._open_saved_world_browser,
    ).grid(row=1, column=2, sticky="w", padx=(12, 0), pady=(3, 0))
    app.language_var = app._tk.StringVar(
        value=app.scenario.get("runtime", {}).get("language", "EN")
    )
    app.language_box: Any | None = None
    app.compare_utterance_var = app._tk.StringVar(value="hello")
    app.matrix_dimension_var = app._tk.StringVar(value="persona")
    app.talk_utterance_var = app._tk.StringVar(
        value=str(app._ui_state.get("talk_utterance") or "hello")
    )
    app.talk_target_var = app._tk.StringVar(value="Current target")
    app.status_var = app._tk.StringVar(value="Starting…")
    app.status_label = ttk.Label(status_controls, textvariable=app.status_var)
    app.status_label.pack(anchor="e")
