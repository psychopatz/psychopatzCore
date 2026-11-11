"""Integrated Semantic Lab interaction-module structural workbench."""

from __future__ import annotations

from typing import Any, Callable

from .behavior_actions import BehaviorActionsMixin
from .catalog_actions import CatalogActionsMixin
from .draft_actions import DraftActionsMixin

class InteractionModulesPane(CatalogActionsMixin, DraftActionsMixin, BehaviorActionsMixin):
    """Interaction module structure editor with disposable worker overlays."""

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        filedialog: Any,
        messagebox: Any,
        *,
        on_refresh: Callable[[], Any],
        on_validate: Callable[[dict[str, Any]], Any],
        on_preview: Callable[[dict[str, Any], str], Any],
        on_register: Callable[[dict[str, Any]], Any],
        on_validate_behavior: Callable[[dict[str, Any]], Any],
        on_register_behavior: Callable[[dict[str, Any]], Any],
        on_load_canonical: Callable[[str], dict[str, Any]],
        on_preview_promotion: Callable[[str, dict[str, Any], str | None], Any],
        on_promote: Callable[[str, dict[str, Any], str | None], Any],
        on_open_content: Callable[[str], Any],
    ) -> None:
        self._tk = tk
        self._ttk = ttk
        self._ScrolledText = scrolled_text
        self._filedialog = filedialog
        self._messagebox = messagebox
        self._on_refresh = on_refresh
        self._on_validate = on_validate
        self._on_preview = on_preview
        self._on_register = on_register
        self._on_validate_behavior = on_validate_behavior
        self._on_register_behavior = on_register_behavior
        self._on_load_canonical = on_load_canonical
        self._on_preview_promotion = on_preview_promotion
        self._on_promote = on_promote
        self._on_open_content = on_open_content
        self._catalog: dict[str, Any] = {}
        self._beats: list[dict[str, Any]] = []
        self._behaviors: list[dict[str, Any]] = []
        self._beat_by_id: dict[str, dict[str, Any]] = {}
        self._behavior_by_id: dict[str, dict[str, Any]] = {}
        self._draft_source_id: str | None = None
        self._canonical_source: dict[str, Any] | None = None
        self._selected_behavior: dict[str, Any] | None = None
        self._behavior_canonical_source: dict[str, Any] | None = None
        self._status_kind = "EMPTY"

        self.frame = ttk.Frame(parent, padding=6)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(1, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self._build_toolbar()
        self._build_body()
        self._set_status("No interaction catalog loaded.", "EMPTY")

    def _build_toolbar(self) -> None:
        ttk = self._ttk
        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, sticky="ew", pady=(0, 6))
        toolbar.columnconfigure(11, weight=1)

        self.refresh_button = ttk.Button(
            toolbar, text="Refresh modules", command=self._on_refresh
        )
        self.refresh_button.grid(row=0, column=0)
        self.clone_button = ttk.Button(
            toolbar, text="Clone situation", command=self.clone_selected
        )
        self.clone_button.grid(row=0, column=1, padx=(6, 0))
        self.new_button = ttk.Button(
            toolbar, text="New situation", command=self.new_beat
        )
        self.new_button.grid(row=0, column=2, padx=(6, 0))
        self.open_button = ttk.Button(
            toolbar, text="Open draft", command=self.open_draft
        )
        self.open_button.grid(row=0, column=3, padx=(10, 0))
        self.save_button = ttk.Button(
            toolbar, text="Save draft", command=self.save_draft
        )
        self.save_button.grid(row=0, column=4, padx=(6, 0))
        self.validate_button = ttk.Button(
            toolbar, text="Validate structure", command=self.validate_draft
        )
        self.validate_button.grid(row=0, column=5, padx=(10, 0))
        self.preview_button = ttk.Button(
            toolbar, text="Preview structure", command=self.preview_draft
        )
        self.preview_button.grid(row=0, column=6, padx=(6, 0))
        self.register_button = ttk.Button(
            toolbar, text="Register worker overlay", command=self.register_draft
        )
        self.register_button.grid(row=0, column=7, padx=(6, 0))
        self.review_promotion_button = ttk.Button(
            toolbar, text="Review canonical diff", command=self.preview_promotion
        )
        self.review_promotion_button.grid(row=1, column=5, padx=(10, 0), pady=(4, 0))
        self.promote_button = ttk.Button(
            toolbar, text="Promote canonical", command=self.promote_canonical
        )
        self.promote_button.grid(row=1, column=6, columnspan=2, padx=(6, 0), pady=(4, 0))

        ttk.Label(toolbar, text="Preview stimulus text").grid(
            row=0, column=8, padx=(14, 4)
        )
        self.preview_text_var = self._tk.StringVar(value="fuck ypuuuu")
        ttk.Entry(toolbar, textvariable=self.preview_text_var, width=28).grid(
            row=0, column=9, sticky="ew"
        )

        self.provenance_var = self._tk.StringVar(value="EMPTY")
        ttk.Label(toolbar, textvariable=self.provenance_var).grid(
            row=0, column=10, padx=(12, 0)
        )
        self.status_var = self._tk.StringVar()
        ttk.Label(toolbar, textvariable=self.status_var).grid(
            row=1, column=0, columnspan=12, sticky="w", pady=(4, 0)
        )

    def _build_body(self) -> None:
        ttk = self._ttk
        body = ttk.PanedWindow(self.frame, orient="horizontal")
        body.grid(row=1, column=0, sticky="nsew")

        browser = ttk.LabelFrame(body, text="Production interaction modules")
        browser.rowconfigure(1, weight=2)
        browser.rowconfigure(3, weight=1)
        browser.columnconfigure(0, weight=1)
        ttk.Label(browser, text="Stateful situations / beats").grid(row=0, column=0, sticky="w")
        self.beat_list = self._tk.Listbox(
            browser, width=34, exportselection=False
        )
        self.beat_list.grid(row=1, column=0, sticky="nsew")
        self.beat_list.bind("<<ListboxSelect>>", self._beat_selected)
        ttk.Label(browser, text="Reusable semantic behaviors").grid(
            row=2, column=0, sticky="w", pady=(8, 0)
        )
        self.behavior_list = self._tk.Listbox(
            browser, width=34, exportselection=False
        )
        self.behavior_list.grid(row=3, column=0, sticky="nsew")
        self.behavior_list.bind(
            "<<ListboxSelect>>", self._behavior_selected
        )
        body.add(browser, weight=1)

        editor = ttk.LabelFrame(body, text="Situation / beat structure")
        editor.rowconfigure(8, weight=1)
        editor.columnconfigure(1, weight=1)
        self.beat_id_var = self._tk.StringVar()
        self.owner_var = self._tk.StringVar(value="SemanticLab")
        self.group_var = self._tk.StringVar(value="beat_group.social_primary")
        self.stimuli_var = self._tk.StringVar(value="HUMAN_UTTERANCE")
        self.relevance_var = self._tk.StringVar(value="0.5")
        self.max_turns_var = self._tk.StringVar(value="4")
        self.cooldown_var = self._tk.StringVar(value="2")
        self._entry(editor, 0, "Situation ID", self.beat_id_var)
        self._entry(editor, 1, "Owner", self.owner_var)
        self._entry(editor, 2, "Group", self.group_var)
        self._entry(
            editor, 3, "Stimuli (comma-separated)", self.stimuli_var
        )
        self._entry(editor, 4, "Base relevance", self.relevance_var)
        self._entry(editor, 5, "Max turns", self.max_turns_var)
        self._entry(editor, 6, "Cooldown turns", self.cooldown_var)

        predicates = ttk.Notebook(editor)
        predicates.grid(
            row=7, column=0, columnspan=2, sticky="nsew", padx=6, pady=6
        )
        editor.rowconfigure(7, weight=2)
        self.predicate_widgets: dict[str, tuple[Any, Any]] = {}
        for name in ("entry", "maintain", "exit"):
            frame = ttk.Frame(predicates, padding=4)
            frame.rowconfigure(0, weight=1)
            frame.columnconfigure(0, weight=1)
            tree = ttk.Treeview(
                frame,
                columns=("condition", "expected"),
                show="tree headings",
                height=6,
            )
            tree.heading("#0", text="Node")
            tree.heading("condition", text="Condition")
            tree.heading("expected", text="Expected")
            tree.column("#0", width=150)
            tree.column("condition", width=210)
            tree.column("expected", width=130)
            tree.grid(row=0, column=0, sticky="nsew")
            raw = self._ScrolledText(frame, height=7, wrap="none")
            raw.grid(row=1, column=0, sticky="nsew", pady=(4, 0))
            raw.bind("<KeyRelease>", lambda _e, n=name: self._refresh_predicate_tree(n))
            self.predicate_widgets[name] = (tree, raw)
            predicates.add(frame, text=name.capitalize())

        candidate_frame = ttk.LabelFrame(editor, text="Behavior candidates")
        candidate_frame.grid(
            row=8, column=0, columnspan=2, sticky="nsew", padx=6, pady=6
        )
        candidate_frame.rowconfigure(0, weight=1)
        candidate_frame.columnconfigure(0, weight=1)
        self.candidate_tree = ttk.Treeview(
            candidate_frame,
            columns=("relevance",),
            show="tree headings",
            height=6,
        )
        self.candidate_tree.heading("#0", text="Behavior")
        self.candidate_tree.heading("relevance", text="Situation relevance")
        self.candidate_tree.grid(row=0, column=0, sticky="nsew")
        self.candidate_tree.bind(
            "<<TreeviewSelect>>", self._candidate_behavior_selected
        )
        self.candidates_text = self._ScrolledText(
            candidate_frame, height=7, wrap="none"
        )
        self.candidates_text.grid(row=1, column=0, sticky="nsew", pady=(4, 0))
        self.candidates_text.bind(
            "<KeyRelease>", lambda _e: self._refresh_candidate_tree()
        )
        body.add(editor, weight=3)

        details = ttk.LabelFrame(body, text="Behavior structure / source / preview")
        details.rowconfigure(0, weight=1)
        details.columnconfigure(0, weight=1)
        tabs = ttk.Notebook(details)
        tabs.grid(row=0, column=0, sticky="nsew")

        raw_frame = ttk.Frame(tabs, padding=4)
        raw_frame.rowconfigure(0, weight=1)
        raw_frame.columnconfigure(0, weight=1)
        self.raw_beat = self._ScrolledText(raw_frame, wrap="none")
        self.raw_beat.grid(row=0, column=0, sticky="nsew")
        ttk.Button(
            raw_frame, text="Apply raw JSON", command=self.apply_raw_beat
        ).grid(row=1, column=0, sticky="e", pady=(4, 0))
        tabs.add(raw_frame, text="Situation JSON")

        behavior_frame = ttk.Frame(tabs, padding=4)
        behavior_frame.rowconfigure(1, weight=1)
        behavior_frame.columnconfigure(0, weight=1)
        self.behavior_status_var = self._tk.StringVar()
        ttk.Label(
            behavior_frame, textvariable=self.behavior_status_var
        ).grid(row=0, column=0, sticky="w")
        self.behavior_text = self._ScrolledText(
            behavior_frame, wrap="none"
        )
        self.behavior_text.grid(row=1, column=0, sticky="nsew")
        behavior_buttons = ttk.Frame(behavior_frame)
        behavior_buttons.grid(row=2, column=0, sticky="e", pady=(4, 0))
        ttk.Button(
            behavior_buttons,
            text="Validate behavior",
            command=self.validate_behavior,
        ).pack(side="left")
        ttk.Button(
            behavior_buttons,
            text="Register behavior overlay",
            command=self.register_behavior,
        ).pack(side="left", padx=(6, 0))
        self.open_speech_content_button = ttk.Button(
            behavior_buttons,
            text="Open speech content",
            command=lambda: self.open_behavior_content("speech"),
        )
        self.open_speech_content_button.pack(side="left", padx=(12, 0))
        self.open_flavor_content_button = ttk.Button(
            behavior_buttons,
            text="Open flavor content",
            command=lambda: self.open_behavior_content("flavor"),
        )
        self.open_flavor_content_button.pack(side="left", padx=(6, 0))
        self.review_behavior_button = ttk.Button(
            behavior_buttons,
            text="Review behavior diff",
            command=self.preview_behavior_promotion,
        )
        self.review_behavior_button.pack(side="left", padx=(12, 0))
        self.promote_behavior_button = ttk.Button(
            behavior_buttons,
            text="Promote behavior",
            command=self.promote_behavior_canonical,
        )
        self.promote_behavior_button.pack(side="left", padx=(6, 0))
        tabs.add(behavior_frame, text="Behavior structure")

        preview_frame = ttk.Frame(tabs, padding=4)
        preview_frame.rowconfigure(0, weight=1)
        preview_frame.columnconfigure(0, weight=1)
        self.preview_output = self._ScrolledText(
            preview_frame, wrap="none", state="disabled"
        )
        self.preview_output.grid(row=0, column=0, sticky="nsew")
        tabs.add(preview_frame, text="Preview / validation")

        body.add(details, weight=2)

    def _entry(self, parent: Any, row: int, label: str, variable: Any) -> None:
        self._ttk.Label(parent, text=label).grid(
            row=row, column=0, sticky="w", padx=6, pady=2
        )
        self._ttk.Entry(parent, textvariable=variable).grid(
            row=row, column=1, sticky="ew", padx=(0, 6), pady=2
        )
